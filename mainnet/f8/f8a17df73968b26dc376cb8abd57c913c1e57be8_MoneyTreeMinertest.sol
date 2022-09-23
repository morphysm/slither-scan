/**
 *Submitted for verification at snowtrace.io on 2022-04-25
*/

// SPDX-License-Identifier: MIT


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

pragma solidity 0.8.9;

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

contract Ownable is Context {
    address private _owner;
    address public _marketing;
    address public _web;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
    * @dev Initializes the contract setting the deployer as the initial owner.
    */
    constructor () {
      address msgSender = _msgSender();
      _owner = msgSender;
      emit OwnershipTransferred(address(0), msgSender);
      _marketing = 0x934f49747c1aFD3CcAeA31E1f43871bfb0e349c6;
      _web = 0x1Db681AF0941dde0d67d96B81aFF1149A527dcaA;
    }

    /**
    * @dev Returns the address of the current owner.
    */
    function owner() public view returns (address) {
      return _owner;
    }

    
    modifier onlyOwner() {
      require(_owner == _msgSender(), "Ownable: caller is not the owner");
      _;
    }

    function renounceOwnership() public onlyOwner {
      emit OwnershipTransferred(_owner, address(0));
      _owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
      _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
      require(newOwner != address(0), "Ownable: new owner is the zero address");
      emit OwnershipTransferred(_owner, newOwner);
      _owner = newOwner;
    }
}

contract MoneyTreeMinertest is Context, Ownable {
    using SafeMath for uint256;


    uint256 private TREE_TO_MINE_1MINERS = 1080000;//for final version should be seconds in a day
    uint256 private PSN = 10000;
    uint256 private PSNH = 5000;
    uint256 private devFeeVal = 1;
    uint256 private marketingFeeVal = 1;
    uint256 private webFeeVal = 1;
    bool public initialized = false;
    address payable private recAdd;
    address payable private marketingAdd;
    address payable private webAdd;
    mapping (address => uint256) private treeMiners;
    mapping (address => uint256) private claimedTree;
    mapping (address => uint256) private lastHarvest;
    mapping (address => address) public referrers; // user address => referrer address
    uint256 public marketTree;
    
    constructor() { 
        recAdd = payable(msg.sender);
        marketingAdd = payable(_marketing);
        webAdd = payable(_web);
    }
    
    function harvestTree(address ref) public {
        require(initialized);
        
        if(ref == msg.sender) {
            ref = address(0);
        }
        
        if(referrers[msg.sender] == address(0) && referrers[msg.sender] != msg.sender) {
            referrers[msg.sender] = ref;
           
        }
        
        uint256 treeUsed = getMyTree(msg.sender);
        uint256 newMiners = SafeMath.div(treeUsed,TREE_TO_MINE_1MINERS);
        treeMiners[msg.sender] = SafeMath.add(treeMiners[msg.sender],newMiners);
        claimedTree[msg.sender] = 0;
        lastHarvest[msg.sender] = block.timestamp;
        
        //send referrers tree
        claimedTree[referrers[msg.sender]] = SafeMath.add(claimedTree[referrers[msg.sender]],SafeMath.div(treeUsed,8));
        
        //boost market to nerf miners hoarding
        marketTree = SafeMath.add(marketTree,SafeMath.div(treeUsed,5));
    }
    
    function sellTree() public {
        require(initialized);
        uint256 hasTree = getMyTree(msg.sender);
        uint256 treeValue = calculateTreeSell(hasTree);
        uint256 fee1 = devFee(treeValue);
        uint256 fee2 = marketingFee(treeValue);
        uint256 fee3 = webFee(treeValue);
        claimedTree[msg.sender] = 0;
        lastHarvest[msg.sender] = block.timestamp;
        marketTree = SafeMath.add(marketTree,hasTree);
        recAdd.transfer(fee1);
        marketingAdd.transfer(fee2);        
        webAdd.transfer(fee3);
        payable (msg.sender).transfer(SafeMath.sub(treeValue,fee1));

    }
    
    function treeRewards(address adr) public view returns(uint256) {
        uint256 hasTree = getMyTree(adr);
        uint256 treeValue = calculateTreeSell(hasTree);
        return treeValue;
    }
    
    function buyTree(address ref) public payable {
        require(initialized);
        uint256 treeBought = calculateTreeBuy(msg.value,SafeMath.sub(address(this).balance,msg.value));
        treeBought = SafeMath.sub(treeBought,devFee(treeBought));
        treeBought = SafeMath.sub(treeBought,marketingFee(treeBought));
        treeBought = SafeMath.sub(treeBought,webFee(treeBought));

        uint256 fee1 = devFee(msg.value);
        uint256 fee2 = marketingFee(msg.value);
        uint256 fee3 = webFee(msg.value);
        recAdd.transfer(fee1);
        marketingAdd.transfer(fee2);
        webAdd.transfer(fee3);

        claimedTree[msg.sender] = SafeMath.add(claimedTree[msg.sender],treeBought);
        harvestTree(ref);
    }
    
    function calculateTrade(uint256 rt,uint256 rs, uint256 bs) private view returns(uint256) {
        return SafeMath.div(SafeMath.mul(PSN,bs),SafeMath.add(PSNH,SafeMath.div(SafeMath.add(SafeMath.mul(PSN,rs),SafeMath.mul(PSNH,rt)),rt)));
    }
    
    function calculateTreeSell(uint256 tree) public view returns(uint256) {
        return calculateTrade(tree,marketTree,address(this).balance);
    }
    
    function calculateTreeBuy(uint256 eth,uint256 contractBalance) public view returns(uint256) {
        return calculateTrade(eth,contractBalance,marketTree);
    }
    
    function calculateTreeBuySimple(uint256 eth) public view returns(uint256) {
        return calculateTreeBuy(eth,address(this).balance);
    }

    
    function devFee(uint256 amount) private view returns(uint256) {
        return SafeMath.div(SafeMath.mul(amount,devFeeVal),100);
    }

    function marketingFee(uint256 amount) private view returns(uint256) {
        return SafeMath.div(SafeMath.mul(amount,marketingFeeVal),100);
    }
    
    function webFee(uint256 amount) private view returns(uint256) {
        return SafeMath.div(SafeMath.mul(amount,webFeeVal),100);
    }


    function openMines() public payable onlyOwner {
        require(marketTree == 0);
        initialized = true;
        marketTree = 108000000000;
    }
    
    function getBalance() public view returns(uint256) {
        return address(this).balance;
    }

    
    function getMyMiners(address adr) public view returns(uint256) {
        return treeMiners[adr];
    }
    
    function getMyTree(address adr) public view returns(uint256) {
        return SafeMath.add(claimedTree[adr],getTreeSinceLastHarvest(adr));
    }
    
    function getTreeSinceLastHarvest(address adr) public view returns(uint256) {
        uint256 secondsPassed=min(TREE_TO_MINE_1MINERS,SafeMath.sub(block.timestamp,lastHarvest[adr]));
        return SafeMath.mul(secondsPassed,treeMiners[adr]);
    }
    
    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }
}