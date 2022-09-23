/**
 *Submitted for verification at snowtrace.io on 2021-12-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

library SafeMath {
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    } 
	function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
}

interface IERC20 {
    function approve(address spender, uint256 amount) external returns (bool);
    function symbol() external view returns (string memory);
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function balanceOf(address account) external view returns (uint256);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IDEXFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IDEXRouter {
    function WAVAX() external pure returns (address);
    function factory() external pure returns (address);
    function swapExactTokensForAVAXSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function addLiquidityAVAX(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountAVAXMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountAVAX, uint liquidity);
    function swapExactAVAXForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
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
}

abstract contract Ownable {
    address public owner;
    constructor(address owner_) {
        owner = owner_;
    }
    modifier onlyOwner() {
        require(isOwner(msg.sender), "Ownership required."); _;
    }
    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }
    function transferOwnership(address payable adr) public onlyOwner {
        address oldOwner = owner;
        owner = adr;
        emit OwnershipTransferred(oldOwner, owner);
    }
	function renouceOwnership() public onlyOwner {
		emit OwnershipTransferred(owner, address(0));
		owner = address(0);
	}
    event OwnershipTransferred(address from, address to);
}

interface IDividendDistributor {
    function setShare(address shareholder, uint256 amount) external;
    function process(uint256 gas) external;
    function claimDividend() external;
    function deposit() external payable;
    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external;
}

contract DividendDistributor is IDividendDistributor {
    using SafeMath for uint256;
    address _token;
	
    IERC20 LINK = IERC20(0x5947BB275c521040051D82396192181b413227A3); 
    address WAVAX = 0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7; 

    struct Share {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalRealised;
    }
    IDEXRouter router;
    mapping (address => Share) public shares;
    mapping (address => uint256) shareholderIndexes;
    uint256 public totalShares;
    uint256 public dividendsPerShare;
    uint256 public dividendsPerShareAccuracyFactor = 10 ** 36;
    address[] shareholders;
    mapping (address => uint256) shareholderClaims;
    uint256 public minPeriod = 30 minutes;
    uint256 public minDistribution = .00001 * (10 ** 18); 
    uint256 public totalDividends;
    uint256 public totalDistributed;
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
    constructor (address _router) {
        router = _router != address(0)
            ? IDEXRouter(_router)
            : IDEXRouter(0x60aE616a2155Ee3d9A68541Ba4544862310933d4);
        _token = msg.sender;
    }
    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external override onlyToken {
        minPeriod = _minPeriod;
        minDistribution = _minDistribution;
    }
    function setShare(address shareholder, uint256 amount) external override onlyToken {
        if(shares[shareholder].amount > 0){
            distributeDividend(shareholder);
        }
        if(amount > 0 && shares[shareholder].amount == 0){
            addShareholder(shareholder);
        }else if(amount == 0 && shares[shareholder].amount > 0){
            removeShareholder(shareholder);
        }
        totalShares = totalShares.sub(shares[shareholder].amount).add(amount);
        shares[shareholder].amount = amount;
        shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
    }
    function deposit() external payable override onlyToken {
        uint256 balanceBefore = LINK.balanceOf(address(this));
        address[] memory path = new address[](2);
        path[0] = WAVAX;
        path[1] = address(LINK);
        router.swapExactAVAXForTokensSupportingFeeOnTransferTokens{value: msg.value}(
            0,
            path,
            address(this),
            block.timestamp
        );
        uint256 amount = LINK.balanceOf(address(this)).sub(balanceBefore);
        totalDividends = totalDividends.add(amount);
        dividendsPerShare = dividendsPerShare.add(dividendsPerShareAccuracyFactor.mul(amount).div(totalShares));
    }
    function process(uint256 gas) external override onlyToken {
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
    function getCumulativeDividends(uint256 share) internal view returns (uint256) {
        return share.mul(dividendsPerShare).div(dividendsPerShareAccuracyFactor);
    }
    function distributeDividend(address shareholder) internal {
        if(shares[shareholder].amount == 0){ return; }
        uint256 amount = getUnpaidEarnings(shareholder);
        if(amount > 0){
            totalDistributed = totalDistributed.add(amount);
            LINK.transfer(shareholder, amount);
            shareholderClaims[shareholder] = block.timestamp;
            shares[shareholder].totalRealised = shares[shareholder].totalRealised.add(amount);
            shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
        }
    }
    function claimDividend() external override {
        distributeDividend(msg.sender);
    }
    function removeShareholder(address shareholder) internal {
        shareholders[shareholderIndexes[shareholder]] = shareholders[shareholders.length-1];
        shareholderIndexes[shareholders[shareholders.length-1]] = shareholderIndexes[shareholder];
        shareholders.pop();
    }
    function getUnpaidEarnings(address shareholder) public view returns (uint256) {
        if(shares[shareholder].amount == 0){ return 0; }
        uint256 shareholderTotalDividends = getCumulativeDividends(shares[shareholder].amount);
        uint256 shareholderTotalExcluded = shares[shareholder].totalExcluded;
        if(shareholderTotalDividends <= shareholderTotalExcluded){ return 0; }
        return shareholderTotalDividends.sub(shareholderTotalExcluded);
    }
    function addShareholder(address shareholder) internal {
        shareholderIndexes[shareholder] = shareholders.length;
        shareholders.push(shareholder);
    }
}

contract autismdev is IERC20, Ownable {
    using SafeMath for uint256;

    string constant _name = "tested2";
    string constant _symbol = "testingtime2";
    uint8 constant _decimals = 9;
    uint256 _totalSupply = 10 ** 8 * (10 ** _decimals);
    uint256 public liquidityFee = 30;
    uint256 public burnFee = 0;
    uint256 public reflectionFee = 60;
    uint256 public marketingFee = 20;
    uint256 public buybackFee = 0;
    uint256 public _maxTxAmount = _totalSupply / 20;
    uint256 public _maxHold = _totalSupply / 20;
    address public marketingFeeReceiver = 0x686ED7349dA71CcACf5Edb6574fA0Edf87d3D9a4;
    address public buybackFeeReceiver = 0x686ED7349dA71CcACf5Edb6574fA0Edf87d3D9a4;

    address LINK = 0x5947BB275c521040051D82396192181b413227A3; 
	address WAVAX = 0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7;
    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;
    mapping (address => bool) isTxLimitExempt;
    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;
    mapping (address => bool) isMaxHoldExempt;
    mapping (address => bool) isFeeExempt;
    mapping (address => bool) isDividendExempt;
    uint256 public feeDenominator = 1000;
    uint256 totalFee = liquidityFee + reflectionFee + marketingFee + buybackFee + burnFee;
    address public autoLiquidityReceiver;
    address[] public pairs;
    IDEXRouter public router;
    address traderjoeAVAXPair;
    DividendDistributor distributor;
    uint256 distributorGas = 600000;
    uint256 public launchedAt;
    bool public liquifyEnabled = true;
    bool public feesOnNormalTransfers = false;
    bool public swapEnabled = true;
    bool inSwap;
    uint256 public swapThreshold = _totalSupply / 5000; // 0.02%
    modifier swapping() { inSwap = true; _; inSwap = false; }
    event SwapBackSuccess(uint256 amount);
    event Launched(uint256 blockNumber, uint256 timestamp);
    event BuybackTransfer(bool status);
    event SwapBackFailed(string message);
    event AutoLiquify(uint256 amountAVAX, uint256 amountBOG);
    event MarketTransfer(bool status);
    constructor () Ownable(msg.sender) {
        router = IDEXRouter(0x60aE616a2155Ee3d9A68541Ba4544862310933d4);

        
		autoLiquidityReceiver = 0xfA7d6a0024bCA2fdFDcbF48E4561D893586f535c;
        traderjoeAVAXPair = IDEXFactory(router.factory()).createPair(WAVAX, address(this));
        _allowances[address(this)][address(router)] = ~uint256(0);
        pairs.push(traderjoeAVAXPair);
        distributor = new DividendDistributor(address(router));
        address owner_ = msg.sender;
        isDividendExempt[DEAD] = true;
        isMaxHoldExempt[DEAD] = true;
        isMaxHoldExempt[traderjoeAVAXPair] = true;
        isDividendExempt[traderjoeAVAXPair] = true;
        isMaxHoldExempt[address(this)] = true;
        isFeeExempt[address(this)] = true;
        isDividendExempt[address(this)] = true;
        isTxLimitExempt[address(this)] = true;
        isFeeExempt[owner_] = true;
        isTxLimitExempt[owner_] = true;
        isMaxHoldExempt[owner_] = true;
        _balances[owner_] = _totalSupply;
        emit Transfer(address(0), owner_, _totalSupply);
    }
    receive() external payable { }
    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }
    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
    function decimals() external pure override returns (uint8) { return _decimals; }
    function name() external pure override returns (string memory) { return _name; }
    function symbol() external pure override returns (string memory) { return _symbol; }
    function getOwner() external view override returns (address) { return owner; }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }
    function totalSupply() external view override returns (uint256) { return _totalSupply; }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if(_allowances[sender][msg.sender] != ~uint256(0)){
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount, "Insufficient Allowance");
        }
        return _transferFrom(sender, recipient, amount);
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        if(inSwap){ return _basicTransfer(sender, recipient, amount); }
        checkTxLimit(sender, amount);
        if(shouldSwapBack()){ swapBack(); }
        if(!launched() && recipient == traderjoeAVAXPair){ require(_balances[sender] > 0); launch(); }
        if(!isMaxHoldExempt[recipient]){
            require((_balances[recipient] + (amount - amount * totalFee / feeDenominator))<= _maxHold, "Wallet cannot hold more than 1%");
        }
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        uint256 amountReceived = shouldTakeFee(sender, recipient) ? takeFee(sender, amount) : amount;
        _balances[recipient] = _balances[recipient].add(amountReceived);
        if(!isDividendExempt[sender]){ try distributor.setShare(sender, _balances[sender]) {} catch {} }
        if(!isDividendExempt[recipient]){ try distributor.setShare(recipient, _balances[recipient]) {} catch {} }
        try distributor.process(distributorGas) {} catch {}
        emit Transfer(sender, recipient, amountReceived);
        return true;
    }

    function approveMax(address spender) external returns (bool) {
        return approve(spender, ~uint256(0));
    }

    function getTotalFee() public view returns (uint256) {
        if(launchedAt + 1 >= block.number){ return feeDenominator.sub(1); }
        return totalFee;
    }

    function shouldTakeFee(address sender, address recipient) internal view returns (bool) {
        if (isFeeExempt[sender] || isFeeExempt[recipient] || !launched()) return false;
        address[] memory liqPairs = pairs;
        for (uint256 i = 0; i < liqPairs.length; i++) {
            if (sender == liqPairs[i] || recipient == liqPairs[i]) return true;
        }
        return feesOnNormalTransfers;
    }

    function isSell(address recipient) internal view returns (bool) {
        address[] memory liqPairs = pairs;
        for (uint256 i = 0; i < liqPairs.length; i++) {
            if (recipient == liqPairs[i]) return true;
        }
        return false;
    }

    function checkTxLimit(address sender, uint256 amount) internal view {
        require(amount <= _maxTxAmount || isTxLimitExempt[sender], "TX Limit Exceeded");
    }

    function takeFee(address sender, uint256 amount) internal returns (uint256) {
        uint256 feeAmount = amount.mul(getTotalFee()).div(feeDenominator);
        uint256 burnAmount = feeAmount.mul(burnFee).div(totalFee);
        uint256 finalFee = feeAmount.sub(burnAmount);
        _balances[address(this)] = _balances[address(this)].add(finalFee);
        _balances[DEAD] = _balances[DEAD].add(burnAmount);
        emit Transfer(sender, DEAD, burnAmount);
        emit Transfer(sender, address(this), finalFee);
        return amount.sub(feeAmount);
    }

    function setIsMaxHoldExempt(address holder, bool exempt) public onlyOwner() {
        isMaxHoldExempt[holder] = exempt;
    }

    function setIsTxLimitExempt(address holder, bool exempt) public onlyOwner() {
        isTxLimitExempt[holder] = exempt;
    }

    function shouldSwapBack() internal view returns (bool) {
        return msg.sender != traderjoeAVAXPair
        && !inSwap
        && swapEnabled
        && _balances[address(this)] >= swapThreshold;
    }

    function setTxLimit(uint256 amount, bool _withCSupply) public onlyOwner() {
        if (_withCSupply) {
            require(amount >= getCirculatingSupply() / 2000);
            _maxTxAmount = amount;
        } else {
            require(amount >= _totalSupply / 2000);
            _maxTxAmount = amount;
        }
    }

    function launch() internal {
        launchedAt = block.number;
        emit Launched(block.number, block.timestamp);
    }

    function setIsDividendExempt(address holder, bool exempt) public onlyOwner() {
        require(holder != address(this) && holder != traderjoeAVAXPair);
        isDividendExempt[holder] = exempt;
        if(exempt){
            distributor.setShare(holder, 0);
        }else{
            distributor.setShare(holder, _balances[holder]);
        }
    }

    function launched() internal view returns (bool) {
        return launchedAt != 0;
    }

    function setIsFeeExempt(address holder, bool exempt) public onlyOwner() {
        isFeeExempt[holder] = exempt;
    }

    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) public onlyOwner() {
        distributor.setDistributionCriteria(_minPeriod, _minDistribution);
    }

    function setDistributorSettings(uint256 gas) public onlyOwner() {
        require(gas <= 1000000);
        distributorGas = gas;
    }

    function setFeesOnNormalTransfers(bool _enabled) public onlyOwner() {
        feesOnNormalTransfers = _enabled;
    }

    function setFees(uint256 _liquidityFee, uint256 _reflectionFee, uint256 _marketingFee, uint256 _buybackFee, uint256 _burnFee, uint256 _feeDenominator) public onlyOwner() {
        liquidityFee = _liquidityFee;
        reflectionFee = _reflectionFee;
        marketingFee = _marketingFee;
        buybackFee = _buybackFee;
        burnFee = _burnFee;
        totalFee = _liquidityFee.add(_reflectionFee).add(_marketingFee).add(_buybackFee).add(_burnFee);
        feeDenominator = _feeDenominator;
    }

    function setFeeReceivers(address _buybackFeeReciever, address _autoLiquidityReceiver, address _marketingFeeReceiver) public onlyOwner() {
        buybackFeeReceiver = _buybackFeeReciever;
        autoLiquidityReceiver = _autoLiquidityReceiver;
        marketingFeeReceiver = _marketingFeeReceiver;
    }

    function setSwapBackSettings(bool _enabled, uint256 _amount) public onlyOwner() {
        swapEnabled = _enabled;
        swapThreshold = _amount;
    }

    function setLiquifyEnabled(bool _enabled) public onlyOwner() {
        liquifyEnabled = _enabled;
    }

    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply.sub(balanceOf(DEAD)).sub(balanceOf(ZERO));
    }

    function addPair(address pair) public onlyOwner() {
        pairs.push(pair);
    }

    function claimDividend() external {
        distributor.claimDividend();
    }

    function clearStuckAVAX() external {
        payable(marketingFeeReceiver).transfer(address(this).balance);
    }

    function setMaxHoldPercentage(uint256 percent) public onlyOwner() {
         _maxHold = (_totalSupply / 100) * percent;
    }    

    function setLaunchedAt(uint256 launched_) public onlyOwner() {
        launchedAt = launched_;
    }
    
    function removeLastPair() public onlyOwner() {
        pairs.pop();
    }

    function swapBack() internal swapping {
        uint256 swapLiquidityFee = liquifyEnabled ? liquidityFee : 0;
        uint256 amountToLiquify = swapThreshold.mul(swapLiquidityFee).div(totalFee).div(2);
        uint256 amountToSwap = swapThreshold.sub(amountToLiquify);
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = WAVAX;
        uint256 balanceBefore = address(this).balance;
        try router.swapExactTokensForAVAXSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        ) {
            uint256 amountAVAX = address(this).balance.sub(balanceBefore);
            uint256 totalAVAXFee = totalFee.sub(swapLiquidityFee.div(2));
            uint256 amountAVAXLiquidity = amountAVAX.mul(swapLiquidityFee).div(totalAVAXFee).div(2);
            uint256 amountAVAXReflection = amountAVAX.mul(reflectionFee).div(totalAVAXFee);
            uint256 amountAVAXMarketing = amountAVAX.mul(marketingFee).div(totalAVAXFee);
            uint256 amountAVAXBuyback = amountAVAX.mul(buybackFee).div(totalAVAXFee);
            try distributor.deposit{value: amountAVAXReflection}() {} catch {}
            (bool marketSuccess, ) = payable(marketingFeeReceiver).call{value: amountAVAXMarketing, gas: 30000}("");
            (bool buybackSuccess, ) = payable(buybackFeeReceiver).call{value: amountAVAXBuyback, gas: 30000}("");
            emit MarketTransfer(marketSuccess);
            emit BuybackTransfer(buybackSuccess);
            if(amountToLiquify > 0){
                try router.addLiquidityAVAX{ value: amountAVAXLiquidity }(
                    address(this),
                    amountToLiquify,
                    0,
                    0,
                    autoLiquidityReceiver,
                    block.timestamp
                ) {
                    emit AutoLiquify(amountToLiquify, amountAVAXLiquidity);
                } catch {
                    emit AutoLiquify(0, 0);
                }
            }
            emit SwapBackSuccess(amountToSwap);
        } catch Error(string memory e) {
            emit SwapBackFailed(string(abi.encodePacked("SwapBack failed with error ", e)));
        } catch {
            emit SwapBackFailed("SwapBack failed without an error message from traderjoe");
        }
    }
}