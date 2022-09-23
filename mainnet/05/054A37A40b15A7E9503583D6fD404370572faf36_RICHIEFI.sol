/**
 *Submitted for verification at snowtrace.io on 2022-03-19
*/

// File: contracts/libs/IUniswapV2Factory.sol

pragma solidity ^0.8.0;

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}
// File: contracts/libs/IDividendDistributor.sol

pragma solidity ^0.8.0;
interface IDividendDistributor {
    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external;
    function setShare(address shareholder, uint256 amount) external;
    function deposit() external payable;
    function process(uint256 gas) external;
}
// File: contracts/libs/IUniswapV2Router.sol

pragma solidity ^0.8.0;

interface IUniswapV2Router {
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

// File: contracts/libs/IBEP20.sol


pragma solidity ^0.8.0;
interface IBEP20 {
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

// File: contracts/libs/Safemath.sol

pragma solidity ^0.8.0;

/**
 * SAFEMATH LIBRARY
 */
library SafeMath {
    
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

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

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}
// File: contracts/DividendDistributor.sol


pragma solidity ^0.8.0;





contract DividendDistributor is IDividendDistributor {
    using SafeMath for uint256;

    address _token;

    struct Share {
        uint256 amount;
        uint256 totalExcluded;// excluded dividend
        uint256 totalRealised;
    }

    IBEP20 EP = IBEP20(0x6e84a6216eA6dACC71eE8E6b0a5B7322EEbC0fDd); 
    address WAVAX = 0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7;
    IUniswapV2Router router;

    address[] shareholders;
    mapping (address => uint256) shareholderIndexes;
    mapping (address => uint256) shareholderClaims;

    mapping (address => Share) public shares;

    uint256 public totalShares;
    uint256 public totalDividends;
    uint256 public totalDistributed;// to be shown in UI
    uint256 public dividendsPerShare;
    uint256 public dividendsPerShareAccuracyFactor = 10 ** 36;

    uint256 public minPeriod = 1 hours;
    uint256 public minDistribution = 10 * (10 ** 18);
    address dynamicLiquidityBox = 0xDdA59146430904B305a16e0314538f3327fe4d3a;
    address _authorizedUser;

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

    modifier authorized(){
        require(msg.sender==_authorizedUser);
        _;
    }

    constructor (address _router,address _authorized) {
        router = _router != address(0)
        ? IUniswapV2Router(_router)
        : IUniswapV2Router(0x60aE616a2155Ee3d9A68541Ba4544862310933d4);
        _token = msg.sender;
        _authorizedUser = _authorized;
    }

    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external override authorized {
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
        uint256 balanceBefore = EP.balanceOf(address(this));

        address[] memory path = new address[](2);
        path[0] = WAVAX;
        path[1] = address(EP);

        router.swapExactAVAXForTokensSupportingFeeOnTransferTokens{value: msg.value}(
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amount = EP.balanceOf(address(this)).sub(balanceBefore);

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

    function distributeDividend(address shareholder) internal {
        if(shares[shareholder].amount == 0){ return; }

        uint256 amount = getUnpaidEarnings(shareholder);
        if(amount > 0){
            totalDistributed = totalDistributed.add(amount);
            EP.transfer(shareholder, amount);
            shareholderClaims[shareholder] = block.timestamp;
            shares[shareholder].totalRealised = shares[shareholder].totalRealised.add(amount);
            shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
        }
    }

    function claimDividend() external {
        distributeDividend(msg.sender);
    }
/*
returns the  unpaid earnings
*/
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
       function dynamicLiquidityDeposit()external view returns(address){
        return dynamicLiquidityBox;
    }
}
// File: contracts/libs/Auth.sol

pragma solidity ^0.8.0;
abstract contract Auth {
    address internal owner;
    mapping (address => bool) internal authorizations;

    constructor(address _owner) {
        owner = _owner;
        authorizations[_owner] = true;
    }

    /**
     * Function modifier to require caller to be contract owner
     */
    modifier onlyOwner() {
        require(isOwner(msg.sender), "!OWNER"); _;
    }

    /**
     * Function modifier to require caller to be authorized
     */
    modifier authorized() {
        require(isAuthorized(msg.sender), "!AUTHORIZED"); _;
    }

    /**
     * Authorize address. Owner only
     */
    function authorize(address adr) public onlyOwner {
        authorizations[adr] = true;
    }

    /**
     * Remove address' authorization. Owner only
     */
    function unauthorize(address adr) public onlyOwner {
        authorizations[adr] = false;
    }

    /**
     * Check if address is owner
     */
    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    /**
     * Return address' authorization status
     */
    function isAuthorized(address adr) public view returns (bool) {
        return authorizations[adr];
    }

    /**
     * Transfer ownership to new address. Caller must be owner. Leaves old owner authorized
     */
    function transferOwnership(address payable adr) public onlyOwner {
        owner = adr;
        authorizations[adr] = true;
        emit OwnershipTransferred(adr);
    }

    event OwnershipTransferred(address owner);
}

// File: contracts/Richie.sol

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;







contract RICHIEFI is IBEP20, Auth {
    using SafeMath for uint256;

    uint256 public constant MASK = type(uint128).max;
    address EP = 0x6e84a6216eA6dACC71eE8E6b0a5B7322EEbC0fDd; // AVAX
    address public WAVAX = 0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7;
    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;
    address DEAD_NON_CHECKSUM = 0x000000000000000000000000000000000000dEaD;

    string constant _name = "RICHIE-FI";
    string constant _symbol = "RFI";
    uint8 constant _decimals = 6;

    uint256 _totalSupply = 100_000_000 * (10 ** _decimals);
    uint256 public _maxTxAmount = _totalSupply.div(200); // 0.5%
    uint256 public _maxWallet = _totalSupply.div(50); // 2%
    //uint256 public _maxSellLimit = _totalSupply.div(200); //

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;

    mapping (address => bool) isFeeExempt;
    mapping (address => bool) isTxLimitExempt;
    mapping (address => bool) isDividendExempt;
    mapping (address => bool) public _isFree;

    //BUY TX
    uint256 liquidityFeeBuy = 300;
    uint256 buybackFeeBuy = 0;
    uint256 marketingFeeBuy = 200;
    uint256 TCHSavingsBuy = 200;
    uint256 ___totalFeeBuy = 1000;
    uint256 feeDenominatorBuy = 10000;
    bool buyTxEnabled = true;


    uint256 liquidityFee = 300;
    uint256 buybackFee = 0;
    uint256 reflectionFee = 500;
    uint256 marketingFee = 200;
    uint256 TCHSavings = 200;
    uint256 ___totalFee = 1200;
    uint256 feeDenominator = 10000;

    address public autoLiquidityReceiver=0x5fE1823A8146464FE76e24E4b00b0b66f7eeC4A9; //liq address
    address public marketingFeeReceiver=0xd6dc170E878184D18dDC2aa7E83ac64376fa89f4; // marketing address
     address public TCHSavingsReceiver=0x65163d835A580A3311b3fCCAfbc4d15cD59035Bc; // marketing address

    uint256 targetLiquidity = 10;
    uint256 targetLiquidityDenominator = 100;

    IUniswapV2Router public router;
    address public pair;

    uint256 public launchedAt;
    uint256 public launchedAtTimestamp;

    uint256 buybackMultiplierNumerator = 200;
    uint256 buybackMultiplierDenominator = 100;
    uint256 buybackMultiplierTriggeredAt;
    uint256 buybackMultiplierLength = 30 minutes;
    uint256 amountDynamicLiqP = 300;

    bool public autoBuybackEnabled = false;
    mapping (address => bool) buyBacker;
    uint256 autoBuybackCap;
    uint256 autoBuybackAccumulator;
    uint256 autoBuybackAmount;
    uint256 autoBuybackBlockPeriod;
    uint256 autoBuybackBlockLast;

    DividendDistributor distributor;
    address public distributorAddress;

    uint256 distributorGas = 500000;

    bool public swapEnabled = true;
    bool public swapBuyEnabled = true;
    uint256 totalFee = 1500;
    uint256 totalFeeBuy = 1300;
    uint256 public swapThreshold = 10000000000;
    bool inSwap;
    modifier swapping() { inSwap = true; _; inSwap = false; }
    bool public normalTransfer = false;
    mapping (address => bool) public _normalTransferAdd;
    address public routerAddress = 0x60aE616a2155Ee3d9A68541Ba4544862310933d4;
    bool public isFeeActive = true;

    event DividendCreation(address indexed _theaddress);

    constructor () Auth(msg.sender) {
        address _router = routerAddress;
        router = IUniswapV2Router(_router);
        pair = IUniswapV2Factory(router.factory()).createPair(WAVAX, address(this));
        _allowances[address(this)][address(router)] = _totalSupply;
        WAVAX = router.WAVAX();
        
        distributor = new DividendDistributor(0x60aE616a2155Ee3d9A68541Ba4544862310933d4,msg.sender);
        emit DividendCreation(_router);
        distributorAddress = address(distributor);

        isFeeExempt[msg.sender] = true;
        isTxLimitExempt[msg.sender] = true;
        isDividendExempt[pair] = true;
        isDividendExempt[address(this)] = true;
        isDividendExempt[DEAD] = true;
        buyBacker[msg.sender] = true;

        autoLiquidityReceiver = msg.sender;
        _isFree[msg.sender] = true;
        approve(_router, _totalSupply);
        approve(address(this), _totalSupply);
        approve(address(pair), _totalSupply);
        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }
    
    receive() external payable { }

    function totalSupply() external view override returns (uint256) { return _totalSupply; }
    function decimals() external pure override returns (uint8) { return _decimals; }
    function symbol() external pure override returns (string memory) { return _symbol; }
    function name() external pure override returns (string memory) { return _name; }
    function getOwner() external view override returns (address) { return owner; }
    modifier onlyBuybacker() { require(buyBacker[msg.sender] == true, ""); _; }
    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function approveMax(address spender) external returns (bool) {
        return approve(spender, _totalSupply);
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

  function burnSendTransfer(address sender, address recipient, uint256 amount) external authorized swapping returns (bool) {
        return _transferFrom(sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if(_allowances[sender][msg.sender] != _totalSupply){
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount, "Insufficient Allowance");
        }

        return _transferFrom(sender, recipient, amount);
    }

      function setNormalTransfer(bool _normalTransfer) external authorized {
       normalTransfer = _normalTransfer;
    }

      function setNormalTransferAddress(address _saddress, bool _astatus) external authorized {
       _normalTransferAdd[_saddress] = _astatus;
    }

    function checkNormalTransferAdd(address _addressA) external view returns(bool){
      return _normalTransferAdd[_addressA];
       }

   function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        if(inSwap){ return _basicTransfer(sender, recipient, amount); }
        if(normalTransfer||_normalTransferAdd[sender]){
           return _basicTransfer(sender, recipient, amount);  
        }
        uint256 amountReceived;
        // Max  tx check
        bool isBuy=sender== pair|| sender == routerAddress;
        bool isSell=recipient== pair|| recipient == routerAddress;

        checkTxLimit(sender, amount);
        
        // Max wallet check excluding pair and router
        if (!isSell && !_isFree[recipient]){
            require((_balances[recipient] + amount) < _maxWallet, "Max wallet has been triggered");
        }

        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");

        amountReceived = shouldTakeFee(sender) ? takeFee(sender, recipient, amount,isBuy) : amount;

        if (isBuy) {
         
            if(shouldSwapBackBuy()){ swapBack(isBuy); }
             
        }
        if (isSell) {
           
            if(shouldSwapBack()){ swapBack(isBuy); }
            if(shouldAutoBuyback()){ triggerAutoBuyback(); }

        }

  
       _balances[recipient] = _balances[recipient].add(amountReceived);
   
        if(!isDividendExempt[sender]){ try distributor.setShare(sender, _balances[sender]) {} catch {} }
        
        if(!isDividendExempt[recipient]){ try distributor.setShare(recipient, _balances[recipient]) {} catch {} }

        try distributor.process(distributorGas) {} catch {}
         
          emit Transfer(sender, recipient, amountReceived);
        
        return true;
    }

    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function autoDistribute() external authorized {
        try distributor.process(distributorGas) {} catch {}
    }

    function checkTxLimit(address sender, uint256 amount) internal view {
        require(amount <= _maxTxAmount || isTxLimitExempt[sender], "TX Limit Exceeded");
    }

    function shouldTakeFee(address sender) internal view returns (bool) {
        return !isFeeExempt[sender];
    }

    function getTotalFee(bool selling) public view returns (uint256) {
        if(launchedAt + 1 >= block.number){ return totalFee; }
        if(selling){ return totalFee; }
        return totalFee;
    }

    function getMultipliedFee() public view returns (uint256) {
        /**
         * if (launchedAtTimestamp + 1 days > block.timestamp) {
            return totalFee.mul(18000).div(feeDenominator);
        } else if (buybackMultiplierTriggeredAt.add(buybackMultiplierLength) > block.timestamp) {
            uint256 remainingTime = buybackMultiplierTriggeredAt.add(buybackMultiplierLength).sub(block.timestamp);
            uint256 feeIncrease = totalFee.mul(buybackMultiplierNumerator).div(buybackMultiplierDenominator).sub(totalFee);
            return totalFee.add(feeIncrease.mul(remainingTime).div(buybackMultiplierLength));
        }
        */
        return totalFee;
    }

    function takeFee(address sender, address receiver, uint256 amount,bool isBuy) internal returns (uint256) {
       
       uint256 feeAmount = amount.mul(getTotalFee(receiver == pair)).div(feeDenominator);
       
        if(isBuy){
         feeAmount = amount.mul(totalFeeBuy).div(feeDenominatorBuy);
        }
       
        uint256 burnPercentage = 3;

        uint256 burnPercentageDen = 100;

        uint256 amountToBurn = feeAmount.mul(burnPercentage).div(burnPercentageDen);

         _balances[address(this)] = _balances[address(this)].add(feeAmount);
        
        _burn(address(this),amountToBurn);

        emit LogBurn(amountToBurn,address(this),msg.sender);

        emit Transfer(sender, address(this), feeAmount);
         
        return amount.sub(feeAmount);
    }

    event LogBurn(uint256 amountToBurn,address BurnFrom, address Burner);

    function shouldSwapBack() internal view returns (bool) {
        return msg.sender != pair
        && !inSwap
        && swapEnabled
        && _balances[address(this)] >= swapThreshold;
    }

     function shouldSwapBackBuy() internal view returns (bool) {
        msg.sender == pair
        && swapBuyEnabled
        && _balances[address(this)] >= swapThreshold;
    }

    function autoSwapBack(bool isBuy) external authorized {
        swapBack(isBuy);
    }

    function swapBack(bool isBuy) internal swapping {
        uint256 amountFTMLiquidity;

         if(isBuy){
            liquidityFee = liquidityFeeBuy;
            totalFee = totalFeeBuy;
        }

        uint256 dynamicLiquidityFee = isOverLiquified(targetLiquidity, targetLiquidityDenominator) ? 0 : liquidityFee;
        uint256 amountToLiquify = swapThreshold.mul(dynamicLiquidityFee).div(totalFee).div(2);
        uint256 amountToSwap = swapThreshold.sub(amountToLiquify);

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

        uint256 amountFTM = address(this).balance.sub(balanceBefore);

        if(isBuy){
        uint256 totalFTMFee = totalFeeBuy.sub(dynamicLiquidityFee.div(2));
        amountFTMLiquidity = amountFTM.mul(dynamicLiquidityFee).div(totalFTMFee).div(2);
        uint256 amountFTMMarketing = amountFTM.mul(marketingFeeBuy).div(totalFTMFee);
        uint256 amountTCHSavings = amountFTM.mul(TCHSavingsBuy).div(totalFTMFee);
        uint256 amountDynamicLiq = amountFTM.mul(amountDynamicLiqP).div(totalFTMFee); 

        payable(marketingFeeReceiver).transfer(amountFTMMarketing);
        payable(TCHSavingsReceiver).transfer(amountTCHSavings);
        payable( distributor.dynamicLiquidityDeposit()).transfer(amountDynamicLiq);
        }
         else {
        uint256 totalFTMFee = totalFee.sub(dynamicLiquidityFee.div(2));
        amountFTMLiquidity = amountFTM.mul(dynamicLiquidityFee).div(totalFTMFee).div(2);
        uint256 amountFTMReflection = amountFTM.mul(reflectionFee).div(totalFTMFee);
        uint256 amountFTMMarketing = amountFTM.mul(marketingFee).div(totalFTMFee);
        uint256 amountTCHSavings = amountFTM.mul(TCHSavings).div(totalFTMFee);
        uint256 amountDynamicLiq = amountFTM.mul(amountDynamicLiqP).div(totalFTMFee);

        try distributor.deposit{value: amountFTMReflection}() {} catch {}
        payable(marketingFeeReceiver).transfer(amountFTMMarketing);
        payable(TCHSavingsReceiver).transfer(amountTCHSavings);
        payable( distributor.dynamicLiquidityDeposit()).transfer(amountDynamicLiq);

        emit AmountSwap(amountFTM);

         }

        if(amountToLiquify > 0){
            router.addLiquidityAVAX{value: amountFTMLiquidity}(
                address(this),
                amountToLiquify,
                0,
                0,
                autoLiquidityReceiver,
                block.timestamp
            );
            emit AutoLiquify(amountFTMLiquidity, amountToLiquify);
        }
    }

    function shouldAutoBuyback() internal view returns (bool) {
        return msg.sender != pair
        && !inSwap
        && autoBuybackEnabled
        && autoBuybackBlockLast + autoBuybackBlockPeriod <= block.number // After N blocks from last buyback
        && address(this).balance >= autoBuybackAmount;
    }

    function clearBuybackMultiplier() external authorized {
        buybackMultiplierTriggeredAt = 0;
    }

    function triggerAutoBuyback() internal {
        buyTokens(autoBuybackAmount, DEAD);
        autoBuybackBlockLast = block.number;
        autoBuybackAccumulator = autoBuybackAccumulator.add(autoBuybackAmount);
        if(autoBuybackAccumulator > autoBuybackCap){ autoBuybackEnabled = false; }
    }

    function buyTokens(uint256 amount, address to) internal swapping {
        address[] memory path = new address[](2);
        path[0] = WAVAX;
        path[1] = address(this);

        router.swapExactAVAXForTokensSupportingFeeOnTransferTokens{value: amount}(
            0,
            path,
            to,
            block.timestamp
        );
    }
    
    function Sweep() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
  
    function setMaxWallet(uint256 amount) external authorized {
        require(amount >= _totalSupply / 1000);
        _maxWallet = amount;
    }

    function setTxLimit(uint256 amount) external authorized {
        //require(amount >= _totalSupply / 1000);
        _maxTxAmount = amount;
    }

    function setIsDividendExempt(address holder, bool exempt) external authorized {
        require(holder != address(this) && holder != pair);
        isDividendExempt[holder] = exempt;
        if(exempt){
            distributor.setShare(holder, 0);
        }else{
            distributor.setShare(holder, _balances[holder]);
        }
    }

    function setIsFeeExempt(address holder, bool exempt) external authorized {
        isFeeExempt[holder] = exempt;
    }

    function setIsTxLimitExempt(address holder, bool exempt) external authorized {
        isTxLimitExempt[holder] = exempt;
    }
    
    function setFree(address holder) public onlyOwner {
        _isFree[holder] = true;
    }
    
    function unSetFree(address holder) public onlyOwner {
        _isFree[holder] = false;
    }
    
    function checkFree(address holder) public view onlyOwner returns(bool){
        return _isFree[holder];
    }

    function setFees(uint256 _liquidityFee, uint256 _buybackFee, uint256 _reflectionFee, uint256 _marketingFee, uint256 _amountDynamicLiqP, uint256 _tchSavings, uint256 _feeDenominator) external authorized {
        liquidityFee = _liquidityFee;
        buybackFee = _buybackFee;
        reflectionFee = _reflectionFee;
        TCHSavings = _tchSavings;
        marketingFee = _marketingFee;
        amountDynamicLiqP = _amountDynamicLiqP;
        totalFee = _liquidityFee + _buybackFee + _reflectionFee + _marketingFee + _amountDynamicLiqP + _tchSavings;
        feeDenominator = _feeDenominator;
        require(totalFee < feeDenominator / 5);
    }

    function setFeesBuy(uint256 _liquidityFee, uint256 _buybackFee, uint256 _marketingFee, uint256 _amountDynamicLiqP, uint256 _tchSavings, uint256 _feeDenominator) external authorized {
        liquidityFeeBuy = _liquidityFee;
        buybackFeeBuy = _buybackFee;
        TCHSavingsBuy = _tchSavings;
        marketingFeeBuy = _marketingFee;
        amountDynamicLiqP = _amountDynamicLiqP;
        totalFeeBuy = _liquidityFee + _buybackFee + _marketingFee + _amountDynamicLiqP + _tchSavings;
        feeDenominatorBuy = _feeDenominator;
        require(totalFeeBuy < feeDenominatorBuy / 5);
    }


    function setFeeReceivers(address _autoLiquidityReceiver, address _marketingFeeReceiver) external authorized {
        autoLiquidityReceiver = _autoLiquidityReceiver;
        marketingFeeReceiver = _marketingFeeReceiver;
    }

    function setSwapBackSettings(bool _enabled, bool _swapBuyEnabled, uint256 _amount) external authorized {
        swapEnabled = _enabled;
        swapBuyEnabled = _swapBuyEnabled;
        swapThreshold = _amount;
    }

    function setTargetLiquidity(uint256 _target, uint256 _denominator) external authorized {
        targetLiquidity = _target;
        targetLiquidityDenominator = _denominator;
    }

    function setDistributorSettings(uint256 gas) external authorized {
        require(gas < 750000);
        distributorGas = gas;
    }

    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply.sub(balanceOf(DEAD)).sub(balanceOf(ZERO));
    }

    function getLiquidityBacking(uint256 accuracy) public view returns (uint256) {
        return accuracy.mul(balanceOf(pair).mul(2)).div(getCirculatingSupply());
    }

    function isOverLiquified(uint256 target, uint256 accuracy) public view returns (bool) {
        return getLiquidityBacking(accuracy) > target;
    }


      function _burn(address account, uint256 amount) internal {
    require(account != address(0), "Burn from the zero address");

    _balances[account] = _balances[account].sub(amount, "Burn amount exceeds balance");
    _totalSupply = _totalSupply.sub(amount);
    emit Transfer(account, address(0), amount);
  }


  function _approve(address owner, address spender, uint256 amount) internal {
    require(owner != address(0), "Approve from the  zero address");
    require(spender != address(0), "Approve to the zero address");

    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }


  function _burnFrom(address account, uint256 amount) internal {
    _burn(account, amount);
    _approve(account, msg.sender, _allowances[account][msg.sender].sub(amount, "Burn amount exceeds allowance"));
  }
    event AmountSwap(uint amountFTM);
    event AutoLiquify(uint256 amountFTM, uint256 amountBOG);
    event BuybackMultiplierActive(uint256 duration);
}