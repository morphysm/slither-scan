// SPDX-License-Identifier: MIT LICENSE

pragma solidity =0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../../Controllable.sol";

contract NFTMintRegister is Controllable {
    
    mapping(uint256 => mapping(address => uint256)) public genMintsPerAddress;

    mapping(uint256 => bool) public initialized;

    function ownerAddMints(uint256 generation, address[] memory addresses, uint256[] memory amounts) external onlyOwner {
        require(addresses.length == amounts.length, "length does not match");
        for (uint256 i; i < addresses.length; i++) {
            _addMint(generation, addresses[i], amounts[i]);
        }
    }
    function ownerRemoveMints(uint256 generation, address[] memory addresses, uint256[] memory amounts) external onlyOwner {
        require(addresses.length == amounts.length, "length does not match");
        for (uint256 i; i < addresses.length; i++) {
            _removeMint(generation, addresses[i], amounts[i]);
        }
    }
    function ownerSetMints(uint256 generation, address[] memory addresses, uint256[] memory amounts) external onlyOwner {
        require(!initialized[generation], "");
        require(addresses.length == amounts.length, "length does not match");
        for (uint256 i; i < addresses.length; i++) {
            _setMint(generation, addresses[i], amounts[i]);
        }
    }

    function setInitialized(uint256 generation) external onlyOwner {
        initialized[generation];
    }

    function addMint(uint256 g, address a, uint256 c) external onlyController {
        _addMint(g, a, c);
    }
    function removeMint(uint256 g, address a, uint256 c) external onlyController {
        _removeMint(g, a, c);
    }

    function _addMint(uint256 g, address a, uint256 c) internal {
        genMintsPerAddress[g][a] += c;
    }
    function _removeMint(uint256 g, address a, uint256 c) internal {
        genMintsPerAddress[g][a] -= c;
    }
    function _setMint(uint256 g, address a, uint256 c) internal {
        genMintsPerAddress[g][a] = c;
    }
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

// SPDX-License-Identifier: MIT LICENSE

pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Controllable is Ownable {
    mapping (address => bool) controllers;

    event ControllerAdded(address);
    event ControllerRemoved(address);

    modifier onlyController() {
        require(controllers[_msgSender()] || _msgSender() ==  owner(), "Only controllers can do that");
        _;
    }

    /*** ADMIN  ***/
    /**
     * enables an address to mint / burn
     * @param controller the address to enable
     */
    function addController(address controller) external onlyOwner {
         _addController(controller);
    }

    function _addController(address controller) internal {
        if (!controllers[controller]) {
            controllers[controller] = true;
            emit ControllerAdded(controller);
        }
    }

    /**
     * disables an address from minting / burning
     * @param controller the address to disbale
     */
    function removeController(address controller) external onlyOwner {
        _RemoveController(controller);
    }

    function _RemoveController(address controller) internal {
        if (controllers[controller]) {
            controllers[controller] = false;
            emit ControllerRemoved(controller);
        }
    }
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