pragma solidity ^0.5.0;

import "./KIP17FullUpgradeable.sol";
import "./KIP17MetadataMintableUpgradeable.sol";
import "./KIP17MintableUpgradeable.sol";
import "./KIP17BurnableUpgradeable.sol";
import "./KIP17EnumerableUpgradeable.sol";
import "./KIP17Upgradeable.sol";
import "./KIP17EnumerableUpgradeable.sol";
import "./KIP17MetadataUpgradeable.sol";

contract KIP17TokenAUpgradeable is
  KIP17Upgradeable,
  KIP17EnumerableUpgradeable,
  KIP17MetadataUpgradeable,
  KIP17MintableUpgradeable,
  KIP17BurnableUpgradeable,
{
  uint256 private currentIndex = 0;
  uint256 internal collectionSize;
  uint256 internal maxBatchSize;

  function __KIP17TokenA_init(
    string memory name,
    string memory symbol,
    uint256 maxBatchSize_,
    uint256 collectionSize_
  ) internal {
    __KIP17_init();
    __KIP17Enumerable_init();
    __KIP17Metadata_init(name, symbol);
    __KIP17Mintable_init();
    __KIP17Burnable_init();
    maxBatchSize = maxBatchSize_;
    collectionSize = collectionSize_;
  }

  /**
   * @dev Mints `quantity` tokens and transfers them to `to`.
   *
   * Requirements:
   *
   * - there must be `quantity` tokens remaining unminted in the total collection.
   * - `to` cannot be the zero address.
   * - `quantity` cannot be larger than the max batch size.
   *
   * Emits a {Transfer} event.
   */
  function _safeMint(address to, uint256 quantity) internal {
    uint256 startTokenId = currentIndex;
    require(to != address(0), "KIP17A: mint to the zero address");
    // We know if the first token in the batch doesn't exist, the other ones don't as well, because of serial ordering.
    require(!_exists(startTokenId), "KIP17A: token already minted");
    require(quantity <= maxBatchSize, "KIP17A: quantity to mint too high");
    require(collectionSize >= totalSupply() + quantity, "Can not mint over collection size");

    uint256 tokenId = startTokenId;

    for (uint256 i = 0; i < quantity; i++) {
      _mint(to, tokenId);
      tokenId++;
    }

    currentIndex = tokenId;
  }
}
