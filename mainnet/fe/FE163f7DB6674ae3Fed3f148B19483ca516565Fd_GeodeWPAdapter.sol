//       ╟╗                                                                      ╔╬
//       ╞╬╬                                                                    ╬╠╬
//      ╔╣╬╬╬                                                                  ╠╠╠╠╦
//     ╬╬╬╬╬╩                                                                  ╘╠╠╠╠╬
//    ║╬╬╬╬╬                                                                    ╘╠╠╠╠╬
//    ╣╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬      ╒╬╬╬╬╬╬╬╜   ╠╠╬╬╬╬╬╬╬         ╠╬╬╬╬╬╬╬    ╬╬╬╬╬╬╬╬╠╠╠╠╠╠╠╠
//    ╙╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╕    ╬╬╬╬╬╬╬╜   ╣╠╠╬╬╬╬╬╬╬╬        ╠╬╬╬╬╬╬╬   ╬╬╬╬╬╬╬╬╬╠╠╠╠╠╠╠╩
//     ╙╣╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬  ╔╬╬╬╬╬╬╬    ╔╠╠╠╬╬╬╬╬╬╬╬        ╠╬╬╬╬╬╬╬ ╣╬╬╬╬╬╬╬╬╬╬╬╠╠╠╠╝╙
//               ╘╣╬╬╬╬╬╬╬╬╬╬╬╬╬╬    ╒╠╠╠╬╠╬╩╬╬╬╬╬╬       ╠╬╬╬╬╬╬╬╣╬╬╬╬╬╬╬╙
//                 ╣╬╬╬╬╬╬╬╬╬╬╠╣     ╣╬╠╠╠╬╩ ╚╬╬╬╬╬╬      ╠╬╬╬╬╬╬╬╬╬╬╬╬╬╬
//                  ╣╬╬╬╬╬╬╬╬╬╣     ╣╬╠╠╠╬╬   ╣╬╬╬╬╬╬     ╠╬╬╬╬╬╬╬╬╬╬╬╬╬╬
//                   ╟╬╬╬╬╬╬╬╩      ╬╬╠╠╠╠╬╬╬╬╬╬╬╬╬╬╬     ╠╬╬╬╬╬╬╬╠╬╬╬╬╬╬╬
//                    ╬╬╬╬╬╬╬     ╒╬╬╠╠╬╠╠╬╬╬╬╬╬╬╬╬╬╬╬    ╠╬╬╬╬╬╬╬ ╣╬╬╬╬╬╬╬
//                    ╬╬╬╬╬╬╬     ╬╬╬╠╠╠╠╝╝╝╝╝╝╝╠╬╬╬╬╬╬   ╠╬╬╬╬╬╬╬  ╚╬╬╬╬╬╬╬╬
//                    ╬╬╬╬╬╬╬    ╣╬╬╬╬╠╠╩       ╘╬╬╬╬╬╬╬  ╠╬╬╬╬╬╬╬   ╙╬╬╬╬╬╬╬╬
//                              

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.7.0;

import "../interface/IGeodePortal.sol";
import "../interface/IGeodeWP.sol";
import "../interface/IgAVAX.sol";
import "../interface/IERC20.sol";
import "../interface/IWETH.sol";
import "../YakAdapter.sol";

