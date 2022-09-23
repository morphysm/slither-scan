/**
 *Submitted for verification at testnet.snowtrace.io on 2022-06-16
*/

// wowoie
pragma solidity 0.8.13;
interface IJoeRouter01 {
    function factory() external pure returns (address);

    function WAVAX() external pure returns (address);

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

    function addLiquidityAVAX(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountAVAX,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityAVAX(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountAVAX);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityAVAXWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountAVAX);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactAVAXForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactAVAX(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForAVAX(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapAVAXForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path) external view returns (uint256[] memory amounts);
}
interface IJoeRouter02 is IJoeRouter01 {
    function removeLiquidityAVAXSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountAVAX);

    function removeLiquidityAVAXWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountAVAX);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactAVAXForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForAVAXSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}
interface IJoeFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint256);

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function migrator() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;

    function setMigrator(address) external;
}
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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}
contract PaymentSplitter is Context {
    event PayeeAdded(address account, uint256 shares);
    event PaymentReleased(address to, uint256 amount);
    event ERC20PaymentReleased(IERC20 indexed token, address to, uint256 amount);
    event PaymentReceived(address from, uint256 amount);

    uint256 private _totalShares;
    uint256 private _totalReleased;

    mapping(address => uint256) private _shares;
    mapping(address => uint256) private _released;
    address[] private _payees;

    mapping(IERC20 => uint256) private _erc20TotalReleased;
    mapping(IERC20 => mapping(address => uint256)) private _erc20Released;

    /**
     * @dev Creates an instance of `PaymentSplitter` where each account in `payees` is assigned the number of shares at
     * the matching position in the `shares` array.
     *
     * All addresses in `payees` must be non-zero. Both arrays must have the same non-zero length, and there must be no
     * duplicates in `payees`.
     */
    constructor(address[] memory payees, uint256[] memory shares_) payable {
        require(payees.length == shares_.length, "PaymentSplitter: payees and shares length mismatch");
        require(payees.length > 0, "PaymentSplitter: no payees");

        for (uint256 i = 0; i < payees.length; i++) {
            _addPayee(payees[i], shares_[i]);
        }
    }

    /**
     * @dev The Ether received will be logged with {PaymentReceived} events. Note that these events are not fully
     * reliable: it's possible for a contract to receive Ether without triggering this function. This only affects the
     * reliability of the events, and not the actual splitting of Ether.
     *
     * To learn more about this see the Solidity documentation for
     * https://solidity.readthedocs.io/en/latest/contracts.html#fallback-function[fallback
     * functions].
     */
    receive() external payable virtual {
        emit PaymentReceived(_msgSender(), msg.value);
    }

    /**
     * @dev Getter for the total shares held by payees.
     */
    function totalShares() public view returns (uint256) {
        return _totalShares;
    }

    /**
     * @dev Getter for the total amount of Ether already released.
     */
    function totalReleased() public view returns (uint256) {
        return _totalReleased;
    }

    /**
     * @dev Getter for the total amount of `token` already released. `token` should be the address of an IERC20
     * contract.
     */
    function totalReleased(IERC20 token) public view returns (uint256) {
        return _erc20TotalReleased[token];
    }

    /**
     * @dev Getter for the amount of shares held by an account.
     */
    function shares(address account) public view returns (uint256) {
        return _shares[account];
    }

    /**
     * @dev Getter for the amount of Ether already released to a payee.
     */
    function released(address account) public view returns (uint256) {
        return _released[account];
    }

    /**
     * @dev Getter for the amount of `token` tokens already released to a payee. `token` should be the address of an
     * IERC20 contract.
     */
    function released(IERC20 token, address account) public view returns (uint256) {
        return _erc20Released[token][account];
    }

    /**
     * @dev Getter for the address of the payee number `index`.
     */
    function payee(uint256 index) public view returns (address) {
        return _payees[index];
    }

    /**
     * @dev Triggers a transfer to `account` of the amount of Ether they are owed, according to their percentage of the
     * total shares and their previous withdrawals.
     */
    function release(address payable account) public virtual {
        require(_shares[account] > 0, "PaymentSplitter: account has no shares");

        uint256 totalReceived = address(this).balance + totalReleased();
        uint256 payment = _pendingPayment(account, totalReceived, released(account));

        require(payment != 0, "PaymentSplitter: account is not due payment");

        _released[account] += payment;
        _totalReleased += payment;

        Address.sendValue(account, payment);
        emit PaymentReleased(account, payment);
    }

    /**
     * @dev Triggers a transfer to `account` of the amount of `token` tokens they are owed, according to their
     * percentage of the total shares and their previous withdrawals. `token` must be the address of an IERC20
     * contract.
     */
    function release(IERC20 token, address account) public virtual {
        require(_shares[account] > 0, "PaymentSplitter: account has no shares");

        uint256 totalReceived = token.balanceOf(address(this)) + totalReleased(token);
        uint256 payment = _pendingPayment(account, totalReceived, released(token, account));

        require(payment != 0, "PaymentSplitter: account is not due payment");

        _erc20Released[token][account] += payment;
        _erc20TotalReleased[token] += payment;

        SafeERC20.safeTransfer(token, account, payment);
        emit ERC20PaymentReleased(token, account, payment);
    }

    /**
     * @dev internal logic for computing the pending payment of an `account` given the token historical balances and
     * already released amounts.
     */
    function _pendingPayment(
        address account,
        uint256 totalReceived,
        uint256 alreadyReleased
    ) private view returns (uint256) {
        return (totalReceived * _shares[account]) / _totalShares - alreadyReleased;
    }

    /**
     * @dev Add a new payee to the contract.
     * @param account The address of the payee to add.
     * @param shares_ The number of shares owned by the payee.
     */
    function _addPayee(address account, uint256 shares_) private {
        require(account != address(0), "PaymentSplitter: account is the zero address");
        require(shares_ > 0, "PaymentSplitter: shares are 0");
        require(_shares[account] == 0, "PaymentSplitter: account already has shares");

        _payees.push(account);
        _shares[account] = shares_;
        _totalShares = _totalShares + shares_;
        emit PayeeAdded(account, shares_);
    }
}library SafeMath {
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
interface INodeManager {
  struct NodeEntity {
    string name;
    uint256 creationTime;
    uint256 lastClaimTime;
    uint256 amount;
  }

  function getMinPrice() external view returns (uint256);

  function createNode(
    address account,
    string memory nodeName,
    uint256 amount
  ) external;

  function getNodeReward(address account, uint256 _creationTime)
    external
    view
    returns (uint256);

  function getAllNodesRewards(address account) external view returns (uint256);

  function cashoutNodeReward(address account, uint256 _creationTime) external;

  function cashoutAllNodesRewards(address account) external;

  function compoundNodeReward(
    address account,
    uint256 creationTime,
    uint256 rewardAmount
  ) external;

  function getAllNodes(address account)
    external
    view
    returns (NodeEntity[] memory);
}
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
interface INodeManager02 {
  struct NodeEntity {
    string name;
    uint256 creationTime;
    uint256 lastClaimTime;
    uint256 lastCompoundTime;
    uint256 amount;
    bool deleted;
  }

  function getMinPrice() external view returns (uint256);

  function createNode(
    address account,
    string memory nodeName,
    uint256 amount
  ) external;

  function getNodeReward(address account, uint256 _creationTime)
    external
    view
    returns (uint256);

  function getAllNodesRewards(address account) external view returns (uint256);

  function cashoutNodeReward(address account, uint256 _creationTime) external;

  function cashoutAllNodesRewards(address account) external;

  function compoundNodeReward(
    address account,
    uint256 creationTime,
    uint256 rewardAmount
  ) external;

  function compoundAllNodesRewards(address account) external;

  function getAllNodes(address account)
    external
    view
    returns (NodeEntity[] memory);

  function renameNode(
    address account,
    string memory _newName,
    uint256 _creationTime
  ) external;

  function mergeNodes(
    address account,
    uint256 _creationTime1,
    uint256 _creationTime2
  ) external;

  function increaseNodeAmount(
    address account,
    uint256 _creationTime,
    uint256 _amount
  ) external;

  function migrateNodes(address account) external;
}
contract NodeManager02 is Ownable, Pausable, ReentrancyGuard {
  using SafeMath for uint256;

  struct NodeEntity {
    string name;
    uint256 creationTime;
    uint256 lastClaimTime;
    uint256 lastCompoundTime;
    uint256 amount;
    bool deleted;
  }

  address public token;
  uint256 public rewardPerNode;
  uint256 public minPrice;

  uint256 public totalNodesCreated = 0;
  uint256 public totalStaked = 0;

  uint256[] private _boostMultipliers = [105, 120, 140];
  uint256[] private _boostRequiredDays = [3, 7, 15];
  INodeManager private nodeManager01;

  mapping(address => bool) public isAuthorizedAddress;
  mapping(address => NodeEntity[]) private _nodesOfUser;
  mapping(address => bool) private migratedWallets;

  event NodeIncreased(address indexed account, uint256 indexed amount);
  event NodeRenamed(address indexed account, string newName);
  event NodeCreated(
    address indexed account,
    uint256 indexed amount,
    uint256 indexed blockTime
  );
  event NodeMerged(
    address indexed account,
    uint256 indexed sourceBlockTime,
    uint256 indexed destBlockTime
  );

  modifier onlyAuthorized() {
    require(isAuthorizedAddress[_msgSender()], "UNAUTHORIZED");
    _;
  }

  constructor(
    uint256 _rewardPerNode,
    uint256 _minPrice,
    address _nodeManager01
  ) {
    rewardPerNode = _rewardPerNode;
    minPrice = _minPrice;

    isAuthorizedAddress[_msgSender()] = true;

    nodeManager01 = INodeManager(_nodeManager01);
  }

  // Private methods

  function _isNameAvailable(address account, string memory nodeName)
    private
    view
    returns (bool)
  {
    NodeEntity[] memory nodes = _nodesOfUser[account];
    for (uint256 i = 0; i < nodes.length; i++) {
      if (keccak256(bytes(nodes[i].name)) == keccak256(bytes(nodeName))) {
        return false;
      }
    }
    return true;
  }

  function _getNodeWithCreatime(
    NodeEntity[] storage nodes,
    uint256 _creationTime
  ) private view returns (NodeEntity storage) {
    uint256 numberOfNodes = nodes.length;
    require(
      numberOfNodes > 0,
      "CASHOUT ERROR: You don't have nodes to cash-out"
    );
    bool found = false;
    int256 index = _binarySearch(nodes, 0, numberOfNodes, _creationTime);
    uint256 validIndex;
    if (index >= 0) {
      found = true;
      validIndex = uint256(index);
    }
    require(found, "NODE SEARCH: No NODE Found with this blocktime");
    return nodes[validIndex];
  }

  function _binarySearch(
    NodeEntity[] memory arr,
    uint256 low,
    uint256 high,
    uint256 x
  ) private view returns (int256) {
    if (high >= low) {
      uint256 mid = (high + low).div(2);
      if (arr[mid].creationTime == x) {
        return int256(mid);
      } else if (arr[mid].creationTime > x) {
        return _binarySearch(arr, low, mid - 1, x);
      } else {
        return _binarySearch(arr, mid + 1, high, x);
      }
    } else {
      return -1;
    }
  }

  function _uint2str(uint256 _i)
    private
    pure
    returns (string memory _uintAsString)
  {
    if (_i == 0) {
      return "0";
    }
    uint256 j = _i;
    uint256 len;
    while (j != 0) {
      len++;
      j /= 10;
    }
    bytes memory bstr = new bytes(len);
    uint256 k = len;
    while (_i != 0) {
      k = k - 1;
      uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
      bytes1 b1 = bytes1(temp);
      bstr[k] = b1;
      _i /= 10;
    }
    return string(bstr);
  }

  function _calculateNodeRewards(
    uint256 _lastClaimTime,
    uint256 _lastCompoundTime,
    uint256 amount_
  ) public view returns (uint256) {
    uint256 elapsedTime_ = (block.timestamp - _lastCompoundTime);
    uint256 _boostMultiplier = _calculateBoost(_lastClaimTime);
    uint256 rewardPerDay = amount_.mul(rewardPerNode).div(100);
    uint256 elapsedMinutes = elapsedTime_ / 1 minutes;
    uint256 rewardPerMinute = rewardPerDay.mul(10000).div(1440);

    return
      rewardPerMinute.mul(elapsedMinutes).div(10000).mul(_boostMultiplier).div(
        100
      );
  }

  function _calculateBoost(uint256 _lastClaimTime)
    public
    view
    returns (uint256)
  {
    uint256 elapsedTime_ = (block.timestamp - _lastClaimTime);
    uint256 elapsedTimeInDays_ = elapsedTime_ / 1 days;

    if (elapsedTimeInDays_ >= _boostRequiredDays[2]) {
      return _boostMultipliers[2];
    } else if (elapsedTimeInDays_ >= _boostRequiredDays[1]) {
      return _boostMultipliers[1];
    } else if (elapsedTimeInDays_ >= _boostRequiredDays[0]) {
      return _boostMultipliers[0];
    } else {
      return 100;
    }
  }

  // External methods

  function createNode(
    address account,
    string memory nodeName,
    uint256 amount_
  ) external onlyAuthorized whenNotPaused {
    require(_isNameAvailable(account, nodeName), "Name not available");
    NodeEntity[] storage _nodes = _nodesOfUser[account];
    require(_nodes.length <= 100, "Max nodes exceeded");
    _nodes.push(
      NodeEntity({
        name: nodeName,
        creationTime: block.timestamp,
        lastClaimTime: block.timestamp,
        lastCompoundTime: block.timestamp,
        amount: amount_,
        deleted: false
      })
    );

    totalNodesCreated++;
    totalStaked += amount_;

    emit NodeCreated(account, amount_, block.timestamp);
  }

  function cashoutNodeReward(address account, uint256 _creationTime)
    external
    onlyAuthorized
    whenNotPaused
  {
    require(_creationTime > 0, "NODE: CREATIME must be higher than zero");
    NodeEntity[] storage nodes = _nodesOfUser[account];
    require(
      nodes.length > 0,
      "CASHOUT ERROR: You don't have nodes to cash-out"
    );
    NodeEntity storage node = _getNodeWithCreatime(nodes, _creationTime);
    require(!node.deleted, "DELETED");
    node.lastClaimTime = block.timestamp;
    node.lastCompoundTime = block.timestamp;
  }

  function compoundNodeReward(
    address account,
    uint256 _creationTime,
    uint256 rewardAmount_
  ) external onlyAuthorized whenNotPaused {
    require(_creationTime > 0, "NODE: CREATIME must be higher than zero");
    NodeEntity[] storage nodes = _nodesOfUser[account];
    require(
      nodes.length > 0,
      "CASHOUT ERROR: You don't have nodes to cash-out"
    );
    NodeEntity storage node = _getNodeWithCreatime(nodes, _creationTime);
    require(!node.deleted, "DELETED");
    node.amount += rewardAmount_;
    node.lastCompoundTime = block.timestamp;
  }

  function cashoutAllNodesRewards(address account)
    external
    onlyAuthorized
    whenNotPaused
  {
    NodeEntity[] storage nodes = _nodesOfUser[account];
    uint256 nodesCount = nodes.length;
    require(nodesCount > 0, "NODE: CREATIME must be higher than zero");
    NodeEntity storage _node;
    for (uint256 i = 0; i < nodesCount; i++) {
      _node = nodes[i];
      if (!_node.deleted) {
        _node.lastClaimTime = block.timestamp;
        _node.lastCompoundTime = block.timestamp;
      }
    }
  }

  function compoundAllNodesRewards(address account)
    external
    onlyAuthorized
    whenNotPaused
  {
    NodeEntity[] storage nodes = _nodesOfUser[account];
    uint256 nodesCount = nodes.length;
    require(nodesCount > 0, "NODE: CREATIME must be higher than zero");
    NodeEntity storage _node;
    for (uint256 i = 0; i < nodesCount; i++) {
      _node = nodes[i];
      if (!_node.deleted) {
        uint256 rewardAmount = getNodeReward(account, _node.creationTime);
        _node.amount += rewardAmount;
        _node.lastCompoundTime = block.timestamp;
      }
    }
  }

  function renameNode(
    address account,
    string memory _newName,
    uint256 _creationTime
  ) external onlyAuthorized whenNotPaused {
    require(_isNameAvailable(account, _newName), "Name not available");
    require(_creationTime > 0, "NODE: CREATIME must be higher than zero");
    NodeEntity[] storage nodes = _nodesOfUser[account];
    require(
      nodes.length > 0,
      "CASHOUT ERROR: You don't have nodes to cash-out"
    );
    NodeEntity storage node = _getNodeWithCreatime(nodes, _creationTime);
    require(!node.deleted, "DELETED");
    node.name = _newName;
  }

  function mergeNodes(
    address account,
    uint256 _creationTime1,
    uint256 _creationTime2
  ) external onlyAuthorized whenNotPaused {
    require(_creationTime1 > 0 && _creationTime2 > 0, "MERGE:1");
    NodeEntity[] storage nodes = _nodesOfUser[account];
    require(
      nodes.length > 0,
      "CASHOUT ERROR: You don't have nodes to cash-out"
    );
    NodeEntity storage node1 = _getNodeWithCreatime(nodes, _creationTime1);
    NodeEntity storage node2 = _getNodeWithCreatime(nodes, _creationTime2);

    node1.amount += node2.amount;
    node1.lastClaimTime = block.timestamp;
    node1.lastCompoundTime = block.timestamp;

    node2.deleted = true;
    totalNodesCreated--;

    emit NodeMerged(account, _creationTime2, _creationTime1);
  }

  function increaseNodeAmount(
    address account,
    uint256 _creationTime,
    uint256 _amount
  ) external onlyAuthorized whenNotPaused {
    require(_creationTime > 0, "NODE: CREATIME must be higher than zero");
    NodeEntity[] storage nodes = _nodesOfUser[account];
    require(
      nodes.length > 0,
      "CASHOUT ERROR: You don't have nodes to cash-out"
    );
    NodeEntity storage node = _getNodeWithCreatime(nodes, _creationTime);
    require(!node.deleted, "DELETED");
    node.amount += _amount;
    node.lastCompoundTime = block.timestamp;
  }

  function migrateNodes(address account) external whenNotPaused nonReentrant {
    require(!migratedWallets[account], "Already migrated");
    INodeManager.NodeEntity[] memory oldNodes = nodeManager01.getAllNodes(
      account
    );
    require(oldNodes.length > 0, "LENGTH");
    NodeEntity[] storage _nodes = _nodesOfUser[account];
    require(_nodes.length + oldNodes.length <= 100, "Max nodes exceeded");

    for (uint256 index = 0; index < oldNodes.length; index++) {
      _nodes.push(
        NodeEntity({
          name: oldNodes[index].name,
          creationTime: oldNodes[index].creationTime,
          lastClaimTime: oldNodes[index].lastClaimTime,
          lastCompoundTime: oldNodes[index].lastClaimTime,
          amount: oldNodes[index].amount,
          deleted: false
        })
      );

      totalNodesCreated++;
      totalStaked += oldNodes[index].amount;
      migratedWallets[account] = true;

      emit NodeCreated(account, oldNodes[index].amount, block.timestamp);
    }
  }

  // Setters & Getters

  function setToken(address newToken) external onlyOwner {
    token = newToken;
  }

  function setRewardPerNode(uint256 newVal) external onlyOwner {
    rewardPerNode = newVal;
  }

  function setMinPrice(uint256 newVal) external onlyOwner {
    minPrice = newVal;
  }

  function setBoostMultipliers(uint8[] calldata newVal) external onlyOwner {
    require(newVal.length == 3, "Wrong length");
    _boostMultipliers = newVal;
  }

  function setBoostRequiredDays(uint8[] calldata newVal) external onlyOwner {
    require(newVal.length == 3, "Wrong length");
    _boostRequiredDays = newVal;
  }

  function setAuthorized(address account, bool newVal) external onlyOwner {
    isAuthorizedAddress[account] = newVal;
  }

  function getMinPrice() external view returns (uint256) {
    return minPrice;
  }

  function getNodeNumberOf(address account) external view returns (uint256) {
    return _nodesOfUser[account].length;
  }

  function getAllNodes(address account)
    external
    view
    returns (NodeEntity[] memory)
  {
    return _nodesOfUser[account];
  }

  function getAllNodesAmount(address account) external view returns (uint256) {
    NodeEntity[] memory nodes = _nodesOfUser[account];
    uint256 nodesCount = nodes.length;
    require(nodesCount > 0, "NO_NODES");
    uint256 totalAmount_ = 0;
    for (uint256 i = 0; i < nodesCount; i++) {
      if (!nodes[i].deleted) {
        totalAmount_ += nodes[i].amount;
      }
    }

    return totalAmount_;
  }

  function getNodeReward(address account, uint256 _creationTime)
    public
    view
    returns (uint256)
  {
    require(_creationTime > 0, "E:1");
    NodeEntity[] storage nodes = _nodesOfUser[account];
    require(nodes.length > 0, "E:2");
    NodeEntity storage node = _getNodeWithCreatime(nodes, _creationTime);
    require(!node.deleted, "DELETED");
    return
      _calculateNodeRewards(
        node.lastClaimTime,
        node.lastCompoundTime,
        node.amount
      );
  }

  function getAllNodesRewards(address account) external view returns (uint256) {
    NodeEntity[] storage nodes = _nodesOfUser[account];
    uint256 nodesCount = nodes.length;
    require(nodesCount > 0, "E:1");
    NodeEntity storage _node;
    uint256 rewardsTotal = 0;
    for (uint256 i = 0; i < nodesCount; i++) {
      _node = nodes[i];
      if (!_node.deleted) {
        rewardsTotal += _calculateNodeRewards(
          _node.lastClaimTime,
          _node.lastCompoundTime,
          _node.amount
        );
      }
    }
    return rewardsTotal;
  }

  // Firewall methods

  function pause() external onlyAuthorized {
    _pause();
  }

  function unpause() external onlyAuthorized {
    _unpause();
  }
}

contract OmniBeer is Ownable, PaymentSplitter {
  using SafeMath for uint256;

  address public tokenAddress;
  address public joePair;
  address public joeRouterAddress = 0x2D99ABD9008Dc933ff5c0CD271B88309593aB921; // TraderJoe Router
  address public teamPool;
  address public rewardsPool;
  address public deadWallet = 0x000000000000000000000000000000000000dEaD;

  uint256 public swapTokensAmount;
  uint256 public totalClaimed = 0;
  bool public swapLiquifyEnabled = true;

  IJoeRouter02 private joeRouter;
  INodeManager02 private nodeManager;
  IERC20 private token;

  uint256 private rwSwap;
  bool private swapping = false;

  mapping(address => bool) public isBlacklisted;
  mapping(address => bool) public automatedMarketMakerPairs;
  mapping(bytes32 => uint256) private fees;

  event UpdateJoeRouter(address indexed newAddress, address indexed oldAddress);
  event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
  event LiquidityWalletUpdated(
    address indexed newLiquidityWallet,
    address indexed oldLiquidityWallet
  );
  event SwapAndLiquify(
    uint256 tokensSwapped,
    uint256 ethReceived,
    uint256 tokensIntoLiqudity
  );
  event Cashout(
    address indexed account,
    uint256 amount,
    uint256 indexed blockTime
  );
  event Compound(
    address indexed account,
    uint256 amount,
    uint256 indexed blockTime
  );

  constructor(
    address[] memory payees,
    uint256[] memory shares,
    address[] memory addresses,
    uint256[] memory _fees,
    uint256 swapAmount
  ) PaymentSplitter(payees, shares) {
    require(
      addresses[0] != address(0) &&
        addresses[1] != address(0) &&
        addresses[2] != address(0) &&
        addresses[3] != address(0) &&
        addresses[4] != address(0),
      "CONSTR:1"
    );
    teamPool = addresses[0];
    rewardsPool = addresses[1];
    nodeManager = INodeManager02(addresses[2]);
    token = IERC20(addresses[3]);
    joePair = addresses[4];

    tokenAddress = addresses[3];

    require(
      joeRouterAddress != address(0) && tokenAddress != address(0),
      "CONSTR:2"
    );
    joeRouter = IJoeRouter02(joeRouterAddress);

    _setAutomatedMarketMakerPair(joePair, true);

    require(
      _fees[0] != 0 &&
        _fees[1] != 0 &&
        _fees[2] != 0 &&
        _fees[3] != 0 &&
        _fees[4] != 0,
      "CONSTR:3"
    );

    _setFee("teamPool", _fees[0]);
    _setFee("rewards", _fees[1]);
    _setFee("liquidityPool", _fees[2]);
    _setFee("cashout", _fees[3]);
    _setFee("rwSwap", _fees[4]);
    _setFee("compound", _fees[5]);
    _setFee("burn", _fees[6]);
    _setFee("merge", _fees[7]);

    uint256 totalFees = _getFee("rewards").add(_getFee("liquidityPool")).add(
      _getFee("teamPool")
    );
    _setFee("total", totalFees);
    require(totalFees == 100, "CONSTR:7");
    require(swapAmount > 0, "CONSTR:8");
    swapTokensAmount = swapAmount * (10**18);
  }

  function _getFee(string memory _key) private view returns (uint256) {
    return fees[keccak256(abi.encodePacked(_key))];
  }

  function _setFee(string memory _key, uint256 _value) private onlyOwner {
    fees[keccak256(abi.encodePacked(_key))] = _value;
  }

  function getFee(string memory _key) external view returns (uint256) {
    return fees[keccak256(abi.encodePacked(_key))];
  }

  function updateJoeRouterAddress(address newAddress) external onlyOwner {
    require(newAddress != address(joeRouter), "TKN:1");
    emit UpdateJoeRouter(newAddress, address(joeRouter));
    IJoeRouter02 _joeRouter = IJoeRouter02(newAddress);
    address _joePair = IJoeFactory(joeRouter.factory()).createPair(
      tokenAddress,
      _joeRouter.WAVAX()
    );
    joePair = _joePair;
    joeRouterAddress = newAddress;
  }

  function updateSwapTokensAmount(uint256 newVal) external onlyOwner {
    swapTokensAmount = newVal;
  }

  function updateTeamPool(address payable newVal) external onlyOwner {
    teamPool = newVal;
  }

  function updateRewardsPool(address payable newVal) external onlyOwner {
    rewardsPool = newVal;
  }

  function updateRwSwapFee(uint256 newVal) external onlyOwner {
    rwSwap = newVal;
  }

  function updateSwapLiquify(bool newVal) external onlyOwner {
    swapLiquifyEnabled = newVal;
  }

  function updateFee(string memory _key, uint256 _value) external onlyOwner {
    fees[keccak256(abi.encodePacked(_key))] = _value;
  }

  function setNodeManager(address newVal) external onlyOwner {
    nodeManager = INodeManager02(newVal);
  }

  function setAutomatedMarketMakerPair(address pair, bool value)
    external
    onlyOwner
  {
    require(pair != joePair, "TKN:2");

    _setAutomatedMarketMakerPair(pair, value);
  }

  function blacklistAddress(address account, bool value) external onlyOwner {
    isBlacklisted[account] = value;
  }

  // Private methods

  function _setAutomatedMarketMakerPair(address pair, bool value) private {
    require(automatedMarketMakerPairs[pair] != value, "TKN:3");
    automatedMarketMakerPairs[pair] = value;

    emit SetAutomatedMarketMakerPair(pair, value);
  }

  function swapAndSendToFee(address destination, uint256 tokens) private {
    uint256 initialAVAXBalance = address(this).balance;

    swapTokensForAVAX(tokens);
    uint256 newBalance = (address(this).balance).sub(initialAVAXBalance);
    payable(destination).transfer(newBalance);
  }

  function swapAndLiquify(uint256 tokens) private {
    uint256 half = tokens.div(2);
    uint256 otherHalf = tokens.sub(half);
    uint256 initialBalance = address(this).balance;
    swapTokensForAVAX(half);

    uint256 newBalance = address(this).balance.sub(initialBalance);
    addLiquidity(otherHalf, newBalance);
    emit SwapAndLiquify(half, newBalance, otherHalf);
  }

  function swapTokensForAVAX(uint256 tokenAmount) private {
    require(token.approve(address(joeRouter), tokenAmount), "Approve failed");

    if (tokenAmount > 0) {
      address[] memory path = new address[](2);
      path[0] = tokenAddress;
      path[1] = joeRouter.WAVAX();

      joeRouter.swapExactTokensForAVAXSupportingFeeOnTransferTokens(
        tokenAmount,
        0, // accept any amount of AVAX
        path,
        address(this),
        block.timestamp
      );
    }
  }

  function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
    require(token.approve(address(joeRouter), tokenAmount), "Approve failed");

    // add the liquidity
    joeRouter.addLiquidityAVAX{ value: ethAmount }(
      tokenAddress,
      tokenAmount,
      0, // slippage is unavoidable
      0, // slippage is unavoidable
      rewardsPool,
      block.timestamp
    );
  }

  // External node methods

  function createNodeWithTokens(string memory name, uint256 _amount) external {
    address sender = _msgSender();
    uint256 minPrice = nodeManager.getMinPrice();
    require(bytes(name).length > 3 && bytes(name).length < 32, "NC:1");
    require(sender != address(0), "NC:2");
    require(!isBlacklisted[sender], "BLACKLISTED");
    require(sender != teamPool && sender != rewardsPool, "NC:4");
    require(token.balanceOf(sender) >= _amount, "NC:5");
    require(_amount >= minPrice, "NC:6");

    uint256 contractTokenBalance = token.balanceOf(address(this));
    bool swapAmountOk = contractTokenBalance >= swapTokensAmount;
    if (
      swapAmountOk &&
      swapLiquifyEnabled &&
      !swapping &&
      sender != owner() &&
      !automatedMarketMakerPairs[sender]
    ) {
      swapping = true;

      uint256 teamTokens = contractTokenBalance.mul(_getFee("teamPool")).div(
        100
      );

      swapAndSendToFee(teamPool, teamTokens);

      uint256 rewardsPoolTokens = contractTokenBalance
        .mul(_getFee("rewards"))
        .div(100);
      uint256 rewardsTokenstoSwap = rewardsPoolTokens
        .mul(_getFee("rwSwap"))
        .div(100);

      swapAndSendToFee(rewardsPool, rewardsTokenstoSwap);

      token.transfer(rewardsPool, rewardsPoolTokens.sub(rewardsTokenstoSwap));

      uint256 swapTokens = contractTokenBalance
        .mul(_getFee("liquidityPool"))
        .div(100);

      swapAndLiquify(swapTokens);

      swapping = false;
    }
    token.transferFrom(sender, address(this), _amount);
    nodeManager.createNode(sender, name, _amount);
  }

  function cashoutReward(uint256 blocktime) external {
    address sender = _msgSender();
    require(sender != address(0), "CASHOUT:1");
    require(!isBlacklisted[sender], "BLACKLISTED");
    require(sender != teamPool && sender != rewardsPool, "CASHOUT:3");
    uint256 rewardAmount = nodeManager.getNodeReward(sender, blocktime);
    require(rewardAmount > 0, "CASHOUT:4");

    uint256 feeAmount;
    uint256 burnAmount;

    if (_getFee("cashout") > 0) {
      feeAmount = rewardAmount.mul(_getFee("cashout")).div(100);
      swapAndSendToFee(rewardsPool, feeAmount);
    }
    rewardAmount -= feeAmount;

    if (_getFee("burn") > 0) {
      burnAmount = rewardAmount.mul(_getFee("burn")).div(100);
      token.transfer(deadWallet, burnAmount);
    }
    rewardAmount -= burnAmount;

    token.transferFrom(rewardsPool, sender, rewardAmount);
    nodeManager.cashoutNodeReward(sender, blocktime);
    totalClaimed += rewardAmount;

    emit Cashout(sender, rewardAmount, blocktime);
  }

  function cashoutAll() external {
    address sender = _msgSender();
    require(sender != address(0), "CASHOUT:5");
    require(!isBlacklisted[sender], "BLACKLISTED");
    require(sender != teamPool && sender != rewardsPool, "CASHOUT:7");
    uint256 rewardAmount = nodeManager.getAllNodesRewards(sender);
    require(rewardAmount > 0, "CASHOUT:8");

    uint256 feeAmount;
    uint256 burnAmount;

    if (_getFee("cashout") > 0) {
      feeAmount = rewardAmount.mul(_getFee("cashout")).div(100);
      swapAndSendToFee(rewardsPool, feeAmount);
    }
    rewardAmount -= feeAmount;

    if (_getFee("burn") > 0) {
      burnAmount = rewardAmount.mul(_getFee("burn")).div(100);
      token.transferFrom(rewardsPool, deadWallet, burnAmount);
    }
    rewardAmount -= burnAmount;

    token.transferFrom(rewardsPool, sender, rewardAmount);
    nodeManager.cashoutAllNodesRewards(sender);
    totalClaimed += rewardAmount;

    emit Cashout(sender, rewardAmount, 0);
  }

  function compoundNodeRewards(uint256 blocktime) external {
    address sender = _msgSender();
    require(sender != address(0), "COMP:1");
    require(!isBlacklisted[sender], "BLACKLISTED");
    require(sender != teamPool && sender != rewardsPool, "COMP:2");
    uint256 rewardAmount = nodeManager.getNodeReward(sender, blocktime);
    require(rewardAmount > 0, "COMP:3");
    uint256 feeAmount;
    uint256 burnAmount;

    if (_getFee("compound") > 0) {
      feeAmount = rewardAmount.mul(_getFee("compound")).div(100);
      swapAndSendToFee(rewardsPool, feeAmount);
    }
    rewardAmount -= feeAmount;

    if (_getFee("burn") > 0) {
      burnAmount = rewardAmount.mul(_getFee("burn")).div(100);
      token.transferFrom(rewardsPool, deadWallet, burnAmount);
    }
    rewardAmount -= burnAmount;

    token.transferFrom(rewardsPool, address(this), rewardAmount);
    nodeManager.compoundNodeReward(sender, blocktime, rewardAmount);

    emit Compound(sender, rewardAmount, blocktime);
  }

  function compoundAll() external {
    address sender = _msgSender();
    require(sender != address(0), "COMP:1");
    require(!isBlacklisted[sender], "BLACKLISTED");
    require(sender != teamPool && sender != rewardsPool, "COMP:2");
    uint256 rewardAmount = nodeManager.getAllNodesRewards(sender);
    require(rewardAmount > 0, "COMP:3");

    uint256 feeAmount;
    uint256 burnAmount;

    if (_getFee("compound") > 0) {
      feeAmount = rewardAmount.mul(_getFee("compound")).div(100);
      swapAndSendToFee(rewardsPool, feeAmount);
    }
    rewardAmount -= feeAmount;

    if (_getFee("burn") > 0) {
      burnAmount = rewardAmount.mul(_getFee("burn")).div(100);
      token.transferFrom(rewardsPool, deadWallet, burnAmount);
    }
    rewardAmount -= burnAmount;
    token.transferFrom(rewardsPool, address(this), rewardAmount);
    nodeManager.compoundAllNodesRewards(sender);

    emit Compound(sender, rewardAmount, 0);
  }

  function renameNode(uint256 blocktime, string memory newName) external {
    address sender = _msgSender();
    require(!isBlacklisted[sender], "BLACKLISTED");

    nodeManager.renameNode(sender, newName, blocktime);
  }

  function increaseNodeAmount(uint256 blocktime, uint256 _amount) external {
    address sender = _msgSender();
    require(!isBlacklisted[sender], "BLACKLISTED");
    require(token.balanceOf(sender) >= _amount, "NC:5");

    token.transferFrom(sender, address(this), _amount);
    nodeManager.increaseNodeAmount(sender, blocktime, _amount);
  }

  function mergeNodes(uint256 destBlocktime, uint256 srcBlocktime) external {
    address sender = _msgSender();
    require(!isBlacklisted[sender], "BLACKLISTED");

    uint256 mergeFee = _getFee("merge");
    if (mergeFee > 0) {
      require(token.balanceOf(sender) >= mergeFee, "E:1");
      token.transfer(deadWallet, mergeFee);
    }

    nodeManager.mergeNodes(sender, destBlocktime, srcBlocktime);
  }
}