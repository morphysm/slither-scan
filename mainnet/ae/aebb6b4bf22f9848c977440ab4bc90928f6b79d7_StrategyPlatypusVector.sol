/**
 *Submitted for verification at snowtrace.io on 2022-03-21
*/

// Sources flattened with hardhat v2.6.4 https://hardhat.org

// File @openzeppelin/contracts/token/ERC20/[email protected]

// SPDX-License-Identifier: MIT
pragma solidity =0.6.12;
pragma experimental ABIEncoderV2;


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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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


// File @openzeppelin/contracts/math/[email protected]





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
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}


// File @openzeppelin/contracts/utils/[email protected]



pragma solidity >=0.6.2 <0.8.0;

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
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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


// File @openzeppelin/contracts/token/ERC20/[email protected]







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
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}


// File @openzeppelin/contracts/utils/[email protected]





/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


// File @openzeppelin/contracts/access/[email protected]





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
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


// File @openzeppelin/contracts/utils/[email protected]





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
    constructor () internal {
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


pragma solidity >=0.6.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeApprove: approve failed'
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeTransfer: transfer failed'
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::transferFrom: transferFrom failed'
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper::safeTransferETH: ETH transfer failed');
    }
}


// File contracts/interfaces/VectorFinance/IPoolHelper.sol


pragma solidity 0.6.12;

interface IPoolHelper {
    function balance(address _address) external view returns (uint256);

    function depositToken() external view returns (address);

    function depositTokenBalance() external view returns (uint256);

    function rewardPerToken(address token) external view returns (uint256);

    function update() external;

    function deposit(uint256 amount) external;

    function stake(uint256 _amount) external;

    function withdraw(uint256 amount, uint256 minAmount) external;

    /// @notice Harvest VTX and PTP rewards for msg.sender
    function getReward() external;

    function mainStaking() external view returns (address);
}


// File contracts/interfaces/VectorFinance/IMainStaking.sol


pragma solidity 0.6.12;

interface IMainStaking {
    function setXPTP(address _xPTP) external;

    function addFee(
        uint256 max,
        uint256 min,
        uint256 value,
        address to,
        bool isPTP,
        bool isAddress
    ) external;

    function setFee(uint256 index, uint256 value) external;

    function setCallerFee(uint256 value) external;

    function deposit(
        address token,
        uint256 amount,
        address sender
    ) external;

    function harvest(address token, bool isUser) external;

    function withdraw(
        address token,
        uint256 _amount,
        uint256 _slippage,
        address sender
    ) external;

    function stakePTP(uint256 amount) external;

    function stakeAllPtp() external;

    function claimVePTP() external;

    function getStakedPtp() external;

    function getVePtp() external;

    function unstakePTP() external;

    function pendingPtpForPool(address _token) external view returns (uint256 pendingPtp);

    function masterPlatypus() external view returns (address);

    function getLPTokensForShares(uint256 amount, address token) external view returns (uint256);

    function getSharesForDepositTokens(uint256 amount, address token) external view returns (uint256);

    function getDepositTokensForShares(uint256 amount, address token) external view returns (uint256);

    function registerPool(
        uint256 _pid,
        address _token,
        address _lpAddress,
        string memory receiptName,
        string memory receiptSymbol,
        uint256 allocpoints
    ) external;

    function getPoolInfo(address _address)
        external
        view
        returns (
            uint256 pid,
            bool isActive,
            address token,
            address lp,
            uint256 sizeLp,
            address receipt,
            uint256 size,
            address rewards_addr,
            address helper
        );

    function removePool(address token) external;

    function nextImplementation() external view returns (address);

    function timelockLength() external view returns (uint256);

    function timelockEndForUpgrade() external view returns (uint256);

    function timelockEndForTimelock() external view returns (uint256);
}


// File contracts/interfaces/BankerJoe/IJoeRouter.sol


pragma solidity 0.6.12;

interface IJoeRouter {
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );
}


// File contracts/interfaces/IWooAccessManager.sol


