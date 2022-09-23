/**
 *Submitted for verification at snowtrace.io on 2022-03-04
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

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

interface IERC721Mintable is IERC721 {
    /**
     * @dev Creates a new token for the given `owner`.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     *
     */
    function mint(address _to) external;
}

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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

/**
 * @dev String operations.
 */
library Strings {
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
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
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

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

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

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting with custom message on overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, errorMessage);

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on underflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot underflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction underflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on underflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot underflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, errorMessage);

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers.
     * Reverts on division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers.
     * Reverts with custom message on division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
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

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

library RemoveElement {

    function find(address[] storage values, address value) internal view returns(uint) {
        uint i = 0;
        while (values[i] != value) {
            i++;
        }
        return i;
    }

    function removeByValue(address[] storage values, address value) internal returns(address[] storage) {
        uint i = find(values, value);
        address[] storage newvalues = removeByIndex(values, i);
        return newvalues;
    }

    function removeByIndex(address[] storage values, uint i) internal returns(address[] storage) {
        while (i < values.length-1) {
            values[i] = values[i+1];
            i++;
        }
        values.pop();
        return values;
    }

    function remove(address[] storage values, uint i) internal returns(address[] storage) {
        values[i] = values[values.length - 1];
        values.pop();
        return values;
    }
}

/**
 * @dev Heroes Chained Raffle Contract Part-1.
 */
