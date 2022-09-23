/**
 *Submitted for verification at snowtrace.io on 2022-03-31
*/

/**
 *Submitted for verification at polygonscan.com on 2022-03-12
*/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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
    function allowance(address owner, address spender) external view returns (uint256);

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
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


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

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
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

// File: @openzeppelin/contracts/utils/Address.sol


// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
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
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
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
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
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
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
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
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
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
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
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

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


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

// File: @openzeppelin/contracts/utils/introspection/ERC165.sol


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
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// File: @openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;


/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// File: @openzeppelin/contracts/token/ERC1155/IERC1155.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;


/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// File: @openzeppelin/contracts/token/ERC1155/extensions/IERC1155MetadataURI.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;


/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// File: @openzeppelin/contracts/token/ERC1155/ERC1155.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC1155/ERC1155.sol)

pragma solidity ^0.8.0;







/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {
    using Address for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    constructor(string memory uri_) {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: balance query for the zero address");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, _asSingletonArray(id), _asSingletonArray(amount), data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, _asSingletonArray(id), _asSingletonArray(amount), data);

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), _asSingletonArray(id), _asSingletonArray(amount), "");

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);
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
        require(owner != operator, "ERC1155: setting approval status for self");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
}

// File: contracts/Official WM/walletmonsters_v3.sol


pragma solidity ^0.8.7;





