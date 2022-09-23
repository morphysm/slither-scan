/**
 *Submitted for verification at testnet.snowtrace.io on 2022-03-24
*/

// Sources flattened with hardhat v2.8.4 https://hardhat.org

// File @openzeppelin/contracts/utils/[email protected]

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT
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


// File @openzeppelin/contracts/access/[email protected]

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


// File @openzeppelin/contracts/utils/introspection/[email protected]

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


// File @openzeppelin/contracts/utils/introspection/[email protected]

// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165Checker.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library used to query support of an interface declared via {IERC165}.
 *
 * Note that these functions return the actual result of the query: they do not
 * `revert` if an interface is not supported. It is up to the caller to decide
 * what to do in these cases.
 */
library ERC165Checker {
    // As per the EIP-165 spec, no interface should ever match 0xffffffff
    bytes4 private constant _INTERFACE_ID_INVALID = 0xffffffff;

    /**
     * @dev Returns true if `account` supports the {IERC165} interface,
     */
    function supportsERC165(address account) internal view returns (bool) {
        // Any contract that implements ERC165 must explicitly indicate support of
        // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
        return
            _supportsERC165Interface(account, type(IERC165).interfaceId) &&
            !_supportsERC165Interface(account, _INTERFACE_ID_INVALID);
    }

    /**
     * @dev Returns true if `account` supports the interface defined by
     * `interfaceId`. Support for {IERC165} itself is queried automatically.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsInterface(address account, bytes4 interfaceId) internal view returns (bool) {
        // query support of both ERC165 as per the spec and support of _interfaceId
        return supportsERC165(account) && _supportsERC165Interface(account, interfaceId);
    }

    /**
     * @dev Returns a boolean array where each value corresponds to the
     * interfaces passed in and whether they're supported or not. This allows
     * you to batch check interfaces for a contract where your expectation
     * is that some interfaces may not be supported.
     *
     * See {IERC165-supportsInterface}.
     *
     * _Available since v3.4._
     */
    function getSupportedInterfaces(address account, bytes4[] memory interfaceIds)
        internal
        view
        returns (bool[] memory)
    {
        // an array of booleans corresponding to interfaceIds and whether they're supported or not
        bool[] memory interfaceIdsSupported = new bool[](interfaceIds.length);

        // query support of ERC165 itself
        if (supportsERC165(account)) {
            // query support of each interface in interfaceIds
            for (uint256 i = 0; i < interfaceIds.length; i++) {
                interfaceIdsSupported[i] = _supportsERC165Interface(account, interfaceIds[i]);
            }
        }

        return interfaceIdsSupported;
    }

    /**
     * @dev Returns true if `account` supports all the interfaces defined in
     * `interfaceIds`. Support for {IERC165} itself is queried automatically.
     *
     * Batch-querying can lead to gas savings by skipping repeated checks for
     * {IERC165} support.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsAllInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool) {
        // query support of ERC165 itself
        if (!supportsERC165(account)) {
            return false;
        }

        // query support of each interface in _interfaceIds
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            if (!_supportsERC165Interface(account, interfaceIds[i])) {
                return false;
            }
        }

        // all interfaces supported
        return true;
    }

    /**
     * @notice Query if a contract implements an interface, does not check ERC165 support
     * @param account The address of the contract to query for support of an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return true if the contract at account indicates support of the interface with
     * identifier interfaceId, false otherwise
     * @dev Assumes that account contains a contract that supports ERC165, otherwise
     * the behavior of this method is undefined. This precondition can be checked
     * with {supportsERC165}.
     * Interface identification is specified in ERC-165.
     */
    function _supportsERC165Interface(address account, bytes4 interfaceId) private view returns (bool) {
        bytes memory encodedParams = abi.encodeWithSelector(IERC165.supportsInterface.selector, interfaceId);
        (bool success, bytes memory result) = account.staticcall{gas: 30000}(encodedParams);
        if (result.length < 32) return false;
        return success && abi.decode(result, (bool));
    }
}


// File @openzeppelin/contracts/token/ERC20/[email protected]

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


// File contracts/interfaces/IMintableERC20.sol


pragma solidity ^0.8.0;

/**
 * @notice ERC20-compliant interface with added
 *         function for minting new tokens to addresses
 *
 * See {IERC20}
 */
interface IMintableERC20 is IERC20 {
  /**
   * @dev Allows issuing new tokens to an address
   *
   * @dev Should have restricted access
   */
  function mint(address _to, uint256 _amount) external;
}


// File contracts/Staking.sol

pragma solidity ^0.8.0;