/*

░██╗░░░░░░░██╗░█████╗░░█████╗░░░░░░░███████╗██╗
░██║░░██╗░░██║██╔══██╗██╔══██╗░░░░░░██╔════╝██║
░╚██╗████╗██╔╝██║░░██║██║░░██║█████╗█████╗░░██║
░░████╔═████║░██║░░██║██║░░██║╚════╝██╔══╝░░██║
░░╚██╔╝░╚██╔╝░╚█████╔╝╚█████╔╝░░░░░░██║░░░░░██║
░░░╚═╝░░░╚═╝░░░╚════╝░░╚════╝░░░░░░░╚═╝░░░░░╚═╝

*
* MIT License
* ===========
*
* Copyright (c) 2020 WooTrade
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

/// @title Reward manager interface for WooFi Swap.
/// @notice this is for swap rebate or potential incentive program
interface IWooAccessManager {
    /* ----- Events ----- */

    event FeeAdminUpdated(address indexed feeAdmin, bool flag);

    event VaultAdminUpdated(address indexed vaultAdmin, bool flag);

    event RebateAdminUpdated(address indexed rebateAdmin, bool flag);

    event ZeroFeeVaultUpdated(address indexed vault, bool flag);

    /* ----- External Functions ----- */

    function isFeeAdmin(address feeAdmin) external returns (bool);

    function isVaultAdmin(address vaultAdmin) external returns (bool);

    function isRebateAdmin(address rebateAdmin) external returns (bool);

    function isZeroFeeVault(address vault) external returns (bool);

    /* ----- Admin Functions ----- */

    /// @notice Sets feeAdmin
    function setFeeAdmin(address feeAdmin, bool flag) external;

    /// @notice Batch sets feeAdmin
    function batchSetFeeAdmin(address[] calldata feeAdmins, bool[] calldata flags) external;

    /// @notice Sets vaultAdmin
    function setVaultAdmin(address vaultAdmin, bool flag) external;

    /// @notice Batch sets vaultAdmin
    function batchSetVaultAdmin(address[] calldata vaultAdmins, bool[] calldata flags) external;

    /// @notice Sets rebateAdmin
    function setRebateAdmin(address rebateAdmin, bool flag) external;

    /// @notice Batch sets rebateAdmin
    function batchSetRebateAdmin(address[] calldata rebateAdmins, bool[] calldata flags) external;

    /// @notice Sets zeroFeeVault
    function setZeroFeeVault(address vault, bool flag) external;

    /// @notice Batch sets zeroFeeVault
    function batchSetZeroFeeVault(address[] calldata vaults, bool[] calldata flags) external;
}


// File contracts/interfaces/IWETH.sol


/// @title Wrapped ETH.
/// BSC: https://bscscan.com/address/0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c#code
interface IWETH {
    /// @dev Deposit ETH into WETH
    function deposit() external payable;

    /// @dev Transfer WETH to receiver
    /// @param to address of WETH receiver
    /// @param value amount of WETH to transfer
    /// @return get true when succeed, else false
    function transfer(address to, uint256 value) external returns (bool);

    /// @dev Withdraw WETH to ETH
    function withdraw(uint256) external;
}


