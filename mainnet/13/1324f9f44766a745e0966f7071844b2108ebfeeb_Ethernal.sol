/**
 *Submitted for verification at snowtrace.io on 2022-06-17
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;


interface EthernalBalance{
    function get(address _owner) external view returns(uint256);
    function add(address _owner, uint256 value) external;
    function sub(address _owner, uint256 value) external;
}

contract Ethernal {

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    function name() public pure returns (string memory){
        return "Eternal Token";
    }

    function symbol() public pure returns (string memory){
        return "ETRN";
    }

    function decimals() public pure returns (uint8){
        return 6;
    }

    function totalSupply() public view returns (uint256){
        return supply;
    }

    // Available and pending balances
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances.get(_owner) + pending_balances[_owner];
    }

    function getOwner() external view returns (address){
        return owner;
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        return _transferFrom(msg.sender, _to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success){
        assert(allowances[_from][msg.sender] >= _value);
        allowances[_from][msg.sender] -= _value;

        return _transferFrom(_from, _to, _value);
    }

    function approve(address _spender, uint256 _value) public returns (bool success){
        allowances[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining){
        return allowances[_owner][_spender];
    }

    struct Transaction{
        address to;
        uint value;
    }


    //Balances
    EthernalBalance balances;
    mapping(address => uint256) pending_balances;
    mapping(address => mapping(address => uint256)) allowances;

    //Info
    address owner;
    uint256 supply;

    //Moving
    uint average;
    uint value_added;
    Transaction[] queue;
    uint value_delivered;

    uint public update_time;
    uint next_update;

    //Setting default parameters
    constructor(){
        owner = msg.sender;
        balances = EthernalBalance(0x0555FdDD0d99A79009d580001925fDa449C24F30);

        update_time = 3 minutes;
        average = 30;
        next_update = block.timestamp + update_time;
    }

    function _transferFrom(address _from, address _to, uint256 _value) public returns (bool success){

        //Initial balance decrease and check
        balances.sub(_from, _value);

        //Adding to queue
        queue.push(Transaction({to: _to, value: _value}));

        //Changing value parameters
        pending_balances[_to] += _value;

        //Total trasferred value in time
        value_added += _value;

        //If time to update parameters
        if(next_update <= block.timestamp){

            //If value changes too slow or
            if(average >= value_added*2){
                update_time >>= 1;
            }

            //too fast
            if(average*2 <= value_added){
                update_time *= 2;
            }
            
            //Calc average moved value
            average = (average + value_added + 1) >> 1;

            //Resetting parameters
            value_added = 0;
            value_delivered = 0;

            next_update = block.timestamp + update_time;
        }   

        //Transferring balances until stop value and wait
        while(value_delivered <= average && queue.length > 0){

            //Removing from queue
            Transaction memory transaction = queue[queue.length - 1];
            queue.pop();

            //Editing values
            value_delivered += transaction.value;
            balances.add(transaction.to, transaction.value);
            pending_balances[transaction.to] -= transaction.value;
        }

        emit Transfer(_from, _to, _value);
        return true;
    }


    //Increase supply
    function issue(uint value)public {
        require(msg.sender == owner);

        supply += value;
        balances.add(owner, value);
    }



    //Balance of sender
    function get_balance() public view returns(uint, uint){
        return (balances.get(msg.sender), pending_balances[msg.sender]);
    }

    //Balance of _owner
    function check_balance(address _owner) public view returns(uint, uint){
        return (balances.get(_owner), pending_balances[_owner]);
    }

    

    //Can be sent without delay
    function available() public view returns(int){
        return int(average) - int(value_delivered);
    }

    //Time until parameters upgrade
    function update_timer() public view returns(int){
        return int(next_update) - int(block.timestamp);
    }

}