/**
 *Submitted for verification at testnet.snowtrace.io on 2022-04-16
*/

// Sources flattened with hardhat v2.9.1 https://hardhat.org

// File @openzeppelin/contracts/utils/[email protected]

// SPDX-License-Identifier: MIT AND UNLICENSED
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File @openzeppelin/contracts/access/[email protected]

// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
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
}

// File @openzeppelin/contracts-upgradeable/utils/[email protected]

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
library CountersUpgradeable {
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

// File @openzeppelin/contracts-upgradeable/utils/introspection/[email protected]

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

// File @openzeppelin/contracts-upgradeable/token/ERC721/[email protected]

// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

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
    function getApproved(uint256 tokenId)
        external
        view
        returns (address operator);

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
    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);

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

// File @openzeppelin/contracts-upgradeable/token/ERC721/[email protected]

// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
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

// File @openzeppelin/contracts-upgradeable/token/ERC721/extensions/[email protected]

// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721MetadataUpgradeable is IERC721Upgradeable {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// File @openzeppelin/contracts-upgradeable/utils/[email protected]

// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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

// File @openzeppelin/contracts-upgradeable/proxy/utils/[email protected]

// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
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
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(
            _initializing ? _isConstructor() : !_initialized,
            "Initializable: contract is already initialized"
        );

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// File @openzeppelin/contracts-upgradeable/utils/[email protected]

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

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

// File @openzeppelin/contracts-upgradeable/utils/[email protected]

// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length)
        internal
        pure
        returns (string memory)
    {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// File @openzeppelin/contracts-upgradeable/utils/introspection/[email protected]

// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {}

    function __ERC165_init_unchained() internal onlyInitializing {}

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// File @openzeppelin/contracts-upgradeable/token/ERC721/[email protected]

// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721Upgradeable is
    Initializable,
    ContextUpgradeable,
    ERC165Upgradeable,
    IERC721Upgradeable,
    IERC721MetadataUpgradeable
{
    using AddressUpgradeable for address;
    using StringsUpgradeable for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    function __ERC721_init(string memory name_, string memory symbol_)
        internal
        onlyInitializing
    {
        __ERC721_init_unchained(name_, symbol_);
    }

    function __ERC721_init_unchained(string memory name_, string memory symbol_)
        internal
        onlyInitializing
    {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165Upgradeable, IERC165Upgradeable)
        returns (bool)
    {
        return
            interfaceId == type(IERC721Upgradeable).interfaceId ||
            interfaceId == type(IERC721MetadataUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner)
        public
        view
        virtual
        override
        returns (uint256)
    {
        require(
            owner != address(0),
            "ERC721: balance query for the zero address"
        );
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
        address owner = _owners[tokenId];
        require(
            owner != address(0),
            "ERC721: owner query for nonexistent token"
        );
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, tokenId.toString()))
                : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
        require(
            _exists(tokenId),
            "ERC721: approved query for nonexistent token"
        );

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved)
        public
        virtual
        override
    {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator)
        public
        view
        virtual
        override
        returns (bool)
    {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(
            _checkOnERC721Received(from, to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId)
        internal
        view
        virtual
        returns (bool)
    {
        require(
            _exists(tokenId),
            "ERC721: operator query for nonexistent token"
        );
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        return (spender == owner ||
            getApproved(tokenId) == spender ||
            isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721Upgradeable.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
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
    ) internal virtual {
        require(
            ERC721Upgradeable.ownerOf(tokenId) == from,
            "ERC721: transfer from incorrect owner"
        );
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721Upgradeable.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try
                IERC721ReceiverUpgradeable(to).onERC721Received(
                    _msgSender(),
                    from,
                    tokenId,
                    _data
                )
            returns (bytes4 retval) {
                return
                    retval ==
                    IERC721ReceiverUpgradeable.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert(
                        "ERC721: transfer to non ERC721Receiver implementer"
                    );
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[44] private __gap;
}

// File @openzeppelin/contracts-upgradeable/token/ERC721/extensions/[email protected]

// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721URIStorage.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC721 token with storage based token URI management.
 */
abstract contract ERC721URIStorageUpgradeable is
    Initializable,
    ERC721Upgradeable
{
    function __ERC721URIStorage_init() internal onlyInitializing {}

    function __ERC721URIStorage_init_unchained() internal onlyInitializing {}

    using StringsUpgradeable for uint256;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721URIStorage: URI query for nonexistent token"
        );

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return super.tokenURI(tokenId);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI)
        internal
        virtual
    {
        require(
            _exists(tokenId),
            "ERC721URIStorage: URI set of nonexistent token"
        );
        _tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// File @openzeppelin/contracts-upgradeable/access/[email protected]

// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(
        bytes32 indexed role,
        bytes32 indexed previousAdminRole,
        bytes32 indexed newAdminRole
    );

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account)
        external
        view
        returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// File @openzeppelin/contracts-upgradeable/access/[email protected]

// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControlUpgradeable is
    Initializable,
    ContextUpgradeable,
    IAccessControlUpgradeable,
    ERC165Upgradeable
{
    function __AccessControl_init() internal onlyInitializing {}

    function __AccessControl_init_unchained() internal onlyInitializing {}

    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            interfaceId == type(IAccessControlUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account)
        public
        view
        virtual
        override
        returns (bool)
    {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        StringsUpgradeable.toHexString(uint160(account), 20),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role)
        public
        view
        virtual
        override
        returns (bytes32)
    {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account)
        public
        virtual
        override
        onlyRole(getRoleAdmin(role))
    {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account)
        public
        virtual
        override
        onlyRole(getRoleAdmin(role))
    {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account)
        public
        virtual
        override
    {
        require(
            account == _msgSender(),
            "AccessControl: can only renounce roles for self"
        );

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// File contracts/NFT/ERC721/IERC721NFTCollection.sol

pragma solidity 0.8.11;

interface IERC721NFTCollection {
    /**
     * @dev spots are the amount of discount a user can have on their WL NFTs.
     * examples:
     * spots = 10000 is for free NFTs (in Basis Points)
     * spots = 5000 is for 50% discounted NFTs
     * spots = 2500 is for 25% discounted NFTs
     * spots = 10001 is for guaranteed NFTs (no discount)
     * spots = 0 is for general NFTs (for all, no discount)
     */
    struct Mintables {
        uint256[] spots;
        bool[] mintedSpots;
        bool isWhitelisted;
        bool isFreezed;
    }

    error NotWhitelisted();
    error UsersTiersLengthMismatch();
    error UsersSpotsLengthMismatch();
    error InvalidAmount(uint256 sent, uint256 minRequired);
    error MintingNotStartedYet();
    error MintingNotEndedYet();
    error MintingHasEnded();
    error MintAmountExceedsMinables(uint256 requested, uint256 actual);
    error CanNotMintMoreThanMaxMintAmount();
    error TotalMintsExceedsMaxMintAmount(uint256 requested, uint256 actual);
    error TotalGuaranteedMintsExceedsAmount(uint256 requested, uint256 actual);
    error TotalForAllMintsExceedsAmount(uint256 requested, uint256 actual);
    error BalanceIsLessThanRequestedAmount(uint256 requested, uint256 balance);
    error WrongBaseURIProvided();
    error WrongNumberOfSpots();
    error ThisSpotIsAlreadyMinted(uint256 spot);
    error SpotIsIncorrect(address user, uint256 spot);

    event MintingStarted();
    event MintingEnded();
    event baseURIIsSet(string indexed baseURI);
    event NFTMinted(address indexed user, uint256 itemId);
    event WinnersAreSet(
        address[] users,
        uint256[][] _spots,
        bool lastSlot,
        bool deletePreviousWinners,
        address[] deletedWinners
    );
    event UserMinted(
        address indexed user,
        uint256 discounts,
        uint256 costWithDiscount,
        uint256 mintFee,
        uint256 totalCost,
        uint256 extraPaid,
        uint256 numberOfMintedSpots
    );

    function mint(bool[] memory _spots) external payable;

    function setWhitelistedUsers(
        address[] memory users,
        uint256[][] memory _spots,
        uint256[] memory _tiers,
        address[] memory deletedWinners,
        bool lastSlot,
        bool deletePreviousWinners
    ) external;

    function isWhitelisted(address user) external view returns (bool);

    function startMinting() external;

    function endMinting() external;

    function setBaseURI(string memory _BaseURI) external;

    function getBalance() external view returns (uint256);

    function getWinners() external view returns (address[] memory);

    function getNumberOfSpots(address user) external view returns (uint256);

    function getNumberOfRemainingSpots(address user)
        external
        view
        returns (uint256);

    function withdrawBalance(address payable receiver, uint256 amount) external;
}

// File contracts/interfaces/IPoolMechanics.sol

pragma solidity 0.8.11;

interface IPoolMechanics {
    struct Tiers {
        uint256 rangeFrom; // in Spark
        uint256 rangeTo; // in Spark
        uint256 poolEntryFee; // in basis points
        uint256 mintFee; // in basis points
        uint256 numberOfPredictions;
        uint256 WLCap; // redundant
        uint256 NFTMintableCap; // 4 (6 for top 10 winners) // ToDo: ???????
    }
    event NewTiersSettled(Tiers[] tiers);

    error TiersAreNotValid(Tiers[] tiers);
    error InputAmountIsInvalid(uint256 amount);
    error FirstTiersRangeFromMustBeZero();
    error TiersDoNotCoverAllAmounts();

    function setNewTiers(Tiers[] memory _tiers) external;

    function getTier(uint256 _amount) external view returns (uint256);

    function getEntryFee(uint256 tier) external view returns (uint256);

    function getMintFee(uint256 tier) external view returns (uint256);

    function getNumberOfPredictions(uint256 tier)
        external
        view
        returns (uint256 numberOfPredictions);

    function getWLCap(uint256 tier) external view returns (uint256 WLCap);

    function getNFTMintableCap(uint256 tier)
        external
        view
        returns (uint256 NFTMintableCap);
}

// File @openzeppelin/contracts/utils/math/[email protected]

// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// File contracts/libraries/BasisPoints.sol

pragma solidity ^0.8.0;

library BasisPoints {
    using SafeMath for uint256;

    uint256 private constant BASIS_POINTS = 10000;

    function mulBP(uint256 amt, uint256 bp) internal pure returns (uint256) {
        return amt.mul(bp).div(BASIS_POINTS);
    }

    function divBP(uint256 amt, uint256 bp) internal pure returns (uint256) {
        require(bp > 0, "Cannot divide by zero.");
        return amt.mul(BASIS_POINTS).div(bp);
    }

    function addBP(uint256 amt, uint256 bp) internal pure returns (uint256) {
        if (amt == 0) return 0;
        if (bp == 0) return amt;
        return amt.add(mulBP(amt, bp));
    }

    function subBP(uint256 amt, uint256 bp) internal pure returns (uint256) {
        if (amt == 0) return 0;
        if (bp == 0) return amt;
        return amt.sub(mulBP(amt, bp));
    }
}

// File hardhat/[email protected]

pragma solidity >=0.4.22 <0.9.0;

library console {
    address constant CONSOLE_ADDRESS =
        address(0x000000000000000000636F6e736F6c652e6c6f67);

    function _sendLogPayload(bytes memory payload) private view {
        uint256 payloadLength = payload.length;
        address consoleAddress = CONSOLE_ADDRESS;
        assembly {
            let payloadStart := add(payload, 32)
            let r := staticcall(
                gas(),
                consoleAddress,
                payloadStart,
                payloadLength,
                0,
                0
            )
        }
    }

    function log() internal view {
        _sendLogPayload(abi.encodeWithSignature("log()"));
    }

    function logInt(int256 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(int)", p0));
    }

    function logUint(uint256 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
    }

    function logString(string memory p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string)", p0));
    }

    function logBool(bool p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
    }

    function logAddress(address p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address)", p0));
    }

    function logBytes(bytes memory p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
    }

    function logBytes1(bytes1 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
    }

    function logBytes2(bytes2 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
    }

    function logBytes3(bytes3 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
    }

    function logBytes4(bytes4 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
    }

    function logBytes5(bytes5 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
    }

    function logBytes6(bytes6 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
    }

    function logBytes7(bytes7 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
    }

    function logBytes8(bytes8 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
    }

    function logBytes9(bytes9 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
    }

    function logBytes10(bytes10 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
    }

    function logBytes11(bytes11 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
    }

    function logBytes12(bytes12 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
    }

    function logBytes13(bytes13 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
    }

    function logBytes14(bytes14 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
    }

    function logBytes15(bytes15 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
    }

    function logBytes16(bytes16 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
    }

    function logBytes17(bytes17 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
    }

    function logBytes18(bytes18 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
    }

    function logBytes19(bytes19 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
    }

    function logBytes20(bytes20 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
    }

    function logBytes21(bytes21 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
    }

    function logBytes22(bytes22 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
    }

    function logBytes23(bytes23 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
    }

    function logBytes24(bytes24 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
    }

    function logBytes25(bytes25 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
    }

    function logBytes26(bytes26 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
    }

    function logBytes27(bytes27 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
    }

    function logBytes28(bytes28 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
    }

    function logBytes29(bytes29 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
    }

    function logBytes30(bytes30 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
    }

    function logBytes31(bytes31 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
    }

    function logBytes32(bytes32 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
    }

    function log(uint256 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
    }

    function log(string memory p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string)", p0));
    }

    function log(bool p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
    }

    function log(address p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address)", p0));
    }

    function log(uint256 p0, uint256 p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint)", p0, p1));
    }

    function log(uint256 p0, string memory p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string)", p0, p1));
    }

    function log(uint256 p0, bool p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool)", p0, p1));
    }

    function log(uint256 p0, address p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address)", p0, p1));
    }

    function log(string memory p0, uint256 p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint)", p0, p1));
    }

    function log(string memory p0, string memory p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
    }

    function log(string memory p0, bool p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
    }

    function log(string memory p0, address p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
    }

    function log(bool p0, uint256 p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint)", p0, p1));
    }

    function log(bool p0, string memory p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
    }

    function log(bool p0, bool p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
    }

    function log(bool p0, address p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
    }

    function log(address p0, uint256 p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint)", p0, p1));
    }

    function log(address p0, string memory p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
    }

    function log(address p0, bool p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
    }

    function log(address p0, address p1) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(address,address)", p0, p1)
        );
    }

    function log(
        uint256 p0,
        uint256 p1,
        uint256 p2
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(uint,uint,uint)", p0, p1, p2)
        );
    }

    function log(
        uint256 p0,
        uint256 p1,
        string memory p2
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(uint,uint,string)", p0, p1, p2)
        );
    }

    function log(
        uint256 p0,
        uint256 p1,
        bool p2
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(uint,uint,bool)", p0, p1, p2)
        );
    }

    function log(
        uint256 p0,
        uint256 p1,
        address p2
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(uint,uint,address)", p0, p1, p2)
        );
    }

    function log(
        uint256 p0,
        string memory p1,
        uint256 p2
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(uint,string,uint)", p0, p1, p2)
        );
    }

    function log(
        uint256 p0,
        string memory p1,
        string memory p2
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(uint,string,string)", p0, p1, p2)
        );
    }

    function log(
        uint256 p0,
        string memory p1,
        bool p2
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(uint,string,bool)", p0, p1, p2)
        );
    }

    function log(
        uint256 p0,
        string memory p1,
        address p2
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(uint,string,address)", p0, p1, p2)
        );
    }

    function log(
        uint256 p0,
        bool p1,
        uint256 p2
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(uint,bool,uint)", p0, p1, p2)
        );
    }

    function log(
        uint256 p0,
        bool p1,
        string memory p2
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(uint,bool,string)", p0, p1, p2)
        );
    }

    function log(
        uint256 p0,
        bool p1,
        bool p2
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(uint,bool,bool)", p0, p1, p2)
        );
    }

    function log(
        uint256 p0,
        bool p1,
        address p2
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(uint,bool,address)", p0, p1, p2)
        );
    }

    function log(
        uint256 p0,
        address p1,
        uint256 p2
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(uint,address,uint)", p0, p1, p2)
        );
    }

    function log(
        uint256 p0,
        address p1,
        string memory p2
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(uint,address,string)", p0, p1, p2)
        );
    }

    function log(
        uint256 p0,
        address p1,
        bool p2
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(uint,address,bool)", p0, p1, p2)
        );
    }

    function log(
        uint256 p0,
        address p1,
        address p2
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(uint,address,address)", p0, p1, p2)
        );
    }

    function log(
        string memory p0,
        uint256 p1,
        uint256 p2
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(string,uint,uint)", p0, p1, p2)
        );
    }

    function log(
        string memory p0,
        uint256 p1,
        string memory p2
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(string,uint,string)", p0, p1, p2)
        );
    }

    function log(
        string memory p0,
        uint256 p1,
        bool p2
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(string,uint,bool)", p0, p1, p2)
        );
    }

    function log(
        string memory p0,
        uint256 p1,
        address p2
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(string,uint,address)", p0, p1, p2)
        );
    }

    function log(
        string memory p0,
        string memory p1,
        uint256 p2
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(string,string,uint)", p0, p1, p2)
        );
    }

    function log(
        string memory p0,
        string memory p1,
        string memory p2
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(string,string,string)", p0, p1, p2)
        );
    }

    function log(
        string memory p0,
        string memory p1,
        bool p2
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2)
        );
    }

    function log(
        string memory p0,
        string memory p1,
        address p2
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(string,string,address)", p0, p1, p2)
        );
    }

    function log(
        string memory p0,
        bool p1,
        uint256 p2
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(string,bool,uint)", p0, p1, p2)
        );
    }

    function log(
        string memory p0,
        bool p1,
        string memory p2
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2)
        );
    }

    function log(
        string memory p0,
        bool p1,
        bool p2
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2)
        );
    }

    function log(
        string memory p0,
        bool p1,
        address p2
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2)
        );
    }

    function log(
        string memory p0,
        address p1,
        uint256 p2
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(string,address,uint)", p0, p1, p2)
        );
    }

    function log(
        string memory p0,
        address p1,
        string memory p2
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(string,address,string)", p0, p1, p2)
        );
    }

    function log(
        string memory p0,
        address p1,
        bool p2
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2)
        );
    }

    function log(
        string memory p0,
        address p1,
        address p2
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(string,address,address)", p0, p1, p2)
        );
    }

    function log(
        bool p0,
        uint256 p1,
        uint256 p2
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(bool,uint,uint)", p0, p1, p2)
        );
    }

    function log(
        bool p0,
        uint256 p1,
        string memory p2
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(bool,uint,string)", p0, p1, p2)
        );
    }

    function log(
        bool p0,
        uint256 p1,
        bool p2
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(bool,uint,bool)", p0, p1, p2)
        );
    }

    function log(
        bool p0,
        uint256 p1,
        address p2
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(bool,uint,address)", p0, p1, p2)
        );
    }

    function log(
        bool p0,
        string memory p1,
        uint256 p2
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(bool,string,uint)", p0, p1, p2)
        );
    }

    function log(
        bool p0,
        string memory p1,
        string memory p2
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2)
        );
    }

    function log(
        bool p0,
        string memory p1,
        bool p2
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2)
        );
    }

    function log(
        bool p0,
        string memory p1,
        address p2
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2)
        );
    }

    function log(
        bool p0,
        bool p1,
        uint256 p2
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(bool,bool,uint)", p0, p1, p2)
        );
    }

    function log(
        bool p0,
        bool p1,
        string memory p2
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2)
        );
    }

    function log(
        bool p0,
        bool p1,
        bool p2
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2)
        );
    }

    function log(
        bool p0,
        bool p1,
        address p2
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2)
        );
    }

    function log(
        bool p0,
        address p1,
        uint256 p2
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(bool,address,uint)", p0, p1, p2)
        );
    }

    function log(
        bool p0,
        address p1,
        string memory p2
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2)
        );
    }

    function log(
        bool p0,
        address p1,
        bool p2
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2)
        );
    }

    function log(
        bool p0,
        address p1,
        address p2
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2)
        );
    }

    function log(
        address p0,
        uint256 p1,
        uint256 p2
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(address,uint,uint)", p0, p1, p2)
        );
    }

    function log(
        address p0,
        uint256 p1,
        string memory p2
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(address,uint,string)", p0, p1, p2)
        );
    }

    function log(
        address p0,
        uint256 p1,
        bool p2
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(address,uint,bool)", p0, p1, p2)
        );
    }

    function log(
        address p0,
        uint256 p1,
        address p2
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(address,uint,address)", p0, p1, p2)
        );
    }

    function log(
        address p0,
        string memory p1,
        uint256 p2
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(address,string,uint)", p0, p1, p2)
        );
    }

    function log(
        address p0,
        string memory p1,
        string memory p2
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(address,string,string)", p0, p1, p2)
        );
    }

    function log(
        address p0,
        string memory p1,
        bool p2
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2)
        );
    }

    function log(
        address p0,
        string memory p1,
        address p2
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(address,string,address)", p0, p1, p2)
        );
    }

    function log(
        address p0,
        bool p1,
        uint256 p2
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(address,bool,uint)", p0, p1, p2)
        );
    }

    function log(
        address p0,
        bool p1,
        string memory p2
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2)
        );
    }

    function log(
        address p0,
        bool p1,
        bool p2
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2)
        );
    }

    function log(
        address p0,
        bool p1,
        address p2
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2)
        );
    }

    function log(
        address p0,
        address p1,
        uint256 p2
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(address,address,uint)", p0, p1, p2)
        );
    }

    function log(
        address p0,
        address p1,
        string memory p2
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(address,address,string)", p0, p1, p2)
        );
    }

    function log(
        address p0,
        address p1,
        bool p2
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2)
        );
    }

    function log(
        address p0,
        address p1,
        address p2
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(address,address,address)", p0, p1, p2)
        );
    }

    function log(
        uint256 p0,
        uint256 p1,
        uint256 p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(uint,uint,uint,uint)", p0, p1, p2, p3)
        );
    }

    function log(
        uint256 p0,
        uint256 p1,
        uint256 p2,
        string memory p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(uint,uint,uint,string)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        uint256 p0,
        uint256 p1,
        uint256 p2,
        bool p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(uint,uint,uint,bool)", p0, p1, p2, p3)
        );
    }

    function log(
        uint256 p0,
        uint256 p1,
        uint256 p2,
        address p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(uint,uint,uint,address)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        uint256 p0,
        uint256 p1,
        string memory p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(uint,uint,string,uint)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        uint256 p0,
        uint256 p1,
        string memory p2,
        string memory p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(uint,uint,string,string)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        uint256 p0,
        uint256 p1,
        string memory p2,
        bool p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(uint,uint,string,bool)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        uint256 p0,
        uint256 p1,
        string memory p2,
        address p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(uint,uint,string,address)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        uint256 p0,
        uint256 p1,
        bool p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(uint,uint,bool,uint)", p0, p1, p2, p3)
        );
    }

    function log(
        uint256 p0,
        uint256 p1,
        bool p2,
        string memory p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(uint,uint,bool,string)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        uint256 p0,
        uint256 p1,
        bool p2,
        bool p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(uint,uint,bool,bool)", p0, p1, p2, p3)
        );
    }

    function log(
        uint256 p0,
        uint256 p1,
        bool p2,
        address p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(uint,uint,bool,address)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        uint256 p0,
        uint256 p1,
        address p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(uint,uint,address,uint)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        uint256 p0,
        uint256 p1,
        address p2,
        string memory p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(uint,uint,address,string)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        uint256 p0,
        uint256 p1,
        address p2,
        bool p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(uint,uint,address,bool)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        uint256 p0,
        uint256 p1,
        address p2,
        address p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(uint,uint,address,address)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        uint256 p0,
        string memory p1,
        uint256 p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(uint,string,uint,uint)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        uint256 p0,
        string memory p1,
        uint256 p2,
        string memory p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(uint,string,uint,string)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        uint256 p0,
        string memory p1,
        uint256 p2,
        bool p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(uint,string,uint,bool)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        uint256 p0,
        string memory p1,
        uint256 p2,
        address p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(uint,string,uint,address)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        uint256 p0,
        string memory p1,
        string memory p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(uint,string,string,uint)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        uint256 p0,
        string memory p1,
        string memory p2,
        string memory p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(uint,string,string,string)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        uint256 p0,
        string memory p1,
        string memory p2,
        bool p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(uint,string,string,bool)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        uint256 p0,
        string memory p1,
        string memory p2,
        address p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(uint,string,string,address)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        uint256 p0,
        string memory p1,
        bool p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(uint,string,bool,uint)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        uint256 p0,
        string memory p1,
        bool p2,
        string memory p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(uint,string,bool,string)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        uint256 p0,
        string memory p1,
        bool p2,
        bool p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(uint,string,bool,bool)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        uint256 p0,
        string memory p1,
        bool p2,
        address p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(uint,string,bool,address)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        uint256 p0,
        string memory p1,
        address p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(uint,string,address,uint)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        uint256 p0,
        string memory p1,
        address p2,
        string memory p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(uint,string,address,string)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        uint256 p0,
        string memory p1,
        address p2,
        bool p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(uint,string,address,bool)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        uint256 p0,
        string memory p1,
        address p2,
        address p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(uint,string,address,address)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        uint256 p0,
        bool p1,
        uint256 p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(uint,bool,uint,uint)", p0, p1, p2, p3)
        );
    }

    function log(
        uint256 p0,
        bool p1,
        uint256 p2,
        string memory p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(uint,bool,uint,string)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        uint256 p0,
        bool p1,
        uint256 p2,
        bool p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(uint,bool,uint,bool)", p0, p1, p2, p3)
        );
    }

    function log(
        uint256 p0,
        bool p1,
        uint256 p2,
        address p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(uint,bool,uint,address)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        uint256 p0,
        bool p1,
        string memory p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(uint,bool,string,uint)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        uint256 p0,
        bool p1,
        string memory p2,
        string memory p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(uint,bool,string,string)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        uint256 p0,
        bool p1,
        string memory p2,
        bool p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(uint,bool,string,bool)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        uint256 p0,
        bool p1,
        string memory p2,
        address p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(uint,bool,string,address)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        uint256 p0,
        bool p1,
        bool p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(uint,bool,bool,uint)", p0, p1, p2, p3)
        );
    }

    function log(
        uint256 p0,
        bool p1,
        bool p2,
        string memory p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(uint,bool,bool,string)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        uint256 p0,
        bool p1,
        bool p2,
        bool p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(uint,bool,bool,bool)", p0, p1, p2, p3)
        );
    }

    function log(
        uint256 p0,
        bool p1,
        bool p2,
        address p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(uint,bool,bool,address)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        uint256 p0,
        bool p1,
        address p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(uint,bool,address,uint)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        uint256 p0,
        bool p1,
        address p2,
        string memory p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(uint,bool,address,string)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        uint256 p0,
        bool p1,
        address p2,
        bool p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(uint,bool,address,bool)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        uint256 p0,
        bool p1,
        address p2,
        address p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(uint,bool,address,address)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        uint256 p0,
        address p1,
        uint256 p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(uint,address,uint,uint)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        uint256 p0,
        address p1,
        uint256 p2,
        string memory p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(uint,address,uint,string)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        uint256 p0,
        address p1,
        uint256 p2,
        bool p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(uint,address,uint,bool)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        uint256 p0,
        address p1,
        uint256 p2,
        address p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(uint,address,uint,address)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        uint256 p0,
        address p1,
        string memory p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(uint,address,string,uint)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        uint256 p0,
        address p1,
        string memory p2,
        string memory p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(uint,address,string,string)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        uint256 p0,
        address p1,
        string memory p2,
        bool p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(uint,address,string,bool)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        uint256 p0,
        address p1,
        string memory p2,
        address p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(uint,address,string,address)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        uint256 p0,
        address p1,
        bool p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(uint,address,bool,uint)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        uint256 p0,
        address p1,
        bool p2,
        string memory p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(uint,address,bool,string)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        uint256 p0,
        address p1,
        bool p2,
        bool p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(uint,address,bool,bool)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        uint256 p0,
        address p1,
        bool p2,
        address p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(uint,address,bool,address)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        uint256 p0,
        address p1,
        address p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(uint,address,address,uint)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        uint256 p0,
        address p1,
        address p2,
        string memory p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(uint,address,address,string)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        uint256 p0,
        address p1,
        address p2,
        bool p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(uint,address,address,bool)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        uint256 p0,
        address p1,
        address p2,
        address p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(uint,address,address,address)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        string memory p0,
        uint256 p1,
        uint256 p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(string,uint,uint,uint)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        string memory p0,
        uint256 p1,
        uint256 p2,
        string memory p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(string,uint,uint,string)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        string memory p0,
        uint256 p1,
        uint256 p2,
        bool p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(string,uint,uint,bool)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        string memory p0,
        uint256 p1,
        uint256 p2,
        address p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(string,uint,uint,address)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        string memory p0,
        uint256 p1,
        string memory p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(string,uint,string,uint)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        string memory p0,
        uint256 p1,
        string memory p2,
        string memory p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(string,uint,string,string)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        string memory p0,
        uint256 p1,
        string memory p2,
        bool p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(string,uint,string,bool)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        string memory p0,
        uint256 p1,
        string memory p2,
        address p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(string,uint,string,address)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        string memory p0,
        uint256 p1,
        bool p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(string,uint,bool,uint)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        string memory p0,
        uint256 p1,
        bool p2,
        string memory p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(string,uint,bool,string)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        string memory p0,
        uint256 p1,
        bool p2,
        bool p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(string,uint,bool,bool)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        string memory p0,
        uint256 p1,
        bool p2,
        address p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(string,uint,bool,address)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        string memory p0,
        uint256 p1,
        address p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(string,uint,address,uint)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        string memory p0,
        uint256 p1,
        address p2,
        string memory p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(string,uint,address,string)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        string memory p0,
        uint256 p1,
        address p2,
        bool p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(string,uint,address,bool)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        string memory p0,
        uint256 p1,
        address p2,
        address p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(string,uint,address,address)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        string memory p0,
        string memory p1,
        uint256 p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(string,string,uint,uint)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        string memory p0,
        string memory p1,
        uint256 p2,
        string memory p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(string,string,uint,string)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        string memory p0,
        string memory p1,
        uint256 p2,
        bool p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(string,string,uint,bool)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        string memory p0,
        string memory p1,
        uint256 p2,
        address p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(string,string,uint,address)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        string memory p0,
        string memory p1,
        string memory p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(string,string,string,uint)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        string memory p0,
        string memory p1,
        string memory p2,
        string memory p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(string,string,string,string)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        string memory p0,
        string memory p1,
        string memory p2,
        bool p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(string,string,string,bool)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        string memory p0,
        string memory p1,
        string memory p2,
        address p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(string,string,string,address)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        string memory p0,
        string memory p1,
        bool p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(string,string,bool,uint)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        string memory p0,
        string memory p1,
        bool p2,
        string memory p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(string,string,bool,string)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        string memory p0,
        string memory p1,
        bool p2,
        bool p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(string,string,bool,bool)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        string memory p0,
        string memory p1,
        bool p2,
        address p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(string,string,bool,address)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        string memory p0,
        string memory p1,
        address p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(string,string,address,uint)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        string memory p0,
        string memory p1,
        address p2,
        string memory p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(string,string,address,string)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        string memory p0,
        string memory p1,
        address p2,
        bool p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(string,string,address,bool)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        string memory p0,
        string memory p1,
        address p2,
        address p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(string,string,address,address)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        string memory p0,
        bool p1,
        uint256 p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(string,bool,uint,uint)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        string memory p0,
        bool p1,
        uint256 p2,
        string memory p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(string,bool,uint,string)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        string memory p0,
        bool p1,
        uint256 p2,
        bool p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(string,bool,uint,bool)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        string memory p0,
        bool p1,
        uint256 p2,
        address p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(string,bool,uint,address)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        string memory p0,
        bool p1,
        string memory p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(string,bool,string,uint)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        string memory p0,
        bool p1,
        string memory p2,
        string memory p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(string,bool,string,string)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        string memory p0,
        bool p1,
        string memory p2,
        bool p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(string,bool,string,bool)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        string memory p0,
        bool p1,
        string memory p2,
        address p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(string,bool,string,address)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        string memory p0,
        bool p1,
        bool p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(string,bool,bool,uint)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        string memory p0,
        bool p1,
        bool p2,
        string memory p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(string,bool,bool,string)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        string memory p0,
        bool p1,
        bool p2,
        bool p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(string,bool,bool,bool)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        string memory p0,
        bool p1,
        bool p2,
        address p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(string,bool,bool,address)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        string memory p0,
        bool p1,
        address p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(string,bool,address,uint)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        string memory p0,
        bool p1,
        address p2,
        string memory p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(string,bool,address,string)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        string memory p0,
        bool p1,
        address p2,
        bool p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(string,bool,address,bool)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        string memory p0,
        bool p1,
        address p2,
        address p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(string,bool,address,address)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        string memory p0,
        address p1,
        uint256 p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(string,address,uint,uint)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        string memory p0,
        address p1,
        uint256 p2,
        string memory p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(string,address,uint,string)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        string memory p0,
        address p1,
        uint256 p2,
        bool p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(string,address,uint,bool)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        string memory p0,
        address p1,
        uint256 p2,
        address p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(string,address,uint,address)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        string memory p0,
        address p1,
        string memory p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(string,address,string,uint)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        string memory p0,
        address p1,
        string memory p2,
        string memory p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(string,address,string,string)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        string memory p0,
        address p1,
        string memory p2,
        bool p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(string,address,string,bool)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        string memory p0,
        address p1,
        string memory p2,
        address p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(string,address,string,address)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        string memory p0,
        address p1,
        bool p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(string,address,bool,uint)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        string memory p0,
        address p1,
        bool p2,
        string memory p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(string,address,bool,string)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        string memory p0,
        address p1,
        bool p2,
        bool p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(string,address,bool,bool)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        string memory p0,
        address p1,
        bool p2,
        address p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(string,address,bool,address)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        string memory p0,
        address p1,
        address p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(string,address,address,uint)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        string memory p0,
        address p1,
        address p2,
        string memory p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(string,address,address,string)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        string memory p0,
        address p1,
        address p2,
        bool p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(string,address,address,bool)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        string memory p0,
        address p1,
        address p2,
        address p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(string,address,address,address)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        bool p0,
        uint256 p1,
        uint256 p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(bool,uint,uint,uint)", p0, p1, p2, p3)
        );
    }

    function log(
        bool p0,
        uint256 p1,
        uint256 p2,
        string memory p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(bool,uint,uint,string)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        bool p0,
        uint256 p1,
        uint256 p2,
        bool p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(bool,uint,uint,bool)", p0, p1, p2, p3)
        );
    }

    function log(
        bool p0,
        uint256 p1,
        uint256 p2,
        address p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(bool,uint,uint,address)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        bool p0,
        uint256 p1,
        string memory p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(bool,uint,string,uint)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        bool p0,
        uint256 p1,
        string memory p2,
        string memory p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(bool,uint,string,string)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        bool p0,
        uint256 p1,
        string memory p2,
        bool p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(bool,uint,string,bool)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        bool p0,
        uint256 p1,
        string memory p2,
        address p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(bool,uint,string,address)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        bool p0,
        uint256 p1,
        bool p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(bool,uint,bool,uint)", p0, p1, p2, p3)
        );
    }

    function log(
        bool p0,
        uint256 p1,
        bool p2,
        string memory p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(bool,uint,bool,string)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        bool p0,
        uint256 p1,
        bool p2,
        bool p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(bool,uint,bool,bool)", p0, p1, p2, p3)
        );
    }

    function log(
        bool p0,
        uint256 p1,
        bool p2,
        address p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(bool,uint,bool,address)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        bool p0,
        uint256 p1,
        address p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(bool,uint,address,uint)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        bool p0,
        uint256 p1,
        address p2,
        string memory p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(bool,uint,address,string)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        bool p0,
        uint256 p1,
        address p2,
        bool p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(bool,uint,address,bool)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        bool p0,
        uint256 p1,
        address p2,
        address p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(bool,uint,address,address)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        bool p0,
        string memory p1,
        uint256 p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(bool,string,uint,uint)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        bool p0,
        string memory p1,
        uint256 p2,
        string memory p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(bool,string,uint,string)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        bool p0,
        string memory p1,
        uint256 p2,
        bool p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(bool,string,uint,bool)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        bool p0,
        string memory p1,
        uint256 p2,
        address p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(bool,string,uint,address)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        bool p0,
        string memory p1,
        string memory p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(bool,string,string,uint)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        bool p0,
        string memory p1,
        string memory p2,
        string memory p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(bool,string,string,string)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        bool p0,
        string memory p1,
        string memory p2,
        bool p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(bool,string,string,bool)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        bool p0,
        string memory p1,
        string memory p2,
        address p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(bool,string,string,address)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        bool p0,
        string memory p1,
        bool p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(bool,string,bool,uint)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        bool p0,
        string memory p1,
        bool p2,
        string memory p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(bool,string,bool,string)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        bool p0,
        string memory p1,
        bool p2,
        bool p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(bool,string,bool,bool)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        bool p0,
        string memory p1,
        bool p2,
        address p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(bool,string,bool,address)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        bool p0,
        string memory p1,
        address p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(bool,string,address,uint)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        bool p0,
        string memory p1,
        address p2,
        string memory p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(bool,string,address,string)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        bool p0,
        string memory p1,
        address p2,
        bool p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(bool,string,address,bool)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        bool p0,
        string memory p1,
        address p2,
        address p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(bool,string,address,address)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        bool p0,
        bool p1,
        uint256 p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(bool,bool,uint,uint)", p0, p1, p2, p3)
        );
    }

    function log(
        bool p0,
        bool p1,
        uint256 p2,
        string memory p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(bool,bool,uint,string)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        bool p0,
        bool p1,
        uint256 p2,
        bool p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(bool,bool,uint,bool)", p0, p1, p2, p3)
        );
    }

    function log(
        bool p0,
        bool p1,
        uint256 p2,
        address p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(bool,bool,uint,address)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        bool p0,
        bool p1,
        string memory p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(bool,bool,string,uint)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        bool p0,
        bool p1,
        string memory p2,
        string memory p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(bool,bool,string,string)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        bool p0,
        bool p1,
        string memory p2,
        bool p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(bool,bool,string,bool)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        bool p0,
        bool p1,
        string memory p2,
        address p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(bool,bool,string,address)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        bool p0,
        bool p1,
        bool p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(bool,bool,bool,uint)", p0, p1, p2, p3)
        );
    }

    function log(
        bool p0,
        bool p1,
        bool p2,
        string memory p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(bool,bool,bool,string)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        bool p0,
        bool p1,
        bool p2,
        bool p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3)
        );
    }

    function log(
        bool p0,
        bool p1,
        bool p2,
        address p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(bool,bool,bool,address)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        bool p0,
        bool p1,
        address p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(bool,bool,address,uint)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        bool p0,
        bool p1,
        address p2,
        string memory p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(bool,bool,address,string)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        bool p0,
        bool p1,
        address p2,
        bool p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(bool,bool,address,bool)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        bool p0,
        bool p1,
        address p2,
        address p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(bool,bool,address,address)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        bool p0,
        address p1,
        uint256 p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(bool,address,uint,uint)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        bool p0,
        address p1,
        uint256 p2,
        string memory p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(bool,address,uint,string)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        bool p0,
        address p1,
        uint256 p2,
        bool p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(bool,address,uint,bool)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        bool p0,
        address p1,
        uint256 p2,
        address p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(bool,address,uint,address)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        bool p0,
        address p1,
        string memory p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(bool,address,string,uint)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        bool p0,
        address p1,
        string memory p2,
        string memory p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(bool,address,string,string)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        bool p0,
        address p1,
        string memory p2,
        bool p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(bool,address,string,bool)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        bool p0,
        address p1,
        string memory p2,
        address p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(bool,address,string,address)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        bool p0,
        address p1,
        bool p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(bool,address,bool,uint)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        bool p0,
        address p1,
        bool p2,
        string memory p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(bool,address,bool,string)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        bool p0,
        address p1,
        bool p2,
        bool p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(bool,address,bool,bool)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        bool p0,
        address p1,
        bool p2,
        address p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(bool,address,bool,address)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        bool p0,
        address p1,
        address p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(bool,address,address,uint)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        bool p0,
        address p1,
        address p2,
        string memory p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(bool,address,address,string)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        bool p0,
        address p1,
        address p2,
        bool p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(bool,address,address,bool)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        bool p0,
        address p1,
        address p2,
        address p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(bool,address,address,address)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        address p0,
        uint256 p1,
        uint256 p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(address,uint,uint,uint)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        address p0,
        uint256 p1,
        uint256 p2,
        string memory p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(address,uint,uint,string)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        address p0,
        uint256 p1,
        uint256 p2,
        bool p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(address,uint,uint,bool)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        address p0,
        uint256 p1,
        uint256 p2,
        address p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(address,uint,uint,address)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        address p0,
        uint256 p1,
        string memory p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(address,uint,string,uint)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        address p0,
        uint256 p1,
        string memory p2,
        string memory p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(address,uint,string,string)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        address p0,
        uint256 p1,
        string memory p2,
        bool p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(address,uint,string,bool)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        address p0,
        uint256 p1,
        string memory p2,
        address p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(address,uint,string,address)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        address p0,
        uint256 p1,
        bool p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(address,uint,bool,uint)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        address p0,
        uint256 p1,
        bool p2,
        string memory p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(address,uint,bool,string)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        address p0,
        uint256 p1,
        bool p2,
        bool p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(address,uint,bool,bool)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        address p0,
        uint256 p1,
        bool p2,
        address p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(address,uint,bool,address)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        address p0,
        uint256 p1,
        address p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(address,uint,address,uint)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        address p0,
        uint256 p1,
        address p2,
        string memory p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(address,uint,address,string)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        address p0,
        uint256 p1,
        address p2,
        bool p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(address,uint,address,bool)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        address p0,
        uint256 p1,
        address p2,
        address p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(address,uint,address,address)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        address p0,
        string memory p1,
        uint256 p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(address,string,uint,uint)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        address p0,
        string memory p1,
        uint256 p2,
        string memory p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(address,string,uint,string)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        address p0,
        string memory p1,
        uint256 p2,
        bool p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(address,string,uint,bool)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        address p0,
        string memory p1,
        uint256 p2,
        address p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(address,string,uint,address)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        address p0,
        string memory p1,
        string memory p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(address,string,string,uint)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        address p0,
        string memory p1,
        string memory p2,
        string memory p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(address,string,string,string)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        address p0,
        string memory p1,
        string memory p2,
        bool p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(address,string,string,bool)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        address p0,
        string memory p1,
        string memory p2,
        address p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(address,string,string,address)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        address p0,
        string memory p1,
        bool p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(address,string,bool,uint)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        address p0,
        string memory p1,
        bool p2,
        string memory p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(address,string,bool,string)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        address p0,
        string memory p1,
        bool p2,
        bool p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(address,string,bool,bool)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        address p0,
        string memory p1,
        bool p2,
        address p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(address,string,bool,address)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        address p0,
        string memory p1,
        address p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(address,string,address,uint)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        address p0,
        string memory p1,
        address p2,
        string memory p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(address,string,address,string)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        address p0,
        string memory p1,
        address p2,
        bool p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(address,string,address,bool)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        address p0,
        string memory p1,
        address p2,
        address p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(address,string,address,address)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        address p0,
        bool p1,
        uint256 p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(address,bool,uint,uint)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        address p0,
        bool p1,
        uint256 p2,
        string memory p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(address,bool,uint,string)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        address p0,
        bool p1,
        uint256 p2,
        bool p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(address,bool,uint,bool)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        address p0,
        bool p1,
        uint256 p2,
        address p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(address,bool,uint,address)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        address p0,
        bool p1,
        string memory p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(address,bool,string,uint)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        address p0,
        bool p1,
        string memory p2,
        string memory p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(address,bool,string,string)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        address p0,
        bool p1,
        string memory p2,
        bool p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(address,bool,string,bool)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        address p0,
        bool p1,
        string memory p2,
        address p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(address,bool,string,address)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        address p0,
        bool p1,
        bool p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(address,bool,bool,uint)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        address p0,
        bool p1,
        bool p2,
        string memory p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(address,bool,bool,string)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        address p0,
        bool p1,
        bool p2,
        bool p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(address,bool,bool,bool)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        address p0,
        bool p1,
        bool p2,
        address p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(address,bool,bool,address)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        address p0,
        bool p1,
        address p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(address,bool,address,uint)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        address p0,
        bool p1,
        address p2,
        string memory p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(address,bool,address,string)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        address p0,
        bool p1,
        address p2,
        bool p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(address,bool,address,bool)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        address p0,
        bool p1,
        address p2,
        address p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(address,bool,address,address)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        address p0,
        address p1,
        uint256 p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(address,address,uint,uint)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        address p0,
        address p1,
        uint256 p2,
        string memory p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(address,address,uint,string)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        address p0,
        address p1,
        uint256 p2,
        bool p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(address,address,uint,bool)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        address p0,
        address p1,
        uint256 p2,
        address p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(address,address,uint,address)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        address p0,
        address p1,
        string memory p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(address,address,string,uint)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        address p0,
        address p1,
        string memory p2,
        string memory p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(address,address,string,string)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        address p0,
        address p1,
        string memory p2,
        bool p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(address,address,string,bool)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        address p0,
        address p1,
        string memory p2,
        address p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(address,address,string,address)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        address p0,
        address p1,
        bool p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(address,address,bool,uint)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        address p0,
        address p1,
        bool p2,
        string memory p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(address,address,bool,string)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        address p0,
        address p1,
        bool p2,
        bool p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(address,address,bool,bool)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        address p0,
        address p1,
        bool p2,
        address p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(address,address,bool,address)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        address p0,
        address p1,
        address p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(address,address,address,uint)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        address p0,
        address p1,
        address p2,
        string memory p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(address,address,address,string)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        address p0,
        address p1,
        address p2,
        bool p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(address,address,address,bool)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        address p0,
        address p1,
        address p2,
        address p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(address,address,address,address)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }
}

