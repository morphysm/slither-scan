/**
 *Submitted for verification at snowtrace.io on 2022-03-08
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

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

abstract contract Ownable {
    address internal owner;
    address private _previousOwner;
    
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor(address _owner) {
        owner = _owner;
    }

    modifier onlyOwner() {
        require(isOwner(msg.sender), "!OWNER"); _;
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


contract TokenContract is BEP20, Ownable {

    address constant private DEAD = 0x000000000000000000000000000000000000dEaD;

    string constant _name = "Test";
    string constant _symbol = "TEST";
    string constant ContractCreator = "@FrankFourier";
    uint8 constant _decimals = 9;

    uint256 _totalSupply =  100 * 10**6 * 10**_decimals;

    uint256 public _maxTxAmount = _totalSupply / 100;
    uint256 public _maxWalletToken = _totalSupply / 50;

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;

    bool public AntisniperMode = true;
    mapping (address => bool) public isSniper;

    mapping (address => bool) isFeeExempt;
    mapping (address => bool) isTxLimitExempt;
    mapping (address => bool) isMaxWalletExempt;

    uint256 liquidityFee = 3;
    uint256 marketingFee = 5;
    uint256 devFee = 4;
    uint256 totalFee = 12;
    uint256 public feeDenominator   = 100;

    uint256 public sellMultiplier = 200;
    uint256 public buyMultiplier = 100;
    uint256 public transferMultiplier = 100;


    uint256 public deadBlocks = 4;
    uint256 public launchedAt = 0;
    address private marketingFeeReceiver = 0x84b4030578A3Ba7A0a28deD695b643A86e9C9e5f;
    address private devFeeReceiver = 0x838103C6FEd2E9Da6aD11160a16a9A33DFAA331d;

    uint256 targetLiquidity = 100;
    uint256 targetLiquidityDenominator = 100;

    IDEXRouter public router;
    address public pair;

    bool public tradingOpen = false;
    bool public antibot = true;
    bool public gasLimitActive = false;
    uint256 public gasPriceLimit = 75;

    bool public swapEnabled = true;
    uint256 public swapThreshold = _totalSupply / 1000;
    uint256 public swapTransactionThreshold = _totalSupply * 5 / 10000;
    bool inSwap;
    modifier swapping() { inSwap = true; _; inSwap = false; }

    constructor () Ownable(msg.sender) {
        router = IDEXRouter(0x60aE616a2155Ee3d9A68541Ba4544862310933d4);
        pair = IDEXFactory(router.factory()).createPair(address(this), router.WAVAX());
        _allowances[address(this)][address(router)] = type(uint256).max;
        
        isFeeExempt[owner] = true;

        isTxLimitExempt[msg.sender] = true;
        isTxLimitExempt[DEAD] = true;

        isMaxWalletExempt[msg.sender] = true;
        isMaxWalletExempt[address(this)] = true;
        isMaxWalletExempt[DEAD] = true;

        _balances[owner] = _totalSupply;
        emit Transfer(address(0), owner, _totalSupply);
    }

    receive() external payable { }

    function totalSupply() external view override returns (uint256) { return _totalSupply; }
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

    function mint(address account, uint256 amount) external onlyOwner {
        require(account != address(0), "BEP20: mint to the zero address");

        _totalSupply = _totalSupply + (amount);
        _balances[account] = _balances[account] + (amount);
        emit Transfer(address(0), account, amount);
    }

    function burn(address account, uint256 amount) external onlyOwner {
        require(account != address(0), 'BEP20: burn from the zero address');

        _balances[account] = _balances[account] - amount;
        _totalSupply = _totalSupply - (amount);
        emit Transfer(account, address(0), amount);
    }

    function setMaxWallet(uint256 amount) external onlyOwner {
        _maxWalletToken = amount;
    }

    function setMaxTx(uint256 amount) external onlyOwner {
        _maxTxAmount = amount;
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        if(inSwap){ return _basicTransfer(sender, recipient, amount); }

        if(sender != owner && recipient != owner){
            require(tradingOpen,"Trading not open yet");
            
            if(gasLimitActive) {
                require(tx.gasprice <= gasPriceLimit,"Gas price exceeds limit");
            }

            // Blacklist sniper
            if(AntisniperMode){
                require(!isSniper[sender] && !isSniper[recipient],"Blacklisted");    
            }
        }

        if (sender != owner && recipient != owner  && recipient != address(this) && sender != address(this) && recipient != address(DEAD) ){
            require(amount <= _maxTxAmount || isTxLimitExempt[sender],"TX Limit Exceeded");
            if(recipient != pair)
            require((amount + balanceOf(recipient)) <= _maxWalletToken || isMaxWalletExempt[recipient],"Max wallet holding reached");
        }

        // Swap
        if(sender != pair
            && !inSwap
            && swapEnabled
            && amount > swapTransactionThreshold
            && _balances[address(this)] >= swapThreshold) {
            swapBack();
        }

        // Actual transfer
        _balances[sender] = _balances[sender] - amount;
        
        uint256 amountReceived = (isFeeExempt[sender] || isFeeExempt[recipient]) ? amount : takeFee(sender, amount, recipient);
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

    function takeFee(address sender, uint256 amount, address recipient) internal returns (uint256) {

        uint256 multiplier = transferMultiplier;
        if(recipient == pair){
            multiplier = sellMultiplier;
        } else if(sender == pair){
            multiplier = buyMultiplier;
        }

        uint256 feeAmount = amount * (totalFee) * (multiplier) / (feeDenominator * 100);


        if(sender == pair && (launchedAt + deadBlocks) > block.number){
            feeAmount = amount/ (100) * (99);
        }

        _balances[address(this)] = _balances[address(this)] + (feeAmount);
        emit Transfer(sender, address(this), feeAmount);
        return amount - (feeAmount);}

    function clearStuckBalance(uint256 amountPercentage) external onlyOwner {
        uint256 amountBNB = address(this).balance;
        payable(msg.sender).transfer(amountBNB * amountPercentage / 100);
    }

    function set_sell_multiplier(uint256 Multiplier) external onlyOwner {
        sellMultiplier = Multiplier;        
    }

    // switch Trading
    function tradingStatus() public onlyOwner {
        tradingOpen = true;
        launchedAt = block.number;
    }

    function swapBack() internal swapping {       
        uint256 contractTokenBalance = balanceOf(address(this));
        uint256 dynamicLiquidityFee = isOverLiquified(targetLiquidity, 100) ? 0 : liquidityFee;
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
        uint256 amountBNB = address(this).balance;
        uint256 totalBNBFee = totalFee - (dynamicLiquidityFee / (2));
        uint256 amountBNBLiquidity = amountBNB * dynamicLiquidityFee / totalBNBFee / (2);
        uint256 amountBNBMarketing = amountBNB * marketingFee / totalBNBFee;
        uint256 amountBNBdev = amountBNB - amountBNBLiquidity - amountBNBMarketing;

        (bool MarketingSuccess, /* bytes memory data */) = payable(marketingFeeReceiver).call{value: amountBNBMarketing, gas: 30000}("");
        require(MarketingSuccess, "receiver rejected BNB transfer");
        (bool devSuccess, /* bytes memory data */) = payable(devFeeReceiver).call{value: amountBNBdev, gas: 30000}("");
        require(devSuccess, "receiver rejected BNB transfer");

        if(amountToLiquify > 0){
            router.addLiquidityAVAX{value: amountBNBLiquidity}(
                address(this),
                amountToLiquify,
                0,
                0,
                marketingFeeReceiver,
                block.timestamp
            );
        }
    }

    function _swapTokensForFees(uint256 amount) external onlyOwner{
        uint256 contractTokenBalance = balanceOf(address(this));
        require(amount <= swapThreshold);
        require(contractTokenBalance >= amount);
        swapBack();
    }

    function setMultipliers(uint256 _buy, uint256 _sell, uint256 _trans) external onlyOwner {
        sellMultiplier = _sell;
        buyMultiplier = _buy;
        transferMultiplier = _trans;
    }

    function enable_AntisniperMode(bool _status) public onlyOwner {
        AntisniperMode = _status;
    }

    function manage_snipers(address[] calldata addresses, bool status) public onlyOwner {
        require(addresses.length < 501,"GAS Error: max limit is 500 addresses");
        for (uint256 i; i < addresses.length; ++i) {
            isSniper[addresses[i]] = status;
        }
    }

    function setGasPriceLimit(uint256 gas) external onlyOwner {
        require(gas >= 75);
        gasPriceLimit = gas * 1 gwei;
    }

    function setgasLimitActive(bool antiGas) external onlyOwner {
        gasLimitActive = antiGas;
    }

    function setIsFeeExempt(address holder, bool exempt) external onlyOwner {
        isFeeExempt[holder] = exempt;
    }

    function setIsTxLimitExempt(address holder, bool exempt) external onlyOwner {
        isTxLimitExempt[holder] = exempt;
    }

    function setIsMaxwalletExempt(address holder, bool exempt) external onlyOwner {
        isMaxWalletExempt[holder] = exempt;
    }

    function setFees(uint256 _liquidityFee, uint256 _marketingFee, uint256 _devFee, uint256 _feeDenominator) external onlyOwner {
        require(_liquidityFee + _marketingFee + _devFee < 33, "Total fees must be below 33%");
        liquidityFee = _liquidityFee;
        marketingFee = _marketingFee;
        devFee = _devFee;
        totalFee = _liquidityFee + _marketingFee + _devFee;
        feeDenominator = _feeDenominator;
        require(totalFee < feeDenominator/2, "Fees cannot be more than 50%");
    }

    function setFeeReceivers( address _marketingFeeReceiver, address _devFeeReceiver) external onlyOwner {
        marketingFeeReceiver = _marketingFeeReceiver;
        devFeeReceiver = _devFeeReceiver;
    }

    function setSwapBackSettings(bool _enabled, uint256 _amount, uint256 _transaction) external onlyOwner {
        swapEnabled = _enabled;
        swapThreshold = _amount;
        swapTransactionThreshold = _transaction;
    }

    function isExcludedFromFee(address account) public view returns(bool) {
        return isFeeExempt[account];
    }

    function isExcludedFromTxLimit(address account) public view returns(bool) {
        return isTxLimitExempt[account];
    }

    function isExcludedFromMaxWallet(address account) public view returns(bool) {
        return isMaxWalletExempt[account];
    }

    function rescueToken(address token, address to) external onlyOwner {
        require(address(this) != token);
        BEP20(token).transfer(to, BEP20(token).balanceOf(address(this))); 
    }

    function setTargetLiquidity(uint256 _target, uint256 _denominator) external onlyOwner {
        targetLiquidity = _target;
        targetLiquidityDenominator = _denominator;
    }
    
    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply - (balanceOf(DEAD));
    }

    function getLiquidityBacking(uint256 accuracy) public view returns (uint256) {
        return accuracy * (balanceOf(pair) * (2)) / (getCirculatingSupply());
    }

    function isOverLiquified(uint256 target, uint256 accuracy) public view returns (bool) {
        return getLiquidityBacking(accuracy) > target;
    }
}