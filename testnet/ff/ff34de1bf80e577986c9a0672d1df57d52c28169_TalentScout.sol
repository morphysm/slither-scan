/**
 *Submitted for verification at testnet.snowtrace.io on 2022-02-14
*/

// File: contracts/talentscout.sol

/**
 *Submitted for verification at testnet.snowtrace.io on 2022-02-10
*/

// File: contracts/talentscout.sol

/**
 *Submitted for verification at testnet.snowtrace.io on 2022-02-10
*/

// File: contracts/talentscout.sol

/**
 *Submitted for verification at testnet.snowtrace.io on 2022-02-10
*/

// File: contracts/talentscout.sol

/**
 *Submitted for verification at testnet.snowtrace.io on 2022-02-05
*/

// File: @chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol


pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
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


// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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

// File: contracts/talentscout.sol

/**
*Submitted for verification at testnet.snowtrace.io on 2022-01-14
*/

pragma solidity ^0.8.0;






 

 
contract Auth {
  address internal owner;
  mapping (address => bool) internal authorizations;
  constructor(address _owner) {
      owner = _owner;
      authorizations[_owner] = true;
  }
  /**
   * Function modifier to require caller to be contract owner
   */
  modifier onlyOwner() {
      require(isOwner(msg.sender), "!OWNER"); _;
  }
  /**
   * Function modifier to require caller to be authorized
   */
  modifier authorized() {
      require(isAuthorized(msg.sender), "!AUTHORIZED"); _;
  }
  /**
   * Authorize address. Owner only
   */
  function authorize(address adr) public onlyOwner {
      authorizations[adr] = true;
  }
  /**
   * Remove address' authorization. Owner only
   */
  function unauthorize(address adr) public onlyOwner {
      authorizations[adr] = false;
  }
  /**
   * Check if address is owner
   */
  function isOwner(address account) public view returns (bool) {
      return account == owner;
  }
  /**
   * Return address' authorization status
   */
  function isAuthorized(address adr) public view returns (bool) {
      return authorizations[adr];
  }
  /**
   * Transfer ownership to new address. Caller must be owner. Leaves old owner authorized
   */
  function transferOwnership(address payable adr) public onlyOwner {
      owner = adr;
      authorizations[adr] = true;
      emit OwnershipTransferred(adr);
  }
  event OwnershipTransferred(address owner);
}

interface IPangolinPair {
   
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
   
    
}