// File contracts/NFT/ERC721/ERC721NFTCollectionStorageStructure.sol

pragma solidity 0.8.11;

contract ERC721NFTCollectionStorageStructure {
    address public ERC721NFTCollectionImpl;

    CountersUpgradeable.Counter internal _tokenIds;

    bool public mintingStarted;
    bool public mintingEnded;

    address public marketplaceContractAddress;
    address public collectionCreatorAddress;
    address payable public feeWallet;

    uint256 public constant guaranteedWithNoDiscountSpot = 10001;

    uint256 public numberOfWhitelistedUsers;
    uint256 public tokenPrice;
    uint256 public maxMintAmount;
    uint256 public mintExpirationTime;
    uint256 public numberOfGuaranteedNFTs;

    uint256 public totalAllocated;
    uint256 public totalGuaranteedAllocated;
    uint256 public totalForAllAllocated;

    mapping(address => IERC721NFTCollection.Mintables) public whitelistedUsers;
    mapping(address => uint256) public tiers;
    address[] public winners;

    string public constant nftCollectionType = "ERC721";
    string public baseURI;
    bytes32 public baseURIHash;

    bytes32 public constant SUPER_ADMIN_ROLE = keccak256("SUPER_ADMIN_ROLE");
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant FPL_ROLE = keccak256("FPL_ROLE");
    bytes32 public constant COLLECTION_CREATOR_ROLE =
        keccak256("COLLECTION_CREATOR_ROLE");

    IPoolMechanics public poolMechanics;
}

