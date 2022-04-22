pragma solidity ^0.5.6;

import "../ownership/Ownable.sol";
import "../token/KIP17/IKIP17.sol";
import "./GeneralBidding.sol";
import "../oldproxy/Initializable.sol";

contract GeneralBiddingV1 is Initializable, Ownable {
  constructor(
    uint256 totalSupply,
    uint256 maxBidPerAddress,
    uint256 maxBidPerTx_
  ) public initializer {
    _totalSupply = totalSupply;
    _maxBidPerAddress = maxBidPerAddress;
    remains = totalSupply;
    maxBidPerTx = maxBidPerTx_;
  }

  // ---------- proxy status start ----------
  mapping(address => uint256) public whitelistAmount;
  address[] public whitelist;

  address[] public winAddresses;
  mapping(address => uint256) winAmounts;

  // Partner NFT holder match
  address[] public nftContracts;
  uint256[] public minHolds;

  uint256 public _totalSupply; // total supply
  uint256 public remains; // remain amount

  uint256 public _maxBidPerAddress;
  uint256 maxBidPerTx;

  // ---------- proxy status end ----------

  function seedWhiteList(address[] calldata addresses, uint256[] calldata amounts) external {
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

  function bid(uint256 amount) external {
    bool avail = _isWhiteListAddress(msg.sender) || _isPartnerHolder(msg.sender);
    require(avail, "Only the account in white list or partner NFT holders can bid.");
    require(remains >= amount, "No whitelist left.");
    require(whitelistAmount[msg.sender] >= amount, "you are bidding more than you can.");
    require(maxBidPerTx >= amount, "You can not bid that much.");

    winAddresses.push(msg.sender);
    remains = remains - amount;
    winAmounts[msg.sender] = winAmounts[msg.sender] + amount;
    whitelistAmount[msg.sender] = whitelistAmount[msg.sender] - amount;
  }

  function withdrawMoney() external onlyOwner {
    (bool success, ) = msg.sender.call.value(address(this).balance)("");
    require(success, "Transfer failed.");
  }
}