interface IDEXFactory {
  function createPair(address tokenA, address tokenB) external returns (address pair);
}
interface IWETH {
  function deposit() external payable;
  function transfer(address to, uint value) external returns (bool);
  function withdraw(uint) external;
  function balanceOf(address) external view returns(uint256);
}
interface IDEXRouter {
  function factory() external pure returns (address);
  function WAVAX() external pure returns (address);
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
contract TalentScout is IERC20,IERC20Metadata, Auth {
  using SafeMath for uint256;
 
  AggregatorV3Interface internal priceFeed;
  uint256 public constant MASK = type(uint128).max;
  address USDC = 0x288068C4feb84509fD76F92AB651E9bBD013ED46; // use USDC for now
  address public WAVAX = 0x3A0236A459215EA4F6DE50Da2A8d179B603ee8C9;
  address DEAD = 0x000000000000000000000000000000000000dEaD;
  address ZERO = 0x0000000000000000000000000000000000000000;
  address DEAD_NON_CHECKSUM = 0x000000000000000000000000000000000000dEaD;
  address VoteStakingContract;
  string constant _name = "Talent Scout Token";
  string constant _symbol = "Scout";
  uint8 constant _decimals = 18; // use 18 decimals
  uint256 _totalSupply = 1_000_000_000_000_000 * (10 ** _decimals);

  mapping (address => mapping (address => uint256)) _allowances;
  mapping(address => uint256) internal _balances;
  mapping (address => bool) isFeeExempt;
  mapping (address => bool) isDividendExempt;
  mapping(address => bool) public _whitelisted;
  

   event AutoLiquify(uint256 amountAVAX, uint256 amountBOG);

  // 0 -> buy
  // 1-> sell
  // 2 -> transfer
  FeeStructure[3] public fees;
  address public autoLiquidityReceiver;
  address public marketingFeeReceiver;
  uint256 targetLiquidity = 25;
  uint256 targetLiquidityDenominator = 100;
  IDEXRouter public router;
  address public pair;
  uint256 public launchedAt;
  uint256 public launchedAtTimestamp;
  address public distributorAddress;
  uint256 distributorGas = 500000;
  bool public swapEnabled = true;
  uint256 public swapThreshold = _totalSupply / 2000; // 0.005%
  bool inSwap;
  modifier swapping() { inSwap = true; _; inSwap = false; }
  
  struct FeeStructure {
    uint256 reflectionFee;
    uint256 voteRewardFee;
    uint256 marketingFee;
    uint256 liquidityFee;
    uint256 burnFee;
    uint256 feeDenominator;
    uint256 totalFee;
  }

 
  constructor (
      address _dexRouter,
      address _distributor,
      address aggregatorAddress
    ) Auth(msg.sender)  {
      router = IDEXRouter(_dexRouter);
      WAVAX = router.WAVAX();
      //lp pair to buy/sell
      pair = IDEXFactory(router.factory()).createPair(WAVAX, address(this));
     _allowances[address(this)][address(router)] = _totalSupply;
      priceFeed = AggregatorV3Interface(aggregatorAddress);
      _whitelisted[msg.sender] = true;
      distributorAddress = address(_distributor);
      isFeeExempt[msg.sender] = true;
      isDividendExempt[pair] = true;
      isDividendExempt[address(this)] = true;
      isDividendExempt[DEAD] = true;
      autoLiquidityReceiver = msg.sender;
      marketingFeeReceiver = msg.sender;
      approve(_dexRouter, _totalSupply);
      approve(address(pair), _totalSupply);
      _balances[msg.sender] = 1_000_000_000_000_000 * (10 ** _decimals);
      emit Transfer(address(0), msg.sender, _totalSupply);
}
 
 
   function approve(address spender, uint256 amount) public virtual override returns (bool) {
       _approve(msg.sender, spender, amount);
       return true;
   }
 
   function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
       _approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue);
       return true;
   }
 
   function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
       uint256 currentAllowance = _allowances[msg.sender][spender];
       require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
       unchecked {
           _approve(msg.sender, spender, currentAllowance - subtractedValue);
       }
 
       return true;
   }
 
  function _transfer(
       address sender,
       address recipient,
       uint256 amount
) internal virtual
    {
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
 
   
   function _mint(address account, uint256 amount) internal virtual {
       require(account != address(0), "ERC20: mint to the zero address");
 
       _beforeTokenTransfer(address(0), account, amount);
 
       _totalSupply += amount;
       _balances[account] += amount;
       emit Transfer(address(0), account, amount);
 
       _afterTokenTransfer(address(0), account, amount);
   }
 
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
 
   function _beforeTokenTransfer(
       address from,
       address to,
       uint256 amount
   ) internal virtual {}
 
  
  function _afterTokenTransfer(
       address from,
       address to,
       uint256 amount
   ) internal virtual {}

  
  function approveMax(address spender) external returns (bool) {
      return approve(spender, _totalSupply);
  }
  function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
      return _transferFrom(msg.sender, recipient, amount);
  }

  function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
      if(_allowances[sender][msg.sender] != _totalSupply){
          _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount, "Insufficient Allowance");
      }
      return _transferFrom(sender, recipient, amount);
  }

    function setwhitelistedUser(address account) external onlyOwner {
        _whitelisted[account] = true;
    }
    function removeWhitelistedUser(address account) external onlyOwner {
        require(_whitelisted[account] == true, "No Whitelisted Found");
        _whitelisted[account] = false;
    }

  function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
      if(_whitelisted[sender] == true){ return _basicTransfer(sender, recipient, amount); }
      if(_whitelisted[recipient] == true){ return _basicTransfer(sender, recipient, amount); }
      if(inSwap){ return _basicTransfer(sender, recipient, amount); }

      
      // determine fee type
      uint256 feeType;
      if (address(sender) == address(pair)) {
        feeType = 0; // buy
      } else if (address(recipient) == address(pair)) {
        feeType = 1; // sell
      } else {
        feeType = 2; // transfer
      }
      if(shouldSwapBack()){ swapBack(feeType); }
      _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
      uint256 amountReceived = shouldTakeFee(sender) ? takeFee(feeType, sender, recipient, amount) : amount;
      _balances[recipient] = _balances[recipient].add(amountReceived);
      emit Transfer(sender, recipient, amountReceived);
      return true;
  }
  function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
      _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
      _balances[recipient] = _balances[recipient].add(amount);
      emit Transfer(sender, recipient, amount);
      return true;
  }
 
  function shouldTakeFee(address sender) internal view returns (bool) {
      return !isFeeExempt[sender];
  }
  function getTotalFee(uint256 _id, bool selling) public view returns (uint256) {
      if(launchedAt + 1 >= block.number){ return fees[_id].feeDenominator.sub(1); }
      if(selling){ return getMultipliedFee(_id); }
      return fees[_id].totalFee;
  }
  function getMultipliedFee(uint256 _id) public view returns (uint256) {
      if (launchedAtTimestamp + 1 days > block.timestamp) {
          return fees[_id].totalFee.mul(18000).div(fees[_id].feeDenominator);
      }
      return fees[_id].totalFee;
  }
  function takeFee(uint256 _id, address sender, address receiver, uint256 amount) internal returns (uint256) {
      uint256 feeAmount = amount.mul(getTotalFee(_id, receiver == pair)).div(fees[_id].feeDenominator);
      _balances[address(this)] = _balances[address(this)].add(feeAmount);
      emit Transfer(sender, address(this), feeAmount);
      return amount.sub(feeAmount);
  }
  function shouldSwapBack() internal view returns (bool) {
      return msg.sender != pair
      && !inSwap
      && swapEnabled
      && _balances[address(this)] >= swapThreshold;
  }
  function swapBack(uint256 _id) internal  swapping {
      uint256 dynamicLiquidityFee = isOverLiquified(targetLiquidity, targetLiquidityDenominator) ? 0 : fees[_id].liquidityFee;
      uint256 amountToLiquify = swapThreshold.mul(dynamicLiquidityFee).div(fees[_id].totalFee).div(2);
      address[] memory path = new address[](2);
      path[0] = address(this);
      path[1] = WAVAX;
      uint256 balanceBefore = address(this).balance;
      router.swapExactTokensForETHSupportingFeeOnTransferTokens(
          swapThreshold.sub(amountToLiquify), // amount to swap
          0,
          path,
          address(this),
          block.timestamp
      );
     
      uint256 amountAVAX = address(this).balance.sub(balanceBefore);
      uint256 totalAVAXFee = fees[_id].totalFee.sub(dynamicLiquidityFee.div(2));
      uint256 amountAVAXLiquidity = amountAVAX.mul(dynamicLiquidityFee).div(totalAVAXFee).div(2);
      uint256 amountAVAXReflection = amountAVAX.mul(fees[_id].reflectionFee).div(totalAVAXFee);
      uint256 amountAVAXMarketing = amountAVAX.mul(fees[_id].marketingFee).div(totalAVAXFee);
      uint256 amountAVAXBurned = amountAVAX.mul(fees[_id].burnFee).div(totalAVAXFee);
      uint256 amountAVAXRewarded = amountAVAX.mul(fees[_id].voteRewardFee).div(totalAVAXFee);
      IWETH(WAVAX).withdraw(amountAVAXRewarded);
      assert(IWETH(WAVAX).transfer(VoteStakingContract, amountAVAXRewarded));
      IWETH(WAVAX).withdraw(amountAVAXReflection);
      assert(IWETH(WAVAX).transfer(distributorAddress, amountAVAXReflection));
      IWETH(WAVAX).withdraw(amountAVAXMarketing);
      assert(IWETH(WAVAX).transfer(marketingFeeReceiver, amountAVAXMarketing));
      burn(amountAVAXBurned);
        
      if(amountToLiquify > 0){
          router.addLiquidityETH{value: amountAVAXLiquidity}(
              address(this),
              amountToLiquify,
              0,
              0,
              autoLiquidityReceiver,
              block.timestamp
          );
          emit AutoLiquify(amountAVAXLiquidity, amountToLiquify);
      }
  }
 
  // any account can burn anyone's token
  function burn(uint256 amount) public onlyOwner {
      _balances[address(this)] = _balances[address(this)].sub(amount);
      emit Transfer(address(this), address(0), amount);
     
  }
  function setVoteStakingContract(address _voteStakingContract) external onlyOwner{
      VoteStakingContract =  _voteStakingContract;
  }
  function buyTokens(uint256 amount, address to) internal swapping {
      address[] memory path = new address[](2);
      path[0] = WAVAX;
      path[1] = address(this);
      router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(
          0,
          path,
          to,
          block.timestamp
      );
  }
  function launched() internal view returns (bool) {
      return launchedAt != 0;
  }
  function launch() public authorized {
      require(launchedAt == 0, "Already launched boi");
      launchedAt = block.number;
      launchedAtTimestamp = block.timestamp;
  }
  function setIsDividendExempt(address holder, bool exempt) external authorized {
      require(holder != address(this) && holder != pair);
      isDividendExempt[holder] = exempt;
      // if (exempt) {
      //     distributor.setShare(holder, 0);
      // } else {
      //     distributor.setShare(holder, _balances[holder]);
      // }
  }
  function setIsFeeExempt(address holder, bool exempt) external authorized {
      isFeeExempt[holder] = exempt;
  }

  function setFeeReceivers(address _autoLiquidityReceiver, address _marketingFeeReceiver) external authorized {
      autoLiquidityReceiver = _autoLiquidityReceiver;
      marketingFeeReceiver = _marketingFeeReceiver;
  }
  function setSwapBackSettings(bool _enabled, uint256 _amount) external authorized {
      swapEnabled = _enabled;
      swapThreshold = _amount;
  }
  function setTargetLiquidity(uint256 _target, uint256 _denominator) external authorized {
      targetLiquidity = _target;
      targetLiquidityDenominator = _denominator;
  }
  function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external authorized {
      // distributor.setDistributionCriteria(_minPeriod, _minDistribution);
  }
  function setDistributorSettings(uint256 gas) external authorized {
      require(gas < 750000);
      distributorGas = gas;
  }
 
  function isOverLiquified(uint256 target, uint256 accuracy) public view returns (bool) {
      return getLiquidityBacking(accuracy) > target;
  }
 
  function setFees(uint256 _id, uint256 _liquidityFee, uint256 _burnFee, uint256 _reflectionFee, uint256 _voteRewardFee, uint256 _marketingFee, uint256 _feeDenominator) external authorized {
      require(_id < 3, "Invalid Fee Id");
      fees[_id].liquidityFee = _liquidityFee;
      fees[_id].burnFee = _burnFee;
      fees[_id].reflectionFee = _reflectionFee;
      fees[_id].voteRewardFee = _voteRewardFee;
      fees[_id].marketingFee = _marketingFee;
      fees[_id].totalFee = _liquidityFee.add(_reflectionFee).add(_voteRewardFee).add(_burnFee).add(_marketingFee);
      fees[_id].feeDenominator = _feeDenominator;
      require(fees[_id].totalFee < fees[_id].feeDenominator / 5);
  }


  /* GETTERS */
 function getCirculatingSupply() public view returns (uint256) {
      return _totalSupply.sub(balanceOf(ZERO));
}
 
