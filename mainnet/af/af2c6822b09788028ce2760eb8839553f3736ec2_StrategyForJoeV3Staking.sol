/**
 *Submitted for verification at snowtrace.io on 2022-05-26
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

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

interface IJoeChef {
    struct PoolInfo {
        IERC20 lpToken; // Address of LP token contract.
        uint256 allocPoint; // How many allocation points assigned to this pool. JOEs to distribute per second.
        uint256 lastRewardTimestamp; // Last timestamp that JOEs distribution occurs.
        uint256 accJoePerShare; // Accumulated JOEs per share, times 1e12. See below.
        address rewarder;
    }
    function poolInfo(uint256 pid) external view returns (PoolInfo memory);
    function totalAllocPoint() external view returns (uint256);
    function pendingTokens(uint256 _pid, address _user) external view
        returns (uint256 pendingJoe, address bonusTokenAddress,
            string memory bonusTokenSymbol, uint256 pendingBonusToken);
    function rewarderBonusTokenInfo(uint256 _pid) external view
        returns (address bonusTokenAddress, string memory bonusTokenSymbol);
    function updatePool(uint256 _pid) external;
    function deposit(uint256 _pid, uint256 _amount) external;
    function withdraw(uint256 _pid, uint256 _amount) external;
    function emergencyWithdraw(uint256 _pid) external;
    function userInfo(uint256 pid, address user) external view returns (uint256 amount, uint256 rewardDebt);
}

//owned by the HauntedHouse contract
interface IBoofiStrategy {
    //pending tokens for the user
    function pendingTokens(address user) external view returns(address[] memory tokens, uint256[] memory amounts);
    // Deposit amount of tokens for 'caller' to address 'to'
    function deposit(address caller, address to, uint256 tokenAmount, uint256 shareAmount) external;
    // Transfer tokens from strategy for 'caller' to address 'to'
    function withdraw(address caller, address to, uint256 tokenAmount, uint256 shareAmount) external;
    function inCaseTokensGetStuck(IERC20 token, address to, uint256 amount) external;
    function migrate(address newStrategy) external;
    function onMigration() external;
    function transferOwnership(address newOwner) external;
    function setPerformanceFeeBips(uint256 newPerformanceFeeBips) external;
}

interface IHauntedHouse {
    struct TokenInfo {
        address rewarder; // Address of rewarder for token
        address strategy; // Address of strategy for token
        uint256 lastRewardTime; // Last time that BOOFI distribution occurred for this token
        uint256 lastCumulativeReward; // Value of cumulativeAvgZboofiPerWeightedDollar at last update
        uint256 storedPrice; // Latest value of token
        uint256 accZBOOFIPerShare; // Accumulated BOOFI per share, times ACC_BOOFI_PRECISION.
        uint256 totalShares; //total number of shares for the token
        uint256 totalTokens; //total number of tokens deposited
        uint128 multiplier; // multiplier for this token
        uint16 withdrawFeeBP; // Withdrawal fee in basis points
    }
    function BOOFI() external view returns (address);
    function strategyPool() external view returns (address);
    function performanceFeeAddress() external view returns (address);
    function updatePrice(address token, uint256 newPrice) external;
    function updatePrices(address[] calldata tokens, uint256[] calldata newPrices) external;
    function tokenList() external view returns (address[] memory);
    function tokenParameters(address tokenAddress) external view returns (TokenInfo memory);
    function deposit(address token, uint256 amount, address to) external;
    function harvest(address token, address to) external;
    function withdraw(address token, uint256 amountShares, address to) external;
}

interface IWAVAX {
    function name() external view returns (string memory);

    function approve(address guy, uint256 wad) external returns (bool);

    function totalSupply() external view returns (uint256);

    function transferFrom(
        address src,
        address dst,
        uint256 wad
    ) external returns (bool);

    function withdraw(uint256 wad) external;

    function decimals() external view returns (uint8);

    function balanceOf(address) external view returns (uint256);

    function symbol() external view returns (string memory);

    function transfer(address dst, uint256 wad) external returns (bool);

    function deposit() external payable;

    function allowance(address, address) external view returns (uint256);
}

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

interface IERC20WithPermit is IERC20Metadata {
    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;
}

interface IZBOOFI is IERC20WithPermit {
    function enter(uint256 _amount) external;
    function enterFor(address _to, uint256 _amount) external;
    function leave(uint256 _share) external;
    function leaveTo(address _to, uint256 _share) external;
    function currentExchangeRate() external view returns(uint256);
    function expectedZBOOFI(uint256 amountBoofi) external view returns(uint256);
    function expectedBOOFI(uint256 amountZBoofi) external view returns(uint256);
}

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

//pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

//import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol';

library UniswapV2Library {
    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'UniswapV2Library: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'UniswapV2Library: ZERO_ADDRESS');
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint160(uint(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                hex'96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f' // init code hash
            )))));
    }

    // fetches and sorts the reserves for a pair
    function getReserves(address factory, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint reserve0, uint reserve1,) = IUniswapV2Pair(pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, 'UniswapV2Library: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        amountB = (amountA * reserveB) / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = (amountIn * 997);
        uint numerator = (amountInWithFee * reserveOut);
        uint denominator = (reserveIn * 1000) + (amountInWithFee);
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) internal pure returns (uint amountIn) {
        require(amountOut > 0, 'UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint numerator = (reserveIn * amountOut) * (1000);
        uint denominator = (reserveOut - amountOut) * (997);
        amountIn = (numerator / denominator) + (1);
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(address factory, uint amountIn, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(address factory, uint amountOut, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint i = path.length - 1; i > 0; i--) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }
}

contract SwappingGuide is Ownable {
    mapping(address => address[]) public tokenPathsToBoofi;
    mapping(address => address[]) public pairPathsToBoofi;

    // tokenPath *includes* the starting token
    // e.g. for tokenA=>tokenB=>BOOFI we encode:
    // tokenPath = [tokenA, tokenB, BOOFI]
    // pairPath = [tokenA+tokenB pair, tokenB+BOOFI pair]
    function setPath(address startingToken, address[] calldata tokenPath, address[] calldata pairPath) external onlyOwner {
        require(pairPath.length == tokenPath.length - 1, "bad lengths");
        tokenPathsToBoofi[startingToken] = tokenPath;
        pairPathsToBoofi[startingToken] = pairPath;
    }

    function getTokenPathToBoofi(address startingToken) external view returns (address[] memory) {
        return tokenPathsToBoofi[startingToken];
    }

    function getPairPathToBoofi(address startingToken) external view returns (address[] memory) {
        return pairPathsToBoofi[startingToken];
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
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
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

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
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
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

abstract contract TokenOrAvaxTransfer {
    using SafeERC20 for IERC20;

    //placeholder address for native token (AVAX)
    address public constant AVAX = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    function _tokenOrAvaxTransfer(address token, address dest, uint256 amount) internal {
        if (amount > 0) {
            if (token == AVAX) {
                payable(dest).transfer(amount);
            } else {
                IERC20(token).safeTransfer(dest,amount);          
            }            
        }
    }

    function _checkBalance(address token) internal view returns (uint256) {
        if (token == AVAX) {
            return address(this).balance;
        } else {
            return IERC20(token).balanceOf(address(this));
        }
    }
}

contract GlobalStrategyBipsAmounts is Ownable {
    struct BipsAmounts {
        // if false, use global values, if true, use local values.
        // this only matters when set locally in a strategy contract
        // changing its value in the GlobalStrategyBipsAmounts contract does nothing
        bool useLocalValues;
        // bips of earnings to be stored as performance fees
        uint16 performanceFeeBips;
        // bips of swapped BOOFI to go to the 'strategyPool' defined in the HauntedHouse
        uint16 strategyPoolBips;
    }

    uint256 internal constant MAX_BIPS = 10000;
    BipsAmounts internal _bipsAmounts;

    constructor(BipsAmounts memory _newBipsAmounts) {
        _setBipsAmounts(_newBipsAmounts);
    }

    function bipsAmounts() external view returns (BipsAmounts memory) {
        return _bipsAmounts;
    }

    function setBipsAmounts(BipsAmounts memory _newBipsAmounts) external onlyOwner {
        _setBipsAmounts(_newBipsAmounts);
    }

    function _setBipsAmounts(BipsAmounts memory _newBipsAmounts) internal {
        require(_newBipsAmounts.performanceFeeBips <= MAX_BIPS);
        require(_newBipsAmounts.strategyPoolBips <= MAX_BIPS);
        _bipsAmounts = _newBipsAmounts;
    }
}

abstract contract StrategyBase is IBoofiStrategy, Ownable, TokenOrAvaxTransfer {
    struct TotalHarvestedAndStoredPerformanceFees {
        uint128 totalHarvested;
        uint128 storedPerformanceFees;
    }

    struct UserInfo {
        uint256 amount; // How many shares the user currently has
        uint256 rewardDebt; // Reward debt. At any time, the amount of pending zBOOFI for a user is ((user.amount * accZBOOFIPerShare) / ACC_BOOFI_PRECISION) - user.rewardDebt
    }

    IHauntedHouse public immutable hauntedHouse;
    IERC20 public immutable depositToken;
    SwappingGuide public immutable swappingGuide;
    GlobalStrategyBipsAmounts public immutable globalStrategyBipsAmounts;

    uint256 internal constant MAX_UINT = 115792089237316195423570985008687907853269984665640564039457584007913129639935;
    uint256 internal constant ACC_BOOFI_PRECISION = 1e18;
    uint256 internal constant MAX_BIPS = 10000;
    address internal constant WAVAX = 0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7;
    address internal constant BOOFI = 0x45eE8311d3d853Df26e69f970Fc52424A57A4997;
    address internal constant ZBOOFI = 0x7c226EE0121C0094e9755C29eFe3d75D85D02F94;

    uint256 public performanceFeeBips = 3000;
    GlobalStrategyBipsAmounts.BipsAmounts public bipsAmounts;
    //tokens rewarded by the DEX    
    uint256 public immutable NUMBER_REWARDS_TOKENS;
    address[] public REWARD_TOKENS_ARRAY;
    //total REWARD_TOKENs harvested by the contract all time, and stored rewardTokens to be withdrawn to performanceFeeAdress of HauntedHouse
    TotalHarvestedAndStoredPerformanceFees[] public totalHarvestedAndStoredPerformanceFees;

    uint256 public totalShares;
    uint256 public cumulativeZboofiPerShare;
    // Info of each user that stakes tokens. stored as userInfo[userAddress]
    mapping(address => UserInfo) public userInfo;

    constructor(
        IHauntedHouse _hauntedHouse,
        IERC20 _depositToken,
        SwappingGuide _swappingGuide,
        GlobalStrategyBipsAmounts _globalStrategyBipsAmounts,
        address[] memory _REWARD_TOKENS_ARRAY
        ){
        require(address(_hauntedHouse) != address(0)
            && address(_depositToken) != address(0)
            && address(_swappingGuide) != address(0)
            ,"zero bad"
        );
        hauntedHouse = _hauntedHouse;
        depositToken = _depositToken;
        swappingGuide = _swappingGuide;
        globalStrategyBipsAmounts = _globalStrategyBipsAmounts;
        transferOwnership(address(_hauntedHouse));
        uint256 numRewardTokens = _REWARD_TOKENS_ARRAY.length;
        REWARD_TOKENS_ARRAY = _REWARD_TOKENS_ARRAY;
        NUMBER_REWARDS_TOKENS = numRewardTokens;
        for (uint256 i = 0; i < numRewardTokens;) {
            totalHarvestedAndStoredPerformanceFees.push(TotalHarvestedAndStoredPerformanceFees({totalHarvested:0, storedPerformanceFees:0}));
            unchecked {
                ++i;
            }
        } 
        IERC20(BOOFI).approve(ZBOOFI, type(uint256).max);
    }

    //simple receive for accepting AVAX transfers
    receive() external payable {
    }

    function getBipsAmounts() public view returns (GlobalStrategyBipsAmounts.BipsAmounts memory) {
        // fetch the local values
        GlobalStrategyBipsAmounts.BipsAmounts memory returnValues = bipsAmounts;
        if (!returnValues.useLocalValues) {
            returnValues = globalStrategyBipsAmounts.bipsAmounts();
        }
        return returnValues;
    }

    //finds the pending rewards for the contract to claim
    function checkReward() public view virtual returns (uint256);

    function pendingTokens(address) external view virtual override returns(address[] memory, uint256[] memory) {
        address[] memory tokens = new address[](0);
        uint256[] memory amounts = new uint256[](0);
        return (tokens, amounts);
    }

    function deposit(address from, address to, uint256 tokenAmount, uint256 newShares) external virtual override onlyOwner {
        _claimRewards();
        if (tokenAmount > 0) {
            _stake(tokenAmount);
        }
        // copy struct to memory
        UserInfo memory fromInfo = userInfo[from];
        uint256 totalZboofiOfShares = cumulativeZboofiPerShare * fromInfo.amount;
        uint256 pending = (totalZboofiOfShares - fromInfo.rewardDebt) / ACC_BOOFI_PRECISION;
        if (pending > 0) {
            _tokenOrAvaxTransfer(ZBOOFI, to, pending);
        }
        // update share amounts
        totalShares += newShares;
        fromInfo.amount += newShares;
        // update user reward debt
        fromInfo.rewardDebt = cumulativeZboofiPerShare * fromInfo.amount;
        // update struct in storage
        userInfo[from] = fromInfo;
    }

    function withdraw(address from, address to, uint256 tokenAmount, uint256 amountShares) external virtual override onlyOwner {
        _claimRewards();
        // copy struct to memory
        UserInfo memory fromInfo = userInfo[from];
        uint256 totalZboofiOfShares = cumulativeZboofiPerShare * fromInfo.amount;
        uint256 pending = (totalZboofiOfShares - fromInfo.rewardDebt) / ACC_BOOFI_PRECISION;
        if (pending > 0) {
            _tokenOrAvaxTransfer(ZBOOFI, to, pending);
        }
        // update share amounts
        totalShares -= amountShares;
        fromInfo.amount -= amountShares;
        // update user reward debt
        fromInfo.rewardDebt = cumulativeZboofiPerShare * fromInfo.amount;
        // update struct in storage
        userInfo[from] = fromInfo;
        userInfo[from] = fromInfo;
        if (tokenAmount > 0) {
            _withdraw(tokenAmount);
            _tokenOrAvaxTransfer(address(depositToken), to, tokenAmount);
        }
    }

    function inCaseTokensGetStuck(IERC20 token, address to, uint256 amount) external virtual override onlyOwner {
        require(amount > 0, "cannot recover 0 tokens");
        require(address(token) != address(depositToken), "cannot recover deposit token");
        _tokenOrAvaxTransfer(address(token), to, amount);
    }

    function migrate(address newStrategy) external virtual override onlyOwner {
        uint256 toWithdraw = _checkDepositedBalance();
        if (toWithdraw > 0) {
            _withdraw(toWithdraw);
            depositToken.transfer(newStrategy, toWithdraw);
        }
        uint256 toTransfer;
        for (uint256 i = 0; i < NUMBER_REWARDS_TOKENS;) {
            toTransfer = _checkBalance(REWARD_TOKENS_ARRAY[i]);
            _tokenOrAvaxTransfer(REWARD_TOKENS_ARRAY[i], newStrategy, toTransfer);
            unchecked {
                ++i;
            }
        }
    }

    function onMigration() external virtual override onlyOwner {
        uint256 toStake = depositToken.balanceOf(address(this));
        _stake(toStake);
        // correctly initialize total shares variable with amount of shares in HauntedHouse at migration time
        IHauntedHouse.TokenInfo memory tokenInfo = hauntedHouse.tokenParameters(address(depositToken));
        totalShares = tokenInfo.totalShares;
    }

    function transferOwnership(address newOwner) public virtual override(Ownable, IBoofiStrategy) onlyOwner {
        Ownable.transferOwnership(newOwner);
    }

    function setBipsAmounts(GlobalStrategyBipsAmounts.BipsAmounts memory _bipsAmounts) external onlyOwner {
        _setBipsAmounts(_bipsAmounts);
    }

    // hacked together to convert a uint256 into the correct format
    function setPerformanceFeeBips(uint256 newPerformanceFeeBips) external onlyOwner {
        GlobalStrategyBipsAmounts.BipsAmounts memory _bipsAmounts;
        // store the input in the memory slot of '_bipsAmounts'
        assembly {
            mstore(_bipsAmounts, newPerformanceFeeBips)
        }
        _setBipsAmounts(_bipsAmounts);
    }

    function withdrawPerformanceFees() public virtual {
        uint256 toTransfer;
        for (uint256 i = 0; i < NUMBER_REWARDS_TOKENS;) {
            toTransfer = totalHarvestedAndStoredPerformanceFees[i].storedPerformanceFees;
            totalHarvestedAndStoredPerformanceFees[i].storedPerformanceFees = 0;
            _tokenOrAvaxTransfer(REWARD_TOKENS_ARRAY[i], hauntedHouse.performanceFeeAddress(), toTransfer);
            unchecked {
                ++i;
            }
        }
    }

    //stakes tokenAmount into farm
    function _stake(uint256 tokenAmount) internal virtual;

    //withdraws tokenAmount from farm
    function _withdraw(uint256 tokenAmount) internal virtual;

    //claims reward from the farm
    function _getReward() internal virtual;

    //checks how many depositTokens this contract has in the farm
    function _checkDepositedBalance() internal virtual returns (uint256);

    //claim any as-of-yet unclaimed rewards
    function _claimRewards() internal {
        uint256 unclaimedRewards = checkReward();
        if (unclaimedRewards > 0) {
            _getReward();
            uint256 balanceDiff;
            // get the bipsAmounts (either local or global)
            GlobalStrategyBipsAmounts.BipsAmounts memory bipsToUse = getBipsAmounts();
            for (uint256 i = 0; i < NUMBER_REWARDS_TOKENS;) {
                balanceDiff = _checkBalance(REWARD_TOKENS_ARRAY[i]) - totalHarvestedAndStoredPerformanceFees[i].storedPerformanceFees;
                if (balanceDiff > 0) {
                    totalHarvestedAndStoredPerformanceFees[i].totalHarvested += uint128(balanceDiff);
                    if (bipsToUse.performanceFeeBips > 0) {
                        uint256 performanceFee = (balanceDiff * bipsToUse.performanceFeeBips) / MAX_BIPS;
                        totalHarvestedAndStoredPerformanceFees[i].storedPerformanceFees += uint128(performanceFee);
                        balanceDiff -= performanceFee;
                    }                    
                    if (REWARD_TOKENS_ARRAY[i] == AVAX) {
                        IWAVAX(WAVAX).deposit{value: balanceDiff}();
                    }
                    address[] memory tokenPath = swappingGuide.getTokenPathToBoofi(REWARD_TOKENS_ARRAY[i]);
                    address[] memory pairPath = swappingGuide.getPairPathToBoofi(REWARD_TOKENS_ARRAY[i]);
                    // swap tokens for BOOFI, and send the final BOOFI to this address
                    uint256 boofiOut = _swapExactTokensForTokens(balanceDiff, tokenPath, pairPath, address(this));
                    // transfer BOOFI to the 'strategyPool', if applicable
                    if (bipsToUse.strategyPoolBips > 0) {
                        uint256 boofiToSend = (boofiOut * bipsToUse.strategyPoolBips) / MAX_BIPS;
                        _tokenOrAvaxTransfer(BOOFI, hauntedHouse.strategyPool(), boofiToSend);
                        boofiOut -= boofiToSend;
                    }
                    // turn the remaining BOOFI into zBOOFI and update the cumulativeZboofiPerShare variable accordingly
                    if (boofiOut > 0) {
                        uint256 zboofiBefore = IERC20(ZBOOFI).balanceOf(address(this));
                        IZBOOFI(ZBOOFI).enter(boofiOut);
                        uint256 zboofiIncrease = IERC20(ZBOOFI).balanceOf(address(this)) - zboofiBefore;
                        cumulativeZboofiPerShare += (zboofiIncrease * ACC_BOOFI_PRECISION) / totalShares;
                    }
                }
                unchecked {
                    ++i;
                }
            }
        }
    }

    function _swapExactTokensForTokens(
        uint256 amountIn,
        address[] memory tokenPath,
        address[] memory pairPath,
        address _to
    ) internal returns (uint256) {
        IERC20(tokenPath[0]).transfer(pairPath[0], amountIn);
        uint256 pairPathLength = pairPath.length;
        for (uint256 i; i < pairPathLength;) {
            // sort the tokens
            (address token0,) = UniswapV2Library.sortTokens(tokenPath[i], tokenPath[i + 1]);
            // get the reserves of the i-th pair in the route
            (uint256 reserve0, uint256 reserve1,) = IUniswapV2Pair(pairPath[i]).getReserves();
            // swap the order of the reserves if necessary
            (uint256 reserveIn, uint256 reserveOut) = tokenPath[i] == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
            // set the 'to' value -- either the next pair in the array, or the ultimate destination
            address to = i < (pairPathLength - 1) ? pairPath[i + 1] : _to;
            // properly set & order the amount in
            (uint256 amount0Out, uint256 amount1Out) = tokenPath[i] == token0 ? (uint256(0), amountIn) : (amountIn, uint256(0));
            // perform the swap with the pair
            IUniswapV2Pair(pairPath[i]).swap(
                amount0Out, amount1Out, to, new bytes(0)
            );
            // calculate the amount received
            amountIn = UniswapV2Library.getAmountOut(amountIn, reserveIn, reserveOut);
            unchecked {
                ++i;
            }
        }
        return amountIn;
    }

    function _setBipsAmounts(GlobalStrategyBipsAmounts.BipsAmounts memory _bipsAmounts) internal {
        require(_bipsAmounts.performanceFeeBips <= MAX_BIPS);
        require(_bipsAmounts.strategyPoolBips <= MAX_BIPS);
        bipsAmounts = _bipsAmounts;
    }
}

contract StrategyForJoeV2Staking is StrategyBase {
    IJoeChef public constant JOE_MASTERCHEF_V2 = IJoeChef(0xd6a4F121CA35509aF06A0Be99093d08462f53052);
    uint256 public immutable JOE_PID;

    constructor(
        IHauntedHouse _hauntedHouse,
        IERC20 _depositToken,
        SwappingGuide _swappingGuide,
        GlobalStrategyBipsAmounts _globalStrategyBipsAmounts,
        address[] memory _REWARD_TOKENS_ARRAY,
        uint256 _JOE_PID
        ) 
        StrategyBase(_hauntedHouse, _depositToken, _swappingGuide, _globalStrategyBipsAmounts, _REWARD_TOKENS_ARRAY)
    {
        JOE_PID = _JOE_PID;
        _depositToken.approve(address(JOE_MASTERCHEF_V2), MAX_UINT);
    }
    //finds the pending rewards for the contract to claim
    function checkReward() public view override returns (uint256) {
        (uint256 pendingJoe, , , ) = JOE_MASTERCHEF_V2.pendingTokens(JOE_PID, address(this));
        return pendingJoe;
    }

    //stakes tokenAmount into farm
    function _stake(uint256 tokenAmount) internal override {
        JOE_MASTERCHEF_V2.deposit(JOE_PID, tokenAmount);
    }

    //withdraws tokenAmount from farm
    function _withdraw(uint256 tokenAmount) internal override {
        JOE_MASTERCHEF_V2.withdraw(JOE_PID, tokenAmount);
    }

    //claims reward from the farm
    function _getReward() internal override {
        JOE_MASTERCHEF_V2.deposit(JOE_PID, 0);
    }

    //checks how many depositTokens this contract has in the farm
    function _checkDepositedBalance() internal view override returns (uint256) {
        (uint256 depositedBalance, ) = JOE_MASTERCHEF_V2.userInfo(JOE_PID, address(this));
        return depositedBalance;
    }
}

contract StrategyForJoeV3Staking is StrategyBase {
    address internal constant JOE_TOKEN = 0x6e84a6216eA6dACC71eE8E6b0a5B7322EEbC0fDd;
    IJoeChef public constant JOE_MASTERCHEF_V3 = IJoeChef(0x188bED1968b795d5c9022F6a0bb5931Ac4c18F00);
    uint256 public immutable JOE_PID;

    constructor(
        IHauntedHouse _hauntedHouse,
        IERC20 _depositToken,
        SwappingGuide _swappingGuide,
        GlobalStrategyBipsAmounts _globalStrategyBipsAmounts,
        address[] memory _REWARD_TOKENS_ARRAY,
        uint256 _JOE_PID
        ) 
        StrategyBase(_hauntedHouse, _depositToken, _swappingGuide, _globalStrategyBipsAmounts, _REWARD_TOKENS_ARRAY)
    {
        require(_REWARD_TOKENS_ARRAY[0] == JOE_TOKEN, "first reward must be JOE");
        JOE_PID = _JOE_PID;
        _depositToken.approve(address(JOE_MASTERCHEF_V3), MAX_UINT);
    }
    //finds the pending rewards for the contract to claim
    function checkReward() public view override returns (uint256) {
        (uint256 pendingJoe, , , ) = JOE_MASTERCHEF_V3.pendingTokens(JOE_PID, address(this));
        return pendingJoe;
    }

    //stakes tokenAmount into farm
    function _stake(uint256 tokenAmount) internal override {
        JOE_MASTERCHEF_V3.deposit(JOE_PID, tokenAmount);
    }

    //withdraws tokenAmount from farm
    function _withdraw(uint256 tokenAmount) internal override {
        JOE_MASTERCHEF_V3.withdraw(JOE_PID, tokenAmount);
    }

    //claims reward from the farm
    function _getReward() internal override {
        JOE_MASTERCHEF_V3.deposit(JOE_PID, 0);
    }

    //checks how many depositTokens this contract has in the farm
    function _checkDepositedBalance() internal view override returns (uint256) {
        (uint256 depositedBalance, ) = JOE_MASTERCHEF_V3.userInfo(JOE_PID, address(this));
        return depositedBalance;
    }
}

interface IBoostedMasterChefJoe {
    event Add(
        uint256 indexed pid,
        uint256 allocPoint,
        uint256 veJoeShareBp,
        address indexed lpToken,
        address indexed rewarder
    );
    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );
    event Harvest(address indexed user, uint256 indexed pid, uint256 amount);
    event Init(uint256 amount);
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
    event Set(
        uint256 indexed pid,
        uint256 allocPoint,
        uint256 veJoeShareBp,
        address indexed rewarder,
        bool overwrite
    );
    event UpdatePool(
        uint256 indexed pid,
        uint256 lastRewardTimestamp,
        uint256 lpSupply,
        uint256 accJoePerShare,
        uint256 accJoePerFactorPerShare
    );
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);

    function JOE() external view returns (address);

    function MASTER_CHEF_V2() external view returns (address);

    function MASTER_PID() external view returns (uint256);

    function VEJOE() external view returns (address);

    function add(
        uint96 _allocPoint,
        uint32 _veJoeShareBp,
        address _lpToken,
        address _rewarder
    ) external;

    function claimableJoe(uint256, address) external view returns (uint256);

    function deposit(uint256 _pid, uint256 _amount) external;

    function emergencyWithdraw(uint256 _pid) external;

    function harvestFromMasterChef() external;

    function init(address _dummyToken) external;

    function initialize(
        address _MASTER_CHEF_V2,
        address _joe,
        address _veJoe,
        uint256 _MASTER_PID
    ) external;

    function joePerSec() external view returns (uint256 amount);

    function massUpdatePools() external;

    function owner() external view returns (address);

    function pendingTokens(uint256 _pid, address _user)
        external
        view
        returns (
            uint256 pendingJoe,
            address bonusTokenAddress,
            string memory bonusTokenSymbol,
            uint256 pendingBonusToken
        );

    function poolInfo(uint256)
        external
        view
        returns (
            address lpToken,
            uint96 allocPoint,
            uint256 accJoePerShare,
            uint256 accJoePerFactorPerShare,
            uint64 lastRewardTimestamp,
            address rewarder,
            uint32 veJoeShareBp,
            uint256 totalFactor,
            uint256 totalLpSupply
        );

    function poolLength() external view returns (uint256 pools);

    function renounceOwnership() external;

    function set(
        uint256 _pid,
        uint96 _allocPoint,
        uint32 _veJoeShareBp,
        address _rewarder,
        bool _overwrite
    ) external;

    function totalAllocPoint() external view returns (uint256);

    function transferOwnership(address newOwner) external;

    function updateFactor(address _user, uint256 _newVeJoeBalance) external;

    function updatePool(uint256 _pid) external;

    function userInfo(uint256, address)
        external
        view
        returns (
            uint256 amount,
            uint256 rewardDebt,
            uint256 factor
        );

    function withdraw(uint256 _pid, uint256 _amount) external;
}

contract StrategyForJoeBoostedStaking is StrategyBase {
    address internal constant JOE_TOKEN = 0x6e84a6216eA6dACC71eE8E6b0a5B7322EEbC0fDd;
    IBoostedMasterChefJoe public constant JOE_BOOSTED_STAKING = IBoostedMasterChefJoe(0x4483f0b6e2F5486D06958C20f8C39A7aBe87bf8F);
    uint256 public immutable JOE_PID;

    constructor(
        IHauntedHouse _hauntedHouse,
        IERC20 _depositToken,
        SwappingGuide _swappingGuide,
        GlobalStrategyBipsAmounts _globalStrategyBipsAmounts,
        address[] memory _REWARD_TOKENS_ARRAY,
        uint256 _JOE_PID
        ) 
        StrategyBase(_hauntedHouse, _depositToken, _swappingGuide, _globalStrategyBipsAmounts, _REWARD_TOKENS_ARRAY)
    {
        require(_REWARD_TOKENS_ARRAY[0] == JOE_TOKEN, "first reward must be JOE");
        JOE_PID = _JOE_PID;
        _depositToken.approve(address(JOE_BOOSTED_STAKING), MAX_UINT);
    }
    //finds the pending rewards for the contract to claim
    function checkReward() public view override returns (uint256) {
        (uint256 pendingJoe, , , ) = JOE_BOOSTED_STAKING.pendingTokens(JOE_PID, address(this));
        return pendingJoe;
    }

    //stakes tokenAmount into farm
    function _stake(uint256 tokenAmount) internal override {
        JOE_BOOSTED_STAKING.deposit(JOE_PID, tokenAmount);
    }

    //withdraws tokenAmount from farm
    function _withdraw(uint256 tokenAmount) internal override {
        JOE_BOOSTED_STAKING.withdraw(JOE_PID, tokenAmount);
    }

    //claims reward from the farm
    function _getReward() internal override {
        JOE_BOOSTED_STAKING.deposit(JOE_PID, 0);
    }

    //checks how many depositTokens this contract has in the farm
    function _checkDepositedBalance() internal view override returns (uint256) {
        (uint256 depositedBalance, , ) = JOE_BOOSTED_STAKING.userInfo(JOE_PID, address(this));
        return depositedBalance;
    }
}