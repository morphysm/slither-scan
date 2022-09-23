/**
 *Submitted for verification at testnet.snowtrace.io on 2022-04-26
*/

// File: contracts\interfaces\ISlashCore.sol

pragma solidity ^0.8.0;

interface ISlashCore {
    
    /**
     * @dev Get in-amount to get out-amount of receive token
     * @return in-amount of token
     */
    function getAmountIn(
        address merchant_,
        address payingToken_,
        uint256 amountOut_,
        address[] memory path_
    ) external view returns (uint256);

    /**
     * @dev Get out-amount from the in-amount of token
     * @return out-amount of receive token
     */
    function getAmountOut(
        address merchant_,
        address payingToken_,
        uint256 amountIn_,
        address[] memory path_
    ) external view returns (uint256);

    /**
     * @dev Get fee amount from the in-amount of token
     * @param feePath_: swap path from _payingTokenAddress to WETH
     * @return totalFee: in Ether
     * @return donationFee: in Ether
     */
    function getFeeAmount(
        address merchant_,
        address account_,
        address payingToken_,
        uint256 amountIn_,
        address[] memory feePath_
    ) external view returns (uint256, uint256);

    /**
     * @dev Submit transaction
     * @param feePath_: swap path from _payingTokenAddress to WETH
     * @param path_: swap path from _payingTokenAddress to receive token
     */
    function submitTransaction(
        address merchant_,
        address account_,
        address payingToken_,
        uint256 amountIn_,
        address[] memory path_,
        address[] memory feePath_
    ) external payable;
}

// File: contracts\interfaces\IStakingPool.sol

pragma solidity ^0.8.0;

interface IStakingPool {
    function balanceOf(address _account) external view returns (uint256);

    function getShare(address _account) external view returns (uint256);
}

// File: contracts\interfaces\IAffiliatePool.sol

pragma solidity ^0.8.0;

interface IAffiliatePool {
    /**
     * deposit affiliate fee
     * _account: affiliator wallet address
     * _amount: deposit amount
     */
    function deposit(address _account, uint256 _amount) external returns (bool);

    /**
     * withdraw affiliate fee
     * withdraw sender's affiliate fee to sender address
     * _amount: withdraw amount. withdraw all amount if _amount is 0
     */
    function withdraw(uint256 _amount) external returns (bool);

    /**
     * get affiliate fee balance
     * _account: affiliator wallet address
     */
    function balanceOf(address _account) external view returns (uint256);


    /**
     * initialize contract (only owner)
     * _tokenAddress: token contract address of affiliate fee
     */
    function initialize(address _tokenAddress) external;

    /**
     * transfer ownership (only owner)
     * _account: wallet address of new owner
     */
    function transferOwnership(address _account) external;

    /**
     * recover wrong tokens (only owner)
     */
    function recoverWrongTokens(address _tokenAddress, uint256 _tokenAmount) external;

    /**
     * @dev called by the owner to pause, triggers stopped state
     * deposit, withdraw method is suspended
     */
    function pause() external;

    /**
     * @dev called by the owner to unpause, untriggers stopped state
     * deposit, withdraw method is enabled
     */
    function unpause() external;
}

// File: contracts\interfaces\IMerchantProperty.sol

pragma solidity ^0.8.0;

interface IMerchantProperty {
    function viewFeeMaxPercent() external view returns (uint16);

    function viewFeeMinPercent() external view returns (uint16);

    function viewDonationFee() external view returns (uint16);

    function viewTransactionFee() external view returns (uint16);

    function viewWeb3BalanceForFreeTx() external view returns (uint256);

    function viewMinAmountToProcessFee() external view returns (uint256);

    function viewMarketingWallet() external view returns (address payable);

    function viewDonationWallet() external view returns (address payable);

    function viewWeb3Token() external view returns (address);

    function viewAffiliatePool() external view returns (address);

    function viewStakingPool() external view returns (address);

    function viewMainSwapRouter() external view returns (address);

    function viewSwapRouters() external view returns (address[] memory);

    function isBlacklistedFromPayToken(address token_)
        external
        view
        returns (bool);

    function isWhitelistedForRecToken(address token_)
        external
        view
        returns (bool);

