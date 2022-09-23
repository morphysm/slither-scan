/**
                                                                                                                                                                                    
.______        ______   .______     ______    _______   ______     _______  _______      ______   ______    __  .__   __. 
|   _  \      /  __  \  |   _  \   /  __  \  |       \ /  __  \   /  _____||   ____|    /      | /  __  \  |  | |  \ |  | 
|  |_)  |    |  |  |  | |  |_)  | |  |  |  | |  .--.  |  |  |  | |  |  __  |  |__      |  ,----'|  |  |  | |  | |   \|  | 
|      /     |  |  |  | |   _  <  |  |  |  | |  |  |  |  |  |  | |  | |_ | |   __|     |  |     |  |  |  | |  | |  . `  | 
|  |\  \----.|  `--'  | |  |_)  | |  `--'  | |  '--'  |  `--'  | |  |__| | |  |____    |  `----.|  `--'  | |  | |  |\   | 
| _| `._____| \______/  |______/   \______/  |_______/ \______/   \______| |_______|    \______| \______/  |__| |__| \__| 
                                                                                                                                                                                                             '              '                   '                                                                                                                                             
*/

pragma solidity ^0.8.3;

// SPDX-License-Identifier: MIT

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */

 import '@openzeppelin/contracts/access/Ownable.sol';
 import '@openzeppelin/contracts/utils/math/SafeMath.sol';
  import '@openzeppelin/contracts/utils/Address.sol';


/**
 * @dev Interface of the BEP20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */


