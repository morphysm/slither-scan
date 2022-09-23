// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./TaxToken.sol";

/** 
    @title CryptoTaxReducer.sol
    @author https://twitter.com/CryptTaxReducer
    
    @dev This contract helps people swap unsellable tokens to the TAX token on Avalanche C-Chain.
    The reason for people to want to swap unsellable tokens in general, is because there might be alot of value for 
    people sitting in tokens that could potentially lower their taxes, if a swap of these
    could generate a loss.

    The procedure for this is the following:

    *   Step 1:
        User approves USDC token for paying fees, and approves the tokens he/she want to swap.

    *   Step 2:
        The user 'clears' their tokens, and pay a small fee for that.
        This clearance temporarely sets the tokens in a whitelist state, and makes
        it possible to swap in the final step.
        Once the users tokens are cleared, they stay cleared until a swap is done on that tokencontract.

    *   Step 3:
        In the final step, the user can then swap their tokens, and will receive 1 TAX token in return.
        The clearance for that tokencontract will also be removed from the whitelist.


    Regarding the users tokens:
    In order to use this service, the tokens need to have approve and transferFrom functions 
    fully working.
    Also, users need to check so that the tokens they want to swap is safe to interact with.
    I take no responsibility for users lost funds/tokens due to interactions with tokencontracts
    containning malisciuous code.

    There is no guarantee that this method to lower taxes will work for all users.
    There might be cases this method is not allowed.
    People that are not doing their crypto taxes will likely not gain anything from this service,
    unless they got other reasons to swap useless/worthless tokens. 
*/


