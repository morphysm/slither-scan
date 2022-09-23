// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.7.0;
import "../leverageFactory/baseleverageFactory.sol";
import "../modules/debugger.sol";
import "./leveragePoolDebug.sol";
// Debug version contract.
//
// This contract is used for debugging leverageFactory. Please see leverageFactory.
contract leverageFactoryDebug is baseleverageFactory {
    /**
     * @dev constructor.
     */
    constructor (address multiSignature,address origin0,address origin1,address payable _feeAddress,address _oracle) 
        baseleverageFactory(multiSignature,origin0,origin1,_feeAddress,_oracle,type(leveragePoolDebug).creationCode) {
    }
}

/**
 * SPDX-License-Identifier: GPL-3.0-or-later
 * Copyright (C) 2020 defrost Protocol
 */
pragma solidity >=0.7.0 <0.8.0;
abstract contract timeLockSetting{
    struct settingInfo {
        uint256 info;
        uint256 acceptTime;
    }
    mapping(uint256=>settingInfo) public settingMap;
    uint256 public constant timeSpan = 2 days;

    event SetValue(address indexed from,uint256 indexed key, uint256 value,uint256 acceptTime);
    event AcceptValue(address indexed from,uint256 indexed key, uint256 value);
    function _set(uint256 key, uint256 _value)internal{
        settingMap[key] = settingInfo(_value,block.timestamp+timeSpan);
        emit SetValue(msg.sender,key,_value,block.timestamp+timeSpan);
    }
    function _remove(uint256 key)internal{
        settingMap[key] = settingInfo(0,0);
        emit SetValue(msg.sender,key,0,0);
    }
    function _accept(uint256 key)internal returns(uint256){
        require(settingMap[key].acceptTime>0 && settingMap[key].acceptTime < block.timestamp , "timeLock error!");
        emit AcceptValue(msg.sender,key,settingMap[key].info);
        return settingMap[key].info;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.7.0 <0.8.0;

import "./IERC20.sol";
import "../modules/SafeMath.sol";
import "../modules/Address.sol";

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
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.7.0 <0.8.0;

/**
 * @title  proxyOwner Contract

 */
import "./multiSignatureClient.sol";
contract proxyOwner is multiSignatureClient{
    bytes32 private constant proxyOwnerPosition  = keccak256("org.defrost.Owner.storage");
    bytes32 private constant proxyOriginPosition0  = keccak256("org.defrost.Origin.storage.0");
    bytes32 private constant proxyOriginPosition1  = keccak256("org.defrost.Origin.storage.1");
    uint256 private constant oncePosition  = uint256(keccak256("org.defrost.Once.storage"));
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event OriginTransferred(address indexed previousOrigin, address indexed newOrigin);
    constructor(address multiSignature,address origin0,address origin1) multiSignatureClient(multiSignature) {
        require(multiSignature != address(0) &&
        origin0 != address(0)&&
        origin1 != address(0),"proxyOwner : input zero address");
        _setProxyOwner(msg.sender);
        _setProxyOrigin(address(0),origin0);
        _setProxyOrigin(address(0),origin1);
    }
    /**
     * @dev Allows the current owner to transfer ownership
     * @param _newOwner The address to transfer ownership to
     */

    function transferOwnership(address _newOwner) external onlyOwner
    {
        _setProxyOwner(_newOwner);
    }
    function _setProxyOwner(address _newOwner) internal 
    {
        emit OwnershipTransferred(owner(),_newOwner);
        bytes32 position = proxyOwnerPosition;
        assembly {
            sstore(position, _newOwner)
        }
    }
    function owner() public view returns (address _owner) {
        bytes32 position = proxyOwnerPosition;
        assembly {
            _owner := sload(position)
        }
    }
    /**
    * @dev Throws if called by any account other than the owner.
    */
    modifier onlyOwner() {
        require (isOwner(),"proxyOwner: caller must be the proxy owner and a contract and not expired");
        _;
    }
    function transferOrigin(address _oldOrigin,address _newOrigin) external onlyOrigin
    {
        _setProxyOrigin(_oldOrigin,_newOrigin);
    }
    function _setProxyOrigin(address _oldOrigin,address _newOrigin) internal 
    {
        emit OriginTransferred(_oldOrigin,_newOrigin);
        (address _origin0,address _origin1) = txOrigin();
        if (_origin0 == _oldOrigin){
            bytes32 position = proxyOriginPosition0;
            assembly {
                sstore(position, _newOrigin)
            }
        }else if(_origin1 == _oldOrigin){
            bytes32 position = proxyOriginPosition1;
            assembly {
                sstore(position, _newOrigin)
            }            
        }else{
            require(false,"OriginTransferred : old origin is illegal address!");
        }
    }
    function txOrigin() public view returns (address _origin0,address _origin1) {
        bytes32 position0 = proxyOriginPosition0;
        bytes32 position1 = proxyOriginPosition1;
        assembly {
            _origin0 := sload(position0)
            _origin1 := sload(position1)
        }
    }
    modifier originOnce() {
        require (isOrigin(),"proxyOwner: caller is not the tx origin!");
        uint256 key = oncePosition+uint32(msg.sig);
        require (getValue(key)==0, "proxyOwner : This function must be invoked only once!");
        saveValue(key,1);
        _;
    }
    function isOrigin() public view returns (bool){
        (address _origin0,address _origin1) = txOrigin();
        return  msg.sender == _origin0 || msg.sender == _origin1;
    }
    function isOwner() public view returns (bool) {
        return msg.sender == owner() && isContract(msg.sender);
    }
    /**
    * @dev Throws if called by any account other than the owner.
    */
    modifier onlyOrigin() {
        require (isOrigin(),"proxyOwner: caller is not the tx origin!");
        checkMultiSignature();
        _;
    }
    modifier OwnerOrOrigin(){
        if (isOwner()){
        }else if(isOrigin()){
            checkMultiSignature();
        }else{
            require(false,"proxyOwner: caller is not owner or origin");
        }
        _;
    }
    
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}

/**
 * SPDX-License-Identifier: GPL-3.0-or-later
 * defrost
 * Copyright (C) 2020 defrost Protocol
 */
pragma solidity >=0.7.0 <0.8.0;

interface IMultiSignature{
    function getValidSignature(bytes32 msghash,uint256 lastIndex) external view returns(uint256);
}
contract multiSignatureClient{
    uint256 private constant multiSignaturePositon = uint256(keccak256("org.defrost.multiSignature.storage"));
    constructor(address multiSignature) {
        require(multiSignature != address(0),"multiSignatureClient : Multiple signature contract address is zero!");
        saveValue(multiSignaturePositon,uint256(multiSignature));
    }    
    function getMultiSignatureAddress()public view returns (address){
        return address(getValue(multiSignaturePositon));
    }
    modifier validCall(){
        checkMultiSignature();
        _;
    }
    function checkMultiSignature() internal {
        uint256 value;
        assembly {
            value := callvalue()
        }
        bytes32 msgHash = keccak256(abi.encodePacked(msg.sender, address(this),value,msg.data));
        address multiSign = getMultiSignatureAddress();
        uint256 index = getValue(uint256(msgHash));
        uint256 newIndex = IMultiSignature(multiSign).getValidSignature(msgHash,index);
        require(newIndex > index, "multiSignatureClient : This tx is not aprroved");
        saveValue(uint256(msgHash),newIndex);
    }
    function saveValue(uint256 position,uint256 value) internal 
    {
        assembly {
            sstore(position, value)
        }
    }
    function getValue(uint256 position) internal view returns (uint256 value) {
        assembly {
            value := sload(position)
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.7.0 <0.8.0;
import "./proxyOwner.sol";
import "./IERC20.sol";
import "./safeErc20.sol";
abstract contract debugger is proxyOwner {
    using SafeERC20 for IERC20;
    modifier isDebugger {
        require(isOrigin(), "debugger : account-not-authorized");
        _;
    }
    /**
     * @dev Withdraw asset.
     * @param _assetAddress Asset to be withdrawn.
     */
    function withdraw(address _assetAddress) external isDebugger {
        uint assetBalance;
        if (_assetAddress == address(0)) {
            address self = address(this); // workaround for a possible solidity bug
            assetBalance = self.balance;
            msg.sender.transfer(assetBalance);
        } else {
            assetBalance = IERC20(_assetAddress).balanceOf(address(this));
            IERC20(_assetAddress).safeTransfer(msg.sender, assetBalance);
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.7.0 <0.8.0;

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
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
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
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
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
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
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
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
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
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
    uint256 constant internal calDecimal = 1e18; 
    function mulPrice(uint256 value,uint256[2] memory prices,uint8 id)internal pure returns(uint256){
        return id == 0 ? div(mul(mul(prices[1],value),calDecimal),prices[0]) :
            div(mul(mul(prices[0],value),calDecimal),prices[1]);
    }
    function divPrice(uint256 value,uint256[2] memory prices,uint8 id)internal pure returns(uint256){
        return id == 0 ? div(div(mul(prices[0],value),calDecimal),prices[1]) :
            div(div(mul(prices[1],value),calDecimal),prices[0]);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.7.0 <0.8.0;
abstract contract ReentrancyGuard {

  /**
   * @dev We use a single lock for the whole contract.
   */
  bool private reentrancyLock = false;
  /**
   * @dev Prevents a contract from calling itself, directly or indirectly.
   * @notice If you mark a function `nonReentrant`, you should also
   * mark it `external`. Calling one nonReentrant function from
   * another is not supported. Instead, you can implement a
   * `private` function doing the actual work, and a `external`
   * wrapper marked as `nonReentrant`.
   */
  modifier nonReentrant() {
    require(!reentrancyLock);
    reentrancyLock = true;
    _;
    reentrancyLock = false;
  }

}

/**
 * SPDX-License-Identifier: GPL-3.0-or-later
 * defrost
 * Copyright (C) 2020 defrost Protocol
 */
pragma solidity >=0.7.0 <0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
 */
interface IERC20 {
    function decimals() external view returns (uint8);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

      /**
     * EXTERNAL FUNCTION
     *
     * @dev change token name
     * @param _name token name
     * @param _symbol token symbol
     *
     */
    function changeTokenName(string calldata _name, string calldata _symbol)external;

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed sender, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.7.0 <0.8.0;
import "./proxyOwner.sol";

abstract contract Halt is proxyOwner {
    bool private halted = false; 
    
    modifier notHalted() {
        require(!halted,"This contract is halted");
        _;
    }

    modifier isHalted() {
        require(halted,"This contract is not halted");
        _;
    }
    
    /// @notice function Emergency situation that requires 
    /// @notice contribution period to stop or not.
    function setHalt(bool halt) 
        external 
        onlyOrigin
    {
        halted = halt;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.7.0 <0.8.0;
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
        require(address(this).balance >= value, "Address: in balance for call");
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

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.7.0 <0.8.0;

import "../modules/SafeMath.sol";
import "../modules/timeLockSetting.sol";
import "../modules/safeErc20.sol";
import "./leverageData.sol";
contract leveragePool is leverageData,timeLockSetting {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    constructor (address multiSignature,address origin0,address origin1,
        address payable _feeAddress,address _lendingPool,address _underlying,
        address _oracle,address _swapHelper,
        uint256 _collateralRate,uint256 _liquidationPenalty,uint256 _liquidationReward)
        proxyOwner(multiSignature,origin0,origin1){
        require(_underlying != address(0), "Underlying must be ERC20 token");
        underlying = _underlying;
        lendingPool = ILendingPool(_lendingPool);
        lendingToken = IERC20(lendingPool.asset());
        feePool = _feeAddress;
        oracle = IDSOracle(_oracle);
        _setLiquidationInfo(_collateralRate,_liquidationReward,_liquidationPenalty);
        IERC20(_underlying).safeApprove(_swapHelper,uint256(-1));
        lendingToken.safeApprove(_swapHelper,uint256(-1));
        swapHelper = ISwapHelper(_swapHelper);
        WAVAX = IWAVAX(swapHelper.WAVAX());
        lendingToken.safeApprove(address(lendingPool),uint256(-1));
    }
    receive()external payable{

    }
    function setSwapHelper(address _swapHelper) external onlyOrigin notZeroAddress(_swapHelper) {
        require(_swapHelper != address(swapHelper),"SwapHelper set error!");
        _set(swapHelperKey,uint256(_swapHelper));
    }
    function acceptSwapHelper() external onlyOrigin {
        swapHelper = ISwapHelper(address(_accept(swapHelperKey)));
        safeApprove(address(swapHelper));
    }
    function setOracle(address _oracle) external onlyOrigin notZeroAddress(_oracle){
        require(_oracle != address(oracle),"oracle set error!");
        _set(oracleKey,uint256(_oracle));
    }
    function acceptOracle() external onlyOrigin{
        oracle = IDSOracle(address(_accept(oracleKey)));
    }
    function safeApprove(address _swapHelper)internal{
        if (IERC20(underlying).allowance(address(this), _swapHelper) == 0){
            IERC20(underlying).safeApprove(_swapHelper,uint256(-1));
        }
        if (lendingToken.allowance(address(this), _swapHelper) == 0){
            lendingToken.safeApprove(_swapHelper,uint256(-1));
        }
    }
    function setLiquidationInfo(uint256 _collateralRate,uint256 _liquidationReward,uint256 _liquidationPenalty)external onlyOrigin{
        _setLiquidationInfo(_collateralRate,_liquidationReward,_liquidationPenalty);
    }
    function _setLiquidationInfo(uint256 _collateralRate,uint256 _liquidationReward,uint256 _liquidationPenalty)internal {
        require(_collateralRate >= 1e18 && _collateralRate<= 5e18 ,"Collateral rate overflow!");
        require(_liquidationReward <= 5e17 && _liquidationPenalty <= 5e17 &&
            (calDecimals+_liquidationPenalty)*(calDecimals+_liquidationReward)/calDecimals <= _collateralRate,"Liquidate setting overflow!");
        collateralRate = _collateralRate;
        liquidationReward = _liquidationReward;
        liquidationPenalty = _liquidationPenalty; 
        emit SetLiquidationInfo(msg.sender,_collateralRate,_liquidationReward,_liquidationPenalty);
    }
    function getUserInfo(address account)external view returns (uint256,uint256){
        bytes32 userID = getUserVaultID(account);
        return (lendingPool.loan(userID),userVault[userID]);
    }
    function getUnderlingLeft(address account) external view returns (uint256){
        bytes32 userID = getUserVaultID(account);
        uint256 loan =lendingPool.loan(userID);
        (uint256 underlyingPrice,uint256 lendingPrice) = getPrices();
        uint256 allUnderlying = userVault[userID].mul(underlyingPrice);
        uint256 loadUSD = loan.mul(lendingPrice).mul(collateralRate)/calDecimals;
        if (allUnderlying > loadUSD){
            return (allUnderlying - loadUSD)/underlyingPrice;
        }
        return 0;
    }
    function _addUnderlying(address account,bytes32 userID, uint256 amount) internal {
        if (amount > 0){
            userVault[userID] = userVault[userID].add(amount);
            emit AddUnderlying(msg.sender,account,userID,amount);
        }
    }
    function _withdrawUnderlying(bytes32 userID, address account,uint256 amount) internal {
        require(_checkLiquidate(userID,0,-(int256(amount))),"underlying remove overflow!");
        userVault[userID] = userVault[userID].sub(amount);
        uint256 fee = amount.mul(swapFee)/calDecimals;
        if (fee > 0){
            _redeem(feePool,underlying,fee);
            amount = amount.sub(fee);
        }
        _redeem(account,underlying,amount);
        emit WithdrawUnderlying(msg.sender,userID, account, amount);
    }
    function _buyLeverage(address account,bytes32 vaultID, uint256 amount,uint amountLending,uint256 slipRate) internal {
        if (amountLending>0){
            lendingPool.borrow(vaultID,amountLending);
        }
        uint256 amountAll = amountLending.add(amount);
        if (amountAll> 0){
            uint256 amountUnderlying = swapTokensOnDex(address(lendingToken),underlying,amountAll,slipRate);
            userVault[vaultID] = userVault[vaultID].add(amountUnderlying);
            require(_checkLiquidate(vaultID,0,0),"Under liquidate!");
            emit BuyLeverage(msg.sender, account,vaultID, amount,amountLending,amountUnderlying);
        }
    }
    function _sellLeverage(bytes32 vaultID,uint256 amountLoan,uint256 slipRate) internal nonReentrant {
        uint256 amount = swapTokensOnDex_exactOut(underlying,address(lendingToken),amountLoan,slipRate);
        lendingPool.repay(vaultID,amountLoan);
        userVault[vaultID] = userVault[vaultID].sub(amount);
        require(_checkLiquidate(vaultID,0,0),"Under liquidate!");
        emit SellLeverage(msg.sender,vaultID,amount,amountLoan);
    }
    function _leverage(bytes32 vaultID,uint256 amount,uint256 leverageRate,uint256 slipRate) internal {
        (uint256 borrow,uint256 payment) = _getLeverageAmount(vaultID,amount,leverageRate);
        if(payment>0){
            if (payment>amount){
                if(amount>0){
                    lendingPool.repay(vaultID,amount);
                }
                _sellLeverage(vaultID,payment.sub(amount),slipRate);
            }else{
                lendingPool.repay(vaultID,payment);
                _buyLeverage(msg.sender,vaultID,amount.sub(payment),0,slipRate);
            }
        }else{
            _buyLeverage(msg.sender,vaultID,amount,borrow,slipRate);
        }
    }
    function leverageETH(uint256 leverageRate,uint256 slipRate,uint256 deadLine)  notHalted nonReentrant ensure(deadLine) AVAXDeposit(address(lendingToken)) external payable {
        _leverage(getUserVaultID(msg.sender),msg.value,leverageRate,slipRate);
    }
    function leverage(uint256 amount,uint256 leverageRate,uint256 slipRate,uint256 deadLine)  notHalted nonReentrant ensure(deadLine) external {
        lendingToken.safeTransferFrom(msg.sender, address(this),amount);
        _leverage(getUserVaultID(msg.sender),amount,leverageRate,slipRate);
    }
    function leverageUnderlyingETH(uint256 leverageRate,uint256 slipRate,uint256 deadLine)  notHalted nonReentrant ensure(deadLine) 
        AVAXDeposit(underlying) external payable {
        bytes32 vaultID = getUserVaultID(msg.sender);
        _addUnderlying(msg.sender,vaultID,msg.value);
        _leverage(vaultID,0,leverageRate,slipRate);
    }
    function leverageUnderlying(uint256 amount,uint256 leverageRate,uint256 slipRate,uint256 deadLine)  notHalted nonReentrant ensure(deadLine) external {
        IERC20(underlying).safeTransferFrom(msg.sender, address(this),amount);
        bytes32 vaultID = getUserVaultID(msg.sender);
        _addUnderlying(msg.sender,vaultID,amount);
        _leverage(vaultID,0,leverageRate,slipRate);
    }
    function buyLeverageETH(address account, uint256 amountLending,uint256 slipRate,uint256 deadLine)  notHalted nonReentrant 
        AVAXDeposit(address(lendingToken)) ensure(deadLine) external payable {
        _buyLeverage(account,getUserVaultID(account),msg.value,amountLending,slipRate);
    }
    function buyLeverage(address account, uint256 amount,uint256 amountLending,uint256 slipRate,uint256 deadLine)  notHalted nonReentrant ensure(deadLine) external {
        lendingToken.safeTransferFrom(msg.sender, address(this),amount);
        _buyLeverage(account,getUserVaultID(account),amount,amountLending,slipRate);
    }
    function addUnderlying(address account, uint256 amount)notHalted nonReentrant external {
        IERC20(underlying).safeTransferFrom(msg.sender, address(this),amount);
        bytes32 vaultID = getUserVaultID(account);
        _addUnderlying(account,vaultID,amount);
    }
    function addUnderlyingETH(address account)notHalted nonReentrant AVAXDeposit(underlying) external payable {
        bytes32 vaultID = getUserVaultID(account);
        _addUnderlying(account,vaultID,msg.value);
    }
    function withdrawUnderlying(address account, uint256 amount) notHalted nonReentrant external {
        _withdrawUnderlying(getUserVaultID(msg.sender),account,amount);
    }
    function buyleverageUnderlyingETH(address account,uint256 amountLending,uint256 slipRate,uint256 deadLine) notHalted nonReentrant
        AVAXDeposit(underlying) ensure(deadLine) external payable {
        bytes32 vaultID = getUserVaultID(account);
        _addUnderlying(account,vaultID,msg.value);
        _buyLeverage(account,vaultID,0,amountLending,slipRate);
    }

    function buyleverageUnderlying(address account, uint256 amount,uint256 amountLending,uint256 slipRate,uint256 deadLine) ensure(deadLine) external {
        IERC20(underlying).safeTransferFrom(msg.sender, address(this),amount);
        bytes32 vaultID = getUserVaultID(account);
        _addUnderlying(account,vaultID,amount);
        _buyLeverage(account,vaultID,0,amountLending,slipRate);
    }
    function sellLeverage(uint256 amountLoan,uint256 slipRate,uint256 deadLine) ensure(deadLine) external {
        bytes32 vaultID = getUserVaultID(msg.sender);
        if (amountLoan == uint256(-1)){
            amountLoan = lendingPool.loan(vaultID);
        }
        _sellLeverage(vaultID,amountLoan,slipRate);
    }
    function closeLeverage(address to,uint256 slipRate,uint256 deadLine) ensure(deadLine) external {
        bytes32 vaultID = getUserVaultID(msg.sender);
        uint256 loan =lendingPool.loan(vaultID);
        _sellLeverage(vaultID,loan,slipRate);
        _withdrawUnderlying(vaultID,to,userVault[vaultID]);
    }
    function repayETH(address account) external  AVAXDeposit(address(lendingToken)) payable {
        lendingPool.repay(getUserVaultID(account),msg.value);
    }
    function repay(address account, uint256 amount) external {
        lendingToken.safeTransferFrom(msg.sender, address(this), amount);
        lendingPool.repay(getUserVaultID(account),amount);
    }
    function getLeverageAmount(address account,uint256 inputAsset,uint256 leverageRate)external view 
        returns (uint256 borrow,uint256 payment,uint256 newLoan,uint256 newUnderlying){
        bytes32 userID = getUserVaultID(account);
        (borrow,payment) = _getLeverageAmount(userID,inputAsset,leverageRate);
        newLoan =lendingPool.loan(userID);
        newUnderlying = userVault[userID];
        if(payment>0){
            newLoan = newLoan.sub(payment);
            if (payment>inputAsset){
                uint256 amountIn = swapHelper.getAmountOut(underlying,address(lendingToken),payment.sub(inputAsset));
                newUnderlying = newUnderlying.sub(amountIn.mul(calDecimals.add(swapFee))/calDecimals);
            }else if(inputAsset>payment){
                inputAsset = inputAsset.sub(payment).mul(calDecimals.sub(swapFee))/calDecimals;
                uint256 amountOut = swapHelper.getAmountOut(address(lendingToken),underlying,inputAsset);
                newUnderlying = newUnderlying.add(amountOut);
            }
        }else{
            newLoan = newLoan.add(borrow);
            inputAsset = inputAsset.add(borrow).mul(calDecimals.sub(swapFee))/calDecimals;
            uint256 amountOut = swapHelper.getAmountOut(address(lendingToken),underlying,inputAsset);
            newUnderlying = newUnderlying.add(amountOut);
        }
    }
    function _getLeverageAmount(bytes32 userID,uint256 inputAsset,uint256 leverageRate)internal view returns (uint256 borrow,uint256 payment){
        uint256 loan =lendingPool.loan(userID);
        (uint256 underlyingPrice,uint256 lendingPrice) = getPrices();
        uint256 allUnderlying = userVault[userID].mul(underlyingPrice).add(inputAsset.mul(lendingPrice));
        uint256 allLoan = loan.mul(lendingPrice);
        allUnderlying = allUnderlying.sub(allLoan).mul(leverageRate.sub(calDecimals))/calDecimals;
        if(allUnderlying>allLoan){
            borrow = (allUnderlying-allLoan)/lendingPrice;
        }else{
            payment = (allLoan - allUnderlying)/lendingPrice;
        }
    }

    // User Vault ID is guaranteed to be unique through hash (contract address,lending token,underlying token,user address)
    function getUserVaultID(address account)public view returns (bytes32){
        return keccak256(abi.encode(address(this),address(lendingToken),underlying,account));
    }
    // get underlying price and lending pirce from orcle
    function getPrices()internal view returns(uint256,uint256){
        (bool tol0,uint256 underlyingPrice) = oracle.getPriceInfo(underlying);
        (bool tol1,uint256 lendingPrice) = oracle.getPriceInfo(address(lendingToken));
         require(tol0 && tol1,"Oracle price is abnormal!");
         return (underlyingPrice,lendingPrice);
    }
    //Check if the user's vault can be liquidated
    function canLiquidate(address account) external view returns (bool){
        return canLiquidateVault(getUserVaultID(account));
    }
    function canLiquidateVault(bytes32 userID) public view returns (bool){
        (uint256 underlyingPrice,uint256 lendingPrice) = getPrices();
        return lendingPool.loan(userID).mul(lendingPrice).mul(collateralRate)/calDecimals>userVault[userID].mul(underlyingPrice);
    }
    //Check if the user's vault can be liquidated while user's operation
    function checkLiquidate(address account,int256 newLending,int256 newUnderlying) external view returns(bool){
        return _checkLiquidate(getUserVaultID(account),newLending,newUnderlying);
    }
    function _checkLiquidate(bytes32 userID,int256 newLending,int256 newUnderlying) internal view returns(bool){
        uint256 loan =lendingPool.loan(userID);
        (uint256 underlyingPrice,uint256 lendingPrice) = getPrices();
        uint256 allUnderlying = newUnderlying >= 0 ? userVault[userID].add(uint256(newUnderlying)) : userVault[userID].sub(uint256(-newUnderlying));
        allUnderlying = allUnderlying.mul(underlyingPrice);
        loan = newLending >= 0 ? loan.add(uint256(newLending)) : loan.sub(uint256(-newLending));
        return loan.mul(lendingPrice).mul(collateralRate)/calDecimals<=allUnderlying;
    } 
    //Calculate liquidation information
    //returns liquidation is liquidatable, penalty,repay loan, and the amount paid by user
    function liquidateTest(uint256 allUnderlying,uint256 loan,uint256 amount) 
        internal view returns(bool,uint256,uint256,uint256){
        (uint256 underlyingPrice,uint256 lendingPrice) = getPrices();
        bool bLiquidate = loan.mul(lendingPrice).mul(collateralRate)/calDecimals>allUnderlying.mul(underlyingPrice);
        if (bLiquidate){
            uint256 penalty;
            uint256 repayLoan;
            (penalty,repayLoan,amount) = liquidateAmount(amount,loan);
            amount = amount.mul(lendingPrice).mul(calDecimals.add(liquidationReward))/underlyingPrice/calDecimals;
            allUnderlying = allUnderlying.mul(repayLoan)/loan;
            amount = amount <= allUnderlying ? amount : allUnderlying;
            return (bLiquidate,penalty,repayLoan,amount);
        }
        return (bLiquidate,0,0,0);
    }
    //Calculate liquidation amount. returns liquidation penalty,repay loan, and the amount paid by user
    function liquidateAmount(uint256 amount,uint256 loan)internal view returns(uint256,uint256,uint256){
        if (amount == 0){
            return (0,0,0);
        }
        uint256 penalty;
        uint256 repayLoan;
        if (amount != uint256(-1)){
            repayLoan = amount.mul(calDecimals)/(calDecimals.add(liquidationPenalty));
            penalty = amount.sub(repayLoan);
            require(loan >= repayLoan,"Input amount is overflow!");
        }else{
            penalty = loan.mul(liquidationPenalty)/calDecimals;
            repayLoan = loan;
            amount = repayLoan.add(penalty);
        }
        return (penalty,repayLoan,amount);
    }
    function liquidateETH(address account,uint256 amount)nonReentrant AVAXDeposit(address(lendingToken)) external payable {
        bytes32 userID = getUserVaultID(account);
        (bool bLiquidate,uint256 penalty,uint256 repayLoan,uint256 _payback) = 
            liquidateTest(userVault[userID],lendingPool.loan(userID),amount);
        require(bLiquidate,"liquidation check error!");
        uint256 payAmount = repayLoan.add(penalty);
        require(msg.value>=payAmount,"insufficient value!");
        if(msg.value>payAmount){
            _redeem(msg.sender,address(lendingToken),msg.value.sub(payAmount));
        }
        _liquidate(userID,penalty,repayLoan,_payback);
        emit Liquidate(msg.sender,account,userID,address(lendingToken),penalty.add(repayLoan),underlying,_payback);
    }
    function liquidate(address account,uint256 amount)nonReentrant external {
        bytes32 userID = getUserVaultID(account);
        (bool bLiquidate,uint256 penalty,uint256 repayLoan,uint256 _payback) = 
            liquidateTest(userVault[userID],lendingPool.loan(userID),amount);
        require(bLiquidate,"liquidation check error!");
        uint256 payAmount = repayLoan.add(penalty);
        lendingToken.safeTransferFrom(msg.sender, address(this), payAmount);
        _liquidate(userID,penalty,repayLoan,_payback);
        emit Liquidate(msg.sender,account,userID,address(lendingToken),penalty.add(repayLoan),underlying,_payback);  
    }
    //Liquidate accounts vault. the amount paid by user. Partial liquidation is supported.
    function _liquidate(bytes32 userID,uint256 penalty,uint256 repayLoan,uint256 _payback) internal{
        lendingPool.repay(userID,repayLoan);
        if (penalty > 0){
            _redeem(feePool,address(lendingToken),penalty);
        }
        userVault[userID] = userVault[userID].sub(_payback);
        _redeem(msg.sender,underlying,_payback);
    }
    modifier notZeroAddress(address inputAddress) {
        require(inputAddress != address(0), "input zero address");
        _;
    }
    modifier ensure(uint256 deadline) {
        require(deadline >= block.timestamp, 'leveragedPool: EXPIRED');
        _;
    }
    // Set Swap fee. (scaled by 1e18)
    function setSwapFee(uint256 _swapFee) OwnerOrOrigin external{
        require(_swapFee<5e16,"Leverage fee is beyond the limit");
        swapFee = _swapFee;
        emit SetSwapFee(msg.sender,_swapFee);
    }
    //safe transfer token to account. WAVAX will be withdraw to AVAX immediately.
    function _redeem(address account,address token,uint256 _amount)internal{
        if(token == address(0) || token == address(WAVAX)){
            WAVAX.withdraw(_amount);
            _safeTransferETH(account, _amount);
        }else{
            IERC20(token).safeTransfer(account,_amount);
        }
    }
    //safe transfer AVAX.
    function _safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'ETH_TRANSFER_FAILED');
    }
    // Exchange by swaphelper. Swap Fee will be transfer to feePool simultaneously.
    function swapTokensOnDex(address token0,address token1,uint256 balance,uint256 slipRate)internal returns (uint256){
        if(balance == 0){
            return 0;
        }
        uint256 fee = balance.mul(swapFee)/calDecimals;
        if (fee > 0){
            _redeem(feePool,token0,fee);
            balance = balance.sub(fee);
        }
        if(token0 == token1){
            return balance;
        }
        
        uint256 amountIn = swapHelper.swapExactTokens_oracle(token0,token1,balance,slipRate,address(this));
        emit SwapOnDex(msg.sender,token0,token1,balance,amountIn);
        return amountIn;
    }
     // Exchange exact amount by swaphelper. Swap Fee will be transfer to feePool simultaneously.
    function swapTokensOnDex_exactOut(address token0,address token1,uint256 amountOut,uint256 slipRate)internal returns (uint256){
        if (amountOut == 0){
            return 0;
        }
        uint256 amountIn = swapHelper.swapToken_exactOut_oracle(token0,token1,amountOut,slipRate,address(this));
        uint256 amountAll = amountIn/(calDecimals.sub(swapFee));
        if (amountAll > amountIn){
            _redeem(feePool,token0,amountAll-amountIn);
        }
        emit SwapOnDex(msg.sender,token0,token1,amountIn,amountOut);
        return amountAll;
    }
    function redeemFee(address token,uint256 _fee)internal{
        if (_fee > 0){
            _redeem(feePool,token,_fee);
            emit RedeemFee(msg.sender,feePool,token,_fee);
        }
    }
    modifier AVAXDeposit(address asset) {
        require(address(asset) == address(WAVAX), "Not WAVAX token");
        WAVAX.deposit{value: msg.value}();
        _;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.7.0 <0.8.0;
import "../interface/IDSOracle.sol";
import "../interface/ILendingPool.sol";
import "../modules/ReentrancyGuard.sol";
import "../modules/IERC20.sol";
import "../modules/Halt.sol";
import "../interface/IWAVAX.sol";
import "../interface/ISwapHelper.sol";
abstract contract leverageData is Halt,ReentrancyGuard{
    uint256 constant internal calDecimals = 1e18;
    IWAVAX public WAVAX;
    IERC20 public lendingToken;
    address public underlying;
    address public feePool;
    ILendingPool public lendingPool;
    uint256 public collateralRate;
    uint256 public liquidationPenalty;
    uint256 public liquidationReward;
    uint256 public swapFee = 1e15;
    mapping(bytes32=>uint256) public userVault;
    ISwapHelper public swapHelper;
    IDSOracle public oracle;
    uint256 public constant swapHelperKey = 1;
    uint256 public constant oracleKey = 2;
    event SetSwapFee(address indexed sender,uint256 swapFee);
    event SetLiquidationInfo(address indexed sender,uint256 collateralRate,uint256 liquidationReward,uint256 liquidationPenalty);
    event BuyLeverage(address indexed sender,address account, bytes32 vaultID, uint256 amount,uint256 amountLending,uint256 amountUnderlying);
    event SellLeverage(address indexed sender, bytes32 vaultID,uint256 amount,uint256 repayLoan);
    event AddUnderlying(address indexed sender,address account, bytes32 vaultID, uint256 amount);
    event WithdrawUnderlying(address indexed sender, bytes32 vaultID, address indexed to,uint256 amount);
    event Liquidate(address indexed sender,address account,bytes32 vaultID,address lending,uint256 amount,address underlying,uint256 _payback);
    event SwapOnDex(address indexed sender,address tokenIn,address tokenOut,uint256 amountIn,uint256 amountOut);
    event RedeemFee(address indexed sender,address feePool,address token,uint256 amountFee);    
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.7.0 <0.8.0;
import "../modules/proxyOwner.sol";
abstract contract leverageFactoryData is proxyOwner{
    mapping(bytes32=>address) public poolsMap;
    address[] public allPools;
    address payable public feePool;
    address public oracle;

    event CreateLeveragePool(address indexed poolAddress,bytes32 indexed poolID,
    address lendingPool,address underlying,uint256 collateralRate,uint256 liquidationReward,uint256 liquidationPenalty);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.7.0 <0.8.0;
import "./leverageFactoryData.sol";
import "../leveragePool/leveragePool.sol";
import "./BaseSplitCodeFactory.sol";
interface IAuthorization{
    function addAuthorization(address account) external;
    function setInterestFee(uint256 _interestFee) external;
    function setInterestRate(int256 _interestRate,uint256 rateInterval)external;

}
contract baseleverageFactory is leverageFactoryData,BaseSplitCodeFactory {
    /**
     * @dev constructor.
     */
    constructor (address multiSignature,address origin0,address origin1,address payable _feeAddress,address _oracle, bytes memory creationCode) 
        proxyOwner(multiSignature,origin0,origin1) BaseSplitCodeFactory(creationCode) {
        require(_feeAddress != address(0), "defrostFactory : input zero address");
        require(_oracle != address(0), "defrostFactory : input zero address");
        oracle = _oracle;
        feePool = _feeAddress;
    }
    // create a new leverage pool.
    // lending from lending pool.
    // swap on swapHelper. exchange from lending token to underlying token.
    function createLeveragePool(bytes32 poolID,address _lendingPool,address _underlying,
        address oracle,uint256 collateralRate,uint256 liquidationReward,uint256 liquidationPenalty)external onlyOrigin returns(address){
        address vaultAddress = poolsMap[poolID];
        require(vaultAddress == address(0),"this vault is already created!");
        return _createLeveragePool(poolID,_lendingPool,_underlying,oracle,
            collateralRate,liquidationReward,liquidationPenalty);
    }
    // get leverage pool by pool name.
    function getLeveragePool(bytes32 poolID)external view returns (address){
        return poolsMap[poolID];
    }
    // get all leverage pools.
    function getAllLeveragePool()external view returns (address[] memory){
        return allPools;
    }
    // create a new leverage pool.
    // lending from lending pool.
    // swap on swapHelper. exchange from lending token to underlying token.
    function _createLeveragePool(bytes32 poolID,address _lendingPool,address _underlying,
        address swapHelper,uint256 collateralRate,uint256 liquidationReward,uint256 liquidationPenalty)internal virtual returns(address){
        (address _origin0,address _origin1) = txOrigin();
        address newPool = super._create(abi.encode(getMultiSignatureAddress(),_origin0,_origin1,
            feePool,_lendingPool,_underlying,oracle,swapHelper,
            collateralRate,liquidationReward,liquidationPenalty));
        IAuthorization(_lendingPool).addAuthorization(newPool);
        poolsMap[poolID] = newPool;
        allPools.push(newPool);
        emit CreateLeveragePool(newPool,poolID,_lendingPool,_underlying,collateralRate,
            liquidationReward,liquidationPenalty);
        return newPool;
    }
    function setInterestFee(address _lendingPool,uint256 _interestFee) external onlyOrigin{
        IAuthorization(_lendingPool).setInterestFee(_interestFee);
    }
    function setInterestRate(address _lendingPool,int256 _interestRate,uint256 rateInterval)external onlyOrigin{
        IAuthorization(_lendingPool).setInterestRate(_interestRate,rateInterval);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.7.0;


/**
 * @dev Library used to deploy contracts with specific code. This can be used for long-term storage of immutable data as
 * contract code, which can be retrieved via the `extcodecopy` opcode.
 */
library CodeDeployer {
    // During contract construction, the full code supplied exists as code, and can be accessed via `codesize` and
    // `codecopy`. This is not the contract's final code however: whatever the constructor returns is what will be
    // stored as its code.
    //
    // We use this mechanism to have a simple constructor that stores whatever is appended to it. The following opcode
    // sequence corresponds to the creation code of the following equivalent Solidity contract, plus padding to make the
    // full code 32 bytes long:
    //
    // contract CodeDeployer {
    //     constructor() payable {
    //         uint256 size;
    //         assembly {
    //             size := sub(codesize(), 32) // size of appended data, as constructor is 32 bytes long
    //             codecopy(0, 32, size) // copy all appended data to memory at position 0
    //             return(0, size) // return appended data for it to be stored as code
    //         }
    //     }
    // }
    //
    // More specifically, it is composed of the following opcodes (plus padding):
    //
    // [1] PUSH1 0x20
    // [2] CODESIZE
    // [3] SUB
    // [4] DUP1
    // [6] PUSH1 0x20
    // [8] PUSH1 0x00
    // [9] CODECOPY
    // [11] PUSH1 0x00
    // [12] RETURN
    //
    // The padding is just the 0xfe sequence (invalid opcode). It is important as it lets us work in-place, avoiding
    // memory allocation and copying.
    bytes32
        private constant _DEPLOYER_CREATION_CODE = 0x602038038060206000396000f3fefefefefefefefefefefefefefefefefefefe;

    /**
     * @dev Deploys a contract with `code` as its code, returning the destination address.
     *
     * Reverts if deployment fails.
     */
    function deploy(bytes memory code) internal returns (address destination) {
        bytes32 deployerCreationCode = _DEPLOYER_CREATION_CODE;

        // We need to concatenate the deployer creation code and `code` in memory, but want to avoid copying all of
        // `code` (which could be quite long) into a new memory location. Therefore, we operate in-place using
        // assembly.

        // solhint-disable-next-line no-inline-assembly
        assembly {
            let codeLength := mload(code)

            // `code` is composed of length and data. We've already stored its length in `codeLength`, so we simply
            // replace it with the deployer creation code (which is exactly 32 bytes long).
            mstore(code, deployerCreationCode)

            // At this point, `code` now points to the deployer creation code immediately followed by `code`'s data
            // contents. This is exactly what the deployer expects to receive when created.
            destination := create(0, code, add(codeLength, 32))

            // Finally, we restore the original length in order to not mutate `code`.
            mstore(code, codeLength)
        }

        // The create opcode returns the zero address when contract creation fails, so we revert if this happens.
        require(destination != address(0), "CODE DEPLOYMENT FAILED");
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "./CodeDeployer.sol";

/**
 * @dev Base factory for contracts whose creation code is so large that the factory cannot hold it. This happens when
 * the contract's creation code grows close to 24kB.
 *
 * Note that this factory cannot help with contracts that have a *runtime* (deployed) bytecode larger than 24kB.
 */
abstract contract BaseSplitCodeFactory {
    // The contract's creation code is stored as code in two separate addresses, and retrieved via `extcodecopy`. This
    // means this factory supports contracts with creation code of up to 48kB.
    // We rely on inline-assembly to achieve this, both to make the entire operation highly gas efficient, and because
    // `extcodecopy` is not available in Solidity.

    // solhint-disable no-inline-assembly

    address private immutable _creationCodeContractA;
    uint256 private immutable _creationCodeSizeA;

    address private immutable _creationCodeContractB;
    uint256 private immutable _creationCodeSizeB;

    /**
     * @dev The creation code of a contract Foo can be obtained inside Solidity with `type(Foo).creationCode`.
     */
    constructor(bytes memory creationCode) {
        uint256 creationCodeSize = creationCode.length;

        // We are going to deploy two contracts: one with approximately the first half of `creationCode`'s contents
        // (A), and another with the remaining half (B).
        // We store the lengths in both immutable and stack variables, since immutable variables cannot be read during
        // construction.
        uint256 creationCodeSizeA = creationCodeSize / 2;
        _creationCodeSizeA = creationCodeSizeA;

        uint256 creationCodeSizeB = creationCodeSize - creationCodeSizeA;
        _creationCodeSizeB = creationCodeSizeB;

        // To deploy the contracts, we're going to use `CodeDeployer.deploy()`, which expects a memory array with
        // the code to deploy. Note that we cannot simply create arrays for A and B's code by copying or moving
        // `creationCode`'s contents as they are expected to be very large (> 24kB), so we must operate in-place.

        // Memory: [ code length ] [ A.data ] [ B.data ]

        // Creating A's array is simple: we simply replace `creationCode`'s length with A's length. We'll later restore
        // the original length.

        bytes memory creationCodeA;
        assembly {
            creationCodeA := creationCode
            mstore(creationCodeA, creationCodeSizeA)
        }

        // Memory: [ A.length ] [ A.data ] [ B.data ]
        //         ^ creationCodeA

        _creationCodeContractA = CodeDeployer.deploy(creationCodeA);

        // Creating B's array is a bit more involved: since we cannot move B's contents, we are going to create a 'new'
        // memory array starting at A's last 32 bytes, which will be replaced with B's length. We'll back-up this last
        // byte to later restore it.

        bytes memory creationCodeB;
        bytes32 lastByteA;

        assembly {
            // `creationCode` points to the array's length, not data, so by adding A's length to it we arrive at A's
            // last 32 bytes.
            creationCodeB := add(creationCode, creationCodeSizeA)
            lastByteA := mload(creationCodeB)
            mstore(creationCodeB, creationCodeSizeB)
        }

        // Memory: [ A.length ] [ A.data[ : -1] ] [ B.length ][ B.data ]
        //         ^ creationCodeA                ^ creationCodeB

        _creationCodeContractB = CodeDeployer.deploy(creationCodeB);

        // We now restore the original contents of `creationCode` by writing back the original length and A's last byte.
        assembly {
            mstore(creationCodeA, creationCodeSize)
            mstore(creationCodeB, lastByteA)
        }
    }

    /**
     * @dev Returns the two addresses where the creation code of the contract crated by this factory is stored.
     */
    function getCreationCodeContracts() external view returns (address contractA, address contractB) {
        return (_creationCodeContractA, _creationCodeContractB);
    }

    /**
     * @dev Returns the creation code of the contract this factory creates.
     */
    function getCreationCode() external view returns (bytes memory) {
        return _getCreationCodeWithArgs("");
    }

    /**
     * @dev Returns the creation code that will result in a contract being deployed with `constructorArgs`.
     */
    function _getCreationCodeWithArgs(bytes memory constructorArgs) private view returns (bytes memory code) {
        // This function exists because `abi.encode()` cannot be instructed to place its result at a specific address.
        // We need for the ABI-encoded constructor arguments to be located immediately after the creation code, but
        // cannot rely on `abi.encodePacked()` to perform concatenation as that would involve copying the creation code,
        // which would be prohibitively expensive.
        // Instead, we compute the creation code in a pre-allocated array that is large enough to hold *both* the
        // creation code and the constructor arguments, and then copy the ABI-encoded arguments (which should not be
        // overly long) right after the end of the creation code.

        // Immutable variables cannot be used in assembly, so we store them in the stack first.
        address creationCodeContractA = _creationCodeContractA;
        uint256 creationCodeSizeA = _creationCodeSizeA;
        address creationCodeContractB = _creationCodeContractB;
        uint256 creationCodeSizeB = _creationCodeSizeB;

        uint256 creationCodeSize = creationCodeSizeA + creationCodeSizeB;
        uint256 constructorArgsSize = constructorArgs.length;

        uint256 codeSize = creationCodeSize + constructorArgsSize;

        assembly {
            // First, we allocate memory for `code` by retrieving the free memory pointer and then moving it ahead of
            // `code` by the size of the creation code plus constructor arguments, and 32 bytes for the array length.
            code := mload(0x40)
            mstore(0x40, add(code, add(codeSize, 32)))

            // We now store the length of the code plus constructor arguments.
            mstore(code, codeSize)

            // Next, we concatenate the creation code stored in A and B.
            let dataStart := add(code, 32)
            extcodecopy(creationCodeContractA, dataStart, 0, creationCodeSizeA)
            extcodecopy(creationCodeContractB, add(dataStart, creationCodeSizeA), 0, creationCodeSizeB)
        }

        // Finally, we copy the constructorArgs to the end of the array. Unfortunately there is no way to avoid this
        // copy, as it is not possible to tell Solidity where to store the result of `abi.encode()`.
        uint256 constructorArgsDataPtr;
        uint256 constructorArgsCodeDataPtr;
        assembly {
            constructorArgsDataPtr := add(constructorArgs, 32)
            constructorArgsCodeDataPtr := add(add(code, 32), creationCodeSize)
        }

        _memcpy(constructorArgsCodeDataPtr, constructorArgsDataPtr, constructorArgsSize);
    }

    /**
     * @dev Deploys a contract with constructor arguments. To create `constructorArgs`, call `abi.encode()` with the
     * contract's constructor arguments, in order.
     */
    function _create(bytes memory constructorArgs) internal virtual returns (address) {
        bytes memory creationCode = _getCreationCodeWithArgs(constructorArgs);

        address destination;
        assembly {
            destination := create(0, add(creationCode, 32), mload(creationCode))
        }

        if (destination == address(0)) {
            // Bubble up inner revert reason
            // solhint-disable-next-line no-inline-assembly
            assembly {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }

        return destination;
    }

    // From
    // https://github.com/Arachnid/solidity-stringutils/blob/b9a6f6615cf18a87a823cbc461ce9e140a61c305/src/strings.sol
    function _memcpy(
        uint256 dest,
        uint256 src,
        uint256 len
    ) private pure {
        // Copy word-length chunks while possible
        for (; len >= 32; len -= 32) {
            assembly {
                mstore(dest, mload(src))
            }
            dest += 32;
            src += 32;
        }

        // Copy remaining bytes
        uint256 mask = 256**(32 - len) - 1;
        assembly {
            let srcpart := and(mload(src), not(mask))
            let destpart := and(mload(dest), mask)
            mstore(dest, or(destpart, srcpart))
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.7.0;

interface IWAVAX {
    /**
     * @dev returns the address of the aToken's underlying asset
     */
    // solhint-disable-next-line func-name-mixedcase
    function deposit() external payable;
    function withdraw(uint wad) external;
}

/**
 * SPDX-License-Identifier: GPL-3.0-or-later
 * Copyright (C) 2020 defrost Protocol
 */
pragma solidity >=0.7.0 <0.8.0;
interface ISwapHelper {
    function WAVAX() external view returns (address);
    function swapExactTokens(
        address token0,
        address token1,
        uint256 amountIn,
        uint256 amountOutMin,
        address to
    ) external payable returns (uint256 amountOut);
    function swapExactTokens_oracle(
        address token0,
        address token1,
        uint256 amountIn,
        uint256 slipRate,
        address to
    ) external payable returns (uint256 amountOut);
    function swapToken_exactOut(address token0,address token1,uint256 amountMaxIn,uint256 amountOut,address to) external returns (uint256);
    function swapToken_exactOut_oracle(address token0,address token1,uint256 amountOut,uint256 slipRate,address to) external returns (uint256);
    function getAmountIn(address token0,address token1,uint256 amountOut)external view returns (uint256);
    function getAmountOut(address token0,address token1,uint256 amountIn)external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.7.0 <0.8.0;
interface ILendingPool {
    function asset() external view returns(address);
    function loan(bytes32 account) external view returns(uint256);
    function borrowLimit()external view returns (uint256);
    function borrow(bytes32 account,uint256 amount) external returns(uint256);
    function repay(bytes32 account,uint256 amount) payable external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.7.0 <0.8.0;
import "../modules/proxyOwner.sol";
interface IDSOracle {
    /**
  * @notice retrieves price of an asset
  * @dev function to get price for an asset
  * @param token Asset for which to get the price
  * @return bool Determine if the current price can be used
  * @return uint256 mantissa of asset price (scaled by 1e18)
  */
    function getPriceInfo(address token) external view returns (bool,uint256);
    function getPrices(address[]calldata assets) external view returns (uint256[]memory);
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.7.0;
import "../leveragePool/leveragePool.sol";
import "../modules/debugger.sol";
// Debug version contract.
//
// This contract is used for debugging leveragePool. Please see leveragePool.
contract leveragePoolDebug is leveragePool,debugger {
    // Define the qiToken token contract
    constructor(address multiSignature,address origin0,address origin1,
        address payable _feeAddress,address _lendingPool,address _underlying,
        address oracle,address _swapHelper,
        uint256 _collateralRate,uint256 _liquidationPenalty,uint256 _liquidationReward)
        leveragePool(multiSignature,origin0,origin1,_feeAddress,_lendingPool,_underlying,
        oracle,_swapHelper,_collateralRate,_liquidationPenalty,_liquidationReward){

    }
}