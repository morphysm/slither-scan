// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./AggregatorV3Interface.sol";
import "./Token.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

contract MidasTokenGenerator is Initializable {
    IUniswapV2Router02 public pcsV2Router;
    AggregatorV3Interface internal priceFeed;

    mapping(string => bool) private availableChainlinkNet;
    mapping(address => bool) public _managers;

    address public _aw;
    address public _bw;
    address public _cw;
    address public _dw;
    address public owner;
    address busdAddress;

    uint256 _ap;
    uint256 _bp;
    uint256 _cp;
    uint256 _dp;

    uint256 public creationPrice; // 50$
    address private aggregatorAddress;

    // CONSTRUCTOR ------------------------------------------------------------------------------------------
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize(address[] memory addresses) public virtual initializer {
        owner = msg.sender;
        _managers[owner] = true;
        // _aw = addresses[0];
        // _bw = addresses[1];
        // _cw = addresses[2];
        // _dw = addresses[3];

        // pcsV2Router = IUniswapV2Router02(addresses[4]);

        // if (addresses[5] != 0x0000000000000000000000000000000000000000) {

        // }


        // priceFeed = AggregatorV3Interface(addresses[5]);

        _ap = 5;
        _bp = 10;
        _cp = 15;
        _dp = 25;
        creationPrice = 50000000000000000000;
    }

    fallback() external payable {}

    receive() external payable {}
    

    modifier onlyOwner() {
        require(owner == msg.sender, "onlyOwner");
        _;
    }

    modifier onlyManager() {
        require(_managers[msg.sender] == true, "onlyManager");
        _;
    }

    function setBusdAddress(address _busdAddress) external onlyOwner {
        busdAddress = _busdAddress;
    }

    function setManagers(address manager, bool newVal) external onlyOwner {
        _managers[manager] = newVal;
    }

    function enableDisableChainlinkNet(string memory name, bool status)
        public
        onlyOwner
    {
        availableChainlinkNet[name] = status;
    }

    function setCreationPrice(uint256 amount) public onlyOwner {
        creationPrice = amount;
    }

    function setPriceDataFeed(address newValue) public onlyOwner {
        priceFeed = AggregatorV3Interface(address(newValue));
    }

    function setRouterAddress(address newValue) public onlyOwner {
        pcsV2Router = IUniswapV2Router02(newValue);
    }

    function createNewToken(
        address paymentTokenAddress,
        address tokenOwner,
        address payable _feeWallet,
        string memory tokenName,
        string memory tokenSymbol,
        uint256 amountOfTokenWei,
        uint8 decimal,
        uint8[] memory fees,
        address routerAddress,
        string memory network
    ) public payable {
        // manager can create tokens for free
        if (!_managers[msg.sender]) {
            // if user pay using other token
            // the contract need how much tokens the user
            // should spend for swap for native network cryptocurrency for pay service
            if (paymentTokenAddress != pcsV2Router.WETH()) {
                // get required token amount for pay service
                uint256 requiredTokenAmount = getMinimunTokenAmout(
                    paymentTokenAddress,
                    network
                );

                // transfer from customer to contract
                require(
                    IERC20(address(paymentTokenAddress)).transferFrom(
                        msg.sender,
                        address(this),
                        requiredTokenAmount
                    )
                );

                // swap to native cryprocurrency | BNB, AVAX, MATIC, ETH ....
                swap(paymentTokenAddress, requiredTokenAmount);
            } else {
                require(
                    msg.value >= getRequiredEthAmount(network),
                    "low value"
                );
            }

            // send to team
            uint256 contractBalance = address(this).balance;
            if (contractBalance > 0) {
                payable(_aw).transfer((_ap * contractBalance) / 100);
                payable(_bw).transfer((_bp * contractBalance) / 100);
                payable(_cw).transfer((_cp * contractBalance) / 100);
                payable(_dw).transfer((_dp * contractBalance) / 100);
            }
        }


        // create token and set user as owner
        Token newToken = new Token(
            tokenOwner,
            tokenName,
            tokenSymbol,
            decimal,
            amountOfTokenWei,
            fees[5],
            fees[6],
            _feeWallet,
            routerAddress
        );
        newToken.setAllFeePercent(fees[0], fees[1], fees[2], fees[3], fees[4]);
    }

    function getRequiredEthAmount(string memory network)
        public
        view
        returns (uint256)
    {
        uint256 nativeTokenPrice;

        // contract need know if user are using network available on chainlink
        // for get native crypto price from chainlink or from router pool
        if (availableChainlinkNet[network]) {
            nativeTokenPrice = uint256(getLatestPrice()) * 1e8;
        } else {
            // get price from router pool
            nativeTokenPrice = estimatedTokensForTokens(
                pcsV2Router.WETH(),
                busdAddress,
                creationPrice
            );
        }

        return creationPrice / nativeTokenPrice;
    }

    function getMinimunTokenAmout(address tokenAddress, string memory network)
        public
        view
        returns (uint256)
    {
        return
            estimatedTokensForTokens(
                tokenAddress,
                pcsV2Router.WETH(),
                getRequiredEthAmount(network)
            );
    }

    // return amount of tokenA needed to buy 1 tokenB
    function estimatedTokensForTokens(
        address add1,
        address add2,
        uint256 amount
    ) public view returns (uint256) {
        return
            pcsV2Router.getAmountsOut(amount, pathTokensForTokens(add1, add2))[
                1
            ];
    }

    // return the route given the busd addresses and the token
    function pathTokensForTokens(address add1, address add2)
        private
        pure
        returns (address[] memory)
    {
        address[] memory path = new address[](2);
        path[0] = add1;
        path[1] = add2;
        return path;
    }

    /**
     * Returns the latest price
     */
    function getLatestPrice() public view returns (int256) {
        (
            ,
            /*uint80 roundID*/
            int256 price, /*uint startedAt*/ /*uint timeStamp*/
            ,
            ,

        ) = /*uint80 answeredInRound*/
            priceFeed.latestRoundData();
        return price;
    }

    function swap(address tokenAddress, uint256 tokenAmount) private {
        IERC20(tokenAddress).approve(address(pcsV2Router), tokenAmount);
        pcsV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            pathTokensForTokens(tokenAddress, pcsV2Router.WETH()),
            address(this),
            block.timestamp
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface IERC20 {

  function totalSupply() external view returns (uint256);

  /**
      * @dev Returns the amount of tokens owned by 'account'.
      */
  function balanceOf(address account) external view returns (uint256);

  /**
      * @dev Moves 'amount' tokens from the caller's account to 'recipient'.
      *
      * Returns a boolean value indicating whether the operation succeeded.
      *
      * Emits a {Transfer} event.
      */
  function transfer(address recipient, uint256 amount) external returns (bool);

  /**
      * @dev Returns the remaining number of tokens that 'spender' will be
      * allowed to spend on behalf of 'owner' through {transferFrom}. This is
      * zero by default.
      *
      * This value changes when {approve} or {transferFrom} are called.
      */
  function allowance(address owner, address spender) external view returns (uint256);

  /**
      * @dev Sets 'amount' as the allowance of 'spender' over the caller's tokens.
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
      * @dev Moves 'amount' tokens from 'sender' to 'recipient' using the
      * allowance mechanism. 'amount' is then deducted from the caller's
      * allowance.
      *
      * Returns a boolean value indicating whether the operation succeeded.
      *
      * Emits a {Transfer} event.
      */
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

  /**
      * @dev Emitted when 'value' tokens are moved from one account ('from') to
      * another ('to').
      *
      * Note that 'value' may be zero.
      */
  event Transfer(address indexed from, address indexed to, uint256 value);

  /**
      * @dev Emitted when the allowance of a 'spender' for an 'owner' is set by
      * a call to {approve}. 'value' is the new allowance.
      */
  event Approval(address indexed owner, address indexed spender, uint256 value);
}


/**
    * @dev Wrappers over Solidity's arithmetic operations with added overflow
    * checks.
    *
    * Arithmetic operations in Solidity wrap on overflow. This can easily result
    * in bugs, because programmers usually assume that an overflow raises an
    * error, which is the standard behavior in high level programming languages.
    * 'SafeMath' restores this intuition by reverting the transaction when an
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
      * Counterpart to Solidity's '+' operator.
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
      * Counterpart to Solidity's '-' operator.
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
      * Counterpart to Solidity's '-' operator.
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
      * Counterpart to Solidity's '*' operator.
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
      * Counterpart to Solidity's '/' operator. Note: this function uses a
      * 'revert' opcode (which leaves remaining gas untouched) while Solidity
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
      * Counterpart to Solidity's '/' operator. Note: this function uses a
      * 'revert' opcode (which leaves remaining gas untouched) while Solidity
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
      * Counterpart to Solidity's '%' operator. This function uses a 'revert'
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
      * Counterpart to Solidity's '%' operator. This function uses a 'revert'
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
  function _msgSender() internal view virtual returns (address payable) {
    return payable(address(msg.sender));
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
      * @dev Returns true if 'account' is a contract.
      *
      * [IMPORTANT]
      * ====
      * It is unsafe to assume that an address for which this function returns
      * false is an externally-owned account (EOA) and not a contract.
      *
      * Among others, 'isContract' will return false for the following
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
    // for accounts without code, i.e. 'keccak256('')'
    bytes32 codehash;
    bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
    // solhint-disable-next-line no-inline-assembly
    assembly { codehash := extcodehash(account) }
    return (codehash != accountHash && codehash != 0x0);
  }

  /**
      * @dev Replacement for Solidity's 'transfer': sends 'amount' wei to
      * 'recipient', forwarding all available gas and reverting on errors.
      *
      * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
      * of certain opcodes, possibly making contracts go over the 2300 gas limit
      * imposed by 'transfer', making them unable to receive funds via
      * 'transfer'. {sendValue} removes this limitation.
      *
      * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
      *
      * IMPORTANT: because control is transferred to 'recipient', care must be
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
      * @dev Performs a Solidity function call using a low level 'call'. A
      * plain'call' is an unsafe replacement for a function call: use this
      * function instead.
      *
      * If 'target' reverts with a revert reason, it is bubbled up by this
      * function (like regular Solidity function calls).
      *
      * Returns the raw returned data. To convert to the expected return value,
      * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions['abi.decode'].
      *
      * Requirements:
      *
      * - 'target' must be a contract.
      * - calling 'target' with 'data' must not revert.
      *
      * _Available since v3.1._
      */
  function functionCall(address target, bytes memory data) internal returns (bytes memory) {
    return functionCall(target, data, "Address: low-level call failed");
  }

  /**
      * @dev Same as {xref-Address-functionCall-address-bytes-}['functionCall'], but with
      * 'errorMessage' as a fallback revert reason when 'target' reverts.
      *
      * _Available since v3.1._
      */
  function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
    return _functionCallWithValue(target, data, 0, errorMessage);
  }

  /**
      * @dev Same as {xref-Address-functionCall-address-bytes-}['functionCall'],
      * but also transferring 'value' wei to 'target'.
      *
      * Requirements:
      *
      * - the calling contract must have an ETH balance of at least 'value'.
      * - the called Solidity function must be 'payable'.
      *
      * _Available since v3.1._
      */
  function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
    return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
  }

  /**
      * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}['functionCallWithValue'], but
      * with 'errorMessage' as a fallback revert reason when 'target' reverts.
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
/**
    * @title SafeERC20
    * @dev Wrappers around ERC20 operations that throw on failure (when the token
    * contract returns false). Tokens that return no value (and instead revert or
    * throw on failure) are also supported, non-reverting calls are assumed to be
    * successful.
    * To use this library you can add a 'using SafeERC20 for IERC20;' statement to your contract,
    * which allows you to call the safe operations as 'token.safeTransfer(...)', etc.
    */
