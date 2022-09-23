// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "./lib/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./utils/ContractGuard.sol";

contract AVICPool is Ownable, ContractGuard {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    
    struct UserInfo {
        uint256 amount; // How many tokens the user has provided.
        uint256 rewardAvicDebt; // Reward debt. See explanation below.
        uint256 rewardChamDebt; // Reward debt. See explanation below.

        uint256 lastSnapshotIndex;
        uint256 rewardEarned;
        uint256 epochTimerStart;
    }

    struct DistributeSnapshot {
        uint256 time;
        uint256 rewardReceived;
        uint256 rewardPerShare;
    }

    DistributeSnapshot[] public distributeHistory;
    mapping(address => UserInfo) public userInfo;
    mapping(uint256 => uint256) public totalAvicSupplyEpoch;

    uint256 public constant PERIOD = 10 minutes;
    uint256 public epoch;

    IERC20 private avicToken;
    IERC20 private chamToken;
    IERC20 private yw30Token;

    uint256 public poolStartTime;
    uint256 public poolEndTime;

    uint256 public constant runningTime = 30 days;
    uint256 public constant TOTAL_AVIC_REWARD = 70000 ether;
    uint256 public constant TOTAL_CHAM_REWARD = 500 ether;
    uint256 public avicTokenPerSecond;
    uint256 public chamTokenPerSecond;
    uint256 private accAvicTokenPerShare = 0;
    uint256 private accChamTokenPerShare = 0;
    uint256 private avicLastRewardTime = 0;
    uint256 private chamLastRewardTime = 0;

    uint256 public emergencyWithdrawFeePercent = 50; // 50%

    address public polWallet;
    address public adminAddress;

    event Deposit(address indexed _user, uint256 _amount);
    event EmergencyWithdraw(address indexed _user, uint256 _amount);
    event AvicRewardPaid(address indexed _user, uint256 _amount);
    event ChamRewardPaid(address indexed _user, uint256 _amount);
    event Withdraw(address indexed _user, uint256 _amount);
    event SetEmergencyWithdrawFeePercent(uint256 oldValue, uint256 newValue);
    event DistributedReward(address indexed user, uint256 reward);
    event ExtraRewardPaid(address indexed _user, uint256 _amount);

    /* ========== INITIALIZER ========== */
    constructor(
        address _avicToken, 
        address _chamToken,
        address _yw30Token,
        address _polWallet,
        address _adminAddress,
        uint256 _poolStartTime
    ) {
        require(block.timestamp < _poolStartTime, "late");
        require(_avicToken != address(0), "!_avicToken");
        require(_chamToken != address(0), "!_chamToken");
        require(_yw30Token != address(0), "!_yw30Token");
        require(_polWallet != address(0), "!_polWallet");
        require(_adminAddress != address(0), "!_adminAddress");

        adminAddress = _adminAddress;
        polWallet = _polWallet;

        avicToken = IERC20(_avicToken);
        chamToken = IERC20(_chamToken);
        yw30Token = IERC20(_yw30Token);

        poolStartTime = _poolStartTime;
        poolEndTime = poolStartTime + runningTime;
        avicLastRewardTime = poolStartTime;
        chamLastRewardTime = poolStartTime;

        avicTokenPerSecond = TOTAL_AVIC_REWARD.div(runningTime);
        chamTokenPerSecond = TOTAL_CHAM_REWARD.div(runningTime);

        DistributeSnapshot memory genesisSnapshot = DistributeSnapshot({time: block.number, rewardReceived: 0, rewardPerShare: 0});
        distributeHistory.push(genesisSnapshot);
    }

    modifier onlyAdmin() {
        require(adminAddress == msg.sender, "AVICPool: caller is not the admin");
        _;
    }

    modifier checkEpoch() {
        require(block.timestamp >= nextEpochPoint(), "AVICPool: not opened yet");
        _;
        epoch = epoch.add(1);
    }

    modifier updateExtraReward(address _member) {
        if (_member != address(0)) {
            UserInfo storage user = userInfo[_member];
            user.rewardEarned = earned(_member);
            user.lastSnapshotIndex = latestSnapshotIndex();
            userInfo[_member] = user;
        }
        _;
    }

    // WRITE FUNCTIONS
    function deposit(uint256 _amount) external onlyOneBlock updateExtraReward(msg.sender) {
        address _sender = msg.sender;
        UserInfo storage user = userInfo[_sender];
        updateAvicReward();
        updateChamReward();
        if (user.amount > 0) {
            uint256 pendingAvicReward = user.amount.mul(accAvicTokenPerShare).div(1e18).sub(user.rewardAvicDebt);
            uint256 pendingChamReward = user.amount.mul(accChamTokenPerShare).div(1e18).sub(user.rewardChamDebt);
            if (pendingAvicReward > 0) {
                safeAvicTokenTransfer(_sender, pendingAvicReward);
                emit AvicRewardPaid(_sender, pendingAvicReward);
            }

            if (pendingChamReward > 0) {
                safeChamTokenTransfer(_sender, pendingChamReward);
                emit ChamRewardPaid(_sender, pendingChamReward);
            }
        }

        if (_amount > 0) {
            user.epochTimerStart = epoch; 
            yw30Token.safeTransferFrom(_sender, address(this), _amount);
            user.amount = user.amount.add(_amount);
        }

        user.rewardAvicDebt = user.amount.mul(accAvicTokenPerShare).div(1e18);
        user.rewardChamDebt = user.amount.mul(accChamTokenPerShare).div(1e18);
        emit Deposit(_sender, _amount);
    }

    function withdraw() external onlyOneBlock updateExtraReward(msg.sender) {
        require(block.timestamp > poolEndTime, "AVICPool: locked!");
        address _sender = msg.sender;
        UserInfo storage user = userInfo[_sender];
        uint256 amount = user.amount;
        if (amount > 0) {
            claimExtraReward();
            updateAvicReward();
            updateChamReward();
            uint256 pendingAvicReward = amount.mul(accAvicTokenPerShare).div(1e18).sub(user.rewardAvicDebt);
            uint256 pendingChamReward = amount.mul(accChamTokenPerShare).div(1e18).sub(user.rewardChamDebt);

            if (pendingAvicReward > 0) {
                safeAvicTokenTransfer(_sender, pendingAvicReward);
                emit AvicRewardPaid(_sender, pendingAvicReward);
            }

            if (pendingChamReward > 0) {
                safeChamTokenTransfer(_sender, pendingChamReward);
                emit ChamRewardPaid(_sender, pendingChamReward);
            }

            user.amount = 0;
            user.rewardAvicDebt = 0;
            user.rewardChamDebt = 0;
            yw30Token.safeTransfer(_sender, amount);
        }
        
        emit Withdraw(_sender, amount);
    }
    
    function emergencyWithdraw() external onlyOneBlock updateExtraReward(msg.sender) {
        UserInfo storage user = userInfo[msg.sender];
        uint256 amount = user.amount;
        user.amount = 0;
        user.rewardAvicDebt = 0;
        user.rewardChamDebt = 0;
        if (amount > 0) {
            uint256 reward = userInfo[msg.sender].rewardEarned;
            if (reward > 0) {
                userInfo[msg.sender].epochTimerStart = epoch;
                userInfo[msg.sender].rewardEarned = 0;
            }
            uint256 feeAmount = amount.mul(emergencyWithdrawFeePercent).div(100);
            uint256 withdrawAmount = amount.sub(feeAmount);
            yw30Token.safeTransfer(polWallet, feeAmount);
            yw30Token.safeTransfer(msg.sender, withdrawAmount);
        }

        emit EmergencyWithdraw(msg.sender, amount);
    }

    function claimExtraReward() public updateExtraReward(msg.sender) {
        uint256 reward = userInfo[msg.sender].rewardEarned;
        if (reward > 0) {
            userInfo[msg.sender].epochTimerStart = epoch;
            userInfo[msg.sender].rewardEarned = 0;
            avicToken.safeTransfer(msg.sender, reward);
            emit ExtraRewardPaid(msg.sender, reward);
        }
    }

    function claimAvicReward() external onlyOneBlock {
        address _sender = msg.sender;
        UserInfo storage user = userInfo[_sender];
        updateAvicReward();
        uint256 _pending = user.amount.mul(accAvicTokenPerShare).div(1e18).sub(user.rewardAvicDebt);
        if (_pending > 0) {
            safeAvicTokenTransfer(_sender, _pending);
        }

        user.rewardAvicDebt = user.amount.mul(accAvicTokenPerShare).div(1e18);
        emit AvicRewardPaid(_sender, _pending);
    }

    function claimChamReward() external onlyOneBlock {
        address _sender = msg.sender;
        UserInfo storage user = userInfo[_sender];
        updateChamReward();
        uint256 _pending = user.amount.mul(accChamTokenPerShare).div(1e18).sub(user.rewardChamDebt);
        if (_pending > 0) {
            safeChamTokenTransfer(_sender, _pending);
        }

        user.rewardChamDebt = user.amount.mul(accChamTokenPerShare).div(1e18);
        emit ChamRewardPaid(_sender, _pending);
    }

    function updateAvicReward() internal {
        if (block.timestamp <= avicLastRewardTime) {
            return;
        }
        uint256 tokenSupply = yw30Token.balanceOf(address(this));
        if (tokenSupply == 0) {
            avicLastRewardTime = block.timestamp;
            return;
        }

        uint256 _generatedReward = getAvicGeneratedReward(avicLastRewardTime, block.timestamp);
        accAvicTokenPerShare = accAvicTokenPerShare.add(_generatedReward.mul(1e18).div(tokenSupply));
        avicLastRewardTime = block.timestamp;
    }

    function updateChamReward() internal {
        if (block.timestamp <= chamLastRewardTime) {
            return;
        }
        uint256 tokenSupply = yw30Token.balanceOf(address(this));
        if (tokenSupply == 0) {
            chamLastRewardTime = block.timestamp;
            return;
        }

        uint256 _generatedReward = getChamGeneratedReward(chamLastRewardTime, block.timestamp);
        accChamTokenPerShare = accChamTokenPerShare.add(_generatedReward.mul(1e18).div(tokenSupply));
        chamLastRewardTime = block.timestamp;
    }

    function safeAvicTokenTransfer(address _to, uint256 _amount) internal {
        uint256 avicTokenBalance = avicToken.balanceOf(address(this));
        if (avicTokenBalance > 0) {
            if (_amount > avicTokenBalance) {
                avicToken.safeTransfer(_to, avicTokenBalance);
            } else {
                avicToken.safeTransfer(_to, _amount);
            }
        }
    }

    function safeChamTokenTransfer(address _to, uint256 _amount) internal {
        uint256 chamTokenBalance = chamToken.balanceOf(address(this));
        if (chamTokenBalance > 0) {
            if (_amount > chamTokenBalance) {
                chamToken.safeTransfer(_to, chamTokenBalance);
            } else {
                chamToken.safeTransfer(_to, _amount);
            }
        }
    }

    function setEmergencyWithdrawFeePercent(uint256 _value) external onlyAdmin {
        require(_value <= 50, 'AVICPool: Max percent is 50%');
        emit SetEmergencyWithdrawFeePercent(emergencyWithdrawFeePercent, _value);
        emergencyWithdrawFeePercent = _value;
    }

    function adminWithdraw(address _token, uint256 _amount) external onlyAdmin {
        require(_token == address(avicToken) || _token == address(chamToken), "Only withdraw AVIC, CHAM");
        IERC20(_token).safeTransfer(adminAddress, _amount);
    }

    function distributeExtraReward() external checkEpoch onlyOneBlock {
        if (epoch > 0) {
            uint256 tokenSupply = yw30Token.balanceOf(address(this));
            if (tokenSupply <= 0) return;
            
            uint256 avicAmount = getExtraReward();
            if (avicAmount <= 0) return;
            
            // Create & add new snapshot
            uint256 prevRPS = getLatestSnapshot().rewardPerShare;
            uint256 nextRPS = prevRPS.add(avicAmount.mul(1e18).div(tokenSupply));

            DistributeSnapshot memory newSnapshot = DistributeSnapshot({time: block.number, rewardReceived: avicAmount, rewardPerShare: nextRPS});
            distributeHistory.push(newSnapshot);

            emit DistributedReward(msg.sender, avicAmount);
        }
    }

    function updateTotalAvicSupplyEpoch() external {
        require(block.timestamp < nextEpochPoint(), "AVICPool: set before epoch start");
        totalAvicSupplyEpoch[epoch] = avicToken.totalSupply();
    }

    // READ FUNCTIONS
    function getAvicGeneratedReward(uint256 _fromTime, uint256 _toTime) public view returns (uint256) {
        if (_fromTime >= _toTime) return 0;
        if (_toTime >= poolEndTime) {
            if (_fromTime >= poolEndTime) return 0;
            if (_fromTime <= poolStartTime) return poolEndTime.sub(poolStartTime).mul(avicTokenPerSecond);
            return poolEndTime.sub(_fromTime).mul(avicTokenPerSecond);
        } else {
            if (_toTime <= poolStartTime) return 0;
            if (_fromTime <= poolStartTime) return _toTime.sub(poolStartTime).mul(avicTokenPerSecond);
            return _toTime.sub(_fromTime).mul(avicTokenPerSecond);
        }
    }

    function getChamGeneratedReward(uint256 _fromTime, uint256 _toTime) public view returns (uint256) {
        if (_fromTime >= _toTime) return 0;
        if (_toTime >= poolEndTime) {
            if (_fromTime >= poolEndTime) return 0;
            if (_fromTime <= poolStartTime) return poolEndTime.sub(poolStartTime).mul(chamTokenPerSecond);
            return poolEndTime.sub(_fromTime).mul(chamTokenPerSecond);
        } else {
            if (_toTime <= poolStartTime) return 0;
            if (_fromTime <= poolStartTime) return _toTime.sub(poolStartTime).mul(chamTokenPerSecond);
            return _toTime.sub(_fromTime).mul(chamTokenPerSecond);
        }
    }

    function pendingAvic(address _user) external view returns (uint256) {
        UserInfo storage user = userInfo[_user];
        uint256 accTokenPerShare = accAvicTokenPerShare;
        uint256 tokenSupply = yw30Token.balanceOf(address(this));
        if (block.timestamp > avicLastRewardTime && tokenSupply != 0) {
            uint256 _generatedReward = getAvicGeneratedReward(avicLastRewardTime, block.timestamp);
            accTokenPerShare = accTokenPerShare.add(_generatedReward.mul(1e18).div(tokenSupply));
        }

        return user.amount.mul(accTokenPerShare).div(1e18).sub(user.rewardAvicDebt);
    }

    function pendingCham(address _user) external view returns (uint256) {
        UserInfo storage user = userInfo[_user];
        uint256 accTokenPerShare = accChamTokenPerShare;
        uint256 tokenSupply = yw30Token.balanceOf(address(this));
        if (block.timestamp > chamLastRewardTime && tokenSupply != 0) {
            uint256 _generatedReward = getChamGeneratedReward(chamLastRewardTime, block.timestamp);
            accTokenPerShare = accTokenPerShare.add(_generatedReward.mul(1e18).div(tokenSupply));
        }

        return user.amount.mul(accTokenPerShare).div(1e18).sub(user.rewardChamDebt);
    }

    function nextEpochPoint() public view returns (uint256) {
        return poolStartTime.add(epoch.mul(PERIOD));
    }

    function getLatestSnapshot() internal view returns (DistributeSnapshot memory) {
        return distributeHistory[latestSnapshotIndex()];
    }

    function latestSnapshotIndex() public view returns (uint256) {
        return distributeHistory.length.sub(1);
    }

    function earned(address _member) public view returns (uint256) {
        uint256 latestRPS = getLatestSnapshot().rewardPerShare;
        uint256 storedRPS = getLastSnapshotOf(_member).rewardPerShare;

        return userInfo[_member].amount.mul(latestRPS.sub(storedRPS)).div(1e18).add(userInfo[_member].rewardEarned);
    }

    function getLastSnapshotIndexOf(address _member) public view returns (uint256) {
        return userInfo[_member].lastSnapshotIndex;
    }

    function getLastSnapshotOf(address _member) internal view returns (DistributeSnapshot memory) {
        return distributeHistory[getLastSnapshotIndexOf(_member)];
    }

    function getExtraReward() public view returns (uint256) {
        if (epoch == 0) return 0;

        uint256 totalAvicSupplyCurrentEpoch = totalAvicSupplyEpoch[epoch];
        uint256 totalAvicSupplyPrevEpoch = totalAvicSupplyEpoch[epoch - 1];
        if (totalAvicSupplyPrevEpoch == 0 || totalAvicSupplyPrevEpoch > totalAvicSupplyCurrentEpoch) return 0;

        return totalAvicSupplyCurrentEpoch.sub(totalAvicSupplyPrevEpoch).mul(10).div(100);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

contract ContractGuard {
    mapping(uint256 => mapping(address => bool)) private _status;

    function checkSameOriginReentranted() internal view returns (bool) {
        return _status[block.number][tx.origin];
    }

    function checkSameSenderReentranted() internal view returns (bool) {
        return _status[block.number][msg.sender];
    }

    modifier onlyOneBlock() {
        require(!checkSameOriginReentranted(), "ContractGuard: one block, one function");
        require(!checkSameSenderReentranted(), "ContractGuard: one block, one function");

        _status[block.number][tx.origin] = true;
        _status[block.number][msg.sender] = true;

        _;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity 0.8.13;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
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
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
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
}