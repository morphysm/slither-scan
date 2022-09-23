/**
 *Submitted for verification at testnet.snowtrace.io on 2022-05-18
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.5;

//===============================================================================================================================================

interface IInsuranceContract {
	function initiate() external;
	function getBalance() external view returns(uint);
	function getMainContract() external view returns(address);
}

contract INSURANCE {

	//accept funds from MainContract
	receive() external payable {}
	address payable public MAINCONTRACT;

	constructor() {
		MAINCONTRACT = payable(msg.sender);
	}

	function initiate() public {
		require(msg.sender == MAINCONTRACT, "Forbidden");
		uint balance = address(this).balance;
		if(balance==0) return;
		MAINCONTRACT.transfer(balance);
	}

	function getBalance() public view returns(uint) {
		return address(this).balance;
	}

	function getMainContract() public view returns(address) {
		return MAINCONTRACT;
	}

}

//===============================================================================================================================================

contract Alize {

	//accept funds from Insurance
	receive() external payable {}

	bool public						LAUNCHED;
	address payable public			WALLET_PROJECT;
	address payable public			WALLET_DEV;
	uint constant public			PERCENTS_DIVIDER				= 10000;
	uint constant public			TIME_STEP						= 3600;
	uint constant public			INVEST_MIN_AMOUNT				= 0.01 ether;			// 0.01 BNB
    uint constant public			INVEST_MAX_AMOUNT				= 100 ether;			// 100 BNB
	uint[] public					REFERRAL_PERCENTS				= [200, 100, 50, 20, 10];	// 2% 1% 0.5% 0.2% 0.1%
	uint constant public			PROJECT_FEE						= 500;					// project fee 5% of deposit
    uint constant public			PROJECT_REINVEST_FEE			= 200;					// project fee 2% of reinvest
	uint constant public			DEV_FEE							= 100;					// dev fee 1% of deposit
	uint constant public			DAILY_LIMIT						= 10 ether;				// limit 10 BNB per day
	address payable public			INSURANCE_CONTRACT;
	mapping (uint => uint) public	INSURANCE_MAXBALANCE;
	uint constant public			INSURANCE_PERCENT				= 200;					// insurance fee 2% of claim
	uint constant public			INSURANCE_LOWBALANCE_PERCENT	= 2500;					// protection kicks in at 25% or lower
	uint constant public			REINVEST_PERCENT				= 100;					// auto reinvest 1% of claim

	mapping (uint => THistoryDeposit) public DEPOSIT_HISTORY;
	mapping (uint256 => mapping(address => uint256)) public dLimit;
	uint public TOTAL_DEPOSITS;
	uint public TOTAL_INVESTED;
	uint public TOTAL_REFDIVIDENDS;
	uint public TOTAL_CLAIMED;
	uint public INSURANCE_TRIGGER_BALANCE;
	

	struct TPlan {
		uint durationDays;
		uint percent;
	}

	struct TDeposit {
		uint planIdx;
		uint amount;
		uint timeStart;
		uint timeEnd;
		bool isReinvest;
	}

	struct THistoryDeposit {
		uint timestamp;
		uint duration;
		uint amount;
	}

	struct TUser {
		uint		checkpoint;
		TDeposit[]	deposits;
		TDeposit[]	depHistory;
		uint[5]		refCount;
		address referrer;
		uint refDividends;
		uint debtBuffer;
		uint totalInvested;
		uint totalRefDividends;
		uint totalClaimed;
	}


	TPlan[] public						PLANS;
	mapping( address => TUser ) public	USERS;

	event ProjectFeePaid(uint amount);
	event DevFeePaid(uint amount);
	event Reinvested(uint amount);
	event InsuranseFeePaid(uint amount);
	event Claimed(address user, uint amount);
	event InitiateInsurance(uint high, uint current);
	event RefInvited(address referrer, address user);
	event RefDividends(address referrer, address user, uint refLevel, uint amount);
	event Newcomer(address user);
	event NewDeposit(address user, uint planIdx, uint amount);

	uint public		stat_maxDepositArrayLength;
	address public	stat_maxDepositArrayUser;
	uint public		stat_depositsReusedCounter;

	//-------------------------------------------------------------------------------------------------------------------------------------------

	constructor() {

		INSURANCE_CONTRACT = payable(new INSURANCE());
		WALLET_PROJECT = payable(0x4D6399a0C4161b2e58BBdb8560760088457702A0);
		WALLET_DEV     = payable(0x4D6399a0C4161b2e58BBdb8560760088457702A0);

		PLANS.push( TPlan(8,1300) );
		PLANS.push( TPlan(10,1050) );
		PLANS.push( TPlan(12,883) );
		PLANS.push( TPlan(14,764) );
		PLANS.push( TPlan(16,675) );
		PLANS.push( TPlan(18,605) );
		PLANS.push( TPlan(20,550) );
		PLANS.push( TPlan(22,504) );
        PLANS.push( TPlan(24,466) );

	}

	//-------------------------------------------------------------------------------------------------------------------------------------------

	function invest(address _referrer, uint8 _planIdx) public payable {

		require(msg.value >= INVEST_MIN_AMOUNT, "Minimum amount is 0.01 BNB");
        require(msg.value <= INVEST_MAX_AMOUNT, "Maximum amount is 50 BNB");
		require(_planIdx < PLANS.length, "Invalid plan index");
		if(!LAUNCHED) {
			require(msg.sender == WALLET_PROJECT, "Project has not launched yet");
			LAUNCHED = true;
		}

		//transfer project fee
		uint pfee = msg.value * PROJECT_FEE / PERCENTS_DIVIDER;
		WALLET_PROJECT.transfer(pfee);
		emit ProjectFeePaid(pfee);

		//transfer dev fee
		uint mfee = msg.value * DEV_FEE / PERCENTS_DIVIDER;
		WALLET_DEV.transfer(mfee);
		emit DevFeePaid(mfee);

		_setUserReferrer(msg.sender, _referrer);

		_allocateReferralRewards(msg.sender, msg.value);

		_createDeposit( msg.sender, _planIdx, msg.value, false );

		_insuranceTrigger();
		
	}

	//-------------------------------------------------------------------------------------------------------------------------------------------

	function claim() public {

		TUser storage user = USERS[msg.sender];

		uint claimAmount = _getUserDividends(msg.sender) + user.refDividends + user.debtBuffer;

		require(claimAmount > 0, "Nothing to withdraw");
		require(dLimit[cDay()][msg.sender] + claimAmount <= DAILY_LIMIT, "only 10 BNB per day");
        dLimit[cDay()][msg.sender] += claimAmount;

		user.checkpoint = block.timestamp;	//clear accumulated dividends
		user.refDividends = 0;				//clear refDividends
		user.debtBuffer = 0;				//clear debtBuffer


		//not enough contract balance? give what we can, promise to refund later
		uint balance = address(this).balance;
		if (claimAmount > balance) {
			user.debtBuffer += claimAmount - balance;
			claimAmount = balance;
		}

		//insurance
		uint insuranceAmount = claimAmount * INSURANCE_PERCENT / PERCENTS_DIVIDER;
		payable(INSURANCE_CONTRACT).transfer( insuranceAmount );
		emit InsuranseFeePaid(insuranceAmount);

		//reinvest
		uint reinvestAmount = claimAmount * REINVEST_PERCENT / PERCENTS_DIVIDER;
        uint pfee = reinvestAmount * PROJECT_REINVEST_FEE / PERCENTS_DIVIDER;
		_createDeposit( msg.sender, 0, reinvestAmount, true );
        WALLET_PROJECT.transfer(pfee);
        emit ProjectFeePaid(pfee);
		emit Reinvested(reinvestAmount);

		claimAmount -= insuranceAmount;
		claimAmount -= reinvestAmount;

		//withdraw to user wallet
		user.totalClaimed += claimAmount;
		TOTAL_CLAIMED += claimAmount;
		payable(msg.sender).transfer( claimAmount );
		emit Claimed(msg.sender, claimAmount );

		_insuranceTrigger();

	}

	function _insuranceTrigger() internal {

		uint balance = address(this).balance;
		uint todayIdx = block.timestamp/TIME_STEP;

		//new high today
		if ( INSURANCE_MAXBALANCE[todayIdx] < balance ) {
			INSURANCE_MAXBALANCE[todayIdx] = balance;
		}

		//high of past 7 days
		uint rangeHigh;
		for( uint i=0; i<7; i++) {
			if( INSURANCE_MAXBALANCE[todayIdx-i] > rangeHigh ) {
				rangeHigh = INSURANCE_MAXBALANCE[todayIdx-i];
			}
		}

		INSURANCE_TRIGGER_BALANCE = rangeHigh*INSURANCE_LOWBALANCE_PERCENT/PERCENTS_DIVIDER;

		//low balance - initiate Insurance
		if( balance < INSURANCE_TRIGGER_BALANCE ) {
			emit InitiateInsurance( rangeHigh, balance );
			IInsuranceContract(INSURANCE_CONTRACT).initiate();
		}
	}

	//-------------------------------------------------------------------------------------------------------------------------------------------

	function _setUserReferrer(address _user, address _referrer) internal {

		if (USERS[_user].referrer != address(0)) return;	//already has a referrer
		if (USERS[_referrer].deposits.length == 0) return;	//referrer doesnt exist
		if (_user == _referrer) return;						//cant refer to yourself

		//adopt
		USERS[_user].referrer = _referrer;

		//loop through the referrer hierarchy, increase every referral Levels counter
		address upline = USERS[_user].referrer;
		for (uint i=0; i < REFERRAL_PERCENTS.length; i++) {
			if(upline==address(0)) break;
			USERS[upline].refCount[i]++;
			upline = USERS[upline].referrer;
		}

		emit RefInvited(_referrer,_user);
	}

	//-------------------------------------------------------------------------------------------------------------------------------------------

	function _allocateReferralRewards(address _user, uint _depositAmount) internal {

		//loop through the referrer hierarchy, allocate refDividends
		address upline = USERS[_user].referrer;
		for (uint i=0; i < REFERRAL_PERCENTS.length; i++) {
			if (upline == address(0)) break;
			uint amount = _depositAmount * REFERRAL_PERCENTS[i] / PERCENTS_DIVIDER;
			USERS[upline].refDividends += amount;
			USERS[upline].totalRefDividends += amount;
			TOTAL_REFDIVIDENDS += amount;
			upline = USERS[upline].referrer;
			emit RefDividends(upline, _user, i, amount);
		}
	}

	//-------------------------------------------------------------------------------------------------------------------------------------------

	function _createDeposit( address _user, uint _planIdx, uint _amount, bool _isReinvest ) internal returns(uint o_depIdx) {

		TUser storage user = USERS[_user];

		//first deposit: set initial checkpoint
		if (user.deposits.length == 0) {
			user.checkpoint = block.timestamp;
			emit Newcomer(_user);
		}

		TDeposit memory newDep = TDeposit( _planIdx, _amount, block.timestamp, block.timestamp + PLANS[_planIdx].durationDays * TIME_STEP, _isReinvest );

		//reuse a deceased slot or create new
		bool found;
		for(uint i=0; i<user.deposits.length; i++) {
			if(_isDepositDeceased(_user,i)) {
				user.deposits[i] = newDep;
				o_depIdx=i;
				found=true;
				stat_depositsReusedCounter++;
				break;
			}
		}
		if(!found) {
		o_depIdx=user.deposits.length;
		user.deposits.push(newDep);
		}

		//if not reinvest - update global stats
		if(!_isReinvest) {
			user.depHistory.push(newDep);
			user.totalInvested += _amount;
			DEPOSIT_HISTORY[TOTAL_DEPOSITS] = THistoryDeposit( block.timestamp, PLANS[_planIdx].durationDays*TIME_STEP, _amount );
			TOTAL_DEPOSITS++;
			TOTAL_INVESTED += _amount;
		}

		//technical data
 		if(stat_maxDepositArrayLength < user.deposits.length) {
			stat_maxDepositArrayLength = user.deposits.length;
			stat_maxDepositArrayUser = _user;
		}

		emit NewDeposit(_user, newDep.planIdx, newDep.amount);
	}

	//-------------------------------------------------------------------------------------------------------------------------------------------

	function _isDepositDeceased(address _user, uint _depIdx) internal view returns(bool) {
		return (USERS[_user].checkpoint >= USERS[_user].deposits[_depIdx].timeEnd);
	}

	//-------------------------------------------------------------------------------------------------------------------------------------------

	function _calculateDepositDividends(address _user, uint _depIdx) internal view returns (uint o_amount) {

		/* use _isDepositDeceased before calling this function to save gas */

		TUser storage user = USERS[_user];
		TDeposit storage deposit = user.deposits[_depIdx];

		//calculate withdrawable dividends starting from the last Claim checkpoint
		uint totalReward = deposit.amount * PLANS[deposit.planIdx].percent / PERCENTS_DIVIDER;
		uint timeA = deposit.timeStart > user.checkpoint ? deposit.timeStart : user.checkpoint;
		uint timeB = deposit.timeEnd < block.timestamp ? deposit.timeEnd : block.timestamp;
		if (timeA < timeB) {
			o_amount = totalReward * (timeB-timeA) / TIME_STEP;
		}
	}

	//-------------------------------------------------------------------------------------------------------------------------------------------

	function _getUserDividends(address _user) internal view returns (uint o_amount) {

		for(uint i=0;i<USERS[_user].deposits.length;i++) {
			if(_isDepositDeceased(_user,i)) continue;
			o_amount += _calculateDepositDividends(_user,i);
		}

	}

	//-------------------------------------------------------------------------------------------------------------------------------------------

	function cDay() public view returns(uint256) {
		return (block.timestamp / (24 * TIME_STEP));
	}

	//-------------------------------------------------------------------------------------------------------------------------------------------

	function getProjectInfo() public view returns(uint o_totDeposits, uint o_totInvested, uint o_totRefDividends, uint o_totClaimed, uint o_ensBalance, uint o_ensTriggerBalance, uint o_timestamp) {

		uint insuranceBalance = IInsuranceContract(INSURANCE_CONTRACT).getBalance();
		return( TOTAL_DEPOSITS, TOTAL_INVESTED, TOTAL_REFDIVIDENDS, TOTAL_CLAIMED, insuranceBalance, INSURANCE_TRIGGER_BALANCE, block.timestamp );
	}

	function getDepositHistory() public view returns(THistoryDeposit[20] memory o_historyDeposits, uint o_timestamp) {

		o_timestamp = block.timestamp;
		uint _from = TOTAL_DEPOSITS>=20 ? TOTAL_DEPOSITS-20 : 0;
		for(uint i=_from; i<TOTAL_DEPOSITS; i++) {
			o_historyDeposits[i-_from] = DEPOSIT_HISTORY[i];
		}
	}

	//-------------------------------------------------------------------------------------------------------------------------------------------

	struct TPlanInfo {
		uint dividends;
		uint mActive;
		uint rActive;
	}

	struct TRefInfo {
		uint[5] count;
		uint dividends;
		uint totalEarned;
	}

	struct TUserInfo {
		uint claimable;
		uint checkpoint;
		uint totalDepositCount;
		uint totalInvested;
		uint totalClaimed;
	}

	function getUserInfo(address _user) public view returns (TPlanInfo memory o_planInfo, TRefInfo memory o_refInfo, TUserInfo memory o_userInfo, uint o_timestamp) {

		o_timestamp = block.timestamp;

		TUser storage user = USERS[_user];

		//active invest/reinvest deposits
		for(uint i=0; i<user.deposits.length; i++) {
			if(_isDepositDeceased(_user,i)) continue;
			o_planInfo.dividends += _calculateDepositDividends(_user,i);
			if(!user.deposits[i].isReinvest){ o_planInfo.mActive++; }
			else							{ o_planInfo.rActive++; }
		}

		//referral stats
		o_refInfo.count = user.refCount;
		o_refInfo.dividends = user.refDividends;
		o_refInfo.totalEarned = user.totalRefDividends;

		//user stats
		o_userInfo.claimable = o_planInfo.dividends + o_refInfo.dividends + user.debtBuffer;
		o_userInfo.checkpoint = user.checkpoint;
		o_userInfo.totalInvested = user.totalInvested;
		o_userInfo.totalDepositCount = user.depHistory.length;
		o_userInfo.totalClaimed = user.totalClaimed;

	}

	function getUserDepositHistory(address _user, uint _numBack) public view returns(TDeposit[5] memory o_deposits, uint o_total, uint o_idxFrom, uint o_idxTo, uint o_timestamp) {

		o_timestamp = block.timestamp;
		o_total = USERS[_user].depHistory.length;
		o_idxFrom = (o_total > _numBack*5) ? (o_total - _numBack*5) : 0;
		uint _cut = (o_total < _numBack*5) ? (_numBack*5 - o_total) : 0;
		o_idxTo = (o_idxFrom+5 < o_total) ? (o_idxFrom+5) - _cut : o_total;
		for(uint i=o_idxFrom; i<o_idxTo; i++) {
			o_deposits[i-o_idxFrom] = USERS[_user].depHistory[i];
		}

	}

	//-------------------------------------------------------------------------------------------------------------------------------------------

	/* MOONARCH INTERFACE */

	function getUserAvailable(address _user) public view returns(uint) {
		(,,TUserInfo memory userInfo,) = getUserInfo(_user);
		return userInfo.claimable;
	}

	function getUserCheckpoint(address _user) public view returns(uint) {
		return USERS[_user].checkpoint;
	}

	function getUserDailyLimit(address _user) public view returns(uint) {
		return dLimit[cDay()][_user];
	}

	function getContractBalance() public view returns(uint) {
		uint insuranceBalance = IInsuranceContract(INSURANCE_CONTRACT).getBalance();
		return address(this).balance + insuranceBalance;
	}

	function withdraw() public {
		claim();
	}

	//invest(address _referrer, uint8 _planIdx)

	//-------------------------------------------------------------------------------------------------------------------------------------------

}

//===============================================================================================================================================