    function viewMerchantWallet() external view returns (address);

    function viewAffiliatorWallet() external view returns (address);

    function viewFeeProcessingMethod() external view returns (uint8);

    function viewReceiveToken() external view returns (address);

    function viewDonationFeeCollected() external view returns (uint256);

    /**
     * @dev Update fee max percentage
     * Only callable by owner
     */
    function updateFeeMaxPercent(uint16 maxPercent_) external;

    /**
     * @dev Update fee min percentage
     * Only callable by owner
     */
    function updateFeeMinPercent(uint16 minPercent_) external;

    /**
     * @dev Update donation fee
     * Only callable by owner
     */
    function updateDonationFee(uint16 fee_) external;

    /**
     * @dev Update the transaction fee
     * Can only be called by the owner
     */
    function updateTransactionFee(uint16 fee_) external;

    /**
     * @dev Update the web3 balance for free transaction
     * Can only be called by the owner
     */
    function updateWeb3BalanceForFreeTx(uint256 web3Balance_) external;

    /**
     * @dev Update the web3 balance for free transaction
     * Can only be called by the owner
     */
    function updateMinAmountToProcessFee(uint256 minAmount_) external;

    /**
     * @dev Update the marketing wallet address
     * Can only be called by the owner.
     */
    function updateMarketingWallet(address payable marketingWallet_) external;

    /**
     * @dev Update the donation wallet address
     * Can only be called by the owner.
     */
    function updateDonationWallet(address payable donationWallet_) external;

    /**
     * @dev Update web3 token address
     * Callable only by owner
     */
    function updateWeb3TokenAddress(address tokenAddress_) external;

    function updateaffiliatePool(address affiliatePool_) external;

    function updateStakingPool(address stakingPool_) external;

    /**
     * @dev Update the main swap router.
     * Can only be called by the owner.
     */
    function updateMainSwapRouter(address router_) external;

    /**
     * @dev Update the swap router.
     * Can only be called by the owner.
     */
    function addSwapRouter(address router_) external;

    /**
     * @dev Remove the swap router from avilable routers.
     * Can only be called by the owner.
     */
    function removeSwapRouter(uint256 index_) external;

    /**
     * @dev Exclude a token from paying blacklist
     * Only callable by owner
     */
    function excludeFromPayTokenBlacklist(address token_) external;

    /**
     * @dev Include a token in paying blacklist
     * Only callable by owner
     */
    function includeInPayTokenBlacklist(address token_) external;

    /**
     * @dev Exclude a token from receiving whitelist
     * Only callable by owner
     */
    function excludeFromRecTokenWhitelist(address token_) external;

    /**
     * @dev Include a token in receiving whitelist
     * Only callable by owner
     */
    function includeInRecTokenWhitelist(address token_) external;

    /**
     * @dev Update the merchant wallet address
     * Can only be called by the owner.
     */
    function updateMerchantWallet(address merchantWallet_) external;

    /**
     * @dev Update affiliator wallet address
     * Only callable by owner
     */
    function updateAffiliatorWallet(address affiliatorWallet_) external;

    /**
     * @dev Update fee processing method
     * Only callable by owner
     */
    function updateFeeProcessingMethod(uint8 method_) external;

    /**
     * @dev Update donationFeeCollected
     * Only callable by owner
     */
    function updateDonationFeeCollected(uint256 fee_) external;
}

// File: node_modules\@uniswap\v2-periphery\contracts\interfaces\IUniswapV2Router01.sol

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

// File: @uniswap\v2-periphery\contracts\interfaces\IUniswapV2Router02.sol

pragma solidity >=0.6.2;


interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// File: contracts\libs\SafeMath.sol

pragma solidity ^0.8.0;

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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
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
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
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
     * @dev Returns the integer division of two unsigned integers. Reverts on
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
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: contracts\libs\Address.sol

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
        // solhint-disable-next-line no-inline-assembly
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
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
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
    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
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
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
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
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
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
    function functionDelegateCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionDelegateCall(
                target,
                data,
                "Address: low-level delegate call failed"
            );
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

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
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

// File: contracts\libs\IBEP20.sol

