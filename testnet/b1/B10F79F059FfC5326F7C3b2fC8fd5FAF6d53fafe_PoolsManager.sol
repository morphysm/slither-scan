// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/math/Math.sol)

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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';

import './interfaces/ITimeLockPool.sol';
import './TimeLockPool.sol';

contract PoolsManager is Ownable {
    using SafeERC20 for IERC20;

    mapping(address => bool) public poolsAdded;

    ITimeLockPool[] public openPools;
    ITimeLockPool[] public removedPools;

    event PoolAdded(address newPool);
    event PoolRemoved(address oldPool);

    struct Info {
        string name;
        address poolAddress;
        address depositToken;
        uint256 TVL;
        uint256 finalTVL;
        address rewardToken;
        uint256 rewardRate;
        uint256 totalClaimed;
    }

    struct UserInfo {
        string name;
        uint256 earned;
        uint256 totalRewards;
        uint256 totalStaked;
        ITimeLockPool.DepositInfo[] deposits;
        ITimeLockPool.LockInfo[] locks;
    }

    function addPool(
        IERC20 depositToken,
        IERC20 rewardToken,
        uint256 stakingPoolDuration,
        uint256 lockDuration,
        uint256 rewardRate,
        string calldata name
    ) external onlyOwner {
        TimeLockPool newPool = new TimeLockPool(
            depositToken,
            rewardToken,
            stakingPoolDuration,
            lockDuration,
            rewardRate,
            name
        );

        rewardToken.safeTransfer(address(newPool), stakingPoolDuration * rewardRate);

        openPools.push(ITimeLockPool(newPool));
        poolsAdded[address(newPool)] = true;

        emit PoolAdded(address(newPool));
    }

    function removePool(uint256 _poolId) external onlyOwner {
        require(_poolId < openPools.length, 'Pool doesnt exist');
        address poolAddress = address(openPools[_poolId]);

        openPools[_poolId] = openPools[openPools.length - 1];
        openPools.pop();
        poolsAdded[poolAddress] = false;

        removedPools.push(ITimeLockPool(poolAddress));

        emit PoolRemoved(poolAddress);
    }

    function addRewardToOpenedPool(uint256 _poolId, uint256 reward) external onlyOwner {
        require(_poolId < openPools.length, 'Pool doesnt exist');
        ITimeLockPool pool = openPools[_poolId];

        pool.rewardToken().safeTransfer(address(pool), reward);

        pool.notifyRewardAmount(reward);
    }

    function setRewardPeriodForPool(uint256 _poolId, uint256 rewardDuration)
        external
        onlyOwner
    {
        require(_poolId < openPools.length, 'Pool doesnt exist');
        ITimeLockPool pool = openPools[_poolId];
        pool.setRewardsDuration(rewardDuration);
    }

    function recoverERC20FromPool(
        address poolAddress,
        address tokenAddress,
        uint256 amount,
        address receiver
    ) external onlyOwner {
        ITimeLockPool pool = ITimeLockPool(poolAddress);
        pool.recoverERC20(tokenAddress, amount, receiver);
    }

    function recoverERC20(
        address tokenAddress,
        uint256 tokenAmount,
        address receiver
    ) external onlyOwner {
        IERC20(tokenAddress).safeTransfer(receiver, tokenAmount);
    }

    function viewInfoAboutOpenPools() external view returns (Info[] memory) {
        uint256 length = openPools.length;

        Info[] memory info = new Info[](length);
        for (uint256 i = 0; i < length; i++) {
            info[i] = Info({
                name: openPools[i].name(),
                poolAddress: address(openPools[i]),
                depositToken: address(openPools[i].depositToken()),
                TVL: openPools[i].TVL(),
                finalTVL: openPools[i].finalTVL(),
                rewardToken: address(openPools[i].rewardToken()),
                rewardRate: openPools[i].rewardRate(),
                totalClaimed: openPools[i].totalClaimed()
            });
        }

        return info;
    }

    function viewInfoAboutUserInOpenPools(address _account)
        external
        view
        returns (UserInfo[] memory)
    {
        uint256 length = openPools.length;

        UserInfo[] memory info = new UserInfo[](length);
        for (uint256 i = 0; i < length; i++) {
            info[i] = UserInfo({
                name: openPools[i].name(),
                earned: openPools[i].earned(_account),
                totalRewards: openPools[i].getTotalReward(_account),
                totalStaked: openPools[i].getTotalDeposit(_account),
                deposits: openPools[i].getTotalDeposits(_account),
                locks: openPools[i].getTotalRewards(_account)
            });
        }

        return info;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import '@openzeppelin/contracts/utils/math/Math.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';

import './interfaces/ITimeLockPool.sol';

contract TimeLockPool is ITimeLockPool {
    using Math for uint256;
    using SafeERC20 for IERC20;

    address public immutable poolManager;

    uint256 public immutable lockDuration;

    uint256 public stakingPoolDuration;
    uint256 public periodFinish;

    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;

    uint256 public constant minStakingDuration = 10 * 60;
    uint256 public constant maxStakingDuration = 365 * 24 * 60 * 60;

    uint256 private totalSupply;
    uint256 private totalFinalSupply;

    uint256 public constant maxDeposits = 20;
    uint256 public constant maxLocks = 50;

    mapping(address => Deposit[]) deposits;
    mapping(address => uint256) balancesFinal;

    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    mapping(address => Lock[]) locks;

    struct Deposit {
        uint256 amount;
        uint256 multiplier;
        uint256 start;
        uint256 end;
    }

    struct Lock {
        uint256 amount;
        uint256 start;
        uint256 end;
    }

    event Deposited(
        address indexed staker,
        uint256 amount,
        uint256 duration,
        uint256 multiplier
    );
    event Withdrawn(address indexed staker, uint256 amount);
    event LockCreated(address indexed staker, uint256 amount, uint256 start, uint256 end);
    event RewardClaimed(address indexed staker, uint256 amount);
    event RewardAdded(uint256 reward);
    event RewardsDurationUpdated(uint256 newDuration);

    constructor(
        IERC20 _depositToken,
        IERC20 _rewardToken,
        uint256 _stakingPoolDuration,
        uint256 _lockDuration,
        uint256 _rewardRate,
        string memory _name
    ) {
        poolManager = msg.sender;
        name = _name;

        depositToken = _depositToken;
        rewardToken = _rewardToken;

        stakingPoolDuration = _stakingPoolDuration;
        periodFinish = block.timestamp + _stakingPoolDuration;

        lockDuration = _lockDuration;

        rewardRate = _rewardRate;
    }

    modifier onlyPoolManager() {
        require(msg.sender == poolManager, 'Only pool manager can call this function');
        _;
    }

    modifier updateReward(address _account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();

        if (_account != address(0)) {
            rewards[_account] = earned(_account);
            userRewardPerTokenPaid[_account] = rewardPerTokenStored;
        }
        _;
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return block.timestamp < periodFinish ? block.timestamp : periodFinish;
    }

    function rewardPerToken() public view returns (uint256) {
        if (totalFinalSupply == 0) {
            return rewardPerTokenStored;
        }

        return
            rewardPerTokenStored +
            ((((lastTimeRewardApplicable() - lastUpdateTime) * rewardRate) * 1e18) /
                totalFinalSupply);
    }

    function earned(address _account) public view override returns (uint256) {
        return
            ((balancesFinal[_account] *
                (rewardPerToken() - userRewardPerTokenPaid[_account])) / 1e18) +
            rewards[_account];
    }

    function stake(uint256 _amount, uint256 _lockDuration)
        external
        updateReward(msg.sender)
    {
        require(_amount > 0, 'Cannot deposit 0');
        require(
            deposits[msg.sender].length < maxDeposits,
            'Cannot make more than 20 staking structs'
        );

        uint256 duration = _lockDuration.min(maxStakingDuration);
        duration = duration.max(minStakingDuration);

        uint256 _multiplier = getMultiplier(duration);

        depositToken.safeTransferFrom(msg.sender, address(this), _amount);

        totalSupply += _amount;
        totalFinalSupply += (_amount * _multiplier) / 10000;
        balancesFinal[msg.sender] += (_amount * _multiplier) / 10000;

        deposits[msg.sender].push(
            Deposit({
                amount: _amount,
                multiplier: _multiplier,
                start: block.timestamp,
                end: block.timestamp + duration
            })
        );

        emit Deposited(msg.sender, _amount, duration, _multiplier);
    }

    function withdraw(uint256 _depositId) external updateReward(msg.sender) {
        require(_depositId < deposits[msg.sender].length, 'Deposit does not exist');

        Deposit memory userDeposit = deposits[msg.sender][_depositId];
        require(block.timestamp >= userDeposit.end, 'Too soon');

        totalSupply -= userDeposit.amount;
        totalFinalSupply -= (userDeposit.amount * userDeposit.multiplier) / 10000;

        balancesFinal[msg.sender] -=
            (userDeposit.amount * userDeposit.multiplier) /
            10000;

        deposits[msg.sender][_depositId] = deposits[msg.sender][
            deposits[msg.sender].length - 1
        ];
        deposits[msg.sender].pop();

        depositToken.safeTransfer(msg.sender, userDeposit.amount);
        emit Withdrawn(msg.sender, userDeposit.amount);
    }

    function getReward() external updateReward(msg.sender) {
        uint256 rewardsToLock = rewards[msg.sender];
        require(rewardsToLock > 0, 'You should have more than 0 reward tokens');
        require(
            locks[msg.sender].length < maxLocks,
            'Cannot make more than 50 lock structs'
        );

        rewards[msg.sender] = 0;
        totalClaimed += rewardsToLock;
        createLock(msg.sender, rewardsToLock);
    }

    function getTotalDeposit(address _account) external view override returns (uint256) {
        uint256 total;
        for (uint256 i = 0; i < deposits[_account].length; i++) {
            total += deposits[_account][i].amount;
        }
        return total;
    }

    function getTotalDeposits(address _account)
        external
        view
        override
        returns (DepositInfo[] memory)
    {
        DepositInfo[] memory info = new DepositInfo[](deposits[_account].length);

        for (uint256 i = 0; i < deposits[_account].length; i++) {
            Deposit memory deposit = deposits[_account][i];

            if (block.timestamp >= deposit.end) {
                info[i] = DepositInfo({
                    poolName: name,
                    depositId: i,
                    amount: deposit.amount,
                    start: deposit.start,
                    ends: deposit.end,
                    available: true
                });
            } else {
                info[i] = DepositInfo({
                    poolName: name,
                    depositId: i,
                    amount: deposit.amount,
                    start: deposit.start,
                    ends: deposit.end,
                    available: false
                });
            }
        }

        return info;
    }

    function getDepositsOf(address _account) external view returns (Deposit[] memory) {
        return deposits[_account];
    }

    function getDepositsLengthOf(address _account) external view returns (uint256) {
        return deposits[_account].length;
    }

    function getTotalReward(address _account) external view override returns (uint256) {
        uint256 total;
        for (uint256 i = 0; i < locks[_account].length; i++) {
            total += locks[_account][i].amount;
        }
        return total;
    }

    function getTotalRewards(address _account)
        external
        view
        override
        returns (LockInfo[] memory)
    {
        LockInfo[] memory info = new LockInfo[](locks[_account].length);

        for (uint256 i = 0; i < locks[_account].length; i++) {
            Lock memory lock = locks[_account][i];

            if (block.timestamp >= lock.end) {
                info[i] = LockInfo({
                    poolName: name,
                    lockId: i,
                    amount: lock.amount,
                    ends: lock.end,
                    available: true
                });
            } else {
                info[i] = LockInfo({
                    poolName: name,
                    lockId: i,
                    amount: lock.amount,
                    ends: lock.end,
                    available: false
                });
            }
        }

        return info;
    }

    function getLocksOf(address _account) external view returns (Lock[] memory) {
        return locks[_account];
    }

    function getLocksLengthOf(address _account) external view returns (uint256) {
        return locks[_account].length;
    }

    function claimRewardFromLock(uint256 _lockId) public {
        require(locks[msg.sender].length > _lockId, 'Lock doesnt exist');
        Lock memory lock = locks[msg.sender][_lockId];

        require(block.timestamp >= lock.end, 'Too soon');

        locks[msg.sender][_lockId] = locks[msg.sender][locks[msg.sender].length - 1];
        locks[msg.sender].pop();

        rewardToken.safeTransfer(msg.sender, lock.amount);
        emit RewardClaimed(msg.sender, lock.amount);
    }

    function TVL() external view override returns (uint256) {
        return totalSupply;
    }

    function finalTVL() external view override returns (uint256) {
        return totalFinalSupply;
    }

    function notifyRewardAmount(uint256 _reward)
        external
        override
        onlyPoolManager
        updateReward(address(0))
    {
        if (block.timestamp >= periodFinish) {
            rewardRate = _reward / stakingPoolDuration;
        } else {
            uint256 remainingTime = periodFinish - block.timestamp;
            uint256 leftover = remainingTime * rewardRate;
            rewardRate = (_reward + leftover) / stakingPoolDuration;
        }

        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp + stakingPoolDuration;
        emit RewardAdded(_reward);
    }

    function setRewardsDuration(uint256 _stakingPoolDuration)
        external
        override
        onlyPoolManager
    {
        require(
            block.timestamp > periodFinish,
            'Previous rewards period must be complete before changing the duration for the new period'
        );

        stakingPoolDuration = _stakingPoolDuration;
        emit RewardsDurationUpdated(_stakingPoolDuration);
    }

    function recoverERC20(
        address tokenAddress,
        uint256 tokenAmount,
        address receiver
    ) external override onlyPoolManager {
        require(
            tokenAddress != address(depositToken) ||
                tokenAmount + totalSupply <= rewardToken.balanceOf(address(this)),
            'TimeLockPool.recoverERC20: '
        );

        IERC20(tokenAddress).safeTransfer(receiver, tokenAmount);
    }

    function createLock(address _account, uint256 _amount) internal {
        locks[_account].push(
            Lock({
                amount: _amount,
                start: block.timestamp,
                end: block.timestamp + lockDuration
            })
        );

        emit LockCreated(
            _account,
            _amount,
            block.timestamp,
            block.timestamp + lockDuration
        );
    }

    function getMultiplier(uint256 _duration) internal pure returns (uint256) {
        if (_duration == minStakingDuration) {
            return 10000;
        } else {
            return 10000 + (_duration * 10000) / maxStakingDuration;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/math/Math.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';

abstract contract ITimeLockPool {
    using SafeERC20 for IERC20;

    string public name;

    IERC20 public rewardToken;
    IERC20 public depositToken;

    uint256 public rewardRate;

    uint256 public totalClaimed;

    struct DepositInfo {
        string poolName;
        uint256 depositId;
        uint256 amount;
        uint256 start;
        uint256 ends;
        bool available;
    }

    struct LockInfo {
        string poolName;
        uint256 lockId;
        uint256 amount;
        uint256 ends;
        bool available;
    }

    function TVL() external view virtual returns (uint256);

    function finalTVL() external view virtual returns (uint256);

    function earned(address _account) public view virtual returns (uint256);

    function getTotalDeposit(address _account) external view virtual returns (uint256);

    function getTotalReward(address _account) external view virtual returns (uint256);

    function getTotalDeposits(address _account)
        external
        view
        virtual
        returns (DepositInfo[] memory);

    function getTotalRewards(address _account)
        external
        view
        virtual
        returns (LockInfo[] memory);

    function recoverERC20(
        address tokenAddress,
        uint256 tokenAmount,
        address receiver
    ) external virtual;

    function setRewardsDuration(uint256 _stakingPoolDuration) external virtual;

    function notifyRewardAmount(uint256 _reward) external virtual;
}