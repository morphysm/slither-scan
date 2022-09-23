//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "../../interfaces/IUniswapV2Router.sol";
import "../../interfaces/IUniswapV2Exchange.sol";
import "../../interfaces/IWETH.sol";
import "../../libs/UniversalERC20.sol";
import "./AvaxHelpers.sol";

contract TraderJoeResolver is AvaxHelpers {
    using SafeMath for uint256;
    using UniversalERC20 for IERC20;
    using UniversalERC20 for IWETH;

    IUniswapV2Router internal constant router = IUniswapV2Router(0x60aE616a2155Ee3d9A68541Ba4544862310933d4);

    IWETH internal constant wavax = IWETH(0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7);

    // EVENTS
    event LogSwap(address indexed src, address indexed dest, uint256 amount);
    event LogLiquidityAdd(address indexed tokenA, address indexed tokenB, uint256 amountA, uint256 amountB);
    event LogLiquidityRemove(address indexed tokenA, address indexed tokenB, uint256 amountA, uint256 amountB);

    function _payFees(IERC20 erc20, uint256 amt) internal returns (uint256 feesPaid) {
        (uint fee, uint maxFee, address feeRecipient) = getSwapFee();

        // When fee recipient is the smart wallet fee
        if (feeRecipient == msg.sender) return 0;

        if (fee > 0) {
            require(feeRecipient != address(0), "ZERO ADDRESS");

            feesPaid = (amt * fee) / maxFee;

            erc20.universalTransfer(feeRecipient, feesPaid);
        }
    }

    /**
     * @dev Swap tokens in Quickswap dex
     * @param path swap route fromToken => destToken
     * @param tokenAmt amount of fromTokens to swap
     * @param getId read value of tokenAmt from memory contract
     * @param setId set value of tokens swapped in memory contract
     */
    function swap(
        address[] memory path,
        uint256 tokenAmt,
        uint256 getId,
        uint256 setId,
        uint256 divider
    ) external payable {
        require(path.length >= 2, "INVALID PATH");

        uint256 realAmt = getId > 0 ? getUint(getId).div(divider) : tokenAmt;
        require(realAmt > 0, "ZERO AMOUNT");

        IERC20 fromToken = IERC20(path[0]);
        IERC20 destToken = IERC20(path[path.length - 1]);

        if (fromToken.isETH()) {
            wavax.deposit{value: realAmt}();
            wavax.universalApprove(address(router), realAmt);
            path[0] = address(wavax);
        } else fromToken.universalApprove(address(router), realAmt);

        if (destToken.isETH()) path[path.length - 1] = address(wavax);

        require(path[0] != path[path.length - 1], "SAME ASSETS");

        uint256 received = router.swapExactTokensForTokens(realAmt, 1, path, address(this), block.timestamp + 1)[
            path.length - 1
        ];

        uint256 feesPaid = _payFees(destToken, received);

        received = received - feesPaid;

        if (destToken.isETH()) {
            wavax.withdraw(received);
        }

        // set destTokens received
        if (setId > 0) {
            setUint(setId, received);
        }

        emit LogSwap(address(fromToken), address(destToken), realAmt);
    }

    /**
     * @dev Add liquidity to Quickswap pools
     * @param amtA amount of A tokens to add
     * @param amtB amount of B tokens to add
     * @param getId read value of tokenAmt from memory contract position 1
     * @param getId2 read value of tokenAmt from memory contract position 2
     * @param setId set value of LP tokens received in memory contract
     */
    function addLiquidity(
        IERC20 tokenA,
        IERC20 tokenB,
        uint256 amtA,
        uint256 amtB,
        uint256 getId,
        uint256 getId2,
        uint256 setId,
        uint256 divider
    ) external payable {
        uint256 realAmtA = getId > 0 ? getUint(getId).div(divider) : amtA;
        uint256 realAmtB = getId2 > 0 ? getUint(getId2).div(divider) : amtB;

        require(realAmtA > 0 && realAmtB > 0, "INVALID AMOUNTS");

        IERC20 tokenAReal = tokenA.isETH() ? wavax : tokenA;
        IERC20 tokenBReal = tokenB.isETH() ? wavax : tokenB;

        // Wrap Ether
        if (tokenA.isETH()) {
            wavax.deposit{value: realAmtA}();
        }
        if (tokenB.isETH()) {
            wavax.deposit{value: realAmtB}();
        }

        // Approve Router
        tokenAReal.universalApprove(address(router), realAmtA);
        tokenBReal.universalApprove(address(router), realAmtB);

        (uint256 amountA, uint256 amountB, uint256 liquidity) = router.addLiquidity(
            address(tokenAReal),
            address(tokenBReal),
            realAmtA,
            realAmtB,
            1,
            1,
            address(this),
            block.timestamp + 1
        );

        // set aTokens received
        if (setId > 0) {
            setUint(setId, liquidity);
        }

        emit LogLiquidityAdd(address(tokenAReal), address(tokenBReal), amountA, amountB);
    }

    /**
     * @dev Remove liquidity from Quickswap pool
     * @param tokenA address of token A from the pool
     * @param tokenA address of token B from the pool
     * @param poolToken address of the LP token
     * @param amtPoolTokens amount of LP tokens to burn
     * @param getId read value from memory contract
     * @param setId set value of amount tokenB received in memory contract position 1
     * @param setId2 set value of amount tokenB received in memory contract position 2
     */
    function removeLiquidity(
        IERC20 tokenA,
        IERC20 tokenB,
        IERC20 poolToken,
        uint256 amtPoolTokens,
        uint256 getId,
        uint256 setId,
        uint256 setId2,
        uint256 divider
    ) external payable {
        uint256 realAmt = getId > 0 ? getUint(getId).div(divider) : amtPoolTokens;

        IERC20 tokenAReal = tokenA.isETH() ? wavax : tokenA;
        IERC20 tokenBReal = tokenB.isETH() ? wavax : tokenB;

        // Approve Router
        IERC20(address(poolToken)).universalApprove(address(router), realAmt);

        (uint256 amountA, uint256 amountB) = router.removeLiquidity(
            address(tokenAReal),
            address(tokenBReal),
            realAmt,
            1,
            1,
            address(this),
            block.timestamp + 1
        );

        // set tokenA received
        if (setId > 0) {
            setUint(setId, amountA);
        }

        // set tokenA received
        if (setId2 > 0) {
            setUint(setId2, amountB);
        }

        emit LogLiquidityRemove(address(tokenAReal), address(tokenBReal), amountA, amountB);
    }
}

