/**
 *Submitted for verification at testnet.snowtrace.io on 2022-08-24
*/

// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.16;


interface IBEP20 {
    function transfer(address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeMath {
    /**
     * @dev Multiplies two unsigned integers, reverts on overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
     * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Adds two unsigned integers, reverts on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
     * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
     * reverts when dividing by zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

contract Ownable {
    address public _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor()  {
        _owner = msg.sender;

        emit OwnershipTransferred(address(0), _owner);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");

        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );

        emit OwnershipTransferred(_owner, newOwner);

        _owner = newOwner;
    }
}

contract HPG_IDO is Ownable {

    using SafeMath for uint256;

    IBEP20 public HPG;
    IBEP20 public BUSD;

    uint256 public investorBonus = 5;
    uint256 public percentage;
    uint256 public BUSDRate = 10;
    uint256 public firstPercentage = 5;
    uint256 public secondPercentage = 3;
    uint256 public thirdPercentage = 2;
    uint256 public fourthPercentage = 1;
    address[] private AllUsers;
    mapping(address=>address) public alladdress;
    

    event TransferBUSD(address indexed from, address indexed to, uint256 value ,uint256 time);
    event TransferHPG(address indexed owner, address indexed spender, uint256 value,uint256 time); 
    event Transaction1(address indexed T1, uint256 indexed t1);
    event Transaction2(address indexed T2, uint256 indexed t2);
    event Transaction3(address indexed T3, uint256 indexed t3);
    event Transaction4(address indexed T4, uint256 indexed t4);

    constructor(IBEP20 _HPG,IBEP20 _BUSD)
    {
        HPG =_HPG;
        BUSD = _BUSD;
       AllUsers.push(owner());
    }
    /**
            /* @dev Adds BUSD tokens to get HPG and investor bonus, referredBy address will be awarded with HPG 
     */
    function buyTokens(
        uint256 _BUSDAmount,
        address referredBy)
       public 
    {
            bool success;
        for(uint256 i;i<AllUsers.length;i++){
            if(referredBy==AllUsers[i]){
               success = true;
            }
        }
        require(success, " Address isn't whitelisted " );
        require(_BUSDAmount >= 10 ether && _BUSDAmount <= BUSD.balanceOf(msg.sender),"min 10 BUSD.");
        uint256 tokens = _BUSDAmount.mul(BUSDToHpgRate());
        uint256 InvesterBonus=getInvestorBonus(tokens); 
        uint256 TotalTokens = tokens + InvesterBonus;          //1bnb=10 HPG
        require (TotalTokens <= HPG.balanceOf(address(this)),"Contract Not Have Enough HPG");

        Refer(referredBy,tokens);
        BUSD.transferFrom(msg.sender,address(this),_BUSDAmount); 
        HPG.transfer(msg.sender, TotalTokens);
       
        emit TransferBUSD(msg.sender,address(this),_BUSDAmount , block.timestamp);
        emit TransferHPG(address(this),msg.sender,tokens, block.timestamp);
    }

   /**
            /* @dev Set Investor Percentage set only by Owner
     */
    function setInvestorPercentage(uint256 _InvestorBonus)
    public
    onlyOwner
    {
        investorBonus= _InvestorBonus;
    }
/**
            /* @dev Owner can Withdraw BUSD from smart contract
     */
    function withDrawBUSD(uint256 _amount) public onlyOwner {
        BUSD.transfer(msg.sender, _amount*10**18);
    }
    /**
            /* @dev Owner can Withdraw HPG from smart contract
     */
    function withDrawHPG(uint256 _amount) public onlyOwner {
        HPG.transfer(msg.sender, _amount*10**18);
    }
/**
            /* @dev Owner can set up BUSD To HPG rate
     */
    function setBUSDToHPGrate(uint _rate)
    public
    onlyOwner
    {
        BUSDRate=_rate;
        }
/**
            /* @dev Get addresses from mapping
     */
    function getaddresses(address _user) public view returns(address add1,address add2,address add3,address add4)
    {
        add1 = getaddress(_user);           
        add2 = getaddress(add1);
        add3 = getaddress(add2);
        add4 = getaddress(add3);
        return(add1,add2,add3,add4);
    }
/**
            /* @dev Transfer addresses and amount upto 4 referrels 
     */
    function Refer(address referredBy, uint256 _amount)
    public
    {
        require(referredBy!=msg.sender,"Please add a valid referred address");
        AllUsers.push(msg.sender);
        alladdress[msg.sender] = referredBy;
        (uint256 referrer1, uint256 referrer2, uint256 referrer3,uint256 referrer4)
        =
        getValues(_amount);
        (address referralAddress1 , address referralAddress2 , address referralAddress3 ,address referralAddress4)
        =
        getaddresses(msg.sender);
        //  address user=msg.sender;
        if(
        referralAddress1 == address(0)||
        referralAddress2 == address(0)||
        referralAddress3 == address(0)||
        referralAddress4 == address(0)
        )
        {
          if(referralAddress2==address(0))
          {referralAddress2=owner();}
          if(referralAddress3==address(0))
          {referralAddress3=owner();}
          if(referralAddress4==address(0))
          {referralAddress4=owner();}
        }

            HPG.transfer(referralAddress1,referrer1);
            HPG.transfer(referralAddress2,referrer2);
            HPG.transfer(referralAddress3,referrer3);
            HPG.transfer(referralAddress4,referrer4);
  
       emit Transaction1(referralAddress1,referrer1);
       emit Transaction2(referralAddress2,referrer2);
       emit Transaction3(referralAddress3,referrer3);
       emit Transaction4(referralAddress4,referrer4);
    }

    function setPercentages
    (uint256 _firstPercentage,uint256 _secondPercentage, uint256 _thirdPercentage, uint256 _fourthPercentage)
    public
    onlyOwner
    {
        firstPercentage=_firstPercentage;
        secondPercentage=_secondPercentage;
        thirdPercentage=_thirdPercentage;
        fourthPercentage=_fourthPercentage;

    }
/**
            /* @dev Get Percentages of Referrals
     */
    function getValues(uint256 _amount) public view returns(uint256,uint256,uint256,uint256){

        uint256 for1 = _amount.mul(firstPercentage).div(100);
        uint256 for2 = _amount.mul(secondPercentage).div(100);
        uint256 for3 = _amount.mul(thirdPercentage).div(100);
        uint256 for4 = _amount.mul(fourthPercentage).div(100);
       
        return(for1,for2,for3,for4);
    }
    /**
            /* @dev Get BUSD To HPG Rate
     */
    function BUSDToHpgRate()  public view returns(uint256){
        require(BUSDRate>0,"BUSD to hpg rate not set yet!");
        return BUSDRate;
    }
    /**
            /* @dev Get All users 
     */
    function ViewUsers() public view returns(address [] memory){
        return AllUsers;
    }
/**
            /* @dev Get Investor Bonus  
     */
    function getInvestorBonus(uint256 _BUSDAmount) public view returns (uint256){
      uint256 reward;
      reward = (_BUSDAmount).mul(investorBonus).div(100);
      return reward;
    }
    /**
            /* @dev Get address against the given address from mapping 
     */
    function getaddress(address _user) public view returns(address){
        return alladdress[_user];
    }


}
//HPG:0x6445e1cA8bacE92489d536e009bB7Bf7B14C7358
//BUSD:0x056Ed368fE043D9922ba0e8b1d21bcd67fA0385F
//ContractAddress:0xaf5dca5367315D4d8F3D9991028d6177bCcaB46F