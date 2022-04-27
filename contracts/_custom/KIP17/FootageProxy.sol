pragma solidity ^0.5.6;

import "../../token/KIP17/IKIP17.sol";
import "../oldproxy/TransparentUpgradeableProxy.sol";

contract FootageProxy is TransparentUpgradeableProxy {
  constructor(address _logic, address _admin) public TransparentUpgradeableProxy(_logic, _admin, "") {}
}