contract TraderJoeLogic is TraderJoeResolver {
    string public constant name = "TraderJoeLogic";
    uint8 public constant version = 1;

    receive() external payable {}
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IUniswapV2Router {
	function factory() external pure returns (address);

	function WETH() external pure returns (address);

	function getAmountsOut(uint256 amountIn, address[] calldata path)
		external
		view
		returns (uint256[] memory amounts);

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

	function removeLiquidity(
		address tokenA,
		address tokenB,
		uint256 liquidity,
		uint256 amountAMin,
		uint256 amountBMin,
		address to,
		uint256 deadline
	) external returns (uint256 amountA, uint256 amountB);

	function swapExactTokensForTokens(
		uint256 amountIn,
		uint256 amountOutMin,
		address[] calldata path,
		address to,
		uint256 deadline
	) external returns (uint256[] memory amounts);

	function swapExactETHForTokens(
		uint256 amountOutMin,
		address[] calldata path,
		address to,
		uint256 deadline
	) external payable returns (uint256[] memory amounts);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../libs/UniversalERC20.sol";

interface IUniswapV2Exchange {
	function swap(
		uint256 amount0Out,
		uint256 amount1Out,
		address to,
		bytes calldata data
	) external;
}

library UniswapV2ExchangeLib {
	using SafeMath for uint256;
	using UniversalERC20 for IERC20;

	function getReturn(
		IUniswapV2Exchange exchange,
		IERC20 fromToken,
		IERC20 destToken,
		uint256 amountIn
	) internal view returns (uint256) {
		uint256 reserveIn = fromToken.universalBalanceOf(address(exchange));
		uint256 reserveOut = destToken.universalBalanceOf(address(exchange));

		uint256 amountInWithFee = amountIn.mul(997);
		uint256 numerator = amountInWithFee.mul(reserveOut);
		uint256 denominator = reserveIn.mul(1000).add(amountInWithFee);
		return (denominator == 0) ? 0 : numerator.div(denominator);
	}
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

abstract contract IWETH is IERC20 {
	function deposit() external payable virtual;

	function withdraw(uint256 amount) external virtual;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

library UniversalERC20 {
	using SafeMath for uint256;
	using SafeERC20 for IERC20;

	IERC20 private constant ZERO_ADDRESS =
		IERC20(0x0000000000000000000000000000000000000000);
	IERC20 private constant ETH_ADDRESS =
		IERC20(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

	function universalTransfer(
		IERC20 token,
		address to,
		uint256 amount
	) internal returns (bool success) {
		if (amount == 0) {
			return true;
		}

		if (isETH(token)) {
			payable(to).transfer(amount);
		} else {
			token.safeTransfer(to, amount);
			return true;
		}
	}

	function universalTransferFrom(
		IERC20 token,
		address from,
		address to,
		uint256 amount
	) internal {
		if (amount == 0) {
			return;
		}

		if (isETH(token)) {
			require(
				from == msg.sender && msg.value >= amount,
				"Wrong useage of ETH.universalTransferFrom()"
			);
			if (to != address(this)) {
				payable(to).transfer(amount);
			}
			if (msg.value > amount) {
				payable(msg.sender).transfer(msg.value.sub(amount));
			}
		} else {
			token.safeTransferFrom(from, to, amount);
		}
	}

	function universalTransferFromSenderToThis(IERC20 token, uint256 amount)
		internal
	{
		if (amount == 0) {
			return;
		}

		if (isETH(token)) {
			if (msg.value > amount) {
				// Return remainder if exist
				payable(msg.sender).transfer(msg.value.sub(amount));
			}
		} else {
			token.safeTransferFrom(msg.sender, address(this), amount);
		}
	}

	function universalApprove(
		IERC20 token,
		address to,
		uint256 amount
	) internal {
		if (!isETH(token)) {
			if (amount == 0) {
				token.safeApprove(to, 0);
				return;
			}

			uint256 allowance = token.allowance(address(this), to);
			if (allowance < amount) {
				if (allowance > 0) {
					token.safeApprove(to, 0);
				}
				token.safeApprove(to, amount);
			}
		}
	}

	function universalBalanceOf(IERC20 token, address who)
		internal
		view
		returns (uint256)
	{
		if (isETH(token)) {
			return who.balance;
		} else {
			return token.balanceOf(who);
		}
	}

	function universalDecimals(IERC20 token) internal view returns (uint256) {
		if (isETH(token)) {
			return 18;
		}

		(bool success, bytes memory data) =
			address(token).staticcall{gas: 10000}(
				abi.encodeWithSignature("decimals()")
			);
		if (!success || data.length == 0) {
			(success, data) = address(token).staticcall{gas: 10000}(
				abi.encodeWithSignature("DECIMALS()")
			);
		}

		return (success && data.length > 0) ? abi.decode(data, (uint256)) : 18;
	}

	function isETH(IERC20 token) internal pure returns (bool) {
		return (address(token) == address(ZERO_ADDRESS) ||
			address(token) == address(ETH_ADDRESS));
	}
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "../../interfaces/IMemory.sol";
import "../../interfaces/IRegistry.sol";
import "../../interfaces/IWallet.sol";

contract AvaxHelpers {
    /**
     * @dev Return Registry Address
     */
    function getRegistryAddr() public view returns (address) {
        return IWallet(address(this)).registry();
    }

    /**
     * @dev Return Memory Variable Address
     */
    function getMemoryAddr() public view returns (address) {
        return IRegistry(getRegistryAddr()).memoryAddr();
    }

    /**
     * @dev Return Vault fee and recipient
     */
    function getSwapFee()
        public
        view
        returns (
            uint256 fee,
            uint256 maxFee,
            address recipient
        )
    {
        IRegistry registry = IRegistry(getRegistryAddr());

        fee = registry.getFee();
        recipient = registry.feeRecipient();
        maxFee = 10000;
    }

    /**
     * @dev Get Uint value from Memory Contract.
     */
    function getUint(uint256 id) internal view returns (uint256) {
        return IMemory(getMemoryAddr()).getUint(id);
    }

    /**
     * @dev Set Uint value in Memory Contract.
     */
    function setUint(uint256 id, uint256 val) internal {
        IMemory(getMemoryAddr()).setUint(id, val);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

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
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
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

// SPDX-License-Identifier: MIT
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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMemory {
	function getUint(uint256) external view returns (uint256);

	function setUint(uint256 id, uint256 value) external;

	function getAToken(address asset) external view returns (address);

	function setAToken(address asset, address _aToken) external;

	function getCrToken(address asset) external view returns (address);

	function setCrToken(address asset, address _crToken) external;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title RegistryInterface Interface
 */
interface IRegistry {
	function logic(address logicAddr) external view returns (bool);

	function implementation(bytes32 key) external view returns (address);

	function notAllowed(address erc20) external view returns (bool);

	function deployWallet() external returns (address);

	function wallets(address user) external view returns (address);

	function getFee() external view returns (uint256);

	function getFeeManager() external view returns (address);

	function feeRecipient() external view returns (address);

	function memoryAddr() external view returns (address);

	function distributionContract(address token)
		external
		view
		returns (address);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IWallet {
    event LogMint(address indexed erc20, uint256 tokenAmt);
    event LogRedeem(address indexed erc20, uint256 tokenAmt);
    event LogBorrow(address indexed erc20, uint256 tokenAmt);
    event LogPayback(address indexed erc20, uint256 tokenAmt);
    event LogDeposit(address indexed erc20, uint256 tokenAmt);
    event LogWithdraw(address indexed erc20, uint256 tokenAmt);
    event LogSwap(address indexed src, address indexed dest, uint256 amount);
    event LogLiquidityAdd(address indexed tokenA, address indexed tokenB, uint256 amountA, uint256 amountB);
    event LogLiquidityRemove(address indexed tokenA, address indexed tokenB, uint256 amountA, uint256 amountB);
    event VaultDeposit(address indexed vault, address indexed erc20, uint256 tokenAmt);
    event VaultWithdraw(address indexed vault, address indexed erc20, uint256 tokenAmt);
    event VaultClaim(address indexed vault, address indexed erc20, uint256 tokenAmt);
    event Claim(address indexed erc20, uint256 tokenAmt);
    event DelegateAdded(address delegate);
    event DelegateRemoved(address delegate);
    event Staked(address indexed erc20, uint256 tokenAmt);
    event Unstaked(address indexed erc20, uint256 tokenAmt);

    event VoteEscrowDeposit(address indexed veETHA, uint256 amountToken, uint256 amtDays);
    event VoteEscrowWithdraw(address indexed veETHA, uint256 amountToken);
    event VoteEscrowIncrease(address indexed veETHA, uint256 amountToken, uint256 amtDays);

    function executeMetaTransaction(bytes memory sign, bytes memory data) external;

    function execute(address[] calldata targets, bytes[] calldata datas) external payable;

    function owner() external view returns (address);

    function registry() external view returns (address);

    function DELEGATE_ROLE() external view returns (bytes32);

    function hasRole(bytes32, address) external view returns (bool);
}