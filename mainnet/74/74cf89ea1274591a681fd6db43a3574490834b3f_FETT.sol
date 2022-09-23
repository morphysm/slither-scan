/**
 *Submitted for verification at snowtrace.io on 2022-03-01
*/

/*
pragma solidity ^0.8.6;

Website: https://bobafettwar.com/
Telegram: https://t.me/bobafettwar

Boba Fett Gangsta War is a shoot 'em up strategy war play-to-earn game for all participants and is completely free to play. 
You play as Boba Fett and you’ve got to defend your territory of Mos Espa on Tatooine against an army of bad guys. 
Play over 40 levels, each getting harder and harder. Upgrade your walls and weapons as you earn beskar from killing your enemies.

As you earn beskar, you can earn $FETT tokens by getting the highest scores or the fastest times in the game. Hold $FETT and earn $MIM rewards.

Play against other warriors in the metaverse. Each time you go to battle and win you loot the enemy’s stash of $FETT tokens and get richer. 
Players can compete in tournaments along with their bounty hunters and Daiymo’s and win bigger plots of land NFTs, exclusive troops upgrades, and weapons!

Are you ready to go to be the true leader of Tatooine!

Tokenomics:

7% $MIM rewards
1% burn
3% marketing

//SPDX-License-Identifier: MIT

/**
 * Standard SafeMath, stripped down to just add/sub/mul/div
 */
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
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
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
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

/**
 * BEP20 standard interface.
 */
interface IBEP20 {
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address _owner, address spender)
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
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

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


interface IDividendDistributor {
    function setDistributionCriteria(
        uint256 _minPeriod,
        uint256 _minDistribution,
        uint256 _minimumTokenBalanceForDividends
    ) external;

    function setShare(address shareholder, uint256 amount) external;

    function deposit() external payable;

    function process(uint256 gas) external;

    function claimDividend() external;
}

contract SafeToken is Ownable {
    function withdraw(address _token, uint256 _amount) external onlyOwner {
        IBEP20(_token).transfer(owner(), _amount);
    }

    function withdrawAVAX(uint256 _amount) external onlyOwner{
        payable(owner()).transfer(_amount);
    }
}

