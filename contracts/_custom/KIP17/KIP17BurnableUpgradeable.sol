pragma solidity ^0.5.0;

import "./KIP17Upgradeable.sol";
import "../introspection/KIP13Upgradeable.sol";

/**
 * @title KIP17 Burnable Token
 * @dev KIP17 Token that can be irreversibly burned (destroyed).
 * See http://kips.klaytn.com/KIPs/kip-17-non_fungible_token
 */
contract KIP17BurnableUpgradeable is KIP13Upgradeable, KIP17Upgradeable {
  /*
   *     bytes4(keccak256('burn(uint256)')) == 0x42966c68
   *
   *     => 0x42966c68 == 0x42966c68
   */
  bytes4 private constant _INTERFACE_ID_KIP17_BURNABLE = 0x42966c68;

  /**
   * @dev Constructor function.
   */
  function __KIP17Burnable_init() internal {
    // register the supported interface to conform to KIP17Burnable via KIP13
    _registerInterface(_INTERFACE_ID_KIP17_BURNABLE);
    __KIP13_init();
    __KIP17_init();
  }

  /**
   * @dev Burns a specific KIP17 token.
   * @param tokenId uint256 id of the KIP17 token to be burned.
   */
  function burn(uint256 tokenId) public {
    //solhint-disable-next-line max-line-length
    require(_isApprovedOrOwner(msg.sender, tokenId), "KIP17Burnable: caller is not owner nor approved");
    _burn(tokenId);
  }
}
