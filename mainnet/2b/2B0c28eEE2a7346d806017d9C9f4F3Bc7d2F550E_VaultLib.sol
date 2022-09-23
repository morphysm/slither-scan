//SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "../interfaces/IPriceOracle.sol";
import "../interfaces/ITokenExchange.sol";
import "./VaultConfig.sol";

library VaultLib {
    using SafeERC20Upgradeable for IERC20MetadataUpgradeable;
    using SafeERC20Upgradeable for IRhoToken;

    struct VaultStorage {
        IVaultConfig config;
        uint256 feeInRho;
    }

    event ReserveChanged(uint256 reserveBalance);
    event RepurchasedFlurry(uint256 rhoTokenIn, uint256 flurryOut);
    event RepurchaseFlurryFailed(uint256 rhoTokenIn);
    event CollectRewardError(address indexed _from, address indexed _strategy, string _reason);
    event CollectRewardUnknownError(address indexed _from, address indexed _strategy);
    event VaultRatesChanged(uint256 supplyRate, uint256 indicativeSupplyRate);
    event NegativeRebase(uint256 oldMultiplier, uint256 newMultiplier);
    event Log(string message);

    function uint2str(uint256 _i) public pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    function flurryToken(VaultStorage storage self) internal view returns (IERC20MetadataUpgradeable) {
        return IERC20MetadataUpgradeable(self.config.flurryToken());
    }

    function rhoToken(VaultStorage storage self) public view returns (IRhoToken) {
        return IRhoToken(self.config.rhoToken());
    }

    function underlying(VaultStorage storage self) public view returns (IERC20MetadataUpgradeable) {
        return IERC20MetadataUpgradeable(self.config.underlying());
    }

    function reserve(VaultStorage storage self) internal view returns (uint256) {
        return underlying(self).balanceOf(address(this));
    }

    function underlyingOne(VaultStorage storage self) internal view returns (uint256) {
        return self.config.underlyingOne();
    }

    function rhoOne(VaultStorage storage self) internal view returns (uint256) {
        return self.config.rhoOne();
    }

    /* distribution */
    // should be called after getting underlying of rhoToken
    function _mintAfterTransfer(VaultStorage storage self, uint256 amount) internal {
        IRhoToken _rhoToken = rhoToken(self);
        uint256 amountInRho = (amount * rhoOne(self)) / underlyingOne(self);
        uint256 _mintingFee = self.config.mintingFee();
        uint256 chargeAmount = (amountInRho * _mintingFee) / 1e4;
        _rhoToken.mint(msg.sender, amountInRho - chargeAmount);
        if (_mintingFee > 0) {
            _rhoToken.mint(address(this), chargeAmount);
            self.feeInRho += chargeAmount;
        }
        emit ReserveChanged(reserve(self));
    }

    function mint(VaultStorage storage self, uint256 amount) public {
        underlying(self).safeTransferFrom(msg.sender, address(this), amount);
        _mintAfterTransfer(self, amount);
    }

    function mintWithDepositToken(
        VaultStorage storage self,
        uint256 amount,
        address depositToken
    ) public {
        IDepositUnwinder unwinder = self.config.getDepositUnwinder(depositToken).target;
        require(address(unwinder) != address(0), "VE8");

        // transfer deposit tokens to unwinder for redeem and unwind actions
        IERC20MetadataUpgradeable(depositToken).safeTransferFrom(msg.sender, address(this), amount);
        IERC20MetadataUpgradeable(depositToken).safeTransfer(address(unwinder), amount);

        uint256 underlyingAdded = unwinder.unwind(depositToken, address(this));

        // mint rhoToken
        rhoToken(self).mint(msg.sender, (underlyingAdded * rhoOne(self)) / underlyingOne(self));
    }

    function redeem(VaultStorage storage self, uint256 amountInRho) public {
        IRhoToken _rhoToken = rhoToken(self);
        uint256 _underlyingOne = underlyingOne(self);
        uint256 _rhoOne = rhoOne(self);
        require(_rhoToken.balanceOf(msg.sender) >= amountInRho, "VE2");

        uint256 amountInUnderlying = (amountInRho * _underlyingOne) / _rhoOne;
        uint256 reserveBalance = reserve(self);
        uint256 chargeAmount = (amountInRho * self.config.redeemFee()) / 1e4;
        uint256 chargeAmountInUnderlying = (chargeAmount * _underlyingOne) / _rhoOne;

        if (amountInUnderlying >= reserveBalance) {
            IVaultConfig.Strategy[] memory strategies = self.config.getStrategiesList();

            // reserveBalance hit zero or not enough to cover withrawal amount\
            // unallocate to replenish reserveBalance to lower bound
            (uint256[] memory balance, uint256[] memory withdrawable, , , ) = self.config.updateStrategiesDetail(
                reserveBalance
            );
            uint256 totalUnderlyingToBe = (_rhoToken.totalSupply() * _underlyingOne) / _rhoOne - amountInUnderlying;
            // amountToWithdraw in underlying
            uint256 amountToWithdraw = amountInUnderlying -
                reserveBalance +
                self.config.reserveLowerBound(totalUnderlyingToBe);

            // VFF-04 although strategies array is unbounded,
            // only flurry'a DEFAULT_ADMIN_ROLE will be able to add a strategies
            // thus there is immediate no denial-of-service threat
            for (uint256 i = 0; i < strategies.length; i++) {
                uint256 stgTarget = strategies[i].target.switchingLockTarget();
                if (withdrawable[i] > amountToWithdraw) {
                    strategies[i].target.withdrawUnderlying(amountToWithdraw);
                    if (stgTarget > withdrawable[i]) {
                        strategies[i].target.switchingLock(stgTarget - withdrawable[i], false);
                    } else {
                        strategies[i].target.switchingLock(0, false);
                    }
                    break;
                } else {
                    if (balance[i] == 0) {
                        continue;
                    }
                    if (stgTarget > withdrawable[i]) {
                        strategies[i].target.switchingLock(stgTarget - withdrawable[i], false);
                    } else {
                        strategies[i].target.switchingLock(0, false);
                    }
                    amountToWithdraw -= withdrawable[i];
                    strategies[i].target.withdrawAllCashAvailable();
                }
            }
        }

        _rhoToken.burn(msg.sender, amountInRho);
        underlying(self).safeTransfer(msg.sender, amountInUnderlying - chargeAmountInUnderlying);
        if (chargeAmount > 0) {
            _rhoToken.mint(address(this), chargeAmount);
            self.feeInRho += chargeAmount;
        }
        emit ReserveChanged(reserve(self));
    }

    function rebalance(VaultStorage storage self) public {
        IVaultConfig.Strategy[] memory strategies = self.config.getStrategiesList();
        IERC20MetadataUpgradeable _underlying = underlying(self);
        uint256 _underlyingOne = underlyingOne(self);

        uint256 gasused;
        (
            uint256[] memory balance,
            uint256[] memory withdrawable,
            bool[] memory locked,
            uint256 optimalIndex,
            uint256 underlyingDeployable
        ) = self.config.updateStrategiesDetail(reserve(self));
        for (uint256 i = 0; i < strategies.length; i++) {
            if (balance[i] == 0) continue;
            if (locked[i]) continue;
            if (optimalIndex == i) continue;
            // withdraw
            uint256 gas0 = gasleft();
            strategies[i].target.withdrawAllCashAvailable();
            uint256 stgTarget = strategies[i].target.switchingLockTarget();
            if (stgTarget > withdrawable[i]) {
                strategies[i].target.switchingLock(stgTarget - withdrawable[i], false);
            } else {
                strategies[i].target.switchingLock(0, false);
            }
            emit VaultRatesChanged(self.config.supplyRate(), self.config.indicativeSupplyRate());
            gasused += gas0 - gasleft();
        }

        uint256 deployAmount;
        if (locked[optimalIndex]) {
            // locked fund is not counted in underlyingDeployable
            deployAmount = underlyingDeployable;
        } else {
            // locked fund is counted in underlyingDeployable, offset the deployable by its own balance
            deployAmount = underlyingDeployable - withdrawable[optimalIndex];
        }

        if (deployAmount != 0) {
            uint256 gas1 = gasleft();
            _underlying.safeTransfer(address(strategies[optimalIndex].target), deployAmount);
            strategies[optimalIndex].target.deploy(deployAmount);
            gasused += gas1 - gasleft();

            uint256 nativePrice = IPriceOracle(self.config.underlyingNativePriceOracle()).priceByQuoteSymbol(
                address(_underlying)
            );
            uint256 switchingCostInUnderlying = (gasused * tx.gasprice * nativePrice * _underlyingOne) / 1e36;
            strategies[optimalIndex].target.switchingLock(
                deployAmount + switchingCostInUnderlying + strategies[optimalIndex].target.switchingLockTarget(),
                true
            );
            emit ReserveChanged(reserve(self));
        } else {
            strategies[optimalIndex].target.deploy(deployAmount);
        }
    }

    function rebase(VaultStorage storage self) public {
        _rebase(self, true);
    }

    function rebaseWithOptions(VaultStorage storage self, bool revertOnNegativeRebase) public {
        _rebase(self, revertOnNegativeRebase);
    }

    function _rebase(VaultStorage storage self, bool revertOnNegativeRebase) internal {
        IVaultConfig.Strategy[] memory strategies = self.config.getStrategiesList();
        IRhoToken _rhoToken = rhoToken(self);
        uint256 _rhoOne = rhoOne(self);

        uint256 originalTvlInRho = _rhoToken.totalSupply();
        if (originalTvlInRho == 0) {
            return;
        }

        // Rebalance fund
        rebalance(self);

        // Rebase
        (uint256 oldM, uint256 lastUpdate) = _rhoToken.getMultiplier();

        uint256 underlyingInvested;
        for (uint256 i = 0; i < strategies.length; i++) {
            underlyingInvested += strategies[i].target.updateBalanceOfUnderlying();
        }
        uint256 currentTvlInUnderlying = reserve(self) + underlyingInvested;
        uint256 currentTvlInRho = (currentTvlInUnderlying * _rhoOne) / underlyingOne(self);
        uint256 rhoRebasing = _rhoToken.unadjustedRebasingSupply();
        uint256 rhoNonRebasing = _rhoToken.nonRebasingSupply();
        if (rhoRebasing < 1e18) {
            // in this case, rhoNonRebasing = rho TotalSupply
            uint256 originalTvlInUnderlying = (originalTvlInRho * underlyingOne(self)) / _rhoOne;
            if (currentTvlInUnderlying > originalTvlInUnderlying) {
                // invested accrued interest
                // all the interest goes to the fee pool since no one is entitled for the interest.
                uint256 feeToMint = ((currentTvlInUnderlying - originalTvlInUnderlying) * _rhoOne) /
                    underlyingOne(self);
                _rhoToken.mint(address(this), feeToMint);
                self.feeInRho += feeToMint;
            }
            return;
        }

        // from this point forward, rhoRebasing > 0
        if (currentTvlInRho == originalTvlInRho) {
            // no fees charged, multiplier does not change
            return;
        }
        if (currentTvlInRho < originalTvlInRho) {
            uint256 _newM = ((currentTvlInRho - rhoNonRebasing) * 1e36) / rhoRebasing;
            // Check for -ive rebase
            // This would happen if there are fees deducted when minting deposit tokens
            // or when balanceOfUnderlying has gone down compared to previous rebase
            // mulitplier is scaled by 36 decimals, allow for an error of 1e30 for multiplier
            // 1e30 err in multiplier is equalivant to 1e-2 dollars error for 1 billion dollars.
            if ((_newM + 1e30) < oldM) {
                if (revertOnNegativeRebase) {
                    revert(uint2str(_newM));
                }
                lastUpdate; // not used
                emit NegativeRebase(oldM, _newM);
            }

            // If the drop in within allowed threshold
            // this happens when fund is initially deployed to a protocol where there is rounding errors (e.g. Compound)
            // and get balance of underlying right away
            // strategy losing money, no fees will be charged
            _rhoToken.setMultiplier(_newM);
            return;
        }

        uint256 fee36 = (currentTvlInRho - originalTvlInRho) * self.config.managementFee();
        uint256 fee18 = fee36 / 1e18;
        if (fee18 > 0) {
            // mint vault's fee18
            _rhoToken.mint(address(this), fee18);
            self.feeInRho += fee18;
        }
        uint256 newM = ((currentTvlInRho * 1e18 - rhoNonRebasing * 1e18 - fee36) * 1e18) / rhoRebasing;
        _rhoToken.setMultiplier(newM);
    }

    function withdrawFees(
        VaultStorage storage self,
        uint256 amount,
        address to
    ) public {
        require(self.feeInRho >= amount, "VE4");
        self.feeInRho -= amount;
        rhoToken(self).safeTransfer(to, amount);
    }

    function retireStrategy(VaultStorage storage self, address strategy) public {
        require(strategy != address(0), "VE6");
        IRhoStrategy target = IRhoStrategy(strategy);

        //collect every bonus no matter how small
        target.collectRewardTokens(0);

        // recall funds if there any from strategy
        target.withdrawAllCashAvailable();
        require(target.updateBalanceOfUnderlying() == 0, "VE7");
        self.config.removeStrategy(strategy);
    }

    function retireDepositUnwinder(VaultStorage storage self, address token) public {
        require(token != address(0), "VE9");

        // there should not be any token left in the unwinder
        // not doing checking
        self.config.removeDepositUnwinder(token);
    }

    function withdrawFromAllStrategies(VaultStorage storage self) public {
        IVaultConfig.Strategy[] memory strategies = self.config.getStrategiesList();

        for (uint256 i = 0; i < strategies.length; i++) {
            uint256 underlyingWithdrawable = strategies[i].target.underlyingWithdrawable();
            uint256 stgTarget = strategies[i].target.switchingLockTarget();
            strategies[i].target.withdrawAllCashAvailable();
            if (stgTarget > underlyingWithdrawable) {
                strategies[i].target.switchingLock(stgTarget - underlyingWithdrawable, false);
            } else {
                strategies[i].target.switchingLock(0, false);
            }
        }
    }

    function shouldRepurchaseFlurry(VaultStorage storage self) public view returns (bool) {
        return self.feeInRho >= self.config.repurchaseFlurryThreshold();
    }

    function repurchaseFlurry(VaultStorage storage self) public {
        // sanity check
        require(self.config.repurchaseSanityCheck(), "VE5");
        // setup Token Exchange and rhoToken
        ITokenExchange tokenEx = ITokenExchange(self.config.tokenExchange());
        uint256 rhoToSell = (self.feeInRho * self.config.repurchaseFlurryRatio()) / 1e18;
        rhoToken(self).safeIncreaseAllowance(address(tokenEx), rhoToSell);
        // state change
        self.feeInRho -= rhoToSell;
        // sell rhoToken at TokenExchange for FLURRY
        uint256 flurryReceived = tokenEx.sellExactInput(
            rhoToken(self),
            flurryToken(self),
            self.config.flurryStakingRewards(),
            rhoToSell
        );
        emit RepurchasedFlurry(rhoToSell, flurryReceived);
    }
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
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
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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
pragma solidity 0.8.9;

interface IPriceOracle {
    /**
     * @return decimals of the "baseSymbol / quoteSymbol" rate
     */
    function decimals() external view returns (uint8);

    /**
     * @return name of the token pair, in the form of "baseSymbol / quoteSymbol"
     */
    function description() external view returns (string memory);

    /**
     * @return name of the base symbol
     */
    function baseSymbol() external view returns (string memory);

    /**
     * @return name of the quote symbol
     */
    function quoteSymbol() external view returns (string memory);

    /**
     * @return address of the base symbol, zero address if `baseSymbol` is USD
     */
    function baseAddr() external view returns (address);

    /**
     * @return address of the quote symbol, zero address if `baseSymbol` is USD
     */
    function quoteAddr() external view returns (address);

    /**
     * @return updateAt timestamp of the last update as seconds since unix epoch
     */
    function lastUpdate() external view returns (uint256 updateAt);

    /**
     * @param _baseAddr address of the base currency in the currency pair
     * @return "baseSymbol / quoteSymbol" rate, i.e. quantity of quote currency in exchange for 1 unit of base currency,
     * where the baseSymbol is specified in the input parameter, return type(uint256).max for invalid rate
     */
    function price(address _baseAddr) external view returns (uint256);

    /**
     * @param _quoteAddr address of the quote currency in the currency pair
     * @return "baseSymbol / quoteSymbol" rate, i.e. quantity of quote currency in exchange for 1 unit of base currency,
     * where the quoteSymbol is specified in the input parameter, return type(uint256).max for invalid rate
     */
    function priceByQuoteSymbol(address _quoteAddr) external view returns (uint256);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.9;
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import "./IPriceOracle.sol";

/**
 * @title Token Exchange Interface
 * @notice Interface for exchanging token on other protocols such as uniswap
 *
 */
interface ITokenExchange {
    event SellToken(address inputToken, address outputToken, uint256 amountIn, uint256 amountOut);

    /**
     * @notice A method to sell input token into output token for a certain input amount.
     * @return uint256 amount of outputToken
     */
    function sellExactInput(
        IERC20MetadataUpgradeable inputToken,
        IERC20MetadataUpgradeable outputToken,
        address recipient,
        uint256 amountIn_
    ) external returns (uint256);

    /**
     * @notice A method to sell the chain's native token (e.g. AVAX on Avalanche) into the desired outputToken
     * @return uint256 amount of outputToken
     */
    function sellExactNativeTokens(IERC20MetadataUpgradeable outputToken, address recipient)
        external
        payable
        returns (uint256);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.9;
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "../interfaces/IRhoToken.sol";
import "../interfaces/IVaultConfig.sol";

contract VaultConfig is IVaultConfig, AccessControlEnumerableUpgradeable, PausableUpgradeable {
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant VAULT_ROLE = keccak256("VAULT_ROLE");
    address public override rhoToken;
    address public override underlying;
    uint256 public override mintingFee; // 18 decimal
    uint256 public override redeemFee; // 18 decimal
    uint256[2] public override reserveBoundary; // 18 decimal
    uint256 public override managementFee; // 18 decimal
    uint256 public override rewardCollectThreshold;
    uint256 public override rhoOne;
    uint256 public override underlyingOne;
    Strategy[] public strategies;
    address[] public strategyAddrs;

    /**
     * @notice Flurry Price Oracle to give price feed for native currency
     * For example, ETH on Ethereum, BNB on Binance Smart Chain...
     * Default base = underlying token, quote = native currency
     */
    address public override underlyingNativePriceOracle;

    /**
     * @notice Flurry Staking Rewards stores the FLURRY rewards pool
     */
    address public override flurryStakingRewards;

    /**
     * @notice Token Exchange to buy FLURRY with rhoToken management fee
     */
    address public override tokenExchange;

    address public override flurryToken;

    /**
     * @dev defines % of fees to be converted to FLURRY
     * 100% == 1e18
     */
    uint256 public override repurchaseFlurryRatio;

    /**
     * @dev threshold (in Rho) to trigger FLURRY purchase
     */
    uint256 public override repurchaseFlurryThreshold;

    address[] public depositTokens;
    mapping(address => DepositUnwinder) depositUnwinders;

    function initialize(
        address _flurryTokenAddr,
        address _rhoAddr,
        address _underlyingAddr,
        address _udlyNativePriceOracleAddr,
        uint256 _mFee,
        uint256 _rFee,
        uint256 _mngtFee,
        uint256 _rLowerBound,
        uint256 _rUpperBound,
        uint256 _rewardCollectThreshold,
        uint256 _repurchaseFlurryRatio,
        uint256 _repurchaseFlurryThreshold
    ) external initializer {
        AccessControlEnumerableUpgradeable.__AccessControlEnumerable_init();
        PausableUpgradeable.__Pausable_init_unchained();
        _setMintingFee(_mFee);
        _setRedeemFee(_rFee);
        _setManagementFee(_mngtFee);
        _setReserveBoundary(_rLowerBound, _rUpperBound);
        flurryToken = _flurryTokenAddr;
        _setRhoToken(_rhoAddr);
        _setUnderlying(_underlyingAddr);
        _setUnderlyingNativePriceOracle(_udlyNativePriceOracleAddr);
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setRewardCollectThreshold(_rewardCollectThreshold);
        _setRepurchaseFlurryRatio(_repurchaseFlurryRatio);
        _setRepurchaseFlurryThreshold(_repurchaseFlurryThreshold);
    }

    function setUnderlyingNativePriceOracle(address addr) external override onlyRole(DEFAULT_ADMIN_ROLE) whenNotPaused {
        _setUnderlyingNativePriceOracle(addr);
    }

    function _setUnderlyingNativePriceOracle(address addr) internal {
        require(addr != address(0), "Und-Native price oracle addrress is 0");
        underlyingNativePriceOracle = addr;
        emit UnderlyingNativePriceOracleSet(underlyingNativePriceOracle);
    }

    function setMintingFee(uint256 _feeInWei) external override onlyRole(DEFAULT_ADMIN_ROLE) whenNotPaused {
        _setMintingFee(_feeInWei);
    }

    function _setMintingFee(uint256 _feeInWei) internal {
        mintingFee = _feeInWei;
        emit MintingFeeSet(mintingFee);
    }

    /* redeem Fee */
    function setRedeemFee(uint256 _feeInWei) external override onlyRole(DEFAULT_ADMIN_ROLE) whenNotPaused {
        _setRedeemFee(_feeInWei);
    }

    function _setRedeemFee(uint256 _feeInWei) internal {
        redeemFee = _feeInWei;
        emit RedeemFeeSet(redeemFee);
    }

    /* in underlying token */
    function setRewardCollectThreshold(uint256 _rewardCollectThreshold)
        external
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
        whenNotPaused
    {
        _setRewardCollectThreshold(_rewardCollectThreshold);
    }

    function _setRewardCollectThreshold(uint256 _rewardCollectThreshold) internal {
        rewardCollectThreshold = (_rewardCollectThreshold * underlyingOne) / 1e18;
        emit RewardCollectThresholdSet(rewardCollectThreshold);
    }

    function setManagementFee(uint256 _feeInWei) external override onlyRole(DEFAULT_ADMIN_ROLE) whenNotPaused {
        _setManagementFee(_feeInWei);
    }

    function _setManagementFee(uint256 _feeInWei) internal {
        managementFee = _feeInWei;
        emit ManagementFeeSet(managementFee);
    }

    /* alloc threshold */
    function setReserveBoundary(uint256 reserveLowerBound_, uint256 reserveUpperBound_)
        external
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
        whenNotPaused
    {
        _setReserveBoundary(reserveLowerBound_, reserveUpperBound_);
    }

    function _setReserveBoundary(uint256 reserveLowerBound_, uint256 reserveUpperBound_) internal {
        reserveBoundary = [reserveLowerBound_, reserveUpperBound_];
        emit ReserveBoundarySet(reserveLowerBound_, reserveUpperBound_);
    }

    /* underlying */
    function _setUnderlying(address _addr) internal {
        require(_addr != address(0), "underlying address is 0");
        underlying = _addr;
        underlyingOne = 10**IERC20MetadataUpgradeable(underlying).decimals();
    }

    /* rho token */
    function _setRhoToken(address _addr) internal {
        require(_addr != address(0), "rhoToken address is 0");
        rhoToken = _addr;
        rhoOne = 10**IRhoToken(rhoToken).decimals();
        emit RhoTokenSet(rhoToken);
    }

    // calculates underlying reserve at upper bound based on a rho total supply
    function reserveUpperBound(uint256 tvl) public view override returns (uint256) {
        return ((tvl * reserveBoundary[1]) / 1e18);
    }

    // calculates underlying reserve at lower bound based on a rho total supply
    function reserveLowerBound(uint256 tvl) public view override returns (uint256) {
        return ((tvl * reserveBoundary[0]) / 1e18);
    }

    /* pause */
    function pause() external onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function supplyRate() external view override returns (uint256) {
        uint256 totalInterestPerYear;
        for (uint256 i = 0; i < strategies.length; i++) {
            totalInterestPerYear +=
                strategies[i].target.balanceOfUnderlying() *
                strategies[i].target.effectiveSupplyRate();
        }
        uint256 rebasingSupply = IRhoToken(rhoToken).adjustedRebasingSupply(); // in 18
        if (rebasingSupply == 0) return type(uint256).max;
        return (totalInterestPerYear * rhoOne) / rebasingSupply / underlyingOne;
    }

    function indicativeSupplyRate() external view override returns (uint256) {
        uint256 len = strategies.length;
        uint256 optimalRate;
        uint256 rebasingSupply = IRhoToken(rhoToken).adjustedRebasingSupply();
        uint256 totalSupply = IRhoToken(rhoToken).totalSupply();
        for (uint256 i = 0; i < len; i++) {
            uint256 rate = strategies[i].target.effectiveSupplyRate();
            if (optimalRate > rate) continue;
            optimalRate = rate;
        }
        if (rebasingSupply == 0) {
            return type(uint256).max;
        }
        return (optimalRate * (1e18 - reserveBoundary[0]) * totalSupply) / 1e18 / rebasingSupply;
    }

    function addStrategy(string memory name, address strategy) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        require(strategy != address(0), "strategy address is 0");
        strategies.push(Strategy(name, IRhoStrategy(strategy)));
        strategyAddrs.push(strategy);
        emit StrategyAdded(name, strategy);
    }

    function removeStrategy(address strategy) external override onlyRole(VAULT_ROLE) {
        uint256 len = strategies.length;
        for (uint256 i = 0; i < len; i++) {
            IRhoStrategy target = strategies[i].target;
            if (address(target) == strategy) {
                emit StrategyRemoved(strategies[i].name, address(target));
                strategies[i] = strategies[len - 1];
                strategies.pop();
                strategyAddrs[i] = strategyAddrs[strategyAddrs.length - 1];
                strategyAddrs.pop();
                return;
            }
        }
    }

    function isStrategyRegistered(address s) external view override returns (bool) {
        require(s != address(0), "strategy address is 0");
        for (uint256 i = 0; i < strategyAddrs.length; i++) {
            if (strategyAddrs[i] == s) return true;
        }
        return false;
    }

    function getStrategiesList() external view override returns (Strategy[] memory) {
        return strategies;
    }

    function getStrategiesListLength() external view override returns (uint256) {
        return strategies.length;
    }

    function updateStrategiesDetail(uint256 vaultUnderlyingBalance)
        external
        override
        onlyRole(VAULT_ROLE)
        returns (
            uint256[] memory,
            uint256[] memory,
            bool[] memory,
            uint256,
            uint256
        )
    {
        uint256 underlyingInvested;
        uint256 underlyingDeployable;

        bool[] memory locked = new bool[](strategies.length);
        uint256[] memory balance = new uint256[](strategies.length);
        uint256[] memory withdrawable = new uint256[](strategies.length);

        uint256 underlyingUninvested = vaultUnderlyingBalance;

        for (uint256 i = 0; i < strategies.length; i++) {
            balance[i] = strategies[i].target.updateBalanceOfUnderlying();
            withdrawable[i] = strategies[i].target.underlyingWithdrawable();
            underlyingInvested += balance[i];
            if (strategies[i].target.isLocked()) {
                locked[i] = true;
            } else {
                underlyingDeployable += withdrawable[i];
            }
        }

        uint256 tvl = underlyingUninvested + underlyingInvested;
        uint256 upperBound = reserveUpperBound(tvl);
        if (underlyingUninvested > upperBound) {
            uint256 lowerBound = reserveLowerBound(tvl);
            underlyingDeployable += underlyingUninvested - lowerBound;
        }

        // optimal strategy? worst strategy?
        uint256 optimalRate;
        uint256 optimalIndex;
        for (uint256 i = 0; i < strategies.length; i++) {
            uint256 rate;
            IRhoStrategy strategy = strategies[i].target;
            if (strategy.isLocked()) {
                // locked fund is not counted in underlyingDeployable
                rate = strategy.effectiveSupplyRate(underlyingDeployable, true);
            } else {
                // locked fund is counted in underlyingDeployable, offset the deployable by its own withdrawable
                rate = strategy.effectiveSupplyRate(underlyingDeployable - withdrawable[i], true);
            }
            if (rate > optimalRate) {
                optimalRate = rate;
                optimalIndex = i;
            }
            emit StrategyRatesChanged(
                address(strategy),
                strategy.effectiveSupplyRate(),
                strategy.supplyRate(),
                strategy.bonusSupplyRate()
            );
        }
        return (balance, withdrawable, locked, optimalIndex, underlyingDeployable);
    }

    function checkStrategiesCollectReward() external view override returns (bool[] memory collectList) {
        bool[] memory _collectList = new bool[](strategies.length);
        for (uint256 i = 0; i < strategies.length; i++) {
            _collectList[i] = strategies[i].target.shouldCollectReward(rewardCollectThreshold);
        }
        return _collectList;
    }

    function setFlurryToken(address addr) external override onlyRole(DEFAULT_ADMIN_ROLE) whenNotPaused {
        _setFlurryToken(addr);
    }

    function _setFlurryToken(address addr) internal {
        flurryToken = addr;
        emit FlurryTokenSet(flurryToken);
    }

    function setFlurryStakingRewards(address addr) external override onlyRole(DEFAULT_ADMIN_ROLE) whenNotPaused {
        _setFlurryStakingRewards(addr);
    }

    function _setFlurryStakingRewards(address addr) internal {
        flurryStakingRewards = addr;
        emit FlurryStakingRewardsSet(flurryStakingRewards);
    }

    function setTokenExchange(address addr) external override onlyRole(DEFAULT_ADMIN_ROLE) whenNotPaused {
        _setTokenExchange(addr);
    }

    function _setTokenExchange(address addr) internal {
        tokenExchange = addr;
        emit TokenExchangeSet(tokenExchange);
    }

    function setRepurchaseFlurryRatio(uint256 _ratio) external override onlyRole(DEFAULT_ADMIN_ROLE) whenNotPaused {
        _setRepurchaseFlurryRatio(_ratio);
    }

    function _setRepurchaseFlurryRatio(uint256 _ratio) internal {
        require(_ratio <= 1e18, "max repurcasing ratio is 100% (1e18)");
        repurchaseFlurryRatio = _ratio;
        emit RepurchaseFlurryRatioSet(repurchaseFlurryRatio);
    }

    function setRepurchaseFlurryThreshold(uint256 _threshold)
        external
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
        whenNotPaused
    {
        _setRepurchaseFlurryThreshold(_threshold);
    }

    function _setRepurchaseFlurryThreshold(uint256 _threshold) internal {
        repurchaseFlurryThreshold = _threshold;
        emit RepurchaseFlurryThresholdSet(repurchaseFlurryThreshold);
    }

    function repurchaseSanityCheck() external view override returns (bool) {
        return
            flurryToken != address(0) &&
            rhoToken != address(0) &&
            flurryStakingRewards != address(0) &&
            tokenExchange != address(0);
    }

    function getStrategy(address depositToken) external view override returns (address) {
        for (uint256 i = 0; i < strategies.length; i++) {
            if (depositToken == strategies[i].target.depositToken()) {
                return (address(strategies[i].target));
            }
        }
        return address(0);
    }

    function addDepositUnwinder(
        address token,
        string memory tokenName,
        address unwinder
    ) external override onlyRole(DEFAULT_ADMIN_ROLE) whenNotPaused {
        require(token != address(0), "deposit token is 0");
        require(unwinder != address(0), "unwinder address is 0");
        require(address(depositUnwinders[token].target) == address(0), "deposit token registered");
        depositTokens.push(token);
        depositUnwinders[token] = DepositUnwinder(tokenName, IDepositUnwinder(unwinder));
        emit DepositUnwinderAdded(token, unwinder);
    }

    function removeDepositUnwinder(address token) external override onlyRole(VAULT_ROLE) whenNotPaused {
        require(token != address(0), "deposit token is 0");
        require(address(depositUnwinders[token].target) != address(0), "no unwinder is registered");

        uint256 len = depositTokens.length;
        for (uint256 i = 0; i < len; i++) {
            if (address(depositTokens[i]) == token) {
                emit DepositUnwinderRemoved(token, address(depositUnwinders[token].target));

                depositTokens[i] = depositTokens[len - 1];
                depositTokens.pop();

                delete depositUnwinders[token];
                return;
            }
        }
    }

    function getDepositUnwinder(address token) external view override returns (DepositUnwinder memory d) {
        if (address(depositUnwinders[token].target) != address(0)) {
            return d = depositUnwinders[token];
        }
    }

    function getDepositTokens() external view override returns (address[] memory) {
        return depositTokens;
    }

    function setRhoToken(address token) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        _setRhoToken(token);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControlEnumerableUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "../utils/structs/EnumerableSetUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Extension of {AccessControl} that allows enumerating the members of each role.
 */
abstract contract AccessControlEnumerableUpgradeable is Initializable, IAccessControlEnumerableUpgradeable, AccessControlUpgradeable {
    function __AccessControlEnumerable_init() internal onlyInitializing {
    }

    function __AccessControlEnumerable_init_unchained() internal onlyInitializing {
    }
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    mapping(bytes32 => EnumerableSetUpgradeable.AddressSet) private _roleMembers;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlEnumerableUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view virtual override returns (address) {
        return _roleMembers[role].at(index);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view virtual override returns (uint256) {
        return _roleMembers[role].length();
    }

    /**
     * @dev Overload {_grantRole} to track enumerable memberships
     */
    function _grantRole(bytes32 role, address account) internal virtual override {
        super._grantRole(role, account);
        _roleMembers[role].add(account);
    }

    /**
     * @dev Overload {_revokeRole} to track enumerable memberships
     */
    function _revokeRole(bytes32 role, address account) internal virtual override {
        super._revokeRole(role, account);
        _roleMembers[role].remove(account);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
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
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.9;
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";

/**
 * @notice Interface for yield farming strategies to integrate with various DeFi Protocols like Compound, Aave, dYdX.. etc
 */
interface IRhoToken is IERC20MetadataUpgradeable {
    /**
     * @dev rebase option will be set when user calls setRebasingOption()
     * default is UNKNOWN, determined by EOA/contract type
     */
    enum RebaseOption {
        UNKNOWN,
        REBASING,
        NON_REBASING
    }

    event MultiplierChange(uint256 from, uint256 to);
    event RhoTokenSupplyChanged(uint256 totalSupply, uint256 rebasingSupply, uint256 nonRebasingSupply);
    event SetRebasingOption(address account, RebaseOption option);
    event SetUnderlying(address addr);

    /**
     * @notice specific to BEP-20 interface
     * @return the address of the contract owner
     */
    function getOwner() external view returns (address);

    /**
     * @dev adjusted supply is multiplied by multiplier from rebasing
     * @return issued amount of rhoToken that is rebasing
     * Total supply = adjusted rebasing supply + non-rebasing supply
     * Adjusted rebasing supply = unadjusted rebasing supply * multiplier
     */
    function adjustedRebasingSupply() external view returns (uint256);

    /**
     * @dev unadjusted supply is NOT multiplied by multiplier from rebasing
     * @return internally stored amount of rhoTokens that is rebasing
     */
    function unadjustedRebasingSupply() external view returns (uint256);

    /**
     * @return issued amount of rhoTokens that is non-rebasing
     */
    function nonRebasingSupply() external view returns (uint256);

    /**
     * @notice The multiplier is set during a rebase
     * @param multiplier - scaled by 1e36
     */
    function setMultiplier(uint256 multiplier) external;

    /**
     * @return multiplier - returns the muliplier of the rhoToken, scaled by 1e36
     * @return lastUpdate - last update time of the multiplier, equivalent to last rebase time
     */
    function getMultiplier() external view returns (uint256 multiplier, uint256 lastUpdate);

    /**
     * @notice function to mint rhoTokens - callable only by owner
     * @param account account for sending new minted tokens to
     * @param amount amount of tokens to be minted
     */
    function mint(address account, uint256 amount) external;

    /**
     * @notice function to burn rhoTokens - callable only by owner
     * @param account the account address for burning tokens from
     * @param amount amount of tokens to be burned
     */
    function burn(address account, uint256 amount) external;

    /**
     * @notice switches the account type of `msg.sender` between rebasing and non-rebasing
     * @param isRebasing true if setting to rebasing, false if setting to non-rebasing
     * NOTE: this function does nothing if caller is already in the same option
     */
    function setRebasingOption(bool isRebasing) external;

    /**
     * @param account address of account to check
     * @return true if `account` is a rebasing account
     */
    function isRebasingAccount(address account) external view returns (bool);

    /**
     * @notice Admin function - set reference token rewards contract
     * @param tokenRewards token rewards contract address
     */
    function setTokenRewards(address tokenRewards) external;

    /**
     * @notice Admin function to sweep ERC20s (other than rhoToken) accidentally sent to this contract
     * @param token token contract address
     * @param to which address to send sweeped ERC20s to
     */
    function sweepERC20Token(address token, address to) external;

    /**
     * @notice Admin function - set reference underlying token contract
     * @param token contract address
     */
    function setUnderlying(address token) external;

    /**
     * @return Returns the contract address of the underlying asset
     */
    function underlying() external view returns (address);

    /**
     * @notice Admin function - pause contract
     */
    function pause() external;

    /**
     * @notice Admin function - unpause contract
     */
    function unpause() external;

    /**
     * @return true if contract is paused
     */
    function paused() external view returns (bool);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./IRhoStrategy.sol";
import "./IDepositUnwinder.sol";

interface IVaultConfig {
    event Log(string message);
    event StrategyAdded(string name, address addr);
    event StrategyRemoved(string name, address addr);
    event StrategyRatesChanged(address indexed strategy, uint256 effRate, uint256 supplyRate, uint256 bonusRate);
    event DepositUnwinderAdded(address token, address addr);
    event DepositUnwinderRemoved(address token, address addr);
    event UnderlyingNativePriceOracleSet(address addr);
    event MintingFeeSet(uint256 fee);
    event RedeemFeeSet(uint256 fee);
    event ManagementFeeSet(uint256 fee);
    event RewardCollectThresholdSet(uint256 threshold);
    event ReserveBoundarySet(uint256 lowerBound, uint256 upperBound);
    event FlurryTokenSet(address token);
    event FlurryStakingRewardsSet(address addr);
    event TokenExchangeSet(address addr);
    event RepurchaseFlurryRatioSet(uint256 ratio);
    event RepurchaseFlurryThresholdSet(uint256 threshold);
    event RhoTokenSet(address token);

    struct Strategy {
        string name;
        IRhoStrategy target;
    }

    struct DepositUnwinder {
        string tokenName;
        IDepositUnwinder target;
    }

    /**
     * @return FLURRY token address
     */
    function flurryToken() external view returns (address);

    /**
     * @return Returns the address of the Rho token contract
     */
    function rhoToken() external view returns (address);

    function rhoOne() external view returns (uint256);

    /**
     * Each Vault currently only supports one underlying asset
     * @return Returns the contract address of the underlying asset
     */
    function underlying() external view returns (address);

    function underlyingOne() external view returns (uint256);

    /**
     * @dev Getter function for Rho token minting fee
     * @return Return the minting fee (in bps)
     */
    function mintingFee() external view returns (uint256);

    /**
     * @dev Getter function for Rho token redemption fee
     * @return Return the redeem fee (in bps)
     */
    function redeemFee() external view returns (uint256);

    /**
     * @dev Getter function for allocation lowerbound and upperbound
     */
    function reserveBoundary(uint256 index) external view returns (uint256);

    function managementFee() external view returns (uint256);

    /**
     * @dev The threshold (denominated in underlying asset ) over which rewards tokens will automatically
     * be converted into the underlying asset
     */

    function rewardCollectThreshold() external view returns (uint256);

    function underlyingNativePriceOracle() external view returns (address);

    function setUnderlyingNativePriceOracle(address addr) external;

    /**
     * @dev Setter function for Rho token redemption fee
     */
    function setRedeemFee(uint256 _feeInBps) external;

    /**
     * @dev set the threshold for collect reward (denominated in underlying asset)
     */
    function setRewardCollectThreshold(uint256 _rewardCollectThreshold) external;

    function setManagementFee(uint256 _feeInBps) external;

    /**
     * @dev set the allocation threshold (denominated in underlying asset)
     */
    function setReserveBoundary(uint256 _lowerBound, uint256 _upperBound) external;

    /**
     * @dev Setter function for minting fee (in bps)
     */
    function setMintingFee(uint256 _feeInBps) external;

    function reserveLowerBound(uint256 tvl) external view returns (uint256);

    function reserveUpperBound(uint256 tvl) external view returns (uint256);

    function supplyRate() external view returns (uint256);

    /**
     * @dev Add strategy contract which implments the IRhoStrategy interface to the vault
     */
    function addStrategy(string memory name, address strategy) external;

    /**
     * @dev Remove strategy contract which implments the IRhoStrategy interface from the vault
     */
    function removeStrategy(address strategy) external;

    /**
     * @dev Check if a strategy is registered
     * @param s address of strategy contract
     * @return boolean
     */
    function isStrategyRegistered(address s) external view returns (bool);

    function getStrategiesList() external view returns (Strategy[] memory);

    function getStrategiesListLength() external view returns (uint256);

    function updateStrategiesDetail(uint256 vaultUnderlyingBalance)
        external
        returns (
            uint256[] memory,
            uint256[] memory,
            bool[] memory,
            uint256,
            uint256
        );

    function checkStrategiesCollectReward() external view returns (bool[] memory collectList);

    function indicativeSupplyRate() external view returns (uint256);

    function setFlurryToken(address addr) external;

    function flurryStakingRewards() external view returns (address);

    function setFlurryStakingRewards(address addr) external;

    function tokenExchange() external view returns (address);

    function setTokenExchange(address addr) external;

    /**
     * @notice Part of the management fee is used to buy back FLURRY
     * from AMM. The FLURRY tokens are sent to FlurryStakingRewards
     * to replendish the rewards pool.
     * @return ratio of repurchasing, with 1e18 representing 100%
     */
    function repurchaseFlurryRatio() external view returns (uint256);

    /**
     * @notice setter method for `repurchaseFlurryRatio`
     * @param _ratio new ratio to be set, must be <=1e18
     */
    function setRepurchaseFlurryRatio(uint256 _ratio) external;

    /**
     * @notice Triggers FLURRY repurchasing if management fee >= threshold
     * @return threshold for triggering FLURRY repurchasing
     */
    function repurchaseFlurryThreshold() external view returns (uint256);

    /**
     * @notice setter method for `repurchaseFlurryThreshold`
     * @param _threshold new threshold to be set
     */
    function setRepurchaseFlurryThreshold(uint256 _threshold) external;

    /**
     * @dev Vault should call this before repurchaseFlurry() for sanity check
     * @return true if all dependent contracts are valid
     */
    function repurchaseSanityCheck() external view returns (bool);

    /**
     * @dev Get the strategy which the deposit token belongs to
     * @param depositToken address of deposit token
     */
    function getStrategy(address depositToken) external view returns (address);

    /**
     * @dev Add unwinder contract which implments the IDepositUnwinder interface to the vault
     * @param token deposit token address
     * @param tokenName deposit token name
     * @param unwinder deposit unwinder address
     */
    function addDepositUnwinder(
        address token,
        string memory tokenName,
        address unwinder
    ) external;

    /**
     * @dev Remove unwinder contract which implments the IDepositUnwinder interface from the vault
     * @param token deposit token address
     */
    function removeDepositUnwinder(address token) external;

    /**
     * @dev Get the unwinder which the deposit token belongs to
     * @param token deposit token address
     * @return d unwinder object
     */
    function getDepositUnwinder(address token) external view returns (DepositUnwinder memory d);

    /**
     * @dev Get the deposit tokens
     * @return deposit token addresses
     */
    function getDepositTokens() external view returns (address[] memory);

    function setRhoToken(address token) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerableUpgradeable is IAccessControlUpgradeable {
    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../utils/StringsUpgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal onlyInitializing {
    }

    function __AccessControl_init_unchained() internal onlyInitializing {
    }
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        StringsUpgradeable.toHexString(uint160(account), 20),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSetUpgradeable {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
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
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
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
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

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

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
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
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
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

//SPDX-License-Identifier: MIT
pragma solidity 0.8.9;
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";

/**
 * @title RhoStrategy Interface
 * @notice Interface for yield farming strategies to integrate with various DeFi Protocols like Compound, Aave, dYdX.. etc
 */
interface IRhoStrategy {
    /**
     * Events
     */
    event WithdrawAllCashAvailable();
    event WithdrawUnderlying(uint256 amount);
    event Deploy(uint256 amount);
    event StrategyOutOfCash(uint256 balance, uint256 withdrawable);
    event BalanceOfUnderlyingChanged(uint256 balance);

    /**
     * @return name of protocol
     */
    function NAME() external view returns (string memory);

    /**
     * @dev for conversion bwtween APY and per block rate
     * @return number of blocks per year
     */
    function BLOCK_PER_YEAR() external view returns (uint256);

    /**
     * @dev setter function for `BLOCK_PER_YEAR`
     * @param blocksPerYear new number of blocks per year
     */
    function setBlocksPerYear(uint256 blocksPerYear) external;

    /**
     * @return underlying ERC20 token
     */
    function underlying() external view returns (IERC20MetadataUpgradeable);

    /**
     * @dev unlock when TVL exceed the this target
     */
    function switchingLockTarget() external view returns (uint256);

    /**
     * @dev duration for locking the strategy
     */
    function switchLockDuration() external view returns (uint256);

    /**
     * @return block number after which rewards are unlocked
     */
    function switchLockedUntil() external view returns (uint256);

    /**
     * @dev setter of switchLockDuration
     */
    function setSwitchLockDuration(uint256 durationInBlock) external;

    /**
     * @dev lock the strategy with a lock target
     */
    function switchingLock(uint256 lockTarget, bool extend) external;

    /**
     * @dev view function to return balance in underlying
     * @return balance (interest included) from DeFi protocol, in terms of underlying (in wei)
     */
    function balanceOfUnderlying() external view returns (uint256);

    /**
     * @dev updates the balance in underlying, and returns it. An `BalanceOfUnderlyingChanged` event is also emitted
     * @return updated balance (interest included) from DeFi protocol, in terms of underlying (in wei)
     */
    function updateBalanceOfUnderlying() external returns (uint256);

    /**
     * @dev deploy the underlying to DeFi platform
     * @param _amount amount of underlying (in wei) to deploy
     */
    function deploy(uint256 _amount) external;

    /**
     * @notice current supply rate per block excluding bonus token (such as Aave / Comp)
     * @return supply rate per block, excluding yield from reward token if any
     */
    function supplyRatePerBlock() external view returns (uint256);

    /**
     * @notice current supply rate excluding bonus token (such as Aave / Comp)
     * @return supply rate per year, excluding yield from reward token if any
     */
    function supplyRate() external view returns (uint256);

    /**
     * @return address of bonus token contract, or 0 if no bonus token
     */
    function bonusTokens() external view returns (address[] memory);

    /**
     * @notice current bonus rate per block for bonus token (such as Aave / Comp)
     * @return bonus supply rate per block
     */
    function bonusRatePerBlock() external view returns (uint256);

    /**
     * @return bonus tokens accrued
     * @notice may remove in the future
     */
    function bonusTokensAccrued() external view returns (uint256[] memory);

    /**
     * @notice current bonus supply rate (such as Aave / Comp)
     * @return bonus supply rate per year
     */
    function bonusSupplyRate() external view returns (uint256);

    /**
     * @notice effective supply rate of the RhoStrategy
     * @dev returns the effective supply rate fomr the underlying DeFi protocol
     * taking into account any rewards tokens
     * @return supply rate per year, including yield from reward token if any (in wei)
     */
    function effectiveSupplyRate() external view returns (uint256);

    /**
     * @notice effective supply rate of the RhoStrategy
     * @dev returns the effective supply rate fomr the underlying DeFi protocol
     * taking into account any rewards tokens AND the change in deployed amount.
     * @param delta magnitude of underlying to be deployed / withdrawn
     * @param isPositive true if `delta` is deployed, false if `delta` is withdrawn
     * @return supply rate per year, including yield from reward token if any (in wei)
     */
    function effectiveSupplyRate(uint256 delta, bool isPositive) external view returns (uint256);

    /**
     * @dev Withdraw the amount in underlying from DeFi protocol and transfer to vault
     * @param _amount amount of underlying (in wei) to withdraw
     */
    function withdrawUnderlying(uint256 _amount) external;

    /**
     * @dev Withdraw all underlying from DeFi protocol and transfer to vault
     */
    function withdrawAllCashAvailable() external;

    /**
     * @dev Collect any bonus reward tokens available for the strategy
     */
    function collectRewardTokens(uint256 rewardCollectThreshold) external;

    /**
     * @dev admin function - withdraw random token transfer to this contract
     */
    function sweepERC20Token(address token, address to) external;

    function isLocked() external view returns (bool);

    /**
     * @notice Set the threshold (denominated in reward tokens) over which rewards tokens will automatically
     * be converted into the underlying asset
     * @dev default returns false. Override if the Protocol offers reward token (e.g. COMP for Compound)
     * @param rewardCollectThreshold minimum threshold for collecting reward token
     * @return true if reward in underlying > `rewardCollectThreshold`, false otherwise
     */
    function shouldCollectReward(uint256 rewardCollectThreshold) external view returns (bool);

    /**
     * @notice not all of the funds deployed to a strategy might be available for withdrawal
     * @return the amount of underlying tokens available for withdrawal from the rho strategy
     */
    function underlyingWithdrawable() external view returns (uint256);

    /**
     * @notice Get the deposit token contract address
     * @return address of deposit token contract, or 0 if no deposit token
     */
    function depositToken() external view returns (address);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

/**
 * @title Deposit Token Converter Interface
 * @notice an adapter which unwinds the deposit token and retrieve the underlying tokens
 *
 */
interface IDepositUnwinder {
    event DepositTokenAdded(address depositToken, address underlyingToken);
    event DepositTokenSet(address depositToken, address underlyingToken);
    event DepositTokenRemoved(address depositToken, address underlyingToken);
    event DepositTokenUnwound(address depositToken, address underlyingToken, uint256 amountIn, uint256 amountOut);

    /**
     * @return name of protocol
     */
    function NAME() external view returns (string memory);

    /**
     * @param depositToken address of the deposit token
     * @return address of the corresponding underlying token contract
     */
    function underlyingToken(address depositToken) external view returns (address);

    /**
     * @notice Admin function - add deposit/underlying pair to this contract
     * @param depositTokenAddr the address of the deposit token contract
     * @param underlying the address of the underlying token contract
     */
    function addDepositToken(address depositTokenAddr, address underlying) external;

    /**
     * @notice Admin function - remove deposit/underlying pair to this contract
     * @param depositTokenAddr the address of the deposit token contract
     */
    function removeDepositToken(address depositTokenAddr) external;

    /**
     * @notice Admin function - change deposit/underlying pair to this contract
     * @param depositToken the address of the deposit token contract
     * @param underlying the address of the underlying token contract
     */
    function setDepositToken(address depositToken, address underlying) external;

    // /**
    //  * @notice Get deposit token list
    //  * @return list of deposit tokens address
    //  */

    /**
     * @notice Admin function - withdraw random token transfer to this contract
     * @param token ERC20 token address to be sweeped
     * @param to address for sending sweeped tokens to
     */
    function sweepERC20Token(address token, address to) external;

    /**
     * @notice Get exchange rate of a token to its underlying
     * @param token address of deposit token
     * @return uint256 which is the amount of underlying (after division of decimals)
     */
    function exchangeRate(address token) external view returns (uint256);

    /**
     * @notice A method to sell all input token in this contract into output token.
     * @param token address of deposit token
     * @param beneficiary to receive unwound underlying tokens
     * @return uint256 no. of underlying tokens retrieved
     */
    function unwind(address token, address beneficiary) external returns (uint256);
}