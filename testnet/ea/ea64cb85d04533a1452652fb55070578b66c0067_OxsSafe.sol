/**
 *Submitted for verification at testnet.snowtrace.io on 2022-09-15
*/

// Sources flattened with hardhat v2.11.1 https://hardhat.org

// File contracts/base/IOwnerManager.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @author Coinoxs Dev <[email protected]>
interface IOwnerManager {
    /// @dev ConfirmTransaction event fires when the transaction is confirmed
    /// @param transactionIndex Transaction Index
    /// @param transactionIndex Address of the owner who gave the confirmation
    /// @param transactionIndex Total number of confirmations of the transaction
    event ConfirmTransaction(uint transactionIndex, address owner, uint confirmCount);

    /// @dev Function to check if the address is one of the smart contract signers
    /// @param _owner Address of the potential signer to evaluate
    /// @return Returns boolean depending on the result of evaluation
    function isOwner(address _owner) external view returns (bool);

    /// @dev Returns list of owners
    /// @return List of owner addresses
    function getOwners() external view returns (address[] memory);

    /// @dev Getter to check the executing threshold
    /// @return Returns integer, which represents signing executing for transaction
    function getThreshold() external view returns (uint);
}


// File contracts/base/ITransactionManager.sol


pragma solidity ^0.8.0;

/// @author Coinoxs Dev <[email protected]>
interface ITransactionManager {
    /// @dev TransactionSubmitted event fires when a new transaction is submitted
    /// @param transactionIndex Transaction Index
    /// @param creator          Creator of the transaction
    /// @param token            If token transfer will be made, address of ERC20 Contract
    /// @param destination      Transaction target address
    /// @param value            Transaction value
    event TransactionSubmitted(uint transactionIndex, address creator, address token, address payable destination, uint value);

    /// @dev Transaction structure
    struct TransactionToken {
        /// @dev Transaction creators address
        address creator;
        /// @dev If token transfer will be made, address of ERC20 Contract
        address token;
        /// @dev Transaction target address
        address payable destination;
        /// @dev Transaction value
        uint value;
        /// @dev Block number where the transaction was created
        uint blockCreated;
        /// @dev Block number where the transaction was finalised
        uint blockFinalised;
        /// @dev Transaction is executed
        bool executed;
    }

    /// @dev Returns total number of transactions after filers are applied.
    /// @param pending Include pending transactions.
    /// @param executed Include executed transactions.
    /// @return Total number of transactions after filters are applied.
    function getTransactionCount(bool pending, bool executed) external view returns (uint);

    /// @dev Getter for transaction
    /// @param _transactionIndex    Transaction Index
    /// @return TransactionToken
    function getTransaction(uint _transactionIndex) external view returns (TransactionToken memory);
}


// File contracts/wallet/IOxsWallet.sol


pragma solidity ^0.8.0;


/**
 * @dev Interface of the OxsWallet
 * @author Coinoxs Dev <[email protected]>
 */
interface IOxsWallet is IOwnerManager, ITransactionManager {
    /**
    / @dev TransactionExecuted event fires when the transaction is executed
    / @param transactionIndex   Transaction Index
    */
    event TransactionExecuted(uint transactionIndex);


    /// @dev Constructor function to create new wallet.
    /// @param _owners Owners who will create and confirm safe transactions.
    /// @param _threshold Unsigned integer representing the minimum number of signers required for transaction confirmation.
    function initialize(address[] calldata _owners, uint _threshold) external;

    /// @dev Returns array with owner addresses, which confirmed transaction
    /// @param _transactionIndex Transaction ID
    /// @return Returns array of owner addresses
    function getConfirmations(uint _transactionIndex) external view returns (address[] memory);


    /// @dev Returns number of confirmations of a transaction
    /// @param _transactionIndex Transaction ID
    /// @return Number of confirmations
    function getConfirmationCount(uint _transactionIndex) external view returns (uint);

    /// @dev Returns the confirmation status of a transaction
    /// @param _transactionIndex Transaction ID
    /// @return Confirmation status
    function isConfirmed(uint _transactionIndex) external view returns (bool);

    /// @dev Allows owner to submit a confirmed transaction.
    /// @param token            If token transfer will be made, address of ERC20 Contract
    /// @param destination      Transaction target address
    /// @param value            Transaction value
    function submitTransaction(address token, address payable destination, uint value) external returns (uint);


    /// @dev Allows owner to confirm transaction.
    /// @param _transactionIndex Transaction Index.
    function confirmTransaction(uint _transactionIndex) external;

    /// @dev Allows owner to execute a confirmed transaction.
    /// @param _transactionIndex Transaction Index.
    function executeTransaction(uint _transactionIndex) external;
}


// File @openzeppelin/contracts/utils/[email protected]


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


// File @openzeppelin/contracts/access/[email protected]


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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


// File @openzeppelin/contracts/proxy/[email protected]


// OpenZeppelin Contracts (last updated v4.7.0) (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}


// File contracts/OxsSafe.sol


pragma solidity ^0.8.0;



/// @notice The most trusted digital asset management platform with signatures to verify transactions.
/// @author Coinoxs Dev <[email protected]>
contract OxsSafe is Ownable {
    using Clones for address;

    /**
    * @dev NewSafeWallet event fires when new safe wallet created
    * @param creator          Creator of the transaction
    * @param owners Owners who will create and confirm safe transactions.
    * @param threshold Unsigned integer representing the minimum number of signers required for transaction confirmation.
    */
    event NewSafeWallet(address creator, address[] owners, uint threshold);

    /**
    * @dev ImplementationAddressChanged event fires when implementation address changed
    * @param previousAddr     Previous Implementation Address
    * @param newAddr          New Implementation Address
    */
    event ImplementationAddressChanged(address indexed previousAddr, address indexed newAddr);

    /// @dev Address of the wallet contract to be cloned
    address public implementation;

    /// @dev Cloned wallet list
    IOxsWallet[] public wallets;

    /// @dev OxsSafe Constructor for set implementation on built
    constructor(address _implementation) {
        implementation = _implementation;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal override view {
        require(owner() == _msgSender(), "OX101");
        // caller is not the owner
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public override onlyOwner {
        require(newOwner != address(0), "OX102");
        // new owner is the zero address
        _transferOwnership(newOwner);
    }

    /// @dev Set Implementation address
    function setImplementationAddress(address _implementation) external onlyOwner {
        address oldImplementation = implementation;
        implementation = _implementation;

        emit ImplementationAddressChanged(oldImplementation, _implementation);
    }

    /// @dev Create new safe wallet
    /// @param _owners Owners who will create and confirm safe transactions.
    /// @param _threshold Unsigned integer representing the minimum number of signers required for transaction confirmation.
    /// @return IOxsWallet
    function createWallet(address[] calldata _owners, uint _threshold) external returns (IOxsWallet) {
        IOxsWallet wallet = IOxsWallet(implementation.clone());
        wallet.initialize(_owners, _threshold);
        emit NewSafeWallet(_msgSender(), _owners, _threshold);
        return wallet;
    }
}