pragma solidity ^0.8.0;

interface IBEP20 {
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function getOwner() external view returns (address);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address _owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

// File: contracts\libs\SafeBEP20.sol

pragma solidity ^0.8.0;




/**
 * @title SafeBEP20
 * @dev Wrappers around BEP20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeBEP20 for IBEP20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeBEP20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(
        IBEP20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IBEP20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IBEP20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeBEP20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(
            value
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function safeDecreaseAllowance(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(
            value,
            "SafeBEP20: decreased allowance below zero"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IBEP20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(
            data,
            "SafeBEP20: low-level call failed"
        );
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(
                abi.decode(returndata, (bool)),
                "SafeBEP20: BEP20 operation did not succeed"
            );
        }
    }
}

// File: contracts\libs\MerchantLibrary.sol

pragma solidity ^0.8.0;




library MerchantLibrary {
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;

    // Predict swap amount in / out of router
    function predictAmount(
        address _payingToken,
        address _receiveToken,
        IUniswapV2Router02 _swapRouter,
        uint256 knownAmount,
        address[] memory path,
        bool getInAmount
    ) public view returns (uint256) {
        if (address(_swapRouter) == address(0)) {
            return 0;
        }
        if (_payingToken == _receiveToken) {
            return knownAmount;
        }

        // swap path should be valid one
        bool isPathValid = path.length >= 2 &&
            path[0] == _payingToken &&
            path[path.length - 1] == _receiveToken;

        if (!isPathValid) {
            if (
                _payingToken == _swapRouter.WETH() ||
                _receiveToken == _swapRouter.WETH()
            ) {
                path = new address[](2);
                path[0] = _payingToken;
                path[1] = _receiveToken;
            } else {
                path = new address[](3);
                path[0] = _payingToken;
                path[1] = _swapRouter.WETH();
                path[2] = _receiveToken;
            }
        }

        if (getInAmount) {
            try _swapRouter.getAmountsIn(knownAmount, path) returns (
                uint256[] memory amounts
            ) {
                return amounts[0];
            } catch (
                bytes memory /* lowLevelData */
            ) {
                return 0;
            }
        } else {
            try _swapRouter.getAmountsOut(knownAmount, path) returns (
                uint256[] memory amounts
            ) {
                return amounts[amounts.length - 1];
            } catch (
                bytes memory /* lowLevelData */
            ) {
                return 0;
            }
        }
    }

    function predictBestOutAmount(
        address _payingToken,
        address _receiveToken,
        uint256 _amountIn,
        address[] memory _swapRouters,
        address[] memory path
    ) public view returns (uint256 bestAmount, uint256 bestRouterIndex) {
        for (uint256 i = 0; i < _swapRouters.length; i++) {
            IUniswapV2Router02 swapRouter = IUniswapV2Router02(_swapRouters[i]);
            uint256 amount = predictAmount(
                _payingToken,
                _receiveToken,
                swapRouter,
                _amountIn,
                path,
                false
            );
            if (bestAmount < amount) {
                bestAmount = amount;
                bestRouterIndex = i;
            }
        }
    }

    /**
     * @dev Swap tokens for eth
     * This function is called when fee processing mode is LIQU or AFLIQU which means web3 token is always set
     */
    function swapEtherToToken(
        address swapRouter_,
        address token_,
        uint256 etherAmount_,
        address to_
    ) public returns (uint256 tokenAmount, bool success) {
        IUniswapV2Router02 swapRouter = IUniswapV2Router02(swapRouter_);
        IBEP20 token = IBEP20(token_);

        // generate the saunaSwap pair path of bnb -> web3
        address[] memory path = new address[](2);
        path[0] = swapRouter.WETH();
        path[1] = token_;

        // make the swap
        uint256 balanceBefore = token.balanceOf(to_);
        try
            swapRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{
                value: etherAmount_
            }(
                0, // accept any amount of WEB3
                path,
                to_,
                block.timestamp.add(300)
            )
        {
            tokenAmount = token.balanceOf(to_).sub(balanceBefore);
            success = true;
        } catch (
            bytes memory /* lowLevelData */
        ) {
            success = false;
            tokenAmount = 0;
        }
    }

    /**
     * @dev Add liquidity
     * This function is called when fee processing mode is LIQU or AFLIQU which means web3 token is always set
     */
    function addLiquidityETH(
        address swapRouter_,
        address token_,
        uint256 tokenAmount_,
        uint256 etherAmount_,
        address to_
    ) public returns (bool success) {
        IUniswapV2Router02 swapRouter = IUniswapV2Router02(swapRouter_);
        IBEP20 token = IBEP20(token_);

        // approve token transfer to cover all possible scenarios
        token.safeApprove(address(swapRouter), tokenAmount_);

        // add the liquidity
        try
            swapRouter.addLiquidityETH{value: etherAmount_}(
                token_,
                tokenAmount_,
                0, // slippage is unavoidable
                0, // slippage is unavoidable
                to_,
                block.timestamp.add(300)
            )
        {
            success = true;
        } catch (
            bytes memory /* lowLevelData */
        ) {
            success = false;
        }
    }
}