contract GeodeWPAdapter is YakAdapter {

    bytes32 constant id = keccak256("GeodeWPAdapter");
    uint constant gAVAX_DENOMINATOR = 1e18;
    uint constant IGNORABLE_DEBT = 1e18;

    uint public pooledTknId;
    address public pooledTknInterface;
    address public portal;
    address public gavax;
    address public pool;

    constructor (
        string memory _name, 
        address _portal,
        uint _pooledTknId,
        uint _swapGasEstimate
    ) {
        pooledTknId = _pooledTknId;
        portal = _portal;
        name = _name;
        pooledTknInterface = IGeodePortal(_portal).planetCurrentInterface(
            pooledTknId
        );
        pool = IGeodePortal(_portal).planetWithdrawalPool(pooledTknId);
        gavax = IGeodePortal(_portal).gAVAX();
        setSwapGasEstimate(_swapGasEstimate);
        setAllowances();
    }

    function setInterfaceForPooledTkn(
        address interfaceAddress
    ) public onlyOwner {
        require(
            IgAVAX(gavax).isInterface(
                interfaceAddress, 
                pooledTknId
            ), 
            "Not interface for the pooled token"
        );
        pooledTknInterface = interfaceAddress;
    }

    function onERC1155Received(
        address, 
        address, 
        uint256, 
        uint256, 
        bytes memory
    ) public virtual returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function setAllowances() public override onlyOwner {
        IgAVAX(gavax).setApprovalForAll(pool, true);
    }

    function revokeAllowance() public onlyOwner {
        IgAVAX(gavax).setApprovalForAll(pool, false);
    }

    function _supportedTokens(
        address tknIn, 
        address tknOut
    ) internal view returns (bool) {
        return (tknOut == WAVAX && tknIn == pooledTknInterface)
            || (tknIn == WAVAX && tknOut == pooledTknInterface);
    }

    function _stakingPaused() internal view returns (bool) {
        return IGeodePortal(portal).isStakingPausedForPool(pooledTknId);
    }

    function _calcSwap(
        uint8 tknInIndex,
        uint8 tknOutIndex,
        uint amountIn
    ) internal view returns (uint) {
        try IGeodeWP(pool).calculateSwap(
            tknInIndex, 
            tknOutIndex, 
            amountIn
        ) returns (uint amountOut) {
            return amountOut;
        } catch {
            return 0;
        }
    }

    function _calculateMint(uint amountIn) internal view returns (uint) {
        uint price = IgAVAX(gavax).pricePerShare(pooledTknId);
        return amountIn * gAVAX_DENOMINATOR / price;
    }

    function _calcSwapAndMint(uint amountIn) internal view returns (uint) {
        uint debt = IGeodeWP(pool).getDebt();
        if (debt >= amountIn || _stakingPaused()) {
            // If pool is unbalanced and missing avax it's cheaper to swap
            return _calcSwap(0, 1, amountIn);
        } else {
            // Swap debt and mint the rest
            uint amountOutBought;
            if (debt > IGNORABLE_DEBT) {
                amountOutBought = _calcSwap(0, 1, debt);
                amountIn -= debt;
            }
            uint amountOutMinted = _calculateMint(amountIn);
            return amountOutBought + amountOutMinted;
        }
    }

    function _query(
        uint _amountIn, 
        address _tokenIn, 
        address _tokenOut
    ) internal override view returns (uint) {
        if (_amountIn == 0 || _tokenIn == _tokenOut || IGeodeWP(pool).paused())
            return 0;
        if (_tokenIn == WAVAX && _tokenOut == pooledTknInterface)
            return _calcSwapAndMint(_amountIn);
        if (_tokenOut == WAVAX && _tokenIn == pooledTknInterface)
            return _calcSwap(1, 0, _amountIn);
    }

    function _swapUnderlying(
        uint8 _tokenInIndex,
        uint8 _tokenOutIndex,
        uint _amountIn, 
        uint _amountOut,
        uint _val
    ) internal {        
        IGeodeWP(pool).swap{ value: _val }(
            _tokenInIndex, 
            _tokenOutIndex,
            _amountIn, 
            _amountOut, 
            block.timestamp
        );
    }

    function _geodeStake(
        uint _amountIn, 
        uint _amountOut
    ) internal {
        IGeodePortal(portal).stake{ value: _amountIn }(
            pooledTknId, 
            _amountOut, 
            block.timestamp
        );
    }

    function _swap(
        uint _amountIn, 
        uint _amountOut, 
        address _tokenIn, 
        address _tokenOut, 
        address _to
    ) internal override {
        if (_tokenIn == WAVAX) {
            IWETH(WAVAX).withdraw(_amountIn);
            if (_stakingPaused())
                _swapUnderlying(0, 1, _amountIn, _amountOut, _amountIn);
            else 
                _geodeStake(_amountIn, _amountOut);
        } else {
            _swapUnderlying(1, 0, _amountIn, _amountOut, 0);
            IWETH(WAVAX).deposit{ value: address(this).balance }();
        }
        _returnTo(_tokenOut, IERC20(_tokenOut).balanceOf(address(this)), _to);
    }

    function _approveIfNeeded(address, uint) internal override {}

}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.7.0;

interface IGeodePortal {

  function gAVAX() external view returns (address);
  function getNameFromId(uint256 _id) external view returns (bytes memory);
  function planetCurrentInterface(uint256 _id) external view returns (address);
  function planetWithdrawalPool(uint256 _id) external view returns (address);
  function getMaintainerFromId(uint256) external view returns (address);
  function isStakingPausedForPool(uint) external view returns (bool);

  function unpauseStakingForPool(uint) external;
  function pauseStakingForPool(uint) external;
  function stake(
    uint256 planetId,
    uint256 minGavax,
    uint256 deadline
  ) external payable returns (uint256 totalgAvax);
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.7.0;

interface IGeodeWP {

  function paused() external view returns (bool);
  function getDebt() external view returns (uint);
  function getToken() external view returns (uint256);
  function getERC1155() external view returns (address);
  function getTokenBalance(uint8) external view returns (uint256);

  function calculateSwap(
    uint8 tokenIndexFrom,
    uint8 tokenIndexTo,
    uint256 dx
  ) external view returns (uint256);

  function swap(
    uint8 tokenIndexFrom,
    uint8 tokenIndexTo,
    uint256 dx,
    uint256 minDy,
    uint256 deadline
  ) external payable returns (uint256);