library SafeERC20 {
  using SafeMath for uint256;
  using Address for address;

  function safeTransfer(IERC20 token, address to, uint256 value) internal {
    _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
  }

  function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
    _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
  }

  /**
      * @dev Deprecated. This function has issues similar to the ones found in
      * {IERC20-approve}, and its usage is discouraged.
      *
      * Whenever possible, use {safeIncreaseAllowance} and
      * {safeDecreaseAllowance} instead.
      */
  function safeApprove(IERC20 token, address spender, uint256 value) internal {
    // safeApprove should only be called when setting an initial allowance,
    // or when resetting it to zero. To increase and decrease it, use
    // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
    // solhint-disable-next-line max-line-length
    require((value == 0) || (token.allowance(address(this), spender) == 0),
      "SafeERC20: approve from non-zero to non-zero allowance"
    );
    _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
  }

  function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
    uint256 newAllowance = token.allowance(address(this), spender).add(value);
    _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
  }

  function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
    uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
    _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
  }

  /**
      * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
      * on the return value: the return value is optional (but if data is returned, it must not be false).
      * @param token The token targeted by the call.
      * @param data The call data (encoded using abi.encode or one of its variants).
      */
  function _callOptionalReturn(IERC20 token, bytes memory data) private {
    // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
    // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
    // the target address contains contract code and also asserts for success in the low-level call.

    bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
    if (returndata.length > 0) { // Return data is optional
      // solhint-disable-next-line max-line-length
      require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
    }
  }
}

