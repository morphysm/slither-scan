/**
 *Submitted for verification at testnet.snowtrace.io on 2022-05-12
*/

// File: @openzeppelin\contracts\token\ERC20\IERC20.sol
// SPDX-License-Identifier: MIT

// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.2;

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

// File: @openzeppelin\contracts\token\ERC20\extensions\IERC20Metadata.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.2;
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

// File: @openzeppelin\contracts\utils\Address.sol


// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.2;

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

// File: @openzeppelin\contracts\token\ERC20\utils\SafeERC20.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.2;
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

// File: contracts\precog\interfaces\IIPCOGFactory.sol

interface IIPCOGFactory {
    function create(uint8 decimals) external returns(address);
}

// File: contracts\precog-core\interfaces\IPrecogCore.sol

interface IPrecogCore {
    struct CoreConfiguration {
        address admin;
        address middleware;
        address exchange;
    }

    struct FeeConfiguration {
        uint64 depositFee;
        uint64 withdrawalFee;
        uint64 tradingFee;
        uint64 lendingFee;
    }

    struct CycleConfiguration {
        uint32 firstDefundingCycle;
        uint32 fundingCycle;
        uint32 defundingCycle;
        uint32 tradingCycle;
    }

    struct CyclesChangedInfo {
        uint48 tradingApplyTime;
        uint48 fundingApplyTime;
        uint48 defundingApplyTime;
        uint48 fundingDuration;
        uint48 firstDefundingDuration;
        uint48 defundingDuration;
    }

    event SetCycleConfiguration(
        address indexed admin,
        uint32 firstDefundingCycle,
        uint32 fundingCycle,
        uint32 defundingCycle,
        uint32 tradingCycle
    );

    event SetCoreConfiguration(
        address indexed admin,
        address newAdmin,
        address newMiddleware,
        address newExchange
    );

    event SetFeeConfiguration(
        address indexed admin,
        uint64 depositFee,
        uint64 withdrawalFee,
        uint64 tradingFee,
        uint64 lendingFee
    );
    event CollectFee(address indexed admin, address indexed token, uint amount);

    function PCOG() external view returns (address);

    function feeDecimalBase() external view returns (uint8);

    function getCoreConfiguration() external view returns (CoreConfiguration memory);

    function getFeeConfiguration() external view returns (FeeConfiguration memory);

    function getCycleConfiguration() external view returns (CycleConfiguration memory);

    function getCyclesChangedInfo(address token) external view returns (CyclesChangedInfo memory);

    function setCyclesChangedInfo(address token, CyclesChangedInfo memory config) external;

    function getCurrentFundingCycle(address token)
        external
        view
        returns (uint lastFundingStartTime, uint nextFundingStartTime);

    function minFunding(address token) external view returns (uint);

    function minDefunding(address token) external view returns (uint);

    function updateDefundingDuration(address token) external;
    function updateFundingDuration(address token) external;
}

// File: contracts\ipcog\interfaces\IIPCOG.sol

pragma solidity ^0.8.2;

interface IIPCOG {

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    function mint(address account, uint256 amount) external;

    function burnFrom(address account, uint256 amount) external;
    
    function burn(uint256 amount) external;

    function holders() external view returns (uint256);

    function isBurner(address account) external view returns (bool);

    function setBurner(address account, bool isBurnerRole) external; 

    event SwitchHolders(uint256 holders);
    event SetPeriodLockingTime(address owner, uint256 periodLockingTime);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: contracts\middleware-exchange\interfaces\IMiddlewareExchange.sol

pragma solidity ^0.8.2;

interface IMiddlewareExchange {
  function buyPCOG(address token, uint256 amount) external returns (uint256);
}

// File: contracts\withdrawal-register\interfaces\IWithdrawalRegister.sol

interface IWithdrawalRegister {
    struct Register {
        uint256 amount;
        uint256 deadline;
    }

    event RegisterWithdrawal(
        address token,
        address account, 
        uint256 amount,
        uint256 deadline
    );

    event ClaimWithdrawal(
        address token,
        address account,
        uint256 amount
    );

    function precog() external view returns (address);
    function precogCore() external view returns (address);
    function getRegister(address token, address account) external view returns (Register memory register);
    function isFirstWithdraw(address token, address account) external view returns (bool _isFirstWithdrawal);
    function isInDeadline(address token, address account) external view returns (bool);
    function registerWithdrawal(address token, address account, uint256 amount, uint256 deadline) external;
    function claimWithdrawal(address token, address account, address to, uint256 amount, uint256 fee) external;
}

// File: contracts\precog\interfaces\IPrecogV5.sol

interface IPrecogV5 {
    struct Investment {
        uint amount;
        uint unit;
        uint48 timestamp;
        uint16 idChanged;
    }

    struct Cycle {
        uint16 id;
        uint48 startTime;
        uint48 endTime;
    }

    struct CyclesChangedInfo {
        uint48 tradingApplyTime;
        uint48 fundingApplyTime;
        uint48 defundingApplyTime;
        uint48 fundingDuration;
        uint48 firstDefundingDuration;
        uint48 defundingDuration;
    }

