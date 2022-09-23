//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "ReentrancyGuard.sol";
import "IERC721.sol";
import "IERC721Receiver.sol";
import "Counters.sol";
import "Ownable.sol";

contract NFTMarket is Ownable, ReentrancyGuard, IERC721Receiver {
    using Counters for Counters.Counter;
    Counters.Counter private _itemIds;
    Counters.Counter private _itemsAdded;
    Counters.Counter private _itemsSold;
    address[] private _supportedNFTContract;

    uint256 listingFee = 0.001 ether;
    mapping(uint256 => MarketItem) private _itemIdToMarketItem;
    mapping(address => mapping(uint256 => uint256))
        private _contractTokenIdToItemId;

    struct MarketItem {
        uint256 itemId;
        address nftContract;
        uint256 tokenId;
        address seller;
        address owner;
        uint256 price;
    }

    event MarketItemCreated(
        uint256 indexed itemId,
        address indexed nftContract,
        uint256 indexed tokenId,
        address seller,
        address owner,
        uint256 price
    );

    event ItemSold(
        uint256 indexed itemId,
        address indexed nftContract,
        uint256 indexed tokenId,
        address seller,
        address owner,
        uint256 price
    );

    event ItemRemoved(
        uint256 indexed itemId,
        address indexed nftContract,
        uint256 indexed tokenId,
        address seller,
        address owner,
        uint256 price
    );

    event ItemPriceUpdated(
        uint256 indexed itemId,
        address indexed nftContract,
        uint256 indexed tokenId,
        address seller,
        address owner,
        uint256 oldPrice,
        uint256 newPrice
    );

    constructor(address owner) Ownable(owner) {}

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function updateListingFee(uint256 newListingFee) public onlyOwner {
        listingFee = newListingFee;
    }

    function getListingFee() public view returns (uint256) {
        return listingFee;
    }

    function withdrawListingFee() public payable nonReentrant onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function addSupportedNFTContract(address nftContract) public onlyOwner {
        for (uint256 index = 0; index < _supportedNFTContract.length; index++) {
            require(
                nftContract != _supportedNFTContract[index],
                "This NFT contract already supported"
            );
        }
        _supportedNFTContract.push(nftContract);
    }

    function removeSupportedNFTContract(address nftContract) public onlyOwner {
        bool isFoundContract = false;
        uint256 index = 0;
        uint256 totalContract = _supportedNFTContract.length;
        for (index = 0; index < totalContract; index++) {
            if (_supportedNFTContract[index] == nftContract) {
                isFoundContract = true;
                break;
            }
        }
        require(isFoundContract, "NFT contract is not supported");
        _supportedNFTContract[index] = _supportedNFTContract[totalContract - 1];
        _supportedNFTContract.pop();
    }

    function getSupportedNFTContract() public view returns (address[] memory) {
        return _supportedNFTContract;
    }

    function addItemToMarket(
        address nftContract,
        uint256 tokenId,
        uint256 price
    ) public payable nonReentrant {
        require(price > 0, "Price must be at least 1 wei");
        require(
            msg.value == listingFee,
            "Price must be equal to listing price"
        );
        bool isSupportedContract = false;
        for (uint256 index = 0; index < _supportedNFTContract.length; index++) {
            if (nftContract == _supportedNFTContract[index]) {
                isSupportedContract = true;
                break;
            }
        }
        require(isSupportedContract, "NFT contract is not supported");
        uint256 itemId = 0;
        MarketItem storage marketItem = _itemIdToMarketItem[
            _contractTokenIdToItemId[nftContract][tokenId]
        ];
        if (marketItem.itemId > 0) {
            itemId = marketItem.itemId;
            marketItem.seller = msg.sender;
            marketItem.owner = address(this);
            marketItem.price = price;
        } else {
            _itemIds.increment();
            itemId = _itemIds.current();
            _itemIdToMarketItem[itemId] = MarketItem(
                itemId,
                nftContract,
                tokenId,
                msg.sender,
                address(this),
                price
            );
            _contractTokenIdToItemId[nftContract][tokenId] = itemId;
        }
        _itemsAdded.increment();
        IERC721(nftContract).safeTransferFrom(
            msg.sender,
            address(this),
            tokenId
        );

        emit MarketItemCreated(
            itemId,
            nftContract,
            tokenId,
            msg.sender,
            address(this),
            price
        );
    }

    function sellItemAndTransferOwnership(uint256 itemId)
        public
        payable
        nonReentrant
    {
        MarketItem storage marketItem = _itemIdToMarketItem[itemId];
        require(itemId > 0, "Item id does not exist");
        require(marketItem.itemId == itemId, "Item id does not exist");
        uint256 price = marketItem.price;
        uint256 tokenId = marketItem.tokenId;
        address nftContract = marketItem.nftContract;
        require(
            msg.value == price,
            "Please submit the asking price in order to complete the purchase"
        );
        payable(marketItem.seller).transfer(msg.value);
        IERC721(nftContract).transferFrom(address(this), msg.sender, tokenId);
        marketItem.seller = msg.sender;
        marketItem.owner = msg.sender;
        _itemsSold.increment();
        emit ItemSold(
            itemId,
            nftContract,
            tokenId,
            marketItem.seller,
            msg.sender,
            price
        );
    }

    function removeItemFromMarket(uint256 itemId) public nonReentrant {
        MarketItem storage marketItem = _itemIdToMarketItem[itemId];
        require(itemId > 0, "Item id does not exist");
        require(marketItem.itemId == itemId, "Item id does not exist");
        require(marketItem.owner == address(this), "The item is not selling");
        require(
            marketItem.seller == msg.sender,
            "You are not the owner of this item"
        );
        IERC721(marketItem.nftContract).transferFrom(
            address(this),
            msg.sender,
            marketItem.tokenId
        );
        marketItem.owner = msg.sender;
        _itemsAdded.decrement();
        emit ItemRemoved(
            itemId,
            marketItem.nftContract,
            marketItem.tokenId,
            marketItem.seller,
            msg.sender,
            marketItem.price
        );
    }

    function updateItemPrice(uint256 itemId, uint256 price) public {
        MarketItem storage marketItem = _itemIdToMarketItem[itemId];
        require(itemId > 0, "Item id does not exist");
        require(marketItem.itemId == itemId, "Item id does not exist");
        require(price > 0, "Price must be at least 1 wei");
        require(marketItem.owner == address(this), "The item is not selling");
        require(
            marketItem.seller == msg.sender,
            "Caller is not the owner of this item"
        );
        uint256 oldPrice = marketItem.price;
        marketItem.price = price;
        emit ItemPriceUpdated(
            itemId,
            marketItem.nftContract,
            marketItem.tokenId,
            msg.sender,
            address(this),
            oldPrice,
            price
        );
    }

    function getMarketItemByItemId(uint256 itemId)
        public
        view
        returns (MarketItem memory)
    {
        return _itemIdToMarketItem[itemId];
    }

    function getMarketItemByContractTokenId(
        address nftContract,
        uint256 tokenId
    ) public view returns (MarketItem memory) {
        return
            _itemIdToMarketItem[_contractTokenIdToItemId[nftContract][tokenId]];
    }

    function getMarketItems() public view returns (MarketItem[] memory) {
        uint256 itemCount = _itemsAdded.current();
        uint256 unsoldItemCount = _itemsAdded.current() - _itemsSold.current();
        uint256 currentIndex = 0;

        MarketItem[] memory items = new MarketItem[](unsoldItemCount);
        for (uint256 i = 0; i < itemCount; i++) {
            uint256 currentId = i + 1;
            if (_itemIdToMarketItem[currentId].owner == address(this)) {
                MarketItem memory currentItem = _itemIdToMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }

    function getMarketItemsOf(address owner)
        public
        view
        returns (MarketItem[] memory)
    {
        uint256 totalItemCount = _itemIds.current();
        uint256 itemCount = 0;

        for (uint256 i = 0; i < totalItemCount; i++) {
            if (
                _itemIdToMarketItem[i + 1].seller == owner &&
                _itemIdToMarketItem[i + 1].owner == address(this)
            ) {
                itemCount += 1;
            }
        }
        MarketItem[] memory items = new MarketItem[](itemCount);
        uint256 currentIndex = 0;
        for (uint256 i = 0; i < totalItemCount; i++) {
            uint256 currentId = i + 1;
            if (
                _itemIdToMarketItem[currentId].seller == owner &&
                _itemIdToMarketItem[currentId].owner == address(this)
            ) {
                items[currentIndex] = _itemIdToMarketItem[currentId];
                currentIndex += 1;
            }
        }

        return items;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract Ownable {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor(address owner) {
        _transferOwnership(owner);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == _owner, "Caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "New owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function getOwner() public view virtual returns (address) {
        return _owner;
    }
}