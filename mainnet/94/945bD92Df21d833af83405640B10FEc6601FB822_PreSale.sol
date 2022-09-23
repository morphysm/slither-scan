/**
 *Submitted for verification at snowtrace.io on 2022-03-30
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;


library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }
}

abstract contract Context {

    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }
}

abstract contract Ownable is Context {

    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IARC20 {

    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract PreSale is Ownable {

    using SafeMath for uint256;

    IARC20 public PTOKEN = IARC20(0x3058A5e76986339C107b3F6636B774cE7328123B);
    address public Recipient = 0x0e5EF4184E897C3aC50A4C3e3Cc3294c486A2B5c;

    uint256 public tokenRatePerEth = 12500; // 12500 * (10 ** decimals) PTOKEN per eth
    uint256 public pTokenRatePerEth = 13000; // 13000 * (10 ** decimals) PTOKEN per eth

    uint256 public minETHLimit = 0.05 ether;
    uint256 public maxETHLimit = 10 ether;

    uint256 public hardCap = 4000 ether;
    uint256 public totalRaisedAVAX = 0; // total AVAX raised by sale
    uint256 public totaltokenSold = 0;

    uint256 public startTime;
    uint256 public endTime;
    uint256 public pSaleDuration = 600;
    bool public contractPaused; // circuit breaker

    mapping(address => bool) public whiteListed;
    mapping(address => uint256) public usersInvestments;

    constructor(uint256 _startTime, uint256 _endTime) {
        require(_startTime > block.timestamp, 'past timestamp');
        startTime = _startTime;
        if(_endTime > _startTime + 7 days) {
            endTime = _endTime;
        } else {
            endTime = _startTime + 30 days;
        }
    }

    modifier checkIfPaused() {
        require(contractPaused == false, "contract is paused");
        _;
    }

    function setPresaleToken(address tokenaddress) external onlyOwner {
        require( tokenaddress != address(0) );
        PTOKEN = IARC20(tokenaddress);
    }

    function setRecipient(address recipient) external onlyOwner {
        Recipient = recipient;
    }

    function setTokenRatePerEth(uint256 rate, uint256 pRate) external onlyOwner {
        tokenRatePerEth = rate;
        pTokenRatePerEth = pRate;
    }

    function setMinEthLimit(uint256 amount) external onlyOwner {
        minETHLimit = amount;    
    }

    function setMaxEthLimit(uint256 amount) external onlyOwner {
        maxETHLimit = amount;    
    }

    function setStartTime(uint256 _startTime) external onlyOwner {
        require(_startTime > block.timestamp, 'past timestamp');
        startTime = _startTime;
    }

    function setEndTime(uint256 _endTime) external onlyOwner {
        require(_endTime > startTime, 'should be bigger than start time');
        endTime = _endTime;
    }

    function togglePause() external onlyOwner returns (bool){
        contractPaused = !contractPaused;
        return contractPaused;
    }

    function addMultipleAccountsToWhiteList(address[] calldata _accounts, bool _value) public onlyOwner {
        for(uint256 i = 0; i < _accounts.length; i++) {
            whiteListed[_accounts[i]] = _value;
        }
    }

    function addWhiteList(address _account) public onlyOwner {
        whiteListed[_account] = true;
    }
    
    function removeWhiteList(address _account) public onlyOwner {
        whiteListed[_account] = false;
    }

    receive() external payable{
        deposit();
    }

    function deposit() public payable checkIfPaused {
        require(block.timestamp > startTime, 'Sale has not started');
        if(block.timestamp < startTime.add(pSaleDuration)){
            require(whiteListed[msg.sender], 'Private sale');
        }
        require(block.timestamp < endTime, 'Sale has ended');
        require(totalRaisedAVAX <= hardCap, 'HardCap exceeded');
        require(
                usersInvestments[msg.sender].add(msg.value) <= maxETHLimit
                && usersInvestments[msg.sender].add(msg.value) >= minETHLimit,
                "Installment Invalid."
        );

        uint256 tokenAmount = getTokensPerEth(msg.value);
        require(PTOKEN.transfer(msg.sender, tokenAmount), "Insufficient balance of presale contract!");

        totalRaisedAVAX = totalRaisedAVAX.add(msg.value);
        totaltokenSold = totaltokenSold.add(tokenAmount);
        usersInvestments[msg.sender] = usersInvestments[msg.sender].add(msg.value);

        payable(Recipient).transfer(msg.value);
    }

    function getUnsoldTokens(address token, address to) external onlyOwner {
        require(block.timestamp > endTime + 10 days, "You cannot get tokens until the presale is closed.");
        IARC20(token).transfer(to, IARC20(token).balanceOf(address(this)) );
    }

    function getUserRemainingAllocation(address account) external view returns ( uint256 ) {
        return maxETHLimit.sub(usersInvestments[account]);
    }

    function getTokensPerEth(uint256 amount) internal view returns(uint256) {
        if(block.timestamp > startTime.add(pSaleDuration)){
            return amount.mul(tokenRatePerEth).div(10**(uint256(18).sub(PTOKEN.decimals())));
        }
        return amount.mul(pTokenRatePerEth).div(10**(uint256(18).sub(PTOKEN.decimals())));
    }
}