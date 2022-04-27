pragma solidity ^0.5.0;

import "./KIP17Upgradeable.sol";
import "../lifecycle/PausableUpgradeable.sol";
import "../introspection/KIP13Upgradeable.sol";

/**
 * @title KIP17 Non-Fungible Pausable token
 * @dev KIP17 modified with pausable transfers.
 */
contract KIP17PausableUpgradeable is KIP13Upgradeable, KIP17Upgradeable, PausableUpgradeable {
  /*
   *     bytes4(keccak256('paused()')) == 0x5c975abb
   *     bytes4(keccak256('pause()')) == 0x8456cb59
   *     bytes4(keccak256('unpause()')) == 0x3f4ba83a
   *     bytes4(keccak256('isPauser(address)')) == 0x46fbf68e
   *     bytes4(keccak256('addPauser(address)')) == 0x82dc1ec4
   *     bytes4(keccak256('renouncePauser()')) == 0x6ef8d66d
   *
   *     => 0x5c975abb ^ 0x8456cb59 ^ 0x3f4ba83a ^ 0x46fbf68e ^ 0x82dc1ec4 ^ 0x6ef8d66d == 0x4d5507ff
   */
  bytes4 private constant _INTERFACE_ID_KIP17_PAUSABLE = 0x4d5507ff;

  /**
   * @dev Constructor function.
   */
  function __KIP17Pausable_init() public {
    // register the supported interface to conform to KIP17Pausable via KIP13
    _registerInterface(_INTERFACE_ID_KIP17_PAUSABLE);
  }

  function approve(address to, uint256 tokenId) public whenNotPaused {
    super.approve(to, tokenId);
  }

  function setApprovalForAll(address to, bool approved) public whenNotPaused {
    super.setApprovalForAll(to, approved);
  }

  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public whenNotPaused {
    super.transferFrom(from, to, tokenId);
  }
}
