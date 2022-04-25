pragma solidity ^0.5.6;

import "../ownership/OwnableUpgradable.sol";
import "../../token/KIP17/IKIP17.sol";
import "../oldproxy/Initializable.sol";

contract GeneralBiddingV1 is Initializable, OwnableUpgradable {
  // ---------- proxy status start ----------
  mapping(address => uint256) public whitelistAmount;
  address[] public whitelist;

  address[] public winAddresses;
  mapping(address => uint256) winAmounts;

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

  // ---------- proxy status end ----------

  function initialize(uint256 price_) public initializer {
    __Ownable_init();
    _price = price_;
  }

  function setPrice(uint256 price_) external {
    _price = price_;
  }

  function seedWhiteList(address[] calldata addresses, uint256[] calldata amounts) external onlyOwner {
    if (addresses.length != amounts.length) {
      revert("The length of addresses and amounts don't match.");
    }

    whitelist = addresses;
    for (uint256 i; i < amounts.length; i++) {
      whitelistAmount[addresses[i]] = amounts[i];
    }
  }

  function _isWhiteListAddress(address address_) internal view returns (bool) {
    if (whitelistAmount[address_] > 0) {
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
      require(whitelistAmount[msg.sender] >= amount, "you are bidding more than you can.");
    }
    require(_maxBidPerTx >= amount, "You can not bid that much");
    require(_maxBidPerAddress >= winAmounts[msg.sender] + amount, "Exceed max bid per account");
    require(msg.value >= price, "You should send more money");
    require(block.timestamp >= _startTime, "Bidding has not started yet");
    require(block.timestamp <= _endTime, "Bidding has been ended");
    if (winAmounts[msg.sender] == 0) {
      winAddresses.push(msg.sender);
    }
    _remains = _remains - amount;
    winAmounts[msg.sender] = winAmounts[msg.sender] + amount;
    whitelistAmount[msg.sender] = whitelistAmount[msg.sender] - amount;
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

  function setRemains(uint256 quantity) external onlyOwner {
    _remains = quantity;
  }

  function setTotalSupply(uint256 quantity) external onlyOwner {
    _totalSupply = quantity;
  }
}
