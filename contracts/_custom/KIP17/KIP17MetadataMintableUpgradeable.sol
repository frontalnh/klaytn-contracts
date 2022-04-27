pragma solidity ^0.5.0;

import "../../token/KIP17/KIP17Metadata.sol";
import "../access/roles/MinterRoleUpgradeable.sol";
import "../introspection/KIP13Upgradeable.sol";
import "./KIP17Upgradeable.sol";
import "./KIP17MetadataUpgradeable.sol";

/**
 * @title KIP17MetadataMintable
 * @dev KIP17 minting logic with metadata.
 */
contract KIP17MetadataMintableUpgradeable is KIP13Upgradeable, KIP17Upgradeable, KIP17MetadataUpgradeable, MinterRoleUpgradeable {
  /*
   *     bytes4(keccak256('mintWithTokenURI(address,uint256,string)')) == 0x50bb4e7f
   *     bytes4(keccak256('isMinter(address)')) == 0xaa271e1a
   *     bytes4(keccak256('addMinter(address)')) == 0x983b2d56
   *     bytes4(keccak256('renounceMinter()')) == 0x98650275
   *
   *     => 0x50bb4e7f ^ 0xaa271e1a ^ 0x983b2d56 ^ 0x98650275 == 0xfac27f46
   */
  bytes4 private constant _INTERFACE_ID_KIP17_METADATA_MINTABLE = 0xfac27f46;

  /**
   * @dev Constructor function.
   */
  function __KIP17MetadataMintable_init() public {
    // register the supported interface to conform to KIP17Mintable via KIP13
    _registerInterface(_INTERFACE_ID_KIP17_METADATA_MINTABLE);
    __KIP13_init();
    __KIP17_init();
    __MinterRole_init();
  }
}
