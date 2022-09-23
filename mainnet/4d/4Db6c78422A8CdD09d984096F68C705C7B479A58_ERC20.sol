// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./IERC20Metadata.sol";

contract ERC20 is IERC20Metadata{

  uint private totalBalance;
  //address public owner;
  mapping(address => uint) private balances;
  mapping(address => mapping(address => uint)) private allowBalances;
  string private tokenName;
  string private tokenSymbol;
  uint8 private tokenDecimal;

  // function owners() external view returns (address) {
  //   return owner;
  // }

  constructor(uint value, string memory _name, string memory _symbol, uint8 _decimal){
    //owner = msg.sender;
    totalBalance = value;
    balances[msg.sender] = value;
    tokenName = _name;
    tokenSymbol = _symbol;
    tokenDecimal = _decimal;
  }
  function totalSupply() external view returns (uint256) {
    return totalBalance;
  }

  function balanceOf(address account) external view returns (uint256) {
    return balances[account];
  }

  function transfer(address to, uint256 amount) external returns (bool) {
    // check enough balance
    require(balances[msg.sender]>=amount,"Insufficient amount");
    require(to!=address(0),"Address should not be 0");
    // decrease the value 
    balances[msg.sender]-=amount;
    // increase the value
    balances[to]+=amount;
    emit Transfer(msg.sender, to, amount);
    return true;
  }

  function allowance(address owner, address spender) external view returns (uint256) {
    return allowBalances[owner][spender];
  }

  function approve(address spender, uint256 amount) external returns (bool) {
    require(spender!=address(0),"Address should not be 0");
    allowBalances[msg.sender][spender] = amount;
    emit Approval(msg.sender, spender, amount);
    return true;
  }

  function transferFrom(
    address from,
    address to,
    uint256 amount
  ) external returns (bool) {
    require(from!=address(0),"Address should not be 0");
    require(to!=address(0),"Address should not be 0");
    // check balance
    require(balances[from]>=amount,"Insufficient amount");
    // check allowance
    require(allowBalances[from][msg.sender]>=amount,"Insufficient allowance");
    allowBalances[from][msg.sender]-=amount;
    // decrease value
    balances[from]-=amount;
    //increase value
    balances[to]+=amount;
    emit Transfer(from, to, amount);
    return true;
  }

  function name() external view returns (string memory) {
    return tokenName;
  }

  function symbol() external view returns (string memory) {
    return tokenSymbol;
  }

  function decimals() external view returns (uint8) {
    return tokenDecimal;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./IERC20.sol";

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.11;

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