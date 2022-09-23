/**
 *Submitted for verification at snowtrace.io on 2022-04-21
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.5;

interface IERC20 {
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

library SafeERC20 {
    using SafeMath for uint256;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
    }

    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function callOptionalReturn(IERC20 token, bytes memory data) private {
        require(isContract(address(token)), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(
                abi.decode(returndata, (bool)),
                "SafeERC20: ERC20 operation did not succeed"
            );
        }
    }

    function isContract(address addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }
}

//===============================================================================================================================================

contract MULTIFURY_TOKENv1 {
    using SafeERC20 for IERC20;

    IERC20 public token;

    //accept funds from external
    receive() external payable {}

    uint256 public startDate;
    address payable public WALLET_PROJECT;
    address payable public WALLET_MARKETING;
    address payable public WALLET_FUND;
    address payable public WALLET_SPONSOR;

    uint256 public constant PERCENTS_DIVIDER = 1000;
    uint256 public constant TIME_STEP = 1 days;
    uint256 public constant INVEST_MIN_AMOUNT = 2 * (10**4); // 0.0002 BTC
    uint256[] public REFERRAL_PERCENTS = [70, 30, 20, 10, 5]; // 7% 3% 2% 1% 0.5%

    uint256 public constant PROJECT_FEE = 30; // project fee 3% of deposit
    uint256 public constant MARKETING_FEE = 30; // marketing fee 3% of deposit
    uint256 public constant FUND_FEE = 30; // fund fee 3% of deposit
    uint256 public constant SPONSOR_FEE = 30; // sponsor fee 3% of deposit

    uint256 public constant MAX_WITHDRAW_AMOUNT = 2 * (10**6); // claim 0.02 BTC max
    uint256 public constant WITHDRAW_COOLDOWN = TIME_STEP / 4; // claim 4 times per day
    uint256 public constant REINVEST_PERCENT = 100; // auto reinvest 10% of claim

    mapping(uint256 => THistoryDeposit) public DEPOSIT_HISTORY;
    uint256 public TOTAL_DEPOSITS;
    uint256 public TOTAL_INVESTED;
    uint256 public TOTAL_REFDIVIDENDS;
    uint256 public TOTAL_CLAIMED;

    struct TPlan {
        uint256 durationDays;
        uint256 percent;
    }

    struct TDeposit {
        uint256 planIdx;
        uint256 amount;
        uint256 timeStart;
        uint256 timeEnd;
        bool isReinvest;
    }

    struct THistoryDeposit {
        uint256 timestamp;
        uint256 duration;
        uint256 amount;
    }

    struct TUser {
        uint256 checkpoint;
        TDeposit[] deposits;
        TDeposit[] depHistory;
        uint256[5] refCount;
        address referrer;
        uint256 refDividends;
        uint256 debtBuffer;
        uint256 totalInvested;
        uint256 totalRefDividends;
        uint256 totalClaimed;
    }

    TPlan[] public PLANS;
    mapping(address => TUser) public USERS;

    event ProjectFeePaid(uint256 amount);
    event MarketingFeePaid(uint256 amount);
    event FundFeePaid(uint256 amount);
    event SponsorFeePaid(uint256 amount);
    event Reinvested(uint256 amount);
    event InsuranseFeePaid(uint256 amount);
    event Claimed(address user, uint256 amount);
    event InitiateInsurance(uint256 high, uint256 current);
    event RefInvited(address referrer, address user);
    event RefDividends(
        address referrer,
        address user,
        uint256 refLevel,
        uint256 amount
    );
    event Newcomer(address user);
    event NewDeposit(address user, uint256 planIdx, uint256 amount);

    uint256 public stat_maxDepositArrayLength;
    address public stat_maxDepositArrayUser;
    uint256 public stat_depositsReusedCounter;

    //-------------------------------------------------------------------------------------------------------------------------------------------

    constructor(
        address _tokenAddress,
        address payable _walletMarketing,
        address payable _walletFund,
        address payable _walletSponsor,
        uint256 startTime
    ) {
        WALLET_PROJECT = payable(msg.sender);
        WALLET_MARKETING = _walletMarketing;
        WALLET_FUND = _walletFund;
        WALLET_SPONSOR = _walletSponsor;

        if (startTime > 0) {
            startDate = startTime;
        } else {
            startDate = block.timestamp;
        }

        token = IERC20(_tokenAddress);

        PLANS.push(TPlan(7, 200));
        PLANS.push(TPlan(8, 184));
        PLANS.push(TPlan(9, 171));
        PLANS.push(TPlan(10, 161));
        PLANS.push(TPlan(11, 152));
        PLANS.push(TPlan(12, 145));
        PLANS.push(TPlan(13, 140));
        PLANS.push(TPlan(14, 135));
        PLANS.push(TPlan(15, 130));
        PLANS.push(TPlan(16, 126));
        PLANS.push(TPlan(17, 123));
        PLANS.push(TPlan(18, 120));
        PLANS.push(TPlan(19, 117));
        PLANS.push(TPlan(20, 115));
        PLANS.push(TPlan(21, 113));
        PLANS.push(TPlan(22, 111));
        PLANS.push(TPlan(23, 109));
        PLANS.push(TPlan(24, 107));
        PLANS.push(TPlan(25, 106));
        PLANS.push(TPlan(26, 104));
        PLANS.push(TPlan(27, 103));
        PLANS.push(TPlan(28, 102));
        PLANS.push(TPlan(29, 101));
        PLANS.push(TPlan(30, 100));
    }

    //-------------------------------------------------------------------------------------------------------------------------------------------

    function invest(
        address _referrer,
        uint8 _planIdx,
        uint256 amount
    ) public {
        require(amount >= INVEST_MIN_AMOUNT, "The deposit amount is too low");
        require(_planIdx < PLANS.length, "Invalid plan index");
        require(block.timestamp > startDate, "contract does not launch yet");

        require(amount <= token.allowance(msg.sender, address(this)));
        token.safeTransferFrom(msg.sender, address(this), amount);

        //transfer project fee
        uint256 pfee = (amount * PROJECT_FEE) / PERCENTS_DIVIDER;
        token.safeTransfer(WALLET_PROJECT, pfee);
        emit ProjectFeePaid(pfee);

        //transfer marketing fee
        uint256 mfee = (amount * MARKETING_FEE) / PERCENTS_DIVIDER;
        token.safeTransfer(WALLET_MARKETING, mfee);
        emit MarketingFeePaid(mfee);

        //transfer fund fee
        uint256 ffee = (amount * FUND_FEE) / PERCENTS_DIVIDER;
        token.safeTransfer(WALLET_FUND, ffee);
        emit FundFeePaid(ffee);

        //transfer sponsor fee
        uint256 sfee = (amount * SPONSOR_FEE) / PERCENTS_DIVIDER;
        token.safeTransfer(WALLET_SPONSOR, sfee);
        emit SponsorFeePaid(sfee);

        _setUserReferrer(msg.sender, _referrer);

        _allocateReferralRewards(msg.sender, amount);

        _createDeposit(msg.sender, _planIdx, amount, false);
    }

    //-------------------------------------------------------------------------------------------------------------------------------------------

    function claim() public {
        TUser storage user = USERS[msg.sender];

        uint256 claimAmount = _getUserDividends(msg.sender) +
            user.refDividends +
            user.debtBuffer;

        require(claimAmount > 0, "Nothing to withdraw");
        require(_canClaim(msg.sender), "Claim cooldown");

        user.checkpoint = block.timestamp; //clear accumulated dividends
        user.refDividends = 0; //clear refDividends
        user.debtBuffer = 0; //clear debtBuffer

        //not enough contract balance? give what we can, promise to refund later
        uint256 balance = token.balanceOf(address(this));
        if (claimAmount > balance) {
            user.debtBuffer += claimAmount - balance;
            claimAmount = balance;
        }

        //anti-whale protection
        if (claimAmount > MAX_WITHDRAW_AMOUNT) {
            user.debtBuffer += claimAmount - MAX_WITHDRAW_AMOUNT;
            claimAmount = MAX_WITHDRAW_AMOUNT;
        }

        //reinvest
        uint256 reinvestAmount = (claimAmount * REINVEST_PERCENT) /
            PERCENTS_DIVIDER;
        _createDeposit(msg.sender, 0, reinvestAmount, true);
        emit Reinvested(reinvestAmount);

        claimAmount -= reinvestAmount;

        //withdraw to user wallet
        user.totalClaimed += claimAmount;
        TOTAL_CLAIMED += claimAmount;
        token.safeTransfer(msg.sender, claimAmount);
        emit Claimed(msg.sender, claimAmount);
    }

    function UpdateStartDate(uint256 _startDate) public {
        require(
            msg.sender == WALLET_PROJECT,
            "Only developer can update start date"
        );
        require(block.timestamp < startDate, "Start date must be in future");
        startDate = _startDate;
    }

    //-------------------------------------------------------------------------------------------------------------------------------------------

    function _canClaim(address _user) internal view returns (bool) {
        return (block.timestamp - USERS[_user].checkpoint >= WITHDRAW_COOLDOWN);
    }

    //-------------------------------------------------------------------------------------------------------------------------------------------
    //-------------------------------------------------------------------------------------------------------------------------------------------

    function _setUserReferrer(address _user, address _referrer) internal {
        if (USERS[_user].referrer != address(0)) return; //already has a referrer
        if (USERS[_referrer].deposits.length == 0) return; //referrer doesnt exist
        if (_user == _referrer) return; //cant refer to yourself

        //adopt
        USERS[_user].referrer = _referrer;

        //loop through the referrer hierarchy, increase every referral Levels counter
        address upline = USERS[_user].referrer;
        for (uint256 i = 0; i < REFERRAL_PERCENTS.length; i++) {
            if (upline == address(0)) break;
            USERS[upline].refCount[i]++;
            upline = USERS[upline].referrer;
        }

        emit RefInvited(_referrer, _user);
    }

    //-------------------------------------------------------------------------------------------------------------------------------------------

    function _allocateReferralRewards(address _user, uint256 _depositAmount)
        internal
    {
        uint256 refsamount;
        //loop through the referrer hierarchy, allocate refDividends
        address upline = USERS[_user].referrer;
        for (uint256 i = 0; i < REFERRAL_PERCENTS.length; i++) {
            if (upline != address(0)) {
                uint256 amount = (_depositAmount * REFERRAL_PERCENTS[i]) /
                    PERCENTS_DIVIDER;
                USERS[upline].refDividends += amount;
                USERS[upline].totalRefDividends += amount;
                TOTAL_REFDIVIDENDS += amount;
                upline = USERS[upline].referrer;
                emit RefDividends(upline, _user, i, amount);
            } else {
                uint256 amount = (_depositAmount * REFERRAL_PERCENTS[i]) /
                    PERCENTS_DIVIDER;
                refsamount += amount;
                TOTAL_REFDIVIDENDS += amount;
            }
        }
        if (refsamount > 0) {
            token.safeTransfer(WALLET_MARKETING, refsamount / 4);
            token.safeTransfer(WALLET_FUND, refsamount / 4);
            token.safeTransfer(WALLET_PROJECT, refsamount / 4);
            token.safeTransfer(WALLET_SPONSOR, refsamount / 4);
        }
    }

    //-------------------------------------------------------------------------------------------------------------------------------------------

    function _createDeposit(
        address _user,
        uint256 _planIdx,
        uint256 _amount,
        bool _isReinvest
    ) internal returns (uint256 o_depIdx) {
        TUser storage user = USERS[_user];

        //first deposit: set initial checkpoint
        if (user.deposits.length == 0) {
            user.checkpoint = block.timestamp;
            emit Newcomer(_user);
        }

        TDeposit memory newDep = TDeposit(
            _planIdx,
            _amount,
            block.timestamp,
            block.timestamp + PLANS[_planIdx].durationDays * TIME_STEP,
            _isReinvest
        );

        //reuse a deceased slot or create new
        bool found;
        for (uint256 i = 0; i < user.deposits.length; i++) {
            if (_isDepositDeceased(_user, i)) {
                user.deposits[i] = newDep;
                o_depIdx = i;
                found = true;
                stat_depositsReusedCounter++;
                break;
            }
        }
        if (!found) {
            o_depIdx = user.deposits.length;
            user.deposits.push(newDep);
        }

        //if not reinvest - update global stats
        if (!_isReinvest) {
            user.depHistory.push(newDep);
            user.totalInvested += _amount;
            DEPOSIT_HISTORY[TOTAL_DEPOSITS] = THistoryDeposit(
                block.timestamp,
                PLANS[_planIdx].durationDays * TIME_STEP,
                _amount
            );
            TOTAL_DEPOSITS++;
            TOTAL_INVESTED += _amount;
        }

        //technical data
        if (stat_maxDepositArrayLength < user.deposits.length) {
            stat_maxDepositArrayLength = user.deposits.length;
            stat_maxDepositArrayUser = _user;
        }

        emit NewDeposit(_user, newDep.planIdx, newDep.amount);
    }

    //-------------------------------------------------------------------------------------------------------------------------------------------

    function _isDepositDeceased(address _user, uint256 _depIdx)
        internal
        view
        returns (bool)
    {
        return (USERS[_user].checkpoint >=
            USERS[_user].deposits[_depIdx].timeEnd);
    }

    //-------------------------------------------------------------------------------------------------------------------------------------------

    function _calculateDepositDividends(address _user, uint256 _depIdx)
        internal
        view
        returns (uint256 o_amount)
    {
        /* use _isDepositDeceased before calling this function to save gas */

        TUser storage user = USERS[_user];
        TDeposit storage deposit = user.deposits[_depIdx];

        //calculate withdrawable dividends starting from the last Claim checkpoint
        uint256 totalReward = (deposit.amount *
            PLANS[deposit.planIdx].percent) / PERCENTS_DIVIDER;
        uint256 timeA = deposit.timeStart > user.checkpoint
            ? deposit.timeStart
            : user.checkpoint;
        uint256 timeB = deposit.timeEnd < block.timestamp
            ? deposit.timeEnd
            : block.timestamp;
        if (timeA < timeB) {
            o_amount = (totalReward * (timeB - timeA)) / TIME_STEP;
        }
    }

    //-------------------------------------------------------------------------------------------------------------------------------------------

    function _getUserDividends(address _user)
        internal
        view
        returns (uint256 o_amount)
    {
        for (uint256 i = 0; i < USERS[_user].deposits.length; i++) {
            if (_isDepositDeceased(_user, i)) continue;
            o_amount += _calculateDepositDividends(_user, i);
        }
    }

    //-------------------------------------------------------------------------------------------------------------------------------------------

    function getProjectInfo()
        public
        view
        returns (
            uint256 o_totDeposits,
            uint256 o_totInvested,
            uint256 o_totRefDividends,
            uint256 o_totClaimed,
            uint256 o_timestamp
        )
    {
        return (
            TOTAL_DEPOSITS,
            TOTAL_INVESTED,
            TOTAL_REFDIVIDENDS,
            TOTAL_CLAIMED,
            block.timestamp
        );
    }

    function getDepositHistory()
        public
        view
        returns (
            THistoryDeposit[20] memory o_historyDeposits,
            uint256 o_timestamp
        )
    {
        o_timestamp = block.timestamp;
        uint256 _from = TOTAL_DEPOSITS >= 20 ? TOTAL_DEPOSITS - 20 : 0;
        for (uint256 i = _from; i < TOTAL_DEPOSITS; i++) {
            o_historyDeposits[i - _from] = DEPOSIT_HISTORY[i];
        }
    }

    //-------------------------------------------------------------------------------------------------------------------------------------------

    struct TPlanInfo {
        uint256 dividends;
        uint256 mActive;
        uint256 rActive;
    }

    struct TRefInfo {
        uint256[5] count;
        uint256 dividends;
        uint256 totalEarned;
    }

    struct TUserInfo {
        uint256 claimable;
        uint256 checkpoint;
        uint256 totalDepositCount;
        uint256 totalInvested;
        uint256 totalClaimed;
    }

    function getUserInfo(address _user)
        public
        view
        returns (
            TPlanInfo memory o_planInfo,
            TRefInfo memory o_refInfo,
            TUserInfo memory o_userInfo,
            uint256 o_timestamp
        )
    {
        o_timestamp = block.timestamp;

        TUser storage user = USERS[_user];

        //active invest/reinvest deposits
        for (uint256 i = 0; i < user.deposits.length; i++) {
            if (_isDepositDeceased(_user, i)) continue;
            o_planInfo.dividends += _calculateDepositDividends(_user, i);
            if (!user.deposits[i].isReinvest) {
                o_planInfo.mActive++;
            } else {
                o_planInfo.rActive++;
            }
        }

        //referral stats
        o_refInfo.count = user.refCount;
        o_refInfo.dividends = user.refDividends;
        o_refInfo.totalEarned = user.totalRefDividends;

        //user stats
        o_userInfo.claimable =
            o_planInfo.dividends +
            o_refInfo.dividends +
            user.debtBuffer;
        o_userInfo.checkpoint = user.checkpoint;
        o_userInfo.totalInvested = user.totalInvested;
        o_userInfo.totalDepositCount = user.depHistory.length;
        o_userInfo.totalClaimed = user.totalClaimed;
    }

    function getUserDepositHistory(address _user, uint256 _numBack)
        public
        view
        returns (
            TDeposit[5] memory o_deposits,
            uint256 o_total,
            uint256 o_idxFrom,
            uint256 o_idxTo,
            uint256 o_timestamp
        )
    {
        o_timestamp = block.timestamp;
        o_total = USERS[_user].depHistory.length;
        o_idxFrom = (o_total > _numBack * 5) ? (o_total - _numBack * 5) : 0;
        uint256 _cut = (o_total < _numBack * 5) ? (_numBack * 5 - o_total) : 0;
        o_idxTo = (o_idxFrom + 5 < o_total) ? (o_idxFrom + 5) - _cut : o_total;
        for (uint256 i = o_idxFrom; i < o_idxTo; i++) {
            o_deposits[i - o_idxFrom] = USERS[_user].depHistory[i];
        }
    }

    //-------------------------------------------------------------------------------------------------------------------------------------------

    /* MOONARCH INTERFACE */

    function getUserAvailable(address _user) public view returns (uint256) {
        if (!_canClaim(_user)) return 0;
        (, , TUserInfo memory userInfo, ) = getUserInfo(_user);
        return userInfo.claimable;
    }

    function getUserCheckpoint(address _user) public view returns (uint256) {
        return USERS[_user].checkpoint;
    }

    function getContractBalance() public view returns (uint256) {
        return token.balanceOf(address(this));
    }

    function withdraw() public {
        claim();
    }
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
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
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;

        return c;
    }
}