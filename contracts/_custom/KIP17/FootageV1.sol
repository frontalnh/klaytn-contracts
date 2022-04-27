// SPDX-License-Identifier: MIT

pragma solidity ^0.5.6;

import "../ownership/OwnableUpgradable.sol";
import "../utils/ReentrancyGuardUpgradable.sol";
import "./KIP17AUpgradable.sol";
import "../utils/Strings.sol";
import "../../token/KIP17/IKIP17.sol";
import "../oldproxy/Initializable.sol";

contract FootageV1 is Initializable, OwnableUpgradable, KIP17AUpgradable, ReentrancyGuardUpgradable {
  // Storage Start
  uint256 public maxPerAddressDuringMint;
  uint256 public amountForDevs;
  uint256 public amountForAuctionAndDev;

  struct PreSaleConfig {
    bool open;
    uint32 startTime;
    uint32 endTime;
    uint256 price;
    uint256 limit;
  }

  struct PublicSaleConfig {
    bool open;
    uint32 publicSaleKey;
    uint32 startTime;
    uint32 endTime;
    uint64 price;
    uint256 limit;
  }

  struct AllowlistSaleConfig {
    bool open;
    uint256 price; // mint price for allow list accounts
    uint32 startTime;
    uint32 endTime;
    mapping(address => uint256) allowlist;
    uint256 limit;
  }

  PreSaleConfig public preSaleConf;
  PublicSaleConfig public publicSaleConf;
  AllowlistSaleConfig public allowSaleConf;

  // Storage End

  function initialize(
    string calldata name_,
    string calldata symbol_,
    uint256 maxBatchSize_,
    uint256 collectionSize_,
    uint256 amountForAuctionAndDev_,
    uint256 amountForDevs_
  ) external initializer {
    __Ownable_init();
    __KIP17A_init(name_, symbol_, maxBatchSize_, collectionSize_);
    __ReentrancyGuard_init();
    maxPerAddressDuringMint = maxBatchSize_;
    amountForAuctionAndDev = amountForAuctionAndDev_;
    amountForDevs = amountForDevs_;
    require(amountForAuctionAndDev_ <= collectionSize_, "larger collection size needed");
  }

  modifier callerIsUser() {
    require(tx.origin == msg.sender, "The caller is another contract");
    _;
  }

  modifier allowlistSaleOn() {
    require(allowSaleConf.open == true, "Allowlist sale not in progress");
    _;
  }

  function openPreSale(
    uint32 startTime_,
    uint32 endTime_,
    uint256 price_,
    uint256 limit_
  ) external onlyOwner {
    preSaleConf.open = true;
    preSaleConf.startTime = startTime_;
    preSaleConf.endTime = endTime_;
    preSaleConf.price = price_;
    preSaleConf.limit = limit_;
  }

  modifier preSaleOn() {
    require(preSaleConf.open == true, "Presale not in progress");
    _;
  }

  function preSaleMint(uint256 quantity_) external payable onlyOwner preSaleOn {
    require(collectionSize >= totalSupply() + quantity_, "Reached collection size");
    uint256 price = preSaleConf.price * quantity_;
    require(msg.value >= price, "You should send more KLAY");
    require(maxPerAddressDuringMint >= numberMinted(msg.sender) + quantity_, "Reached max allowed mint");
    _safeMint(msg.sender, quantity_);
    refundIfOver(price);
  }

  function closePreSale() external onlyOwner {
    preSaleConf.open = false;
  }

  function openAllowlistSale(uint256 price) external onlyOwner {
    allowSaleConf.open = true;
    allowSaleConf.price = price;
  }

  function closeAllowListSale() external onlyOwner {
    allowSaleConf.open = false;
  }

  function allowlistMint(uint256 amount) external payable callerIsUser allowlistSaleOn {
    uint256 price = uint256(allowSaleConf.price * amount);
    require(allowSaleConf.allowlist[msg.sender] >= amount, "not eligible for allowlist mint");
    require(totalSupply() + amount <= collectionSize, "reached max supply");
    allowSaleConf.allowlist[msg.sender] = allowSaleConf.allowlist[msg.sender] - amount;
    _safeMint(msg.sender, amount);
    refundIfOver(price);
  }

  function publicSaleMint(uint256 quantity, uint256 callerPublicSaleKey) external payable callerIsUser publicSaleOn {
    require(publicSaleConf.publicSaleKey == callerPublicSaleKey, "called with incorrect public sale key");
    require(block.timestamp >= publicSaleConf.startTime && block.timestamp <= publicSaleConf.endTime, "Public sale not in progress");
    require(totalSupply() + quantity <= publicSaleConf.limit, "reached public sale limit");
    require(totalSupply() + quantity <= collectionSize, "reached max supply");
    require(numberMinted(msg.sender) + quantity <= maxPerAddressDuringMint, "can not mint this many");
    uint256 price = publicSaleConf.price * quantity;
    require(price >= msg.value, "Need to send more KLAY");
    _safeMint(msg.sender, quantity);
    refundIfOver(price);
  }

  modifier publicSaleOn() {
    require(publicSaleConf.open == true, "Public sale not in progress");
    _;
  }

  function refundIfOver(uint256 price) private {
    require(msg.value >= price, "Need to send more KLAY.");
    if (msg.value > price) {
      msg.sender.transfer(msg.value - price);
    }
  }

  function startPublicSale(
    uint32 publicSaleKey,
    uint64 priceWei,
    uint32 startTime,
    uint32 endTime,
    uint256 limit
  ) external onlyOwner {
    publicSaleConf = PublicSaleConfig(true, publicSaleKey, startTime, endTime, priceWei, limit);
  }

  function endPublicSale() external onlyOwner {
    publicSaleConf.open = false;
  }

  function setPublicSaleKey(uint32 key) external onlyOwner {
    publicSaleConf.publicSaleKey = key;
  }

  function seedAllowlist(address[] calldata addresses, uint256[] calldata numSlots) external onlyOwner {
    require(addresses.length == numSlots.length, "addresses does not match numSlots length");
    for (uint256 i = 0; i < addresses.length; i++) {
      allowSaleConf.allowlist[addresses[i]] = numSlots[i];
    }
  }

  // For marketing etc.
  function devMint(uint256 quantity) external onlyOwner {
    require(totalSupply() + quantity <= amountForDevs, "too many already minted before dev mint");

    uint256 numChunks = quantity / maxBatchSize;
    for (uint256 i = 0; i < numChunks; i++) {
      _safeMint(msg.sender, maxBatchSize);
    }
    uint256 left = quantity % maxBatchSize;
    _safeMint(msg.sender, left);
  }

  // // metadata URI
  string private _baseTokenURI;

  function _baseURI() internal view returns (string memory) {
    return _baseTokenURI;
  }

  function setBaseURI(string calldata baseURI) external onlyOwner {
    _baseTokenURI = baseURI;
  }

  function withdrawMoney() external onlyOwner nonReentrant {
    (bool success, ) = msg.sender.call.value(address(this).balance)("");
    require(success, "Transfer failed.");
  }

  function setOwnersExplicit(uint256 quantity) external onlyOwner nonReentrant {
    _setOwnersExplicit(quantity);
  }

  function numberMinted(address owner) public view returns (uint256) {
    return _numberMinted(owner);
  }
}
