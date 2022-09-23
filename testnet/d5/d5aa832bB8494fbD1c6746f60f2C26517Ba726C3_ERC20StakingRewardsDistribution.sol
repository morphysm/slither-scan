/**
 *Submitted for verification at testnet.snowtrace.io on 2022-06-13
*/

// File: contracts/interfaces/IERC20StakingRewardsDistribution.sol





pragma solidity >=0.8.0;



interface IERC20StakingRewardsDistribution {

    function rewardAmount(address _rewardToken) external view returns (uint256);



    function recoverableUnassignedReward(address _rewardToken)

        external

        view

        returns (uint256);



    function stakedTokensOf(address _staker) external view returns (uint256);



    function getRewardTokens() external view returns (address[] memory);



    function getClaimedRewards(address _claimer)

        external

        view

        returns (uint256[] memory);



    function initialize(

        address[] calldata _rewardTokenAddresses,

        address _stakableTokenAddress,

        uint256[] calldata _rewardAmounts,

        uint64 _startingTimestamp,

        uint64 _endingTimestamp,

        bool _locked,

        uint256 _stakingCap

    ) external;



    function cancel() external;



    function recoverRewardsAfterCancel() external;



    function recoverRewardAfterCancel(address _token) external;



    function recoverUnassignedRewards() external;



    function recoverSpecificUnassignedRewards(address _token) external;



    function stake(uint256 _amount) external;



    function withdraw(uint256 _amount) external;



    function claim(uint256[] memory _amounts, address _recipient) external;



    function claimAll(address _recipient) external;



    function claimAllSpecific(address _token, address _recipient) external;



    function exit(address _recipient) external;



    function claimableRewards(address _staker)

        external

        view

        returns (uint256[] memory);



    function renounceOwnership() external;



    function transferOwnership(address _newOwner) external;



    function addRewards(address _token, uint256 _amount) external;

}


// File: contracts/interfaces/IERC20StakingRewardsDistributionFactory.sol





pragma solidity >=0.8.0;




interface IERC20StakingRewardsDistributionFactory {

    function createDistribution(

        address[] calldata _rewardTokenAddresses,

        address _stakableTokenAddress,

        uint256[] calldata _rewardAmounts,

        uint64 _startingTimestamp,

        uint64 _endingTimestamp,

        bool _locked,

        uint256 _stakingCap

    ) external;



    function getDistributionsAmount() external view returns (uint256);



    function implementation() external view returns (address);



    function upgradeImplementation(address _newImplementation) external;



    function distributions(uint256 _index)

        external

        view

        returns (IERC20StakingRewardsDistribution);



    function stakingPaused() external view returns (bool);



    function pauseStaking() external;



