/**
 *Submitted for verification at testnet.snowtrace.io on 2022-05-27
*/

//SPDX-License-Identifier: MIT
// File: SafeMath.sol
pragma solidity ^0.8.0;

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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
    function trySub(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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
    function tryMul(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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
    function tryDiv(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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
    function tryMod(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/token/ERC20/ERC20.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;




/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// File: @openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/extensions/ERC20Burnable.sol)

pragma solidity ^0.8.0;



/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }
}

// File: TBGEN.sol
pragma solidity ^0.8.0;
//TODO: https://stermi.medium.com/how-to-create-an-erc20-token-and-a-solidity-vendor-contract-to-sell-buy-your-own-token-8882808dd905
/* Open Zeppelin Contracts */




/* import "./IUniswapDependencies.sol"; */
//TODO: Pangolin testnet _FACTORY address: 0xefa94DE7a4656D787667C749f7E1223D71E9FD88
//TODO: Pangolin testnet _WETH address: 0xd00ae08403B9bbb9124bB305C09058E32C39A48c
/*
 * Test Router Pancake : 0x60d0E984C1c1C13fA93D30Eb2B48c70BD445892e
 */
/*
 *
 function swapExactTokensForTokens(
  uint amountIn,
  uint amountOutMin,
  address[] calldata path,
  address to,
  uint deadline
) external returns (uint[] memory amounts);
 */
// https://uniswap.org/docs/v2/smart-contracts/router01/
// https://github.com/Uniswap/uniswap-v2-periphery/blob/master/contracts/UniswapV2Router01.sol implementation
// https://github.com/pancakeswap/pancake-swap-periphery/blob/master/contracts/examples/ExampleSwapToPrice.sol
// UniswapV2Router01 is deployed at 0xf164fC0Ec4E93095b804a4795bBe1e041497b92a on the Ethereum mainnet, and the Ropsten, Rinkeby, Görli, and Kovan testnets

pragma solidity >=0.6.2;

/* TODO: Implement, isExcludedFromFee to Owner */
contract TBGEN is ERC20, ERC20Burnable, ReentrancyGuard {
    uint256 x;
    uint256 y;

/*     fallback() external payable {
        x = 1;
        y = msg.value;
    }

    receive() external payable {
        x = 2;
        y = msg.value;
    } */

    using SafeMath for uint256;
    /* TAGEN address */
    address tokenAAddress = 0x2396FA63168798Ddd878f42c48251e4946218333;

    uint256 public constant AMOUNT_OF_TOKEN = 10000 * 10**18;
    /* 32 * 6 = 256, 256 bytes are 1 block. Gas savings */
    uint256 public buyTokenRewardsFee = 3;
    uint256 public sellTokenRewardsFee = 4;
    /* Liquidity fees */
    uint256 public buyLiquidityFee = 3;
    uint256 public sellLiquidityFee = 2;

    /* Marketing & Development Fees */
    uint256 public buyMarketDevFee = 2;
    /*
     * TODO: Assume that commision and marketDev wallets are same
     */

    /* TODO: Make sure sellMarketDevFee is divided with 200 */
    uint256 public sellMarketDevFee = 5;

    /* Commision & Charity */
    /* TODO: Make sure commisionFee is divided with 200 */
    uint256 public commisionFee = 1;
    uint256 public charityFee = 1;
    uint256 public burnFee = 2;
    /* Handle incoming BNB in constructor */
    uint256 fullBalance;
    mapping(address => bool) _isExcludedFromFee;
    modifier isUser() {
        require(
            _msgSender() == tx.origin,
            "Token B:Only real users are allowed to access."
        );
        _;
    }
    /* BEP20 STANDARD EXTRA START */
    /* THESE ARE REQUIRED BECAUSE BEP20 NEEDS THIS ACCORDING TO THEIR DOCUMENTATION*/
    address private _owner;

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address) {
        return owner();
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    function renounceOwnership() public {
        require(msg.sender == owner());
        _owner = address(0);
    }

    /* BEP20 STANDARD EXTRA END*/
    /*
     * TODO: Creating liquidity pool should be exempt from fees
     */
    /* IUniswapV2Router02 public uniswapV2Router;

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) internal {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // add the liquidity
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(this),
            block.timestamp
        );

        /* router.addLiquidity(
            tokenAAddress,
            address(this),
            5000,
            10000,
            4999,
            9999,
            uniswapV2Pair,
            block.timestamp
        ); 
    } */

    constructor(/* address _router */) ERC20("Token B", "PURPLE-2") {
        /* Get router */
        _mint(_msgSender(), AMOUNT_OF_TOKEN);
        /* IUniswapV2Router02 router = IUniswapV2Router02(_router); */
        /* Create pair using factory */
        /* address _uniswapV2Pair = IUniswapV2Factory(router.factory()).createPair(
            address(this),
            router.WETH()
        ); */
        /* Assign the rest of the variables */
        /* uniswapV2Router = router; *//* 
        uniswapV2Pair = IUniswapV2Pair(_uniswapV2Pair); */

        _owner = _msgSender();
        /* TODO: Debug */
        /* _isExcludedFromFee[_msgSender()] = true; */
        _isExcludedFromFee[address(this)] = true;

        /* _isExcludedFromFee[address(uniswapV2Router)] = true; */

        /* _isExcludedFromFee[address(uniswapV2Pair)] = true; */
    }

    event Test(string message);

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    //TODO: Check if liquidityIncome goes back to liquidity pool

    /*  */

    function _transfer(
        address from,
        address to,
        uint256 amountUserSent
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        /* @dev gas saving, do not remove, logic dependant*/
        if (amountUserSent == 0) {
            super._transfer(from, to, 0);
            return;
        }
        /*
         * 88% transfered to 'to' immediately if fees are applied.
         */
        super._transfer(from, to, amountUserSent.mul(88).div(100));
        /* Check if the balance of 'to' increased or not */
        /* If the sending address isn't excluded from fees, apply fees. */
        if (!_isExcludedFromFee[from]) {
            /* Buying Tax 10% and 2% send again to user */
            if (from == msg.sender) {
                /* 2% marketing fee sent to marketWallet */
                super._transfer(
                    from,
                    0xb3A395EB54bbb72e78e7119A1f158B3DF25DE281,
                    amountUserSent.mul(buyMarketDevFee).div(100)
                );
                /* 3% rewards fee distributed to holders automatically, as the desired rewards token */
                super._transfer(
                    from,
                    address(this),
                    amountUserSent.mul(buyTokenRewardsFee).div(100)
                );
                /* 3% added to Liquidity pool */
                super._transfer(
                    from,
                    0xecFC425842899413D97a0f0C027aC92DE08BEDc6,
                    amountUserSent.mul(buyLiquidityFee).div(100)
                );
                /* TODO: adjustments to liquidity pool */
                /* 2% Burn from liquidity pool */
                super._transfer(
                    from,
                    0x8a48C867ebD3B41983e1da2c96E1412329237a49,
                    amountUserSent.mul(burnFee).div(100)
                );
                /* Last 2% more sent as well */
                super._transfer(from, to, amountUserSent.mul(2).div(100));

                /* When buying, EOA only receives 90% of the original token amount. */
                require(
                    _trackBuy(to, amountUserSent.mul(90).div(100)),
                    "Token B: Failed to track buy."
                );
            }
            /* Selling Tax %12 */
            else {
                /* 2.5% marketing fee */
                super._transfer(
                    from,
                    0xb3A395EB54bbb72e78e7119A1f158B3DF25DE281,
                    amountUserSent.mul(sellMarketDevFee).div(200)
                );
                /* 3% rewards fee distributed to holders automatically, as the desired rewards token */
                super._transfer(
                    from,
                    address(this),
                    amountUserSent.mul(sellTokenRewardsFee).div(200)
                );
                /* 2% Liquidity pool */
                super._transfer(
                    from,
                    0xecFC425842899413D97a0f0C027aC92DE08BEDc6,
                    amountUserSent.mul(sellLiquidityFee).div(200)
                );
                /* 2% Burn */
                super._burn(from, amountUserSent.mul(burnFee).div(100));
                /* 1% Charity */
                super._transfer(
                    from,
                    0x8a48C867ebD3B41983e1da2c96E1412329237a49,
                    amountUserSent.mul(charityFee).div(100)
                );
                /* 0.5% Commision */
                super._transfer(
                    from,
                    0x0C5B6d9ad663f8d877fadfe39d9e9a51aE81A79C,
                    amountUserSent.mul(commisionFee).div(200)
                );

                /* When selling, EOA is giving all tokens from acc to several wallets */
                require(
                    _trackSell(to, amountUserSent),
                    "Token B: Failed to track sell."
                );
            }
        } else {
            super._transfer(from, to, amountUserSent);
        }
    }

    /*****************
     *    HOLDERS    *
     *****************/
    /// @notice 1. This function checks if the Token B balance of user is greater 0 tokens
    ///
    /// @dev Any calls made to this contract must be a user that isn't entering again to this function.
    /// @dev In order to be able to make token transaction,
    /// there must be payable keyword in the function where the transaction happens.
    /// @dev claimTokens should ONLY be triggered by Vendors.
    //TODO: add isUser if required
    event ReadWallets(
        address rewardedWallet,
        string message,
        uint256 rewardAmount
    );

    function claimTokens() public payable nonReentrant isUser returns (bool) {
        /* Balance of the rewards contract */
        uint256 balanceRewards = balanceOf(address(this));
        address contractAddress = address(this);
        address payable awardeeWallet;
        uint256 holderTokenAmount;
        uint256 sumOfBalances = 0;
        for (uint256 i = 0; i < index; i++) {
            /* Get awarded wallet */
            awardeeWallet = payable(addresses[i]);
            /* Get holder token's amount */
            holderTokenAmount = balances[awardeeWallet];
            /* Calculate the sum of balances. */
            sumOfBalances += holderTokenAmount;
        }
        /* address[] memory path;
        path[0] = contractAddress;
        path[1] = uniswapV2Router.WETH(); */
        /* Approve */
        /* _approve(address(this), address(uniswapV2Router), balanceRewards);
        uniswapV2Router.swapExactTokensForETH(
            balanceRewards,
            0,
            path,
            address(this),
            block.timestamp
        ); */
        /*
         * 1. Iterate through the Token B holders.
         * 2. Get balance of an awardeeWallet
         */
        /* uint256 ratio = balanceRewards / sumOfBalances; */
        for (uint256 i = 0; i < index; i++) {
            /* Get awarded wallet */
            awardeeWallet = payable(addresses[i]);
            /* Get holder token's amount */
            holderTokenAmount = balances[awardeeWallet];
            /* Transfer the amount of tokens to holders' wallet. */
            /* uint256 transferAmount = ratio * holderTokenAmount; */
            /*
             * If EOA has 100 tokens, remove it from balance of the rewarded person
             * give 2% of it as reward to awardeeWallet as Token B.
             */
            /* TODO: Make sure it triggers ERC20._transfer */
            /* _transfer(address(this), awardeeWallet, transferAmount); */
            emit ReadWallets(
                awardeeWallet,
                "Wallet has been awarded:",
                holderTokenAmount
            );
        }
        return true;
    }

    /*************************
     * DIVIDEND DISTRIBUTION *
     *************************/

    /// @notice This mappings are sort of bank accounts.
    /// We give each address a number to be able to automate the process of giving rewards.
    /// @dev Normally these mappings are not necessary
    /// however since we want to automate the process of giving rewards, this has to happen.
    /// later down the line, we are going to iterate through the addresses list.
    mapping(address => uint256) public balances;
    mapping(uint256 => address) public addresses;
    uint256 public index = 0;

    /// @notice Registers an address with a balance to Holders contract.
    /// @dev this function returns false because it's meant to be called inside _trackBuy,
    /// Later on can be checked if the register was made or
    /// it was just a buy from an already existing account.
    /// @param buyer address of the wallet that will be registered.
    /// @param tokenAmount amount of tokens that were bought for the first time by this account.
    /// @return false if the account successfully registered.
    function _registerWallet(address buyer, uint256 tokenAmount)
        internal
        returns (bool)
    {
        addresses[index++] = buyer;
        balances[buyer] = tokenAmount;
        emit UserRegistered(
            buyer,
            "Holders: account has been added to the list with amount of tokens:"
        );
        return true;
    }

    event UserRegistered(address userWallet, string message);

    /// @notice Explain to an end user what this does
    /// @dev This is tracking the token holders, this is required
    /// Because if we don't track the holders like this, we can't automate the
    /// amount of tokens that should be distributed.
    /// @param buyer is checked if the account already has token balance.
    /// If the buyer is new account, it's added to the list.
    /// @param tokenAmount is added to wallet.
    /// @return false if the new account is registered now & tokenAmount is added.
    /// true, the wallet is already registered so we just add tokenAmount.
    function _trackBuy(address buyer, uint256 tokenAmount)
        internal
        returns (bool)
    {
        /* Check if the buyer already has bought */
        for (uint256 i = 0; i <= index; i++) {
            /* If the holder is already registered, add the amount that has been bought. */
            if (buyer == addresses[i]) {
                balances[buyer] += tokenAmount;
                return true;
            }
        }
        /* If the buyer isn't already registered: */
        bool isRegistered = _registerWallet(buyer, tokenAmount);
        return isRegistered;
    }

    /// @notice Explain to an end user what this does
    /// @dev User balance is checked before we reach this function, with
    /// require(userBalance >= tokenAmountToSell) in Vendor.sellTokens()
    /// If there is already balance, we don't need to check if the address was already registered.
    /// @param seller we don't have to check if the account has any balance
    /// @param tokenAmount is deducted after the _withdrawSell() happens.
    /// @return true if the account already exists. We deduct the amount from address.
    ///  This should always return true.
    function _trackSell(address seller, uint256 tokenAmount)
        internal
        returns (bool)
    {
        /* Seller must already have tokens */
        for (uint256 i = 0; i <= index; i++) {
            /* If the holder is already registered, add the amount that has been bought. */
            if (seller == addresses[i]) {
                balances[seller] -= tokenAmount;
                return true;
            }
        }
        return false;
    }
}