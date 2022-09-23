/**
 *Submitted for verification at snowtrace.io on 2022-02-06
*/

// File: @openzeppelin/contracts/utils/Address.sol


// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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

// File: @openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;



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

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: dairyFarm.sol

pragma solidity >=0.7.0 <0.9.0;




contract dairyFarm is Ownable {
    // emit payment events
    event IERC20TransferEvent(IERC20 indexed token, address to, uint256 amount);
    event IERC20TransferFromEvent(IERC20 indexed token, address from, address to, uint256 amount);


    //variables
    IERC20 public milk;
    IERC20 public usdc;

    address public pair;
    address public treasury;
    address public dev;

    uint256 public dailyInterest;
    uint256 public nodeCost;
    uint256 public nodeBase;
    uint256 public bondDiscount;

    uint256 public claimTaxMilk = 15;
    uint256 public claimTaxBond = 18;
    uint256 public treasuryShare = 2;
    uint256 public devShare = 1;

    bool public isLive = false;
    uint256 totalNodes = 0;

    //Array
    address [] public farmersAddresses;

    //Farmers Struct
    struct Farmer {
        bool exists;
        uint256 milkNodes;
        uint256 bondNodes;
        uint256 claimsMilk;
        uint256 claimsBond;
        uint256 lastUpdate;
    }

    //mappings
    mapping(address => Farmer) public farmers;

    //constructor
    constructor (
        address _milk, //address of a standard erc20 to use in the platform
        address _usdc, //address of an erc20 stablecoin
        address _pair, //address of potential liquidity pool 
        address _treasury, //address of a trasury wallet to hold fees and taxes
        address _dev, //address of developer
        uint256 _dailyInterest,
        uint256 _nodeCost,
        uint256 _nodeBase,
        uint256 _bondDiscount
    ) {
        milk = IERC20(_milk);
        usdc = IERC20(_usdc);
        pair = _pair;
        treasury = _treasury;
        dev = _dev;
        dailyInterest = _dailyInterest;
        nodeCost = _nodeCost * 1e18;
        nodeBase = _nodeBase * 1e18;
        bondDiscount = _bondDiscount;
    }

    //Price Checking Functions
    function getMilkBalance() external view returns (uint256) {
	return milk.balanceOf(pair);
    }

    function getUSDCBalance() external view returns (uint256) {
	return usdc.balanceOf(pair);
    }

    function getPrice() public view returns (uint256) {
        uint256 milkBalance = milk.balanceOf(pair);
        uint256 usdcBalance = usdc.balanceOf(pair);
        require(milkBalance > 0, "divison by zero error");
        uint256 price = usdcBalance * 1e30 / milkBalance;
        return price;
    }

    //Bond Setup
    function setBondCost() public view returns (uint256) {
        uint256 tokenPrice = getPrice();
        uint256 basePrice = nodeCost / 1e18 * tokenPrice / 1e12;
        uint256 discount = 100 - bondDiscount;
        uint256 bondPrice = basePrice * discount / 100;
        return bondPrice;
    }

    function setBondDiscount(uint256 newDiscount) public onlyOwner {
        require(newDiscount <= 25, "Discount above limit");
        bondDiscount = newDiscount;
    }

    //Set Addresses
    function setTokenAddr(address tokenAddress) public {
        require(msg.sender == treasury, 'Can only be used by Dairy.Money Treasury');
        milk = IERC20(tokenAddress);
    }

    function setUSDCAddr(address tokenAddress) public {
        require(msg.sender == treasury, 'Can only be used by Dairy.Money Treasury');
        usdc = IERC20(tokenAddress);
    }

    function setPairAddr(address pairAddress) public {
        require(msg.sender == treasury, 'Can only be used by Dairy.Money Treasury');
        pair = pairAddress;
    }

    function setTreasuryAddr(address treasuryAddress) public {
        require(msg.sender == treasury, 'Can only be used by Dairy.Money Treasury');
        treasury = treasuryAddress;
    }

    //Platform Settings
    function setPlatformState(bool _isLive) public {
        require(msg.sender == treasury, 'Can only be used by Dairy.Money Treasury');
        isLive = _isLive;
    }

    function setTreasuryShare(uint256 _treasuryShare) public {
        require(msg.sender == treasury, 'Can only be used by Dairy.Money Treasury');
        treasuryShare = _treasuryShare;
    }

    function setDevShare(uint256 _devShare) public {
        require(msg.sender == treasury, 'Can only be used by Dairy.Money Treasury');
        devShare = _devShare;
    }

    function setMilkTax(uint256 _claimTaxMilk) public onlyOwner {
        claimTaxMilk = _claimTaxMilk;
    }

    function setBondTax(uint256 _claimTaxBond) public onlyOwner {
        claimTaxBond = _claimTaxBond;
    }

    function setDailyInterest(uint256 newInterest) public onlyOwner {
        updateAllClaims();
        dailyInterest = newInterest;
    }

    function updateAllClaims() internal {
        uint256 i;
        for(i=0; i<farmersAddresses.length; i++){
            address _address = farmersAddresses[i];
            updateClaims(_address);
        }
    }

    function setNodeCost(uint256 newNodeCost) public onlyOwner {
        nodeCost = newNodeCost;
    }

    function setNodeBase(uint256 newBase) public onlyOwner {
        nodeBase = newBase;
    }

    //Node management - Buy - Claim - Bond - User front
    function buyNode(uint256 _amount) external payable {  
        require(isLive, "Platform is offline");
        uint256 nodesOwned = farmers[msg.sender].milkNodes + farmers[msg.sender].bondNodes + _amount;
        require(nodesOwned < 101, "Max Cows Owned");
        Farmer memory farmer;
        if(farmers[msg.sender].exists){
            farmer = farmers[msg.sender];
        } else {
            farmer = Farmer(true, 0, 0, 0, 0, 0);
            farmersAddresses.push(msg.sender);
        }
        uint256 transactionTotal = nodeCost * _amount;
        uint256 toDev = transactionTotal / 10 * devShare;
        uint256 toTreasury = transactionTotal / 10 * treasuryShare;
        uint256 toPool = transactionTotal - toDev - toTreasury;
        _transferFrom(milk, msg.sender, address(this), toPool);
        _transferFrom(milk, msg.sender, address(treasury), toTreasury);
        _transferFrom(milk, msg.sender, address(dev), toDev);
        farmers[msg.sender] = farmer;
        updateClaims(msg.sender);
        farmers[msg.sender].milkNodes += _amount;
        totalNodes += _amount;
    }

    function bondNode(uint256 _amount) external payable {
        require(isLive, "Platform is offline");
        uint256 nodesOwned = farmers[msg.sender].milkNodes + farmers[msg.sender].bondNodes + _amount;
        require(nodesOwned < 101, "Max Cows Owned");
        Farmer memory farmer;
        if(farmers[msg.sender].exists){
            farmer = farmers[msg.sender];
        } else {
            farmer = Farmer(true, 0, 0, 0, 0, 0);
            farmersAddresses.push(msg.sender);
        }
        uint256 usdcAmount = setBondCost();
        uint256 transactionTotal = usdcAmount * _amount;
        uint256 toDev = transactionTotal / 10 * devShare;
        uint256 toTreasury = transactionTotal - toDev;
        _transferFrom(usdc, msg.sender, address(dev), toDev);
        _transferFrom(usdc, msg.sender, address(treasury), toTreasury);
        farmers[msg.sender] = farmer;
        updateClaims(msg.sender);
        farmers[msg.sender].bondNodes += _amount;
        totalNodes += _amount;
    }

    function awardNode(address _address, uint256 _amount) public onlyOwner {
        uint256 nodesOwned = farmers[_address].milkNodes + farmers[_address].bondNodes + _amount;
        require(nodesOwned < 101, "Max Cows Owned");
        Farmer memory farmer;
        if(farmers[_address].exists){
            farmer = farmers[_address];
        } else {
            farmer = Farmer(true, 0, 0, 0, 0, 0);
            farmersAddresses.push(_address);
        }
        farmers[_address] = farmer;
        updateClaims(_address);
        farmers[_address].milkNodes += _amount;
        totalNodes += _amount;
        farmers[_address].lastUpdate = block.timestamp;
    }

    function compoundNode() public {
        uint256 pendingClaims = getTotalClaimable();
        uint256 nodesOwned = farmers[msg.sender].milkNodes + farmers[msg.sender].bondNodes;
        require(pendingClaims>nodeCost, "Not enough pending MILK to compound");
        require(nodesOwned < 100, "Max Cows Owned");
        updateClaims(msg.sender);
        if (farmers[msg.sender].claimsMilk > nodeCost) {
            farmers[msg.sender].claimsMilk -= nodeCost;
            farmers[msg.sender].milkNodes++;
        } else {
            uint256 difference = nodeCost - farmers[msg.sender].claimsMilk;
            farmers[msg.sender].claimsMilk = 0;
            farmers[msg.sender].claimsBond -= difference;
            farmers[msg.sender].bondNodes++;
        }
        totalNodes++;
    }

    function updateClaims(address _address) internal {
        uint256 time = block.timestamp;
        uint256 timerFrom = farmers[_address].lastUpdate;
        if (timerFrom > 0)
            farmers[_address].claimsMilk += farmers[_address].milkNodes * nodeBase * dailyInterest * (time - timerFrom) / 8640000;
            farmers[_address].claimsBond += farmers[_address].bondNodes * nodeBase * dailyInterest * (time - timerFrom) / 8640000;
            farmers[_address].lastUpdate = time;
    }

    function getTotalClaimable() public view returns (uint256) {
        uint256 time = block.timestamp;
        uint256 pendingMilk = farmers[msg.sender].milkNodes * nodeBase * dailyInterest * (time - farmers[msg.sender].lastUpdate) / 8640000;
        uint256 pendingBond = farmers[msg.sender].bondNodes * nodeBase * dailyInterest * (time - farmers[msg.sender].lastUpdate) / 8640000;
        uint256 pending = pendingMilk + pendingBond;
        return farmers[msg.sender].claimsMilk + farmers[msg.sender].claimsBond + pending;
	}

    function getTaxEstimate() external view returns (uint256) {
        uint256 time = block.timestamp;
        uint256 pendingMilk = farmers[msg.sender].milkNodes * nodeBase * dailyInterest * (time - farmers[msg.sender].lastUpdate) / 8640000;
        uint256 pendingBond = farmers[msg.sender].bondNodes * nodeBase * dailyInterest * (time - farmers[msg.sender].lastUpdate) / 8640000;
        uint256 claimableMilk = pendingMilk + farmers[msg.sender].claimsMilk;
        uint256 claimableBond = pendingBond + farmers[msg.sender].claimsBond;
        uint256 taxMilk = claimableMilk / 100 * claimTaxMilk;
        uint256 taxBond = claimableBond / 100 * claimTaxBond;
        return taxMilk + taxBond;
	}

    function calculateTax() public returns (uint256) {
        updateClaims(msg.sender);
        uint256 taxMilk = farmers[msg.sender].claimsMilk / 100 * claimTaxMilk;
        uint256 taxBond = farmers[msg.sender].claimsBond / 100 * claimTaxBond;
        uint256 tax = taxMilk + taxBond;
        return tax;
    }


    function claim() external payable {
        // ensure msg.sender is sender
        require(farmers[msg.sender].exists, "sender must be registered farmer to claim yields");

        updateClaims(msg.sender);
        uint256 tax = calculateTax();
		uint256 reward = farmers[msg.sender].claimsMilk + farmers[msg.sender].claimsBond;
        uint256 toTreasury = tax;
        uint256 toFarmer = reward - tax;
		if (reward > 0) {
            farmers[msg.sender].claimsMilk = 0;		
            farmers[msg.sender].claimsBond = 0;
            _transfer(milk, msg.sender, toFarmer);
            _transfer(milk, address(treasury), toTreasury);
		}
	}

    //Platform Info
    function currentDailyRewards() external view returns (uint256) {
        uint256 dailyRewards = nodeBase * dailyInterest / 100;
        return dailyRewards;
    }

    function getOwnedNodes() external view returns (uint256) {
        uint256 ownedNodes = farmers[msg.sender].milkNodes + farmers[msg.sender].bondNodes;
        return ownedNodes;
    }

    function getTotalNodes() external view returns (uint256) {
        return totalNodes;
    }

    function getMilkClaimTax() external view returns (uint256) {
        return claimTaxMilk;
    }

    function getBondClaimTax() external view returns (uint256) {
        return claimTaxBond;
    }

    // SafeERC20 transfer
    function _transfer(IERC20 token, address account, uint256 amount) private {
        SafeERC20.safeTransfer(token, account, amount);
        // log transfer to blockchain
        emit IERC20TransferEvent(token, account, amount);
    }

    // SafeERC20 transferFrom 
    function _transferFrom(IERC20 token, address from, address to, uint256 amount) private {
        SafeERC20.safeTransferFrom(token, from, to, amount);
        // log transferFrom to blockchain
        emit IERC20TransferFromEvent(token, from, to, amount);
    }

}