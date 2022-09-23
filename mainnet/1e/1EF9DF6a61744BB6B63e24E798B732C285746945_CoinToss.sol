// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./interfaces/IRandomizer.sol";


contract CoinToss is Ownable, ReentrancyGuard, Pausable {
  using SafeERC20 for IERC20;

  struct Game {
    bool start;
    bool hamster;
    uint256 probability;
    uint256 randomRound;
    uint256 amount;
    uint256 rewards;
  }

  mapping(address => Game) public game;
  uint256 public minAmount;
  uint256 public maxAmount;
  uint256 public accumulatedGamesCount;
  uint256 public accumulatedGamesTokenAmount;
  uint256 public multiplyer;
  uint256 public probability;
  uint256 public fee;
  uint256 public rewards;
  address public operator;
  uint256 public taxBp = 500;
  IERC20 public token;
  IRandomizer public randomizer;

  modifier onlyOperator() {
    require(msg.sender == operator, "invalid operator");
    _;
  }

  event Bought(
    address indexed account,
    bool hamster,
    uint256 probability,
    uint256 randomRound,
    uint256 amount,
    uint256 rewards
  );
  event Withdrawn(
    address indexed account,
    bool hamster,
    uint256 probability,
    uint256 randomRound,
    uint256 amount,
    uint256 withdrawnRewards,
    uint256 autobuyRewards
  );
  event MinAmountUpdated(uint256 minAmount);
  event MaxAmountUpdated(uint256 maxAmount);
  event MultiplyerUpdated(uint256 multiplyer);
  event ProbabilityUpdated(uint256 probability);
  event TokenUpdated(address token);
  event RandomizerUpdated(address randomizer);
  event RewardsIncreased(address caller, uint256 amount);
  event RewardsDecreased(address caller, uint256 amount);

  function isRandomReady(address account) external view returns (bool) {
    Game storage game_ = game[account];
    return randomizer.isRandomReady(game_.randomRound);
  }

  function isWinner(address account) public view returns (bool) {
    Game storage game_ = game[account];
    if (!game_.start) return false;
    return isWinnerByRandomRound(account, game_.randomRound, game_.probability);
  }

  function isWinnerByRandomRound(
    address account,
    uint256 randomRound,
    uint256 probability_
  ) public view returns (bool) {
    require(randomizer.isRandomReady(randomRound), "random not ready");
    uint256 random = uint256(keccak256(
      abi.encodePacked(
        randomizer.random(randomRound),
        account
      )
    )) % 100;
    return random < probability_;
  }

  constructor(
    uint256 _minAmount,
    uint256 _maxAmount,
    uint256 _multiplyer,
    uint256 _probability,
    address _token,
    address _randomizer,
    address _operator
  ) Ownable() Pausable() {
    configure(_minAmount, _maxAmount, _multiplyer, _probability, _token, _randomizer);
    operator = _operator;
  }

  function configure(
    uint256 _minAmount,
    uint256 _maxAmount,
    uint256 _multiplyer,
    uint256 _probability,
    address _token,
    address _randomizer
  ) public onlyOwner {
    _updateMaxAmount(_maxAmount);
    _updateMinAmount(_minAmount);
    _updateMultiplyer(_multiplyer);
    _updateProbability(_probability);
    _updateToken(_token);
    _updateRandomizer(_randomizer);
  }

  function setOperator(address _operator) external onlyOperator {
    operator = _operator;
  }

  function setTaxBp(uint256 _taxBp) external onlyOperator {
    require(_taxBp >= 0 && _taxBp <= 2000, "invalid range");
    taxBp = _taxBp;
  }

  function buy(uint256 amount, bool hamster) external whenNotPaused returns (bool) {
    address caller = msg.sender;
    require(!isWinner(caller), "need withdraw");
    token.safeTransferFrom(caller, address(this), amount);
    Game storage game_ = game[caller];
    _resolveGame(game_);
    return _buy(game_, caller, amount, hamster);
  }

  function withdraw(bool autobuy, uint256 amount, bool hamster) external nonReentrant returns (bool) {
    address caller = msg.sender;
    require(isWinner(caller), "you not winner");
    Game storage game_ = game[caller];
    require(game_.rewards >= amount, "amount gt rewards");
    uint256 rewardsToWithdraw = autobuy ? game_.rewards - amount : game_.rewards;
    if (rewardsToWithdraw > 0) token.safeTransfer(caller, rewardsToWithdraw);
    emit Withdrawn(
      caller,
      game_.hamster,
      game_.probability,
      game_.randomRound,
      game_.amount,
      rewardsToWithdraw,
      amount
    );
    if (autobuy) {
      require(!paused(), "autobuy not avaible when paused");
      return _buy(game_, caller, amount, hamster);
    } else {
      delete game[caller];
      return true;
    }
  }

  function resolveGame(address account) public onlyOwner returns (bool result) {
    require(!isWinner(account), "need withdraw");
    result = _resolveGame(game[account]);
    delete game[account];
  }

  function togglePause() external onlyOwner {
    if (paused()) _unpause();
    else _pause();  
  }

  function increaseRewards(uint256 amount) external returns (bool) {
    address caller = msg.sender;
    require(amount > 0, "amount is zero");
    rewards += amount;
    token.safeTransferFrom(caller, address(this), amount);
    emit RewardsIncreased(caller, amount);
    return true;
  }

  function decreaseRewards(uint256 amount) external onlyOwner returns (bool) {
    address caller = msg.sender;
    require(amount <= rewards, "rewards overflow");
    rewards -= amount;
    token.safeTransfer(caller, amount);
    emit RewardsDecreased(caller, amount);
    return true;
  }

  function withdrawFee(uint256 amount) external onlyOperator returns (bool) {
    require(amount <= fee, "fee overflow");
    fee -= amount;
    uint256 feeForOperator = amount * taxBp / 10000;
    uint256 feeForOwner = amount - feeForOperator;
    token.safeTransfer(operator, feeForOperator);
    token.safeTransfer(owner(), feeForOwner);
    return true;
  }

  function withdrawFee(uint256 amount, address to) external onlyOwner returns (bool) {
    require(to != address(0), "to is zero address");
    require(amount <= fee, "fee overflow");
    fee -= amount;
    uint256 feeForOperator = amount * taxBp / 10000;
    uint256 feeForOwner = amount - feeForOperator;
    token.safeTransfer(operator, feeForOperator);
    token.safeTransfer(to, feeForOwner);
    return true;
  }

  function withdrawTokens(address _erc20Address, uint256 amount) external onlyOwner returns (bool) {
    IERC20(_erc20Address).safeTransfer(owner(), amount);
    return true;
  }

  function _buy(Game storage game_, address caller, uint256 amount, bool hamster) private returns (bool) {
    uint256 rewards_ = amount * multiplyer / 100;
    require(amount >= minAmount && amount <= maxAmount, "invalid amount");
    require(rewards_ <= rewards, "not enough rewards for game");
    if (!randomizer.nextRoundRequired()) randomizer.requireNextRound();
    game_.hamster = hamster;
    game_.start = true;
    game_.probability = probability;
    game_.randomRound = randomizer.nextRound(); 
    game_.amount = amount;
    game_.rewards = rewards_;
    accumulatedGamesCount += 1;
    accumulatedGamesTokenAmount += amount;
    fee += amount;
    rewards -= rewards_;
    emit Bought(caller, hamster, probability, game_.randomRound, amount, rewards_);
    return true;
  }

  function _resolveGame(Game storage game_) private returns (bool) {
    if (game_.start && game_.rewards > 0) rewards += game_.rewards;
    return true;
  }

  function _updateMinAmount(uint256 _minAmount) private {
    require(_minAmount > 0 && _minAmount < maxAmount, "invalid minAmount");
    if (_minAmount != minAmount) {
      minAmount = _minAmount;
      emit MinAmountUpdated(_minAmount);
    }
  }

  function _updateMaxAmount(uint256 _maxAmount) private {
    require(_maxAmount > 0 && _maxAmount > minAmount, "invalid maxAmount");
    if (_maxAmount != maxAmount) {
      maxAmount = _maxAmount;
      emit MaxAmountUpdated(_maxAmount);
    }
  }

  function _updateMultiplyer(uint256 _multiplyer) private {
    require(_multiplyer > 0, "multiplyer is zero");
    if (_multiplyer != multiplyer) {
      multiplyer = _multiplyer;
      emit MultiplyerUpdated(_multiplyer);
    }
  }

  function _updateProbability(uint256 _probability) private {
    require(_probability >= 0 && _probability <= 100, "probability not in range");
    if (_probability != probability) {
      probability = _probability;
      emit ProbabilityUpdated(_probability);
    }
  }

  function _updateToken(address _token) private {
    require(_token != address(0), "token is zero address");
    if (_token != address(token)) {
      token = IERC20(_token);
      emit TokenUpdated(_token);
    }
  }

  function _updateRandomizer(address _randomizer) private {
    require(_randomizer != address(0), "randomizer is zero address");
    if (_randomizer != address(randomizer)) {
      randomizer = IRandomizer(_randomizer);
      emit RandomizerUpdated(_randomizer);
    }
  }
}