    struct TokenPair {
        address token;
        address liqudityToken;
    }

    struct AccountProfitInfo {
        uint profitOf;
        uint claimedProfitOf;
        uint16 lastProfitIdOf;
        uint16 lastInvestmentIdOf;
    }

    struct AccountTradingInfo {
        uint depositedTimestampOf;
        uint availableAmount;
        bool isNotFirstIncreaseInvestment;
    }

    // Events
    event AddLiquidity(address indexed token, address indexed liquidityToken);
    event RemoveLiquidity(address indexed token, address indexed liquidityToken);
    event SendProfit(address indexed token, uint indexed cycleId, uint profitByToken, uint profitByPCOG);
    event UpdateTradingCycle(address indexed token, uint indexed cycleId, uint liquidity, uint duration);
    event Deposit(address indexed token, address indexed account, uint amount, uint fee);
    event RequestWithdrawal(address indexed token, address indexed account, uint amount);
    event TakeProfit(address indexed token, address indexed account, uint amount);
    event Withdraw(
        address indexed token,
        address indexed account,
        address indexed to,
        uint amount,
        uint fee,
        bool isEmergency
    );
    

    // View functions
    function getConfig()
        external
        view
        returns (
            address _core,
            address _factory,
            address _middlewareExchange,
            address _withdrawalRegister
        );

    function getInvestmentOfByIndex(
        address token,
        address account,
        uint index
    ) external view returns (Investment memory investmentOf);

    //function getTradingCycleByIndex(address token, uint index) external view returns (Cycle memory tradingCycle);
    function currentProfitId(address token) external view returns (uint16);

    function getLastInvestmentOf(address token, address account)
        external
        view
        returns (Investment memory lastInvestmentOf);

    //function isExistingToken(address token) external view returns (bool);
    function tokenConvert(address token) external view returns (address);

    function liquidity(address token) external view returns (uint);

    //function getProfitByIndex(address token, uint index) external view returns (uint);

    function getExistingTokensPair() external view returns (TokenPair[] memory pairs);

    function getExistingTokenPairByIndex(uint index) external view returns (TokenPair memory pair);

    function calculateProfit(address token, address account)
        external
        view
        returns (
            uint,
            uint16,
            uint16
        );

    function getCurrentTradingCycle(address token) external view returns (Cycle memory);

    function getTradingCycle(address token, uint48 timestamp) external view returns (Cycle memory);

    //function getTotalUnitOfTradingCycle(address token, uint16 index) external view returns (uint unit);

    // Functions for all role
    function updateCurrentTradingCycle(address token, uint limitTradingCycles) external;

    // Functions for middleware

    function takeInvestment(address token) external;

    function sendProfit(address token, uint profitAmount) external;

    // Functions for IPCOG
    function increaseInvestment(
        address token,
        address account,
        uint amount
    ) external;

    function decreaseInvestment(
        address token,
        address account,
        uint amount
    ) external;

    // Functions for user
    function deposit(address token, uint amount) external;

    function requestWithdrawal(address liquidityToken, uint amount) external;

    function takeProfit(address to, address token) external;