contract HC_Raffle_p1 is Ownable, ReentrancyGuard, Pausable {
    using SafeERC20 for IERC20;
    using RemoveElement for address[];

    /* ========== STATE VARIABLES ========== */
    IERC721Mintable public nftContractAddress;
    IERC20 public depositTokenAddress;

    uint256 public maxNFTCountForRaffle;
    uint256 public depositAmountPerNFT;
    uint256 public pricePerNFT;
    uint256 public maxDepositAmount;
    uint256 public mintableNFTs;
    uint256 public numberOfTicketsExemptFromDraw;

    uint256 private totalMintedNFTCount;
    uint256 private totalRemainingDepositAmount;

    address[] private participants;

    mapping(address => uint256) private balances;
    address[] private depositList;

    mapping(address => uint256) private w1;
    mapping(address => uint256) private w2;
    mapping(address => uint256) private userDepositAmount;

    uint256 public depositStartTime;
    uint256 public depositEndTime;

    uint256 public phase1MintingStartTime;
    uint256 public phase1MintingEndTime;

    uint256 public phase2MintingStartTime;
    uint256 public phase2MintingEndTime;

    uint256 public phase3MintingStartTime;
    uint256 public phase3MintingEndTime;

    bool private isRaffleCompleted;
    uint public raffleState;
    uint private oldRaffleState;

    uint private totalW1Count;
    uint private totalW1MintedCount;

    uint private totalW2Count;
    uint private totalW2MintedCount;

    uint private totalW3MintedCount;

    /* ========== EVENTS ========== */
    event JoinEvent(uint _length, uint _qty);    

    /* ========== RAFFLE STATES ========== */
    uint private constant NOT_INITIALIZED = 0;
    uint private constant DEPOSIT_PERIOD = 1;
    uint private constant PHASE1_DRAW_COMPLETED = 2;
    uint private constant PHASE1_MINTING_PERIOD = 3;
    uint private constant PHASE2_DRAW_COMPLETED = 4;
    uint private constant PHASE2_MINTING_PERIOD = 5;
    uint private constant PHASE3_MINTING_PERIOD = 6;
    uint private constant RAFFLE_COMPLETED = 7;

    /* ========== CONSTRUCTOR ========== */
    constructor(
        address _depositTokenAddress,
        uint256 _maxNFTCountForRaffle,
        uint256 _pricePerNFT,
        uint256 _depositAmountPerNFT,
        uint256 _maxDepositAmount,
        uint256 _numberOfTicketsExemptFromDraw
    ) 
    {
        require(_maxNFTCountForRaffle > 0, "maxNFTCountForRaffle must be greater than 0");
        require(_pricePerNFT > 0, "pricePerNFT must be greater than 0");
        require(_depositAmountPerNFT > 0, "depositAmountPerNFT must be greater than 0");
        require(_depositAmountPerNFT < _pricePerNFT, "depositAmountPerNFT must be smaller than pricePerNFT");
        require(_maxDepositAmount % _depositAmountPerNFT == 0, "maxDepositAmount must be a multiple of depositAmountPerNFT");
        require(_numberOfTicketsExemptFromDraw < _maxNFTCountForRaffle, "numberOfTicketsExemptFromDraw must be smaller than maxNFTCountForRaffle");

        depositTokenAddress = IERC20(_depositTokenAddress);

        maxNFTCountForRaffle = _maxNFTCountForRaffle;
        depositAmountPerNFT = _depositAmountPerNFT;
        pricePerNFT = _pricePerNFT;
        maxDepositAmount = _maxDepositAmount;
        numberOfTicketsExemptFromDraw = _numberOfTicketsExemptFromDraw;
        isRaffleCompleted = false;
    }    

    /* ========== END USER FUNCTIONS ========== */
    function withdrawDeposit() external nonReentrant whenNotPaused {
        require(isRaffleCompleted, "Raffle has not ended. Cannot withdraw funds at the moment.");
        require(w2[msg.sender] > 0, "Insufficient balance");

        uint256 amount = w2[msg.sender] * depositAmountPerNFT;
        totalRemainingDepositAmount -= amount;

        totalW2Count = totalW2Count - w2[msg.sender];
        w2[msg.sender] = 0;
        
        depositTokenAddress.safeTransfer(msg.sender, amount);
    }

    function depositRaffle(uint256 depositAmount) external nonReentrant whenNotPaused returns(bool) {
        require(depositStartTime <= block.timestamp, "Deposit period has not started yet");
        require(block.timestamp <= depositEndTime, "Deposit period ended");
        require(depositAmount >= depositAmountPerNFT, "Deposit amount must be greater than or equal to ticket price");
        require(depositAmount % depositAmountPerNFT == 0, "Deposit amount must be a multiple of ticket price");
        require((userDepositAmount[msg.sender] + depositAmount) <= maxDepositAmount, "Deposit amount exceeds maximum deposit amount"); 

        deposit(depositAmount);

        userDepositAmount[msg.sender] = userDepositAmount[msg.sender] + depositAmount;
        uint256 ticketnum = depositAmount / depositAmountPerNFT;

        uint256 ticketnumExemptFromDraw = ticketnum;

        if ((mintableNFTs + ticketnum) > numberOfTicketsExemptFromDraw)
            ticketnumExemptFromDraw = numberOfTicketsExemptFromDraw - mintableNFTs;

        if (ticketnumExemptFromDraw > 0) {
            mintableNFTs = mintableNFTs + ticketnumExemptFromDraw;
            w1[msg.sender] += ticketnumExemptFromDraw;              
            totalW1Count += ticketnumExemptFromDraw;
            balances[msg.sender] -= ticketnumExemptFromDraw * depositAmountPerNFT;
            totalRemainingDepositAmount -= ticketnumExemptFromDraw * depositAmountPerNFT;
        }
        
        for (uint j = 0; j < ticketnum - ticketnumExemptFromDraw; j++) {
            participants.push(msg.sender);
        }

        emit JoinEvent(participants.length, ticketnum);
        return true;
    }

    function mint() external nonReentrant whenNotPaused returns(bool) {
        if (raffleState == PHASE1_MINTING_PERIOD)
            return phase1Mint();
        else if (raffleState == PHASE2_MINTING_PERIOD)
            return phase2Mint();
        else if (raffleState == PHASE3_MINTING_PERIOD)
            return phase3Mint();

        revert("Minting is currently inactive.");
    }

    function getPrizeCount() external view returns(uint)
    {
        if (raffleState == PHASE1_MINTING_PERIOD || raffleState == DEPOSIT_PERIOD)
            return w1[msg.sender];
        else if (raffleState == PHASE2_MINTING_PERIOD)
            return w2[msg.sender];
        else if (raffleState == PHASE3_MINTING_PERIOD)
        {
            if (totalMintedNFTCount < maxNFTCountForRaffle)
                return 1;            
        }
 
        return 0;
    }

    function getDepositAmount() external view returns(uint256)
    {
        return balances[msg.sender];
    }

    /* ========== OWNER ONLY FUNCTIONS ========== */
    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function updateNFTAddress(address _nftContractAddress) external onlyOwner {
        nftContractAddress = IERC721Mintable(_nftContractAddress);
    }

    function startDepositPeriod(uint256 _startTime, uint256 _endTime) external onlyOwner {
        require(_startTime < _endTime, "Start time must be before End time.");

        depositStartTime = _startTime;
        depositEndTime = _endTime;

        raffleState = DEPOSIT_PERIOD;
    }

    function drawPhase1(uint256 _drawCount) external onlyOwner returns (bool) {
        require(participants.length > 0, "No participants");
        require(depositEndTime > 0 && block.timestamp > depositEndTime, "Deposit period not yet completed.");
        require(raffleState < PHASE1_DRAW_COMPLETED, "Contract no suitable for Phase 1 draw.");
        require((mintableNFTs + _drawCount) <= maxNFTCountForRaffle, "NFT number overflow.");

        uint256 seed;
        uint256 random;
        address winner;

        uint256 loopNum = _drawCount;
        if(loopNum > participants.length) {
            loopNum = participants.length;
        }

        for(uint i = 0; i < loopNum; i++) {
            seed = block.number;
            random = uint256(seed) % participants.length;
            winner = participants[random];

            if (balances[winner] >= depositAmountPerNFT) {
                mintableNFTs++;
                w1[winner] += 1;                
                totalW1Count += 1;
                balances[winner] -= depositAmountPerNFT;
                totalRemainingDepositAmount -= depositAmountPerNFT;
            }
            participants.remove(random);
        }

        if (mintableNFTs >= maxNFTCountForRaffle || participants.length <= 0) {
            raffleState = PHASE1_DRAW_COMPLETED;
            return true;
        }
        return false;
    }

    function startPhase1Minting(uint256 _startTime, uint256 _endTime) external onlyOwner {
        require(_startTime < _endTime, "Start time must be before End time.");        
        require(raffleState == PHASE1_DRAW_COMPLETED, "Phase 1 Draw not yet executed.");

        phase1MintingStartTime = _startTime;
        phase1MintingEndTime = _endTime;

        raffleState = PHASE1_MINTING_PERIOD;
    }

    function getDepositListLength() external view onlyOwner returns(uint256) {
        return depositList.length;
    }
    
    function drawPhase2(uint _start, uint _end) external onlyOwner returns (bool) {
        require(phase1MintingEndTime > 0 && block.timestamp > phase1MintingEndTime, "Phase 1 minting period not yet completed.");
        require(raffleState < PHASE2_DRAW_COMPLETED, "Contract no suitable for Phase 2 draw.");
        require(participants.length > 0, "No participants");
        require(_end <= depositList.length, "End index is out of bounds");

        for(uint i = _start; i < _end; i++) {
            if (balances[depositList[i]] >= depositAmountPerNFT) {
                w2[depositList[i]] += balances[depositList[i]] / depositAmountPerNFT;
                totalW2Count += balances[depositList[i]] / depositAmountPerNFT;
                balances[depositList[i]] = 0;
            }
        }

        if(_end == depositList.length) {
            raffleState = PHASE2_DRAW_COMPLETED;
            return true;
        }
        return false;
    }

    function startPhase2Minting(uint256 _startTime, uint256 _endTime) external onlyOwner {
        require(_startTime < _endTime, "Start time must be before End time.");
        require(raffleState == PHASE2_DRAW_COMPLETED, "Phase 2 Draw not yet executed.");

        phase2MintingStartTime = _startTime;
        phase2MintingEndTime = _endTime;

        raffleState = PHASE2_MINTING_PERIOD;
    }

    function startPhase3Minting(uint256 _startTime, uint256 _endTime) external onlyOwner {
        require(_startTime < _endTime, "Start time must be before End time.");
        require(raffleState >= PHASE1_MINTING_PERIOD && raffleState < PHASE3_MINTING_PERIOD, "Phase 2 Draw not yet executed.");

        phase3MintingStartTime = _startTime;
        phase3MintingEndTime = _endTime;

        raffleState = PHASE3_MINTING_PERIOD;
    }

    function completeRaffle() external onlyOwner {
        isRaffleCompleted = true;

        oldRaffleState = raffleState;
        raffleState = RAFFLE_COMPLETED;
    }

    function unCompleteRaffle() external onlyOwner {
        isRaffleCompleted = false;

        raffleState = oldRaffleState;
    }

    function collectTokens(address to) external onlyOwner {
        require(isRaffleCompleted, "Raffle has not ended. Cannot withdraw funds at the moment.");
        uint256 amount = depositTokenAddress.balanceOf(address(this)) - (totalW2Count * depositAmountPerNFT);
        require(amount > 0, "Insufficient balance");

        depositTokenAddress.safeTransfer(to, amount);        
    }

    function collectTokensIncludingUnclaimedDeposits(address to, uint256 _amount) external onlyOwner {
        require(isRaffleCompleted, "Raffle has not ended. Cannot withdraw funds at the moment.");
        require(_amount <= depositTokenAddress.balanceOf(address(this)), "Insufficient balance");
        require(_amount > 0, "Amount must be larger than 0");

        depositTokenAddress.safeTransfer(to, _amount);        
    }

    function getCollectedAmount() external view onlyOwner returns(uint)
    {
        return depositTokenAddress.balanceOf(address(this)) - (totalW2Count * depositAmountPerNFT);
    }

    function getPrizeCountOfAddress(address _address, uint _phase) external view onlyOwner returns(uint)
    {
        if (_phase == 1)
            return w1[_address];
        else if (_phase == 2)
            return w2[_address];

        return 0;
    }

    function getTotalMintedNFTCount() external view onlyOwner returns(uint256)
    {
        return totalMintedNFTCount;
    }

    function getTotalRemainingDepositAmount() external view onlyOwner returns(uint256)
    {
        return totalRemainingDepositAmount;
    }

    function getDrawResults() external view onlyOwner returns(uint256, uint256, uint256, uint256, uint256)
    {
        return (totalW1Count, totalW1MintedCount, totalW2Count, totalW2MintedCount, totalW3MintedCount);
    }

    /* ========== PRIVATE/INTERNAL FUNCTIONS ========== */
    function deposit(uint256 _value) private {
        require(_value > 0, "Deposit amount must be greater than 0.");
        depositTokenAddress.safeTransferFrom(msg.sender, address(this), _value);
        
        if (balances[msg.sender] == 0) {
            depositList.push(msg.sender);
        } 
        balances[msg.sender] += _value;
        totalRemainingDepositAmount += _value;
    }

    function phase1Mint() private returns(bool) {
        require(isRaffleCompleted == false, "Raffle is completed. Cannot mint at the moment.");
        require(phase1MintingStartTime > 0 && block.timestamp >= phase1MintingStartTime, "Phase 1 minting has not started. Cannot mint at the moment.");
        require(block.timestamp < phase1MintingEndTime, "Phase 1 has already ended. Cannot mint at the moment.");
        require(w1[msg.sender] > 0, "You do not have NFTs to mint.");
        require(totalMintedNFTCount < maxNFTCountForRaffle, "Max NFTs reached.");
        
        depositTokenAddress.safeTransferFrom(msg.sender, address(this), pricePerNFT - depositAmountPerNFT);

        w1[msg.sender] -= 1;
        totalW1Count -= 1;
        totalMintedNFTCount += 1;
        totalW1MintedCount += 1;
        if (totalMintedNFTCount >= maxNFTCountForRaffle)
            isRaffleCompleted = true;
        nftContractAddress.mint(msg.sender);
        return true;
    }

    function phase2Mint() private returns(bool) {
        require(isRaffleCompleted == false, "Raffle is completed. Cannot mint at the moment.");
        require(phase2MintingStartTime > 0 && block.timestamp >= phase2MintingStartTime, "Phase 2 minting has not started. Cannot mint at the moment.");
        require(block.timestamp < phase2MintingEndTime, "Phase 2 has already ended. Cannot mint at the moment.");
        require(w2[msg.sender] > 0, "You do not have NFTs to mint.");
        require(totalMintedNFTCount < maxNFTCountForRaffle, "Max NFTs reached.");

        depositTokenAddress.safeTransferFrom(msg.sender, address(this), pricePerNFT - depositAmountPerNFT);
        
        w2[msg.sender] -= 1;
        totalW2Count -= 1;
        totalMintedNFTCount += 1;
        totalW2MintedCount += 1;
        if (totalMintedNFTCount >= maxNFTCountForRaffle)
            isRaffleCompleted = true;
        nftContractAddress.mint(msg.sender);
        return true;
    }

    function phase3Mint() private returns(bool) {
        require(isRaffleCompleted == false, "Raffle is completed. Cannot mint at the moment.");
        require(phase3MintingStartTime > 0 && block.timestamp >= phase3MintingStartTime, "Phase 3 minting has not started. Cannot mint at the moment.");
        require(block.timestamp < phase3MintingEndTime, "Phase 3 has already ended. Cannot mint at the moment.");
        require(totalMintedNFTCount < maxNFTCountForRaffle, "Max NFTs reached.");

        uint256 remainingDeposit = w2[msg.sender] * depositAmountPerNFT;

        if (remainingDeposit >= pricePerNFT)
        {
            w2[msg.sender] -= pricePerNFT / depositAmountPerNFT;
            totalW2Count -= pricePerNFT / depositAmountPerNFT;
            totalRemainingDepositAmount -= pricePerNFT;
        }
        else 
        {
            if (remainingDeposit > 0)
            {
                w2[msg.sender] -= remainingDeposit / depositAmountPerNFT;
                totalW2Count -= remainingDeposit / depositAmountPerNFT;
                totalRemainingDepositAmount -= remainingDeposit;
            }
            
            depositTokenAddress.safeTransferFrom(msg.sender, address(this), pricePerNFT - remainingDeposit);
        }

        totalMintedNFTCount += 1;
        totalW3MintedCount += 1;
        if (totalMintedNFTCount >= maxNFTCountForRaffle)
            isRaffleCompleted = true;
        nftContractAddress.mint(msg.sender);
        return true;
    }
}