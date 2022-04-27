import "../ownership/OwnableUpgradeable.sol";
pragma solidity ^0.5.6;

contract RevealableUpgradeable is OwnableUpgradeable {
  bool public revealed = false;
  string internal _revealURI;

  function reveal() public {
    revealed = true;
  }

  function __Revealable_init() public {
    __Ownable_init();
  }

  function setRevealURI(string memory uri) public {
    _revealURI = uri;
  }
}
