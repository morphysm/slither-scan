/**
 *Submitted for verification at snowtrace.io on 2022-07-06
*/

// SPDX-License-Identifier: MIT
/*

            @@@                                                                                   
            @@@@@@@                                                                                 
         &    @@@@@@@@                                                                              
       @@@@@    @@@@@@@@                                                                            
     @@@@@@@@     @@@@@@@@        @@@    @@@  @@@@@@        @@@@@@@^      @@@@@@@     @@  @@@     @@
   @@@@@@@@    @    @@@@@@@@        @@  @@.   @@   @@@    @@@     @@@   @@@     @@@   @@  @@@@    @@
 @@@@@@@     @@@@@    @@@@@@@@       @@@@     @@   @@@    @@           @@@       @@@  @@  @@ @@@  @@
 @@@@@@@~    @@@@@    @@@@@@@@       @@@@     @@@@@@      @@           @@@       @@@  @@  @@   @@ @@
   @@@@@@@@    @    @@@@@@@@       @@@  @@@   @@  @@@     @@@     @@@   @@@     @@@   @@  @@    @@@@
     @@@@@@@@     @@@@@@@@        @@@    @@@  @@    @@@     @@@@@@@.      @@@@@@@     @@  @@     @@@
       @@@@@    @@@@@@@@                                                                            
         ~    @@@@@@@@                                                                              
            @@@@@@@                                                                                 
              @@@                                   

            
            WEBSITE:    xr-coin.net
            E-MAIL:     [email protected]
            Twitter:    ---->   https://twitter.com/xr_coin
            Instagram:  ---->   https://instagram.com/xr_coin  
            Telegram:   ---->   https://t.me/xr_coin
            Medium:     ---->   https://medium.com/@xr_coin
            Linkedin:   ---->   https://www.linkedin.com/in/xr-coin/
            Discord:    ---->   https://discord.gg/r37xC8WmFS

*/

pragma solidity 0.8.13;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

library Address {
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            codehash := extcodehash(account)
        }
        return (codehash != accountHash && codehash != 0x0);
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }

    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 weiValue,
        string memory errorMessage
    ) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: weiValue}(
            data
        );
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
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

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() external virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) external virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function getUnlockTime() public view returns (uint256) {
        return _lockTime;
    }

    function getTime() public view returns (uint256) {
        return block.timestamp;
    }
}


interface IUniswapV2Factory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}


interface IUniswapV2Pair {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function burn(address to)
        external
        returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

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

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
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

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

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

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

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

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
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

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

contract XR_COIN is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    address payable public marketingAddress =
        payable(0x864BC306d5E444773b06500Ae8B0821C2206211b); // Marketing Address

    address payable public devAddress =
        payable(0x1f73Eb7f782Bad5d53AaF3D8cc8794D8294c0720); // Developer Address

    address payable public liquidityAddress =
        payable(0x6a54c90A6b6229C758eb567AeA3124fE3407c221); // Liquidity Address

    address public immutable deadAddress =
        0x000000000000000000000000000000000000dEaD; // dead address

