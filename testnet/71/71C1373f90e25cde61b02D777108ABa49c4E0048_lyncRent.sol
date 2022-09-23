// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

error PriceNotMet(address nftAddress, uint256 tokenId, uint256 price);
error ItemAlreadyRented(address nftAddress, uint256 tokenId);
error NotListedForRent(address nftAddress, uint256 tokenId);
error AlreadyListedForRent(address nftAddress, uint256 tokenId);
error ItemNotRentedByUser(address nftAddress, uint256 tokenId, address user);
error cantRentOwnedNfts(uint256 tokenId, address spender, address nftAddress);
error PriceMustBeAboveZero();
error NotOwner();
error DurationMustBeAtleastOneDay();
error DurationMustBeLessThanOrEqualTomaxRentDuration();

contract lyncRent is ReentrancyGuard {
    struct Listing {
        uint256 price;
        address seller;
        address renter;
        address nftContractAddress;
        uint256 tokenId;
        uint256 maxRentDuration;
        uint256 rentedDuration;
        bool isRented;
    }

    event ItemListedForRent(
        address indexed seller,
        address indexed nftAddress,
        uint256 indexed tokenId,
        uint256 pricePerDay,
        uint256 maxRentDuration
    );

    event ItemRented(
        address indexed renter,
        address indexed nftAddress,
        uint256 indexed tokenId,
        uint256 price,
        uint256 duration //no of days
    );

    event ItemReturned(
        address indexed renter,
        address indexed nftAddress,
        uint256 indexed tokenId,
        uint256 price,
        uint256 duration //no of days
    );

    event ItemDeListed(
        address indexed seller,
        address indexed nftAddress,
        uint256 indexed tokenId
    );

    mapping(address => mapping(uint256 => Listing))
        public allNftContractListings; //listings per nftaddress based on tokenids

    modifier notListedForRent(uint256 tokenId, address nftAddress) {
        Listing memory listing = allNftContractListings[nftAddress][tokenId];
        if (listing.price > 0) {
            revert AlreadyListedForRent(nftAddress, tokenId);
        }
        _;
    }
    modifier isCurrentlyRentedByUser(uint256 tokenId, address nftAddress) {
        Listing memory listing = allNftContractListings[nftAddress][tokenId];
        if (!listing.isRented || listing.renter != msg.sender) {
            revert ItemNotRentedByUser(nftAddress, tokenId, msg.sender);
        }
        _;
    }
    modifier notAlreadyRented(uint256 tokenId, address nftAddress) {
        Listing memory listing = allNftContractListings[nftAddress][tokenId];
        if (listing.isRented) {
            revert ItemAlreadyRented(nftAddress, tokenId);
        }
        _;
    }

    modifier isOwner(
        uint256 tokenId,
        address spender,
        address nftAddress
    ) {
        IERC721 nft = IERC721(nftAddress);
        address owner = nft.ownerOf(tokenId);
        if (spender != owner) {
            revert NotOwner();
        }
        _;
    }

    modifier isListedForRent(uint256 tokenId, address nftAddress) {
        Listing memory listing = allNftContractListings[nftAddress][tokenId];
        if (listing.price <= 0) {
            revert NotListedForRent(nftAddress, tokenId);
        }
        _;
    }

    function listItemForRent(
        uint256 tokenId,
        uint256 price,
        address nftAddress,
        uint256 maxRentDuration
    )
        external
        notListedForRent(tokenId, nftAddress)
        isOwner(tokenId, msg.sender, nftAddress)
    {
        if (price <= 0) {
            revert PriceMustBeAboveZero();
        }
        if (maxRentDuration < 1) {
            revert DurationMustBeAtleastOneDay();
        }
        allNftContractListings[nftAddress][tokenId] = Listing(
            price,
            msg.sender,
            address(0),
            nftAddress,
            tokenId,
            maxRentDuration,
            0,
            false
        );
        emit ItemListedForRent(
            msg.sender,
            nftAddress,
            tokenId,
            price,
            maxRentDuration
        );
    }

    function delistItemForRent(uint256 tokenId, address nftAddress)
        external
        isListedForRent(tokenId, nftAddress)
        isOwner(tokenId, msg.sender, nftAddress)
        notAlreadyRented(tokenId, nftAddress)
    {
        allNftContractListings[nftAddress][tokenId] = Listing(
            0,
            address(0),
            address(0),
            address(0),
            0,
            0,
            0,
            false
        );
        emit ItemDeListed(msg.sender, nftAddress, tokenId);
    }

    function rentItem(
        uint256 duration,
        address nftContractAddress,
        uint256 tokenId
    )
        external
        payable
        isListedForRent(tokenId, nftContractAddress)
        notAlreadyRented(tokenId, nftContractAddress)
    {
        Listing memory listing = allNftContractListings[nftContractAddress][
            tokenId
        ];
        if (duration > listing.maxRentDuration) {
            revert DurationMustBeLessThanOrEqualTomaxRentDuration();
        }
        if (msg.sender == listing.seller) {
            revert cantRentOwnedNfts(tokenId, msg.sender, nftContractAddress);
        }
        if (duration < 1) {
            revert DurationMustBeAtleastOneDay();
        }
        if (msg.value < listing.price * duration) {
            revert PriceNotMet(nftContractAddress, tokenId, listing.price);
        }
        allNftContractListings[nftContractAddress][tokenId] = Listing(
            listing.price,
            listing.seller,
            msg.sender,
            nftContractAddress,
            tokenId,
            listing.maxRentDuration,
            duration,
            true
        );
        (bool success, ) = payable(listing.seller).call{value: msg.value}("");
        require(success, "Failed to Send Ether");
        emit ItemRented(
            msg.sender,
            nftContractAddress,
            tokenId,
            listing.price * duration,
            duration
        );
    }

    function returnNftFromRent(address nftContractAddress, uint256 tokenId)
        external
        isCurrentlyRentedByUser(tokenId, nftContractAddress)
    {
        Listing memory listing = allNftContractListings[nftContractAddress][
            tokenId
        ];
        emit ItemReturned(
            msg.sender,
            nftContractAddress,
            tokenId,
            listing.price * listing.rentedDuration,
            listing.rentedDuration
        );
        allNftContractListings[nftContractAddress][tokenId] = Listing(
            listing.price,
            listing.seller,
            address(0),
            nftContractAddress,
            tokenId,
            listing.maxRentDuration,
            0,
            false
        );
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
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