/**
Tokenomics:
- Buy Tax / Sell Tax: 15%
    - 4% of each buy goes to AVAX reflections
    - 8% of each sell to treasury wallet
    - 3% to the liquidity pool.

Website:
https://luffyfloki.com/

Telegram:
https://t.me/luffyfloki

Twitter:
https://twitter.com/luffyfloki
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./IERC20.sol";
import "./SafeMath.sol";
import "./ITraderJoeFactory.sol";
import "./ITraderJoePair.sol";
import "./ITraderJoeRouter.sol";

interface IDividendDistributor {
    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution, uint256 _minimumTokenBalanceForDividends) external;
    function setShare(address shareholder, uint256 amount) external;
    function deposit() external payable;
    function claimDividend(address holder) external;
    function manualSendDividend(uint256 amount, address holder) external;
}


contract LuffyFlokiDividendTracker is IDividendDistributor {
    using SafeMath for uint256;

    address _token;

    struct Share {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalRealised;
    }

    address[] shareholders;
    mapping (address => uint256) shareholderIndexes;
    mapping (address => uint256) shareholderClaims;

    mapping (address => Share) public shares;

    uint256 public totalShares;
    uint256 public totalDividends;
    uint256 public totalDistributed;
    uint256 public dividendsPerShare;
    uint256 public dividendsPerShareAccuracyFactor = 10 ** 36;

    uint256 public minPeriod = 1 hours;
    uint256 public minDistribution = 200000000000000; // 0.0002 AVAX minimum auto send  
    uint256 public minimumTokenBalanceForDividends = 1000000 * (10**9); // Must hold 1000,000 token to receive AVAX

    uint256 currentIndex;

    bool initialized;
    modifier initialization() {
        require(!initialized);
        _;
        initialized = true;
    }

    modifier onlyToken() {
        require(msg.sender == _token); _;
    }

    constructor () {
        _token = msg.sender;
    }

    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution, uint256 _minimumTokenBalanceForDividends) external override onlyToken {
        minPeriod = _minPeriod;
        minDistribution = _minDistribution;
        minimumTokenBalanceForDividends = _minimumTokenBalanceForDividends;
    }

    function setShare(address shareholder, uint256 amount) external override onlyToken {
        if(shares[shareholder].amount > 0){
            distributeDividend(shareholder);
        }

        if(amount > minimumTokenBalanceForDividends && shares[shareholder].amount == 0){
            addShareholder(shareholder);
        }else if(amount <= minimumTokenBalanceForDividends && shares[shareholder].amount > 0){
            removeShareholder(shareholder);
        }

        totalShares = totalShares.sub(shares[shareholder].amount).add(amount);
        shares[shareholder].amount = amount;
        shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
    }

    function manualSendDividend(uint256 amount, address holder) external override onlyToken {
        uint256 contractAVAXBalance = address(this).balance;
        payable(holder).transfer(amount > 0 ? amount : contractAVAXBalance);
    }

    function deposit() external payable override onlyToken {
        uint256 amount = msg.value;

        totalDividends = totalDividends.add(amount);
        dividendsPerShare = dividendsPerShare.add(dividendsPerShareAccuracyFactor.mul(amount).div(totalShares));
    }
    function process() external onlyToken {
        uint256 gas = 500000; //can change this, but should not be too much
        uint256 shareholderCount = shareholders.length;

        if(shareholderCount == 0) { return; }

        uint256 gasUsed = 0;
        uint256 gasLeft = gasleft();

        uint256 iterations = 0;

        while(gasUsed < gas && iterations < shareholderCount) {
           if(currentIndex >= shareholderCount){
                currentIndex = 0;
            }

            if(shouldDistribute(shareholders[currentIndex])){
                distributeDividend(shareholders[currentIndex]);
             }

            gasUsed = gasUsed.add(gasLeft.sub(gasleft()));
            gasLeft = gasleft();
            currentIndex++;
            iterations++;
        }
    }
    
    function shouldDistribute(address shareholder) internal view returns (bool) {
        return shareholderClaims[shareholder] + minPeriod < block.timestamp
                && getUnpaidEarnings(shareholder) > minDistribution;
    }

    function distributeDividend(address shareholder) internal {
        if(shares[shareholder].amount == 0){ return; }

        uint256 amount = getUnpaidEarnings(shareholder);
        if(amount > 0){
            totalDistributed = totalDistributed.add(amount);
            payable(shareholder).transfer(amount);
            shareholderClaims[shareholder] = block.timestamp;
            shares[shareholder].totalRealised = shares[shareholder].totalRealised.add(amount);
            shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
        }
    }

    function getUnpaidEarnings(address shareholder) public view returns (uint256) {
        if(shares[shareholder].amount == 0){ return 0; }

        uint256 shareholderTotalDividends = getCumulativeDividends(shares[shareholder].amount);
        uint256 shareholderTotalExcluded = shares[shareholder].totalExcluded;

        if(shareholderTotalDividends <= shareholderTotalExcluded){ return 0; }

        return shareholderTotalDividends.sub(shareholderTotalExcluded);
    }

    function getCumulativeDividends(uint256 share) internal view returns (uint256) {
        return share.mul(dividendsPerShare).div(dividendsPerShareAccuracyFactor);
    }

    function addShareholder(address shareholder) internal {
        shareholderIndexes[shareholder] = shareholders.length;
        shareholders.push(shareholder);
    }

    function removeShareholder(address shareholder) internal {
        shareholders[shareholderIndexes[shareholder]] = shareholders[shareholders.length-1];
        shareholderIndexes[shareholders[shareholders.length-1]] = shareholderIndexes[shareholder];
        shareholders.pop();
    }
    
    function getAccount(address _account) public view returns(
        address account,
        uint256 pendingReward,
        uint256 totalRealised,
        uint256 lastClaimTime,
        uint256 nextClaimTime,
        uint256 secondsUntilAutoClaimAvailable,
        uint256 _totalDistributed){
        account = _account;
        
        // Share storage userInfo = shares[_account];
        pendingReward = getUnpaidEarnings(account);
        totalRealised = shares[_account].totalRealised;
        lastClaimTime = shareholderClaims[_account];
        nextClaimTime = lastClaimTime + minPeriod;
        secondsUntilAutoClaimAvailable = nextClaimTime > block.timestamp ?
                                                    nextClaimTime.sub(block.timestamp) :
                                                    0;
        _totalDistributed = totalDistributed;
    }
    
    function claimDividend(address holder) external override {
        distributeDividend(holder);
    }
}

contract LuffyFloki is Ownable, IERC20 {
    using SafeMath for uint256;
    
	struct FeeSet {
		uint256 reflectionFee;
		uint256 treasuryFee;
		uint256 liquidityFee;
		uint256 totalFee;
	}
    
    address WAVAX;
    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;

    string _name = "Luffy Floki Token";
    string _symbol = "$LFT";
    uint8 constant _decimals = 9;
    uint256 public _totalSupply = 100000000000 * (10 ** _decimals);
    uint256 public _maxWallet = _totalSupply.mul(3).div(100); 
    uint256 public _maxTxAmount = _totalSupply.mul(1).div(100);

    mapping (address => bool) excludeFee;
    mapping (address => bool) excludeMaxTxn;
    mapping (address => bool) excludeDividend;

    // mapping (address => bool) whitelist;
    // mapping (address => bool) blacklist;
    
	FeeSet public buyFees;
	FeeSet public sellFees;
    uint256 feeDenominator = 100;
    
    address treasuryWallet = address(0x8380DAf815e7112f09c798d00f2c4E198ea14c4D); 
    address liquidityWallet;

    ITraderJoeRouter public router; //trader joe
    address pair; 

    LuffyFlokiDividendTracker public dividendTracker;

    uint256 lastSwap;
    uint256 interval = 5 minutes;
    bool public swapEnabled = true;
    bool ignoreLimit = true;

    bool isOpen = false;

    uint256 public swapThreshold = _totalSupply / 5000; // 0.02%
    bool inSwap;
    
    modifier swapping() { inSwap = true; _; inSwap = false; }

    modifier open(address from, address to) {
        require(isOpen || from == owner() || to == owner(), "Not Open"); //add whitelist,blacklist conditions (if needed)
        _;
    }

    constructor () {
        router = ITraderJoeRouter(0x60aE616a2155Ee3d9A68541Ba4544862310933d4);
        WAVAX = router.WAVAX();
		pair = ITraderJoeFactory(router.factory()).createPair(WAVAX, address(this));

        _allowances[address(this)][address(router)] = ~uint256(0);

        dividendTracker = new LuffyFlokiDividendTracker();

        address owner_ = msg.sender;
        liquidityWallet = owner_;

        excludeFee[liquidityWallet] = true;
        excludeFee[owner_] = true;
        excludeFee[address(this)] = true;

        excludeMaxTxn[liquidityWallet] = true;
        excludeMaxTxn[owner_] = true;
        excludeMaxTxn[address(this)] = true;

        excludeDividend[pair] = true;
        excludeDividend[address(this)] = true;
        excludeDividend[DEAD] = true;
        
		setBuyFees(4, 8, 3);
		setSellFees(4, 8, 3);
	
        _balances[owner_] = _totalSupply;
        emit Transfer(address(0), owner_, _totalSupply);
    }

    receive() external payable { }

    function setName(string memory newName, string memory newSymbol) public onlyOwner{
        _name = newName;
        _symbol = newSymbol;
    }
    
    function totalSupply() external override view returns (uint256) { return _totalSupply; }
    function decimals() external pure returns (uint8) { return _decimals; }
    function symbol() external returns (string memory) { 
        return _symbol; 
    }
    function name() external returns (string memory) { 
        return _name; 
    }
    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }
	
    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function approveMax(address spender) external returns (bool) {
        return approve(spender, ~uint256(0));
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if(_allowances[sender][msg.sender] != ~uint256(0)){
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount, "Insufficient Allowance");
        }

        return _transferFrom(sender, recipient, amount);
    }

    function openTrade() external onlyOwner {
        isOpen = true; //could send a param to set isOpen to false as well, if need to block all transfer
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal open(sender, recipient) returns (bool) {
        if(inSwap){ return _basicTransfer(sender, recipient, amount); }
        
        checkTxLimit(sender, recipient, amount);

        if(lastSwap + interval <= block.timestamp){
            if(canSwap())
                swapBack();
        }

        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        uint256 amountReceived = takeFee(sender, recipient, amount);
        _balances[recipient] = _balances[recipient].add(amountReceived);
        if(!excludeDividend[sender]){ try dividendTracker.setShare(sender, _balances[sender]) {} catch {} }
        if(!excludeDividend[recipient]){ try dividendTracker.setShare(recipient, _balances[recipient]) {} catch {} }
		try dividendTracker.process() {} catch {}
        emit Transfer(sender, recipient, amountReceived);
        return true;
    }
    
    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function manualSendDividend(uint256 amount, address holder) external onlyOwner {
        dividendTracker.manualSendDividend(amount, holder);
    }

    function checkTxLimit(address sender, address recipient, uint256 amount) internal view {
        require(amount <= _maxTxAmount || excludeMaxTxn[sender], "TX Limit Exceeded");
        
        if (sender != owner() && recipient != address(this)  && recipient != address(DEAD) && recipient != pair && recipient != treasuryWallet && recipient != liquidityWallet){
            uint256 currentBalance = balanceOf(recipient);
            require(excludeMaxTxn[recipient] || (currentBalance + amount <= _maxWallet));
        }
    }

    function takeFee(address sender, address recipient, uint256 amount) internal returns (uint256) {
        if (excludeFee[sender] || excludeFee[recipient]) 
            return amount;
        
        uint256 totalFee;
        if(sender == pair)
            totalFee = buyFees.totalFee;
        else
            totalFee = sellFees.totalFee;
            
        uint256 feeAmount = amount.mul(totalFee).div(feeDenominator);
        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);

        return amount.sub(feeAmount);
    }

    function canSwap() internal view returns (bool) {
        return msg.sender != pair
        && !inSwap
        && swapEnabled
        && _balances[address(this)] >= swapThreshold;
    }

    function swapBack() internal swapping {
        uint256 swapAmount = _balances[address(this)];
        if(!ignoreLimit)
            swapAmount = swapThreshold;

        lastSwap = block.timestamp;
        FeeSet memory fee = sellFees;
        uint256 totalFee = fee.totalFee;
        uint256 dynamicLiquidityFee = fee.liquidityFee;
        uint256 treasuryFee = fee.treasuryFee;
        uint256 reflectionFee = fee.reflectionFee;
        
        uint256 amountToLiquify = swapAmount.mul(dynamicLiquidityFee).div(totalFee).div(2);
        uint256 amountToSwap = swapAmount.sub(amountToLiquify);

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = WAVAX;

        uint256 balanceBefore = address(this).balance;

        router.swapExactTokensForAVAXSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amountAVAX = address(this).balance.sub(balanceBefore);

        uint256 totalAVAXFee = totalFee.sub(dynamicLiquidityFee.div(2));
        
        uint256 amountAVAXLiquidity = amountAVAX.mul(dynamicLiquidityFee).div(totalAVAXFee).div(2);
        if(amountToLiquify > 0){
            router.addLiquidityAVAX{value: amountAVAXLiquidity}(
                address(this),
                amountToLiquify,
                0,
                0,
                liquidityWallet,
                block.timestamp
            );
        }
        
        uint256 amountAVAXReflection = amountAVAX.mul(reflectionFee).div(totalAVAXFee);
        try dividendTracker.deposit{value: amountAVAXReflection}() {} catch {}
        
        uint256 amountAVAXTreasury = address(this).balance;
        payable(treasuryWallet).transfer(amountAVAXTreasury);
    }

    function setExcludeDividend(address holder, bool exempt) external onlyOwner {
        require(holder != address(this) && holder != pair);
        excludeDividend[holder] = exempt;
        if(exempt){
            dividendTracker.setShare(holder, 0);
        }else{
            dividendTracker.setShare(holder, _balances[holder]);
        }
    }

    function setExcludeFeeMultiple(address[] calldata _users, bool exempt) external onlyOwner {
        for(uint8 i = 0; i < _users.length; i++) {
            excludeFee[_users[i]] = exempt;
        }
    }
    
    function setExcludeTxMultiple(address[] calldata _users, bool exempt) external onlyOwner {
        for(uint8 i = 0; i < _users.length; i++) {
            excludeMaxTxn[_users[i]] = exempt;
        }
    }
    
    function setReceiver(address _treasuryWallet, address _liquidityWallet) external onlyOwner {
        treasuryWallet = _treasuryWallet;
        liquidityWallet = _liquidityWallet;
    }

    function rescueToken(address _token, uint256 _amount) external onlyOwner {
        IERC20(_token).transfer(msg.sender, _amount);
    }

    function rescueAVAX(uint256 _amount) external onlyOwner{
        payable(msg.sender).transfer(_amount);
    }

    function setSwapBackSettings(bool _enabled, uint256 _amount, bool _ignoreLimit, uint256 _interval) external onlyOwner {
        swapEnabled = _enabled;
        swapThreshold = _amount;
        ignoreLimit = _ignoreLimit;
        interval = _interval;
    }

    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution, uint256 _minimumTokenBalanceForDividends) external onlyOwner {
        dividendTracker.setDistributionCriteria(_minPeriod, _minDistribution, _minimumTokenBalanceForDividends);
    }
    
    function setTxLimit(uint256 amount) external onlyOwner {
        require(amount >= _totalSupply / 2000);
        _maxTxAmount = amount;
    }
    
    function getAccountDividendsInfo(address account)
        external view returns (
            address,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256) {
        return dividendTracker.getAccount(account);
    }
    
    function claim() public {
        dividendTracker.claimDividend(msg.sender);
    }

    function setBuyFees(uint256 _reflectionFee, uint256 _treasuryFee, uint256 _liquidityFee) public onlyOwner {
		buyFees = FeeSet({
			reflectionFee: _reflectionFee,
			treasuryFee: _treasuryFee,
			liquidityFee: _liquidityFee,
			totalFee: _reflectionFee + _treasuryFee + _liquidityFee
		});
	}

	function setSellFees(uint256 _reflectionFee, uint256 _treasuryFee, uint256 _liquidityFee) public onlyOwner {
		sellFees = FeeSet({
			reflectionFee: _reflectionFee,
			treasuryFee: _treasuryFee,
			liquidityFee: _liquidityFee,
			totalFee: _reflectionFee + _treasuryFee + _liquidityFee
		});
	}
}