//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./interfaces/ITreasury.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../../util/CommonModifiers.sol";
import "../pusd/PUSD.sol";

contract Treasury is Ownable, ITreasury, CommonModifiers {
    constructor(
        address payable _pusdAddress,
        address payable _loanAgentAddress,
        uint256 _mintPrice,
        uint256 _burnPrice
    ) {
        if(
            _pusdAddress == address(0) || 
            _loanAgentAddress == address(0)
        ) revert AddressExpected();

        pusdAddress = _pusdAddress;
        loanAgent = _loanAgentAddress;
        mintPrice = _mintPrice;
        burnPrice = _burnPrice;
    }

    /// @inheritdoc ITreasury
    function mintPUSD(
        address stablecoinAddress,
        uint256 stablecoinAmount
    ) external override nonReentrant() returns (bool) {
        if (!supportedStablecoins[stablecoinAddress]) revert TokenNotSupported(stablecoinAddress); 

        ERC20 stablecoin = ERC20(stablecoinAddress);
        uint8 stablecoinDecimals = stablecoin.decimals();
        uint256 stablecoinPrice = 10**(stablecoinDecimals);

        if (stablecoin.balanceOf(msg.sender) < stablecoinAmount) revert NotEnoughBalance(stablecoinAddress, msg.sender);

        PUSD pusd = PUSD(pusdAddress);
        uint256 exchangeRate = mintPrice * 10**stablecoinDecimals / stablecoinPrice;
        uint256 pusdAmount = stablecoinAmount * exchangeRate / (10**stablecoinDecimals);

        stablecoinReserves[stablecoinAddress] += stablecoinAmount;
        if (!stablecoin.transferFrom(msg.sender, address(this), stablecoinAmount)) revert TransferFailed(msg.sender, address(this)); 
        pusd.mint(msg.sender, pusdAmount);

        return true;
    }

    /// @inheritdoc ITreasury
    function burnPUSD(
        address stablecoinAddress,
        uint256 pusdAmount
    ) external override nonReentrant() returns (bool) {
        if (!supportedStablecoins[stablecoinAddress]) revert TokenNotSupported(stablecoinAddress); 
        
        PUSD pusd = PUSD(pusdAddress);
        uint256 pusdPrice = burnPrice;
        uint8 pusdDecimals = pusd.decimals();

        ERC20 stablecoin = ERC20(stablecoinAddress);
        uint8 stablecoinDecimals = stablecoin.decimals();
        uint256 stablecoinPrice = 10**(stablecoinDecimals);

        uint256 exchangeRate = stablecoinPrice * 10**pusdDecimals / pusdPrice;
        uint256 stablecoinAmount = pusdAmount * exchangeRate / (10**pusdDecimals);
        uint256 stablecoinReserve = stablecoinReserves[stablecoinAddress];

        if (stablecoinReserve < stablecoinAmount) revert NotEnoughBalance(stablecoinAddress, address(this));

        stablecoinReserves[stablecoinAddress] = stablecoinReserve - stablecoinAmount;
        pusd.burnFrom(msg.sender, pusdAmount);
        if (!stablecoin.transfer(msg.sender, stablecoinAmount)) revert TransferFailed(address(this), msg.sender); 

        return true;
    }

    /// @inheritdoc ITreasury
    function checkReserves(
        address tokenAddress
    ) external view override returns (uint256) {
        return stablecoinReserves[tokenAddress];
    }

    /// @inheritdoc ITreasury
    function deposit(
        address tokenAddress,
        uint256 amount
    ) external override nonReentrant() {
        IERC20 token = IERC20(tokenAddress);

        stablecoinReserves[tokenAddress] += amount;

        if (!token.transferFrom(msg.sender, address(this), amount)) revert TransferFailed(msg.sender, address(this));
    }

    /// @inheritdoc ITreasury
    function withdraw(
        address tokenAddress,
        uint256 amount,
        address recipient
    ) external override onlyOwner() nonReentrant() {
        uint256 stablecoinReserve = stablecoinReserves[tokenAddress];

        if (stablecoinReserve < amount) revert InsufficientReserves();

        IERC20 token = IERC20(tokenAddress);

        stablecoinReserves[tokenAddress] = stablecoinReserve - amount;

        if (!token.transfer(recipient, amount)) revert TransferFailed(address(this), recipient);
    }

    /// @inheritdoc ITreasury
    function whitelistStablecoin(
        address stablecoinAddress
    ) external override onlyOwner() {
        if(stablecoinAddress == address(0)) revert AddressExpected();
        if (supportedStablecoins[stablecoinAddress]) {
            supportedStablecoins[stablecoinAddress] = false;
        } else {
           supportedStablecoins[stablecoinAddress] = true; 
        }
    }

    /// @inheritdoc ITreasury
    function setPUSDAddress(
        address payable newPUSD
    ) external override onlyOwner() {
        if(newPUSD == address(0)) revert AddressExpected();
        pusdAddress = newPUSD;
    }

    /// @inheritdoc ITreasury
    function setLoanAgent(
        address payable newLoanAgent
    ) external override onlyOwner() {
        if(newLoanAgent == address(0)) revert AddressExpected();
        loanAgent = newLoanAgent;
    }

    //transfer funds to the xPrime contract
    function accrueProfit() external override {
        // TODO
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";

/*
    Tokens in the treasury are divided between three buckets: reserves, insurance, and surplus.

    Reserve tokens accrue from the result of arbitrageurs buying PUSD from the treasury.

    Insurance tokens are held in for the event where a liquidation does not fully cover an outstanding loan.
    If an incomplete liquidation occurs, insurance tokens are transferred to reserves to back the newly outstanding PUSD
    When sufficient insurance tokens are accrued, newly recieved tokens are diverted to surplus.

    Surplus tokens are all remaining tokens that aren't backing or insuring ourstanding PUSD.
    When profit accrues, the value of surplus tokens is distributed to xPrime stakers.
*/

abstract contract ITreasury is Ownable {
    // Address of the PUSD contract on the same blockchain
    address payable public pusdAddress;

    // Address of the loan agent on the same blockchain
    address payable public loanAgent;

    /*
     * Mapping of addesss of accepted stablecoin to amount held in reserve
     */
    mapping(address => uint256) public stablecoinReserves;

    // Addresses of stablecoins that can be swapped for PUSD at the guaranteed rate
    mapping(address => bool) public supportedStablecoins;

    // Exchange rate at which a trader can deposit PUSD via the treasury. Should be more than 1
    uint256 public mintPrice;

    // Exchange rate at which a trader can burn PUSD via the treasury. Should be less than 1
    uint256 public burnPrice;

    /**
     * @notice Deposit PUSD from the treasury at the guaranteed exchange rate
     * @dev This is called by an arbitrageur seeking to stabilize the PUSD peg
     * @param stablecoinAddress Address of the stablecoin the user will transfer in
     * @param stablecoinAmount Amount of the stablecoin the user will transfer in
     * @return (bool, true if completed successfully) Note: should change this so a real error is returned
     */
    function mintPUSD(address stablecoinAddress, uint256 stablecoinAmount)
        external
        virtual
        returns (bool);

    /**
     * @notice Burn PUSD via the treasury at the guaranteed exchange rate
     * @dev This is called by an arbitrageur seeking to stabilize the PUSD peg
     * @param stablecoinAddress Address of the stablecoin given the user will transfer out
     * @param pusdAmount Amount of PUSD to transfer to the user
     * @return (bool, true if completed successfully) Note: should change this so a real error is returned
     */
    function burnPUSD(address stablecoinAddress, uint256 pusdAmount)
        external
        virtual
        returns (bool);

    /**
     * @notice Get the amount of a given token that the treasury holds
     * @dev This is called by a third party application to analyze treasury holdings
     * @param tokenAddress Address of the coin to check balance of
     * @return The amount of the given token that this deployment of the treasury holds
     */
    function checkReserves(address tokenAddress)
        external
        view
        virtual
        returns (uint256);

    /**
     * @notice Deposit a given ERC20 token into the treasury
     * @dev Msg.sender will be the address used to transfer tokens from
     * @param tokenAddress Address of the coin to deposit
     * @param amount Amount of the token to deposit
     */
    function deposit(address tokenAddress, uint256 amount) external virtual;

    /**
     * @notice Withdraw a given ERC20 token from the treasury
     * @dev Withdrawals should not be allowed to come from reserves
     * @param tokenAddress Address of the coin to withdraw
     * @param amount Amount of the token to withdraw
     * @param recipient Address where tokens are sent to
     */
    function withdraw(
        address tokenAddress,
        uint256 amount,
        address recipient
    ) external virtual;

    /**
     * @notice Remove or Add a stablecoin to the list of accepted reserve stablecoins, toggles the status
     * @dev Update both the array and mapping
     * @param stablecoinAddress Stablecoin to be removed or added from reserve whitelist
     */
    function whitelistStablecoin(address stablecoinAddress) external virtual;

    /**
     * @notice Sets the address of the PUSD contract
     * @param pusd Address of the new PUSD contract
     */
    function setPUSDAddress(address payable pusd) external virtual;

    /**
     * @notice Sets the address of the loan agent contract
     * @param loanAgentAddress Address of the new loan agent contract
     */
    function setLoanAgent(address payable loanAgentAddress) external virtual;

    /**
     * @notice Transfers funds to the xPrime contract
     */
    function accrueProfit() external virtual;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

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
        _approve(owner, spender, _allowances[owner][spender] + addedValue);
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
        uint256 currentAllowance = _allowances[owner][spender];
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
     * @dev Spend `amount` form the allowance of `owner` toward `spender`.
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./CommonErrors.sol";

abstract contract CommonModifiers is CommonErrors {

    /**
    * @dev Guard variable for re-entrancy checks
    */
    bool internal notEntered;

    constructor() {
        notEntered = true;
    }

    /**
    * @dev Prevents a contract from calling itself, directly or indirectly.
    */
    modifier nonReentrant() {
        if (!notEntered) revert Reentrancy();
        notEntered = false;
        _;
        notEntered = true; // get a gas-refund post-Istanbul
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

// import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "../../middleLayer/interfaces/IMiddleLayer.sol";
import "../../interfaces/IHelper.sol";
import "./PUSDStorage.sol";
import "./PUSDMessageHandler.sol";
import "./PUSDAdmin.sol";

contract PUSD is PUSDAdmin, PUSDMessageHandler {
    constructor(
        string memory tknName,
        string memory tknSymbol,
        uint256 underlyingAssetChainId,
        address underlyingAssetAddress,
        address eccAddress,
        uint8 decimals
    ) ERC20(tknName, tknSymbol) {
        admin = msg.sender;
        underlyingChainId = underlyingAssetChainId;
        underlyingAsset = underlyingAssetAddress;
        ecc = IECC(eccAddress);
        _decimals = decimals;
    }

    function mint(
        address to,
        uint256 amount
    ) external override onlyPermissioned() {
        _mint(to, amount);
    }

    /**
     * @notice Burn tokens on the local chain and mint on the destination chain
     * @dev Accrues interest whether or not the operation succeeds, unless reverted
     * @param dstChainId Destination chain to mint
     * @param receiver Wallet that is sending/burning PUSD
     * @param amount Amount to burn locally/mint on the destination chain
     */
    function sendTokensToChain(
        uint256 dstChainId,
        address receiver,
        uint256 amount,
        address route
    ) external payable {
        if (paused) revert TransferPaused();
        _sendTokensToChain(dstChainId, receiver, amount, route);
    }

    fallback() external payable {}

    receive() payable external {}
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

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

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

abstract contract CommonErrors {
    error AccountNoAssets(address account);
    error AddressExpected();
    error AlreadyInitialized();
    error EccMessageAlreadyProcessed();
    error EccFailedToValidate();
    error ExpectedWithdrawAmount();
    error ExpectedRepayAmount();
    error InsufficientReserves();
    error InvalidPayload();
    error InvalidPrice();
    error MarketExists();
    error MarketIsPaused();
    error MarketNotListed();
    error MsgDataExpected();
    error NothingToWithdraw();
    error NotInMarket(uint256 chainId, address token);
    error OnlyAdmin();
    error OnlyAuth();
    error OnlyGateway();
    error OnlyMiddleLayer();
    error OnlyRoute();
    error OnlyRouter();
    error OnlyMasterState();
    error ParamOutOfBounds();
    error RouteExists();
    error Reentrancy();
    error RepayTooMuch(uint256 repayAmount, uint256 maxAmount);
    error WithdrawTooMuch();
    error NotEnoughBalance(address token, address who);
    error LiquidateDisallowed();
    error SeizeTooMuch();
    error RouteNotSupported(address route);
    error MiddleLayerPaused();
    error TokenNotSupported(address token);
    error TransferFailed(address from, address dest);
    error TransferPaused();
    error UnknownRevert();
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

abstract contract IMiddleLayer {
    /**
     * @notice routes and encodes messages for you
     * @param _params - abi.encode() of the struct related to the selector, used to generate _payload
     * all params starting with '_' are directly sent to the 'send()' function
     */
    function msend(
        uint256 _dstChainId,
        bytes memory _params,
        address payable _refundAddress,
        address _fallbackAddress
    ) external payable virtual;

    function mreceive(
        uint256 _srcChainId,
        bytes memory _payload
    ) external virtual;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.4;

interface IHelper {
    enum Selector {
        MASTER_DEPOSIT,
        MASTER_WITHDRAW_ALLOWED,
        FB_WITHDRAW,
        MASTER_REPAY,
        MASTER_BORROW_ALLOWED,
        FB_BORROW,
        SATELLITE_LIQUIDATE_BORROW,
        PUSD_BRIDGE
    }

    // !!!!
    // @dev
    // an artificial uint256 param for metadata should be added
    // after packing the payload
    // metadata can be generated via call to ecc.preRegMsg()

    struct MDeposit {
        Selector selector; // = Selector.MASTER_DEPOSIT
        address user;
        address pToken;
        uint256 exchangeRate;
        uint256 previousAmount;
        uint256 amountIncreased;
    }

    struct MWithdrawAllowed {
        Selector selector; // = Selector.MASTER_WITHDRAW_ALLOWED
        address pToken;
        address user;
        uint256 amount;
        uint256 exchangeRate;
    }

    struct FBWithdraw {
        Selector selector; // = Selector.FB_WITHDRAW
        address pToken;
        address user;
        uint256 withdrawAmount;
        uint256 exchangeRate;
    }

    struct MRepay {
        Selector selector; // = Selector.MASTER_REPAY
        address borrower;
        uint256 amountRepaid;
        address loanMarketAsset;
    }

    struct MBorrowAllowed {
        Selector selector; // = Selector.MASTER_BORROW_ALLOWED
        address user;
        uint256 borrowAmount;
        address loanMarketAsset;
    }

    struct FBBorrow {
        Selector selector; // = Selector.FB_BORROW
        address user;
        uint256 borrowAmount;
        address loanMarketAsset;
    }

    struct SLiquidateBorrow {
        Selector selector; // = Selector.SATELLITE_LIQUIDATE_BORROW
        address borrower;
        address liquidator;
        uint256 seizeTokens;
        address pToken;
    }


    struct PUSDBridge {
        Selector selector; // = Selector.PUSD_BRIDGE
        address minter;
        uint256 amount;
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "../../middleLayer/interfaces/IMiddleLayer.sol";
import "../../ecc/interfaces/IECC.sol";

abstract contract PUSDStorage {

    /**
     * @notice Administrator for this contract
     */
    address public admin;

    /**
     * @notice Underlying asset for this contract
     */
    address public underlyingAsset;

    /**
     * @notice Underlying chain id for this contract
     */
    uint256 public underlyingChainId;

    /**
     * @notice MiddleLayer Interface
     */
    IMiddleLayer internal middleLayer;
    
    /**
     * @notice ECC Interface
     */
    IECC internal ecc;

    /**
     * @notice PUSD Decimals
     */
    uint8 internal _decimals;

    /**
     * @notice Whitelisted treasury address
     */    
    address internal treasuryAddress;
    
    /**
     * @notice Whitelisted Loan Agent Address
     */
    address internal loanAgentAddress;    
    /**
     * @notice Whether PUSD transfers are paused
     */
    address internal masterStateAddress;
    bool internal paused;
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "./PUSDStorage.sol";
import "./PUSDAdmin.sol";
import "../../interfaces/IHelper.sol";
import "../../util/CommonModifiers.sol";

abstract contract PUSDMessageHandler is
    PUSDStorage,
    PUSDAdmin,
    ERC20Burnable,
    CommonModifiers
{

    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    // slither-disable-next-line assembly
    function _sendTokensToChain(
        uint256 _dstChainId,
        address receiver,
        uint256 amount,
        address route
    ) internal {
        if (paused) revert TransferPaused();

        bytes memory payload = abi.encode(
            uint256(0),
            IHelper.PUSDBridge(
                IHelper.Selector.PUSD_BRIDGE,
                receiver,
                amount
            )
        );

        // if (_dstChainId != block.chainid) {
            bytes32 metadata = ecc.preRegMsg(payload, msg.sender);
            assembly {
                mstore(add(payload, 0x20), metadata)
            }
        // }

        // burn senders PUSD locally
        _burn(msg.sender, amount);

        middleLayer.msend{ value: msg.value }(
            _dstChainId,
            payload,
            payable(receiver), // refund address
            route
        );

        emit SentToChain(_dstChainId, receiver, amount);
    }

    function mintFromChain(
        IHelper.PUSDBridge memory params,
        bytes32 metadata,
        uint256 srcChain
    ) external onlyMid() {
        if (/* srcChain != block.chainid &&  */!ecc.preProcessingValidation(abi.encode(params), metadata)) revert EccMessageAlreadyProcessed();

        if (/* srcChain != block.chainid &&  */!ecc.flagMsgValidated(abi.encode(params), metadata)) revert EccFailedToValidate();

        _mint(params.minter, params.amount);

        emit ReceiveFromChain(srcChain, params.minter, params.amount);
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./interfaces/IPUSD.sol";
import "./PUSDModifiers.sol";
import "./PUSDEvents.sol";

abstract contract PUSDAdmin is IPUSD, PUSDModifiers, PUSDEvents {

    function setLoanAgent(
        address newLoanAgent
    ) external onlyAdmin() {
        if(newLoanAgent == address(0)) revert AddressExpected();

        emit SetLoanAgent(loanAgentAddress, newLoanAgent);

        loanAgentAddress = newLoanAgent;
    }

    function changeAdmin(
        address newAdmin
    ) external onlyAdmin() {
        if(newAdmin == address(0)) revert AddressExpected();
        
        emit ChangeAdmin(admin, newAdmin);
        
        admin = newAdmin;
    }

    function setTreasury(
        address newTreasury
    ) external onlyAdmin() {
        if(newTreasury == address(0)) revert AddressExpected();
        
        emit SetTreasury(treasuryAddress, newTreasury);
        
        treasuryAddress = newTreasury;
    }

    function setMiddleLayer(
        address newMiddleLayer
    ) external onlyAdmin() {
        if(newMiddleLayer == address(0)) revert AddressExpected();

        emit SetMiddleLayer(address(middleLayer), newMiddleLayer);

        middleLayer = IMiddleLayer(newMiddleLayer);
    }

    function pauseSendTokens(
        bool newPauseStatus
    ) external onlyAdmin() {
        emit Paused(paused, newPauseStatus);

        paused = newPauseStatus;
    }

    function setMasterState(
        address newMasterState
    ) external onlyAdmin() {
        emit SetMasterState(masterStateAddress, newMasterState);
        masterStateAddress = newMasterState;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IECC {
    struct Metadata {
        bytes5 soph; // start of payload hash
        uint40 creation;
        uint16 nonce; // in case the same exact message is sent multiple times the same block, we increase the nonce in metadata
        address sender;
    }

    function preRegMsg(
        bytes memory payload,
        address instigator
    ) external returns (bytes32 metadata);

    function preProcessingValidation(
        bytes memory payload,
        bytes32 metadata
    ) external view returns (bool allowed);

    function flagMsgValidated(
        bytes memory payload,
        bytes32 metadata
    ) external returns (bool);

    // function rsm(uint256 messagePtr) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/extensions/ERC20Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC20.sol";
import "../../../utils/Context.sol";

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

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

interface IPUSD {
    function mint(address to, uint256 amount) external;
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./PUSDStorage.sol";
import "../../util/CommonErrors.sol";

abstract contract PUSDModifiers is PUSDStorage, CommonErrors {

    modifier onlyPermissioned() {
        if (
            msg.sender != treasuryAddress &&
            msg.sender != loanAgentAddress &&
            msg.sender != masterStateAddress &&
            msg.sender != admin // FIXME: Remove
        ) revert OnlyAuth();
        _;
    }

    modifier onlyAdmin() {
        if(msg.sender != admin) revert OnlyAdmin();
        _;
    }

    modifier onlyMid() {
        if (msg.sender != address(middleLayer)) revert OnlyMiddleLayer();
        _;
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

abstract contract PUSDEvents {

    /*** User Events ***/

    /**
     * @notice Event emitted when PUSD is sent cross-chain
     */
    event SentToChain(
        uint256 destChainId,
        address toAddress,
        uint256 amount
    );

    /**
     * @notice Event emitted when PUSD is received cross-chain
     */
    event ReceiveFromChain(
        uint256 srcChainId,
        address toAddress,
        uint256 amount
    );

    /*** Admin Events ***/

    event Paused(
        bool previousStatus,
        bool newStatus
    );

    event SetLoanAgent(
        address oldLoanAgentAddress,
        address newLoanAgentAddress
    );

    event ChangeAdmin(
        address oldAdmin,
        address newAdmin
    );

    event SetTreasury(
        address oldTreasuryAddress,
        address newTreasuryAddress
    );

    event SetMiddleLayer(
        address oldMiddleLayer,
        address newMiddleLayer
    );

    event SetMasterState(
        address oldMasterState,
        address newMasterState
    );
}