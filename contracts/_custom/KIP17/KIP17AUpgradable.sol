// SPDX-License-Identifier: MIT

pragma solidity ^0.5.6;

import "../../token/KIP17/IKIP17.sol";
import "./KIP17Upgradable.sol";
import "../../token/KIP17/IKIP17Receiver.sol";
import "../../token/KIP17/IKIP17Metadata.sol";
import "../../token/KIP17/IKIP17Enumerable.sol";
import "../../utils/Address.sol";
import "../../GSN/Context.sol";
import "../utils/Strings.sol";
import "../introspection/KIP13Upgradable.sol";
import "../oldproxy/Initializable.sol";
import "../reveal/RevealableUpgradeable.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[KIP17] Non-Fungible Token Standard, including
 * the Metadata and Enumerable extension. Built to optimize for lower gas during batch mints.
 *
 * Assumes serials are sequentially minted starting at 0 (e.g. 0, 1, 2, 3..).
 *
 * Assumes the number of issuable tokens (collection size) is capped and fits in a uint128.
 *
 * Does not support burning tokens to address(0).
 */
contract KIP17AUpgradable is Context, KIP13Upgradable, KIP17Upgradable, IKIP17Metadata, IKIP17Enumerable, Initializable, RevealableUpgradeable {
  using Address for address;
  using Strings for uint256;

  struct TokenOwnership {
    address addr;
    uint64 startTimestamp;
  }

  struct AddressData {
    uint128 balance;
    uint128 numberMinted;
  }

  uint256 private currentIndex = 0;

  uint256 internal collectionSize;
  uint256 internal maxBatchSize;

  // Token name
  string private _name;

  // Token symbol
  string private _symbol;

  // Mapping from token ID to ownership details
  // An empty struct value does not necessarily mean the token is unowned. See ownershipOf implementation for details.
  mapping(uint256 => TokenOwnership) private _ownerships;

  // Mapping owner address to address data
  mapping(address => AddressData) private _addressData;

  // Mapping from token ID to approved address
  mapping(uint256 => address) private _tokenApprovals;

  // Mapping from owner to operator approvals
  mapping(address => mapping(address => bool)) private _operatorApprovals;

  function __KIP17A_init(
    string memory name_,
    string memory symbol_,
    uint256 maxBatchSize_,
    uint256 collectionSize_
  ) internal initializer {
    require(collectionSize_ > 0, "KIP17A: collection must have a nonzero supply");
    require(maxBatchSize_ > 0, "KIP17A: max batch size must be nonzero");
    __KIP13_init();
    __KIP17_init();
    _name = name_;
    _symbol = symbol_;
    maxBatchSize = maxBatchSize_;
    collectionSize = collectionSize_;
  }

  /**
   * @dev See {IKIP17Enumerable-totalSupply}.
   */
  function totalSupply() public view returns (uint256) {
    return currentIndex;
  }

  /**
   * @dev See {IKIP17Enumerable-tokenByIndex}.
   */
  function tokenByIndex(uint256 index) public view returns (uint256) {
    require(index < totalSupply(), "KIP17A: global index out of bounds");
    return index;
  }

  /**
   * @dev See {IKIP17Enumerable-tokenOfOwnerByIndex}.
   * This read function is O(collectionSize). If calling from a separate contract, be sure to test gas first.
   * It may also degrade with extremely large collection sizes (e.g >> 10000), test for your use case.
   */
  function tokenOfOwnerByIndex(address owner, uint256 index) public view returns (uint256) {
    require(index < balanceOf(owner), "KIP17A: owner index out of bounds");
    uint256 numMintedSoFar = totalSupply();
    uint256 tokenIdsIdx = 0;
    address currOwnershipAddr = address(0);
    for (uint256 i = 0; i < numMintedSoFar; i++) {
      TokenOwnership memory ownership = _ownerships[i];
      if (ownership.addr != address(0)) {
        currOwnershipAddr = ownership.addr;
      }
      if (currOwnershipAddr == owner) {
        if (tokenIdsIdx == index) {
          return i;
        }
        tokenIdsIdx++;
      }
    }
    revert("KIP17A: unable to get token of owner by index");
  }

  /**
   * @dev See {IKIP17-balanceOf}.
   */
  function balanceOf(address owner) public view returns (uint256) {
    require(owner != address(0), "KIP17A: balance query for the zero address");
    return uint256(_addressData[owner].balance);
  }

  function _numberMinted(address owner) internal view returns (uint256) {
    require(owner != address(0), "KIP17A: number minted query for the zero address");
    return uint256(_addressData[owner].numberMinted);
  }

  function ownershipOf(uint256 tokenId) internal view returns (TokenOwnership memory) {
    require(_exists(tokenId), "KIP17A: owner query for nonexistent token");

    uint256 lowestTokenToCheck;
    if (tokenId >= maxBatchSize) {
      lowestTokenToCheck = tokenId - maxBatchSize + 1;
    }

    for (uint256 curr = tokenId; curr >= lowestTokenToCheck; curr--) {
      TokenOwnership memory ownership = _ownerships[curr];
      if (ownership.addr != address(0)) {
        return ownership;
      }
    }

    revert("KIP17A: unable to determine the owner of token");
  }

  /**
   * @dev See {IKIP17-ownerOf}.
   */
  function ownerOf(uint256 tokenId) public view returns (address) {
    return ownershipOf(tokenId).addr;
  }

  /**
   * @dev See {IKIP17Metadata-name}.
   */
  function name() public view returns (string memory) {
    return _name;
  }

  /**
   * @dev See {IKIP17Metadata-symbol}.
   */
  function symbol() public view returns (string memory) {
    return _symbol;
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

  /**
   * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
   * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
   * by default, can be n in child contracts.
   */
  function _baseURI() internal view returns (string memory) {
    return "";
  }

  /**
   * @dev See {IKIP17-approve}.
   */
  function approve(address to, uint256 tokenId) public {
    address owner = KIP17AUpgradable.ownerOf(tokenId);
    require(to != owner, "KIP17A: approval to current owner");

    require(_msgSender() == owner || isApprovedForAll(owner, _msgSender()), "KIP17A: approve caller is not owner nor approved for all");

    _approve(to, tokenId, owner);
  }

  /**
   * @dev See {IKIP17-getApproved}.
   */
  function getApproved(uint256 tokenId) public view returns (address) {
    require(_exists(tokenId), "KIP17A: approved query for nonexistent token");

    return _tokenApprovals[tokenId];
  }

  /**
   * @dev See {IKIP17-setApprovalForAll}.
   */
  function setApprovalForAll(address operator, bool approved) public {
    require(operator != _msgSender(), "KIP17A: approve to caller");

    _operatorApprovals[_msgSender()][operator] = approved;
    emit ApprovalForAll(_msgSender(), operator, approved);
  }

  /**
   * @dev See {IKIP17-isApprovedForAll}.
   */
  function isApprovedForAll(address owner, address operator) public view returns (bool) {
    return _operatorApprovals[owner][operator];
  }

  /**
   * @dev See {IKIP17-transferFrom}.
   */
  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public {
    _transfer(from, to, tokenId);
  }

  /**
   * @dev See {IKIP17-safeTransferFrom}.
   */
  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public {
    safeTransferFrom(from, to, tokenId, "");
  }

  /**
   * @dev See {IKIP17-safeTransferFrom}.
   */
  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes memory _data
  ) public {
    _transfer(from, to, tokenId);
    require(_checkOnKIP17Received(from, to, tokenId, _data), "KIP17A: transfer to non KIP17Receiver implementer");
  }

  /**
   * @dev Returns whether `tokenId` exists.
   *
   * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
   *
   * Tokens start existing when they are minted (`_mint`),
   */
  function _exists(uint256 tokenId) internal view returns (bool) {
    return tokenId < currentIndex;
  }

  function _safeMint(address to, uint256 quantity) internal {
    _safeMint(to, quantity, "");
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
  function _safeMint(
    address to,
    uint256 quantity,
    bytes memory _data
  ) internal {
    uint256 startTokenId = currentIndex;
    require(to != address(0), "KIP17A: mint to the zero address");
    // We know if the first token in the batch doesn't exist, the other ones don't as well, because of serial ordering.
    require(!_exists(startTokenId), "KIP17A: token already minted");
    require(quantity <= maxBatchSize, "KIP17A: quantity to mint too high");

    AddressData memory addressData = _addressData[to];
    _addressData[to] = AddressData(addressData.balance + uint128(quantity), addressData.numberMinted + uint128(quantity));
    _ownerships[startTokenId] = TokenOwnership(to, uint64(block.timestamp));

    uint256 updatedIndex = startTokenId;

    for (uint256 i = 0; i < quantity; i++) {
      emit Transfer(address(0), to, updatedIndex);
      require(_checkOnKIP17Received(address(0), to, updatedIndex, _data), "KIP17A: transfer to non KIP17Receiver implementer");
      updatedIndex++;
    }

    currentIndex = updatedIndex;
  }

  /**
   * @dev Transfers `tokenId` from `from` to `to`.
   *
   * Requirements:
   *
   * - `to` cannot be the zero address.
   * - `tokenId` token must be owned by `from`.
   *
   * Emits a {Transfer} event.
   */
  function _transfer(
    address from,
    address to,
    uint256 tokenId
  ) private {
    TokenOwnership memory prevOwnership = ownershipOf(tokenId);

    bool isApprovedOrOwner = (_msgSender() == prevOwnership.addr ||
      getApproved(tokenId) == _msgSender() ||
      isApprovedForAll(prevOwnership.addr, _msgSender()));

    require(isApprovedOrOwner, "KIP17A: transfer caller is not owner nor approved");

    require(prevOwnership.addr == from, "KIP17A: transfer from incorrect owner");
    require(to != address(0), "KIP17A: transfer to the zero address");

    // Clear approvals from the previous owner
    _approve(address(0), tokenId, prevOwnership.addr);

    _addressData[from].balance -= 1;
    _addressData[to].balance += 1;
    _ownerships[tokenId] = TokenOwnership(to, uint64(block.timestamp));

    // If the ownership slot of tokenId+1 is not explicitly set, that means the transfer initiator owns it.
    // Set the slot of tokenId+1 explicitly in storage to maintain correctness for ownerOf(tokenId+1) calls.
    uint256 nextTokenId = tokenId + 1;
    if (_ownerships[nextTokenId].addr == address(0)) {
      if (_exists(nextTokenId)) {
        _ownerships[nextTokenId] = TokenOwnership(prevOwnership.addr, prevOwnership.startTimestamp);
      }
    }

    emit Transfer(from, to, tokenId);
  }

  /**
   * @dev Approve `to` to operate on `tokenId`
   *
   * Emits a {Approval} event.
   */
  function _approve(
    address to,
    uint256 tokenId,
    address owner
  ) private {
    _tokenApprovals[tokenId] = to;
    emit Approval(owner, to, tokenId);
  }

  uint256 public nextOwnerToExplicitlySet = 0;

  /**
   * @dev Explicitly set `owners` to eliminate loops in future calls of ownerOf().
   */
  function _setOwnersExplicit(uint256 quantity) internal {
    uint256 oldNextOwnerToSet = nextOwnerToExplicitlySet;
    require(quantity > 0, "quantity must be nonzero");
    uint256 endIndex = oldNextOwnerToSet + quantity - 1;
    if (endIndex > collectionSize - 1) {
      endIndex = collectionSize - 1;
    }
    // We know if the last one in the group exists, all in the group exist, due to serial ordering.
    require(_exists(endIndex), "not enough minted yet for this cleanup");
    for (uint256 i = oldNextOwnerToSet; i <= endIndex; i++) {
      if (_ownerships[i].addr == address(0)) {
        TokenOwnership memory ownership = ownershipOf(i);
        _ownerships[i] = TokenOwnership(ownership.addr, ownership.startTimestamp);
      }
    }
    nextOwnerToExplicitlySet = endIndex + 1;
  }
}
