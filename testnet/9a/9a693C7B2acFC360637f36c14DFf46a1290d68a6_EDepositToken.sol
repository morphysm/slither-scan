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

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);
    
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

contract EDepositToken is Ownable {
    event SetPackage(uint256 id, address token, uint256 amount);
    event Deposit(address user, uint256 packageId);
    event Withdraw(address token, uint256 amount);

    struct Package {
      uint256 id;
      address token;
      uint256 amount;
    }

    mapping(uint256 => Package) public packages;
    address public ceoAddress;
    constructor(address _token) {
        _changeCeo(_msgSender());
        _setPackage(1, _token, 5 ether);
        _setPackage(2, _token, 6 ether);
        _setPackage(3, _token, 7 ether);
    }

    modifier onlyManager() {
        require(_msgSender() == owner() || _msgSender() == ceoAddress);
        _;
    }

    modifier onlyCeoAddress() {
        require(_msgSender() == ceoAddress);
        _;
    }

    function setPackage(uint256 _id, address _token, uint256 _amount) public onlyCeoAddress {
      require(_token != address(0), "Invalid address!");
      require(_amount > 0, "Amount must be >0!");
      _setPackage(_id, _token, _amount);
    }

    function _setPackage(uint256 _id, address _token, uint256 _amount) private {
        packages[_id] = Package({id: _id, token: _token, amount: _amount});
        emit SetPackage(_id, _token, _amount);
    }

    function deposit(uint _id) public {
        require(packages[_id].token != address(0), "Invalid token!");
        address account = _msgSender();
        IERC20(packages[_id].token).transferFrom(account, address(this), packages[_id].amount);
        emit Deposit(account, _id);
    }
    
    function withdraw(address _token, uint256 _amount) public onlyManager {
        IERC20 erc20 = IERC20(_token);
        require(erc20.balanceOf(address(this)) > 0, "Cannot withdraw 0!");
        erc20.transfer(_msgSender(), _amount);
        emit Withdraw(_token, _amount);
    }

    function changeCeo(address _address) public onlyCeoAddress {
        require(_address != address(0), "Invalid address");
        _changeCeo(_address);
    }   

    function _changeCeo(address _address) private {
        ceoAddress = _address;
    }
}