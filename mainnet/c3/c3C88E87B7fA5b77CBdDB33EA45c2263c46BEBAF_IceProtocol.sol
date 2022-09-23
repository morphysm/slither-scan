/**
 *Submitted for verification at snowtrace.io on 2022-04-25
*/

pragma solidity ^0.8.4;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}


contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);

    }

    mapping (address => bool) public Whitelist;

    function owner() public view returns (address) {
        return _owner;
    } 
    
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    modifier onlyWhitelisted() {
        require(Whitelist[_msgSender()] == true, "Whitelisted: caller is not whitelisted");
        _;
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

}


abstract contract ReentrancyGuard {
   
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        _status = _ENTERED;

        _;

        _status = _NOT_ENTERED;
    }
}

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
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


    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

interface IERC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract IceProtocol is ReentrancyGuard, Context, Ownable {
    using SafeMath for uint256;
    
    mapping (address => uint256) public _contributions;

    uint256 private _tokenDecimals;
    address payable public _wallet;
    uint256 public _rate;
    uint256 public _weiRaised;
    uint256 public endICO;
    uint public minPurchase;
    uint public maxPurchase;
    uint public hardCap;
    uint public softCap;
    bool public startRefund = false;
    uint256 public refundStartDate;

    event TokensPurchased(address  purchaser, address  beneficiary, uint256 value, uint256 amount);
    event Refund(address recipient, uint256 amount);
    constructor (uint256 rate, address payable wallet, uint256 tokenDecimals)  {
        require(rate > 0, "Pre-Sale: rate is 0");
        require(wallet != address(0), "Pre-Sale: wallet is the zero address");
        
        _rate = rate;
        _wallet = wallet;
        _tokenDecimals = 18 - tokenDecimals;
    }


    receive () external payable {
        if(endICO > 0 && block.timestamp < endICO){
            buyTokens(_msgSender());
        }
        else{
            endICO = 0;
            revert('Pre-Sale is closed');
        }
    }
    
    
    //Start Pre-Sale
    function startICO(uint endDate, uint _minPurchase, uint _maxPurchase, uint _softCap, uint _hardCap) external onlyOwner icoNotActive() {
        startRefund = false;
        refundStartDate = 0;
        require(endDate > block.timestamp, 'duration should be > 0');
        require(_softCap < _hardCap, "Softcap must be lower than Hardcap");
        require(_minPurchase < _maxPurchase, "minPurchase must be lower than maxPurchase");
        require(_minPurchase > 0, '_minPurchase should > 0');
        endICO = endDate; 
        minPurchase = _minPurchase;
        maxPurchase = _maxPurchase;
        softCap = _softCap;
        hardCap = _hardCap;
        _weiRaised = 0;
    }
    
    function stopICO() external onlyOwner icoActive(){
        endICO = 0;
        if(_weiRaised >= softCap) {
            _forwardFunds();
        }
        else{
            startRefund = true;
            refundStartDate = block.timestamp;
        }
    }

    function addWhitelist(address _walletAdd) external onlyOwner {
        Whitelist[_walletAdd]=true;
    }

    function removeWhitelist(address _walletRemove) external onlyOwner {
        Whitelist[_walletRemove]=false;
    }

    //Pre-Sale 
    function buyTokens(address beneficiary) public nonReentrant onlyWhitelisted icoActive payable {
        uint256 weiAmount = msg.value;
        _preValidatePurchase(beneficiary, weiAmount);
        _weiRaised = _weiRaised.add(weiAmount);
        _contributions[beneficiary] = _contributions[beneficiary].add(weiAmount);
    }

    function _preValidatePurchase(address beneficiary, uint256 weiAmount) internal view {
        require(beneficiary != address(0), "Crowdsale: beneficiary is the zero address");
        require(weiAmount != 0, "Crowdsale: weiAmount is 0");
        require(weiAmount >= minPurchase, 'have to send at least: minPurchase');
        require(_contributions[beneficiary].add(weiAmount)<= maxPurchase, 'can\'t buy more than: maxPurchase');
        require((_weiRaised+weiAmount) <= hardCap, 'Hard Cap reached');
        this; 
    }

    function _forwardFunds() internal {
        _wallet.transfer(msg.value);
    }
    
     function withdraw() external onlyOwner icoNotActive{
         require(startRefund == false || (refundStartDate + 3 days) < block.timestamp);
         require(address(this).balance > 0, 'Contract has no money');
        _wallet.transfer(address(this).balance);    
    }
    
    function checkContribution(address addr) public view returns(uint256){
        return _contributions[addr];
    }
 
    function weiRaised() public view returns (uint256) {
        return _weiRaised;
    }
    
    function setWalletReceiver(address payable newWallet) external onlyOwner(){
        _wallet = newWallet;
    }
    
    function setHardCap(uint256 value) external onlyOwner{
        hardCap = value;
    }
    
    function setSoftCap(uint256 value) external onlyOwner{
        softCap = value;
    }
    
    function setMaxPurchase(uint256 value) external onlyOwner{
        maxPurchase = value;
    }
    
     function setMinPurchase(uint256 value) external onlyOwner{
        minPurchase = value;
    }
    
    function refundMe() public icoNotActive{
        require(startRefund == true, 'no refund available');
        uint amount = _contributions[msg.sender];
    if (address(this).balance >= amount) {
      _contributions[msg.sender] = 0;
      if (amount > 0) {
          address payable recipient = payable(msg.sender);
        recipient.transfer(amount);
        emit Refund(msg.sender, amount);
      }
    }
    }
    
    modifier icoActive() {
        require(endICO > 0 && block.timestamp < endICO, "ICO must be active");
        _;
    }
    
    modifier icoNotActive() {
        require(endICO < block.timestamp, 'ICO should not be active');
        _;
    }
    
}