contract RoboDogeCoin is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    string private _name = "RoboDoge Coin";
    string private _symbol = "ROBODOGE";
    uint8 private _decimals = 9;

    uint256 constant private DENOMINATOR = 10000;
    
    mapping(address => uint256) internal _reflectionBalance;
    mapping(address => uint256) internal _tokenBalance;
    mapping(address => mapping(address => uint256)) internal _allowances;
    
    uint256 private constant MAX = ~uint256(0);
    uint256 internal _tokenTotal = 420 *10**24; //
    uint256 internal _reflectionTotal = (MAX - (MAX % _tokenTotal));
    
    mapping(address => bool) isExcludedFromFee;
    mapping(address => bool) internal _isExcluded;
    address[] internal _excluded;
    // fees
    uint256 public _taxFee = 0; // 100 = 1% [PRESALE]
    uint256 public _charityFee = 0; // 100 = 1% [PRESALE]
    uint256 public _burnFee = 0; // 100 = 1% [PRESALE] 
    uint256 public _liquidityFee = 0; // 100 = 1% [PRESALE]
    uint256 public _marketingFee = 0; // 100 = 1% [PRESALE]
    uint256 public _earlySellFee = 0;
    //var
    uint256 public _charityFeeTotal;
    uint256 public _burnFeeTotal;
    uint256 public _taxFeeTotal;
    uint256 public _liquidityFeeTotal;
    uint256 public _marketingFeeTotal;
    uint256 public _earlySellFeeTotal;

    //addresses
    address public charityAddress; // Charity Address
    address public routerAddress; // PancakeSwapRouterV2
    address public marketingFeeAddress; // marketing wallet
    address public liquidityManager; // address which will manually add liquidity to pool
    
    event RewardsDistributed(uint256 amount);

    mapping(address => bool) public isLiquidityPoolAddress;

    bool public lockTransfer;
    uint public HaltDuration;
    uint public HaltStartTime;
    // Anti-dumping settings
    struct UserInfo {
        uint256 firstSellTime;
        uint256 amountSpent;
        uint256 spendLimit;
    }
    uint256 public threshold;
    uint256 public rule;
    uint256 public restrictionDuration;
    address public reservePoolAddress;

    mapping(address => UserInfo) public userInfos;

    bool public forceEop;

    // Set limit on addresses
    struct LimitInfo {
        address account;
        uint256 end;
        uint256 period;
        uint256 rule;
        uint256 spendLimit;
        uint256 amountSpent;
    }

    mapping(address => uint256) public lockedTill;
    mapping(address => LimitInfo) public limitInfos;
    // Keep track of first buy time
    mapping(address => uint256) public firstBuy;

    modifier isUnlocked(address _address) {
        require(lockedTill[_address] == 0, "Address is already locked");
        _;
    }

    constructor() {
        
        isExcludedFromFee[_msgSender()] = true;
        isExcludedFromFee[address(this)] = true;
        
        _reflectionBalance[_msgSender()] = _reflectionTotal;
        emit Transfer(address(0), _msgSender(), _tokenTotal);
        _moveDelegates(address(0), _msgSender(), _tokenTotal);
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

    function totalSupply() public override view returns (uint256) {
        return _tokenTotal;
    }

    function balanceOf(address account) public override view returns (uint256) {
        if (_isExcluded[account]) return _tokenBalance[account];
        return tokenFromReflection(_reflectionBalance[account]);
    }

    function transfer(address recipient, uint256 amount) public override virtual returns (bool) {
       _transfer(_msgSender(),recipient,amount);
        return true;
    }

    function allowance(address _owner, address spender) public override view returns (uint256) {
        return _allowances[_owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override virtual returns (bool) {
        _transfer(sender,recipient,amount);
               
        _approve(sender,_msgSender(),_allowances[sender][_msgSender()].sub( amount,"ERC20: transfer amount exceeds allowance"));
        return true;
    }  

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function isExcluded(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    function reflectionFromToken(uint256 tokenAmount, bool deductTransferFee) public view returns (uint256) {
        require(tokenAmount <= _tokenTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            return tokenAmount.mul(_getReflectionRate());
        } else {
            return tokenAmount.sub(tokenAmount.mul(_taxFee).div(DENOMINATOR)).mul(_getReflectionRate());
        }
    }

    function tokenFromReflection(uint256 reflectionAmount) public view returns (uint256) {
        require(reflectionAmount <= _reflectionTotal, "Amount must be less than total reflections");
        uint256 currentRate = _getReflectionRate();
        return reflectionAmount.div(currentRate);
    }

    function excludeAccount(address account) public onlyOwner {
        require(account != routerAddress,"ROBODOGE: Uniswap router cannot be excluded.");
        require(account != address(this), 'ROBODOGE: The contract it self cannot be excluded');
        require(!_isExcluded[account], "ROBODOGE: Account is already excluded");
        if (_reflectionBalance[account] > 0) {
            _tokenBalance[account] = tokenFromReflection(
                _reflectionBalance[account]
            ); 
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function includeAccount(address account) public onlyOwner {
        require(_isExcluded[account], "ROBODOGE: Account is already included");
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _tokenBalance[account] = 0;
                _isExcluded[account] = false;
                _excluded.pop();
                break;
            }
        }
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address sender, address recipient, uint256 amount) private isUnlocked(sender) isUnlocked(recipient) {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        // require(!lockTransfer || msg.sender == owner(), "Transfers are locked");
        require(!lockTransfer || msg.sender == owner(), "Transfers are halted");

        (bool isValid, string memory limitMessage) = isWithinLimit(sender, amount);
        require(isValid, limitMessage);

        uint256 transferAmount = amount;
        uint256 rate = _getReflectionRate();

        if(
            !isExcludedFromFee[sender] &&
            !isExcludedFromFee[recipient] &&
            isLiquidityPoolAddress[recipient]
        ) {
            transferAmount = collectFee(sender,amount,rate);
        }

        //@dev Transfer reflection
        _reflectionBalance[sender] = _reflectionBalance[sender].sub(amount.mul(rate));
        _reflectionBalance[recipient] = _reflectionBalance[recipient].add(transferAmount.mul(rate));
        _moveDelegates(_delegates[sender], _delegates[recipient], transferAmount.mul(rate));

        if (firstBuy[recipient] == 0) {
            firstBuy[recipient] = block.timestamp;
        }

        //@dev If any account belongs to the excludedAccount transfer token
        if (_isExcluded[sender]) {
            _tokenBalance[sender] = _tokenBalance[sender].sub(amount);
        }
        if (_isExcluded[recipient]) {
            _tokenBalance[recipient] = _tokenBalance[recipient].add(transferAmount);
        }
        
        emit Transfer(sender, recipient, transferAmount);
    }

    function setReservePool(address _address) external onlyOwner {
        require(_address != reservePoolAddress, "New reserve pool address must different");
        reservePoolAddress = _address;
        isExcludedFromFee[_address] = true;
    }

    function setLiquidityPoolAddress(address _address, bool _add) external onlyOwner {
        require(isLiquidityPoolAddress[_address] != _add, "Change address status");
        isLiquidityPoolAddress[_address] = _add;
    }

    function setThreshold(uint256 _threshold) external onlyOwner {
        threshold = _threshold;
    }

    function setRule(uint256 _rule) external onlyOwner {
        rule = _rule;
    }

    function setRestrictionDuration(uint256 _minutes) external onlyOwner {
        restrictionDuration = _minutes * 1 minutes;
    }

    function enforceAntiDumping(address sender, uint256 amount) private returns (bool, string memory) {
        UserInfo storage userInfo = userInfos[sender];
        uint256 balance = balanceOf(sender);

        if (isLiquidityPoolAddress[sender]) {
            return (true, "");
        }

        // if balance is above threshold
        if (balanceOf(sender) >= threshold && sender != owner()) {
            if (block.timestamp > userInfo.firstSellTime + restrictionDuration) {
                // first order within the last 24 hours
                // calculate spend limit acc to rule
                // initialize the user info

                uint256 spendLimit = balance.mul(rule).div(DENOMINATOR);
                if (amount > spendLimit) {
                    return (false, "Amount exceeds spend limit");
                }

                userInfo.firstSellTime = block.timestamp;
                userInfo.amountSpent = amount;
                userInfo.spendLimit = spendLimit;
            } else {
                // not the first order within the last 24 hours
                // check amount spent to be less than or equal to spend limit
                // update the amount spent

                if (userInfo.amountSpent.add(amount) > userInfo.spendLimit) {
                    return (false, "Amount exceeds spend limit");
                }
                userInfo.amountSpent = userInfo.amountSpent.add(amount);
            }
        } else if (block.timestamp <= userInfo.firstSellTime + restrictionDuration) {
            // even if balance is less than threshold
            // if user has order in the last 24 hours
            // check amount spent to be less than or equal to spend limit
            // update the amount spent

            if (userInfo.amountSpent.add(amount) > userInfo.spendLimit) {
                return (false, "Amount exceeds spend limit");
            }
            userInfo.amountSpent = userInfo.amountSpent.add(amount);
        }
        
        return (true, "");
    }

    function toggleForceEop() external onlyOwner {
        forceEop = !forceEop;
    }

    // function toggleLockTransfer() external onlyOwner {
    //     lockTransfer = !lockTransfer;
    // }
    
    function haltTransfer(uint _period) external onlyOwner {
        require(!lockTransfer, "Transfers are already locked");
        HaltDuration = _period;
        HaltStartTime = block.timestamp;
        lockTransfer = true;
    }

    function unhaltTransfer() external onlyOwner {
        require(lockTransfer, "Transfers are not halted");
        require(HaltStartTime + HaltDuration <= block.timestamp, "Cannot unlock before locked time");
        HaltDuration = 0;
        HaltStartTime = 0;
        lockTransfer = false;
    }

    function lock(address _address, uint256 _days) external isUnlocked(_address) onlyOwner {
        lockedTill[_address] = block.timestamp + _days * 1 days;
        excludeAccount(_address);
    }

    function unlock(address _address) external {
        require(block.timestamp > lockedTill[_address] || msg.sender == owner(), "Cannot unlock before locked time");
        require(lockedTill[_address] > 0, "Address is already unlocked");
        lockedTill[_address] = 0;
        includeAccount(_address);
    }

    function isWithinLimit(address _address, uint256 _amount) private returns (bool, string memory) {
        LimitInfo storage limit = limitInfos[_address];

        if (limitInfos[_address].account != _address) {
            return (
                true, ""
            );
        }

        if (block.timestamp <= limit.end) {
            if (limit.amountSpent.add(_amount) > limit.spendLimit) {
                return (
                    false, "Amount exceeds limit"
                );
            } else {
                limit.amountSpent = limit.amountSpent.add(_amount);
            }
        } else {
            uint256 max = balanceOf(_address).mul(limit.rule).div(DENOMINATOR);
            if (_amount <= max) {
                limit.spendLimit = max;
                limit.amountSpent = _amount;
                limit.end = block.timestamp + limit.period * 1 days;
            } else {
                return (
                    false, "Amount exceeds limit"
                );
            }
        }

        return (
            true, ""
        );
    }

    function setLimit(address _address, uint256 _period, uint256 _rule) external onlyOwner {
        limitInfos[_address] = LimitInfo(_address, 0, _period, _rule, 0, 0);
    }

    function removeLimit(address _address) external onlyOwner {
        delete limitInfos[_address];
    }

    function mint(uint256 amount) external {
        require(_msgSender() == reservePoolAddress);

        uint256 rate = _getReflectionRate();
        _reflectionBalance[_msgSender()] = _reflectionBalance[_msgSender()].add(amount * rate);
        _reflectionTotal = _reflectionTotal.add(amount * rate);
        _tokenTotal = _tokenTotal.add(amount);

        _moveDelegates(_delegates[address(0)], _delegates[msg.sender], amount);
        emit Transfer(address(0), _msgSender(), amount);
    }

    function burn(uint256 amount) external {
        uint256 rate = _getReflectionRate();
        _reflectionBalance[msg.sender] = _reflectionBalance[msg.sender].sub(amount * rate, "ERC20: burn amount exceeds balance");
        _reflectionTotal = _reflectionTotal.sub(amount * rate);
        _tokenTotal = _tokenTotal.sub(amount);
        _moveDelegates(_delegates[msg.sender], _delegates[address(0)], amount);
        emit Transfer(msg.sender, address(0), amount);
    }

    function collectFee(address account, uint256 amount, uint256 rate) private returns (uint256) {
        
        uint256 transferAmount = amount;
        
        uint256 charityFee = amount.mul(_charityFee).div(DENOMINATOR);
        uint256 liquidityFee = amount.mul(_liquidityFee).div(DENOMINATOR);
        uint256 taxFee = amount.mul(_taxFee).div(DENOMINATOR);
        uint256 burnFee = amount.mul(_burnFee).div(DENOMINATOR);
        uint256 marketingFee = amount.mul(_marketingFee).div(DENOMINATOR);

        // DEDUCTS EXTRA 17% IF POSITION SOLD WITHIN ONE WEEK OF OPENING
        if (block.timestamp <= firstBuy[account] + 1 weeks) {
            uint256 extraTax = amount.mul(_earlySellFee).div(DENOMINATOR);
            transferAmount = transferAmount.sub(extraTax);
            _reflectionBalance[reservePoolAddress] = _reflectionBalance[reservePoolAddress].add(extraTax.mul(rate));
            _earlySellFeeTotal = _earlySellFeeTotal.add(extraTax);
            emit Transfer(account, reservePoolAddress, extraTax);
        }
        if (taxFee > 0) {
            transferAmount = transferAmount.sub(taxFee);
            _reflectionTotal = _reflectionTotal.sub(taxFee.mul(rate));
            _taxFeeTotal = _taxFeeTotal.add(taxFee);
            emit RewardsDistributed(taxFee);
        }

        if(charityFee > 0){
            transferAmount = transferAmount.sub(charityFee);
            _reflectionBalance[charityAddress] = _reflectionBalance[charityAddress].add(charityFee.mul(rate));
            _charityFeeTotal = _charityFeeTotal.add(charityFee);
            emit Transfer(account, charityAddress, charityFee);
        }

        if(burnFee > 0){
            transferAmount = transferAmount.sub(burnFee);
            _reflectionTotal = _reflectionTotal.sub(burnFee.mul(rate));
            _tokenTotal = _tokenTotal.sub(burnFee);
            _burnFeeTotal = _burnFeeTotal.add(burnFee);
            emit Transfer(account, address(0), burnFee);
        }

        if(liquidityFee > 0){
            transferAmount = transferAmount.sub(liquidityFee);
            _reflectionBalance[liquidityManager] = _reflectionBalance[liquidityManager].add(liquidityFee.mul(rate));
            _liquidityFeeTotal = _liquidityFeeTotal.add(liquidityFee);
            emit Transfer(account, liquidityManager, liquidityFee);
        }

        if(marketingFee > 0){
            transferAmount = transferAmount.sub(marketingFee);
            _reflectionBalance[marketingFeeAddress] = _reflectionBalance[marketingFeeAddress].add(marketingFee.mul(rate));
            _marketingFeeTotal = _marketingFeeTotal.add(marketingFee);
            emit Transfer(account, marketingFeeAddress, marketingFee);
        }

        return transferAmount;
    }

    function _getReflectionRate() private view returns (uint256) {
        uint256 reflectionSupply = _reflectionTotal;
        uint256 tokenSupply = _tokenTotal;
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (
                _reflectionBalance[_excluded[i]] > reflectionSupply ||
                _tokenBalance[_excluded[i]] > tokenSupply
            ) return _reflectionTotal.div(_tokenTotal);
            reflectionSupply = reflectionSupply.sub(
                _reflectionBalance[_excluded[i]]
            );
            tokenSupply = tokenSupply.sub(_tokenBalance[_excluded[i]]);
        }
        if (reflectionSupply < _reflectionTotal.div(_tokenTotal))
            return _reflectionTotal.div(_tokenTotal);
        return reflectionSupply.div(tokenSupply);
    }

    function excludeFromFee(address account) external onlyOwner {
        isExcludedFromFee[account] = true;
    }
    
    function includeFromFee(address account) external onlyOwner {
        isExcludedFromFee[account] = false;
    }
    
    function setReflectionFee(uint256 fee) external onlyOwner {
        _taxFee = fee;
    }
    
    function setLiquidityFee(uint256 fee) external onlyOwner {
        _liquidityFee = fee;
    }
    
    function setCharityFee(uint256 fee) external onlyOwner {
        _charityFee = fee;
    }
    
    function setBurnPercent(uint256 fee) external onlyOwner {
        _burnFee = fee;
    }

    function setMarketingFee(uint256 fee) external onlyOwner {
        _marketingFee = fee;
    }

    function setEarlySellFee(uint256 fee) external onlyOwner {
        _earlySellFee = fee;
    }
    
    function setCharityAddress(address _Address) external onlyOwner {
        require(_Address != charityAddress);
        
        charityAddress = _Address;
    }
    
    function setRouterAddress(address _Address) external onlyOwner {
        require(_Address != routerAddress);
        
        routerAddress = _Address;
    }

    function setLiquidityManager(address _address) external onlyOwner {
        require(_address != liquidityManager);

        liquidityManager = _address;
    }

    function setMarketingAddress(address _Address) external onlyOwner {
        require(_Address != marketingFeeAddress);
        
        marketingFeeAddress = _Address;
    }
    
    function PrepareForPreSale() external onlyOwner {
        _burnFee = 0;
        _charityFee = 0;
        _taxFee = 0;
        _marketingFee = 0;
        _liquidityFee = 0;
        _earlySellFee = 0;
    }
    
    function afterPreSale() external onlyOwner {
        _burnFee = 200;
        _charityFee = 100;
        _taxFee = 500;
        _marketingFee = 300;
        _liquidityFee = 600;
        _earlySellFee = 1700;
    }

    // Copied and modified from YAM code:
    // https://github.com/yam-finance/yam-protocol/blob/master/contracts/token/YAMGovernanceStorage.sol
    // https://github.com/yam-finance/yam-protocol/blob/master/contracts/token/YAMGovernance.sol
    // Which is copied and modified from COMPOUND:
    // https://github.com/compound-finance/compound-protocol/blob/master/contracts/Governance/Comp.sol

    /// @dev A record of each accounts delegate
    mapping (address => address) internal _delegates;

    /// @notice A checkpoint for marking number of votes from a given block
    struct Checkpoint {
        uint32 fromBlock;
        uint256 votes;
    }

    /// @notice A record of votes checkpoints for each account, by index
    mapping (address => mapping (uint32 => Checkpoint)) public checkpoints;

    /// @notice The number of checkpoints for each account
    mapping (address => uint32) public numCheckpoints;

    /// @notice The EIP-712 typehash for the contract's domain
    bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");

    /// @notice The EIP-712 typehash for the delegation struct used by the contract
    bytes32 public constant DELEGATION_TYPEHASH = keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");

    /// @notice A record of states for signing / validating signatures
    mapping (address => uint) public nonces;

      /// @notice An event thats emitted when an account changes its delegate
    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);

    /// @notice An event thats emitted when a delegate account's vote balance changes
    event DelegateVotesChanged(address indexed delegate, uint previousBalance, uint newBalance);

    /**
     * @notice Delegate votes from `msg.sender` to `delegatee`
     * @param delegator The address to get delegatee for
     */
    function delegates(address delegator) external view returns (address) {
        return _delegates[delegator];
    }

   /**
    * @notice Delegate votes from `msg.sender` to `delegatee`
    * @param delegatee The address to delegate votes to
    */
    function delegate(address delegatee) external {
        return _delegate(msg.sender, delegatee);
    }

    /**
     * @notice Delegates votes from signatory to `delegatee`
     * @param delegatee The address to delegate votes to
     * @param nonce The contract state required to match the signature
     * @param expiry The time at which to expire the signature
     * @param v The recovery byte of the signature
     * @param r Half of the ECDSA signature pair
     * @param s Half of the ECDSA signature pair
     */
    function delegateBySig(address delegatee, uint nonce, uint expiry, uint8 v, bytes32 r, bytes32 s) external {
        bytes32 domainSeparator = keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(name())), getChainId(), address(this)));

        bytes32 structHash = keccak256(abi.encode(DELEGATION_TYPEHASH, delegatee, nonce, expiry));

        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));

        address signatory = ecrecover(digest, v, r, s);
        require(signatory != address(0), "ROBODOGE::delegateBySig: invalid signature");
        require(nonce == nonces[signatory]++, "ROBODOGE::delegateBySig: invalid nonce");
        require(block.timestamp <= expiry, "ROBODOGE::delegateBySig: signature expired");
        return _delegate(signatory, delegatee);
    }

    /**
     * @notice Gets the current votes balance for `account`
     * @param account The address to get votes balance
     * @return The number of current votes for `account`
     */
    function getCurrentVotes(address account) external view returns (uint256) {
        uint32 nCheckpoints = numCheckpoints[account];
        return nCheckpoints > 0 ? checkpoints[account][nCheckpoints - 1].votes : 0;
    }
    /**
     * @notice Determine the prior number of votes for an account as of a block number
     * @dev Block number must be a finalized block or else this function will revert to prevent misinformation.
     * @param account The address of the account to check
     * @param blockNumber The block number to get the vote balance at
     * @return The number of votes the account had as of the given block
     */
    function getPriorVotes(address account, uint blockNumber) external view returns (uint256) {
        require(blockNumber < block.number, "ROBODOGE::getPriorVotes: not yet determined");

        uint32 nCheckpoints = numCheckpoints[account];
        if (nCheckpoints == 0) {
            return 0;
        }

        // First check most recent balance
        if (checkpoints[account][nCheckpoints - 1].fromBlock <= blockNumber) {
            return checkpoints[account][nCheckpoints - 1].votes;
        }

        // Next check implicit zero balance
        if (checkpoints[account][0].fromBlock > blockNumber) {
            return 0;
        }

        uint32 lower = 0;
        uint32 upper = nCheckpoints - 1;
        while (upper > lower) {
            uint32 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
            Checkpoint memory cp = checkpoints[account][center];
            if (cp.fromBlock == blockNumber) {
                return cp.votes;
            } else if (cp.fromBlock < blockNumber) {
                lower = center;
            } else {
                upper = center - 1;
            }
        }
        return checkpoints[account][lower].votes;
    }

    function _delegate(address delegator, address delegatee) internal {
        address currentDelegate = _delegates[delegator];
        uint256 delegatorBalance = balanceOf(delegator);
        _delegates[delegator] = delegatee;

        emit DelegateChanged(delegator, currentDelegate, delegatee);

        _moveDelegates(currentDelegate, delegatee, delegatorBalance);
    }
    function _moveDelegates(address srcRep, address dstRep, uint256 amount) internal {
        if (srcRep != dstRep && amount > 0) {
            if (srcRep != address(0)) {
                // decrease old representative
                uint32 srcRepNum = numCheckpoints[srcRep];
                uint256 srcRepOld = srcRepNum > 0 ? checkpoints[srcRep][srcRepNum - 1].votes : 0;
                uint256 srcRepNew = srcRepOld.sub(amount);
                _writeCheckpoint(srcRep, srcRepNum, srcRepOld, srcRepNew);
            }

            if (dstRep != address(0)) {
                // increase new representative
                uint32 dstRepNum = numCheckpoints[dstRep];
                uint256 dstRepOld = dstRepNum > 0 ? checkpoints[dstRep][dstRepNum - 1].votes : 0;
                uint256 dstRepNew = dstRepOld.add(amount);
                _writeCheckpoint(dstRep, dstRepNum, dstRepOld, dstRepNew);
            }
        }
    }

    function _writeCheckpoint(address delegatee, uint32 nCheckpoints, uint256 oldVotes, uint256 newVotes) internal {
        uint32 blockNumber = safe32(block.number, "ROBODOGE::_writeCheckpoint: block number exceeds 32 bits");

        if (nCheckpoints > 0 && checkpoints[delegatee][nCheckpoints - 1].fromBlock == blockNumber) {
            checkpoints[delegatee][nCheckpoints - 1].votes = newVotes;
        } else {
            checkpoints[delegatee][nCheckpoints] = Checkpoint(blockNumber, newVotes);
            numCheckpoints[delegatee] = nCheckpoints + 1;
        }

        emit DelegateVotesChanged(delegatee, oldVotes, newVotes);
    }

    function safe32(uint n, string memory errorMessage) internal pure returns (uint32) {
        require(n < 2**32, errorMessage);
        return uint32(n);
    }

    function getChainId() internal view returns (uint) {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        return chainId;
    }
    
    receive() external payable {}

    function withdraw() external onlyOwner {
        payable(_msgSender()).transfer(address(this).balance);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
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

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}