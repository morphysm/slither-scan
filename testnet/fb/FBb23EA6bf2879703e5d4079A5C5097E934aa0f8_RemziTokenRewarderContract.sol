// SPDX-License-Identifier: MIT

// Generated and Deployed by PolyVerse - www.polyverse.life

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";


interface IRewardToken {
    function mint(address to, uint amount) external;
}

contract RemziTokenRewarderContract is Ownable {

    address public REWARD_TOKEN = 0xC65a51AF913664faf355bA482b5BdfF7dE75fFA7;
    address public SIGNER_WALLET = 0x904A378632021919a22DB0578Cc6Dc4812Dc8dd6;
    bool public IsRewardingPaused = false;
        
    function claimPrize(bytes32 _hashedMessage, uint8 _v, bytes32 _r, bytes32 _s, uint amount) public {

        require(!IsRewardingPaused, "Rewarding has been stopped");
        require(amount > 0, "Amount must be greater than 0");

        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 prefixedHashMessage = keccak256(abi.encodePacked(prefix, _hashedMessage));
        address signer = ecrecover(prefixedHashMessage, _v, _r, _s);

        require(signer == SIGNER_WALLET,"You do not have permission for this action");

        IRewardToken r = IRewardToken(REWARD_TOKEN);
        r.mint(msg.sender, amount);
    }

    function setRewardToken(address addr) public onlyOwner {
        REWARD_TOKEN=addr;
    }

    function setSigner(address addr) public onlyOwner {
        SIGNER_WALLET=addr;
    }

    function pauseRewarding() public onlyOwner {
        IsRewardingPaused=true;
    }

    function unpauseRewarding() public onlyOwner {
        IsRewardingPaused=false;
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