// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../ERC1238/extensions/ERC1238URIStorage.sol";

contract Badge is ERC1238, ERC1238URIStorage {
    address public owner;

    constructor(address owner_, string memory baseURI_) ERC1238(baseURI_) {
        owner = owner_;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Unauthorized: sender is not the owner");
        _;
    }

    function setOwner(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Invalid address for new owner");
        owner = newOwner;
    }

    function setBaseURI(string memory newBaseURI) external onlyOwner {
        _setBaseURI(newBaseURI);
    }

    function mint(
        address to,
        uint256 id,
        uint256 amount,
        string memory uri,
        bytes memory data
    ) external onlyOwner {
        _mintWithURI(to, id, amount, uri, data);
    }

    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        string[] memory uris,
        bytes memory data
    ) external onlyOwner {
        _mintBatchWithURI(to, ids, amounts, uris, data);
    }

    function burn(
        address from,
        uint256 id,
        uint256 amount,
        bool deleteURI
    ) external onlyOwner {
        if (deleteURI) {
            _burnAndDeleteURI(from, id, amount);
        } else {
            _burn(from, id, amount);
        }
    }

    function burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts,
        bool deleteURI
    ) external onlyOwner {
        if (deleteURI) {
            _burnBatchAndDeleteURIs(from, ids, amounts);
        } else {
            _burnBatch(from, ids, amounts);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC1238.sol";
import "./IERC1238URIStorage.sol";

/**
 * @dev Proposal for ERC1238 token with storage based token URI management.
 */
abstract contract ERC1238URIStorage is IERC1238URIStorage, ERC1238 {
    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    /**
     * @dev See {IERC1238URIStorage-tokenURI}.
     */
    function tokenURI(uint256 id) public view virtual override returns (string memory) {
        string memory _tokenURI = _tokenURIs[id];

        // Returns the token URI if there is a specific one set that overrides the base URI
        if (_isTokenURISet(id)) {
            return _tokenURI;
        }

        string memory base = _baseURI();

        return base;
    }

    /**
     * @dev Sets `_tokenURI` as the token URI for the tokens of type `id`.
     *
     */
    function _setTokenURI(uint256 id, string memory _tokenURI) internal virtual {
        _tokenURIs[id] = _tokenURI;

        emit URI(id, _tokenURI);
    }

    /**
     * @dev Deletes the tokenURI for the tokens of type `id`.
     *
     * Requirements:
     *  - A token URI must be set.
     *
     *  Possible improvement:
     *  - The URI can only be deleted if all tokens of type `id` have been burned.
     */
    function _deleteTokenURI(uint256 id) internal virtual {
        if (_isTokenURISet(id)) {
            delete _tokenURIs[id];
        }
    }

    /**
     * @dev Returns whether a tokenURI is set or not for a specific `id` token type.
     *
     */
    function _isTokenURISet(uint256 id) private view returns (bool) {
        return bytes(_tokenURIs[id]).length > 0;
    }

    /**
     * @dev Creates `amount` tokens of token type `id` and URI `uri`, and assigns them to `to`.
     *
     * Emits a {MintSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1238Receiver-onERC1238Mint} and return the
     * acceptance magic value.
     */
    function _mintWithURI(
        address to,
        uint256 id,
        uint256 amount,
        string memory uri,
        bytes memory data
    ) internal virtual {
        _mint(to, id, amount, data);
        _setTokenURI(id, uri);
    }

    /**
     * @dev [Batched] version of {_mintWithURI}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - `ids` and `uris` must have the same length.
     *
     * Emits a {MintBatch} event.
     */
    function _mintBatchWithURI(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        string[] memory uris,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1238: mint to the zero address");
        require(ids.length == amounts.length, "ERC1238: ids and amounts length mismatch");
        require(ids.length == uris.length, "ERC1238: ids and URIs length mismatch");

        address minter = msg.sender;

        for (uint256 i = 0; i < ids.length; i++) {
            _beforeMint(minter, to, ids[i], amounts[i], data);

            _setTokenURI(ids[i], uris[i]);

            _balances[ids[i]][to] += amounts[i];
        }

        emit MintBatch(minter, to, ids, amounts);

        _doSafeBatchMintAcceptanceCheck(minter, to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` of tokens with id `id` owned by `from` and deletes the associated URI.
     *
     * Requirements:
     *  - A token URI must be set.
     *  - All tokens of this type must have been burned.
     */
    function _burnAndDeleteURI(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        super._burn(from, id, amount);

        _deleteTokenURI(id);
    }

    /**
     * @dev [Batched] version of {_burnAndDeleteURI}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - For each id the balance of `from` must be at least the amount wished to be burnt.
     *
     * Emits a {BurnBatch} event.
     */
    function _burnBatchAndDeleteURIs(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(from != address(0), "ERC1238: burn from the zero address");
        require(ids.length == amounts.length, "ERC1238: ids and amounts length mismatch");

        address burner = msg.sender;

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            _beforeBurn(burner, from, id, amount);

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1238: burn amount exceeds balance");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }

            _deleteTokenURI(id);
        }

        emit BurnBatch(burner, from, ids, amounts);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC1238.sol";
import "./IERC1238Receiver.sol";
import "../utils/AddressMinimal.sol";

/**
 * @dev Implementation proposal for non-transferable (Badge) tokens
 * See https://github.com/ethereum/EIPs/issues/1238
 */
contract ERC1238 is IERC1238 {
    using Address for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) internal _balances;

    // TODO: Add a mapping returning the number of tokens in circulation by id?

    // Used as the URI by default for all token types by relying on ID substitution,
    // e.g. https://token-cdn-domain/{id}.json
    string private baseURI;

    /**
     * @dev Initializes the contract by setting a `baseURI`.
     * See {_setBaseURI}
     */
    constructor(string memory baseURI_) {
        _setBaseURI(baseURI_);
    }

    // TODO: Add support for ERC165
    // function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
    //     return
    //
    // }

    /**
     * @dev This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism as in EIP-1155:
     * https://eips.ethereum.org/EIPS/eip-1155#metadata
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return baseURI;
    }

    /**
     * @dev See {IERC1238-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1238: balance query for the zero address");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1238-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1238: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism as in EIP-1155
     * https://eips.ethereum.org/EIPS/eip-1155#metadata
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setBaseURI(string memory newBaseURI) internal virtual {
        baseURI = newBaseURI;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
     *
     * Emits a {MintSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1238Receiver-onERC1238Mint} and return the
     * acceptance magic value.
     *
     * Emits a {MintSingle} event.
     */
    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1238: mint to the zero address");

        address minter = msg.sender;

        _beforeMint(minter, to, id, amount, data);

        _balances[id][to] += amount;
        emit MintSingle(minter, to, id, amount);

        _doSafeMintAcceptanceCheck(minter, to, id, amount, data);
    }

    /**
     * @dev [Batched] version of {_mint}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1238Receiver-onERC1238BatchMint} and return the
     * acceptance magic value.
     *
     * Emits a {MintBatch} event.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1238: mint to the zero address");
        require(ids.length == amounts.length, "ERC1238: ids and amounts length mismatch");

        address minter = msg.sender;

        for (uint256 i = 0; i < ids.length; i++) {
            _beforeMint(minter, to, ids[i], amounts[i], data);

            _balances[ids[i]][to] += amounts[i];
        }

        emit MintBatch(minter, to, ids, amounts);

        _doSafeBatchMintAcceptanceCheck(minter, to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     *
     * Emits a {BurnSingle} event.
     */
    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC1238: burn from the zero address");

        address burner = msg.sender;

        _beforeBurn(burner, from, id, amount);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1238: burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit BurnSingle(burner, from, id, amount);
    }

    /**
     * @dev [Batched] version of {_burn}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     *
     * Emits a {BurnBatch} event.
     */
    function _burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(from != address(0), "ERC1238: burn from the zero address");
        require(ids.length == amounts.length, "ERC1238: ids and amounts length mismatch");

        address burner = msg.sender;

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            _beforeBurn(burner, from, id, amount);

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1238: burn amount exceeds balance");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
        }

        emit BurnBatch(burner, from, ids, amounts);
    }

    /**
     * @dev Hook that is called before an `amount` of tokens are minted.
     *
     * Calling conditions:
     * - `minter` and `to` cannot be the zero address
     *
     */
    function _beforeMint(
        address minter,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {}

    /**
     * @dev Hook that is called before an `amount` of tokens are burned.
     *
     * Calling conditions:
     * - `minter` and `to` cannot be the zero address
     *
     */
    function _beforeBurn(
        address burner,
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {}

    function _doSafeMintAcceptanceCheck(
        address minter,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1238Receiver(to).onERC1238Mint(minter, id, amount, data) returns (bytes4 response) {
                if (response != IERC1238Receiver.onERC1238Mint.selector) {
                    revert("ERC1238: ERC1238Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1238: transfer to non ERC1238Receiver implementer");
            }
        }
    }

    function _doSafeBatchMintAcceptanceCheck(
        address minter,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal {
        if (to.isContract()) {
            try IERC1238Receiver(to).onERC1238BatchMint(minter, ids, amounts, data) returns (bytes4 response) {
                if (response != IERC1238Receiver.onERC1238BatchMint.selector) {
                    revert("ERC1238: ERC1238Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1238: transfer to non ERC1238Receiver implementer");
            }
        }
    }

    // Could have that in a library instead of redeploying it every time?
    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC1238.sol";

/**
 * @dev Proposal of an interface for ERC1238 token with storage based token URI management.
 */
interface IERC1238URIStorage is IERC1238 {
    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     */
    event URI(uint256 indexed id, string value);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `id` token.
     */
    function tokenURI(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev Interface proposal for Badge tokens
 * See https://github.com/ethereum/EIPs/issues/1238
 */
interface IERC1238 {
    /**
     * @dev Emitted when `amount` tokens of token type `id` are minted to `to` by `minter`.
     */
    event MintSingle(address indexed minter, address indexed to, uint256 indexed id, uint256 amount);

    /**
     * @dev Equivalent to multiple {MintSingle} events, where `minter` and `to` is the same for all token types
     */
    event MintBatch(address indexed minter, address indexed to, uint256[] ids, uint256[] amounts);

    /**
     * @dev Emitted when `amount` tokens of token type `id` owned by `owner` are burned by `burner`.
     */
    event BurnSingle(address indexed burner, address indexed owner, uint256 indexed id, uint256 amount);

    /**
     * @dev Equivalent to multiple {BurnSingle} events, where `owner` and `burner` is the same for all token types
     */
    event BurnBatch(address indexed burner, address indexed owner, uint256[] ids, uint256[] amounts);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev [Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 *
 */
interface IERC1238Receiver {
    /**
     * @dev Handles the receipt of a single ERC1238 token type.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1238Mint(address,address,uint256,uint256,bytes)"))`
     *
     * @param minter The address which initiated minting (i.e. msg.sender)
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1238Mint(address,uint256,uint256,bytes)"))` if minting is allowed
     */
    function onERC1238Mint(
        address minter,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of multiple ERC1238 token types.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1238BatchMint(address,address,uint256[],uint256[],bytes)"))`
     *
     * @param minter The address which initiated minting (i.e. msg.sender)
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1238BatchMint(address,uint256[],uint256[],bytes)"))` if minting is allowed
     */
    function onERC1238BatchMint(
        address minter,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

       return account.code.length > 0;
    }

   
}