/**
 *Submitted for verification at snowtrace.io on 2022-01-12
*/

// SPDX-License-Identifier: Unlicensed

/**
   
   Shibies WTREATS liquidity lock contract
   
   WTREATS held by this contract can only be added to the liquidity pool specified in the WTREATS contract.
   The addition of liquidity is initially only allowed for Shibies Deployer and
   will be controlled by our voting contract in the future.
   LP tokens are automatically sent to our burn address.
   
   Small update with slippage and pool control.
   With modifications for compatibility with the Trader Joe Router.
   
   WTREATS contract address: 0xBBCA403C20aD0932d0509af0132897a25aB1ebe0
   Burn address: 0xdEAD000000000000000042069420694206942069

 */
 
pragma solidity 0.8.2;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
	function approve(address spender, uint256 amount) external returns (bool);
	function isExcludedFromFee(address account) external returns (bool);
	function uniswapV2Router() external returns (IJoeRouter02);
	function uniswapV2Pair() external returns (address);
}

// interface for start voting in the voting contract
interface Voter {
    function startVote(bytes32 hash, string memory vote) external returns (bool);
}

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
 
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
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
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
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
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
     * opcode (which leaves remaining gas untouched) while Solidity uses an
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
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

/**
 * @dev Collection of functions related to the address type
 */
