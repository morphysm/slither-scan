// SPDX-License-Identifier: MIT
pragma solidity 0.7.3;

import "../YakStrategyV2.sol";
import "../interfaces/IBenqiUnitroller.sol";
import "../interfaces/IBenqiERC20Delegator.sol";
import "../interfaces/IWAVAX.sol";
import "../interfaces/IERC20.sol";
import "../lib/DexLibrary.sol";
import "../lib/BenqiLibrary.sol";

contract BenqiStrategyV3 is YakStrategyV2 {
    using SafeMath for uint256;

    IBenqiUnitroller private rewardController;
    IBenqiERC20Delegator private tokenDelegator;
    IERC20 private rewardToken0;
    IERC20 private rewardToken1;
    IPair private swapPairToken0;
    IPair private swapPairToken1;
    IWAVAX private constant WAVAX = IWAVAX(0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7);
    uint256 private leverageLevel;
    uint256 private leverageBips;
    uint256 private minMinting;
    uint256 private redeemLimitSafetyMargin;

    constructor(
        string memory _name,
        address _depositToken,
        address _rewardController,
        address _tokenDelegator,
        address _rewardToken0,
        address _rewardToken1,
        address _swapPairToken0,
        address _swapPairToken1,
        address _timelock,
        uint256 _minMinting,
        uint256 _leverageLevel,
        uint256 _leverageBips,
        uint256 _minTokensToReinvest,
        uint256 _devFeeBips,
        uint256 _reinvestRewardBips
    ) {
        name = _name;
        depositToken = IERC20(_depositToken);
        rewardController = IBenqiUnitroller(_rewardController);
        tokenDelegator = IBenqiERC20Delegator(_tokenDelegator);
        rewardToken0 = IERC20(_rewardToken0);
        rewardToken1 = IERC20(_rewardToken1);
        rewardToken = rewardToken1;
        minMinting = _minMinting;
        _updateLeverage(
            _leverageLevel,
            _leverageBips,
            _leverageBips.mul(990).div(1000) //works as long as leverageBips > 1000
        );
        devAddr = 0x2D580F9CF2fB2D09BC411532988F2aFdA4E7BefF;

        _enterMarket();

        assignSwapPairSafely(_swapPairToken0, _swapPairToken1);
        updateMinTokensToReinvest(_minTokensToReinvest);
        updateDevFee(_devFeeBips);
        updateReinvestReward(_reinvestRewardBips);
        updateDepositsEnabled(true);
        transferOwnership(_timelock);

        emit Reinvest(0, 0);
    }

    function totalDeposits() public view override returns (uint256) {
        (, uint256 internalBalance, uint256 borrow, uint256 exchangeRate) = tokenDelegator.getAccountSnapshot(
            address(this)
        );
        return internalBalance.mul(exchangeRate).div(1e18).sub(borrow);
    }

    function _totalDepositsFresh() internal returns (uint256) {
        uint256 borrow = tokenDelegator.borrowBalanceCurrent(address(this));
        uint256 balance = tokenDelegator.balanceOfUnderlying(address(this));
        return balance.sub(borrow);
    }

    function _enterMarket() internal {
        address[] memory tokens = new address[](1);
        tokens[0] = address(tokenDelegator);
        rewardController.enterMarkets(tokens);
    }

    function _updateLeverage(
        uint256 _leverageLevel,
        uint256 _leverageBips,
        uint256 _redeemLimitSafetyMargin
    ) internal {
        leverageLevel = _leverageLevel;
        leverageBips = _leverageBips;
        redeemLimitSafetyMargin = _redeemLimitSafetyMargin;
    }

    function updateLeverage(
        uint256 _leverageLevel,
        uint256 _leverageBips,
        uint256 _redeemLimitSafetyMargin
    ) external onlyDev {
        _updateLeverage(_leverageLevel, _leverageBips, _redeemLimitSafetyMargin);
        uint256 borrowed = tokenDelegator.borrowBalanceCurrent(address(this));
        uint256 balance = tokenDelegator.balanceOfUnderlying(address(this));
        _unrollDebt(balance.sub(borrowed));
        if (balance.sub(borrowed) > 0) {
            _rollupDebt(balance.sub(borrowed), 0);
        }
    }

    /**
     * @notice Initialization helper for Pair deposit tokens
     * @dev Checks that selected Pairs are valid for trading deposit tokens
     * @dev Assigns values to swapPairToken0 and swapPairToken1
     */
    function assignSwapPairSafely(address _swapPairToken0, address _swapPairToken1) private {
        require(_swapPairToken0 > address(0), "Swap pair 0 is necessary but not supplied");
        require(_swapPairToken1 > address(0), "Swap pair 1 is necessary but not supplied");

        require(
            address(rewardToken0) == IPair(address(_swapPairToken0)).token0() ||
                address(rewardToken0) == IPair(address(_swapPairToken0)).token1(),
            "Swap pair 0 does not match rewardToken0"
        );

        require(
            address(rewardToken1) == IPair(address(_swapPairToken0)).token0() ||
                address(rewardToken1) == IPair(address(_swapPairToken0)).token1(),
            "Swap pair 0 does not match rewardToken1"
        );

        require(
            address(depositToken) == IPair(address(_swapPairToken1)).token0() ||
                address(depositToken) == IPair(address(_swapPairToken1)).token1(),
            "Swap pair 1 does not match depositToken"
        );

        require(
            address(rewardToken1) == IPair(address(_swapPairToken1)).token0() ||
                address(rewardToken1) == IPair(address(_swapPairToken1)).token1(),
            "Swap pair 1 does not match rewardToken1"
        );

        swapPairToken0 = IPair(_swapPairToken0);
        swapPairToken1 = IPair(_swapPairToken1);
    }

    /**
     * @notice Approve tokens for use in Strategy
     * @dev Deprecated; approvals should be handled in context of staking
     */
    function setAllowances() public override onlyOwner {
        revert("setAllowances::deprecated");
    }

    function deposit(uint256 amount) external override {
        _deposit(msg.sender, amount);
    }

    function depositWithPermit(
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external override {
        depositToken.permit(msg.sender, address(this), amount, deadline, v, r, s);
        _deposit(msg.sender, amount);
    }

    function depositFor(address account, uint256 amount) external override {
        _deposit(account, amount);
    }

    function _deposit(address account, uint256 amount) private onlyAllowedDeposits {
        require(DEPOSITS_ENABLED == true, "BenqiStrategyV3::_deposit");
        if (MAX_TOKENS_TO_DEPOSIT_WITHOUT_REINVEST > 0) {
            uint256 totalAvaxRewards = checkReward();
            if (totalAvaxRewards > MAX_TOKENS_TO_DEPOSIT_WITHOUT_REINVEST) {
                _reinvest(true);
            }
        }
        require(depositToken.transferFrom(msg.sender, address(this), amount), "BenqiStrategyV3::transfer failed");
        uint256 depositTokenAmount = amount;
        uint256 balance = _totalDepositsFresh();
        if (totalSupply.mul(balance) > 0) {
            depositTokenAmount = amount.mul(totalSupply).div(balance);
        }
        _mint(account, depositTokenAmount);
        _stakeDepositTokens(amount);
        emit Deposit(account, amount);
    }

    function withdraw(uint256 amount) external override {
        uint256 depositTokenAmount = _totalDepositsFresh().mul(amount).div(totalSupply);
        require(depositTokenAmount > 0, "BenqiStrategyV3::withdraw");
        _burn(msg.sender, amount);
        _withdrawDepositTokens(depositTokenAmount);
        _safeTransfer(address(depositToken), msg.sender, depositTokenAmount);
        emit Withdraw(msg.sender, depositTokenAmount);
    }

    function _withdrawDepositTokens(uint256 amount) private {
        _unrollDebt(amount);
        require(tokenDelegator.redeemUnderlying(amount) == 0, "BenqiStrategyV3::failed to redeem");
    }

    function reinvest() external override onlyEOA {
        _reinvest(false);
    }

    receive() external payable {
        require(msg.sender == address(rewardController), "BenqiStrategyV3::payments not allowed");
    }

    /**
     * @notice Reinvest rewards from staking contract to deposit tokens
     */
    function _reinvest(bool userDeposit) private {
        address[] memory markets = new address[](1);
        markets[0] = address(tokenDelegator);
        rewardController.claimReward(0, address(this), markets);
        rewardController.claimReward(1, address(this), markets);

        uint256 avaxBalance = address(this).balance;
        if (avaxBalance > 0) {
            WAVAX.deposit{value: avaxBalance}();
        }

        uint256 qiBalance = rewardToken0.balanceOf(address(this));
        if (qiBalance > 0) {
            DexLibrary.swap(qiBalance, address(rewardToken0), address(rewardToken1), swapPairToken0);
        }

        uint256 amount = rewardToken.balanceOf(address(this));
        if (!userDeposit) {
            require(amount >= MIN_TOKENS_TO_REINVEST, "BenqiStrategyV3::reinvest");
        }

        uint256 devFee = amount.mul(DEV_FEE_BIPS).div(BIPS_DIVISOR);
        if (devFee > 0) {
            _safeTransfer(address(rewardToken), devAddr, devFee);
        }

        uint256 reinvestFee = amount.mul(REINVEST_REWARD_BIPS).div(BIPS_DIVISOR);
        if (reinvestFee > 0) {
            _safeTransfer(address(rewardToken), msg.sender, reinvestFee);
        }

        uint256 depositTokenAmount = DexLibrary.swap(
            amount.sub(devFee).sub(reinvestFee),
            address(rewardToken),
            address(depositToken),
            swapPairToken1
        );

        _stakeDepositTokens(depositTokenAmount);

        emit Reinvest(totalDeposits(), totalSupply);
    }

    function _rollupDebt(uint256 principal, uint256 borrowed) internal {
        (uint256 borrowLimit, uint256 borrowBips) = _getBorrowLimit();
        uint256 supplied = principal;
        uint256 lendTarget = principal.sub(borrowed).mul(leverageLevel).div(leverageBips);
        uint256 totalBorrowed = borrowed;
        depositToken.approve(address(tokenDelegator), lendTarget);
        while (supplied < lendTarget) {
            uint256 toBorrowAmount = _getBorrowable(supplied, totalBorrowed, borrowLimit, borrowBips);
            if (supplied.add(toBorrowAmount) > lendTarget) {
                toBorrowAmount = lendTarget.sub(supplied);
            }
            // safeguard needed because we can't mint below a certain threshold
            if (toBorrowAmount < minMinting) {
                break;
            }
            require(tokenDelegator.borrow(toBorrowAmount) == 0, "BenqiStrategyV3::borrowing failed");
            require(tokenDelegator.mint(toBorrowAmount) == 0, "BenqiStrategyV3::lending failed");
            supplied = tokenDelegator.balanceOfUnderlying(address(this));
            totalBorrowed = totalBorrowed.add(toBorrowAmount);
        }
        depositToken.approve(address(tokenDelegator), 0);
    }

    function _getRedeemable(
        uint256 balance,
        uint256 borrowed,
        uint256 borrowLimit,
        uint256 bips
    ) internal view returns (uint256) {
        return balance.sub(borrowed.mul(bips).div(borrowLimit)).mul(redeemLimitSafetyMargin).div(leverageBips);
    }

    function _getBorrowable(
        uint256 balance,
        uint256 borrowed,
        uint256 borrowLimit,
        uint256 bips
    ) internal pure returns (uint256) {
        return balance.mul(borrowLimit).div(bips).sub(borrowed);
    }

    function _getBorrowLimit() internal view returns (uint256, uint256) {
        (, uint256 borrowLimit) = rewardController.markets(address(tokenDelegator));
        return (borrowLimit, 1e18);
    }

    function _unrollDebt(uint256 amountToBeFreed) internal {
        uint256 borrowed = tokenDelegator.borrowBalanceCurrent(address(this));
        uint256 balance = tokenDelegator.balanceOfUnderlying(address(this));
        uint256 targetBorrow = balance.sub(borrowed).sub(amountToBeFreed).mul(leverageLevel).div(leverageBips).sub(
            balance.sub(borrowed).sub(amountToBeFreed)
        );
        uint256 toRepay = borrowed.sub(targetBorrow);
        (uint256 borrowLimit, uint256 borrowBips) = _getBorrowLimit();
        depositToken.approve(address(tokenDelegator), borrowed);
        while (toRepay > 0) {
            uint256 unrollAmount = _getRedeemable(balance, borrowed, borrowLimit, borrowBips);
            if (unrollAmount > toRepay) {
                unrollAmount = toRepay;
            }
            require(tokenDelegator.redeemUnderlying(unrollAmount) == 0, "BenqiStrategyV3::failed to redeem");
            require(tokenDelegator.repayBorrow(unrollAmount) == 0, "BenqiStrategyV3::failed to repay borrow");
            balance = tokenDelegator.balanceOfUnderlying(address(this));
            borrowed = tokenDelegator.borrowBalanceCurrent(address(this));
            if (targetBorrow >= borrowed) {
                break;
            }
            toRepay = borrowed.sub(targetBorrow);
        }
        depositToken.approve(address(tokenDelegator), 0);
    }

    function _stakeDepositTokens(uint256 amount) private {
        require(amount > 0, "BenqiStrategyV3::_stakeDepositTokens");
        depositToken.approve(address(tokenDelegator), amount);
        require(tokenDelegator.mint(amount) == 0, "BenqiStrategyV3::Deposit failed");
        depositToken.approve(address(tokenDelegator), 0);
        uint256 borrowed = tokenDelegator.borrowBalanceCurrent(address(this));
        uint256 principal = tokenDelegator.balanceOfUnderlying(address(this));
        _rollupDebt(principal, borrowed);
    }

    /**
     * @notice Safely transfer using an anonymous ERC20 token
     * @dev Requires token to return true on transfer
     * @param token address
     * @param to recipient address
     * @param value amount
     */
    function _safeTransfer(
        address token,
        address to,
        uint256 value
    ) private {
        require(IERC20(token).transfer(to, value), "BenqiStrategyV3::TRANSFER_FROM_FAILED");
    }

    function checkReward() public view override returns (uint256) {
        uint256 qiRewards = BenqiLibrary.calculateReward(rewardController, tokenDelegator, 0, address(this));
        uint256 avaxRewards = BenqiLibrary.calculateReward(rewardController, tokenDelegator, 1, address(this));

        uint256 qiAsWavax = DexLibrary.estimateConversionThroughPair(
            qiRewards,
            address(rewardToken0),
            address(rewardToken1),
            swapPairToken0
        );
        return avaxRewards.add(qiAsWavax);
    }

    function getActualLeverage() public view returns (uint256) {
        (, uint256 internalBalance, uint256 borrow, uint256 exchangeRate) = tokenDelegator.getAccountSnapshot(
            address(this)
        );
        uint256 balance = internalBalance.mul(exchangeRate).div(1e18);
        return balance.mul(1e18).div(balance.sub(borrow));
    }

    function estimateDeployedBalance() external view override returns (uint256) {
        return totalDeposits();
    }

    function rescueDeployedFunds(
        uint256 minReturnAmountAccepted,
        bool /*disableDeposits*/
    ) external override onlyOwner {
        uint256 balanceBefore = depositToken.balanceOf(address(this));
        uint256 borrowed = tokenDelegator.borrowBalanceCurrent(address(this));
        uint256 balance = tokenDelegator.balanceOfUnderlying(address(this));
        _unrollDebt(balance.sub(borrowed));
        tokenDelegator.redeemUnderlying(tokenDelegator.balanceOfUnderlying(address(this)));
        uint256 balanceAfter = depositToken.balanceOf(address(this));
        require(balanceAfter.sub(balanceBefore) >= minReturnAmountAccepted, "BenqiStrategyV3::rescueDeployedFunds");
        emit Reinvest(totalDeposits(), totalSupply);
        if (DEPOSITS_ENABLED == true) {
            updateDepositsEnabled(false);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.3;

import "./lib/SafeMath.sol";
import "./lib/Ownable.sol";
import "./lib/Permissioned.sol";
import "./interfaces/IERC20.sol";
import "./YakERC20.sol";

/**
 * @notice YakStrategy should be inherited by new strategies
 */
abstract contract YakStrategyV2 is YakERC20, Ownable, Permissioned {
    using SafeMath for uint;


    IERC20 public depositToken;
    IERC20 public rewardToken;
    address public devAddr;

    uint public MIN_TOKENS_TO_REINVEST;
    uint public MAX_TOKENS_TO_DEPOSIT_WITHOUT_REINVEST;
    bool public DEPOSITS_ENABLED;

    uint public REINVEST_REWARD_BIPS;
    uint public ADMIN_FEE_BIPS;
    uint public DEV_FEE_BIPS;

    uint constant internal BIPS_DIVISOR = 10000;
    uint constant internal MAX_UINT = uint(-1);

    event Deposit(address indexed account, uint amount);
    event Withdraw(address indexed account, uint amount);
    event Reinvest(uint newTotalDeposits, uint newTotalSupply);
    event Recovered(address token, uint amount);
    event UpdateAdminFee(uint oldValue, uint newValue);
    event UpdateDevFee(uint oldValue, uint newValue);
    event UpdateReinvestReward(uint oldValue, uint newValue);
    event UpdateMinTokensToReinvest(uint oldValue, uint newValue);
    event UpdateMaxTokensToDepositWithoutReinvest(uint oldValue, uint newValue);
    event UpdateDevAddr(address oldValue, address newValue);
    event DepositsEnabled(bool newValue);

    /**
     * @notice Throws if called by smart contract
     */
    modifier onlyEOA() {
        require(tx.origin == msg.sender, "YakStrategy::onlyEOA");
        _;
    }

    /**
     * @notice Only called by dev
     */
    modifier onlyDev() {
        require(msg.sender == devAddr, "YakStrategy::onlyDev");
        _;
    }

    /**
     * @notice Approve tokens for use in Strategy
     * @dev Should use modifier `onlyOwner` to avoid griefing
     */
    function setAllowances() public virtual;

    /**
     * @notice Revoke token allowance
     * @param token address
     * @param spender address
     */
    function revokeAllowance(address token, address spender) external onlyOwner {
        require(IERC20(token).approve(spender, 0));
    }

    /**
     * @notice Deposit and deploy deposits tokens to the strategy
     * @dev Must mint receipt tokens to `msg.sender`
     * @param amount deposit tokens
     */
    function deposit(uint amount) external virtual;

    /**
    * @notice Deposit using Permit
    * @dev Should revert for tokens without Permit
    * @param amount Amount of tokens to deposit
    * @param deadline The time at which to expire the signature
    * @param v The recovery byte of the signature
    * @param r Half of the ECDSA signature pair
    * @param s Half of the ECDSA signature pair
    */
    function depositWithPermit(uint amount, uint deadline, uint8 v, bytes32 r, bytes32 s) external virtual;

    /**
     * @notice Deposit on behalf of another account
     * @dev Must mint receipt tokens to `account`
     * @param account address to receive receipt tokens
     * @param amount deposit tokens
     */
    function depositFor(address account, uint amount) external virtual;

    /**
     * @notice Redeem receipt tokens for deposit tokens
     * @param amount receipt tokens
     */
    function withdraw(uint amount) external virtual;

    /**
     * @notice Reinvest reward tokens into deposit tokens
     */
    function reinvest() external virtual;

    /**
     * @notice Estimate reinvest reward
     * @return reward tokens
     */
    function estimateReinvestReward() external view returns (uint) {
        uint unclaimedRewards = checkReward();
        if (unclaimedRewards >= MIN_TOKENS_TO_REINVEST) {
            return unclaimedRewards.mul(REINVEST_REWARD_BIPS).div(BIPS_DIVISOR);
        }
        return 0;
    }

    /**
     * @notice Reward tokens avialable to strategy, including balance
     * @return reward tokens
     */
    function checkReward() public virtual view returns (uint);

    /**
     * @notice Estimated deposit token balance deployed by strategy, excluding balance
     * @return deposit tokens
     */
    function estimateDeployedBalance() external virtual view returns (uint);

    /**
     * @notice Rescue all available deployed deposit tokens back to Strategy
     * @param minReturnAmountAccepted min deposit tokens to receive
     * @param disableDeposits bool
     */
    function rescueDeployedFunds(uint minReturnAmountAccepted, bool disableDeposits) external virtual;

    /**
     * @notice This function returns a snapshot of last available quotes
     * @return total deposits available on the contract
     */
    function totalDeposits() public virtual view returns (uint);
    /**
     * @notice Calculate receipt tokens for a given amount of deposit tokens
     * @dev If contract is empty, use 1:1 ratio
     * @dev Could return zero shares for very low amounts of deposit tokens
     * @param amount deposit tokens
     * @return receipt tokens
     */
    function getSharesForDepositTokens(uint amount) public view returns (uint) {
        if (totalSupply.mul(totalDeposits()) == 0) {
            return amount;
        }
        return amount.mul(totalSupply).div(totalDeposits());
    }

    /**
     * @notice Calculate deposit tokens for a given amount of receipt tokens
     * @param amount receipt tokens
     * @return deposit tokens
     */
    function getDepositTokensForShares(uint amount) public view returns (uint) {
        if (totalSupply.mul(totalDeposits()) == 0) {
            return 0;
        }
        return amount.mul(totalDeposits()).div(totalSupply);
    }

    /**
     * @notice Update reinvest min threshold
     * @param newValue threshold
     */
    function updateMinTokensToReinvest(uint newValue) public onlyOwner {
        emit UpdateMinTokensToReinvest(MIN_TOKENS_TO_REINVEST, newValue);
        MIN_TOKENS_TO_REINVEST = newValue;
    }

    /**
     * @notice Update reinvest max threshold before a deposit
     * @param newValue threshold
     */
    function updateMaxTokensToDepositWithoutReinvest(uint newValue) public onlyOwner {
        emit UpdateMaxTokensToDepositWithoutReinvest(MAX_TOKENS_TO_DEPOSIT_WITHOUT_REINVEST, newValue);
        MAX_TOKENS_TO_DEPOSIT_WITHOUT_REINVEST = newValue;
    }

    /**
     * @notice Update developer fee
     * @param newValue fee in BIPS
     */
    function updateDevFee(uint newValue) public onlyOwner {
        require(newValue.add(ADMIN_FEE_BIPS).add(REINVEST_REWARD_BIPS) <= BIPS_DIVISOR);
        emit UpdateDevFee(DEV_FEE_BIPS, newValue);
        DEV_FEE_BIPS = newValue;
    }

    /**
     * @notice Update admin fee
     * @param newValue fee in BIPS
     */
    function updateAdminFee(uint newValue) public onlyOwner {
        require(newValue.add(DEV_FEE_BIPS).add(REINVEST_REWARD_BIPS) <= BIPS_DIVISOR);
        emit UpdateAdminFee(ADMIN_FEE_BIPS, newValue);
        ADMIN_FEE_BIPS = newValue;
    }

    /**
     * @notice Update reinvest reward
     * @param newValue fee in BIPS
     */
    function updateReinvestReward(uint newValue) public onlyOwner {
        require(newValue.add(ADMIN_FEE_BIPS).add(DEV_FEE_BIPS) <= BIPS_DIVISOR);
        emit UpdateReinvestReward(REINVEST_REWARD_BIPS, newValue);
        REINVEST_REWARD_BIPS = newValue;
    }

    /**
     * @notice Enable/disable deposits
     * @param newValue bool
     */
    function updateDepositsEnabled(bool newValue) public onlyOwner {
        require(DEPOSITS_ENABLED != newValue);
        DEPOSITS_ENABLED = newValue;
        emit DepositsEnabled(newValue);
    }

    /**
     * @notice Update devAddr
     * @param newValue address
     */
    function updateDevAddr(address newValue) public onlyDev {
        emit UpdateDevAddr(devAddr, newValue);
        devAddr = newValue;
    }

    /**
     * @notice Recover ERC20 from contract
     * @param tokenAddress token address
     * @param tokenAmount amount to recover
     */
    function recoverERC20(address tokenAddress, uint tokenAmount) external onlyOwner {
        require(tokenAmount > 0);
        require(IERC20(tokenAddress).transfer(msg.sender, tokenAmount));
        emit Recovered(tokenAddress, tokenAmount);
    }

    /**
     * @notice Recover AVAX from contract
     * @param amount amount
     */
    function recoverAVAX(uint amount) external onlyOwner {
        require(amount > 0);
        msg.sender.transfer(amount);
        emit Recovered(address(0), amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.3;

interface IBenqiUnitroller {
    function enterMarkets(address[] memory cTokens) external returns (uint256[] memory);

    function exitMarket(address cTokenAddress) external returns (uint256);

    function mintAllowed(
        address cToken,
        address minter,
        uint256 mintAmount
    ) external returns (uint256);

    function redeemAllowed(
        address cToken,
        address redeemer,
        uint256 redeemTokens
    ) external returns (uint256);

    function borrowAllowed(
        address cToken,
        address borrower,
        uint256 borrowAmount
    ) external returns (uint256);

    function claimReward(uint8 rewardType, address holder) external; //reward type 0 is qi, 1 is avax

    function claimReward(
        uint8 rewardType,
        address holder,
        address[] memory qiTokens
    ) external; //reward type 0 is qi, 1 is avax

    function rewardAccrued(uint8 rewardType, address holder) external view returns (uint256);

    function markets(address cTokenAddress) external view returns (bool, uint256);

    function getClaimableRewards(uint256 rewardToken) external view returns (uint256, uint256);

    function rewardSupplyState(uint8 rewardType, address holder)
        external
        view
        returns (uint224 index, uint32 timestamp);

    function supplyRewardSpeeds(uint8 rewardType, address qiToken) external view returns (uint256);

    function borrowRewardSpeeds(uint8 rewardType, address qiToken) external view returns (uint256);

    function rewardBorrowState(uint8 rewardType, address holder)
        external
        view
        returns (uint224 index, uint32 timestamp);

    function rewardSupplierIndex(
        uint8 rewardType,
        address qiContractAddress,
        address holder
    ) external view returns (uint256 supplierIndex);

    function rewardBorrowerIndex(
        uint8 rewardType,
        address qiContractAddress,
        address holder
    ) external view returns (uint256 borrowerIndex);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.3;

import "./IERC20.sol";

interface IBenqiERC20Delegator is IERC20 {
    function exchangeRateStored() external view returns (uint256);

    function exchangeRateCurrent() external returns (uint256);

    function mint(uint256 mintAmount) external returns (uint256);

    function redeem(uint256 redeemTokens) external returns (uint256);

    function redeemUnderlying(uint256 redeemAmount) external returns (uint256);

    function borrow(uint256 borrowAmount) external returns (uint256);

    function repayBorrow(uint256 repayAmount) external returns (uint256);

    function totalBorrows() external view returns (uint256);

    function borrowIndex() external view returns (uint256);

    function balanceOfUnderlying(address owner) external returns (uint256);

    function borrowBalanceCurrent(address owner) external returns (uint256);

    function borrowBalanceStored(address owner) external view returns (uint256);

    function getAccountSnapshot(address account)
        external
        view
        returns (
            uint256 error,
            uint256 balance,
            uint256 borrow,
            uint256 mantissa
        );

    function getCash() external returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.3;

interface IWAVAX {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function balanceOf(address owner) external view returns (uint); 
    function withdraw(uint) external;
    function approve(address to, uint value) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.3;

interface IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.3;

import "./SafeMath.sol";
import "../interfaces/IPair.sol";
import "../interfaces/IWAVAX.sol";

library DexLibrary {
    using SafeMath for uint;
    bytes private constant zeroBytes = new bytes(0);
    IWAVAX private constant WAVAX = IWAVAX(0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7);

    /**
     * @notice Swap directly through a Pair
     * @param amountIn input amount
     * @param fromToken address
     * @param toToken address
     * @param pair Pair used for swap
     * @return output amount
     */
    function swap(uint amountIn, address fromToken, address toToken, IPair pair) internal returns (uint) {
        (address token0,) = sortTokens(fromToken, toToken);
        (uint112 reserve0, uint112 reserve1,) = pair.getReserves();
        if (token0 != fromToken) (reserve0, reserve1) = (reserve1, reserve0);
        uint amountOut1 = 0;
        uint amountOut2 = getAmountOut(amountIn, reserve0, reserve1);
        if (token0 != fromToken) (amountOut1, amountOut2) = (amountOut2, amountOut1);
        safeTransfer(fromToken, address(pair), amountIn);
        pair.swap(amountOut1, amountOut2, address(this), zeroBytes);
        return amountOut2 > amountOut1 ? amountOut2 : amountOut1;
    }

    function checkSwapPairCompatibility(IPair pair, address tokenA, address tokenB) internal pure returns (bool) {
        return (tokenA == pair.token0() || tokenA == pair.token1()) && (tokenB == pair.token0() || tokenB == pair.token1()) && tokenA != tokenB;
    }

    function estimateConversionThroughPair(uint amountIn, address fromToken, address toToken, IPair swapPair) internal view returns (uint) {
        (address token0,) = sortTokens(fromToken, toToken);
        (uint112 reserve0, uint112 reserve1,) = swapPair.getReserves();
        if (token0 != fromToken) (reserve0, reserve1) = (reserve1, reserve0);
        return getAmountOut(amountIn, reserve0, reserve1);
    }

    /**
     * @notice Converts reward tokens to deposit tokens
     * @dev No price checks enforced
     * @param amount reward tokens
     * @return deposit tokens
     */
    function convertRewardTokensToDepositTokens(uint amount, address rewardToken, address depositToken, IPair swapPairToken0, IPair swapPairToken1) internal returns (uint) {
        uint amountIn = amount.div(2);
        require(amountIn > 0, "DexLibrary::_convertRewardTokensToDepositTokens");

        address token0 = IPair(depositToken).token0();
        uint amountOutToken0 = amountIn;
        if (rewardToken != token0) {
            amountOutToken0 = DexLibrary.swap(amountIn, rewardToken, token0, swapPairToken0);
        }

        address token1 = IPair(depositToken).token1();
        uint amountOutToken1 = amountIn;
        if (rewardToken != token1) {
            amountOutToken1 = DexLibrary.swap(amountIn, rewardToken, token1, swapPairToken1);
        }

        return DexLibrary.addLiquidity(depositToken, amountOutToken0, amountOutToken1);
    }

    /**
     * @notice Add liquidity directly through a Pair
     * @dev Checks adding the max of each token amount
     * @param depositToken address
     * @param maxAmountIn0 amount token0
     * @param maxAmountIn1 amount token1
     * @return liquidity tokens
     */
    function addLiquidity(address depositToken, uint maxAmountIn0, uint maxAmountIn1) internal returns (uint) {
        (uint112 reserve0, uint112 reserve1,) = IPair(address(depositToken)).getReserves();
        uint amountIn1 = _quoteLiquidityAmountOut(maxAmountIn0, reserve0, reserve1);
        if (amountIn1 > maxAmountIn1) {
            amountIn1 = maxAmountIn1;
            maxAmountIn0 = _quoteLiquidityAmountOut(maxAmountIn1, reserve1, reserve0);
        }

        safeTransfer(IPair(depositToken).token0(), depositToken, maxAmountIn0);
        safeTransfer(IPair(depositToken).token1(), depositToken, amountIn1);
        return IPair(depositToken).mint(address(this));
    }

    /**
     * @notice Quote liquidity amount out
     * @param amountIn input tokens
     * @param reserve0 size of input asset reserve
     * @param reserve1 size of output asset reserve
     * @return liquidity tokens
     */
    function _quoteLiquidityAmountOut(uint amountIn, uint reserve0, uint reserve1) private pure returns (uint) {
        return amountIn.mul(reserve1).div(reserve0);
    }

    /**
     * @notice Given two tokens, it'll return the tokens in the right order for the tokens pair
     * @dev TokenA must be different from TokenB, and both shouldn't be address(0), no validations
     * @param tokenA address
     * @param tokenB address
     * @return sorted tokens
     */
    function sortTokens(address tokenA, address tokenB) internal pure returns (address, address) {
        return tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
    }

    /**
     * @notice Given an input amount of an asset and pair reserves, returns maximum output amount of the other asset
     * @dev Assumes swap fee is 0.30%
     * @param amountIn input asset
     * @param reserveIn size of input asset reserve
     * @param reserveOut size of output asset reserve
     * @return maximum output amount
     */
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint) {
        uint amountInWithFee = amountIn.mul(997);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        return numerator.div(denominator);
    }

    /**
     * @notice Safely transfer using an anonymous ERC20 token
     * @dev Requires token to return true on transfer
     * @param token address
     * @param to recipient address
     * @param value amount
     */
    function safeTransfer(address token, address to, uint256 value) internal {
        require(IERC20(token).transfer(to, value), "DexLibrary::TRANSFER_FROM_FAILED");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.3;

import "./SafeMath.sol";
import "./Exponential.sol";
import "../interfaces/IBenqiUnitroller.sol";
import "../interfaces/IBenqiERC20Delegator.sol";

library BenqiLibrary {
    using SafeMath for uint256;

    function calculateReward(
        IBenqiUnitroller rewardController,
        IBenqiERC20Delegator tokenDelegator,
        uint8 tokenIndex,
        address account
    ) internal view returns (uint256) {
        uint256 rewardAccrued = rewardController.rewardAccrued(tokenIndex, account);
        return
            rewardAccrued.add(supplyAccrued(rewardController, tokenDelegator, tokenIndex, account)).add(
                borrowAccrued(rewardController, tokenDelegator, tokenIndex, account)
            );
    }

    function supplyAccrued(
        IBenqiUnitroller rewardController,
        IBenqiERC20Delegator tokenDelegator,
        uint8 tokenIndex,
        address account
    ) internal view returns (uint256) {
        Exponential.Double memory supplyIndex = Exponential.Double({
            mantissa: _supplyIndex(rewardController, tokenDelegator, tokenIndex)
        });
        Exponential.Double memory supplierIndex = Exponential.Double({
            mantissa: rewardController.rewardSupplierIndex(tokenIndex, address(tokenDelegator), account)
        });

        if (supplierIndex.mantissa == 0 && supplyIndex.mantissa > 0) {
            supplierIndex.mantissa = 1e36;
        }
        Exponential.Double memory deltaIndex = supplyIndex.mantissa > 0
            ? Exponential.sub_(supplyIndex, supplierIndex)
            : Exponential.Double({mantissa: 0});
        return Exponential.mul_(tokenDelegator.balanceOf(account), deltaIndex);
    }

    function borrowAccrued(
        IBenqiUnitroller rewardController,
        IBenqiERC20Delegator tokenDelegator,
        uint8 tokenIndex,
        address account
    ) internal view returns (uint256 borrowAccrued_) {
        Exponential.Double memory borrowerIndex = Exponential.Double({
            mantissa: rewardController.rewardBorrowerIndex(tokenIndex, address(tokenDelegator), account)
        });
        borrowAccrued_ = 0;
        if (borrowerIndex.mantissa > 0) {
            Exponential.Exp memory marketBorrowIndex = Exponential.Exp({mantissa: tokenDelegator.borrowIndex()});
            Exponential.Double memory borrowIndex = Exponential.Double({
                mantissa: _borrowIndex(rewardController, tokenDelegator, tokenIndex, marketBorrowIndex)
            });
            if (borrowIndex.mantissa > 0) {
                Exponential.Double memory deltaIndex = Exponential.sub_(borrowIndex, borrowerIndex);
                uint256 borrowerAmount = Exponential.div_(
                    tokenDelegator.borrowBalanceStored(address(this)),
                    marketBorrowIndex
                );
                borrowAccrued_ = Exponential.mul_(borrowerAmount, deltaIndex);
            }
        }
    }

    function _supplyIndex(
        IBenqiUnitroller rewardController,
        IBenqiERC20Delegator tokenDelegator,
        uint8 rewardType
    ) private view returns (uint224) {
        (uint224 supplyStateIndex, uint256 supplyStateTimestamp) = rewardController.rewardSupplyState(
            rewardType,
            address(tokenDelegator)
        );

        uint256 supplySpeed = rewardController.supplyRewardSpeeds(rewardType, address(tokenDelegator));
        uint256 deltaTimestamps = Exponential.sub_(block.timestamp, uint256(supplyStateTimestamp));
        if (deltaTimestamps > 0 && supplySpeed > 0) {
            uint256 supplyTokens = IERC20(tokenDelegator).totalSupply();
            uint256 qiAccrued = Exponential.mul_(deltaTimestamps, supplySpeed);
            Exponential.Double memory ratio = supplyTokens > 0
                ? Exponential.fraction(qiAccrued, supplyTokens)
                : Exponential.Double({mantissa: 0});
            Exponential.Double memory index = Exponential.add_(Exponential.Double({mantissa: supplyStateIndex}), ratio);
            return Exponential.safe224(index.mantissa, "new index exceeds 224 bits");
        }
        return 0;
    }

    function _borrowIndex(
        IBenqiUnitroller rewardController,
        IBenqiERC20Delegator tokenDelegator,
        uint8 rewardType,
        Exponential.Exp memory marketBorrowIndex
    ) private view returns (uint224) {
        (uint224 borrowStateIndex, uint256 borrowStateTimestamp) = rewardController.rewardBorrowState(
            rewardType,
            address(tokenDelegator)
        );
        uint256 borrowSpeed = rewardController.borrowRewardSpeeds(rewardType, address(tokenDelegator));
        uint256 deltaTimestamps = Exponential.sub_(block.timestamp, uint256(borrowStateTimestamp));
        if (deltaTimestamps > 0 && borrowSpeed > 0) {
            uint256 borrowAmount = Exponential.div_(tokenDelegator.totalBorrows(), marketBorrowIndex);
            uint256 qiAccrued = Exponential.mul_(deltaTimestamps, borrowSpeed);
            Exponential.Double memory ratio = borrowAmount > 0
                ? Exponential.fraction(qiAccrued, borrowAmount)
                : Exponential.Double({mantissa: 0});
            Exponential.Double memory index = Exponential.add_(Exponential.Double({mantissa: borrowStateIndex}), ratio);
            return Exponential.safe224(index.mantissa, "new index exceeds 224 bits");
        }
        return 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.3;

// From https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/math/Math.sol
// Subject to the MIT license.

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting with custom message on overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, errorMessage);

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on underflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot underflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction underflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on underflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot underflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, errorMessage);

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers.
     * Reverts on division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers.
     * Reverts with custom message on division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.3;

import "./Context.sol";

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
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.3;

import "./Ownable.sol";
import "./SafeMath.sol";

abstract contract Permissioned is Ownable {
    using SafeMath for uint;

    uint public numberOfAllowedDepositors;
    mapping(address => bool) public allowedDepositors;

    event AllowDepositor(address indexed account);
    event RemoveDepositor(address indexed account);

    modifier onlyAllowedDeposits() {
        if (numberOfAllowedDepositors > 0) {
            require(allowedDepositors[msg.sender] == true, "Permissioned::onlyAllowedDeposits, not allowed");
        }
        _;
    }

    /**
     * @notice Add an allowed depositor
     * @param depositor address
     */
    function allowDepositor(address depositor) external onlyOwner {
        require(allowedDepositors[depositor] == false, "Permissioned::allowDepositor");
        allowedDepositors[depositor] = true;
        numberOfAllowedDepositors = numberOfAllowedDepositors.add(1);
        emit AllowDepositor(depositor);
    }

    /**
     * @notice Remove an allowed depositor
     * @param depositor address
     */
    function removeDepositor(address depositor) external onlyOwner {
        require(numberOfAllowedDepositors > 0, "Permissioned::removeDepositor, no allowed depositors");
        require(allowedDepositors[depositor] == true, "Permissioned::removeDepositor, not allowed");
        allowedDepositors[depositor] = false;
        numberOfAllowedDepositors = numberOfAllowedDepositors.sub(1);
        emit RemoveDepositor(depositor);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.3;
pragma experimental ABIEncoderV2;

import "./lib/SafeMath.sol";
import "./interfaces/IERC20.sol";

abstract contract YakERC20 {
    using SafeMath for uint256;

    string public name = "Yield Yak";
    string public symbol = "YRT";
    uint8 public constant decimals = 18;
    uint256 public totalSupply;
  
    mapping (address => mapping (address => uint256)) internal allowances;
    mapping (address => uint256) internal balances;

    /// @dev keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)")
    bytes32 public constant DOMAIN_TYPEHASH = 0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f;

    /// @dev keccak256("1");
    bytes32 public constant VERSION_HASH = 0xc89efdaa54c0f20c7adf612882df0950f5a951637e0307cdcb4c672f298b8bc6;

    /// @dev keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;

    mapping(address => uint) public nonces;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor() {}

    /**
     * @notice Get the number of tokens `spender` is approved to spend on behalf of `account`
     * @param account The address of the account holding the funds
     * @param spender The address of the account spending the funds
     * @return The number of tokens approved
     */
    function allowance(address account, address spender) external view returns (uint) {
        return allowances[account][spender];
    }

    /**
     * @notice Approve `spender` to transfer up to `amount` from `src`
     * @dev This will overwrite the approval amount for `spender`
     * and is subject to issues noted [here](https://eips.ethereum.org/EIPS/eip-20#approve)
     * It is recommended to use increaseAllowance and decreaseAllowance instead
     * @param spender The address of the account which may transfer tokens
     * @param amount The number of tokens that are approved (2^256-1 means infinite)
     * @return Whether or not the approval succeeded
     */
    function approve(address spender, uint256 amount) external returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    /**
     * @notice Get the number of tokens held by the `account`
     * @param account The address of the account to get the balance of
     * @return The number of tokens held
     */
    function balanceOf(address account) external view returns (uint) {
        return balances[account];
    }

    /**
     * @notice Transfer `amount` tokens from `msg.sender` to `dst`
     * @param dst The address of the destination account
     * @param amount The number of tokens to transfer
     * @return Whether or not the transfer succeeded
     */
    function transfer(address dst, uint256 amount) external returns (bool) {
        _transferTokens(msg.sender, dst, amount);
        return true;
    }

    /**
     * @notice Transfer `amount` tokens from `src` to `dst`
     * @param src The address of the source account
     * @param dst The address of the destination account
     * @param amount The number of tokens to transfer
     * @return Whether or not the transfer succeeded
     */
    function transferFrom(address src, address dst, uint256 amount) external returns (bool) {
        address spender = msg.sender;
        uint256 spenderAllowance = allowances[src][spender];

        if (spender != src && spenderAllowance != uint256(-1)) {
            uint256 newAllowance = spenderAllowance.sub(amount, "transferFrom: transfer amount exceeds allowance");
            allowances[src][spender] = newAllowance;

            emit Approval(src, spender, newAllowance);
        }

        _transferTokens(src, dst, amount);
        return true;
    }


    /**
     * @notice Approval implementation
     * @param owner The address of the account which owns tokens
     * @param spender The address of the account which may transfer tokens
     * @param amount The number of tokens that are approved (2^256-1 means infinite)
     */
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "_approve::owner zero address");
        require(spender != address(0), "_approve::spender zero address");
        allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @notice Transfer implementation
     * @param from The address of the account which owns tokens
     * @param to The address of the account which is receiving tokens
     * @param value The number of tokens that are being transferred
     */
    function _transferTokens(address from, address to, uint256 value) internal {
        require(to != address(0), "_transferTokens: cannot transfer to the zero address");

        balances[from] = balances[from].sub(value, "_transferTokens: transfer exceeds from balance");
        balances[to] = balances[to].add(value);
        emit Transfer(from, to, value);
    }

    function _mint(address to, uint256 value) internal {
        totalSupply = totalSupply.add(value);
        balances[to] = balances[to].add(value);
        emit Transfer(address(0), to, value);
    }

    function _burn(address from, uint256 value) internal {
        balances[from] = balances[from].sub(value, "_burn: burn amount exceeds from balance");
        totalSupply = totalSupply.sub(value, "_burn: burn amount exceeds total supply");
        emit Transfer(from, address(0), value);
    }

    /**
     * @notice Triggers an approval from owner to spender
     * @param owner The address to approve from
     * @param spender The address to be approved
     * @param value The number of tokens that are approved (2^256-1 means infinite)
     * @param deadline The time at which to expire the signature
     * @param v The recovery byte of the signature
     * @param r Half of the ECDSA signature pair
     * @param s Half of the ECDSA signature pair
     */
    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external {
        require(deadline >= block.timestamp, "permit::expired");

        bytes32 encodeData = keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline));
        _validateSignedData(owner, encodeData, v, r, s);

        _approve(owner, spender, value);
    }

    /**
     * @notice Recovers address from signed data and validates the signature
     * @param signer Address that signed the data
     * @param encodeData Data signed by the address
     * @param v The recovery byte of the signature
     * @param r Half of the ECDSA signature pair
     * @param s Half of the ECDSA signature pair
     */
    function _validateSignedData(address signer, bytes32 encodeData, uint8 v, bytes32 r, bytes32 s) internal view {
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                getDomainSeparator(),
                encodeData
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        // Explicitly disallow authorizations for address(0) as ecrecover returns address(0) on malformed messages
        require(recoveredAddress != address(0) && recoveredAddress == signer, "Arch::validateSig: invalid signature");
    }

    /**
     * @notice EIP-712 Domain separator
     * @return Separator
     */
    function getDomainSeparator() public view returns (bytes32) {
        return keccak256(
            abi.encode(
                DOMAIN_TYPEHASH,
                keccak256(bytes(name)),
                VERSION_HASH,
                _getChainId(),
                address(this)
            )
        );
    }

    /**
     * @notice Current id of the chain where this contract is deployed
     * @return Chain id
     */
    function _getChainId() internal pure returns (uint) {
        uint256 chainId;
        assembly { chainId := chainid() }
        return chainId;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.3;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.3;

import "./IERC20.sol";

interface IPair is IERC20 {
    function token0() external pure returns (address);
    function token1() external pure returns (address);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function mint(address to) external returns (uint liquidity);
    function sync() external;
}

pragma solidity 0.7.3;

/**
 * @title Exponential module for storing fixed-precision decimals
 * @author Benqi
 * @notice Exp is a struct which stores decimals with a fixed precision of 18 decimal places.
 *         Thus, if we wanted to store the 5.1, mantissa would store 5.1e18. That is:
 *         `Exp({mantissa: 5100000000000000000})`.
 */
library Exponential {
    uint256 constant expScale = 1e18;
    uint256 constant doubleScale = 1e36;
    uint256 constant halfExpScale = expScale / 2;
    uint256 constant mantissaOne = expScale;

    struct Exp {
        uint256 mantissa;
    }

    struct Double {
        uint256 mantissa;
    }

    /**
     * @dev Truncates the given exp to a whole number value.
     *      For example, truncate(Exp{mantissa: 15 * expScale}) = 15
     */
    function truncate(Exp memory exp) internal pure returns (uint256) {
        // Note: We are not using careful math here as we're performing a division that cannot fail
        return exp.mantissa / expScale;
    }

    /**
     * @dev Multiply an Exp by a scalar, then truncate to return an unsigned integer.
     */
    function mul_ScalarTruncate(Exp memory a, uint256 scalar) internal pure returns (uint256) {
        Exp memory product = mul_(a, scalar);
        return truncate(product);
    }

    /**
     * @dev Multiply an Exp by a scalar, truncate, then add an to an unsigned integer, returning an unsigned integer.
     */
    function mul_ScalarTruncateAddUInt(
        Exp memory a,
        uint256 scalar,
        uint256 addend
    ) internal pure returns (uint256) {
        Exp memory product = mul_(a, scalar);
        return add_(truncate(product), addend);
    }

    /**
     * @dev Checks if first Exp is less than second Exp.
     */
    function lessThanExp(Exp memory left, Exp memory right) internal pure returns (bool) {
        return left.mantissa < right.mantissa;
    }

    /**
     * @dev Checks if left Exp <= right Exp.
     */
    function lessThanOrEqualExp(Exp memory left, Exp memory right) internal pure returns (bool) {
        return left.mantissa <= right.mantissa;
    }

    /**
     * @dev Checks if left Exp > right Exp.
     */
    function greaterThanExp(Exp memory left, Exp memory right) internal pure returns (bool) {
        return left.mantissa > right.mantissa;
    }

    /**
     * @dev returns true if Exp is exactly zero
     */
    function isZeroExp(Exp memory value) internal pure returns (bool) {
        return value.mantissa == 0;
    }

    function safe224(uint256 n, string memory errorMessage) internal pure returns (uint224) {
        require(n < 2**224, errorMessage);
        return uint224(n);
    }

    function safe32(uint256 n, string memory errorMessage) internal pure returns (uint32) {
        require(n < 2**32, errorMessage);
        return uint32(n);
    }

    function add_(Exp memory a, Exp memory b) internal pure returns (Exp memory) {
        return Exp({mantissa: add_(a.mantissa, b.mantissa)});
    }

    function add_(Double memory a, Double memory b) internal pure returns (Double memory) {
        return Double({mantissa: add_(a.mantissa, b.mantissa)});
    }

    function add_(uint256 a, uint256 b) internal pure returns (uint256) {
        return add_(a, b, "addition overflow");
    }

    function add_(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, errorMessage);
        return c;
    }

    function sub_(Exp memory a, Exp memory b) internal pure returns (Exp memory) {
        return Exp({mantissa: sub_(a.mantissa, b.mantissa)});
    }

    function sub_(Double memory a, Double memory b) internal pure returns (Double memory) {
        return Double({mantissa: sub_(a.mantissa, b.mantissa)});
    }

    function sub_(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub_(a, b, "subtraction underflow");
    }

    function sub_(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    function mul_(Exp memory a, Exp memory b) internal pure returns (Exp memory) {
        return Exp({mantissa: mul_(a.mantissa, b.mantissa) / expScale});
    }

    function mul_(Exp memory a, uint256 b) internal pure returns (Exp memory) {
        return Exp({mantissa: mul_(a.mantissa, b)});
    }

    function mul_(uint256 a, Exp memory b) internal pure returns (uint256) {
        return mul_(a, b.mantissa) / expScale;
    }

    function mul_(Double memory a, Double memory b) internal pure returns (Double memory) {
        return Double({mantissa: mul_(a.mantissa, b.mantissa) / doubleScale});
    }

    function mul_(Double memory a, uint256 b) internal pure returns (Double memory) {
        return Double({mantissa: mul_(a.mantissa, b)});
    }

    function mul_(uint256 a, Double memory b) internal pure returns (uint256) {
        return mul_(a, b.mantissa) / doubleScale;
    }

    function mul_(uint256 a, uint256 b) internal pure returns (uint256) {
        return mul_(a, b, "multiplication overflow");
    }

    function mul_(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        if (a == 0 || b == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, errorMessage);
        return c;
    }

    function div_(Exp memory a, Exp memory b) internal pure returns (Exp memory) {
        return Exp({mantissa: div_(mul_(a.mantissa, expScale), b.mantissa)});
    }

    function div_(Exp memory a, uint256 b) internal pure returns (Exp memory) {
        return Exp({mantissa: div_(a.mantissa, b)});
    }

    function div_(uint256 a, Exp memory b) internal pure returns (uint256) {
        return div_(mul_(a, expScale), b.mantissa);
    }

    function div_(Double memory a, Double memory b) internal pure returns (Double memory) {
        return Double({mantissa: div_(mul_(a.mantissa, doubleScale), b.mantissa)});
    }

    function div_(Double memory a, uint256 b) internal pure returns (Double memory) {
        return Double({mantissa: div_(a.mantissa, b)});
    }

    function div_(uint256 a, Double memory b) internal pure returns (uint256) {
        return div_(mul_(a, doubleScale), b.mantissa);
    }

    function div_(uint256 a, uint256 b) internal pure returns (uint256) {
        return div_(a, b, "divide by zero");
    }

    function div_(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    function fraction(uint256 a, uint256 b) internal pure returns (Double memory) {
        return Double({mantissa: div_(mul_(a, doubleScale), b)});
    }
}