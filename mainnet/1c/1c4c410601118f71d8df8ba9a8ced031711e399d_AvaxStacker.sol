/**
 *Submitted for verification at snowtrace.io on 2022-04-14
*/

// SPDX-License-Identifier: MIT License
pragma solidity 0.8.7;

struct Deposit {
  uint256 amount;
  uint40 time;
}

struct Player {
  uint256 dividends;
  uint256 ref_bonus;  
  uint256 total_invested;
  uint256 total_withdrawn;
  uint256 total_ref_bonus;
  uint256[5] structure; 
  uint40 last_payout;
  Deposit[] deposits;
  address upline;
}

contract AvaxStacker {
    address public owner;
    address public dev;
    address public marketing;

    uint256 public invested;
    uint256 public withdrawn;
    uint256 public ref_bonus;
    uint256 constant MAX_WITHDRAW = 10 ether;
    uint8 constant BONUS_LINES_COUNT = 5;
    uint16 constant PERCENT = 1000; 
    uint16 constant REWARD = 200;
    uint256 constant PERIOD = 25;
    uint8[BONUS_LINES_COUNT] public ref_bonuses = [100, 50, 30, 20, 10]; 

    mapping(address => Player) public players;

    event Upline(address indexed addr, address indexed upline, uint256 bonus);
    event NewDeposit(address indexed addr, uint256 amount);
    event RefPayout(address indexed addr, address indexed from, uint256 amount);
    event Withdraw(address indexed addr, uint256 amount);

    constructor(address _dev, address _marketing) {
        owner = msg.sender;
        dev = _dev;
        marketing = _marketing;
    }

    function deposit(address _upline) external payable {
        require(msg.value >= 0.05 ether, "Minimum deposit amount is 0.05 AVAX");

        Player storage player = players[msg.sender];

        require(player.deposits.length < 200, "Max 200 deposits per address");

        _setUpline(msg.sender, _upline, msg.value);

        player.deposits.push(Deposit({
            amount: msg.value,
            time: uint40(block.timestamp)
        }));

        player.total_invested += msg.value;
        invested += msg.value;
        _refPayout(msg.sender, msg.value);

        //4% goes to the dev
		uint256 amount = msg.value * 4 / 100;

        //6% goes to the marketing
		uint256 amount1 = msg.value * 6 / 100;

        payable(dev).transfer(amount);
        payable(marketing).transfer(amount1); 
        withdrawn += msg.value * 10 / 100;

	    emit NewDeposit(msg.sender, msg.value);
    }
    
    function withdraw() external {
        Player storage player = players[msg.sender];

        _payout(msg.sender);

        require(player.dividends > 0 || player.ref_bonus > 0, "Zero amount");

        uint256 amount = player.dividends + player.ref_bonus;
		
        player.dividends = 0;
        player.ref_bonus = 0;

        if(amount > MAX_WITHDRAW) {
            player.dividends = amount - MAX_WITHDRAW;
            amount = MAX_WITHDRAW;            
        }
       
        player.total_withdrawn += amount;
        
        uint to_receive; 
        if(withdrawn > (invested * 700 / PERCENT)){
            to_receive = amount * 700 / PERCENT;
            payable(msg.sender).transfer(to_receive);
            emit Withdraw(msg.sender, to_receive);

            withdrawn += to_receive;
        }else{
            to_receive = amount * 850 / PERCENT;
            
            payable(msg.sender).transfer(to_receive);
            emit Withdraw(msg.sender, to_receive);

            withdrawn += to_receive;
        }
        
    }

    function _payout(address _addr) private {
        uint256 payout = this.payoutOf(_addr);

        if(payout > 0) {
            players[_addr].last_payout = uint40(block.timestamp);
            players[_addr].dividends += payout;
        }
    }

    function _refPayout(address _addr, uint256 _amount) private {
        address up = players[_addr].upline;

        for(uint8 i = 0; i < ref_bonuses.length; i++) {
            if(up == address(0)) break;
            
            uint256 bonus = _amount * ref_bonuses[i] / PERCENT;
            
            players[up].ref_bonus += bonus;
            players[up].total_ref_bonus += bonus;

            ref_bonus += bonus;

            emit RefPayout(up, _addr, bonus);

            up = players[up].upline;
        }
    }

    function _setUpline(address _addr, address _upline, uint256 _amount) private {
        if(players[_addr].upline == address(0) && _addr != owner) {

            players[_addr].upline = _upline;

            emit Upline(_addr, _upline, _amount / 100);
            
            for(uint8 i = 0; i < BONUS_LINES_COUNT; i++) {
                players[_upline].structure[i]++;

                _upline = players[_upline].upline;

                if(_upline == address(0)) break;
            }
        }
    }   

    function payoutOf(address _addr) view external returns(uint256 value) {
        Player storage player = players[_addr];

        for(uint256 i = 0; i < player.deposits.length; i++) {
            Deposit storage dep = player.deposits[i];

            uint256 time_end = dep.time + PERIOD * 86400;
            uint40 from = player.last_payout > dep.time ? player.last_payout : dep.time;
            uint256 to = block.timestamp > time_end ? time_end : block.timestamp;

            if(from < to) {
                value += dep.amount * (to - from) * REWARD / PERIOD / 8640000;
            }
        }

        return value;
    }
    
    function userInfo(address _addr) view external returns(uint256 for_withdraw, uint256 total_invested, uint256 total_withdrawn, uint256 total_ref_bonus, uint256[BONUS_LINES_COUNT] memory structure) {
        Player storage player = players[_addr];

        uint256 payout = this.payoutOf(_addr);

        for(uint8 i = 0; i < ref_bonuses.length; i++) {
            structure[i] = player.structure[i];
        }

        return (
            payout + player.dividends + player.ref_bonus,
            player.total_invested,
            player.total_withdrawn,
            player.total_ref_bonus,
            structure
        );
    }

    function setDev(address _dev) external {
        require(msg.sender==owner,'Unauthorized!');
        dev = _dev;
    }
    
    function setMarketing(address _marketing) external {
        require(msg.sender==owner,'Unauthorized!');
        marketing = _marketing;
    }

    function contractInfo() view external returns(uint256 _invested, uint256 _withdrawn, uint256 _ref_bonus) {
        return (invested, withdrawn, ref_bonus);
    }
    
}