//Created By The Suns Of DeFi | S.O.D
contract WalletMonsters is ERC1155, Ownable, IERC1155Receiver{
    
    //state variable
    uint256 nextId = 0;
    uint256 eightHours = 28800; 
    uint256 escrowedAmountTotal = 0;
    uint public faucetPrice;
    address reserves;
    address escrowedValut; 
    address payable public FULLSTACKCALI;
    uint256 amountBurned = 0;
    
    string public name;
    string public symbol;
 
    //Mappings
    mapping(uint256 => Enjimon) private _tokenDetails; 
    mapping(address => uint) balance;
    mapping(uint256 => uint256) public enjimonTVL;
    mapping(address => mapping(uint => uint)) public _hold; 
    
    mapping(address => mapping(uint256 => bool))activeItems; 

    mapping(address => bool) public tokenApproved;
 
    //Dapp Events
    event bornDate(address from, string name, uint256 enjimonID, uint256 date);
    event tokenSupplyMinted(address from, uint256 tokenID, uint256 amount, uint256 date);
    event artifactMinted(address from, uint256 tokenID, uint256 amount, uint256 date);
    event tokenSupplyBurned(address from, uint256 tokenID, uint256 amount, uint256 date);
    event itemBurned(address from, uint256 tokenID, uint256 amount, uint256 date);
    event enjimonSlayed(address from, uint256 tokenID, string name,uint256 TVL ,uint256 date);
    event enjimonFed(address from, uint256 enjimonID, string name, uint256 lastFed );
    event enjimonTrained(address from, uint256 enjimonID, string name, uint lastTrainded);
    event transferEnjimon(address from, address to, uint256 tokenId, string name);
    event transferItem(address from, address to, uint256 tokenId);
    event burnedCount(uint256 tokenID, uint256 amount, uint256 date);
    
    //Marketplace events
    event itemAdded(uint256 id, uint256 tokenId, address tokenAddress,uint amount ,uint256 askingPrice);
    event enjimonAdded(uint256 id, uint256 tokenId, address tokenAddress, uint256 askingPrice);
    event itemSold(uint256 id, address buyer,uint256 amount, uint256 askingPrice);
    event enjimonSold(uint256 id, address buyer,uint256 amount, uint256 askingPrice);
    event itemRemoved(uint256 id, address seller, uint256 amount, uint256 askingPrice, uint256 date); 
    event enjimonRemoved(uint256 id, address seller, uint256 amount, uint256 askingPrice, uint256 date); 

    struct Enjimon {
            string enjimonName;
            string nickname;
            uint256 healthPoints; 
            uint256 defense; 
            uint256 attack; 
            uint256 endurance;
            uint256 level;
            uint256 lastMeal;
            uint256 lastTrained;
            string enjimonType;
            string  sex;
            uint256 TVL;
    }
    
    struct AuctionItem {
            uint256 id;
            address tokenAddress;
            uint256 tokenId;
            address payable seller;
            uint256 askingPrice;
            uint256 units;
            bool isSold;
        }
        
    AuctionItem[] public itemsForSale;

    //Market Modifiers
    modifier OnlyItemOwner(address tokenAddress, uint256 tokenId)
        {
            IERC1155 tokenContract = IERC1155(tokenAddress);
            require(tokenContract.balanceOf(msg.sender, tokenId) > 0); 
            _;
        }   
    modifier HasTransferApproval(address tokenAddress, uint256 tokenId)
        {
            IERC1155 tokenContract = IERC1155(tokenAddress);
            require(tokenContract.isApprovedForAll(msg.sender, address(this)) == true); 
            _;
        }
    modifier ItemExist(uint256 id) 
        {
            require(id < itemsForSale.length && itemsForSale[id].id == id,"can't find id");
            _;
        }
    modifier IsForSale(uint256 id) 
        {
            require(itemsForSale[id].isSold == false,"id already sold");
            _;
        }
 
 
    constructor() ERC1155("https://oxitcquxqc4e.usemoralis.com/{id}.json") {
        
        reserves = 0xC686855C52C918Fb7b18E8dc149CFecF4Fa2E574;
        FULLSTACKCALI = payable(msg.sender);
        faucetPrice = 2500000000000000;
        escrowedValut = address(this);
        tokenApproved[0x1CD842709cFdf49d991bC1D507bFb06574Da4FCa] = true;

        name = "Immutable World of Wallet Monsters";
        symbol = "WMON";
       
    
        _mint(msg.sender, nextId, 10**8, ""); //UUJI
        nextId++;

        _mint(msg.sender, nextId, 10000**1, ""); //potions
        nextId++;

        _mint(msg.sender, nextId, 25000**1, ""); //eATK
        nextId++;

        _mint(msg.sender, nextId, 25000**1, ""); //eDef
        nextId++;

        _mint(msg.sender, nextId, 2000**1, ""); //elixer
         nextId++;

        _mint(msg.sender, nextId, 2500**1, ""); //walle
        
        nextId++; //6
                
        setApprovalForAll(address(this), true);

    }
   
     function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external override pure returns (bytes4)
    {
 
       return this.onERC1155Received.selector;
    }
    
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external override pure returns (bytes4)
    {
        return this.onERC1155BatchReceived.selector;
    }

    function Randomness() private view returns (uint) {
     
        return ((uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp))) % 10)+ 1);
    } 

    function mintMonster(string memory enjimonName, uint256 healthPoints, uint256 defense, uint256 attack, uint256 endurance, uint256 level, string memory enjimonType,  string memory sex) public onlyOwner {

        _tokenDetails[nextId] = Enjimon(enjimonName,"unnamed", healthPoints, defense, attack, endurance, level, block.timestamp, block.timestamp, enjimonType, sex, 0);
        
        _mint(msg.sender, nextId, 1, "");
        
        
        
        emit bornDate(msg.sender, enjimonName, nextId, block.timestamp);
        
        nextId++;
   
    }
    
