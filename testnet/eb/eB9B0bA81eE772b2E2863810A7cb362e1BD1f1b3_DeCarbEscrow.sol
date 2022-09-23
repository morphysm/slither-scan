// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IDeCarbParams.sol";
import "./interfaces/IDAO.sol";
import "./interfaces/ILiquidity.sol";
import "./interfaces/IDCO2.sol";

contract DeCarbEscrow is Ownable {
    //variables
    struct Escrow {
        address payable creator;
        bytes32 escrowID;
        string projectID;
        uint256 vintage;
        uint256 tCO2; //Tonnes CO2 being escrowed
        uint256 depositFee; //determines the escrow time period
        uint256 escrowValue;
        uint256 escrowPeriod; //in hours
        uint256 creationTs;
        string status; //opened, approved, rejected, cancelled
    }

    struct Totals {
        uint256 escrowOpened;
        uint256 escrowApproved;
        uint256 escrowRejected;
        uint256 escrowInPipeLine;
        uint256 lastUpdateTs;
    }

    Totals public totals;

    bytes32 public escrowID;
    bytes32[] public escrowIDs;

    //interfaces
    IERC20 public dco2Token;
    IERC20 public vDco2Token;
    IDeCarbParams public keyParams;
    IDAO public decarbDAO;
    ILiquidity public liquidity;
    IDCO2 public dco2Staker;

    mapping(bytes32 => bool) public isValidEscrowId;
    mapping(bytes32 => Escrow) public escrowIdToEscrow;

    //events
    event EscrowCreated(Escrow _escrow);
    event EscrowApproved(bytes32 _escrowID, uint256 _escrowValue);
    event EscrowRejected(bytes32 _escrowID, uint256 _escrowValue);
    event EscrowCancelled(bytes32 _escrowID);

    constructor() {
        transferOwnership(msg.sender);
    }

    function openCarbonEscrow(
        string memory _projectID,
        uint256 _vintage,
        uint256 _tCO2,
        uint256 _escrowPeriod, //in hours
        uint256 _nonce
    ) external payable returns (bytes32) {
        require(_tCO2 > 1, "CO2 Tonnes should be more than 1");
        require(msg.value > 0 ether, "deposit fee is less");
        require(
            keyParams.isProjectIdApproved(_vintage, _projectID),
            "project not approved"
        );
        uint256 co2PriceInUSDC = keyParams.getVintPrice(_vintage, _projectID);
        uint256 _escrowValue = (_tCO2 * co2PriceInUSDC);

        //need to get DCO2 Price in USDC
        uint256 dco2PriceInUSDC = keyParams.getDco2USDC();
        uint256 swapDCO2 = (_escrowValue / dco2PriceInUSDC);

        require(liquidity.totalLiquidity() > swapDCO2, "Not enough liquidity");
        bool success = liquidity.initSwap(swapDCO2, payable(msg.sender));
        require(success, "Something went wrong");

        escrowID = keccak256(
            abi.encode(_projectID, _vintage, _tCO2, _escrowPeriod, _nonce)
        );

        Escrow memory escrow;
        escrow.creator = payable(msg.sender);
        escrow.escrowID = escrowID;
        escrow.projectID = _projectID;
        escrow.vintage = _vintage;
        escrow.tCO2 = _tCO2;
        escrow.depositFee = msg.value; //in ethers
        escrow.escrowValue = _escrowValue;
        escrow.escrowPeriod = _escrowPeriod * 3600; //in seconds
        escrow.creationTs = block.timestamp;
        escrow.status = "opened";

        isValidEscrowId[escrowID] = true;
        escrowIdToEscrow[escrowID] = escrow;

        totals.escrowOpened += _escrowValue;
        totals.escrowInPipeLine += _escrowValue;
        totals.lastUpdateTs = block.timestamp;

        escrowIDs.push(escrowID);

        address treasuryAdd = keyParams.treasuryAdd();

        payable(treasuryAdd).transfer(msg.value);

        emit EscrowCreated(escrow);
        return escrowID;
    }

    //_time is in hours
    function getFee(uint256 _tco2, uint256 _time)
        external
        returns (uint256 _feeRequired)
    {
        uint256 tenPow18 = 10**18;
        uint256 dco2PriceInUSDC = keyParams.getDco2USDC() / tenPow18;

        _feeRequired = (dco2PriceInUSDC * _tco2 * _time * 5) / 2400; //in ethers
    }

    function validateCarbonEscrow(bytes32 _escrowID) external {
        require(isValidEscrowId[_escrowID], "Not a valid ID");
        Escrow storage escrow = escrowIdToEscrow[_escrowID];

        if (block.timestamp > (escrow.creationTs + escrow.escrowPeriod)) {
            bool success = decarbDAO.startVoting(escrow.escrowID, escrow.tCO2);
            require(success, "Something went wrong");
        }

        if (block.timestamp < (escrow.creationTs + escrow.escrowPeriod)) {
            require(msg.sender == escrow.creator, "Not Authorised");
            bool success = decarbDAO.startVoting(escrow.escrowID, escrow.tCO2);
            require(success, "Something went wrong");
        }
    }

    // it will be called by DAO
    function approveEscrow(bytes32 _escrowID) external payable {
        uint256 tenPow18 = 10**18;
        require(msg.sender == address(decarbDAO), "Not Authorised");
        require(isValidEscrowId[_escrowID], "Not a valid ID");
        Escrow storage escrow = escrowIdToEscrow[_escrowID];

        //get DCO2 Price in USDC
        uint256 dco2PriceInUSDC = keyParams.getDco2USDC() / tenPow18;
        uint256 swapDCO2 = (escrow.escrowValue / dco2PriceInUSDC);

        require(liquidity.totalLiquidity() > swapDCO2, "Not enough liquidity");
        if (liquidity.completeSwap(swapDCO2, escrow.creator)) {
            totals.escrowApproved += escrow.escrowValue;
            totals.escrowInPipeLine -= escrow.escrowValue;
            totals.lastUpdateTs = block.timestamp;
            escrow.status = "approved";
            emit EscrowApproved(_escrowID, swapDCO2);
        }
    }

    function rejectEscrow(bytes32 _escrowID) external {
        require(msg.sender == address(decarbDAO), "Not Authorised");
        require(isValidEscrowId[_escrowID], "Not a valid ID");
        Escrow storage escrow = escrowIdToEscrow[_escrowID];

        //Get DCO2 Price in USDC
        uint256 dco2PriceInUSDC = keyParams.getDco2USDC();
        uint256 swapDCO2 = (escrow.escrowValue / dco2PriceInUSDC);
        if (liquidity.unSwap(swapDCO2, escrow.creator)) {
            totals.escrowRejected = escrow.escrowValue;
            totals.escrowInPipeLine -= escrow.escrowValue;
            totals.lastUpdateTs = block.timestamp;
            escrow.status = "rejected";
            emit EscrowRejected(_escrowID, swapDCO2);
        }
    }

    function cancelEscrow(bytes32 _escrowID) external {
        require(isValidEscrowId[_escrowID], "Not a valid ID");
        Escrow storage escrow = escrowIdToEscrow[_escrowID];
        require(msg.sender == escrow.creator, "Not Authorised");
        require(
            block.timestamp < escrow.creationTs + escrow.escrowPeriod,
            "Escrow period expried"
        );

        //Get DCO2 Price in USDC
        uint256 dco2PriceInUSDC = keyParams.getDco2USDC();
        uint256 swapDCO2 = (escrow.escrowValue / dco2PriceInUSDC);
        if (liquidity.unSwap(swapDCO2, escrow.creator)) {
            totals.escrowRejected = escrow.escrowValue;
            totals.escrowInPipeLine -= escrow.escrowValue;
            totals.lastUpdateTs = block.timestamp;
            escrow.status = "cancelled";
            emit EscrowCancelled(_escrowID);
        }
        uint256 timeDiffInHrs = (block.timestamp - escrow.creationTs);

        // deposit fee is reduced prorata as per the time elaplsed since ecrow creation
        uint256 lessFee = ((escrow.depositFee * 10 * 18) *
            timeDiffInHrs *
            100) / escrow.escrowPeriod;
    }

    function isContract(address _addr)
        external
        view
        returns (bool _isContract)
    {
        uint32 size;
        assembly {
            size := extcodesize(_addr)
        }
        return (size > 0);
    }

    //set interfaces
    function setDco2Token(address _dco2Token) external onlyOwner {
        require(_dco2Token != address(0), "invalid address");
        dco2Token = IERC20(_dco2Token);
    }

    function setVDco2Token(address _vDco2Token) external onlyOwner {
        require(_vDco2Token != address(0), "invalid address");
        vDco2Token = IERC20(_vDco2Token);
    }

    function setDeCarbParams(address _keyParams) external onlyOwner {
        require(_keyParams != address(0), "invalid address");
        keyParams = IDeCarbParams(_keyParams);
    }

    function setDecarbDAO(address _decarbDAO) external onlyOwner {
        require(_decarbDAO != address(0), "invalid address");
        decarbDAO = IDAO(_decarbDAO);
    }

    function setLiquidity(address _liquidity) external onlyOwner {
        require(_liquidity != address(0), "invalid address");
        liquidity = ILiquidity(_liquidity);
    }

    function setDco2Staker(address _dco2Staker) external onlyOwner {
        require(_dco2Staker != address(0), "invalid address");
        dco2Staker = IDCO2(_dco2Staker);
    }

    function getEscrows() external view returns (Escrow[] memory) {
        uint256 len = escrowIDs.length;
        Escrow[] memory escr = new Escrow[](len);
        for (uint256 i = 0; i < len; i++) {
            require(isValidEscrowId[escrowIDs[i]], "Not a valid ID");
            escr[i] = (escrowIdToEscrow[escrowIDs[i]]);
        }
        return escr;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IDeCarbParams {
    function isProjectIdApproved(uint256 _vintage, string memory _projectID)
        external
        view
        returns (bool);

    function getVintPrice(uint256 _vintage, string memory _projectID)
        external
        view
        returns (uint256);

    function treasuryAdd() external view returns (address);

    function getDco2USDC() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IDAO {
    function isEscrowAllowed() external returns (bool);

    function startVoting(bytes32 _escrowID, uint256 _tCO2)
        external
        returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ILiquidity {
    function totalLiquidity() external view returns (uint256);

    function initSwap(uint256 _amount, address payable _receiver)
        external
        view
        returns (bool);

    function completeSwap(uint256 _amount, address payable _receiver)
        external
        view
        returns (bool);

    function unSwap(uint256 _amount, address payable _receiver)
        external
        view
        returns (bool);

    function dco2InUSDC() external pure returns (uint256);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.4;
pragma experimental ABIEncoderV2;

import "../libraries/LibDCO2Storage.sol";

interface IDCO2 {
    // deposit allows a user to add more dco2 to his staked balance
    function deposit(uint256 amount) external;

    // withdraw allows a user to withdraw funds if the balance is not locked
    function withdraw(uint256 amount) external;

    // lock a user's currently staked balance until timestamp & add the bonus to his voting power
    function lock(uint256 timestamp) external;

    // delegate allows a user to delegate his voting power to another user
    function delegate(address to) external;

    // stopDelegate allows a user to take back the delegated voting power
    function stopDelegate() external;

    // lock the balance of a proposal creator until the voting ends; only callable by DAO
    function lockCreatorBalance(address user, uint256 timestamp) external;

    // balanceOf returns the current DCO2 balance of a user (bonus not included)
    function balanceOf(address user) external view returns (uint256);

    // balanceAtTs returns the amount of DCO2 that the user currently staked (bonus NOT included)
    function balanceAtTs(address user, uint256 timestamp)
        external
        view
        returns (uint256);

    // stakeAtTs returns the Stake object of the user that was valid at `timestamp`
    function stakeAtTs(address user, uint256 timestamp)
        external
        view
        returns (LibDCO2Storage.Stake memory);

    // votingPower returns the voting power (bonus included) + delegated voting power for a user at the current block
    function votingPower(address user) external view returns (uint256);

    // votingPowerAtTs returns the voting power (bonus included) + delegated voting power for a user at a point in time
    function votingPowerAtTs(address user, uint256 timestamp)
        external
        view
        returns (uint256);

    // dco2Staked returns the total raw amount of DCO2 staked at the current block
    function dco2Staked() external view returns (uint256);

    // dco2StakedAtTs returns the total raw amount of DCO2 users have deposited into the contract
    // it does not include any bonus
    function dco2StakedAtTs(uint256 timestamp) external view returns (uint256);

    // delegatedPower returns the total voting power that a user received from other users
    function delegatedPower(address user) external view returns (uint256);

    // delegatedPowerAtTs returns the total voting power that a user received from other users at a point in time
    function delegatedPowerAtTs(address user, uint256 timestamp)
        external
        view
        returns (uint256);

    // multiplierAtTs calculates the multiplier at a given timestamp based on the user's stake a the given timestamp
    // it includes the decay mechanism
    function multiplierAtTs(address user, uint256 timestamp)
        external
        view
        returns (uint256);

    // userLockedUntil returns the timestamp until the user's balance is locked
    function userLockedUntil(address user) external view returns (uint256);

    // userDidDelegate returns the address to which a user delegated their voting power; address(0) if not delegated
    function userDelegatedTo(address user) external view returns (address);

    // dco2CirculatingSupply returns the current circulating supply of DCO2
    function dco2CirculatingSupply() external view returns (uint256);
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

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.4;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IRewards.sol";

library LibDCO2Storage {
    bytes32 constant STORAGE_POSITION = keccak256("com.decarb.dco2.storage");

    struct Checkpoint {
        uint256 timestamp;
        uint256 amount;
    }

    struct Stake {
        uint256 timestamp;
        uint256 amount;
        uint256 expiryTimestamp;
        address delegatedTo;
    }

    struct Storage {
        bool initialized;
        // mapping of user address to history of Stake objects
        // every user action creates a new object in the history
        mapping(address => Stake[]) userStakeHistory;
        // array of DCO2 staked Checkpoint
        // deposits/withdrawals create a new object in the history (max one per block)
        Checkpoint[] dco2StakedHistory;
        // mapping of user address to history of delegated power
        // every delegate/stopDelegate call create a new checkpoint (max one per block)
        mapping(address => Checkpoint[]) delegatedPowerHistory;
        IERC20 dco2;
        IRewards rewards;
    }

    function dco2Storage() internal pure returns (Storage storage ds) {
        bytes32 position = STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.4;
pragma experimental ABIEncoderV2;

interface IRewards {
    function registerUserAction(address user) external;
}