/**
 *Submitted for verification at testnet.snowtrace.io on 2022-06-02
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

// File: contracts\withdrawal-register\interfaces\IWithdrawalRegister.sol


pragma solidity ^0.8.2;

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

    /**
     * @dev Emits when user claim the token amount
     * @param token is token address
     * @param account is account address
     * @param amount is token amount
     */
    event ClaimWithdrawal(
        address token,
        address account,
        uint256 amount
    );

    /**
     * @dev Returns the precog address
     */
    function precog() external view returns (address);

    /**
     * @dev Returns the precog core address
     */
    function precogCore() external view returns (address);

    /**
     * @notice Returns the register of user that includes amount and deadline
     * @param token is token address
     * @param account is user address
     * @return register is the set of amount and deadline for token address and account address
     */
    function getRegister(address token, address account) external view returns (Register memory register);

    /**
     * @notice Check if user has a first request withdrawal
     * @param token is token address
     * @param account is user address
     * @return _isFirstWithdrawal is the value if user has a first request withdrawal or not
     */
    function isFirstWithdraw(address token, address account) external view returns (bool _isFirstWithdrawal);

    /**
     * @notice Check if register of user is in deadline
     * @param token is token address
     * @param account is user address
     * @return _isInDeadline - the value of register if it is in deadline or not
     */
    function isInDeadline(address token, address account) external view returns (bool _isInDeadline);

    /**
     * @notice Register the token amount and deadline for user
     * @dev Requirements:
     * - Must be called by only precog contract
     * - Deadline of register must be less than or equal to param `deadline`
     * - If deadline of register is completed, user must claim withdrawal before calling this function
     * @param token is token address that user wants to request withdrawal
     * @param account is user address
     * @param amount is token amount that user wants to request withdrawal  
     * @param deadline is deadline that precog calculates and is used for locking token amount of user 
     */
    function registerWithdrawal(address token, address account, uint256 amount, uint256 deadline) external;

    /**
     * @notice Withdraw token amount that user registered and out of deadline
     * @dev Requirements:
     * - Must be called only by precog contract
     * - Deadline of register must be less than or equal to now
     * - Amount of register must be greater than or equal to param `amount`
     * - This contract has enough token amount for user
     * @param token is token address that user want to claim the requested withdrawal
     * @param account is user address
     * @param to is account address that user want to transfer when claiming requested withdrawal
     * @param amount is amount token that user want to claim
     * @param fee is fee token that precog core charges when user claim token
     */
    function claimWithdrawal(address token, address account, address to, uint256 amount, uint256 fee) external;

    /**
     * @notice Modify register info
     * @dev Requirements:
     
     */
    function modifyRegister(address token, address account, Register memory newRegister) external;
}

// File: contracts\withdrawal-register\WithdrawalRegister.sol


pragma solidity ^0.8.2;
/**
 * @title WithdrawalRegister contract
 * @dev Implementation contract that be used to withdraw the requested withdrawal tokens
 */
contract WithdrawalRegister is IWithdrawalRegister {
    using SafeERC20 for IERC20;

    modifier onlyPrecog() {
        require(msg.sender == precog, "WithdrawalRegister: Caller is not precog");
        _;
    }

    // Address of precog contract
    address public override precog;

    // Address of precog core contract 
    address public override precogCore;

    // Mapping from token address to register of account
    mapping(address => mapping(address => Register)) register;

    // Mapping from token address to check if the first request withdrawal of account
    mapping(address => mapping(address => bool)) isNotFirstWithdrawal;

    /**
     * @dev Constructor to set up contract
     * @param _precog is used to set up precog address when deploy contract
     * @param _precogCore is used to set precog core address when deploy contract
     */
    constructor(address _precog, address _precogCore) {
        precog = _precog;
        precogCore = _precogCore;
    }

    /**
     * @dev See {IWithdrawalRegister - getRegister}
     */
    function getRegister(address token, address account) external view override returns (Register memory _register) {
        _register = register[token][account];
    }

    /**
     * @dev See {IWithdrawalRegister - isFirstWithdraw}
     */
    function isFirstWithdraw(address token, address account) external view override returns (bool _isFirstWithdrawal) {
        _isFirstWithdrawal = !isNotFirstWithdrawal[token][account];
    }

    /**
     * @dev See {IWithdrawalRegister - isInDeadline}
     */
    function isInDeadline(address token, address account) public override view returns (bool) {
        Register memory lastRegister = register[token][account];
        return lastRegister.deadline >= block.timestamp;
    }

    /**
     * @dev See {IWithdrawalRegister - registerWithdrawal}
     */
    function registerWithdrawal(address token, address account, uint256 amount, uint256 deadline) onlyPrecog external override {
        Register memory lastRegister = register[token][account];
        require(deadline >= lastRegister.deadline, "WithdrawalRegister: DEADLINE_IS_INVALID");
        require(isInDeadline(token, account) || lastRegister.amount == 0, "WithdrawalRegister: MUST_CLAIM_TOKEN_BEFORE_REGISTER_AGAIN");
        register[token][account] = Register(lastRegister.amount + amount, deadline);   
    }

    /**
     * @dev See {IWithdrawalRegister - claimWithdrawal}
     */
    function claimWithdrawal(address token, address account, address to, uint256 amount, uint256 fee) onlyPrecog external override { 
        Register memory lastRegister = register[token][account];
        require(lastRegister.deadline < block.timestamp, "WithdrawalRegister: NOT_OUT_OF_DEADLINE");
        require(lastRegister.amount >= amount, "WithdrawalRegister: INVALID_AMOUNT");
        require(IERC20(token).balanceOf(address(this)) >= amount, "WithdrawalRegister: MIDDLEWARE_HAS_NOT_SENT_TOKEN_YET");
        IERC20(token).safeTransfer(to, amount - fee);
        IERC20(token).safeTransfer(precogCore, fee);
        register[token][account].amount -= amount;
        if(isNotFirstWithdrawal[token][account] == false) {
            isNotFirstWithdrawal[token][account] = true;
        }
    }

    function modifyRegister(address token, address account, Register memory newRegister) onlyPrecog external override {
        register[token][account] = newRegister;
    } 
}