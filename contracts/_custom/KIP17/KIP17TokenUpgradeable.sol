pragma solidity ^0.5.0;

import "./KIP17FullUpgradeable.sol";
import "./KIP17MetadataMintableUpgradeable.sol";
import "./KIP17MintableUpgradeable.sol";
import "./KIP17BurnableUpgradeable.sol";
import "./KIP17PausableUpgradeable.sol";
import "./KIP17EnumerableUpgradeable.sol";

contract KIP17TokenUpgradeable is KIP17FullUpgradeable, KIP17MintableUpgradeable, KIP17MetadataMintableUpgradeable, KIP17BurnableUpgradeable, KIP17PausableUpgradeable, KIP17EnumerableUpgradeable {
  function __KIP17Token_init(string memory name, string memory symbol) internal {
    __KIP17Full_init(name, symbol);
  }
}