// File: contracts\libs\Context.sol

pragma solidity ^0.8.0;

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
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor() {}

    function _msgSender() internal view returns (address) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: contracts\libs\Ownable.sol

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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: contracts\SlashCore.sol

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;









contract SlashCore is ISlashCore, Ownable {
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;

    enum FeeMethod {
        SIMPLE,
        LIQU,
        AFLIQU
    }

    event SwapEtherToWeb3TokenFailed(
        address indexed merchant,
        uint256 etherAmount
    );
    event AddLiquidityFailed(
        address indexed merchant,
        uint256 tokenAmount,
        uint256 etherAmount,
        address to
    );

    mapping(address => uint256) _taxFeePerMerchant;
    mapping(address => uint256) _donationFeePerMerchant;

    //to recieve ETH
    receive() external payable {}

    function handleFeeLiq(IMerchantProperty merchant_, uint256 taxFeeAmount_)
        internal
    {
        address payable marketingWallet = merchant_.viewMarketingWallet();
        address swapRouter = merchant_.viewMainSwapRouter();
        address web3Token = merchant_.viewWeb3Token();

        // 50% of staked fee is added to WEB3-BNB liquidity and sent to the marketing address
        uint256 liquidifyBalance = taxFeeAmount_.div(2);

        uint256 half = liquidifyBalance.div(2);
        uint256 otherHalf = liquidifyBalance.sub(half);

        // Swap ether to web3
        (uint256 swappedWeb3Balance, bool success) = MerchantLibrary
            .swapEtherToToken(swapRouter, web3Token, half, address(this));
        if (!success) {
            emit SwapEtherToWeb3TokenFailed(address(merchant_), half);
            return;
        }

        // Add liquidity
        success = MerchantLibrary.addLiquidityETH(
            swapRouter,
            web3Token,
            swappedWeb3Balance,
            otherHalf,
            marketingWallet
        );
        if (!success) {
            emit AddLiquidityFailed(
                address(merchant_),
                swappedWeb3Balance,
                otherHalf,
                marketingWallet
            );
            // Do not return this time
        }

        // 50% of staked fee is swapped to WEB3 tokens to be sent to the marketing address
        uint256 directSwapBalance = taxFeeAmount_.sub(liquidifyBalance);
        // Swap bnb to web3
        (, success) = MerchantLibrary.swapEtherToToken(
            swapRouter,
            web3Token,
            directSwapBalance,
            marketingWallet
        );
        if (!success) {
            emit SwapEtherToWeb3TokenFailed(
                address(merchant_),
                directSwapBalance
            );
        }
    }

    function handleFeeAfLiq(IMerchantProperty merchant_, uint256 taxFeeAmount_)
        internal
    {
        IAffiliatePool affiliatePool = IAffiliatePool(
            merchant_.viewAffiliatePool()
        );
        address payable marketingWallet = merchant_.viewMarketingWallet();
        address swapRouter = merchant_.viewMainSwapRouter();
        address web3Token = merchant_.viewWeb3Token();

        // 55% of staked fee is swapped to WEB3 token
        uint256 buyupBalance = taxFeeAmount_.mul(55).div(100);
        uint256 remainedEthBalance = taxFeeAmount_.sub(buyupBalance);

        (uint256 swappedWeb3Balance, bool success) = MerchantLibrary
            .swapEtherToToken(
                swapRouter,
                web3Token,
                buyupBalance,
                address(this)
            );
        if (!success) {
            emit SwapEtherToWeb3TokenFailed(address(merchant_), buyupBalance);
            return;
        }

        uint256 web3AmountToStake = swappedWeb3Balance.mul(10).div(55);

        // When fee processing method is AFLIQU, affiliatePool & affiliatorWallet addresses are not zero
        IBEP20(web3Token).approve(address(affiliatePool), web3AmountToStake);
        // 5% amount of WEB3 token is deposited to affiliate pool for merchant and affiliator
        uint256 eachStakeAmount = web3AmountToStake.div(2);
        if (eachStakeAmount > 0) {
            affiliatePool.deposit(
                merchant_.viewMerchantWallet(),
                eachStakeAmount
            );
            affiliatePool.deposit(
                merchant_.viewAffiliatorWallet(),
                eachStakeAmount
            );
        }

        // WEB3 + BNB to liquidity
        uint256 liqifyBalance = swappedWeb3Balance.sub(web3AmountToStake);
        // Add liquidity
        success = MerchantLibrary.addLiquidityETH(
            swapRouter,
            web3Token,
            liqifyBalance,
            remainedEthBalance,
            marketingWallet
        );
        if (!success) {
            emit AddLiquidityFailed(
                address(merchant_),
                liqifyBalance,
                remainedEthBalance,
                marketingWallet
            );
            return;
        }
    }

    /**
     * @dev Handle fee
     * @param taxFeeAmount_: tax fee
     * @param donationFeeAmount_: donation fee is processed separately, so pass this amount
     */
    function handleFee(
        address merchant_,
        uint256 taxFeeAmount_,
        uint256 donationFeeAmount_
    ) internal {
        IMerchantProperty merchant = IMerchantProperty(merchant_);
        uint256 taxFeeAmount = taxFeeAmount_.add(_taxFeePerMerchant[merchant_]);
        uint256 donationFeeAmount = donationFeeAmount_.add(
            _donationFeePerMerchant[merchant_]
        );

        uint256 feeAmount = taxFeeAmount.add(donationFeeAmount);

        // Fee will be processed only when it is more than specific amount
        if (feeAmount < merchant.viewMinAmountToProcessFee()) {
            return;
        }

        if (donationFeeAmount > 0) {
            merchant.viewDonationWallet().transfer(donationFeeAmount);
            _donationFeePerMerchant[merchant_] = 0;
        }

        if (taxFeeAmount == 0) {
            return;
        }

        address payable marketingWallet = merchant.viewMarketingWallet();
        FeeMethod feeProcessingMethod = FeeMethod(
            merchant.viewFeeProcessingMethod()
        );

        if (feeProcessingMethod == FeeMethod.SIMPLE) {
            marketingWallet.transfer(taxFeeAmount);
        } else if (feeProcessingMethod == FeeMethod.LIQU) {
            handleFeeLiq(merchant, taxFeeAmount);
        } else if (feeProcessingMethod == FeeMethod.AFLIQU) {
            handleFeeAfLiq(merchant, taxFeeAmount);
        }
        _taxFeePerMerchant[merchant_] = 0;
    }

    /**
     * @dev Get in-amount to get out-amount of receive token
     * @return in-amount of token
     */
    function getAmountIn(
        address merchant_,
        address payingToken_,
        uint256 amountOut_,
        address[] memory path_
    ) external view override returns (uint256) {
        IMerchantProperty merchant = IMerchantProperty(merchant_);

        // Blacklisted token can not be used as paying token
        if (merchant.isBlacklistedFromPayToken(payingToken_)) {
            return 0;
        }
        return
            MerchantLibrary.predictAmount(
                payingToken_,
                merchant.viewReceiveToken(),
                IUniswapV2Router02(merchant.viewMainSwapRouter()),
                amountOut_,
                path_,
                true
            );
    }

    /**
     * @dev Get out-amount from the in-amount of token
     * @return out-amount of receive token
     */
    function getAmountOut(
        address merchant_,
        address payingToken_,
        uint256 amountIn_,
        address[] memory path_
    ) external view override returns (uint256) {
        IMerchantProperty merchant = IMerchantProperty(merchant_);

        // Blacklisted token can not be used as paying token
        if (merchant.isBlacklistedFromPayToken(payingToken_)) {
            return 0;
        }

        return
            MerchantLibrary.predictAmount(
                payingToken_,
                merchant.viewReceiveToken(),
                IUniswapV2Router02(merchant.viewMainSwapRouter()),
                amountIn_,
                path_,
                false
            );
    }

    /**
     * @dev Swap token to receive token and transfer to the merchant wallet
     * @param path_: swap path from _payingTokenAddress to receive token
     */
    function doMerchantDeposit(
        IMerchantProperty merchant_,
        address payingToken_,
        uint256 amountIn_,
        address[] memory path_
    ) private {
        IUniswapV2Router02 swapRouter = IUniswapV2Router02(
            merchant_.viewMainSwapRouter()
        );
        address receiveToken = merchant_.viewReceiveToken();
        address merchantWallet = merchant_.viewMerchantWallet();

        if (payingToken_ == receiveToken) {
            IBEP20(receiveToken).safeTransfer(merchantWallet, amountIn_);
        } else {
            // swap path should be valid one
            if (
                !(path_.length >= 2 &&
                    path_[0] == payingToken_ &&
                    path_[path_.length - 1] == receiveToken)
            ) {
                // generate the saunaSwap pair path when valid path is not provided
                if (
                    payingToken_ == swapRouter.WETH() ||
                    receiveToken == swapRouter.WETH()
                ) {
                    // generate the saunaSwap pair path
                    path_ = new address[](2);
                    path_[0] = payingToken_;
                    path_[1] = receiveToken;
                } else if (payingToken_ != swapRouter.WETH()) {
                    path_ = new address[](3);
                    path_[0] = payingToken_;
                    path_[1] = swapRouter.WETH();
                    path_[2] = receiveToken;
                }
            }

            // Choose router which returns max amount
            address[] memory availableSwapRouters = merchant_.viewSwapRouters();
            // Assume that WETH is same in all routers
            (uint256 bestAmount, uint256 bestRouterIndex) = MerchantLibrary
                .predictBestOutAmount(
                    payingToken_,
                    receiveToken,
                    amountIn_,
                    availableSwapRouters,
                    path_
                );

            if (bestAmount > 0) {
                IUniswapV2Router02 router = IUniswapV2Router02(
                    availableSwapRouters[bestRouterIndex]
                );
                // Approve token before transfer
                IBEP20(payingToken_).approve(address(router), amountIn_);
                // make the swap
                router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                    amountIn_,
                    0, // accept any amount of receive token
                    path_,
                    merchantWallet,
                    block.timestamp.add(300)
                );
            }
        }
    }

    /**
     * @dev Get tax fee amount
     */
    function getTxFeeAmount(
        IMerchantProperty merchant_,
        address account_,
        uint256 amountIn_
    ) private view returns (uint256) {
        IBEP20 web3Token = IBEP20(merchant_.viewWeb3Token());
        uint256 web3BalanceForFreeTx = merchant_.viewWeb3BalanceForFreeTx();
        IStakingPool stakingPool = IStakingPool(merchant_.viewStakingPool());
        uint256 feeMaxPercent = merchant_.viewFeeMaxPercent();

        // If user wallet has enough web3 token, fee amount is 0
        if (
            address(web3Token) != address(0) &&
            web3Token.balanceOf(account_) >= web3BalanceForFreeTx
        ) {
            return 0;
        }
        // If user did stake enough amount in staking contract, fee amount is 0
        if (
            address(stakingPool) != address(0) &&
            stakingPool.balanceOf(account_) >= web3BalanceForFreeTx
        ) {
            return 0;
        }
        // If staking contract is set to the merchant, determine fee amount from the staking amount
        if (address(stakingPool) != address(0)) {
            return
                amountIn_
                    .mul(
                        uint256(feeMaxPercent).sub(
                            stakingPool.getShare(account_).mul(
                                uint256(feeMaxPercent).sub(
                                    merchant_.viewFeeMinPercent()
                                )
                            )
                        )
                    )
                    .div(10000);
        }
        // Default fee amount
        return amountIn_.mul(merchant_.viewTransactionFee()).div(10000);
    }

    /**
     * @dev Get fee amount from the in-amount of token
     * @param feePath_: swap path from _payingTokenAddress to WETH
     * @return taxFee: tax fee in ether
     * @return donationFee: donation fee in ether
     */
    function getFeeAmount(
        address merchant_,
        address account_,
        address payingToken_,
        uint256 amountIn_,
        address[] memory feePath_
    ) public view override returns (uint256, uint256) {
        IMerchantProperty merchant = IMerchantProperty(merchant_);

        // Blacklisted token can not be used as paying token
        if (merchant.isBlacklistedFromPayToken(payingToken_)) {
            return (0, 0);
        }

        IUniswapV2Router02 swapRouter = IUniswapV2Router02(
            merchant.viewMainSwapRouter()
        );

        uint256 taxFeeAmount = getTxFeeAmount(merchant, account_, amountIn_);
        // There is donation fee set always
        uint256 donationFeeAmount = amountIn_
            .mul(merchant.viewDonationFee())
            .div(10000);
        uint256 feeAmount = taxFeeAmount.add(donationFeeAmount);

        if (feeAmount == 0) {
            return (0, 0);
        }

        if (payingToken_ == swapRouter.WETH()) {
            return (taxFeeAmount, donationFeeAmount);
        }

        if (
            !(feePath_.length >= 2 &&
                feePath_[0] == payingToken_ &&
                feePath_[feePath_.length - 1] == swapRouter.WETH())
        ) {
            feePath_ = new address[](2);
            feePath_[0] = payingToken_;
            feePath_[1] = swapRouter.WETH();
        }

        uint256[] memory amounts = swapRouter.getAmountsOut(
            feeAmount,
            feePath_
        );
        return (
            amounts[feePath_.length - 1].mul(taxFeeAmount).div(feeAmount),
            amounts[feePath_.length - 1].mul(donationFeeAmount).div(feeAmount)
        );
    }

    /**
     * @dev Submit transaction
     * @param feePath_: swap path from _payingTokenAddress to WETH
     * @param path_: swap path from _payingTokenAddress to receive token
     */
    function submitTransaction(
        address merchant_,
        address account_,
        address payingToken_,
        uint256 amountIn_,
        address[] memory path_,
        address[] memory feePath_
    ) external payable override {
        require(amountIn_ > 0, "_amountIn > 0");
        IMerchantProperty merchant = IMerchantProperty(merchant_);
        require(
            !merchant.isBlacklistedFromPayToken(payingToken_),
            "blacklisted"
        );
        IBEP20 payingToken = IBEP20(payingToken_);
        uint256 balanceBefore = payingToken.balanceOf(address(this));
        payingToken.safeTransferFrom(account_, address(this), amountIn_);
        amountIn_ = payingToken.balanceOf(address(this)).sub(balanceBefore);

        (uint256 taxFeeAmount, uint256 donationFeeAmount) = getFeeAmount(
            merchant_,
            account_,
            payingToken_,
            amountIn_,
            feePath_
        );
        require(
            msg.value >= taxFeeAmount.add(donationFeeAmount),
            "Insufficient fee"
        );

        // Swap token to receive token and transfer to the merchant wallet
        doMerchantDeposit(merchant, payingToken_, amountIn_, path_);

        // Handle fee
        handleFee(merchant_, taxFeeAmount, donationFeeAmount);
    }

    /**
     * @notice It allows the admin to recover wrong tokens sent to the contract
     * @param _tokenAddress: the address of the token to withdraw
     * @param _tokenAmount: the number of tokens to withdraw
     * @dev This function is only callable by admin.
     */
    function recoverWrongTokens(address _tokenAddress, uint256 _tokenAmount)
        external
        onlyOwner
    {
        IBEP20(_tokenAddress).safeTransfer(_msgSender(), _tokenAmount);
    }
}