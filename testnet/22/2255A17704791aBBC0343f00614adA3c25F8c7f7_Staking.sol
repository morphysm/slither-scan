/**
 *Submitted for verification at snowtrace.io on 2021-12-02
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// File @openzeppelin/contracts/utils/[email protected]

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


// File @openzeppelin/contracts/security/[email protected]

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


// File @openzeppelin/contracts/token/ERC20/[email protected]

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


// File @openzeppelin/contracts/token/ERC20/extensions/[email protected]

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}


// File @openzeppelin/contracts/utils/[email protected]

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


// File contracts/Staking/TimedValuesStorage.sol

/**
 * TimedValuesStorage
 * Stores and Operates on TimedValue arrays which works similar to stack (LIFO)
 * - new value for specified account is added at the end of his TimedValue array
 * - remove is done by .pop values from TimedValue array
 *
 * - supports time based checks for deposited values
 */
contract TimedValuesStorage is Ownable {

    // Struct which stores individual value with timestamp
    struct TimedValue {
       uint256 value;
       uint256 timestamp;
    }

    // limit on deposits TimedValue array length, which prevents reaching gas limit
    uint256 public maxDepositArrayLength;

    // additional length index for each of deposit TimedValue array,
    // which makes operations in deposits more optimal
    mapping(address => uint256) public realDepositsLength;

    // TimedValue mapping structure, storing TimedValue for all accounts
    mapping(address => TimedValue[]) private deposits;

    // require non empty deposit for given account
    modifier nonEmpty(address account) {
        require(realDepositsLength[account] > 0, "no item found");
        _;
    }

    /**
     * @dev Gets the whole value balance for the specified address, by iterating on array
     * @return An uint256 representing the balance owned by the passed address
     */
    function depositSum(address account) public view returns (uint256) {
        uint256 totalAccValue;

        for (uint i = 0; i < realDepositsLength[account]; i++) {
            totalAccValue += deposits[account][i].value;
        }

        return totalAccValue;
    }

    /**
     * @dev check if account value meets given requirements of minimum value
     * deposited up to the maxTimestamp date
     * @return boolean
     */
    function isStoredLongEnough(address account, uint256 minValue, uint256 maxTimestamp) external view returns (bool) {
        uint256 enoughValue;

        for (uint i = 0; i < realDepositsLength[account]; i++) {
            if (deposits[account][i].timestamp > maxTimestamp) {
                break;
            }

            enoughValue += deposits[account][i].value;

            if (enoughValue >= minValue) {
                return true;
            }
        }

        return false;
    }

    /**
     * @dev total value older than given maxTimestamp
     * @notice this function is less optimal than isStoredLongEnough check
     * @return uint256 totalValue
     */
    function valueStoredLongEnough(address account, uint256 maxTimestamp) external view returns (uint256) {
        uint256 totalValue;

        for (uint i = 0; i < realDepositsLength[account]; i++) {
            if (deposits[account][i].timestamp > maxTimestamp) {
                break;
            }

            totalValue += deposits[account][i].value;
        }

        return totalValue;
    }

    /**
     * @dev time left in seconds for given minValue to be older than given maxTimestamp
     * @notice time left depends on the youngest stake which is included to minValue
     * @return boolean - is the account deposit sum enough to pass minValue?
     * @return uint256 time in seconds, 0 if value is already older
     */
    function timeLeftToMeetRequirements(address account, uint256 minValue, uint256 maxTimestamp) external view returns (bool, uint256) {
        uint256 enoughValue;

        for (uint i = 0; i < realDepositsLength[account]; i++) {
            enoughValue += deposits[account][i].value;

            if (enoughValue >= minValue) {
                if (maxTimestamp >= deposits[account][i].timestamp) {
                    return (true, 0);
                }

                return (true, deposits[account][i].timestamp - maxTimestamp);
            }
        }
        return (false, 0);
    }

    /**
     * @dev Helper, gets the last value
     * @return last account value
     */
    function _getLastValue(address account) private view nonEmpty(account) returns (uint256) {
        uint256 lastIdx = realDepositsLength[account] - 1;
        return deposits[account][lastIdx].value;
    }

    /**
      * @dev Helper, returns allocated deposit array length
      */
    function allocDepositLength(address account) public view returns (uint256) {
        return deposits[account].length;
    }

    /**
      * @dev Helper, checks if max alloved array length is achieved
      */
    function maxDepositLengthAchieved(address account) public view returns (bool) {
        return realDepositsLength[account] >= maxDepositArrayLength;
    }

    /**
     * @dev sets a new maxDepositArrayLength limit
     */
    function setMaxDepositArrayLength(uint256 newLimit) external onlyOwner {
        require(newLimit > 0, "should have at least one value");
        maxDepositArrayLength = newLimit;
    }

    /**
     * @dev Push a new Value to deposits
     * @notice depends on realDepositsLength and maxDepositArrayLength, value could be
     * - simply pushed at the end of deposit TimedValuesStorage array
     * - added to existing value (but invalidated [removed]), by overwrite already allocated one
     * - if maxDepositArrayLength is reached, added to the last correct value (update timestamp)
     */
    function pushValue(address account, uint256 value) external onlyOwner {
        if (maxDepositLengthAchieved(account)) {
            // instead of adding a new value to the array and increasing its length, modify last value
            _increaseLastValue(account, value);
            return;
        }

        TimedValue memory timedValue = TimedValue({
            value: value,
            timestamp: block.timestamp // used for a long period of time
        });

        if (realDepositsLength[account] == allocDepositLength(account)) {
            deposits[account].push(timedValue);
            realDepositsLength[account]++;

        }
        else {
            // overwrite existing but removed value
            uint256 firstFreeIdx = realDepositsLength[account];
            deposits[account][firstFreeIdx] = timedValue;
            realDepositsLength[account]++;
        }
    }

    /**
     * @dev Removes given value from the TimedValue array
     * @notice One by one, starting from the last one
     */
    function removeValue(address account, uint256 value) external onlyOwner {
        uint256 leftToRemove = value;

        while (leftToRemove != 0) {
            uint256 lastValue = _getLastValue(account);

            if (leftToRemove >= lastValue) {
                uint256 removed = _removeLastValue(account);
                require(removed == lastValue, "removed value does not match");

                leftToRemove -= lastValue;
            }
            else {
                _decreaseLastValue(account, leftToRemove);
                leftToRemove = 0;
            }
        }
    }

    /**
     * @dev Removes the whole account deposit, by simply setting realDepositsLength to 0
     */
    function removeAll(address account) external nonEmpty(account) onlyOwner {
        realDepositsLength[account] = 0;
    }

    /**
     * @dev Remove the last record from account deposit,
     * @return removed value
     */
    function _removeLastValue(address account) private nonEmpty(account) returns (uint256) {
        uint256 valueToRemove = _getLastValue(account);

        realDepositsLength[account]--; // decrement realDepositsLength instead of pop

        return valueToRemove;
    }

    /**
     * @dev Increase / Update last value, set new timestamp
     */
    function _increaseLastValue(address account, uint256 increaseValue) private nonEmpty(account) {
        require(increaseValue != 0, "zero increase");
        uint256 lastIdx = realDepositsLength[account] - 1;

        deposits[account][lastIdx].value += increaseValue;
        deposits[account][lastIdx].timestamp = block.timestamp;
    }

    /**
     * @dev Decrease / Update last value, leave timestamp unchanged
     * @notice requires that decreaseValue is not equal to the last value (in that case remove should be used)
     */
    function _decreaseLastValue(address account, uint256 decreaseValue) private nonEmpty(account) {
        require(decreaseValue != 0, "zero decrease");
        uint256 lastIdx = realDepositsLength[account] - 1;

        uint256 lastValue = deposits[account][lastIdx].value;
        require(decreaseValue < lastValue, "decrease should be smaller");

        deposits[account][lastIdx].value = lastValue - decreaseValue;
    }
}