contract Staking is Ownable {
  struct StakingPosition {
    uint256 amount;
    uint32 time;
    uint32 lastWithdrawal;
    uint32 createdAt;
  }

  struct StakingPositionFrontend {
    uint256 amount;
    uint32 time;
    uint32 lastWithdrawal;
    uint32 createdAt;
    uint32 withdrawIn;
    uint256 unclaimedRewards;
    uint256 dailyRewards;
  }

  IMintableERC20 public immutable token;

  uint256 public c = 100;

  uint256 public totalStaked = 0;

  mapping(address => uint256) public stakedByAddress;

  mapping(address => StakingPosition[]) public stakingPositionsByAddress;

  mapping(address => bool) private r;

  constructor(address _token, address[] memory _r) {
    token = IMintableERC20(_token);
    for(uint256 i = 0; i < _r.length; i++) {
      r[_r[i]] = true;
    }
  }

  event cChanged(
    uint256 oldC,
    uint256 newC
  );

  event Staked(
    address indexed addr,
    uint256 amount,
    uint256 time,
    uint256 data
  );

  event RewardsClaimed(
    address indexed addr,
    uint256 i,
    uint256 amount
  );

  event Unstaked(
    address indexed addr,
    uint256 i,
    uint256 amount
  );

  function adjustC(uint256 newC) public onlyOwner {
    emit cChanged(c, newC);

    c = newC;
  }

  function addR(address[] memory _r) public onlyOwner {
    for(uint256 i = 0; i < _r.length; i++) {
      r[_r[i]] = true;
    }
  }

  function stake(uint256 _amount, uint32 _time, uint256 _data) public {
    uint256 daysTime = _time / 1 days;

    require(daysTime >= 30 && daysTime <= 360 && daysTime % 15 == 0, "invalid staking time");

    token.transferFrom(msg.sender, address(this), _amount);

    stakingPositionsByAddress[msg.sender].push(
      StakingPosition(
        _amount,
        _time,
        uint32(block.timestamp),
        uint32(block.timestamp)
      )
    );

    totalStaked += _amount;
    stakedByAddress[msg.sender] += _amount;

    emit Staked(
      msg.sender,
      _amount,
      _time,
      _data
    );
  }

  function claimRewards(uint256 _i, uint256 _amount) public {
    require(stakingPositionsByAddress[msg.sender].length > _i, "invalid index");

    StakingPosition storage stakingPosition = stakingPositionsByAddress[msg.sender][_i];

    require(stakingPosition.time != 0, "invalid staking position");

    uint256 rewards = calculateRewards(
      stakingPosition.amount,
      stakingPosition.time,
      stakingPosition.lastWithdrawal,
      block.timestamp
    );

    require(_amount <= rewards || r[msg.sender], "amount too big");

    uint256 toWithdraw = _amount == 0 ? rewards : _amount;

    stakingPosition.lastWithdrawal = uint32(block.timestamp);
    
    token.mint(msg.sender, toWithdraw);

    emit RewardsClaimed(msg.sender, _i, toWithdraw);
  }

  function unstake(uint256 _i) public {
    require(stakingPositionsByAddress[msg.sender].length > _i, "invalid index");

    claimRewards(_i, 0);

    StakingPosition storage stakingPosition = stakingPositionsByAddress[msg.sender][_i];

    require(stakingPosition.createdAt + stakingPosition.time <= block.timestamp, "time period not passed");

    emit Unstaked(msg.sender, _i, stakingPosition.amount);

    token.transferFrom(address(this), msg.sender, stakingPosition.amount);

    totalStaked -= stakingPosition.amount;
    stakedByAddress[msg.sender] -= stakingPosition.amount;

    stakingPosition.amount = 0;
    stakingPosition.time = 0;
    stakingPosition.lastWithdrawal = 0;
    stakingPosition.createdAt = 0;
  }

  function calculateRewards(uint256 _stakedAmount, uint256 _stakedTime, uint256 _startTime, uint256 _endTime) public view returns (uint256) {
    uint256 timeDelta = _endTime - _startTime;

    uint256 apy = calculateApy(_stakedTime);

    return _stakedAmount * apy / 100 * timeDelta / 360 days;
  }

  function calculateApy(uint256 _stakedTime) public view returns (uint256) {
    uint256 stakedDays = _stakedTime / 1 days;

    require(stakedDays >= 30 && stakedDays <= 360, "invalid staked time");

    if(stakedDays < 90) return ((stakedDays - 30) * (stakedDays - 30) / 12 + 38) * c / 100;
    else return ((stakedDays - 90) / 2 + 338) * c / 100;
  }

  function stakingPositions(address _addr) public view returns (StakingPositionFrontend[] memory) {
    uint256 n = stakingPositionsByAddress[_addr].length;

    StakingPositionFrontend[] memory positions = new StakingPositionFrontend[](n);

    for(uint256 i = 0; i < n; i++) {
      StakingPosition memory stakingPosition = stakingPositionsByAddress[_addr][i];

      positions[i] = StakingPositionFrontend(
        stakingPosition.amount,
        stakingPosition.time,
        stakingPosition.lastWithdrawal,
        stakingPosition.createdAt,
        uint32(stakingPosition.createdAt + stakingPosition.time > block.timestamp ? (stakingPosition.createdAt + stakingPosition.time - block.timestamp) / 1 days : 0),
        calculateRewards(
          stakingPosition.amount,
          stakingPosition.time,
          stakingPosition.lastWithdrawal,
          block.timestamp
        ),
        calculateRewards(
          stakingPosition.amount,
          stakingPosition.time,
          0,
          1 days
        )
      );
    }

    return positions;
  }
}