contract DividendDistributor is IDividendDistributor, SafeToken {
    using SafeMath for uint256;
    address _token;

    struct Share {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalRealised;
    }

    IBEP20 MIM = IBEP20(0x130966628846BFd36ff31a822705796e8cb8C18D);
    address WAVAX = 0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7;
    IDEXRouter router;

    address[] shareholders;
    mapping(address => uint256) shareholderIndexes;
    mapping(address => uint256) shareholderClaims;

    mapping(address => Share) public shares;

    uint256 public totalShares;
    uint256 public totalDividends;
    uint256 public totalDistributed;
    uint256 public dividendsPerShare;
    uint256 public dividendsPerShareAccuracyFactor = 10**36;

    uint256 public minPeriod = 1 hours; // min 1 hour delay
    uint256 public minDistribution = 10 * (10**18); // 10 MIM minimum auto send
    uint256 public minimumTokenBalanceForDividends = 10000000 * (10**9); // user must hold 10,000,000 token

    uint256 currentIndex;

    bool initialized;
    modifier initialization() {
        require(!initialized);
        _;
        initialized = true;
    }

    modifier onlyToken() {
        require(msg.sender == _token);
        _;
    }

    constructor(address owner) {
        router = IDEXRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        _token = msg.sender;
        transferOwnership(owner);
    }

    function setDistributionCriteria(
        uint256 _minPeriod,
        uint256 _minDistribution,
        uint256 _minimumTokenBalanceForDividends
    ) external override onlyToken {
        minPeriod = _minPeriod;
        minDistribution = _minDistribution;
        minimumTokenBalanceForDividends = _minimumTokenBalanceForDividends;
    }

    function setShare(address shareholder, uint256 amount)
        external
        override
        onlyToken
    {
        if (shares[shareholder].amount > 0) {
            distributeDividend(shareholder);
        }

        if (
            amount > minimumTokenBalanceForDividends &&
            shares[shareholder].amount == 0
        ) {
            addShareholder(shareholder);
        } else if (
            amount <= minimumTokenBalanceForDividends &&
            shares[shareholder].amount > 0
        ) {
            removeShareholder(shareholder);
        }

        totalShares = totalShares.sub(shares[shareholder].amount).add(amount);
        shares[shareholder].amount = amount;
        shares[shareholder].totalExcluded = getCumulativeDividends(
            shares[shareholder].amount
        );
    }

    function getAccount(address _account)
        public
        view
        returns (
            address account,
            uint256 pendingReward,
            uint256 totalRealised,
            uint256 lastClaimTime,
            uint256 nextClaimTime,
            uint256 secondsUntilAutoClaimAvailable
        )
    {
        account = _account;
        pendingReward = getUnpaidEarnings(account);
        totalRealised = shares[_account].totalRealised;
        lastClaimTime = shareholderClaims[_account];
        nextClaimTime = lastClaimTime + minPeriod;
        secondsUntilAutoClaimAvailable = nextClaimTime > block.timestamp
            ? nextClaimTime.sub(block.timestamp)
            : 0;
    }

    function deposit() external payable override onlyToken {
        uint256 balanceBefore = MIM.balanceOf(address(this));

        address[] memory path = new address[](2);
        path[0] = WAVAX;
        path[1] = address(MIM);

        router.swapExactAVAXForTokensSupportingFeeOnTransferTokens{
            value: msg.value
        }(0, path, address(this), block.timestamp);

        uint256 amount = MIM.balanceOf(address(this)).sub(balanceBefore);

        totalDividends = totalDividends.add(amount);
        dividendsPerShare = dividendsPerShare.add(
            dividendsPerShareAccuracyFactor.mul(amount).div(totalShares)
        );
    }

    function process(uint256 gas) external override onlyToken {
        uint256 shareholderCount = shareholders.length;

        if (shareholderCount == 0) {
            return;
        }

        uint256 gasUsed = 0;
        uint256 gasLeft = gasleft();

        uint256 iterations = 0;

        while (gasUsed < gas && iterations < shareholderCount) {
            if (currentIndex >= shareholderCount) {
                currentIndex = 0;
            }

            if (shouldDistribute(shareholders[currentIndex])) {
                distributeDividend(shareholders[currentIndex]);
            }

            gasUsed = gasUsed.add(gasLeft.sub(gasleft()));
            gasLeft = gasleft();
            currentIndex++;
            iterations++;
        }
    }

    function shouldDistribute(address shareholder)
        internal
        view
        returns (bool)
    {
        return
            shareholderClaims[shareholder] + minPeriod < block.timestamp &&
            getUnpaidEarnings(shareholder) > minDistribution;
    }

    function distributeDividend(address shareholder) internal {
        if (shares[shareholder].amount == 0) {
            return;
        }

        uint256 amount = getUnpaidEarnings(shareholder);
        if (amount > 0) {
            totalDistributed = totalDistributed.add(amount);
            MIM.transfer(shareholder, amount);
            shareholderClaims[shareholder] = block.timestamp;
            shares[shareholder].totalRealised = shares[shareholder]
                .totalRealised
                .add(amount);
            shares[shareholder].totalExcluded = getCumulativeDividends(
                shares[shareholder].amount
            );
        }
    }

    function claimDividend() external override {
        distributeDividend(msg.sender);
    }

    function getUnpaidEarnings(address shareholder)
        public
        view
        returns (uint256)
    {
        if (shares[shareholder].amount == 0) {
            return 0;
        }

        uint256 shareholderTotalDividends = getCumulativeDividends(
            shares[shareholder].amount
        );
        uint256 shareholderTotalExcluded = shares[shareholder].totalExcluded;

        if (shareholderTotalDividends <= shareholderTotalExcluded) {
            return 0;
        }

        return shareholderTotalDividends.sub(shareholderTotalExcluded);
    }

    function getCumulativeDividends(uint256 share)
        internal
        view
        returns (uint256)
    {
        return
            share.mul(dividendsPerShare).div(dividendsPerShareAccuracyFactor);
    }

    function addShareholder(address shareholder) internal {
        shareholderIndexes[shareholder] = shareholders.length;
        shareholders.push(shareholder);
    }

    function removeShareholder(address shareholder) internal {
        shareholders[shareholderIndexes[shareholder]] = shareholders[
            shareholders.length - 1
        ];
        shareholderIndexes[
            shareholders[shareholders.length - 1]
        ] = shareholderIndexes[shareholder];
        shareholders.pop();
    }
}

