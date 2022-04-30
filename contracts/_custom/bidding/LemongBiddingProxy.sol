pragma solidity ^0.5.6;

import "../../ownership/Ownable.sol";
import "../../token/KIP17/IKIP17.sol";
import "../oldproxy/TransparentUpgradeableProxy.sol";

contract LemongBiddingProxy is TransparentUpgradeableProxy {
  constructor(address _logic, address _admin) public TransparentUpgradeableProxy(_logic, _admin, "") {}
}
