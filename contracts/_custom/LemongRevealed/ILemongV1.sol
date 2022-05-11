// SPDX-License-Identifier: MIT

pragma solidity ^0.5.6;

contract ILemongV1 {
  function ownerOf(uint256 tokenId) public view returns (address) {}

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public {}
}