// SPDX-License-Identifier: MIT

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

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
     * by making the `nonReentrant` function external, and make it call a
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
pragma solidity ^0.8.11;


interface IRandomizer {
  enum Status {
    NOT_ACTIVE,
    ACTIVE,
    FINISHED,
    RELEASED
  }

  struct Round {
    uint256 startAt;
    uint256 endsAt;
    bytes32 hashSeed;
    string seed;
    uint256 blockNumber;
    bytes32 blockHash;
    uint256 random;
    Status status;
  }

  function canFinishRound() external view returns (bool);
  function currentRound() external view returns (uint256);
  function delay() external view returns (uint256);
  function nextRound() external view returns (uint256);
  function nextRoundRequired() external view returns (bool);
  function roundMinDuration() external view returns (uint256);
  function canFinishRound(uint256 roundNumber_) external view returns (bool);
  function isRandomReady(uint256 roundNumber_) external view returns (bool);
  function random(uint256 roundNumber_) external view returns (uint256);
  function round(uint256 roundNumber_) external view returns (Round memory);

  function requireNextRound() external returns (bool);

  event BlockHashSaved(uint256 round_, bytes32 blockHash_, address indexed caller);
  event DelayUpdated(uint256 delay_);
  event RandomReleased(
    uint256 round_,
    uint256 random_,
    address indexed caller
  );
  event RoundMinDurationUpdated(uint256 roundMinDuration_);
  event RoundFinished(uint256 round_, string seed_, address indexed caller);
  event RoundRequired(uint256 round_);
  event RoundRestarted(uint256 indexed round_, bytes32 hashSeed_, uint256 blockNumber_, address indexed caller);
  event RoundStarted(uint256 round_, bytes32 hashSeed_, uint256 blockNumber_, address indexed caller);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
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

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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
        return _verifyCallResult(success, returndata, errorMessage);
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
        return _verifyCallResult(success, returndata, errorMessage);
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
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
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