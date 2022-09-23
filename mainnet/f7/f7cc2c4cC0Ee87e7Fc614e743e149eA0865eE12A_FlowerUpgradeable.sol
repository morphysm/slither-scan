// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.13;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";

import "./interfaces/IBloomexRouter02.sol";
import "./interfaces/INectar.sol";
import "./interfaces/ITreasuryUpgradeable.sol";

contract IDarkForestNFT {
    mapping(uint256 => uint256) public tierOfNfts;

    function ownerOf(uint256 tokenId) public view virtual returns (address) {}

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual {}
}

contract FlowerUpgradeable is OwnableUpgradeable {
    struct Action {
        bool isCompound;
        uint256 timestamp;
    }
    struct User {
        // USDC.e wallet
        address walletUSDCe;
        // Referral Info
        address upline;
        // Deposit Accounting
        uint256 depositsNCTR;
        uint256 depositsUSDCe;
        uint256 lastDepositTime;
        uint256 APR;
        // Payout Accounting
        uint256 payouts;
        uint256 dailyClaimAmount;
        uint256 uplineRewardTracker;
        uint256 lastActionTime;
        uint256 nextActionTime;
        Action[] lastActions;
        uint256 nftTier;
    }

    struct Airdrop {
        // Airdrop tracking
        uint256 airdropsGiven;
        uint256 airdropsReceived;
        uint256 lastAirdropTime;
    }

    mapping(address => User) public users;
    mapping(address => Airdrop) public airdrops;

    uint256 private constant MAX_PERC = 100;
    uint256 private constant MAX_PERMILLE = 1000;
    uint256 private constant MIN_NUM_OF_REF_FOR_TEAM_WALLET = 5;
    uint256 private constant MAX_NUM_OF_REF_FOR_OWNER = 15;
    uint256 private constant MIN_TIER_LVL = 1;
    uint256 private constant MAX_TIER_LVL = 15;
    uint256 private constant NUM_OF_TIERS = 16; // 16th wallet is the dev's wallet

    mapping(address => address[]) public userDownlines;
    mapping(address => mapping(address => uint256)) public userDownlinesIndex;

    uint256 public totalAirdrops;
    uint256 public totalUsers;
    uint256 public totalDepositedNCTR;
    uint256 public totalDepositedUSDCe;
    uint256 public totalWithdraw;

    INectar public nectarToken;
    ERC1155Upgradeable public tierNFT;
    ERC20Upgradeable public USDCeToken;

    IBloomexRouter02 public router;
    ITreasuryUpgradeable public treasury;
    address public devWalletAddressNCTR;
    address public devWalletAddressUSDCe;
    address public pairAddress;
    address public liquidityManagerAddress;

    uint256 public depositTax;
    uint256 private depositBurnPercNCTR;
    uint256 private depositFlowerPercNCTR;
    uint256 private depositLpPercNCTR;
    uint256 private depositLpPercUSDCe;
    uint256 private depositTreasuryPercUSDCe;

    uint256 public compoundTax;
    uint256 private compoundBurnPercNCTR;
    uint256 private compoundUplinePercNCTR;
    uint256 private compoundUplinePercUSDCe;

    uint256 public claimTax;
    // uint256 public sellTax; // not used for now
    // WHALE TAX work in progress

    uint256 public teamWalletDownlineRewardPerc;

    mapping(address => uint256) public userCompoundRewards;

    event Deposit(address indexed addr, uint256 amount, address indexed token);
    event Reward(address indexed addr, uint256 amount, address indexed token);
    event TeamReward(
        address indexed teamLead,
        address indexed teamMember,
        uint256 amount,
        address indexed token
    );
    event Claim(address indexed addr, uint256 amount);
    event AirdropNCTR(
        address indexed from,
        address[] indexed receivers,
        uint256[] airdrops,
        uint256 timestamp
    );

    event DownlineUpdated(address indexed upline, address[] downline);

    struct DownlineRewardTracker {
        uint256 compoundDownlineNCTR;
        uint256 compoundDownlineeUSDCe;
        uint256 depositDownlineNCTR;
        uint256 depositDownlineeUSDCe;
    }

    mapping(address => DownlineRewardTracker) public downlineRewardTracker;

    event CompoundRewardFrom(
        address indexed addr,
        address indexed from,
        uint256 amountNCTR,
        uint256 amountUsce
    );
    event DepositRewardFrom(
        address indexed addr,
        address indexed from,
        uint256 amountNCTR,
        uint256 amountUsce
    );

    mapping(uint256 => MoveToBloomify) public movetobloomify;

    struct MoveToBloomify {
        uint256 bloomId;
        address walletAddress;
        uint256 bloomValue;
        uint256 rewardAmount;
        uint256 instantAmount;
        uint256 alreadyMoved;
        uint256 movingDay;
    }

    uint256[] public _moveToBloomify;

    mapping(address => uint256[]) public movedBloomBoxes;

    mapping(address => uint256) public movedNCTRFromBloomBox;

    address[] private _allowedForAdding;

    address[] private _banList;

    uint256[] public percentagePerTier;

    address public nft;

    uint256 public denominatorPercentagePerTier;

    mapping(uint256 => address) public tokenStaked;

    /**
     * @dev - Initializes the contract and initiates necessary state variables
     * @param _tierNFTAddress - Address of the TierNFT token contract
     * @param _nectarTokenAddress - Address of the NCTR token contract
     * @param _USDCeTokenAddress - Address of the USDC.e token contract
     * @param _treasuryAddress - Address of the treasury
     * @param _routerAddress - Address of the Router contract
     * @param _devWalletAddressNCTR - Address of the developer's NCTR wallet
     * @param _devWalletAddressUSDCe - Address of the developer's USDC.e wallet
     * @notice - Can only be initialized once
     */
    function initialize(
        address _tierNFTAddress,
        address _nectarTokenAddress,
        address _USDCeTokenAddress,
        address _treasuryAddress,
        address _routerAddress,
        address _devWalletAddressNCTR,
        address _devWalletAddressUSDCe,
        address _liquidityManagerAddress
    ) external initializer {
        require(_tierNFTAddress != address(0));
        require(_nectarTokenAddress != address(0));
        require(_USDCeTokenAddress != address(0));
        require(_treasuryAddress != address(0));
        require(_routerAddress != address(0));
        require(_devWalletAddressNCTR != address(0));
        require(_devWalletAddressUSDCe != address(0));
        require(_liquidityManagerAddress != address(0));

        __Ownable_init();

        // NFT for tier level representation
        tierNFT = ERC1155Upgradeable(_tierNFTAddress);
        // Nectar token
        nectarToken = INectar(_nectarTokenAddress);
        // USDC.e token
        USDCeToken = ERC20Upgradeable(_USDCeTokenAddress);
        // Treasury
        treasury = ITreasuryUpgradeable(_treasuryAddress);
        // Router
        router = IBloomexRouter02(_routerAddress);
        // Developer's wallet addresses
        devWalletAddressNCTR = _devWalletAddressNCTR;
        devWalletAddressUSDCe = _devWalletAddressUSDCe;

        // Liquidity manager address
        liquidityManagerAddress = _liquidityManagerAddress;

        // Initialize contract state variables
        totalUsers += 1;

        depositTax = 10;
        depositBurnPercNCTR = 20;
        depositFlowerPercNCTR = 60;
        depositLpPercNCTR = 20;
        depositLpPercUSDCe = 20;
        depositTreasuryPercUSDCe = 80;

        compoundTax = 10;
        compoundBurnPercNCTR = 50;
        compoundUplinePercNCTR = 90;
        compoundUplinePercUSDCe = 10;

        claimTax = 10;
        // sellTax = 10;

        teamWalletDownlineRewardPerc = 25;

        // Initialize owner's APR
        users[owner()].APR = 10;
    }

    /*****************************************************************/
    /********** Modifiers ********************************************/
    modifier onlyBloomReferralNode() {
        require(
            users[msg.sender].upline != address(0) || msg.sender == owner(),
            "Caller must be in the Bloom Referral system!"
        );

        _;
    }

    modifier noZeroAddress(address _addr) {
        require(_addr != address(0), "Zero address!");

        _;
    }

    modifier onlyValidPercentage(uint256 _percentage) {
        require(_percentage <= 100, "Percentage greater than 100!");

        _;
    }

    modifier onlyAmountGreaterThanZero(uint256 _amount) {
        require(_amount > 0, "Amount should be greater than zero!");

        _;
    }

    /*************************************************************************/
    /****** Management Functions *********************************************/

    /**
     * @dev - Update deposit tax with onlyOwner rights
     * @param _newDepositTax - New deposit tax
     */
    function updateDepositTax(uint256 _newDepositTax)
        external
        onlyOwner
        onlyValidPercentage(_newDepositTax)
    {
        depositTax = _newDepositTax;
    }

    /**
     * @dev - Update deposit distribution percentages with onlyOwner rights
     * @param _depositBurnPercNCTR - Percentage of Nectar to be burned
     * @param _depositFlowerPercNCTR - Percentage of Nectar to be sent to the Flower
     * @param _depositLpPercNCTR - Percentage of Nectar to be added to liquidity pool
     * @param _depositLpPercUSDCe - Percentage of USDC.e to be added to liquidity pool
     * @param _depositTreasuryPercUSDCe - Percentage of USDC.e to be sent to the Treasury
     */
    function updateDepositDistributionPercentages(
        uint256 _depositBurnPercNCTR,
        uint256 _depositFlowerPercNCTR,
        uint256 _depositLpPercNCTR,
        uint256 _depositLpPercUSDCe,
        uint256 _depositTreasuryPercUSDCe
    ) external onlyOwner {
        require(
            _depositBurnPercNCTR +
                _depositFlowerPercNCTR +
                _depositLpPercNCTR ==
                MAX_PERC,
            "Nectar deposit percentages not summing up to 100!"
        );
        require(
            _depositLpPercUSDCe + _depositTreasuryPercUSDCe == MAX_PERC,
            "USDC.e deposit percentages not summing up to 100!"
        );
        require(
            _depositLpPercNCTR == _depositLpPercUSDCe,
            "Different LP percentages!"
        );

        depositBurnPercNCTR = _depositBurnPercNCTR;
        depositFlowerPercNCTR = _depositFlowerPercNCTR;
        depositLpPercNCTR = _depositLpPercNCTR;
        depositLpPercUSDCe = _depositLpPercUSDCe;
        depositTreasuryPercUSDCe = _depositTreasuryPercUSDCe;
    }

    function allowToAdd(address _address) external onlyOwner {
        _allowedForAdding.push(_address);
    }

    function addToBanList(address _address) external onlyOwner {
        _banList.push(_address);
    }

    function checkIfAllowedForAdding(address _address)
        public
        view
        returns (bool)
    {
        for (uint256 i = 0; i < _allowedForAdding.length; i++) {
            if (_allowedForAdding[i] == _address) {
                return true;
            }
        }

        return false;
    }

    function fixBloomBoxWallet(uint256 id, address wallet) external onlyOwner {
        MoveToBloomify storage bloomifyMove = movetobloomify[id];
        bloomifyMove.walletAddress = wallet;
    }

    function movingChoice(
        uint256 _bloomId,
        address _bloomOwner,
        uint256 _bloomValue,
        uint256 _bloomRewardAmount,
        uint256 _instantAmount
    ) external {
        bool doesListContainElement = false;

        require(
            checkIfAllowedForAdding(msg.sender),
            "You are not allowed to add"
        );

        for (uint256 i = 0; i < _moveToBloomify.length; i++) {
            if (_bloomId == _moveToBloomify[i]) {
                doesListContainElement = true;
                break;
            }
        }

        require(doesListContainElement == false, "already in list");

        movetobloomify[_bloomId] = MoveToBloomify({
            walletAddress: _bloomOwner,
            bloomId: _bloomId,
            bloomValue: _bloomValue,
            rewardAmount: _bloomRewardAmount,
            instantAmount: _instantAmount,
            alreadyMoved: _bloomRewardAmount,
            movingDay: 0
        });

        movedBloomBoxes[_bloomOwner].push(_bloomId);

        _moveToBloomify.push(_bloomId);
    }

    function moveInstantFromBloombox(address _wallet, uint256 _value) external {
        require(
            checkIfAllowedForAdding(msg.sender),
            "You are not allowed to add"
        );

        require(getDepositedValue(_wallet) > 0, "User Never Deposited");

        movedNCTRFromBloomBox[_wallet] += _value;
        updateAPR(_wallet);
    }

    function removeInstantFromBloombox(address _wallet, uint256 _value)
        external
    {
        require(
            checkIfAllowedForAdding(msg.sender),
            "You are not allowed to add"
        );

        require(getDepositedValue(_wallet) > 0, "User Never Deposited");
        movedNCTRFromBloomBox[_wallet] -= _value;
        updateAPR(_wallet);
    }

    function resetMovedFromBloombox(address _wallet) external {
        require(
            checkIfAllowedForAdding(msg.sender),
            "You are not allowed to add"
        );

        require(getDepositedValue(_wallet) > 0, "User Never Deposited");
        users[_wallet].depositsNCTR = 0;
        users[_wallet].depositsUSDCe = 0;
        users[_wallet].payouts = 0;
        movedNCTRFromBloomBox[_wallet] = 0;
        airdrops[_wallet].airdropsReceived = 0;
        userCompoundRewards[_wallet] = 0;
        updateAPR(_wallet);
    }

    /**
     * @dev - Update compound tax with onlyOwner rights
     * @param _newCompoundTax - New compound tax
     */
    function updateCompoundTax(uint256 _newCompoundTax)
        external
        onlyOwner
        onlyValidPercentage(_newCompoundTax)
    {
        compoundTax = _newCompoundTax;
    }

    /**
     * @dev - Update compound distribution percentages with onlyOwner rights
     * @param _compoundBurnPercNCTR - Percentage of Nectar to be burned
     * @param _compoundUplinePercNCTR - Percentage of Nectar to be sent to the upline's deposit section
     * @param _compoundUplinePercUSDCe - Percentage of USDC.e to be sent to the upline's wallet
     */
    function updateCompoundDistributionPercentages(
        uint256 _compoundBurnPercNCTR,
        uint256 _compoundUplinePercNCTR,
        uint256 _compoundUplinePercUSDCe
    ) external onlyOwner {
        require(
            _compoundBurnPercNCTR +
                _compoundUplinePercNCTR +
                _compoundUplinePercUSDCe ==
                MAX_PERC,
            "Compound percentages not summing up to 100!"
        );

        compoundBurnPercNCTR = _compoundBurnPercNCTR;
        compoundUplinePercNCTR = _compoundUplinePercNCTR;
        compoundUplinePercUSDCe = _compoundUplinePercUSDCe;
    }

    /**
     * @dev - Update claim tax with onlyOwner rights
     * @param _newClaimTax - New claim tax
     */
    function updateClaimTax(uint256 _newClaimTax)
        external
        onlyOwner
        onlyValidPercentage(_newClaimTax)
    {
        claimTax = _newClaimTax;
    }

    /**
     * @dev - Update sell tax with onlyOwner rights
     * @param _newSellTax - New sell tax
     */
    // function updateSellTax(uint256 _newSellTax) external onlyOwner {
    //     sellTax = _newSellTax;
    // }

    /**
     * @dev - Update reward percentage for downline that has a team
     * @param _teamWalletDownlineRewardPerc - New percentage of downline reward that has a team
     */
    function updateTeamWalletDownlineRewardPerc(
        uint256 _teamWalletDownlineRewardPerc
    ) external onlyOwner onlyValidPercentage(_teamWalletDownlineRewardPerc) {
        teamWalletDownlineRewardPerc = _teamWalletDownlineRewardPerc;
    }

    /*******************************************************************************/
    /********** Private Functions **************************************************/

    /**
     * @dev - Calculate percentage part of given number
     * @param _number - Number on which percentage part will be calculated
     * @param _percentage - Percentage to calculate part of the _number
     * @return uint256 - Percentage part of the _number
     */
    function _calculatePercentagePart(uint256 _number, uint256 _percentage)
        private
        pure
        onlyValidPercentage(_percentage)
        returns (uint256)
    {
        return (_number * _percentage) / MAX_PERC;
    }

    /**
     * @dev - Calculate permille part of given number
     * @param _number - Number on which permille part will be calculated
     * @param _permille - Permille to calculate part of the _number
     * @return uint256 - Permille part of the _number
     */
    function _calculatePermillePart(uint256 _number, uint256 _permille)
        private
        pure
        returns (uint256)
    {
        require(_permille <= MAX_PERMILLE, "Invalid permille!");

        return (_number * _permille) / MAX_PERMILLE;
    }

    /**
     * @dev - Calculate realized amount and tax amount for given tax
     * @param _amount - Amount on which tax will be applied
     * @param _tax - Tax percentage that cannot be greater than 50%
     * @return (uint256, uint256) - Tuple with amount after aplied tax and tax amount
     */
    function _calculateTax(uint256 _amount, uint256 _tax)
        private
        pure
        returns (uint256, uint256)
    {
        uint256 taxedAmount = _calculatePercentagePart(_amount, _tax);

        return (_amount - taxedAmount, taxedAmount);
    }

    /**
     * @dev - Check if upline if eligible for rewards (to have appropriate NFT and is net positive)
     * @param _user - User for which tier level is calculated
     * @return id uint256 - Returns tier level of user, zero if user has no appropriate NFT for any tier level
     */
    function _getTierLevel(address _user)
        private
        view
        noZeroAddress(_user)
        returns (uint256 id)
    {
        for (id = MAX_TIER_LVL; id >= MIN_TIER_LVL; id--) {
            if (tierNFT.balanceOf(_user, id) > 0) {
                break;
            }
        }

        return id;
    }

    /**
     * @dev - Check if upline if eligible for rewards (to have appropriate NFT and is net positive)
     * @param _upline - Upline user, the one that gave referral key
     * @param _downlineDepth - Depth of a downline user calculated from _upline user
     * @return bool - Returns true if upline is eligible for rewards
     */
    function _getRewardEligibility(address _upline, uint256 _downlineDepth)
        private
        view
        noZeroAddress(_upline)
        returns (bool)
    {
        return
            _getTierLevel(_upline) > _downlineDepth &&
            getDepositedValue(_upline) + airdrops[_upline].airdropsGiven >
            users[_upline].payouts;
    }

    /**
     * @dev - Adds liquidity to the liquidity pool
     * @param _nctrToLiquidityAmount - Amount of NCTR to add
     * @param _usdcToLiquidityAmount - Amount of USDC.e to add
     */
    function _routerAddLiquidity(
        uint256 _nctrToLiquidityAmount,
        uint256 _usdcToLiquidityAmount
    ) private {
        nectarToken.approve(address(router), _nctrToLiquidityAmount);
        USDCeToken.approve(address(router), _usdcToLiquidityAmount);
        (uint256 amountA, uint256 amountB, uint256 liquidity) = router
            .addLiquidity(
                address(USDCeToken),
                address(nectarToken),
                _usdcToLiquidityAmount,
                _nctrToLiquidityAmount,
                0,
                0,
                owner(),
                type(uint256).max
            );
    }

    /**
     * @dev - Updates team's APR. If a team leader has 5 or more downlines then whole team gets 1% APR and 0.5% otherwise
     * @param _teamLeader - Upline that is a team leader for a team which APR needs to be updated
     */
    function updateAPR(address _teamLeader) public {
        address[] storage downlines = userDownlines[_teamLeader];
        if (downlines.length >= MIN_NUM_OF_REF_FOR_TEAM_WALLET) {
            users[_teamLeader].APR = 10;
            if (users[_teamLeader].nftTier > 0)
                users[_teamLeader].APR += percentagePerTier[
                    users[_teamLeader].nftTier - 1
                ];
            _updateDailyClaimAmount(_teamLeader);
            for (uint256 i = 0; i < downlines.length; i++) {
                users[downlines[i]].APR = 10;
                if (users[downlines[i]].nftTier > 0)
                    users[downlines[i]].APR += percentagePerTier[
                        users[downlines[i]].nftTier - 1
                    ];
                _updateDailyClaimAmount(downlines[i]);
            }
        } else {
            users[_teamLeader].APR = 10;
            if (users[_teamLeader].nftTier > 0)
                users[_teamLeader].APR += percentagePerTier[
                    users[_teamLeader].nftTier - 1
                ];
            _updateDailyClaimAmount(_teamLeader);
            for (uint256 i = 0; i < downlines.length; i++) {
                users[downlines[i]].APR = 10;
                if (users[downlines[i]].nftTier > 0)
                    users[downlines[i]].APR += percentagePerTier[
                        users[downlines[i]].nftTier - 1
                    ];
                _updateDailyClaimAmount(downlines[i]);
            }
        }
    }

    /**
     * @dev - Updates users daily claim amount based on its APR
     * @param _user - User which daily claim amount needs to be updated
     */
    function _updateDailyClaimAmount(address _user) private {
        uint256 depositedValue = getDepositedValue(_user);

        users[_user].dailyClaimAmount = _calculatePermillePart(
            depositedValue,
            users[_user].APR
        );
    }

    /**
     * @dev - Updates users last and next possible action (claim/compound) time
     * @param _user - User for which last and next possible action will be updated
     */
    function _updateActionTime(address _user) private {
        users[_user].lastActionTime = block.timestamp;
        users[_user].nextActionTime = users[_user].lastActionTime + 1 days;
    }

    /******************************************************************************/
    /********** Public Functions **************************************************/

    /**
     * @dev - Getter for all of user's downlines
     * @param _user - User address for which we want to get all the downlines
     * @return - Array of addresses that represents all of the user's downlines
     */
    function getUserDownlines(address _user)
        public
        view
        noZeroAddress(_user)
        returns (address[] memory)
    {
        return userDownlines[_user];
    }

    /**
     * @dev - Calculates DEPOSITED VALUE for given user: deposits + airdrops received
     * @param _user - User address for which we want to calculate DEPOSITED VALUE
     * @return uint256 - Returns the user's DEPOSITED VALUE
     */
    function getDepositedValue(address _user)
        public
        view
        noZeroAddress(_user)
        returns (uint256)
    {
        return
            airdrops[_user].airdropsReceived +
            users[_user].depositsNCTR *
            2 +
            userCompoundRewards[_user] +
            movedNCTRFromBloomBox[_user];
    }

    /**
     * @dev - Calculates PENDING REWARD for given user
     * @param _user - User address for which we want to calculate PENDING REWARD
     * @return rewards - Returns the user's PENDING REWARD
     */
    function getPendingReward(address _user)
        public
        view
        noZeroAddress(_user)
        returns (uint256 rewards)
    {
        uint256 timeSinceLastAction = block.timestamp -
            users[_user].lastActionTime;
        if (timeSinceLastAction > 3 days) timeSinceLastAction = 3 days;
        rewards = ((users[_user].dailyClaimAmount * timeSinceLastAction) /
            1 days);
        if (users[_user].nftTier > 0)
            rewards +=
                (rewards * percentagePerTier[users[_user].nftTier - 1]) /
                denominatorPercentagePerTier;
    }

    /**
     * @dev - Set USDC.e/NCTR pair address
     * @param _pairAddress - Address of USDC.e/NCTR pair
     */
    function setPairAddress(address _pairAddress)
        external
        onlyOwner
        noZeroAddress(_pairAddress)
    {
        pairAddress = _pairAddress;
    }

    /**
     * @dev - Change the timer for the next action
     * @param _user - Address of the user to target
     * @param _nextActionTime - Timestamp of the next action
     */
    function changeNextActionTime(address _user, uint256 _nextActionTime)
        external
        onlyOwner
        noZeroAddress(_user)
    {
        users[_user].nextActionTime = _nextActionTime;
    }

    /**
     * @dev - Change the timer for the last action
     * @param _user - Address of the user to target
     * @param _lastActionTime - Timestamp of the last action
     */
    function changeLastActionTime(address _user, uint256 _lastActionTime)
        external
        onlyOwner
        noZeroAddress(_user)
    {
        users[_user].lastActionTime = _lastActionTime;
    }

    /**
     * @dev - Change the amount of token claim today
     * @param _user - Address of the user to target
     * @param _dailyClaimAmount - Amount of token claim
     */
    function changeAirdropsGiven(address _user, uint256 _dailyClaimAmount)
        external
        onlyOwner
        noZeroAddress(_user)
    {
        users[_user].dailyClaimAmount = _dailyClaimAmount;
    }

    /**
     * @dev - Change the payout of a specific user
     * @param _user - Address of the user to target
     * @param _payout - New payout value
     */
    function changePayouts(address _user, uint256 _payout)
        external
        onlyOwner
        noZeroAddress(_user)
    {
        users[_user].payouts = _payout;
    }

    /**
     * @dev - Deposit with upline referral
     * @param _amountUSDCe - Desired amount in USDC.e for deposit on which deposit tax is applied
     * @param _upline - Upline address
     */
    function deposit(uint256 _amountUSDCe, address _upline)
        external
        noZeroAddress(_upline)
        onlyAmountGreaterThanZero(_amountUSDCe)
    {
        require(
            _upline != owner() ||
                userDownlines[_upline].length < MAX_NUM_OF_REF_FOR_OWNER,
            "Owner can have max 15 referrals!"
        );

        require(
            users[_upline].depositsNCTR > 0 || _upline == owner(),
            "Given upline is not node in Bloom Referral or it's not the owner"
        );

        require(
            USDCeToken.transferFrom(msg.sender, address(this), _amountUSDCe)
        );

        if (getPendingReward(msg.sender) > 0) _compoundRewards();

        // If sender is a new user
        if (users[msg.sender].upline == address(0) && msg.sender != owner()) {
            users[msg.sender].upline = _upline;

            address[] storage downlines = userDownlines[_upline];
            downlines.push(msg.sender);
            userDownlinesIndex[_upline][msg.sender] = downlines.length - 1;

            updateAPR(_upline);
            totalUsers += 1;
            emit DownlineUpdated(_upline, downlines);
        }

        if (
            users[msg.sender].upline != address(0) &&
            _upline != users[msg.sender].upline
        ) {
            address oldUpline = users[msg.sender].upline;
            users[msg.sender].upline = _upline;

            address[] storage downlinesOld = userDownlines[oldUpline];
            address[] storage downlinesNew = userDownlines[_upline];

            uint256 downlineOldIndex = userDownlinesIndex[oldUpline][
                msg.sender
            ];
            address lastAddressInDowlinesOld = downlinesOld[
                downlinesOld.length - 1
            ];
            downlinesOld[downlineOldIndex] = lastAddressInDowlinesOld;
            userDownlinesIndex[oldUpline][
                lastAddressInDowlinesOld
            ] = downlineOldIndex;
            downlinesOld.pop();

            downlinesNew.push(msg.sender);
            userDownlinesIndex[_upline][msg.sender] = downlinesNew.length - 1;

            updateAPR(oldUpline);
            updateAPR(_upline);

            emit DownlineUpdated(oldUpline, downlinesOld);
            emit DownlineUpdated(_upline, downlinesNew);
        }

        // Swap 50% of USDC.e tokens for NCTR
        uint256 amountUSDCe = _amountUSDCe / 2;
        uint256 nectarBalanceBefore = nectarToken.balanceOf(address(this));

        USDCeToken.approve(liquidityManagerAddress, amountUSDCe);
        nectarToken.swapUsdcForToken(amountUSDCe, 1);

        uint256 amountNCTR = nectarToken.balanceOf(address(this)) -
            nectarBalanceBefore;
        // Calculate realized deposit (after tax) in NCTR and in USDC.e
        (uint256 realizedDepositNCTR, uint256 uplineRewardNCTR) = _calculateTax(
            amountNCTR,
            depositTax
        );
        (
            uint256 realizedDepositUSDCe,
            uint256 uplineRewardUSDCe
        ) = _calculateTax(amountUSDCe, depositTax);

        // Update user's NCTR and USDC.e deposit sections
        users[msg.sender].depositsNCTR += amountNCTR;
        users[msg.sender].depositsUSDCe += realizedDepositUSDCe;
        users[msg.sender].lastDepositTime = block.timestamp;

        emit Deposit(msg.sender, amountNCTR, address(nectarToken));
        emit Deposit(msg.sender, realizedDepositUSDCe, address(USDCeToken));

        // Update stats
        totalDepositedNCTR += amountNCTR;
        totalDepositedUSDCe += realizedDepositUSDCe;

        // Reward an upline if it's eligible
        if (_getRewardEligibility(_upline, 0)) {
            // Update _upline's deposit section
            users[_upline].depositsNCTR += uplineRewardNCTR;

            // Send USDC.e reward to _upline's USDC.e wallet address
            require(
                USDCeToken.transfer(_upline, uplineRewardUSDCe),
                "USDC.e token transfer failed!"
            );

            emit Reward(_upline, uplineRewardUSDCe, address(USDCeToken));

            downlineRewardTracker[_upline]
                .depositDownlineNCTR += uplineRewardNCTR;
            downlineRewardTracker[_upline]
                .depositDownlineeUSDCe += uplineRewardUSDCe;
            emit DepositRewardFrom(
                _upline,
                msg.sender,
                uplineRewardNCTR,
                uplineRewardUSDCe
            );
        } else {
            // Send rewards to developer's wallet if _upline is not eligible for rewards
            require(
                nectarToken.transfer(devWalletAddressNCTR, uplineRewardNCTR),
                "Nectar token transfer failed!"
            );
            require(
                USDCeToken.transfer(devWalletAddressUSDCe, uplineRewardUSDCe),
                "USDC.e token transfer failed!"
            );

            emit Reward(
                devWalletAddressNCTR,
                uplineRewardNCTR,
                address(nectarToken)
            );
            emit Reward(
                devWalletAddressUSDCe,
                uplineRewardUSDCe,
                address(USDCeToken)
            );

            downlineRewardTracker[devWalletAddressNCTR]
                .depositDownlineNCTR += uplineRewardNCTR;
            downlineRewardTracker[devWalletAddressUSDCe]
                .depositDownlineeUSDCe += uplineRewardUSDCe;
            emit DepositRewardFrom(
                devWalletAddressNCTR,
                msg.sender,
                uplineRewardNCTR,
                uplineRewardUSDCe
            );
        }

        // @notice - 60% NCTR to Flower address is already in the Flower

        // Burn 20% of NCTR
        uint256 burnAmountNCTR = _calculatePercentagePart(
            realizedDepositNCTR,
            depositBurnPercNCTR
        );

        // Add 20% of NCTR and 20% of USDC.e to Liquidity pool
        uint256 lpAmountNCTR = _calculatePercentagePart(
            realizedDepositNCTR,
            depositLpPercNCTR
        );

        nectarToken.burnNectar(address(this), burnAmountNCTR + lpAmountNCTR);

        uint256 lpAmountUSDCe = _calculatePercentagePart(
            realizedDepositUSDCe,
            depositLpPercUSDCe
        );
        //   _routerAddLiquidity(lpAmountNCTR, lpAmountUSDCe);

        // Add 80% of USDC.e to Treasury address
        uint256 treasuryAmountUSDCe = _calculatePercentagePart(
            realizedDepositUSDCe,
            depositTreasuryPercUSDCe
        );
        require(
            USDCeToken.transfer(address(treasury), treasuryAmountUSDCe),
            "USDC.e token transfer failed!"
        );

        require(
            USDCeToken.transfer(address(devWalletAddressUSDCe), lpAmountUSDCe),
            "USDC.e token transfer failed!"
        );

        // Update dailyClaimAmount since DEPOSITED VALUE has change
        _updateDailyClaimAmount(msg.sender);
        if (users[msg.sender].upline != address(0)) {
            _updateDailyClaimAmount(users[msg.sender].upline);
        }
        _updateActionTime(msg.sender);
    }

    /**
     * @dev - Distribute compound rewards to the upline with Round Robin system
     */
    function _compoundRewards() private {
        uint256 compoundReward = getPendingReward(msg.sender);
        userCompoundRewards[msg.sender] += compoundReward;

        (, uint256 taxedAmountNCTR) = _calculateTax(
            compoundReward,
            compoundTax
        );

        // Burn half of the compounded NCTR amount
        // nectarToken.burnNectar(
        //     address(this),
        //     _calculatePercentagePart(taxedAmountNCTR, compoundBurnPercNCTR)
        // );

        address upline = users[msg.sender].upline;
        uint256 downlineDepth = 0;
        for (; downlineDepth < NUM_OF_TIERS; downlineDepth++) {
            // If we've reached the top of the chain or we're at the 16th upline (dev's wallet)
            if (upline == address(0) || downlineDepth == NUM_OF_TIERS - 1) {
                // Send the rewards to dev's wallet
                // uint256 restOfTaxedAmount = _calculatePercentagePart(
                //     taxedAmountNCTR,
                //     MAX_PERC - compoundBurnPercNCTR
                // );
                require(
                    nectarToken.transfer(devWalletAddressNCTR, taxedAmountNCTR),
                    "Nectar token transfer failed!"
                );
                downlineDepth = NUM_OF_TIERS - 1;

                emit Reward(
                    devWalletAddressNCTR,
                    taxedAmountNCTR,
                    address(nectarToken)
                );

                downlineRewardTracker[devWalletAddressNCTR]
                    .compoundDownlineNCTR += taxedAmountNCTR;

                emit DepositRewardFrom(
                    devWalletAddressNCTR,
                    msg.sender,
                    taxedAmountNCTR,
                    0
                );

                break;
            }

            if (
                downlineDepth >= users[msg.sender].uplineRewardTracker &&
                _getRewardEligibility(upline, downlineDepth)
            ) {
                // Calculate amount of NCTR for the swap
                uint256 forSwapNCTR = _calculatePercentagePart(
                    taxedAmountNCTR,
                    compoundUplinePercUSDCe
                );

                // Swap 5% NCTR for USDC.e and send it to upline's USDC.e wallet
                uint256 usdcBalanceBefore = USDCeToken.balanceOf(address(this));

                nectarToken.approve(liquidityManagerAddress, forSwapNCTR);
                nectarToken.swapTokenForUsdc(forSwapNCTR, 1);

                uint256 forUplineWalletUSDCe = USDCeToken.balanceOf(
                    address(this)
                ) - usdcBalanceBefore;

                require(
                    USDCeToken.transfer(upline, forUplineWalletUSDCe),
                    "USDC.e token transfer failed!"
                );

                downlineRewardTracker[upline]
                    .compoundDownlineeUSDCe += forUplineWalletUSDCe;

                // Calculate 45% of the compound NCTR amount to deposit section
                uint256 forUplineDepositSectionNCTR = _calculatePercentagePart(
                    taxedAmountNCTR,
                    compoundUplinePercNCTR
                );
                // fix

                forUplineDepositSectionNCTR = forUplineDepositSectionNCTR / 2;
                totalDepositedNCTR += forUplineDepositSectionNCTR;

                // Check if upline is Team wallet. If true, give 25% of the upline's reward to downline
                if (
                    userDownlines[upline].length >=
                    MIN_NUM_OF_REF_FOR_TEAM_WALLET
                ) {
                    uint256 downlineRewardNCTR = _calculatePercentagePart(
                        forUplineDepositSectionNCTR,
                        teamWalletDownlineRewardPerc
                    );
                    users[msg.sender].depositsNCTR += downlineRewardNCTR;
                    forUplineDepositSectionNCTR -= downlineRewardNCTR;
                    emit TeamReward(
                        upline,
                        msg.sender,
                        downlineRewardNCTR,
                        address(nectarToken)
                    );
                }
                users[upline].depositsNCTR += forUplineDepositSectionNCTR;

                downlineRewardTracker[upline].compoundDownlineNCTR +=
                    forUplineDepositSectionNCTR *
                    2;

                emit Reward(
                    upline,
                    forUplineDepositSectionNCTR,
                    address(nectarToken)
                );
                emit Reward(upline, forUplineWalletUSDCe, address(USDCeToken));

                emit CompoundRewardFrom(
                    upline,
                    msg.sender,
                    forUplineDepositSectionNCTR * 2,
                    forUplineWalletUSDCe
                );

                break;
            }

            upline = users[upline].upline;
        }

        if (movedBloomBoxes[msg.sender].length > 0) {
            for (uint256 i = 0; i < movedBloomBoxes[msg.sender].length; i++) {
                MoveToBloomify storage bloomifyMove = movetobloomify[
                    movedBloomBoxes[msg.sender][i]
                ];
                [movedBloomBoxes[msg.sender][i]];

                require(
                    bloomifyMove.walletAddress == msg.sender,
                    "You are not the owner of this BloomBox"
                );

                require(bloomifyMove.movingDay < 101, "day limit reached");
                if (
                    bloomifyMove.movingDay < 10 &&
                    bloomifyMove.alreadyMoved < bloomifyMove.instantAmount
                ) {
                    movedNCTRFromBloomBox[msg.sender] +=
                        bloomifyMove.instantAmount /
                        10;
                    bloomifyMove.movingDay += 1;
                    bloomifyMove.alreadyMoved +=
                        bloomifyMove.instantAmount /
                        10;
                } else {
                    bloomifyMove.alreadyMoved += calculateFee(
                        bloomifyMove.rewardAmount,
                        2000
                    );
                    movedNCTRFromBloomBox[msg.sender] += calculateFee(
                        bloomifyMove.rewardAmount,
                        2000
                    );
                    bloomifyMove.movingDay += 1;
                }
            }
        }

        // Prepare tracker for next reward
        users[msg.sender].uplineRewardTracker = downlineDepth + 1;

        // Reset tracker if we've hit the end of the line
        if (users[msg.sender].uplineRewardTracker >= NUM_OF_TIERS) {
            users[msg.sender].uplineRewardTracker = 0;
        }

        // Update dailyClaimAmount since DEPOSITED VALUE has change
        _updateDailyClaimAmount(msg.sender);
        if (users[msg.sender].upline != address(0)) {
            _updateDailyClaimAmount(users[msg.sender].upline);
        }
    }

    function removeFromArray(Action[] storage array, uint256 index)
        private
        returns (Action[] storage)
    {
        require(array.length > index, "PL:1");
        // move all elements to the left, starting from the `index + 1`
        for (uint256 i = index; i < array.length - 1; i++) {
            array[i] = array[i + 1];
        }
        array.pop(); // delete the last item
        return array;
    }

    function getLastActions(address user)
        external
        view
        returns (Action[] memory)
    {
        return users[user].lastActions;
    }

    function getRealLastActions(address user)
        public
        view
        returns (uint256 countCompound, uint256 countClaim)
    {
        Action[] storage actions = users[user].lastActions;
        for (uint256 i; i < actions.length; i++) {
            if (actions[i].timestamp + 7 days > block.timestamp) {
                if (actions[i].isCompound) {
                    countCompound += 1;
                } else {
                    countClaim += 1;
                }
            }
        }
    }

    function getLastActionCount(address user)
        public
        view
        returns (uint256 countCompound, uint256 countClaim)
    {
        Action[] storage actions = users[user].lastActions;
        for (uint256 i; i < actions.length; i++) {
            if (actions.length >= 7) {
                if (actions.length - 7 > i) {
                    if (actions[i].isCompound) {
                        countCompound += 1;
                    } else {
                        countClaim += 1;
                    }
                } else {
                    break;
                }
            } else {
                if (actions[i].isCompound) {
                    countCompound += 1;
                } else {
                    countClaim += 1;
                }
            }
        }
    }

    function setNftAddress(address _nft) external onlyOwner {
        nft = _nft;
    }

    function setPercentagePerTier(
        uint256 percentageTier1,
        uint256 percentageTier2,
        uint256 percentageTier3,
        uint256 percentageTier4,
        uint256 percentagePredator,
        uint256 denominator
    ) external onlyOwner {
        percentagePerTier = [
            percentageTier1,
            percentageTier2,
            percentageTier3,
            percentageTier4,
            percentagePredator
        ];
        denominatorPercentagePerTier = denominator;
    }

    function stake(uint256 tokenID) external {
        IDarkForestNFT(nft).transferFrom(msg.sender, address(this), tokenID);
        users[msg.sender].nftTier = IDarkForestNFT(nft).tierOfNfts(tokenID);
        tokenStaked[tokenID] = msg.sender;
        updateAPR(msg.sender);
    }

    function unstake(uint256 tokenID) external {
        require(tokenStaked[tokenID] == msg.sender);
        IDarkForestNFT(nft).transferFrom(address(this), msg.sender, tokenID);
        users[msg.sender].nftTier = 0;
        updateAPR(msg.sender);
    }

    /**
     * @dev - Distribute compound rewards to the upline with Round Robin system
     */
    function compoundRewards() external onlyBloomReferralNode {
        require(
            users[msg.sender].nextActionTime < block.timestamp,
            "Can't make two actions under 24h!"
        );

        _compoundRewards();
        updateAPR(msg.sender);

        Action[] storage actions;
        if (users[msg.sender].lastActions.length == 7) {
            actions = removeFromArray(users[msg.sender].lastActions, 0);
        } else {
            actions = users[msg.sender].lastActions;
        }
        actions.push(Action(true, block.timestamp));
        users[msg.sender].lastActions = actions;

        // Update last and next possible action time
        _updateActionTime(msg.sender);
    }

    /**
     * @dev - Claim sender's daily claim amount from Bloom Treasury, calculate taxes
     */
    function claim() external onlyBloomReferralNode {
        require(
            getDepositedValue(msg.sender) + airdrops[msg.sender].airdropsGiven >
                getPendingReward(msg.sender) + users[msg.sender].payouts,
            "Can't claim if your NET DEPOSITE VALUE - daily claim amount is negative!"
        );

        uint256 maxClaim = (getDepositedValue(msg.sender) * 365) / MAX_PERC;
        require(
            users[msg.sender].payouts + getPendingReward(msg.sender) <=
                maxClaim,
            "Can't claim more than 365% of the DEPOSITED VALUE!"
        );

        require(
            users[msg.sender].nextActionTime < block.timestamp,
            "Can't make two actions under 24h!"
        );

        uint256 treasuryBalance = nectarToken.balanceOf(address(treasury));

        require(
            getPendingReward(msg.sender) < 2000000000000000000000,
            "Call Dev Team"
        );

        if (treasuryBalance < getPendingReward(msg.sender)) {
            uint256 differenceToMint = getPendingReward(msg.sender) -
                treasuryBalance;
            nectarToken.mintNectar(address(treasury), differenceToMint);
        }

        (uint256 countCompound, uint256 countClaim) = getLastActionCount(
            msg.sender
        );
        uint256 _claimTax;
        if (countCompound == 7 && countClaim == 0) {
            _claimTax = 10;
        } else if (countCompound == 6 && countClaim == 1) {
            _claimTax = 10;
        } else if (countCompound == 5 && countClaim == 2) {
            _claimTax = 25;
        } else if (countCompound == 4 && countClaim == 3) {
            _claimTax = 25;
        } else if (countCompound == 3 && countClaim == 4) {
            _claimTax = 50;
        } else {
            _claimTax = 10;
        }
        (uint256 realizedClaimNCTR, ) = _calculateTax(
            getPendingReward(msg.sender),
            _claimTax
        );

        // @notice - rest of the NCTR amount is already in the Flower

        // Send NCTR tokens from Treasury to claimer's address
        treasury.withdrawNCTR(msg.sender, realizedClaimNCTR);

        totalWithdraw += getPendingReward(msg.sender);
        users[msg.sender].payouts += getPendingReward(msg.sender);
        Action[] storage actions;
        if (users[msg.sender].lastActions.length == 7) {
            actions = removeFromArray(users[msg.sender].lastActions, 0);
        } else {
            actions = users[msg.sender].lastActions;
        }
        actions.push(Action(false, block.timestamp));
        users[msg.sender].lastActions = actions;

        if (movedBloomBoxes[msg.sender].length > 0) {
            for (uint256 i = 0; i < movedBloomBoxes[msg.sender].length; i++) {
                MoveToBloomify storage bloomifyMove = movetobloomify[
                    movedBloomBoxes[msg.sender][i]
                ];
                [movedBloomBoxes[msg.sender][i]];

                require(
                    bloomifyMove.walletAddress == msg.sender,
                    "You are not the owner of this BloomBox"
                );

                require(bloomifyMove.movingDay < 101, "day limit reached");
                if (
                    bloomifyMove.movingDay < 10 &&
                    bloomifyMove.alreadyMoved < bloomifyMove.instantAmount
                ) {
                    movedNCTRFromBloomBox[msg.sender] +=
                        bloomifyMove.instantAmount /
                        10;
                    bloomifyMove.movingDay += 1;
                    bloomifyMove.alreadyMoved +=
                        bloomifyMove.instantAmount /
                        10;
                } else {
                    bloomifyMove.alreadyMoved += calculateFee(
                        bloomifyMove.rewardAmount,
                        2000
                    );
                    movedNCTRFromBloomBox[msg.sender] += calculateFee(
                        bloomifyMove.rewardAmount,
                        2000
                    );
                    bloomifyMove.movingDay += 1;
                }
            }
        }

        emit Claim(msg.sender, getPendingReward(msg.sender));

        // Update last and next possible action time
        updateAPR(msg.sender);
        _updateActionTime(msg.sender);
    }

    function calculateFee(uint256 _amount, uint256 _fee)
        internal
        pure
        returns (uint256)
    {
        uint256 calculateFees = _amount * _fee;

        return calculateFees / 10000;
    }

    /**
     * @dev - Airdrop to multiple addresses and save airdrops to Treasury. Update _receivers deposit section
     * @param _receivers - Addresses to which airdrop would go
     * @param _airdrops - Amounts to airdrop to receivers
     * @notice - _receivers and _amounts indexes must match
     */
    function airdrop(address[] memory _receivers, uint256[] memory _airdrops)
        external
        onlyBloomReferralNode
    {
        require(
            _receivers.length == _airdrops.length,
            "Receivers and airdrops array lengths must be equal!"
        );

        uint256 sumOfAirdrops = 0;
        for (uint256 i = 0; i < _airdrops.length; i++) {
            require(_airdrops[i] > 0, "Can't airdrop amount equal to zero!");
            require(
                users[_receivers[i]].upline != address(0) ||
                    _receivers[i] == owner(),
                "Can't airdrop to someone that's not in the Bloom Referral system!"
            );

            sumOfAirdrops += _airdrops[i];

            // Update receiver's stats
            airdrops[_receivers[i]].airdropsReceived += _airdrops[i];
            _updateDailyClaimAmount(_receivers[i]);
        }

        require(
            nectarToken.transferFrom(
                msg.sender,
                address(treasury),
                sumOfAirdrops
            ),
            "NCTR token transfer failed!"
        );

        // Update sender's stats
        airdrops[msg.sender].airdropsGiven += sumOfAirdrops;
        airdrops[msg.sender].lastAirdropTime = block.timestamp;
        totalAirdrops += sumOfAirdrops;

        emit AirdropNCTR(msg.sender, _receivers, _airdrops, block.timestamp);
    }

    function setRouterAddress(address _router) external onlyOwner {
        require(_router != address(0), "invalid address");

        router = IBloomexRouter02(_router);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";
import "./extensions/IERC20MetadataUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable, IERC20MetadataUpgradeable {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    function __ERC20_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[45] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC1155/ERC1155.sol)

pragma solidity ^0.8.0;

import "./IERC1155Upgradeable.sol";
import "./IERC1155ReceiverUpgradeable.sol";
import "./extensions/IERC1155MetadataURIUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../utils/introspection/ERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155Upgradeable is Initializable, ContextUpgradeable, ERC165Upgradeable, IERC1155Upgradeable, IERC1155MetadataURIUpgradeable {
    using AddressUpgradeable for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    function __ERC1155_init(string memory uri_) internal onlyInitializing {
        __ERC1155_init_unchained(uri_);
    }

    function __ERC1155_init_unchained(string memory uri_) internal onlyInitializing {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return
            interfaceId == type(IERC1155Upgradeable).interfaceId ||
            interfaceId == type(IERC1155MetadataURIUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: balance query for the zero address");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC1155: setting approval status for self");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    /**
     * @dev Hook that is called after any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155ReceiverUpgradeable(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155ReceiverUpgradeable.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155ReceiverUpgradeable(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155ReceiverUpgradeable.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[47] private __gap;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.2;

import "./IBloomexRouter01.sol";

interface IBloomexRouter02 is IBloomexRouter01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.13;

interface INectar {
    function approve(address spender, uint256 amount) external returns (bool);

    function balanceOf(address account) external returns (uint256);

    function burnNectar(address account, uint256 amount) external;

    function mintNectar(address _to, uint256 _amount) external returns (bool);

    function transfer(address to, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    function swapUsdcForToken(uint256 _amountIn, uint256 _amountOutMin)
        external;

    function swapTokenForUsdc(uint256 _amountIn, uint256 _amountOutMin)
        external;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.13;

interface ITreasuryUpgradeable {
    function withdrawNCTR(address _to, uint256 _amount) external;

    function withdrawUSDCe(address _to, uint256 _amount) external;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

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
        bool isTopLevelCall = _setInitializedVersion(1);
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
        bool isTopLevelCall = _setInitializedVersion(version);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(version);
        }
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
        _setInitializedVersion(type(uint8).max);
    }

    function _setInitializedVersion(uint8 version) private returns (bool) {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, and for the lowest level
        // of initializers, because in other contexts the contract may have been reentered.
        if (_initializing) {
            require(
                version == 1 && !AddressUpgradeable.isContract(address(this)),
                "Initializable: contract is already initialized"
            );
            return false;
        } else {
            require(_initialized < version, "Initializable: contract is already initialized");
            _initialized = version;
            return true;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155Upgradeable is IERC165Upgradeable {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155ReceiverUpgradeable is IERC165Upgradeable {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

import "../IERC1155Upgradeable.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURIUpgradeable is IERC1155Upgradeable {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165Upgradeable {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.2;

interface IBloomexRouter01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}