function getAVAXPrice() public view returns (uint256) {
       (
           uint80 roundID,
           int price,
           uint startedAt,
           uint timeStamp,
           uint80 answeredInRound
       ) = priceFeed.latestRoundData();
       return uint256(price);
}

function getCurrentPrice() public view returns (uint256){
//    uint256 balance0 =IWETH(WAVAX).balanceOf(pair); //wavax balance in pair
 
//    uint256 balance1 = balanceOf(pair); //talent scout balance in pair
//    if(balance1 == 0){ return 0;}
//    uint256 ratio = balance0.div(balance1); //token price in WAVAX
//    uint256 priceInDollars = ratio.mul(getPrice());

    

   (uint256 balance0, uint256 balance1, ) = IPangolinPair(pair).getReserves();
   if(balance1 == 0){ return 0;}
   uint256 ratio = balance0.div(balance1); //token price in WAVAX
   uint256 priceInDollars = ratio.mul(getAVAXPrice());
   return priceInDollars;

}

function getLiquidityBacking(uint256 accuracy) public view returns (uint256) {
      return accuracy.mul(balanceOf(pair).mul(2)).div(getCirculatingSupply());
}
  

   
  /* ERC20 GETTERS */

   function name() public view virtual override returns (string memory) {
       return _name;
   }
 
   function symbol() public view virtual override returns (string memory) {
       return _symbol;
   }
 
   function decimals() public view virtual override returns (uint8) {
       return 18;
   }
 
   function totalSupply() public view virtual override returns (uint256) {
       return _totalSupply;
   }
 
   function balanceOf(address account) public view virtual override returns (uint256) {
       return _balances[account];
   }

   
   function allowance(address owner, address spender) public view virtual override returns (uint256) {
       return _allowances[owner][spender];
   }
}