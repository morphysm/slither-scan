// SPDX-License-Identifier: AGPLv3
pragma solidity 0.8.4;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "../BaseStrategy.sol";

/*//////////////////////////
 *          INTERFACES
 *//////////////////////////

// Uniswap router interface
interface IUni {
    function getAmountsOut(uint256 _amountIn, address[] calldata _path)
        external
        view
        returns (uint256[] memory amounts);

    function swapExactTokensForTokens(
        uint256 _amountIn,
        uint256 _amountOutMin,
        address[] calldata _path,
        address _to,
        uint256 _deadline
    ) external returns (uint256[] memory amounts);

    function swapExactAVAXForTokens(
        uint256 _amountOutMin,
        address[] calldata _path,
        address _to,
        uint256 _deadline
    ) external payable returns (uint256[] memory amounts);
}

// Uniswap pool interface
interface IUniPool {
    function getReserves()
        external
        view
        returns (
            uint112 _reserve0,
            uint112 _reserve1,
            uint32 _blockTimestampLast
        );

    function totalSupply() external view returns (uint256);
}

interface ICurve {
    function exchange_underlying(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 min_dy
    ) external returns (uint256);

    function get_dy_underlying(
        int128 i,
        int128 j,
        uint256 dx
    ) external view returns (uint256);
}

interface IHomoraOracle {
    function getETHPx(address token) external view returns (uint256);
}

// HomoraBank interface
interface IHomora {
    function execute(
        uint256 _positionId,
        address _spell,
        bytes memory _data
    ) external payable returns (uint256);

    function getPositionInfo(uint256 _positionId)
        external
        view
        returns (
            address owner,
            address collToken,
            uint256 collId,
            uint256 collateralSize
        );

    function getPositionDebts(uint256 _positionId)
        external
        view
        returns (address[] memory tokens, uint256[] memory debts);
}

// AH master chef tracker interface
interface IWMasterChef {
    function balanceOf(address _account, uint256 _id)
        external
        view
        returns (uint256);

    function decodeId(uint256 _id)
        external
        pure
        returns (uint256 pid, uint256 sushiPerShare);
}

// Master chef interface
interface IMasterChef {
    function poolInfo(uint256 _pid)
        external
        view
        returns (
            address lpToken,
            uint256 allocPoint,
            uint256 lastRewardBlock,
            uint256 accSushiPerShare
        );
}

/* @notice AHv2Farmer - Alpha Homora V2 yield aggregator strategy
 *
 *      Farming AHv2 Stable/AVAX positions.
 *
 *  ###############################################
 *      Strategy overview
 *  ###############################################
 *
 *  Gro Protocol Alpha Homora v2 impermanent loss strategy
 *
 *  Alpha homora (referred to as AHv2) offers leveraged yield farming by offering up to 7x leverage
 *      on users positions in various AMMs. The gro alpha homora v2 strategy (referred to as the strategy)
 *      aim to utilize AHv2 leverage to create and maintain market neutral positions (2x leverage)
 *      for as long as they are deemed profitable. This means that the strategy will supply want (stable coin)
 *      to AH, and borrow avax in a proportional amount. Under certian circumstances the strategy will stop
 *      it's borrowing, but will not ever attempt to borrow want from AH.
 *
 *  ###############################################
 *      Strategy specifications
 *  ###############################################
 *
 *  The strategy sets out to fulfill the following requirements:
 *  - Open new positions
 *  - Close active positions
 *  - Adjust active positions
 *  - Interact with Gro vault adapters (GVA):
 *      - Report gains/losses
 *      - Borrow assets from GVA to invest into AHv2
 *      - Repay debts to GVA
 *      - Accommodate withdrawals from GVA
 *
 * The strategy keeps track of the following:
 *   - Price changes in opening position
 *   - Collateral ratio of AHv2 position
 *
 * If any of these go out of a preset threshold, the strategy will attempt to close down the position.
 *  If the collateral factor move away from the ideal target, the strategy won't take on more debt from alpha
 *  homora when adding assets to the position.
 */
