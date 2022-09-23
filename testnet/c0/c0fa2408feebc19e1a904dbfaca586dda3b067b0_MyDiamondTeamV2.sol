/**
 *Submitted for verification at testnet.snowtrace.io on 2022-05-03
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

contract MyDiamondTeamV2 {
    using SafeMath for uint256;
    using SafeMath for uint8;

     struct User {
        address upline;
        uint256 referrals;
        uint256 payouts;
        uint256 direct_bonus;
        uint256 pool_bonus;
        uint256 match_bonus;
        uint256 deposit_amount;
        uint256 deposit_payouts;
        uint256 total_direct_deposits;
        uint256 total_payouts;
        uint256 total_structure;
        uint256 total_downline_deposit;
        uint256 checkpoint;
    }

    struct Airdrop {
        uint256 airdrops;
        uint256 airdrops_sent;
        uint256 airdrops_sent_count;
        uint256 airdrops_received;
        uint256 airdrops_received_count;
        uint256 last_airdrop;
        uint256 last_airdrop_received;
        uint256 airdrop_bonus;
    }

    struct Team {
        address[] members; // owner is also in member-array!
        address owner; // owner is able to add users
        uint256 id;
        uint256 created_at;
        string name;
        bool is_referral_team; // first team of upline-user is the referral team. all ref users are added automatically
    }

    struct TeamInfo {
        uint256 id;
        bool exists;
    }

    struct UserBonusStats {
        uint256 direct_bonus_withdrawn;
        uint256 match_bonus_withdrawn;
        uint256 pool_bonus_withdrawn;
        uint256 airdrops_withdrawn;
        uint256 income_reinvested;
        uint256 bonus_reinvested;
        uint256 airdrops_reinvested;
        uint256 reinvested_gross;
    }
		
	mapping(address => address) public uplinesOld;
		
    
    mapping(address => UserBonusStats) public userBonusStats;
    mapping(address => string) nicknames;
    mapping(address => User) public users;
    mapping(uint256 => address) public id2Address;
    mapping(address => Airdrop) public airdrops;
    mapping(uint256 => Team) public teams;
    mapping(address => uint8) public user_teams_counter; // holds the number of teams of a user
    mapping(address => TeamInfo[]) public user_teams;
    mapping(address => TeamInfo) public user_referral_team;

    address payable public owner;
    address payable public project;
    address payable public community;

    uint256 public REFERRAL;
    uint256 public PROJECT;
	uint256 public COMMUNITY;
    uint256 public AIRDROP; // 0% Tax on airdrop
    uint256 public REINVEST_BONUS;
    uint256 public MAX_PAYOUT;
    uint256 public BASE_PERCENT;
    uint256 public TIME_STEP;
    uint8 public MAX_TEAMS_PER_ADDRESS;
    uint8 public MAX_LENGTH_NICKNAME;
    uint256 constant public PERCENTS_DIVIDER = 1000;

    uint8[] public ref_bonuses;
    uint8[] public pool_bonuses;
    uint256 public pool_last_draw;
    uint256 public pool_cycle;
    uint256 public pool_balance;
    uint256 constant public ref_depth = 15;

    mapping(uint256 => mapping(address => uint256)) public pool_users_refs_deposits_sum;
    mapping(uint8 => address) public pool_top;

    uint256 public total_users;
    uint256 public total_deposited;
    uint256 public total_withdraw;
    uint256 public total_reinvested;
    uint256 public total_airdrops;
    uint256 public total_teams_created;

    bool public started;
    bool public initialized;
    bool public airdrop_enabled;
    uint256 public MIN_INVEST; //0.1 BNB
    uint256 public AIRDROP_MIN; //0.1 BNB
    uint256 public MAX_WALLET_DEPOSIT; //25 BNB
    uint256 public MAX_POOL_BALANCE; //25 BNB

    bool public KEEP_TAXES_IN_CONTRACT;

    event Upline(address indexed addr, address indexed upline);
    event NewDeposit(address indexed addr, uint256 amount);
    event DirectPayout(address indexed addr, address indexed from, uint256 amount);
    event MatchPayout(address indexed addr, address indexed from, uint256 amount);
    event PoolPayout(address indexed addr, uint256 amount);
    event Withdraw(address indexed addr, uint256 amount);
    event LimitReached(address indexed addr, uint256 amount);
	event ReinvestedDeposit(address indexed user, uint256 amount);
    event NewAirdrop(address indexed from, address indexed to, uint256 amount, uint256 timestamp);

    /*function initialize(address payable ownerAddress, address payable projectAddress, address payable communityAddress) external{
		require(!initialized);	
        require(!isContract(ownerAddress) && !isContract(projectAddress) && !isContract(communityAddress));
        owner = ownerAddress;
		project = projectAddress;
		community = communityAddress;

        total_users = 1;
        REFERRAL = 50;
        PROJECT = 10;
        COMMUNITY = 90;
        AIRDROP = 0; // 0% Tax on airdrop
        REINVEST_BONUS = 50;
        MAX_PAYOUT = 3650;
        BASE_PERCENT = 15;
        TIME_STEP = 1 days;
        MAX_TEAMS_PER_ADDRESS = 6;
        MAX_LENGTH_NICKNAME = 10;
        pool_last_draw = block.timestamp;

        MIN_INVEST = 1 * 1e17; //0.1 BNB
        AIRDROP_MIN = 1 * 1e17; //0.1 BNB
        MAX_WALLET_DEPOSIT = 25 ether; //25 BNB
        MAX_POOL_BALANCE = 25 ether; //25 BNB


        ref_bonuses.push(10);
        ref_bonuses.push(10);
        ref_bonuses.push(10);
        ref_bonuses.push(10);
        ref_bonuses.push(10);
        ref_bonuses.push(7);
        ref_bonuses.push(7);
        ref_bonuses.push(7);
        ref_bonuses.push(7);
        ref_bonuses.push(7);
        ref_bonuses.push(5);
        ref_bonuses.push(5);
        ref_bonuses.push(5);
        ref_bonuses.push(5);
        ref_bonuses.push(5);

        pool_bonuses.push(25);
        pool_bonuses.push(20);
        pool_bonuses.push(15);
        pool_bonuses.push(10);

        initialized = true;
    }*/

	function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }
	
	receive() external payable {
        
    }

    //deposit_amount -- can only be done by the project address for first deposit.
    function deposit() payable external {
        _deposit(msg.sender, msg.value);
    }

    //deposit with upline
    function deposit(address _upline) payable external {
        require(started, "Contract not yet started.");
				
		if(uplinesOld[msg.sender] != address(0)) {
            _setUpline(msg.sender, uplinesOld[msg.sender]);
		} else {
			_setUpline(msg.sender, _upline);
		}
        _deposit(msg.sender, msg.value);
    }

    //deposit with upline NICKNAME
    function depositWithNickname(string calldata _nickname) payable external {
        require(started, "Contract not yet started.");
        if(uplinesOld[msg.sender] != address(0)) {
			_setUpline(msg.sender, uplinesOld[msg.sender]);
        } else {
            address _upline = getAddressToNickname(_nickname);
            require(_upline != address(0), "nickname not found");        
            _setUpline(msg.sender, _upline);
        }
        _deposit(msg.sender, msg.value);
    }

    //invest
    function _deposit(address _addr, uint256 _amount) private {
        if (!started) {
    		if (msg.sender == project) {
    			started = true;
    		} else revert("Contract not yet started.");
    	}
        
        require(users[_addr].upline != address(0) || _addr == project, "No upline");
        require(_amount >= MIN_INVEST, "Mininum investment not met.");
        require(users[_addr].total_direct_deposits.add(_amount) <= MAX_WALLET_DEPOSIT, "Max deposit limit reached.");

        if(users[_addr].deposit_amount == 0 ){ // new user
            id2Address[total_users] = _addr;
            total_users++;
        }

        // reinvest before deposit because the checkpoint gets an reset here
        uint256 to_reinvest = this.payoutToReinvest(msg.sender);
        if(to_reinvest > 0){
            userBonusStats[msg.sender].income_reinvested += to_reinvest;
            to_reinvest = to_reinvest.add(to_reinvest.mul(REINVEST_BONUS).div(PERCENTS_DIVIDER)); //add 5% more bonus for reinvest action.
            users[msg.sender].deposit_amount += to_reinvest;	
            userBonusStats[msg.sender].reinvested_gross += to_reinvest;        
            total_reinvested += to_reinvest;
            emit ReinvestedDeposit(msg.sender, to_reinvest);
        }

        // deposit
        users[_addr].deposit_amount += _amount;
        users[_addr].checkpoint = block.timestamp;
        users[_addr].total_direct_deposits += _amount;

        total_deposited += _amount;

        emit NewDeposit(_addr, _amount);
        if(users[_addr].upline != address(0)) {
            //direct referral bonus 5%
						if(users[users[_addr].upline].checkpoint > 0) {
            users[users[_addr].upline].direct_bonus += _amount.mul(REFERRAL).div(PERCENTS_DIVIDER);
            emit DirectPayout(users[_addr].upline, _addr, _amount.mul(REFERRAL).div(PERCENTS_DIVIDER));
						}
        }

        _poolDeposits(_addr, _amount);
        _downLineDeposits(_addr, _amount);

        if(pool_last_draw.add(TIME_STEP) < block.timestamp) {
            _drawPool();
        }

        //pay fees
        fees(_amount);
    }

    function checkUplineValid(address _addr, address _upline) external view returns (bool isValid) {
        if (uplinesOld[_addr] == _upline && users[_addr].checkpoint == 0) {
            isValid = true;
        }		
        if(users[_addr].upline == address(0) && _upline != _addr && _addr != project && (users[_upline].checkpoint > 0 || _upline == project)) {
            isValid = true;        
        }
    }

    function _setUpline(address _addr, address _upline) private {
        if(this.checkUplineValid(_addr, _upline)) {
            users[_addr].upline = _upline;
            users[_upline].referrals++;

            if(user_referral_team[_upline].exists == false){
                uint256 teamId = _createTeam(_upline, true); // create first team on upline-user. this contains the direct referrals
                user_referral_team[_upline].id = teamId;
                user_referral_team[_upline].exists = true;
            }

            // check if current user is in ref-team
            bool memberExists = false;
            for(uint256 i = 0; i < teams[user_referral_team[_upline].id].members.length; i++){
                if(teams[user_referral_team[_upline].id].members[i] == _addr){
                    memberExists = true;
                }
            }
            if(memberExists == false){
                _addTeamMember(user_referral_team[_upline].id, _addr); // add referral user to upline users referral-team
            }

            emit Upline(_addr, _upline);

            for(uint8 i = 0; i < ref_bonuses.length; i++) {
                if(_upline == address(0)) break;

                users[_upline].total_structure++;

                _upline = users[_upline].upline;
            }
        }
    }

    function _poolDeposits(address _addr, uint256 _amount) private {
        
	    uint256 pool_amount = _amount.mul(3).div(100); // use 3% of the deposit
		
        if(pool_balance.add(pool_amount) > MAX_POOL_BALANCE){ // check if old balance + additional pool deposit is in range            
            pool_balance += MAX_POOL_BALANCE.sub(pool_balance);
        }else{
            pool_balance += pool_amount;
        }

        address upline = users[_addr].upline;

        if(upline == address(0) || upline == project) return;

        pool_users_refs_deposits_sum[pool_cycle][upline] += _amount;

        for(uint8 i = 0; i < pool_bonuses.length; i++) {
            if(pool_top[i] == upline) break;

            if(pool_top[i] == address(0)) {
                pool_top[i] = upline;
                break;
            }

            if(pool_users_refs_deposits_sum[pool_cycle][upline] > pool_users_refs_deposits_sum[pool_cycle][pool_top[i]]) {
                for(uint8 j = i + 1; j < pool_bonuses.length; j++) {
                    if(pool_top[j] == upline) {
                        for(uint8 k = j; k <= pool_bonuses.length; k++) {
                            pool_top[k] = pool_top[k + 1];
                        }
                        break;
                    }
                }

                for(uint8 j = uint8(pool_bonuses.length.sub(1)); j > i; j--) {
                    pool_top[j] = pool_top[j - 1];
                }

                pool_top[i] = upline;

                break;
            }
        }
    }

    function _downLineDeposits(address _addr, uint256 _amount) private {
      address _upline = users[_addr].upline;
      for(uint8 i = 0; i < ref_bonuses.length; i++) {
          if(_upline == address(0)) break;
					if(users[_upline].checkpoint > 0) {
          users[_upline].total_downline_deposit = users[_upline].total_downline_deposit.add(_amount);
					}
          _upline = users[_upline].upline;
      }
    }

    function _refPayout(address _addr, uint256 _amount) private {
        address up = users[_addr].upline;

        for(uint8 i = 0; i < ref_depth; i++) {
            if(up == address(0)) break;

            if(users[up].referrals >= i.add(1)) {
                uint256 bonus = _amount * ref_bonuses[i] / 100;
                if(users[up].checkpoint!= 0) { // only pay match payout if user is present
                    users[up].match_bonus += bonus;
                    emit MatchPayout(up, _addr, bonus);   
                }       
            }

            up = users[up].upline;
        }
    }

    function _drawPool() private {
        pool_last_draw = block.timestamp;
        pool_cycle++;

        uint256 draw_amount = pool_balance.div(10);

        for(uint8 i = 0; i < pool_bonuses.length; i++) {
            if(pool_top[i] == address(0)) break;

            uint256 win = draw_amount.mul(pool_bonuses[i]) / 100;

            users[pool_top[i]].pool_bonus += win;
            pool_balance -= win;

            emit PoolPayout(pool_top[i], win);
        }

        for(uint8 i = 0; i < pool_bonuses.length; i++) {
            pool_top[i] = address(0);
        }
    }

    function withdraw() external {
        if (!started) {
			revert("Contract not yet started.");
		}
        
        (uint256 to_payout, uint256 max_payout) = this.payoutOf(msg.sender);
        require(users[msg.sender].payouts < max_payout, "Max payout already received.");

        // Deposit payout
        if(to_payout > 0) {
            if(users[msg.sender].payouts.add(to_payout) > max_payout) {
                to_payout = max_payout.sub(users[msg.sender].payouts);
            }

            users[msg.sender].deposit_payouts += to_payout;
            users[msg.sender].payouts += to_payout;

            _refPayout(msg.sender, to_payout);
        }

        // Direct bonnus payout
        if(users[msg.sender].payouts < max_payout && users[msg.sender].direct_bonus > 0) {
            uint256 direct_bonus = users[msg.sender].direct_bonus;

            if(users[msg.sender].payouts.add(direct_bonus) > max_payout) {
                direct_bonus = max_payout.sub(users[msg.sender].payouts);
            }

            users[msg.sender].direct_bonus -= direct_bonus;
            users[msg.sender].payouts += direct_bonus;
            userBonusStats[msg.sender].direct_bonus_withdrawn += direct_bonus;
            to_payout += direct_bonus;
        }

        // Pool payout
        if(users[msg.sender].payouts < max_payout && users[msg.sender].pool_bonus > 0) {
            uint256 pool_bonus = users[msg.sender].pool_bonus;

            if(users[msg.sender].payouts.add(pool_bonus) > max_payout) {
                pool_bonus = max_payout.sub(users[msg.sender].payouts);
            }

            users[msg.sender].pool_bonus -= pool_bonus;
            users[msg.sender].payouts += pool_bonus;
            userBonusStats[msg.sender].pool_bonus_withdrawn += pool_bonus;
            to_payout += pool_bonus;
        }

        // Match payout
        if(users[msg.sender].payouts < max_payout && users[msg.sender].match_bonus > 0) {
            uint256 match_bonus = users[msg.sender].match_bonus;

            if(users[msg.sender].payouts.add(match_bonus) > max_payout) {
                match_bonus = max_payout.sub(users[msg.sender].payouts);
            }

            users[msg.sender].match_bonus -= match_bonus;
            users[msg.sender].payouts += match_bonus;
            userBonusStats[msg.sender].match_bonus_withdrawn += match_bonus;
            to_payout += match_bonus;  
        }

        // Airdrop payout
        if(users[msg.sender].payouts < max_payout && airdrops[msg.sender].airdrop_bonus > 0) {
            uint256 airdrop_bonus = airdrops[msg.sender].airdrop_bonus;

            if(users[msg.sender].payouts.add(airdrop_bonus) > max_payout) {
                airdrop_bonus = max_payout.sub(users[msg.sender].payouts);
            }

            airdrops[msg.sender].airdrop_bonus -= airdrop_bonus;
            users[msg.sender].payouts += airdrop_bonus;
            userBonusStats[msg.sender].airdrops_withdrawn += airdrop_bonus;
            to_payout += airdrop_bonus;  
            
        }

        require(to_payout > 0, "User has zero dividends payout.");
        //check for withdrawal tax and get final payout.
        to_payout = this.withdrawalTaxPercentage(to_payout);
        users[msg.sender].total_payouts += to_payout;
        total_withdraw += to_payout;
        users[msg.sender].checkpoint = block.timestamp;
        
        //pay investor
        uint256 payout = to_payout.sub(fees(to_payout));
        payable(address(msg.sender)).transfer(payout);
        emit Withdraw(msg.sender, payout);
        //max payout of 
        if(users[msg.sender].payouts >= max_payout) {
            emit LimitReached(msg.sender, users[msg.sender].payouts);
        }
    }

    //re-invest direct deposit payouts and direct referrals.
    function reinvest() external {
		if (!started) {
			revert("Not started yet");
		}

        (, uint256 max_payout) = this.payoutOf(msg.sender);
        require(users[msg.sender].payouts < max_payout, "Max payout already received.");

        // Deposit payout
        uint256 to_reinvest = this.payoutToReinvest(msg.sender);

        userBonusStats[msg.sender].income_reinvested += to_reinvest;

        // Direct payout
        uint256 direct_bonus = users[msg.sender].direct_bonus;
        users[msg.sender].direct_bonus -= direct_bonus;
        userBonusStats[msg.sender].bonus_reinvested += direct_bonus;
        to_reinvest += direct_bonus;

        // Pool payout
        uint256 pool_bonus = users[msg.sender].pool_bonus;
        users[msg.sender].pool_bonus -= pool_bonus;
        userBonusStats[msg.sender].bonus_reinvested += pool_bonus;
        to_reinvest += pool_bonus;
        
        // Match payout
        uint256 match_bonus = users[msg.sender].match_bonus;
        users[msg.sender].match_bonus -= match_bonus;
        userBonusStats[msg.sender].bonus_reinvested += match_bonus;
        to_reinvest += match_bonus;    

        // Airdrop payout
        uint256 airdrop_bonus = airdrops[msg.sender].airdrop_bonus;
        airdrops[msg.sender].airdrop_bonus -= airdrop_bonus;
        userBonusStats[msg.sender].airdrops_reinvested += airdrop_bonus;
        to_reinvest += airdrop_bonus; 

        require(to_reinvest > 0, "User has zero dividends re-invest.");
        //add 5% more bonus for reinvest action.
        to_reinvest = to_reinvest.add(to_reinvest.mul(REINVEST_BONUS).div(PERCENTS_DIVIDER));
        users[msg.sender].deposit_amount += to_reinvest;
        users[msg.sender].checkpoint = block.timestamp;
        userBonusStats[msg.sender].reinvested_gross += to_reinvest;        
        /** to_reinvest will not be added to total_deposits, new deposits will only be added here. **/
        //users[msg.sender].total_deposits += to_reinvest;
        total_reinvested += to_reinvest;
        emit ReinvestedDeposit(msg.sender, to_reinvest);
        
        //_poolDeposits(msg.sender, to_reinvest);

        //_downLineDeposits(msg.sender, to_reinvest);

        if(pool_last_draw.add(TIME_STEP) < block.timestamp) {
            _drawPool();
        }
	}

    function airdrop(address _to) payable external {
        require(airdrop_enabled, "Airdrop not Enabled.");

        address _addr = msg.sender;
        uint256 _amount = msg.value;

        require(_amount >= AIRDROP_MIN, "Mininum airdrop amount not met.");

        // transfer to recipient        
        uint256 project_fee = _amount.mul(AIRDROP).div(PERCENTS_DIVIDER); // tax on airdrop if enabled
        uint256 payout = _amount.sub(project_fee);
        if(project_fee > 0){
            project.transfer(project_fee);
        }

        //Make sure _to exists in the system; we increase
        require(users[_to].upline != address(0), "_to not found");

        //Fund to airdrop bonus (not a transfer - user will be able to claim/reinvest)
        airdrops[_to].airdrop_bonus += payout;

        //User stats
        airdrops[_addr].airdrops += payout; // sender
        airdrops[_addr].last_airdrop = block.timestamp; // sender
        airdrops[_addr].airdrops_sent += payout; // sender
        airdrops[_addr].airdrops_sent_count = airdrops[_addr].airdrops_sent_count.add(1); // sender add count for airdrop sent count
        airdrops[_to].airdrops_received += payout; // recipient
        airdrops[_to].airdrops_received_count = airdrops[_to].airdrops_received_count.add(1); // recipient add count for airdrop received count
        airdrops[_to].last_airdrop_received = block.timestamp; // recipient

        //Keep track of overall stats
        total_airdrops += payout;

        emit NewAirdrop(_addr, _to, payout, block.timestamp);
    }

    function teamAirdrop(uint256 teamId, bool excludeOwner) payable external {
        require(airdrop_enabled, "Airdrop not Enabled.");
        
        address _addr = msg.sender;
        uint256 _amount = msg.value;
        
        require(_amount >= AIRDROP_MIN, "Mininum airdrop amount not met.");

        // transfer to recipient        
        uint256 project_fee = _amount.mul(AIRDROP).div(PERCENTS_DIVIDER); // tax on airdrop
        uint256 payout = _amount.sub(project_fee);
        if(project_fee > 0){
            project.transfer(project_fee);
        }

        //Make sure _to exists in the system; we increase
        require(teams[teamId].owner != address(0), "team not found");

        uint256 memberDivider = teams[teamId].members.length;
        if(excludeOwner == true){
            memberDivider--;
        }
        uint256 amountDivided = _amount.div(memberDivider);

        for(uint8 i = 0; i < teams[teamId].members.length; i++){

            address _to = address(teams[teamId].members[i]);
            if(excludeOwner == true && _to == teams[teamId].owner){
                continue;
            }
            //Fund to airdrop bonus (not a transfer - user will be able to claim/reinvest)
            airdrops[_to].airdrop_bonus += amountDivided;
    
            //User stats
            airdrops[_addr].airdrops += amountDivided; // sender
            airdrops[_addr].last_airdrop = block.timestamp; // sender
            airdrops[_addr].airdrops_sent += amountDivided; // sender
            airdrops[_addr].airdrops_sent_count = airdrops[_addr].airdrops_sent_count.add(1); // sender add count for airdrop sent count
            airdrops[_to].airdrops_received += amountDivided; // recipient
            airdrops[_to].airdrops_received_count = airdrops[_to].airdrops_received_count.add(1); // recipient add count for airdrop received count
            airdrops[_to].last_airdrop_received = block.timestamp; // recipient

            emit NewAirdrop(_addr, _to, payout, block.timestamp);
        }

        //Keep track of overall stats
        total_airdrops += payout;
    }

    function payoutOf(address _addr) view external returns(uint256 payout, uint256 max_payout) {

        max_payout = this.maxPayoutOf(users[_addr].deposit_amount);

        if(users[_addr].deposit_payouts < max_payout) {

            payout = (users[_addr].deposit_amount.mul(BASE_PERCENT).div(PERCENTS_DIVIDER))
                    .mul(block.timestamp.sub(users[_addr].checkpoint))
                    .div(TIME_STEP);

            if(users[_addr].deposit_payouts.add(payout) > max_payout) {
                payout = max_payout.sub(users[_addr].deposit_payouts);

            }
        }
    }

    function payoutToReinvest(address _addr) view external returns(uint256 payout) {
        
        uint256 max_payout = this.maxPayoutOf(users[_addr].deposit_amount);

        if(users[_addr].deposit_payouts < max_payout) {

            payout = (users[_addr].deposit_amount.mul(BASE_PERCENT).div(PERCENTS_DIVIDER))
                    .mul(block.timestamp.sub(users[_addr].checkpoint))
                    .div(TIME_STEP);

        }            
    
    }

    //max payout per user is 300% including initial investment.
    function maxPayoutOf(uint256 _amount) view external returns(uint256) {
        return _amount.mul(MAX_PAYOUT).div(PERCENTS_DIVIDER);
    }

    function fees(uint256 amount) internal returns(uint256){
        uint256 proj = amount.mul(PROJECT).div(PERCENTS_DIVIDER);
        uint256 market = amount.mul(COMMUNITY).div(PERCENTS_DIVIDER);

        if(KEEP_TAXES_IN_CONTRACT == false){
            //so no transfer will trigger when tax is set to 0.
            if(proj > 0){
                project.transfer(proj);
            }

            if(market > 0){
                community.transfer(market);
            }
        }

        return proj.add(market);
    }

    function withdrawalTaxPercentage(uint256 to_payout) view external returns(uint256 finalPayout) {
      uint256 contractBalance = address(this).balance;
	  
      if (to_payout < contractBalance.mul(10).div(PERCENTS_DIVIDER)) {           // 0% tax if amount is  <  1% of contract balance
          finalPayout = to_payout; 
      }else if(to_payout >= contractBalance.mul(10).div(PERCENTS_DIVIDER)){
          finalPayout = to_payout.sub(to_payout.mul(50).div(PERCENTS_DIVIDER));  // 5% tax if amount is >=  1% of contract balance
      }else if(to_payout >= contractBalance.mul(20).div(PERCENTS_DIVIDER)){
          finalPayout = to_payout.sub(to_payout.mul(100).div(PERCENTS_DIVIDER)); //10% tax if amount is >=  2% of contract balance
      }else if(to_payout >= contractBalance.mul(30).div(PERCENTS_DIVIDER)){
          finalPayout = to_payout.sub(to_payout.mul(150).div(PERCENTS_DIVIDER)); //15% tax if amount is >=  3% of contract balance
      }else if(to_payout >= contractBalance.mul(40).div(PERCENTS_DIVIDER)){
          finalPayout = to_payout.sub(to_payout.mul(200).div(PERCENTS_DIVIDER)); //20% tax if amount is >=  4% of contract balance
      }else if(to_payout >= contractBalance.mul(50).div(PERCENTS_DIVIDER)){
          finalPayout = to_payout.sub(to_payout.mul(250).div(PERCENTS_DIVIDER)); //25% tax if amount is >=  5% of contract balance
      }else if(to_payout >= contractBalance.mul(60).div(PERCENTS_DIVIDER)){
          finalPayout = to_payout.sub(to_payout.mul(300).div(PERCENTS_DIVIDER)); //30% tax if amount is >=  6% of contract balance
      }else if(to_payout >= contractBalance.mul(70).div(PERCENTS_DIVIDER)){
          finalPayout = to_payout.sub(to_payout.mul(350).div(PERCENTS_DIVIDER)); //35% tax if amount is >=  7% of contract balance
      }else if(to_payout >= contractBalance.mul(80).div(PERCENTS_DIVIDER)){
          finalPayout = to_payout.sub(to_payout.mul(400).div(PERCENTS_DIVIDER)); //40% tax if amount is >=  8% of contract balance
      }else if(to_payout >= contractBalance.mul(90).div(PERCENTS_DIVIDER)){
          finalPayout = to_payout.sub(to_payout.mul(450).div(PERCENTS_DIVIDER)); //45% tax if amount is >=  9% of contract balance
      }else if(to_payout >= contractBalance.mul(100).div(PERCENTS_DIVIDER)){
          finalPayout = to_payout.sub(to_payout.mul(500).div(PERCENTS_DIVIDER)); //50% tax if amount is >= 10% of contract balance
      }
    }

    function _createTeam(address userAddress, bool is_referral_team) private returns(uint256 teamId){
        uint8 numberOfExistingTeams = user_teams_counter[userAddress];

        require(numberOfExistingTeams <= MAX_TEAMS_PER_ADDRESS, "Max number of teams reached.");

        teamId = total_teams_created++;
        teams[teamId].id = teamId;
        teams[teamId].created_at = block.timestamp;
        teams[teamId].owner = userAddress;
        teams[teamId].members.push(userAddress);
        teams[teamId].is_referral_team = is_referral_team;

        user_teams[userAddress].push(TeamInfo(teamId, true));

        user_teams_counter[userAddress]++;
    }

    function _addTeamMember(uint256 teamId, address member) private {
        // on private call, there is no limit on memers. if someone has many referras, the referral team can get huge
        // also no check if member is invested since the addTeamMember is used in setUpline before the investment
        Team storage team = teams[teamId];

        team.members.push(member);
        user_teams[member].push(TeamInfo(teamId, true));
        user_teams_counter[member]++;
    }

    function removeUserNickname() external {
        nicknames[msg.sender] = "";
    }
    
    function _checkNickname(string memory name) private view returns (bool){
        name = _toLower(name);
        if(checkAlphaNumericStr(name) == false){
            return false; // illegal characters
        }
        if(bytes(name).length > MAX_LENGTH_NICKNAME){
            return false; // too long str
        }
        for( uint256 i = 0; i < total_users; i++){
            string memory nick = nicknames[id2Address[i]];
            if( strcmp(nick, name)){
                return false;
            }
        }
        return true;
    }

    function getAddressToNickname(string memory name) public view returns (address){
        for( uint256 i = 0; i < total_users; i++){
            string memory nick = nicknames[id2Address[i]];
            if( strcmp(nick, name)){
                return id2Address[i];
            }
        }

        return address(0);
    }

    function getNicknameToAddress(address _addr) public view returns (string memory nick){
        return nicknames[_addr];
    }

    // string helper function --- START
    //
    function memcmp(bytes memory a, bytes memory b) internal pure returns(bool){
        return (a.length == b.length) && (keccak256(a) == keccak256(b));
    }
    function strcmp(string memory a, string memory b) internal pure returns(bool){
        return memcmp(bytes(a), bytes(b));
    }
    
    function _toLower(string memory str) internal pure returns (string memory) {
        bytes memory bStr = bytes(str);
        bytes memory bLower = new bytes(bStr.length);
        for (uint i = 0; i < bStr.length; i++) {
            // Uppercase character...
            if ((uint8(bStr[i]) >= 65) && (uint8(bStr[i]) <= 90)) {
                // So we add 32 to make it lowercase
                bLower[i] = bytes1(uint8(bStr[i]) + 32);
            } else {
                bLower[i] = bStr[i];
            }
        }
        return string(bLower);
    }

    function checkAlphaNumericStr(string memory str) public pure returns (bool){
        bytes memory b = bytes(str);

        for(uint i; i<b.length; i++){
            bytes1 char = b[i];

            if(
                !(char >= 0x30 && char <= 0x39) && //9-0
                !(char >= 0x41 && char <= 0x5A) && //A-Z
                !(char >= 0x61 && char <= 0x7A) //a-z
            ){
                return false;
            }
        }

        return true;
    }
    //
    // string helper functions --- END

    /*
        Only external call
    */

    function setUserNickname(string memory name) external {
        name = _toLower(name);
        require(_checkNickname(name), "nickname not valid");
        nicknames[msg.sender] = name;
    }

    function checkNickname(string memory name) external view returns (bool){
        return _checkNickname(name);
    }

    function userInfo(address _addr) view external returns(address upline, uint256 checkpoint, uint256 deposit_amount, uint256 payouts, uint256 direct_bonus, uint256 pool_bonus, uint256 match_bonus) {
        return (users[_addr].upline, users[_addr].checkpoint, users[_addr].deposit_amount, users[_addr].payouts, users[_addr].direct_bonus, users[_addr].pool_bonus, users[_addr].match_bonus);
    }

    function userInfo2(address _addr) view external returns(uint256 last_airdrop, uint8 teams_counter, TeamInfo[] memory member_of_teams, string memory nickname, uint256 airdrop_bonus) {

        return (airdrops[_addr].last_airdrop, user_teams_counter[_addr], user_teams[_addr], nicknames[_addr], airdrops[_addr].airdrop_bonus);
    }

    function userDirectTeamsInfo(address _addr) view external returns(uint256 referral_team, bool referral_team_exists, uint256 upline_team, bool upline_team_exists) {
        User memory user = users[_addr];

        return (user_referral_team[_addr].id, user_referral_team[_addr].exists, user_referral_team[user.upline].id, user_referral_team[user.upline].exists);
    }

    function teamInfo(uint256 teamId) view external returns(Team memory _team, string[] memory nicks) {
        Team memory team = teams[teamId];
        nicks = new string[](team.members.length);

        for(uint256 i = 0; i < team.members.length; i++){
            nicks[i] = nicknames[team.members[i]];
        }

        return (team, nicks);
    }

    function userInfoTotals(address _addr) view external returns(uint256 referrals, uint256 total_deposits, uint256 total_payouts, uint256 total_structure,uint256 total_downline_deposit, uint256 airdrops_total, uint256 airdrops_received) {
        return (users[_addr].referrals, users[_addr].total_direct_deposits, users[_addr].total_payouts, users[_addr].total_structure, users[_addr].total_downline_deposit, airdrops[_addr].airdrops, airdrops[_addr].airdrops_received);
    }

    function contractInfo() view external returns(uint256 _total_users, uint256 _total_deposited, uint256 _total_withdraw, uint256 _pool_last_draw, uint256 _pool_balance, uint256 _pool_lider, uint256 _total_airdrops) {
        return (total_users, total_deposited, total_withdraw, pool_last_draw, pool_balance, pool_users_refs_deposits_sum[pool_cycle][pool_top[0]], total_airdrops);
    }

    function poolTopInfo() view external returns(address[4] memory addrs, uint256[4] memory deps) {
        for(uint8 i = 0; i < pool_bonuses.length; i++) {
            if(pool_top[i] == address(0)) break;

            addrs[i] = pool_top[i];
            deps[i] = pool_users_refs_deposits_sum[pool_cycle][pool_top[i]];
        }
    }

    function getBlockTimeStamp() public view returns (uint256) {
	    return block.timestamp;
	}	
		
    /** SETTERS **/
    function CHANGE_OWNERSHIP(address value) external {
        require(msg.sender == owner, "Admin use only");
        owner = payable(value);
    }

    function CHANGE_PROJECT_WALLET(address value) external {
        require(msg.sender == owner, "Admin use only");
        project = payable(value);
    }

    function CHANGE_COMMUNITY_WALLET(address value) external {
        require(msg.sender == owner, "Admin use only");
        community = payable(value);
    }

    function CHANGE_KEEP_TAXES_IN_CONTRACT(bool value) external {
        require(msg.sender == owner, "Admin use only");
        KEEP_TAXES_IN_CONTRACT = value;
    }

    function CHANGE_PROJECT_FEE(uint256 value) external {
        require(msg.sender == owner, "Admin use only");
        require(value <= 100);
        PROJECT = value;
    }

    function CHANGE_COMMUNITY_FEE(uint256 value) external {
        require(msg.sender == owner, "Admin use only");
        require(value <= 100);
        COMMUNITY = value;
    }

    function CHANGE_AIRDROP_FEE(uint256 value) external {
        require(msg.sender == owner, "Admin use only");
        require(value <= 100);
        AIRDROP = value;
    }

    function SET_REFERRAL_PERCENT(uint256 value) external {
        require(msg.sender == owner, "Admin use only");
        require(value >= 10 &&value <= 100);
        REFERRAL = value;
    }

    function SET_REINVEST_BONUS(uint256 value) external {
        require(msg.sender == owner, "Admin use only");
        require(value <= 500);
        REINVEST_BONUS = value;
    }

    function SET_MAX_PAYOUT(uint256 value) external {
        require(msg.sender == owner, "Admin use only");
        require(value >= 3000 && value <= 10000); 
        MAX_PAYOUT = value;
    }

    function SET_INVEST_MIN(uint256 value) external {
        require(msg.sender == owner, "Admin use only");
        MIN_INVEST = value;
    }

    function SET_AIRDROP_MIN(uint256 value) external {
        require(msg.sender == owner, "Admin use only");
        AIRDROP_MIN = value;
    }

    function SET_MAX_WALLET_DEPOSIT(uint256 value) external {
        require(msg.sender == owner, "Admin use only");
        MAX_WALLET_DEPOSIT = value * 1 ether;
    }

    function SET_MAX_TEAMS_PER_ADDRESS(uint8 value) external{
        require(msg.sender == owner, "Admin use only");
        require(value >= 1);
        MAX_TEAMS_PER_ADDRESS = value;
    }

    function SET_MAX_LENGTH_NICKNAME(uint8 value) external{
        require(msg.sender == owner, "Admin use only");
        require(value >= 1);
        MAX_LENGTH_NICKNAME = value;
    }

    function SET_MAX_POOL_BALANCE(uint256 value) external{
        require(msg.sender == owner, "Admin use only");
        MAX_POOL_BALANCE = value * 1 ether;
    }
    
    function ENABLE_AIRDROP(bool value) external{
        require(msg.sender == owner, "Admin use only");
        airdrop_enabled = value;
    }

    function SET_BASE_PERCENT(uint256 value) external {
        require(msg.sender == owner, "Admin use only");
        require(value <= 200);
        BASE_PERCENT = value;
    }
}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    /**
    * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}