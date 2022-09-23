/**
 *Submitted for verification at snowtrace.io on 2022-02-05
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

/**
 * BEP20 standard interface
 */

interface BEP20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * Basic access control mechanism
 */

abstract contract Ownable {
    address internal owner;
    address private _previousOwner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor(address _owner) {
        owner = _owner;
    }

    modifier onlyOwner() {
        require(isOwner(msg.sender), "!You are not the Owner"); _;
    }

    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

/**
 * Router Interfaces
 */

interface IDEXFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
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

    function addLiquidityAVAX(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountAVAXMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountAVAX, uint liquidity);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function swapExactAVAXForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;

    function swapExactTokensForAVAXSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

/**
 * Contract Code
 */

contract LonelyInu is BEP20, Ownable {

    // Events
    event AutoLiquify(uint256 amountBNB, uint256 amountTokens);
    event SetMaxWallet(uint256 maxWalletToken);
    event SetFees(uint256 liquidityFee, uint256 marketingFee, uint256 buybackFee, uint256 totalFee);
    event SetSwapBackSettings(bool enabled, uint256 swapThreshold);
    event SetTargetLiquidity(uint256 PercentageLiquidity);
    event SetIsFeeExempt(address holder, bool enabled);
    event SetIsTxLimitExempt(address holder, bool enabled);
    event SetFeeReceivers(address marketingReceiver, address buybackFeeReceiver);
    event StuckBalanceSent(uint256 amountBNB, address recipient);
    event ForeignTokenTransfer(address tokenAddress, uint256 quantity);

    // Mappings
    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;
    mapping (address => bool) isFeeExempt;
    mapping (address => bool) isTxLimitExempt;

    // Basic Contract Info
    string constant _name = "Lonely Inu";
    string constant _symbol = "LONELY";
    uint8 constant _decimals = 9;

    // Supply
    uint256 constant _totalSupply = 10000000 * (10 ** _decimals); // 10,000,000 Tokens

    // Max wallet
    uint256 public _maxWalletSize = (_totalSupply * 3) / 100;  // 3% MaxWallet

    // Detailed Fees
    uint256 buyMarketingFee = 3;
    uint256 buyBuyBackFee = 3;
    uint256 buyLpFee = 2;
    uint256 buyTotalFee = buyMarketingFee+buyBuyBackFee+buyLpFee;

    uint256 sellMarketingFee = 8;
    uint256 sellBuyBackFee = 6;
    uint256 sellLpFee = 2;
    uint256 sellTotalFee = sellMarketingFee+sellBuyBackFee+sellLpFee;

    uint256 actualFee;
    
    // Fee receivers
    address private marketingFeeReceiver = 0x5bF717d3d03EE406ff1dc5d31C1657F895864753;
    address private buybackFeeReceiver = 0xF9F66989Af777dd5954fF2f15eed59b5917A7F08;
    address constant private devWallet = 0xd84a43535285918A9F931b8D599119844bb74Ea9;
    address constant private DEAD = 0x000000000000000000000000000000000000dEaD;

    // Dynamic Liquidity Fee
    uint256 targetLiquidity = 20;

    // Router
    IDEXRouter public router;
    address public pair;
    
    uint256 public launchedAt;

    bool public swapEnabled = true;
    uint256 public swapThreshold = _totalSupply / 10000 * 5; // 0.05% 

    bool inSwap;
    modifier swapping() { inSwap = true; _; inSwap = false; }

    constructor () Ownable(msg.sender) {
        router = IDEXRouter(0x60aE616a2155Ee3d9A68541Ba4544862310933d4);
        pair = IDEXFactory(router.factory()).createPair(address(this), router.WAVAX());
        _allowances[address(this)][address(router)] = type(uint256).max;
        
        address _owner = owner;
        
        isFeeExempt[_owner] = true;
        isFeeExempt[marketingFeeReceiver] = true;
        isFeeExempt[buybackFeeReceiver] = true;

        isTxLimitExempt[_owner] = true;
        isTxLimitExempt[marketingFeeReceiver] = true;
        isTxLimitExempt[buybackFeeReceiver] = true;

        _balances[_owner] = _totalSupply;
        emit Transfer(address(0), _owner, _totalSupply);
    }

    receive() external payable { }

    // Basic Internal Functions

    function totalSupply() external pure override returns (uint256) { return _totalSupply; }
    function decimals() external pure override returns (uint8) { return _decimals; }
    function symbol() external pure override returns (string memory) { return _symbol; }
    function name() external pure override returns (string memory) { return _name; }
    function getOwner() external view override returns (address) { return owner; }
    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function approveMax(address spender) external returns (bool) {
        return approve(spender, type(uint256).max);
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if(_allowances[sender][msg.sender] != type(uint256).max){
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender] - (amount);
        }

        return _transferFrom(sender, recipient, amount);
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        if(inSwap){ return _basicTransfer(sender, recipient, amount); }
        
        // Checks max transaction limit
        if (sender != owner &&
            recipient != owner &&
            recipient != pair) {
            require(isTxLimitExempt[recipient] || isTxLimitExempt[sender] || _balances[recipient] + amount <= _maxWalletSize, "Transfer amount exceeds the MaxWallet size.");
        }
        
        //Exchange tokens
        if(shouldSwapBack()){ swapBack(); }

        if(!launched() && recipient == pair){ require(_balances[sender] > 0); launch(); }

        _balances[sender] = _balances[sender] - amount;

        //Check if should Take Fee
        uint256 amountReceived = (!shouldTakeFee(sender) || !shouldTakeFee(recipient)) ? amount : takeFee(sender, amount);
        _balances[recipient] = _balances[recipient] + (amountReceived);

        emit Transfer(sender, recipient, amountReceived);
        return true;
    }
    
    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender] - amount;
        _balances[recipient] = _balances[recipient] + amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    // Internal Functions

    function shouldTakeFee(address sender) internal view returns (bool) {
        return !isFeeExempt[sender];
    }

    function takeFee(address sender, uint256 amount) internal returns (uint256) {
        if(sender == pair){
            actualFee = buyTotalFee+2;
        }else {actualFee = sellTotalFee+2;}
        uint256 feeAmount = amount / 100 * actualFee ;

        _balances[address(this)] = _balances[address(this)] + (feeAmount);
        emit Transfer(sender, address(this), feeAmount);

        return amount - (feeAmount);
    }

    function shouldSwapBack() internal view returns (bool) {
        return msg.sender != pair
        && !inSwap
        && swapEnabled
        && _balances[address(this)] >= swapThreshold;
    }

    function swapBack() internal swapping {       
        uint256 contractTokenBalance = balanceOf(address(this));
        uint256 dynamicLiquidityFee = isOverLiquified(targetLiquidity, 100) ? 0 : sellLpFee;
        uint256 totalFee = buyTotalFee+sellTotalFee;
        uint256 amountToLiquify = contractTokenBalance * dynamicLiquidityFee / totalFee / (2);
        uint256 amountToSwap = contractTokenBalance - amountToLiquify;

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WAVAX();

        router.swapExactTokensForAVAXSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );
        uint256 marketingFee = buyMarketingFee+sellMarketingFee;
        uint256 buybackFee = buyBuyBackFee+sellBuyBackFee;
        uint256 amountBNB = address(this).balance;
        uint256 totalBNBFee = totalFee - (dynamicLiquidityFee / (2));
        uint256 amountBNBLiquidity = amountBNB * dynamicLiquidityFee / totalBNBFee / (2);
        uint256 amountBNBMarketing = amountBNB * marketingFee / totalBNBFee;
        uint256 amountBNBbuyback = amountBNB * buybackFee / totalBNBFee;
        uint256 amountBNBDev = amountBNB - amountBNBLiquidity - amountBNBMarketing - amountBNBbuyback;

        payable(marketingFeeReceiver).call{value: amountBNBMarketing, gas: 30000};
        payable(buybackFeeReceiver).call{value: amountBNBbuyback, gas: 30000};
        payable(devWallet).call{value: amountBNBDev, gas: 30000};
        
        if(amountToLiquify > 0){
            router.addLiquidityAVAX{value: amountBNBLiquidity}(
                address(this),
                amountToLiquify,
                0,
                0,
                marketingFeeReceiver,
                block.timestamp
            );
            emit AutoLiquify(amountBNBLiquidity, amountToLiquify);
        }
    }

    function launched() internal view returns (bool) {
        return launchedAt != 0;
    }

    function launch() internal {
        launchedAt = block.timestamp;
    }

    function getLiquidityBacking(uint256 accuracy) public view returns (uint256) {
        return accuracy * (balanceOf(pair) * (2)) / (_totalSupply);
    }

    function isOverLiquified(uint256 target, uint256 accuracy) public view returns (bool) {
        return getLiquidityBacking(accuracy) > target;
    }

    // External Functions

    function setMaxWallet(uint256 percentageBase100) external onlyOwner {
        uint256 percentage = _totalSupply * percentageBase100 / 100;
        require(percentage >= _totalSupply / 100, "Can't set MaxWallet below 1%" );
        _maxWalletSize = percentage;
        emit SetMaxWallet(_maxWalletSize);
    }

    function setTargetLiquidity(uint256 _target) external onlyOwner {
        targetLiquidity = _target;
        emit SetTargetLiquidity(_target);
    }    

    function setIsFeeExempt(address holder, bool exempt) external onlyOwner {
        isFeeExempt[holder] = exempt;
        emit SetIsFeeExempt(holder, exempt);
    }

    function setIsTxLimitExempt(address holder, bool exempt) external onlyOwner {
        isTxLimitExempt[holder] = exempt;
        emit SetIsTxLimitExempt(holder, exempt);
    }

    function setFees(uint256 _liquidityFee, uint256 _buyMarketingFee, uint256 _buyBuybackFee, uint56 _sellMarketingFee, uint256 _sellBuybackFee) external onlyOwner {
        sellLpFee = _liquidityFee;
        sellMarketingFee = _sellMarketingFee;
        sellBuyBackFee = _sellBuybackFee;
        sellTotalFee = _sellMarketingFee + _sellBuybackFee + _liquidityFee + 2;
        buyMarketingFee = _buyMarketingFee;
        buyBuyBackFee = _buyBuybackFee;
        buyTotalFee = _buyMarketingFee + _buyBuybackFee + _liquidityFee + 2;
    }

    function setFeeReceiver(address _marketingFeeReceiver, address _buybackFeeReceiver) external onlyOwner {
        marketingFeeReceiver = _marketingFeeReceiver;
        buybackFeeReceiver = _buybackFeeReceiver;
        emit SetFeeReceivers(marketingFeeReceiver, buybackFeeReceiver);
    }

    function setSwapBackSettings(bool _enabled, uint256 _amount) external onlyOwner {
        require(_amount > 0, "Can't set SwapThreshold to ZERO");
        swapEnabled = _enabled;
        swapThreshold = _amount*10**_decimals;
        emit SetSwapBackSettings(swapEnabled, swapThreshold);
    }

    // Stuck Balance Function

    function ClearStuckBalance() external onlyOwner {
        uint256 contractAVAXBalance = address(this).balance;
        payable(marketingFeeReceiver).transfer(contractAVAXBalance);
        emit StuckBalanceSent(contractAVAXBalance, marketingFeeReceiver);
    }

    function transferForeignToken(address _token) public onlyOwner {
        uint256 _contractBalance = BEP20(_token).balanceOf(address(this));
        payable(marketingFeeReceiver).transfer(_contractBalance);
        emit ForeignTokenTransfer(_token, _contractBalance);
    }
}