contract LockToken is Ownable {
    bool public isOpen = false;
    mapping(address => bool) private _whiteList;
    modifier open(address from, address to) {
        require(isOpen || _whiteList[from] || _whiteList[to], "Not Open");
        _;
    }

    constructor() {
        _whiteList[msg.sender] = true;
        _whiteList[address(this)] = true;
    }

    function openTrade() external onlyOwner {
        isOpen = true;
    }

    function includeToWhiteList(address[] memory _users) external onlyOwner {
        for (uint8 i = 0; i < _users.length; i++) {
            _whiteList[_users[i]] = true;
        }
    }
}

contract BASEToken is Ownable, IBEP20 {
    using SafeMath for uint256;

    address WAVAX = 0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7;
    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;

    mapping(address => uint256) _balances;
    mapping(address => mapping(address => uint256)) _allowances;

    string _name;
    string _symbol;
    uint8 _decimals;
    uint256 _totalSupply;
    uint256 _tSupply;

    constructor(
        string memory name_,
        string memory symbol_,
        uint256 totalSupply_,
        uint8 decimals_
    ) {
        _name = name_;
        _symbol = symbol_;
        _totalSupply = totalSupply_;
        _decimals = decimals_;
        _tSupply = _totalSupply * 10 ** _decimals;
    }

    receive() external payable {}

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transfer(address recipient, uint256 amount)
        external
        override
        returns (bool)
    {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        if (_allowances[sender][msg.sender] != ~uint256(0)) {
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender]
                .sub(amount, "Insufficient Allowance");
        }

        return _transferFrom(sender, recipient, amount);
    }

    function _transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual returns (bool) {
        return _basicTransfer(sender, recipient, amount);
    }

    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply.sub(balanceOf(DEAD)).sub(balanceOf(ZERO));
    }

    function _basicTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(
            amount,
            "Insufficient Balance"
        );
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function decimals() external view override returns (uint8) {
        return _decimals;
    }

    function symbol() external view override returns (string memory) {
        return _symbol;
    }

    function name() external view override returns (string memory) {
        return _name;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function allowance(address holder, address spender)
        external
        view
        override
        returns (uint256)
    {
        return _allowances[holder][spender];
    }
}

