// SPDX-License-Identifier: MIT

pragma solidity ^0.5.6;

import "../ownership/OwnableUpgradeable.sol";
import "../utils/ReentrancyGuardUpgradable.sol";
import "../../token/KIP17/IKIP17.sol";
import "../oldproxy/Initializable.sol";
import "./KIP17TokenAUpgradeable.sol";

contract FootageV1 is Initializable, OwnableUpgradeable, KIP17TokenAUpgradeable, ReentrancyGuardUpgradable {
  // Storage Start
  uint256 public maxPerAddressDuringMint;
  uint256 public amountForDevs;
  struct PreSaleConf {
    bool open;
    uint32 startTime;
    uint32 endTime;
    uint256 price;
    uint256 limit;
  }
  struct PublicSaleConf {
    bool open;
    uint32 publicSaleKey;
    uint32 startTime;
    uint32 endTime;
    uint64 price;
    uint256 limit;
  }
  struct AllowSaleConf {
    bool open;
    uint256 price; // mint price for allow list accounts
    uint32 startTime;
    uint32 endTime;
    mapping(address => uint256) allowlist;
    uint256 limit;
  }
  PreSaleConf public preSaleConf;
  PublicSaleConf public publicSaleConf;
  AllowSaleConf public allowSaleConf;
  mapping(address => uint256) private _numberMinted;

  // Storage End

  function initialize(
    string calldata name_,
    string calldata symbol_,
    uint256 maxBatchSize_,
    uint256 collectionSize_,
    uint256 amountForDevs_
  ) external initializer {
    __Ownable_init();
    __KIP17TokenA_init(name_, symbol_, maxBatchSize_, collectionSize_);
    __ReentrancyGuard_init();
    maxPerAddressDuringMint = maxBatchSize_;
    amountForDevs = amountForDevs_;
    require(amountForDevs_ <= collectionSize_, "larger collection size needed");
  }

  modifier callerIsUser() {
    require(tx.origin == msg.sender, "The caller is another contract");
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

  function preSaleMint(uint256 quantity_) external payable onlyOwner {
    require(collectionSize >= totalSupply() + quantity_, "Reached collection size");
    require(preSaleConf.open == true, "Presale not in progress");
    uint256 price = preSaleConf.price * quantity_;
    require(msg.value >= price, "You should send more KLAY");
    require(maxPerAddressDuringMint >= _numberMinted[msg.sender] + quantity_, "Reached max allowed mint");
    _safeMint(msg.sender, quantity_);
    _increaseMinted(msg.sender, quantity_);
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

  function allowlistMint(uint256 quantity_) external payable callerIsUser {
    require(allowSaleConf.open == true, "Allowlist sale not in progress");
    uint256 price = uint256(allowSaleConf.price * quantity_);
    require(allowSaleConf.allowlist[msg.sender] >= quantity_, "not eligible for allowlist mint");
    require(totalSupply() + quantity_ <= collectionSize, "reached max supply");
    require(maxPerAddressDuringMint >= _numberMinted[msg.sender] + quantity_, "Reached max allowed mint");
    allowSaleConf.allowlist[msg.sender] = allowSaleConf.allowlist[msg.sender] - quantity_;
    _safeMint(msg.sender, quantity_);
    _increaseMinted(msg.sender, quantity_);
    refundIfOver(price);
  }

  function publicSaleMint(uint256 quantity, uint256 callerPublicSaleKey) external payable callerIsUser {
    require(publicSaleConf.open == true, "Public sale not in progress");
    require(publicSaleConf.publicSaleKey == callerPublicSaleKey, "incorrect public sale key");
    require(block.timestamp >= publicSaleConf.startTime && block.timestamp <= publicSaleConf.endTime, "Public sale not in progress");
    require(totalSupply() + quantity <= publicSaleConf.limit, "reached public sale limit");
    require(totalSupply() + quantity <= collectionSize, "reached max supply");
    require(_numberMinted[msg.sender] + quantity <= maxPerAddressDuringMint, "can not mint this many");
    require(maxPerAddressDuringMint >= _numberMinted[msg.sender] + quantity, "Reached max allowed mint");
    uint256 price = publicSaleConf.price * quantity;
    require(msg.value >= price, "Need to send more KLAY");
    _safeMint(msg.sender, quantity);
    _increaseMinted(msg.sender, quantity);
    refundIfOver(price);
  }

  function _increaseMinted(address address_, uint256 quantity) private {
    _numberMinted[address_] = _numberMinted[address_] + quantity;
  }

  function refundIfOver(uint256 price) private {
    require(msg.value >= price, "Need to send more KLAY.");
    if (msg.value > price) {
      msg.sender.transfer(msg.value - price);
    }
  }

  function openPublicSale(
    uint32 publicSaleKey,
    uint64 priceWei,
    uint32 startTime,
    uint32 endTime,
    uint256 limit
  ) external onlyOwner {
    publicSaleConf = PublicSaleConf(true, publicSaleKey, startTime, endTime, priceWei, limit);
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

  // metadata URI
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
}
