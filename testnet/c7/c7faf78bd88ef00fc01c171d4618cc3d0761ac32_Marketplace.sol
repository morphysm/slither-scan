/**
 *Submitted for verification at testnet.snowtrace.io on 2022-04-26
*/

// SPDX-License-Identifier: BUSL-1.1

// Marketplace contract for SnowGenesis
// SnowGenesis is a Validator Marketplace for Avalanche Subnets
// https://snowgenesis.com

pragma solidity ^0.8.0;
pragma abicoder v2;

// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)



// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)



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
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)





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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)



// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)



/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)



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

// OpenZeppelin Contracts (last updated v4.5.0) (utils/math/Math.sol)



/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/ECDSA.sol)


// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)



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
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}
library MathUtils {
    uint256 internal constant RAY = 10 ** 27;
    uint256 internal constant SECONDS_PER_YEAR = 365 days;

    function calculateReward(uint256 rate, uint256 amount, uint256 durationInSeconds) internal pure returns (uint256) {
        return (amount * rate * durationInSeconds / SECONDS_PER_YEAR) / RAY;
    }

}

struct SubnetVerificationParams {
    address sender;
    string subnet;
    uint256 nonce;
    bytes signature;
}

struct ValidatorVerificationParams {
    address sender;
    string node;
    uint256 nonce;
    bytes signature;
}

struct AcceptValidatorVerificationParams {
    address sender;
    string subnet;
    string node;
    uint256 acceptedAt;
    uint256 endAt;
    uint256 nonce;
    bytes signature;
}

struct IncentiveParams {
    address token;
    uint256 minStakeAmount;
    uint256 maxStakeAmount;
    uint256 apy; // in RAY
}

struct ValidatorStake {
    address sender;
    // incentive params at time of validator acceptance are stored along with the stake
    // because incentive params are mutable; but changes to incentives will not affect previous validations
    IncentiveParams incentiveParams;
    address subnetSender;
    uint256 stakeAmount;

    // The properties below are set when the subnet creator accepts this stake
    // the potential reward amount is calculated based on the period being validated, the staked amount, and the reward slope
    uint256 potentialRewardAmount;
    uint256 acceptedAt;
    uint256 endAt;

    // set to true when reward is claimed
    bool claimed;
    // set to true if the uptime oracle indicates node was not sufficiently validating the subnet
    bool insufficientUptime;
}

interface IValidatorUptimeOracle {
    function checkUptime(string memory subnet, string memory node, uint256 start, uint256 end) external returns (bool);
}

library StringUtils {
    function stringsEqual(string memory a, string memory b) internal pure returns (bool) {
        return bytes(a).length == bytes(b).length && keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
    }
}

library SignatureVerifier {
    using ECDSA for bytes32;

    function getMessageHash(address sender, string memory kind, string memory subnetOrNode, uint256 nonce) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(sender, kind, subnetOrNode, nonce));
    }

    function getDigest(address sender, string memory kind, string memory subnetOrNode, uint256 nonce) internal pure returns (bytes32) {
        return getMessageHash(sender, kind, subnetOrNode, nonce).toEthSignedMessageHash();
    }

    function getSignerForSubnet(address sender, string memory subnet, uint256 nonce, bytes memory signature) internal pure returns (address) {
        bytes32 digest = getDigest(sender, "subnet", subnet, nonce);
        return digest.recover(signature);
    }

    function getSignerForValidator(address sender, string memory node, uint256 nonce, bytes memory signature) internal pure returns (address) {
        bytes32 digest = getDigest(sender, "node", node, nonce);
        return digest.recover(signature);
    }

    function getSignerForAcceptValidator(address sender, string memory subnet, string memory node, uint256 acceptedAt, uint256 endAt, uint256 nonce, bytes memory signature) internal pure returns (address) {
        bytes32 hash = keccak256(abi.encodePacked(sender, subnet, node, acceptedAt, endAt, nonce));
        bytes32 digest = hash.toEthSignedMessageHash();
        return digest.recover(signature);
    }

}

