pragma solidity ^0.5.0;

import "../ownership/OwnableUpgradeable.sol";

contract SelfDestructibleUpgradeable is OwnableUpgradeable {
  function destroy() public onlyOwner {
    selfdestruct(owner());
  }
}
