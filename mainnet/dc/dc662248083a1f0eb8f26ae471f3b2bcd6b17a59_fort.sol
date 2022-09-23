// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.6;

import "./DividendPayingToken.sol";
import "./IterableMapping.sol";
import "./Ownable.sol";
import "./IDex.sol";
import "./SafeMath.sol";

library Address{
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

contract fort is ERC20, Ownable {
    using Address for address payable;

    IRouter public router;
    address public  pair;
        
    bool private swapping;
    bool public swapEnabled;
    bool public tradingEnabled;
    uint256 public genesis_block;

   fortDividendTracker public dividendTracker;

    uint256 public swapTokensAtAmount = 1_000_000_000 * (10**9);
    uint256 public maxBuyAmount = 20_000_000_000 * 10**9;
    uint256 public maxSellAmount = 10_000_000_000 * 10**9;
    uint256 public maxWalletBalance = 30_000_000_000 * 10**9;

    uint256 public AVAXRewardsFee = 5;
    uint256 public marketingFee = 5;
    uint256 public buybackFee = 2;
    uint256 public utilityFee = 2;
    uint256 public liquidityFee = 1;
    uint256 public totalFees = AVAXRewardsFee + marketingFee + buybackFee + liquidityFee;
    
    address public marketingWallet = 0x0D2bb4c7b27A2c90C2473E10Ac0E8E99Cb78800C;
    address public buybackWallet = 0x6ec070b30dc0E95fA61d4Dc9c39b5a83709d30C8;
    address public utilityWallet = 0x38d299932074B6640df3172bd81Ad12dCF3185CC;

    // use by default 300,000 gas to process auto-claiming dividends
    uint256 public gasForProcessing = 300000;

    mapping (address => bool) private _isExcludedFromFees;

    // store addresses that a automatic market maker pairs. Any transfer *to* these addresses
    // could be subject to a maximum transfer amount
    mapping (address => bool) public automatedMarketMakerPairs;

    event UpdateDividendTracker(address indexed newAddress, address indexed oldAddress);
    event Updaterouter(address indexed newAddress, address indexed oldAddress);
    event ExcludeFromFees(address indexed account, bool isExcluded);
    event ExcludeMultipleAccountsFromFees(address[] accounts, bool isExcluded);
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
    event GasForProcessingUpdated(uint256 indexed newValue, uint256 indexed oldValue);

    event SendDividends(
    	uint256 tokensSwapped,
    	uint256 amount
    );

    event ProcessedDividendTracker(
    	uint256 iterations,
    	uint256 claims,
        uint256 lastProcessedIndex,
    	bool indexed automatic,
    	uint256 gas,
    	address indexed processor
    );

     modifier lockTheSwap {
        swapping = true;
        _;
        swapping = false;
    }

    constructor()  ERC20("forttest", "fort") {
        
    	dividendTracker = new fortDividendTracker();

    	IRouter _router = IRouter(0x60aE616a2155Ee3d9A68541Ba4544862310933d4);
         // Create a uniswap pair for this new token
        address _pair = IFactory(_router.factory())
            .createPair(address(this), _router.WAVAX());

        router = _router;
        pair = _pair;

        _setAutomatedMarketMakerPair(_pair, true);

        // exclude from receiving dividends
        dividendTracker.excludeFromDividends(address(dividendTracker));
        dividendTracker.excludeFromDividends(address(this));
        dividendTracker.excludeFromDividends(owner());
        dividendTracker.excludeFromDividends(address(_router));

        // exclude from paying fees or having max transaction amount
        excludeFromFees(owner(), true);
        excludeFromFees(address(this), true);
        excludeFromFees(marketingWallet, true);
        excludeFromFees(buybackWallet, true);
        excludeFromFees(utilityWallet, true);

        /*
            _mint is an internal function in ERC20.sol that is only called here,
            and CANNOT be called ever again
        */
        _mint(owner(), 1_000_000_000_000  * (10**9));
    }

    receive() external payable {

  	}


    function updateDividendTracker(address newAddress) public onlyOwner {
        require(newAddress != address(dividendTracker), "fort: The dividend tracker already has that address");

        fortDividendTracker newDividendTracker = fortDividendTracker(payable(newAddress));

        require(newDividendTracker.owner() == address(this), "fort: The new dividend tracker must be owned by the fort token contract");

        newDividendTracker.excludeFromDividends(address(newDividendTracker));
        newDividendTracker.excludeFromDividends(address(this));
        newDividendTracker.excludeFromDividends(owner());
        newDividendTracker.excludeFromDividends(address(router));

        emit UpdateDividendTracker(newAddress, address(dividendTracker));

        dividendTracker = newDividendTracker;
    }

    function updaterouter(address newAddress) public onlyOwner {
        require(newAddress != address(router), "fort: The router already has that address");
        emit Updaterouter(newAddress, address(router));
        router = IRouter(newAddress);
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        require(_isExcludedFromFees[account] != excluded, "fort: Account is already the value of 'excluded'");
        _isExcludedFromFees[account] = excluded;

        emit ExcludeFromFees(account, excluded);
    }

    function excludeMultipleAccountsFromFees(address[] calldata accounts, bool excluded) public onlyOwner {
        for(uint256 i = 0; i < accounts.length; i++) {
            _isExcludedFromFees[accounts[i]] = excluded;
        }

        emit ExcludeMultipleAccountsFromFees(accounts, excluded);
    }

    function setSwapTokensAtAmount(uint256 amount) external onlyOwner{
        swapTokensAtAmount = amount * 10**9;
    }

    function setMaxWalletBalance(uint256 amount) external onlyOwner{
        maxWalletBalance = amount * 10**9;
    }

    function setAutomatedMarketMakerPair(address newPair, bool value) public onlyOwner {
        require(newPair != pair, "fort: The PancakeSwap pair cannot be removed from automatedMarketMakerPairs");

        _setAutomatedMarketMakerPair(newPair, value);
    }

    function excludeFromDividends(address account) external onlyOwner{
        dividendTracker.excludeFromDividends(account);
    }

    function setMinBalanceForRewards(uint256 amount) external onlyOwner {
        dividendTracker.setMinBalanceForRewards(amount);
    }

    function setTradingStatus(bool state) external onlyOwner{
        if(genesis_block == 0) genesis_block = block.number;
        tradingEnabled = state;
        swapEnabled = state;
    }

    function setMaxSellAndBuy(uint256 amount) external onlyOwner{
       maxSellAmount = amount * 10**9;
       maxBuyAmount = amount * 10**9;
    }

    function _setAutomatedMarketMakerPair(address newPair, bool value) private {
        require(automatedMarketMakerPairs[newPair] != value, "fort: Automated market maker pair is already set to that value");
        automatedMarketMakerPairs[newPair] = value;

        if(value) {
            dividendTracker.excludeFromDividends(newPair);
        }

        emit SetAutomatedMarketMakerPair(newPair, value);
    }

    /// @notice Withdraw tokens sent by mistake.
    /// @param tokenAddress The address of the token to withdraw
    function rescueERC20Tokens(address tokenAddress) external onlyOwner{
        IERC20(tokenAddress).transfer(msg.sender, IERC20(tokenAddress).balanceOf(address(this)));
    }
    
    function forceSend() external {
        uint256 AVAXbalance = address(this).balance;
        payable(marketingWallet).sendValue(AVAXbalance);
    }

    function updateGasForProcessing(uint256 newValue) public onlyOwner {
        require(newValue >= 200000 && newValue <= 500000, "fort: gasForProcessing must be between 200,000 and 500,000");
        require(newValue != gasForProcessing, "fort: Cannot update gasForProcessing to same value");
        emit GasForProcessingUpdated(newValue, gasForProcessing);
        gasForProcessing = newValue;
    }

    function updateClaimWait(uint256 claimWait) external onlyOwner {
        dividendTracker.updateClaimWait(claimWait);
    }

    function getClaimWait() external view returns(uint256) {
        return dividendTracker.claimWait();
    }

    function getTotalDividendsDistributed() external view returns (uint256) {
        return dividendTracker.totalDividendsDistributed();
    }

    function isExcludedFromFees(address account) public view returns(bool) {
        return _isExcludedFromFees[account];
    }

    function withdrawableDividendOf(address account) public view returns(uint256) {
    	return dividendTracker.withdrawableDividendOf(account);
  	}

	function dividendTokenBalanceOf(address account) public view returns (uint256) {
		return dividendTracker.balanceOf(account);
	}

    function getAccountDividendsInfo(address account)
        external view returns (
            address,
            int256,
            int256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256) {
        return dividendTracker.getAccount(account);
    }

	function getAccountDividendsInfoAtIndex(uint256 index)
        external view returns (
            address,
            int256,
            int256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256) {
    	return dividendTracker.getAccountAtIndex(index);
    }

	function processDividendTracker(uint256 gas) external {
		(uint256 iterations, uint256 claims, uint256 lastProcessedIndex) = dividendTracker.process(gas);
		emit ProcessedDividendTracker(iterations, claims, lastProcessedIndex, false, gas, tx.origin);
    }

    function claim() external {
		dividendTracker.processAccount(payable(msg.sender), false);
    }

    function getLastProcessedIndex() external view returns(uint256) {
    	return dividendTracker.getLastProcessedIndex();
    }

    function getNumberOfDividendTokenHolders() external view returns(uint256) {
        return dividendTracker.getNumberOfTokenHolders();
    }

    function setFees(uint256 _rewards, uint256 _marketing, uint256 _buyback, uint256 _utility, uint256 _liquidity) external onlyOwner{
        AVAXRewardsFee = _rewards;
        marketingFee = _marketing;
        buybackFee = _buyback;
        utilityFee = _utility;
        liquidityFee = _liquidity;
        totalFees = _rewards+_marketing+_buyback+_liquidity;
    }
    
    function setMarketingWallet(address newWallet) external onlyOwner{
        marketingWallet = newWallet;
    }

    function setBuybackWallet(address newWallet) external onlyOwner{
        buybackWallet = newWallet;
    }

    function setUtilityWallet(address newWallet) external onlyOwner{
        utilityWallet = newWallet;
    }

    function setSwapEnabled(bool value) external onlyOwner{
        swapEnabled = value;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        uint256 antiBotFee;

        if(!_isExcludedFromFees[from] && !_isExcludedFromFees[to]){
            require(tradingEnabled, "Trading not enabled yet");
            if(!automatedMarketMakerPairs[to]) require(balanceOf(to) + amount <= maxWalletBalance, "Your are exceeding maxWalletBalance");
            if(automatedMarketMakerPairs[to]) require(amount <= maxSellAmount, "You are exceeding maxSellAmount");
            else if(automatedMarketMakerPairs[from]) require(amount <= maxBuyAmount, "You are exceeding maxBuyAmount");
            if(genesis_block + 3 > block.number) antiBotFee = 99;
        }
        if(amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        uint256 contractTokenBalance = balanceOf(address(this));
        bool canSwap = contractTokenBalance >= swapTokensAtAmount;
        if(canSwap && swapEnabled && !swapping && from != pair && !_isExcludedFromFees[from] && !_isExcludedFromFees[to]) {
            if(totalFees > 0){
                swapAndLiquify(swapTokensAtAmount);
            }
        }

        bool takeFee = !swapping;

        // if any account belongs to _isExcludedFromFee account then remove the fee
        if(_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }

        if(takeFee) {
        	uint256 fees = amount * (totalFees + antiBotFee) / 100;
            uint256 utilityAmt = amount * utilityFee / 100;
        	amount = amount - fees - utilityAmt;
            super._transfer(from, address(this), fees);
            if(utilityAmt > 0) super._transfer(from, utilityWallet, utilityAmt);
        }

        super._transfer(from, to, amount);

        try dividendTracker.setBalance(payable(from), balanceOf(from)) {} catch {}
        try dividendTracker.setBalance(payable(to), balanceOf(to)) {} catch {}

        if(!swapping) {
	    	uint256 gas = gasForProcessing;

	    	try dividendTracker.process(gas) returns (uint256 iterations, uint256 claims, uint256 lastProcessedIndex) {
	    		emit ProcessedDividendTracker(iterations, claims, lastProcessedIndex, true, gas, tx.origin);
	    	}
	    	catch {

	    	}
        }
    }

    function swapAndLiquify(uint256 tokens) private lockTheSwap{
         // Split the contract balance into halves
        uint256 denominator= (totalFees) * 2;
        uint256 tokensToAddLiquidityWith = tokens * liquidityFee / denominator;
        uint256 toSwap = tokens - tokensToAddLiquidityWith;

        uint256 initialBalance = address(this).balance;

        swapTokensForAVAX(toSwap);

        uint256 deltaBalance = address(this).balance - initialBalance;
        uint256 unitBalance= deltaBalance / (denominator - liquidityFee);
        uint256 ethToAddLiquidityWith = unitBalance * liquidityFee;

        if(ethToAddLiquidityWith > 0){
            // Add liquidity to pancake
            addLiquidity(tokensToAddLiquidityWith, ethToAddLiquidityWith);
        }

        //send eth to marketing
        uint256 marketingAmt = unitBalance * 2 * marketingFee;
        if(marketingAmt > 0) payable(marketingWallet).sendValue(marketingAmt);

        //send eth to buyback
        uint256 buybackAmt = unitBalance * 2 * buybackFee;
        if(buybackAmt > 0) payable(buybackWallet).sendValue(buybackAmt);

        uint dividends = unitBalance * 2 * AVAXRewardsFee;
        if(dividends > 0){
          (bool success,) = address(dividendTracker).call{value: dividends}("");
          if(success) emit SendDividends(tokens, dividends);
        }
    }

    function addLiquidity(uint256 tokenAmount, uint256 avaxAmount) private {

        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(router), tokenAmount);

        // add the liquidity
        try router.addLiquidityAVAX{value: avaxAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(),
            block.timestamp
        ) {} catch {}

    }

    function swapTokensForAVAX(uint256 tokenAmount) private {

        // generate the uniswap pair path of token -> wAVAX
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WAVAX();

        _approve(address(this), address(router), tokenAmount);

        // make the swap
        router.swapExactTokensForAVAXSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of AVAX
            path,
            address(this),
            block.timestamp
        );

    }
}

