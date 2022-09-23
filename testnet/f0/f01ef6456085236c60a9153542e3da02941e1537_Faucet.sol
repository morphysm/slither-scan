// SPDX-License-Identifier: MIT

pragma solidity >= 0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

interface ISwap {
    function getInputPrice(
        uint256 input_amount,
        uint256 input_reserve,
        uint256 output_reserve
    ) external view returns (uint256);
    function getOutputPrice(
        uint256 output_amount,
        uint256 input_reserve,
        uint256 output_reserve
    ) external view returns (uint256);
    function trxToTokenSwapInput(uint256 min_tokens)
    external
    payable
    returns (uint256);
    function trxToTokenSwapOutput(uint256 tokens_bought)
    external
    payable
    returns (uint256);
    function tokenToTrxSwapInput(uint256 tokens_sold, uint256 min_trx)
    external
    returns (uint256);
    function tokenToTrxSwapOutput(uint256 trx_bought, uint256 max_tokens)
    external
    returns (uint256);
    function getTrxToTokenInputPrice(uint256 trx_sold)
    external
    view
    returns (uint256);
    function getTrxToTokenOutputPrice(uint256 tokens_bought)
    external
    view
    returns (uint256);
    function getTokenToTrxInputPrice(uint256 tokens_sold)
    external
    view
    returns (uint256);
    function getTokenToTrxOutputPrice(uint256 trx_bought)
    external
    view
    returns (uint256);
    function tokenAddress() external view returns (address);
    function tronBalance() external view returns (uint256);
    function tokenBalance() external view returns (uint256);
    function getTrxToLiquidityInputPrice(uint256 trx_sold)
    external
    view
    returns (uint256);
    function getLiquidityToReserveInputPrice(uint256 amount)
    external
    view
    returns (uint256, uint256);
    function txs(address owner) external view returns (uint256);
    function addLiquidity(uint256 min_liquidity, uint256 max_tokens)
    external
    payable
    returns (uint256);
    function removeLiquidity(
        uint256 amount,
        uint256 min_trx,
        uint256 min_tokens
    ) external returns (uint256, uint256);
}

interface IToken {
    function remainingMintableSupply() external view returns (uint256);
    function calculateTransferTaxes(address _from, address _to, uint256 _value) external view returns (uint256 adjustedValue, uint256 taxAmount);
    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
    function transfer(address to, uint256 value) external returns (bool);
    function balanceOf(address who) external view returns (uint256);
    function mintedSupply() external returns (uint256);
    function allowance(address owner, address spender)
    external
    view
    returns (uint256);
    function approve(address spender, uint256 value) external returns (bool);
}

interface ITokenMint {
    function mint(address beneficiary, uint256 tokenAmount) external returns (uint256);
    function estimateMint(uint256 _amount) external returns (uint256);
    function remainingMintableSupply() external returns (uint256);
}

interface IDripVault {
    function withdraw(uint256 tokenAmount) external;
}

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }
    function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
        if (b > a) {
            return 0;
        } else {
            return a - b;
        }
    }
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}

