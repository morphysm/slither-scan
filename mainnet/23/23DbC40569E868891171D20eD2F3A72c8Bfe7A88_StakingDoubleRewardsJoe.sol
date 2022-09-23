/**
 *Submitted for verification at snowtrace.io on 2022-03-28
*/

// Sources flattened with hardhat v2.2.0 https://hardhat.org

// File @openzeppelin/contracts/utils/[email protected]

// SPDX-License-Identifier: MIT

// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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


// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

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


// File @openzeppelin/contracts/utils/math/[email protected]


// OpenZeppelin Contracts v4.4.0 (utils/math/Math.sol)

pragma solidity ^0.8.0;

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


// File @openzeppelin/contracts/utils/math/[email protected]


// OpenZeppelin Contracts v4.4.0 (utils/math/SafeMath.sol)

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
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
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
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
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
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
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
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
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
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
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


// File @openzeppelin/contracts/token/ERC20/[email protected]


// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

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


// File @openzeppelin/contracts/utils/[email protected]


// OpenZeppelin Contracts v4.4.0 (utils/Address.sol)

pragma solidity ^0.8.0;

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


// File @openzeppelin/contracts/token/ERC20/utils/[email protected]


// OpenZeppelin Contracts v4.4.0 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;


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


// File contracts/StakingDoubleRewardsJoe.sol



pragma solidity ^0.8.9;
interface IJoeChef {
    struct PoolInfo {
        IERC20 lpToken; // Address of LP token contract.
        uint256 allocPoint; // How many allocation points assigned to this pool. JOEs to distribute per second.
        uint256 lastRewardTimestamp; // Last timestamp that JOEs distribution occurs.
        uint256 accJoePerShare; // Accumulated JOEs per share, times 1e12. See below.
        IRewarder rewarder;
    }
    function poolInfo(uint256 pid) external view returns (PoolInfo memory);
    function totalAllocPoint() external view returns (uint256);
    function pendingTokens(uint256 _pid, address _user) external view returns (uint256 pendingJoe, address bonusTokenAddress, string memory bonusTokenSymbol, uint256 pendingBonusToken);
    function rewarderBonusTokenInfo(uint256 _pid) external view returns (address bonusTokenAddress, string memory bonusTokenSymbol);
    function updatePool(uint256 _pid) external;
    function deposit(uint256 _pid, uint256 _amount) external;
    function withdraw(uint256 _pid, uint256 _amount) external;
    function emergencyWithdraw(uint256 _pid) external;
    function userInfo(uint256 pid, address user) external returns (uint256 amount, uint256 rewardDebt);
}

interface IRewarder {
    function onJoeReward(address user, uint256 newLpAmount) external;

    function pendingTokens(address user) external view returns (uint256 pending);

    function rewardToken() external view returns (IERC20);
}

