// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

pragma abicoder v2;

import "../openzeppelin-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "../openzeppelin-upgradeable/access/OwnableUpgradeable.sol";

import "../securitize/WhitelistableUpgradeable.sol";

import "../royalties/IRoyaltiesProvider.sol";
import "../royalties/LibRoyalties2981.sol";
import "../royalties/LibRoyaltiesV1.sol";
import "../royalties/LibRoyaltiesV2.sol";
import "../royalties/RoyaltiesV1.sol";
import "../royalties/RoyaltiesV2.sol";
import "../royalties/IERC2981.sol";

contract RoyaltiesRegistry is
    IRoyaltiesProvider,
    OwnableUpgradeable,
    WhitelistableUpgradeable
{
    /// @dev deprecated
    event RoyaltiesSetForToken(
        address indexed token,
        uint256 indexed tokenId,
        LibPart.Part[] royalties
    );

    /// @dev emitted when royalties set for token in
    event RoyaltiesSetForContract(
        address indexed token,
        LibPart.Part[] royalties
    );

    /// @dev struct to store royalties in royaltiesByToken
    struct RoyaltiesSet {
        bool initialized;
        LibPart.Part[] royalties;
    }

    /// @dev deprecated
    mapping(bytes32 => RoyaltiesSet) public royaltiesByTokenAndTokenId;
    /// @dev stores royalties for token contract, set in setRoyaltiesByToken() method
    mapping(address => RoyaltiesSet) public royaltiesByToken;
    /// @dev stores external provider and royalties type for token contract
    mapping(address => uint256) public royaltiesProviders;

    /// @dev total amount or supported royalties types
    // 0 - royalties type is unset
    // 1 - royaltiesByToken, 2 - v2, 3 - v1,
    // 4 - external provider, 5 - EIP-2981
    // 6 - unsupported/nonexistent royalties type
    uint256 internal constant ROYALTIES_TYPES_AMOUNT = 6;

    function __RoyaltiesRegistry_init(
        address securitizeRegistryProxy,
        address contractsRegistryProxy
    ) external initializer {
        __Ownable_init_unchained();
        __Whitelistable_init_unchained(
            securitizeRegistryProxy,
            contractsRegistryProxy
        );
    }

    /// @dev sets external provider for token contract, and royalties type = 4
    function setProviderByToken(address token, address provider) public {
        onlyWhitelistedAddress(_msgSender());

        checkOwner(token);

        setRoyaltiesType(token, 4, provider);
    }

    /// @dev returns provider address for token contract from royaltiesProviders mapping
    function getProvider(address token) public view returns (address) {
        return address(uint160(royaltiesProviders[token]));
    }

    /// @dev returns royalties type for token contract
    function getRoyaltiesType(address token) external view returns (uint256) {
        return _getRoyaltiesType(royaltiesProviders[token]);
    }

    /// @dev returns royalties type from uint
    function _getRoyaltiesType(uint256 data) internal pure returns (uint256) {
        for (uint256 i = 1; i <= ROYALTIES_TYPES_AMOUNT; i++) {
            if (data / 2**(256 - i) == 1) {
                return i;
            }
        }

        return 0;
    }

    /// @dev sets royalties type for token contract
    function setRoyaltiesType(
        address token,
        uint256 royaltiesType,
        address royaltiesProvider
    ) internal {
        require(
            royaltiesType > 0 && royaltiesType <= ROYALTIES_TYPES_AMOUNT,
            "RoyaltiesRegistry: wrong royaltiesType"
        );

        royaltiesProviders[token] =
            uint256(uint160(royaltiesProvider)) +
            2**(256 - royaltiesType);
    }

    /// @dev clears and sets new royalties type for token contract
    function forceSetRoyaltiesType(address token, uint256 royaltiesType)
        public
    {
        onlyWhitelistedAddress(_msgSender());

        checkOwner(token);

        setRoyaltiesType(token, royaltiesType, getProvider(token));
    }

    /// @dev clears royalties type for token contract
    function clearRoyaltiesType(address token) public {
        onlyWhitelistedAddress(_msgSender());

        checkOwner(token);

        royaltiesProviders[token] = uint256(uint160(getProvider(token)));
    }

    /// @dev sets royalties for token contract in royaltiesByToken mapping and royalties type = 1
    function setRoyaltiesByToken(address token, LibPart.Part[] memory royalties)
        public
    {
        onlyWhitelistedAddress(_msgSender());

        checkOwner(token);

        // Clearing royaltiesProviders value for the token
        delete royaltiesProviders[token];

        // Setting royaltiesType = 1 for the token
        setRoyaltiesType(token, 1, address(0));

        uint256 sumRoyalties = 0;

        delete royaltiesByToken[token];

        for (uint256 i = 0; i < royalties.length; i++) {
            require(
                royalties[i].account != address(0),
                "RoyaltiesRegistry: royaltiesByToken recipient should be present"
            );
            require(
                royalties[i].value != 0,
                "RoyaltiesRegistry: royalty value for royaltiesByToken should be > 0"
            );

            royaltiesByToken[token].royalties.push(royalties[i]);

            sumRoyalties += royalties[i].value;
        }

        require(
            sumRoyalties < 10000,
            "RoyaltiesRegistry: set by token royalties sum more, than 100%"
        );

        royaltiesByToken[token].initialized = true;

        emit RoyaltiesSetForContract(token, royalties);
    }

    /// @dev checks if msg.sender is owner of this contract or owner of the token contract
    function checkOwner(address token) internal view {
        if (
            (owner() != _msgSender()) &&
            (OwnableUpgradeable(token).owner() != _msgSender())
        ) {
            revert("RoyaltiesRegistry: token owner not detected");
        }
    }

    /// @dev calculates royalties type for token contract
    function calculateRoyaltiesType(address token, address royaltiesProvider)
        internal
        view
        returns (uint256)
    {
        try
            IERC165Upgradeable(token).supportsInterface(
                LibRoyaltiesV2._INTERFACE_ID_ROYALTIES
            )
        returns (bool result) {
            if (result) {
                return 2;
            }
        } catch {}

        try
            IERC165Upgradeable(token).supportsInterface(
                LibRoyaltiesV1._INTERFACE_ID_FEES
            )
        returns (bool result) {
            if (result) {
                return 3;
            }
        } catch {}

        try
            IERC165Upgradeable(token).supportsInterface(
                LibRoyalties2981._INTERFACE_ID_ROYALTIES
            )
        returns (bool result) {
            if (result) {
                return 5;
            }
        } catch {}

        if (royaltiesProvider != address(0)) {
            return 4;
        }

        if (royaltiesByToken[token].initialized) {
            return 1;
        }

        return 6;
    }

    /// @dev returns royalties for token contract and token id
    function getRoyalties(address token, uint256 tokenId)
        public
        override
        returns (LibPart.Part[] memory)
    {
        onlyWhitelistedAddress(_msgSender());

        uint256 royaltiesProviderData = royaltiesProviders[token];
        address royaltiesProvider = address(uint160(royaltiesProviderData));
        uint256 royaltiesType = _getRoyaltiesType(royaltiesProviderData);

        // Case when royaltiesType is not set
        if (royaltiesType == 0) {
            // Calculating royalties type for token
            royaltiesType = calculateRoyaltiesType(token, royaltiesProvider);

            // Saving royalties type
            setRoyaltiesType(token, royaltiesType, royaltiesProvider);
        }

        // Case royaltiesType = 1, royalties are set in royaltiesByToken
        if (royaltiesType == 1) {
            return royaltiesByToken[token].royalties;
        }

        // Case royaltiesType = 2, royalties BridgeTower v2
        if (royaltiesType == 2) {
            return getRoyaltiesBridgeTowerV2(token, tokenId);
        }

        // Case royaltiesType = 3, royalties BridgeTower v1
        if (royaltiesType == 3) {
            return getRoyaltiesBridgeTowerV1(token, tokenId);
        }

        // Case royaltiesType = 4, royalties from external provider
        if (royaltiesType == 4) {
            return providerExtractor(token, tokenId, royaltiesProvider);
        }

        // Case royaltiesType = 5, royalties EIP-2981
        if (royaltiesType == 5) {
            return getRoyaltiesEIP2981(token, tokenId);
        }

        // Case royaltiesType = 6, unknown/empty royalties
        if (royaltiesType == 6) {
            return new LibPart.Part[](0);
        }

        revert("RoyaltiesRegistry: something wrong in getRoyalties");
    }

    /// @dev tries to get royalties BridgeTower v2 for token and tokenId
    function getRoyaltiesBridgeTowerV2(address token, uint256 tokenId)
        internal
        view
        returns (LibPart.Part[] memory)
    {
        try RoyaltiesV2(token).getBridgeTowerV2Royalties(tokenId) returns (
            LibPart.Part[] memory result
        ) {
            return result;
        } catch {
            return new LibPart.Part[](0);
        }
    }

    /// @dev tries to get royalties BridgeTower v1 for token and tokenId
    function getRoyaltiesBridgeTowerV1(address token, uint256 tokenId)
        internal
        view
        returns (LibPart.Part[] memory)
    {
        RoyaltiesV1 v1 = RoyaltiesV1(token);

        address payable[] memory recipients;

        try v1.getFeeRecipients(tokenId) returns (
            address payable[] memory resultRecipients
        ) {
            recipients = resultRecipients;
        } catch {
            return new LibPart.Part[](0);
        }

        uint256[] memory values;

        try v1.getFeeBps(tokenId) returns (uint256[] memory resultValues) {
            values = resultValues;
        } catch {
            return new LibPart.Part[](0);
        }

        if (values.length != recipients.length) {
            return new LibPart.Part[](0);
        }

        LibPart.Part[] memory result = new LibPart.Part[](values.length);

        for (uint256 i = 0; i < values.length; i++) {
            result[i].value = uint96(values[i]);
            result[i].account = recipients[i];
        }

        return result;
    }

    /// @dev tries to get royalties EIP-2981 for token and tokenId
    function getRoyaltiesEIP2981(address token, uint256 tokenId)
        internal
        view
        returns (LibPart.Part[] memory)
    {
        try
            IERC2981(token).royaltyInfo(tokenId, LibRoyalties2981._WEIGHT_VALUE)
        returns (address receiver, uint256 royaltyAmount) {
            return LibRoyalties2981.calculateRoyalties(receiver, royaltyAmount);
        } catch {
            return new LibPart.Part[](0);
        }
    }

    /// @dev tries to get royalties for token and tokenId from external provider set in royaltiesProviders
    function providerExtractor(
        address token,
        uint256 tokenId,
        address providerAddress
    ) internal returns (LibPart.Part[] memory) {
        try
            IRoyaltiesProvider(providerAddress).getRoyalties(token, tokenId)
        returns (LibPart.Part[] memory result) {
            return result;
        } catch {
            return new LibPart.Part[](0);
        }
    }

    function transferOwnership(address newOwner) public override {
        onlyWhitelistedAddress(_msgSender());
        onlyWhitelistedAddress(newOwner);

        super.transferOwnership(newOwner);
    }

    function renounceOwnership() public override {
        onlyWhitelistedAddress(_msgSender());

        super.renounceOwnership();
    }

    uint256[46] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

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
    function getApproved(uint256 tokenId)
        external
        view
        returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";

import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
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
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../openzeppelin-upgradeable/access/OwnableUpgradeable.sol";
import "../openzeppelin-upgradeable/utils/AddressUpgradeable.sol";

import "./interfaces/ISecuritizeRegistryProxy.sol";
import "./interfaces/IContractsRegistryProxy.sol";

abstract contract WhitelistableUpgradeable is OwnableUpgradeable {
    using AddressUpgradeable for address;

    address public securitizeRegistryProxy;
    address public contractsRegistryProxy;

    modifier onlyContract(address addr) {
        require(addr.isContract(), "Whitelistable: not contract address");
        _;
    }

    function __Whitelistable_init(
        address initialSecuritizeRegistryProxy,
        address initialContractsRegistryProxy
    ) internal {
        __Ownable_init_unchained();
        __Whitelistable_init_unchained(
            initialSecuritizeRegistryProxy,
            initialContractsRegistryProxy
        );
    }

    function __Whitelistable_init_unchained(
        address initialSecuritizeRegistryProxy,
        address initialContractsRegistryProxy
    )
        internal
        onlyContract(initialSecuritizeRegistryProxy)
        onlyContract(initialContractsRegistryProxy)
    {
        securitizeRegistryProxy = initialSecuritizeRegistryProxy;
        contractsRegistryProxy = initialContractsRegistryProxy;
    }

    function setSecuritizeRegistryProxy(address newSecuritizeRegistryProxy)
        external
        onlyOwner
        onlyContract(newSecuritizeRegistryProxy)
    {
        onlyWhitelistedAddress(_msgSender());

        securitizeRegistryProxy = newSecuritizeRegistryProxy;
    }

    function setContractsRegistryProxy(address newContractsRegistryProxy)
        external
        onlyOwner
        onlyContract(newContractsRegistryProxy)
    {
        onlyWhitelistedAddress(_msgSender());

        contractsRegistryProxy = newContractsRegistryProxy;
    }

    function onlyWhitelistedAddress(address addr) public view {
        require(
            ISecuritizeRegistryProxy(securitizeRegistryProxy)
                .isWhitelistedWallet(addr) ||
                IContractsRegistryProxy(contractsRegistryProxy)
                    .isWhitelistedContract(addr),
            "Whitelistable: address is not whitelisted"
        );
    }

    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

pragma abicoder v2;

import "./LibPart.sol";

interface IRoyaltiesProvider {
    function getRoyalties(address token, uint256 tokenId)
        external
        returns (LibPart.Part[] memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./LibPart.sol";

library LibRoyalties2981 {
    /*
     * bytes4(keccak256("royaltyInfo(uint256,uint256)")) == 0x2a55205a
     */
    bytes4 internal constant _INTERFACE_ID_ROYALTIES = 0x2a55205a;
    uint96 internal constant _WEIGHT_VALUE = 1000000;

    /**
     * Method for converting amount to percent and forming LibPart
     */
    function calculateRoyalties(address to, uint256 amount)
        internal
        pure
        returns (LibPart.Part[] memory)
    {
        LibPart.Part[] memory result;

        if (amount == 0) {
            return result;
        }

        uint256 percent = ((amount * 100) / _WEIGHT_VALUE) * 100;

        require(percent < 10000, "Royalties2981: value more than 100%");

        result = new LibPart.Part[](1);
        result[0].account = payable(to);
        result[0].value = uint96(percent);

        return result;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library LibRoyaltiesV1 {
    /**
     * bytes4(keccak256('getFeeBps(uint256)')) == 0x0ebd4c7f
     * bytes4(keccak256('getFeeRecipients(uint256)')) == 0xb9c4d9fb
     *
     * => 0x0ebd4c7f ^ 0xb9c4d9fb == 0xb7799584
     */
    bytes4 internal constant _INTERFACE_ID_FEES = 0xb7799584;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library LibRoyaltiesV2 {
    /**
     * bytes4(keccak256('getBridgeTowerV2Royalties(uint256)')) == 0x2182ba32
     */
    bytes4 internal constant _INTERFACE_ID_ROYALTIES = 0x2182ba32;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface RoyaltiesV1 {
    event SecondarySaleFees(
        uint256 tokenId,
        address[] recipients,
        uint256[] bps
    );

    function getFeeRecipients(uint256 id)
        external
        view
        returns (address payable[] memory);

    function getFeeBps(uint256 id) external view returns (uint256[] memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

pragma abicoder v2;

import "./LibPart.sol";

interface RoyaltiesV2 {
    event RoyaltiesSet(uint256 tokenId, LibPart.Part[] royalties);

    function getBridgeTowerV2Royalties(uint256 id)
        external
        view
        returns (LibPart.Part[] memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./LibPart.sol";

/**
 * @dev Interface for the NFT Royalty Standard
 */
interface IERC2981 {
    /**
     * @notice Called with the sale price to determine how much royalty is owed and to whom.
     * @param _tokenId - the NFT asset queried for royalty information
     * @param _salePrice - the sale price of the NFT asset specified by _tokenId
     * @return receiver - address of who should be sent the royalty payment
     * @return royaltyAmount - the royalty payment amount for _salePrice
     */
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
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
interface IERC165Upgradeable {
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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

import "../proxy/utils/Initializable.sol";

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {}

    function __Context_init_unchained() internal onlyInitializing {}

    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = _setInitializedVersion(1);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        bool isTopLevelCall = _setInitializedVersion(version);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(version);
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        _setInitializedVersion(type(uint8).max);
    }

    function _setInitializedVersion(uint8 version) private returns (bool) {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, and for the lowest level
        // of initializers, because in other contexts the contract may have been reentered.
        if (_initializing) {
            require(
                version == 1 && !AddressUpgradeable.isContract(address(this)),
                "Initializable: contract is already initialized"
            );
            return false;
        } else {
            require(
                _initialized < version,
                "Initializable: contract is already initialized"
            );
            _initialized = version;
            return true;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ISecuritizeRegistryProxy {
    function setSecuritizeRegistry(address newSecuritizeRegistry) external;

    function isWhitelistedWallet(address wallet) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IContractsRegistryProxy {
    function setContractsRegistry(address newContractsRegistry) external;

    function setSecuritizeRegistryProxy(address newSecuritizeRegistryProxy)
        external;

    function isWhitelistedContract(address addr) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library LibPart {
    /**
     * keccak256("Part(address account,uint96 value)") == 0x397e04204c1e1a60ee8724b71f8244e10ab5f2e9009854d80f602bda21b59ebb
     */
    bytes32 public constant TYPE_HASH =
        0x397e04204c1e1a60ee8724b71f8244e10ab5f2e9009854d80f602bda21b59ebb;

    struct Part {
        address payable account;
        uint96 value;
    }

    function hash(Part memory part) internal pure returns (bytes32) {
        return keccak256(abi.encode(TYPE_HASH, part.account, part.value));
    }
}