    function withdraw(
        address to,
        address token,
        uint amount,
        bool isWithdrawBeforeFundingTime
    ) external;
}

// File: contracts\precog\libraries\PrecogV5Library.sol

pragma solidity ^0.8.2; 
library PrecogV5Library {

    function _isAppliedChangedCycle(uint _nextCycleApplyChangingTimestamp) internal view returns (bool) {
        return block.timestamp > _nextCycleApplyChangingTimestamp;
    }

    function _chooseLastAvailableTradingId(
        IPrecogV5.Investment[] memory _investments,
        uint16 _investmentId, 
        uint16 _value
    ) internal pure returns (
        IPrecogV5.Investment memory _nextInvestment,
        uint16 _lastAvailableProfitId) 
    {
        _nextInvestment = IPrecogV5.Investment(0, 0, 0, 0);
        _lastAvailableProfitId = _value;
        if (_investmentId < _investments.length - 1) {
            _nextInvestment = _investments[_investmentId + 1];
            if (_nextInvestment.idChanged <= _value) {
                _lastAvailableProfitId = _nextInvestment.idChanged;
            }
        }
    }

    function _calculateProfitAtCycle(
        IPrecogV5.Cycle memory _profitCycle,
        IPrecogV5.Investment memory _investment,
        uint _totalInvestmentUnit, 
        uint _lastProfit, 
        uint16 _lastProfitIdOf
    ) 
        internal 
        pure
        returns (uint _profitAtCycle) 
    {
        if (_totalInvestmentUnit > 0) {
            if (_lastProfitIdOf == _investment.idChanged) {
                _profitAtCycle = (_lastProfit * _investment.unit) / _totalInvestmentUnit;
            } else {
                IPrecogV5.Cycle memory lastCycle = _profitCycle;
                _profitAtCycle = (_lastProfit * _investment.amount * (lastCycle.endTime - lastCycle.startTime)) / _totalInvestmentUnit;
            }
        }    
    }

    function _nextFundingTime(uint48 _newFirstFundingStartTime, uint48 _fundingDuration) internal view returns (uint48 _nextFundingTimestamp) {
        if(block.timestamp < _newFirstFundingStartTime) {
            _nextFundingTimestamp = _newFirstFundingStartTime;
        } else {
            _nextFundingTimestamp = ((uint48(block.timestamp) - _newFirstFundingStartTime) / _fundingDuration + 1) * _fundingDuration + _newFirstFundingStartTime;
        }
    }

    function _nextDefundingTime(
        uint48 _newFirstDefundingStartTime, 
        uint48 _defundingDuration, 
        uint48 _firstDefundingDuration) 
        internal 
        view 
        returns (uint48 _nextDefundingTimestamp) 
    {
        if(_firstDefundingDuration > 0) {
            if(block.timestamp < _newFirstDefundingStartTime) {
                return _newFirstDefundingStartTime + _firstDefundingDuration - _defundingDuration;
            } else {
                return ((uint48(block.timestamp) - _newFirstDefundingStartTime) / _defundingDuration) * _defundingDuration + _newFirstDefundingStartTime + _firstDefundingDuration;
            }
        } else {
            if(block.timestamp < _newFirstDefundingStartTime) {
                return _newFirstDefundingStartTime;
            } else {
                return ((uint48(block.timestamp) - _newFirstDefundingStartTime) / _defundingDuration + 1) * _defundingDuration + _newFirstDefundingStartTime;
            }
        }
        
    }

}

// File: contracts\precog\Precogv5.sol

pragma solidity ^0.8.2;
contract PrecogV5 is IPrecogV5 {
    using SafeERC20 for IERC20;

    // Modifiers

    modifier onlyAdmin() {
        require(msg.sender == core.getCoreConfiguration().admin, "0");
        _;
    }

    modifier onlyPrecogCore() {
        require(msg.sender == address(core), "1");
        _;
    }

    modifier onlyMiddleware() {
        require(msg.sender == core.getCoreConfiguration().middleware);
        _;
    }

    modifier _isExistingToken(address token) {
        require(isExistingToken[token], "2");
        _;
    }

    // Attributes

    IPrecogCore core;
    IIPCOGFactory factory;
    IMiddlewareExchange middlewareExchange;
    IWithdrawalRegister withdrawalRegister;

    function getConfig()
        external
        view
        override
        returns (
            address _core,
            address _factory,
            address _middlewareExchange,
            address _withdrawalRegister
        )
    {
        _core = address(core);
        _factory = address(factory);
        _middlewareExchange = address(middlewareExchange);
        _withdrawalRegister = address(withdrawalRegister);
    }

    address[] existingTokens;
    mapping(address => mapping(address => Investment[])) investmentsOf; ///// investmentOf[token][account] = Investment()
    mapping(address => mapping(address => AccountProfitInfo)) accountProfitInfo;
    mapping(address => Cycle[]) tradingCycles; //
    mapping(address => uint16) public override currentProfitId;
    mapping(address => bool) isExistingToken;
    mapping(address => address) public override tokenConvert;
    mapping(address => uint) public override liquidity;
    mapping(address => uint[]) profits;
    mapping(address => mapping(uint16 => uint)) totalUnitsTradingCycle;
    mapping(address => bool) isNotFirstInvestmentCycle;
    mapping(address => bool) isRemoved;
    mapping(address => mapping(address => AccountTradingInfo)) accountTradingInfo;
    mapping(address => mapping(uint => bool)) isUpdateUnitTradingCycle;

    constructor(
        IPrecogCore _core,
        IMiddlewareExchange _middlewareExchange,
        IIPCOGFactory _factory
    ) {
        core = _core;
        middlewareExchange = _middlewareExchange;
        factory = _factory;
    }

    // View functions

    function getInvestmentOfByIndex(
        address token,
        address account,
        uint index
    ) external view override returns (Investment memory investmentOf) {
        investmentOf = investmentsOf[token][account][index];
    }

    function getInfoTradingCycleById(address token, uint16 id)
        external
        view
        returns (
            uint48 startTime,
            uint48 endTime,
            uint unit,
            uint profitAmount
        )
    {
        Cycle memory tradingCycle = tradingCycles[token][id];
        startTime = tradingCycle.startTime;
        endTime = tradingCycle.endTime;
        unit = totalUnitsTradingCycle[token][id];
        if (id < profits[token].length) {
            profitAmount = profits[token][id];
        }
    }

    function getAccountProfitInfo(address token, address account)
        external
        view
        returns (AccountProfitInfo memory _accountProfitInfo)
    {
        _accountProfitInfo = accountProfitInfo[token][account];
    }

    function getAccountTradingInfo(address token, address account)
        external
        view
        returns (AccountTradingInfo memory _accountTradingInfo)
    {
        _accountTradingInfo = accountTradingInfo[token][account];
    }

    function getExistingTokensPair() external view override returns (TokenPair[] memory pairs) {
        pairs = new TokenPair[](existingTokens.length);
        for (uint index = 0; index < existingTokens.length; index++) {
            pairs[index] = TokenPair(existingTokens[index], tokenConvert[existingTokens[index]]);
        }
    }

    function getExistingTokenPairByIndex(uint index) external view override returns (TokenPair memory pair) {
        pair = TokenPair(existingTokens[index], tokenConvert[existingTokens[index]]);
    }

    function getLastInvestmentOf(address token, address account)
        public
        view
        override
        returns (Investment memory lastInvestmentOf)
    {
        uint lastInvestmentIndex = investmentsOf[token][account].length - 1;
        lastInvestmentOf = investmentsOf[token][account][lastInvestmentIndex];
    }

    function getCurrentTradingCycle(address token) external view override returns (Cycle memory) {
        return _getTradingCycleByTimestamp(token, block.timestamp);
    }

    function getTradingCycle(address token, uint48 timestamp) external view override returns (Cycle memory) {
        return _getTradingCycleByTimestamp(token, timestamp);
    }

    // Write functions

    function _updateCurrentTradingCycle(
        address _token,
        bool _isLimitedTradingCycles,
        uint _limitTradingCycles
    ) internal {
        core.updateFundingDuration(_token);
        core.updateDefundingDuration(_token);
        Cycle memory _lastTradingCycle = tradingCycles[_token][tradingCycles[_token].length - 1];
        uint48 _newCycleStartTime;
        uint48 _duration;
        uint48 _tradingCycle = core.getCycleConfiguration().tradingCycle;
        uint _timestampApplyNewTradingCycle = core.getCyclesChangedInfo(_token).tradingApplyTime;
        while (uint48(block.timestamp) >= _lastTradingCycle.endTime) {
            if (_isLimitedTradingCycles) {
                if (_limitTradingCycles > 0) {
                    _limitTradingCycles--;
                } else {
                    return;
                }
            }
            emit UpdateTradingCycle(
                _token,
                _lastTradingCycle.id,
                liquidity[_token],
                _lastTradingCycle.endTime - _lastTradingCycle.startTime
            );
            _newCycleStartTime = _lastTradingCycle.endTime;
            _duration = _newCycleStartTime < _timestampApplyNewTradingCycle
                ? _lastTradingCycle.endTime - _lastTradingCycle.startTime
                : _duration = _tradingCycle;

            _lastTradingCycle = Cycle(
                _lastTradingCycle.id + 1,
                _newCycleStartTime,
                _newCycleStartTime + _duration
            );
            tradingCycles[_token].push(_lastTradingCycle);

            if (isUpdateUnitTradingCycle[_token][_lastTradingCycle.id] == false) {
                totalUnitsTradingCycle[_token][_lastTradingCycle.id] += liquidity[_token] * _duration;
                isUpdateUnitTradingCycle[_token][_lastTradingCycle.id] = true;
            }
        }
    }

    function updateCurrentTradingCycle(address token, uint limitTradingCycles) external override {
        _updateCurrentTradingCycle(token, true, limitTradingCycles);
    }

    function calculateProfit(address token, address account)
        external
        view
        override
        _isExistingToken(token)
        returns (
            uint newProfitOf,
            uint16 newInvestmentIdOf,
            uint16 newProfitIdOf
        )
    {
        (newProfitOf, newInvestmentIdOf, newProfitIdOf) = _calculateProfit(token, account);
    }

    function _calculateProfit(address _token, address _account)
        internal
        view
        returns (
            uint _profitOf,
            uint16 _investmentId,
            uint16 _profitId
        )
    {
        Investment[] memory _investments = investmentsOf[_token][_account];
        Cycle[] memory _tradingCycles = tradingCycles[_token];
        uint[] memory _profits = profits[_token];
        uint16 _updatedLatestCycle = currentProfitId[_token];
        uint16 _lastAvailableProfitId;
        {
            AccountProfitInfo memory _accountProfitInfo = accountProfitInfo[_token][_account];
            _profitId = _accountProfitInfo.lastProfitIdOf;
            _investmentId = _accountProfitInfo.lastInvestmentIdOf;
            _profitOf = _accountProfitInfo.profitOf;
        }

        if (_profitId < _updatedLatestCycle) {
            for (_investmentId; _investmentId < _investments.length; _investmentId++) {
                Investment memory _nextInvestment = Investment(0, 0, 0, 0);
                if (
                    _profitId == _updatedLatestCycle &&
                    _updatedLatestCycle == _investments[_investmentId].idChanged
                ) return (_profitOf, _investmentId, _profitId);
                (_nextInvestment, _lastAvailableProfitId) = PrecogV5Library._chooseLastAvailableTradingId(
                    _investments,
                    _investmentId,
                    _updatedLatestCycle
                );
                for (_profitId; _profitId < _lastAvailableProfitId; _profitId++) {
                    _profitOf += PrecogV5Library._calculateProfitAtCycle(
                        _tradingCycles[_profitId],
                        _investments[_investmentId],
                        totalUnitsTradingCycle[_token][_profitId],
                        _profits[_profitId],
                        _profitId
                    );
                }
                if (_profitId == _updatedLatestCycle && _updatedLatestCycle != _nextInvestment.idChanged)
                    return (_profitOf, _investmentId, _profitId);
            }
        }
    }

    // Functions for admin

    function setConfig(address newMiddlewareExchange, address newWithdrawalRegister) external onlyAdmin {
        middlewareExchange = IMiddlewareExchange(newMiddlewareExchange);
        withdrawalRegister = IWithdrawalRegister(newWithdrawalRegister);
    }

    function addLiquidityPool(address token) external onlyAdmin {
        require(!isExistingToken[token]);
        require(tokenConvert[token] == address(0) && token != core.PCOG() && token != address(0));
        // Deploy new IPCOG
        tokenConvert[token] = factory.create(IERC20Metadata(token).decimals());
        tokenConvert[tokenConvert[token]] = token;
        isExistingToken[token] = true;
        existingTokens.push(token);
        IPrecogCore.CycleConfiguration memory cycleConfig = core.getCycleConfiguration();
        Cycle memory lastTradingCycle;
        uint48 currentTime = uint48(block.timestamp);

        if (!isNotFirstInvestmentCycle[token]) {
            tradingCycles[token].push(Cycle(0, currentTime, currentTime + cycleConfig.tradingCycle));
            lastTradingCycle = tradingCycles[token][0];

            profits[token].push(0);
            isNotFirstInvestmentCycle[token] = true;
            isUpdateUnitTradingCycle[token][0] = true;
        }

        if (isRemoved[token] == true) {
            lastTradingCycle = tradingCycles[token][tradingCycles[token].length - 1];
            if (block.timestamp >= lastTradingCycle.endTime) {
                Cycle memory newCycle = Cycle(
                    lastTradingCycle.id + 1,
                    currentTime,
                    currentTime + cycleConfig.tradingCycle
                );
                tradingCycles[token].push(newCycle);
                profits[token].push(0);
                isUpdateUnitTradingCycle[token][lastTradingCycle.id] = true;
            }
            isRemoved[token] = false;
        }

        core.setCyclesChangedInfo(
            token,
            IPrecogCore.CyclesChangedInfo(
                lastTradingCycle.endTime,
                uint48(block.timestamp),
                uint48(block.timestamp),
                cycleConfig.fundingCycle,
                cycleConfig.firstDefundingCycle,
                cycleConfig.defundingCycle
            )
        );
        emit AddLiquidity(token, tokenConvert[token]);
    }

    function removeLiquidityPool(address token) external onlyAdmin _isExistingToken(token) {
        _updateCurrentTradingCycle(token, false, 0);
        emit RemoveLiquidity(token, tokenConvert[token]);
        require(IERC20(tokenConvert[token]).totalSupply() == 0);
        address[] memory _existingTokens = existingTokens;
        for (uint i = 0; i < _existingTokens.length; i++) {
            if (_existingTokens[i] == token) {
                existingTokens[i] = _existingTokens[_existingTokens.length - 1];
                existingTokens.pop();
                break;
            }
        }
        tokenConvert[token] = address(0);
        isExistingToken[token] = false;
        isRemoved[token] = true;
        
    }

    // Functions for middleware

    function takeInvestment(address token) external override onlyMiddleware _isExistingToken(token) {
        uint actualBalance = IERC20(token).balanceOf(address(this));
        uint idealRemainBalance = liquidity[token] / 10;
        if (idealRemainBalance < actualBalance) {
            IERC20(token).safeTransfer(msg.sender, actualBalance - idealRemainBalance);
        } else if (idealRemainBalance > actualBalance) {
            IERC20(token).safeTransferFrom(msg.sender, address(this), idealRemainBalance - actualBalance);
        }
    }

    function _buyPCOG(
        address _token,
        uint _profitAmount,
        uint16 _currentProfitId
    ) internal returns (uint _amountBoughtPCOG) {
        if (_profitAmount > 0) {
            uint _feeTrading = (_profitAmount * core.getFeeConfiguration().tradingFee) /
                10**core.feeDecimalBase();
            IERC20(_token).safeTransfer(address(core), _feeTrading);
            if (IERC20(_token).allowance(address(this), address(middlewareExchange)) < _profitAmount) {
                IERC20(_token).safeApprove(address(middlewareExchange), 2**255);
            }
            _amountBoughtPCOG = middlewareExchange.buyPCOG(_token, _profitAmount - _feeTrading);
            profits[_token][_currentProfitId] = _amountBoughtPCOG;
        }
    }

    function sendProfit(address token, uint profitAmount)
        external
        override
        onlyMiddleware
        _isExistingToken(token)
    {
        if (totalUnitsTradingCycle[token][currentProfitId[token]] == 0) {
            profitAmount = 0;
        }
        _updateCurrentTradingCycle(token, false, 0);
        IERC20(token).safeTransferFrom(msg.sender, address(this), profitAmount);
        uint16 _currentProfitId = currentProfitId[token];
        uint lastIndexProfitCycle = tradingCycles[token].length - 1;
        require(_currentProfitId < tradingCycles[token][lastIndexProfitCycle].id, "3");
        uint amountBoughtPCOG = _buyPCOG(token, profitAmount, _currentProfitId);
        emit SendProfit(token, _currentProfitId, profitAmount, amountBoughtPCOG);
        currentProfitId[token]++;
        profits[token].push(0);
    }

    // Function for IPCOG

    function _getTradingCycleByTimestamp(address _token, uint _timestamp)
        internal
        view
        returns (Cycle memory _currentTradingCycle)
    {
        Cycle[] memory _tradingCycles = tradingCycles[_token];
        Cycle memory _lastTradingCycle = _tradingCycles[_tradingCycles.length - 1];
        uint48 _newCycleStartTime;
        uint48 _newCycleEndTime;
        uint48 _tradingCycle = core.getCycleConfiguration().tradingCycle;
        uint48 _duration;
        if (isRemoved[_token]) {
            return _lastTradingCycle;
        }
        uint _tradingApplyTime = core.getCyclesChangedInfo(_token).tradingApplyTime;
        while (uint48(_timestamp) >= _lastTradingCycle.endTime) {
            _newCycleStartTime = _lastTradingCycle.endTime;
            if (_lastTradingCycle.endTime < _tradingApplyTime) {
                _duration = _lastTradingCycle.endTime - _lastTradingCycle.startTime;
            } else {
                _duration = _tradingCycle;
            }
            _newCycleEndTime = _newCycleStartTime + _duration;
            _lastTradingCycle = (
                IPrecogV5.Cycle(_lastTradingCycle.id + 1, _newCycleStartTime, _newCycleEndTime)
            );
        }
        _currentTradingCycle = _lastTradingCycle;
    }

    function _increaseInvestment(
        address _token,
        address _account,
        uint _amount
    ) internal _isExistingToken(_token) {
        Investment[] memory _investmentsOf = investmentsOf[_token][_account];
        uint48 _nextFundingTime;
        Cycle memory _futureTradingCycle;
        {
            _nextFundingTime = PrecogV5Library._nextFundingTime(
                core.getCyclesChangedInfo(_token).fundingApplyTime,
                core.getCyclesChangedInfo(_token).fundingDuration
            );
            _futureTradingCycle = _getTradingCycleByTimestamp(_token, _nextFundingTime);
        }

        if (accountTradingInfo[_token][_account].isNotFirstIncreaseInvestment == false) {
            accountProfitInfo[_token][_account].lastProfitIdOf = uint16(_futureTradingCycle.id);
            accountTradingInfo[_token][_account].isNotFirstIncreaseInvestment = true;
        }

        if (isUpdateUnitTradingCycle[_token][_futureTradingCycle.id] == false) {
            totalUnitsTradingCycle[_token][_futureTradingCycle.id] += (liquidity[_token] *
                (_futureTradingCycle.endTime - _futureTradingCycle.startTime));
            isUpdateUnitTradingCycle[_token][_futureTradingCycle.id] = true;
        }

        uint _unit = _amount * (_futureTradingCycle.endTime - _nextFundingTime);

        if (_investmentsOf.length > 0) {
            Investment memory _lastInvestmentOf = _investmentsOf[_investmentsOf.length - 1];
            Investment memory _newInvestmentOf = Investment(
                _lastInvestmentOf.amount + _amount,
                0,
                _nextFundingTime,
                _futureTradingCycle.id
            );
            if (_lastInvestmentOf.idChanged < _futureTradingCycle.id) {
                _newInvestmentOf.unit =
                    _lastInvestmentOf.amount *
                    (_futureTradingCycle.endTime - _futureTradingCycle.startTime) +
                    _unit;
                investmentsOf[_token][_account].push(_newInvestmentOf);
            } else {
                _newInvestmentOf.unit = _lastInvestmentOf.unit + _unit;
                investmentsOf[_token][_account][_investmentsOf.length - 1] = _newInvestmentOf;
            }
        } else {
            Investment memory _newInvestmentOf = Investment(
                _amount,
                _unit,
                _nextFundingTime,
                _futureTradingCycle.id
            );
            investmentsOf[_token][_account].push(_newInvestmentOf);
        }

        totalUnitsTradingCycle[_token][_futureTradingCycle.id] += _unit;
    }

    function increaseInvestment(
        address token,
        address account,
        uint amount
    ) external override {
        require(msg.sender == tokenConvert[token]);
        _increaseInvestment(token, account, amount);
    }

    function _decreaseInvestment(
        address _token,
        address _account,
        uint _amount,
        bool isFirstRequestWithdrawal
    ) internal _isExistingToken(_token) returns (uint remainingAmount) {
        require(!isBeforeFundingTime(_token, _account), "9");
        Investment[] memory _investmentsOf = investmentsOf[_token][_account];
        uint48 _nextDefundingTime;
        Cycle memory _futureTradingCycle;
        {
            IPrecogCore.CyclesChangedInfo memory _cycleChangedInfo = core.getCyclesChangedInfo(_token);
            if (isFirstRequestWithdrawal == true) {
                if (withdrawalRegister.isInDeadline(_token, _account)) {
                    _nextDefundingTime = uint48(withdrawalRegister.getRegister(_token, _account).deadline);
                } else {
                    _nextDefundingTime = PrecogV5Library._nextDefundingTime(
                        _cycleChangedInfo.defundingApplyTime,
                        _cycleChangedInfo.defundingDuration,
                        _cycleChangedInfo.firstDefundingDuration
                    );
                }
            } else {
                _nextDefundingTime = PrecogV5Library._nextDefundingTime(
                    _cycleChangedInfo.defundingApplyTime,
                    _cycleChangedInfo.defundingDuration,
                    0
                );
            }
            _futureTradingCycle = _getTradingCycleByTimestamp(_token, _nextDefundingTime);
        }
        Investment memory _lastInvestmentOf = _investmentsOf[_investmentsOf.length - 1];
        Investment memory _newInvestmentOf = Investment(
            _lastInvestmentOf.amount - _amount,
            0,
            _lastInvestmentOf.timestamp,
            _futureTradingCycle.id
        );
        remainingAmount = _newInvestmentOf.amount;
        uint _unit = _amount * (_futureTradingCycle.endTime - _nextDefundingTime);
        if (isUpdateUnitTradingCycle[_token][_futureTradingCycle.id] == false) {
            uint _totalUnit = (liquidity[_token] *
                (_futureTradingCycle.endTime - _futureTradingCycle.startTime));
            totalUnitsTradingCycle[_token][_futureTradingCycle.id] += _totalUnit;
            isUpdateUnitTradingCycle[_token][_futureTradingCycle.id] = true;
        }
        if (_lastInvestmentOf.idChanged < _futureTradingCycle.id) {
            _newInvestmentOf.unit =
                _lastInvestmentOf.amount *
                (_futureTradingCycle.endTime - _futureTradingCycle.startTime) -
                _unit;
            investmentsOf[_token][_account].push(_newInvestmentOf);
        } else {
            _newInvestmentOf.unit = _lastInvestmentOf.unit - _unit;
            investmentsOf[_token][_account][_investmentsOf.length - 1] = _newInvestmentOf;
        }
        totalUnitsTradingCycle[_token][_futureTradingCycle.id] -= _unit;
    }

    function decreaseInvestment(
        address token,
        address account,
        uint amount
    ) external override {
        require(msg.sender == tokenConvert[token]);
        _decreaseInvestment(token, account, amount, false);
    }

    // Functions for user

    function _updateProfit(address _token, address _account) internal {
        (uint _newProfitOf, uint16 _newInvestmentIdOf, uint16 _newProfitIdOf) = _calculateProfit(
            _token,
            _account
        );
        uint _claimedProfitOf = accountProfitInfo[_token][_account].claimedProfitOf;
        accountProfitInfo[_token][_account] = AccountProfitInfo(
            _newProfitOf,
            _claimedProfitOf,
            _newProfitIdOf,
            _newInvestmentIdOf
        );
    }

    function _updateDepositInfo(
        address _token,
        address _account,
        uint _amount
    ) internal {
        AccountTradingInfo memory _accountTradingInfo = accountTradingInfo[_token][_account];
        if (block.timestamp >= _accountTradingInfo.depositedTimestampOf) {
            _accountTradingInfo.availableAmount = _amount;
            _accountTradingInfo.depositedTimestampOf = getLastInvestmentOf(_token, _account).timestamp;
        } else {
            _accountTradingInfo.availableAmount += _amount;
        }
        accountTradingInfo[_token][_account] = _accountTradingInfo;
    }

    function availableDepositedAmount(address token, address account)
        public
        view
        returns (uint amount, uint fundingStartTimeOf, uint lastFundingStartTime, uint nextFundingStartTime)
    {
        AccountTradingInfo memory _accountTradingInfo = accountTradingInfo[token][account];
        amount = _accountTradingInfo.depositedTimestampOf > block.timestamp
            ? _accountTradingInfo.availableAmount
            : 0;
        fundingStartTimeOf = _accountTradingInfo.depositedTimestampOf;
        (lastFundingStartTime, nextFundingStartTime) = core.getCurrentFundingCycle(token);
    }

    function deposit(address token, uint amount) external override {
        require(amount >= core.minFunding(token), "00");
        _updateCurrentTradingCycle(token, false, 0);
        // Calculate fees and actual deposit amount
        uint feeDeposit = (amount * core.getFeeConfiguration().depositFee) / 10**core.feeDecimalBase();
        uint actualDepositAmount = amount - feeDeposit;

        // Push investment of user and increase liquidity
        _increaseInvestment(token, msg.sender, actualDepositAmount);
        _updateProfit(token, msg.sender);
        liquidity[token] += actualDepositAmount;
        // Transfer tokens
        IERC20(token).safeTransferFrom(msg.sender, address(this), actualDepositAmount);
        IERC20(token).safeTransferFrom(msg.sender, address(core), feeDeposit);
        IIPCOG(tokenConvert[token]).mint(msg.sender, actualDepositAmount);
        _updateDepositInfo(token, msg.sender, actualDepositAmount);
        emit Deposit(token, msg.sender, amount, feeDeposit);
    }

    function _registerWithdrawal(
        address _token,
        address _account,
        uint _amount,
        bool _isFirstRequestWithdrawal
    ) internal {
        IPrecogCore.CyclesChangedInfo memory _cycleChangedInfo = core.getCyclesChangedInfo(_token);
        uint48 _duration = _isFirstRequestWithdrawal ? core.getCycleConfiguration().firstDefundingCycle : 0;
        uint48 _nextDefundingTime = PrecogV5Library._nextDefundingTime(
            _cycleChangedInfo.defundingApplyTime,
            _cycleChangedInfo.defundingDuration,
            _duration
        );
        uint48 _locktime = withdrawalRegister.isInDeadline(_token, _account)
            ? uint48(withdrawalRegister.getRegister(_token, _account).deadline)
            : _nextDefundingTime;

        withdrawalRegister.registerWithdrawal(_token, _account, _amount, _locktime);
    }

    function requestWithdrawal(address token, uint amount) external override {
        require(amount >= core.minDefunding(token), "6");
        _updateCurrentTradingCycle(token, false, 0);
        bool isFirstRequestWithdrawal = withdrawalRegister.isFirstWithdraw(token, msg.sender);
        uint remainingAmount = _decreaseInvestment(token, msg.sender, amount, isFirstRequestWithdrawal);
        require(remainingAmount == 0 || remainingAmount >= core.minFunding(token), "7");
        _registerWithdrawal(token, msg.sender, amount, isFirstRequestWithdrawal);
        _updateProfit(token, msg.sender);
        liquidity[token] -= amount;
        emit RequestWithdrawal(token, msg.sender, amount);
    }

    function takeProfit(address to, address token) external override _isExistingToken(token) {
        _updateCurrentTradingCycle(token, false, 0);
        _updateProfit(token, msg.sender);
        uint profitOfAccount = accountProfitInfo[token][msg.sender].profitOf;
        accountProfitInfo[token][to].claimedProfitOf += profitOfAccount;
        accountProfitInfo[token][msg.sender].profitOf = 0;
        IERC20(core.PCOG()).safeTransfer(to, profitOfAccount);
        emit TakeProfit(token, msg.sender, profitOfAccount);
    }

    function _decreaseInvestmentWhenWithdraw(
        address _token,
        address _account,
        uint _amount
    ) internal returns (uint _remainingAmount) {
        Investment[] memory _investmentsOf = investmentsOf[_token][_account];
        Investment memory _lastInvestmentOf = _investmentsOf[_investmentsOf.length - 1];
        Cycle memory _futureTradingCycle = _getTradingCycleByTimestamp(_token, _lastInvestmentOf.timestamp);
        _lastInvestmentOf.amount -= _amount;
        _remainingAmount = _lastInvestmentOf.amount;
        uint _unit = _amount * (_futureTradingCycle.endTime - _lastInvestmentOf.timestamp);
        _lastInvestmentOf.unit -= _unit;
        investmentsOf[_token][_account][_investmentsOf.length - 1] = _lastInvestmentOf;
        totalUnitsTradingCycle[_token][_futureTradingCycle.id] -= _unit;
        accountTradingInfo[_token][msg.sender].availableAmount -= _amount;
        liquidity[_token] -= _amount;
    }

    function _withdrawBeforeFundingTime(
        address _account,
        address _to,
        address _token,
        uint _amount,
        uint _fee
    ) internal {
        (uint availableWithdrawalAmount, , ,) = availableDepositedAmount(_token, _account);
        require(availableWithdrawalAmount >= _amount && IERC20(_token).balanceOf(address(this)) >= _amount, "8");
        uint remainingAmount = _decreaseInvestmentWhenWithdraw(_token, _account, _amount);
        require(
            remainingAmount == 0 ||
                (remainingAmount >= core.minFunding(_token) && _amount >= core.minDefunding(_token)), "7"
        );
        IERC20(_token).safeTransfer(_to, _amount - _fee);
        IERC20(_token).safeTransfer(address(core), _fee);
    }

    function isBeforeFundingTime(address token, address account)
        public
        view
        returns (bool isBeforeInvestmentCycle)
    {
        (uint availableWithdrawalAmount, , ,) = availableDepositedAmount(token, account);
        isBeforeInvestmentCycle = availableWithdrawalAmount > 0;
    }

    function withdraw(
        address to,
        address token,
        uint amount,
        bool isWithdrawBeforeFundingTime
    ) external override _isExistingToken(token) {
        uint withdrawalFee = (amount * core.getFeeConfiguration().withdrawalFee) / 10**core.feeDecimalBase();
        IIPCOG(tokenConvert[token]).burnFrom(msg.sender, amount);
        if (isWithdrawBeforeFundingTime) {
            _withdrawBeforeFundingTime(msg.sender, to, token, amount, withdrawalFee);
        } else {
            withdrawalRegister.claimWithdrawal(token, msg.sender, to, amount, withdrawalFee);
        }
        emit Withdraw(token, msg.sender, to, amount, withdrawalFee, isWithdrawBeforeFundingTime);
    }
}