// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interface/AggregatorInterface.sol";
import "./struct/Round.sol";

/**
 * @title AvalanchePredictionV2
 */
contract AvalanchePredictionV2 is Ownable, Pausable, ReentrancyGuard {
  using SafeERC20 for IERC20;

  AggregatorV3Interface public oracle;

  bool public genesisLockOnce = false;
  bool public genesisStartOnce = false;

  address public adminAddress; // address of the admin
  address public operatorAddress; // address of the operator

  uint256 public bufferSeconds; // number of seconds for valid execution of a prediction round
  uint256 public intervalSeconds; // interval in seconds between two prediction rounds

  uint256 public minBetAmount; // minimum betting amount (denominated in wei)
  uint256 public treasuryFee; // treasury rate (e.g. 200 = 2%, 150 = 1.50%)
  uint256 public treasuryAmount; // treasury amount that was not claimed

  uint256 public currentEpoch; // current epoch for prediction round

  uint256 public oracleLatestRoundId; // converted from uint80 (Chainlink)
  uint256 public oracleUpdateAllowance; // seconds

  uint256 public constant MAX_TREASURY_FEE = 1000; // 10%

  mapping(uint256 => mapping(address => BetInfo)) public ledger;
  mapping(uint256 => Round) public rounds;
  mapping(address => uint256[]) public userRounds;

  enum Position {
    Bull,
    Bear
  }

  struct BetInfo {
    Position position;
    uint256 amount;
    bool claimed; // default false
  }

  event BetBear(address indexed sender, uint256 indexed epoch, uint256 amount);
  event BetBull(address indexed sender, uint256 indexed epoch, uint256 amount);
  event Claim(address indexed sender, uint256 indexed epoch, uint256 amount);
  event EndRound(uint256 indexed epoch, uint256 indexed roundId, int256 price);
  event LockRound(uint256 indexed epoch, uint256 indexed roundId, int256 price);

  event NewAdminAddress(address admin);
  event NewBufferAndIntervalSeconds(
    uint256 bufferSeconds,
    uint256 intervalSeconds
  );
  event NewMinBetAmount(uint256 indexed epoch, uint256 minBetAmount);
  event NewTreasuryFee(uint256 indexed epoch, uint256 treasuryFee);
  event NewOperatorAddress(address operator);
  event NewOracle(address oracle);
  event NewOracleUpdateAllowance(uint256 oracleUpdateAllowance);

  event Pause(uint256 indexed epoch);
  event RewardsCalculated(
    uint256 indexed epoch,
    uint256 rewardBaseCalAmount,
    uint256 rewardAmount,
    uint256 treasuryAmount
  );

  event StartRound(uint256 indexed epoch);
  event TokenRecovery(address indexed token, uint256 amount);
  event TreasuryClaim(uint256 amount);
  event Unpause(uint256 indexed epoch);

  modifier onlyAdmin() {
    require(msg.sender == adminAddress, "Not admin");
    _;
  }

  modifier onlyAdminOrOperator() {
    require(
      msg.sender == adminAddress || msg.sender == operatorAddress,
      "Not operator/admin"
    );
    _;
  }

  modifier onlyOperator() {
    require(msg.sender == operatorAddress, "Not operator");
    _;
  }

  modifier notContract() {
    require(!_isContract(msg.sender), "Contract not allowed");
    require(msg.sender == tx.origin, "Proxy contract not allowed");
    _;
  }

  /**
   * @notice Constructor
   * @param _oracleAddress: oracle address
   * @param _adminAddress: admin address
   * @param _operatorAddress: operator address
   * @param _intervalSeconds: number of time within an interval
   * @param _bufferSeconds: buffer of time for resolution of price
   * @param _minBetAmount: minimum bet amounts (in wei)
   * @param _oracleUpdateAllowance: oracle update allowance
   * @param _treasuryFee: treasury fee (1000 = 10%)
   */
  constructor(
    address _oracleAddress,
    address _adminAddress,
    address _operatorAddress,
    uint256 _intervalSeconds,
    uint256 _bufferSeconds,
    uint256 _minBetAmount,
    uint256 _oracleUpdateAllowance,
    uint256 _treasuryFee
  ) {
    require(_treasuryFee <= MAX_TREASURY_FEE, "Treasury fee too high");

    oracle = AggregatorV3Interface(_oracleAddress);
    adminAddress = _adminAddress;
    operatorAddress = _operatorAddress;
    intervalSeconds = _intervalSeconds;
    bufferSeconds = _bufferSeconds;
    minBetAmount = _minBetAmount;
    oracleUpdateAllowance = _oracleUpdateAllowance;
    treasuryFee = _treasuryFee;
  }

  /**
   * @notice Bet bear position
   * @param epoch: epoch
   */
  function betBear(uint256 epoch)
    external
    payable
    whenNotPaused
    nonReentrant
    notContract
  {
    require(epoch == currentEpoch, "Bet is too early/late");
    require(_bettable(epoch), "Round not bettable");
    require(msg.value >= minBetAmount, "Bet must be greater than minBet");
    require(
      ledger[epoch][msg.sender].amount == 0,
      "Can only bet once per round"
    );

    // Update round data
    uint256 amount = msg.value;
    Round storage round = rounds[epoch];
    round.totalAmount = round.totalAmount + amount;
    round.bearAmount = round.bearAmount + amount;

    // Update user data
    BetInfo storage betInfo = ledger[epoch][msg.sender];
    betInfo.position = Position.Bear;
    betInfo.amount = amount;
    userRounds[msg.sender].push(epoch);

    emit BetBear(msg.sender, epoch, amount);
  }

  /**
   * @notice Bet bull position
   * @param epoch: epoch
   */
  function betBull(uint256 epoch)
    external
    payable
    whenNotPaused
    nonReentrant
    notContract
  {
    require(epoch == currentEpoch, "Bet is too early/late");
    require(_bettable(epoch), "Round not bettable");
    require(msg.value >= minBetAmount, "Bet must be greater than minBet");
    require(
      ledger[epoch][msg.sender].amount == 0,
      "Can only bet once per round"
    );

    // Update round data
    uint256 amount = msg.value;
    Round storage round = rounds[epoch];
    round.totalAmount = round.totalAmount + amount;
    round.bullAmount = round.bullAmount + amount;

    // Update user data
    BetInfo storage betInfo = ledger[epoch][msg.sender];
    betInfo.position = Position.Bull;
    betInfo.amount = amount;
    userRounds[msg.sender].push(epoch);

    emit BetBull(msg.sender, epoch, amount);
  }

  /**
   * @notice Claim reward for an array of epochs
   * @param epochs: array of epochs
   */
  function claim(uint256[] calldata epochs) external nonReentrant notContract {
    uint256 reward; // Initializes reward

    for (uint256 i = 0; i < epochs.length; i++) {
      reward += _claimEpoch(epochs[i]);
    }

    if (reward > 0) {
      _safeTransferBNB(address(msg.sender), reward);
    }
  }

  function _claimEpoch(uint256 epoch) internal returns (uint256 addReward) {
    require(rounds[epoch].startTimestamp != 0, "Round has not started");
    require(
      block.timestamp > rounds[epoch].closeTimestamp,
      "Round has not ended"
    );

    uint256 addedReward = 0;

    // Round valid, claim rewards
    if (rounds[epoch].oracle.oracleCalled) {
      require(claimable(epoch, msg.sender), "Not eligible for claim");
      Round memory round = rounds[epoch];
      addedReward =
        (ledger[epoch][msg.sender].amount * round.rewardAmount) /
        round.rewardBaseCalAmount;
    }
    // Round invalid, refund bet amount
    else {
      require(refundable(epoch, msg.sender), "Not eligible for refund");
      addedReward = ledger[epoch][msg.sender].amount;
    }

    ledger[epoch][msg.sender].claimed = true;

    emit Claim(msg.sender, epoch, addedReward);
    return addedReward;
  }

  /**
   * @notice Start the next round n, lock price for round n-1, end round n-2
   * @dev Callable by operator
   */
  function executeRound() external whenNotPaused onlyOperator {
    require(
      genesisStartOnce && genesisLockOnce,
      "Can run after Start and Lock"
    );

    (uint80 currentRoundId, int256 currentPrice) = _getPriceFromOracle();

    oracleLatestRoundId = uint256(currentRoundId);

    // CurrentEpoch refers to previous round (n-1)
    _safeLockRound(currentEpoch, currentRoundId, currentPrice);
    _safeEndRound(currentEpoch - 1, currentRoundId, currentPrice);
    _calculateRewards(currentEpoch - 1);

    // Increment currentEpoch to current round (n)
    currentEpoch = currentEpoch + 1;
    _safeStartRound(currentEpoch);
  }

  /**
   * @notice Lock genesis round
   * @dev Callable by operator
   */
  function genesisLockRound() external whenNotPaused onlyOperator {
    require(genesisStartOnce, "Can run after Start Round");
    require(!genesisLockOnce, "Can run Lock Round once");

    (uint80 currentRoundId, int256 currentPrice) = _getPriceFromOracle();

    oracleLatestRoundId = uint256(currentRoundId);

    _safeLockRound(currentEpoch, currentRoundId, currentPrice);

    currentEpoch = currentEpoch + 1;
    _startRound(currentEpoch);
    genesisLockOnce = true;
  }

  /**
   * @notice Start genesis round
   * @dev Callable by admin or operator
   */
  function genesisStartRound() external whenNotPaused onlyOperator {
    require(!genesisStartOnce, "Can only run Start Round once");

    currentEpoch = currentEpoch + 1;
    _startRound(currentEpoch);
    genesisStartOnce = true;
  }

  /**
   * @notice Claim some rewards in treasury
   * @dev Callable by owner
   */
  function claim(uint256 amount) external nonReentrant onlyOwner {
    require(amount < treasuryAmount, "TreasuryAmount is not enough");
    treasuryAmount = treasuryAmount - amount;
    _safeTransferBNB(adminAddress, amount);

    emit TreasuryClaim(amount);
  }

  /**
   * @notice called by the admin to pause, triggers stopped state
   * @dev Callable by admin or operator
   */
  function pause() external whenNotPaused onlyAdminOrOperator {
    _pause();

    emit Pause(currentEpoch);
  }

  /**
   * @notice Claim all rewards in treasury
   * @dev Callable by admin
   */
  function claimTreasury() external nonReentrant onlyAdmin {
    uint256 currentTreasuryAmount = treasuryAmount;
    treasuryAmount = 0;
    _safeTransferBNB(adminAddress, currentTreasuryAmount);

    emit TreasuryClaim(currentTreasuryAmount);
  }

  /**
   * @notice called by the admin to unpause, returns to normal state
   * Reset genesis state. Once paused, the rounds would need to be kickstarted by genesis
   */
  function unpause() external whenPaused onlyAdmin {
    genesisStartOnce = false;
    genesisLockOnce = false;
    _unpause();

    emit Unpause(currentEpoch);
  }

  /**
   * @notice Set buffer and interval (in seconds)
   * @dev Callable by admin
   */
  function setBufferAndIntervalSeconds(
    uint256 _bufferSeconds,
    uint256 _intervalSeconds
  ) external whenPaused onlyAdmin {
    require(
      _bufferSeconds < _intervalSeconds,
      "bufferSec must be inferior to interval"
    );
    bufferSeconds = _bufferSeconds;
    intervalSeconds = _intervalSeconds;

    emit NewBufferAndIntervalSeconds(_bufferSeconds, _intervalSeconds);
  }

  /**
   * @notice Set minBetAmount
   * @dev Callable by admin
   */
  function setMinBetAmount(uint256 _minBetAmount)
    external
    whenPaused
    onlyAdmin
  {
    require(_minBetAmount != 0, "Must be superior to 0");
    minBetAmount = _minBetAmount;

    emit NewMinBetAmount(currentEpoch, minBetAmount);
  }

  /**
   * @notice Set operator address
   * @dev Callable by admin
   */
  function setOperator(address _operatorAddress) external onlyAdmin {
    require(_operatorAddress != address(0), "Cannot be zero address");
    operatorAddress = _operatorAddress;

    emit NewOperatorAddress(_operatorAddress);
  }

  /**
   * @notice Set Oracle address
   * @dev Callable by admin
   */
  function setOracle(address _oracle) external whenPaused onlyAdmin {
    require(_oracle != address(0), "Cannot be zero address");
    oracleLatestRoundId = 0;
    oracle = AggregatorV3Interface(_oracle);

    // Dummy check to make sure the interface implements this function properly
    oracle.latestRoundData();

    emit NewOracle(_oracle);
  }

  /**
   * @notice Set oracle update allowance
   * @dev Callable by admin
   */
  function setOracleUpdateAllowance(uint256 _oracleUpdateAllowance)
    external
    whenPaused
    onlyAdmin
  {
    oracleUpdateAllowance = _oracleUpdateAllowance;

    emit NewOracleUpdateAllowance(_oracleUpdateAllowance);
  }

  /**
   * @notice Set treasury fee
   * @dev Callable by admin
   */
  function setTreasuryFee(uint256 _treasuryFee) external whenPaused onlyAdmin {
    require(_treasuryFee <= MAX_TREASURY_FEE, "Treasury fee too high");
    treasuryFee = _treasuryFee;

    emit NewTreasuryFee(currentEpoch, treasuryFee);
  }

  /**
   * @notice It allows the owner to recover tokens sent to the contract by mistake
   * @param _token: token address
   * @param _amount: token amount
   * @dev Callable by owner
   */
  function recoverToken(address _token, uint256 _amount) external onlyOwner {
    IERC20(_token).safeTransfer(address(msg.sender), _amount);

    emit TokenRecovery(_token, _amount);
  }

  /**
   * @notice Set admin address
   * @dev Callable by owner
   */
  function setAdmin(address _adminAddress) external onlyOwner {
    require(_adminAddress != address(0), "Cannot be zero address");
    adminAddress = _adminAddress;

    emit NewAdminAddress(_adminAddress);
  }

  /**
   * @notice Returns round epochs and bet information for a user that has participated
   * @param user: user address
   * @param cursor: cursor
   * @param size: size
   */
  function getUserRounds(
    address user,
    uint256 cursor,
    uint256 size
  )
    external
    view
    returns (
      uint256[] memory,
      BetInfo[] memory,
      uint256
    )
  {
    uint256 length = size;

    if (length > userRounds[user].length - cursor) {
      length = userRounds[user].length - cursor;
    }

    uint256[] memory values = new uint256[](length);
    BetInfo[] memory betInfo = new BetInfo[](length);

    for (uint256 i = 0; i < length; i++) {
      values[i] = userRounds[user][cursor + i];
      betInfo[i] = ledger[values[i]][user];
    }

    return (values, betInfo, cursor + length);
  }

  /**
   * @notice Returns round epochs length
   * @param user: user address
   */
  function getUserRoundsLength(address user) external view returns (uint256) {
    return userRounds[user].length;
  }

  /**
   * @notice Get the claimable stats of specific epoch and user account
   * @param epoch: epoch
   * @param user: user address
   */
  function claimable(uint256 epoch, address user) public view returns (bool) {
    BetInfo memory betInfo = ledger[epoch][user];
    Round memory round = rounds[epoch];
    if (round.lockPrice == round.closePrice) {
      return false;
    }
    return
      round.oracle.oracleCalled &&
      betInfo.amount != 0 &&
      !betInfo.claimed &&
      ((round.closePrice > round.lockPrice &&
        betInfo.position == Position.Bull) ||
        (round.closePrice < round.lockPrice &&
          betInfo.position == Position.Bear));
  }

  /**
   * @notice Get the refundable stats of specific epoch and user account
   * @param epoch: epoch
   * @param user: user address
   */
  function refundable(uint256 epoch, address user) public view returns (bool) {
    BetInfo memory betInfo = ledger[epoch][user];
    Round memory round = rounds[epoch];
    return
      !round.oracle.oracleCalled &&
      !betInfo.claimed &&
      block.timestamp > round.closeTimestamp + bufferSeconds &&
      betInfo.amount != 0;
  }

  /**
   * @notice Get latest oracle price and id
   */
  function getOraclelastRound() public view returns (int256) {
    (, int256 currentPrice) = _getPriceFromOracle();
    return currentPrice;
  }

  /**
   * @notice Calculate rewards for round
   * @param epoch: epoch
   */
  function _calculateRewards(uint256 epoch) internal {
    require(
      rounds[epoch].rewardBaseCalAmount == 0 && rounds[epoch].rewardAmount == 0,
      "Rewards calculated"
    );

    Round storage round = rounds[epoch];
    uint256 rewardBaseCalAmount;
    uint256 treasuryAmt;
    uint256 rewardAmount;

    // Bull wins
    if (round.closePrice > round.lockPrice) {
      rewardBaseCalAmount = round.bullAmount;
      treasuryAmt = (round.totalAmount * treasuryFee) / 10000;
      rewardAmount = round.totalAmount - treasuryAmt;
    }
    // Bear wins
    else if (round.closePrice < round.lockPrice) {
      rewardBaseCalAmount = round.bearAmount;
      treasuryAmt = (round.totalAmount * treasuryFee) / 10000;
      rewardAmount = round.totalAmount - treasuryAmt;
    }
    // House wins
    else {
      rewardBaseCalAmount = 0;
      rewardAmount = 0;
      treasuryAmt = round.totalAmount;
    }
    round.rewardBaseCalAmount = rewardBaseCalAmount;
    round.rewardAmount = rewardAmount;

    // Add to treasury
    treasuryAmount += treasuryAmt;

    emit RewardsCalculated(
      epoch,
      rewardBaseCalAmount,
      rewardAmount,
      treasuryAmt
    );
  }

  /**
   * @notice End round
   * @param epoch: epoch
   * @param roundId: roundId
   * @param price: price of the round
   */
  function _safeEndRound(
    uint256 epoch,
    uint256 roundId,
    int256 price
  ) internal {
    require(
      rounds[epoch].lockTimestamp != 0,
      "Can only end round after round has locked"
    );
    require(
      block.timestamp >= rounds[epoch].closeTimestamp,
      "Can only end round after closeTimestamp"
    );
    require(
      block.timestamp <= rounds[epoch].closeTimestamp + bufferSeconds,
      "Can only end round within bufferSeconds"
    );
    Round storage round = rounds[epoch];
    round.closePrice = price;
    round.oracle.closeOracleId = roundId;
    round.oracle.oracleCalled = true;

    emit EndRound(epoch, roundId, round.closePrice);
  }

  /**
   * @notice Lock round
   * @param epoch: epoch
   * @param roundId: roundId
   * @param price: price of the round
   */
  function _safeLockRound(
    uint256 epoch,
    uint256 roundId,
    int256 price
  ) internal {
    require(
      rounds[epoch].startTimestamp != 0,
      "Can only lock round after round has started"
    );
    require(
      block.timestamp >= rounds[epoch].lockTimestamp,
      "Can only lock round after lockTimestamp"
    );
    require(
      block.timestamp <= rounds[epoch].lockTimestamp + bufferSeconds,
      "Can only lock round within bufferSeconds"
    );
    Round storage round = rounds[epoch];
    round.closeTimestamp = block.timestamp + intervalSeconds;
    round.lockPrice = price;
    round.oracle.lockOracleId = roundId;

    emit LockRound(epoch, roundId, round.lockPrice);
  }

  /**
   * @notice Start round
   * Previous round n-2 must end
   * @param epoch: epoch
   */
  function _safeStartRound(uint256 epoch) internal {
    require(
      genesisStartOnce,
      "Can only run after genesisStartRound is triggered"
    );
    require(
      rounds[epoch - 2].closeTimestamp != 0,
      "Can only start round after round n-2 has ended"
    );
    require(
      block.timestamp >= rounds[epoch - 2].closeTimestamp,
      "Can only start new round after round n-2 closeTimestamp"
    );
    _startRound(epoch);
  }

  /**
   * @notice Transfer BNB in a safe way
   * @param to: address to transfer BNB to
   * @param value: BNB amount to transfer (in wei)
   */
  function _safeTransferBNB(address to, uint256 value) internal {
    (bool success, ) = to.call{ value: value }("");
    require(success, "TransferHelper: BNB_TRANSFER_FAILED");
  }

  /**
   * @notice Start round
   * Previous round n-2 must end
   * @param epoch: epoch
   */
  function _startRound(uint256 epoch) internal {
    Round storage round = rounds[epoch];
    round.startTimestamp = block.timestamp;
    round.lockTimestamp = block.timestamp + intervalSeconds;
    round.closeTimestamp = block.timestamp + (2 * intervalSeconds);
    round.epoch = epoch;
    round.totalAmount = 0;

    emit StartRound(epoch);
  }

  /**
   * @notice Determine if a round is valid for receiving bets
   * Round must have started and locked
   * Current timestamp must be within startTimestamp and closeTimestamp
   */
  function _bettable(uint256 epoch) internal view returns (bool) {
    return
      rounds[epoch].startTimestamp != 0 &&
      rounds[epoch].lockTimestamp != 0 &&
      block.timestamp > rounds[epoch].startTimestamp &&
      block.timestamp < rounds[epoch].lockTimestamp;
  }

  /**
   * @notice Get latest recorded price from oracle
   * If it falls below allowed buffer or has not updated, it would be invalid.
   */
  function _getPriceFromOracle() internal view returns (uint80, int256) {
    uint256 leastAllowedTimestamp = block.timestamp + oracleUpdateAllowance;
    (uint80 roundId, int256 price, , uint256 timestamp, ) = oracle
      .latestRoundData();
    require(
      timestamp <= leastAllowedTimestamp,
      "Oracle update exceeded max timestamp allowance"
    );
    require(
      uint256(roundId) > oracleLatestRoundId,
      "Oracle update roundId must be larger than oracleLatestRoundId"
    );
    return (roundId, price);
  }

  /**
   * @notice Returns true if `account` is a contract.
   * @param account: account address
   */
  function _isContract(address account) internal view returns (bool) {
    uint256 size;
    assembly {
      size := extcodesize(account)
    }
    return size > 0;
  }
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface AggregatorInterface {
  function latestAnswer() external view returns (int256);

  function latestTimestamp() external view returns (uint256);

  function latestRound() external view returns (uint256);

  function getAnswer(uint256 roundId) external view returns (int256);

  function getTimestamp(uint256 roundId) external view returns (uint256);

  event AnswerUpdated(
    int256 indexed current,
    uint256 indexed roundId,
    uint256 updatedAt
  );
  event NewRound(
    uint256 indexed roundId,
    address indexed startedBy,
    uint256 startedAt
  );
}

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

interface AggregatorV2V3Interface is
  AggregatorInterface,
  AggregatorV3Interface
{}

interface AccessControllerInterface {
  function hasAccess(address user, bytes calldata data)
    external
    view
    returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./Oracle.sol";

struct Round {
  uint256 epoch;
  uint256 startTimestamp;
  uint256 lockTimestamp;
  uint256 closeTimestamp;
  int256 lockPrice;
  int256 closePrice;
  uint256 totalAmount;
  uint256 bullAmount;
  uint256 bearAmount;
  uint256 rewardBaseCalAmount;
  uint256 rewardAmount;
  Oracle oracle;
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

pragma solidity ^0.8.4;

struct Oracle {
  bool oracleCalled;
  uint256 lockOracleId;
  uint256 closeOracleId;
}