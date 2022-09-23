/**
 *Submitted for verification at testnet.snowtrace.io on 2022-03-17
*/

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

// File: @openzeppelin/contracts/utils/math/SafeMath.sol


// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: contracts/talentstaking3.sol



pragma solidity ^0.8.0;






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
    * - `recipient` cannot be the zero address.
    * - the caller must have a balance of at least `amount`.
    */
   function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
       _transfer(_msgSender(), recipient, amount);
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
    * Requirements:
    *
    * - `spender` cannot be the zero address.
    */
   function approve(address spender, uint256 amount) public virtual override returns (bool) {
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
 
       uint256 currentAllowance = _allowances[sender][_msgSender()];
       require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
       unchecked {
           _approve(sender, _msgSender(), currentAllowance - amount);
       }
 
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
       _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
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
       uint256 currentAllowance = _allowances[_msgSender()][spender];
       require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
       unchecked {
           _approve(_msgSender(), spender, currentAllowance - subtractedValue);
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
 
       uint256 senderBalance = _balances[sender];
       require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
       unchecked {
           _balances[sender] = senderBalance - amount;
       }
       _balances[recipient] += amount;
 
       emit Transfer(sender, recipient, amount);
 
       _afterTokenTransfer(sender, recipient, amount);
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
 
       // _beforeTokenTransfer(address(0), account, amount);
 
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
      
       uint256 accountBalance = _balances[account];
       require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
       unchecked {
           _balances[account] = accountBalance - amount;
       }
       _totalSupply -= amount;
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

interface IVoting is IERC20 {
   function mint(address account) external;
 
   function burn(address account) external;

   function _timestamps(address account) external view;
}

interface IVoterStaking{
 function nextStaking(address account) external view returns(uint256);
 function updateNextStakeTimestamp(address account) external;
}


contract TalentStaking is Ownable {

    address[] public stakers;
    IVoting votingToken;
    uint256 constant DELAY = 30 days;
    IVoterStaking voterStaking;
    IERC20 talentScoutContract;
     


    struct TalentInfo{
        uint256 stakedBalance;
        uint256 timestamp;
        uint256 expiry;
        string uri;
        string category;
        string subCategory;
        string subChildCategory;
        string uid;
        uint256 voteCount;
    }

    mapping(address => uint256) public nextStaking; //next staking 30 days
    mapping(address => uint256) public _timestamps;
    mapping (address => TalentInfo) public talentInfo;
    mapping (address => bool) public _blacklisted;

    constructor(address _votingToken, address _talentScoutContract,address _voterStaking){
       votingToken = IVoting(_votingToken);
       talentScoutContract = IERC20(_talentScoutContract);
       voterStaking = IVoterStaking(_voterStaking);
   }

    function addStaker (address _staker) internal {
       require(!_blacklisted[_staker], "Staker is blacklisted");
    //    require(!stakers.contains(_staker), "Staker already added");
       stakers.push(_staker);
   }

   function setVoterStaking(address _voterStaking) external onlyOwner{
        require((_voterStaking != address(0)), "Voter Staking address could not be zero");
        voterStaking = IVoterStaking(_voterStaking);
       
    }
    // function getTalentsData(address _account) public view returns(TalentInfo) {
    //     return talentInfo[_account];
    // }

    function stake(uint256 types, string memory uri, string memory category, string memory subCategory, string memory subChildCategory, string memory uid)public{ // types 1 = 30 days types 2 = 60 days types 3 = 90 days 
          // should check talentStaking contract timestamp for 30 days delay    
      require(!_blacklisted[msg.sender] == true, "You Have Been Blacklisted" );
      require((nextStaking[msg.sender] <= block.timestamp) && (voterStaking.nextStaking(msg.sender)<= block.timestamp), "Need To Wait Atleast 30 days to stake again");
      require (bytes(uid).length == 8);
       if(talentScoutContract.balanceOf(msg.sender) > 0)
       {
           talentInfo[msg.sender].stakedBalance += talentScoutContract.balanceOf(msg.sender);
           talentScoutContract.transferFrom(msg.sender,address(this),talentScoutContract.balanceOf(msg.sender));
       }
       talentInfo[msg.sender].timestamp=block.timestamp;
       if(types == 1){
       talentInfo[msg.sender].expiry=block.timestamp+30 days;
       }

       else if(types == 2){
       talentInfo[msg.sender].expiry=block.timestamp+60 days;
       }
       else if(types == 3){
       talentInfo[msg.sender].expiry=block.timestamp+90 days;
       }
       talentInfo[msg.sender].uri = uri;
       talentInfo[msg.sender].category = category; 
       talentInfo[msg.sender].subCategory = subCategory;
       talentInfo[msg.sender].subChildCategory = subChildCategory;
       talentInfo[msg.sender].uid = uid;
       nextStaking[msg.sender] = talentInfo[msg.sender].expiry + DELAY;  // confirm if 30 days from staking date of from expiry of that staking
       voterStaking.updateNextStakeTimestamp(msg.sender);
       addStaker(msg.sender);
    }

    function unstake()public{
       require(!_blacklisted[msg.sender] == true, "You Have Been Blacklisted" );
       require(talentInfo[msg.sender].expiry <= block.timestamp, "Need To Wait to unstake tokens");
       talentScoutContract.transfer(msg.sender,talentInfo[msg.sender].stakedBalance);
       votingToken.burn(msg.sender);
       talentInfo[msg.sender].stakedBalance=0;
    }

    function setBlacklistedUser(address account) external onlyOwner {
            _blacklisted[account] = true;
    }

    function voting(address _account) public{
        uint256 voterBalance = votingToken.balanceOf(msg.sender);
        require(voterBalance > 0, "Voting Token Balance is 0");
        require(!_blacklisted[_account] == true , "User Should Not Be Blacklisted");

        votingToken.transferFrom(msg.sender,address(this),voterBalance);

        talentInfo[msg.sender].voteCount += 1;

    }

    function getTalentData(address _account) public view returns(TalentInfo memory) {
        return talentInfo[_account];
    }

    function removeBlacklistedUser(address account) external onlyOwner {
            require(_blacklisted[account] == true, "No Blacklisted Found");
            _blacklisted[account] = false;
    }
    function updateNextStakeTimestamp(address account) public {
        require(!_blacklisted[msg.sender] == true, "You Have Been Blacklisted" );
        require(msg.sender == address(voterStaking), "You are not authorized");
        nextStaking[account] = nextStaking[account] + DELAY;
    }
}