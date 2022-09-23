/**
 *Submitted for verification at testnet.snowtrace.io on 2022-05-23
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

library SafeMathInt {
    int256 private constant MIN_INT256 = int256(1) << 255;
    int256 private constant MAX_INT256 = ~(int256(1) << 255);

    function mul(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a * b;

        require(c != MIN_INT256 || (a & MIN_INT256) != (b & MIN_INT256));
        require((b == 0) || (c / b == a));
        return c;
    }

    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != -1 || a != MIN_INT256);

        return a / b;
    }

    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a));
        return c;
    }

    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a));
        return c;
    }

    function abs(int256 a) internal pure returns (int256) {
        require(a != MIN_INT256);
        return a < 0 ? -a : a;
    }
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

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

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

    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path) external view returns (uint256[] memory amounts);
}

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

interface IJoePair {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

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

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
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

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to) external returns (uint256 amount0, uint256 amount1);

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

interface IJoeFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint256);

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function migrator() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;

    function setMigrator(address) external;
}

contract Ownable {
    address private _owner;

    event OwnershipRenounced(address indexed previousOwner);

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        _owner = msg.sender;
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(isOwner());
        _;
    }

    function isOwner() private view returns (bool) {
        return msg.sender == _owner;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipRenounced(_owner);
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

abstract contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_
    ) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
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
}

contract GourmetAPY is ERC20Detailed, Ownable {

    using SafeMath for uint256;
    using SafeMathInt for int256;

    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;

    mapping(address => uint256) _rBalance;
    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => bool) _isFeeExempt;

    uint256 public liquidityFee;
    uint256 public marketingFee;
    uint256 public totalFee;

    address public marketingWallet;

    bool public launchAddLiquidity = false;
    uint256 public launchTime = 0;
    uint256 public timeDetectBotSeconds = 2;
    uint256 public timeAntiBot = 60 * timeDetectBotSeconds;
    uint256 public _botIncreaseFee = 3;

    mapping(address => bool) _isBot;


    IJoeRouter02 public router;
    address public pair;
    IJoePair public pairContract;

    bool public tradingOpen = false;

    bool public antibot;
    uint256 private initialSupply;
    uint256 private constant MAX_UINT256 = ~uint256(0);
    uint256 private constant MAX_SUPPLY = ~uint128(0);
    uint256 private rSupply;
    uint256 public _totalSupply;
    uint256 private swapThreshold;
    uint256 private rate;
    uint256 private _rebaseRate;
    uint256 public rebase_count = 0;
    uint256 private constant rateDivisor = 10000000;

    bool public swapEnabled = true;
    bool inSwap = false;
    modifier swapping() { inSwap = true; _; inSwap = false; }

    bool public autoRebase;
    uint256 public lastRebasedTime;
    struct ConstructorArgument {
        string  name_;
        string  symbol_;
        uint8 decimals_;
        uint256 initialSupply_;
        uint256 rebaseRate_;
        uint256 liquidityFee_;
        uint256 marketingFee_;
        address marketingWallet_;
        address router_;
        address serviceFeeReceiver_;
        uint256 serviceFee_;
        bool antibotEnabled;
    }
    constructor(
        ConstructorArgument memory infoArg
    ) ERC20Detailed(infoArg.name_, infoArg.symbol_, infoArg.decimals_) Ownable() payable {
        require(infoArg.liquidityFee_ >= 0);
        require(infoArg.marketingFee_ >= 0);
        require(infoArg.liquidityFee_.add(infoArg.marketingFee_) <= 25,
                "Total fees cannot be more than 25%");
        require(infoArg.rebaseRate_ == 1978 ||
        infoArg.rebaseRate_ == 2088||
        infoArg.rebaseRate_ == 2170 ||
        infoArg.rebaseRate_ == 2234||
        infoArg.rebaseRate_ == 2286||
        infoArg.rebaseRate_ == 2330 ||
        infoArg.rebaseRate_ == 2368||
        infoArg.rebaseRate_ == 2401||
        infoArg.rebaseRate_ == 2432||
        infoArg.rebaseRate_ == 2484||
        infoArg.rebaseRate_==2528||
        infoArg.rebaseRate_ == 2566
        , "Rebase rate invalid"
        );
        antibot = infoArg.antibotEnabled;
        router = IJoeRouter02(infoArg.router_); 
        pair = IJoeFactory(router.factory()).createPair(router.WAVAX(),address(this));
        _allowances[address(this)][address(router)] = MAX_UINT256;

        pairContract = IJoePair(pair);

        initialSupply = infoArg.initialSupply_ * (10**infoArg.decimals_);

        rSupply = MAX_UINT256 - (MAX_UINT256 % initialSupply);
        _totalSupply = initialSupply;
        swapThreshold = rSupply / 5000;
        rate = rSupply.div(_totalSupply);
        _rebaseRate = infoArg.rebaseRate_;

        liquidityFee = infoArg.liquidityFee_;
        marketingFee = infoArg.marketingFee_;
        totalFee = infoArg.liquidityFee_.add(infoArg.marketingFee_);

        _isFeeExempt[msg.sender] = true;
        _isFeeExempt[address(this)] = true;

        lastRebasedTime = block.timestamp;
        autoRebase = false;

        marketingWallet = infoArg.marketingWallet_;

        _rBalance[msg.sender] = rSupply;
        payable(infoArg.serviceFeeReceiver_).transfer(infoArg.serviceFee_);
        emit Transfer(address(0x0), msg.sender, _totalSupply);
    }

    event LogRebase(uint256 indexed epoch, uint256 totalSupply);

    function rebase() internal {
        
        if ( inSwap ) return;
        uint256 times = (block.timestamp - lastRebasedTime) / 15 minutes;

        for (uint256 i = 0; i < times; i++) {
            _totalSupply = _totalSupply
                .mul((rateDivisor).add(_rebaseRate))
                .div(rateDivisor);
            rebase_count++;
        }

        if (_totalSupply > MAX_SUPPLY) {
            _totalSupply = MAX_SUPPLY;
        }

        rate = rSupply.div(_totalSupply);
        lastRebasedTime = lastRebasedTime + (times * 15 minutes);

        pairContract.sync();

        emit LogRebase(rebase_count, _totalSupply);
    }

    function transfer(address to, uint256 value)
        external
        override
        returns (bool)
    {
        _transferFrom(msg.sender, to, value);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external override returns (bool) {
        
        if (_allowances[from][msg.sender] != MAX_UINT256) {
            _allowances[from][msg.sender] = _allowances[from][
                msg.sender
            ].sub(value, "Insufficient Allowance");
        }
        _transferFrom(from, to, value);
        return true;
    }

    function _basicTransfer(
        address from,
        address to,
        uint256 amount
    ) internal returns (bool) {
        uint256 rAmount = amount.mul(rate);
        _rBalance[from] = _rBalance[from].sub(rAmount);
        _rBalance[to] = _rBalance[to].add(rAmount);
        return true;
    }

    function openTrading() external onlyOwner {
        tradingOpen = true;
        autoRebase = true;
        lastRebasedTime = block.timestamp;
    }

    function _transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
		require(recipient != address(0), "ERC20: transfer to the zero address");
        if (inSwap) { return _basicTransfer(sender, recipient, amount); }
        if(!_isFeeExempt[sender] && !_isFeeExempt[recipient]){
            require(tradingOpen,"Trading not open yet");
        }
        if(antibot){
            if (recipient == address(pairContract)) {
                if(!launchAddLiquidity && launchTime == 0)  {
                    launchAddLiquidity = true;
                    launchTime = block.timestamp;
                    
                }
            }

            if(launchTime > 0) {
                if(block.timestamp - launchTime <= timeAntiBot && sender == address(pairContract)) {
                    _isBot[recipient] = true;
                }
            }
        }
        
        uint256 rAmount = amount.mul(rate);

        if (shouldRebase()) { rebase(); }

        if (shouldSwapBack()) { swapBack(); }

        _rBalance[sender] = _rBalance[sender].sub(rAmount, "Insufficient Balance");

        uint256 amountReceived = (_isFeeExempt[sender] || _isFeeExempt[recipient]) ? rAmount : takeFee(sender,recipient, rAmount);
        _rBalance[recipient] = _rBalance[recipient].add(amountReceived);


        emit Transfer(sender, recipient, amountReceived.div(rate));
        return true;
    }

    function shouldSwapBack() internal view returns (bool) {
        return msg.sender != pair
        && !inSwap
        && swapEnabled
        && balanceOf(address(this)) >= checkSwapThreshold()
        && (totalFee > 0);
    }

    function swapBack() internal swapping {
        uint256 tokensToSell = balanceOf(address(this));

        uint256 amountToLiquify = tokensToSell.div(totalFee).mul(liquidityFee).div(2);
        uint256 amountToSwap = tokensToSell.sub(amountToLiquify);

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WAVAX();

        uint256 balanceBefore = address(this).balance;

        router.swapExactTokensForAVAXSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amountBNB = address(this).balance.sub(balanceBefore);

        uint256 totalBNBFee = (totalFee.mul(2)).sub(liquidityFee);
        
        uint256 amountBNBLiquidity = amountBNB.mul(liquidityFee).div(totalBNBFee);
        uint256 amountBNBMarketing = amountBNB.mul(marketingFee).mul(2).div(totalBNBFee);

        if(amountBNBMarketing > 0) {
            payable(marketingWallet).transfer(amountBNBMarketing);
        }

        if(amountBNBLiquidity > 0){
            router.addLiquidityAVAX{value: amountBNBLiquidity}(
                address(this),
                amountToLiquify,
                0,
                0,
                DEAD,
                block.timestamp
            );
        }
    } 

     function isBot(address acc) public view returns (bool) {
        return _isBot[acc];
    }

    function setBotSettingTime(uint256 _val) public onlyOwner {
        require(launchTime == 0 && _val <= 5, "Already launched or max 5 minuts.");
        timeDetectBotSeconds = _val;
        timeAntiBot = 60 * _val;
    }
    function excludeAntibot(address ac) public onlyOwner {
        require(_isBot[ac], "not bot");
        _isBot[ac] = false;
    }    
    
    function setBotFeeMultiplicator(uint256 _val) public onlyOwner {
        require(_val <= 3 && launchTime == 0, "max x3 and not launched");
        _botIncreaseFee = _val;
    } 
   
    function takeFee(address sender, address receiver, uint256 rAmount) internal returns (uint256) {
       
       uint256 feeAmount;
        if(_isBot[sender] || _isBot[receiver]) {
            feeAmount = rAmount.div(100).mul(totalFee * _botIncreaseFee);
        } else {
            feeAmount = rAmount.div(100).mul(totalFee);
        }
        _rBalance[address(this)] = _rBalance[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount.div(rate));

        return rAmount.sub(feeAmount);
    }

    function _swapTokensForBNB(uint256 tokenAmount) private {
		address[] memory path = new address[](2);
		path[0] = address(this);
		path[1] = router.WAVAX();

		router.swapExactTokensForAVAXSupportingFeeOnTransferTokens(
			tokenAmount,
			0, // accept any amount of ETH
			path,
			address(this),
			block.timestamp
		);
	}

	function _addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
		router.addLiquidityAVAX{value: ethAmount}(
			address(this),
			tokenAmount,
			0, // slippage is unavoidable
			0, // slippage is unavoidable
			DEAD,
			block.timestamp
		);
	}

    function shouldRebase() internal view returns (bool) {
        return
            autoRebase &&
            (_totalSupply < MAX_SUPPLY) &&
            msg.sender != pair  &&
            !inSwap &&
            block.timestamp >= (lastRebasedTime + 15 minutes);
    }

    function setAutoRebase(bool enable) external onlyOwner {
         autoRebase = enable;
    
    }

    function setMarketingFee(uint256 newMarketingFee) public onlyOwner{
        require(newMarketingFee != marketingFee, "Marketing fee is already set to given value");
        require(newMarketingFee.add(liquidityFee) <= 25, "Total fees cannot be more than 25%");
        marketingFee = newMarketingFee;
        totalFee = newMarketingFee.add(liquidityFee);
    }

    function setLiquidityFee(uint256 newLiquidityFee) public onlyOwner{
        require(newLiquidityFee != liquidityFee, "Liquidity fee is already set to given value");
        require(newLiquidityFee.add(marketingFee) <= 25, "Total fees cannot be more than 25%");
        liquidityFee = newLiquidityFee;
        totalFee = newLiquidityFee.add(marketingFee);
    }

    function allowance(address owner_, address spender)
        external
        view
        override
        returns (uint256)
    {
        return _allowances[owner_][spender];
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        external
        returns (bool)
    {
        uint256 oldValue = _allowances[msg.sender][spender];
        if (subtractedValue >= oldValue) {
            _allowances[msg.sender][spender] = 0;
        } else {
            _allowances[msg.sender][spender] = oldValue.sub(
                subtractedValue
            );
        }
        emit Approval(
            msg.sender,
            spender,
            _allowances[msg.sender][spender]
        );
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        external
        returns (bool)
    {
        _allowances[msg.sender][spender] = _allowances[msg.sender][
            spender
        ].add(addedValue);
        emit Approval(
            msg.sender,
            spender,
            _allowances[msg.sender][spender]
        );
        return true;
    }

    function approve(address spender, uint256 value)
        external
        override
        returns (bool)
    {
        _allowances[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function checkFeeExempt(address _addr) external view returns (bool) {
        return _isFeeExempt[_addr];
    }

    function manualSync() external {
        IJoePair(pair).sync();
    }

    function setMarketingWallet(address newWallet) external onlyOwner() {
        marketingWallet = newWallet;
    }

    function setSwapBackSettings(bool _enabled, uint256 _percentage_base100000) external onlyOwner {
        require(_percentage_base100000 >= 1, "Percentage must be more than 0.001%");
        swapEnabled = _enabled;
        swapThreshold = rSupply.div(100000).mul(_percentage_base100000);
    }

    function checkSwapThreshold() public view returns (uint256) {
        return swapThreshold.div(rate);
    }

    function setLP(address _address) external onlyOwner {
        pairContract = IJoePair(_address);
    }
    
    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }
   
    function balanceOf(address account) public view override returns (uint256) {
        return _rBalance[account].div(rate);
    }

    function claimStuckTokens(address token) external onlyOwner {
        require(token != address(this), "Owner cannot claim native tokens");
        if (token == address(0x0)) {
            payable(msg.sender).transfer(address(this).balance);
            return;
        }
        IERC20 ERC20token = IERC20(token);
        uint256 balance = ERC20token.balanceOf(address(this));
        ERC20token.transfer(msg.sender, balance);
    }

    receive() external payable {}
}