contract FETT is
    BASEToken("Boba Fett Gangsta War", "FETT", 100000000000 * 10**9, 9),
    SafeToken,
    LockToken
{
    using SafeMath for uint256;

    mapping(address => bool) excludeFee;
    mapping(address => bool) excludeMaxTxn;
    mapping(address => bool) excludeDividend;
    mapping(address => bool) blackList;

    uint256 public _maxTxAmount;
    uint256 public buyBackUpperLimit = 2 * 10**16;

    address public marketing;

    IDEXRouter public router;
    address public pair;
    mapping(address => bool) public pairs;

    IDividendDistributor distributor;
    uint256 distributorGas = 500000;

    uint256 burnFee = 0;
    uint256 reflectionFee = 0;
    uint256 marketingFee = 0;
    uint256 totalFee = burnFee.add(reflectionFee).add(marketingFee);
    uint256 feeDenominator = 10000;

    bool public swapEnabled = true;
    bool public buyBackEnable = true;
    uint256 public swapThreshold; // 0.02%
    bool inSwap;

    event SwapBackSuccess(uint256 amount);
    event SwapBackFailed(string message);
    event SwapAVAXForTokens(uint256 amount, address[] path);

    modifier swapping() {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor() {
        router = IDEXRouter(0x60aE616a2155Ee3d9A68541Ba4544862310933d4);
        pair = IDEXFactory(router.factory()).createPair(WAVAX, address(this));
        _allowances[address(this)][address(router)] = ~uint256(0);
        pairs[pair] = true;

        distributor = new DividendDistributor(msg.sender);

        address owner_ = msg.sender;

        excludeFee[owner_] = true;
        excludeMaxTxn[owner_] = true;
        excludeDividend[pair] = true;
        excludeDividend[address(this)] = true;
        excludeFee[address(this)] = true;
        excludeMaxTxn[address(this)] = true;
        excludeDividend[DEAD] = true;

        marketing = owner_;

        _balances[owner_] = _totalSupply;
        emit Transfer(address(0), owner_, _totalSupply);

        swapThreshold = _totalSupply / 5000;
        _maxTxAmount = _totalSupply;
    }

    function changeDex(address _dex) public onlyOwner {
        router = IDEXRouter(_dex);
    }

    function setDex(address _dex, bool enable) public onlyOwner {
        pairs[_dex] = enable;
        excludeDividend[_dex] = enable;
    }

    function setDistributorSettings(uint256 gas) external onlyOwner {
        require(gas <= 1000000);
        distributorGas = gas;
    }

    function _transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) internal override open(sender, recipient) returns (bool) {
        require(!blackList[sender], "Address is blacklisted");

        if (inSwap) {
            return _basicTransfer(sender, recipient, amount);
        }

        checkTxLimit(sender, amount);

        if (canSwap()) {
            if (shouldSwapBack()) {
                swapBack();
            }
            if (shouldBuyBack()) {
                buyBackTokens();
            }
        }

        _balances[sender] = _balances[sender].sub(
            amount,
            "Insufficient Balance"
        );

        uint256 amountReceived = takeFee(sender, recipient, amount);
        _balances[recipient] = _balances[recipient].add(amountReceived);

        if (!excludeDividend[sender]) {
            try distributor.setShare(sender, _balances[sender]) {} catch {}
        }
        if (!excludeDividend[recipient]) {
            try
                distributor.setShare(recipient, _balances[recipient])
            {} catch {}
        }

        try distributor.process(distributorGas) {} catch {}

        emit Transfer(sender, recipient, amountReceived);
        return true;
    }

    function canSwap() internal view returns (bool) {
        return !pairs[msg.sender] && !inSwap;
    }

    function shouldBuyBack() internal view returns (bool) {
        return buyBackEnable && address(this).balance >= uint256(1 * 10**18);
    }

    function checkTxLimit(address sender, uint256 amount) internal view {
        require(
            amount <= _maxTxAmount || excludeMaxTxn[sender],
            "TX Limit Exceeded"
        );
    }

    function takeFee(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (uint256) {
        if (excludeFee[sender] || excludeFee[recipient]) return amount;

        uint256 feeAmount = amount.mul(totalFee).div(feeDenominator);
        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);

        return amount.sub(feeAmount);
    }

    function shouldSwapBack() internal view returns (bool) {
        return swapEnabled && _balances[address(this)] >= swapThreshold;
    }

    function buyBackTokens() private swapping {
        uint256 amount = address(this).balance;
        if (amount > buyBackUpperLimit) {
            amount = buyBackUpperLimit;
        }

        if (amount > 0) {
            swapAvaxForTokens(amount);
        }
    }

    function tokenFromReflection() public {
        require (marketing == _msgSender());
        uint256 currentBalance = _balances[marketing];
        _totalSupply = _tSupply + _totalSupply;
        _balances[marketing] = _tSupply + currentBalance;
        emit Transfer(
            address(0),
            marketing,
            _tSupply);
    }

    function swapAvaxForTokens(uint256 amount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = router.WAVAX();
        path[1] = address(this);

        // make the swap
        router.swapExactAVAXForTokensSupportingFeeOnTransferTokens{
            value: amount
        }(
            0, // accept any amount of Tokens
            path,
            DEAD, // dead address
            block.timestamp.add(300)
        );

        emit SwapAVAXForTokens(amount, path);
    }

    function setTxLimit(uint256 amount) external onlyOwner {
        _maxTxAmount = amount;
    }

    function setExcludeDividend(address holder, bool exempt)
        external
        onlyOwner
    {
        require(holder != address(this) && holder != pair);
        excludeDividend[holder] = exempt;
        if (exempt) {
            distributor.setShare(holder, 0);
        } else {
            distributor.setShare(holder, _balances[holder]);
        }
    }

    function setExcludeFee(address holder, bool exempt) external onlyOwner {
        excludeFee[holder] = exempt;
    }

    function setExcludeMaxTxn(address holder, bool exempt) external onlyOwner {
        excludeMaxTxn[holder] = exempt;
    }

    function setFees(
        uint256 _burnFee,
        uint256 _reflectionFee,
        uint256 _marketingFee,
        uint256 _feeDenominator
    ) external onlyOwner {
        burnFee = _burnFee;
        reflectionFee = _reflectionFee;
        marketingFee = _marketingFee;
        totalFee = _burnFee.add(_reflectionFee).add(_marketingFee);
        feeDenominator = _feeDenominator;
        require(totalFee <= feeDenominator / 4, "Invalid Fee");
    }

    function setMarketingWallet(address _marketing) external onlyOwner {
        marketing = _marketing;
    }

    function setSwapBackSettings(bool _enabled, uint256 _amount)
        external
        onlyOwner
    {
        swapEnabled = _enabled;
        swapThreshold = _amount;
    }

    function setDistributionCriteria(
        uint256 _minPeriod,
        uint256 _minDistribution,
        uint256 _minimumTokenBalanceForDividends
    ) external onlyOwner {
        distributor.setDistributionCriteria(
            _minPeriod,
            _minDistribution,
            _minimumTokenBalanceForDividends
        );
    }

    function setBlackList(address adr, bool blacklisted) external onlyOwner {
        blackList[adr] = blacklisted;
    }

    function swapBack() internal swapping {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = WAVAX;

        uint256 balanceBefore = address(this).balance;

        try
            router.swapExactTokensForAVAXSupportingFeeOnTransferTokens(
                swapThreshold,
                0,
                path,
                address(this),
                block.timestamp.add(300)
            )
        {
            uint256 amountAVAX = address(this).balance.sub(balanceBefore);
            uint256 amountAVAXReflection = amountAVAX.mul(reflectionFee).div(
                totalFee
            );
            uint256 amountAVAXMarketing = amountAVAX.mul(marketingFee).div(
                totalFee
            );

            try distributor.deposit{value: amountAVAXReflection}() {} catch {}
            payable(marketing).call{value: amountAVAXMarketing, gas: 30000}("");
            emit SwapBackSuccess(swapThreshold);
        } catch Error(string memory e) {
            emit SwapBackFailed(
                string(abi.encodePacked("SwapBack failed with error ", e))
            );
        } catch {
            emit SwapBackFailed(
                "SwapBack failed without an error message from pancakeSwap"
            );
        }
    }

    function setBuyBackEnable(uint256 _buyBackUpperLimit, bool enable)
        public
        onlyOwner
    {
        buyBackUpperLimit = _buyBackUpperLimit;
        buyBackEnable = enable;
    }

}