// SPDX-License-Identifier: BSD-4-Clause
pragma solidity 0.8.3;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./IOddzAsset.sol";
import "../Pool/IOddzLiquidityPoolManager.sol";
import "./IOddzOptionPremiumManager.sol";
import "../IOddzAdministrator.sol";
import "../IOddzSDK.sol";
import "../Oracle/IOddzPriceOracleManager.sol";
import "../Oracle/IOddzIVOracleManager.sol";
import "../Libs/ABDKMath64x64.sol";
import "../Libs/IERC20Extented.sol";
import "./IOddzFeeManager.sol";

contract OddzOptionManager is IOddzOption, AccessControl {
    using Math for uint256;
    using SafeERC20 for IERC20Extented;
    using Address for address;

    bytes32 public constant TIMELOCKER_ROLE = keccak256("TIMELOCKER_ROLE");

    IOddzAsset public assetManager;
    IOddzLiquidityPoolManager public pool;
    IOddzPriceOracleManager public oracle;
    IOddzIVOracleManager public volatility;
    IOddzOptionPremiumManager public premiumManager;
    IERC20Extented public token;
    IOddzFeeManager public oddzFeeManager;
    OddzOptionManagerStorage public override optionStorage;

    /**
     * @dev Transaction Fee definitions
     */
    uint256 public txnFeeAggregate;

    /**
     * @dev Settlement Fee definitions
     */
    uint256 public settlementFeeAggregate;

    /**
     * @dev Max Deadline in seconds
     */
    uint32 public maxDeadline;

    /**
     * @dev SDK contract address
     */
    IOddzSDK public sdk;
    IOddzAdministrator public administrator;
    address public exerciser;
    address public secondaryMarket;

    /**
     * @dev minimum premium
     */
    uint256 public override minimumPremium;

    /**
     * @dev option transfer map
     * mapping (optionId => minAmount)
     */
    mapping(uint256 => uint256) public optionTransferMap;

    bool public exerciseBeforeExpireEnabled = true;

    constructor(
        IOddzPriceOracleManager _oracle,
        IOddzIVOracleManager _iv,
        IOddzLiquidityPoolManager _pool,
        IERC20Extented _token,
        IOddzAsset _assetManager,
        IOddzOptionPremiumManager _premiumManager,
        IOddzFeeManager _oddzFeeManager,
        address _optionStorage
    ) {
        pool = _pool;
        oracle = _oracle;
        volatility = _iv;
        token = _token;
        assetManager = _assetManager;
        premiumManager = _premiumManager;
        oddzFeeManager = _oddzFeeManager;
        optionStorage = OddzOptionManagerStorage(_optionStorage);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(TIMELOCKER_ROLE, msg.sender);
        _setRoleAdmin(TIMELOCKER_ROLE, TIMELOCKER_ROLE);
    }

    modifier onlyOwner(address _address) {
        require(hasRole(DEFAULT_ADMIN_ROLE, _address), "caller has no access to the method");
        _;
    }

    modifier onlyTimeLocker(address _address) {
        require(hasRole(TIMELOCKER_ROLE, _address), "caller has no access to the method");
        _;
    }

    function _validateOptionParams(address _pair, uint256 _expiration) private view {
        // validate asset pair
        require(assetManager.getStatusOfPair(_pair) == true, "Invalid Asset pair");
        // validate expiration
        require(_expiration <= assetManager.getMaxPeriod(_pair), "Expiration > max expiry");
        require(_expiration >= assetManager.getMinPeriod(_pair), "Expiration < min expiry");
    }

    /**
     * @notice get IV component for strike price
     * @param _iv implied volatility of the underlying asset
     * @param _ivDecimal iv precision
     * @param _isOTM OTM option?
     * @return ivComponent
     */
    function _getIvForStrike(
        uint256 _iv,
        uint256 _expiry,
        uint8 _ivDecimal,
        bool _isOTM
    ) private pure returns (int128 ivComponent) {
        // If IV is 100% (which is for a year from now), then at 1 month (30 days)
        // it should be 100% * sqrt(30/365) = 28.86% change in price with 68% probability
        // In order to compensate for the highly volatile market, we will be locking four times period value for OTM
        // i.e. for 1 month (30 days) => If IV is 100% then 100% * sqrt(30 * 4 /365) = 57.33%
        uint256 maxExpiry = _expiry;
        if (_isOTM) maxExpiry *= 4;
        uint256 maxDivident = 365 days;
        ivComponent = ABDKMath64x64.mul(
            ABDKMath64x64.divu((_iv), 10**_ivDecimal),
            ABDKMath64x64.sqrt(ABDKMath64x64.divu(maxDivident.min(maxExpiry), 365 days))
        );
    }

    /**
     * @notice get maximum strike price
     * @param _cp current price of the underlying asset
     * @param _iv implied volatility of the underlying asset
     * @param _ivDecimal iv precision
     * @param _isOTM OTM option?
     * @return oc - over collateralization
     */
    function _getMaxStrikePrice(
        uint256 _cp,
        uint256 _iv,
        uint256 _expiry,
        uint8 _ivDecimal,
        bool _isOTM
    ) private pure returns (uint256 oc) {
        // fetch highest call price using IV
        oc =
            (_cp *
                ABDKMath64x64.mulu(
                    ABDKMath64x64.exp(_getIvForStrike(_iv, _expiry, _ivDecimal, _isOTM)),
                    10**_ivDecimal
                )) /
            10**_ivDecimal;
    }

    /**
     * @notice get minimum strike price
     * @param _cp current price of the underlying asset
     * @param _iv implied volatility of the underlying asset
     * @param _ivDecimal iv precision
     * @param _isOTM OTM option?
     * @return oc - over collateralization
     */
    function _getMinStrikePrice(
        uint256 _cp,
        uint256 _iv,
        uint256 _expiry,
        uint8 _ivDecimal,
        bool _isOTM
    ) private pure returns (uint256 oc) {
        // fetch lowest put price using IV
        // use negative IV for put
        oc =
            (_cp *
                ABDKMath64x64.mulu(
                    ABDKMath64x64.exp(-_getIvForStrike(_iv, _expiry, _ivDecimal, _isOTM)),
                    10**_ivDecimal
                )) /
            10**_ivDecimal;
    }

    /**
     * @notice get current price of the given asset
     * @param _pair asset pair
     * @return cp - current price of the underlying asset
     */
    function _getCurrentPrice(IOddzAsset.AssetPair memory _pair) private view returns (uint256 cp) {
        uint8 decimal;
        // retrieving struct if more than one field is used, to reduce gas for memory storage
        IOddzAsset.Asset memory primary = assetManager.getAsset(_pair._primary);
        (cp, decimal) = oracle.getUnderlyingPrice(primary._name, _pair._strike);
        cp = _updatePrecision(cp, decimal, primary._precision);
    }

    /**
     * @notice get historical price of the given asset
     * @param _pair asset pair
     * @param _referenceId roundId of the oracle
     * @return price - price of the underlying asset
     */
    function _getHistoricalPrice(
        IOddzAsset.AssetPair memory _pair,
        uint256 _optionExpiry,
        uint256 _referenceId
    ) private view returns (uint256 price) {
        uint8 decimal;
        // retrieving struct if more than one field is used, to reduce gas for memory storage
        IOddzAsset.Asset memory primary = assetManager.getAsset(_pair._primary);
        (price, decimal) = oracle.getHistoricalPrice(primary._name, _pair._strike, _optionExpiry, _referenceId);

        price = _updatePrecision(price, decimal, primary._precision);
    }

    /**
     * @notice get amount that should be locked
     * @param _cp current price of the underlying asset
     * @param _strike strike price provided by the option buyer
     * @param _expiry option expiration timestamp
     * @param _quantity option quantity
     * @param _pair Asset pair
     * @param _iv implied volatility of the underlying asset
     * @param _ivDecimal iv precision
     * @return lockAmount pool lock amount
     */
    function _getLockAmount(
        uint256 _cp,
        uint256 _strike,
        uint256 _expiry,
        uint256 _quantity,
        address _pair,
        uint256 _iv,
        uint8 _ivDecimal,
        OptionType _optionType
    ) private view returns (uint256 lockAmount) {
        IOddzAsset.Asset memory primary = assetManager.getAsset(assetManager.getPrimaryFromPair(_pair));
        bool isOTM = false;
        if ((_optionType == OptionType.Call && _strike > _cp) || (_optionType == OptionType.Put && _cp > _strike))
            isOTM = true;
        uint256 minAssetPrice = _getMinStrikePrice(_cp, _iv, _expiry, _ivDecimal, isOTM);
        uint256 maxAssetPrice = _getMaxStrikePrice(_cp, _iv, _expiry, _ivDecimal, isOTM);
        // validate strike price within given range
        require(_strike <= maxAssetPrice && _strike >= minAssetPrice, "Strike out of Range");
        // limit call over collateral to _strike i.e. max profit is limited to _strike
        uint256 overColl;
        if (_optionType == OptionType.Call)
            overColl = _updatePrecision(maxAssetPrice.min(_strike), primary._precision, token.decimals());
        else overColl = _updatePrecision(_strike - minAssetPrice, primary._precision, token.decimals());
        lockAmount = (overColl * _quantity) / 1e18;
    }

    /**
     * @notice Create option
     * @param _details option buy details
     * @param _premiumWithSlippage Options details
     * @param _buyer Address of buyer
     * @return optionId newly created Option Id
     */
    function _createOption(
        OptionDetails memory _details,
        uint256 _premiumWithSlippage,
        address _buyer
    ) private returns (uint256 optionId) {
        PremiumResult memory premiumResult = getPremium(_details, _buyer);
        require(_premiumWithSlippage >= premiumResult.optionPremium, "Premium crossed slippage tolerance");
        uint256 cp = _getCurrentPrice(assetManager.getPair(_details._pair));
        uint256 totalPremium = premiumResult.optionPremium + premiumResult.txnFee;
        require(totalPremium >= minimumPremium, "amount < minimum premium");
        require(token.allowance(_buyer, address(this)) >= totalPremium, "Premium is low");

        uint256 lockAmount =
            _getLockAmount(
                cp,
                _details._strike,
                _details._expiration,
                _details._amount,
                _details._pair,
                premiumResult.iv,
                premiumResult.ivDecimal,
                _details._optionType
            );
        optionId = optionStorage.getOptionsCount();

        optionStorage.createOption(
            Option(
                State.Active,
                _buyer,
                _details._strike,
                _details._amount,
                lockAmount,
                premiumResult.optionPremium,
                _details._expiration + block.timestamp,
                _details._pair,
                _details._optionType
            )
        );
        IOddzLiquidityPoolManager.LiquidityParams memory liquidityParams =
            IOddzLiquidityPoolManager.LiquidityParams(
                lockAmount,
                _details._expiration,
                _details._pair,
                _details._optionModel,
                _details._strike,
                cp,
                _details._optionType
            );
        pool.lockLiquidity(optionId, liquidityParams, premiumResult.optionPremium);
        txnFeeAggregate += premiumResult.txnFee;

        token.safeTransferFrom(_buyer, address(pool), premiumResult.optionPremium);
        token.safeTransferFrom(_buyer, address(this), premiumResult.txnFee);

        emit Buy(
            optionId,
            _buyer,
            _details._optionModel,
            premiumResult.txnFee,
            premiumResult.optionPremium + premiumResult.txnFee,
            _details._pair
        );
    }

    function buy(
        OptionDetails memory _details,
        uint256 _premiumWithSlippage,
        address _buyer
    ) external override returns (uint256 optionId) {
        _validateOptionParams(_details._pair, _details._expiration);
        // validate Amount
        require(_details._amount >= assetManager.getPurchaseLimit(_details._pair), "Quantity < purchase limit");
        address buyer_ = msg.sender == address(sdk) ? _buyer : msg.sender;
        optionId = _createOption(_details, _premiumWithSlippage, buyer_);
    }

    /**
     * @notice Used for getting the actual options prices
     * @param _option Option details
     * @param _buyer Address of option buyer
     * @return premiumResult Premium, iv  Details
     */
    function getPremium(OptionDetails memory _option, address _buyer)
        public
        view
        override
        returns (PremiumResult memory premiumResult)
    {
        _validateOptionParams(_option._pair, _option._expiration);
        (premiumResult.ivDecimal, premiumResult.iv, premiumResult.optionPremium) = _getOptionPremiumDetails(_option);

        premiumResult.txnFee = getTransactionFee(premiumResult.optionPremium, _buyer);
    }

    function _getOptionPremiumDetails(OptionDetails memory optionDetails)
        private
        view
        returns (
            uint8 ivDecimal,
            uint256 iv,
            uint256 optionPremium
        )
    {
        IOddzAsset.AssetPair memory pair = assetManager.getPair(optionDetails._pair);
        uint256 price = _getCurrentPrice(pair);
        (iv, ivDecimal) = volatility.calculateIv(
            pair._primary,
            pair._strike,
            optionDetails._expiration,
            price,
            optionDetails._strike
        );

        optionPremium = premiumManager.getPremium(
            optionDetails._optionType == IOddzOption.OptionType.Call ? true : false,
            assetManager.getPrecision(pair._primary),
            ivDecimal,
            price,
            optionDetails._strike,
            optionDetails._expiration,
            optionDetails._amount,
            iv,
            optionDetails._optionModel
        );
        // convert to USD price precision
        optionPremium = _updatePrecision(optionPremium, assetManager.getPrecision(pair._primary), token.decimals());
    }

    /**
     * @notice Used for cash settlement excerise for an active option
     * @param _optionId Option id
     */
    function exercise(uint256 _optionId) external override {
        Option memory option = optionStorage.getOption(_optionId);
        require(msg.sender == option.holder || msg.sender == exerciser, "Invalid Caller");
        require(option.expiration >= block.timestamp, "Option has expired");
        (uint256 profit, uint256 settlementFee) = getProfit(_optionId);

        _exercise(_optionId, option, _getCurrentPrice(assetManager.getPair(option.pair)), profit, settlementFee);
    }

    function _exercise(
        uint256 _optionId,
        Option memory _option,
        uint256 _price,
        uint256 _profit,
        uint256 _settlementFee
    ) private {
        require(_option.state == State.Active, "Invalid state");

        optionStorage.setOptionStatus(_optionId, State.Exercised);
        settlementFeeAggregate += _settlementFee;
        pool.send(_optionId, _option.holder, _profit, _settlementFee);

        emit Exercise(_optionId, _profit, _settlementFee, ExcerciseType.Cash, _price);
    }

    /**
     * @notice Used for physical settlement excerise for an active option
     * @param _optionId Option id
     * @param _deadline Deadline until which txn does not revert
     * @param _minAmountOut Min output tokens
     */
    function exerciseUA(
        uint256 _optionId,
        uint32 _deadline,
        uint256 _minAmountOut
    ) external override {
        require(_deadline <= maxDeadline, "Invalid Deadline");
        Option memory option = optionStorage.getOption(_optionId);
        require(option.holder == msg.sender, "Invalid Caller");
        require(option.expiration >= block.timestamp, "Option has expired");
        require(option.state == State.Active, "Invalid state");

        (uint256 profit, uint256 settlementFee) = getProfit(_optionId);

        optionStorage.setOptionStatus(_optionId, State.Exercised);
        settlementFeeAggregate += settlementFee;
        IOddzAsset.AssetPair memory pair = assetManager.getPair(option.pair);

        pool.sendUA(
            _optionId,
            option.holder,
            profit,
            settlementFee,
            pair._primary,
            pair._strike,
            _deadline,
            _minAmountOut
        );

        emit Exercise(
            _optionId,
            profit,
            settlementFee,
            ExcerciseType.Physical,
            _getCurrentPrice(assetManager.getPair(option.pair))
        );
    }

    /**
     * @notice Transaction fee calculation for the option premium
     * @param _amount Option premium
     * @param _buyer Option buyer address
     * @return txnFee Transaction Fee
     */
    function getTransactionFee(uint256 _amount, address _buyer) public view override returns (uint256 txnFee) {
        txnFee = ((_amount * oddzFeeManager.getTransactionFee(_buyer)) / (100 * 10**oddzFeeManager.decimals()));
    }

    function setTransactionFee(uint256 _amount) public override {
        require(msg.sender == secondaryMarket, "cannot add txn fee");
        txnFeeAggregate += _amount;
    }

    /**
     * @notice get profits in USD for an option
     * @param _optionId ID of the option
     * @return profit Profit from the option
     * @return settlementFee Settlement fee deducted from profit
     */
    function getProfit(uint256 _optionId) public view override returns (uint256 profit, uint256 settlementFee) {
        Option memory option = optionStorage.getOption(_optionId);
        IOddzAsset.AssetPair memory pair = assetManager.getPair(option.pair);
        uint256 _cp = _getCurrentPrice(pair);

        if (option.optionType == OptionType.Call) {
            require(option.strike <= _cp, "Call: Cp is too low");
            profit = (_cp - option.strike) * option.amount;
        } else {
            require(option.strike >= _cp, "Put: Cp is too high");
            profit = (option.strike - _cp) * option.amount;
        }
        // amount in wei
        profit = profit / 1e18;

        // convert profit to usd decimals
        profit = _updatePrecision(profit, assetManager.getPrecision(pair._primary), token.decimals());

        if (profit > option.lockedAmount) profit = option.lockedAmount;

        settlementFee = ((profit * oddzFeeManager.getSettlementFee(option.holder)) /
            (100 * 10**oddzFeeManager.decimals()));
        profit -= settlementFee;
    }

    /**
     * @notice get profits in USD at expiration
     * @param _optionId ID of the option
     * @param _price Asset price
     * @return profit Profit from the option
     * @return settlementFee Settlement fee deducted from profit
     */
    function _getProfitAtExpiration(uint256 _optionId, uint256 _price)
        private
        view
        returns (uint256 profit, uint256 settlementFee)
    {
        Option memory option = optionStorage.getOption(_optionId);

        if (option.optionType == OptionType.Call) {
            if (option.strike > _price) return (0, 0);
            profit = (_price - option.strike) * option.amount;
        } else {
            if (option.strike < _price) return (0, 0);
            profit = (option.strike - _price) * option.amount;
        }
        // amount in wei
        profit = profit / 1e18;

        // convert profit to usd decimals
        profit = _updatePrecision(
            profit,
            assetManager.getPrecision((assetManager.getPair(option.pair))._primary),
            token.decimals()
        );

        if (profit > option.lockedAmount) profit = option.lockedAmount;

        settlementFee = ((profit * oddzFeeManager.getSettlementFee(option.holder)) /
            (100 * 10**oddzFeeManager.decimals()));
        profit -= settlementFee;
    }

    /**
     * @notice Unlock funds locked in the expired options
     * @param _optionId ID of the option
     * @param _referenceId referenceId of the oracle
     */
    function unlock(uint256 _optionId, uint256 _referenceId) public {
        Option memory option = optionStorage.getOption(_optionId);
        require(option.expiration < block.timestamp, "Option has not expired yet");
        require(option.state == State.Active, "Option is not active");
        IOddzAsset.AssetPair memory pair = assetManager.getPair(option.pair);
        uint256 profit;
        uint256 settlementFee;
        uint256 price;
        if (exerciseBeforeExpireEnabled) {
            price = _getHistoricalPrice(pair, option.expiration, _referenceId);
            (profit, settlementFee) = _getProfitAtExpiration(_optionId, price);
        }
        if (profit >= oddzFeeManager.getMinProfitForAutoExercise(option.holder) && profit > 0)
            _exercise(_optionId, option, price, profit, settlementFee);
        else {
            optionStorage.setOptionStatus(_optionId, State.Expired);
            pool.unlockLiquidity(_optionId);
            if (price > 0) emit Expire(_optionId, option.premium, price);
            else emit Expire(_optionId, option.premium, _getCurrentPrice(pair));
        }
    }

    /**
     * @notice Unlocks an array of options
     * @param _optionIds array of options
     * @param _referenceIds RoundId of the oracle
     */
    function unlockAll(uint256[] calldata _optionIds, uint256[] calldata _referenceIds) external {
        require(_optionIds.length == _referenceIds.length, "invalid input");
        uint256 arrayLength = _optionIds.length;
        for (uint256 i = 0; i < arrayLength; i++) {
            unlock(_optionIds[i], _referenceIds[i]);
        }
    }

    /**
     * @notice sets maximum deadline for DEX swap
     * @param _deadline maximum swap transaction time
     */
    function setMaxDeadline(uint32 _deadline) external onlyOwner(msg.sender) {
        maxDeadline = _deadline;
    }

    /**
     * @notice sets SDK address
     * @param _sdk Oddz SDK address
     */
    function setSdk(IOddzSDK _sdk) external onlyTimeLocker(msg.sender) {
        require(address(_sdk).isContract(), "invalid SDK address");
        sdk = _sdk;
    }

    /**
     * @notice sets administrator address
     * @param _administrator Oddz administrator address
     */
    function setAdministrator(IOddzAdministrator _administrator) external onlyTimeLocker(msg.sender) {
        require(address(_administrator).isContract(), "invalid administrator address");
        // Set token allowance of previous administrator to 0
        if (address(administrator) != address(0)) token.safeApprove(address(administrator), 0);

        administrator = _administrator;

        // Approve token transfer to administrator contract
        token.safeApprove(address(administrator), type(uint256).max);
    }

    function setMinimumPremium(uint256 _amount) external onlyTimeLocker(msg.sender) {
        uint256 amount = _amount / 10**token.decimals();
        require(amount >= 1 && amount < 50, "invalid minimum premium");
        minimumPremium = _amount;
    }

    function enableExerciseBeforeExpire(bool _enable) external onlyTimeLocker(msg.sender) {
        exerciseBeforeExpireEnabled = _enable;
    }

    function setTimeLocker(address _address) external {
        require(_address != address(0), "Invalid timelocker address");
        grantRole(TIMELOCKER_ROLE, _address);
    }

    function removeTimeLocker(address _address) external {
        revokeRole(TIMELOCKER_ROLE, _address);
    }

    /**
     * @notice transfer transaction fee to beneficiary
     */
    function transferTxnFeeToBeneficiary(uint256 _minAmountsOut) external onlyOwner(msg.sender) {
        uint256 txnFee = txnFeeAggregate;
        txnFeeAggregate = 0;

        require(address(administrator) != address(0), "invalid administrator address");
        administrator.deposit(txnFee, IOddzAdministrator.DepositType.Transaction, _minAmountsOut);
    }

    /**
     * @notice transfer settlement fee to beneficiary
     */
    function transferSettlementFeeToBeneficiary(uint256 _minAmountsOut) external onlyOwner(msg.sender) {
        uint256 settlementFee = settlementFeeAggregate;
        settlementFeeAggregate = 0;

        require(address(administrator) != address(0), "invalid administrator address");
        administrator.deposit(settlementFee, IOddzAdministrator.DepositType.Settlement, _minAmountsOut);
    }

    /**
     * @notice update precision from current to required
     * @param _value value to be precision updated
     * @param _current current precision
     * @param _required required precision
     * @return result updated _value
     */
    function _updatePrecision(
        uint256 _value,
        uint8 _current,
        uint8 _required
    ) private pure returns (uint256 result) {
        result = (_value * (10**_required)).ceilDiv(10**_current);
    }

    function setExerciser(address _exerciser) external onlyTimeLocker(msg.sender) {
        exerciser = _exerciser;
    }

    function setSecondaryMarket(address _secondaryMarket) external onlyTimeLocker(msg.sender) {
        secondaryMarket = _secondaryMarket;
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

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

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
abstract contract AccessControl is Context, IAccessControl, ERC165 {
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
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
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
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
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
     * If the calling account had been granted `role`, emits a {RoleRevoked}
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

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: BSD-4-Clause
pragma solidity 0.8.3;

interface IOddzAsset {
    struct Asset {
        address _address;
        uint8 _precision;
        bool _active;
        bytes32 _name;
    }

    struct AssetPair {
        bytes32 _primary;
        bytes32 _strike;
        address _address;
        bool _active;
        uint256 _limit;
        uint256 _maxDays;
        uint256 _minDays;
    }

    // Asset functions
    function getAsset(bytes32 _asset) external view returns (Asset memory asset);

    function getPrecision(bytes32 _asset) external view returns (uint8 precision);

    function getAssetAddressByName(bytes32 _asset) external view returns (address asset);

    // Asset pair functions
    function getPair(address _address) external view returns (AssetPair memory pair);

    function getPrimaryFromPair(address _address) external view returns (bytes32 primary);

    function getStatusOfPair(address _address) external view returns (bool status);

    function getPurchaseLimit(address _address) external view returns (uint256 limit);

    function getMaxPeriod(address _address) external view returns (uint256 maxPeriod);

    function getMinPeriod(address _address) external view returns (uint256 minPeriod);
}

// SPDX-License-Identifier: BSD-4-Clause
pragma solidity 0.8.3;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./IOddzLiquidityPool.sol";
import "../Option/IOddzOption.sol";

/**
 * @title Oddz USD Liquidity Pool
 * @notice Accumulates liquidity in USD from LPs
 */
interface IOddzLiquidityPoolManager {
    struct LockedLiquidity {
        uint256 _amount;
        uint256 _premium;
        bool _locked;
        address[] _pools;
        uint256[] _share;
    }

    struct LiquidityParams {
        uint256 _amount;
        uint256 _expiration;
        address _pair;
        bytes32 _model;
        uint256 _strike;
        uint256 _cp;
        IOddzOption.OptionType _type;
    }

    /**
     * @dev Pool transfer
     */
    struct PoolTransfer {
        IOddzLiquidityPool[] _source;
        IOddzLiquidityPool[] _destination;
        uint256[] _sAmount;
        uint256[] _dAmount;
    }

    /**
     * @notice A provider supplies USD pegged stablecoin to the pool and receives oUSD tokens
     * @param _provider Liquidity provider
     * @param _pool Liquidity pool
     * @param _amount Amount in USD
     * @return mint Amount of tokens minted
     */
    function addLiquidity(
        address _provider,
        IOddzLiquidityPool _pool,
        uint256 _amount
    ) external returns (uint256 mint);

    /**
     * @notice Provider burns oUSD and receives USD from the pool
     * @param _provider Liquidity provider
     * @param _pool Remove liquidity from a pool
     * @param _amount Amount of USD to receive
     */
    function removeLiquidity(
        address _provider,
        IOddzLiquidityPool _pool,
        uint256 _amount
    ) external;

    /**
     * @notice called by Oddz call options to lock the funds
     * @param _id Id of the LockedLiquidity same as option Id
     * @param _liquidityParams liquidity related parameters
     * @param _premium Premium that should be locked in an option
     */

    function lockLiquidity(
        uint256 _id,
        LiquidityParams memory _liquidityParams,
        uint256 _premium
    ) external;

    /**
     * @notice called by Oddz option to unlock the funds
     * @param _id Id of LockedLiquidity that should be unlocked
     */
    function unlockLiquidity(uint256 _id) external;

    /**
     * @notice called by Oddz call options to send funds in USD to LPs after an option's expiration
     * @param _id Id of LockedLiquidity that should be unlocked
     * @param _account Provider account address
     * @param _amount Funds that should be sent
     * @param _settlementFee Settlement Fee
     */
    function send(
        uint256 _id,
        address _account,
        uint256 _amount,
        uint256 _settlementFee
    ) external;

    /**
     * @notice called by Oddz call options to send funds in UA to LPs after an option's expiration
     * @param _id Id of LockedLiquidity that should be unlocked
     * @param _account Provider account address
     * @param _amount Funds that should be sent
     * @param _settlementFee Settlement Fee
     * @param _underlying underlying asset name
     * @param _strike strike asset name
     * @param _deadline deadline until which txn does not revert
     * @param _minAmountsOut min output tokens
     */
    function sendUA(
        uint256 _id,
        address _account,
        uint256 _amount,
        uint256 _settlementFee,
        bytes32 _underlying,
        bytes32 _strike,
        uint32 _deadline,
        uint256 _minAmountsOut
    ) external;

    /**
     * @notice Move liquidity between pools
     * @param _provider Liquidity provider
     * @param _poolTransfer source and destination pools with amount of transfer
     */
    function move(address _provider, PoolTransfer memory _poolTransfer) external;

    /**
     * @notice Get validity of pool
     * @param _pool address of pool
     */
    function poolExposure(IOddzLiquidityPool _pool) external view returns (uint256);
}

// SPDX-License-Identifier: BSD-4-Clause
pragma solidity 0.8.3;

interface IOddzOptionPremiumManager {
    /**
     * @notice Function to get option premium
     * @param _isCallOption True if the option type is CALL, false for PUT.
     * @param _precision current price and strike price precision
     * @param _currentPrice underlying asset current price
     * @param _strikePrice underlying asset strike price
     * @param _expiration Option period in unix timestamp
     * @param _amount Option amount
     * @param _iv implied volatility of the underlying asset
     * @param _model option premium model identifier
     * @return premium option premium amount
     */
    function getPremium(
        bool _isCallOption,
        uint8 _precision,
        uint8 _ivDecimal,
        uint256 _currentPrice,
        uint256 _strikePrice,
        uint256 _expiration,
        uint256 _amount,
        uint256 _iv,
        bytes32 _model
    ) external view returns (uint256 premium);
}

// SPDX-License-Identifier: BSD-4-Clause
pragma solidity 0.8.3;

interface IOddzAdministrator {
    enum DepositType { Transaction, Settlement }

    /**
     * @dev Emitted when txn fee and settlement fee is deposited
     * @param _sender Address of the depositor
     * @param _type  DepositType (Transaction or Settlement)
     * @param _amount Amount deposited
     */
    event Deposit(address indexed _sender, DepositType indexed _type, uint256 _amount);

    function deposit(
        uint256 _amount,
        DepositType _depositType,
        uint256 _minAmountsOut
    ) external;
}

// SPDX-License-Identifier: BSD-4-Clause
pragma solidity 0.8.3;

import "./Option/IOddzOption.sol";

interface IOddzSDK {
    event OptionProvider(uint256 indexed _month, address indexed _provider);

    function buy(
        address _pair,
        bytes32 _optionModel,
        uint256 _premiumWithSlippage,
        uint256 _expiration,
        uint256 _amount,
        uint256 _strike,
        IOddzOption.OptionType _optionType,
        address _provider,
        address _buyer
    ) external returns (uint256 optionId);

    function buyWithGasless(
        address _pair,
        bytes32 _optionModel,
        uint256 _premiumWithSlippage,
        uint256 _expiration,
        uint256 _amount,
        uint256 _strike,
        IOddzOption.OptionType _optionType,
        address _provider
    ) external returns (uint256 optionId);

    function getPremium(
        address _pair,
        bytes32 _optionModel,
        uint256 _expiration,
        uint256 _amount,
        uint256 _strike,
        IOddzOption.OptionType _optionType
    )
        external
        view
        returns (
            uint256 optionPremium,
            uint256 txnFee,
            uint256 iv,
            uint8 ivDecimal
        );

    function allocateOddzReward(uint256 _amount) external;

    function distributeReward(address[] memory _providers, uint256 _month) external;

    function minimumGaslessPremium() external returns (uint256);
}

// SPDX-License-Identifier: BSD-4-Clause
pragma solidity 0.8.3;

interface IOddzPriceOracleManager {
    function getUnderlyingPrice(bytes32 _underlying, bytes32 _strike)
        external
        view
        returns (uint256 price, uint8 decimal);

    /**
     * @notice Function to fetch historical price
     * @param _underlying Underlying Asset
     * @param _strike Strike Asset
     * @param _timestamp price at the timestamp
     * @param _referenceId oracle reference
     * @return price historical asset price
     * @return decimals asset price decimals
     */
    function getHistoricalPrice(
        bytes32 _underlying,
        bytes32 _strike,
        uint256 _timestamp,
        uint256 _referenceId
    ) external view returns (uint256 price, uint8 decimals);
}

// SPDX-License-Identifier: BSD-4-Clause
pragma solidity 0.8.3;

interface IOddzIVOracleManager {
    function calculateIv(
        bytes32 _underlying,
        bytes32 _strike,
        uint256 _expiration,
        uint256 _currentPrice,
        uint256 _strikePrice
    ) external view returns (uint256 iv, uint8 decimals);
}

// SPDX-License-Identifier: BSD-4-Clause
/*
 * ABDK Math 64.64 Smart Contract Library.  Copyright © 2019 by ABDK Consulting.
 * Author: Mikhail Vladimirov <[email protected]>
 */
pragma solidity 0.8.3;

/**
 * Smart contract library of mathematical functions operating with signed
 * 64.64-bit fixed point numbers.  Signed 64.64-bit fixed point number is
 * basically a simple fraction whose numerator is signed 128-bit integer and
 * denominator is 2^64.  As long as denominator is always the same, there is no
 * need to store it, thus in Solidity signed 64.64-bit fixed point numbers are
 * represented by int128 type holding only the numerator.
 */
library ABDKMath64x64 {
    /*
     * Minimum value signed 64.64-bit fixed point number may have.
     */
    int128 private constant MIN_64x64 = -0x80000000000000000000000000000000;

    /*
     * Maximum value signed 64.64-bit fixed point number may have.
     */
    int128 private constant MAX_64x64 = 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

    /**
     * Convert signed 256-bit integer number into signed 64.64-bit fixed point
     * number.  Revert on overflow.
     *
     * @param x signed 256-bit integer number
     * @return signed 64.64-bit fixed point number
     */
    function fromInt(int256 x) internal pure returns (int128) {
        unchecked {
            require(x >= -0x8000000000000000 && x <= 0x7FFFFFFFFFFFFFFF);
            return int128(x << 64);
        }
    }

    /**
     * Convert signed 64.64 fixed point number into signed 64-bit integer number
     * rounding down.
     *
     * @param x signed 64.64-bit fixed point number
     * @return signed 64-bit integer number
     */
    function toInt(int128 x) internal pure returns (int64) {
        unchecked {
            return int64(x >> 64);
        }
    }

    /**
     * Convert unsigned 256-bit integer number into signed 64.64-bit fixed point
     * number.  Revert on overflow.
     *
     * @param x unsigned 256-bit integer number
     * @return signed 64.64-bit fixed point number
     */
    function fromUInt(uint256 x) internal pure returns (int128) {
        unchecked {
            require(x <= 0x7FFFFFFFFFFFFFFF);
            return int128(int256(x << 64));
        }
    }

    /**
     * Convert signed 64.64 fixed point number into unsigned 64-bit integer
     * number rounding down.  Revert on underflow.
     *
     * @param x signed 64.64-bit fixed point number
     * @return unsigned 64-bit integer number
     */
    function toUInt(int128 x) internal pure returns (uint64) {
        unchecked {
            require(x >= 0);
            return uint64(uint128(x >> 64));
        }
    }

    /**
     * Convert signed 128.128 fixed point number into signed 64.64-bit fixed point
     * number rounding down.  Revert on overflow.
     *
     * @param x signed 128.128-bin fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function from128x128(int256 x) internal pure returns (int128) {
        unchecked {
            int256 result = x >> 64;
            require(result >= MIN_64x64 && result <= MAX_64x64);
            return int128(result);
        }
    }

    /**
     * Convert signed 64.64 fixed point number into signed 128.128 fixed point
     * number.
     *
     * @param x signed 64.64-bit fixed point number
     * @return signed 128.128 fixed point number
     */
    function to128x128(int128 x) internal pure returns (int256) {
        unchecked {
            return int256(x) << 64;
        }
    }

    /**
     * Calculate x + y.  Revert on overflow.
     *
     * @param x signed 64.64-bit fixed point number
     * @param y signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function add(int128 x, int128 y) internal pure returns (int128) {
        unchecked {
            int256 result = int256(x) + y;
            require(result >= MIN_64x64 && result <= MAX_64x64);
            return int128(result);
        }
    }

    /**
     * Calculate x - y.  Revert on overflow.
     *
     * @param x signed 64.64-bit fixed point number
     * @param y signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function sub(int128 x, int128 y) internal pure returns (int128) {
        unchecked {
            int256 result = int256(x) - y;
            require(result >= MIN_64x64 && result <= MAX_64x64);
            return int128(result);
        }
    }

    /**
     * Calculate x * y rounding down.  Revert on overflow.
     *
     * @param x signed 64.64-bit fixed point number
     * @param y signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function mul(int128 x, int128 y) internal pure returns (int128) {
        unchecked {
            int256 result = (int256(x) * y) >> 64;
            require(result >= MIN_64x64 && result <= MAX_64x64);
            return int128(result);
        }
    }

    /**
     * Calculate x * y rounding down, where x is signed 64.64 fixed point number
     * and y is unsigned 256-bit integer number.  Revert on overflow.
     *
     * @param x signed 64.64 fixed point number
     * @param y unsigned 256-bit integer number
     * @return unsigned 256-bit integer number
     */
    function mulu(int128 x, uint256 y) internal pure returns (uint256) {
        unchecked {
            if (y == 0) return 0;

            require(x >= 0);

            uint256 lo = (uint256(int256(x)) * (y & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)) >> 64;
            uint256 hi = uint256(int256(x)) * (y >> 128);

            require(hi <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
            hi <<= 64;

            require(hi <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF - lo);
            return hi + lo;
        }
    }

    /**
     * Calculate x / y rounding towards zero.  Revert on overflow or when y is
     * zero.
     *
     * @param x signed 64.64-bit fixed point number
     * @param y signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function div(int128 x, int128 y) internal pure returns (int128) {
        unchecked {
            require(y != 0);
            int256 result = (int256(x) << 64) / y;
            require(result >= MIN_64x64 && result <= MAX_64x64);
            return int128(result);
        }
    }

    /**
     * Calculate x / y rounding towards zero, where x and y are unsigned 256-bit
     * integer numbers.  Revert on overflow or when y is zero.
     *
     * @param x unsigned 256-bit integer number
     * @param y unsigned 256-bit integer number
     * @return signed 64.64-bit fixed point number
     */
    function divu(uint256 x, uint256 y) internal pure returns (int128) {
        unchecked {
            require(y != 0);
            uint128 result = divuu(x, y);
            require(result <= uint128(MAX_64x64));
            return int128(result);
        }
    }

    /**
     * Calculate -x.  Revert on overflow.
     *
     * @param x signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function neg(int128 x) internal pure returns (int128) {
        unchecked {
            require(x != MIN_64x64);
            return -x;
        }
    }

    /**
     * Calculate |x|.  Revert on overflow.
     *
     * @param x signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function abs(int128 x) internal pure returns (int128) {
        unchecked {
            require(x != MIN_64x64);
            return x < 0 ? -x : x;
        }
    }

    /**
     * Calculate sqrt (x) rounding down.  Revert if x < 0.
     *
     * @param x signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function sqrt(int128 x) internal pure returns (int128) {
        unchecked {
            require(x >= 0);
            return int128(sqrtu(uint256(int256(x)) << 64));
        }
    }

    /**
     * Calculate binary logarithm of x.  Revert if x <= 0.
     *
     * @param x signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function log_2(int128 x) internal pure returns (int128) {
        unchecked {
            require(x > 0);

            int256 msb = 0;
            int256 xc = x;
            if (xc >= 0x10000000000000000) {
                xc >>= 64;
                msb += 64;
            }
            if (xc >= 0x100000000) {
                xc >>= 32;
                msb += 32;
            }
            if (xc >= 0x10000) {
                xc >>= 16;
                msb += 16;
            }
            if (xc >= 0x100) {
                xc >>= 8;
                msb += 8;
            }
            if (xc >= 0x10) {
                xc >>= 4;
                msb += 4;
            }
            if (xc >= 0x4) {
                xc >>= 2;
                msb += 2;
            }
            if (xc >= 0x2) msb += 1; // No need to shift xc anymore

            int256 result = (msb - 64) << 64;
            uint256 ux = uint256(int256(x)) << uint256(127 - msb);
            for (int256 bit = 0x8000000000000000; bit > 0; bit >>= 1) {
                ux *= ux;
                uint256 b = ux >> 255;
                ux >>= 127 + b;
                result += bit * int256(b);
            }

            return int128(result);
        }
    }

    /**
     * Calculate natural logarithm of x.  Revert if x <= 0.
     *
     * @param x signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function ln(int128 x) internal pure returns (int128) {
        unchecked {
            require(x > 0);

            return int128(int256((uint256(int256(log_2(x))) * 0xB17217F7D1CF79ABC9E3B39803F2F6AF) >> 128));
        }
    }

    /**
     * Calculate binary exponent of x.  Revert on overflow.
     *
     * @param x signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function exp_2(int128 x) internal pure returns (int128) {
        unchecked {
            require(x < 0x400000000000000000); // Overflow

            if (x < -0x400000000000000000) return 0; // Underflow

            uint256 result = 0x80000000000000000000000000000000;

            if (x & 0x8000000000000000 > 0) result = (result * 0x16A09E667F3BCC908B2FB1366EA957D3E) >> 128;
            if (x & 0x4000000000000000 > 0) result = (result * 0x1306FE0A31B7152DE8D5A46305C85EDEC) >> 128;
            if (x & 0x2000000000000000 > 0) result = (result * 0x1172B83C7D517ADCDF7C8C50EB14A791F) >> 128;
            if (x & 0x1000000000000000 > 0) result = (result * 0x10B5586CF9890F6298B92B71842A98363) >> 128;
            if (x & 0x800000000000000 > 0) result = (result * 0x1059B0D31585743AE7C548EB68CA417FD) >> 128;
            if (x & 0x400000000000000 > 0) result = (result * 0x102C9A3E778060EE6F7CACA4F7A29BDE8) >> 128;
            if (x & 0x200000000000000 > 0) result = (result * 0x10163DA9FB33356D84A66AE336DCDFA3F) >> 128;
            if (x & 0x100000000000000 > 0) result = (result * 0x100B1AFA5ABCBED6129AB13EC11DC9543) >> 128;
            if (x & 0x80000000000000 > 0) result = (result * 0x10058C86DA1C09EA1FF19D294CF2F679B) >> 128;
            if (x & 0x40000000000000 > 0) result = (result * 0x1002C605E2E8CEC506D21BFC89A23A00F) >> 128;
            if (x & 0x20000000000000 > 0) result = (result * 0x100162F3904051FA128BCA9C55C31E5DF) >> 128;
            if (x & 0x10000000000000 > 0) result = (result * 0x1000B175EFFDC76BA38E31671CA939725) >> 128;
            if (x & 0x8000000000000 > 0) result = (result * 0x100058BA01FB9F96D6CACD4B180917C3D) >> 128;
            if (x & 0x4000000000000 > 0) result = (result * 0x10002C5CC37DA9491D0985C348C68E7B3) >> 128;
            if (x & 0x2000000000000 > 0) result = (result * 0x1000162E525EE054754457D5995292026) >> 128;
            if (x & 0x1000000000000 > 0) result = (result * 0x10000B17255775C040618BF4A4ADE83FC) >> 128;
            if (x & 0x800000000000 > 0) result = (result * 0x1000058B91B5BC9AE2EED81E9B7D4CFAB) >> 128;
            if (x & 0x400000000000 > 0) result = (result * 0x100002C5C89D5EC6CA4D7C8ACC017B7C9) >> 128;
            if (x & 0x200000000000 > 0) result = (result * 0x10000162E43F4F831060E02D839A9D16D) >> 128;
            if (x & 0x100000000000 > 0) result = (result * 0x100000B1721BCFC99D9F890EA06911763) >> 128;
            if (x & 0x80000000000 > 0) result = (result * 0x10000058B90CF1E6D97F9CA14DBCC1628) >> 128;
            if (x & 0x40000000000 > 0) result = (result * 0x1000002C5C863B73F016468F6BAC5CA2B) >> 128;
            if (x & 0x20000000000 > 0) result = (result * 0x100000162E430E5A18F6119E3C02282A5) >> 128;
            if (x & 0x10000000000 > 0) result = (result * 0x1000000B1721835514B86E6D96EFD1BFE) >> 128;
            if (x & 0x8000000000 > 0) result = (result * 0x100000058B90C0B48C6BE5DF846C5B2EF) >> 128;
            if (x & 0x4000000000 > 0) result = (result * 0x10000002C5C8601CC6B9E94213C72737A) >> 128;
            if (x & 0x2000000000 > 0) result = (result * 0x1000000162E42FFF037DF38AA2B219F06) >> 128;
            if (x & 0x1000000000 > 0) result = (result * 0x10000000B17217FBA9C739AA5819F44F9) >> 128;
            if (x & 0x800000000 > 0) result = (result * 0x1000000058B90BFCDEE5ACD3C1CEDC823) >> 128;
            if (x & 0x400000000 > 0) result = (result * 0x100000002C5C85FE31F35A6A30DA1BE50) >> 128;
            if (x & 0x200000000 > 0) result = (result * 0x10000000162E42FF0999CE3541B9FFFCF) >> 128;
            if (x & 0x100000000 > 0) result = (result * 0x100000000B17217F80F4EF5AADDA45554) >> 128;
            if (x & 0x80000000 > 0) result = (result * 0x10000000058B90BFBF8479BD5A81B51AD) >> 128;
            if (x & 0x40000000 > 0) result = (result * 0x1000000002C5C85FDF84BD62AE30A74CC) >> 128;
            if (x & 0x20000000 > 0) result = (result * 0x100000000162E42FEFB2FED257559BDAA) >> 128;
            if (x & 0x10000000 > 0) result = (result * 0x1000000000B17217F7D5A7716BBA4A9AE) >> 128;
            if (x & 0x8000000 > 0) result = (result * 0x100000000058B90BFBE9DDBAC5E109CCE) >> 128;
            if (x & 0x4000000 > 0) result = (result * 0x10000000002C5C85FDF4B15DE6F17EB0D) >> 128;
            if (x & 0x2000000 > 0) result = (result * 0x1000000000162E42FEFA494F1478FDE05) >> 128;
            if (x & 0x1000000 > 0) result = (result * 0x10000000000B17217F7D20CF927C8E94C) >> 128;
            if (x & 0x800000 > 0) result = (result * 0x1000000000058B90BFBE8F71CB4E4B33D) >> 128;
            if (x & 0x400000 > 0) result = (result * 0x100000000002C5C85FDF477B662B26945) >> 128;
            if (x & 0x200000 > 0) result = (result * 0x10000000000162E42FEFA3AE53369388C) >> 128;
            if (x & 0x100000 > 0) result = (result * 0x100000000000B17217F7D1D351A389D40) >> 128;
            if (x & 0x80000 > 0) result = (result * 0x10000000000058B90BFBE8E8B2D3D4EDE) >> 128;
            if (x & 0x40000 > 0) result = (result * 0x1000000000002C5C85FDF4741BEA6E77E) >> 128;
            if (x & 0x20000 > 0) result = (result * 0x100000000000162E42FEFA39FE95583C2) >> 128;
            if (x & 0x10000 > 0) result = (result * 0x1000000000000B17217F7D1CFB72B45E1) >> 128;
            if (x & 0x8000 > 0) result = (result * 0x100000000000058B90BFBE8E7CC35C3F0) >> 128;
            if (x & 0x4000 > 0) result = (result * 0x10000000000002C5C85FDF473E242EA38) >> 128;
            if (x & 0x2000 > 0) result = (result * 0x1000000000000162E42FEFA39F02B772C) >> 128;
            if (x & 0x1000 > 0) result = (result * 0x10000000000000B17217F7D1CF7D83C1A) >> 128;
            if (x & 0x800 > 0) result = (result * 0x1000000000000058B90BFBE8E7BDCBE2E) >> 128;
            if (x & 0x400 > 0) result = (result * 0x100000000000002C5C85FDF473DEA871F) >> 128;
            if (x & 0x200 > 0) result = (result * 0x10000000000000162E42FEFA39EF44D91) >> 128;
            if (x & 0x100 > 0) result = (result * 0x100000000000000B17217F7D1CF79E949) >> 128;
            if (x & 0x80 > 0) result = (result * 0x10000000000000058B90BFBE8E7BCE544) >> 128;
            if (x & 0x40 > 0) result = (result * 0x1000000000000002C5C85FDF473DE6ECA) >> 128;
            if (x & 0x20 > 0) result = (result * 0x100000000000000162E42FEFA39EF366F) >> 128;
            if (x & 0x10 > 0) result = (result * 0x1000000000000000B17217F7D1CF79AFA) >> 128;
            if (x & 0x8 > 0) result = (result * 0x100000000000000058B90BFBE8E7BCD6D) >> 128;
            if (x & 0x4 > 0) result = (result * 0x10000000000000002C5C85FDF473DE6B2) >> 128;
            if (x & 0x2 > 0) result = (result * 0x1000000000000000162E42FEFA39EF358) >> 128;
            if (x & 0x1 > 0) result = (result * 0x10000000000000000B17217F7D1CF79AB) >> 128;

            result >>= uint256(int256(63 - (x >> 64)));
            require(result <= uint256(int256(MAX_64x64)));

            return int128(int256(result));
        }
    }

    /**
     * Calculate natural exponent of x.  Revert on overflow.
     *
     * @param x signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function exp(int128 x) internal pure returns (int128) {
        unchecked {
            require(x < 0x400000000000000000); // Overflow

            if (x < -0x400000000000000000) return 0; // Underflow

            return exp_2(int128((int256(x) * 0x171547652B82FE1777D0FFDA0D23A7D12) >> 128));
        }
    }

    /**
     * Calculate x / y rounding towards zero, where x and y are unsigned 256-bit
     * integer numbers.  Revert on overflow or when y is zero.
     *
     * @param x unsigned 256-bit integer number
     * @param y unsigned 256-bit integer number
     * @return unsigned 64.64-bit fixed point number
     */
    function divuu(uint256 x, uint256 y) private pure returns (uint128) {
        unchecked {
            require(y != 0);

            uint256 result;

            if (x <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF) result = (x << 64) / y;
            else {
                uint256 msb = 192;
                uint256 xc = x >> 192;
                if (xc >= 0x100000000) {
                    xc >>= 32;
                    msb += 32;
                }
                if (xc >= 0x10000) {
                    xc >>= 16;
                    msb += 16;
                }
                if (xc >= 0x100) {
                    xc >>= 8;
                    msb += 8;
                }
                if (xc >= 0x10) {
                    xc >>= 4;
                    msb += 4;
                }
                if (xc >= 0x4) {
                    xc >>= 2;
                    msb += 2;
                }
                if (xc >= 0x2) msb += 1; // No need to shift xc anymore

                result = (x << (255 - msb)) / (((y - 1) >> (msb - 191)) + 1);
                require(result <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);

                uint256 hi = result * (y >> 128);
                uint256 lo = result * (y & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);

                uint256 xh = x >> 192;
                uint256 xl = x << 64;

                if (xl < lo) xh -= 1;
                xl -= lo; // We rely on overflow behavior here
                lo = hi << 128;
                if (xl < lo) xh -= 1;
                xl -= lo; // We rely on overflow behavior here

                assert(xh == hi >> 128);

                result += xl / y;
            }

            require(result <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
            return uint128(result);
        }
    }

    /**
     * Calculate sqrt (x) rounding down, where x is unsigned 256-bit integer
     * number.
     *
     * @param x unsigned 256-bit integer number
     * @return unsigned 128-bit integer number
     */
    function sqrtu(uint256 x) public pure returns (uint128) {
        unchecked {
            if (x == 0) return 0;
            else {
                uint256 xx = x;
                uint256 r = 1;
                if (xx >= 0x100000000000000000000000000000000) {
                    xx >>= 128;
                    r <<= 64;
                }
                if (xx >= 0x10000000000000000) {
                    xx >>= 64;
                    r <<= 32;
                }
                if (xx >= 0x100000000) {
                    xx >>= 32;
                    r <<= 16;
                }
                if (xx >= 0x10000) {
                    xx >>= 16;
                    r <<= 8;
                }
                if (xx >= 0x100) {
                    xx >>= 8;
                    r <<= 4;
                }
                if (xx >= 0x10) {
                    xx >>= 4;
                    r <<= 2;
                }
                if (xx >= 0x8) {
                    r <<= 1;
                }
                r = (r + x / r) >> 1;
                r = (r + x / r) >> 1;
                r = (r + x / r) >> 1;
                r = (r + x / r) >> 1;
                r = (r + x / r) >> 1;
                r = (r + x / r) >> 1;
                r = (r + x / r) >> 1; // Seven iterations should be enough
                uint256 r1 = x / r;
                return uint128(r < r1 ? r : r1);
            }
        }
    }
}

// SPDX-License-Identifier: BSD-4-Clause
pragma solidity 0.8.3;
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface IERC20Extented is IERC20 {
    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: BSD-4-Clause
pragma solidity 0.8.3;

/**
 * @title Oddz Fee Manager
 * @notice Oddz Fee Manager Contract
 */
interface IOddzFeeManager {
    /**
     * @notice Gets transaction fee for an option buyer
     * @param _buyer Address of buyer
     * @return txnFee Transaction fee percentage for the buyer
     */
    function getTransactionFee(address _buyer) external view returns (uint256 txnFee);

    /**
     * @notice Gets settlement fee for an option holder
     * @param _holder Address of buyer
     * @return settlementFee Transaction fee percentage for the buyer
     */
    function getSettlementFee(address _holder) external view returns (uint256 settlementFee);

    /**
     * @notice Gets min profit for auto exercise for option holder
     * @param _holder Address of buyer
     * @return minProfit min profit for auto exercise
     */
    function getMinProfitForAutoExercise(address _holder) external view returns (uint256 minProfit);

    /**
     * @notice returns fee decimals
     * @return decimals fee decimals
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
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
 * @dev String operations.
 */
library Strings {
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

pragma solidity ^0.8.0;

import "./IERC165.sol";

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
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT

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
interface IERC165 {
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

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
contract ERC20 is Context, IERC20, IERC20Metadata {
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
    constructor(string memory name_, string memory symbol_) {
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
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
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
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
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
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
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
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
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
}

// SPDX-License-Identifier: BSD-4-Clause
pragma solidity 0.8.3;

/**
 * @title Oddz USD Liquidity Pool
 * @notice Accumulates liquidity in USD from LPs
 */
interface IOddzLiquidityPool {
    event AddLiquidity(address indexed _account, uint256 _amount);
    event RemoveLiquidity(address indexed _account, uint256 _amount, uint256 _burn);
    event LockLiquidity(uint256 _amount);
    event UnlockLiquidity(uint256 _amount);
    event PremiumCollected(address indexed _account, uint256 _amount);
    event PremiumForfeited(address indexed _account, uint256 _amount);
    event Profit(uint256 indexed _id, uint256 _amount);
    event Loss(uint256 indexed _id, uint256 _amount);

    enum TransactionType { ADD, REMOVE }
    struct PoolDetails {
        bytes32 _strike;
        bytes32 _underlying;
        bytes32 _optionType;
        bytes32 _model;
        bytes32 _maxExpiration;
    }

    /**
     * @notice returns pool parameters info
     */
    function poolDetails()
        external
        view
        returns (
            bytes32 _strike,
            bytes32 _underlying,
            bytes32 _optionType,
            bytes32 _model,
            bytes32 _maxExpiration
        );

    /**
     * @notice Add liquidity for the day
     * @param _amount USD value
     * @param _account Address of the Liquidity Provider
     */
    function addLiquidity(uint256 _amount, address _account) external;

    /**
     * @notice Provider burns oUSD and receives USD from the pool
     * @param _amount Amount of oUSD to burn
     * @param _account Address of the Liquidity Provider
     * @param _lockDuration premium lockup days
     * @return transferAmount oUSD corresponding amount to user
     */
    function removeLiquidity(
        uint256 _amount,
        address _account,
        uint256 _lockDuration
    ) external returns (uint256 transferAmount);

    /**
     * @notice called by Oddz call options to lock the funds
     * @param _amount Amount of funds that should be locked in an option
     */
    function lockLiquidity(uint256 _amount) external;

    /**
     * @notice called by Oddz option to unlock the funds
     * @param _amount Amount of funds that should be unlocked in an option
     */
    function unlockLiquidity(uint256 _amount) external;

    /**
     * @notice Returns the amount of USD available for withdrawals
     * @return balance Unlocked balance
     */
    function availableBalance() external view returns (uint256);

    /**
     * @notice Returns the total balance of USD provided to the pool
     * @return balance Pool balance
     */
    function totalBalance() external view returns (uint256);

    /**
     * @notice Allocate premium to pool
     * @param _lid liquidity ID
     * @param _amount Premium amount
     */
    function unlockPremium(uint256 _lid, uint256 _amount) external;

    /**
     * @notice Allocate premium to pool
     * @param _lid liquidity ID
     * @param _amount Premium amount
     * @param _transfer Amount i.e will be transferred to option owner
     */
    function exercisePremium(
        uint256 _lid,
        uint256 _amount,
        uint256 _transfer
    ) external;

    /**
     * @notice fetches user premium
     * @param _provider Address of the Liquidity Provider
     */
    function getPremium(address _provider) external view returns (uint256 rewards, bool isNegative);

    /**
     * @notice helper to convert premium to oUSD and sets the premium to zero
     * @param _provider Address of the Liquidity Provider
     * @param _lockDuration premium lockup days
     * @return premium Premium balance
     */
    function collectPremium(address _provider, uint256 _lockDuration) external returns (uint256 premium);

    function getBalance(address _provider) external view returns (uint256 amount);

    function checkWithdraw(address _provider, uint256 _amount) external view returns (bool);

    function getWithdrawAmount(address _provider, uint256 _amount) external view returns (uint256);
}

// SPDX-License-Identifier: BSD-4-Clause
pragma solidity 0.8.3;
import "./OddzOptionManagerStorage.sol";

/**
 * @title Oddz Call and Put Options
 * @notice Oddz Options Contract
 */
interface IOddzOption {
    enum State { Active, Exercised, Expired }
    enum OptionType { Call, Put }
    enum ExcerciseType { Cash, Physical }

    event Buy(
        uint256 indexed _optionId,
        address indexed _account,
        bytes32 indexed _model,
        uint256 _transactionFee,
        uint256 _totalFee,
        address _pair
    );
    event Exercise(
        uint256 indexed _optionId,
        uint256 _profit,
        uint256 _settlementFee,
        ExcerciseType _type,
        uint256 _assetPrice
    );
    event Expire(uint256 indexed _optionId, uint256 _premium, uint256 _assetPrice);

    struct Option {
        State state;
        address holder;
        uint256 strike;
        uint256 amount;
        uint256 lockedAmount;
        uint256 premium;
        uint256 expiration;
        address pair;
        OptionType optionType;
    }

    struct OptionDetails {
        bytes32 _optionModel;
        uint256 _expiration;
        address _pair;
        uint256 _amount;
        uint256 _strike;
        OptionType _optionType;
    }

    struct PremiumResult {
        uint256 optionPremium;
        uint256 txnFee;
        uint256 iv;
        uint8 ivDecimal;
    }

    /**
     * @notice Buy a new option
     * @param _option Options details
     * @param _premiumWithSlippage Options details
     * @param _buyer Address of option buyer
     * @return optionId Created option ID
     */
    function buy(
        OptionDetails memory _option,
        uint256 _premiumWithSlippage,
        address _buyer
    ) external returns (uint256 optionId);

    /**
     * @notice getPremium of option
     * @param _option Options details
     * @param _buyer Address of option buyer
     * @return premiumResult premium Result Created option ID
     */
    function getPremium(OptionDetails memory _option, address _buyer)
        external
        view
        returns (PremiumResult memory premiumResult);

    /**
     * @notice Exercises an active option
     * @param _optionId Option ID
     */
    function exercise(uint256 _optionId) external;

    /**
     * @notice Exercises an active option in underlying asset
     * @param _optionId Option ID
     * @param _deadline Deadline until which txn does not revert
     * @param _minAmountOut minimum amount of tokens
     */
    function exerciseUA(
        uint256 _optionId,
        uint32 _deadline,
        uint256 _minAmountOut
    ) external;

    function optionStorage() external view returns (OddzOptionManagerStorage ostorage);

    function minimumPremium() external view returns (uint256 premium);

    function setTransactionFee(uint256 _amount) external;

    function getTransactionFee(uint256 _amount, address _buyer) external view returns (uint256 txnFee);

    function getProfit(uint256 _optionID) external view returns (uint256 profit, uint256 settlementFee);
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

// SPDX-License-Identifier: BSD-4-Clause
pragma solidity 0.8.3;

import "./IOddzOption.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract OddzOptionManagerStorage is AccessControl {
    using Address for address;

    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    IOddzOption.Option[] public options;
    /**
     * @dev option transfer map
     * mapping (optionId => minAmount)
     */
    mapping(uint256 => uint256) public optionTransferMap;

    modifier onlyManager(address _address) {
        require(hasRole(MANAGER_ROLE, _address), "caller has no access to the method");
        _;
    }

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function setManager(address _address) external {
        require(_address != address(0) && _address.isContract(), "Invalid manager address");
        grantRole(MANAGER_ROLE, _address);
    }

    function createOption(IOddzOption.Option memory _option) external onlyManager(msg.sender) {
        options.push(_option);
    }

    function getOption(uint256 _optionId) external view returns (IOddzOption.Option memory option) {
        option = options[_optionId];
    }

    function getOptionsCount() external view returns (uint256 count) {
        count = options.length;
    }

    function setOptionStatus(uint256 _optionId, IOddzOption.State _state) external onlyManager(msg.sender) {
        IOddzOption.Option storage option = options[_optionId];
        option.state = _state;
    }

    function setOptionHolder(uint256 _optionId, address _holder) external onlyManager(msg.sender) {
        IOddzOption.Option storage option = options[_optionId];
        option.holder = _holder;
    }

    function addOptionTransfer(uint256 _optionId, uint256 _minAmount) external onlyManager(msg.sender) {
        optionTransferMap[_optionId] = _minAmount;
    }

    function removeOptionTransfer(uint256 _optionId) external onlyManager(msg.sender) {
        delete optionTransferMap[_optionId];
    }

    function getOptionTransfer(uint256 _optionId) external view returns (uint256 minAmount) {
        minAmount = optionTransferMap[_optionId];
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