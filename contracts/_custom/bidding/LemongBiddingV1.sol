pragma solidity ^0.5.6;

import "../ownership/OwnableUpgradeable.sol";
import "../../token/KIP17/IKIP17.sol";
import "../oldproxy/Initializable.sol";

contract ILemong {
  function numberMinted(address owner) public view returns (uint256);
}

contract LemongBiddingV1 is Initializable, OwnableUpgradeable {
  // ---------- proxy status start ----------
  mapping(address => uint256) public whitelist;

  address[] public winAddresses;
  mapping(address => uint256) public winAmounts;

  // Partner NFT holder match
  address[] public nftContracts;
  uint256[] public minHolds;

  uint256 public _totalSupply; // total supply
  uint256 public _remains; // remain amount

  uint256 public _maxBidPerAddress;
  uint256 public _maxBidPerTx;
  uint256 public _price;

  uint32 public _startTime;
  uint32 public _endTime;
  address internal _lemongAddress;
  uint32 public _maxMintPerAddress;

  // ---------- proxy status end ----------

  function initialize(
    uint256 price_,
    address lemongAddress_,
    uint256 maxBidPerAddress_,
    uint256 maxBidPerTx_,
    uint32 maxMintPerAddress_
  ) public initializer {
    __Ownable_init();
    _price = price_;
    _lemongAddress = lemongAddress_;
    _maxBidPerAddress = maxBidPerAddress_;
    _maxBidPerTx = maxBidPerTx_;
    _maxMintPerAddress = maxMintPerAddress_;
  }

  function setMaxBidPerAddress(uint256 maxBidPerAddress_) public onlyOwner {
    _maxBidPerAddress = maxBidPerAddress_;
  }

  function setMaxBidPerTx(uint256 maxBidPerTx_) public onlyOwner {
    _maxBidPerTx = maxBidPerTx_;
  }

  function setPrice(uint256 price_) external {
    _price = price_;
  }

  function seedWhiteList(address[] calldata addresses, uint256[] calldata numSlots) external onlyOwner {
    require(addresses.length == numSlots.length, "addresses does not match numSlots length");
    for (uint256 i = 0; i < addresses.length; i++) {
      whitelist[addresses[i]] = numSlots[i];
    }
  }

  function _isWhiteListAddress(address address_) internal view returns (bool) {
    if (whitelist[address_] > 0) {
      return true;
    } else {
      return false;
    }
  }

  function _isPartnerHolder(address address_) internal view returns (bool) {
    for (uint256 i = 0; i < nftContracts.length; i++) {
      uint256 balance = IKIP17(nftContracts[i]).balanceOf(address_);
      if (minHolds[i] <= balance) {
        return true;
      }
    }

    return false;
  }

  function setPartnerNFT(address[] calldata nftContracts_, uint256[] calldata minHolds_) external onlyOwner {
    nftContracts = nftContracts_;
    minHolds = minHolds_;
  }

  function bid(uint256 amount) external payable {
    bool isWhiteListAddress_ = _isWhiteListAddress(msg.sender);
    bool isPartnerHolder_ = _isPartnerHolder(msg.sender);
    bool avail = isWhiteListAddress_ || isPartnerHolder_;
    uint256 price = _price * amount;
    require(avail, "Only the account in whitelist or partner NFT holders can bid.");
    require(_remains >= amount, "No whitelist left.");
    if (isWhiteListAddress_) {
      require(whitelist[msg.sender] >= amount, "you are bidding more than you can.");
    }
    require(_maxBidPerTx >= amount, "You can not bid that much");
    require(_maxBidPerAddress >= winAmounts[msg.sender] + amount, "Exceed max bid per account");
    require(msg.value >= price, "You should send more money");
    require(block.timestamp >= _startTime, "Bidding has not started yet");
    require(block.timestamp <= _endTime, "Bidding has been ended");
    // FIXME: 이거 꼭 수정해야함
    // uint256 minted = ILemong(_lemongAddress).numberMinted(msg.sender);
    // require(minted <= _maxMintPerAddress, "You can not mint anymore. Check how many LEMONG NFT did you mint.");
    //  FIXME: 이거 꼭 수정해야함
    // if (winAmounts[msg.sender] == 0) {
    //   winAddresses.push(msg.sender);
    // }
    _remains = _remains - amount;
    winAmounts[msg.sender] = winAmounts[msg.sender] + amount;
    whitelist[msg.sender] = whitelist[msg.sender] - amount;
    refundIfOver(price);
  }

  function refundIfOver(uint256 price) private {
    require(msg.value >= price, "Need to send more ETH.");
    if (msg.value > price) {
      msg.sender.transfer(msg.value - price);
    }
  }

  function withdrawMoney() external onlyOwner {
    (bool success, ) = msg.sender.call.value(address(this).balance)("");
    require(success, "Transfer failed.");
  }

  function getWinAddresses() external view returns (address[] memory) {
    return winAddresses;
  }

  function setTotalSupply(uint256 quantity) external onlyOwner {
    _totalSupply = quantity;
    _remains = quantity;
  }

  function startBidding(
    uint32 startTime_,
    uint32 endTime_,
    uint256 price_
  ) external onlyOwner {
    _startTime = startTime_;
    _endTime = endTime_;
    _price = price_;
  }
}
