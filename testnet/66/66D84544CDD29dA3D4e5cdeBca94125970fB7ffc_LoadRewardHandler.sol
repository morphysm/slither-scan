// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./libraries/IRewardReceiver.sol";
import "./libraries/IERC20Mint.sol";

contract LoadRewardHandler is
    ReentrancyGuard,
    Ownable,
    ERC721Holder,
    IRewardReceiver
{
    using ECDSA for bytes32;

    event NestStaked(address indexed user, uint256 indexed tokenId);
    event NestWithdrawn(address indexed user, uint256 indexed tokenId);
    event NestClaimed(
        address indexed user,
        uint256 indexed tokenId,
        address indexed tokenClaimed,
        uint256 amount
    );
    event TreasuryPercentageSet(
        address indexed user,
        uint256 oldPercentage,
        uint256 newPercentage
    );
    event TokenBurnPercentageSet(
        address indexed user,
        address indexed token,
        uint256 oldPercentage,
        uint256 newPercentage
    );
    event SenderPermissionAdded(address indexed user, address indexed sender);
    event SenderPermissionRemoved(address indexed user, address indexed sender);

    struct NestInfo {
        bool isStaked;
        address stakerAddress;
        mapping(address => uint256) pendingRewards;
    }

    address public constant BURN_ADDRESS =
        0x000000000000000000000000000000000000dEaD;

    uint256 public constant NEST_COUNT = 25;

    uint256 public NEST_PERCENTAGE = 100;

    uint256 public NESTS_STAKED = 0;

    address public immutable NEST_CONTRACT;
    address public immutable TREASURY;

    address public constant WAVAX_ADDRESS =
        0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7;

    address private _signerAddress = 0x07A6597abB94BD91783E992c4f469878f9544177;

    mapping(string => bool) private _usedNonces;

    mapping(address => bool) public SenderPermissions;

    mapping(address => uint256) public TokenBurnPercentage;

    mapping(address => uint256) public TokenTreasuryPercentage;

    mapping(address => uint256) public PendingTokenRewards;

    mapping(uint256 => NestInfo) public StakedNests;

    mapping(address => uint256) public StakedCountForAddress;

    mapping(address => bool) public CanRewarderMint;

    constructor(address nestContract, address treasury) {
        require(nestContract != address(0), "must be valid address");
        require(treasury != address(0), "must be valid address");

        NEST_CONTRACT = nestContract;
        TREASURY = treasury;
    }

    function receiveTokens(address tokenAddress, uint256 amount)
        external
        nonReentrant
    {
        require(tokenAddress != address(0), "INVALID_TOKEN_ADDRESS");
        require(SenderPermissions[msg.sender]);

        if (tokenAddress == WAVAX_ADDRESS) {
            IERC20 wavaxToken = IERC20(WAVAX_ADDRESS);
            wavaxToken.transfer(TREASURY, amount);
        } else {
            uint256 nestAmount = (amount * NEST_PERCENTAGE) / 10000;
            uint256 leftOverAmount = amount - nestAmount;

            distributeGameRewards(tokenAddress, leftOverAmount);
            distributeNestHolderTokens(tokenAddress, nestAmount);
        }
    }

    function transferTokensNoDistribution(address tokenAddress, uint256 amount)
        external
        nonReentrant
        onlyOwner
    {
        require(tokenAddress != address(0), "INVALID_TOKEN_ADDRESS");

        IERC20 tokenERC20Contract = IERC20(tokenAddress);

        tokenERC20Contract.transferFrom(msg.sender, address(this), amount);

        PendingTokenRewards[tokenAddress] += amount;
    }

    function addSender(address addressToAdd) public onlyOwner {
        require(addressToAdd != address(0), "INVALID_TOKEN_ADDRESS");
        require(addressToAdd != msg.sender);

        SenderPermissions[addressToAdd] = true;

        emit SenderPermissionAdded(msg.sender, addressToAdd);
    }

    function removeSender(address addressToRemove) public onlyOwner {
        require(addressToRemove != address(0), "INVALID_TOKEN_ADDRESS");
        require(addressToRemove != msg.sender);

        SenderPermissions[addressToRemove] = false;

        emit SenderPermissionRemoved(msg.sender, addressToRemove);
    }

    function setBurnPercentage(address tokenAddress, uint256 percentage)
        external
        onlyOwner
    {
        require(
            percentage <= 5000,
            "REWARD HANLDER: must be less than or equal to 50%"
        );
        require(tokenAddress != address(0), "INVALID_TOKEN_ADDRESS");

        uint256 current = TokenBurnPercentage[tokenAddress];
        TokenBurnPercentage[tokenAddress] = percentage;

        emit TokenBurnPercentageSet(
            msg.sender,
            tokenAddress,
            current,
            percentage
        );
    }

    function setTreasuryPercentage(address tokenAddress, uint256 percentage)
        external
        onlyOwner
    {
        require(
            percentage <= 2500,
            "REWARD HANLDER: must be less than or equal to 25%"
        );
        require(tokenAddress != address(0), "INVALID_TOKEN_ADDRESS");

        uint256 current = TokenTreasuryPercentage[tokenAddress];

        TokenTreasuryPercentage[tokenAddress] = percentage;

        emit TreasuryPercentageSet(msg.sender, current, percentage);
    }

    function setCanMint(address tokenAddress) external onlyOwner {
        require(tokenAddress != address(0), "INVALID_TOKEN_ADDRESS");

        CanRewarderMint[tokenAddress] = true;
    }

    function setCantMint(address tokenAddress) external onlyOwner {
        require(tokenAddress != address(0), "INVALID_TOKEN_ADDRESS");

        CanRewarderMint[tokenAddress] = false;
    }

    // function claimGameRewards( address tokenAddress,  )

    function distributeGameRewards(address tokenAddress, uint256 amount)
        internal
    {
        require(tokenAddress != address(0), "INVALID_TOKEN_ADDRESS");

        uint256 totalRewards = amount;

        IERC20 tokenERC20Contract = IERC20(tokenAddress);

        if (TokenBurnPercentage[tokenAddress] > 0) {
            uint256 burnAmount = (amount * TokenBurnPercentage[tokenAddress]) /
                10000;
            totalRewards -= burnAmount;
            tokenERC20Contract.transfer(BURN_ADDRESS, burnAmount);
        }

        if (TokenTreasuryPercentage[tokenAddress] > 0) {
            uint256 treasuryAmount = (amount *
                TokenTreasuryPercentage[tokenAddress]) / 10000;
            totalRewards -= treasuryAmount;
            tokenERC20Contract.transfer(TREASURY, treasuryAmount);
        }

        PendingTokenRewards[tokenAddress] += totalRewards;
    }

    function distributeNestHolderTokens(address tokenAddress, uint256 amount)
        internal
    {
        if (NESTS_STAKED > 0) {
            uint256 amountPerNest = amount / NESTS_STAKED;
            uint256 amountDistributed = 0;

            for (uint256 index = 0; index < NEST_COUNT; index++) {
                if (StakedNests[index + 1].isStaked) {
                    uint256 amountOnNest = StakedNests[index + 1]
                        .pendingRewards[tokenAddress];
                    StakedNests[index + 1].pendingRewards[tokenAddress] =
                        amountOnNest +
                        amountPerNest;
                    amountDistributed += amountPerNest;
                }
            }

            if (amountDistributed < amount) {
                distributeGameRewards(tokenAddress, amount - amountDistributed);
            }
        }
    }

    function claimNestTokens(address tokenAddress, uint256 tokenId)
        external
        nonReentrant
    {
        require(
            StakedNests[tokenId].isStaked,
            "REWARD HANLDER: nest must be staked to claim"
        );

        IERC721 nestContract = IERC721(NEST_CONTRACT);

        require(
            nestContract.ownerOf(tokenId) == msg.sender,
            "REWARD HANDLER: you must own this nft to claim rewards"
        );

        uint256 pendingRewards = StakedNests[tokenId].pendingRewards[
            tokenAddress
        ];

        if (pendingRewards > 0) {
            IERC20 tokenERC20Contract = IERC20(tokenAddress);
            tokenERC20Contract.transfer(msg.sender, pendingRewards);

            StakedNests[tokenId].pendingRewards[tokenAddress] = 0;

            emit NestClaimed(msg.sender, tokenId, tokenAddress, pendingRewards);
        }
    }

    function pendingNestTokens(address tokenAddress, uint256 tokenId)
        external
        view
        returns (uint256)
    {
        return StakedNests[tokenId].pendingRewards[tokenAddress];
    }

    function stakeNest(uint256 tokenId) external nonReentrant {
        IERC721 nestContract = IERC721(NEST_CONTRACT);
        nestContract.safeTransferFrom(msg.sender, address(this), tokenId);

        StakedNests[tokenId].stakerAddress = msg.sender;
        StakedNests[tokenId].isStaked = true;

        NESTS_STAKED++;

        StakedCountForAddress[msg.sender]++;

        emit NestStaked(msg.sender, tokenId);
    }

    function withdrawNest(uint256 tokenId) external nonReentrant {
        require(
            StakedNests[tokenId].stakerAddress == msg.sender,
            "REWARD HANDLER: You do not own this NFT"
        );

        StakedNests[tokenId].stakerAddress = address(0);
        StakedNests[tokenId].isStaked = false;

        IERC721 nestContract = IERC721(NEST_CONTRACT);
        nestContract.safeTransferFrom(address(this), msg.sender, tokenId);

        NESTS_STAKED--;

        StakedCountForAddress[msg.sender]--;

        emit NestWithdrawn(msg.sender, tokenId);
    }

    function stakedNestsForAddress(address requestAddress)
        external
        view
        returns (uint256[] memory)
    {
        uint256 stakedCount = StakedCountForAddress[requestAddress];

        uint256 currentIndex = 0;
        uint256[] memory stakedIds = new uint256[](stakedCount);

        for (uint256 index = 0; index < NEST_COUNT; index++) {
            if (
                StakedNests[index + 1].isStaked &&
                StakedNests[index + 1].stakerAddress == requestAddress
            ) {
                stakedIds[currentIndex] = index + 1;
                currentIndex++;
            }
        }

        return stakedIds;
    }

    function hasRewardsForToken(address tokenAddress)
        public
        view
        returns (bool)
    {
        require(tokenAddress != address(0), "INVALID_TOKEN_ADDRESS");

        return PendingTokenRewards[tokenAddress] > 0;
    }

    function claimTokens(
        address tokenAddress,
        uint256 amount,
        bytes memory signature,
        string memory nonce
    ) external nonReentrant {
        require(tokenAddress != address(0), "INVALID_TOKEN_ADDRESS");
        require(amount > 0, "BAD_AMOUNT");
        require(
            matchAddresSigner(
                hashTransaction(msg.sender, tokenAddress, amount, nonce),
                signature
            ),
            "DIRECT_CLAIM_DISALLOWED"
        );
        require(!_usedNonces[nonce], "HASH_USED");

        _usedNonces[nonce] = true;

        IERC20 tokenERC20Contract = IERC20(tokenAddress);

        if (amount <= PendingTokenRewards[tokenAddress]) {
            tokenERC20Contract.transfer(msg.sender, amount);
            PendingTokenRewards[tokenAddress] -= amount;
        }

        if (amount > PendingTokenRewards[tokenAddress]) {
            require(CanRewarderMint[tokenAddress], "REWARDER_CANNOT_MINT");

            uint256 amountPending = amount - PendingTokenRewards[tokenAddress];

            IERC20Mint tokenERC20MintingContract = IERC20Mint(tokenAddress);

            tokenERC20MintingContract.mint(msg.sender, amountPending);
            tokenERC20MintingContract.transfer(
                msg.sender,
                PendingTokenRewards[tokenAddress]
            );

            PendingTokenRewards[tokenAddress] = 0;
        }
    }

    // verify whether hash matches against tampering
    function hashTransaction(
        address sender,
        address tokenAddress,
        uint256 claimAmount,
        string memory nonce
    ) private pure returns (bytes32) {
        bytes32 hash = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                keccak256(
                    abi.encodePacked(sender, tokenAddress, claimAmount, nonce)
                )
            )
        );

        return hash;
    }

    // match serverside private key sign to set pub key
    function matchAddresSigner(bytes32 hash, bytes memory signature)
        private
        view
        returns (bool)
    {
        return _signerAddress == hash.recover(signature);
    }

    // change public key for relaunches so signatures get invalidated
    function setSignerAddress(address signerAddress) external onlyOwner {
        _signerAddress = signerAddress;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

import "../IERC721Receiver.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT
// DragonCryptoGaming - Legend of Aurum Draconis Contract Libaries

pragma solidity ^0.8.14;

/**
 * @dev Interfact
 */
interface IRewardReceiver {
    /**
     * @dev Emitted when `value` tokens are moved from in to the receiver contract
     *
     * Note that `value` may be zero.
     */
    event TokensReceived(address indexed tokenContract, uint256 indexed value);

    /**
     * @dev Tells the receiver contract that tokens have been moved to it.
     *
     * Emits a {TokensReceived} event.
     */
    function receiveTokens(address tokenContract, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
// DragonCryptoGaming - Legend of Aurum Draconis Contract Libaries

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

pragma solidity ^0.8.14;

/**
 * @dev Interfact
 */
interface IERC20Mint is IERC20 {
    function mint(address _to, uint256 _amount) external;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}