    address public bridgeAddress;

    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => bool) private _isExcludedFromFee;

    mapping(address => bool) private _isExcluded;
    address[] private _excluded;

    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal = 100000000 * 1e18;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;

    bool public limitsInEffect = true;

    string private constant _name = "XR COIN";
    string private constant _symbol = "XR";

    uint8 private constant _decimals = 18;

    uint256 private constant BUY = 1;
    uint256 private constant SELL = 2;
    uint256 private constant TRANSFER = 3;
    uint256 private buyOrSellSwitch;

    uint256 private _taxFee;
    uint256 private _previousTaxFee = _taxFee;

    uint256 private _liquidityFee;
    uint256 private _previousLiquidityFee = _liquidityFee;

    uint256 private _buyTaxFee = 0;
    uint256 public _buyLiquidityFee = 2;
    uint256 public _buyMarketingFee = 6;
    uint256 public _buyDevFee = 2;

    uint256 private _sellTaxFee = 0;
    uint256 public _sellLiquidityFee = 2;
    uint256 public _sellMarketingFee = 6;
    uint256 public _sellDevFee = 2;

    uint256 public tradingActiveBlock = 0; // 0 means trading is not active
    mapping(address => bool) public boughtEarly;
    uint256 public earlyBuyPenaltyEnd; // determines when snipers/bots can sell without extra penalty

    uint256 private _liquidityTokensToSwap;
    uint256 private _marketingTokensToSwap;
    uint256 private _teamTokensToSwap;

    bool private gasLimitActive = true;
    uint256 private gasPriceLimit = 100 * 1 gwei;
    uint256 private gasMaxLimit =  50000000; // gasLeft limit

    uint256 public maxTransactionAmount;
    mapping (address => bool) public _isExcludedMaxTransactionAmount;

    mapping (address => bool) public automatedMarketMakerPairs;

    uint256 private minimumTokensBeforeSwap = _tTotal * 5 / 10000; // 0.05%

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;

    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = false;
    bool public tradingActive = false;

    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiquidity
    );

    event SwapETHForTokens(uint256 amountIn, address[] path);

    event SwapTokensForETH(uint256 amountIn, address[] path);

    event SetAutomatedMarketMakerPair(address pair, bool value);

    event ExcludeFromReward(address excludedAddress);

    event IncludeInReward(address includedAddress);

    event ExcludeFromFee(address excludedAddress);

    event IncludeInFee(address includedAddress);

    event SetBuyFee(uint256 marketingFee, uint256 liquidityFee, uint256 devFee);

    event SetSellFee(uint256 marketingFee, uint256 liquidityFee, uint256 devFee);

    event TransferForeignToken(address token, uint256 amount);

    event UpdatedMarketingAddress(address marketing);

    event UpdatedLiquidityAddress(address liquidity);

    event UpdatedDevAddress(address devAddress);

    event OwnerForcedSwapBack(uint256 timestamp);

    event BoughtEarly(address indexed sniper);

    event RemovedSniper(address indexed notsnipersupposedly);

    event UpdatedRouter(address indexed newrouter);

    modifier lockTheSwap() {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    modifier onlyBridge() {
        require(bridgeAddress == msg.sender, "This method can be only triggered by bridge address.");
        _;
    }

    
    modifier tempExcludeRewards(address wallet){
        bool addressIsExcludedFromReward = isExcludedFromReward(wallet);

        if(addressIsExcludedFromReward == false){
            excludeFromReward(wallet);
        }

        _;

        if(addressIsExcludedFromReward == false){
            includeInReward(wallet);
        }
    }


    constructor() {
        _rOwned[_msgSender()] = _rTotal;

        maxTransactionAmount = _tTotal * 5 / 1000; // 0.5% maxTransactionAmountTxn

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0xb6bFfD8af0deeAc17B8B586Bae88143A2394c691);
        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;

        _setAutomatedMarketMakerPair(_uniswapV2Pair, true);

        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[marketingAddress] = true;
        _isExcludedFromFee[liquidityAddress] = true;
        _isExcludedFromFee[devAddress] = true;

        excludeFromMaxTransaction(owner(), true);
        excludeFromMaxTransaction(address(this), true);
        excludeFromMaxTransaction(address(0xdead), true);

        emit Transfer(address(0), _msgSender(), _tTotal);
    }

    function name() external pure returns (string memory) {
        return _name;
    }

    function symbol() external pure returns (string memory) {
        return _symbol;
    }

    function decimals() external pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }

        function tokenFromReflection(uint256 rAmount)
        public
        view
        returns (uint256)
    {
        require(
            rAmount <= _rTotal,
            "Amount must be less than total reflections"
        );
        uint256 currentRate = _getRate();
        return rAmount.div(currentRate);
    }

    function transfer(address recipient, uint256 amount)
        external
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
        external
        view
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        external
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        external
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].add(addedValue)
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        external
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(
                subtractedValue,
                "ERC20: decreased allowance below zero"
            )
        );
        return true;
    }

    function isExcludedFromReward(address account)
        public
        view
        returns (bool)
    {
        return _isExcluded[account];
    }

    function totalFees() external view returns (uint256) {
        return _tFeeTotal;
    }

    // once enabled, can never be turned off
    function enableTrading() external onlyOwner {
        tradingActive = true;
        swapAndLiquifyEnabled = true;
        tradingActiveBlock = block.number;
        earlyBuyPenaltyEnd = block.timestamp + 72 hours;
    }

    function minimumTokensBeforeSwapAmount() external view returns (uint256) {
        return minimumTokensBeforeSwap;
    }

    function setAutomatedMarketMakerPair(address pair, bool value) external onlyOwner {
        require(pair != uniswapV2Pair, "The pair cannot be removed from automatedMarketMakerPairs");

        _setAutomatedMarketMakerPair(pair, value);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        automatedMarketMakerPairs[pair] = value;
        excludeFromMaxTransaction(pair, value);
        if(value){excludeFromReward(pair);}
        if(!value){includeInReward(pair);}
        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function setProtectionSettings(bool antiGas) external onlyOwner() {
        gasLimitActive = antiGas;
    }

    function setGasPriceLimit(uint256 gas) external onlyOwner {
        require(gas >= 75);
        gasPriceLimit = gas * 1 gwei;
    }

    function setGasMaxLimit(uint256 gas) external onlyOwner {
        require(gas >= 750000);
        gasMaxLimit = gas * gasPriceLimit;
    }

    function removeLimits() external onlyOwner returns (bool){
        limitsInEffect = false;
        gasLimitActive = false;
        return true;
    }

    function excludeFromReward(address account) public onlyOwner {
        require(!_isExcluded[account], "Account is already excluded");
        require(_excluded.length + 1 <= 50, "Cannot exclude more than 50 accounts.  Include a previously excluded address.");
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function includeInReward(address account) public onlyOwner {
        require(_isExcluded[account], "Account is not excluded");
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

    function excludeFromMaxTransaction(address updAds, bool isEx) public onlyOwner {
        _isExcludedMaxTransactionAmount[updAds] = isEx;
    }

    function safeTransfer(address from, address to, uint256 amount) public onlyOwner {
        _tokenTransfer(from, to, amount, false);
    }

    function _safeTransfer(IERC20 _token, address recipient, uint256 amount) private {
        bool sent = _token.transfer(recipient, amount);
        require(sent, "Token transfer failed");
    }

    function getStuckBnb(uint256 amount, address receiveAddress) external onlyOwner {
        payable(receiveAddress).transfer(amount);
    }

    function getStuckToken(IERC20 _token, address receiveAddress, uint256 amount) external onlyOwner {
        _safeTransfer(_token, receiveAddress, amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        if(!tradingActive){
            require(_isExcludedFromFee[from] || _isExcludedFromFee[to], "Trading is not active yet.");
        }

     if(limitsInEffect){
        if (
            from != owner() &&
            to != owner() &&
            to != address(0) &&
            to != address(0xdead) &&
            !inSwapAndLiquify
        ){

            if(from != owner() && to != uniswapV2Pair && block.number == tradingActiveBlock){
                boughtEarly[to] = true;
                emit BoughtEarly(to);
            }

            if (gasLimitActive && automatedMarketMakerPairs[from]) {
                require(tx.gasprice <= gasPriceLimit, "Gas price exceeds limit.");
            }

            //only on buys
            if (automatedMarketMakerPairs[from] && !_isExcludedMaxTransactionAmount[to]) {
                    require(amount <= maxTransactionAmount, "Buy transfer amount exceeds the maxTransactionAmount.");
            }
        }
    }

        uint256 totalTokensToSwap = _liquidityTokensToSwap + _marketingTokensToSwap + _teamTokensToSwap;
        uint256 contractTokenBalance = balanceOf(address(this));
        bool overMinimumTokenBalance = contractTokenBalance >= minimumTokensBeforeSwap;

        // swap and liquify
        if (
            !inSwapAndLiquify &&
            swapAndLiquifyEnabled &&
            balanceOf(uniswapV2Pair) > 0 &&
            totalTokensToSwap > 0 &&
            !_isExcludedFromFee[to] &&
            !_isExcludedFromFee[from] &&
            automatedMarketMakerPairs[to] &&
            overMinimumTokenBalance
        ) {
            swapBack();
        }

        bool takeFee = true;

        // If any account belongs to _isExcludedFromFee account then remove the fee
        if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
            takeFee = false;
            buyOrSellSwitch = TRANSFER;
        } else {
            // Buy
            if (automatedMarketMakerPairs[from]) {
                removeAllFee();
                _taxFee = _buyTaxFee;
                _liquidityFee = _buyLiquidityFee + _buyMarketingFee + _buyDevFee;
                buyOrSellSwitch = BUY;
            }
            // Sell
            else if (automatedMarketMakerPairs[to]) {
                removeAllFee();
                _taxFee = _sellTaxFee;
                _liquidityFee = _sellLiquidityFee + _sellMarketingFee + _sellDevFee;
                buyOrSellSwitch = SELL;
                // triple tax if bought in the same block as trading active for 72 hours
                if(boughtEarly[from]  && earlyBuyPenaltyEnd <= block.number){
                    _taxFee = _taxFee * 3;
                    _liquidityFee = _liquidityFee * 3;
                }
            // Normal transfers do not get taxed
            } else {
                removeAllFee();
                buyOrSellSwitch = TRANSFER;
            }
        }

        _tokenTransfer(from, to, amount, takeFee);

    }

    function swapBack() private lockTheSwap {
        uint256 contractBalance = balanceOf(address(this));

        uint256 totalTokensToSwap = _liquidityTokensToSwap.add(_teamTokensToSwap).add(_marketingTokensToSwap);

        // Halve the amount of liquidity tokens
        uint256 tokensForLiquidity = _liquidityTokensToSwap.div(2);
        uint256 amountToSwapForBNB = contractBalance.sub(tokensForLiquidity);

        uint256 initialBNBBalance = address(this).balance;

        swapTokensForBNB(amountToSwapForBNB);

        uint256 bnbBalance = address(this).balance.sub(initialBNBBalance);

        uint256 bnbForMarketing = bnbBalance.mul(_marketingTokensToSwap).div(totalTokensToSwap);
        uint256 bnbForTeam = bnbBalance.mul(_teamTokensToSwap).div(totalTokensToSwap);

        uint256 bnbForLiquidity = bnbBalance.sub(bnbForMarketing).sub(bnbForTeam);

        _liquidityTokensToSwap = 0;
        _marketingTokensToSwap = 0;
        _teamTokensToSwap = 0;

        (bool success,) = address(devAddress).call{value: bnbForTeam}("");
        (success,) = address(marketingAddress).call{value: bnbForMarketing}("");

        addLiquidity(tokensForLiquidity, bnbForLiquidity);
        emit SwapAndLiquify(amountToSwapForBNB, bnbForLiquidity, tokensForLiquidity);

        // send leftover BNB to the marketing wallet so it doesn't get stuck on the contract.
        if(address(this).balance > 1e17){
            (success,) = address(marketingAddress).call{value: address(this).balance}("");
        }
    }

    function swapTokensForBNB(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            liquidityAddress,
            block.timestamp
        );
    }

    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 amount,
        bool takeFee
    ) private {
        if (!takeFee) removeAllFee();

        if (_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferFromExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
            _transferToExcluded(sender, recipient, amount);
        } else if (_isExcluded[sender] && _isExcluded[recipient]) {
            _transferBothExcluded(sender, recipient, amount);
        } else {
            _transferStandard(sender, recipient, amount);
        }

        restoreAllFee();
    }

    function _transferStandard(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLiquidity
        ) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferToExcluded(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLiquidity
        ) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferFromExcluded(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLiquidity
        ) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferBothExcluded(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLiquidity
        ) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    function _getValues(uint256 tAmount)
        private
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        (
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLiquidity
        ) = _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(
            tAmount,
            tFee,
            tLiquidity,
            _getRate()
        );
        return (
            rAmount,
            rTransferAmount,
            rFee,
            tTransferAmount,
            tFee,
            tLiquidity
        );
    }

    function _getTValues(uint256 tAmount)
        private
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 tFee = calculateTaxFee(tAmount);
        uint256 tLiquidity = calculateLiquidityFee(tAmount);
        uint256 tTransferAmount = tAmount.sub(tFee).sub(tLiquidity);
        return (tTransferAmount, tFee, tLiquidity);
    }

    function _getRValues(
        uint256 tAmount,
        uint256 tFee,
        uint256 tLiquidity,
        uint256 currentRate
    )
        private
        pure
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rLiquidity);
        return (rAmount, rTransferAmount, rFee);
    }

    function _getRate() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns (uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (
                _rOwned[_excluded[i]] > rSupply ||
                _tOwned[_excluded[i]] > tSupply
            ) return (_rTotal, _tTotal);
            rSupply = rSupply.sub(_rOwned[_excluded[i]]);
            tSupply = tSupply.sub(_tOwned[_excluded[i]]);
        }
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    function _takeLiquidity(uint256 tLiquidity) private {
        if(buyOrSellSwitch == BUY){
            _liquidityTokensToSwap += tLiquidity * _buyLiquidityFee / _liquidityFee;
            _teamTokensToSwap += tLiquidity * _buyDevFee / _liquidityFee;
            _marketingTokensToSwap += tLiquidity * _buyMarketingFee / _liquidityFee;
        } else if(buyOrSellSwitch == SELL){
            _liquidityTokensToSwap += tLiquidity * _sellLiquidityFee / _liquidityFee;
            _teamTokensToSwap += tLiquidity * _sellDevFee / _liquidityFee;
            _marketingTokensToSwap += tLiquidity * _sellMarketingFee / _liquidityFee;
        }
        uint256 currentRate = _getRate();
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rLiquidity);
        if (_isExcluded[address(this)])
            _tOwned[address(this)] = _tOwned[address(this)].add(tLiquidity);
    }

    function calculateTaxFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_taxFee).div(10**2);
    }

    function calculateLiquidityFee(uint256 _amount)
        private
        view
        returns (uint256)
    {
        return _amount.mul(_liquidityFee).div(10**2);
    }

    function removeAllFee() private {
        if (_taxFee == 0 && _liquidityFee == 0) return;

        _previousTaxFee = _taxFee;
        _previousLiquidityFee = _liquidityFee;

        _taxFee = 0;
        _liquidityFee = 0;
    }

    function restoreAllFee() private {
        _taxFee = _previousTaxFee;
        _liquidityFee = _previousLiquidityFee;
    }

    function isExcludedFromFee(address account) external view returns (bool) {
        return _isExcludedFromFee[account];
    }

    function excludeFromFee(address account) external onlyOwner {
        _isExcludedFromFee[account] = true;
        emit ExcludeFromFee(account);
    }

    function includeInFee(address account) external onlyOwner {
        _isExcludedFromFee[account] = false;
        emit IncludeInFee(account);
    }

    function antiWhale(address account) external onlyOwner {
        boughtEarly[account] = false;
        emit RemovedSniper(account);
    }

    function setBuyFee(uint256 buyDevFee, uint256 buyLiquidityFee, uint256 buyMarketingFee)
        external
        onlyOwner
    {
        _buyDevFee = buyDevFee;
        _buyLiquidityFee = buyLiquidityFee;
        _buyMarketingFee = buyMarketingFee;
        require(_buyDevFee + _buyLiquidityFee + _buyMarketingFee <= 30, "Must keep taxes below 30%");
        emit SetBuyFee(buyMarketingFee, buyLiquidityFee, buyDevFee);
    }

    function setSellFee(uint256 sellDevFee, uint256 sellLiquidityFee, uint256 sellMarketingFee)
        external
        onlyOwner
    {
        _sellDevFee = sellDevFee;
        _sellLiquidityFee = sellLiquidityFee;
        _sellMarketingFee = sellMarketingFee;
        require(_sellDevFee + _sellLiquidityFee + _sellMarketingFee <= 30, "Must keep taxes below 30%");
        emit SetSellFee(sellMarketingFee, sellLiquidityFee, sellDevFee);
    }


    function setMarketingAddress(address _marketingAddress) external onlyOwner {
        require(_marketingAddress != address(0), "_marketingAddress address cannot be 0");
        marketingAddress = payable(_marketingAddress);
        _isExcludedFromFee[marketingAddress] = true;
        emit UpdatedMarketingAddress(_marketingAddress);
    }

    function setDevAddress(address _devAddress) external onlyOwner {
        require(_devAddress != address(0), "_devAddress address cannot be 0");
        devAddress = payable(_devAddress);
        _isExcludedFromFee[devAddress] = true;
        emit UpdatedDevAddress(devAddress);
    }

    function setLiquidityAddress(address _liquidityAddress) external onlyOwner {
        require(_liquidityAddress != address(0), "_liquidityAddress address cannot be 0");
        liquidityAddress = payable(_liquidityAddress);
        _isExcludedFromFee[liquidityAddress] = true;
        emit UpdatedLiquidityAddress(_liquidityAddress);
    }

    function setBridgeAddress(address _bridgeAddress) external onlyOwner {
        bridgeAddress = _bridgeAddress;
    }

    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }

    function getPairAddress() external view onlyOwner returns (address) {
        return uniswapV2Pair;
    }

    function changeRouterVersion(address _router)
        external
        onlyOwner
        returns (address _pair)
    {
        require(_router != address(0), "_router address cannot be 0");
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(_router);

        _pair = IUniswapV2Factory(_uniswapV2Router.factory()).getPair(
            address(this),
            _uniswapV2Router.WETH()
        );
        if (_pair == address(0)) {
            // Pair doesn't exist
            _pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(
                address(this),
                _uniswapV2Router.WETH()
            );
        }
        uniswapV2Pair = _pair;

        // Set the router of the contract variables
        uniswapV2Router = _uniswapV2Router;
        emit UpdatedRouter(_router);
    }

    // To receive ETH from uniswapV2Router when swapping
    receive() external payable {}

    function _bridgeMintTokens(address _to, uint256 _tokens) internal virtual {
        require(_to != address(0), "BEP20: mint to the zero address");
        require(_tokens > 0, "Tokens value should be greater then Zero");

        uint256 rTokens = _tokens.mul(_getRate());
        _tOwned[_to] = _tOwned[_to].add(_tokens);
        _rOwned[_to] = _rOwned[_to].add(rTokens);
        _tTotal = _tTotal.add(_tokens);
        _rTotal = _rTotal.add(rTokens);

        emit Transfer(address(0), _to, _tokens);
    }

    function _burnTokens(address _from, uint256 _tokens) private {
        require(_from != address(0), "BEP20: burn from the zero address");
        require(_tokens > 0, "Tokens value should be greater then Zero");
        require(_tokens <= balanceOf(_from), "Tokens value should be less then equal to your balance");

        uint256 rTokens = _tokens.mul(_getRate());
        if(_isExcluded[_from])
            _tOwned[_from] = _tOwned[_from].sub(_tokens);
        _rOwned[_from] = _rOwned[_from].sub(rTokens);
        _tTotal = _tTotal.sub(_tokens);
        _rTotal = _rTotal.sub(rTokens);

        emit Transfer(_from, address(this), _tokens);
    }

    function burnTokens(uint256 tokens) external {
        tokens = tokens.mul( 10**_decimals );
        _burnTokens(msg.sender, tokens);
    }

    function _bridgeBurnTokens(address _from, uint256 _tokens) private {
        _burnTokens(_from, _tokens);
    }

    function transferForeignToken(address _token, address _to)
        external
        onlyOwner
        returns (bool _sent)
    {
        require(_token != address(0), "_token address cannot be 0");
        require(_token != address(this), "Can't withdraw native tokens");
        uint256 _contractBalance = IERC20(_token).balanceOf(address(this));
        _sent = IERC20(_token).transfer(_to, _contractBalance);
        emit TransferForeignToken(_token, _contractBalance);
    }

    function bridgeMint(address to, uint amount) external onlyBridge() {
      _bridgeMintTokens(to, amount);
    }

    function bridgeBurn(address from, uint amount) external onlyBridge() tempExcludeRewards(from) {
      _bridgeBurnTokens(from, amount);
    }

}