// File @openzeppelin/contracts/utils/[email protected]





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

    constructor () internal {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
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


// File contracts/interfaces/PancakeSwap/IMasterChef.sol


pragma solidity 0.6.12;

interface IMasterChef {
    function deposit(uint256 pid, uint256 amount) external;

    function withdraw(uint256 pid, uint256 amount) external;

    function enterStaking(uint256 amount) external;

    function leaveStaking(uint256 amount) external;

    function emergencyWithdraw(uint256 pid) external;

    function pendingCake(uint256 pid, address user) external view returns (uint256);

    function poolInfo(uint256 pid)
        external
        view
        returns (
            address,
            uint256,
            uint256,
            uint256
        );

    function userInfo(uint256 pid, address user) external view returns (uint256, uint256);
}


// File contracts/interfaces/IStrategy.sol


pragma solidity 0.6.12;

/*

░██╗░░░░░░░██╗░█████╗░░█████╗░░░░░░░███████╗██╗
░██║░░██╗░░██║██╔══██╗██╔══██╗░░░░░░██╔════╝██║
░╚██╗████╗██╔╝██║░░██║██║░░██║█████╗█████╗░░██║
░░████╔═████║░██║░░██║██║░░██║╚════╝██╔══╝░░██║
░░╚██╔╝░╚██╔╝░╚█████╔╝╚█████╔╝░░░░░░██║░░░░░██║
░░░╚═╝░░░╚═╝░░░╚════╝░░╚════╝░░░░░░░╚═╝░░░░░╚═╝

*
* MIT License
* ===========
*
* Copyright (c) 2020 WooTrade
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/
interface IStrategy {
    function vault() external view returns (address);

    function want() external view returns (address);

    function beforeDeposit() external;

    function beforeWithdraw() external;

    function deposit() external;

    function withdraw(uint256) external;

    function balanceOf() external view returns (uint256);

    function balanceOfWant() external view returns (uint256);

    function balanceOfPool() external view returns (uint256);

    function harvest() external;

    function retireStrat() external;

    function emergencyExit() external;

    function paused() external view returns (bool);

    function inCaseTokensGetStuck(address stuckToken) external;
}


// File contracts/interfaces/IVault.sol


pragma solidity 0.6.12;

interface IVault {
    function want() external view returns (address);

    function deposit(uint256 amount) external payable;

    function withdraw(uint256 shares) external;

    function earn() external;

    function available() external view returns (uint256);

    function balance() external view returns (uint256);

    function getPricePerFullShare() external view returns (uint256);
}


// File contracts/earn/strategies/BaseStrategy.sol


pragma solidity 0.6.12;










/*

░██╗░░░░░░░██╗░█████╗░░█████╗░░░░░░░███████╗██╗
░██║░░██╗░░██║██╔══██╗██╔══██╗░░░░░░██╔════╝██║
░╚██╗████╗██╔╝██║░░██║██║░░██║█████╗█████╗░░██║
░░████╔═████║░██║░░██║██║░░██║╚════╝██╔══╝░░██║
░░╚██╔╝░╚██╔╝░╚█████╔╝╚█████╔╝░░░░░░██║░░░░░██║
░░░╚═╝░░░╚═╝░░░╚════╝░░╚════╝░░░░░░░╚═╝░░░░░╚═╝

*
* MIT License
* ===========
*
* Copyright (c) 2020 WooTrade
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

/**
 * Base strategy abstract contract for:
 *  - vault and access manager setup
 *  - fees management
 *  - pause / unpause
 */
abstract contract BaseStrategy is Ownable, Pausable, IStrategy, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    /* ----- State Variables ----- */

    address public override want;
    address public immutable override vault;

    // Default them to 'true' to make the system more fair, but cost a bit more gas.
    bool public harvestOnDeposit = true;
    bool public harvestOnWithdraw = true;

    /* ----- Constant Variables ----- */

    uint256 public constant FEE_MAX = 10000;
    uint256 public performanceFee = 300; // 1 in 10000th: 100: 1%, 300: 3%
    uint256 public withdrawalFee = 0; // 1 in 10000th: 1: 0.01%, 10: 0.1%
    address public performanceTreasury;
    address public withdrawalTreasury;

    IWooAccessManager public accessManager;

    event PerformanceFeeUpdated(uint256 newFee);
    event WithdrawalFeeUpdated(uint256 newFee);

    constructor(address initVault, address initAccessManager) public {
        require(initVault != address(0), 'BaseStrategy: initVault_ZERO_ADDR');
        require(initAccessManager != address(0), 'BaseStrategy: initAccessManager_ZERO_ADDR');
        vault = initVault;
        accessManager = IWooAccessManager(initAccessManager);
        want = IVault(initVault).want();
    }

    modifier onlyAdmin() {
        require(owner() == _msgSender() || accessManager.isVaultAdmin(msg.sender), 'BaseStrategy: NOT_ADMIN');
        _;
    }

    /* ----- Public Functions ----- */

    function beforeDeposit() public virtual override {
        require(msg.sender == address(vault), 'BaseStrategy: NOT_VAULT');
        if (harvestOnDeposit) {
            harvest();
        }
    }

    function beforeWithdraw() public virtual override {
        require(msg.sender == address(vault), 'BaseStrategy: NOT_VAULT');
        if (harvestOnWithdraw) {
            harvest();
        }
    }

    function balanceOf() public view override returns (uint256) {
        return balanceOfWant().add(balanceOfPool());
    }

    function balanceOfWant() public view override returns (uint256) {
        return IERC20(want).balanceOf(address(this));
    }

    /* ----- Internal Functions ----- */

    function chargePerformanceFee(uint256 amount) internal returns (uint256) {
        uint256 fee = amount.mul(performanceFee).div(FEE_MAX);
        if (fee > 0) {
            TransferHelper.safeTransfer(want, performanceTreasury, fee);
        }
        return fee;
    }

    function chargeWithdrawalFee(uint256 amount) internal returns (uint256) {
        uint256 fee = amount.mul(withdrawalFee).div(FEE_MAX);
        if (fee > 0) {
            TransferHelper.safeTransfer(want, withdrawalTreasury, fee);
        }
        return fee;
    }

    /* ----- Abstract Method ----- */

    function balanceOfPool() public view virtual override returns (uint256);

    function deposit() public virtual override;

    function withdraw(uint256 amount) external virtual override;

    function harvest() public virtual override;

    function retireStrat() external virtual override;

    function emergencyExit() external virtual override;

    function _giveAllowances() internal virtual;

    function _removeAllowances() internal virtual;

    /* ----- Admin Functions ----- */

    function setPerformanceFee(uint256 fee) external onlyAdmin {
        require(fee <= FEE_MAX, 'BaseStrategy: fee_EXCCEEDS_MAX');
        performanceFee = fee;
        emit PerformanceFeeUpdated(fee);
    }

    function setWithdrawalFee(uint256 fee) external onlyAdmin {
        require(fee <= FEE_MAX, 'BaseStrategy: fee_EXCCEEDS_MAX');
        require(fee <= 500, 'BaseStrategy: fee_EXCCEEDS_5%'); // less than 5%
        withdrawalFee = fee;
        emit WithdrawalFeeUpdated(fee);
    }

    function setPerformanceTreasury(address treasury) external onlyAdmin {
        require(treasury != address(0), 'BaseStrategy: treasury_ZERO_ADDR');
        performanceTreasury = treasury;
    }

    function setWithdrawalTreasury(address treasury) external onlyAdmin {
        require(treasury != address(0), 'BaseStrategy: treasury_ZERO_ADDR');
        withdrawalTreasury = treasury;
    }

    function setHarvestOnDeposit(bool newHarvestOnDeposit) external onlyAdmin {
        harvestOnDeposit = newHarvestOnDeposit;
    }

    function setHarvestOnWithdraw(bool newHarvestOnWithdraw) external onlyAdmin {
        harvestOnWithdraw = newHarvestOnWithdraw;
    }

    function pause() public onlyAdmin {
        _pause();
        _removeAllowances();
    }

    function unpause() external onlyAdmin {
        _unpause();
        _giveAllowances();
        deposit();
    }

    function paused() public view override(IStrategy, Pausable) returns (bool) {
        return Pausable.paused();
    }

    function inCaseTokensGetStuck(address stuckToken) external override onlyAdmin {
        require(stuckToken != want, 'BaseStrategy: stuckToken_NOT_WANT');
        require(stuckToken != address(0), 'BaseStrategy: stuckToken_ZERO_ADDR');

        uint256 amount = IERC20(stuckToken).balanceOf(address(this));
        if (amount > 0) {
            TransferHelper.safeTransfer(stuckToken, msg.sender, amount);
        }
    }

    function inCaseNativeTokensGetStuck() external onlyAdmin {
        // NOTE: vault never needs native tokens to do the yield farming;
        // This native token balance indicates a user's incorrect transfer.
        if (address(this).balance > 0) {
            TransferHelper.safeTransferETH(msg.sender, address(this).balance);
        }
    }
}


