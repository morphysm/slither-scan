// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "./lib/Babylonian.sol";
import "./owner/Operator.sol";
import "./utils/ContractGuard.sol";
import "./interfaces/IBasisAsset.sol";
import "./interfaces/IOracle.sol";
import "./interfaces/IBoardroom.sol";
import "./interfaces/IEVICToken.sol";
import "./lib/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract EVICTreasury is ContractGuard {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    /* ========= CONSTANT VARIABLES ======== */
    uint256 public constant PERIOD = 6 hours;

    /* ========== STATE VARIABLES ========== */

    // governance
    address public operator;
    // flags
    bool public initialized;
    // epoch
    uint256 public startTime;
    uint256 public epoch;
    uint256 public previousEpoch;
    uint256 public epochSupplyContractionLeft;

    address public mainToken;
    address public boardroom;
    address public oracle;

    // price
    uint256 public mainTokenPriceOne;
    uint256 public mainTokenPriceCeiling;
    uint256 public mainTokenPriceRebase;
    uint256 public consecutiveEpochHasPriceBelowOne;

    uint256 public totalEpochAbovePeg = 0;
    uint256 public totalEpochUnderPeg = 0;
    uint256 public totalEpochRebase = 0;

    uint256[] public supplyTiers;
    uint256[] public maxExpansionTiers;

    uint256[] public expansionTiersTwaps = [0, 1.5 ether, 2 ether];
    uint256[] public expansionTiersRates = [4000, 7000, 10000];

    /*===== Rebase ====*/
    uint256 private constant DECIMALS = 18;
    uint256 private constant STABLE_DECIMALS = 18;
    uint256 private constant ONE = uint256(10**DECIMALS);
    // Due to the expression in computeSupplyDelta(), MAX_RATE * MAX_SUPPLY must fit into an int256.
    // Both are 18 decimals fixed point numbers.
    uint256 private constant MAX_RATE = 10**STABLE_DECIMALS * 10**DECIMALS;
    // MAX_SUPPLY = MAX_INT256 / MAX_RATE
    uint256 private constant MAX_SUPPLY = uint256(type(int256).max) / MAX_RATE;
    
    bool public rebaseStarted;
    bool public enabledRebase = true;

    uint256 private constant midpointRounding = 10**(DECIMALS - 4);

    uint256 public previousEpochMainPrice;

    uint256 public minTokenToExpansion = 0.675 ether;
    uint256 public minTokenSupplyToExpansion = 15 ether;

    /*===== End Rebase ====*/
        
    uint256 public constant daoFundSharedPercent = 10; // 10%
    uint256 public constant polFundSharedPercent = 15; // 15%

    uint256 private constant minPercentExpansionTier = 10; // 0.1%
    uint256 private constant maxPercentExpansionTier = 1000; // 10%
        
    /* =================== Events =================== */

    event Initialized(address indexed executor, uint256 at);
    event TreasuryFunded(uint256 timestamp, uint256 seigniorage);
    event BoardroomFunded(uint256 timestamp, uint256 seigniorage);
    event DaoFundFunded(uint256 timestamp, uint256 seigniorage);
    event PolFundFunded(uint256 timestamp, uint256 seigniorage);
    event LogRebase(
        uint256 indexed epoch,
        uint256 supplyDelta,
        uint256 newPrice,
        uint256 oldPrice,
        uint256 newTotalSupply,
        uint256 oldTotalSupply,
        uint256 timestampSec
    );
    event EnableRebase();
    event DisableRebase();
    event SetOperator(address indexed account, address newOperator);
    event SetBoardroom(address indexed account, address newBoardroom);
    event SetMainTokenPriceCeiling(uint256 newValue);
    event SetSupplyTiersEntry(uint8 _index, uint256 _value);
    event SetMaxExpansionTiersEntry(uint8 _index, uint256 _value);
    event SetMinTokenToExpansion(uint256 oldValue, uint256 newValue);
    event SetMinTokenSupplyToExpansion(uint256 oldValue, uint256 newValue);
    event SetExpansionTiersTwaps(uint8 _index, uint256 _value);
    event SetExpansionTiersRates(uint8 _index, uint256 _value);

    constructor() {
        initialized = false;
        epoch = 0;
        previousEpoch = 0;
        epochSupplyContractionLeft = 0;
        consecutiveEpochHasPriceBelowOne = 0;
        rebaseStarted = false;
        previousEpochMainPrice = 0;
    }

    /* =================== Modifier =================== */

    modifier onlyOperator() {
        require(operator == msg.sender, "Treasury: caller is not the operator");
        _;
    }

    modifier checkCondition() {
        require(block.timestamp >= startTime, "Treasury: not started yet");

        _;
    }

    modifier checkEpoch() {
        require(block.timestamp >= nextEpochPoint(), "Treasury: not opened yet");

        _;

        epoch = epoch.add(1);
    }

    modifier checkOperator() {
        require(
            IBasisAsset(mainToken).operator() == address(this) &&
                Operator(boardroom).operator() == address(this),
            "Treasury: need more permission"
        );

        _;
    }

    modifier notInitialized() {
        require(!initialized, "Treasury: already initialized");

        _;
    }

    /* ========== VIEW FUNCTIONS ========== */

    function isInitialized() external view returns (bool) {
        return initialized;
    }

    // epoch
    function nextEpochPoint() public view returns (uint256) {
        return startTime.add(epoch.mul(PERIOD));
    }

    // oracle
    function getMainTokenPrice() public view returns (uint256) {
        try IOracle(oracle).consult(mainToken, 1e18) returns (uint144 price) {
            return uint256(price);
        } catch {
            revert("Treasury: failed to consult MainToken price from the oracle");
        }
    }

    function getTwapPrice() public view returns (uint256) {
        try IOracle(oracle).twap(mainToken, 1e18) returns (uint144 price) {
            return uint256(price);
        } catch {
            revert("Treasury: failed to twap MainToken price from the oracle");
        }
    }

    function initialize(
        address _mainToken,
        address _oracle,
        address _boardroom,
        uint256 _startTime
    ) external notInitialized {
        require(_mainToken != address(0), "!_mainToken");
        require(_oracle != address(0), "!_oracle");
        require(_boardroom != address(0), "!_boardroom");

        mainToken = _mainToken;
        oracle = _oracle;
        boardroom = _boardroom;

        startTime = _startTime;

        mainTokenPriceOne = 10**STABLE_DECIMALS; // This is to allow a PEG of 1 MainToken per WETH
        mainTokenPriceRebase = 8*10**(STABLE_DECIMALS - 1); // 0.8 WETH
        mainTokenPriceCeiling = mainTokenPriceOne.mul(101).div(100);

        // Dynamic max expansion percent
        supplyTiers = [15 ether, 250 ether, 500 ether, 750 ether, 1000 ether, 2500 ether, 5000 ether, 10000 ether, 25000 ether];
        maxExpansionTiers = [450, 400, 350, 300, 250, 200, 150, 125, 100];

        IEVICToken(mainToken).grantRebaseExclusion(address(this));
        IEVICToken(mainToken).grantRebaseExclusion(address(boardroom));

        initialized = true;
        operator = msg.sender;

        emit Initialized(msg.sender, block.number);
    }

    function setOperator(address _operator) external onlyOperator {
        operator = _operator;
        emit SetOperator(msg.sender, _operator);
    }

    function setBoardroom(address _boardroom) external onlyOperator {
        boardroom = _boardroom;
        emit SetBoardroom(msg.sender, _boardroom);
    }

    function grantRebaseExclusion(address who) external onlyOperator {
        IEVICToken(mainToken).grantRebaseExclusion(who);
    }

    function revokeRebaseExclusion(address who) external onlyOperator {
        IEVICToken(mainToken).revokeRebaseExclusion(who);
    }

    function setMainTokenPriceCeiling(uint256 _mainTokenPriceCeiling) external onlyOperator {
        require(_mainTokenPriceCeiling >= mainTokenPriceOne && _mainTokenPriceCeiling <= mainTokenPriceOne.mul(120).div(100), "out of range"); // [$1.0, $1.2]
        mainTokenPriceCeiling = _mainTokenPriceCeiling;
        emit SetMainTokenPriceCeiling(_mainTokenPriceCeiling);
    }

    function setSupplyTiersEntry(uint8 _index, uint256 _value) external onlyOperator returns (bool) {
        require(_index >= 0, "Index has to be higher than 0");
        require(_index < supplyTiers.length, "Index has to be lower than count of tiers");
        if (_index > 0) {
            require(_value > supplyTiers[_index - 1]);
        }
        if (_index < 8) {
            require(_value < supplyTiers[_index + 1]);
        }
        supplyTiers[_index] = _value;
        emit SetSupplyTiersEntry(_index, _value);
        return true;
    }

    function setMaxExpansionTiersEntry(uint8 _index, uint256 _value) external onlyOperator returns (bool) {
        require(_index >= 0, "Index has to be higher than 0");
        require(_index < maxExpansionTiers.length, "Index has to be lower than count of tiers");
        require(_value >= minPercentExpansionTier && _value <= maxPercentExpansionTier, "_value: out of range"); // [0.1%, 10%]
        maxExpansionTiers[_index] = _value;
        emit SetMaxExpansionTiersEntry(_index, _value);
        return true;
    }

    function syncPrice() external {
        try IOracle(oracle).sync() {} catch {
            revert("Treasury: failed to sync price from the oracle");
        }
    }

    function _updatePrice() internal {
        try IOracle(oracle).update() {} catch {
            revert("Treasury: failed to update price from the oracle");
        }
    }

    function getMainTokenCirculatingSupply() public view returns (uint256) {
        return IEVICToken(mainToken).rebaseSupply();
    }

    function getEstimatedReward() external view returns (uint256) {
        uint256 mainTokenTotalSupply = IEVICToken(mainToken).totalSupply();
        uint256 estimatedReward = minTokenToExpansion;
        if (mainTokenTotalSupply >= minTokenSupplyToExpansion) {   
            uint256 percentage = calculateMaxSupplyExpansionPercent(mainTokenTotalSupply);
            estimatedReward = mainTokenTotalSupply.mul(percentage).div(10000);
        }
        uint256 tokenPrice = getTwapPrice();
        uint256 expansionRate = calculateExpansionRate(tokenPrice);
        estimatedReward = estimatedReward.mul(expansionRate).div(10000);

        uint256 _daoFundSharedAmount = estimatedReward.mul(daoFundSharedPercent).div(100);
        uint256 _polFundSharedAmount = estimatedReward.mul(polFundSharedPercent).div(100);

        return estimatedReward.sub(_daoFundSharedAmount).sub(_polFundSharedAmount);
    }

    function _sendToBoardroom(uint256 _amount) internal {
        IEVICToken mainTokenErc20 = IEVICToken(mainToken);
        mainTokenErc20.mint(address(this), _amount);

        uint256 _daoFundSharedAmount = _amount.mul(daoFundSharedPercent).div(100);
        address daoFund = mainTokenErc20.getDaoFund();
        mainTokenErc20.transfer(daoFund, _daoFundSharedAmount);
        emit DaoFundFunded(block.timestamp, _daoFundSharedAmount);

        uint256 _polFundSharedAmount = _amount.mul(polFundSharedPercent).div(100);
        address polFund = mainTokenErc20.getPolWallet();
        mainTokenErc20.transfer(polFund, _polFundSharedAmount);
        emit PolFundFunded(block.timestamp, _polFundSharedAmount);

        _amount = _amount.sub(_daoFundSharedAmount).sub(_polFundSharedAmount);
        IERC20(mainToken).safeApprove(boardroom, 0);
        IERC20(mainToken).safeApprove(boardroom, _amount);
        IBoardroom(boardroom).allocateSeigniorage(_amount);
        emit BoardroomFunded(block.timestamp, _amount);
    }

    function calculateMaxSupplyExpansionPercent(uint256 _mainTokenSupply) public view returns (uint256) {
        if (_mainTokenSupply < minTokenSupplyToExpansion) {
            return 0;
        }
        uint256 maxSupplyExpansionPercent;
        uint256 supplyTierLength = supplyTiers.length;
        uint256 maxExpansionTiersLength = maxExpansionTiers.length;
        require(supplyTierLength == maxExpansionTiersLength, "SupplyTier data invalid");

        for (uint256 tierId = supplyTierLength - 1; tierId >= 0; --tierId) {
            if (_mainTokenSupply >= supplyTiers[tierId]) {
                maxSupplyExpansionPercent = maxExpansionTiers[tierId];
                break;
            }
        }
        
        return maxSupplyExpansionPercent;
    }

    function calculateExpansionRate(uint256 _mainTokenSupply) public view returns (uint256) {
        uint256 expansionRate;
        uint256 expansionTiersTwapsLength = expansionTiersTwaps.length;
        uint256 expansionTiersRatesLength = expansionTiersRates.length;
        require(expansionTiersTwapsLength == expansionTiersRatesLength, "ExpansionTiers data invalid");

        for (uint256 tierId = expansionTiersTwapsLength - 1; tierId >= 0; --tierId) {
            if (_mainTokenSupply >= expansionTiersTwaps[tierId]) {
                expansionRate = expansionTiersRates[tierId];
                break;
            }
        }
        
        return expansionRate;
    }

    function allocateSeigniorage() external onlyOneBlock checkCondition checkEpoch checkOperator {
        _updatePrice();
        if (epoch > 0) {
            previousEpochMainPrice = getMainTokenPrice();
            if (previousEpochMainPrice > mainTokenPriceCeiling) {
                totalEpochAbovePeg = totalEpochAbovePeg.add(1);
                // Expansion
                uint256 mainTokenTotalSupply = IEVICToken(mainToken).totalSupply();
                uint256 _savedForBoardroom = minTokenToExpansion;
                if (mainTokenTotalSupply >= minTokenSupplyToExpansion) {
                    uint256 _percentage = calculateMaxSupplyExpansionPercent(mainTokenTotalSupply);
                    _savedForBoardroom = mainTokenTotalSupply.mul(_percentage).div(10000);
                }

                if (_savedForBoardroom > 0) {
                    uint256 expansionRate = calculateExpansionRate(previousEpochMainPrice);
                    _savedForBoardroom = _savedForBoardroom.mul(expansionRate).div(10000);

                    uint256 boardRoomAmount = IBoardroom(boardroom).totalSupply();
                    if (boardRoomAmount > 0) {
                        _sendToBoardroom(_savedForBoardroom);
                    } else {
                        // mint to DAOFund
                        address daoFund = IEVICToken(mainToken).getDaoFund();
                        IEVICToken(mainToken).mint(daoFund, _savedForBoardroom);
                    }
                }
            }

            if (previousEpochMainPrice < mainTokenPriceCeiling) {
                totalEpochUnderPeg = totalEpochUnderPeg.add(1);
            }

            // Rebase
            if (enabledRebase) {
                if (previousEpochMainPrice < mainTokenPriceOne) {
                    consecutiveEpochHasPriceBelowOne = consecutiveEpochHasPriceBelowOne.add(1);
                } else {
                    consecutiveEpochHasPriceBelowOne = 0;
                }
                
                if (rebaseStarted && previousEpochMainPrice < mainTokenPriceOne) {
                    _rebase(mainTokenPriceOne);
                    consecutiveEpochHasPriceBelowOne = 0;
                } else {
                    rebaseStarted = false;
                    // twap <= 0.8 USD => rebase
                    // 10 consecutive epoch has twap < 1 USD => rebase
                    if (previousEpochMainPrice <= mainTokenPriceRebase || consecutiveEpochHasPriceBelowOne == 10) {
                        _rebase(mainTokenPriceOne);
                        consecutiveEpochHasPriceBelowOne = 0;
                    }
                }
            }
        }
    }

    function boardroomAllocateSeigniorage(uint256 amount) external onlyOperator {
        IBoardroom(boardroom).allocateSeigniorage(amount);
    }

    function computeSupplyDelta() public view returns (bool negative, uint256 supplyDelta, uint256 targetRate) {
        require(previousEpochMainPrice > 0, "previousEpochMainPrice invalid");
        targetRate = 10**DECIMALS;
        uint256 rate = previousEpochMainPrice.mul(10**DECIMALS).div(10**STABLE_DECIMALS);
        negative = rate < targetRate;
        uint256 rebasePercentage = ONE;
        if (negative) {
            rebasePercentage = targetRate.sub(rate).mul(ONE).div(targetRate);
        } else {
            rebasePercentage = rate.sub(targetRate).mul(ONE).div(targetRate);
        }

        supplyDelta = mathRound(getMainTokenCirculatingSupply().mul(rebasePercentage).div(ONE));
    }

    function mathRound(uint256 _value) internal pure returns (uint256) {
        uint256 valueFloor = _value.div(midpointRounding).mul(midpointRounding);
        uint256 delta = _value.sub(valueFloor);
        if (delta >= midpointRounding.div(2)) {
            return valueFloor.add(midpointRounding);
        } else {
            return valueFloor;
        }
    }

    function _rebase(uint256 _oldPrice) internal {
        require(epoch >= previousEpoch, "cannot rebase");
        (bool negative, uint256 supplyDelta, uint256 targetRate) = computeSupplyDelta();

        uint256 oldTotalSupply = IERC20(mainToken).totalSupply();
        uint256 newTotalSupply = oldTotalSupply;
        if (supplyDelta > 0) {
            rebaseStarted = true;
            if (oldTotalSupply.add(uint256(supplyDelta)) > MAX_SUPPLY) {
                supplyDelta = MAX_SUPPLY.sub(oldTotalSupply);
            }

            newTotalSupply = IEVICToken(mainToken).rebase(epoch, supplyDelta, negative);
            require(newTotalSupply <= MAX_SUPPLY, "newTotalSupply <= MAX_SUPPLY");
            previousEpoch = epoch;
            totalEpochRebase = totalEpochRebase.add(1);
        }

        emit LogRebase(epoch, supplyDelta, targetRate, _oldPrice, newTotalSupply, oldTotalSupply, block.timestamp);
    }

    function setMinTokenToExpansion(uint256 _value) external onlyOperator {
        emit SetMinTokenToExpansion(minTokenToExpansion, _value);
        minTokenToExpansion = _value;
    }

    function setMinTokenSupplyToExpansion(uint256 _value) external onlyOperator {
        emit SetMinTokenSupplyToExpansion(minTokenSupplyToExpansion, _value);
        minTokenSupplyToExpansion = _value;
    }

    function setExpansionTiersTwaps(uint8 _index, uint256 _value) external onlyOperator returns (bool) {
        require(_index >= 0, "Index has to be higher than 0");
        uint256 expansionTiersTwapsLength = expansionTiersTwaps.length;
        require(_index < expansionTiersTwapsLength, "Index has to be lower than count of tiers");
        if (_index > 0) {
            require(_value > expansionTiersTwaps[_index - 1]);
        }
        if (_index < expansionTiersTwapsLength - 1) {
            require(_value < expansionTiersTwaps[_index + 1]);
        }
        expansionTiersTwaps[_index] = _value;
        emit SetExpansionTiersTwaps(_index, _value);
        return true;
    }

    function setExpansionTiersRates(uint8 _index, uint256 _value) external onlyOperator returns (bool) {
        require(_index >= 0, "Index has to be higher than 0");
        require(_index < expansionTiersRates.length, "Index has to be lower than count of tiers");
        require(_value <= 10000, "_value: out of range"); // [_value < 100%]
        expansionTiersRates[_index] = _value;
        emit SetExpansionTiersRates(_index, _value);
        return true;
    }

    function enableRebase() external onlyOperator {
        enabledRebase = true;
		emit EnableRebase();
    }

    function disableRebase() external onlyOperator {
        enabledRebase = false;
		emit DisableRebase();
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

pragma solidity 0.8.13;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Operator is Context, Ownable {
    address private _operator;

    event OperatorTransferred(address indexed previousOperator, address indexed newOperator);

    constructor() {
        _operator = _msgSender();
        emit OperatorTransferred(address(0), _operator);
    }

    function operator() public view returns (address) {
        return _operator;
    }

    modifier onlyOperator() {
        require(_operator == msg.sender, "operator: caller is not the operator");
        _;
    }

    function isOperator() public view returns (bool) {
        return _msgSender() == _operator;
    }

    function transferOperator(address newOperator_) public onlyOwner {
        _transferOperator(newOperator_);
    }

    function _transferOperator(address newOperator_) internal {
        require(newOperator_ != address(0), "operator: zero address given for new operator");
        emit OperatorTransferred(address(0), newOperator_);
        _operator = newOperator_;
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

pragma solidity 0.8.13;

library Babylonian {
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
        // else z = 0
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

interface IOracle {
    function update() external;

    function consult(address _token, uint256 _amountIn) external view returns (uint144 amountOut);

    function twap(address _token, uint256 _amountIn) external view returns (uint144 _amountOut);

    function sync() external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IEVICToken is IERC20 {
    function grantRebaseExclusion(address account) external;
    function revokeRebaseExclusion(address account) external;
    function getExcluded() external view returns (address[] memory);
    function rebase(uint256 epoch, uint256 supplyDelta, bool negative) external returns (uint256);
    function rebaseSupply() external view returns (uint256);
    function isDaoFund(address _address) external view returns (bool);
    function getDaoFund() external view returns (address);
    function getPolWallet() external view returns (address);
    function mint(address recipient, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

interface IBoardroom {
    function balanceOf(address _member) external view returns (uint256);

    function earned(address _member) external view returns (uint256);

    function canWithdraw(address _member) external view returns (bool);

    function canClaimReward(address _member) external view returns (bool);

    function epoch() external view returns (uint256);

    function nextEpochPoint() external view returns (uint256);

    function getMainTokenPrice() external view returns (uint256);

    function setOperator(address _operator) external;

    function setLockUp(uint256 _withdrawLockupEpochs, uint256 _rewardLockupEpochs) external;

    function stake(uint256 _amount) external;

    function withdraw(uint256 _amount) external;

    function exit() external;

    function claimReward() external;

    function allocateSeigniorage(uint256 _amount) external;
    
    function totalSupply() external view returns (uint256);

    function governanceRecoverUnsupported(
        address _token,
        uint256 _amount,
        address _to
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

interface IBasisAsset {
    function mint(address recipient, uint256 amount) external returns (bool);

    function burn(uint256 amount) external;

    function burnFrom(address from, uint256 amount) external;

    function isOperator() external returns (bool);

    function operator() external view returns (address);

    function transferOperator(address newOperator_) external;
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