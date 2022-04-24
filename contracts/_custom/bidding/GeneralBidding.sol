pragma solidity ^0.5.6;

import "../../ownership/Ownable.sol";
import "../../token/KIP17/IKIP17.sol";
import "../oldproxy/TransparentUpgradeableProxy.sol";

contract GeneralBidding is TransparentUpgradeableProxy, Ownable {
  constructor(
    uint256 totalSupply,
    uint256 maxBidPerAddress,
    uint256 maxBidPerTx,
    address _logic,
    address _admin
  ) public TransparentUpgradeableProxy(_logic, _admin, "") {
    _totalSupply = totalSupply;
    _maxBidPerAddress = maxBidPerAddress;
    _maxBidPerTx = maxBidPerTx;
    _remains = totalSupply;
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
  uint256 public _remains; // remain amount

  uint256 public _maxBidPerAddress;
  uint256 public _maxBidPerTx;
  uint256 public price;

  // ---------- proxy status end ----------
}