// File contracts/NFT/ERC721/ERC721NFTCollectionProxy.sol

pragma solidity 0.8.11;

contract ERC721NFTCollectionProxy is
    ERC721NFTCollectionStorageStructure,
    ERC721URIStorageUpgradeable,
    AccessControlUpgradeable
{
    event ERC721NFTCollectionImplUpgraded(
        address indexed newImpl,
        address indexed oldImpl
    );

    error NotADifferentImpl();
    error MintExpirationTimeCanNotBeInThePast();
    error GuaranteedNFTsCanNotBeMoreThanMaxMintAmount();

    constructor() {
        _setupRole(SUPER_ADMIN_ROLE, _msgSender());
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Upgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function upgradeTo(address _newERC721NFTCollectionImplementation)
        external
        onlyRole(SUPER_ADMIN_ROLE)
    {
        if (ERC721NFTCollectionImpl == _newERC721NFTCollectionImplementation)
            revert NotADifferentImpl();

        _setERC721NFTCollectionImpl(_newERC721NFTCollectionImplementation);
    }

    function initialize(
        address[6] memory addresses,
        string memory name,
        string memory symbol,
        bytes32 _baseURIHash,
        uint256[4] memory variables
    ) public initializer onlyRole(SUPER_ADMIN_ROLE) {
        AccessControlUpgradeable.__AccessControl_init();
        ERC721URIStorageUpgradeable.__ERC721URIStorage_init();
        ERC721Upgradeable.__ERC721_init(name, symbol);

        baseURIHash = _baseURIHash;
        marketplaceContractAddress = addresses[0];
        poolMechanics = IPoolMechanics(addresses[1]);
        collectionCreatorAddress = addresses[2];
        feeWallet = payable(addresses[3]);

        tokenPrice = variables[0];
        maxMintAmount = variables[1];

        if (variables[2] <= block.timestamp)
            revert MintExpirationTimeCanNotBeInThePast();
        mintExpirationTime = variables[2];

        if (numberOfGuaranteedNFTs > variables[1])
            revert GuaranteedNFTsCanNotBeMoreThanMaxMintAmount();
        numberOfGuaranteedNFTs = variables[3];

        _setupRole(SUPER_ADMIN_ROLE, addresses[5]);
        _setupRole(ADMIN_ROLE, addresses[4]);
        _setupRole(FPL_ROLE, addresses[4]);
        _setupRole(COLLECTION_CREATOR_ROLE, collectionCreatorAddress);

        _setRoleAdmin(SUPER_ADMIN_ROLE, SUPER_ADMIN_ROLE);
        _setRoleAdmin(ADMIN_ROLE, ADMIN_ROLE);
        _setRoleAdmin(FPL_ROLE, ADMIN_ROLE);
        _setRoleAdmin(COLLECTION_CREATOR_ROLE, ADMIN_ROLE);
    }

    fallback() external payable {
        address opr = ERC721NFTCollectionImpl;
        require(opr != address(0));
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), opr, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    receive() external payable {}

    function _setERC721NFTCollectionImpl(address _newERC721NFTCollectionImpl)
        internal
    {
        address oldImpl = ERC721NFTCollectionImpl;
        ERC721NFTCollectionImpl = _newERC721NFTCollectionImpl;
        emit ERC721NFTCollectionImplUpgraded(
            _newERC721NFTCollectionImpl,
            oldImpl
        );
    }
}

// File @openzeppelin/contracts/token/ERC20/[email protected]

// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// File contracts/interfaces/ISparkWorldToken.sol

pragma solidity 0.8.11;

interface ISparkWorldToken is IERC20 {
    // function setLocker(address _locker) external;

    function setAllocationAddresses(
        address _SeedAddr,
        address _StrategicRoundAddr,
        address _PrivateSaleAddr,
        address _PublicSaleAddr,
        address _TeamAllocationAddr,
        address _StakingAddr,
        address _EchosystemTreasuryAddr,
        address _LiquidityAddr,
        address _AdvisorsAddr,
        address _AirdropAddr
    ) external;

    function distributeTokens() external;

    function getFeeWallet() external returns (address);

    function setFeeWallet(address _newFeeWallet) external;
}

// File contracts/NFT/NFTCollectionFactory.sol

pragma solidity 0.8.11;

// import "./ERC1155/ERC1155NFTCollectionProxy.sol";

contract NFTCollectionFactory is Ownable {
    event NFTMarketPlaceAddressChanged(
        address indexed newNFTMarketPlace,
        address indexed oldNFTMarketPlace
    );
    event FeeWalletChanged(
        address indexed newFeeWallet,
        address indexed oldFeeWallet
    );
    event NewERC721NFTCollectionImplWasSet(
        address indexed newERC721NFTCollectionImpl,
        address indexed oldERC721NFTCollectionImpl
    );
    event NewERC1155NFTCollectionImplWasSet(
        address indexed newERC115NFTCollectionImpl,
        address indexed oldERC1155NFTCollectionImpl
    );
    event NFTCollectionCreated(
        address indexed nftCollection,
        string name,
        string symbol,
        bytes32 baseURIHash,
        // uint256 nftType,
        // uint256 price,
        // uint256 maxMintAmount,
        // uint256 mintExpirationTime,
        // uint256 numberOfGuaranteedNFTs,
        uint256[5] variables,
        address indexed collectionCreator
    );

    event NewSuperAdminWasSet(
        address indexed newSuperAdmin,
        address indexed oldSuperAdmin
    );

    error NotADifferentImpl();

    uint256 public constant ERC721Token = 721;
    uint256 public constant ERC1155Token = 1155;

    address[] public erc721NFTCollections;
    address[] public erc1155NFTCollections;
    address public marketplaceContract;
    address public poolMechanicsContract;
    address payable public feeWallet;
    address public erc721NFTCollectionImpl;
    address public erc1155NFTCollectionImpl;
    address public superAdmin;

    constructor(
        address _nftMarketplace,
        address _poolMechanicsContract,
        address _sparkWorldToken,
        address _erc721NFCollectionImpl,
        address _erc1155NFTCollectionImpl,
        address _superAdmin
    ) {
        marketplaceContract = _nftMarketplace;
        poolMechanicsContract = _poolMechanicsContract;

        erc721NFTCollectionImpl = _erc721NFCollectionImpl;
        erc1155NFTCollectionImpl = _erc1155NFTCollectionImpl;
        superAdmin = _superAdmin;

        feeWallet = payable(ISparkWorldToken(_sparkWorldToken).getFeeWallet());
    }

    function createNFTCollectionProxy(
        string memory name,
        string memory symbol,
        bytes32 baseURIHash,
        // uint256 nftType,
        // uint256 price,
        // uint256 maxMintAmount,
        // uint256 mintExpirationTime,
        // uint256 numberOfGuaranteedNFTs,
        uint256[5] memory _variables,
        address collectionCreator
    ) external onlyOwner returns (address) {
        if (_variables[0] == ERC721Token) {
            ERC721NFTCollectionProxy erc721NFTCollectionProxy = new ERC721NFTCollectionProxy();
            address erc721NFTCollectionProxyAddress = address(
                erc721NFTCollectionProxy
            );

            erc721NFTCollectionProxy.upgradeTo(erc721NFTCollectionImpl);

            uint256[4] memory variables = [
                _variables[1],
                _variables[2],
                _variables[3],
                _variables[4]
            ];
            address[6] memory addresses = [
                marketplaceContract,
                poolMechanicsContract,
                collectionCreator,
                feeWallet,
                _msgSender(),
                superAdmin
            ];

            erc721NFTCollectionProxy.initialize(
                addresses,
                name,
                symbol,
                baseURIHash,
                variables
            );

            erc721NFTCollections.push(erc721NFTCollectionProxyAddress);

            emit NFTCollectionCreated(
                erc721NFTCollectionProxyAddress,
                name,
                symbol,
                baseURIHash,
                _variables,
                collectionCreator
            );

            return erc721NFTCollectionProxyAddress;
        }
        // ToDo: un comment when ERC1155 is ready
        // else if (nftType == ERC1155Token) {
        //     ERC1155NFTCollectionProxy erc1155NFTCollectionProxy = new ERC1155NFTCollectionProxy();
        //     address erc1155NFTCollectionProxyAddress = address(
        //         erc1155NFTCollectionProxy
        //     );
        //     erc1155NFTCollectionProxy.upgradeTo(erc1155NFTCollectionImpl);
        //     erc1155NFTCollectionProxy.initialize(
        //         marketplaceContract,
        //         poolMechanicsContract,
        //         collectionCreator,
        //         feeWallet,
        //         _msgSender(),
        //         superAdmin,
        //         name,
        //         symbol,
        //         baseURIHash,
        //         price,
        //         maxMintAmount,
        //         mintExpirationTime
        //     );
        //     erc1155NFTCollections.push(erc1155NFTCollectionProxyAddress);
        //     emit NFTCollectionCreated(
        //         erc1155NFTCollectionProxyAddress,
        //         name,
        //         symbol,
        //         baseURIHash,
        //         nftType,
        //         price,
        //         maxMintAmount,
        //         mintExpirationTime,
        //         collectionCreator
        //     );
        //     return erc1155NFTCollectionProxyAddress;
        // }
        else return address(0);
    }

    function setNFTMarketPlace(address _nftMarketPlace) public onlyOwner {
        address oldNFTMarketPlace = marketplaceContract;
        marketplaceContract = _nftMarketPlace;
        emit NFTMarketPlaceAddressChanged(_nftMarketPlace, oldNFTMarketPlace);
    }

    function setFeeWallet(address newFeeWallet) public onlyOwner {
        address oldFeeWallet = feeWallet;
        feeWallet = payable(newFeeWallet);
        emit FeeWalletChanged(newFeeWallet, oldFeeWallet);
    }

    function setNewERC721NFTCollectionAddr(address ImpAdr) external onlyOwner {
        if (erc721NFTCollectionImpl == ImpAdr) revert NotADifferentImpl();

        address oldERC721NFTCollectionImpl = erc721NFTCollectionImpl;
        erc721NFTCollectionImpl = ImpAdr;
        emit NewERC721NFTCollectionImplWasSet(
            ImpAdr,
            oldERC721NFTCollectionImpl
        );
    }

    function setNewERC1155NFTCollectionAddr(address ImpAdr) external {
        if (erc1155NFTCollectionImpl == ImpAdr) revert NotADifferentImpl();

        address oldERC1155NFTCollectionImpl = erc1155NFTCollectionImpl;
        erc1155NFTCollectionImpl = ImpAdr;
        emit NewERC1155NFTCollectionImplWasSet(
            ImpAdr,
            oldERC1155NFTCollectionImpl
        );
    }

    function setNewSuperAdmin(address _superAdmin) external {
        address oldSuperAdmin = superAdmin;
        superAdmin = _superAdmin;
        emit NewSuperAdminWasSet(_superAdmin, oldSuperAdmin);
    }
}