pragma solidity ^0.5.0;

import "./KIP17BurnableUpgradeable.sol";
import "./KIP17EnumerableUpgradeable.sol";
import "./KIP17Upgradeable.sol";
import "./KIP17EnumerableUpgradeable.sol";

contract KIP17TokenAUpgradeable is KIP17Upgradeable, KIP17EnumerableUpgradeable, KIP17BurnableUpgradeable {
  // Token name
  string private _name;

  // Token symbol
  string private _symbol;
  uint256 private currentIndex = 0;
  uint256 internal collectionSize;
  uint256 internal maxBatchSize;
  bytes4 private constant _INTERFACE_ID_KIP17_METADATA = 0x5b5e139f;

  function __KIP17TokenA_init(
    string memory name,
    string memory symbol,
    uint256 maxBatchSize_,
    uint256 collectionSize_
  ) internal {
    __KIP17_init();
    __KIP17Enumerable_init();
    _name = name;
    _symbol = symbol;

    // register the supported interfaces to conform to KIP17 via KIP13
    _registerInterface(_INTERFACE_ID_KIP17_METADATA);
    __KIP13_init();
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
      tokenId++; // token ID for next mint
    }

    currentIndex = tokenId;
  }

  /**
   * @dev Gets the token name.
   * @return string representing the token name
   */
  function name() external view returns (string memory) {
    return _name;
  }

  /**
   * @dev Gets the token symbol.
   * @return string representing the token symbol
   */
  function symbol() external view returns (string memory) {
    return _symbol;
  }

  function _updateBatchSize(uint256 amount) internal {
    maxBatchSize = amount;
  }
}
