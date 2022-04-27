pragma solidity ^0.5.0;

import "./KIP17Upgradeable.sol";
import "../../token/KIP17/IKIP17Metadata.sol";
import "../introspection/KIP13Upgradeable.sol";

contract KIP17MetadataUpgradeable is KIP13Upgradeable, KIP17Upgradeable, IKIP17Metadata {
  // Token name
  string private _name;

  // Token symbol
  string private _symbol;

  /*
   *     bytes4(keccak256('name()')) == 0x06fdde03
   *     bytes4(keccak256('symbol()')) == 0x95d89b41
   *     bytes4(keccak256('tokenURI(uint256)')) == 0xc87b56dd
   *
   *     => 0x06fdde03 ^ 0x95d89b41 ^ 0xc87b56dd == 0x5b5e139f
   */
  bytes4 private constant _INTERFACE_ID_KIP17_METADATA = 0x5b5e139f;

  /**
   * @dev Constructor function
   */
  function __KIP17Metadata_init(string memory name, string memory symbol) public {
    _name = name;
    _symbol = symbol;

    // register the supported interfaces to conform to KIP17 via KIP13
    _registerInterface(_INTERFACE_ID_KIP17_METADATA);
    __KIP13_init();
  }

  /**
   * @dev Gets the token name.
   * @return string representing the token name
   */
  function name() external view returns (string memory) {
    return _name;
  }

  /**
   * @dev Gets the token symbol.
   * @return string representing the token symbol
   */
  function symbol() external view returns (string memory) {
    return _symbol;
  }
}