contract StakingDoubleRewardsJoe is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    bool public onlyApprovedContractOrEOAStatus;
    mapping(address => bool) public approvedContracts;

    modifier onlyApprovedContractOrEOA() {
        if (onlyApprovedContractOrEOAStatus) {
            require(tx.origin == msg.sender || approvedContracts[msg.sender], "StakingDoubleRewards::onlyApprovedContractOrEOA");
        }
        _;
    }

    IERC20 public rewardsToken;
    IERC20 public stakingToken;
    uint256 public periodFinish = 0;
    uint256 public rewardRate = 0;
    uint256 public rewardsDuration = 5 days;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;
    address public liqPoolManager;

    //MCJoe V2 0xd6a4F121CA35509aF06A0Be99093d08462f53052
    //MCJoe V3 0x188bED1968b795d5c9022F6a0bb5931Ac4c18F00
    //BMCJoe proxy 0x4483f0b6e2F5486D06958C20f8C39A7aBe87bf8F, master 0xfaa452111f2167532e29fc2b696247cda61d006f
    IJoeChef public constant masterChefJoe = IJoeChef(0x4483f0b6e2F5486D06958C20f8C39A7aBe87bf8F);
    IRewarder public rewarder;
    uint256 internal constant MAX_UINT = 115792089237316195423570985008687907853269984665640564039457584007913129639935;
    uint256 internal constant ACC_PRECISION = 1e18;
    uint256 internal constant MAX_BIPS = 10000;
    address public performanceFeeAddress;
    address public rewardTokenJOE;
    uint256 public totalShares; 
    uint256 public lpPerShare = 1e18;
    uint256 public joePid;
    uint256 public performanceFeeBips = 1000;
    bool public isSuper;
    address[] public rewardSuperTokens;
    mapping(address => uint256) public userAmount;
    mapping(address => uint256) public userRewardDebt;
    mapping(address => uint256) public rewardTokensPerShare;
    mapping(address => mapping(address => uint256)) public rewardDebt;
    mapping(uint256 => mapping(address => uint256)) public withdrawals;
    mapping(address => mapping(address => uint256)) public harvested;
    mapping(address => uint256) public totalHarvested;

    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;

    constructor(
        uint256 _joePid,
        address _rewardsToken,
        address _stakingToken,
        address _liqPoolManager,
        address _rewarder,
        address[] memory _rewardTokens,
        bool _isSuper
    ) {
        joePid = _joePid;
        rewardsToken = IERC20(_rewardsToken);
        stakingToken = IERC20(_stakingToken);
        liqPoolManager = _liqPoolManager;
        stakingToken.safeApprove(address(masterChefJoe), MAX_UINT);
        rewardTokenJOE = 0x6e84a6216eA6dACC71eE8E6b0a5B7322EEbC0fDd; //JOE token
        performanceFeeAddress = 0xC17634466ec32f66EbbFfD0e927d492406377B5f;
        onlyApprovedContractOrEOAStatus = true;
        rewarder = IRewarder(_rewarder);
        rewardSuperTokens = _rewardTokens;
        isSuper = _isSuper;
    }

    function rewardsSuperTokens() external view returns (address[] memory) {
        return rewardSuperTokens;
    }

    function rewardsSuperTokensCount() external view returns (uint256) {
        return rewardSuperTokens.length;
    }

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return Math.min(block.timestamp, periodFinish);
    }

    function rewardPerToken() public view returns (uint256) {
        if (_totalSupply == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored.add(
                lastTimeRewardApplicable().sub(lastUpdateTime).mul(rewardRate).mul(1e18).div(_totalSupply)
            );
    }

    function earned(address account) public view returns (uint256) {
        return _balances[account].mul(rewardPerToken().sub(userRewardPerTokenPaid[account])).div(1e18).add(rewards[account]);
    }

    function getRewardForDuration() external view returns (uint256) {
        return rewardRate.mul(rewardsDuration);
    }


    function stake(uint256 amount) external onlyApprovedContractOrEOA updateReward(msg.sender) {
        require(amount > 0, "Cannot stake 0");
        //minichef2 staking section
        uint256 newShares = (amount * ACC_PRECISION) / lpPerShare;

        stakingToken.safeTransferFrom(msg.sender, address(this), amount);

        _claimRewards();
        _harvest();
        _getReward();

        if (amount > 0) {
            masterChefJoe.deposit(joePid, amount);
        }
        if (newShares > 0) {
            increaseRewardDebt(msg.sender, rewardTokenJOE, newShares);
            if (isSuper) {
                for (uint256 i = 0; i < rewardSuperTokens.length; i++) {
                    increaseRewardDebt(msg.sender, rewardSuperTokens[i], newShares);
                } 
            }
        }

        _totalSupply = _totalSupply.add(amount);
        _balances[msg.sender] = _balances[msg.sender].add(amount);

        totalShares = totalShares + newShares;
        userAmount[msg.sender] = userAmount[msg.sender] + newShares;
        userRewardDebt[msg.sender] = userRewardDebt[msg.sender] + ((newShares * rewardPerTokenStored) / ACC_PRECISION);
        
        emit Staked(msg.sender, amount);
    }


    function withdraw(uint256 amountShares) external onlyApprovedContractOrEOA updateReward(msg.sender) {
        require(userAmount[msg.sender] >= amountShares, "withdraw: not good");

        if (amountShares > 0) {
            uint256 lpFromShares = (amountShares * lpPerShare) / ACC_PRECISION;

            withdrawals[joePid][msg.sender] += lpFromShares;

        _claimRewards();
        _harvest();
        _getReward();

        if (lpFromShares > 0) {
            masterChefJoe.withdraw(joePid, lpFromShares);
            stakingToken.safeTransfer(msg.sender, lpFromShares);
        }
        if (amountShares > 0) {
            decreaseRewardDebt(msg.sender, rewardTokenJOE, amountShares);
            if (isSuper) {
                for (uint256 i = 0; i < rewardSuperTokens.length; i++) {
                    decreaseRewardDebt(msg.sender, rewardSuperTokens[i], amountShares);
                } 
            }
        }

        _totalSupply = _totalSupply.sub(amountShares);
        _balances[msg.sender] = _balances[msg.sender].sub(amountShares);

        userAmount[msg.sender] = userAmount[msg.sender] - amountShares;
        uint256 rewardDebtOfShares = ((amountShares * rewardPerTokenStored) / ACC_PRECISION);
        uint256 userRewardDebtt = userRewardDebt[msg.sender];
        userRewardDebt[msg.sender] = (userRewardDebtt >= rewardDebtOfShares) ? 
            (userRewardDebtt - rewardDebtOfShares) : 0;
        totalShares = totalShares - amountShares;

        emit Withdrawn(msg.sender, amountShares);
        }
    }
    
    function harvest() external onlyApprovedContractOrEOA updateReward(msg.sender) {
        _claimRewards();
        _harvest(); 
        _getReward();
    }

    function _claimRewards() internal {
        uint256 pendingAmounts;
        bool updateAndClaim;

        pendingAmounts = checkReward();
        if (pendingAmounts > 0) {
            updateAndClaim = true;
        }

        if (updateAndClaim && totalShares > 0) {
            uint256 balancesBefore;
            uint256[] memory superBalancesBefore = new uint256[](rewardSuperTokens.length);

            balancesBefore = _checkBalance(rewardTokenJOE);

            if (isSuper) {
                for (uint256 i = 0; i < rewardSuperTokens.length; i++) {
                    superBalancesBefore[i] = _checkBalance(rewardSuperTokens[i]);
                }                
            }

            masterChefJoe.deposit(joePid, 0);

            uint256 balanceDiff = _checkBalance(rewardTokenJOE) - balancesBefore;
            if (balanceDiff > 0) {
                increaseRewardTokensPerShare(rewardTokenJOE, (balanceDiff * ACC_PRECISION) / totalShares);
            }

            if (isSuper) {
                for (uint256 i = 0; i < rewardSuperTokens.length; i++) {
                    uint256 balanceDiffS = _checkBalance(rewardSuperTokens[i]) - superBalancesBefore[i];
                    if (balanceDiffS > 0) {
                        increaseRewardTokensPerShare(rewardSuperTokens[i], (balanceDiffS * ACC_PRECISION) / totalShares);
                    }
                }                
            } 
        }
    }

    function _harvest() internal {
        uint256 userShares = userAmount[msg.sender];
        address rewardToken = rewardTokenJOE;
        uint256 totalRewards = userShares * rewardTokensPerShare[rewardToken] / ACC_PRECISION;
        uint256 userRewardDebtt = rewardDebt[msg.sender][rewardToken];
        uint256 userPendingRewards = (totalRewards > userRewardDebtt) ?  (totalRewards - userRewardDebtt) : 0;
        setRewardDebt(msg.sender, rewardToken, userShares);
        if (userPendingRewards > 0) {
            totalHarvested[rewardToken] += userPendingRewards;
            if (performanceFeeBips > 0) {
                uint256 performanceFee = (userPendingRewards * performanceFeeBips) / MAX_BIPS;
                _safeRewardTokenTransfer(rewardToken, performanceFeeAddress, performanceFee);
                userPendingRewards = userPendingRewards - performanceFee;
            }
            harvested[msg.sender][rewardToken] += userPendingRewards;
            _safeRewardTokenTransfer(rewardToken, msg.sender, userPendingRewards);
            emit Harvest(msg.sender, userPendingRewards);
        }

        //if the pool is super, the sending of bonus tokens starts here
        if (isSuper) {
            for (uint256 i = 0; i < rewardSuperTokens.length; i++) {
                uint256 totalRewardsSuper = userShares * rewardTokensPerShare[rewardSuperTokens[i]] / ACC_PRECISION;
                uint256 userRewardDebttSuper = rewardDebt[msg.sender][rewardSuperTokens[i]];
                uint256 userPendingRewardsSuper = (totalRewardsSuper > userRewardDebttSuper) ?  (totalRewardsSuper - userRewardDebttSuper) : 0;
                setRewardDebt(msg.sender, rewardSuperTokens[i], userShares);
                if (userPendingRewardsSuper > 0) {
                    totalHarvested[rewardSuperTokens[i]] += userPendingRewardsSuper;
                    if (performanceFeeBips > 0) {
                        uint256 performanceFee = (userPendingRewardsSuper * performanceFeeBips) / MAX_BIPS;
                        _safeRewardTokenTransfer(rewardSuperTokens[i], performanceFeeAddress, performanceFee);
                        userPendingRewardsSuper = userPendingRewardsSuper - performanceFee;
                    }
                    harvested[msg.sender][rewardSuperTokens[i]] += userPendingRewardsSuper;
                    _safeRewardTokenTransfer(rewardSuperTokens[i], msg.sender, userPendingRewardsSuper);
                }
            }
        }
    }

    function _getReward() internal {
        uint256 reward = rewards[msg.sender];
        if (reward > 0) {
            rewards[msg.sender] = 0;
            rewardsToken.safeTransfer(msg.sender, reward);
            emit RewardPaid(msg.sender, reward);
        }
    }

    function pendingRewards(address user) public view returns (uint256, uint256, uint256) {
        return (earned(user), pendingRewardJoe(user), pendingRewardSuper(user));
    }

    function pendingRewardSuper(address user) public view returns (uint256) {
        if(isSuper){
            return rewarder.pendingTokens(user);
        }else{
            return 0;
        }

    }

    function pendingRewardJoe(address user) public view returns (uint256) {
        uint256 userShares = userAmount[user];
        address rewardToken = rewardTokenJOE;
        uint256 unclaimedRewards = checkReward();
        uint256 userRewardDebtt = rewardDebt[user][rewardToken];
        uint256 multiplier =  rewardTokensPerShare[rewardToken];
        if(totalShares > 0) {
            multiplier = multiplier + ((unclaimedRewards * ACC_PRECISION) / totalShares);
        }
        uint256 totalRewards = (userShares * multiplier) / ACC_PRECISION;
        uint256 userPendingRewards = (totalRewards > userRewardDebtt) ? (totalRewards - userRewardDebtt) : 0;
        uint256 pendingAmount = (userPendingRewards * (MAX_BIPS - performanceFeeBips)) / MAX_BIPS;

        return pendingAmount;
    }

    function _safeRewardTokenTransfer(address token, address user, uint256 amount) internal {
        IERC20 rewardToken = IERC20(token);
        uint256 rewardTokenBal = rewardToken.balanceOf(address(this));
        if (amount > rewardTokenBal) {
            rewardToken.safeTransfer(user, rewardTokenBal);
        } else {
            rewardToken.safeTransfer(user, amount);
        }            
    }

    function setPerfomanceFeeAddress(address _performanceFeeAddress) external onlyOwner {
        require(_performanceFeeAddress != address(0));
        performanceFeeAddress = _performanceFeeAddress;
    }

    function setPerformanceFeeBips(uint256 newPerformanceFeeBips) external onlyOwner {
        performanceFeeBips = newPerformanceFeeBips;
    }

    function setSuper(bool _isSuper) external onlyOwner {
        isSuper = _isSuper;
    }

    function modifyApprovedContracts(address[] calldata contracts, bool[] calldata statuses) external onlyOwner {
        require(contracts.length == statuses.length, "input length mismatch");
        for (uint256 i = 0; i < contracts.length; i++) {
            approvedContracts[contracts[i]] = statuses[i];
        }
    }

    function setOnlyApprovedContractOrEOAStatus(bool newStatus) external onlyOwner {
        onlyApprovedContractOrEOAStatus = newStatus;
    }

    function checkBalance(address token) external view returns (uint256) {
        return IERC20(token).balanceOf(address(this));
    }

    function _checkBalance(address token) internal view returns (uint256) {
        return IERC20(token).balanceOf(address(this));
    }

    function checkReward() public view returns (uint256) {
        (uint256 pendingJoe,,,) = masterChefJoe.pendingTokens(joePid, address(this));
        return pendingJoe;
    }

    function checkRewards() public view returns (uint256, address, string memory, uint256) {
        (uint256 pendingJoe, address bonusTokenAddress, string memory bonusTokenSymbol, uint256 pendingBonusToken) = masterChefJoe.pendingTokens(joePid, address(this));
        return (pendingJoe, bonusTokenAddress, bonusTokenSymbol, pendingBonusToken);
    }

    function increaseRewardDebt(address user, address token, uint256 shareAmount) internal {
        rewardDebt[user][token] += (rewardTokensPerShare[token] * shareAmount) / ACC_PRECISION;
    }

    function decreaseRewardDebt(address user, address token, uint256 shareAmount) internal {
        rewardDebt[user][token] -= (rewardTokensPerShare[token] * shareAmount) / ACC_PRECISION;
    }

    function setRewardDebt(address user, address token, uint256 userShares) internal {
        rewardDebt[user][token] = (rewardTokensPerShare[token] * userShares) / ACC_PRECISION;
    }

    function increaseRewardTokensPerShare(address token, uint256 amount) internal {
        rewardTokensPerShare[token] += amount;
    }

    function notifyRewardAmount(uint256 reward) external updateReward(address(0)) {
        require(msg.sender == owner() || msg.sender == liqPoolManager, "Liqpoll Manager or Owner can call this.");

        if (block.timestamp >= periodFinish) {
            rewardRate = reward.div(rewardsDuration);
        } else {
            uint256 remaining = periodFinish.sub(block.timestamp);
            uint256 leftover = remaining.mul(rewardRate);
            rewardRate = reward.add(leftover).div(rewardsDuration);
        }

        uint balance = rewardsToken.balanceOf(address(this));
        require(rewardRate <= balance.div(rewardsDuration), "Provided reward too high");

        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp.add(rewardsDuration);
        emit RewardAdded(reward);
    }

    function recoverERC20(address tokenAddress, uint256 tokenAmount) external onlyOwner {
        require(tokenAddress != address(stakingToken), "Cannot withdraw the staking token");
        IERC20(tokenAddress).safeTransfer(owner(), tokenAmount);
        emit Recovered(tokenAddress, tokenAmount);
    }

    function setRewardsDuration(uint256 _rewardsDuration) external onlyOwner {
        require(
            block.timestamp > periodFinish,
            "Previous rewards period must be complete before changing the duration for the new period"
        );
        rewardsDuration = _rewardsDuration;
        emit RewardsDurationUpdated(rewardsDuration);
    }
    
    function setLiqPoolManager (address _liqPoolManager) external onlyOwner {
        require(
            block.timestamp > periodFinish,
            "Previous rewards period must be complete before changing the liqPoolManager for the new period"
        );
        liqPoolManager  = _liqPoolManager;
    }


    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
    event RewardsDurationUpdated(uint256 newDuration);
    event Recovered(address token, uint256 amount);
    event Harvest(address indexed user, uint256 harvestedAmount);
}