/*


██╗░░██╗██████╗░  ░█████╗░░█████╗░██╗███╗░░██╗
╚██╗██╔╝██╔══██╗  ██╔══██╗██╔══██╗██║████╗░██║
░╚███╔╝░██████╔╝  ██║░░╚═╝██║░░██║██║██╔██╗██║
░██╔██╗░██╔══██╗  ██║░░██╗██║░░██║██║██║╚████║
██╔╝╚██╗██║░░██║  ╚█████╔╝╚█████╔╝██║██║░╚███║
╚═╝░░╚═╝╚═╝░░╚═╝  ░╚════╝░░╚════╝░╚═╝╚═╝░░╚══╝




        
███╗░░░███╗███████╗████████╗░█████╗░██╗░░░██╗███████╗██████╗░░██████╗███████╗  ░░░░░░  ███╗░░██╗███████╗████████╗
████╗░████║██╔════╝╚══██╔══╝██╔══██╗██║░░░██║██╔════╝██╔══██╗██╔════╝██╔════╝  ░░░░░░  ████╗░██║██╔════╝╚══██╔══╝
██╔████╔██║█████╗░░░░░██║░░░███████║╚██╗░██╔╝█████╗░░██████╔╝╚█████╗░█████╗░░  █████╗  ██╔██╗██║█████╗░░░░░██║░░░
██║╚██╔╝██║██╔══╝░░░░░██║░░░██╔══██║░╚████╔╝░██╔══╝░░██╔══██╗░╚═══██╗██╔══╝░░  ╚════╝  ██║╚████║██╔══╝░░░░░██║░░░
██║░╚═╝░██║███████╗░░░██║░░░██║░░██║░░╚██╔╝░░███████╗██║░░██║██████╔╝███████╗  ░░░░░░  ██║░╚███║██║░░░░░░░░██║░░░
╚═╝░░░░░╚═╝╚══════╝░░░╚═╝░░░╚═╝░░╚═╝░░░╚═╝░░░╚══════╝╚═╝░░╚═╝╚═════╝░╚══════╝  ░░░░░░  ╚═╝░░╚══╝╚═╝░░░░░░░░╚═╝░░░

███╗░░░███╗░█████╗░██████╗░██╗░░██╗███████╗████████╗██████╗░██╗░░░░░░█████╗░░█████╗░███████╗  ░░░░░░
████╗░████║██╔══██╗██╔══██╗██║░██╔╝██╔════╝╚══██╔══╝██╔══██╗██║░░░░░██╔══██╗██╔══██╗██╔════╝  ░░░░░░
██╔████╔██║███████║██████╔╝█████═╝░█████╗░░░░░██║░░░██████╔╝██║░░░░░███████║██║░░╚═╝█████╗░░  █████╗
██║╚██╔╝██║██╔══██║██╔══██╗██╔═██╗░██╔══╝░░░░░██║░░░██╔═══╝░██║░░░░░██╔══██║██║░░██╗██╔══╝░░  ╚════╝
██║░╚═╝░██║██║░░██║██║░░██║██║░╚██╗███████╗░░░██║░░░██║░░░░░███████╗██║░░██║╚█████╔╝███████╗  ░░░░░░
╚═╝░░░░░╚═╝╚═╝░░╚═╝╚═╝░░╚═╝╚═╝░░╚═╝╚══════╝░░░╚═╝░░░╚═╝░░░░░╚══════╝╚═╝░░╚═╝░╚════╝░╚══════╝  ░░░░░░

██████╗░░█████╗░██╗░░░██╗███╗░░░███╗███████╗███╗░░██╗████████╗  ░██████╗██╗░░░██╗░██████╗████████╗███████╗███╗░░░███╗
██╔══██╗██╔══██╗╚██╗░██╔╝████╗░████║██╔════╝████╗░██║╚══██╔══╝  ██╔════╝╚██╗░██╔╝██╔════╝╚══██╔══╝██╔════╝████╗░████║
██████╔╝███████║░╚████╔╝░██╔████╔██║█████╗░░██╔██╗██║░░░██║░░░  ╚█████╗░░╚████╔╝░╚█████╗░░░░██║░░░█████╗░░██╔████╔██║
██╔═══╝░██╔══██║░░╚██╔╝░░██║╚██╔╝██║██╔══╝░░██║╚████║░░░██║░░░  ░╚═══██╗░░╚██╔╝░░░╚═══██╗░░░██║░░░██╔══╝░░██║╚██╔╝██║
██║░░░░░██║░░██║░░░██║░░░██║░╚═╝░██║███████╗██║░╚███║░░░██║░░░  ██████╔╝░░░██║░░░██████╔╝░░░██║░░░███████╗██║░╚═╝░██║
╚═╝░░░░░╚═╝░░╚═╝░░░╚═╝░░░╚═╝░░░░░╚═╝╚══════╝╚═╝░░╚══╝░░░╚═╝░░░  ╚═════╝░░░░╚═╝░░░╚═════╝░░░░╚═╝░░░╚══════╝╚═╝░░░░░╚═╝

░░░░░░  ░██████╗░░█████╗░███╗░░░███╗███████╗███████╗██╗  ░█████╗░███╗░░██╗██████╗░
░░░░░░  ██╔════╝░██╔══██╗████╗░████║██╔════╝██╔════╝██║  ██╔══██╗████╗░██║██╔══██╗
█████╗  ██║░░██╗░███████║██╔████╔██║█████╗░░█████╗░░██║  ███████║██╔██╗██║██║░░██║
╚════╝  ██║░░╚██╗██╔══██║██║╚██╔╝██║██╔══╝░░██╔══╝░░██║  ██╔══██║██║╚████║██║░░██║
░░░░░░  ╚██████╔╝██║░░██║██║░╚═╝░██║███████╗██║░░░░░██║  ██║░░██║██║░╚███║██████╔╝
░░░░░░  ░╚═════╝░╚═╝░░╚═╝╚═╝░░░░░╚═╝╚══════╝╚═╝░░░░░╚═╝  ╚═╝░░╚═╝╚═╝░░╚══╝╚═════╝░

███╗░░░███╗░█████╗░██████╗░███████╗
████╗░████║██╔══██╗██╔══██╗██╔════╝
██╔████╔██║██║░░██║██████╔╝█████╗░░
██║╚██╔╝██║██║░░██║██╔══██╗██╔══╝░░
██║░╚═╝░██║╚█████╔╝██║░░██║███████╗
╚═╝░░░░░╚═╝░╚════╝░╚═╝░░╚═╝╚══════╝







*/