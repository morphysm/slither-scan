// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.7;

import "../interfaces/IOmniApp.sol";
import "../interfaces/IOmnichainRouter.sol";
import "../interfaces/IOmniERC20.sol";
import "./OmniERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract OGateway is IOmniApp, Ownable {

    event OmReceived(string srcChain, address srcOA);
    event Transferred(address token, uint256 amount, address account);
    event Locked(address token, uint256 amount, address account);

    IOmnichainRouter public omnichainRouter;
    mapping(address => mapping(address => uint256)) public locked; // token -> account -> amount
    // Emergency unlock in case of a failed tx on the dstChain
    mapping(address => mapping(address => uint256)) public forceUnlockRequests; // token -> account -> amount
    mapping(address => address) public copyToOriginal;
    mapping(address => address) public originalToCopy;
    mapping(address => bool) public isCopy;
    string public chainName;
    mapping(string => address) public remoteChainToOA;
    address private _owner;
    address private _redirectionsBudgetManager;

    /**
     * @notice Sets the contract owner, feeManager address, router, and indicates source chain name for mappings.
     *
     * @param _router A contract that handles cross-chain messaging used to extend ERC721 with omnichain capabilities.
     */
    constructor(IOmnichainRouter _router) {
        _owner = msg.sender;
        chainName = "Avalanche";
        omnichainRouter = _router;
        _redirectionsBudgetManager = address(0x61104fBe07ecc735D8d84422c7f045f8d29DBf15);
    }

    function setRouter(IOmnichainRouter _router) external onlyOwner {
        omnichainRouter = _router;
    }

    function setRedirectionsBudgetManager(address _newManager) external onlyOwner {
        _redirectionsBudgetManager = _newManager;
    }

    /**
     * @notice Sets the remote Omnichain Applications ("OA") addresses to meet omReceive() validation.
     *
     * @param remoteChainName Name of the remote chain.
     * @param remoteOA Address of the remote OA.
     */
    function setOA(string memory remoteChainName, address remoteOA) external onlyOwner {
        remoteChainToOA[remoteChainName] = remoteOA;
    }

    /**
     * @notice Checks the presence of the selected remote Omnichain Application ("OA").
     *
     * @param remoteChainName Name of the remote chain.
     * @param remoteOA Address of the remote OA.
     */
    function isOA(string memory remoteChainName, address remoteOA) public view returns (bool) {
        return remoteChainToOA[remoteChainName] == remoteOA;
    }

    /**
     * @notice Sends the ERC-721 to the destination chain
     *
     * @param token ERC20 token contract.
     * @param amount quantity of the token
     * @param dstChainName OmnichainRouter-specific destination chain name.
     * @param gas Gas limit of the transaction executed on the destination chain.
     * @param redirectFee OmnichainRouter-specific gas limit of the redirection transaction on the redirect chain.
     */
    function sendTo(ERC20 token, uint256 amount, string memory dstChainName, uint256 gas, uint256 redirectFee) public payable {
        require(bytes(dstChainName).length > 0, "!CHAIN");
        address tokenAddress = address(token);
        require(tokenAddress != address(0), "!ADDRESS");
        require(amount > 0, "!AMOUNT");
        require(_isContract(tokenAddress), "!EXISTS");
        require(token.balanceOf(msg.sender) >= amount, "!BALANCE");

        if (isCopy[tokenAddress]) {
            IOmniERC20 omniToken = IOmniERC20(tokenAddress);
            omniToken.burn(msg.sender, amount);
            _send(_getPayload(token, copyToOriginal[tokenAddress], amount), dstChainName, gas, redirectFee);

            return;
        }

        token.transferFrom(msg.sender, address(this), amount);
        locked[tokenAddress][msg.sender] += amount;
        emit Locked(tokenAddress, amount, msg.sender);
        _send(_getPayload(token, tokenAddress, amount), dstChainName, gas, redirectFee);
    }

    /**
     * @notice Handles the incoming task from other chains received from Omnichain Router.
     *         Validates Omnichain Application.

     * @notice Mints an NFT copy (ONFTCopy) or recovers the original NFT (locked on the source chain) and transfers to
     *         its owner.
     *
     * @param _payload Encoded bytes payload.
     * @param srcOA Address of the remote OA.
     * @param srcChain Name of the remote OA chain.
     */
    function omReceive(bytes calldata _payload, address srcOA, string memory srcChain) external override {
        emit OmReceived(srcChain, srcOA);
        require(isOA(srcChain, srcOA));
        (address originalAddress, uint256 amount, uint8 decimals, address account, string memory name, string memory symbol) = abi.decode(_payload, (address, uint256, uint8, address, string, string));

        if (locked[originalAddress][account] > 0) {
            IERC20 original = IERC20(originalAddress);
            locked[originalAddress][account] -= amount;
            original.transfer(account, amount);
            emit Transferred(originalAddress, amount, account);

            return;
        }

        if (originalToCopy[originalAddress] != address(0)) {
            IOmniERC20 omniToken = IOmniERC20(originalToCopy[originalAddress]);
            omniToken.mint(account, amount);
            isCopy[address(omniToken)] = true; // Is that needed?
        } else {
            OmniERC20 omniToken = new OmniERC20(name, symbol, decimals, address(this));
            omniToken.mint(account, amount);
            address tokenAddress = address(omniToken);
            isCopy[tokenAddress]= true;
            originalToCopy[originalAddress] = tokenAddress;
            copyToOriginal[tokenAddress] = originalAddress;
        }
        emit Transferred(originalAddress, amount, account);
    }

    /**
     * @notice Withdraws all the Omnichain Application's redirect fees collected from end-users in case of required redirections
    */
    function withdrawOARedirectFees() external onlyOwner {
        omnichainRouter.withdrawOARedirectFees(_redirectionsBudgetManager);
    }

    function requestForceUnlock(address _token, uint256 _amount) external {
        require(locked[_token][msg.sender] >= _amount, '!LOCKED');
        forceUnlockRequests[_token][msg.sender] += _amount;
    }

    function forceUnlock(address _token, address _account, uint256 _amount) external onlyOwner {
        require(locked[_token][_account] >= _amount, '!LOCKED');
        require(forceUnlockRequests[_token][_account] >= _amount, '!REQUESTED');
        forceUnlockRequests[_token][_account] -= _amount;
        IERC20 unlocked = IERC20(_token);
        locked[_token][_account] -= _amount;
        unlocked.transferFrom(address(this), _account, _amount);
    }

    /**
     * @notice Delegates cross-chain task to the Omnichain Router.
     *
     * @param payload Data required for the task execution on the dstChain.
     * @param dstChainName Name of the remote chain.
     * @param gas Gas limit set for the function execution on the dstChain.
     * @param redirectFee Fee required to cover transaction fee on the redirectChain, if involved. OmnichainRouter-specific.
     *        Involved during cross-chain multi-protocol routing. For example, Optimism (LayerZero) to Moonbeam (Axelar).
     */
    function _send(bytes memory payload, string memory dstChainName, uint256 gas, uint256 redirectFee) private {
        omnichainRouter.send{value : msg.value}(dstChainName, remoteChainToOA[dstChainName], payload, gas, msg.sender, redirectFee);
    }

    /**
     * @notice Encodes the data to the bytes payload for the cross-chain message.
     *
     * @param token ERC20 token.
     * @param original Address of the original bridged ERC20.
     * @param amount quantity of the token.
     */
    function _getPayload(ERC20 token, address original, uint256 amount) private view returns (bytes memory) {
        return abi.encode(original, amount, token.decimals(), msg.sender, token.name(), token.symbol());
    }

    /**
     * @notice Checks if the given address is a contract.
     */
    function _isContract(address collection) private view returns (bool) {
        uint size;
        assembly { size := extcodesize(collection) }
        return size > 0;
    }

    receive() external payable {}
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.7;

