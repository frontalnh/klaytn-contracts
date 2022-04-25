// SPDX-License-Identifier: MIT

pragma solidity ^0.5.6;

import "../../ownership/Ownable.sol";
import "../utils/ReentrancyGuard.sol";
import "./KIP17A.sol";
import "../utils/Strings.sol";
import "../../token/KIP17/IKIP17.sol";

contract Lemong is Ownable, KIP17A, ReentrancyGuard {
  uint256 public maxPerAddressDuringMint;
  uint256 public amountForDevs;
  uint256 public amountForAuctionAndDev;

  struct SaleConfig {
    uint32 publicSaleKey;
    uint32 publicSaleStartTime;
    uint32 publicSaleEndTime; // public sale end time
    uint256 publicPrice;
    uint256 publicSaleLimit;
  }

  struct AllowListSaleConfig {
    uint256 price; // mint price for allow list accounts
  }

  struct HolderSaleConfig {
    uint256 holderPrice;
    // check nft holder
    address[] nftContracts;
    uint256[] nftMinHolds;
    uint256 mintLimit;
  }

  SaleConfig public saleConfig;
  HolderSaleConfig public holderSaleConfig;
  AllowListSaleConfig public allowListSaleConfig;

  mapping(address => uint256) public allowlist;

  uint256 public minMatchCondition = 2;

  constructor(
    uint256 maxBatchSize_,
    uint256 collectionSize_,
    uint256 amountForAuctionAndDev_,
    uint256 amountForDevs_
  ) public KIP17A("LEMONG 3D", "LEMONG", maxBatchSize_, collectionSize_) {
    maxPerAddressDuringMint = maxBatchSize_;
    amountForAuctionAndDev = amountForAuctionAndDev_;
    amountForDevs = amountForDevs_;
    require(amountForAuctionAndDev_ <= collectionSize_, "larger collection size needed");
  }

  function startHolderSale(
    uint256 holderPrice,
    address[] calldata contracts,
    uint256[] calldata minHolds,
    uint256 mintLimit
  ) external onlyOwner {
    holderSaleConfig = HolderSaleConfig(holderPrice, contracts, minHolds, mintLimit);
  }

  function setMintMatchCondition(uint256 count) external {
    minMatchCondition = count;
  }

  function endHolderSale() external onlyOwner {
    holderSaleConfig.holderPrice = 0;
  }

  modifier callerIsUser() {
    require(tx.origin == msg.sender, "The caller is another contract");
    _;
  }

  modifier matchNFTHoldCondition() {
    uint256 _matchCnt = 0;

    for (uint256 i = 0; i < holderSaleConfig.nftContracts.length; i++) {
      uint256 balance = IKIP17(holderSaleConfig.nftContracts[i]).balanceOf(msg.sender);
      if (holderSaleConfig.nftMinHolds[i] <= balance) {
        _matchCnt++;
      }
    }

    require(minMatchCondition <= _matchCnt, "NFT hold condition not matched");
    _;
  }

  modifier allowlistMintOn() {
    uint256 price = uint256(allowListSaleConfig.price);
    require(price != 0, "allowlist sale has not begun yet");
    _;
  }

  function startAllowlistSale(uint256 price) external onlyOwner {
    allowListSaleConfig.price = price;
  }

  function endAllowListSale() external onlyOwner {
    allowListSaleConfig.price = 0;
  }

  function allowlistMint(uint256 amount) external payable callerIsUser allowlistMintOn {
    uint256 price = uint256(allowListSaleConfig.price);
    require(price != 0, "allowlist sale has not begun yet");
    require(allowlist[msg.sender] >= amount, "not eligible for allowlist mint");
    require(totalSupply() + amount <= collectionSize, "reached max supply");
    allowlist[msg.sender] = allowlist[msg.sender] - amount;
    _safeMint(msg.sender, amount);
    refundIfOver(price);
  }

  modifier holderSaleOn() {
    require(holderSaleConfig.holderPrice != 0, "holder sale not in progress");
    _;
  }

  // mint for user who owns specific NFT tokens
  function holderMint(uint256 amount) external payable callerIsUser matchNFTHoldCondition holderSaleOn {
    uint256 price = uint256(holderSaleConfig.holderPrice);
    require(price != 0, "holder sale has not begun yet");
    require(totalSupply() + amount <= collectionSize, "reached max supply");
    require(balanceOf(msg.sender) + amount <= holderSaleConfig.mintLimit, "reached max mint count for NFT holders");
    _safeMint(msg.sender, amount);
    refundIfOver(price);
  }

  function publicSaleMint(uint256 quantity, uint256 callerPublicSaleKey) external payable callerIsUser {
    SaleConfig memory config = saleConfig;
    uint256 publicSaleKey = uint256(config.publicSaleKey);
    uint256 publicPrice = uint256(config.publicPrice);
    uint256 publicSaleStartTime = uint256(config.publicSaleStartTime);
    uint256 publicSaleEndTime = uint256(config.publicSaleEndTime);
    uint256 publicSaleLimit = uint256(config.publicSaleLimit);
    require(publicSaleKey == callerPublicSaleKey, "called with incorrect public sale key");
    require(isPublicSaleOn(publicPrice, publicSaleKey, publicSaleStartTime, publicSaleEndTime), "public sale has not begun yet");
    require(totalSupply() + quantity <= publicSaleLimit, "reached public sale limit");
    require(totalSupply() + quantity <= collectionSize, "reached max supply");
    require(numberMinted(msg.sender) + quantity <= maxPerAddressDuringMint, "can not mint this many");
    _safeMint(msg.sender, quantity);
    refundIfOver(publicPrice * quantity);
  }

  function refundIfOver(uint256 price) private {
    require(msg.value >= price, "Need to send more ETH.");
    if (msg.value > price) {
      msg.sender.transfer(msg.value - price);
    }
  }

  function isPublicSaleOn(
    uint256 publicPriceWei,
    uint256 publicSaleKey,
    uint256 publicSaleStartTime,
    uint256 publicSaleEndTime
  ) public view returns (bool) {
    return publicPriceWei != 0 && publicSaleKey != 0 && block.timestamp >= publicSaleStartTime && block.timestamp <= publicSaleEndTime;
  }

  function startPublicSale(
    uint32 publicSaleKey,
    uint256 publicPriceWei,
    uint32 publicSaleStartTime,
    uint32 publicSaleEndTime,
    uint256 publicSaleLimit
  ) external onlyOwner {
    saleConfig = SaleConfig(publicSaleKey, publicSaleStartTime, publicSaleEndTime, publicPriceWei, publicSaleLimit);
  }

  function endPublicSale() external onlyOwner {
    saleConfig.publicPrice = 0;
  }

  function setPublicSaleKey(uint32 key) external onlyOwner {
    saleConfig.publicSaleKey = key;
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
