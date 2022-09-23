/**
 *Submitted for verification at testnet.snowtrace.io on 2022-03-28
*/

/**
 *Submitted for verification at polygonscan.com on 2022-01-16
*/

/**
 *Submitted for verification at polygonscan.com on 2021-09-07
*/

/**
 *Submitted for verification at Etherscan.io on 2021-05-11
*/

// File: node_modules\@openzeppelin\contracts\utils\introspection\IERC165.sol



pragma solidity ^0.8.10;




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


interface ERC20 {
 
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function decimals() external returns (uint256);
}


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
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}


/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {

    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

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
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
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
        return functionCallWithValue(target, data, 0, errorMessage);
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
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
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

/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant alphabet = "0123456789abcdef";

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
            buffer[i] = alphabet[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

}

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}



/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping (uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping (address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping (uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping (address => mapping (address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC721).interfaceId
            || interfaceId == type(IERC721Metadata).interfaceId
            || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0
            ? string(abi.encodePacked(baseURI, tokenId.toString()))
            : '';
    }

    /**
     * @dev Base URI for computing {tokenURI}. Empty by default, can be overriden
     * in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(_msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(address to, uint256 tokenId, bytes memory _data) internal virtual {
        _mint(to, tokenId);
        require(_checkOnERC721Received(address(0), to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }


    
    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
     
     
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data)
        private returns (bool)
    {
        if (to.isContract()) {
                                    
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver(to).onERC721Received.selector;
                //GRAB = IERC721Receiver(to).onERC721Received.selector;
                //return retval == retval;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    // solhint-disable-next-line no-inline-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual { }
}

// File: node_modules\@openzeppelin\contracts\token\ERC721\ERC721.sol





/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {

    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// File: @openzeppelin\contracts\token\ERC721\extensions\ERC721Enumerable.sol




/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId
            || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

// File: @openzeppelin\contracts\token\ERC721\extensions\ERC721URIStorage.sol




/**
 * @dev ERC721 token with storage based token URI management.
 */
abstract contract ERC721URIStorage is ERC721 {
    using Strings for uint256;

    // Optional mapping for token URIs
    mapping (uint256 => string) private _tokenURIs;

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return super.tokenURI(tokenId);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }
}

// File: @openzeppelin\contracts\access\Ownable.sol



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
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


// File: contracts\ComicMinter.sol

// SPDX-License-Identifier: UNLICENSED

interface EngineEcosystemContract{
    function isEngineContract( address _address ) external returns (bool);
    function returnAddress ( string memory _contract ) external returns ( address );
}

interface RequestData {
    function getNext (  address _address) external  returns(uint256);
}



contract MicroMachineManufacturingPlant is ERC721, ERC721Enumerable, ERC721URIStorage, Ownable  {
    uint256 private _tokenIds=1200;
    bool public futuresEnabled;

    uint256 public warbotMintFee = 0;
   
    
    event WarBotsManufactured(address to, uint256 quantity);
    
   
    bytes4 ERC721_RECEIVED = 0x150b7a02;
    
    address public EmergencyAddress;
    address public EngineEcosystemContractAddress;
    EngineEcosystemContract public _enginecontract;
    uint256 public manufacturingPeriod;

    address public MicroMachineAddress;
    address public nanomachines;
    address public nanoReserve;
    address public RequestDataAddress;
    
    
    mapping ( uint256 => ManufacturingPlant ) public ManufacturingPlants;
    mapping ( address => uint256[] ) public userManufacturingPlants;
    mapping ( address =>uint256 ) public  userManufacturingPlantCount;
    uint256 public ManufacturingPlantCount=0;
    
    uint256 public globalwarbotproduction;
    uint256 public globalwarbotmanufacturingplants;
    
   
    
    string public  contractURIstorefront = '{ "name": "Micromachine Warbots", "description": "Rise of the Warbots is one of the greatest Play-to-Earn 3D NFT Augmented Reality (AR) PVP Blockchain gaming experiences where players unleash their customizable and upgradeable Warbots in the form of a tractor, walker or drone against one another pitting strategy and skill for great rewards! Every single item in the Warbot universe is also a collectible NFT.", "image": "https://riseofthewarbots.com", "external_link": "https://riseofthewarbots.com", "seller_fee_basis_points": 300, "fee_recipient": "0x42A1DE863683F3230568900bA23f86991D012f42"}'; 
    
    
     string public _tokenURI = '{"attributes":[{"trait_type":"type","value":"Amorphous"},{"trait_type":"level","value":0},{"trait_type":"Hitpoints","value":0},{"trait_type":"Attack","value":0},{"trait_type":"Defense","value":0},{"trait_type":"Speed","value":0},{"trait_type":"Movement","value":0},{"display_type":"boost_number","trait_type":"attack_bonus","value":0},{"display_type":"boost_number","trait_type":"Speed_Bonus","value":0},{"display_type":"number","trait_type":"generation","value":1}],"description":"Amorphous. Origin: 0,0,0 ","external_url":"http://riseofthewarbots.com","image":"https://gateway.pinata.cloud/ipfs/QmdCo4hCdDKcXWAtczVpVCheucjBZsiWEUdWpFBEJ9VKtP","name":"Amorphous Warbot." ,"seller_fee_basis_points": 500, "fee_recipient": "0x42A1DE863683F3230568900bA23f86991D012f42" }';
     
    mapping ( address => uint256[] ) public usersWarbots;  
  
    mapping ( uint256 => uint256 ) public warbotArrayPosition;
    mapping ( uint256 => uint256 ) public plantArrayPosition;
    
    
    uint256 public deposits=580;
    
    bool public coolDownPeriod;
    
    uint256 public royaltyPerc;
    mapping ( uint256 => address payable ) public royaltySplitContract;
    
    uint256 public upgradeCost= 1000 * 10 **18;
    uint8 public plantMaxLevel = 1 ;
     
   // bool public migrationActive;
    
    address payable public royaltyContract;
    
    mapping ( uint256 => mapping ( uint256 => mapping ( uint256 => uint256) ) ) public futuresTokenId;
    mapping ( uint256 => uint256 ) public plantProfile;
    
    bool public maxPeriodMinting = true;
     
    struct ManufacturingPlant {
       address _owner;
       string  _name;
       Location  _location;
       uint256 _level;
       uint256 _micromachinesstaked;
       uint256 _timeofexpiration;
       uint256 _timeunitslocked;
       uint256 _timeinitiated;
       uint256 _lastmanufacture;
       uint256 _warbotsmanufactured;
       uint256 _periodproductionrate;
       uint256 _periodsmanufactured;
       bool    _status;
    
    } 
    
    struct Location {
        int256 x;
        int256 y;
        int256 z;
    }
    
    mapping ( uint256 => WarbotCertificateOfManufacture ) public WarbotManufactureCertificates;
    mapping ( uint256 => mapping ( uint256 => bool )) public futuresSetup;
    
    struct WarbotCertificateOfManufacture {
        uint256 _plant;
        uint256 _plantlevel;
        uint256 _plantperiod;
        Location _location;
        uint256 _warbotposition;
    }
    
    
    constructor(address _EngineEcosystemContractAddress ) ERC721("MicroMachineWarBots", "MMWarBot") {
       
        //remove the uncomment on the following line 
        setEngineEcosystemContractAddress ( _EngineEcosystemContractAddress  ); 
        EmergencyAddress = msg.sender;
        manufacturingPeriod = 90 days;
       // migrationActive = true;
        plantMaxLevel = 1;
        royaltyContract = payable(msg.sender);
    }

    function setDepositsAndTokenId( uint256 _deposits, uint256 tokenid ) public onlyOwner{
        deposits = _deposits;
        _tokenIds = tokenid;
    }

    function setEngineEcosystemContractAddress ( address _address ) public onlyOwner {
        require ( _address != address(0) , "No Zero Address");
        EngineEcosystemContractAddress = _address;
        _enginecontract = EngineEcosystemContract ( EngineEcosystemContractAddress );
        
        MicroMachineAddress = _enginecontract.returnAddress ( "MMAC");
        nanoReserve =  _enginecontract.returnAddress ( "NanoReserve");
        nanomachines = _enginecontract.returnAddress ( "NMAC");
        RequestDataAddress = _enginecontract.returnAddress ( "RequestData");
       
    } 


    function emergencyWithdrawAnyToken( address _address) public OnlyEmergency {
        ERC20 _token = ERC20(_address);
        _token.transfer( msg.sender, _token.balanceOf (address(this)) );
    }

    function emergencyWithdrawBNB() public OnlyEmergency {
       payable(msg.sender).transfer( address(this).balance );
    }

   
    function setLocation ( uint256 _plant , Location memory _location) public onlyEngine {
        ManufacturingPlants[_plant]._location = _location;
    }
    
    function setPlantProfile ( uint256  _plant , uint256 _profile ) public onlyEngine {
        plantProfile[_plant] = _profile;
    }
    
    function setName ( uint256 _plant , string memory _name) public onlyEngine {
        ManufacturingPlants[_plant]._name = _name;
    }
    
    function setFuturesOnPlant ( uint256 _plant, uint256 _period , bool _switch ) public onlyEngine {
        futuresSetup[_plant][_period] = _switch;
    }
    
    function getPlantFuturesInfo ( uint256 _plant, uint256 _period ) public view returns ( address, bool, uint256 ) {
        address _owner = ManufacturingPlants[_plant]._owner;
        bool _futuresactive = futuresSetup[_plant][_period];
        uint256 _currentperiod = ManufacturingPlants[_plant]._periodsmanufactured + 1;
        return ( _owner,_futuresactive, _currentperiod );
    }
    
    function getManufacturerCertificate ( uint256 _tokenId ) public view returns ( uint256, uint256, uint256, Location memory, uint256 ){
        return ( WarbotManufactureCertificates[_tokenId]._plant,WarbotManufactureCertificates[_tokenId]._plantlevel, WarbotManufactureCertificates[_tokenId]._plantperiod, WarbotManufactureCertificates[_tokenId]._location, WarbotManufactureCertificates[_tokenId]._warbotposition );
    }
    
    function setManufacturingPeriod( uint256 _minutes ) public onlyEngine {
        maxPeriodMinting = false;
        manufacturingPeriod = _minutes * 1 minutes;  //43,200 = 30 days
        
    }
    
    function setWarbotMintFee( uint256 _mintfee ) public OnlyEmergency {
        warbotMintFee = _mintfee;
    }

    
    
   

    uint256 public RequestsCount;
    uint256 public RequestsProcessed;
    mapping ( uint256 => uint256 ) public Requests;


    
   function migrateMyNextPlant ( ) public payable {
       RequestData _request = RequestData(RequestDataAddress);
       uint256 _factory = _request.getNext(msg.sender);
       RequestsCount++;
       Requests[RequestsCount] = _factory;
    }  

   

    function migratePlant ( uint256 _plant, address _owner,  uint256 _micromachinesstaked, uint256 _timeofexpiration, uint256 _timeunitslocked, uint256 _timeinitiated, uint256 _lastmanufacture, uint256 _warbotsmanufactured, uint256 _periodproductionrate, uint256 _periodsmanufactured, bool _status  ) public onlyEngine {
          
          require (  ManufacturingPlants[_plant]._periodproductionrate == 0 , "already recorded" );
          require (  _periodproductionrate > 0 , "empty dataset" );
           ManufacturingPlants[_plant]._owner = _owner;
           ManufacturingPlants[_plant]._micromachinesstaked = _micromachinesstaked;
           ManufacturingPlants[_plant]._timeofexpiration = _timeofexpiration;
           ManufacturingPlants[_plant]._timeunitslocked = _timeunitslocked;
           ManufacturingPlants[_plant]._timeinitiated = _timeinitiated;
           ManufacturingPlants[_plant]._lastmanufacture = _lastmanufacture;
           ManufacturingPlants[_plant]._warbotsmanufactured = _warbotsmanufactured;
           ManufacturingPlants[_plant]._periodproductionrate = _periodproductionrate;
           ManufacturingPlants[_plant]._periodsmanufactured = _periodsmanufactured;
           ManufacturingPlants[_plant]._status = _status;
           
       
           globalwarbotproduction += _periodproductionrate;
           globalwarbotmanufacturingplants++;
           userManufacturingPlantCount[_owner]++;
           userManufacturingPlants[_owner].push(_plant);
           ManufacturingPlantCount++;
           
         
           plantArrayPosition[_plant] =  userManufacturingPlants[_owner].length - 1;
           RequestsProcessed++;
        
    }
    
    function toggleFutures() public onlyOwner {
        futuresEnabled = !futuresEnabled;
    }
  
    
    
    function setRoyaltyContract( uint256 _tokenId, address payable _address ) public onlyEngine {
        require ( _address != address(0) , "No Zero Address");
        royaltySplitContract[_tokenId] = _address;
    }
    
    function onERC721Received( address _operator, address _from, uint256 _tokenId, bytes memory _data) public view returns(bytes4){
        _operator; _from; _tokenId; _data; 
        return ERC721_RECEIVED;
    }
    
    function setTokenURI ( string memory _uri ) public onlyEngine {
        _tokenURI = _uri;
    }

    
    
    function setStoreJSON ( string memory _uri ) public onlyEngine {
        contractURIstorefront = _uri;
    }
    
    function setTokenURIEngine ( uint256 tokenId, string memory __tokenURI) public onlyEngine {
        _setTokenURI( tokenId, __tokenURI);
    }
    
    function catchReflect() public onlyEngine {
         ERC20 _token = ERC20(MicroMachineAddress);
        _token.transfer( msg.sender, balanceOf(address(this)) - deposits  );
    }
    
    function upgradePlant ( uint256 _plant ) public {
        require ( ManufacturingPlants[ _plant]._owner == msg.sender );
        require ( ManufacturingPlants[ _plant]._status == true );
        require ( ManufacturingPlants[_plant]._level  < plantMaxLevel, "already at max level");
        ManufacturingPlants[_plant]._level++;
        
        ERC20 _nano = ERC20(nanomachines);
        _nano.transferFrom ( msg.sender , address(this), calculatePlantUpgradeCost( _plant, ManufacturingPlants[_plant]._level ));
        _nano.transfer( nanoReserve, calculatePlantUpgradeCost( _plant, ManufacturingPlants[_plant]._level ));
    }
    
    function calculatePlantUpgradeCost( uint256 _plant, uint256 _level ) public view returns ( uint256 ){
        return ManufacturingPlants[ _plant ]._periodproductionrate * upgradeCost * ( _level * _level );
    }
    
    function setPlantMaxLevel( uint8 _maxlevel ) public onlyEngine {
        plantMaxLevel = _maxlevel;
    }
    
    function setUpgradeCost( uint256 _cost ) public onlyEngine {
        require ( _cost > 0 , "cost bust be greater than zero");
        upgradeCost = _cost * 10 ** 18;
    }
    
    function transferPlant ( address _owner , uint256 _plant, address _newowner ) public onlyEngine {
        require ( ManufacturingPlants[_plant]._owner == _owner, "Not rightful owner" );
        ManufacturingPlants[_plant]._owner = _newowner;
        
        userManufacturingPlantCount[_owner]--;
        uint256 pos = plantArrayPosition[_plant];
        
        userManufacturingPlants[_owner][pos] = userManufacturingPlants[msg.sender][userManufacturingPlants[msg.sender].length-1];
        plantArrayPosition[userManufacturingPlants[_owner].length-1] = pos;
        userManufacturingPlants[_owner].pop();
        
        userManufacturingPlants[_newowner].push(_plant);
        plantArrayPosition[_plant] =  userManufacturingPlants[_newowner].length - 1;
        userManufacturingPlantCount[_newowner]++;
    } 
    
   
    
    
     function maxPeriodMintingToggle() public OnlyEmergency {
        maxPeriodMinting = !maxPeriodMinting;
        
    }
    
    function contractURI() public view returns (string memory) {
        return contractURIstorefront;
    } 
    
    function isEngineContract( address _address ) public  returns ( bool) {
        EngineEcosystemContract _engine = EngineEcosystemContract ( EngineEcosystemContractAddress );
        return _engine.isEngineContract( _address );
    }
    
    mapping ( uint256 => uint256 ) public splitManufacturing;
    
    function manufacture( uint256 _plant, uint256 _option ) public payable {
       
        
        uint256 quantity = manufactureUnits ( ManufacturingPlants[_plant]._timeunitslocked, ManufacturingPlants[_plant]._micromachinesstaked );
        require ( _option > 0, "Zero not allowed" );
        require ( _option <= (quantity- splitManufacturing[_plant]), "Not enough bots available" );
        
        if ( splitManufacturing[_plant] == 0 )  ManufacturingPlants[ _plant]._periodsmanufactured++;
        uint256 _marker = splitManufacturing[_plant];
        splitManufacturing[_plant] += _option;
        

        require ( ManufacturingPlants[ _plant]._owner == msg.sender || isEngineContract(msg.sender) );
        require ( ManufacturingPlants[ _plant]._status == true );
        require ( block.timestamp > ManufacturingPlants[ _plant]._lastmanufacture + manufacturingPeriod, "manufacturing process not complete" );
        
        if ( maxPeriodMinting )require ( ManufacturingPlants[ _plant]._periodsmanufactured < ManufacturingPlants[ _plant]._timeunitslocked );
        if ( splitManufacturing[_plant] == quantity ){
            ManufacturingPlants[_plant]._lastmanufacture = block.timestamp;
           
            splitManufacturing[_plant] = 0;
       }
        if  ( futuresSetup[_plant][ManufacturingPlants[ _plant]._periodsmanufactured]) require (isEngineContract(msg.sender), "Plant Period is under Futures Contract" );
        if  ( !futuresSetup[_plant][ManufacturingPlants[ _plant]._periodsmanufactured]) require (ManufacturingPlants[ _plant]._owner == msg.sender, "Plant Period is not under Futures Contract" );
      
        require ( msg.value == _option * warbotMintFee, "Mint fee not met" );
        for ( uint i = 0; i < _option; i++ ) {
            _tokenIds++;
            uint256 newTokenId = _tokenIds;
            _safeMint( msg.sender , newTokenId);
            _setTokenURI(newTokenId, _tokenURI);
            usersWarbots[msg.sender].push(newTokenId);
            warbotArrayPosition[newTokenId] = usersWarbots[msg.sender].length -1;
            uint256 _warbotposition = i+1+_marker;
            if ( isEngineContract(msg.sender) && msg.sender != EmergencyAddress ) futuresTokenId[_plant][ManufacturingPlants[ _plant]._periodsmanufactured][_warbotposition] = newTokenId;
            
            WarbotManufactureCertificates[newTokenId]._plant = _plant;
            WarbotManufactureCertificates[newTokenId]._location = ManufacturingPlants[ _plant]._location;
            WarbotManufactureCertificates[newTokenId]._plantperiod = ManufacturingPlants[ _plant]._periodsmanufactured;
            WarbotManufactureCertificates[newTokenId]._plantlevel = ManufacturingPlants[_plant]._level;
            WarbotManufactureCertificates[newTokenId]._warbotposition = _warbotposition;
        }
        ManufacturingPlants[_plant]._warbotsmanufactured += _option;
        emit WarBotsManufactured(msg.sender, _option);
    }
    
    function returnFuturesTokenID ( uint256 _plant, uint256 _period, uint256 _position ) public view returns (uint256){
        
        return futuresTokenId[_plant][_period][_position];
            
    }
    
    function assembleWarbot (uint256 _plant, address _target ,  Location  memory _location, string memory __tokenURI) public onlyEngine returns(uint256) {
            _tokenIds++;
            uint256 newTokenId = _tokenIds;
            _safeMint( _target , newTokenId);
            _setTokenURI(newTokenId, __tokenURI);
            usersWarbots[_target].push(newTokenId);
            warbotArrayPosition[newTokenId] = usersWarbots[msg.sender].length -1;
           
            WarbotManufactureCertificates[newTokenId]._plant = _plant;
            WarbotManufactureCertificates[newTokenId]._location = _location;
            WarbotManufactureCertificates[newTokenId]._plantlevel = ManufacturingPlants[_plant]._level;
           
            return newTokenId;
    }
    
    uint256 public warbotRequestProcessed;
    function migrateWarbot (uint256 _warbotid, uint256 _plant, uint256 _period, uint256 _warbotposition, address _target ,  Location  memory _location, string memory __tokenURI) public onlyEngine returns(uint256) {
            
            warbotRequestProcessed++;
            
            uint256 newTokenId = _warbotid;
             
            _safeMint( _target , newTokenId);
            
            _setTokenURI(newTokenId, __tokenURI);
            
            usersWarbots[_target].push(newTokenId);
            warbotArrayPosition[newTokenId] = usersWarbots[_target].length -1;
           
            WarbotManufactureCertificates[newTokenId]._plant = _plant;
            WarbotManufactureCertificates[newTokenId]._location = _location;
            WarbotManufactureCertificates[newTokenId]._plantlevel = ManufacturingPlants[_plant]._level;
            WarbotManufactureCertificates[newTokenId]._plantperiod = _period;
            WarbotManufactureCertificates[newTokenId]._warbotposition = _warbotposition;
            
            return newTokenId;
    }
    
    function getUsersWarbots ( address  _user ) public view returns(uint256[] memory){
        return usersWarbots[_user];
    }
    
    function manufactureUnits( uint256  _timeunitslocked, uint256 _micromachinesstaked ) public pure returns(uint256){
        return _timeunitslocked * _micromachinesstaked/ 10**9;
    }
    
    function getUserManufacturingPlants(address _user ) public view returns(uint256[] memory) {
        return userManufacturingPlants[_user];
    }
    
    
    
    function stakeMicroMachines( uint256 _units, uint256 _timeperiod , Location memory _location ) public {
        require ( _units/10**9 > 0, "At least one Micromachine needs to be staked" );
        require ( manufactureUnits( _timeperiod, _units ) <= 12, "No more than 25 units of Manufacturing Capacity" );
        
        require ( _timeperiod > 0 && _timeperiod <=12 , "Between 1 and 12 periods only");
        
        deposits += _units;
        ERC20 _token = ERC20(MicroMachineAddress);
        _token.transferFrom( msg.sender, address(this) , _units );
        ManufacturingPlantCount++;
        ManufacturingPlants[ManufacturingPlantCount]._owner = msg.sender;
        ManufacturingPlants[ManufacturingPlantCount]._level = 1;
        ManufacturingPlants[ManufacturingPlantCount]._timeofexpiration =  block.timestamp + ( manufacturingPeriod * _timeperiod);
        ManufacturingPlants[ManufacturingPlantCount]._timeunitslocked =   _timeperiod;
        ManufacturingPlants[ManufacturingPlantCount]._micromachinesstaked = _units;
        ManufacturingPlants[ManufacturingPlantCount]._timeinitiated = block.timestamp;
        ManufacturingPlants[ManufacturingPlantCount]._lastmanufacture = block.timestamp;
        ManufacturingPlants[ManufacturingPlantCount]._warbotsmanufactured = 0;
        ManufacturingPlants[ManufacturingPlantCount]._location = _location;
        ManufacturingPlants[ManufacturingPlantCount]._periodproductionrate = manufactureUnits( _timeperiod, _units );
        ManufacturingPlants[ManufacturingPlantCount]._status = true;
       
        userManufacturingPlants[msg.sender].push(ManufacturingPlantCount);
        userManufacturingPlantCount[msg.sender]++;
        plantArrayPosition[ManufacturingPlantCount] =  userManufacturingPlants[msg.sender].length - 1;
        
        
        globalwarbotproduction += ManufacturingPlants[ManufacturingPlantCount]._periodproductionrate;
        globalwarbotmanufacturingplants++;
    }
  
    
     function isApprovedForAll(
        address _owner,
        address _operator
    ) public override view returns (bool isOperator) {
      // if OpenSea's ERC721 Proxy Address is detected, auto-return true
        if (_operator == address(0x58807baD0B376efc12F5AD86aAc70E78ed67deaE)) {
            return true;
        }
        
        // otherwise, use the default ERC721.isApprovedForAll()
        return ERC721.isApprovedForAll(_owner, _operator);
    }
    
    function royaltyInfo( uint256 _tokenId, uint256 _salePrice ) public  view returns ( address receiver, uint256 royaltyAmount ){
        
        receiver = royaltyContract;
        if ( royaltySplitContract[_tokenId]  != address(0) ) receiver = royaltySplitContract[_tokenId];
        royaltyAmount = _salePrice * royaltyPerc / 100;
        
    }
    
    function setRoyaltyPercent ( uint256 _perc ) public OnlyEmergency {
        royaltyPerc = _perc;
    }
    
    
    function unstakeMicroMachines ( uint256 _plant ) public  {
        
        require ( ManufacturingPlants[ _plant]._owner == msg.sender );
        require ( ManufacturingPlants[ _plant]._status == true );
        
        require ( block.timestamp > ManufacturingPlants[ _plant]._timeofexpiration  , "time committed not yet fulfilled" );
        require ( ManufacturingPlants[ _plant]._periodsmanufactured >= ManufacturingPlants[ _plant]._timeunitslocked );
       
        ManufacturingPlants[_plant]._lastmanufacture = block.timestamp;
        ManufacturingPlants[_plant]._status = false;
        
        globalwarbotproduction = globalwarbotproduction - ManufacturingPlants[_plant]._periodproductionrate;
        globalwarbotmanufacturingplants--;
         ERC20 _token = ERC20(MicroMachineAddress);
        _token.transfer( msg.sender, ManufacturingPlants[_plant]._micromachinesstaked );
        deposits -= ManufacturingPlants[_plant]._micromachinesstaked;
    } 
    
    function burn(uint256 tokenId) public onlyEngine {
       
        require(_isApprovedOrOwner(_msgSender(), tokenId), "caller is not owner nor approved");
        uint256 pos = warbotArrayPosition[tokenId];
       
        usersWarbots[msg.sender][warbotArrayPosition[tokenId]] = usersWarbots[msg.sender][ usersWarbots[msg.sender].length -1 ]  ;
        warbotArrayPosition[usersWarbots[msg.sender][ usersWarbots[msg.sender].length -1 ]] = pos;
        usersWarbots[msg.sender].pop();
        _burn(tokenId);
    }
    
   
    
    function transfer(address from, address to, uint256 tokenId) public {
       popWarbot ( from, to, tokenId );
       _transfer(from, to, tokenId);
    }   
    
    function transferFrom(address from, address to, uint256 tokenId) public  override {
       
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        popWarbot ( from, to, tokenId );
       _transfer(from, to, tokenId);
    }
    
    function popWarbot (address from, address to, uint256 tokenId ) internal {
       usersWarbots[to].push(tokenId);
       uint256 pos = warbotArrayPosition[tokenId];
       usersWarbots[from][warbotArrayPosition[tokenId]] = usersWarbots[from][ usersWarbots[from].length -1 ]  ;
       warbotArrayPosition[usersWarbots[from][ usersWarbots[from].length -1 ]] = pos;
       usersWarbots[from].pop();
       warbotArrayPosition[tokenId] = usersWarbots[to].length -1; 
    }
    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _baseURI() internal pure override returns (string memory) {
        return "";
    }
    
   
    
    modifier onlyEngine() {
       // EngineEcosystemContract _engine = EngineEcosystemContract ( EngineEcosystemContractAddress );
        require ( _enginecontract.isEngineContract(msg.sender), "Not an Engine Contract");
         _;
    }
    
    
    modifier OnlyEmergency() {
        require( msg.sender == EmergencyAddress, " Emergency Only");
        _;
    }
}