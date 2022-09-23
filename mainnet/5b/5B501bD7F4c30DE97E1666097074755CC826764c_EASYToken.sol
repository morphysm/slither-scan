/**
 *Submitted for verification at snowtrace.io on 2022-04-29
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

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

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
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
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function migrator() external view returns (address);

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;

    function setMigrator(address) external;
}

interface IJoePair {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to)
        external
        returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

/*
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

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}

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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

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
        // Gas optimization: this is TKNaper than requiring 'a' not being zero, but the
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
     * `revert` opcode (which leaves remaining gas untouTKNd) while Solidity
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
     * `revert` opcode (which leaves remaining gas untouTKNd) while Solidity
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
     * opcode (which leaves remaining gas untouTKNd) while Solidity uses an
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
     * opcode (which leaves remaining gas untouTKNd) while Solidity uses an
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

contract ERC20 is Context, IERC20, IERC20Metadata {
    using SafeMath for uint256;

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
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
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
    function balanceOf(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
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
    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].add(addedValue)
        );
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
    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(
                subtractedValue,
                "ERC20: decreased allowance below zero"
            )
        );
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(
            amount,
            "ERC20: transfer amount exceeds balance"
        );
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
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

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
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

        _balances[account] = _balances[account].sub(
            amount,
            "ERC20: burn amount exceeds balance"
        );
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
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
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
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
}

contract Ownable is Context {
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
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface ITestToken {
    function mint(address account, uint256 amount) external;

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function totalSupply() external view returns (uint256);
}

contract NODERewardManagement is Ownable {
    using SafeMath for uint256;

    struct NodeEntity {
        uint256 ID;
        uint256 creationTime;
        uint256 lastClaimedTime;
        uint256 tokenValue;
        uint256 rewardAvailable;
    }

    address[] public nodeOwners;
    mapping(address => NodeEntity[]) public _nodesOfUser;

    // // real : 60 * 60 * 24, test : 60 * 3
    uint256 public DetaforDay = 60 * 60 * 24;

    address public token;

    uint256 public totalNodesCreated = 0;
    uint256 public maximumTotalNodes = 1000000000;
    uint256 public nodePrice = 10 * (10**18);
    uint256 public taxRate = 100;
    uint256 public rewardRate = 50;

    bool public createNodeFlag = false;

    constructor(address _token) {
        token = _token;
    }

    modifier onlySentry() {
        require(msg.sender == token, "Fuck off");
        _;
    }

    function uint2str(uint256 _i)
        internal
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

    function isNodeOwner(address account) private view returns (bool) {
        return _nodesOfUser[account].length > 0;
    }

    function _isNodeOwner(address account) external view returns (bool) {
        return _nodesOfUser[account].length > 0;
    }

    function _getNodeNumberOf(address account) public view returns (uint256) {
        return _nodesOfUser[account].length;
    }

    function setToken(address _token) external onlyOwner {
        require(_token != address(0), "Token CANNOT BE ZERO");
        token = _token;
    }

    function setMaximumTotalNodes(uint256 _maximumTotalNodes)
        external
        onlyOwner
    {
        maximumTotalNodes = _maximumTotalNodes;
    }

    function setTaxRate(uint256 _taxRate) external onlyOwner {
        taxRate = _taxRate;
    }

    function setDetaforDay(uint256 _DetaforDay) external onlyOwner {
        require(_DetaforDay != 0, "Deta for day CANNOT BE ZERO");
        DetaforDay = _DetaforDay;
    }

    function setRewardRate(uint256 _rewardRate) external onlyOwner {
        require(_rewardRate > 0, "Reward rate CANNOT BE ZERO");
        rewardRate = _rewardRate;
    }

    function _changeNodePrice(uint256 _nodePrice) external onlySentry {
        require(nodePrice != 0, "Node price CANNOT BE ZERO");
        nodePrice = _nodePrice;
    }

    function _upgradeRewardOfNode(address account, uint256 ID)
        external
        onlySentry
    {
        require(isNodeOwner(account), "GET REWARD OF: NO NODE OWNER");

        NodeEntity storage node = _nodesOfUser[account][ID];
        node.tokenValue += node.rewardAvailable;
        node.rewardAvailable = 0;
        node.lastClaimedTime = block.timestamp;
    }

    function createNode(address account) external onlySentry {
        require(
            totalNodesCreated < maximumTotalNodes,
            "Amount of node was limited"
        );
        require(!createNodeFlag, "Creating NODE by other");

        createNodeFlag = true;

        _nodesOfUser[account].push(
            NodeEntity({
                ID: totalNodesCreated,
                creationTime: block.timestamp,
                lastClaimedTime: block.timestamp,
                tokenValue: nodePrice,
                rewardAvailable: 0
            })
        );
        nodeOwners.push(account);
        totalNodesCreated++;

        createNodeFlag = false;
    }

    function _getRewardAmountOf(address account)
        external
        view
        returns (uint256)
    {
        if (isNodeOwner(account) == false) {
            return 0;
        }
        uint256 nodesCount;
        uint256 rewardCount = 0;

        NodeEntity[] storage nodes = _nodesOfUser[account];
        nodesCount = nodes.length;

        for (uint256 i = 0; i < nodesCount; i++) {
            rewardCount += (nodes[i].rewardAvailable +
                ((block.timestamp - nodes[i].lastClaimedTime) *
                    nodes[i].tokenValue *
                    rewardRate) /
                (1000 * DetaforDay));
        }

        return rewardCount;
    }

    function _getRewardAmountOfAsWeek(address account)
        external
        view
        returns (uint256)
    {
        if (isNodeOwner(account) == false) {
            return 0;
        }
        uint256 nodesCount;
        uint256 rewardCount = 0;
        uint256 temp = 0;

        NodeEntity[] storage nodes = _nodesOfUser[account];
        nodesCount = nodes.length;

        for (uint256 i = 0; i < nodesCount; i++) {
            temp =
                ((nodes[i].rewardAvailable +
                    ((block.timestamp - nodes[i].lastClaimedTime) *
                        nodes[i].tokenValue *
                        rewardRate) /
                    (1000 * DetaforDay)) * taxRate) /
                100;
            rewardCount += temp;
        }

        return rewardCount;
    }

    function _getRewardOfNode(address account, uint256 ID)
        external
        view
        returns (uint256)
    {
        if (isNodeOwner(account) == false) {
            return 0;
        }
        uint256 rewardOfNode = 0;

        NodeEntity storage node = _nodesOfUser[account][ID];

        rewardOfNode = (node.rewardAvailable +
            ((block.timestamp - node.lastClaimedTime) *
                node.tokenValue *
                rewardRate) /
            (1000 * DetaforDay));

        return rewardOfNode;
    }

    function _getRewardOfNodeAsWeek(address account, uint256 ID)
        external
        view
        returns (uint256)
    {
        if (isNodeOwner(account) == false) {
            return 0;
        }
        uint256 rewardOfNode = 0;

        NodeEntity storage node = _nodesOfUser[account][ID];

        rewardOfNode =
            ((node.rewardAvailable +
                ((block.timestamp - node.lastClaimedTime) *
                    node.tokenValue *
                    rewardRate) /
                (1000 * DetaforDay)) * taxRate) /
            100;

        return rewardOfNode;
    }

    function _cashoutNodeReward(address account, uint256 ID)
        external
        onlySentry
    {
        require(
            account != address(0),
            "NODE: CREATIME must be higher than zero"
        );
        NodeEntity storage node = _nodesOfUser[account][ID];
        node.rewardAvailable = 0;
        node.lastClaimedTime = block.timestamp;
    }

    function _cashoutAllNodesReward(address account) external onlySentry {
        NodeEntity[] storage nodes = _nodesOfUser[account];
        uint256 nodesCount = nodes.length;
        require(nodesCount > 0, "NODE: CREATIME must be higher than zero");
        NodeEntity storage _node;
        for (uint256 i = 0; i < nodesCount; i++) {
            _node = nodes[i];
            _node.lastClaimedTime = block.timestamp;
            _node.rewardAvailable = 0;
        }
    }

    function _updateRewardOfNode(address account) public onlySentry {
        if (!isNodeOwner(account)) {
            return;
        }
        NodeEntity[] storage nodes = _nodesOfUser[account];
        uint256 nodesCount = nodes.length;
        NodeEntity storage _node;
        for (uint256 i = 0; i < nodesCount; i++) {
            _node = nodes[i];
            _node.rewardAvailable =
                nodes[i].rewardAvailable +
                ((block.timestamp - nodes[i].lastClaimedTime) *
                    nodes[i].tokenValue *
                    rewardRate) /
                (1000 * DetaforDay);
            _node.lastClaimedTime = block.timestamp;
        }
    }

    function _updateRewardOfOneNode(address account, uint256 ID)
        public
        onlySentry
    {
        if (!isNodeOwner(account)) {
            return;
        }
        NodeEntity storage _node = _nodesOfUser[account][ID];
        _node.rewardAvailable =
            _node.rewardAvailable +
            ((block.timestamp - _node.lastClaimedTime) *
                _node.tokenValue *
                rewardRate) /
            (1000 * DetaforDay);
        _node.lastClaimedTime = block.timestamp;
    }

    function _updateRewardOfAllNodes() public onlySentry {
        uint256 numberOfNodeOwners = nodeOwners.length;
        NodeEntity[] storage nodes;
        NodeEntity storage _node;
        uint256 nodesCount;
        uint256 index;
        if (numberOfNodeOwners > 0) {
            while (index < numberOfNodeOwners) {
                nodes = _nodesOfUser[nodeOwners[index]];
                index++;
                nodesCount = nodes.length;
                for (uint256 i = 0; i < nodesCount; i++) {
                    _node = nodes[i];
                    _node.rewardAvailable =
                        _node.rewardAvailable +
                        ((block.timestamp - _node.lastClaimedTime) *
                            _node.tokenValue *
                            rewardRate) /
                        (1000 * DetaforDay);
                    _node.lastClaimedTime = block.timestamp;
                }
            }
        }
    }
}

contract EASYToken is ERC20, Ownable {
    using SafeMath for uint256;

    NODERewardManagement public nodeRewardManager;

    IJoeRouter02 public joeV2Router;

    address public joeV2Pair;
    address public treasuryAddress;
    address public teamAddress;

    uint256 maxNodeNumberOf = 100;

    uint256 public rewardPoolRate = 70;
    uint256 public teamRate = 10;
    uint256 public liquidityRate = 10;
    uint256 public treasuryRate = 10;

    bool public tokenLock;

    uint256 public initialSetting;
    mapping(address => bool) public whiteList;

    bool isStart = false;
    bool distribution = false;

    address public deadWallet = 0x000000000000000000000000000000000000dEaD;

    mapping(address => bool) public _isBlacklisted;
    mapping(address => bool) public automatedMarketMakerPairs;

    modifier onlyStarted() {
        require(isStart, "Not Start");
        _;
    }

    modifier whenDistribution() {
        require(!distribution, "Distributing now!");
        _;
    }

    event UpdatejoeV2Router(
        address indexed newAddress,
        address indexed oldAddress
    );

    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );

    constructor(address uniV2Router) ERC20("EasyNodes", "EASY") {
        require(uniV2Router != address(0), "ROUTER CANNOT BE ZERO");
        IJoeRouter02 _joeV2Router = IJoeRouter02(uniV2Router);

        address _joeV2Pair = IJoeFactory(_joeV2Router.factory()).createPair(
            address(this),
            _joeV2Router.WAVAX()
        );

        joeV2Router = _joeV2Router;
        joeV2Pair = _joeV2Pair;

        _setAutomatedMarketMakerPair(_joeV2Pair, true);
    }

    receive() external payable {}

    function setTreasury(address _treasuryAddress) external onlyOwner {
        require(_treasuryAddress != address(0), "Treasury CANNOT BE ZERO");
        treasuryAddress = _treasuryAddress;
    }

    function setTeam(address _teamAddress) external onlyOwner {
        require(_teamAddress != address(0), "Team CANNOT BE ZERO");
        teamAddress = _teamAddress;
    }

    function setNodeManagement(address payable _nodeManagement)
        external
        onlyOwner
    {
        require(_nodeManagement != address(0), "Manager CANNOT BE ZERO");
        nodeRewardManager = NODERewardManagement(_nodeManagement);
    }

    function setRewardPoolRate(uint256 _rewardPoolRate) external onlyOwner {
        rewardPoolRate = _rewardPoolRate;
    }

    function setMaxNodeNumberOf(uint256 _maxNodeNumberOf) external onlyOwner {
        maxNodeNumberOf = _maxNodeNumberOf;
    }

    function setTeamRate(uint256 _teamRate) external onlyOwner {
        teamRate = _teamRate;
    }

    function setLiquidityRate(uint256 _liquidityRate) external onlyOwner {
        liquidityRate = _liquidityRate;
    }

    function setTreasuryRate(uint256 _treasuryRate) external onlyOwner {
        treasuryRate = _treasuryRate;
    }

    function updatejoeV2Router(address newAddress) public onlyOwner {
        require(
            newAddress != address(joeV2Router),
            "TKN: The router already has that address"
        );
        emit UpdatejoeV2Router(newAddress, address(joeV2Router));
        joeV2Router = IJoeRouter02(newAddress);
        address _joeV2Pair = IJoeFactory(joeV2Router.factory()).createPair(
            address(this),
            joeV2Router.WAVAX()
        );
        joeV2Pair = _joeV2Pair;
    }

    function setAutomatedMarketMakerPair(address pair, bool value)
        public
        onlyOwner
    {
        require(
            pair != joeV2Pair,
            "TKN: The PancakeSwap pair cannot be removed from automatedMarketMakerPairs"
        );

        _setAutomatedMarketMakerPair(pair, value);
    }

    function blacklistMalicious(address account, bool value)
        external
        onlyOwner
    {
        _isBlacklisted[account] = value;
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        require(
            automatedMarketMakerPairs[pair] != value,
            "TKN: Automated market maker pair is already set to that value"
        );
        automatedMarketMakerPairs[pair] = value;

        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(
            !tokenLock || whiteList[from] || whiteList[to],
            "ERC20: lock now"
        );
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(
            !_isBlacklisted[from] && !_isBlacklisted[to],
            "Blacklisted address"
        );

        super._transfer(from, to, amount);
    }

    function setTokenLock() public onlyOwner {
        require(initialSetting == 0, "Can't lock forever!");
        tokenLock = !tokenLock;
    }

    function setWhiteList(address account) public onlyOwner {
        whiteList[account] = !whiteList[account];
    }

    function setUnlockForever() public onlyOwner {
        initialSetting += 1;
    }

    function swapAndLiquify(uint256 tokens, address account) private {
        uint256 half = tokens.div(2);
        uint256 otherHalf = tokens.sub(half);

        uint256 initialBalance = address(this).balance;

        swapTokensForAvax(half);

        uint256 newBalance = address(this).balance.sub(initialBalance);

        addLiquidity(otherHalf, newBalance, account);

        emit SwapAndLiquify(half, newBalance, otherHalf);
    }

    function swapTokensForAvax(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = joeV2Router.WAVAX();

        super._approve(
            address(this),
            address(joeV2Router),
            tokenAmount + 10000
        );

        joeV2Router.swapExactTokensForAVAXSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(
        uint256 tokenAmount,
        uint256 ethAmount,
        address _to
    )
        private
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(joeV2Router), tokenAmount);

        // add the liquidity
        return
            joeV2Router.addLiquidityAVAX{value: ethAmount}(
                address(this),
                tokenAmount,
                0, // slippage is unavoidable
                0, // slippage is unavoidable
                _to,
                block.timestamp
            );
    }

    function createNodeWithTokens() public onlyStarted whenDistribution {
        address sender = _msgSender();
        require(
            sender != address(0),
            "NODE CREATION:  creation from the zero address"
        );

        require(!_isBlacklisted[sender], "NODE CREATION: Blacklisted address");

        require(
            getNodeNumberOf(sender) <= maxNodeNumberOf,
            "NODE CREATION: Your node maxium was limited"
        );

        uint256 nodePrice = nodeRewardManager.nodePrice();
        require(
            balanceOf(sender) >= nodePrice,
            "NODE CREATION: Balance too low for creation."
        );

        uint256 balanceOfRewardPool = nodePrice.mul(rewardPoolRate).div(100);
        uint256 balanceOfTeam = nodePrice.mul(teamRate).div(100);
        uint256 balanceOfTreasury = nodePrice.mul(treasuryRate).div(100);
        uint256 balanceOfLiquidity = nodePrice
            .sub(balanceOfTeam)
            .sub(balanceOfTreasury)
            .sub(balanceOfRewardPool);

        super._transfer(sender, address(this), nodePrice);

        swapAndSendToFee(teamAddress, balanceOfTeam);
        swapAndSendToFee(treasuryAddress, balanceOfTreasury);
        swapAndLiquify(balanceOfLiquidity, sender);

        nodeRewardManager.createNode(sender);
    }

    function createNodeWithFree(address account)
        public
        onlyStarted
        onlyOwner
        whenDistribution
    {
        require(
            account != address(0),
            "NODE CREATION:  creation from the zero address"
        );

        require(!_isBlacklisted[account], "NODE CREATION: Blacklisted address");

        require(
            getNodeNumberOf(account) <= maxNodeNumberOf,
            "NODE CREATION: Your node maxium was limited"
        );

        nodeRewardManager.createNode(account);
    }

    function swapAndSendToFee(address destination, uint256 tokens) private {
        uint256 initialETHBalance = address(this).balance;
        swapTokensForAvax(tokens);
        uint256 newBalance = (address(this).balance).sub(initialETHBalance);
        payable(destination).transfer(newBalance);
    }

    function upgradeRewardOfNode(uint256 ID) public whenDistribution {
        address sender = _msgSender();
        updateRewardOfOneNode(sender, ID);
        require(getNodeNumberOf(sender) > 0, "UPDATE : NO NODE OWNER");
        nodeRewardManager._upgradeRewardOfNode(sender, ID);
    }

    function cashoutAll() public whenDistribution {
        address sender = _msgSender();
        require(
            sender != address(0),
            "MANIA CSHT:  creation from the zero address"
        );
        require(!_isBlacklisted[sender], "MANIA CSHT: Blacklisted address");

        updateRewardOfNodes(sender);

        uint256 rewardAmount = nodeRewardManager._getRewardAmountOfAsWeek(
            sender
        );

        require(
            rewardAmount > 0,
            "MANIA CSHT: You don't have enough reward to cash out"
        );

        uint256 balanceOfThis = balanceOf(address(this));

        if (balanceOfThis < rewardAmount) {
            rewardAmount = balanceOfThis;
        }
        super._transfer(address(this), sender, rewardAmount);

        nodeRewardManager._cashoutAllNodesReward(sender);
    }

    function cashoutNodeReward(uint256 ID) public whenDistribution {
        address sender = _msgSender();
        require(
            sender != address(0),
            "MANIA CSHT:  creation from the zero address"
        );
        require(!_isBlacklisted[sender], "MANIA CSHT: Blacklisted address");
        updateRewardOfOneNode(sender, ID);
        uint256 rewardAmount = nodeRewardManager._getRewardOfNodeAsWeek(
            sender,
            ID
        );

        require(
            rewardAmount > 0,
            "MANIA CSHT: You don't have enough reward to cash out"
        );

        uint256 balanceOfThis = balanceOf(address(this));

        if (balanceOfThis < rewardAmount) {
            rewardAmount = balanceOfThis;
        }
        super._transfer(address(this), sender, rewardAmount);

        nodeRewardManager._cashoutNodeReward(sender, ID);
    }

    function getNodeNumberOf(address account) public view returns (uint256) {
        return nodeRewardManager._getNodeNumberOf(account);
    }

    function getRewardTotalAmount() public view returns (uint256) {
        require(_msgSender() != address(0), "SENDER CAN'T BE ZERO");
        require(nodeRewardManager._isNodeOwner(_msgSender()), "NO NODE OWNER");
        return nodeRewardManager._getRewardAmountOf(_msgSender());
    }

    function changeNodePrice(uint256 newNodePrice) public onlyOwner {
        nodeRewardManager._changeNodePrice(newNodePrice);
    }

    function getNodePrice() public view returns (uint256) {
        return nodeRewardManager.nodePrice();
    }

    function getTotalCreatedNodes() public view returns (uint256) {
        return nodeRewardManager.totalNodesCreated();
    }

    function mint(address account, uint256 amount) public onlyOwner {
        _mint(account, amount);
    }

    function start() public onlyOwner {
        isStart = true;
    }

    function updateRewardOfNodes(address account) private whenDistribution {
        nodeRewardManager._updateRewardOfNode(account);
    }

    function updateRewardOfOneNode(address account, uint256 ID)
        private
        whenDistribution
    {
        nodeRewardManager._updateRewardOfOneNode(account, ID);
    }

    function updateRewardOfAllNodes() public onlyOwner {
        distribution = true;
        nodeRewardManager._updateRewardOfAllNodes();
        distribution = false;
    }

    function withdraw(uint256 tokenAmount) public onlyOwner {
        require(
            tokenAmount < balanceOf(address(this)),
            "Amount of token is more than liquidity"
        );
        super._transfer(address(this), msg.sender, tokenAmount);
    }
}