// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./dependencies/openzeppelin/utils/math/Math.sol";
import "./dependencies/openzeppelin/security/ReentrancyGuard.sol";
import "./lib/WadRayMath.sol";
import "./access/Manageable.sol";
import "./storage/DepositTokenStorage.sol";

/**
 * @title Represents the users' deposits
 */
contract DepositToken is ReentrancyGuard, Manageable, DepositTokenStorageV1 {
    using SafeERC20 for IERC20;
    using WadRayMath for uint256;

    string public constant VERSION = "1.0.0";

    /// @notice Emitted when CR is updated
    event CollateralizationRatioUpdated(uint256 oldCollateralizationRatio, uint256 newCollateralizationRatio);

    /// @notice Emitted when minimum deposit time is updated
    event MinDepositTimeUpdated(uint256 oldMinDepositTime, uint256 newMinDepositTime);

    /// @notice Emitted when active flag is updated
    event DepositTokenActiveUpdated(bool oldActive, bool newActive);

    /// @notice Emitted when max total supply is updated
    event MaxTotalSupplyUpdated(uint256 oldMaxTotalSupplyInUsd, uint256 newMaxTotalSupplyInUsd);

    /// @notice Emitted when collateral is deposited
    event CollateralDeposited(address indexed from, address indexed account, uint256 amount, uint256 fee);

    /// @notice Emitted when collateral is withdrawn
    event CollateralWithdrawn(address indexed account, address indexed to, uint256 amount, uint256 fee);

    /**
     * @dev Throws if minimum deposit time haven't passed
     */
    modifier onlyIfMinDepositTimePassed(address _account) {
        require(block.timestamp >= lastDepositOf[_account] + minDepositTime, "min-deposit-time-have-not-passed");
        _;
    }

    /**
     * @notice Requires that amount is lower than the account's unlocked balance
     */
    modifier onlyIfNotLocked(address _account, uint256 _amount) {
        require(unlockedBalanceOf(_account) >= _amount, "not-enough-free-balance");
        _;
    }

    /**
     * @dev Throws if deposit token doesn't exist
     */
    modifier onlyIfDepositTokenExists() {
        require(controller.isDepositTokenExists(this), "collateral-inexistent");
        _;
    }

    /**
     * @notice Update reward contracts' states
     * @dev Should be called before balance changes (i.e. mint/burn)
     */
    modifier updateRewardsBeforeMintOrBurn(address _account) {
        IRewardsDistributor[] memory _rewardsDistributors = controller.getRewardsDistributors();
        uint256 _length = _rewardsDistributors.length;
        for (uint256 i; i < _length; i++) {
            _rewardsDistributors[i].updateBeforeMintOrBurn(this, _account);
        }
        _;
    }

    /**
     * @notice Update reward contracts' states
     * @dev Should be called before balance changes (i.e. transfer)
     */
    modifier updateRewardsBeforeTransfer(address _sender, address _recipient) {
        IRewardsDistributor[] memory _rewardsDistributors = controller.getRewardsDistributors();
        uint256 _length = _rewardsDistributors.length;
        for (uint256 i; i < _length; i++) {
            _rewardsDistributors[i].updateBeforeTransfer(this, _sender, _recipient);
        }
        _;
    }

    /**
     * @dev Throws if deposit token isn't enabled
     */
    modifier onlyIfDepositTokenIsActive() {
        require(isActive, "deposit-token-is-inactive");
        _;
    }

    function initialize(
        IERC20 _underlying,
        IController _controller,
        string calldata _symbol,
        uint8 _decimals,
        uint128 _collateralizationRatio,
        uint256 _maxTotalSupplyInUsd
    ) public initializer {
        require(address(_underlying) != address(0), "underlying-is-null");
        require(address(_controller) != address(0), "controller-address-is-zero");
        require(_collateralizationRatio <= 1e18, "collateralization-ratio-gt-100%");

        __Manageable_init();

        controller = _controller;
        name = "Tokenized deposit position";
        symbol = _symbol;
        underlying = _underlying;
        minDepositTime = 0;
        isActive = true;
        decimals = _decimals;
        collateralizationRatio = _collateralizationRatio;
        maxTotalSupplyInUsd = _maxTotalSupplyInUsd;
    }

    function approve(address spender, uint256 _amount) external override returns (bool) {
        _approve(_msgSender(), spender, _amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) external returns (bool) {
        _approve(_msgSender(), spender, allowance[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool) {
        uint256 currentAllowance = allowance[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "decreased-allowance-below-zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _transfer(
        address _sender,
        address _recipient,
        uint256 _amount
    ) private updateRewardsBeforeTransfer(_sender, _recipient) {
        require(_sender != address(0), "transfer-from-the-zero-address");
        require(_recipient != address(0), "transfer-to-the-zero-address");

        uint256 _senderBalance = balanceOf[_sender];
        require(_senderBalance >= _amount, "transfer-amount-exceeds-balance");
        unchecked {
            balanceOf[_sender] = _senderBalance - _amount;
        }
        balanceOf[_recipient] += _amount;

        emit Transfer(_sender, _recipient, _amount);

        unchecked {
            _addToDepositTokensOfRecipientIfNeeded(_recipient, balanceOf[_recipient] - _amount);
        }
        _removeFromDepositTokensOfSenderIfNeeded(_sender, balanceOf[_sender]);
    }

    function _mint(address _account, uint256 _amount)
        private
        onlyIfDepositTokenIsActive
        updateRewardsBeforeMintOrBurn(_account)
    {
        require(_account != address(0), "mint-to-the-zero-address");

        uint256 _newTotalSupplyInUsd = controller.masterOracle().quoteTokenToUsd(this, totalSupply + _amount);
        require(_newTotalSupplyInUsd <= maxTotalSupplyInUsd, "surpass-max-total-supply");
        lastDepositOf[_account] = block.timestamp;

        totalSupply += _amount;
        balanceOf[_account] += _amount;
        emit Transfer(address(0), _account, _amount);

        unchecked {
            _addToDepositTokensOfRecipientIfNeeded(_account, balanceOf[_account] - _amount);
        }
    }

    function _burn(address _account, uint256 _amount) private updateRewardsBeforeMintOrBurn(_account) {
        require(_account != address(0), "burn-from-the-zero-address");

        uint256 _accountBalance = balanceOf[_account];
        require(_accountBalance >= _amount, "burn-amount-exceeds-balance");
        unchecked {
            balanceOf[_account] = _accountBalance - _amount;
        }
        totalSupply -= _amount;

        emit Transfer(_account, address(0), _amount);

        _removeFromDepositTokensOfSenderIfNeeded(_account, balanceOf[_account]);
    }

    function _approve(
        address _owner,
        address _spender,
        uint256 _amount
    ) private {
        require(_owner != address(0), "approve-from-the-zero-address");
        require(_spender != address(0), "approve-to-the-zero-address");

        allowance[_owner][_spender] = _amount;
        emit Approval(_owner, _spender, _amount);
    }

    function _addToDepositTokensOfRecipientIfNeeded(address _recipient, uint256 _recipientBalanceBefore) private {
        if (_recipientBalanceBefore == 0) {
            controller.addToDepositTokensOfAccount(_recipient);
        }
    }

    function _removeFromDepositTokensOfSenderIfNeeded(address _sender, uint256 _senderBalanceAfter) private {
        if (_senderBalanceAfter == 0) {
            controller.removeFromDepositTokensOfAccount(_sender);
        }
    }

    /**
     * @notice Deposit collateral and mint vsdTOKEN (tokenized deposit position)
     * @param _amount The amount of collateral tokens to deposit
     * @param _onBehalfOf The account to deposit to
     */
    function deposit(uint256 _amount, address _onBehalfOf)
        external
        override
        whenNotPaused
        nonReentrant
        onlyIfDepositTokenIsActive
        onlyIfDepositTokenExists
    {
        require(_amount > 0, "amount-is-zero");

        address _sender = _msgSender();
        ITreasury _treasury = controller.treasury();

        uint256 _balanceBefore = underlying.balanceOf(address(_treasury));

        underlying.safeTransferFrom(_sender, address(_treasury), _amount);

        _amount = underlying.balanceOf(address(_treasury)) - _balanceBefore;

        uint256 _depositFee = controller.depositFee();
        uint256 _amountToDeposit = _amount;
        uint256 _feeAmount;
        if (_depositFee > 0) {
            _feeAmount = _amount.wadMul(_depositFee);
            _mint(address(_treasury), _feeAmount);
            _amountToDeposit -= _feeAmount;
        }

        _mint(_onBehalfOf, _amountToDeposit);

        emit CollateralDeposited(_sender, _onBehalfOf, _amount, _feeAmount);
    }

    /**
     * @notice Burn vsdTOKEN and withdraw collateral
     * @param _amount The amount of collateral to withdraw
     * @param _to The account that will receive withdrawn collateral
     */
    function withdraw(uint256 _amount, address _to)
        external
        override
        whenNotShutdown
        nonReentrant
        onlyIfDepositTokenExists
    {
        require(_amount > 0, "amount-is-zero");

        address _account = _msgSender();

        require(_amount <= unlockedBalanceOf(_account), "amount-gt-unlocked");

        ITreasury _treasury = controller.treasury();

        uint256 _withdrawFee = controller.withdrawFee();
        uint256 _amountToWithdraw = _amount;
        uint256 _feeAmount;
        if (_withdrawFee > 0) {
            _feeAmount = _amount.wadMul(_withdrawFee);
            _transfer(_account, address(_treasury), _feeAmount);
            _amountToWithdraw -= _feeAmount;
        }

        _burnForWithdraw(_account, _amountToWithdraw);
        _treasury.pull(_to, _amountToWithdraw);

        emit CollateralWithdrawn(_account, _to, _amount, _feeAmount);
    }

    /**
     * @notice Mint deposit token when an account deposits collateral
     * @param _to The account to mint to
     * @param _amount The amount to mint
     */
    function mint(address _to, uint256 _amount) external override onlyController {
        _mint(_to, _amount);
    }

    /**
     * @notice Burn deposit token as part of withdraw process
     * @param _from The account to burn from
     * @param _amount The amount to burn
     */
    function _burnForWithdraw(address _from, uint256 _amount) private onlyIfMinDepositTimePassed(_from) {
        _burn(_from, _amount);
    }

    /**
     * @notice Burn deposit tokens
     * @param _from The account to burn from
     * @param _amount The amount to burn
     */
    function burn(address _from, uint256 _amount) external override onlyController {
        _burn(_from, _amount);
    }

    /**
     * @notice Transfer tokens if checks pass
     * @param _sender The account to transfer from
     * @param _recipient The account to transfer to
     * @param _amount The amount to transfer
     */
    function _transferWithChecks(
        address _sender,
        address _recipient,
        uint256 _amount
    ) private onlyIfNotLocked(_sender, _amount) onlyIfMinDepositTimePassed(_sender) {
        _transfer(_sender, _recipient, _amount);
    }

    function transfer(address _to, uint256 _amount) external override returns (bool) {
        _transferWithChecks(_msgSender(), _to, _amount);
        return true;
    }

    function transferFrom(
        address _sender,
        address _recipient,
        uint256 _amount
    ) external override nonReentrant returns (bool) {
        _transferWithChecks(_sender, _recipient, _amount);

        uint256 currentAllowance = allowance[_sender][_msgSender()];
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= _amount, "amount-exceeds-allowance");
            unchecked {
                _approve(_sender, _msgSender(), currentAllowance - _amount);
            }
        }

        return true;
    }

    /**
     * @notice Get the unlocked balance (i.e. transferable, withdrawable)
     * @param _account The account to check
     * @return _unlockedBalance The amount that user can transfer or withdraw
     */
    function unlockedBalanceOf(address _account) public view override returns (uint256 _unlockedBalance) {
        (, , , , uint256 _issuableInUsd) = controller.debtPositionOf(_account);

        if (_issuableInUsd > 0) {
            uint256 _unlockedInUsd = _issuableInUsd.wadDiv(collateralizationRatio);
            _unlockedBalance = Math.min(
                balanceOf[_account],
                controller.masterOracle().quoteUsdToToken(this, _unlockedInUsd)
            );
        }
    }

    /**
     * @notice Get the locked balance
     * @param _account The account to check
     * @return _lockedBalance The locked amount
     */
    function lockedBalanceOf(address _account) external view override returns (uint256 _lockedBalance) {
        unchecked {
            return balanceOf[_account] - unlockedBalanceOf(_account);
        }
    }

    /**
     * @notice Seize tokens
     * @dev Same as _transfer
     * @param _from The account to seize from
     * @param _to The beneficiary account
     * @param _amount The amount to seize
     */
    function seize(
        address _from,
        address _to,
        uint256 _amount
    ) external override onlyController {
        _transfer(_from, _to, _amount);
    }

    /**
     * @notice Update collateralization ratio
     * @param _newCollateralizationRatio The new CR value
     */
    function updateCollateralizationRatio(uint128 _newCollateralizationRatio) external override onlyGovernor {
        require(_newCollateralizationRatio <= 1e18, "collateralization-ratio-gt-100%");
        uint256 _currentCollateralizationRatio = collateralizationRatio;
        require(_newCollateralizationRatio != _currentCollateralizationRatio, "new-same-as-current");
        emit CollateralizationRatioUpdated(_currentCollateralizationRatio, _newCollateralizationRatio);
        collateralizationRatio = _newCollateralizationRatio;
    }

    /**
     * @notice Update minimum deposit time
     */
    function updateMinDepositTime(uint256 _newMinDepositTime) external onlyGovernor {
        uint256 _currentMinDepositTime = minDepositTime;
        require(_newMinDepositTime != _currentMinDepositTime, "new-same-as-current");
        emit MinDepositTimeUpdated(_currentMinDepositTime, _newMinDepositTime);
        minDepositTime = _newMinDepositTime;
    }

    /**
     * @notice Update max total supply
     * @param _newMaxTotalSupplyInUsd The new max total supply
     */
    function updateMaxTotalSupplyInUsd(uint256 _newMaxTotalSupplyInUsd) external override onlyGovernor {
        uint256 _currentMaxTotalSupplyInUsd = maxTotalSupplyInUsd;
        require(_newMaxTotalSupplyInUsd != _currentMaxTotalSupplyInUsd, "new-same-as-current");
        emit MaxTotalSupplyUpdated(_currentMaxTotalSupplyInUsd, _newMaxTotalSupplyInUsd);
        maxTotalSupplyInUsd = _newMaxTotalSupplyInUsd;
    }

    /**
     * @notice Enable/Disable the Deposit Token
     */
    function toggleIsActive() external override onlyGovernor {
        bool _isActive = isActive;
        emit DepositTokenActiveUpdated(_isActive, !_isActive);
        isActive = !_isActive;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "../dependencies/openzeppelin/utils/Context.sol";
import "../dependencies/openzeppelin/proxy/utils/Initializable.sol";
import "../utils/TokenHolder.sol";
import "../interface/IGovernable.sol";
import "../interface/IController.sol";

/**
 * @title Reusable contract that handles accesses
 */
abstract contract Manageable is Context, TokenHolder, Initializable {
    /**
     * @notice Controller contract
     */
    IController public controller;

    // solhint-disable-next-line func-name-mixedcase
    function __Manageable_init() internal initializer {}

    /**
     * @notice Requires that the caller is the Controller contract
     */
    modifier onlyController() {
        require(_msgSender() == address(controller), "not-controller");
        _;
    }

    /**
     * @notice Requires that the caller is the Controller contract
     */
    modifier onlyGovernor() {
        require(_msgSender() == governor(), "not-governor");
        _;
    }

    modifier whenNotPaused() {
        require(!controller.paused(), "paused");
        _;
    }

    modifier whenNotShutdown() {
        require(!controller.everythingStopped(), "not-shutdown");
        _;
    }

    function governor() public view returns (address _governor) {
        _governor = IGovernable(address(controller)).governor();
    }

    function _requireCanSweep() internal view override onlyGovernor {}

    /**
     * @notice Update Controller contract
     * @param _controller The new Controller contract
     */
    function setController(IController _controller) external onlyGovernor {
        require(address(_controller) != address(0), "new-controller-address-is-zero");
        controller = _controller;
    }

    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuard is Initializable {
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

    function __ReentrancyGuard_init() internal initializer {
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

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
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

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./oracle/IMasterOracle.sol";
import "./IPausable.sol";
import "./ISyntheticToken.sol";
import "./IDepositToken.sol";
import "./ITreasury.sol";
import "./IRewardsDistributor.sol";

/**
 * @notice Controller interface
 */
interface IController is IPausable {
    function debtFloorInUsd() external returns (uint256);

    function depositFee() external returns (uint256);

    function issueFee() external returns (uint256);

    function withdrawFee() external returns (uint256);

    function repayFee() external returns (uint256);

    function isSyntheticTokenExists(ISyntheticToken _syntheticToken) external view returns (bool);

    function isDepositTokenExists(IDepositToken _depositToken) external view returns (bool);

    function depositTokenOf(IERC20 _underlying) external view returns (IDepositToken);

    function getDepositTokens() external view returns (address[] memory);

    function getSyntheticTokens() external view returns (address[] memory);

    function getRewardsDistributors() external view returns (IRewardsDistributor[] memory);

    function debtOf(address _account) external view returns (uint256 _debtInUsd);

    function depositOf(address _account) external view returns (uint256 _depositInUsd, uint256 _issuableLimitInUsd);

    function debtPositionOf(address _account)
        external
        view
        returns (
            bool _isHealthy,
            uint256 _depositInUsd,
            uint256 _debtInUsd,
            uint256 _issuableLimitInUsd,
            uint256 _issuableInUsd
        );

    function addSyntheticToken(address _synthetic) external;

    function removeSyntheticToken(ISyntheticToken _synthetic) external;

    function addDepositToken(address _depositToken) external;

    function removeDepositToken(IDepositToken _depositToken) external;

    function liquidate(
        ISyntheticToken _syntheticToken,
        address _account,
        uint256 _amountToRepay,
        IDepositToken _depositToken
    ) external;

    function swap(
        ISyntheticToken _syntheticTokenIn,
        ISyntheticToken _syntheticTokenOut,
        uint256 _amountIn
    ) external returns (uint256 _amountOut);

    function updateMasterOracle(IMasterOracle _newOracle) external;

    function updateDebtFloor(uint256 _newDebtFloorInUsd) external;

    function updateDepositFee(uint256 _newDepositFee) external;

    function updateIssueFee(uint256 _newIssueFee) external;

    function updateWithdrawFee(uint256 _newWithdrawFee) external;

    function updateRepayFee(uint256 _newRepayFee) external;

    function updateSwapFee(uint256 _newSwapFee) external;

    function updateLiquidatorLiquidationFee(uint256 _newLiquidatorLiquidationFee) external;

    function updateProtocolLiquidationFee(uint256 _newProtocolLiquidationFee) external;

    function updateMaxLiquidable(uint256 _newMaxLiquidable) external;

    function updateTreasury(ITreasury _newTreasury, bool _withMigration) external;

    function treasury() external view returns (ITreasury);

    function masterOracle() external view returns (IMasterOracle);

    function addToDepositTokensOfAccount(address _account) external;

    function removeFromDepositTokensOfAccount(address _account) external;

    function addToDebtTokensOfAccount(address _account) external;

    function removeFromDebtTokensOfAccount(address _account) external;

    function getDepositTokensOfAccount(address _account) external view returns (address[] memory);

    function getDebtTokensOfAccount(address _account) external view returns (address[] memory);

    function addRewardsDistributor(IRewardsDistributor _distributor) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "../dependencies/openzeppelin/token/ERC20/extensions/IERC20Metadata.sol";
import "./ISyntheticToken.sol";

interface IDebtToken is IERC20Metadata {
    function syntheticToken() external view returns (ISyntheticToken);

    function accrueInterest() external returns (uint256 _interestAmountAccrued);

    function debtIndex() external returns (uint256 _debtIndex);

    function mint(address _to, uint256 _amount) external;

    function burn(address _from, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "../dependencies/openzeppelin/token/ERC20/extensions/IERC20Metadata.sol";

interface IDepositToken is IERC20Metadata {
    function underlying() external view returns (IERC20);

    function collateralizationRatio() external view returns (uint256);

    function unlockedBalanceOf(address _account) external view returns (uint256);

    function lockedBalanceOf(address _account) external view returns (uint256);

    function minDepositTime() external view returns (uint256);

    function lastDepositOf(address _account) external view returns (uint256);

    function deposit(uint256 _amount, address _onBehalfOf) external;

    function withdraw(uint256 _amount, address _to) external;

    function mint(address _to, uint256 _amount) external;

    function burn(address _from, uint256 _amount) external;

    function seize(
        address _from,
        address _to,
        uint256 _amount
    ) external;

    function updateCollateralizationRatio(uint128 _newCollateralizationRatio) external;

    function isActive() external view returns (bool);

    function toggleIsActive() external;

    function maxTotalSupplyInUsd() external view returns (uint256);

    function updateMaxTotalSupplyInUsd(uint256 _newMaxTotalSupplyInUsd) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

/**
 * @notice Governable interface
 */
interface IGovernable {
    function governor() external view returns (address _governor);

    function transferGovernorship(address _proposedGovernor) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface IPausable {
    function paused() external returns (bool);

    function everythingStopped() external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "../dependencies/openzeppelin/token/ERC20/IERC20.sol";

/**
 * @notice Reward Distributor interface
 */
interface IRewardsDistributor {
    function rewardToken() external view returns (IERC20);

    function tokenSpeeds(IERC20 _token) external view returns (uint256);

    function tokensAccruedOf(address _account) external view returns (uint256);

    function updateBeforeMintOrBurn(IERC20 _token, address _account) external;

    function updateBeforeTransfer(
        IERC20 _token,
        address _from,
        address _to
    ) external;

    function claimRewards(address _account) external;

    function claimRewards(address _account, IERC20[] memory _tokens) external;

    function claimRewards(address[] memory _accounts, IERC20[] memory _tokens) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "../dependencies/openzeppelin/token/ERC20/extensions/IERC20Metadata.sol";
import "./IDebtToken.sol";

interface ISyntheticToken is IERC20Metadata {
    function isActive() external view returns (bool);

    function maxTotalSupplyInUsd() external view returns (uint256);

    function interestRate() external view returns (uint256);

    function interestRatePerSecond() external view returns (uint256);

    function debtToken() external view returns (IDebtToken);

    function mint(address _to, uint256 amount) external;

    function burn(address _from, uint256 amount) external;

    function updateMaxTotalSupplyInUsd(uint256 _newMaxTotalSupply) external;

    function toggleIsActive() external;

    function updateInterestRate(uint256 _newInterestRate) external;

    function issue(uint256 _amount, address _to) external;

    function repay(address _onBehalfOf, uint256 _amount) external;

    function accrueInterest() external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface ITreasury {
    function pull(address _to, uint256 _amount) external;

    function migrateTo(address _newTreasury) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "../../dependencies/openzeppelin/token/ERC20/IERC20.sol";

interface IMasterOracle {
    function quoteTokenToUsd(IERC20 _asset, uint256 _amount) external view returns (uint256 _amountInUsd);

    function quoteUsdToToken(IERC20 _asset, uint256 _amountInUsd) external view returns (uint256 _amount);

    function quote(
        IERC20 _assetIn,
        IERC20 _assetOut,
        uint256 _amountIn
    ) external view returns (uint256 _amountOut);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

/**
 * @title Math library
 * @dev Provides mul and div function for wads (decimal numbers with 18 digits precision) and rays (decimals with 27 digits)
 * @dev Based on https://github.com/dapphub/ds-math/blob/master/src/math.sol
 */
library WadRayMath {
    uint256 internal constant WAD = 1e18;
    uint256 internal constant HALF_WAD = WAD / 2;

    uint256 internal constant RAY = 1e27;
    uint256 internal constant HALF_RAY = RAY / 2;

    uint256 internal constant WAD_RAY_RATIO = 1e9;

    /**
     * @dev Multiplies two wad, rounding half up to the nearest wad
     * @param a Wad
     * @param b Wad
     * @return The result of a*b, in wad
     */
    function wadMul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0 || b == 0) {
            return 0;
        }

        return (a * b + HALF_WAD) / WAD;
    }

    /**
     * @dev Divides two wad, rounding half up to the nearest wad
     * @param a Wad
     * @param b Wad
     * @return The result of a/b, in wad
     */
    function wadDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        return (a * WAD + b / 2) / b;
    }

    /**
     * @dev Multiplies two ray, rounding half up to the nearest ray
     * @param a Ray
     * @param b Ray
     * @return The result of a*b, in ray
     */
    function rayMul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0 || b == 0) {
            return 0;
        }

        return (a * b + HALF_RAY) / RAY;
    }

    /**
     * @dev Divides two ray, rounding half up to the nearest ray
     * @param a Ray
     * @param b Ray
     * @return The result of a/b, in ray
     */
    function rayDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        return (a * RAY + b / 2) / b;
    }

    /**
     * @dev Casts ray down to wad
     * @param a Ray
     * @return a casted to wad, rounded half up to the nearest wad
     */
    function rayToWad(uint256 a) internal pure returns (uint256) {
        return ((WAD_RAY_RATIO / 2) + a) / WAD_RAY_RATIO;
    }

    /**
     * @dev Converts wad up to ray
     * @param a Wad
     * @return a converted in ray
     */
    function wadToRay(uint256 a) internal pure returns (uint256) {
        return a * WAD_RAY_RATIO;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "../interface/IDepositToken.sol";

abstract contract DepositTokenStorageV1 is IDepositToken {
    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    string public name;
    string public symbol;
    uint8 public decimals;

    uint256 public totalSupply;
    uint256 public maxTotalSupplyInUsd;

    /**
     * @notice Deposit underlying asset (e.g. MET)
     */
    IERC20 public underlying;

    /**
     * @notice Collateralization ration for the deposit token
     * @dev Use 18 decimals (e.g. 0.66e18 = 66%)
     */
    uint256 public collateralizationRatio;

    /**
     * @notice The min amount of time that an account should wait after deposit collateral before be able to withdraw
     */
    uint256 public minDepositTime;

    /**
     * @notice Stores de timestamp of last deposit event of each account. It's used combined with `minDepositTime`.
     */
    mapping(address => uint256) public lastDepositOf;

    /**
     * @notice If a collateral isn't active, it disables minting new tokens
     */
    bool public isActive;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "../dependencies/openzeppelin/token/ERC20/utils/SafeERC20.sol";
import "../dependencies/openzeppelin/token/ERC20/IERC20.sol";

/**
 * @title Utils contract that handles tokens sent to it
 */
abstract contract TokenHolder {
    using SafeERC20 for IERC20;

    /**
     * @notice Function that reverts if the caller isn't allowed to sweep tokens
     */
    function _requireCanSweep() internal view virtual;

    /**
     * @notice ERC20 recovery in case of stuck tokens due direct transfers to the contract address.
     * @param _token The token to transfer
     * @param _to The recipient of the transfer
     * @param _amount The amount to send
     */
    function sweep(
        IERC20 _token,
        address _to,
        uint256 _amount
    ) external {
        _requireCanSweep();

        if (address(_token) == address(0)) {
            Address.sendValue(payable(_to), _amount);
        } else {
            _token.safeTransfer(_to, _amount);
        }
    }

    /**
     * @dev Revert when receiving by default
     */
    receive() external payable virtual {
        revert("receive-not-allowed");
    }

    /**
     * @dev Revert fallback calls
     */
    fallback() external payable {
        revert("fallback-not-allowed");
    }
}