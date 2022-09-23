//SPDX-License-Identifier: MIT
pragma solidity >=0.8.2;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

import './IComptroller.sol';
import './IQiToken.sol';

contract YieldFarmer is Ownable {
  IComptroller comptroller;
  IQiToken qiToken;
  IERC20 underlying;
  uint collateralFactor;

  constructor(
    address _comptroller,
    address _qiToken,
    address _underlying,
    uint256 _collateralFactor
  ) {
    comptroller = IComptroller(_comptroller);
    qiToken = IQiToken(_qiToken);
    underlying = IERC20(_underlying);
    address[] memory qiTokens = new address[](1);
    qiTokens[0] = _qiToken; 
    comptroller.enterMarkets(qiTokens);
    collateralFactor = _collateralFactor;
  }

  fallback () payable external {}

  function openPosition(uint initialAmount, uint256 leverage) external onlyOwner {
    uint nextCollateralAmount = initialAmount;
    for(uint i = 0; i < leverage; i++) {
      nextCollateralAmount = this._supplyAndBorrow(nextCollateralAmount);
    }
  }

  function _supplyAndBorrow(uint collateralAmount) external returns(uint) {
    underlying.approve(address(qiToken), collateralAmount);
    qiToken.mint(collateralAmount);
    uint borrowAmount = (collateralAmount * collateralFactor) / 100;
    qiToken.borrow(borrowAmount);
    return borrowAmount;
  }

  function closePosition() external onlyOwner {
    uint balanceBorrow = qiToken.borrowBalanceCurrent(address(this));
    underlying.approve(address(qiToken), balanceBorrow);
    qiToken.repayBorrow(balanceBorrow);
    uint balanceQiToken = qiToken.balanceOf(address(this));
    qiToken.redeem(balanceQiToken);
  }

  function borrowBalance() external returns (uint256) {
    return qiToken.borrowBalanceCurrent(address(this));
  }  
  
  function borrowBalanceStored() external view returns (uint256) {
    return qiToken.borrowBalanceStored(address(this));
  }

  function underlyingBalance() external view returns (uint256) {
    return underlying.balanceOf(address(this));
  }  

  function balanceOf() external view returns (uint256) {
    return qiToken.balanceOf(address(this));
  }

  function balanceOfUnderlying() external view returns (uint256) {
    return qiToken.balanceOfUnderlying(address(this));
  }

  function rates() external view returns (uint256, uint256) {
    return (
      qiToken.supplyRatePerTimestamp(),      
      qiToken.borrowRatePerTimestamp()
    );
  }

  function withdraw(uint256 amount) external onlyOwner {
    underlying.transfer(msg.sender, amount);
  }

  function drain() external onlyOwner {
    underlying.transfer(msg.sender, this.underlyingBalance());
  }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.2;

interface IComptroller {
  function enterMarkets(address[] calldata cTokens) external returns (uint[] memory);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.2;

interface IQiToken {
  function mint(uint mintAmount) external returns (uint);
  function redeem(uint redeemTokens) external returns (uint);
  function borrow(uint borrowAmount) external returns (uint);
  function repayBorrow(uint repayAmount) external returns (uint);
  function borrowBalanceCurrent(address account) external returns (uint);
  function borrowBalanceStored(address account) external view returns (uint);
  function balanceOf(address owner) external view returns (uint);
  function balanceOfUnderlying(address owner) external view returns (uint);
  function borrowRatePerTimestamp() external view returns (uint);
  function supplyRatePerTimestamp() external view returns (uint);
  function exchangeRateCurrent() external returns (uint);
}

// SPDX-License-Identifier: MIT
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