contract CryptoTaxReducer is Ownable {
    
    /*  State variables */
    IERC20 immutable public taxToken; // Set once in the constructor.
    IERC20 immutable public usdc; // Set once in the constructor.

    uint public numberOfTaxTokenSent;
    uint public tokensToTransfer; 
    uint public usdcFee;
    
    //  Contract set to be able to be paused. 
    //  If at any point set to ´false´, contract will not be able to be paused in the future.
    bool public canPause = true;   
    bool public paused = false; // Contract is initially set to  not paused.

    /*  Mapping */
    mapping (address => User) Users;

    /*  Struct */
    struct User {
        uint totalTokensClearedByUser; // User counter for number of cleared tokens, based on contracts. 
        mapping (address => bool) tokenContracts;}

    /*  Events */ 
    event FeePaid (
        address user, 
        uint fee, 
        address token
        );
    
    event SwapCompleted (
        address user, 
        address yourTokenAddress, 
        uint yourTokenAmount, 
        uint tokensToTransfer
        );

    /*  Constructor */
    constructor(address taxTokenAddr) {
        usdcFee = 10 * 10 ** 6; // Initial fee set to 10 USDC.
        usdc = IERC20(0xB97EF9Ef8734C71904D8002F8b6Bc66Dd9c48a6E); // USDC on Avalanche C-Chain.
        taxToken = IERC20(taxTokenAddr); // Address passed in constructor.
        tokensToTransfer = 1 * 10 ** 18; // For each swap, user will receive 1 TAX token.
        numberOfTaxTokenSent = 0; // Total number of TAX tokens sent to users set to zero.
     }

    /*   
        Used for paying fees and clear a token for swap. (The actual swapfunction can be 
        executed at any time as long as the contract is not paused, the fee is paid 
        and the token is cleared and approved)
    */
    function payUsdcFeeAndClearToken(address clearToken) public returns (address) {
        // Check if contract is paused
        require(paused == false, "Contract is currently paused");

        IERC20 userToken = IERC20(clearToken);
        uint fee = usdcFee;
        bool checkTokenCleared = false; 

        // Check approvals, allowances, fee and that the token is not yet cleared.
        // If the token is already cleared, there is no need to clear it again. 
        checkTokenCleared = checkTokenClearance(msg.sender, clearToken);
        require(checkTokenCleared == false, "Fee has already been paid for this token");
        uint vendorBalance = taxToken.balanceOf(address(this));
        require (vendorBalance >= tokensToTransfer, "The vendor do not hold enough tokens to make a swap possible at the moment. Please check again later");
        uint usdcAllowance = usdc.allowance(msg.sender, address(this));
        require(usdcAllowance >= fee, "You need to approve enough USDC for the fee");
        uint usdcBalance = usdc.balanceOf(msg.sender);
        require (usdcBalance >= fee, "Your balance of USDC is not enough to pay the fee");
        uint userTokenBalance = userToken.balanceOf(msg.sender);
        require (userTokenBalance > 0, "You do not hold any tokens from this tokencontract, please check the address again");
        
        // Sends USDC fee from user to contract, and clears the token for swap.
        bool receivedFee = usdc.transferFrom(msg.sender,address(this), fee);
        require (receivedFee, "USDC fee could not be paid");
        bool tokenAddressToTrue = _setTokenClearance(msg.sender, clearToken);
        require (tokenAddressToTrue, "The token could not be cleared");

        emit FeePaid(msg.sender, fee, clearToken);
        return clearToken;
    }

    /* 
        Sends approved tokens from user to contract, and sends 1 TAX token back to user.
    */
    function swapTokens(address yourTokenAddress, uint yourTokenAmount) public returns (bool swapComplete) {
        // Check if contract is paused
        require(paused == false, "Contract is currently paused");

        IERC20 userToken = IERC20(yourTokenAddress);
        bool clearedToken = false;     
        bool sentTokenToUser = false;
        bool receivedTokenFromUser = false;

        // Check balances, allowances and that the users token is cleared.        
        clearedToken = checkTokenClearance(msg.sender, yourTokenAddress);
        require(clearedToken == true, "You need to clear the token prior to swap");
        uint allowance = IERC20(yourTokenAddress).allowance(msg.sender, address(this));
        require(allowance >= yourTokenAmount, "You need to set enough allowance for your tokens");
        uint vendorBalance = taxToken.balanceOf(address(this));
        require (vendorBalance >= tokensToTransfer, "The vendor do not hold enough tokens to make a swap possible at the moment. Please check again later");  
        uint userTokenBalance = userToken.balanceOf(msg.sender);
        require (userTokenBalance > 0, "You do not hold any tokens from this tokencontract, please check the address again");

        // Sets tokenclearence back to 'false' (not cleared).
        bool  tokenAddrToFalse = _clearTokenClearance(msg.sender, yourTokenAddress);
        require(tokenAddrToFalse, "Clearence for the token could not be set back to uncleared state");

        // Receives tokens from user, and sends TAX token back.
        receivedTokenFromUser = userToken.transferFrom(msg.sender,address(this), yourTokenAmount);
        require(receivedTokenFromUser, "Tokens could not be sent from the user");          
        sentTokenToUser = taxToken.transfer(msg.sender, tokensToTransfer);
        require(sentTokenToUser, "TAX token could not be sent to the user");
        numberOfTaxTokenSent += 1;

        emit SwapCompleted (msg.sender, yourTokenAddress, yourTokenAmount, tokensToTransfer);
        return swapComplete;
    } 

    /*
        Let the owner set a new USDC fee. 
        (ownlyOwner)
    */
    function setUsdcFee(uint newFee) public onlyOwner returns (uint) {
        usdcFee = newFee;
        return usdcFee;
    }

    /*
        Let the owner withdraw funds from the contract. 
        (ownlyOwner)
    */
    function withdrawFunds() public payable onlyOwner returns (bool sent) {
        uint balance = address(this).balance;
        require(balance > 0, "Owner have no funds to withdraw");
        (bool sentToOwner, ) = msg.sender.call{value: balance}("");
        require(sentToOwner, "Failed to send funds to owner");
        return sent;
    }

    /*
        Let the owner withdraw tokens from the contract. 
        (ownlyOwner)
    */
    function withdrawTokens(address token) public onlyOwner returns (bool sent) {
        IERC20 tokenContract = IERC20(token);
        uint tokenBalance = tokenContract.balanceOf(address(this));
        require(tokenBalance > 0,"Insufficient tokens with that address in contract");
        (bool sentTokensToOwner) = tokenContract.transfer(msg.sender, tokenBalance);
        require(sentTokensToOwner, "Failed to send tokens to owner");
        return sent;
    }

    /*
        Returns the total number of tokens cleared by a user.
    */
    function getTokensClearedByUser(address user) public view returns (uint) {
        User storage checkUser = Users[user];
        return checkUser.totalTokensClearedByUser;
    }

    /*  
        Sets "clearance" for a specific tokenaddress to 'true'.
        Meaning, this contract address (this token) is now ready for swap.
    */
    function _setTokenClearance(address user, address clearToken) private returns (bool) {
        // Check if contract is paused
        require(paused == false, "Contract is currently paused");

        User storage setUser = Users[user];
        (setUser.tokenContracts[clearToken]) = true;
        setUser.totalTokensClearedByUser += 1;   
        return true;   
    }

    /*  
        Clears a specific "clearance" for a specific tokenaddress bacl to 'false'.
        Meaning, this contract address (this token) is not ready for swap anymore unless
        a fee is paid again.
    */
    function _clearTokenClearance(address user, address removeToken) private returns (bool) {
        // Check if contract is paused
        require(paused == false, "Contract is currently paused");
        
        User storage setUser = Users[user];
        (setUser.tokenContracts[removeToken]) = false;
        return true;   
    }

    /*  
        Allows the owner to pause some functions in the contract if needed.
        (ownlyOwner)
    */
    function setPaused(bool _paused) public onlyOwner {
        require(canPause == true, "You are not able to pause the contract anymore");
        paused = _paused;
   }

    /*  
        Allows the owner to permanently remove the pause function for the contract.
        (ownlyOwner)
    */
    function removePauseCapability() public onlyOwner {
        paused = false;
        canPause = false;
   }

    /*  
        Resetting counter for TAX tokens sent, if needed for any reason.
        (ownlyOwner)
    */
    function resetNumberOfTaxTokensSent() public onlyOwner {
        numberOfTaxTokenSent = 0;
    }

    /*  
        Sets a new amount of TAX tokens to be sent out for each swap.
        (ownlyOwner)        
    */
    function setTokensToTransfer(uint amount) public onlyOwner {
        tokensToTransfer = amount;
    }

    /*
        Checks if a specific token is cleared for the user. (Returns true if it is)
    */
    function checkTokenClearance(address user, address tokenAddress) public view returns (bool) {
        User storage checkUser = Users[user];
        return (checkUser.tokenContracts[tokenAddress]);
    }

    /*  
        Checks if a specific token is cleared for the user. (Returns a string)
    */
    function checkTokenClearanceString(address user, address tokenAddress) public view returns (string memory) {
        string memory cleared = "This token is cleared for swap";
        string memory notCleared = "This token is not cleared for swap";

        User storage checkUser = Users[user];
        bool addressCheck = (checkUser.tokenContracts[tokenAddress]);

        if (addressCheck) {
            return cleared;
        } else {
            return notCleared;
        }    
    }
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
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TaxToken is ERC20, Ownable {

    constructor() ERC20("Taxtoken", "TAX") {
        _mint(msg.sender, 1000000 * 10 ** decimals());
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
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