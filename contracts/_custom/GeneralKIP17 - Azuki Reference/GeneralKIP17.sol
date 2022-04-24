// SPDX-License-Identifier: MIT

pragma solidity ^0.5.6;

import "../../ownership/Ownable.sol";
import "./ReentrancyGuard.sol";
import "../KIP17/KIP17A.sol";
import "../utils/Strings.sol";
import "../../token/KIP17/IKIP17.sol";

contract GeneralKIP17 is Ownable, KIP17A, ReentrancyGuard {
  uint256 public maxPerAddressDuringMint;
  uint256 public amountForDevs;
  uint256 public amountForAuctionAndDev;

  struct SaleConfig {
    uint32 auctionSaleStartTime;
    uint32 publicSaleKey;
    uint32 publicSaleStartTime;
    uint32 publicSaleEndTime; // public sale end time
    uint64 publicPrice;
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
  ) public KIP17A("GeneralKIP17", "GKIP17", maxBatchSize_, collectionSize_) {
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

  function auctionMint(uint256 quantity) external payable callerIsUser {
    uint256 _saleStartTime = uint256(saleConfig.auctionSaleStartTime);
    require(_saleStartTime != 0 && block.timestamp >= _saleStartTime, "sale has not started yet");
    require(totalSupply() + quantity <= amountForAuctionAndDev, "not enough remaining reserved for auction to support desired mint amount");
    require(numberMinted(msg.sender) + quantity <= maxPerAddressDuringMint, "can not mint this many");
    uint256 totalCost = getAuctionPrice(_saleStartTime) * quantity;
    _safeMint(msg.sender, quantity);
    refundIfOver(totalCost);
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

  function allowlistMint() external payable callerIsUser allowlistMintOn {
    uint256 price = uint256(allowListSaleConfig.price);
    require(price != 0, "allowlist sale has not begun yet");
    require(allowlist[msg.sender] > 0, "not eligible for allowlist mint");
    require(totalSupply() + 1 <= collectionSize, "reached max supply");
    allowlist[msg.sender]--;
    _safeMint(msg.sender, 1);
    refundIfOver(price);
  }

  modifier holderSaleOn() {
    require(holderSaleConfig.holderPrice != 0, "holder sale not in progress");
    _;
  }

  // mint for user who owns specific NFT tokens
  function holderMint() external payable callerIsUser matchNFTHoldCondition holderSaleOn {
    uint256 price = uint256(holderSaleConfig.holderPrice);
    require(price != 0, "holder sale has not begun yet");
    require(totalSupply() + 1 <= collectionSize, "reached max supply");
    require(balanceOf(msg.sender) + 1 <= holderSaleConfig.mintLimit, "reached max mint count for NFT holders");
    _safeMint(msg.sender, 1);
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
    uint256 publicSalesEndTime
  ) public view returns (bool) {
    return publicPriceWei != 0 && publicSaleKey != 0 && block.timestamp >= publicSaleStartTime && block.timestamp <= publicSalesEndTime;
  }

  uint256 public constant AUCTION_START_PRICE = 1 ether;
  uint256 public constant AUCTION_END_PRICE = 0.15 ether;
  uint256 public constant AUCTION_PRICE_CURVE_LENGTH = 340 minutes;
  uint256 public constant AUCTION_DROP_INTERVAL = 20 minutes;
  uint256 public constant AUCTION_DROP_PER_STEP = (AUCTION_START_PRICE - AUCTION_END_PRICE) / (AUCTION_PRICE_CURVE_LENGTH / AUCTION_DROP_INTERVAL);

  function getAuctionPrice(uint256 _saleStartTime) public view returns (uint256) {
    if (block.timestamp < _saleStartTime) {
      return AUCTION_START_PRICE;
    }
    if (block.timestamp - _saleStartTime >= AUCTION_PRICE_CURVE_LENGTH) {
      return AUCTION_END_PRICE;
    } else {
      uint256 steps = (block.timestamp - _saleStartTime) / AUCTION_DROP_INTERVAL;
      return AUCTION_START_PRICE - (steps * AUCTION_DROP_PER_STEP);
    }
  }

  function startPublicSale(
    uint32 publicSaleKey,
    uint64 publicPriceWei,
    uint32 publicSaleStartTime,
    uint32 publicSalesEndTime,
    uint256 publicSaleLimit
  ) external onlyOwner {
    saleConfig = SaleConfig(0, publicSaleKey, publicSaleStartTime, publicSalesEndTime, publicPriceWei, publicSaleLimit);
  }

  function setAuctionSaleStartTime(uint32 timestamp) external onlyOwner {
    saleConfig.auctionSaleStartTime = timestamp;
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
    require(quantity % maxBatchSize == 0, "can only mint a multiple of the maxBatchSize");
    uint256 numChunks = quantity / maxBatchSize;
    for (uint256 i = 0; i < numChunks; i++) {
      _safeMint(msg.sender, maxBatchSize);
    }
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
