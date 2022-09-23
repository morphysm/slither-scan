// SPDX-License-Identifier: MIT

pragma solidity >= 0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract Whitelist is OwnableUpgradeable {
    mapping(address => bool) public whitelist;
    event WhitelistedAddressAdded(address addr);
    event WhitelistedAddressRemoved(address addr);
    modifier onlyWhitelisted() {
        require(whitelist[msg.sender], 'not whitelisted!');
        _;
    }
    function addAddressToWhitelist(address addr) onlyOwner public returns(bool success) {
        if (!whitelist[addr]) {
            whitelist[addr] = true;
            emit WhitelistedAddressAdded(addr);
            success = true;
        }
    }
    function addAddressesToWhitelist(address[] memory addrs) onlyOwner public returns(bool success) {
        for (uint256 i = 0; i < addrs.length; i++) {
            if (addAddressToWhitelist(addrs[i])) {
                success = true;
            }
        }
    }
    function removeAddressFromWhitelist(address addr) onlyOwner public returns(bool success) {
        if (whitelist[addr]) {
            whitelist[addr] = false;
            emit WhitelistedAddressRemoved(addr);
            success = true;
        }
    }
    function removeAddressesFromWhitelist(address[] memory addrs) onlyOwner public returns(bool success) {
        for (uint256 i = 0; i < addrs.length; i++) {
            if (removeAddressFromWhitelist(addrs[i])) {
                success = true;
            }
        }
    }
}

contract BEP20 {
    using SafeMath for uint256;
    mapping (address => uint256) internal _balances;
    mapping (address => mapping (address => uint256)) internal _allowed;
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    uint256 internal _totalSupply;
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }
    function balanceOf(address owner) public view returns (uint256) {
        return _balances[owner];
    }
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowed[owner][spender];
    }
    function transfer(address to, uint256 value) public returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }
    function approve(address spender, uint256 value) public returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }
    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        _transfer(from, to, value);
        _approve(from, msg.sender, _allowed[from][msg.sender].sub(value));
        return true;
    }
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowed[msg.sender][spender].add(addedValue));
        return true;
    }
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowed[msg.sender][spender].sub(subtractedValue));
        return true;
    }
    function _transfer(address from, address to, uint256 value) internal {
        require(to != address(0),"to address will not be 0");
        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(from, to, value);
    }
    function _mint(address account, uint256 value) internal {
        require(account != address(0),"2");
        _totalSupply = _totalSupply.add(value);
        _balances[account] = _balances[account].add(value);
        emit Transfer(address(0), account, value);
    }
    function _burn(address account, uint256 value) internal {
        require(account != address(0),"3");
        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }
    function _approve(address owner, address spender, uint256 value) internal {
        require(spender != address(0),"4");
        require(owner != address(0),"5");
        _allowed[owner][spender] = value;
        emit Approval(owner, spender, value);
    }
    function _burnFrom(address account, uint256 value) internal {
        _burn(account, value);
        _approve(account, msg.sender, _allowed[account][msg.sender].sub(value));
    }
}

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }
    function safeSub(uint a, uint b) internal pure returns (uint) {
        if (b > a) {
            return 0;
        } else {
            return a - b;
        }
    }
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}

interface IToken {
    function calculateTransferTaxes(address _from, uint256 _value) external view returns (uint256 adjustedValue, uint256 taxAmount);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function transfer(address to, uint256 value) external returns (bool);
    function balanceOf(address who) external view returns (uint256);
    function burn(uint256 _value) external;
}