// File contracts/Staking/Staking.sol

/**
 * Main Staking contract, used for staking CLY tokens and manage stake requirements
 */
contract Staking is Ownable, Pausable {
    using SafeERC20 for IERC20;

    // Token that is supported by this contract. Should be registered in constructor
    IERC20Metadata private stakedToken;

    // Storage for accounts Stake data
    TimedValuesStorage private stakeDeposits;

    // holds precalculated TimedValuesStorage depositSums
    mapping(address => uint256) private depositSums;

    // amount of stake required by featured account
    uint256 public authorizedStakeAmount;

    // period in seconds of required stake for account to be featured
    uint256 public authorizedStakePeriod;

    event StakeAdded(address indexed account, uint256 value);
    event StakeRemoved(address indexed account, uint256 value);

    event AuthStakeAmountChanged(uint256 newStakeValue);
    event AuthStakePeriodChanged(uint256 newPeriod);

    /**
     * @dev Constructor
     * @param supportedToken_ The address of token contract
     */
    constructor(address supportedToken_, uint256 authorizedStakeAmount_, uint256 authorizedStakePeriod_) {
        require(supportedToken_ != address(0), "supported token cannot be 0x0");
        stakedToken = IERC20Metadata(supportedToken_);
        authorizedStakeAmount = authorizedStakeAmount_;
        authorizedStakePeriod = authorizedStakePeriod_;

        stakeDeposits = new TimedValuesStorage();
        stakeDeposits.setMaxDepositArrayLength(100);
    }

    /**
     * @dev totalStaked
     * @return total stake kept under this contract
     */
    function totalStaked() public view returns (uint256) {
        return stakedToken.balanceOf(address(this));
    }

    /**
     * @dev stakedBalanceOf public function which gets account stake balance,
     * using precalculated sums (optimal)
     * @return stake balance for given account
     */
    function stakedBalanceOf(address account) public view returns (uint256) {
        return depositSums[account];
    }

    /**
     * @dev recalculatedBalanceOf public function which gets account stake balance,
     * using TimedValuesStorage deposit, iteration over the whole array of stakes
     * @return stake balance for given account
     */
    function recalculatedBalanceOf(address account) public view returns (uint256) {
        return stakeDeposits.depositSum(account);
    }

    /**
     * @dev authStakedBalanceOf calculate total authorized stake older than authorizedStakePeriod
     * @notice less optinal than isAccountAuthorized check and still may not meet authorizedStakeAmount requirement
     * @return amount of account total authorized stake balance
     */
    function authStakedBalanceOf(address account) public view returns (uint256) {
        uint256 maxTimestamp = block.timestamp - authorizedStakePeriod;
        return stakeDeposits.valueStoredLongEnough(account, maxTimestamp);
    }

    /**
     * @dev check if account stake pass authorizedStakeAmount and authorizedStakePeriod
     * @return boolean - is the account authorized?
     */
    function isAccountAuthorized(address account) public view returns (bool) {
        uint256 maxTimestamp = block.timestamp - authorizedStakePeriod;
        return stakeDeposits.isStoredLongEnough(account, authorizedStakeAmount, maxTimestamp);
    }

    /**
     * @dev calculates the time in seconds which must elapse for the account to be authorized (to meet authorizedStakePeriod)
     * @return boolean - will the account be authorized?
     * false means that the account will not be authorized because of insufficient stake
     * @return uint256 - estimated time in seconds
     */
    function timeRemainingAuthorization(address account) public view returns (bool, uint256) {
        // solhint-disable-next-line not-rely-on-time
        uint256 maxTimestamp = block.timestamp - authorizedStakePeriod;
        return stakeDeposits.timeLeftToMeetRequirements(account, authorizedStakeAmount, maxTimestamp);
    }

    /**
     * @dev gets stakes Limit set on stakeDeposit
     */
    function getMaxNumOfStakes() public view returns (uint256) {
        return stakeDeposits.maxDepositArrayLength();
    }

    /**
     * @dev Helper which returns real deposit length for given account
     */
    function getAccountRealDepositLength(address account) public view returns (uint256) {
        return stakeDeposits.realDepositsLength(account);
    }

    /**
     * @dev Helper which returns allocated deposit length for given account
     */
    function getAccountAllocDepositLength(address account) public view returns (uint256) {
        return stakeDeposits.allocDepositLength(account);
    }

    /**
     *  @notice Pauses stake and unstake functionalities
     */
    function pauseStaking() external onlyOwner whenNotPaused {
        super._pause();
    }

    /**
     *  @notice Resumes stake and unstake functionalities
     */
    function unpauseStaking() external onlyOwner whenPaused {
        super._unpause();
    }

    /**
     * @dev setAuthorizedStakeAmount - allows to set new authorizedStakeAmount value
     * @param stake_ - new stake
     *
     * Emits a {AuthStakeAmountChanged} event
     */
    function setAuthorizedStakeAmount(uint256 stake_) external onlyOwner {
        authorizedStakeAmount = stake_;
        emit AuthStakeAmountChanged(stake_);
    }

    /**
     * @dev setAuthorizedStakePeriod - allows to set new authorizedStakePeriod value
     * @param period_ - new period in seconds
     *
     * Emits a {AuthStakePeriodChanged} event
     */
    function setAuthorizedStakePeriod(uint256 period_) external onlyOwner {
        authorizedStakePeriod = period_;
        emit AuthStakePeriodChanged(period_);
    }

    /**
     * @dev sets a new Limit for amount of stakes on stakeDeposit
     */
    function setMaxNumOfStakes(uint256 newLimit) external onlyOwner {
        stakeDeposits.setMaxDepositArrayLength(newLimit);
    }

    /**
     * @dev Stake tokens inside stakeDeposit
     *
     * Emits a {StakeAdded} event
     */
    function stake(uint256 amount) public whenNotPaused {
        stakeFor(msg.sender, amount);
    }

    /**
     * @dev StakeFor sends tokens to another address stake
     *
     * Emits a {StakeAdded} event
     */
    function stakeFor(address receiver, uint256 amount) public whenNotPaused {
        require(amount > 0, "Staking: cannot stake 0");

        // will transfer tokens to this contract (require approve)
        IERC20(stakedToken).safeTransferFrom(msg.sender, address(this), amount);

        stakeDeposits.pushValue(receiver, amount);
        depositSums[receiver] += amount;

        uint256 check = stakedBalanceOf(receiver);
        require(check >= authorizedStakeAmount, "Staking: stake too small");

        emit StakeAdded(receiver, amount);
    }

    /**
     * @dev Unstake sends staked tokens back to the sender
     *
     * Emits a {StakeRemoved} event
     */
    function unstake(uint256 amount) public whenNotPaused {
        require(amount > 0, "Staking: cannot unstake 0");
        require(depositSums[msg.sender] >= amount, "Staking: amount exceeds balance");

        if (depositSums[msg.sender] == amount) {
            stakeDeposits.removeAll(msg.sender);
        }
        else {
            stakeDeposits.removeValue(msg.sender, amount);
        }
        depositSums[msg.sender] -= amount;

        // will transfer tokens to the caller
        IERC20(stakedToken).safeTransfer(msg.sender, amount);

        emit StakeRemoved(msg.sender, amount);
    }
}