/**
    * @dev Contract module which provides a basic access control mechanism, where
    * there is an account (an owner) that can be granted exclusive access to
    * specific functions.
    *
    * By default, the owner account will be the one that deploys the contract. This
    * can later be changed with {transferOwnership}.
    *
    * This module is used through inheritance. It will make available the modifier
    * 'onlyOwner', which can be applied to your functions to restrict their use to
    * the owner.
    */
abstract contract Ownable is Context {
  address private _owner;
  address private _previousOwner;
  uint256 private _lockTime;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
      * @dev Initializes the contract setting the deployer as the initial owner.
      */
  constructor ()  {
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
  * 'onlyOwner' functions anymore. Can only be called by the current owner.
  *
  * NOTE: Renouncing ownership will leave the contract without an owner,
  * thereby removing any functionality that is only available to the owner.
  */
  function renounceOwnership() public virtual onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

  /**
      * @dev Transfers ownership of the contract to a new account ('newOwner').
      * Can only be called by the current owner.
      */
  function transferOwnership(address newOwner) public virtual onlyOwner {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }

  function geUnlockTime() public view returns (uint256) {
    return _lockTime;
  }

  //Locks the contract for owner for the amount of time provided
  function lock(uint256 time) public virtual onlyOwner {
    _previousOwner = _owner;
    _owner = address(0);
    _lockTime = block.timestamp + time;
    emit OwnershipTransferred(_owner, address(0));
  }

  //Unlocks the contract for owner when _lockTime is exceeds
  function unlock() public virtual {
    require(_previousOwner == msg.sender, "You don't have permission to unlock the token contract");
    require(block.timestamp > _lockTime , "Contract is locked until 7 days");
    emit OwnershipTransferred(_owner, _previousOwner);
    _owner = _previousOwner;
  }
}

// pragma solidity >=0.5.0;

interface IUniswapV2Factory {
  event PairCreated(address indexed token0, address indexed token1, address pair, uint);

  function feeTo() external view returns (address);
  function feeToSetter() external view returns (address);

  function getPair(address tokenA, address tokenB) external view returns (address pair);
  function allPairs(uint) external view returns (address pair);
  function allPairsLength() external view returns (uint);

  function createPair(address tokenA, address tokenB) external returns (address pair);

  function setFeeTo(address) external;
  function setFeeToSetter(address) external;
}



// pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
  function factory() external pure returns (address);
  function WETH() external pure returns (address);

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
  function removeLiquidity(
    address tokenA,
    address tokenB,
    uint liquidity,
    uint amountAMin,
    uint amountBMin,
    address to,
    uint deadline
  ) external returns (uint amountA, uint amountB);
  function removeLiquidityETH(
    address token,
    uint liquidity,
    uint amountTokenMin,
    uint amountETHMin,
    address to,
    uint deadline
  ) external returns (uint amountToken, uint amountETH);
  function removeLiquidityWithPermit(
    address tokenA,
    address tokenB,
    uint liquidity,
    uint amountAMin,
    uint amountBMin,
    address to,
    uint deadline,
    bool approveMax, uint8 v, bytes32 r, bytes32 s
  ) external returns (uint amountA, uint amountB);
  function removeLiquidityETHWithPermit(
    address token,
    uint liquidity,
    uint amountTokenMin,
    uint amountETHMin,
    address to,
    uint deadline,
    bool approveMax, uint8 v, bytes32 r, bytes32 s
  ) external returns (uint amountToken, uint amountETH);
  function swapExactTokensForTokens(
    uint amountIn,
    uint amountOutMin,
    address[] calldata path,
    address to,
    uint deadline
  ) external returns (uint[] memory amounts);
  function swapTokensForExactTokens(
    uint amountOut,
    uint amountInMax,
    address[] calldata path,
    address to,
    uint deadline
  ) external returns (uint[] memory amounts);
  function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
  external
  payable
  returns (uint[] memory amounts);
  function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
  external
  returns (uint[] memory amounts);
  function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
  external
  returns (uint[] memory amounts);
  function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
  external
  payable
  returns (uint[] memory amounts);

  function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
  function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
  function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
  function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
  function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}