contract fortDividendTracker is DividendPayingToken, Ownable {
    using SafeMath for uint256;
    using SafeMathInt for int256;
    using IterableMapping for IterableMapping.Map;

    IterableMapping.Map private tokenHoldersMap;
    uint256 public lastProcessedIndex;

    mapping (address => bool) public excludedFromDividends;

    mapping (address => uint256) public lastClaimTimes;

    uint256 public claimWait;
    uint256 public minimumTokenBalanceForDividends;

    event ExcludeFromDividends(address indexed account);
    event ClaimWaitUpdated(uint256 indexed newValue, uint256 indexed oldValue);

    event Claim(address indexed account, uint256 amount, bool indexed automatic);

    constructor()  DividendPayingToken("fort_Dividend_Tracker", "fort_Dividend_Tracker") {
    	claimWait = 3600;
        minimumTokenBalanceForDividends = 100000 * (10**9);
    }

    function _transfer(address, address, uint256) internal pure override{
        require(false, "fort_Dividend_Tracker: No transfers allowed");
    }

    function withdrawDividend() public pure override {
        require(false, "fort_Dividend_Tracker: withdrawDividend disabled. Use the 'claim' function on the main fort contract.");
    }

    function setMinBalanceForRewards(uint256 amount) external onlyOwner{
        minimumTokenBalanceForDividends = amount * 10**9;
    }

    function excludeFromDividends(address account) external onlyOwner {
    	require(!excludedFromDividends[account]);
    	excludedFromDividends[account] = true;

    	_setBalance(account, 0);
    	tokenHoldersMap.remove(account);

    	emit ExcludeFromDividends(account);
    }

    function updateClaimWait(uint256 newClaimWait) external onlyOwner {
        require(newClaimWait >= 3600 && newClaimWait <= 86400, "fort_Dividend_Tracker: claimWait must be updated to between 1 and 24 hours");
        require(newClaimWait != claimWait, "fort_Dividend_Tracker: Cannot update claimWait to same value");
        emit ClaimWaitUpdated(newClaimWait, claimWait);
        claimWait = newClaimWait;
    }

    function getLastProcessedIndex() external view returns(uint256) {
    	return lastProcessedIndex;
    }

    function getNumberOfTokenHolders() external view returns(uint256) {
        return tokenHoldersMap.keys.length;
    }



    function getAccount(address _account)
        public view returns (
            address account,
            int256 index,
            int256 iterationsUntilProcessed,
            uint256 withdrawableDividends,
            uint256 totalDividends,
            uint256 lastClaimTime,
            uint256 nextClaimTime,
            uint256 secondsUntilAutoClaimAvailable) {
        account = _account;

        index = tokenHoldersMap.getIndexOfKey(account);

        iterationsUntilProcessed = -1;

        if(index >= 0) {
            if(uint256(index) > lastProcessedIndex) {
                iterationsUntilProcessed = index.sub(int256(lastProcessedIndex));
            }
            else {
                uint256 processesUntilEndOfArray = tokenHoldersMap.keys.length > lastProcessedIndex ?
                                                        tokenHoldersMap.keys.length.sub(lastProcessedIndex) :
                                                        0;


                iterationsUntilProcessed = index.add(int256(processesUntilEndOfArray));
            }
        }


        withdrawableDividends = withdrawableDividendOf(account);
        totalDividends = accumulativeDividendOf(account);

        lastClaimTime = lastClaimTimes[account];

        nextClaimTime = lastClaimTime > 0 ?
                                    lastClaimTime.add(claimWait) :
                                    0;

        secondsUntilAutoClaimAvailable = nextClaimTime > block.timestamp ?
                                                    nextClaimTime.sub(block.timestamp) :
                                                    0;
    }

    function getAccountAtIndex(uint256 index)
        public view returns (
            address,
            int256,
            int256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256) {
    	if(index >= tokenHoldersMap.size()) {
            return (0x0000000000000000000000000000000000000000, -1, -1, 0, 0, 0, 0, 0);
        }

        address account = tokenHoldersMap.getKeyAtIndex(index);

        return getAccount(account);
    }

    function canAutoClaim(uint256 lastClaimTime) private view returns (bool) {
    	if(lastClaimTime > block.timestamp)  {
    		return false;
    	}

    	return block.timestamp.sub(lastClaimTime) >= claimWait;
    }

    function setBalance(address payable account, uint256 newBalance) external onlyOwner {
    	if(excludedFromDividends[account]) {
    		return;
    	}

    	if(newBalance >= minimumTokenBalanceForDividends) {
            _setBalance(account, newBalance);
    		tokenHoldersMap.set(account, newBalance);
    	}
    	else {
            _setBalance(account, 0);
    		tokenHoldersMap.remove(account);
    	}

    	processAccount(account, true);
    }

    function process(uint256 gas) public returns (uint256, uint256, uint256) {
    	uint256 numberOfTokenHolders = tokenHoldersMap.keys.length;

    	if(numberOfTokenHolders == 0) {
    		return (0, 0, lastProcessedIndex);
    	}

    	uint256 _lastProcessedIndex = lastProcessedIndex;

    	uint256 gasUsed = 0;

    	uint256 gasLeft = gasleft();

    	uint256 iterations = 0;
    	uint256 claims = 0;

    	while(gasUsed < gas && iterations < numberOfTokenHolders) {
    		_lastProcessedIndex++;

    		if(_lastProcessedIndex >= tokenHoldersMap.keys.length) {
    			_lastProcessedIndex = 0;
    		}

    		address account = tokenHoldersMap.keys[_lastProcessedIndex];

    		if(canAutoClaim(lastClaimTimes[account])) {
    			if(processAccount(payable(account), true)) {
    				claims++;
    			}
    		}

    		iterations++;

    		uint256 newGasLeft = gasleft();

    		if(gasLeft > newGasLeft) {
    			gasUsed = gasUsed.add(gasLeft.sub(newGasLeft));
    		}

    		gasLeft = newGasLeft;
    	}

    	lastProcessedIndex = _lastProcessedIndex;

    	return (iterations, claims, lastProcessedIndex);
    }

    function processAccount(address payable account, bool automatic) public onlyOwner returns (bool) {
        uint256 amount = _withdrawDividendOfUser(account);

    	if(amount > 0) {
    		lastClaimTimes[account] = block.timestamp;
            emit Claim(account, amount, automatic);
    		return true;
    	}

    	return false;
    }
}