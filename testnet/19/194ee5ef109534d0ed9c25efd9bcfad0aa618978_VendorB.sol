/**
 *Submitted for verification at testnet.snowtrace.io on 2022-05-08
*/

// File: contracts/TestPayable.sol


pragma solidity ^0.8.0;

contract TestPayable {
    uint256 abc;
    uint256 def;

    // This function is called for all messages sent to
    // this contract, except plain Ether transfers
    // (there is no other function except the receive function).
    // Any call with non-empty calldata to this contract will execute
    // the fallback function (even if Ether is sent along with the call).
    fallback() external payable {
        abc = 1;
        def = msg.value;
    }

    // This function is called for plain Ether transfers, i.e.
    // for every call with empty calldata.
    receive() external payable {
        abc = 2;
        def = msg.value;
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

// File: contracts/TAGEN.sol

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
//https://stermi.medium.com/how-to-create-an-erc20-token-and-a-solidity-vendor-contract-to-sell-buy-your-own-token-8882808dd905



contract TAGEN is ERC20, ERC20Burnable {
    uint256 public constant AMOUNT_OF_TOKEN = 10000 * 10**18;

    constructor() ERC20("123", "123") {
        _mint(_msgSender(), AMOUNT_OF_TOKEN);
    }
}

// File: contracts/TBGEN.sol



pragma solidity ^0.8.0;



contract TBGEN is ERC20, ERC20Burnable {
    uint256 public constant AMOUNT_OF_TOKEN = 10000 * 10**18;

    constructor() ERC20("456", "456") {
        _mint(_msgSender(), AMOUNT_OF_TOKEN);
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

// File: contracts/VendorA.sol


//^0.8.4;
pragma solidity ^0.8.0;

/* Set a price for our token (1 BNB = 100 Token)
Implement a payable buyToken() function. To transfer tokens look at the transfer() function exposed by the OpenZeppelin ERC20 implementation.
Emit a BuyTokens event that will log who’s the buyer, the amount of BNB sent and the amount of Token bought
Transfer all the Tokens to the Vendor contract at deployment time
Transfer the ownership of the Vendor contract (at deploy time) to our frontend address (you can see it on the top right of your web app) to withdraw the BNB in the balance */





//TODO: Implement safeERC20 Library https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/utils/SafeERC20.sol
///@notice safeERC20 Library is a library that allows us to safely make calls between addresses.
///@dev ERC20->Approve function is deprecated. This function has issues similar to the ones found in
/// {IERC20-approve}, and its usage is discouraged.
///
contract VendorA is ReentrancyGuard, Ownable, TestPayable {
    /// @notice These are the wallets that Genesis Group GEN (LTD) will use.
    /// @dev These wallets :
    /// 1. Can't be changed once they are constructed.
    /// 2. Are user wallets(?)
    /* CAN BE CHANGED */
    address public constant rewardsWallet =
        0xab0404fa605f0e3D437D7fdbB92D80717cAC6aF6;
    address public constant marketDevWallet =
        0x8a48C867ebD3B41983e1da2c96E1412329237a49;
    address public constant liquidityWallet =
        0x8a48C867ebD3B41983e1da2c96E1412329237a49;
    address public constant commisionWallet =
        0xecFC425842899413D97a0f0C027aC92DE08BEDc6;
    address public constant charityWallet =
        0x8a48C867ebD3B41983e1da2c96E1412329237a49;
    /* CAN BE CHANGED */
    address public constant burnWallet = address(0);
    // Token Contract
    TAGEN tokenAA;
    address VendorBAddress;
    uint8 flagVendor = 0;
    // Token price for BNB
    // 0.000001 ether
    uint256 public tokensPerBNB = 10 wei;

    // This event will print out buying tokens
    event BuyTokens(address buyer, uint256 amountOfBNB, uint256 amountOfTokens);

    constructor(address tokenAddress) {
        transferOwnership(msg.sender);
        tokenAA = TAGEN(tokenAddress);
    }

    /// @notice this is added to a function like an add-on, an extension,
    /// once it's added to a function it checks if the user that is accessing the function is indeed a real user.
    /// @dev In blockchains, msg.sender is ONLY equal to tx.origin if a real user, a person's crypto wallet, is accessing the contract.
    modifier isUser() {
        require(
            msg.sender == tx.origin,
            "Vendor: This function is only accessed by real users."
        );
        _;
    }

    /// @notice Allows users to buy token for BNB.
    /// @dev This function can be accessed outside of contract, this function can not be re-entered while being executed, this function can't be accessed by other contracts.

    function buyTokens() public payable isUser returns (uint256 tokenAmount) {
        require(msg.value > 0, "Vendor: Send BNB to buy some tokens");
        /* TODO: I've changed division and multiplication from buy & sell, that looks flaw-ish */
        uint256 amountToBuy = msg.value / tokensPerBNB;

        //Checking if the Vendor Contract has enough amount of tokens for the transaction.
        uint256 vendorBalance = tokenAA.balanceOf(address(this));
        require(
            vendorBalance >= amountToBuy,
            "Vendor: Contract does not have enough tokens in its balance."
        );

        // Transfer token to the msg.sender

        bool sent = tokenAA.transfer(msg.sender, amountToBuy);
        require(sent, "Vendor: Failed to transfer token to user.");

        emit BuyTokens(msg.sender, msg.value, amountToBuy);
        _withdrawBuy();
        return amountToBuy;
    }

    /**
     * @notice Allow users to sell tokens for BNB
     * 1. send tokens to contract
     * 2.
     */
    function sellTokens(uint256 tokenAmountToSell) public payable isUser {
        // Check that the requested amount of tokens to sell is more than 0
        require(
            tokenAmountToSell > 0,
            "Specify an amount of token greater than zero"
        );

        // Check that the user's token balance is enough to do the swap
        uint256 userBalance = tokenAA.balanceOf(msg.sender);
        require(
            userBalance >= tokenAmountToSell,
            "Your balance is lower than the amount of tokens you want to sell"
        );

        // Check that the Vendor's balance is enough to do the swap
        uint256 amountOfBNBToTransfer = tokenAmountToSell * tokensPerBNB;
        uint256 contractBNBBalance = address(this).balance;
        require(
            contractBNBBalance >= amountOfBNBToTransfer,
            "Vendor has not enough funds to accept the sell request"
        );

        bool sent = tokenAA.transferFrom(
            msg.sender,
            address(this),
            tokenAmountToSell
        );
        require(sent, "Failed to transfer tokens from user to vendor");
        _withdrawSell(); /* 
        (sent, ) = msg.sender.call{value: amountOfBNBToTransfer}("");
        require(sent, "Failed to send BNB to the user"); */
    }

    /**
     * @notice Allow the owner of the contract to withdraw BNB
     * @dev TODO: This is a debug functin that will be removed before production.
     */
    function withdraw(address wallet, uint256 amount) private {
        require(amount > 0, "Vendor-withdraw: Not enough to withdraw.");
        (bool success, ) = wallet.call{value: amount}("");
        require(success, "Vendor: Transfer failed.");
    }

    /// @notice This function is used to distribute the income through several wallets
    /// 1.
    /// @dev This function can not be called from outside,
    /// This includes owner of the contract or any party that is involved in the development of this process.
    ///TODO: withdraw might require onlyOwner
    function _withdrawBuy() internal {
        uint256 fullBalance = address(this).balance;
        require(
            fullBalance > 0,
            "Vendor: Contract does not have balance to withdraw."
        );

        /* 1. Rewards wallet %3 */
        withdraw(rewardsWallet, (fullBalance * 3) / 100);

        /* 2. Liquidity Wallet %3 */
        withdraw(liquidityWallet, (fullBalance * 3) / 100);

        /* 3. Burn of Genesis Token (A) Token, %1.5 */
        withdraw(address(0), (fullBalance * 3) / 200);

        /* 4. Market & Dev wallet, %2.5 5/200 is 2.5/100 */
        withdraw(marketDevWallet, (fullBalance * 2) / 100);

        /* 5. Contract wallet %90 */
        withdraw(address(this), (fullBalance * 90) / 100);
    }

    /// @notice This function is used to distribute the income through several wallets
    /// 1.
    /// @dev This function can not be called from outside,
    ///TODO: withdraw might require onlyOwner
    function _withdrawSell() internal {
        uint256 fullBalance = address(this).balance;
        require(
            fullBalance > 0,
            "Vendor: Contract does not have balance to withdraw."
        );
        /* 1. Rewards wallet %4 */
        withdraw(rewardsWallet, (fullBalance * 4) / 100);

        /* 2. Liquidity Wallet %2 */
        withdraw(liquidityWallet, (fullBalance * 2) / 100);

        /* 3. Burn of token A %2 */
        withdraw(address(0), (fullBalance * 2) / 100);

        /* 4. Market & Dev wallet, %2.5 5/200 is 2.5/100 */
        withdraw(marketDevWallet, (fullBalance * 5) / 200);

        /* 5. Charity wallet, %1 */
        withdraw(charityWallet, (fullBalance * 1) / 100);

        /* 6. Commision Wallet %0.5 is 1/200 */
        withdraw(commisionWallet, (fullBalance * 1) / 200);
        /* 7. User wallet %88 */
        withdraw(_msgSender(), (fullBalance * 88) / 100);
    }

    modifier onlyVendorB(address sender) {
        require(
            sender == VendorBAddress,
            "VendorA: Only Vendor B can call this function."
        );
        _;
    }

    function setVendorBAddress(address vendorBaddress) public onlyOwner {
        require(
            vendorBaddress != address(0),
            "VendorA: VendorB address can't be 0."
        );
        require(
            flagVendor == 0,
            "VendorA: Vendor B can only be assigned once."
        );
        flagVendor = 1;
        VendorBAddress = vendorBaddress;
    }

    function burnToken(uint256 dividend, uint256 divisor)
        external
        onlyVendorB(msg.sender)
    {
        uint256 amount = tokenAA.balanceOf(msg.sender);
        uint256 amountToBeBurned = (amount * dividend) / divisor;
        tokenAA.burnFrom(msg.sender, amountToBeBurned);
    }

    /// @notice This function is used to burn a token. In this instance Token A
    /// @dev This function accepts param as Wei not Eth, see https://eth-converter.com/
    /// Only vendor b should be able to access this.
    /// @param amount is the amount that will be burned from the previously declared token.
    function burnToken(uint256 amount) external onlyVendorB(msg.sender) {
        tokenAA.burnFrom(msg.sender, amount);
    }
}

// File: contracts/VendorB.sol



pragma solidity ^0.8.0;






/// @title Vendor B
/// @author Genesis Group GEN (LTD)
/// @notice VendorB contract handles Token B's tokenomics.
/// @dev Explain to a developer any extra details
contract VendorB is ReentrancyGuard, Ownable, TestPayable {
    /// @notice These are the wallets that Genesis Group GEN (LTD) will use.
    /// @dev These wallets :
    /// 1. Can't be changed once they are constructed.
    /// 2. Are user wallets(?)
    /* CAN BE CHANGED */
    address public constant rewardsWallet =
        0xab0404fa605f0e3D437D7fdbB92D80717cAC6aF6;
    address public constant marketDevWallet =
        0x8a48C867ebD3B41983e1da2c96E1412329237a49;
    address public constant liquidityWallet =
        0x8a48C867ebD3B41983e1da2c96E1412329237a49;
    address public constant commisionWallet =
        0xecFC425842899413D97a0f0C027aC92DE08BEDc6;
    address public constant charityWallet =
        0x8a48C867ebD3B41983e1da2c96E1412329237a49;
    /* CAN BE CHANGED */
    address public constant burnWallet = address(0);

    uint256 public tokensPerBNB = 1 wei;

    /* These are the declarations for tokenB and vendorA */
    TBGEN tokenB;
    VendorA vendorA;
    // Token price for BNB
    // 0.000001 ether
    // This event will print out buying tokens
    event BuyTokens(address buyer, uint256 amountOfBNB, uint256 amountOfTokens);

    constructor(address tokenAddress, address payable _vendorA) {
        //Get tokenB from an address on a blockchain mainnet/testnet.
        tokenB = TBGEN(tokenAddress);
        vendorA = VendorA(_vendorA);
    }

    /// @notice this is added to a function like an add-on, an extension,
    /// once it's added to a function it checks if the user that is accessing the function is indeed a real user.
    /// @dev In blockchains, msg.sender is ONLY equal to tx.origin if a real user, a person's crypto wallet, is accessing the contract.
    modifier isUser() {
        require(
            msg.sender == tx.origin,
            "Vendor: This function is only accessed by real users."
        );
        _;
    }

    /// @notice Allows users to buy token for BNB.
    /// @dev This function can be accessed outside of contract, this function can not be re-entered while being executed, this function can't be accessed by other contracts.

    function buyTokens() public payable isUser returns (uint256 tokenAmount) {
        /* Check if the user sent any BNB to the function */
        require(msg.value > 0, "Vendor: Send BNB to buy some tokens");
        uint256 amountToBuy = msg.value * tokensPerBNB;

        /* Checking if the Vendor Contract has enough amount of tokens for the transaction. */
        uint256 vendorBalance = tokenB.balanceOf(address(this));
        require(
            vendorBalance >= amountToBuy,
            "Vendor: Contract does not have enough tokens in its balance."
        );

        // Transfer token to the msg.sender

        bool sent = tokenB.transfer(msg.sender, amountToBuy);
        require(sent, "Vendor: Failed to transfer token to user.");

        emit BuyTokens(msg.sender, msg.value, amountToBuy);
        _withdrawBuy();
        return amountToBuy;
    }

    /**
     * @notice Allow users to sell tokens for BNB
     */
    function sellTokens(uint256 tokenAmountToSell) public payable isUser {
        // Check that the requested amount of tokens to sell is more than 0
        require(
            tokenAmountToSell > 0,
            "Specify an amount of token greater than zero"
        );

        // Check that the user's token balance is enough to do the swap
        uint256 userBalance = tokenB.balanceOf(msg.sender);
        require(
            userBalance >= tokenAmountToSell,
            "Your balance is lower than the amount of tokens you want to sell"
        );

        // Check that the Vendor's balance is enough to do the swap
        uint256 amountOfBNBToTransfer = tokenAmountToSell / tokensPerBNB;
        uint256 contractBNBBalance = address(this).balance;
        require(
            contractBNBBalance >= amountOfBNBToTransfer,
            "Vendor has not enough funds to accept the sell request"
        );

        bool sent = tokenB.transferFrom(
            msg.sender,
            address(this),
            tokenAmountToSell
        );
        require(sent, "Failed to transfer tokens from user to vendor");
        _withdrawSell();
        /* (sent, ) = msg.sender.call{value: amountOfBNBToTransfer}("");
        require(sent, "Failed to send BNB to the user"); */
    }

    /// @notice This function is used to distribute the income through several wallets
    /// 1.
    /// @dev This function can not be called from outside,
    /// This includes owner of the contract or any party that is involved in the development of this process.
    function _withdrawBuy() internal {
        uint256 fullBalance = address(this).balance;
        require(
            fullBalance > 0,
            "Vendor: Contract does not have balance to withdraw."
        );

        /* 1. Rewards wallet %3 */
        withdraw(rewardsWallet, (fullBalance * 3) / 100);

        /* 2. Liquidity Wallet %3 */
        withdraw(liquidityWallet, (fullBalance * 3) / 100);

        /* 3. Burn of Genesis Token (A) %0.5 1/200 is 0.5/100 */
        vendorA.burnToken(1, 200);

        /* 4. Burn of Native Gen(X) Token, %1.5 */
        withdraw(address(0), (fullBalance * 3) / 200);

        /* 5. Market & Dev wallet, %2.5 5/200 is 2.5/100 */
        withdraw(marketDevWallet, (fullBalance * 2) / 100);

        /* 6. Contract wallet %90 */
        withdraw(address(this), (fullBalance * 90) / 100);
    }

    /// @notice This function is used to distribute the income through several wallets
    /// 1.
    /// @dev This function can not be called from outside,
    function _withdrawSell() public payable onlyOwner {
        uint256 fullBalance = address(this).balance;
        require(
            fullBalance > 0,
            "Vendor: Contract does not have balance to withdraw."
        );
        /* 1. Rewards wallet %4 */
        withdraw(rewardsWallet, (fullBalance * 4) / 100);

        /* 2. Liquidity Wallet %2 */
        withdraw(liquidityWallet, (fullBalance * 2) / 100);

        /* 3. Burn of token B %1.5 3/200 is 1.5/100 */
        withdraw(address(0), (fullBalance * 3) / 200);

        /* 4. Burn of Token A token %0.5 is 1/200 */
        vendorA.burnToken(1, 200);

        /* 5. Market & Dev wallet, %2.5 5/200 is 2.5/100 */
        withdraw(marketDevWallet, (fullBalance * 5) / 200);

        /* 6. Charity wallet, %1 */
        withdraw(charityWallet, (fullBalance * 1) / 100);

        /* 7. Commision Wallet %0.5 is 1/200 */
        withdraw(commisionWallet, (fullBalance * 1) / 200);

        /* 8. User wallet %88 */
        withdraw(_msgSender(), (fullBalance * 88) / 100);
    }

    function withdraw(address wallet, uint256 amount) private {
        (bool success, ) = wallet.call{value: amount}("");
        require(success, "Vendor: Transfer failed.");
    }
}