pragma solidity ^0.5.6;

contract RevealableUpgradeable {
  bool public revealed = false;
  string internal _revealURI;

  function reveal() public {
    revealed = true;
  }

  function setRevealURI(string memory uri) public {
    _revealURI = uri;
  }
}
