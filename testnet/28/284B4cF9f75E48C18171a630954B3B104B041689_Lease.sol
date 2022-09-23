/**
 *Submitted for verification at testnet.snowtrace.io on 2022-08-10
*/

// File: @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol



pragma solidity ^0.7.0;

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
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data)
    external returns (bytes4);
}

// File: @openzeppelin/contracts/token/ERC721/ERC721Holder.sol



pragma solidity ^0.7.0;


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
    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// File: @openzeppelin/contracts/utils/Address.sol



pragma solidity ^0.7.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// File: @openzeppelin/contracts/introspection/IERC165.sol



pragma solidity ^0.7.0;

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

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol



pragma solidity ^0.7.0;


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
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

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
    function transferFrom(address from, address to, uint256 tokenId) external;

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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

// File: src/base/ERC721Base.sol


pragma solidity 0.7.4;




contract ERC721Base is IERC721 {
    // -----------------------------------------
    // Libraries
    // -----------------------------------------

    using Address for address;

    // -----------------------------------------
    // CONSTANTS
    // -----------------------------------------

    bytes4 internal constant ERC721_RECEIVED = 0x150b7a02;
    bytes4 internal constant ERC165ID = 0x01ffc9a7;

    // -----------------------------------------
    // Storage
    // -----------------------------------------

    mapping(address => uint256) internal _numNFTPerAddress;
    mapping(uint256 => uint256) internal _owners;
    mapping(address => mapping(address => bool)) internal _operatorsForAll;
    mapping(uint256 => address) internal _operators;

    // -----------------------------------------
    // External Functions
    // -----------------------------------------

    function ownerOf(uint256 id) external view override returns (address owner) {
        owner = _ownerOf(id);
        require(owner != address(0), "TOKEN_NOT_EXISTS");
    }

    function balanceOf(address owner) external view override returns (uint256) {
        require(owner != address(0), "INVALID_ADDRESS_ZERO");
        return _numNFTPerAddress[owner];
    }

    function approve(address operator, uint256 id) external override {
        address owner = _ownerOf(id);
        require(owner != address(0), "TOKEN_NOT_EXISTS");
        require(owner == msg.sender, "NOT_OWNER");
        _approveFor(owner, operator, id);
    }

    function getApproved(uint256 id) external view override returns (address) {
        (address owner, bool operatorEnabled) = _ownerAndOperatorEnabledOf(id);
        require(owner != address(0), "TOKEN_NOT_EXISTS");
        if (operatorEnabled) {
            return _operators[id];
        } else {
            return address(0);
        }
    }

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) external override {
        _checkTransfer(from, to, id);
        _transferFrom(from, to, id);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes memory data
    ) public override {
        _checkTransfer(from, to, id);
        _transferFrom(from, to, id);
        if (to.isContract()) {
            require(_checkOnERC721Received(msg.sender, from, to, id, data), "ERC721_TRANSFER_REJECTED");
        }
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) external override {
        safeTransferFrom(from, to, id, "");
    }

    function supportsInterface(bytes4 id) public pure virtual override returns (bool) {
        return id == 0x01ffc9a7 || id == 0x80ac58cd;
    }

    function setApprovalForAll(address operator, bool approved) external override {
        _operatorsForAll[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function isApprovedForAll(address owner, address operator) external view override returns (bool isOperator) {
        return _operatorsForAll[owner][operator];
    }

    // -----------------------------------------
    // Internal Functions
    // -----------------------------------------

    function _ownerOf(uint256 id) internal view virtual returns (address) {
        uint256 data = _owners[id];
        return address(data);
    }

    function _ownerAndOperatorEnabledOf(uint256 id) internal view returns (address owner, bool operatorEnabled) {
        uint256 data = _owners[id];
        owner = address(data);
        operatorEnabled = (data / 2**255) == 1;
    }

    function _mint(address to, uint256 id) internal {
        _numNFTPerAddress[to]++;
        _owners[id] = uint256(to);
        emit Transfer(address(0), to, id);
    }

    function _transferFrom(
        address from,
        address to,
        uint256 id
    ) internal {
        _numNFTPerAddress[from]--;
        _numNFTPerAddress[to]++;
        _owners[id] = uint256(to);
        emit Transfer(from, to, id);
    }

    function _approveFor(
        address owner,
        address operator,
        uint256 id
    ) internal {
        if (operator == address(0)) {
            _owners[id] = _owners[id] & (2**255 - 1); // no need to resset the operator, it will be overriden next time
        } else {
            _owners[id] = _owners[id] | (2**255);
            _operators[id] = operator;
        }
        emit Approval(owner, operator, id);
    }

    function _burn(address owner, uint256 id) internal {
        _owners[id] = 0;
        _numNFTPerAddress[owner]--;
        emit Transfer(owner, address(0), id);
    }

    function _checkOnERC721Received(
        address operator,
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal returns (bool) {
        bytes4 retval = ERC721Holder(to).onERC721Received(operator, from, tokenId, _data);
        return (retval == ERC721_RECEIVED);
    }

    // ---------------------------------------
    // Internal Checks
    // ---------------------------------------

    function _checkTransfer(
        address from,
        address to,
        uint256 id
    ) internal view {
        (address owner, bool operatorEnabled) = _ownerAndOperatorEnabledOf(id);
        require(owner != address(0), "TOKEN_NOT_EXISTS");
        require(owner == from, "NOT_OWNER");
        require(to != address(0), "INVALID_ADDRESS_ZERO");
        require(to != address(this), "INVALID_ADDRESS_THIS");
        if (msg.sender != from) {
            require(
                _operatorsForAll[from][msg.sender] || (operatorEnabled && _operators[id] == msg.sender),
                "NOT_AUTHORIZED"
            );
        }
    }
}

// File: src/Lease.sol


pragma solidity 0.7.4;



contract Lease is ERC721Base {
    // -----------------------------------------
    // Storage
    // -----------------------------------------

    mapping(uint256 => address) internal _agreements;

    // -----------------------------------------
    // Events
    // -----------------------------------------

    event LeaseAgreement(
        IERC721 indexed tokenContract,
        uint256 indexed tokenID,
        address indexed user,
        address agreement
    );

    // -----------------------------------------
    // External functions
    // -----------------------------------------

    /// @notice Create a Lease between an owner and a user
    /// @param tokenContract ERC721 contract whose token is being leased
    /// @param tokenID id of the ERC721 token being leased
    /// @param user address of the user receiving right of use
    /// @param agreement Contract's address defining the rules of the lease. Only such contract is able to break the lease.
    /// if `agreement` is set to the zero address, no agreement are in place and both user and owner can break the lease at any time
    function create(
        IERC721 tokenContract,
        uint256 tokenID,
        address user,
        address agreement
    ) external {
        address tokenOwner = tokenContract.ownerOf(tokenID);
        require(msg.sender == tokenOwner || _operatorsForAll[tokenOwner][msg.sender], "NOT_AUTHORIZED");

        uint256 lease = _leaseIDOrRevert(tokenContract, tokenID);
        address leaseOwner = _ownerOf(lease);
        require(leaseOwner == address(0), "ALREADY_EXISTS");

        _mint(user, lease);
        _agreements[lease] = agreement;
        emit LeaseAgreement(tokenContract, tokenID, user, agreement);
    }

    /// @notice Destroy a specific lease. All the sub lease will also be destroyed
    /// @param tokenContract ERC721 contract whose token is being leased
    /// @param tokenID ERC721 tokenID being leased
    function destroy(IERC721 tokenContract, uint256 tokenID) external {
        uint256 lease = _leaseID(tokenContract, tokenID);
        address leaseOwner = _ownerOf(lease);
        require(leaseOwner != address(0), "NOT_EXISTS");
        address agreement = _agreements[lease];
        if (agreement != address(0)) {
            require(msg.sender == agreement, "NOT_AUTHORIZED_AGREEMENT");
        } else {
            address tokenOwner = tokenContract.ownerOf(tokenID);
            require(
                msg.sender == leaseOwner ||
                    _operatorsForAll[leaseOwner][msg.sender] ||
                    msg.sender == tokenOwner ||
                    _operatorsForAll[tokenOwner][msg.sender],
                "NOT_AUTHORIZED"
            );
        }
        emit LeaseAgreement(tokenContract, tokenID, address(0), address(0));
        _burn(leaseOwner, lease);

        // This recursively destroy all sub leases
        _destroySubLeases(lease);
    }

    /// @notice return the current agreement for a particular lease
    /// @param lease lease token id
    function getAgreement(uint256 lease) public view returns (address) {
        return _agreements[lease];
    }

    /// @notice return the current agreement for a particular tokenContract/tokenId pair
    /// @param tokenContract ERC721 contract whose token is being leased
    /// @param tokenID ERC721 tokenID being leased
    function getAgreement(IERC721 tokenContract, uint256 tokenID) external view returns (address) {
        return getAgreement(_leaseIDOrRevert(tokenContract, tokenID));
    }

    /// @notice return whether an particular token (tokenContract/tokenId pair) is being leased
    /// @param tokenContract ERC721 contract whose token is being leased
    /// @param tokenID ERC721 tokenID being leased
    function isLeased(IERC721 tokenContract, uint256 tokenID) external view returns (bool) {
        return _ownerOf(_leaseIDOrRevert(tokenContract, tokenID)) != address(0);
    }

    /// @notice return the current user of a particular token (the owner of the deepest lease)
    /// The user is basically the owner of the lease of a lease of a lease (max depth = 8)
    /// @param tokenContract ERC721 contract whose token is being leased
    /// @param tokenID ERC721 tokenID being leased
    function currentUser(IERC721 tokenContract, uint256 tokenID) external view returns (address) {
        uint256 lease = _leaseIDOrRevert(tokenContract, tokenID);
        address leaseOwner = _ownerOf(lease);
        if (leaseOwner != address(0)) {
            // lease for this tokenContract/tokenID paire exists => get the sub-most lease recursively
            return _submostLeaseOwner(lease, leaseOwner);
        } else {
            // there is no lease for this tokenContract/tokenID pair, the user is thus the owner
            return tokenContract.ownerOf(tokenID);
        }
    }

    /// @notice return the leaseId (tokenID of the lease) based on tokenContract/tokenID pair
    /// @param tokenContract ERC721 contract whose token is being leased
    /// @param tokenID ERC721 tokenID being leased
    function leaseID(IERC721 tokenContract, uint256 tokenID) external view returns (uint256) {
        return _leaseIDOrRevert(tokenContract, tokenID);
    }

    // -----------------------------------------
    // Internal Functions
    // -----------------------------------------

    function _leaseIDOrRevert(IERC721 tokenContract, uint256 tokenID) internal view returns (uint256 lease) {
        lease = _leaseID(tokenContract, tokenID);
        require(lease != 0, "INVALID_LEASE_MAX_DEPTH_8");
    }

    function _leaseID(IERC721 tokenContract, uint256 tokenID) internal view returns (uint256) {
        uint256 baseId = uint256(keccak256(abi.encodePacked(tokenContract, tokenID))) &
            0x1FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
        if (tokenContract == this) {
            uint256 depth = ((tokenID >> 253) + 1);
            if (depth >= 8) {
                return 0;
            }
            return baseId | (depth << 253);
        }
        return baseId;
    }

    function _submostLeaseOwner(uint256 lease, address lastLeaseOwner) internal view returns (address) {
        uint256 subLease = _leaseID(this, lease);
        address subLeaseOwner = _ownerOf(subLease);
        if (subLeaseOwner != address(0)) {
            return _submostLeaseOwner(subLease, subLeaseOwner);
        } else {
            return lastLeaseOwner;
        }
    }

    function _destroySubLeases(uint256 lease) internal {
        uint256 subLease = _leaseID(this, lease);
        address subLeaseOwner = _ownerOf(subLease);
        if (subLeaseOwner != address(0)) {
            emit LeaseAgreement(this, lease, address(0), address(0));
            _burn(subLeaseOwner, subLease);
            _destroySubLeases(subLease);
        }
    }
}