contract AHv2FarmerDai is BaseStrategy {
    using SafeERC20 for IERC20;

    // Base constants
    uint256 public constant PERCENTAGE_DECIMAL_FACTOR = 1E4;
    // LP Pool token
    IUniPool public immutable pool;
    uint256 immutable decimals;
    address public constant wavax =
        address(0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7);
    IHomoraOracle public constant homoraOralce =
        IHomoraOracle(0xc842CC25FE89F0A60Fe9C1fd6483B6971020Eb3A);
    // Full repay
    uint256 constant REPAY = type(uint256).max;

    // UniV2 or Sushi swap style router
    IUni public immutable uniSwapRouter;

    ICurve public constant curvePool =
        ICurve(0x7f90122BF0700F9E7e1F688fe926940E8839F353);
    address public constant homoraBank =
        address(0x376d16C7dE138B01455a51dA79AD65806E9cd694);
    address public constant masterChef =
        address(0xd6a4F121CA35509aF06A0Be99093d08462f53052);
    IWMasterChef public constant wMasterChef =
        IWMasterChef(0xB41DE9c1f50697cC3Fd63F24EdE2B40f6269CBcb);
    address public immutable spell;

    // strategies current position
    uint256 public activePosition;
    // How much change we accept in AVAX price before closing or adjusting the position
    uint256 public ilThreshold = 400; // 4%
    uint256 public slippage = 10; // 0.1% curve slippage

    // In case no direct path exists for the swap, use this token as an inermidiary step
    address public immutable indirectPath;
    // liq. pool token order, used to determine if calculations should be reversed or not
    // first token in liquidity pool
    address public immutable tokenA;
    // second token in liquidity pool
    address public immutable tokenB;

    // poolId for masterchef - can be commented out for non sushi spells
    uint256 immutable public poolId;

    // Min amount of tokens to open/adjust positions or sell
    uint256 public minWant;
    // Amount of tokens to sell as a % of pool liq. depth
    uint256 public sellThreshold = 10; // 0.1%
    // Thresholds for the different tokens sold
    mapping(address => uint256) public ammThreshold;
    // How short on avax a position is allowed to be before adjusting
    uint256 public exposureThreshold = 50; // 0.5 %
    // Amount of short/long position to liquidate from position
    uint256 public adjustRatio = 5000; // 50 %
    // Limits the size of a position based on how much is available to borrow
    uint256 public borrowLimit;

    // strategy positions
    mapping(uint256 => PositionData) positions;

    // function headers for generating signatures for encoding function calls
    // AHv2 homorabank uses encoded spell function calls in order to cast spells
    string constant spellOpen =
        "addLiquidityWMasterChef(address,address,(uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256),uint256)";
    string constant spellClose =
        "removeLiquidityWMasterChef(address,address,(uint256,uint256,uint256,uint256,uint256,uint256,uint256))";

    /*//////////////////////////
     *          EVENTS
     *//////////////////////////

    event LogNewPositionOpened(
        uint256 indexed positionId,
        uint256[] price,
        uint256 collateralSize
    );

    event LogPositionClosed(
        uint256 indexed positionId,
        uint256 wantRecieved,
        uint256[] price
    );

    event LogPositionAdjusted(
        uint256 indexed positionId,
        uint256[] amounts,
        uint256 collateralSize,
        bool withdrawal
    );

    event LogAVAXSold(uint256[] AVAXSold);

    event NewFarmer(
        address vault,
        address spell,
        address router,
        address pool,
        uint256 poolId
    );
    event LogNewSlippage(uint256 slippage);
    event LogNewReserversSet(uint256 reserve);
    event LogNewMinWantSet(uint256 minWawnt);
    event LogNewBorrowLimit(uint256 newLimit);
    event LogNewStrategyThresholds(uint256 ilThreshold, uint256 sellThreshold, uint256 exposureThreshold, uint256 adjustRatio);
    event LogNewAmmThreshold(address token, uint256 newThreshold);

    struct PositionData {
        uint256[] wantClose; // AVAX value of position when closed [want => AVAX]
        uint256 totalClose; // total value of position on close
        uint256[] wantOpen; // AVAX value of position when opened [want => AVAX]
        uint256 collateral; // collateral amount
        uint256[] timestamps; // open/close position stamps
    }

    struct Amounts {
        uint256 aUser; // Supplied tokenA amount
        uint256 bUser; // Supplied tokenB amount
        uint256 lpUser; // Supplied LP token amount
        uint256 aBorrow; // Borrow tokenA amount
        uint256 bBorrow; // Borrow tokenB amount
        uint256 lpBorrow; // Borrow LP token amount
        uint256 aMin; // Desired tokenA amount (slippage control)
        uint256 bMin; // Desired tokenB amount (slippage control)
    }

    struct RepayAmounts {
        uint256 lpTake; // Take out LP token amount (from Homora)
        uint256 lpWithdraw; // Withdraw LP token amount (back to caller)
        uint256 aRepay; // Repay tokenA amount
        uint256 bRepay; // Repay tokenB amount
        uint256 lpRepay; // Repay LP token amount
        uint256 aMin; // Desired tokenA amount
        uint256 bMin; // Desired tokenB amount
    }

    constructor(
        address _vault,
        address _spell,
        address _router,
        address _pool,
        uint256 _poolId,
        address[] memory _tokens,
        address _indirectPath
    ) BaseStrategy(_vault) {
        uint256 _decimals = IVault(_vault).decimals();
        decimals = _decimals;
        tokenA = _tokens[0];
        tokenB = _tokens[1];
        indirectPath = _indirectPath;
        debtThreshold = 1_000_000 * (10**_decimals);
        // approve the homora bank to use our want
        want.safeApprove(homoraBank, type(uint256).max);
        // approve curve
        IERC20(_indirectPath).safeApprove(address(curvePool), type(uint256).max);
        spell = _spell;
        uniSwapRouter = IUni(_router);
        pool = IUniPool(_pool);
        poolId = _poolId;
        emit NewFarmer(_vault, _spell, _router, _pool, _poolId);
    }

    // Strategy will recieve AVAX from closing/adjusting positions, do nothing with the AVAX here
    receive() external payable {}

    /*//////////////////////////
     *    Getters
     *//////////////////////////

    // Strategy name
    function name() external pure override returns (string memory) {
        return "AHv2 strategy";
    }

    // Default getter for public structs dont return dynamics arrays, so we add this here
    function getPosition(uint256 _positionId)
        external
        view
        returns (PositionData memory)
    {
        return positions[_positionId];
    }

    // Function for testing purposes
    /////////////////////////////////
    // function getExposure() external view returns (bool, bool, uint256[] memory, int256, uint256[] memory) {
    //     uint256 positionId = activePosition;
    //     bool check;
    //     bool short;
    //     uint256[] memory lp;
    //     if (positionId > 0) {
    //         (check, short, lp) = _calcAVAXExposure(positionId, positions[positionId].collateral);
    //     }
    //     (uint256[] memory lpPosition, int256 AVAXPosition) = _calcAVAXPosition(positionId, positions[positionId].collateral);
    //     return (check, short, lp, AVAXPosition, lpPosition);
    // }

    /*//////////////////////////
     *    Setters
     *//////////////////////////

    /*
     * @notice set minimum want required to adjust position
     * @param _minWant minimum amount of want
     */
    function setMinWant(uint256 _minWant) external onlyOwner {
        minWant = _minWant;
        emit LogNewMinWantSet(_minWant);
    }

    /*
     * @notice set threshold for amm check
     * @param _threshold new threshold
     */
    function setAmmThreshold(address _token, uint256 _threshold)
        external
        onlyOwner
    {
        ammThreshold[_token] = _threshold;
        emit LogNewAmmThreshold(_token, _threshold);
    }

    /*
     * @notice set minimum want required to adjust position
     * @param _minWant minimum amount of want
     */
    function setBorrowLimit(uint256 _newLimt) external onlyAuthorized {
        borrowLimit = _newLimt;
        emit LogNewBorrowLimit(_newLimt);
    }

    /*
     * @notice set curve slippage
     * @param _slippage new curve slippage
     */
    function setSlippage(uint256 _slippage) external onlyOwner {
        require(_slippage < 1000, 'setSlippage: slippage > 10%');
        slippage = _slippage;
        emit LogNewSlippage(_slippage);
    }

    /*
     * @notice setters for varius strategy variables
     * @param _ilThreshold new il threshold
     * @param _sellThreshold threshold of pool depth in BP
     * @param _exposureThreshold amount the positiong can go long/short before adjusting
     * @param _adjustRatio amount of long/short position to liquidate
     * @dev combined multiple setters to save space in strategy
     */
    function setStrategyThresholds(
        uint256 _ilThreshold,
        uint256 _sellThreshold,
        uint256 _exposureThreshold,
        uint256 _adjustRatio
    ) external onlyOwner {
        ilThreshold = _ilThreshold;
        sellThreshold = _sellThreshold;
        exposureThreshold = _exposureThreshold;
        adjustRatio = _adjustRatio;
        emit LogNewStrategyThresholds(_ilThreshold, _sellThreshold, _exposureThreshold, _adjustRatio);
    }

    /*//////////////////////////
     *    Core logic
     *//////////////////////////

    /*
     * @notice Calculate strategies current loss, profit and amount it can repay
     * @param _debtOutstanding amount of debt remaining to be repaid
     * @dev to avoid large slippage, we will always try to sell of AVAX in chunks, this
     *  will block any other harvest actions as long as their is avax to sell in this strategy.
     *  This is expected behavior, and we only expect to report gains/losses after all has been
     *  sold - There is also no possiblity for users to frontrun this, as any unrealized loss would
     *  be shifted on to a user if they were to try to withdraw assets from the strategy (see _liquidatePosition)
     */
    function _prepareReturn(uint256 _debtOutstanding, uint256 _positionId)
        internal
        returns (
            uint256 profit,
            uint256 loss,
            uint256 debtPayment,
            uint256 positionId
        )
    {
        uint256 balance;
        // only try to realize profits if there is no active position
        _sellAVAX();
        // As we potentially will sell of avax in chunks to avoid high level of slippage it is
        //  important that we dont engage with our positions or report gains/losses until we
        //  have sold of all excess avax (likely to happen if a position is closed when long).
        if (address(this).balance > 0) return (0, 0, 0, _positionId);
        positionId = _positionId;
        if (positionId == 0 || _debtOutstanding > 0) {
            balance = want.balanceOf(address(this));
            if (balance < _debtOutstanding && positionId > 0) {
                // withdraw to cover the debt
                if (compare(_debtOutstanding, (positions[positionId].wantOpen[0] + balance), 8000)) {
                    balance = 0;
                } else {
                    balance = _debtOutstanding - balance;
                }
                positionId = _closePosition(positionId, balance, true, true);
                balance = want.balanceOf(address(this));
            }
            debtPayment = Math.min(balance, _debtOutstanding);

            if (positionId == 0) {
                uint256 debt = vault.strategies(address(this)).totalDebt;
                // Balance - Total Debt is profit
                if (balance > debt) {
                    profit = balance - debt;
                    if (balance < profit) {     
                        profit = balance;
                    } else if (balance > profit + _debtOutstanding){
                        debtPayment = _debtOutstanding;
                    } else {
                        debtPayment = balance - profit;
                    }
                } else {
                    loss = debt - balance;
                }
            }
        }
    }

    /*
     * @notice partially removes or closes the current AH v2 position in order to repay a requested amount
     * @param _amountNeeded amount needed to be withdrawn from strategy
     * @dev This function will atempt to remove part of the current position in order to repay debt or accomodate a withdrawal,
     *      This is a gas costly operation, should not be atempted unless the amount being withdrawn warrants it.
     */
    function _liquidatePosition(uint256 _amountNeeded)
        internal
        override
        returns (uint256 amountFreed, uint256 loss)
    {
        require(_ammCheck(decimals, address(want)), "!ammCheck");
        // want in contract + want value of position based of AVAX value of position (total - borrowed)
        uint256 _positionId = activePosition;

        (uint256 assets, uint256 _balance) = _estimatedTotalAssets(_positionId);

        uint256 debt = vault.strategyDebt();

        // cannot repay the entire debt
        if (debt > assets) {
            loss = debt - assets;
            if (loss >= _amountNeeded) {
                loss = _amountNeeded;
                amountFreed = 0;
                return (amountFreed, loss);
            }
            _amountNeeded = _amountNeeded - loss;
        }

        // do we have enough assets in strategy to repay?
        if (_balance < _amountNeeded) {
            if (activePosition > 0) {
                uint256 remainder;
                // because pulling out assets from AHv2 tends to give us less assets than
                // we want specify, so lets see if we can pull out a bit in excess to be
                // able to pay back the full amount
                if (assets > _amountNeeded + 100 * (10**decimals)) {
                    remainder = _amountNeeded - _balance + 100 * (10**decimals);
                } else {
                    // but if not possible just pull the original amount
                    remainder = _amountNeeded - _balance;
                }

                // if we want to remove 80% or more of the position, just close it
                if (compare(remainder, assets, 8000)) {
                    _closePosition(_positionId, 0, true, true);
                    _sellAVAX();
                } else {
                    _closePosition(_positionId, remainder, true, true);
                }
            }

            // dont return more than was asked for
            amountFreed = Math.min(
                _amountNeeded,
                want.balanceOf(address(this))
            );
            loss += _amountNeeded - amountFreed;
        } else {
            amountFreed = _amountNeeded;
        }
        return (amountFreed, loss);
    }

    /*
     * @notice adjust current position, repaying any debt
     * @param _debtOutstanding amount of outstanding debt the strategy holds
     * @dev _debtOutstanding should always be 0 here, but we should handle the
     *      eventuality that something goes wrong in the reporting, in which case
     *      this strategy should act conservative and atempt to repay any outstanding amount
     */
    function _adjustPosition(
        uint256 _positionId
    ) internal {
        //emergency exit is dealt with in liquidatePosition
        if (emergencyExit) {
            return;
        }

        (bool check, uint256 remainingLimit) = _checkPositionHealth(_positionId);
        if (check) {
            _closePosition(_positionId, 0, false, true);
            return;
        }
        //we are spending all our cash unless we have debt outstanding
        uint256 wantBal = want.balanceOf(address(this));

        // check if the current want amount is large enough to justify opening/adding
        // to an existing position, else do nothing
        if (wantBal > remainingLimit) wantBal = remainingLimit;
        if (wantBal >= minWant && address(this).balance == 0) {
            if (_positionId == 0) {
                _openPosition(true, 0, wantBal);
            } else {
                // TODO logic to lower the collateral ratio
                // When adding to the position we will try to stabilize the collateralization ratio, this
                //  will be possible if we owe more than originally, as we just need to borrow less AVAX
                //  from AHv2. The opposit will currently not work as we want to avoid taking on want
                //  debt from AHv2.

                // else if (changeFactor > 0) {
                //     // See what the % of the position the current pos is
                //     uint256 assets = _calcEstimatedWant(_positionId);
                //     uint256[] memory oldPrice = positions[_positionId].openWant;
                //     uint256 newPercentage = (newPosition[0] * PERCENTAGE_DECIMAL_FACTOR / oldPrice[0])
                // }
                _openPosition(false, _positionId, wantBal);
            }
        } else if (_positionId > 0) {
            uint256[] memory lpPosition;
            uint256 collateral = positions[_positionId].collateral;
            bool short;
            (check, short, lpPosition) = _calcAVAXExposure(_positionId, collateral);
            if (check) {
                _closePosition(_positionId, lpPosition[1], !short, short);
            }
        }
    }

    /*//////////////////////////
     *    Alpha Homora functions
     *//////////////////////////

    /*
     * @notice Open a new AHv2 position with market neutral leverage
     * @param _new is it a new position
     * @param _positionId id of position if adding
     * @param amount amount of want to provide to prosition
     */
    function _openPosition(
        bool _new,
        uint256 _positionId,
        uint256 _amount
    ) internal {
        (uint256[] memory amounts, ) = _calcSingleSidedLiq(_amount, false);
        Amounts memory amt = _formatOpen(amounts);
        _positionId = IHomora(homoraBank).execute(
            _positionId,
            spell,
            abi.encodeWithSignature(spellOpen, tokenA, tokenB, amt, poolId)
        );
        _setPositionData(_positionId, amounts, _new, false);
    }

    /*
     * @notice Close and active AHv2 position
     * @param _positionId ID of position to close
     * @param _amount amount of want to remove
     * @param _force Force close position, set minAmount to 0/0
     */
    function _closePosition(
        uint256 _positionId,
        uint256 _amount,
        bool _withdraw,
        bool _repay
    ) internal returns (uint256) {
        // active position data
        uint256[] memory minAmounts;
        uint256[] memory amounts;
        uint256 collateral;
        uint256 wantBal;
        bool _partial;
        if (_amount > 0) {
            _partial = true;
            (amounts, collateral) = _calcSingleSidedLiq(_amount, true);
            minAmounts = new uint256[](2);
            if (_withdraw) {
                minAmounts[1] =
                    (amounts[0] * (PERCENTAGE_DECIMAL_FACTOR - 100)) /
                    PERCENTAGE_DECIMAL_FACTOR;
            } else {
                amounts[1] =
                    (amounts[1] * (PERCENTAGE_DECIMAL_FACTOR - 100)) /
                    PERCENTAGE_DECIMAL_FACTOR;
                collateral = collateral / 2;
            }
        } else {
            PositionData storage pd = positions[_positionId];
            collateral = pd.collateral;
            wantBal = want.balanceOf(address(this));
            amounts = new uint256[](2);
            amounts[1] = REPAY;
            // Calculate amount we expect to get out by closing the position (applying 0.5% slippage)
            // Note, expected will be [AVAX, want], as debts always will be [AVAX] and solidity doesnt support
            // sensible operations like [::-1] or zip...
            (minAmounts, ) = _calcAvailable(
                _positionId,
                (collateral * (PERCENTAGE_DECIMAL_FACTOR - 50)) /
                    PERCENTAGE_DECIMAL_FACTOR
            );
        }
        if (!_repay) amounts[1] = 0;
        _positionId = _homoraClose(_positionId, minAmounts, collateral, amounts[1]);
        if (_partial) {
            _setPositionData(_positionId, amounts, false, true);
            return _positionId;
        } else {
            // Do not sell after closing down the position, AVAX/yieldToken are sold during
            //  the early stages for the harvest flow (see prepareReturn)
            // total amount of want retrieved from position
            wantBal = want.balanceOf(address(this)) - wantBal;
            _closePositionData(_positionId, wantBal);
            return 0;
        }
    }

    /*
     * @notice Format data and close/remove assets from position
     * @param _positionId id of position
     * @param _minAmounts minimum amounts that we expect to get back
     * @param _collateral amount of collateral to burn
     * @param _repay amount to repay
     */
    function _homoraClose(
        uint256 _positionId,
        uint256[] memory _minAmounts,
        uint256 _collateral,
        uint256 _repay
    ) private returns (uint256)
    {
        RepayAmounts memory amt = _formatClose(_minAmounts, _collateral, _repay);
        return IHomora(homoraBank).execute(
            _positionId,
            spell,
            abi.encodeWithSignature(spellClose, tokenA, tokenB, amt)
        );
    }

    ////// Format functions for Alpha Homora spells

    /*
     * @notice format the open position input struct
     * @param _amounts Amounts for position
     */
    function _formatOpen(uint256[] memory _amounts)
        internal
        view
        returns (Amounts memory amt)
    {
        // Unless we borrow we only supply a value for the want we provide
        if (tokenA == address(want)) {
            amt.aUser = _amounts[0];
            amt.bBorrow = _amounts[1];
        } else {
            amt.bUser = _amounts[0];
            amt.aBorrow = _amounts[1];
        }
    }

    /*
     * @notice format the close position input struct
     * @param _expect expected return amounts
     * @param _collateral collateral to remove from position
     * @param _repay amount to repay - default to max value if closing position
     */
    function _formatClose(
        uint256[] memory _expected,
        uint256 _collateral,
        uint256 _repay
    ) internal view returns (RepayAmounts memory amt) {
        amt.lpTake = _collateral;
        if (tokenA == address(want)) {
            amt.aMin = _expected[1];
            amt.bMin = _expected[0];
            amt.bRepay = _repay;
        } else {
            amt.aMin = _expected[0];
            amt.bMin = _expected[1];
            amt.aRepay = _repay;
        }
    }

    /*//////////////////////////
     *    Oracle logic
     *//////////////////////////

    /*
     * @notice Check if price change is outside the accepted range,
     *      in which case the the opsition needs to be closed or adjusted
     */
    function volatilityCheck() public view returns (bool) {
        if (activePosition == 0) {
            return false;
        }
        uint256[] memory openPrice = positions[activePosition].wantOpen;
        (uint256[] memory currentPrice, ) = _calcSingleSidedLiq(
            openPrice[0],
            false
        );
        bool check = (openPrice[1] < currentPrice[1]) ? 
            compare(currentPrice[1], openPrice[1], ilThreshold+PERCENTAGE_DECIMAL_FACTOR) : 
            compare(openPrice[1], currentPrice[1], ilThreshold+PERCENTAGE_DECIMAL_FACTOR);
        return check;
    }

    /*
     * @notice Compare prices in amm vs external oralce
     * @param _decimals decimal of token, used to determine spot price
     * @param _start token to check
     * @dev The following price check is done AHOracle [token/Avax] / Amm [token/Avax], this
     *      Value needs to be within the AMMthreshold for the transaction to proceed
     */
    function _ammCheck(uint256 _decimals, address _start)
        internal
        view
        returns (bool)
    {
        // Homor oracle avax price for token
        uint256 ethPx = IHomoraOracle(homoraOralce).getETHPx(_start);
        address[] memory path = new address[](2);
        path[0] = _start;
        path[1] = wavax;
        // Joe router price
        uint256[] memory amounts = uniSwapRouter.getAmountsOut(
            10**_decimals,
            path
        );
        // Normalize homora price and add the default decimal factor to get it to BP
        uint256 diff = ((ethPx * 10**(_decimals + 4)) / 2**112) / amounts[1];
        diff = (diff > PERCENTAGE_DECIMAL_FACTOR)
            ? diff - PERCENTAGE_DECIMAL_FACTOR
            : PERCENTAGE_DECIMAL_FACTOR - diff;
        // check the difference against the ammThreshold
        if (diff < ammThreshold[_start]) return true;
    }

    /*
     * @notice check if the position needs to be closed or adjusted
     * @param _positionId active position
     */
    function _checkPositionHealth(uint256 _positionId)
        internal
        view
        returns (bool, uint256)
    {
        uint256 posWant;
        if (_positionId > 0) {
            posWant = positions[_positionId].wantOpen[0];
            if (
                posWant * 9750 / PERCENTAGE_DECIMAL_FACTOR > borrowLimit ||
                volatilityCheck() ||
                block.timestamp - positions[_positionId].timestamps[0] >=
                maxReportDelay
            ) {
                return (true, 0);
            }
        }
        return (false, borrowLimit - posWant);
    }

    /*//////////////////////////
     *    Position tracking
     *//////////////////////////

    /*
     * @notice Create or update the position data for indicated position
     * @param _positionId ID of position
     * @param _amounts Amounts add/withdrawn from position
     * @param _newPosition Is the position a new one
     * @param _withdraw Was the action a withdrawal
     */
    function _setPositionData(
        uint256 _positionId,
        uint256[] memory _amounts,
        bool _newPosition,
        bool _withdraw
    ) internal {
        // get position data
        (, , , uint256 collateralSize) = IHomora(homoraBank)
            .getPositionInfo(_positionId);

        PositionData storage pos = positions[_positionId];
        pos.collateral = collateralSize;
        if (_newPosition) {
            activePosition = _positionId;
            pos.timestamps.push(block.timestamp);
            pos.wantOpen = _amounts;
            emit LogNewPositionOpened(
                _positionId,
                _amounts,
                collateralSize
            );
        } else {
            // previous position price
            uint256[] memory _openPrice = pos.wantOpen;
            if (!_withdraw) {
                _openPrice[0] += _amounts[0];
                _openPrice[1] += _amounts[1];
            } else {
                _openPrice[0] -= _amounts[0];
                _openPrice[1] -= _amounts[1];
            }
            pos.wantOpen = _openPrice;
            emit LogPositionAdjusted(
                _positionId,
                _amounts,
                collateralSize,
                _withdraw
            );
        }
    }

    /*
     * @notice Update position data when closing a position
     * @param _positionId id of position that was closed
     * @param _amounts total amounts that was returned by position (exclused avax and yield tokens)
     */
    function _closePositionData(uint256 _positionId, uint256 _amount) private {
        PositionData storage pos = positions[_positionId];
        pos.timestamps.push(block.timestamp);
        pos.totalClose = _amount;
        uint256[] memory _wantClose = _uniPrice(
            pos.wantOpen[0],
            address(want)
        );
        pos.wantClose = _wantClose;
        activePosition = 0;
        emit LogPositionClosed(_positionId, _amount, _wantClose);
    }

    /*//////////////////////////
     *    UniSwap functions
     *//////////////////////////

    /*
     * @notice sell the contracts AVAX for want if there enough to justify the sell
     * @param _all sell all available avax
     */
    function _sellAVAX() internal {
        uint256 balance = address(this).balance;

        // check if we have enough AVAX to sell
        if (balance == 0) {
            return;
        }

        (, uint112 resB) = _getPoolReserves();
        if (balance * PERCENTAGE_DECIMAL_FACTOR / resB > sellThreshold) {
            balance = resB * sellThreshold / PERCENTAGE_DECIMAL_FACTOR;
        }
        // Use a call to the uniswap router contract to swap exact AVAX for want
        // note, minwant could be set to 0 here as it doesnt matter, this call
        // cannot prevent any frontrunning and the transaction should be executed
        // using a private host. When lacking a private host it needs to rely on the
        // AMM check or ues the manual see function between harvest.
        uint256[] memory amounts = uniSwapRouter.swapExactAVAXForTokens{
            value: balance
        }(0, _getPath(indirectPath), address(this), block.timestamp);

        // Due to a thin pool, we sell of avax for a thicker asset and swap it
        // into want via curve
        balance = IERC20(indirectPath).balanceOf(address(this));
        uint256 minAmount = balance * 10 ** (18 - 6) * (PERCENTAGE_DECIMAL_FACTOR - slippage) / PERCENTAGE_DECIMAL_FACTOR;
        amounts[1] = curvePool.exchange_underlying(1, 0, balance, minAmount);

        emit LogAVAXSold(amounts);
    }

    /*
     * @notice calculate want and AVAX value of lp position
     *      value of lp is defined by (in uniswap routerv2):
     *          lp = Math.min(input0 * poolBalance / reserve0, input1 * poolBalance / reserve1)
     *      which in turn implies:
     *          input0 = reserve0 * lp / poolBalance
     *          input1 = reserve1 * lp / poolBalance
     * @param _collateral lp amount
     * @dev Note that we swap the order of want and AVAX in the return array, this is because
     *      the debt position always will be in AVAX, and to save gas we dont add a 0 value for the
     *      want debt. So when doing repay calculations we need to remove the debt from the AVAX amount,
     *      which becomes simpler if the AVAX position comes first.
     */
    function _calcLpPosition(uint256 _collateral)
        internal
        view
        returns (uint256[] memory)
    {
        (uint112 resA, uint112 resB) = _getPoolReserves();
        uint256 poolBalance = IUniPool(pool).totalSupply();
        uint256[] memory lpPosition = new uint256[](2);

        lpPosition[1] = ((_collateral * uint256(resA)) / poolBalance);
        lpPosition[0] = ((_collateral * uint256(resB)) / poolBalance);

        return lpPosition;
    }

    /*
     * @notice get reserves from uniswap v2 style pool
     * @dev Depending on order of tokens return value may be reversed, as
     *      strategy expects Stable Coin/Avax
     */
    function _getPoolReserves()
        private
        view
        returns (uint112 resA, uint112 resB)
    {
        if (tokenA == address(want)) {
            (resA, resB, ) = pool.getReserves();
        } else {
            (resB, resA, ) = pool.getReserves();
        }
    }

    /*
     * @notice Calculate how much AVAX needs to be provided for a set amount of want
     *      when adding liquidity - This is used to estimate how much to borrow from AH.
     *      We need to solve the AH optimal swap formula for 0, which can be achieved by taking:
     *          uint _c = (amtA.mul(resB)).sub(amtB.mul(resA));
     *          uint c = _c.mul(1000).div(amtB.add(resB)).mul(resA);
     *      and rewriting it to:
     *          (A * resB - B * resA) * K / (B + resB)
     *      Which we in turn can simplify to:
     *          B = (resB * A * k  - resB) / (resA * k + 1);
     *      B (the amount of the second pool component) needs to be less than or equal to the RHS
     *      in order for the optional swap formula to not perform a swap.
     * @param _amount amount of want
     * @param _withdraw we need to calculate the liquidity amount if withdrawing
     * @dev Small enough position may revert in these calculations, this can be avoided by setting an
     *  appropriate minWant
     */
    function _calcSingleSidedLiq(uint256 _amount, bool _withdraw)
        internal
        view
        returns (uint256[] memory, uint256)
    {
        (uint112 resA, uint112 resB) = _getPoolReserves();
        uint256[] memory amt = new uint256[](2);
        amt[1] =
            (resB * 1000 * _amount - resB) /
            (resA * 1000 + 10**decimals) -
            1;
        amt[0] = _amount;
        if (_withdraw) {
            uint256 poolBalance = IUniPool(pool).totalSupply();
            uint256 liquidity = Math.min(
                (amt[0] * poolBalance) / resA,
                (amt[1] * poolBalance) / resB
            );
            return (amt, liquidity);
        }
        return (amt, 0);
    }

    /*
     * @notice get swap price in uniswap pool
     * @param _amount amount of token to swap
     * @param _start token to swap out
     */
    function _uniPrice(uint256 _amount, address _start)
        internal
        view
        returns (uint256[] memory)
    {
        if (_amount == 0) {
            return new uint256[](2);
        }
        uint256[] memory amounts = uniSwapRouter.getAmountsOut(
            _amount,
            _getPath(_start)
        );

        return amounts;
    }

    /*//////////////////////////
     *    Emergency logic
     *//////////////////////////

    /*
     * @notice Manually wind down an AHv2 position
     * @param _positionId ID of position to close
     */
    function forceClose(uint256 _positionId) external onlyAuthorized {
        PositionData storage pd = positions[_positionId];
        uint256 collateral = pd.collateral;
        uint256[] memory minAmounts = new uint256[](2);
        uint256 wantBal = want.balanceOf(address(this));
        _homoraClose(_positionId, minAmounts, collateral, REPAY);
        wantBal = want.balanceOf(address(this)) - wantBal;
        _closePositionData(_positionId, wantBal);
    }

    /*//////////////////////////
     *    Asset Views
     *//////////////////////////

    //////// External

    function estimatedTotalAssets() external view override returns (uint256) {
        (uint256 totalAssets, ) = _estimatedTotalAssets(activePosition);
        return totalAssets;
    }

    /*
     * @notice expected profit/loss of the strategy
     */
    function expectedReturn() external view returns (uint256) {
        (uint256 totalAssets, ) = _estimatedTotalAssets(activePosition);
        uint256 debt = vault.strategyDebt();
        if (totalAssets < debt) return 0;
        return totalAssets - debt;
    }

    /*
     * @notice want value of position
     */
    function calcEstimatedWant() external view returns (uint256) {
        uint256 _positionId = activePosition;
        if (_positionId == 0) return 0;
        return _calcEstimatedWant(_positionId);
    }

    ///////// Internal

    /*
     * @notice Get the estimated total assets of this strategy in want.
     *      This method is only used to pull out debt if debt ratio has changed.
     * @param _positionId active position
     * @return Total assets in want this strategy has invested into underlying protocol and
     *      the balance of this contract as a seperate variable
     */
    function _estimatedTotalAssets(uint256 _positionId)
        private
        view
        returns (uint256, uint256)
    {
        // get the value of the current position supplied by this strategy (total - borrowed)
        uint256[] memory _valueOfAVAX = _uniPrice(address(this).balance, indirectPath);
        if (_valueOfAVAX[1] > 0) {
            _valueOfAVAX[1] = curvePool.get_dy_underlying(1, 0, _valueOfAVAX[1]);
        }
        uint256 _reserve = want.balanceOf(address(this));

        if (_positionId == 0) {
            return (
                    _valueOfAVAX[1] +
                    _reserve,
                _reserve
            );
        }
        return (
            _reserve +
                _calcEstimatedWant(_positionId) +
                _valueOfAVAX[1],
            _reserve
        );
    }

    /*
     * @notice calculate how much expected returns we will get when closing down our position,
     *      this involves calculating the value of the collateral for the position (lp),
     *      and repaying the existing debt to Alpha homora. Two potential outcomes can come from this:
     *          - the position returns more AVAX than debt:
     *              in which case the strategy will collect the AVAX and atempt to sell it
     *          - the position returns less AVAX than the debt:
     *              Alpha homora will repay the debt by swapping part of the want to AVAX, we
     *              need to reduce the expected return amount of want by how much we will have to repay
     * @param _collateral lp value of position
     * @param _debts debts to repay (should always be AVAX)
     */
    function _calcAvailable(uint256 _positionId, uint256 _collateral)
        private
        view
        returns (uint256[] memory, uint256)
    {
        uint256 posWant;
        (uint256[] memory lpPosition, int256 AVAXPosition) = _calcAVAXPosition(_positionId, _collateral);
        if (AVAXPosition > 0) {
            posWant =
                curvePool.get_dy_underlying(1, 0, _uniPrice(uint256(AVAXPosition), indirectPath)[1]) +
                lpPosition[1];
            lpPosition[0] = uint256(AVAXPosition);
        } else {
            lpPosition[1] -= _uniPrice(uint256(AVAXPosition * -1), wavax)[1];
            lpPosition[0] = 0;
            posWant = lpPosition[1];
        }
        return (lpPosition, posWant);
    }

    /*
     * @notice Calculate estimated amount of want the strategy holds
     * @param _positionId active position
     */
    function _calcEstimatedWant(uint256 _positionId)
        private
        view
        returns (uint256)
    {
        PositionData storage pd = positions[_positionId];
        (, uint256 estWant) = _calcAvailable(_positionId, pd.collateral);
        return estWant;
    }

    /*
     * @notice Calculate the amount of avax the strategy has in excess/owes 
     *      to Alpha Homora
     * @param _positionId active position 
     * @param _collateral amount of collateral the strategy holds
     * @return value of collateral and avax (excess or owed)
     */
    function _calcAVAXPosition(uint256 _positionId, uint256 _collateral) 
        private
        view
        returns (uint256[] memory, int256)
    {
        if (_positionId == 0) return (new uint256[](2), 0);
        (, uint256[] memory debts) = IHomora(homoraBank).getPositionDebts(
            _positionId
        );
        uint256[] memory lpPosition = _calcLpPosition(_collateral);
        int256 AVAXPosition = int256(lpPosition[0]) - int256(debts[0]);

        return (lpPosition, AVAXPosition);
    }

    /*
     * @notice determine if the strategy is short/long on avax and if this is outside
     *      an acceptable threshold.
     * @param _positionId active position
     * @param _collateral amount of collateral the strategy holds
     * @return if avax exposure to high, if strategy is short or long in avax and the
     *      amount the strategy intends to remove if it would adjust itself.
     */
    function _calcAVAXExposure(uint256 _positionId, uint256 _collateral)
        private
        view
        returns (bool, bool, uint256[] memory)
    {
        (uint256[] memory lpPosition, int256 AVAXPosition) = _calcAVAXPosition(_positionId, _collateral);
        bool short;
        if (AVAXPosition < 0) {
            short = true;
            AVAXPosition = AVAXPosition * -1;
        }
        if (compare(uint256(AVAXPosition), lpPosition[0], exposureThreshold)) {
            uint256 ratio = (uint256(AVAXPosition) * adjustRatio) / lpPosition[0];
            lpPosition[0] = lpPosition[0] * ratio / PERCENTAGE_DECIMAL_FACTOR;
            lpPosition[1] = lpPosition[1] * ratio / PERCENTAGE_DECIMAL_FACTOR;
            return (true, short, lpPosition);
        }
    }

    /*//////////////////////////
     *    Other logic
     *//////////////////////////
    
    /*
     * @notice create path for uniswap style router
     * @dev if there is no direct path for the token pair, the intermidiate
     *      path (avax) will be taken before going to want
     */
    function _getPath(address _start) private view returns (address[] memory) {
        address[] memory path = new address[](2);
        if (_start == wavax) {
            path[0] = wavax;
            path[1] = address(want);
        } else if (_start == address(want)) {
            path[0] = address(want);
            path[1] = wavax;
        } else {
            path[0] = wavax;
            path[1] = _start;
        }
        return path;
    }

    /**
     * @notice
     *  Provide a signal to the keeper that `harvest()` should be called. The
     *  keeper will provide the estimated gas cost that they would pay to call
     *  `harvest()`, and this function should use that estimate to make a
     *  determination if calling it is "worth it" for the keeper. This is not
     *  the only consideration into issuing this trigger, for example if the
     *  position would be negatively affected if `harvest()` is not called
     *  shortly, then this can return `true` even if the keeper might be "at a
     *  loss".
     * @dev
     *  `_callCost` must be priced in terms of `want`.
     *
     *  It is expected that an external system will check `harvestTrigger()`.
     *  This could be a script run off a desktop or cloud bot.
     * @param _callCost The keeper's estimated cast cost to call `harvest()`.
     * @return `true` if `harvest()` should be called, `false` otherwise.
     */
    function harvestTrigger(uint256 _callCost)
        external
        view
        override
        returns (bool)
    {
        // Should not trigger if Strategy is not activated
        if (vault.strategies(address(this)).activation == 0) return false;

        // external view function, so we dont bother setting activePosition to a local variable
        if (!_ammCheck(decimals, address(want))) return false;
        (bool check, uint256 remainingLimit) = _checkPositionHealth(
            activePosition
        );
        if (check) return true;
        if (activePosition > 0) {
            (check, , ) = _calcAVAXExposure(activePosition, positions[activePosition].collateral);
            if (check) return true;
        }

        // If some amount is owed, pay it back
        // NOTE: Since debt is based on deposits, it makes sense to guard against large
        //       changes to the value from triggering a harvest directly through user
        //       behavior. This should ensure reasonable resistance to manipulation
        //       from user-initiated withdrawals as the outstanding debt fluctuates.
        uint256 outstanding = vault.debtOutstanding();
        if (outstanding > debtThreshold) return true;

        // Otherwise, only trigger if it "makes sense" economically
        uint256 credit = vault.creditAvailable();
        // Check if we theres enough assets to add to/open a new position
        if (remainingLimit >= minWant) {
            if (credit + want.balanceOf(address(this)) >= minWant) {
                return true;
            }
        }
        if (address(this).balance > 5E17) return true;
        return false;
    }

    /**
     * @notice
     *  Harvests the Strategy, recognizing any profits or losses and adjusting
     *  the Strategy's position.
     *
     *  In the rare case the Strategy is in emergency shutdown, this will exit
     *  the Strategy's position.
     *
     * @dev
     *  When `harvest()` is called, the Strategy reports to the Vault (via
     *  `vault.report()`), so in some cases `harvest()` must be called in order
     *  to take in profits, to borrow newly available funds from the Vault, or
     *  otherwise adjust its position. In other cases `harvest()` must be
     *  called to report to the Vault on the Strategy's position, especially if
     *  any losses have occurred. For the AHv2 strategy, the order of which
     *  accounting vs. position changes are made depends on if the position
     *  will be closed down or not.
     */
    function harvest() external override {
        require(msg.sender == address(vault), "!vault");
        uint256 profit = 0;
        uint256 loss = 0;
        uint256 debtOutstanding = vault.debtOutstanding();
        uint256 debtPayment = 0;

        // Check if position needs to be closed before accounting
        uint256 positionId = activePosition;
        if (emergencyExit) {
            // Free up as much capital as possible
            (uint256 totalAssets, ) = _estimatedTotalAssets(positionId);
            // NOTE: use the larger of total assets or debt outstanding to book losses properly
            (debtPayment, loss) = _liquidatePosition(
                totalAssets > debtOutstanding ? totalAssets : debtOutstanding
            );
            // NOTE: take up any remainder here as profit
            if (debtPayment > debtOutstanding) {
                profit = debtPayment - debtOutstanding;
                debtPayment = debtOutstanding;
            }
            positionId = 0;
        } else {
            require(_ammCheck(decimals, address(want)), "!ammCheck");
            // Free up returns for Vault to pull
            (profit, loss, debtPayment, positionId) = _prepareReturn(debtOutstanding, activePosition);
        }
        // Allow Vault to take up to the "harvested" balance of this contract,
        // which is the amount it has earned since the last time it reported to
        // the Vault.
        debtOutstanding = vault.report(profit, loss, debtPayment);

        // Check if free returns are left, and re-invest them
        _adjustPosition(positionId);
        emit LogHarvested(profit, loss, debtPayment, debtOutstanding);
    }

    // compare if the BP ratio between two value is GT or EQ to a target
    function compare(uint256 a, uint256 b, uint256 target) private view returns (bool) {
        return a * PERCENTAGE_DECIMAL_FACTOR / b >= target;
    }

    /*
     * @notice prepare this strategy for migrating to a new
     * @param _newStrategy address of migration target (not used here)
     */
    function _prepareMigration(address _newStrategy) internal override {
        require(activePosition == 0, "active position");
        require(address(this).balance == 0, "avax > 0");
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

struct StrategyParams {
    uint256 activation;
    bool active;
    uint256 debtRatio;
    uint256 minDebtPerHarvest;
    uint256 maxDebtPerHarvest;
    uint256 lastReport;
    uint256 totalDebt;
    uint256 totalGain;
    uint256 totalLoss;
}

interface IVault {
    function decimals() external view returns (uint256);

    function token() external view returns (address);

    function strategies(address _strategy)
        external
        view
        returns (StrategyParams memory);

    /**
     * View how much the Vault would increase this Strategy's borrow limit,
     * based on its present performance (since its last report). Can be used to
     * determine expectedReturn in your Strategy.
     */
    function creditAvailable() external view returns (uint256);

    /**
     * View how much the Vault would like to pull back from the Strategy,
     * based on its present performance (since its last report). Can be used to
     * determine expectedReturn in your Strategy.
     */
    function debtOutstanding() external view returns (uint256);

    function strategyDebt() external view returns (uint256);

    /**
     * This is the main contact point where the Strategy interacts with the
     * Vault. It is critical that this call is handled as intended by the
     * Strategy. Therefore, this function will be called by BaseStrategy to
     * make sure the integration is correct.
     */
    function report(
        uint256 _gain,
        uint256 _loss,
        uint256 _debtPayment
    ) external returns (uint256);

    /**
     * This function should only be used in the scenario where the Strategy is
     * being retired but no migration of the positions are possible, or in the
     * extreme scenario that the Strategy needs to be put into "Emergency Exit"
     * mode in order for it to exit as quickly as possible. The latter scenario
     * could be for any reason that is considered "critical" that the Strategy
     * exits its position as fast as possible, such as a sudden change in
     * market conditions leading to losses, or an imminent failure in an
     * external dependency.
     */
    function revokeStrategy() external;

    function owner() external view returns (address);
}

/**
 * @title Yearn Base Strategy
 * @author yearn.finance
 * @notice
 *  BaseStrategy implements all of the required functionality to interoperate
 *  closely with the Vault contract. This contract should be inherited and the
 *  abstract methods implemented to adapt the Strategy to the particular needs
 *  it has to create a return.
 *
 *  Of special interest is the relationship between `harvest()` and
 *  `vault.report()'. `harvest()` may be called simply because enough time has
 *  elapsed since the last report, and not because any funds need to be moved
 *  or positions adjusted. This is critical so that the Vault may maintain an
 *  accurate picture of the Strategy's performance. See  `vault.report()`,
 *  `harvest()`, and `harvestTrigger()` for further details.
 */
abstract contract BaseStrategy {
    using SafeERC20 for IERC20;

    IVault public vault;
    address public rewards;
    address public keeper;

    IERC20 public want;

    // So indexers can keep track of this
    event LogHarvested(
        uint256 profit,
        uint256 loss,
        uint256 debtPayment,
        uint256 debtOutstanding
    );
    event LogUpdatedKeeper(address newKeeper);
    event LogUpdatedRewards(address rewards);
    event LogUpdatedMinReportDelay(uint256 delay);
    event LogUpdatedMaxReportDelay(uint256 delay);
    event LogUpdatedDebtThreshold(uint256 debtThreshold);
    event LogEmergencyExitEnabled();

    // The minimum number of seconds between harvest calls. See
    // `setMinReportDelay()` for more details.
    uint256 public minReportDelay;

    // The maximum number of seconds between harvest calls. See
    // `setMaxReportDelay()` for more details.
    uint256 public maxReportDelay = 21600;

    // Use this to adjust the threshold at which running a debt causes a
    // harvest trigger. See `setDebtThreshold()` for more details.
    uint256 public debtThreshold;

    // See note on `setEmergencyExit()`.
    bool public emergencyExit;

    // modifiers
    modifier onlyAuthorized() {
        require(msg.sender == keeper || msg.sender == _owner(), "!authorized");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == _owner(), "!authorized");
        _;
    }

    constructor(address _vault) {
        vault = IVault(_vault);
        want = IERC20(IVault(_vault).token());
        want.safeApprove(_vault, type(uint256).max); // Give Vault unlimited access (might save gas)
    }

    function name() external view virtual returns (string memory);

    function setKeeper(address _keeper) external onlyOwner {
        require(_keeper != address(0), "setKeeper: _keeper == 0x");
        keeper = _keeper;
        emit LogUpdatedKeeper(_keeper);
    }

    /**
     * @notice
     *  Used to change `minReportDelay`. `minReportDelay` is the minimum number
     *  of blocks that should pass for `harvest()` to be called.
     *
     *  For external keepers (such as the Keep3r network), this is the minimum
     *  time between jobs to wait. (see `harvestTrigger()`
     *  for more details.)
     *
     * @param _delay The minimum number of seconds to wait between harvests.
     */
    function setMinReportDelay(uint256 _delay) external onlyAuthorized {
        require(
            _delay < maxReportDelay,
            "setMinReportDelay: _delay > maxReportDelay"
        );
        minReportDelay = _delay;
        emit LogUpdatedMinReportDelay(_delay);
    }

    /**
     * @notice
     *  Used to change `maxReportDelay`. `maxReportDelay` is the maximum number
     *  of blocks that should pass for `harvest()` to be called.
     *
     *  For external keepers (such as the Keep3r network), this is the maximum
     *  time between jobs to wait. (see `harvestTrigger()`
     *  for more details.)
     *
     * @param _delay The maximum number of seconds to wait between harvests.
     */
    function setMaxReportDelay(uint256 _delay) external onlyAuthorized {
        require(
            _delay > minReportDelay,
            "setMaxReportDelay: _delay < minReportDelay"
        );
        maxReportDelay = _delay;
        emit LogUpdatedMaxReportDelay(_delay);
    }

    /**
     * @notice
     *  Sets how far the Strategy can go into loss without a harvest and report
     *  being required.
     *
     *  By default this is 0, meaning any losses would cause a harvest which
     *  will subsequently report the loss to the Vault for tracking. (See
     *  `harvestTrigger()` for more details.)
     *
     * @param _debtThreshold How big of a loss this Strategy may carry without
     * being required to report to the Vault.
     */
    function setDebtThreshold(uint256 _debtThreshold)
        external
        virtual
        onlyAuthorized
    {
        debtThreshold = _debtThreshold;
        emit LogUpdatedDebtThreshold(_debtThreshold);
    }

    /**
     * Resolve owner address from Vault contract, used to make assertions
     * on protected functions in the Strategy.
     */
    function _owner() internal view returns (address) {
        return vault.owner();
    }

    /**
     * @notice
     *  Provide an accurate estimate for the total amount of assets
     *  (principle + return) that this Strategy is currently managing,
     *  denominated in terms of `want` tokens.
     *
     *  This total should be "realizable" e.g. the total value that could
     *  *actually* be obtained from this Strategy if it were to divest its
     *  entire position based on current on-chain conditions.
     * @dev
     *  Care must be taken in using this function, since it relies on external
     *  systems, which could be manipulated by the attacker to give an inflated
     *  (or reduced) value produced by this function, based on current on-chain
     *  conditions (e.g. this function is possible to influence through
     *  flashloan attacks, oracle manipulations, or other DeFi attack
     *  mechanisms).
     *
     *  It is up to owner to use this function to correctly order this
     *  Strategy relative to its peers in the withdrawal queue to minimize
     *  losses for the Vault based on sudden withdrawals. This value should be
     *  higher than the total debt of the Strategy and higher than its expected
     *  value to be "safe".
     * @return The estimated total assets in this Strategy.
     */
    function estimatedTotalAssets() external view virtual returns (uint256);

    /*
     * @notice
     *  Provide an indication of whether this strategy is currently "active"
     *  in that it is managing an active position, or will manage a position in
     *  the future. This should correlate to `harvest()` activity, so that Harvest
     *  events can be tracked externally by indexing agents.
     * @return True if the strategy is actively managing a position.
     */
    function isActive() public view returns (bool) {
        return vault.strategies(address(this)).active;
    }

    /**
     * Perform any Strategy unwinding or other calls necessary to capture the
     * "free return" this Strategy has generated since the last time its core
     * position(s) were adjusted. Examples include unwrapping extra rewards.
     * This call is only used during "normal operation" of a Strategy, and
     * should be optimized to minimize losses as much as possible.
     *
     * This method returns any realized profits and/or realized losses
     * incurred, and should return the total amounts of profits/losses/debt
     * payments (in `want` tokens) for the Vault's accounting (e.g.
     * `want.balanceOf(this) >= _debtPayment + _profit - _loss`).
     *
     * `_debtOutstanding` will be 0 if the Strategy is not past the configured
     * debt limit, otherwise its value will be how far past the debt limit
     * the Strategy is. The Strategy's debt limit is configured in the Vault.
     *
     * NOTE: `_debtPayment` should be less than or equal to `_debtOutstanding`.
     *       It is okay for it to be less than `_debtOutstanding`, as that
     *       should only used as a guide for how much is left to pay back.
     *       Payments should be made to minimize loss from slippage, debt,
     *       withdrawal fees, etc.
     *
     * See `vault.debtOutstanding()`.
     */
    // function _prepareReturn(uint256 _debtOutstanding)
    //     internal
    //     virtual
    //     returns (
    //         uint256 profit,
    //         uint256 loss,
    //         uint256 debtPayment
    //     );

    /**
     * Perform any adjustments to the core position(s) of this Strategy given
     * what change the Vault made in the "investable capital" available to the
     * Strategy. Note that all "free capital" in the Strategy after the report
     * was made is available for reinvestment. Also note that this number
     * could be 0, and you should handle that scenario accordingly.
     *
     * See comments regarding `_debtOutstanding` on `_prepareReturn()`.
     */
    // function _adjustPosition(uint256 _debtOutstanding) internal virtual;

    /**
     * Liquidate up to `_amountNeeded` of `want` of this strategy's positions,
     * irregardless of slippage. Any excess will be re-invested with `_adjustPosition()`.
     * This function should return the amount of `want` tokens made available by the
     * liquidation. If there is a difference between them, `_loss` indicates whether the
     * difference is due to a realized loss, or if there is some other sitution at play
     * (e.g. locked funds) where the amount made available is less than what is needed.
     * This function is used during emergency exit instead of `_prepareReturn()` to
     * liquidate all of the Strategy's positions back to the Vault.
     *
     * NOTE: The invariant `liquidatedAmount + loss <= _amountNeeded` should always be maintained
     */
    function _liquidatePosition(uint256 _amountNeeded)
        internal
        virtual
        returns (uint256 liquidatedAmount, uint256 loss);

    /**
     * @notice
     *  Provide a signal to the keeper that `tend()` should be called. The
     *  keeper will provide the estimated gas cost that they would pay to call
     *  `tend()`, and this function should use that estimate to make a
     *  determination if calling it is "worth it" for the keeper. This is not
     *  the only consideration into issuing this trigger, for example if the
     *  position would be negatively affected if `tend()` is not called
     *  shortly, then this can return `true` even if the keeper might be
     *  "at a loss" (keepers are always reimbursed by Yearn).
     * @dev
     *  `_callCost` must be priced in terms of `want`.
     *
     *  This call and `harvestTrigger()` should never return `true` at the same
     *  time.
     * @param _callCost The keeper's estimated cast cost to call `tend()`.
     * @return `true` if `tend()` should be called, `false` otherwise.
     */
    function tendTrigger(uint256 _callCost)
        external
        view
        virtual
        returns (bool)
    {}

    /**
     * @notice
     *  Adjust the Strategy's position. The purpose of tending isn't to
     *  realize gains, but to maximize yield by reinvesting any returns.
     *
     *  See comments on `_adjustPosition()`.
     *
     */
    function tend() external virtual onlyAuthorized {}

    /**
     * @notice
     *  Provide a signal to the keeper that `harvest()` should be called. The
     *  keeper will provide the estimated gas cost that they would pay to call
     *  `harvest()`, and this function should use that estimate to make a
     *  determination if calling it is "worth it" for the keeper. This is not
     *  the only consideration into issuing this trigger, for example if the
     *  position would be negatively affected if `harvest()` is not called
     *  shortly, then this can return `true` even if the keeper might be "at a
     *  loss" (keepers are always reimbursed by Yearn).
     * @dev
     *  `_callCost` must be priced in terms of `want`.
     *
     *  This call and `tendTrigger` should never return `true` at the
     *  same time.
     *
     *  See `min/maxReportDelay`, `debtThreshold`
     *  -controlled parameters that will influence whether this call
     *  returns `true` or not. These parameters will be used in conjunction
     *  with the parameters reported to the Vault (see `params`) to determine
     *  if calling `harvest()` is merited.
     *
     *  It is expected that an external system will check `harvestTrigger()`.
     *  This could be a script run off a desktop or cloud bot (e.g.
     *  https://github.com/iearn-finance/yearn-vaults/blob/master/scripts/keep.py),
     *  or via an integration with the Keep3r network (e.g.
     *  https://github.com/Macarse/GenericKeep3rV2/blob/master/contracts/keep3r/GenericKeep3rV2.sol).
     * @param _callCost The keeper's estimated cast cost to call `harvest()`.
     * @return `true` if `harvest()` should be called, `false` otherwise.
     */
    function harvestTrigger(uint256 _callCost)
        external
        view
        virtual
        returns (bool)
    {}

    /**
     * @notice
     *  Harvests the Strategy, recognizing any profits or losses and adjusting
     *  the Strategy's position.
     *
     *  In the rare case the Strategy is in emergency shutdown, this will exit
     *  the Strategy's position.
     *
     * @dev
     *  When `harvest()` is called, the Strategy reports to the Vault (via
     *  `vault.report()`), so in some cases `harvest()` must be called in order
     *  to take in profits, to borrow newly available funds from the Vault, or
     *  otherwise adjust its position. In other cases `harvest()` must be
     *  called to report to the Vault on the Strategy's position, especially if
     *  any losses have occurred.
     */
    function harvest() external virtual {}

    /**
     * @notice
     *  Withdraws `_amountNeeded` to `vault`.
     *
     *  This may only be called by the Vault.
     * @param _amountNeeded How much `want` to withdraw.
     * @return loss Any realized losses
     */
    function withdraw(uint256 _amountNeeded) external returns (uint256 loss) {
        require(msg.sender == address(vault), "!vault");
        // Liquidate as much as possible to `want`, up to `_amountNeeded`
        uint256 amountFreed;
        (amountFreed, loss) = _liquidatePosition(_amountNeeded);
        // Send it directly back (NOTE: Using `msg.sender` saves some gas here)
        if (amountFreed > 0) want.safeTransfer(msg.sender, amountFreed);
        // NOTE: Reinvest anything leftover on next `tend`/`harvest`
    }

    /**
     * Do anything necessary to prepare this Strategy for migration, such as
     * transferring any reserve or LP tokens, CDPs, or other tokens or stores of
     * value.
     */
    function _prepareMigration(address _newStrategy) internal virtual;

    /**
     * @notice
     *  Transfers all `want` from this Strategy to `_newStrategy`.
     *
     *  This may only be called by owner or the Vault.
     * @dev
     *  The new Strategy's Vault must be the same as this Strategy's Vault.
     * @param _newStrategy The Strategy to migrate to.
     */
    function migrate(address _newStrategy) external {
        require(msg.sender == address(vault));
        require(BaseStrategy(_newStrategy).vault() == vault);
        _prepareMigration(_newStrategy);
        want.safeTransfer(_newStrategy, want.balanceOf(address(this)));
    }

    /**
     * @notice
     *  Activates emergency exit. Once activated, the Strategy will exit its
     *  position upon the next harvest, depositing all funds into the Vault as
     *  quickly as is reasonable given on-chain conditions.
     *
     * @dev
     *  See `vault.setEmergencyShutdown()` and `harvest()` for further details.
     */
    function setEmergencyExit() external onlyAuthorized {
        emergencyExit = true;
        vault.revokeStrategy();

        emit LogEmergencyExitEnabled();
    }

    /**
     * Override this to add all tokens/tokenized positions this contract
     * manages on a *persistent* basis (e.g. not just for swapping back to
     * want ephemerally).
     *
     * NOTE: Do *not* include `want`, already included in `sweep` below.
     *
     * Example:
     *
     *    function _protectedTokens() internal override view returns (address[] memory) {
     *      address[] memory protected = new address[](3);
     *      protected[0] = tokenA;
     *      protected[1] = tokenB;
     *      protected[2] = tokenC;
     *      return protected;
     *    }
     */
    function _protectedTokens()
        internal
        view
        virtual
        returns (address[] memory)
    {}

    /**
     * @notice
     *  Removes tokens from this Strategy that are not the type of tokens
     *  managed by this Strategy. This may be used in case of accidentally
     *  sending the wrong kind of token to this Strategy.
     *
     *  Tokens will be sent to `_owner()`.
     *
     *  This will fail if an attempt is made to sweep `want`, or any tokens
     *  that are protected by this Strategy.
     *
     *  This may only be called by owner.
     * @dev
     *  Implement `_protectedTokens()` to specify any additional tokens that
     *  should be protected from sweeping in addition to `want`.
     * @param _token The token to transfer out of this vault.
     */
    function sweep(address _token) external onlyOwner {
        require(_token != address(want), "sweep: !want");
        require(_token != address(vault), "sweep: !shares");

        address[] memory protectedTokens = _protectedTokens();
        for (uint256 i; i < protectedTokens.length; i++)
            require(_token != protectedTokens[i], "sweep: !protected");

        IERC20(_token).safeTransfer(
            _owner(),
            IERC20(_token).balanceOf(address(this))
        );
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