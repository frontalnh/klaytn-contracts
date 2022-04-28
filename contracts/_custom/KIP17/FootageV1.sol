// SPDX-License-Identifier: MIT

pragma solidity ^0.5.6;

import "../ownership/OwnableUpgradeable.sol";
import "../utils/ReentrancyGuardUpgradable.sol";
import "../oldproxy/Initializable.sol";
import "./KIP17TokenAUpgradeable.sol";
import "../utils/Strings.sol";
import "../reveal/RevealableUpgradeable.sol";

contract FootageV1 is Initializable, OwnableUpgradeable, KIP17TokenAUpgradeable, ReentrancyGuardUpgradable, RevealableUpgradeable {
  using Strings for uint256;

  uint256 public maxPerAddressDuringMint;
  uint256 public amountForDevs;

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
    uint256 limit;
    uint256 minted;
  }
  mapping(address => uint256) allowlist;

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

  function openAllowlistSale(
    uint256 price,
    uint256 limit_,
    uint32 startTime_,
    uint32 endTime_
  ) external onlyOwner {
    allowSaleConf = AllowSaleConf(true, price, startTime_, endTime_, limit_, 0);
  }

  function closeAllowListSale() external onlyOwner {
    allowSaleConf.open = false;
  }

  function allowlistMint(uint256 quantity_) external payable callerIsUser {
    require(allowSaleConf.open == true, "Allowlist sale not in progress");
    uint256 price = uint256(allowSaleConf.price * quantity_);
    require(allowlist[msg.sender] >= quantity_, "not eligible for allowlist mint");
    require(totalSupply() + quantity_ <= collectionSize, "reached max supply");
    require(maxPerAddressDuringMint >= _numberMinted[msg.sender] + quantity_, "Reached max allowed mint");
    require(allowSaleConf.limit >= allowSaleConf.minted + quantity_, "exceed limit");
    allowlist[msg.sender] = allowlist[msg.sender] - quantity_;
    _safeMint(msg.sender, quantity_);
    _increaseMinted(msg.sender, quantity_);
    allowSaleConf.minted = allowSaleConf.minted + quantity_;
    refundIfOver(price);
  }

  function publicSaleMint(uint256 quantity, uint256 callerPublicSaleKey) external payable callerIsUser {
    require(publicSaleConf.open == true, "not opened");
    require(publicSaleConf.publicSaleKey == callerPublicSaleKey, "incorrect public sale key");
    require(block.timestamp >= publicSaleConf.startTime && block.timestamp <= publicSaleConf.endTime, "not on sale");
    require(totalSupply() + quantity <= publicSaleConf.limit, "reached limit");
    require(totalSupply() + quantity <= collectionSize, "reached collection size");
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

  function closePublicSale() external onlyOwner {
    publicSaleConf.open = false;
  }

  function setPublicSaleKey(uint32 key) external onlyOwner {
    publicSaleConf.publicSaleKey = key;
  }

  function seedAllowlist(address[] calldata addresses, uint256[] calldata numSlots) external onlyOwner {
    require(addresses.length == numSlots.length, "addresses does not match numSlots length");
    for (uint256 i = 0; i < addresses.length; i++) {
      allowlist[addresses[i]] = numSlots[i];
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

  /**
   * @dev See {IKIP17Metadata-tokenURI}.
   */
  function tokenURI(uint256 tokenId) public view returns (string memory) {
    require(_exists(tokenId), "KIP17Metadata: URI query for nonexistent token");

    string memory baseURI = _baseURI();
    if (revealed) {
      baseURI = _revealURI;
    }
    return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json")) : "";
  }
}