contract Surge is Initializable, BEP20, Whitelist {
    using SafeMath for uint256;

    string public constant name = "Melta Liquidity Token";
    string public constant symbol = "DROPS";
    uint8 public constant decimals = 18;
    IToken internal token;
    BEP20 internal usdt;
    uint256 public totalTxs;
    uint256 internal lastBalance_;
    uint256 internal trackingInterval_;
    uint256 public providers;
    mapping (address => bool) internal _providers;
    mapping (address => uint256) internal _txs;
    bool public isPaused;
    event onTokenPurchase(address indexed buyer, uint256 indexed usdt_amount, uint256 indexed token_amount);
    event onUsdtPurchase(address indexed buyer, uint256 indexed token_amount, uint256 indexed usdt_amount);
    event onAddLiquidity(address indexed provider, uint256 indexed usdt_amount, uint256 indexed token_amount);
    event onRemoveLiquidity(address indexed provider, uint256 indexed usdt_amount, uint256 indexed token_amount);
    event onLiquidity(address indexed provider, uint256 indexed amount);
    event onContractBalance(uint256 balance);
    event onPrice(uint256 price);
    event onSummary(uint256 liquidity, uint256 price);

    function initialize(address usdt_addr, address token_addr) public initializer {
        __Ownable_init();

        isPaused = true;
        usdt = BEP20(usdt_addr);
        token = IToken(token_addr);
        lastBalance_= block.timestamp;
        trackingInterval_ = 1 minutes;
    }

    function unpause() public onlyOwner {
        isPaused = false;
    }

    function pause() public onlyOwner {
        isPaused = true;
    }

    modifier isNotPaused() {
        require(!isPaused, "Swaps currently paused");
        _;
    }

    function getInputPrice(uint256 input_amount, uint256 input_reserve, uint256 output_reserve)  public view returns (uint256) {
        require(input_reserve > 0 && output_reserve > 0, "INVALID_VALUE");
        uint256 input_amount_with_fee = input_amount.mul(990);
        uint256 numerator = input_amount_with_fee.mul(output_reserve);
        uint256 denominator = input_reserve.mul(1000).add(input_amount_with_fee);
        return numerator / denominator;
    }

    function getOutputPrice(uint256 output_amount, uint256 input_reserve, uint256 output_reserve)  public view returns (uint256) {
        require(input_reserve > 0 && output_reserve > 0,"input_reserve & output reserve must >0");
        uint256 numerator = input_reserve.mul(output_amount).mul(1000);
        uint256 denominator = (output_reserve.sub(output_amount)).mul(990);
        return (numerator / denominator).add(1);
    }

    function usdtToTokenInput(uint256 usdt_sold, uint256 min_tokens, address buyer, address recipient) private returns (uint256) {
        require(usdt_sold > 0 && min_tokens > 0, "sold and min 0");
        uint256 token_reserve = token.balanceOf(address(this));
        uint256 tokens_bought = getInputPrice(usdt_sold, usdt.balanceOf(address(this)).sub(usdt_sold), token_reserve);
        require(tokens_bought >= min_tokens, "tokens_bought >= min_tokens");

        require(usdt.transferFrom(buyer, address(this), usdt_sold), "DRIP to contract transfer failed; check balance and allowance, airdrop");
        require(token.transfer(recipient, tokens_bought), "transfer err");

        emit onTokenPurchase(buyer, usdt_sold, tokens_bought);
        emit onContractBalance(usdtBalance());
        trackGlobalStats();
        return tokens_bought;
    }

    function usdtToTokenSwapInput(uint256 usdt_sold, uint256 min_tokens) public isNotPaused returns (uint256) {
        return usdtToTokenInput(usdt_sold, min_tokens,msg.sender, msg.sender);
    }

    function tokenToUsdtInput(uint256 tokens_sold, uint256 min_usdt, address buyer, address recipient) private returns (uint256) {
        require(tokens_sold > 0 && min_usdt > 0,"tokens_sold > 0 && min_usdt > 0");
        uint256 token_reserve = token.balanceOf(address(this));
        (uint256 realized_sold, uint256 taxAmount) = token.calculateTransferTaxes(buyer, tokens_sold);
        uint256 usdt_bought = getInputPrice(realized_sold, token_reserve, usdt.balanceOf(address(this)));
        require(usdt_bought >= min_usdt,"usdt_bought >= min_usdt");

        require(usdt.transfer(recipient, usdt_bought), "transfer err");
        require(token.transferFrom(buyer, address(this), tokens_sold),"transforfrom error");

        emit onUsdtPurchase(buyer, tokens_sold, usdt_bought);
        trackGlobalStats();
        return usdt_bought;
    }

    function tokenToUsdtSwapInput(uint256 tokens_sold, uint256 min_usdt) public isNotPaused returns (uint256) {
        return tokenToUsdtInput(tokens_sold, min_usdt, msg.sender, msg.sender);
    }

    function trackGlobalStats() private {
        uint256 price = getUsdtToTokenOutputPrice(1e18);
        uint256 balance = usdtBalance();
        uint256 currentTime = block.timestamp;
        if (currentTime.sub(lastBalance_) > trackingInterval_) {
            emit onSummary(balance * 2, price);
            lastBalance_ = currentTime;
        }
        emit onContractBalance(balance);
        emit onPrice(price);
        totalTxs += 1;
        _txs[msg.sender] += 1;
    }

    function getUsdtToTokenInputPrice(uint256 usdt_sold) public view returns (uint256) {
        require(usdt_sold > 0,"usdt_sold > 0,,,1");
        uint256 token_reserve = token.balanceOf(address(this));
        return getInputPrice(usdt_sold, usdt.balanceOf(address(this)), token_reserve);
    }

    function getUsdtToTokenOutputPrice(uint256 tokens_bought) public view returns (uint256) {
        require(tokens_bought > 0,"tokens_bought > 0,,,1");
        uint256 token_reserve = token.balanceOf(address(this));
        uint256 usdt_sold = getOutputPrice(tokens_bought, usdt.balanceOf(address(this)), token_reserve);
        return usdt_sold;
    }

    function getTokenToUsdtInputPrice(uint256 tokens_sold) public view returns (uint256) {
        require(tokens_sold > 0, "token sold < 0,,,,,2");
        uint256 token_reserve = token.balanceOf(address(this));
        uint256 usdt_bought = getInputPrice(tokens_sold, token_reserve, usdt.balanceOf(address(this)));
        return usdt_bought;
    }

    function getTokenToUsdtOutputPrice(uint256 usdt_bought) public view returns (uint256) {
        require(usdt_bought > 0,"usdt_bought > 0,,,,2");
        uint256 token_reserve = token.balanceOf(address(this));
        return getOutputPrice(usdt_bought, token_reserve, usdt.balanceOf(address(this)));
    }

    function tokenAddress() public view returns (address) {
        return address(token);
    }

    function usdtBalance() public view returns (uint256) {
        return usdt.balanceOf(address(this));
    }

    function tokenBalance() public view returns (uint256) {
        return token.balanceOf(address(this));
    }

    function getUsdtToLiquidityInputPrice(uint256 usdt_sold) public view returns (uint256) {
        require(usdt_sold > 0,"usdt_sold > 0,,,,,3");
        uint256 token_amount = 0;
        uint256 total_liquidity = _totalSupply;
        uint256 usdt_reserve = usdt.balanceOf(address(this));
        uint256 token_reserve = token.balanceOf(address(this));
        token_amount = (usdt_sold.mul(token_reserve) / usdt_reserve).add(1);
        uint256 liquidity_minted = usdt_sold.mul(total_liquidity) / usdt_reserve;
        return liquidity_minted;
    }

    function getLiquidityToReserveInputPrice(uint amount) public view returns (uint256, uint256) {
        uint256 total_liquidity = _totalSupply;
        require(total_liquidity > 0,"total_liquidity > 0,,,,1");
        uint256 token_reserve = token.balanceOf(address(this));
        uint256 usdt_amount = amount.mul(usdt.balanceOf(address(this))) / total_liquidity;
        uint256 token_amount = amount.mul(token_reserve) / total_liquidity;
        return (usdt_amount, token_amount);
    }

    function txs(address owner) public view returns (uint256) {
        return _txs[owner];
    }

    function addLiquidity(uint256 min_liquidity, uint256 max_tokens, uint256 max_usdt) isNotPaused public returns (uint256) {
        require(max_tokens > 0 && max_usdt > 0, "Swap#addLiquidity: INVALID_ARGUMENT");
        uint256 total_liquidity = _totalSupply;
        uint256 token_amount = 0;
        if (_providers[msg.sender] == false){
            _providers[msg.sender] = true;
            providers += 1;
        }
        if (total_liquidity > 0) {
            require(min_liquidity > 0,"min_liquidity > 0,,,,4");
            uint256 usdt_reserve = usdt.balanceOf(address(this)).sub(max_usdt);
            uint256 token_reserve = token.balanceOf(address(this));
            token_amount = (max_usdt.mul(token_reserve) / usdt_reserve).add(1);
            uint256 liquidity_minted = max_usdt.mul(total_liquidity) / usdt_reserve;
            require(max_tokens >= token_amount && liquidity_minted >= min_liquidity,"max_tokens >= token_amount && liquidity_minted >= min_liquidity,,,,1");
            _balances[msg.sender] = _balances[msg.sender].add(liquidity_minted);
            _totalSupply = total_liquidity.add(liquidity_minted);
            require(token.transferFrom(msg.sender, address(this), token_amount),"transfrom4 error");
            require(usdt.transferFrom(msg.sender, address(this), token_amount),"usdt transfrom error");
            emit onAddLiquidity(msg.sender, max_usdt, token_amount);
            emit onLiquidity(msg.sender, _balances[msg.sender]);
            emit Transfer(address(0), msg.sender, liquidity_minted);
            return liquidity_minted;
        } else {
            require(max_usdt >= 1e18, "INVALID_VALUE");
            token_amount = max_tokens;
            uint256 initial_liquidity = usdt.balanceOf(address(this));
            _totalSupply = initial_liquidity;
            _balances[msg.sender] = initial_liquidity;
            require(token.transferFrom(msg.sender, address(this), token_amount),"transforfrom 5 error");
            require(usdt.transferFrom(msg.sender, address(this), token_amount),"usdt transfrom error");
            emit onAddLiquidity(msg.sender, max_usdt, token_amount);
            emit onLiquidity(msg.sender, _balances[msg.sender]);
            emit Transfer(address(0), msg.sender, initial_liquidity);
            return initial_liquidity;
        }
    }

    function removeLiquidity(uint256 amount, uint256 min_usdt, uint256 min_tokens) onlyWhitelisted public returns (uint256, uint256) {
        require(amount > 0 && min_usdt > 0 && min_tokens > 0,"amount > 0 && min_usdt > 0 && min_tokens > 0,333");
        uint256 total_liquidity = _totalSupply;
        require(total_liquidity > 0);
        uint256 token_reserve = token.balanceOf(address(this));
        uint256 usdt_amount = amount.mul(usdt.balanceOf(address(this))) / total_liquidity;
        uint256 token_amount = amount.mul(token_reserve) / total_liquidity;
        require(usdt_amount >= min_usdt && token_amount >= min_tokens,"(usdt_amount >= min_usdt && token_amount >= min_tokens,33");
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        _totalSupply = total_liquidity.sub(amount);
        payable(msg.sender).transfer(usdt_amount);
        require(token.transfer(msg.sender, token_amount),"transfer error");
        emit onRemoveLiquidity(msg.sender, usdt_amount, token_amount);
        emit onLiquidity(msg.sender, _balances[msg.sender]);
        emit Transfer(msg.sender, address(0), amount);
        return (usdt_amount, token_amount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
                /// @solidity memory-safe-assembly
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