contract Faucet is Initializable, OwnableUpgradeable {
    using SafeMath for uint256;
    struct User {
        address upline;
        uint256 referrals;
        uint256 total_structure;
        uint256 direct_bonus;
        uint256 match_bonus;
        uint256 deposits;
        uint256 deposit_time;
        uint256 payouts;
        uint256 rolls;
        uint256 ref_claim_pos;
        address entered_address;
    }
    struct Airdrop {
        uint256 airdrops;
        uint256 airdrops_received;
        uint256 last_airdrop;
    }
    struct Custody {
        address manager;
        address beneficiary;
        uint256 last_heartbeat;
        uint256 last_checkin;
        uint256 heartbeat_interval;
    }
    address public dripVaultAddress;
    ITokenMint private tokenMint;
    IToken private dripToken;
    IDripVault private dripVault;
    mapping(address => User) public users;
    mapping(address => Airdrop) public airdrops;
    mapping(address => Custody) public custody;
    uint256 public CompoundTax;
    uint256 public ExitTax;
    uint256 private payoutRate;
    uint256 private ref_depth;
    uint256 private ref_bonus;
    uint256 private minimumInitial;
    uint256 private minimumAmount;
    uint256 public deposit_bracket_size;
    uint256 public max_payout_cap;
    uint256 private deposit_bracket_max;
    uint256[] public ref_balances;
    uint256 public total_airdrops;
    uint256 public total_users;
    uint256 public total_deposited;
    uint256 public total_withdraw;
    uint256 public total_bnb;
    uint256 public total_txs;
    uint256 public constant MAX_UINT = 2**256 - 1;

    event Upline(address indexed addr, address indexed upline);
    event NewDeposit(address indexed addr, uint256 amount);
    event Leaderboard(address indexed addr, uint256 referrals, uint256 total_deposits, uint256 total_payouts, uint256 total_structure);
    event DirectPayout(address indexed addr, address indexed from, uint256 amount);
    event MatchPayout(address indexed addr, address indexed from, uint256 amount);
    event BalanceTransfer(address indexed _src, address indexed _dest, uint256 _deposits, uint256 _payouts);
    event Withdraw(address indexed addr, uint256 amount);
    event LimitReached(address indexed addr, uint256 amount);
    event NewAirdrop(address indexed from, address indexed to, uint256 amount, uint256 timestamp);
    event ManagerUpdate(address indexed addr, address indexed manager, uint256 timestamp);
    event BeneficiaryUpdate(address indexed addr, address indexed beneficiary);
    event HeartBeatIntervalUpdate(address indexed addr, uint256 interval);
    event HeartBeat(address indexed addr, uint256 timestamp);
    event Checkin(address indexed addr, uint256 timestamp);

    function initialize(address _mintAddress, address _dripTokenAddress, address _vaultAddress) public initializer {
        __Ownable_init();

        total_users = 1;
        deposit_bracket_size = 10000e18;
        max_payout_cap = 100000e18;
        minimumInitial = 1e18;
        minimumAmount = 1e18;
        payoutRate = 1;
        ref_depth  = 15;
        ref_bonus  = 10;
        deposit_bracket_max = 10;
        CompoundTax = 5;
        ExitTax = 10;
        tokenMint = ITokenMint(_mintAddress);
        dripToken = IToken(_dripTokenAddress);
        dripVaultAddress = _vaultAddress;
        dripVault = IDripVault(_vaultAddress);
        ref_balances.push(2e8);
        ref_balances.push(3e8);
        ref_balances.push(5e8);
        ref_balances.push(8e8);
        ref_balances.push(13e8);
        ref_balances.push(21e8);
        ref_balances.push(34e8);
        ref_balances.push(55e8);
        ref_balances.push(89e8);
        ref_balances.push(144e8);
        ref_balances.push(233e8);
        ref_balances.push(377e8);
        ref_balances.push(610e8);
        ref_balances.push(987e8);
        ref_balances.push(1597e8);
    }

    fallback() external payable {
    }

    function addUsers(address[] memory UserAddresses, User[] memory newUserData, Airdrop[] memory newUserAirdropData) public onlyOwner {
        for (uint i = 0; i < UserAddresses.length; i++) {
            users[UserAddresses[i]] = newUserData[i];
            airdrops[UserAddresses[i]] = newUserAirdropData[i];
        }
    }

    function setTotalAirdrops(uint256 newTotalAirdrop) public onlyOwner {
        total_airdrops = newTotalAirdrop;
    }

    function setTotalUsers(uint256 newTotalUsers) public onlyOwner {
        total_users = newTotalUsers;
    }
    function setTotalDeposits(uint256 newTotalDeposits) public onlyOwner {
        total_deposited = newTotalDeposits;
    }
    function setTotalWithdraw(uint256 newTotalWithdraw) public onlyOwner {
        total_withdraw = newTotalWithdraw;
    }
    function setTotalBNB(uint256 newTotalBNB) public onlyOwner {
        total_bnb = newTotalBNB;
    }
    function setTotalTX(uint256 newTotalTX) public onlyOwner {
        total_txs = newTotalTX;
    }
    function updatePayoutRate(uint256 _newPayoutRate) public onlyOwner {
        payoutRate = _newPayoutRate;
    }
    function updateRefDepth(uint256 _newRefDepth) public onlyOwner {
        ref_depth = _newRefDepth;
    }
    function updateRefBonus(uint256 _newRefBonus) public onlyOwner {
        ref_bonus = _newRefBonus;
    }
    function updateInitialDeposit(uint256 _newInitialDeposit) public onlyOwner {
        minimumInitial = _newInitialDeposit;
    }
    function updateCompoundTax(uint256 _newCompoundTax) public onlyOwner {
        require(_newCompoundTax >= 0 && _newCompoundTax <= 20);
        CompoundTax = _newCompoundTax;
    }
    function updateExitTax(uint256 _newExitTax) public onlyOwner {
        require(_newExitTax >= 0 && _newExitTax <= 20);
        ExitTax = _newExitTax;
    }
    function updateDepositBracketSize(uint256 _newBracketSize) public onlyOwner {
        deposit_bracket_size = _newBracketSize;
    }
    function updateMaxPayoutCap(uint256 _newPayoutCap) public onlyOwner {
        max_payout_cap = _newPayoutCap;
    }
    function updateHoldRequirements(uint256[] memory _newRefBalances) public onlyOwner {
        require(_newRefBalances.length == ref_depth);
        delete ref_balances;
        for(uint8 i = 0; i < ref_depth; i++) {
            ref_balances.push(_newRefBalances[i]);
        }
    }
    function checkin() public {
        address _addr = msg.sender;
        custody[_addr].last_checkin = block.timestamp;
        emit Checkin(_addr, custody[_addr].last_checkin);
    }

    function deposit(address _upline, uint256 _amount) external {
        address _addr = msg.sender;
        (uint256 realizedDeposit, uint256 taxAmount) = dripToken.calculateTransferTaxes(_addr, address(this), _amount);
        uint256 _total_amount = realizedDeposit;
        checkin();
        require(_amount >= minimumAmount, "Minimum deposit");
        if (users[_addr].deposits == 0){
            require(_amount >= minimumInitial, "Initial deposit too low");
        }
        _setUpline(_addr, _upline);
        if (claimsAvailable(_addr) > _amount / 100){
            uint256 claimedDivs = _claim(_addr, false);
            uint256 taxedDivs = claimedDivs.mul(SafeMath.sub(100, CompoundTax)).div(100);
            _total_amount += taxedDivs;
        }
        require(
            dripToken.transferFrom(
                _addr,
                address(dripVaultAddress),
                _amount
            ),
            "DRIP token transfer failed"
        );
        _deposit(_addr, _total_amount);
        emit Leaderboard(_addr, users[_addr].referrals, users[_addr].deposits, users[_addr].payouts, users[_addr].total_structure);
        total_txs++;
    }

    function depositFromPresale(address presale, address _depositor, address _upline, uint256 _amount) external {
        require(presale == _msgSender()   , "Caller is not the preSale");
        address _addr = _depositor;
        (uint256 realizedDeposit, uint256 taxAmount) = dripToken.calculateTransferTaxes(_addr, address(this), _amount);
        uint256 _total_amount = realizedDeposit;
        checkin();
        require(_amount >= minimumAmount, "Minimum deposit");
        if (users[_addr].deposits == 0){
            require(_amount >= minimumInitial, "Initial deposit too low");
        }
        _setUpline(_addr, _upline);
        if (claimsAvailable(_addr) > _amount / 100){
            uint256 claimedDivs = _claim(_addr, false);
            uint256 taxedDivs = claimedDivs.mul(SafeMath.sub(100, CompoundTax)).div(100);
            _total_amount += taxedDivs;
        }
        require(
            dripToken.transferFrom(
                presale,
                address(dripVaultAddress),
                _amount
            ),
            "DRIP token transfer failed"
        );
        _deposit(_addr, _total_amount);
        emit Leaderboard(_addr, users[_addr].referrals, users[_addr].deposits, users[_addr].payouts, users[_addr].total_structure);
        total_txs++;
    }

    function claim() external {
        checkin();
        address _addr = msg.sender;
        _claim_out(_addr);
    }
    function roll() public {
        checkin();
        address _addr = msg.sender;
        _roll(_addr);
    }
    function _setUpline(address _addr, address _upline) internal {
        if(users[_addr].upline == address(0) && _upline != _addr && _addr != owner() && (users[_upline].deposit_time > 0 || _upline == owner() )) {
            users[_addr].upline = _upline;
            users[_upline].referrals++;
            emit Upline(_addr, _upline);
            total_users++;
            for(uint8 i = 0; i < ref_depth; i++) {
                if(_upline == address(0)) break;
                users[_upline].total_structure++;
                _upline = users[_upline].upline;
            }
        }
    }
    function _deposit(address _addr, uint256 _amount) internal {
        require(users[_addr].upline != address(0) || _addr == owner(), "No upline");
        users[_addr].deposits += _amount;
        users[_addr].deposit_time = block.timestamp;
        users[_addr].entered_address=_addr;
        total_deposited += _amount;
        emit NewDeposit(_addr, _amount);
        address _up = users[_addr].upline;
        if(_up != address(0) && isNetPositive(_up)) {
            uint256 _bonus = _amount / 10;
            users[_up].direct_bonus += _bonus;
            users[_up].deposits += _bonus;
            emit NewDeposit(_up, _bonus);
            emit DirectPayout(_up, _addr, _bonus);
        }
    }
    function _refPayout(address _addr, uint256 _amount) internal {
        address _up = users[_addr].upline;
        uint256 _bonus = _amount * ref_bonus / 100;
        uint256 _share = _bonus / 4;
        uint256 _up_share = _bonus.sub(_share);
        bool _team_found = false;
        for(uint8 i = 0; i < ref_depth; i++) {
            if(_up == address(0)){
                users[_addr].ref_claim_pos = ref_depth;
                break;
            }
            if(users[_addr].ref_claim_pos == i && isNetPositive(_up)) {
                if(users[_up].referrals >= 5 && !_team_found) {
                    _team_found = true;
                    users[_up].deposits += _up_share;
                    users[_addr].deposits += _share;
                    users[_up].match_bonus += _up_share;
                    airdrops[_up].airdrops += _share;
                    airdrops[_up].last_airdrop = block.timestamp;
                    airdrops[_addr].airdrops_received += _share;
                    total_airdrops += _share;
                    emit NewDeposit(_addr, _share);
                    emit NewDeposit(_up, _up_share);
                    emit NewAirdrop(_up, _addr, _share, block.timestamp);
                    emit MatchPayout(_up, _addr, _up_share);
                } else {
                    users[_up].deposits += _bonus;
                    users[_up].match_bonus += _bonus;
                    emit NewDeposit(_up, _bonus);
                    emit MatchPayout(_up, _addr, _bonus);
                }
                break;
            }
            _up = users[_up].upline;
        }
        users[_addr].ref_claim_pos += 1;
        if (users[_addr].ref_claim_pos >= ref_depth){
            users[_addr].ref_claim_pos = 0;
        }
    }
    function _heart(address _addr) internal {
        custody[_addr].last_heartbeat = block.timestamp;
        emit HeartBeat(_addr, custody[_addr].last_heartbeat);
    }

    function _roll(address _addr) internal {
        uint256 to_payout = _claim(_addr, false);
        uint256 payout_taxed = to_payout.mul(SafeMath.sub(100, CompoundTax)).div(100);
        _deposit(_addr, payout_taxed);
        users[_addr].rolls += payout_taxed;
        emit Leaderboard(_addr, users[_addr].referrals, users[_addr].deposits, users[_addr].payouts, users[_addr].total_structure);
        total_txs++;
    }

    function _claim_out(address _addr) internal {
        uint256 to_payout = _claim(_addr, true);
        uint256 realizedPayout = to_payout.mul(SafeMath.sub(100, ExitTax)).div(100);
        require(dripToken.transfer(address(msg.sender), realizedPayout));
        emit Leaderboard(_addr, users[_addr].referrals, users[_addr].deposits, users[_addr].payouts, users[_addr].total_structure);
        total_txs++;
    }
    function _claim(address _addr, bool isClaimedOut) internal returns (uint256) {
        (uint256 _gross_payout, uint256 _max_payout, uint256 _to_payout, uint256 _sustainability_fee) = payoutOf(_addr);
        require(users[_addr].payouts < _max_payout, "Full payouts");
        if(_to_payout > 0) {
            if(users[_addr].payouts + _to_payout > _max_payout) {
                _to_payout = _max_payout.safeSub(users[_addr].payouts);
            }
            users[_addr].payouts += _gross_payout;
            if (!isClaimedOut){
                uint256 compoundTaxedPayout = _to_payout.mul(SafeMath.sub(100, CompoundTax)).div(100);
                _refPayout(_addr, compoundTaxedPayout);
            }
        }
        require(_to_payout > 0, "Zero payout");
        total_withdraw += _to_payout;
        users[_addr].deposit_time = block.timestamp;
        emit Withdraw(_addr, _to_payout);
        if(users[_addr].payouts >= _max_payout) {
            emit LimitReached(_addr, users[_addr].payouts);
        }
        return _to_payout;
    }
    function isNetPositive(address _addr) public view returns (bool) {
        (uint256 _credits, uint256 _debits) = creditsAndDebits(_addr);
        return _credits > _debits;
    }
    function creditsAndDebits(address _addr) public view returns (uint256 _credits, uint256 _debits) {
        User memory _user = users[_addr];
        Airdrop memory _airdrop = airdrops[_addr];
        _credits = _airdrop.airdrops + _user.rolls + _user.deposits;
        _debits = _user.payouts;
    }
    function sustainabilityFee(address _addr) public view returns (uint256) {
        uint256 _bracket = users[_addr].deposits.div(deposit_bracket_size);
        _bracket = SafeMath.min(_bracket, deposit_bracket_max);
        return _bracket * 5;
    }
    function getCustody(address _addr) public view returns (address _beneficiary, uint256 _heartbeat_interval, address _manager) {
        return (custody[_addr].beneficiary, custody[_addr].heartbeat_interval, custody[_addr].manager);
    }
    function lastActivity(address _addr) public view returns (uint256 _heartbeat, uint256 _lapsed_heartbeat, uint256 _checkin, uint256 _lapsed_checkin) {
        _heartbeat = custody[_addr].last_heartbeat;
        _lapsed_heartbeat = block.timestamp.safeSub(_heartbeat);
        _checkin = custody[_addr].last_checkin;
        _lapsed_checkin = block.timestamp.safeSub(_checkin);
    }
    function claimsAvailable(address _addr) public view returns (uint256) {
        (uint256 _gross_payout, uint256 _max_payout, uint256 _to_payout, uint256 _sustainability_fee) = payoutOf(_addr);
        return _to_payout;
    }
    function maxPayoutOf(uint256 _amount) public pure returns(uint256) {
        return _amount * 365 / 100;
    }
    function payoutOf(address _addr) public view returns(uint256 payout, uint256 max_payout, uint256 net_payout, uint256 sustainability_fee) {
        max_payout = maxPayoutOf(users[_addr].deposits).min(max_payout_cap);
        uint256 _fee = sustainabilityFee(_addr);
        uint256 share;
        if(users[_addr].payouts < max_payout) {
            share = users[_addr].deposits.mul(payoutRate * 100).div(10000).div(24 hours);
            payout = share * block.timestamp.safeSub(users[_addr].deposit_time);
            if(users[_addr].payouts + payout > max_payout) {
                payout = max_payout.safeSub(users[_addr].payouts);
            }
            sustainability_fee = payout * _fee / 100;
            net_payout = payout.safeSub(sustainability_fee);
        }
    }
    function userInfo(address _addr) external view returns(address upline, uint256 deposit_time, uint256 deposits, uint256 payouts, uint256 direct_bonus, uint256 match_bonus, uint256 last_airdrop) {
        return (users[_addr].upline, users[_addr].deposit_time, users[_addr].deposits, users[_addr].payouts, users[_addr].direct_bonus, users[_addr].match_bonus, airdrops[_addr].last_airdrop);
    }
    function userInfoTotals(address _addr) external view returns(uint256 referrals, uint256 total_deposits, uint256 total_payouts, uint256 total_structure, uint256 airdrops_total, uint256 airdrops_received) {
        return (users[_addr].referrals, users[_addr].deposits, users[_addr].payouts, users[_addr].total_structure, airdrops[_addr].airdrops, airdrops[_addr].airdrops_received);
    }
    function contractInfo() external view returns(uint256 _total_users, uint256 _total_deposited, uint256 _total_withdraw, uint256 _total_bnb, uint256 _total_txs, uint256 _total_airdrops) {
        return (total_users, total_deposited, total_withdraw, total_bnb, total_txs, total_airdrops);
    }
    function airdrop(address _to, uint256 _amount) external {
        address _addr = msg.sender;
        (uint256 _realizedAmount, uint256 taxAmount) = dripToken.calculateTransferTaxes(_addr, address(this), _amount);
        require(
            dripToken.transferFrom(
                _addr,
                address(dripVaultAddress),
                _amount
            ),
            "DRIP to contract transfer failed; check balance and allowance, airdrop"
        );
        require(users[_to].upline != address(0), "_to not found");
        users[_to].deposits += _realizedAmount;
        airdrops[_addr].airdrops += _realizedAmount;
        airdrops[_addr].last_airdrop = block.timestamp;
        airdrops[_to].airdrops_received += _realizedAmount;
        total_airdrops += _realizedAmount;
        total_txs += 1;
        emit NewAirdrop(_addr, _to, _realizedAmount, block.timestamp);
        emit NewDeposit(_to, _realizedAmount);
    }
    function MultiSendairdrop(address[] memory _to, uint256 _amount) external
    {
        address _addr = msg.sender;
        uint256 __amount;
        uint256 _realizedAmount;
        uint256 taxAmount;
        for(uint256 i=0; i< _to.length ; i++){
            require(dripToken.transferFrom( _addr,address(dripVaultAddress),_amount ),"DRIP to contract transfer failed; check balance and allowance, airdrop");
            require(users[_to[i]].upline != address(0), "_to not found");
            (_realizedAmount, taxAmount) = dripToken.calculateTransferTaxes(_addr, address(this), _amount);
            users[_to[i]].deposits += _realizedAmount;
            airdrops[_to[i]].airdrops_received += _realizedAmount;
            __amount = _amount;
        }
        airdrops[_addr].airdrops += __amount;
        airdrops[_addr].last_airdrop = block.timestamp;
        total_airdrops += __amount;
        total_txs += 1;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}