library Address {
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
     */
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

// pragma solidity >=0.6.2;

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

// File: contracts/traderjoe/interfaces/IJoeRouter02.sol

pragma solidity >=0.6.2;

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


contract ShibiesLiquidityLock is Context {
    using SafeMath for uint256;

    // primary controller of the token contract
    address public vault;
    
    // burn address of lp-token
    address public burnAddress = 0xdEAD000000000000000042069420694206942069;

    // set of operators, can be this address or other addresses
    mapping(address => bool) public isOperator;

    // list of operators for votes of the token contract
    address[] private operators;
    
    uint256 private transFee;

    address public  wtreats = 0xBBCA403C20aD0932d0509af0132897a25aB1ebe0;

    // configurable delay for voting   
    uint public delay = 7*24*3600;
    
    // voting variables
    uint public delayVote;
    bytes32 public pendingVote;
    string public lastVote;
    uint256 private votingInt;

    // swap variables
    IJoeRouter02 public immutable uniswapV2Router;
    address public immutable uniswapV2Pair;    
    
    event LogChangeVault(address indexed auth, uint timestamp);
    event LogAddOperator(address indexed auth, uint timestamp);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );

     modifier onlyOperator() {
        require(isOperator[msg.sender], "FORBIDDEN, only operator");
        _;
    }

    modifier onlyVault() {
        require(msg.sender == vault, "FORBIDDEN, only vault");
        _;
    }
    
    function balanceLocked() public view returns (uint256) {
        return IERC20(wtreats).balanceOf(address(this));
    }

    constructor(){
        require(IERC20(wtreats).uniswapV2Pair() != address(0), "No pool created yet");
        vault = 0x480a891b2c60F73769c0A8a6b689DD63A5964172;
        isOperator[vault] = true;
        operators.push(vault);
        
	    // set wtreats pool for liquidity        
        uniswapV2Router = IJoeRouter02(0x60aE616a2155Ee3d9A68541Ba4544862310933d4);
        uniswapV2Pair = IERC20(wtreats).uniswapV2Pair();
    }
    
    // get list of operators
    function getAllOperators() external view returns (address[] memory) {
        return operators;
    }
    
     // to recieve ETH from uniswapV2Router when swaping
    receive() external payable {}
	
	// start community voting for add liquidity
    function voteLiquidate(uint256 amount) external onlyOperator {
	    require(balanceLocked() >= amount, "Amount is higher than contract balance!");
		require(balanceLocked() != 0, "No Liquidity available!");
        if(isOperator[vault]){
           swapAndLiquify(amount); 
           return;
        }
        string memory voteName = " TREATS in liquidity pool";
        setVoteTitelInt(voteName, amount);
    }                       
    
    // set new delay via community voting
    function setDelay(uint256 day) external onlyVault returns (bool) {
        require(day >= 3, "Delay cannot be less than 3 days!");
        require(day <= 30, "Delay cannot be more than 30 days!");
        delay = day*24*3600;
        return true;
    }
    
    // add new operator via community voting
    function setOperator(address _auth) external onlyVault returns (bool) {
        isOperator[_auth] = true;
        operators.push(_auth);
        emit LogAddOperator(_auth, block.timestamp);
        return true;
    }
    
    // set new owner via community voting
    function setVault(address _vault) external onlyVault returns (bool) {
        vault = _vault;
        emit LogChangeVault(_vault, block.timestamp);
        return true;
    }
    
    // revoke operator via community voting
    function revokeOperator(address _auth) external onlyVault returns (bool) {
        isOperator[_auth] = false;
        for (uint256 i = 0; i < operators.length; i++) {
            if (operators[i] == _auth) {
                if(i != (operators.length - 1)){operators[i] = operators[operators.length - 1];}
                operators.pop();
                break;
            }
        }
        return true;
    }
    
    // get voting result from voting contract and execute if result is true
    function endVote(bytes32 hash, bool result) external onlyVault returns (bool) {
        require(pendingVote == hash, "Vote could not be found!");
        require(block.timestamp >= delayVote, "Voting time not over!");
        if(result){
            swapAndLiquify(votingInt);
        }
        pendingVote = "";
        return true;
    }
    
    // set vote titel and hash id and save voting variables
    function setVoteTitelInt(string memory titel, uint256 amount) private {
        lastVote = string(abi.encodePacked(uintToString(amount/10**18), titel));
        pendingVote = keccak256(
                abi.encode(keccak256(bytes(lastVote)),
                keccak256(abi.encodePacked(block.timestamp)),
                keccak256(abi.encodePacked(address(this)))));
                
        Voter(vault).startVote(pendingVote, lastVote);
        votingInt = amount;
        delayVote = block.timestamp + delay;
        return;
    }

    //Swap half of amount to ETH and add it with other half to liquidity pool
    function swapAndLiquify(uint256 amount) private {
        if(!IERC20(wtreats).isExcludedFromFee(address(this))){
        setFee(amount.div(2));
        amount = amount.sub(amount.mul(transFee).div(10**2));
        }
        // split the amount into halves
        uint256 half = amount.div(2);
        uint256 poolRate = half.mul(10**3).div(IERC20(wtreats).balanceOf(uniswapV2Pair).add(half));
        if(poolRate > 1){
           half = half.sub(half.mul(poolRate).div(2).div(10**3));
        }
        uint256 otherHalf = amount.sub(half);

        // capture the contract's current ETH balance.
        // this is so that we can capture exactly the amount of ETH that the
        // swap creates, and not make the liquidity event include any ETH that
        // has been manually sent to the contract
        uint256 initialBalance = address(this).balance;

        // swap tokens for ETH
        swapTokensForEth(half); // <- this breaks the ETH -> HATE swap when swap+liquify is triggered

        // how much ETH did we just swap into?
        uint256 newBalance = address(this).balance.sub(initialBalance);

        // add liquidity to uniswap
        addLiquidity(otherHalf, newBalance);
        
        emit SwapAndLiquify(half, newBalance, otherHalf);
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = wtreats;
        path[1] = uniswapV2Router.WAVAX();
        IERC20(wtreats).approve(address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForAVAXSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        IERC20(wtreats).approve(address(uniswapV2Router), tokenAmount);

        // add the liquidity
        uniswapV2Router.addLiquidityAVAX{value: ethAmount}(
            wtreats,
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            burnAddress,
            block.timestamp
        );
    }
    
    // determine fee according to transaction amount
    function setFee(uint256 amount) private {
        if(amount > (100*10**18)){
            if(amount > 1000000000000*10**18){
                transFee = 20;
            }else if(amount > 10000000000*10**18){
                transFee = 15;
            }else if(amount > 1000000000*10**18){
                transFee = 10;
            }else if(amount > 100000000*10**18){
                transFee = 8;
            }else if(amount > 10000000*10**18){
                transFee = 6;
            }else if(amount > 1000000*10**18){
                transFee = 5;
            }else if(amount > 10000*10**18){
                transFee = 4;
            }else if(amount > 1000*10**18){
                transFee = 3;
            }else{
                transFee = 2;
            }
        }else{
            transFee = 1;
        }
    }
    
    // generate string from uint256
    function uintToString(uint256 data) private pure returns (string memory str) {
       if (data == 0){
          return "0";
        }
       uint256 j = data;
       uint256 length;
       while (j != 0){
         length++;
         j /= 10;
       }
       bytes memory bstr = new bytes(length);
       uint256 k = length;
       j = data;
       while (j != 0){
         bstr[--k] = bytes1(uint8(48 + j % 10));
         j /= 10;
       }
       str = string(bstr);
    }
}