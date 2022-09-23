/**
 *Submitted for verification at testnet.snowtrace.io on 2022-06-10
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

interface IERC20 {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint16);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
}

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

/**
 * @dev Partial interface for a Chainlink Aggregator.
 */
interface AggregatorV3Interface {
    // latestRoundData should raise "No data present"
    // if he do not have data to report, instead of returning unset values
    // which could be misinterpreted as actual reported values.
    function latestRoundData()
        external
        view
        returns (
            uint160 roundId,
            int answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint160 answeredInRound
        );
}

contract DexilonTest_v12 {
    using SafeERC20 for IERC20;
    
    struct userAssetParameters {
        string assetName;
        int256 assetBalance;
        uint256 assetLockedBalance;
        uint256 assetPrice;
        uint256 assetLeverage;
    }

    struct tradingArrayIndexed {
        bool isBuy;
        uint32 makerIndex;
        uint32 takerIndex;
        uint32 assetIndex;
        uint256 assetAmount;
        uint256 assetRate;
        uint256 tradeFee;
        uint16 makerLeverage;
        uint16 takerLeverage;
        string tradeId;
    }

    struct tradingArray {
        bool isBuy;
        address makerAddress;
        address takerAddress;
        string assetName;
        uint256 assetAmount;
        uint256 assetRate;
        uint256 tradeFee;
        uint16 makerLeverage;
        uint16 takerLeverage;
        string tradeId;
    }

    struct FeesArray {
        address userAddress;
        int feeAmount;
    }

    mapping(address => uint256) internal usersAvailableBalances;
    mapping(address => mapping (string => userAssetParameters)) internal usersAssetsData;
    
    mapping(address => uint256) public usersIndex;
    mapping(uint256 => address) public indexedAddresses;
    
    mapping(string => bool) internal checkAsset;

    uint256 public usersCount;
    string[] internal assetsNames;
    
    address payable public owner;
    
    
    event Deposit(
        address indexed depositor,
        uint256 amountUSDC,
        uint256 timestamp
    );
    
    event Withdraw(
        address indexed user,
        uint256 amountUSDC,
        uint256 timestamp
    );
    
    event Trade(
        bool isBuy,
        address indexed maker,
        address indexed taker,
        string asset,
        uint256 assetAmount,
        uint256 assetRate,
        uint256 tradeFee,
        uint16 makerLeverage,
        uint16 takerLeverage,
        string tradeId,
        uint256 timestamp
    );
    
    uint8 internal constant DECIMALS_USDC = 6;
    uint8 internal constant DECIMALS_ETH = 18;
    
    int internal constant ETH_UNIT_FACTOR = int(10**DECIMALS_ETH);
    int internal constant ROUNDING_FACTOR = int(10**(DECIMALS_ETH-DECIMALS_USDC));
    
    // Chainlink price feed for ETH/USD
    AggregatorV3Interface internal btcToUsdPriceFeed = AggregatorV3Interface(0x007A22900a3B98143368Bd5906f8E17e9867581b);
    // Chainlink price feed for USDC/USD
    AggregatorV3Interface internal usdcToUsdPriceFeed = AggregatorV3Interface(0x572dDec9087154dC5dfBB1546Bb62713147e0Ab0);
    
    // USDC test token (Mumbai Testnet)
    IERC20 internal depositToken = IERC20(0x7592A72A46D3165Dcc7BF0802D70812Af19471B3); 
    
    constructor(address USDC_address) {
        owner = payable(msg.sender);
        // Base stable coin
        depositToken = IERC20(USDC_address);
        // Supported assets
        assetsNames = ['BTC', 'ETH', 'SOL', 'ADA', 'NEAR', 'MATIC', 'LUNA', 'DOGE'];
        
        for (uint16 i=0; i<assetsNames.length; i++) {
            checkAsset[assetsNames[i]] = true;
        }
        // Initiating user index
        usersIndex[owner] = 0;
        indexedAddresses[0] = owner;
        usersCount = 1;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        owner = payable(newOwner);
    }

    /**
     * @dev Add new assets to supported names.
     * Can only be called by the current owner.
     */
    function addNewSupportedAsset(string memory _newAssetName) public onlyOwner returns (bool) {

        require(checkAsset[_newAssetName] == false, "Asset already exists!");

        assetsNames.push(_newAssetName);
        checkAsset[_newAssetName] = true;
        return true;
    }

    /**
    * @notice Convert btc to usdc by Chainlink market price
    */
    function btcToUsdcMarketConvert(int assetAmount) public view returns (int) {
        (, int signedBtcToUsdPrice, , , ) = btcToUsdPriceFeed.latestRoundData();
        (, int signedUsdcToUsdPrice, , , ) = usdcToUsdPriceFeed.latestRoundData();
        
        return (signedBtcToUsdPrice*assetAmount/signedUsdcToUsdPrice)/int(10**(DECIMALS_ETH - DECIMALS_USDC));
    }

    /**
     * @dev Deposit token into contract and open user account
     * @param amountUSDC Amount of token in smallest units
     */
    function deposit(uint256 amountUSDC) public {
        depositToken.safeTransferFrom(msg.sender, address(this), amountUSDC);
        
        usersAvailableBalances[msg.sender] += amountUSDC * uint(ROUNDING_FACTOR);

        /// indexing users
        if (usersIndex[msg.sender] == 0 && msg.sender != owner) {
            usersIndex[msg.sender] = usersCount;
            indexedAddresses[usersCount] = msg.sender;
            usersCount += 1;
        }

        emit Deposit(msg.sender, amountUSDC, block.timestamp);
    }
    

    /**
     * @dev Read all balances for the user
     * @param user Address of the user is the id of account
     */
    function getUserBalances(address user) public view 
        returns (uint256 , uint256 , userAssetParameters[] memory ) 
    {
        uint256 availableBalance = usersAvailableBalances[user] / uint(ROUNDING_FACTOR);
        uint256 lockedBalance;

        userAssetParameters[] memory userAssets = new userAssetParameters[](assetsNames.length);

        for (uint256 i=0; i < assetsNames.length; i++) {
            userAssets[i] = _setOutputDecimalsForAsset(assetsNames[i], usersAssetsData[user][assetsNames[i]]);
            lockedBalance += userAssets[i].assetLockedBalance;
        }
        // rounding error correction
        if (lockedBalance % 10 !=0){
            lockedBalance += 10 - lockedBalance % 10;
        }
        
        return (availableBalance, lockedBalance, userAssets);

    }

    /**
     * @dev convert locked balance and asset price to USDC decimals
     * @param assetData struct userAssetParameters for current asset of the user
     */
    function _setOutputDecimalsForAsset(string memory assetName, userAssetParameters memory assetData) internal pure returns (userAssetParameters memory assetDataModified) {
        // struct userAssetParameters {
        // 0 string assetName;
        // 1 int256 assetBalance;
        // 2 uint256 assetLockedBalance;
        // 3 uint256 assetPrice;
        // 4 uint16 assetLeverage; }
        assetDataModified.assetName = assetName;
        assetDataModified.assetBalance = assetData.assetBalance; // ETH decimals

        // assetDataModified.assetLockedBalance = assetData.assetLockedBalance / uint(ROUNDING_FACTOR); // USDC decimals
        if (assetData.assetLeverage !=0) {
            assetDataModified.assetLockedBalance = (uint(abs(assetData.assetBalance)) * assetData.assetPrice / 
            assetData.assetLeverage) / uint(ETH_UNIT_FACTOR * ROUNDING_FACTOR); // USDC decimals
        } 


        assetDataModified.assetPrice = assetData.assetPrice / uint(ROUNDING_FACTOR); // USDC decimals
        assetDataModified.assetLeverage = assetData.assetLeverage; 
    }

    /**
     * @dev transfer amount to the user
     * @param userAddress transfer to this address 
     * @param amountUSDC amount of the deposited token in smallest units
     */
    function withdraw(address userAddress, uint256 amountUSDC) public onlyOwner {
        
        require(usersAvailableBalances[userAddress] >= amountUSDC * uint(ROUNDING_FACTOR), 'Insufficient balance!');

        depositToken.safeTransfer(userAddress, amountUSDC);
        usersAvailableBalances[userAddress] -= amountUSDC * uint(ROUNDING_FACTOR);
        
        emit Withdraw(userAddress, amountUSDC, block.timestamp);
    }

    /// @dev development ONLY
    function withdrawAll() public onlyOwner {
        depositToken.safeTransfer(owner, depositToken.balanceOf(address(this)));
        
        if (address(this).balance > 0) {
            owner.transfer(address(this).balance);
        }
    }

    /// @dev development ONLY
    function resetUserAccount(address userAddress, 
                              uint256 userAvailableBalance,
                              uint256 userLockedBalance,
                              string memory asset,
                              int256 userAssetBalance,
                              uint16 leverage) public onlyOwner {
        usersAvailableBalances[userAddress] = userAvailableBalance;
        
        userAssetParameters memory zeroParameters;
        zeroParameters.assetName = '';
        zeroParameters.assetBalance = 0;
        zeroParameters.assetLockedBalance = 0;
        zeroParameters.assetPrice = 0;
        zeroParameters.assetLeverage = 1;

        for (uint16 i=0; i<assetsNames.length; i++) {
            usersAssetsData[userAddress][assetsNames[i]] = zeroParameters;
            usersAssetsData[userAddress][assetsNames[i]].assetLeverage = leverage;
        }

        usersAssetsData[userAddress][asset].assetBalance = userAssetBalance;
        usersAssetsData[userAddress][asset].assetLockedBalance = userLockedBalance;
        if (userAssetBalance != 0){
            usersAssetsData[userAddress][asset].assetPrice = uint((int(userLockedBalance * leverage)  * ETH_UNIT_FACTOR) / 
            abs(userAssetBalance));}

    }
       
    /**
    * @dev trade between a maker and a taker
    * @param isBuy true if this is a buy order trade, false if a sell order trade
    * @param maker the address of the user who created the order
    * @param taker the address of the user who accepted the order
    * @param asset string id of the supported asset ('ETH','ETH','XRP','SOL')
    * @param assetAmount the amount of the asset in Wei (smallest unit)
    * @param assetRate price of 1 asset coin in the smallest unit of USDC
    * @param tradeFee absolute fee amount in the smallest unit of USDC from taker to maker
    * @param makerLeverage leverage of the maker for the asset
    * @param takerLeverage leverage of the taker for the asset
    * @param tradeId incoming id of the trade as as string
    **/
    function trade(
        bool isBuy,
        address maker,
        address taker,
        string memory asset,
        uint256 assetAmount,
        uint256 assetRate,
        uint256 tradeFee,
        uint16 makerLeverage,
        uint16 takerLeverage,
        string memory tradeId
    ) public onlyOwner {
        
        require(checkAsset[asset], string(abi.encodePacked('Unknown Asset! TradeId:', tradeId)));

        updateUserLeverage(maker, asset, makerLeverage, tradeId);
        updateUserLeverage(taker, asset, takerLeverage, tradeId);
        
        updateUserBalances(maker, asset, (isBuy ? int(1) : int(-1))*int(assetAmount), int(assetRate), int(tradeFee), tradeId);
        updateUserBalances(taker, asset, (isBuy ? int(-1) : int(1))*int(assetAmount), int(assetRate), -int(tradeFee), tradeId);
        
        emit Trade(isBuy, maker, taker, asset, assetAmount, assetRate, tradeFee, makerLeverage, takerLeverage, tradeId, block.timestamp);
    }
    
    /**
    * @dev update the balances of one of the traders
    * @param user user address whose balances are updated
    * @param asset string id of the supported asset ('ETH','ETH','XRP','SOL')
    * @param assetAmount the amount of the asset in Wei (smallest unit)
    * @param assetRate price of 1 asset coin in the smallest unit of USDC
    * @param tradeFee absolute fee amount in the smallest unit of USDC
    * @param tradeId incoming id of the trade as as string
    **/
    function updateUserBalances(
        address user,
        string memory asset,
        int assetAmount,
        int assetRate,
        int tradeFee,
        string memory tradeId
    ) internal {
        int assetBalance = usersAssetsData[user][asset].assetBalance;
        int assetPrice = int(usersAssetsData[user][asset].assetPrice);
        int leverage = int(uint256(usersAssetsData[user][asset].assetLeverage)) * ETH_UNIT_FACTOR;
        int availableBalance = int(usersAvailableBalances[user]) + tradeFee * ROUNDING_FACTOR;
        // int lockedBalance = int(usersAssetsData[user][asset].assetLockedBalance);
        int lockedBalance = ((abs(assetBalance)) * assetPrice / leverage);

        assetRate = assetRate * ROUNDING_FACTOR;

        require(assetRate > 0, string(abi.encodePacked('Zero Rate! TradeId:', tradeId)));
        
        if (((assetAmount > 0 && assetBalance < 0) || 
              (assetAmount < 0 && assetBalance > 0)) &&
                abs(assetAmount) > abs(assetBalance)) {
            
            availableBalance = availableBalance  
                + abs(assetBalance)*assetPrice/(leverage) 
                - assetBalance*(assetPrice - assetRate)/(ETH_UNIT_FACTOR);
            lockedBalance = lockedBalance - abs(assetBalance*assetPrice/(leverage));
            assetAmount = assetAmount + assetBalance;
            assetBalance = 0;
        }
        
                
        if (assetBalance == 0  
                || (assetBalance < 0 && assetAmount < 0) 
                || (assetBalance > 0 && assetAmount > 0)) {

            availableBalance = availableBalance
                - abs(assetAmount*assetRate/(leverage));
            lockedBalance = lockedBalance + abs(assetAmount*assetRate/(leverage));
            assetPrice = (assetBalance*assetPrice + assetAmount*assetRate) / (assetBalance + assetAmount);

        } else {
            // (assetBalance > 0 && assetAmount < 0)
            // (assetBalance < 0 && assetAmount > 0)
            availableBalance = availableBalance 
                + abs(assetAmount)*assetPrice/(leverage)
                + assetAmount*(assetPrice - assetRate)/(ETH_UNIT_FACTOR);
            lockedBalance = lockedBalance - abs(assetAmount*assetPrice/(leverage));
        }
        
        require(availableBalance >= 0, string(abi.encodePacked('Insufficient balance! TradeId:', tradeId)));
        require(lockedBalance >= 0, string(abi.encodePacked('LockedBalance < 0! TradeId:', tradeId)));
        
        usersAvailableBalances[user] = uint256(availableBalance);
        // usersAssetsData[user][asset].assetLockedBalance = uint256(lockedBalance);
        usersAssetsData[user][asset].assetPrice = uint256(assetPrice);
        usersAssetsData[user][asset].assetBalance = assetBalance + assetAmount;
    }

    /**
    * @dev update available balance and asset locked balance for new leverage
    * @param user user address whose balances are updated
    * @param asset string id of the supported asset ('ETH','ETH','XRP','SOL')
    * @param assetLeverage leverage of the user for the asset
    * @param tradeId incoming id of the trade as as string
    **/
    function updateUserLeverage(
        address user,
        string memory asset,
        uint16 assetLeverage,
        string memory tradeId
    ) internal {

        int lockedBalance;
        int newLockedBalance;
        int newAvailableBalance;  
                
        require(assetLeverage > 0, string(abi.encodePacked('Zero Leverage! TradeId:', tradeId)));

        if (usersAssetsData[user][asset].assetBalance == 0) {
            usersAssetsData[user][asset].assetLeverage = assetLeverage;
        }


        if (usersAssetsData[user][asset].assetLeverage != assetLeverage){

            lockedBalance = ((int(usersAssetsData[user][asset].assetPrice) 
                * abs(int(usersAssetsData[user][asset].assetBalance))) 
                / int(usersAssetsData[user][asset].assetLeverage));
            newLockedBalance = ((int(usersAssetsData[user][asset].assetPrice) 
                * abs(int(usersAssetsData[user][asset].assetBalance))) 
                / int(uint256(assetLeverage)));
                
            newAvailableBalance = int(usersAvailableBalances[user]) 
                - (newLockedBalance - lockedBalance) / ETH_UNIT_FACTOR;

            require(newAvailableBalance >= 0, string(abi.encodePacked('Insufficient balance! TradeId:', tradeId))); 

            usersAvailableBalances[user] = uint256(newAvailableBalance);
            // usersAssetsData[user][asset].assetLockedBalance = uint256(newLockedBalance);
            usersAssetsData[user][asset].assetLeverage = assetLeverage;
        }
    }

    // struct tradingArrayIndexed {
    //     bool isBuy;
    //     uint32 makerIndex;
    //     uint32 takerIndex;
    //     uint32 assetIndex;
    //     uint256 assetAmount;
    //     uint256 assetRate;
    //     uint256 tradeFee;
    //     uint16 makerLeverage;
    //     uint16 takerLeverage;
    //     string tradeId;
    // } 

    /**
    * @dev Batch trading with indexes for users
    * @param batchTradingArray array of structs tradingArrayIndexed
    **/
    function batchTradeIndexed(tradingArrayIndexed[] memory batchTradingArray) public onlyOwner {

        uint256 max = batchTradingArray.length;

        for (uint256 i=0; i < max; i++) {
            trade(
                batchTradingArray[i].isBuy,
                indexedAddresses[batchTradingArray[i].makerIndex],
                indexedAddresses[batchTradingArray[i].takerIndex],
                assetsNames[batchTradingArray[i].assetIndex],
                batchTradingArray[i].assetAmount,
                batchTradingArray[i].assetRate,
                batchTradingArray[i].tradeFee,
                batchTradingArray[i].makerLeverage,
                batchTradingArray[i].takerLeverage,
                batchTradingArray[i].tradeId
                );
        }
    }

    // struct tradingArray {
    //     bool isBuy;
    //     address makerAddress;
    //     address takerAddress;
    //     string assetName;
    //     uint256 assetAmount;
    //     uint256 assetRate;
    //     uint256 tradeFee;
    //     uint16 makerLeverage;
    //     uint16 takerLeverage;
    //     string tradeId;
    // }
    /**
    * @dev Batch trading with addresses
    * @param batchTradingArray array of structs tradingArray
    **/
    function batchTrade(tradingArray[] memory batchTradingArray) public onlyOwner {

        uint256 max = batchTradingArray.length;

        for (uint256 i=0; i < max; i++) {
            trade(
                batchTradingArray[i].isBuy,
                batchTradingArray[i].makerAddress,
                batchTradingArray[i].takerAddress,
                batchTradingArray[i].assetName,
                batchTradingArray[i].assetAmount,
                batchTradingArray[i].assetRate,
                batchTradingArray[i].tradeFee,
                batchTradingArray[i].makerLeverage,
                batchTradingArray[i].takerLeverage,
                batchTradingArray[i].tradeId
                );
        }
    }

    /**
    * @notice Batch pay funding rate fees
    * @dev feeAmount should have 18 decimals
    * @param batchFees array of structs feesArray (userAddress, feeAmount)
    **/
    function batchFundingRateFees(FeesArray[] memory batchFees) public onlyOwner {

        uint256 max = batchFees.length;

        for (uint256 i=0; i < max; i++) {
            if (batchFees[i].feeAmount < 0 ) {
                // negative fee
                if (usersAvailableBalances[batchFees[i].userAddress] >= uint(-batchFees[i].feeAmount)) {
                    // enough available to pay fee
                    usersAvailableBalances[batchFees[i].userAddress] -= uint(-batchFees[i].feeAmount);
                } else {
                    // not enough available to pay fee
                    usersAvailableBalances[batchFees[i].userAddress] = 0;
                }

            } else {
                // positive fee
                usersAvailableBalances[batchFees[i].userAddress] += uint(batchFees[i].feeAmount);
            }
        }
    }

    function abs(int x) private pure returns (int) {
        return x >= 0 ? x : -x;
    }

}