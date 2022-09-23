// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './interface/IManager.sol';
import './interface/IERC20.sol';
import './utils/Ownable.sol';

interface IPool {
    function pay(address _to, uint _amount) external returns (bool);
}

contract Helper is Ownable {

    IManager public manager;

    IERC20 public token;

    address public dao;

    IPool public pool;
    
    // base 10**2
    uint public daoFee;
    uint public claimFee;

    uint private randomCallCount = 0;

    constructor(address _manager, address _token, address _pool, address daoAdrs, uint _daoFee, uint _claimFee) {
        manager = IManager(_manager);
        token = IERC20(_token);
        pool = IPool(_pool);
        dao = daoAdrs;
        daoFee = _daoFee;
        claimFee = _claimFee;
    }

    function updateDaoAddress(address payable _dao) external onlyOwner {
        dao = _dao;
    }

    function updateDaoFee(uint _fee) external onlyOwner {
        daoFee = _fee;
    }

    function updateClaimFee(uint _fee) external onlyOwner {
        claimFee = _fee;
    }

    function updatePoolAddress(address _pool) external onlyOwner {
        pool.pay(address(owner()), token.balanceOf(address(pool)));
        pool = IPool(_pool);
    }

    function _transferIt(uint contractTokenBalance) internal {
        uint daoTokens = (contractTokenBalance * daoFee) / 100;
        token.transfer(dao, daoTokens);

        token.transfer(address(pool), contractTokenBalance - daoTokens);
    }

    // randomized through block timestamp, it'll be upgraded to chainlink
    function random() internal returns(uint){
        randomCallCount += 1;
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, randomCallCount)));
    }
    function isInRange(uint index, uint rangeStart, uint rangeEnd) internal pure returns(bool) {
        for(uint i = rangeStart; i <= rangeEnd; i++){
            if(i == index){
                return true;
            }
        }
        return false;
    }
    function drawTier() internal returns(uint8){
        uint tierIndex = random() % 100;
        // tier 1 6%
        if(isInRange(tierIndex, 0, 5)){
            return 1;
        }
        // tier 2 14%
        if(isInRange(tierIndex, 6, 19)){
            return 2;
        }
        // tier 3 21%
        if(isInRange(tierIndex, 20, 40)){
            return 3;
        }
        // tier 4 26%
        if(isInRange(tierIndex, 41, 66)){
            return 4;
        }
        // tier 5 33%
        if(isInRange(tierIndex, 67, 99)){
            return 5;
        }
        return 0;
    }

    function createNodeWithTokens(string memory name, uint paidAmount) public {
        require(bytes(name).length > 0 && bytes(name).length < 33, "HELPER: name size is invalid");
        address sender = _msgSender();
        require(sender != address(0), "HELPER:  Creation from the zero address");
        require(token.balanceOf(sender) >= paidAmount, "HELPER: Balance too low for creation.");
        token.transferFrom(_msgSender(), address(this), paidAmount);
        uint contractTokenBalance = token.balanceOf(address(this));
        _transferIt(contractTokenBalance);
        uint8 tier = drawTier();
        manager.createNode(sender, name, tier, paidAmount);
    }

    function payRewardsAndClaimFee(uint rewardAmount, address sender) internal{
        require(rewardAmount > 0,"HELPER: You don't have enough reward to cash out");
        uint claimFeeAmount = rewardAmount * claimFee / 100;
        pool.pay(dao, claimFeeAmount);
        pool.pay(sender, rewardAmount - claimFeeAmount);
    }

    function claimAll() public {
        address sender = _msgSender();
        uint rewardAmount = manager.claimAll(sender);

        payRewardsAndClaimFee(rewardAmount, sender);

        // require(rewardAmount > 0,"HELPER: You don't have enough reward to cash out");
        // return pool.pay(sender, rewardAmount);
    }

    function claim(uint _node) public {
        address sender = _msgSender();
        uint rewardAmount = manager.claim(sender, _node);

        payRewardsAndClaimFee(rewardAmount, sender);

        // require(rewardAmount > 0,"HELPER: You don't have enough reward to cash out");
        // return pool.pay(sender, rewardAmount);
    }

    function claimAndCompoundAll() public {
        manager.claimAndCompoundAll(_msgSender());
    }

    function claimAndCompound(uint _node) public {
        manager.claimAndCompound(_msgSender(), _node);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './Context.sol';

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
pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './IERC721.sol';

interface IManager is IERC721 {
    // function price() external returns(uint256);
    function createNode(address account, string memory nodeName, uint8 tier, uint paidAmount) external;
    function claim(address account, uint256 _id) external returns (uint);
    function claimAndCompound(address account, uint _id) external;
    function claimAll(address account) external returns (uint);
    function claimAndCompoundAll(address account) external;
    function stake(address account, uint id, uint amountToStake) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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

abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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
    function transferFrom(
        address sender,
        address recipient,
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