interface IOmniApp {
    /**
     * @notice Handles the incoming tasks from other chains received from Omnichain Router.
     *
     * @param _payload Encoded MintParams data.
     * @param srcOA Address of the remote OA.
     * @param srcChain Name of the remote OA chain.
     */
    function omReceive(bytes calldata _payload, address srcOA, string memory srcChain) external;
}

// SPDX-License-Identifier: BUSL-1.1
// gatebly-contracts v0.1

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "../interfaces/IOmniERC20.sol";

contract OmniERC20 is IOmniERC20, ERC20, IERC165 {
    address public bridge;
    uint8 private _decimals;

    constructor(string memory _name, string memory _symbol, uint8 decimals_, address _bridge) ERC20(_name, _symbol) {
        _decimals = decimals_;
        bridge = _bridge;
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165) returns (bool) {
        return interfaceId == type(IOmniERC20).interfaceId || interfaceId == type(IERC20).interfaceId;
    }

    function burn(address _account, uint256 _amount) override external {
        require(msg.sender == bridge, "!BRIDGE");
        _burn(_account, _amount);
    }

    function mint(address _account, uint256 _amount) override external {
        require(msg.sender == bridge, "!BRIDGE");
        _mint(_account, _amount);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.7;

interface IOmniERC20 {
    function burn(address account, uint256 amount) external;
    function mint(address account, uint256 amount) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.7;

interface IOmnichainRouter {
    /**
     * @notice Delegates the cross-chain task to the Omnichain Router.
     *
     * @param dstChainName Name of the remote chain.
     * @param dstOA Address of the remote Omnichain Application ("OA").
     * @param fnData Encoded payload with a data for a target function execution.
     * @param gas Cross-chain task (tx) execution gas limit
     * @param user Address of the user initiating the cross-chain task (for gas refund)
     * @param redirectFee Fee required to cover transaction fee on the redirectChain, if involved. OmnichainRouter-specific.
     *        Involved during cross-chain multi-protocol routing. For example, Optimism (LayerZero) to Moonbeam (Axelar).
     */
    function send(string memory dstChainName, address dstOA, bytes memory fnData, uint gas, address user, uint256 redirectFee) external payable;

    /**
     * @notice Router on source chain receives redirect fee on payable send() function call. This fee is accounted to srcOARedirectBudget.
     *         here, msg.sender is that srcOA. srcOA contract should implement this function and point the address below which manages redirection budget.
     *
     * @param redirectionBudgetManager Address pointed by the srcOA (msg.sender) executing this function.
     *        Responsible for funding srcOA redirection budget.
     */
    function withdrawOARedirectFees(address redirectionBudgetManager) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

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
     * @dev Moves `amount` of tokens from `from` to `to`.
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
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