// File contracts/earn/strategies/Platypus/StrategyPlatypusVector.sol


pragma solidity 0.6.12;











/*

░██╗░░░░░░░██╗░█████╗░░█████╗░░░░░░░███████╗██╗
░██║░░██╗░░██║██╔══██╗██╔══██╗░░░░░░██╔════╝██║
░╚██╗████╗██╔╝██║░░██║██║░░██║█████╗█████╗░░██║
░░████╔═████║░██║░░██║██║░░██║╚════╝██╔══╝░░██║
░░╚██╔╝░╚██╔╝░╚█████╔╝╚█████╔╝░░░░░░██║░░░░░██║
░░░╚═╝░░░╚═╝░░░╚════╝░░╚════╝░░░░░░░╚═╝░░░░░╚═╝

*
* MIT License
* ===========
*
* Copyright (c) 2020 WooTrade
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/
contract StrategyPlatypusVector is BaseStrategy {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    /* ----- State Variables ----- */

    // DepositPool list:
    // usdc.e pool helper: 0x257D69AA678e0A8DA6DFDA6A16CdF2052A460b45
    IPoolHelper public poolHelper;
    address public mainStaking = address(0x8B3d9F0017FA369cD8C164D0Cc078bf4cA588aE5);

    address[] public reward1ToWantRoute;
    address[] public reward2ToWantRoute;
    uint256 public lastHarvest;
    uint256 public slippage = 100; // 100 = 1%; 300 = 3%; 1 = 0.01%

    /* ----- Constant Variables ----- */

    address public constant wrappedEther = address(0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7); // WAVAX
    address public constant reward1 = address(0xe6E7e03b60c0F8DaAE5Db98B03831610A60FfE1B); // VTX
    address public constant reward2 = address(0x22d4002028f537599bE9f666d1c4Fa138522f9c8); // PTP
    address public constant uniRouter = address(0x60aE616a2155Ee3d9A68541Ba4544862310933d4); // JoeRouter02

    /* ----- Events ----- */

    event StratHarvest(address indexed harvester, uint256 wantHarvested, uint256 tvl);
    event Deposit(uint256 tvl);
    event Withdraw(uint256 tvl);

    constructor(
        address _vault,
        address _accessManager,
        address _poolHelper,
        address[] memory _reward1ToWantRoute,
        address[] memory _reward2ToWantRoute
    ) public BaseStrategy(_vault, _accessManager) {
        poolHelper = IPoolHelper(_poolHelper);
        reward1ToWantRoute = _reward1ToWantRoute;
        reward2ToWantRoute = _reward2ToWantRoute;

        require(IVault(_vault).want() == poolHelper.depositToken(), 'StrategyPlatypusVector: !poolHelper');
        require(
            reward1ToWantRoute.length > 0 && reward1ToWantRoute[reward1ToWantRoute.length - 1] == want,
            'StrategyPlatypusVector: !route'
        );
        require(
            reward2ToWantRoute.length > 0 && reward2ToWantRoute[reward2ToWantRoute.length - 1] == want,
            'StrategyPlatypusVector: !route'
        );

        _giveAllowances();
    }

    /* ----- External Functions ----- */

    function reward1ToWant() external view returns (address[] memory) {
        return reward1ToWantRoute;
    }

    function reward2ToWant() external view returns (address[] memory) {
        return reward2ToWantRoute;
    }

    /* ----- Public Functions ----- */

    function harvest() public override whenNotPaused {
        require(msg.sender == tx.origin || msg.sender == address(vault), 'StrategyPlatypusVector: EOA_or_vault');

        // NOTE: in case of upgrading, withdraw all the funds and pause the strategy.
        if (IMainStaking(mainStaking).nextImplementation() != address(0)) {
            _withdrawAll();
            pause();
            return;
        }

        uint256 beforeBal = balanceOfWant();

        poolHelper.getReward(); // Harvest VTX and PTP rewards

        _swapRewardToWant(reward1, reward1ToWantRoute);
        _swapRewardToWant(reward2, reward2ToWantRoute);

        uint256 wantHarvested = balanceOfWant().sub(beforeBal);
        uint256 fee = chargePerformanceFee(wantHarvested);
        deposit();

        lastHarvest = block.timestamp;
        emit StratHarvest(msg.sender, wantHarvested.sub(fee), balanceOf());
    }

    function _swapRewardToWant(address reward, address[] memory route) private {
        uint256 rewardBal = IERC20(reward).balanceOf(address(this));

        // rewardBal == 0: means the current token reward ended
        // reward == want: no need to swap
        if (rewardBal > 0 && reward != want) {
            require(route.length > 0, 'StrategyPlatypusVector: SWAP_ROUTE_INVALID');
            IJoeRouter(uniRouter).swapExactTokensForTokens(rewardBal, 0, route, address(this), now);
        }
    }

    function deposit() public override whenNotPaused nonReentrant {
        uint256 wantBal = balanceOfWant();
        if (wantBal > 0) {
            poolHelper.deposit(wantBal);
            emit Deposit(balanceOf());
        }
    }

    function withdraw(uint256 amount) public override nonReentrant {
        require(msg.sender == vault, 'StrategyPlatypusVector: !vault');
        require(amount > 0, 'StrategyPlatypusVector: !amount');

        uint256 wantBal = balanceOfWant();

        if (wantBal < amount) {
            uint256 amountToWithdraw = amount.sub(wantBal);
            // minAmount with 1% slippage
            uint256 minAmount = amountToWithdraw.mul(uint256(10000).sub(slippage)).div(10000);
            poolHelper.withdraw(amountToWithdraw, minAmount);
            uint256 newWantBal = IERC20(want).balanceOf(address(this));
            require(newWantBal > wantBal, 'StrategyPlatypusVector: !newWantBal');
            wantBal = newWantBal;
        }

        uint256 withdrawAmt = amount < wantBal ? amount : wantBal;
        uint256 fee = chargeWithdrawalFee(withdrawAmt);
        if (withdrawAmt > fee) {
            TransferHelper.safeTransfer(want, vault, withdrawAmt.sub(fee));
        }

        emit Withdraw(balanceOf());
    }

    function balanceOfPool() public view override returns (uint256) {
        return poolHelper.depositTokenBalance();
    }

    /* ----- Internal Functions ----- */

    function _giveAllowances() internal override {
        TransferHelper.safeApprove(want, mainStaking, 0);
        TransferHelper.safeApprove(want, mainStaking, uint256(-1));
        TransferHelper.safeApprove(reward1, uniRouter, 0);
        TransferHelper.safeApprove(reward1, uniRouter, uint256(-1));
        TransferHelper.safeApprove(reward2, uniRouter, 0);
        TransferHelper.safeApprove(reward2, uniRouter, uint256(-1));
        TransferHelper.safeApprove(wrappedEther, uniRouter, 0);
        TransferHelper.safeApprove(wrappedEther, uniRouter, uint256(-1));
    }

    function _removeAllowances() internal override {
        TransferHelper.safeApprove(want, mainStaking, 0);
        TransferHelper.safeApprove(reward1, uniRouter, 0);
        TransferHelper.safeApprove(reward2, uniRouter, 0);
        TransferHelper.safeApprove(wrappedEther, uniRouter, 0);
    }

    function _withdrawAll() internal {
        uint256 stakingBal = poolHelper.balance(address(this));
        if (stakingBal > 0) {
            // minAmount with 1% slippage
            uint256 minAmount = stakingBal.mul(uint256(10000).sub(slippage)).div(10000);
            poolHelper.withdraw(stakingBal, minAmount);
        }
    }

    /* ----- Admin Functions ----- */

    function setPoolHelper(address newPoolHelper) external onlyAdmin {
        require(newPoolHelper != address(0), 'StrategyPlatypusVector: !newPoolHelper');
        poolHelper = IPoolHelper(newPoolHelper);
    }

    function setSlippage(uint256 newSlippage) external onlyAdmin {
        slippage = newSlippage;
    }

    function retireStrat() external override {
        require(msg.sender == vault, 'StrategyPlatypusVector: !vault');
        // call harvest explicitly if needed
        _withdrawAll();
        uint256 wantBal = IERC20(want).balanceOf(address(this));
        if (wantBal > 0) {
            TransferHelper.safeTransfer(want, vault, wantBal);
        }
    }

    function emergencyExit() external override onlyAdmin {
        _withdrawAll();
        uint256 wantBal = IERC20(want).balanceOf(address(this));
        if (wantBal > 0) {
            TransferHelper.safeTransfer(want, vault, wantBal);
        }
    }

    receive() external payable {}
}