function trainerMarket(uint256 itemId, uint256 amount) public  {
         require(msg.sender != FULLSTACKCALI, "Not allowed");
         require(itemId != 0, "Invalid ID"); 
         require(itemId != 1, "Invalid ID"); 
         require(itemId < 4, "only eDEF, and eATK"); 
         require(balanceOf(msg.sender, 0) >= (50 * amount), "not enough UUJI");
         
         
         
         if(amount > 1){
             
             uint txAmount = amount * 50;
             uint txCost =  txAmount / 2;
             
             amountBurned+= txCost;

             _burn(msg.sender, 0, txCost); 
            _safeTransferFrom(msg.sender, reserves, 0, txCost, ""); 
           
            emit burnedCount(0, amountBurned, block.timestamp);

         }
         else
         {
             amountBurned+= 25;
             _burn(msg.sender, 0, 25); 
            _safeTransferFrom(msg.sender, reserves, 0, 25, ""); 

            emit burnedCount(0, amountBurned, block.timestamp);
         }
         
        _mint(msg.sender, itemId, amount, "");
       
        if(isApprovedForAll(msg.sender, address(this)) == false){
            
            setApprovalForAll(escrowedValut, true);
        }
        
        
        emit artifactMinted(msg.sender, itemId, amount, block.timestamp);  
    }
    
    function burn(address account, uint256 id, uint256 amount) public onlyOwner {
        require(id < 6, "cant burn $Enjimon"); 
       
        if(id == 0)
        {
            require(amount < escrowedAmountTotal, "can't burn Escrowed value, decrease");
            
             _burn(account, id, amount);
             amountBurned+= amount;

             emit tokenSupplyBurned(msg.sender, id, amount, block.timestamp);
             emit burnedCount(0, amountBurned, block.timestamp);
        }
        else
        {
            _burn(account, id, amount);
            amountBurned+= amount;
            emit itemBurned(msg.sender, id, amount, block.timestamp);
            emit burnedCount(0, amountBurned, block.timestamp);
        }
     
    }

   function useWaly(address token,uint tokenId) public {
        require(tokenApproved[token] == true, "We don't accept those");
        require(tokenId != 0 && tokenId < 6);
        require(balanceOf(FULLSTACKCALI, tokenId) >= 50, "Reserves Depleted.");
        

        IERC20(token).transferFrom(msg.sender, reserves, 50000 *(10**18));

        _safeTransferFrom(FULLSTACKCALI, msg.sender, tokenId, 1, '');


  
}
    
    function faucet() payable public returns(uint UUJIs){
        require(balanceOf(FULLSTACKCALI, 0) >= 50, "faucet is empty, check later.");
        require(msg.value >= faucetPrice, "Not enough to cover tx");
        
        FULLSTACKCALI.transfer(msg.value);
        _safeTransferFrom(FULLSTACKCALI, msg.sender, 0, 50, '');

        return UUJIs;
    }

    function setFaucet(uint _cost) public onlyOwner returns(uint){
            faucetPrice = _cost;

            return faucetPrice;
    }


    //$Enjimon interaction logic
    function slay(address account, uint256 amount, uint256 enjimonId) public 
    {
         
        require(enjimonId >= 6, "only slay $Enjimon"); 
        require(balanceOf(msg.sender, enjimonId) > 0, "Not your $Enjimon"); 
        require(_hold[msg.sender][enjimonId] == 0, "$Enjimon unavailable");
        
        
        Enjimon storage enjimon =_tokenDetails[enjimonId];
        
        require(enjimon.lastMeal + enjimon.endurance > block.timestamp, "$Enjimon reached Immutable Death");
        require(enjimon.TVL > 0, "Can Not slay yet");

        uint256 _amount = enjimonTVL[enjimonId]; 
        enjimonTVL[enjimonId] = 0;  
        enjimon.TVL = 0; 
            
        _safeTransferFrom(escrowedValut, msg.sender, 0, _amount, ""); 
        _burn(account, enjimonId, amount); 
        
        emit enjimonSlayed(msg.sender, enjimonId, enjimon.enjimonName,_amount ,block.timestamp);
    }
     
    function feed(uint256 tokenId) public {
        require(tokenId >= 6, "invalid ID");
        require(balanceOf(msg.sender, tokenId) > 0); 
        
        Enjimon storage enjimon = _tokenDetails[tokenId]; 
        
        uint uujiBalance = balanceOf(msg.sender, 0);
        
         if(_hold[msg.sender][0] > 0){
             uint256 restrictedUnits = _hold[msg.sender][0];
             
             uint256 txFee = (50 + (27 + enjimon.level)) + restrictedUnits;
             
            require(uujiBalance > txFee, "exceeds available UUJIs");
        }
        
        require(enjimon.lastMeal + enjimon.endurance > block.timestamp, "$Enjimon reached Immutable Death"); 
        require(uujiBalance > (50 + (27 + enjimon.level)), "Not enough UUJI Tokens"); 
        
        _burn(msg.sender, 0, 25 ); 
        _escrow(25, tokenId); 
        _safeTransferFrom(msg.sender, reserves, 0, 27 + enjimon.level, "");  

        amountBurned+= 25;

        enjimon.lastMeal = block.timestamp; 
        enjimon.TVL+= 25; 
         
        escrowedAmountTotal+= 25; 
        
        emit enjimonFed(msg.sender, tokenId,  enjimon.enjimonName, block.timestamp);
        emit burnedCount(0, amountBurned, block.timestamp);
    }
    
    function train(uint256 tokenId) public {
        require(tokenId >= 6, "invalid ID");
        require(balanceOf(msg.sender, tokenId) > 0);
        
        Enjimon storage enjimon =_tokenDetails[tokenId];
        uint uujiBalance = balanceOf(msg.sender, 0);
        
         if(_hold[msg.sender][0] > 0){
             uint256 restrictedUnits = _hold[msg.sender][0];
             
             uint256 txFee = (100 + (27 + enjimon.level)) + restrictedUnits;
             
            require(uujiBalance > txFee, "UUJI unavailable");
        }
        
        require(block.timestamp > enjimon.lastTrained + eightHours);
        require(uujiBalance > (100 + (27 + enjimon.level)), "Not enough UUJI"); 
        require(enjimon.lastMeal + enjimon.endurance > block.timestamp, "$Enjimon reached Immutable Death");
     
         _burn(msg.sender, 0, 50 );
         _escrow(50, tokenId);
         _safeTransferFrom(msg.sender, reserves, 0, 27 + enjimon.level, "");
         amountBurned+= 50;
       
        uint index = Randomness();
      
         
        enjimon.lastTrained = block.timestamp;
        enjimon.level+=1;
        enjimon.endurance+=(3600 + index); 
        enjimon.defense+=(2 + index);
        enjimon.attack+=(1 + index);
        enjimon.healthPoints+=index;
        enjimon.TVL+= 50;
        
        escrowedAmountTotal+= 50;
        
        emit enjimonTrained(msg.sender, tokenId, enjimon.enjimonName, block.timestamp);
        emit burnedCount(0, amountBurned, block.timestamp);
    }

    function givePotion(uint256 tokenId) public {
        require(tokenId >= 6, "Invalid ID");
        require(balanceOf(msg.sender, 1) > 0); 
        require(balanceOf(msg.sender, tokenId) > 0);
        
        if(_hold[msg.sender][1] > 0){
             uint256 restrictedUnits = _hold[msg.sender][1];
             require(balanceOf(msg.sender, 1) > restrictedUnits); 
        }
        
        Enjimon storage enjimon =_tokenDetails[tokenId];
        uint uujiBalance = balanceOf(msg.sender, 0);
        
        require(uujiBalance > 10, "Not enough UUJI");
        require(enjimon.lastMeal + enjimon.endurance > block.timestamp, "$Enjimon reached Immutable Death"); 

        _burn(msg.sender, 0, 5); 
        _burn(msg.sender, 1, 1); 
        _safeTransferFrom(msg.sender, reserves, 0, 5, ""); 

        amountBurned+= 5;

        uint index = Randomness();
        
        index+=5;

        enjimon.healthPoints+=index;

        emit burnedCount(0, amountBurned, block.timestamp);

    }

    function giveEATK(uint256 tokenId) public{
        require(tokenId >= 6, "Invalid ID");
        require(balanceOf(msg.sender, 2) > 0); 
        require(balanceOf(msg.sender, tokenId) > 0); 
        
        if(_hold[msg.sender][2] > 0){
             uint256 restrictedUnits = _hold[msg.sender][2];
             require(balanceOf(msg.sender, 2) > restrictedUnits); 
        }
        
        Enjimon storage enjimon =_tokenDetails[tokenId];
        uint uujiBalance = balanceOf(msg.sender, 0);

        require(uujiBalance > 10, "Not enough UUJI"); 
        require(enjimon.lastMeal + enjimon.endurance > block.timestamp, "$Enjimon reached Immutable Death");
        
        _burn(msg.sender, 0, 5); //burn uuji
        _burn(msg.sender, 2, 1); //burn eATK
        _safeTransferFrom(msg.sender, reserves, 0, 5, "");

        amountBurned+= 5;

        uint index = Randomness();
        
        enjimon.attack+=index;

        emit burnedCount(0, amountBurned, block.timestamp);

    }

    function giveEDEF(uint256 tokenId) public{
        require(tokenId >= 6, "Invalid ID");
        require(balanceOf(msg.sender, 3) > 0); 
        require(balanceOf(msg.sender, tokenId) > 0); 
        
        if(_hold[msg.sender][3] > 0){
             uint256 restrictedUnits = _hold[msg.sender][3];
             require(balanceOf(msg.sender, 3) > restrictedUnits); 
        }
        
        Enjimon storage enjimon =_tokenDetails[tokenId];
        uint uujiBalance = balanceOf(msg.sender, 0);

        require(uujiBalance > 10, "Not enough UUJI"); 
        require(enjimon.lastMeal + enjimon.endurance > block.timestamp, "$Enjimon reached Immutable Death");
        
        _burn(msg.sender, 0, 5); 
        _burn(msg.sender, 3, 1); 
        _safeTransferFrom(msg.sender, reserves, 0, 5, "");
        amountBurned+= 5;

        uint index = Randomness();
        
        enjimon.defense+=index;
        emit burnedCount(0, amountBurned, block.timestamp);

    }

    function giveElixer(uint256 tokenId) public{
        require(tokenId >= 6, "Invalid ID");
        require(balanceOf(msg.sender, 4) > 0, "no elixers!"); 
        require(balanceOf(msg.sender, tokenId) > 0); 
        
        if(_hold[msg.sender][4] > 0){
             uint256 restrictedUnits = _hold[msg.sender][4];
             require(balanceOf(msg.sender, 4) > restrictedUnits);
        }
        
        Enjimon storage enjimon =_tokenDetails[tokenId];
        uint uujiBalance = balanceOf(msg.sender, 0);
        

        require(uujiBalance > 10, "Not enough UUJI Tokens");
        require(enjimon.lastMeal + enjimon.endurance > block.timestamp, "$Enjimon reached Immutable Death"); 
        
        _burn(msg.sender, 0, 5); 
        _burn(msg.sender, 4, 1); 
        _safeTransferFrom(msg.sender, reserves, 0, 5, "");

        amountBurned+= 5;

        uint index = Randomness();

        enjimon.healthPoints+= index;
        enjimon.level+= 1;
        enjimon.endurance+=(900 + index);
        enjimon.defense+=1;
        enjimon.attack+=1;

        emit burnedCount(0, amountBurned, block.timestamp);
    }
    function giveWalle(uint256 tokenId)public{
        require(tokenId >= 6, "Invalid ID");
        require(balanceOf(msg.sender, 5) > 0, "no walle"); 
        require(balanceOf(msg.sender, tokenId) > 0);   

        Enjimon storage enjimon =_tokenDetails[tokenId];

        _burn(msg.sender, 5, 1); 

        enjimon.lastMeal = block.timestamp;

    }
    function _escrow(uint amount, uint tokenId) private {
        
       uint256 previousEnjimonBalance = enjimonTVL[tokenId];
       
        enjimonTVL[tokenId] += amount;
       
       _safeTransferFrom(msg.sender, escrowedValut, 0, amount, "");
  
       assert((enjimonTVL[tokenId] - amount) == previousEnjimonBalance);
    
    }
    
    function getTokenDetails(uint256 tokenId) public view returns(Enjimon memory){
        return _tokenDetails[tokenId];
 }
    
 
     
    function giveEnjimonName(uint enjimonId, string memory _name) public returns(string memory nickname)
    {
        require(enjimonId >= 6, "You can only name $Enjimon!");
        require(balanceOf(msg.sender, enjimonId) > 0, "you can only give your $Enjimon nickname!");
        require(balanceOf(msg.sender, 0) > 10, "not enough UUJI");
        
        Enjimon storage enjimon =_tokenDetails[enjimonId];
        require(enjimon.lastMeal + enjimon.endurance > block.timestamp, "$Enjimon reached Immutable Death"); 

        _burn(msg.sender, 0, 5);
        _safeTransferFrom(msg.sender, reserves, 0, 3, "");
        _escrow(2, enjimonId);
        amountBurned+= 5;

        enjimon.nickname = _name;
        enjimon.TVL+= 2;
        
        escrowedAmountTotal+= 2;
        emit burnedCount(0, amountBurned, block.timestamp);
        return enjimon.nickname;
        
    }
    
     //requires enjimon to be alive or they can never transfer the token
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        uint256 amount,
        bytes memory data
    ) public virtual  override {
         
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );
        
        if(tokenId >= 6 ){
              Enjimon storage enjimon =_tokenDetails[tokenId];

              require(enjimon.lastMeal + enjimon.endurance > block.timestamp, "$Enjimon reached Immutable Death"); 
              require(_hold[msg.sender][tokenId] == 0, "$Enjimon unavailable");
            
             _safeTransferFrom(from, to, tokenId, 1, data);
             
             emit transferEnjimon(msg.sender, to, tokenId, enjimon.enjimonName);
        }
        else{
            
             if(_hold[msg.sender][0] > 0){
                uint uujiBalance = balanceOf(msg.sender, 0);
                
                uint256 restrictedUnits = _hold[msg.sender][0];
             
                require(uujiBalance > restrictedUnits);
                require(amount <= (uujiBalance - restrictedUnits));
            }
            else if(_hold[msg.sender][tokenId] > 0)
            {
                uint totalItems = balanceOf(msg.sender, tokenId);

                uint256 restrictedUnits = _hold[msg.sender][tokenId];

                require(balanceOf(from, tokenId) > restrictedUnits); 
                require(amount <= (totalItems - restrictedUnits));
            }
            
            _safeTransferFrom(from, to, tokenId, amount, data);
            
            emit transferItem(from, to, tokenId);
            
        }
    }
    
    //Market functionality
    function additemToMarket(uint256 tokenId, uint256 units, uint256 askingPrice) OnlyItemOwner(address(this),tokenId) HasTransferApproval(address(this),tokenId) public returns(uint256){
            require(tokenId < 6, "Invalid ID");
            require(balanceOf(msg.sender, tokenId) >= units, "not enough tokens available!");
            
            _hold[msg.sender][tokenId] += units; 
                
            uint256 newItemId = itemsForSale.length;
            
            itemsForSale.push(AuctionItem(newItemId, address(this), tokenId, payable(msg.sender), askingPrice, units, false));
            
            activeItems[address(this)][tokenId] = true; 
            setApprovalForAll(escrowedValut, true);
                
            assert(itemsForSale[newItemId].id == newItemId);
            emit itemAdded(newItemId, tokenId, address(this), units ,askingPrice);
                
            return newItemId;
            
        }
        
    function addEnjimonToMarket(uint256 tokenId,  uint256 askingPrice) OnlyItemOwner(address(this),tokenId) HasTransferApproval(address(this),tokenId) public returns(uint256){
            require(tokenId >= 6, "Invalid ID");
            require(balanceOf(msg.sender, tokenId) == 1, "no $Enjimon");
            require(activeItems[address(this)][tokenId] == false,"Item for sale already");

            Enjimon storage enjimon =_tokenDetails[tokenId];    
            require(enjimon.lastMeal + enjimon.endurance > block.timestamp, "$Enjimon in Immutable Death");            
            
            _hold[msg.sender][tokenId] = 1;
            
            uint256 newItemId = itemsForSale.length;
            
            itemsForSale.push(AuctionItem(newItemId, address(this), tokenId, payable(msg.sender), askingPrice, 1, false));
            
            activeItems[address(this)][tokenId] = true;
            setApprovalForAll(escrowedValut, true);
            
            assert(itemsForSale[newItemId].id == newItemId);
            emit enjimonAdded(newItemId, tokenId, address(this), askingPrice);
            
            return newItemId;
            
        }

    function buyItem(uint256 id) payable public ItemExist(id) IsForSale(id) {
            require(msg.sender != itemsForSale[id].seller, "cannot buy your own item, remove instead");
            require(msg.value >= itemsForSale[id].askingPrice, "Not enough funds sent"); 
            require(balanceOf(msg.sender, 0) >= 10, "You nedd 10 UUJI min.");
    
            
            if(itemsForSale[id].tokenId >= 6)
            {
                Enjimon storage enjimon =_tokenDetails[itemsForSale[id].tokenId];
                require(enjimon.lastMeal + enjimon.endurance > block.timestamp, "$Enjimon's in Immutable Death");

                _hold[itemsForSale[id].seller][itemsForSale[id].tokenId] = 0;

                itemsForSale[id].isSold = true; 
                activeItems[itemsForSale[id].tokenAddress][itemsForSale[id].tokenId] = false; 
            
                _safeTransferFrom(itemsForSale[id].seller, msg.sender, itemsForSale[id].tokenId, 1, '');
                 itemsForSale[id].seller.transfer(msg.value);
                 
                 //UUJI Fees
                _safeTransferFrom(msg.sender, itemsForSale[id].seller, 0, 5, '');
                _safeTransferFrom(msg.sender, FULLSTACKCALI, 0, 2, '');
                _burn(msg.sender, 0, 3);
                amountBurned+=3;

                emit enjimonSold(id, msg.sender, 1 ,itemsForSale[id].askingPrice);
                emit burnedCount(0, amountBurned, block.timestamp);
                
            }
            else
            {
                _hold[itemsForSale[id].seller][itemsForSale[id].tokenId]-= itemsForSale[id].units;

                itemsForSale[id].isSold = true; 
                activeItems[itemsForSale[id].tokenAddress][itemsForSale[id].tokenId] = false; 
                
                _safeTransferFrom(itemsForSale[id].seller, msg.sender, itemsForSale[id].tokenId, itemsForSale[id].units, '');
                
                itemsForSale[id].seller.transfer(msg.value); 
                
                
                _safeTransferFrom(msg.sender, itemsForSale[id].seller, 0, 5, '');
                _safeTransferFrom(msg.sender, FULLSTACKCALI, 0, 2, '');
                _burn(msg.sender, 0, 3);
                amountBurned+=3;
                emit itemSold(id, msg.sender, itemsForSale[id].units ,itemsForSale[id].askingPrice);
                emit burnedCount(0, amountBurned, block.timestamp);
            }
           
        }
    
    function removeItem(uint256 id) public ItemExist(id) IsForSale(id) returns(bool success){
            require(msg.sender == itemsForSale[id].seller);

            activeItems[itemsForSale[id].tokenAddress][itemsForSale[id].tokenId] = false;
            itemsForSale[id].isSold = true;

            _hold[msg.sender][itemsForSale[id].tokenId] -= itemsForSale[id].units;
             
            delete itemsForSale[id];

            if(itemsForSale[id].tokenId >= 6){
                emit enjimonRemoved(id, msg.sender, itemsForSale[id].units , itemsForSale[id].askingPrice, block.timestamp); 
            }else{
                emit itemRemoved(id, msg.sender, itemsForSale[id].units , itemsForSale[id].askingPrice, block.timestamp); 
            }  
            

             return success;
            
        }  
}