contract Marketplace is Ownable, Pausable {
    using SafeERC20 for IERC20;
    using StringUtils for string;
    using SignatureVerifier for address;

    event SubnetAdded(string subnet, address indexed owner);
    event SubnetOwnerChanged(string subnet, address indexed oldOwner, address indexed newOwner);
    event SubnetUpdated(string subnet);

    event ValidatorAdded(string node, address indexed owner);
    event ValidatorOwnerChanged(string node, address indexed oldOwner, address indexed newOwner);
    event ValidationRequestCreated(string subnet, string node);
    event ValidationRequestAccepted(string subnet, string node);
    event ValidationRequestWithdrawn(string subnet, string node);

    event ValidationStakeReturned(string subnet, string node, address user, address token, uint256 amount);
    event ValidationRewardClaimed(string subnet, string node, address user, address token, uint256 amount);
    event ValidationRewardNotEarned(string subnet, string node); // returned to subnet owner

    event OracleUpdated(address indexed oldOracle, address indexed newOracle);
    event SignerUpdated(address indexed oldSigner, address indexed newSigner);

    event RescuedNative(uint256 amount);
    event RescuedTokens(address token, uint256 amount);

    address public signatory;
    IValidatorUptimeOracle public uptimeOracle;

    mapping(uint256 => bool) private usedNonces;

    // we allow subnet/validator ownership to change but our requirement is that
    // changes to incentiveParams and subnet ownership does not
    // affect current or past validations
    // ex1: if the owner of a subnet is changed but the reward for failed pending validation
    //     should go to the previous owner
    // ex2: if the owner of a validator changes, the previous staked amount should go to the previous owner
    mapping(string => IncentiveParams) public incentiveParamMapping;
    mapping(string => address) public subnetClaimMapping;
    mapping(string => address) public validatorClaimMapping;

    // {subnet => node => stake}
    mapping(string => mapping(string => ValidatorStake)) public validatorStakeMapping;

    // {subnet => node => [historicalStake]}
    mapping(string => mapping(string => ValidatorStake[])) public historicalValidatorStakes;

    constructor(address _signatory, address _uptimeOracle) {
        signatory = _signatory;
        uptimeOracle = IValidatorUptimeOracle(_uptimeOracle);
    }

    // Subnet creator
    function claimAndAddSubnet(
        string calldata subnet,
        IncentiveParams calldata incentiveParams,
        SubnetVerificationParams calldata vParams
    ) external whenNotPaused {
        require(bytes(subnet).length > 0, "subnet too short");
        require(!usedNonces[vParams.nonce], "nonce reused");
        require(msg.sender == vParams.sender, "params sender must match caller");
        require(subnet.stringsEqual(vParams.subnet), "invalid subnet");
        address signatory_ = vParams.sender.getSignerForSubnet(vParams.subnet, vParams.nonce, vParams.signature);
        require(signatory_ == signatory, "invalid signature");
        usedNonces[vParams.nonce] = true;

        _validateIncentiveParams(incentiveParams);

        address prevOwner = subnetClaimMapping[subnet];
        bool firstAction = prevOwner == address(0);

        incentiveParamMapping[vParams.subnet] = incentiveParams;
        subnetClaimMapping[vParams.subnet] = msg.sender;

        if (firstAction) {
            emit SubnetAdded(vParams.subnet, msg.sender);
        } else {
            emit SubnetUpdated(vParams.subnet);
            if (prevOwner != msg.sender) {
                emit SubnetOwnerChanged(vParams.subnet, prevOwner, msg.sender);
            }
        }
    }

    // Subnet creator
    function updateSubnet(string calldata subnet, IncentiveParams calldata incentiveParams) external whenNotPaused {
        require(msg.sender == subnetClaimMapping[subnet], "not subnet creator");
        _validateIncentiveParams(incentiveParams);
        incentiveParamMapping[subnet] = incentiveParams;
        emit SubnetUpdated(subnet);
    }

    function _validateIncentiveParams(IncentiveParams memory incentiveParams) internal pure {
        require(incentiveParams.token != address(0), "token cannot be 0 address");
        require(incentiveParams.minStakeAmount > 0, "minStake > 0");
        require(incentiveParams.maxStakeAmount >= incentiveParams.minStakeAmount, "maxStake < minStake");
        require(incentiveParams.apy > 0, "minAPY > 0");
    }

    // Validator
    function claimAndAddValidator(
        string calldata node,
        ValidatorVerificationParams calldata vParams
    ) external whenNotPaused {
        require(!usedNonces[vParams.nonce], "nonce reused");
        require(node.stringsEqual(vParams.node), "invalid node");
        require(msg.sender == vParams.sender, "invalid sender");
        address signatory_ = vParams.sender.getSignerForValidator(vParams.node, vParams.nonce, vParams.signature);
        require(signatory_ == signatory, "invalid signature");
        usedNonces[vParams.nonce] = true;

        if (validatorClaimMapping[node] == address(0)) {
            emit ValidatorAdded(node, msg.sender);
        } else {
            emit ValidatorOwnerChanged(node, validatorClaimMapping[node], msg.sender);
        }
        validatorClaimMapping[node] = msg.sender;
    }

    // Validator
    function stakeForValidation(
        string calldata subnet,
        string calldata node,
        address token,
        uint256 stakeAmount
    ) external whenNotPaused {
        require(subnetClaimMapping[subnet] != address(0), "subnet not claimed");
        require(validatorClaimMapping[node] != address(0), "validator not claimed");
        require(validatorClaimMapping[node] == msg.sender, "validator claimed by another address");

        require(!claimable(subnet, node), "claim first");
        require(validatorStakeMapping[subnet][node].stakeAmount == 0, "already staked");

        IncentiveParams memory incentives = incentiveParamMapping[subnet];
        require(incentives.token != address(0), "subnet has no incentives");
        require(incentives.token == token, "tokens do not match");
        require(stakeAmount >= incentives.minStakeAmount, "amount must be gte min");
        require(stakeAmount <= incentives.maxStakeAmount, "amount must be lte max");

        IERC20 stoken = IERC20(incentives.token);
        require(stoken.allowance(msg.sender, address(this)) >= stakeAmount, "insufficient allowance");

        validatorStakeMapping[subnet][node] = ValidatorStake({
          sender : msg.sender,
          incentiveParams : incentives,
          subnetSender : subnetClaimMapping[subnet],
          stakeAmount : stakeAmount,
          acceptedAt : 0,
          endAt : 0,
          potentialRewardAmount : 0,
          claimed : false,
          insufficientUptime : false
        });

        stoken.safeTransferFrom(msg.sender, address(this), stakeAmount);

        emit ValidationRequestCreated(subnet, node);
    }

    // Subnet creator
    function acceptValidator(
        string calldata subnet,
        string calldata node,
        AcceptValidatorVerificationParams calldata vParams
    )
    external whenNotPaused {
        ValidatorStake storage vs = validatorStakeMapping[subnet][node];
        require(vs.subnetSender != address(0), "subnet has not been claimed");
        require(vs.subnetSender == msg.sender, "must be the subnet creator");
        require(vs.stakeAmount > 0, "not staked");
        require(vs.acceptedAt == 0, "already accepted");
        require(vParams.sender == msg.sender, "does not match signature sender");
        require(subnet.stringsEqual(vParams.subnet) && node.stringsEqual(vParams.node), "subnet/node do not match signature");
        require(!usedNonces[vParams.nonce], "nonce reused");

        address signatory_ = vParams.sender.getSignerForAcceptValidator(
            vParams.subnet, vParams.node, vParams.acceptedAt, vParams.endAt, vParams.nonce, vParams.signature);
        require(signatory_ == signatory, "invalid signature");
        usedNonces[vParams.nonce] = true;

        vs.acceptedAt = vParams.acceptedAt;
        vs.endAt = vParams.endAt;
        vs.potentialRewardAmount = getPotentialRewardAmount(vs.stakeAmount, vParams.endAt - vParams.acceptedAt, vs.incentiveParams);

        IERC20 token = IERC20(vs.incentiveParams.token);
        require(token.allowance(msg.sender, address(this)) >= vs.potentialRewardAmount, "insufficient token allowance");
        token.safeTransferFrom(msg.sender, address(this), vs.potentialRewardAmount);

        emit ValidationRequestAccepted(subnet, node);
    }

    // Validator
    function withdrawStake(string calldata subnet, string calldata node) external whenNotPaused {
        ValidatorStake storage vs = validatorStakeMapping[subnet][node];
        require(vs.sender != address(0), "not staked");
        require(vs.sender == msg.sender, "not the validator");
        require(vs.stakeAmount > 0, "not staked");
        require(vs.acceptedAt == 0, "already accepted");
        require(!claimable(subnet, node), "claim previous stake first");

        uint256 amount = vs.stakeAmount;
        vs.stakeAmount = 0;
        IERC20(vs.incentiveParams.token).safeTransfer(vs.sender, amount);
        delete validatorStakeMapping[subnet][node];
        emit ValidationRequestWithdrawn(subnet, node);
    }

    // (1) Send staked tokens back to validator
    // (2a) If uptime was sufficient, send reward to validator
    // (2b) Else, send reward back to subnet creator
    // (3) archive the ValidatorStake object
    // claimRewards is permission-less. Rewards/tokens get sent back to the validator/subnet
    function claimReward(string calldata subnet, string calldata node) external whenNotPaused {
        ValidatorStake storage vs = validatorStakeMapping[subnet][node];
        require(claimable(subnet, node), "not claimable");

        bool sufficientUptime = uptimeOracle.checkUptime(subnet, node, vs.acceptedAt, vs.endAt);
        vs.insufficientUptime = !sufficientUptime;
        vs.claimed = true;

        IERC20 token = IERC20(vs.incentiveParams.token);

        token.safeTransfer(vs.sender, vs.stakeAmount);
        emit ValidationStakeReturned(subnet, node, vs.sender, address(token), vs.stakeAmount);

        if (!sufficientUptime) {
            // return reward to subnet creator
            token.safeTransfer(vs.subnetSender, vs.potentialRewardAmount);
            emit ValidationRewardNotEarned(subnet, node);
        } else {
            // validator gets reward
            token.safeTransfer(vs.sender, vs.potentialRewardAmount);
            emit ValidationRewardClaimed(subnet, node, vs.sender, address(token), vs.potentialRewardAmount);
        }

        historicalValidatorStakes[subnet][node].push(vs);
        delete validatorStakeMapping[subnet][node];
    }

    function claimable(string calldata subnet, string calldata node) public view returns (bool) {
        ValidatorStake memory vs = validatorStakeMapping[subnet][node];
        bool stakedAndAccepted = vs.stakeAmount >= 0 && vs.potentialRewardAmount > 0 && vs.acceptedAt > 0;
        bool ended = block.timestamp > vs.endAt;
        return !vs.claimed && stakedAndAccepted && ended;
    }

    function getPotentialRewardAmount(
        uint256 stakeAmount,
        uint256 stakeDurationInSeconds,
        IncentiveParams memory params
    ) public pure returns (uint256) {
        return MathUtils.calculateReward(params.apy, stakeAmount, stakeDurationInSeconds);
    }

    // UI and tests

    function getIncentivesForSubnet(string memory subnet) public view returns (IncentiveParams memory) {
        return incentiveParamMapping[subnet];
    }

    function getValidatorStakeMapping(string memory subnet, string memory node) public view returns (ValidatorStake memory) {
        return validatorStakeMapping[subnet][node];
    }

    function getValidationPeriod(string memory subnet, string memory node) public view returns (uint256, uint256) {
        ValidatorStake memory vs = validatorStakeMapping[subnet][node];
        if (vs.acceptedAt == 0) {
            return (0, 0);
        }
        return (vs.acceptedAt, vs.endAt);
    }

    // Admin functions

    function pause() external onlyOwner whenNotPaused {
        _pause();
    }

    function unpause() external onlyOwner whenPaused {
        _unpause();
    }

    function rescueFunds(uint256 amount_) external onlyOwner {
        uint256 amount = Math.min(amount_, address(this).balance);
        if (amount == 0) {
            return;
        }

        payable(address(this)).transfer(amount);
        emit RescuedNative(amount);
    }

    function rescueTokens(address token_, uint256 amount_) external onlyOwner {
        IERC20 token = IERC20(token_);
        uint256 amount = Math.min(amount_, token.balanceOf(address(this)));
        if (amount == 0) {
            return;
        }

        token.safeTransfer(owner(), amount);
        emit RescuedTokens(token_, amount);
    }

    function updateSignatory(address newSignatory) external onlyOwner {
        emit SignerUpdated(signatory, newSignatory);
        signatory = newSignatory;
    }

    function updateOracle(address newOracle) external onlyOwner {
        emit OracleUpdated(address(uptimeOracle), newOracle);
        uptimeOracle = IValidatorUptimeOracle(newOracle);
    }

}