  function addLiquidity(
    uint256[] calldata amounts,
    uint256 minToMint,
    uint256 deadline
  ) external payable;

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

// @note: operator stands for interface address 
interface IgAVAX {

  function setApprovalForAll(address operator, bool approved) external;
  function pricePerShare(uint256 _id) external view returns (uint256);
  
  function balanceOf(
    address account, 
    uint256 id
  ) external view returns (uint256);

  function isInterface(address operator, uint256 id)
    external
    view
    returns (bool);

  function isApprovedForAll(address account, address operator)
    external
    view
    returns (bool);

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

interface IERC20 {
    event Approval(address,address,uint);
    event Transfer(address,address,uint);
    function name() external view returns (string memory);
    function decimals() external view returns (uint8);
    function transferFrom(address,address,uint) external returns (bool);
    function allowance(address,address) external view returns (uint);
    function approve(address,uint) external returns (bool);
    function transfer(address,uint) external returns (bool);
    function balanceOf(address) external view returns (uint);
    function nonces(address) external view returns (uint);  // Only tokens that support permit
    function permit(address,address,uint256,uint256,uint8,bytes32,bytes32) external;  // Only tokens that support permit
    function swap(address,uint256) external;  // Only Avalanche bridge tokens 
    function swapSupply(address) external view returns (uint);  // Only Avalanche bridge tokens 
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

import "./IERC20.sol";

interface IWETH is IERC20 {
    function withdraw(uint256 amount) external;
    function deposit() external payable;
}

//       ╟╗                                                                      ╔╬
//       ╞╬╬                                                                    ╬╠╬
//      ╔╣╬╬╬                                                                  ╠╠╠╠╦
//     ╬╬╬╬╬╩                                                                  ╘╠╠╠╠╬
//    ║╬╬╬╬╬                                                                    ╘╠╠╠╠╬
//    ╣╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬      ╒╬╬╬╬╬╬╬╜   ╠╠╬╬╬╬╬╬╬         ╠╬╬╬╬╬╬╬    ╬╬╬╬╬╬╬╬╠╠╠╠╠╠╠╠
//    ╙╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╕    ╬╬╬╬╬╬╬╜   ╣╠╠╬╬╬╬╬╬╬╬        ╠╬╬╬╬╬╬╬   ╬╬╬╬╬╬╬╬╬╠╠╠╠╠╠╠╩
//     ╙╣╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬  ╔╬╬╬╬╬╬╬    ╔╠╠╠╬╬╬╬╬╬╬╬        ╠╬╬╬╬╬╬╬ ╣╬╬╬╬╬╬╬╬╬╬╬╠╠╠╠╝╙
//               ╘╣╬╬╬╬╬╬╬╬╬╬╬╬╬╬    ╒╠╠╠╬╠╬╩╬╬╬╬╬╬       ╠╬╬╬╬╬╬╬╣╬╬╬╬╬╬╬╙
//                 ╣╬╬╬╬╬╬╬╬╬╬╠╣     ╣╬╠╠╠╬╩ ╚╬╬╬╬╬╬      ╠╬╬╬╬╬╬╬╬╬╬╬╬╬╬
//                  ╣╬╬╬╬╬╬╬╬╬╣     ╣╬╠╠╠╬╬   ╣╬╬╬╬╬╬     ╠╬╬╬╬╬╬╬╬╬╬╬╬╬╬
//                   ╟╬╬╬╬╬╬╬╩      ╬╬╠╠╠╠╬╬╬╬╬╬╬╬╬╬╬     ╠╬╬╬╬╬╬╬╠╬╬╬╬╬╬╬
//                    ╬╬╬╬╬╬╬     ╒╬╬╠╠╬╠╠╬╬╬╬╬╬╬╬╬╬╬╬    ╠╬╬╬╬╬╬╬ ╣╬╬╬╬╬╬╬
//                    ╬╬╬╬╬╬╬     ╬╬╬╠╠╠╠╝╝╝╝╝╝╝╠╬╬╬╬╬╬   ╠╬╬╬╬╬╬╬  ╚╬╬╬╬╬╬╬╬
//                    ╬╬╬╬╬╬╬    ╣╬╬╬╬╠╠╩       ╘╬╬╬╬╬╬╬  ╠╬╬╬╬╬╬╬   ╙╬╬╬╬╬╬╬╬
//                              

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.7.0;

import "./interface/IERC20.sol";
import "./interface/IWETH.sol";
import "./lib/SafeERC20.sol";
import "./lib/Ownable.sol";

abstract contract YakAdapter is Ownable {
    using SafeERC20 for IERC20;

    event YakAdapterSwap(
        address indexed _tokenFrom, 
        address indexed _tokenTo, 
        uint _amountIn, 
        uint _amountOut
    );

    event UpdatedGasEstimate(
        address indexed _adapter,
        uint _newEstimate
    );

    event Recovered(
        address indexed _asset, 
        uint amount
    );

    address internal constant WAVAX = 0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7;
    address internal constant AVAX = address(0);
    uint internal constant UINT_MAX = type(uint).max;

    uint public swapGasEstimate;
    string public name;

    function setSwapGasEstimate(uint _estimate) public onlyOwner {
        swapGasEstimate = _estimate;
        emit UpdatedGasEstimate(address(this), _estimate);
    }

    /**
     * @notice Revoke token allowance
     * @param _token address
     * @param _spender address
     */
    function revokeAllowance(address _token, address _spender) external onlyOwner {
        IERC20(_token).safeApprove(_spender, 0);
    }

    /**
     * @notice Recover ERC20 from contract
     * @param _tokenAddress token address
     * @param _tokenAmount amount to recover
     */
    function recoverERC20(address _tokenAddress, uint _tokenAmount) external onlyOwner {
        require(_tokenAmount > 0, 'YakAdapter: Nothing to recover');
        IERC20(_tokenAddress).safeTransfer(msg.sender, _tokenAmount);
        emit Recovered(_tokenAddress, _tokenAmount);
    }

    /**
     * @notice Recover AVAX from contract
     * @param _amount amount
     */
    function recoverAVAX(uint _amount) external onlyOwner {
        require(_amount > 0, 'YakAdapter: Nothing to recover');
        payable(msg.sender).transfer(_amount);
        emit Recovered(address(0), _amount);
    }

    function query(
        uint _amountIn, 
        address _tokenIn, 
        address _tokenOut
    ) external view returns (uint) {
        return _query(
            _amountIn, 
            _tokenIn, 
            _tokenOut
        );
    }

    /**
     * Execute a swap from token to token assuming this contract already holds input tokens
     * @notice Interact through the router
     * @param _amountIn input amount in starting token
     * @param _amountOut amount out in ending token
     * @param _fromToken ERC20 token being sold
     * @param _toToken ERC20 token being bought
     * @param _to address where swapped funds should be sent to
     */
    function swap(
        uint _amountIn, 
        uint _amountOut,
        address _fromToken, 
        address _toToken, 
        address _to
    ) external {
        _approveIfNeeded(_fromToken, _amountIn);
        _swap(_amountIn, _amountOut, _fromToken, _toToken, _to);
        emit YakAdapterSwap(
            _fromToken, 
            _toToken,
            _amountIn, 
            _amountOut 
        );
    } 

    /**
     * @notice Return expected funds to user
     * @dev Skip if funds should stay in the contract
     * @param _token address
     * @param _amount tokens to return
     * @param _to address where funds should be sent to
     */
    function _returnTo(address _token, uint _amount, address _to) internal {
        if (address(this)!=_to) {
            IERC20(_token).safeTransfer(_to, _amount);
        }
    }

    /**
     * @notice Wrap AVAX
     * @param _amount amount
     */
    function _wrap(uint _amount) internal {
        IWETH(WAVAX).deposit{value: _amount}();
    }

    /**
     * @notice Unwrap WAVAX
     * @param _amount amount
     */
    function _unwrap(uint _amount) internal {
        IWETH(WAVAX).withdraw(_amount);
    }

    /**
     * @notice Internal implementation of a swap
     * @dev Must return tokens to address(this)
     * @dev Wrapping is handled external to this function
     * @param _amountIn amount being sold
     * @param _amountOut amount being bought
     * @param _fromToken ERC20 token being sold
     * @param _toToken ERC20 token being bought
     * @param _to Where recieved tokens are sent to
     */
    function _swap(
        uint _amountIn, 
        uint _amountOut, 
        address _fromToken, 
        address _toToken, 
        address _to
    ) internal virtual;

    function _query(
        uint _amountIn,
        address _tokenIn, 
        address _tokenOut
    ) internal virtual view returns (uint);

    /**
     * @notice Approve tokens for use in Strategy
     * @dev Should use modifier `onlyOwner` to avoid griefing
     */
    function setAllowances() public virtual;

    function _approveIfNeeded(address _tokenIn, uint _amount) internal virtual;

    receive() external payable {}
}

// This is a simplified version of OpenZepplin's SafeERC20 library
// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;
pragma experimental ABIEncoderV2;

import "../interface/IERC20.sol";
import "./SafeMath.sol";


/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;

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
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
    }

    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0;

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
        require(owner() == _msgSender(), "Ownable: Caller is not the owner");
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
        require(newOwner != address(0), "Ownable: New owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)

library SafeMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'SafeMath: ds-math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'SafeMath: ds-math-sub-underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'SafeMath: ds-math-mul-overflow');
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

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
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}