// pragma solidity >=0.6.2;

interface IUniswapV2Router02 is IUniswapV2Router01 {
  function removeLiquidityETHSupportingFeeOnTransferTokens(
    address token,
    uint liquidity,
    uint amountTokenMin,
    uint amountETHMin,
    address to,
    uint deadline
  ) external returns (uint amountETH);
  function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
    address token,
    uint liquidity,
    uint amountTokenMin,
    uint amountETHMin,
    address to,
    uint deadline,
    bool approveMax, uint8 v, bytes32 r, bytes32 s
  ) external returns (uint amountETH);

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


contract Token is Context, IERC20, Ownable {
  using SafeMath for uint256;
  using Address for address;
  using SafeERC20 for IERC20;

  address dead = 0x000000000000000000000000000000000000dEaD;

  uint8 public maxLiqFee = 10;
  uint8 public maxTaxFee = 10;
  uint8 public maxBurnFee = 10;
  uint8 public maxWalletFee = 10;
  uint8 public maxBuybackFee = 10;
  uint8 public minMxTxPercentage = 1;
  uint8 public minMxWalletPercentage = 1;

  mapping (address => bool) private blacklist;

  mapping (address => uint256) private _rOwned;
  mapping (address => uint256) private _tOwned;
  mapping (address => mapping (address => uint256)) private _allowances;

  mapping (address => bool) private _isExcludedFromFee;

  mapping (address => bool) private _isExcluded;
  address[] private _excluded;

  address public router; //= 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3;   // bsc

  uint256 private constant MAX = ~uint256(0);
  uint256 public _tTotal;
  uint256 private _rTotal;
  uint256 private _tFeeTotal;

  string public _name;
  string public _symbol;
  uint8 private _decimals;

  uint8 public _taxFee = 0;
  uint8 private _previousTaxFee = _taxFee;

  uint8 public _liquidityFee = 0;
  uint8 private _previousLiquidityFee = _liquidityFee;

  uint8 public _burnFee = 0;
  uint8 private _previousBurnFee = _burnFee;

  uint8 public _walletFee = 0;
  uint8 private _previousWalletFee = _walletFee;

  uint8 public _buybackFee = 0;
  uint8 private _previousBuybackFee = _buybackFee;

  IUniswapV2Router02 public immutable pcsV2Router;
  address public immutable pcsV2Pair;
  address payable public feeWallet;

  bool inSwapAndLiquify;
  bool public swapAndLiquifyEnabled = true;

  uint256 public _maxTxAmount;
  uint256 public _maxWalletAmount;
  uint256 public numTokensSellToAddToLiquidity;
  uint256 private buyBackUpperLimit = 1 * 10**18;

  event SwapAndLiquifyEnabledUpdated(bool enabled);
  event SwapAndLiquify(
    uint256 tokensSwapped,
    uint256 ethReceived,
    uint256 tokensIntoLiqudity
  );

  modifier lockTheSwap {
    inSwapAndLiquify = true;
    _;
    inSwapAndLiquify = false;
  }

  constructor (address tokenOwner,string memory tokenName,
    string memory tokenSymbol, uint8 decimal, uint256 amountOfTokenWei,
    uint8 setMxTxPer, uint8 setMxWalletPer,
    address payable _feeWallet,
       address routerAddress
  )  {

    _name = tokenName;
    _symbol = tokenSymbol;
    _decimals = decimal;
    _tTotal = amountOfTokenWei;
    _rTotal = (MAX - (MAX % _tTotal));

    _rOwned[tokenOwner] = _rTotal;

    feeWallet = _feeWallet;
    router = routerAddress;


    _maxTxAmount = _tTotal.mul(setMxTxPer).div(
      10**2
    );
    _maxWalletAmount = _tTotal.mul(setMxWalletPer).div(
      10**2
    );

    numTokensSellToAddToLiquidity = amountOfTokenWei.mul(1).div(1000);

    IUniswapV2Router02 _pcsV2Router = IUniswapV2Router02(router);
    // Create a uniswap pair for this new token
    pcsV2Pair = IUniswapV2Factory(_pcsV2Router.factory())
    .createPair(address(this), _pcsV2Router.WETH());

    // set the rest of the contract variables
    pcsV2Router = _pcsV2Router;

    _isExcludedFromFee[tokenOwner] = true;
    _isExcludedFromFee[address(this)] = true;

    emit Transfer(address(0), tokenOwner, _tTotal);
  }

  function name() public view returns (string memory) {
    return _name;
  }

  function symbol() public view returns (string memory) {
    return _symbol;
  }

  function decimals() public view returns (uint8) {
    return _decimals;
  }

  function totalSupply() public view override returns (uint256) {
    return _tTotal;
  }

  function balanceOf(address account) public view override returns (uint256) {
    if (_isExcluded[account]) return _tOwned[account];
    return tokenFromReflection(_rOwned[account]);
  }

  function transfer(address recipient, uint256 amount) public override returns (bool) {
    _transfer(_msgSender(), recipient, amount);
    return true;
  }

  function allowance(address owner, address spender) public view override returns (uint256) {
    return _allowances[owner][spender];
  }

  function approve(address spender, uint256 amount) public override returns (bool) {
    _approve(_msgSender(), spender, amount);
    return true;
  }

  function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
    _transfer(sender, recipient, amount);
    _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
    return true;
  }

  function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
    return true;
  }

  function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
    return true;
  }

  function isExcludedFromReward(address account) public view returns (bool) {
    return _isExcluded[account];
  }

  function totalFees() public view returns (uint256) {
    return _tFeeTotal;
  }

  function deliver(uint256 tAmount) public {
    address sender = _msgSender();
    require(!_isExcluded[sender], "Excluded addresses cannot call this function");
    (uint256 rAmount,,,,,) = _getValues(tAmount);
    _rOwned[sender] = _rOwned[sender].sub(rAmount);
    _rTotal = _rTotal.sub(rAmount);
    _tFeeTotal = _tFeeTotal.add(tAmount);
  }

  function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns(uint256) {
    require(tAmount <= _tTotal, "Amt must be less than supply");
    if (!deductTransferFee) {
      (uint256 rAmount,,,,,) = _getValues(tAmount);
      return rAmount;
    } else {
      (,uint256 rTransferAmount,,,,) = _getValues(tAmount);
      return rTransferAmount;
    }
  }

  function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
    require(rAmount <= _rTotal, "Amt must be less than tot refl");
    uint256 currentRate =  _getRate();
    return rAmount.div(currentRate);
  }

  function excludeFromReward(address account) public onlyOwner() {
    require(!_isExcluded[account], "Account is already excluded from reward");
    if(_rOwned[account] > 0) {
      _tOwned[account] = tokenFromReflection(_rOwned[account]);
    }
    _isExcluded[account] = true;
    _excluded.push(account);
  }

  function includeInReward(address account) external onlyOwner() {
    require(_isExcluded[account], "Already excluded");
    for (uint256 i = 0; i < _excluded.length; i++) {
      if (_excluded[i] == account) {
        _excluded[i] = _excluded[_excluded.length - 1];
        _tOwned[account] = 0;
        _isExcluded[account] = false;
        _excluded.pop();
        break;
      }
    }
  }


  function excludeFromFee(address account) public onlyOwner {
    _isExcludedFromFee[account] = true;
  }

  function includeInFee(address account) public onlyOwner {
    _isExcludedFromFee[account] = false;
  }

  function setAllFeePercent(uint8 taxFee, uint8 liquidityFee, uint8 burnFee, uint8 walletFee, uint8 buybackFee) external onlyOwner() {
    require(taxFee >= 0 && taxFee <=maxTaxFee,"TF err");
    require(liquidityFee >= 0 && liquidityFee <=maxLiqFee,"LF err");
    require(burnFee >= 0 && burnFee <=maxBurnFee,"BF err");
    require(walletFee >= 0 && walletFee <=maxWalletFee,"WF err");
    require(buybackFee >= 0 && buybackFee <=maxBuybackFee,"BBF err");
    _taxFee = taxFee;
    _liquidityFee = liquidityFee;
    _burnFee = burnFee;
    _buybackFee = buybackFee;
    _walletFee = walletFee;
  }

  function buyBackUpperLimitAmount() public view returns (uint256) {
    return buyBackUpperLimit;
  }

  function setBuybackUpperLimit(uint256 buyBackLimit) external onlyOwner() {
    buyBackUpperLimit = buyBackLimit * 10**18;
  }

  function setMaxTxPercent(uint256 maxTxPercent) external onlyOwner() {
    require(maxTxPercent >= minMxTxPercentage && maxTxPercent <=100,"err");
    _maxTxAmount = _tTotal.mul(maxTxPercent).div(
      10**2
    );
  }

  function setMaxWalletPercent(uint256 maxWalletPercent) external onlyOwner() {
    require(maxWalletPercent >= minMxWalletPercentage && maxWalletPercent <=100,"err");
    _maxWalletAmount = _tTotal.mul(maxWalletPercent).div(
      10**2
    );
  }

  function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
    swapAndLiquifyEnabled = _enabled;
    emit SwapAndLiquifyEnabledUpdated(_enabled);
  }

  function setFeeWallet(address payable newFeeWallet) external onlyOwner {
    require(newFeeWallet != address(0), "ZERO ADDRESS");
    feeWallet = newFeeWallet;
  }


  //to recieve ETH from pcsV2Router when swaping
  receive() external payable {}

  function _reflectFee(uint256 rFee, uint256 tFee) private {
    _rTotal = _rTotal.sub(rFee);
    _tFeeTotal = _tFeeTotal.add(tFee);
  }

  function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
    (uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getTValues(tAmount);
    (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tLiquidity, _getRate());
    return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tLiquidity);
  }

  function _getTValues(uint256 tAmount) private view returns (uint256, uint256, uint256) {
    uint256 tFee = calculateTaxFee(tAmount);
    uint256 tLiquidity = calculateLiquidityFee(tAmount);
    uint256 tTransferAmount = tAmount.sub(tFee).sub(tLiquidity);
    return (tTransferAmount, tFee, tLiquidity);
  }

  function _getRValues(uint256 tAmount, uint256 tFee, uint256 tLiquidity, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
    uint256 rAmount = tAmount.mul(currentRate);
    uint256 rFee = tFee.mul(currentRate);
    uint256 rLiquidity = tLiquidity.mul(currentRate);
    uint256 rTransferAmount = rAmount.sub(rFee).sub(rLiquidity);
    return (rAmount, rTransferAmount, rFee);
  }

  function _getRate() private view returns(uint256) {
    (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
    return rSupply.div(tSupply);
  }

  function _getCurrentSupply() private view returns(uint256, uint256) {
    uint256 rSupply = _rTotal;
    uint256 tSupply = _tTotal;
    for (uint256 i = 0; i < _excluded.length; i++) {
      if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) return (_rTotal, _tTotal);
      rSupply = rSupply.sub(_rOwned[_excluded[i]]);
      tSupply = tSupply.sub(_tOwned[_excluded[i]]);
    }
    if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
    return (rSupply, tSupply);
  }

  function _takeLiquidity(uint256 tLiquidity) private {
    uint256 currentRate =  _getRate();
    uint256 rLiquidity = tLiquidity.mul(currentRate);
    _rOwned[address(this)] = _rOwned[address(this)].add(rLiquidity);
    if(_isExcluded[address(this)])
      _tOwned[address(this)] = _tOwned[address(this)].add(tLiquidity);
  }

  function calculateTaxFee(uint256 _amount) private view returns (uint256) {
    return _amount.mul(_taxFee).div(
      10**2
    );
  }

  function calculateLiquidityFee(uint256 _amount) private view returns (uint256) {
    return _amount.mul(_liquidityFee + _burnFee + _walletFee + _buybackFee).div(
      10**2
    );
  }

  function removeAllFee() private {
    if(_taxFee == 0 && _liquidityFee == 0 && _burnFee == 0 && _walletFee == 0 && _buybackFee == 0) return;

    _previousTaxFee = _taxFee;
    _previousLiquidityFee = _liquidityFee;
    _previousBurnFee = _burnFee;
    _previousWalletFee = _walletFee;
    _previousBuybackFee = _buybackFee;

    _taxFee = 0;
    _liquidityFee = 0;
    _burnFee = 0;
    _walletFee = 0;
    _buybackFee = 0;
  }

  function restoreAllFee() private {
    _taxFee = _previousTaxFee;
    _liquidityFee = _previousLiquidityFee;
    _burnFee = _previousBurnFee;
    _walletFee = _previousWalletFee;
    _buybackFee = _previousBuybackFee;
  }

  function isExcludedFromFee(address account) public view returns(bool) {
    return _isExcludedFromFee[account];
  }

  function _approve(address owner, address spender, uint256 amount) private {
    require(owner != address(0), "ERC20: approve from zero address");
    require(spender != address(0), "ERC20: approve to zero address");

    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }

  function _transfer(
    address from,
    address to,
    uint256 amount
  ) private {
    require(from != address(0), "ERC20: transfer from zero address");
    require(to != address(0), "ERC20: transfer to zero address");
    require(amount > 0, "Transfer amount must be greater than zero");
    if(from != owner() && to != owner())
      require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");

    if(from != owner() && to != owner() && to != address(0) && to != dead && to != pcsV2Pair){
      uint256 contractBalanceRecepient = balanceOf(to);
      require(contractBalanceRecepient + amount <= _maxWalletAmount, "Exceeds maximum wallet amount");
    }
    // is the token balance of this contract address over the min number of
    // tokens that we need to initiate a swap + liquidity lock?
    // also, don't get caught in a circular liquidity event.
    // also, don't swap & liquify if sender is uniswap pair.
    uint256 contractTokenBalance = balanceOf(address(this));

    if(contractTokenBalance >= _maxTxAmount)
    {
      contractTokenBalance = _maxTxAmount;
    }

    bool overMinTokenBalance = contractTokenBalance >= numTokensSellToAddToLiquidity;
    if (
      !inSwapAndLiquify &&
    to == pcsV2Pair &&
    swapAndLiquifyEnabled
    ) {
      if(overMinTokenBalance){
        contractTokenBalance = numTokensSellToAddToLiquidity;
        //add liquidity
        swapAndLiquify(contractTokenBalance);
      }
      if(_buybackFee !=0){
        uint256 balance = address(this).balance;
        if (balance > uint256(1 * 10**18)) {

          if (balance > buyBackUpperLimit)
            balance = buyBackUpperLimit;

          buyBackTokens(balance.div(100));
        }
      }

    }


    //indicates if fee should be deducted from transfer
    bool takeFee = true;

    //if any account belongs to _isExcludedFromFee account then remove the fee
    if(_isExcludedFromFee[from] || _isExcludedFromFee[to]){
      takeFee = false;
    }

    //transfer amount, it will take tax, burn, liquidity fee
    _tokenTransfer(from,to,amount,takeFee);
  }


  function updateBlacklist(address blackListedAddress, bool status) public onlyOwner {
    blacklist[blackListedAddress] = status;
  }


  function burn(uint256 burnAmount) public {
    require(burnAmount >= 0, "Burn amount should be greater than zero");
    require(burnAmount <= _rOwned[msg.sender], "Burn amount should be less than account balance");

    _rOwned[msg.sender] = _rOwned[msg.sender] - burnAmount;
    _tTotal = _tTotal - burnAmount;


    emit Transfer(msg.sender, address(0), burnAmount);
  }

  function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
    //This needs to be distributed among burn, wallet and liquidity
    //burn
    uint8 totFee  = _burnFee + _walletFee + _liquidityFee + _buybackFee;
    uint256 spentAmount = 0;
    uint256 totSpentAmount = 0;
    if(_burnFee != 0){
      spentAmount  = contractTokenBalance.div(totFee).mul(_burnFee);
      _tokenTransferNoFee(address(this), dead, spentAmount);
      totSpentAmount = spentAmount;
    }

    if(_walletFee != 0){
      spentAmount = contractTokenBalance.div(totFee).mul(_walletFee);
      _tokenTransferNoFee(address(this), feeWallet, spentAmount);
      totSpentAmount = totSpentAmount + spentAmount;
    }

    if(_buybackFee != 0){
      spentAmount = contractTokenBalance.div(totFee).mul(_buybackFee);
      swapTokensForBNB(spentAmount);
      totSpentAmount = totSpentAmount + spentAmount;
    }

    if(_liquidityFee != 0){
      contractTokenBalance = contractTokenBalance.sub(totSpentAmount);

      // split the contract balance into halves
      uint256 half = contractTokenBalance.div(2);
      uint256 otherHalf = contractTokenBalance.sub(half);

      // capture the contract's current ETH balance.
      // this is so that we can capture exactly the amount of ETH that the
      // swap creates, and not make the liquidity event include any ETH that
      // has been manually sent to the contract
      uint256 initialBalance = address(this).balance;

      // swap tokens for ETH
      swapTokensForBNB(half); // <- this breaks the ETH -> HATE swap when swap+liquify is triggered

      // how much ETH did we just swap into?
      uint256 newBalance = address(this).balance.sub(initialBalance);

      // add liquidity to uniswap
      addLiquidity(otherHalf, newBalance);

      emit SwapAndLiquify(half, newBalance, otherHalf);
    }

  }

  function buyBackTokens(uint256 amount) private lockTheSwap {
    if (amount > 0) {
      swapBNBForTokens(amount);
    }
  }

  function swapTokensForBNB(uint256 tokenAmount) private {
    // generate the uniswap pair path of token -> weth
    address[] memory path = new address[](2);
    path[0] = address(this);
    path[1] = pcsV2Router.WETH();

    _approve(address(this), address(pcsV2Router), tokenAmount);

    // make the swap
    pcsV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
      tokenAmount,
      0, // accept any amount of ETH
      path,
      address(this),
      block.timestamp
    );
  }

  function swapBNBForTokens(uint256 amount) private {
    // generate the uniswap pair path of token -> weth
    address[] memory path = new address[](2);
    path[0] = pcsV2Router.WETH();
    path[1] = address(this);

    // make the swap
    pcsV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(
      0, // accept any amount of Tokens
      path,
      dead, // Burn address
      block.timestamp.add(300)
    );
  }

  function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
    // approve token transfer to cover all possible scenarios
    _approve(address(this), address(pcsV2Router), tokenAmount);

    // add the liquidity
    pcsV2Router.addLiquidityETH{value: ethAmount}(
      address(this),
      tokenAmount,
      0, // slippage is unavoidable
      0, // slippage is unavoidable
      dead,
      block.timestamp
    );
  }

  //this method is responsible for taking all fee, if takeFee is true
  function _tokenTransfer(address sender, address recipient, uint256 amount,bool takeFee) private {
    if(!takeFee)
      removeAllFee();

    if (_isExcluded[sender] && !_isExcluded[recipient]) {
      _transferFromExcluded(sender, recipient, amount);
    } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
      _transferToExcluded(sender, recipient, amount);
    } else if (!_isExcluded[sender] && !_isExcluded[recipient]) {
      _transferStandard(sender, recipient, amount);
    } else if (_isExcluded[sender] && _isExcluded[recipient]) {
      _transferBothExcluded(sender, recipient, amount);
    } else {
      _transferStandard(sender, recipient, amount);
    }

    if(!takeFee)
      restoreAllFee();
  }

  function _transferStandard(address sender, address recipient, uint256 tAmount) private {
    (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount);
    _rOwned[sender] = _rOwned[sender].sub(rAmount);
    _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
    _takeLiquidity(tLiquidity);
    _reflectFee(rFee, tFee);
    emit Transfer(sender, recipient, tTransferAmount);
  }

  function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
    (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount);
    _rOwned[sender] = _rOwned[sender].sub(rAmount);
    _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
    _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
    _takeLiquidity(tLiquidity);
    _reflectFee(rFee, tFee);
    emit Transfer(sender, recipient, tTransferAmount);
  }

  function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
    (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount);
    _tOwned[sender] = _tOwned[sender].sub(tAmount);
    _rOwned[sender] = _rOwned[sender].sub(rAmount);
    _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
    _takeLiquidity(tLiquidity);
    _reflectFee(rFee, tFee);
    emit Transfer(sender, recipient, tTransferAmount);
  }

  function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
    (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount);
    _tOwned[sender] = _tOwned[sender].sub(tAmount);
    _rOwned[sender] = _rOwned[sender].sub(rAmount);
    _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
    _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
    _takeLiquidity(tLiquidity);
    _reflectFee(rFee, tFee);
    emit Transfer(sender, recipient, tTransferAmount);
  }

  function _tokenTransferNoFee(address sender, address recipient, uint256 amount) private {
    uint256 currentRate =  _getRate();
    uint256 rAmount = amount.mul(currentRate);

    _rOwned[sender] = _rOwned[sender].sub(rAmount);
    _rOwned[recipient] = _rOwned[recipient].add(rAmount);

    if (_isExcluded[sender]) {
      _tOwned[sender] = _tOwned[sender].sub(amount);
    }
    if (_isExcluded[recipient]) {
      _tOwned[recipient] = _tOwned[recipient].add(amount);
    }
    emit Transfer(sender, recipient, amount);
  }

  function recoverBEP20(address tokenAddress, uint256 tokenAmount) public onlyOwner {
    // do not allow recovering self token
    require(tokenAddress != address(this), "Self withdraw");
    IERC20(tokenAddress).transfer(owner(), tokenAmount);
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

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
        bool isTopLevelCall = _setInitializedVersion(1);
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
        bool isTopLevelCall = _setInitializedVersion(version);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(version);
        }
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
        _setInitializedVersion(type(uint8).max);
    }

    function _setInitializedVersion(uint8 version) private returns (bool) {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, and for the lowest level
        // of initializers, because in other contexts the contract may have been reentered.
        if (_initializing) {
            require(
                version == 1 && !AddressUpgradeable.isContract(address(this)),
                "Initializable: contract is already initialized"
            );
            return false;
        } else {
            require(_initialized < version, "Initializable: contract is already initialized");
            _initialized = version;
            return true;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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