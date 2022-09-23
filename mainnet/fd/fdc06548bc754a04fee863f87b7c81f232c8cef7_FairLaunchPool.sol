/**
 *Submitted for verification at snowtrace.io on 2022-04-14
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

interface IOwnable {
    function owner() external view returns (address);

    function renounceManagement() external;

    function pushManagement(address newOwner_) external;

    function pullManagement() external;
}

contract Ownable is IOwnable {
    address internal _owner;
    address internal _newOwner;

    event OwnershipPushed(
        address indexed previousOwner,
        address indexed newOwner
    );
    event OwnershipPulled(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        _owner = msg.sender;
        emit OwnershipPushed(address(0), _owner);
    }

    function owner() public view override returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, 'Ownable: caller is not the owner');
        _;
    }

    function renounceManagement() public virtual override onlyOwner {
        emit OwnershipPushed(_owner, address(0));
        _owner = address(0);
    }

    function pushManagement(address newOwner_)
        public
        virtual
        override
        onlyOwner
    {
        require(
            newOwner_ != address(0),
            'Ownable: new owner is the zero address'
        );
        emit OwnershipPushed(_owner, newOwner_);
        _newOwner = newOwner_;
    }

    function pullManagement() public virtual override {
        require(msg.sender == _newOwner, 'Ownable: must be new owner to pull');
        emit OwnershipPulled(_owner, _newOwner);
        _owner = _newOwner;
    }
}




library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, 'SafeMath: addition overflow');

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, 'SafeMath: subtraction overflow');
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
        require(c / a == b, 'SafeMath: multiplication overflow');

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, 'SafeMath: division by zero');
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function sqrrt(uint256 a) internal pure returns (uint256 c) {
        if (a > 3) {
            c = a;
            uint256 b = add(div(a, 2), 1);
            while (b < c) {
                c = b;
                b = div(add(div(a, b), b), 2);
            }
        } else if (a != 0) {
            c = 1;
        }
    }
}






interface IERC20 {
    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
    external
    returns (bool);

    function allowance(address owner, address spender)
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

abstract contract ERC20 is IERC20 {
    using SafeMath for uint256;

    // TODO comment actual hash value.
    bytes32 private constant ERC20TOKEN_ERC1820_INTERFACE_ID =
    keccak256("ERC20Token");

    mapping(address => uint256) internal _balances;

    mapping(address => mapping(address => uint256)) internal _allowances;

    uint256 internal _totalSupply;

    string internal _name;

    string internal _symbol;

    uint8 internal _decimals;

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

    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account)
    public
    view
    virtual
    override
    returns (uint256)
    {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount)
    public
    virtual
    override
    returns (bool)
    {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
    public
    view
    virtual
    override
    returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
    public
    virtual
    override
    returns (bool)
    {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            msg.sender,
            _allowances[sender][msg.sender].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
    public
    virtual
    returns (bool)
    {
        _approve(
            msg.sender,
            spender,
            _allowances[msg.sender][spender].add(addedValue)
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
    public
    virtual
    returns (bool)
    {
        _approve(
            msg.sender,
            spender,
            _allowances[msg.sender][spender].sub(
                subtractedValue,
                "ERC20: decreased allowance below zero"
            )
        );
        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(
            amount,
            "ERC20: transfer amount exceeds balance"
        );
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account_, uint256 ammount_) internal virtual {
        require(account_ != address(0), "ERC20: mint to the zero address");
        _beforeTokenTransfer(address(this), account_, ammount_);
        _totalSupply = _totalSupply.add(ammount_);
        _balances[account_] = _balances[account_].add(ammount_);
        emit Transfer(address(this), account_, ammount_);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(
            amount,
            "ERC20: burn amount exceeds balance"
        );
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _beforeTokenTransfer(
        address from_,
        address to_,
        uint256 amount_
    ) internal virtual {}
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
abstract contract OwnableMulti {
    mapping(address => bool) private _owners;

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _owners[msg.sender] = true;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function isOwner(address _address) public view virtual returns (bool) {
        return _owners[_address];
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owners[msg.sender], "Ownable: caller is not an owner");
        _;
    }



    function addOwner(address _newOwner) public onlyOwner {
        require(_newOwner != address(0));
        _owners[_newOwner] = true;
    }
}








contract NRT is OwnableMulti {
    uint256 private _issuedSupply;
    uint256 private _outstandingSupply;
    uint256 private _decimals;
    string private _symbol;

    using SafeMath for uint256;

    mapping(address => uint256) private _balances;

    event Issued(address account, uint256 amount);
    event Redeemed(address account, uint256 amount);

    constructor(string memory __symbol, uint256 __decimals) {
        _symbol = __symbol;
        _decimals = __decimals;
        _issuedSupply = 0;
        _outstandingSupply = 0;
    }

    // Creates amount NRT and assigns them to account
    function issue(address account, uint256 amount) public onlyOwner {
        require(account != address(0), "zero address");

        _issuedSupply = _issuedSupply.add(amount);
        _outstandingSupply = _outstandingSupply.add(amount);
        _balances[account] = _balances[account].add(amount);

        emit Issued(account, amount);
    }

    //redeem, caller handles transfer of created value
    function redeem(address account, uint256 amount) public onlyOwner {
        require(account != address(0), "zero address");
        require(_balances[account] >= amount, "Insufficent balance");

        _balances[account] = _balances[account].sub(amount);
        _outstandingSupply = _outstandingSupply.sub(amount);

        emit Redeemed(account, amount);
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint256) {
        return _decimals;
    }

    function issuedSupply() public view returns (uint256) {
        return _issuedSupply;
    }

    function outstandingSupply() public view returns (uint256) {
        return _outstandingSupply;
    }
}



// *********************************
// TEST LAUNCH FOLL
// *********************************

contract FairLaunchPool is Ownable {

    using SafeMath for uint256;

    
    
    // the token address the cash is raised in
    address public investToken;
    // the token to be launched
    address public launchToken;
    // proceeds go to treasury
    address public treasury;
    // the certificate
    NRT public nrt;
    // how much was raised
    uint256 public totalraised;
    // how much was issued
    uint256 public totalissued;
    // how much was redeemed
    uint256 public totalredeem;
    // start of the sale
    uint256 public startTime;
    // total duration
    uint256 public duration;
    // end of the sale
    uint256 public endTime;
    // sale has started
    bool public saleEnabled;
    // redeem is possible
    bool public redeemEnabled;
	//has been extended, allow only one extension
	bool public isExtended;
    // minimum amount
    uint256 public mininvest;
    //
    uint256 public numWhitelisted = 0;
    //
    uint256 public numInvested = 0;

    event SaleEnabled(bool enabled, uint256 time);
    event RedeemEnabled(bool enabled, uint256 time);
    event Invest(address investor, uint256 amount);
    event Redeem(address investor, uint256 amount);

    struct InvestorInfo {
        uint256 amountInvested; // Amount deposited by user
        bool claimed; // has claimed MAG
    }
    
    // user is whitelisted
    mapping(address => bool) public whitelisted;

    mapping(address => InvestorInfo) public investorInfoMap;

    constructor(
        address _investToken,
        uint256 _startTime,
        uint256 _duration,
        uint256 _minInvest,
        address _treasury
    ) {
        investToken = _investToken;
        startTime = _startTime;
        duration = _duration;
        mininvest = _minInvest;
        treasury = _treasury;
        require(duration < 7 days, "duration too long");
        endTime = startTime.add(duration);
        nrt = new NRT("pSGF", 18);
        redeemEnabled = false;
        saleEnabled = false;
		isExtended = false;
    }

    // adds an address to the whitelist
    function addWhitelist(address _address) external onlyOwner {
        require(!whitelisted[_address], "already whitelisted");
        if(!whitelisted[_address])
            numWhitelisted = numWhitelisted.add(1);
        whitelisted[_address] = true;
    }

    // adds multiple addresses
    function addMultipleWhitelist(address[] calldata _addresses) external onlyOwner {
        require(_addresses.length <= 1000, "too many addresses");
        for (uint256 i = 0; i < _addresses.length; i++) {
            if(!whitelisted[_addresses[i]])
            numWhitelisted = numWhitelisted.add(1);
            whitelisted[_addresses[i]] = true;
        }
    }

    // removes a single address from the sale
    function removeWhitelist(address _address) external onlyOwner {
        whitelisted[_address] = false;
    }

    function invest(uint256 investAmount) public {
        require(block.timestamp >= startTime, "not started yet");
        require(endTime >= block.timestamp, "sale has ended");
        require(saleEnabled, "not enabled yet");
        require(whitelisted[msg.sender] == true, 'sender is not whitelisted');
        require(investAmount == mininvest, "not equal invest");

        InvestorInfo storage investor = investorInfoMap[msg.sender];
        require(investor.amountInvested == 0, "already invested");
		
        require(
            ERC20(investToken).transferFrom(
                msg.sender,
                treasury,
                investAmount
            ),
            "transfer failed"
        ); 

        //500 USDC turns into 100,000 of SMG
		//500 USDC is 5e8 using decimals 6, SMG uses decimals 18, issue amount is multiplied by 2e14 to get 1e23 which is 100,000
        uint256 issueAmount = investAmount.mul(200000000000000);

        nrt.issue(msg.sender, issueAmount);

        totalraised = totalraised.add(investAmount);
        totalissued = totalissued.add(issueAmount);
        if (investor.amountInvested == 0){
            numInvested = numInvested.add(1);
        }
        investor.amountInvested = investor.amountInvested.add(investAmount);

        emit Invest(msg.sender, investAmount);
    }

    // redeem all tokens
    function redeem() public {
        InvestorInfo storage investor = investorInfoMap[msg.sender];
        require(redeemEnabled, "redeem not enabled");
        require(!investor.claimed, "already claimed");
        uint256 redeemAmount = nrt.balanceOf(msg.sender);
        require(redeemAmount > 0, "no amount issued");

        nrt.redeem(msg.sender, redeemAmount);
        
        totalredeem = totalredeem.add(redeemAmount);
        emit Redeem(msg.sender, redeemAmount);
        investor.claimed = true;
        require(
            ERC20(launchToken).transfer(
                msg.sender,
                redeemAmount
            ),
            "transfer failed"
        );
    }

    // -- admin functions -- 

    // define the launch token to be redeemed
    function setLaunchToken(address _launchToken) public onlyOwner {
        launchToken = _launchToken;
    }

    //change the datetime for when the launch happens
    function setstartTime(uint256 _startTime) public onlyOwner {
        require(block.timestamp <= startTime, "too late, sale has started");
        require(!saleEnabled, "sale has already started");
        startTime = _startTime;
        endTime = _startTime.add(duration);
    }

    function depositLaunchtoken(uint256 amount) public onlyOwner {
        require(
            ERC20(launchToken).transferFrom(msg.sender, address(this), amount),
            "transfer failed"
        );
    }

    // withdraw in case some tokens were not redeemed
 function withdrawLaunchtoken(uint256 amount) public onlyOwner {
   require(
        ERC20(launchToken).transfer(msg.sender, amount),
          "transfer failed"
      );
  }

    function toggleSale() public onlyOwner {
        if(block.timestamp > endTime ) {
            saleEnabled = false;
            emit SaleEnabled(false, block.timestamp);
        } else {
            saleEnabled = true;
            emit SaleEnabled(true, block.timestamp);
        }
    }

    function enableRedeem() public onlyOwner {
        require(launchToken != address(0), "launch token not set");
        redeemEnabled = true;
        emit RedeemEnabled(true, block.timestamp);
    }
	
	function extendSale() public onlyOwner {
		require(!isExtended, 'cannot extend a second time');
		isExtended = true;
		endTime = endTime + 86400;
	}

}