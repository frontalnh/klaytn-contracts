// SPDX-License-Identifier: MIT

pragma solidity ^0.5.6;

import "../../ownership/Ownable.sol";
import "../utils/ReentrancyGuard.sol";
import "./KIP17A.sol";
import "../utils/Strings.sol";
import "../../token/KIP17/IKIP17.sol";
import "../oldproxy/TransparentUpgradeableProxy.sol";

contract GKIP17 is Ownable, TransparentUpgradeableProxy {
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
  }

  struct HolderSaleConfig {
    uint256 price;
    address[] nftContracts;
    uint256[] nftMinHolds;
    uint256 minMatchCondition;
    uint256 limit;
    uint32 startTime;
    uint32 endTime;
  }
  PreSaleConfig public preSaleConfig;
  PublicSaleConfig public saleConfig;
  HolderSaleConfig public holderSaleConfig;
  AllowlistSaleConfig public allowlistSaleConfig;

  constructor(address _logic, address _admin) public TransparentUpgradeableProxy(_logic, _admin, "") Ownable() {}
}
