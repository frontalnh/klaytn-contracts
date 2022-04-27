pragma solidity ^0.5.6;

import "../../ownership/Ownable.sol";
import "../../token/KIP17/IKIP17.sol";
import "../oldproxy/TransparentUpgradeableProxy.sol";

contract LemongBiddingProxy is TransparentUpgradeableProxy, Ownable {
  constructor(address _logic, address _admin) public TransparentUpgradeableProxy(_logic, _admin, "") {}

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

  PreSaleConfig public preSaleConfig;
  PublicSaleConfig public publicSaleConfig;
  AllowlistSaleConfig public allowlistSaleConfig;

  // Storage End
}
