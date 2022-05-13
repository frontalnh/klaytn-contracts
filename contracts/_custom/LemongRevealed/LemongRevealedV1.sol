// SPDX-License-Identifier: MIT

pragma solidity ^0.5.6;

import "../ownership/OwnableUpgradeable.sol";
import "../utils/ReentrancyGuardUpgradable.sol";
import "../oldproxy/Initializable.sol";
import "../KIP17/KIP17TokenAUpgradeable.sol";
import "../utils/Strings.sol";
import "../reveal/RevealableUpgradeable.sol";
import "./ILemongV1.sol";

contract LemongRevealedV1 is Initializable, OwnableUpgradeable, KIP17TokenAUpgradeable, ReentrancyGuardUpgradable, RevealableUpgradeable {
  using Strings for uint256;

  uint256 public maxBatchSize;
  address public lemongV1Contract;
  address public lemongV1ContractOwner;

  function initialize(
    string calldata name_,
    string calldata symbol_,
    uint256 maxBatchSize_,
    uint256 collectionSize_,
    address lemongV1Contract_,
    address lemongV1ContractOwner_
  ) external initializer {
    __Ownable_init();
    __KIP17TokenA_init(name_, symbol_, maxBatchSize_, collectionSize_);
    __ReentrancyGuard_init();
    maxBatchSize = maxBatchSize_;
    lemongV1Contract = lemongV1Contract_;
    lemongV1ContractOwner = lemongV1ContractOwner_;
  }

  modifier callerIsUser() {
    require(tx.origin == msg.sender, "The caller is another contract");
    _;
  }

  // metadata URI
  string private _baseTokenURI;

  function _baseURI() internal view returns (string memory) {
    return _baseTokenURI;
  }

  function setBaseURI(string calldata baseURI) external onlyOwner {
    _baseTokenURI = baseURI;
  }

  function withdrawMoney() external onlyOwner nonReentrant {
    (bool success, ) = msg.sender.call.value(address(this).balance)("");
    require(success, "Transfer failed.");
  }

  /**
   * @dev See {IKIP17Metadata-tokenURI}.
   */
  function tokenURI(uint256 tokenId) public view returns (string memory) {
    require(_exists(tokenId), "KIP17Metadata: URI query for nonexistent token");

    string memory baseURI = _baseURI();
    if (revealed) {
      baseURI = _revealURI;
    }
    return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json")) : "";
  }

  function setBatchSize(uint256 amount_) public onlyOwner {
    maxBatchSize = amount_;
    _updateBatchSize(amount_);
  }

  function setLemongContract(address contractAddress, address contractOwner) external onlyOwner {
    lemongV1Contract = contractAddress;
    lemongV1ContractOwner = contractOwner;
  }

  function swap(uint256[] calldata tokenIds) external callerIsUser {
    for (uint256 i = 0; i < tokenIds.length; i++) {
      uint256 tokenId = tokenIds[i];
      require(msg.sender == ILemongV1(lemongV1Contract).ownerOf(tokenId), "sender is not the owner of the token");
      ILemongV1(lemongV1Contract).safeTransferFrom(msg.sender, lemongV1ContractOwner, tokenId);
      _mint(msg.sender, tokenId);
    }
  }
}
