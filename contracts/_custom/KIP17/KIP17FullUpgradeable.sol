pragma solidity ^0.5.0;

import "./KIP17Upgradable.sol";
import "./KIP17EnumerableUpgradable.sol";
import "./KIP17MetadataUpgradable.sol";

/**
 * @title Full KIP-17 Token
 * This implementation includes all the required and some optional functionality of the KIP-17 standard
 * Moreover, it includes approve all functionality using operator terminology
 * @dev see http://kips.klaytn.com/KIPs/kip-17-non_fungible_token
 */
contract KIP17Full is KIP17, KIP17EnumerableUpgradable, KIP17MetadataUpgradable {
  function __KIP17Full_init(string memory name, string memory symbol) public {
    __KIP17Metadata_init(name, symbol);
    // solhint-disable-previous-line no-empty-blocks
  }
}