    function resumeStaking() external;

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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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

// File: @openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

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

// File: @openzeppelin/contracts/utils/math/Math.sol


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

// File: contracts/ERC20StakingRewardsDistribution.sol





pragma solidity 0.8.12;








/**

 * Errors codes:

 *

 * SRD01: invalid starting timestamp

 * SRD02: invalid time duration

 * SRD03: inconsistent reward token/amount

 * SRD04: 0 address as reward token

 * SRD05: no reward

 * SRD06: no funding

 * SRD07: 0 address as stakable token

 * SRD08: distribution already started

 * SRD09: tried to stake nothing

 * SRD10: staking cap hit

 * SRD11: tried to withdraw nothing

 * SRD12: funds locked until the distribution ends

 * SRD13: withdrawn amount greater than current stake

 * SRD14: inconsistent claimed amounts

 * SRD15: insufficient claimable amount

 * SRD16: 0 address owner

 * SRD17: caller not owner

 * SRD18: already initialized

 * SRD19: invalid state for cancel to be called

 * SRD20: not started

 * SRD21: already ended

 * SRD23: no rewards are claimable while claiming all

 * SRD24: no rewards are claimable while manually claiming an arbitrary amount of rewards

 * SRD25: staking is currently paused

 * SRD26: no rewards were added

 * SRD27: maximum number of reward tokens breached

 * SRD28: duplicated reward tokens

 * SRD29: distribution must be canceled

 */

contract ERC20StakingRewardsDistribution is IERC20StakingRewardsDistribution {

    using SafeERC20 for IERC20;



    uint224 constant MULTIPLIER = 2**112;



    struct Reward {

        address token;

        uint256 amount;

        uint256 toBeRewarded;

        uint256 perStakedToken;

        uint256 recoverableAmount;

        uint256 claimed;

    }



    struct StakerRewardInfo {

        uint256 consolidatedPerStakedToken;

        uint256 earned;

        uint256 claimed;

    }



    struct Staker {

        uint256 stake;

        mapping(address => StakerRewardInfo) rewardInfo;

    }



    Reward[] public rewards;

    mapping(address => Staker) public stakers;

    uint64 public startingTimestamp;

    uint64 public endingTimestamp;

    uint64 public lastConsolidationTimestamp;

    IERC20 public stakableToken;

    address public owner;

    address public factory;

    bool public locked;

    bool public canceled;

    bool public initialized;

    uint256 public totalStakedTokensAmount;

    uint256 public stakingCap;



    event OwnershipTransferred(

        address indexed previousOwner,

        address indexed newOwner

    );

    event Initialized(

        address[] rewardsTokenAddresses,

        address stakableTokenAddress,

        uint256[] rewardsAmounts,

        uint64 startingTimestamp,

        uint64 endingTimestamp,

        bool locked,

        uint256 stakingCap

    );

    event Canceled();

    event Staked(address indexed staker, uint256 amount);

    event Withdrawn(address indexed withdrawer, uint256 amount);

    event Claimed(address indexed claimer, uint256[] amounts);

    event Recovered(uint256[] amounts);

    event RecoveredAfterCancel(address token, uint256 amount);

    event UpdatedRewards(uint256[] amounts);



    function initialize(

        address[] calldata _rewardTokenAddresses,

        address _stakableTokenAddress,

        uint256[] calldata _rewardAmounts,

        uint64 _startingTimestamp,

        uint64 _endingTimestamp,

        bool _locked,

        uint256 _stakingCap

    ) external override onlyUninitialized {

        require(_startingTimestamp > block.timestamp, "SRD01");

        require(_endingTimestamp > _startingTimestamp, "SRD02");

        require(_rewardTokenAddresses.length == _rewardAmounts.length, "SRD03");

        require(_rewardTokenAddresses.length <= 5, "SRD27");



        // Initializing reward tokens and amounts

        for (uint8 _i = 0; _i < _rewardTokenAddresses.length; _i++) {

            address _rewardTokenAddress = _rewardTokenAddresses[_i];



            // checking for duplicates

            for (uint8 _j = _i + 1; _j < _rewardTokenAddresses.length; _j++)

                require(

                    _rewardTokenAddress != _rewardTokenAddresses[_j],

                    "SRD28"

                );



            uint256 _rewardAmount = _rewardAmounts[_i];

            require(_rewardTokenAddress != address(0), "SRD04");

            require(_rewardAmount > 0, "SRD05");

            IERC20 _rewardToken = IERC20(_rewardTokenAddress);

            require(

                _rewardToken.balanceOf(address(this)) >= _rewardAmount,

                "SRD06"

            );

            rewards.push(

                Reward({

                    token: _rewardTokenAddress,

                    amount: _rewardAmount,

                    toBeRewarded: _rewardAmount * MULTIPLIER,

                    perStakedToken: 0,

                    recoverableAmount: 0,

                    claimed: 0

                })

            );

        }



        require(_stakableTokenAddress != address(0), "SRD07");

        stakableToken = IERC20(_stakableTokenAddress);



        owner = msg.sender;

        factory = msg.sender;

        startingTimestamp = _startingTimestamp;

        endingTimestamp = _endingTimestamp;

        lastConsolidationTimestamp = _startingTimestamp;

        locked = _locked;

        stakingCap = _stakingCap;

        initialized = true;

        canceled = false;



        emit Initialized(

            _rewardTokenAddresses,

            _stakableTokenAddress,

            _rewardAmounts,

            _startingTimestamp,

            _endingTimestamp,

            _locked,

            _stakingCap

        );

    }



    function cancel() external override onlyOwner {

        require(initialized && !canceled, "SRD19");

        require(block.timestamp < startingTimestamp, "SRD08");

        canceled = true;

        emit Canceled();

    }



    function recoverRewardsAfterCancel() external override onlyOwner {

        require(canceled, "SRD29");

        for (uint256 _i; _i < rewards.length; _i++) {

            Reward storage _reward = rewards[_i];

            IERC20(_reward.token).safeTransfer(

                owner,

                IERC20(_reward.token).balanceOf(address(this))

            );

        }

    }



    function recoverRewardAfterCancel(address _token)

        external

        override

        onlyOwner

    {

        require(canceled, "SRD29");

        for (uint256 _i; _i < rewards.length; _i++) {

            Reward memory _reward = rewards[_i];

            if (_reward.token == _token) {

                uint256 _recoveredAmount =

                    IERC20(_reward.token).balanceOf(address(this));

                if (_recoveredAmount > 0)

                    IERC20(_reward.token).safeTransfer(owner, _recoveredAmount);

                emit RecoveredAfterCancel(_token, _recoveredAmount);

                break;

            }

        }

    }



    function recoverUnassignedRewards()

        external

        override

        onlyOwner

        onlyStarted

    {

        consolidateReward();

        uint256[] memory _recoveredUnassignedRewards =

            new uint256[](rewards.length);

        for (uint256 _i; _i < rewards.length; _i++) {

            Reward storage _reward = rewards[_i];

            // recoverable rewards are going to be recovered in this tx (if it does not revert),

            // so we add them to the claimed rewards right now

            _reward.claimed += _reward.recoverableAmount / MULTIPLIER;

            delete _reward.recoverableAmount;

            uint256 _recoverableRewards =

                IERC20(_reward.token).balanceOf(address(this)) -

                    (_reward.amount - _reward.claimed);

            if (_recoverableRewards > 0) {

                _recoveredUnassignedRewards[_i] = _recoverableRewards;

                IERC20(_reward.token).safeTransfer(owner, _recoverableRewards);

            }

        }

        emit Recovered(_recoveredUnassignedRewards);

    }



    function recoverSpecificUnassignedRewards(address _token)

        external

        override

        onlyOwner

        onlyStarted

    {

        consolidateReward();

        uint256[] memory _recoveredUnassignedRewards =

            new uint256[](rewards.length);

        for (uint256 _i; _i < rewards.length; _i++) {

            Reward storage _reward = rewards[_i];

            address _rewardToken = _reward.token;

            if (_token == _rewardToken) {

                // recoverable rewards are going to be recovered in this tx (if it does not revert),

                // so we add them to the claimed rewards right now

                _reward.claimed += _reward.recoverableAmount / MULTIPLIER;

                delete _reward.recoverableAmount;

                uint256 _recoverableRewards =

                    IERC20(_rewardToken).balanceOf(address(this)) -

                        (_reward.amount - _reward.claimed);

                if (_recoverableRewards > 0) {

                    _recoveredUnassignedRewards[_i] = _recoverableRewards;

                    IERC20(_rewardToken).safeTransfer(

                        owner,

                        _recoverableRewards

                    );

                }

                break;

            }

        }

        emit Recovered(_recoveredUnassignedRewards);

    }



    function stake(uint256 _amount) external override onlyRunning {

        require(

            !IERC20StakingRewardsDistributionFactory(factory).stakingPaused(),

            "SRD25"

        );

        require(_amount > 0, "SRD09");

        if (stakingCap > 0) {

            require(totalStakedTokensAmount + _amount <= stakingCap, "SRD10");

        }

        consolidateReward();

        Staker storage _staker = stakers[msg.sender];

        _staker.stake += _amount;

        totalStakedTokensAmount += _amount;

        stakableToken.safeTransferFrom(msg.sender, address(this), _amount);

        emit Staked(msg.sender, _amount);

    }



    function withdraw(uint256 _amount) public override onlyStarted {

        require(_amount > 0, "SRD11");

        if (locked) {

            require(block.timestamp > endingTimestamp, "SRD12");

        }

        consolidateReward();

        Staker storage _staker = stakers[msg.sender];

        require(_staker.stake >= _amount, "SRD13");

        _staker.stake -= _amount;

        totalStakedTokensAmount -= _amount;

        stakableToken.safeTransfer(msg.sender, _amount);

        emit Withdrawn(msg.sender, _amount);

    }



    function claim(uint256[] memory _amounts, address _recipient)

        external

        override

        onlyStarted

    {

        require(_amounts.length == rewards.length, "SRD14");

        consolidateReward();

        Staker storage _staker = stakers[msg.sender];

        uint256[] memory _claimedRewards = new uint256[](rewards.length);

        for (uint256 _i; _i < rewards.length; _i++) {

            Reward storage _reward = rewards[_i];

            StakerRewardInfo storage _stakerRewardInfo =

                _staker.rewardInfo[_reward.token];

            uint256 _claimableReward =

                _stakerRewardInfo.earned - _stakerRewardInfo.claimed;

            uint256 _wantedAmount = _amounts[_i];

            require(_claimableReward >= _wantedAmount, "SRD15");

            if (_wantedAmount > 0) {

                _stakerRewardInfo.claimed += _wantedAmount;

                _reward.claimed += _wantedAmount;

                IERC20(_reward.token).safeTransfer(_recipient, _wantedAmount);

                _claimedRewards[_i] = _wantedAmount;

            }

        }

        emit Claimed(msg.sender, _claimedRewards);

    }



    function claimAll(address _recipient) public override onlyStarted {

        consolidateReward();

        Staker storage _staker = stakers[msg.sender];

        uint256[] memory _claimedRewards = new uint256[](rewards.length);

        for (uint256 _i; _i < rewards.length; _i++) {

            Reward storage _reward = rewards[_i];

            address _rewardToken = _reward.token;

            StakerRewardInfo storage _stakerRewardInfo =

                _staker.rewardInfo[_rewardToken];

            uint256 _claimableReward =

                _stakerRewardInfo.earned - _stakerRewardInfo.claimed;

            if (_claimableReward > 0) {

                _stakerRewardInfo.claimed += _claimableReward;

                _reward.claimed += _claimableReward;

                IERC20(_rewardToken).safeTransfer(_recipient, _claimableReward);

                _claimedRewards[_i] = _claimableReward;

            }

        }

        emit Claimed(msg.sender, _claimedRewards);

    }



    function claimAllSpecific(address _token, address _recipient)

        external

        override

        onlyStarted

    {

        consolidateReward();

        Staker storage _staker = stakers[msg.sender];

        uint256[] memory _claimedRewards = new uint256[](rewards.length);

        for (uint256 _i; _i < rewards.length; _i++) {

            Reward storage _reward = rewards[_i];

            address _rewardToken = _reward.token;

            if (_token == _rewardToken) {

                StakerRewardInfo storage _stakerRewardInfo =

                    _staker.rewardInfo[_rewardToken];

                uint256 _claimableReward =

                    _stakerRewardInfo.earned - _stakerRewardInfo.claimed;

                if (_claimableReward > 0) {

                    _stakerRewardInfo.claimed += _claimableReward;

                    _reward.claimed += _claimableReward;

                    IERC20(_rewardToken).safeTransfer(

                        _recipient,

                        _claimableReward

                    );

                    _claimedRewards[_i] = _claimableReward;

                }

                break;

            }

        }

        emit Claimed(msg.sender, _claimedRewards);

    }



    function exit(address _recipient) external override {

        claimAll(_recipient);

        withdraw(stakers[msg.sender].stake);

    }



    function addRewards(address _token, uint256 _amount)

        external

        override

        onlyStarted

    {

        consolidateReward();

        uint256[] memory _updatedAmounts = new uint256[](rewards.length);

        bool _atLeastOneUpdate = false;

        for (uint8 _i = 0; _i < rewards.length; _i++) {

            Reward storage _reward = rewards[_i];

            if (_reward.token == _token) {

                _reward.amount += _amount;

                _reward.toBeRewarded += _amount * MULTIPLIER;

                _atLeastOneUpdate = true;

                IERC20(_token).safeTransferFrom(

                    msg.sender,

                    address(this),

                    _amount

                );

            }

            _updatedAmounts[_i] = _reward.amount;

        }

        require(_atLeastOneUpdate, "SRD26");

        emit UpdatedRewards(_updatedAmounts);

    }



    function consolidateReward() private {

        uint64 _consolidationTimestamp =

            uint64(Math.min(block.timestamp, endingTimestamp));

        uint256 _lastPeriodDuration =

            uint256(_consolidationTimestamp - lastConsolidationTimestamp);

        uint256 _durationLeft =

            uint256(endingTimestamp - lastConsolidationTimestamp);

        Staker storage _staker = stakers[msg.sender];

        for (uint256 _i; _i < rewards.length; _i++) {

            Reward storage _reward = rewards[_i];

            StakerRewardInfo storage _stakerRewardInfo =

                _staker.rewardInfo[_reward.token];

            if (_lastPeriodDuration > 0) {

                uint256 _periodReward =

                    (_lastPeriodDuration * _reward.toBeRewarded) /

                        _durationLeft;

                if (totalStakedTokensAmount == 0) {

                    _reward.recoverableAmount += _periodReward;

                    // no need to update the reward per staked token since in this period

                    // there have been no staked tokens, so no reward has been given out to stakers

                } else {

                    _reward.perStakedToken +=

                        _periodReward /

                        totalStakedTokensAmount;

                }

                _reward.toBeRewarded -= _periodReward;

            }

            uint256 _rewardSinceLastConsolidation =

                (_staker.stake *

                    (_reward.perStakedToken -

                        _stakerRewardInfo.consolidatedPerStakedToken)) /

                    MULTIPLIER;

            _stakerRewardInfo.earned += _rewardSinceLastConsolidation;

            _stakerRewardInfo.consolidatedPerStakedToken = _reward

                .perStakedToken;

        }

        lastConsolidationTimestamp = _consolidationTimestamp;

    }



    function claimableRewards(address _account)

        external

        view

        override

        returns (uint256[] memory)

    {

        uint256[] memory _outstandingRewards = new uint256[](rewards.length);

        if (!initialized || block.timestamp < startingTimestamp)

            return _outstandingRewards;

        Staker storage _staker = stakers[_account];

        uint64 _consolidationTimestamp =

            uint64(Math.min(block.timestamp, endingTimestamp));

        uint256 _lastPeriodDuration =

            uint256(_consolidationTimestamp - lastConsolidationTimestamp);

        uint256 _durationLeft =

            uint256(endingTimestamp - lastConsolidationTimestamp);

        for (uint256 _i; _i < rewards.length; _i++) {

            Reward storage _reward = rewards[_i];

            StakerRewardInfo storage _stakerRewardInfo =

                _staker.rewardInfo[_reward.token];

            uint256 _localRewardPerStakedToken = _reward.perStakedToken;

            if (_lastPeriodDuration > 0 && totalStakedTokensAmount > 0) {

                _localRewardPerStakedToken +=

                    (_lastPeriodDuration * _reward.toBeRewarded) /

                    totalStakedTokensAmount /

                    _durationLeft;

            }

            uint256 _rewardSinceLastConsolidation =

                (_staker.stake *

                    (_localRewardPerStakedToken -

                        _stakerRewardInfo.consolidatedPerStakedToken)) /

                    MULTIPLIER;

            _outstandingRewards[_i] =

                _rewardSinceLastConsolidation +

                (_stakerRewardInfo.earned - _stakerRewardInfo.claimed);

        }

        return _outstandingRewards;

    }



    function getRewardTokens()

        external

        view

        override

        returns (address[] memory)

    {

        address[] memory _rewardTokens = new address[](rewards.length);

        for (uint256 _i = 0; _i < rewards.length; _i++) {

            _rewardTokens[_i] = rewards[_i].token;

        }

        return _rewardTokens;

    }



    function rewardAmount(address _rewardToken)

        external

        view

        override

        returns (uint256)

    {

        for (uint256 _i = 0; _i < rewards.length; _i++) {

            Reward storage _reward = rewards[_i];

            if (_rewardToken == _reward.token) return _reward.amount;

        }

        return 0;

    }



    function stakedTokensOf(address _staker)

        external

        view

        override

        returns (uint256)

    {

        return stakers[_staker].stake;

    }



    function earnedRewardsOf(address _staker)

        external

        view

        returns (uint256[] memory)

    {

        Staker storage _stakerFromStorage = stakers[_staker];

        uint256[] memory _earnedRewards = new uint256[](rewards.length);

        for (uint256 _i; _i < rewards.length; _i++) {

            _earnedRewards[_i] = _stakerFromStorage.rewardInfo[

                rewards[_i].token

            ]

                .earned;

        }

        return _earnedRewards;

    }



    function recoverableUnassignedReward(address _rewardToken)

        external

        view

        override

        returns (uint256)

    {

        for (uint256 _i = 0; _i < rewards.length; _i++) {

            Reward storage _reward = rewards[_i];

            if (_reward.token == _rewardToken) {

                uint256 _nonRequiredFunds =

                    _reward.claimed + (_reward.recoverableAmount / MULTIPLIER);

                return

                    IERC20(_reward.token).balanceOf(address(this)) -

                    (_reward.amount - _nonRequiredFunds);

            }

        }

        return 0;

    }



    function getClaimedRewards(address _claimer)

        external

        view

        override

        returns (uint256[] memory)

    {

        Staker storage _staker = stakers[_claimer];

        uint256[] memory _claimedRewards = new uint256[](rewards.length);

        for (uint256 _i = 0; _i < rewards.length; _i++) {

            Reward storage _reward = rewards[_i];

            _claimedRewards[_i] = _staker.rewardInfo[_reward.token].claimed;

        }

        return _claimedRewards;

    }



    function renounceOwnership() external override onlyOwner {

        owner = address(0);

        emit OwnershipTransferred(owner, address(0));

    }



    function transferOwnership(address _newOwner) external override onlyOwner {

        require(_newOwner != address(0), "SRD16");

        emit OwnershipTransferred(owner, _newOwner);

        owner = _newOwner;

    }



    modifier onlyOwner() {

        require(owner == msg.sender, "SRD17");

        _;

    }



    modifier onlyUninitialized() {

        require(!initialized, "SRD18");

        _;

    }



    modifier onlyStarted() {

        require(

            initialized && !canceled && block.timestamp >= startingTimestamp,

            "SRD20"

        );

        _;

    }



    modifier onlyRunning() {

        require(

            initialized &&

                !canceled &&

                block.timestamp >= startingTimestamp &&

                block.timestamp <= endingTimestamp,

            "SRD21"

        );

        _;

    }

}