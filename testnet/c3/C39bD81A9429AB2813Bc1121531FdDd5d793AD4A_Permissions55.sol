// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/ERC1155.sol)

pragma solidity ^0.8.0;

import "./IERC1155.sol";
import "./IERC1155Receiver.sol";
import "./extensions/IERC1155MetadataURI.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {
    using Address for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    constructor(string memory uri_) {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: address zero is not a valid owner");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
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
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not token owner nor approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not token owner nor approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
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
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC1155: setting approval status for self");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `ids` and `amounts` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    /**
     * @dev Hook that is called after any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/extensions/ERC1155Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC1155.sol";

/**
 * @dev Extension of {ERC1155} that allows token holders to destroy both their
 * own tokens and those that they have been approved to use.
 *
 * _Available since v3.1._
 */
abstract contract ERC1155Burnable is ERC1155 {
    function burn(
        address account,
        uint256 id,
        uint256 value
    ) public virtual {
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "ERC1155: caller is not token owner nor approved"
        );

        _burn(account, id, value);
    }

    function burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory values
    ) public virtual {
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "ERC1155: caller is not token owner nor approved"
        );

        _burnBatch(account, ids, values);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC1155/extensions/ERC1155Supply.sol)

pragma solidity ^0.8.0;

import "../ERC1155.sol";

/**
 * @dev Extension of ERC1155 that adds tracking of total supply per id.
 *
 * Useful for scenarios where Fungible and Non-fungible tokens have to be
 * clearly identified. Note: While a totalSupply of 1 might mean the
 * corresponding is an NFT, there is no guarantees that no other token with the
 * same id are not going to be minted.
 */
abstract contract ERC1155Supply is ERC1155 {
    mapping(uint256 => uint256) private _totalSupply;

    /**
     * @dev Total amount of tokens in with a given id.
     */
    function totalSupply(uint256 id) public view virtual returns (uint256) {
        return _totalSupply[id];
    }

    /**
     * @dev Indicates whether any token exist with a given id, or not.
     */
    function exists(uint256 id) public view virtual returns (bool) {
        return ERC1155Supply.totalSupply(id) > 0;
    }

    /**
     * @dev See {ERC1155-_beforeTokenTransfer}.
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

        if (from == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                _totalSupply[ids[i]] += amounts[i];
            }
        }

        if (to == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                uint256 id = ids[i];
                uint256 amount = amounts[i];
                uint256 supply = _totalSupply[id];
                require(supply >= amount, "ERC1155: burn amount exceeds totalSupply");
                unchecked {
                    _totalSupply[id] = supply - amount;
                }
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

import "../IERC1155.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

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

pragma solidity ^0.8.7;

import "./LibSet.bytes32.sol";

library LibMap_bytes32_string {
    using LibSet_bytes32 for LibSet_bytes32.set;

    struct map {
        LibSet_bytes32.set keyset;
        mapping(bytes32 => string) values;
    }

    function length(map storage _map) internal view returns (uint256) {
        return _map.keyset.length();
    }

    function tryGet(map storage _map, bytes32 _key) internal view returns (bool, string memory) {
        return (contains(_map, _key), _map.values[_key]);
    }

    function get(map storage _map, bytes32 _key) internal view returns (string memory) {
        require(contains(_map, _key), "LibMap_bytes32_string: key not found");
        return _map.values[_key];
    }

    function keyAt(map storage _map, uint256 _index) internal view returns (bytes32) {
        return _map.keyset.at(_index);
    }

    function at(map storage _map, uint256 _index) internal view returns (bytes32, string memory) {
        bytes32 key = keyAt(_map, _index);
        return (key, _map.values[key]);
    }

    function indexOf(map storage _map, bytes32 _key) internal view returns (uint256) {
        return _map.keyset.indexOf(_key);
    }

    function contains(map storage _map, bytes32 _key) internal view returns (bool) {
        return _map.keyset.contains(_key);
    }

    function keys(map storage _map) internal view returns (bytes32[] memory) {
        return _map.keyset.content();
    }

    function set(
        map storage _map,
        bytes32 _key,
        string memory _value
    ) internal returns (bool) {
        _map.keyset.add(_key);
        _map.values[_key] = _value;
        return true;
    }

    function del(map storage _map, bytes32 _key) internal returns (bool) {
        _map.keyset.remove(_key);
        delete _map.values[_key];
        return true;
    }

    function clear(map storage _map) internal returns (bool) {
        for (uint256 i = _map.keyset.length(); i > 0; --i) {
            delete _map.values[keyAt(_map, i)];
        }
        _map.keyset.clear();
        return true;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./LibSet.uint256.sol";

library LibMap_uint256_string {
    using LibSet_uint256 for LibSet_uint256.set;

    struct map {
        LibSet_uint256.set keyset;
        mapping(uint256 => string) values;
    }

    function length(map storage _map) internal view returns (uint256) {
        return _map.keyset.length();
    }

    function tryGet(map storage _map, uint256 _key) internal view returns (bool, string memory) {
        return (contains(_map, _key), _map.values[_key]);
    }

    function get(map storage _map, uint256 _key) internal view returns (string memory) {
        require(contains(_map, _key), "LibMap_uint256_string: key not found");
        return _map.values[_key];
    }

    function keyAt(map storage _map, uint256 _index) internal view returns (uint256) {
        return _map.keyset.at(_index);
    }

    function at(map storage _map, uint256 _index) internal view returns (uint256, string memory) {
        uint256 key = keyAt(_map, _index);
        return (key, _map.values[key]);
    }

    function indexOf(map storage _map, uint256 _key) internal view returns (uint256) {
        return _map.keyset.indexOf(_key);
    }

    function contains(map storage _map, uint256 _key) internal view returns (bool) {
        return _map.keyset.contains(_key);
    }

    function keys(map storage _map) internal view returns (uint256[] memory) {
        return _map.keyset.content();
    }

    function set(
        map storage _map,
        uint256 _key,
        string memory _value
    ) internal returns (bool) {
        _map.keyset.add(_key);
        _map.values[_key] = _value;
        return true;
    }

    function del(map storage _map, uint256 _key) internal returns (bool) {
        _map.keyset.remove(_key);
        delete _map.values[_key];
        return true;
    }

    function clear(map storage _map) internal returns (bool) {
        for (uint256 i = _map.keyset.length(); i > 0; --i) {
            delete _map.values[keyAt(_map, i)];
        }
        _map.keyset.clear();
        return true;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

library LibSet_address {
    struct set {
        address[] values;
        mapping(address => uint256) indexes;
    }

    function length(set storage _set) internal view returns (uint256) {
        return _set.values.length;
    }

    function at(set storage _set, uint256 _index) internal view returns (address) {
        return _set.values[_index - 1];
    }

    function indexOf(set storage _set, address _value) internal view returns (uint256) {
        return _set.indexes[_value];
    }

    function contains(set storage _set, address _value) internal view returns (bool) {
        return indexOf(_set, _value) != 0;
    }

    function content(set storage _set) internal view returns (address[] memory) {
        return _set.values;
    }

    function add(set storage _set, address _value) internal returns (bool) {
        if (contains(_set, _value)) {
            return false;
        }
        _set.values.push(_value);
        _set.indexes[_value] = _set.values.length;
        return true;
    }

    function remove(set storage _set, address _value) internal returns (bool) {
        if (!contains(_set, _value)) {
            return false;
        }

        uint256 i = indexOf(_set, _value);
        uint256 last = length(_set);

        if (i != last) {
            address swapValue = _set.values[last - 1];
            _set.values[i - 1] = swapValue;
            _set.indexes[swapValue] = i;
        }

        delete _set.indexes[_value];
        _set.values.pop();

        return true;
    }

    function clear(set storage _set) internal returns (bool) {
        for (uint256 i = _set.values.length; i > 0; --i) {
            delete _set.indexes[_set.values[i - 1]];
        }
        _set.values = new address[](0);
        return true;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

library LibSet_bytes32 {
    struct set {
        bytes32[] values;
        mapping(bytes32 => uint256) indexes;
    }

    function length(set storage _set) internal view returns (uint256) {
        return _set.values.length;
    }

    function at(set storage _set, uint256 _index) internal view returns (bytes32) {
        return _set.values[_index - 1];
    }

    function indexOf(set storage _set, bytes32 _value) internal view returns (uint256) {
        return _set.indexes[_value];
    }

    function contains(set storage _set, bytes32 _value) internal view returns (bool) {
        return indexOf(_set, _value) != 0;
    }

    function content(set storage _set) internal view returns (bytes32[] memory) {
        return _set.values;
    }

    function add(set storage _set, bytes32 _value) internal returns (bool) {
        if (contains(_set, _value)) {
            return false;
        }
        _set.values.push(_value);
        _set.indexes[_value] = _set.values.length;
        return true;
    }

    function remove(set storage _set, bytes32 _value) internal returns (bool) {
        if (!contains(_set, _value)) {
            return false;
        }

        uint256 i = indexOf(_set, _value);
        uint256 last = length(_set);

        if (i != last) {
            bytes32 swapValue = _set.values[last - 1];
            _set.values[i - 1] = swapValue;
            _set.indexes[swapValue] = i;
        }

        delete _set.indexes[_value];
        _set.values.pop();

        return true;
    }

    function clear(set storage _set) internal returns (bool) {
        for (uint256 i = _set.values.length; i > 0; --i) {
            delete _set.indexes[_set.values[i - 1]];
        }
        _set.values = new bytes32[](0);
        return true;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

library LibSet_uint256 {
    struct set {
        uint256[] values;
        mapping(uint256 => uint256) indexes;
    }

    function length(set storage _set) internal view returns (uint256) {
        return _set.values.length;
    }

    function at(set storage _set, uint256 _index) internal view returns (uint256) {
        return _set.values[_index - 1];
    }

    function indexOf(set storage _set, uint256 _value) internal view returns (uint256) {
        return _set.indexes[_value];
    }

    function contains(set storage _set, uint256 _value) internal view returns (bool) {
        return indexOf(_set, _value) != 0;
    }

    function content(set storage _set) internal view returns (uint256[] memory) {
        return _set.values;
    }

    function add(set storage _set, uint256 _value) internal returns (bool) {
        if (contains(_set, _value)) {
            return false;
        }
        _set.values.push(_value);
        _set.indexes[_value] = _set.values.length;
        return true;
    }

    function remove(set storage _set, uint256 _value) internal returns (bool) {
        if (!contains(_set, _value)) {
            return false;
        }

        uint256 i = indexOf(_set, _value);
        uint256 last = length(_set);

        if (i != last) {
            uint256 swapValue = _set.values[last - 1];
            _set.values[i - 1] = swapValue;
            _set.indexes[swapValue] = i;
        }

        delete _set.indexes[_value];
        _set.values.pop();

        return true;
    }

    function clear(set storage _set) internal returns (bool) {
        for (uint256 i = _set.values.length; i > 0; --i) {
            delete _set.indexes[_set.values[i - 1]];
        }
        _set.values = new uint256[](0);
        return true;
    }
}

// SPDX-License-Identifier: UNLICENSED
// (C) by TokenForge GmbH, Berlin
// Author: Hagen Hübel, [email protected]

pragma solidity >=0.8.7;

interface IPermissions55 {
    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
// (C) by TokenForge GmbH, Berlin
// Author: Hagen Hübel, [email protected]
pragma solidity ^0.8.7;

interface PermissionErrors {
    /**
     * @dev Revert with an error when an `account` is missing role #`roleId`
     */
    /// AccessControl: `account` is missing role #`roleId`
    /// @param account the account that requires the role.
    /// @param roleId the ID of the required role
    error ErrMissingRole(address account, uint256 roleId);

    /**
     * @dev Revert with an error when an Admin Role is required for this action
     */
    /// Admin Role is required for this action
    error ErrAdminRoleRequired();
}

// SPDX-License-Identifier: UNLICENSED
// (C) by TokenForge GmbH, Berlin
// Author: Hagen Hübel, [email protected]

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

abstract contract PermissionRoles is Context {
    // ***** Roles ********
    uint256 public constant TOKEN_ROLE_ADMIN = 1;
    uint256 public constant TOKEN_ROLE_DEPLOYER = 2;
    uint256 public constant TOKEN_ROLE_WHITELIST_ADMIN = 3;
    uint256 public constant TOKEN_ROLE_BLACKLIST_ADMIN = 4;
    uint256 public constant TOKEN_ROLE_MINTER = 5;
    uint256 public constant TOKEN_ROLE_TRANSFERER = 6;
    uint256 public constant TOKEN_ROLE_IS_WHITELISTED = 7;
    uint256 public constant TOKEN_ROLE_IS_BLACKLISTED = 8;

    /**
     * @dev Modifier to make a function callable only when a specific role is met
     */
    modifier onlyRole(uint256 roleTokenId) {
        _checkRole(roleTokenId, _msgSender());
        _;
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `roleTokenId`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(uint256 roleTokenId) internal view virtual {
        _checkRole(roleTokenId, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `roleTokenId`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(uint256 roleTokenId, address account) internal view virtual {
        if (!_hasRole(roleTokenId, account) && !_hasRole(TOKEN_ROLE_ADMIN, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(roleTokenId)
                    )
                )
            );
        }
    }

    function _hasRole(uint256 roleTokenId, address account) internal view virtual returns (bool);

    function hasRole(uint256 roleTokenId, address account) external view returns (bool) {
        return _hasRole(roleTokenId, account);
    }

    function hasRole(uint256 roleTokenId) external view returns (bool) {
        return _hasRole(roleTokenId, _msgSender());
    }
}

// SPDX-License-Identifier: UNLICENSED
// (C) by TokenForge GmbH, Berlin
// Author: Hagen Hübel, [email protected]

pragma solidity ^0.8.7;

import "../lib/solstruct/LibSet.uint256.sol";
import "../lib/solstruct/LibSet.address.sol";
import "../lib/solstruct/LibMap.bytes32.string.sol";
import "../lib/solstruct/LibMap.uint256.string.sol";

contract PermissionSet {
    using LibSet_uint256 for LibSet_uint256.set;
    using LibSet_address for LibSet_address.set;
    using LibMap_uint256_string for LibMap_uint256_string.map;

    event PermissionSetAdded(uint256 indexed id, string indexed name);
    event PermissionSetRemoved(uint256 indexed id);

    uint256 private _nextPermissionSetId = 1; // we start with 1 because 0 is default for Default Set
    LibMap_uint256_string.map private _permissionSets;

    constructor() {}

    function permissionSet(uint256 id) external view returns (string memory) {
        return _permissionSets.get(id);
    }

    function permissionSetIds() external view returns (uint256[] memory) {
        return _permissionSets.keys();
    }

    function permissionSets() external view returns (uint256[] memory, string[] memory) {
        uint256[] memory keys = _permissionSets.keys();
        string[] memory values = new string[](keys.length);

        for (uint256 i = 0; i < keys.length; i++) {
            values[i] = _permissionSets.get(i + 1);
        }
        return (keys, values);
    }

    function _addPermissionSet(uint256 id, string calldata name) internal virtual {
        require(!_permissionSets.contains(id), "PermissionSet already exists with that ID");
        _permissionSets.set(id, name);

        emit PermissionSetAdded(id, name);
    }

    function _removePermissionSet(uint256 id) internal virtual {
        require(_permissionSets.contains(id), "PermissionSet is not existing");
        _permissionSets.del(id);

        emit PermissionSetRemoved(id);
    }

    function _registerPermissionSet(string calldata name) internal virtual {
        uint256 id = _nextPermissionSetId;
        _addPermissionSet(id, name);
        unchecked {
            _nextPermissionSetId++;
        }
    }

    function nextPermissionSetId() external view returns (uint256) {
        return _nextPermissionSetId;
    }
}

// SPDX-License-Identifier: UNLICENSED
// (C) by TokenForge GmbH, Berlin
// Author: Hagen Hübel, [email protected]

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";

import "../lib/solstruct/LibSet.uint256.sol";
import "../lib/solstruct/LibSet.address.sol";
import "../lib/solstruct/LibMap.bytes32.string.sol";
import "../lib/solstruct/LibMap.uint256.string.sol";

import "./PermissionRoles.sol";
import "./IPermissions55.sol";
import "./PermissionSet.sol";
import "./PermissionErrors.sol";

contract Permissions55 is
    Context,
    ERC1155Burnable,
    ERC1155Supply,
    IPermissions55,
    PermissionRoles,
    PermissionSet,
    PermissionErrors
{
    using LibSet_uint256 for LibSet_uint256.set;
    using LibSet_address for LibSet_address.set;
    using LibMap_uint256_string for LibMap_uint256_string.map;

    // **** Error messages *****

    string public constant ERROR_TOKEN_ALREADY_EXISTS = "Permissions55: Token already minted";
    string public constant ERROR_TRANSFER_IS_NOT_ALLOWED = "Permissions55: Transfer is not allowed";
    string public constant ERROR_PERMISSION_DENIED = "Permissions55: not allowed due to missing permissions";

    // **** Token Members ****
    mapping(uint256 => LibSet_address.set) private _tokenMembers;
    mapping(uint256 => LibSet_uint256.set) private _customTokenSets;
    mapping(uint256 => LibSet_uint256.set) private _customTokenSetsReversed;

    mapping(uint256 => string) private _tokenUris;

    event CustomTokenSetAdded(uint256 indexed roleTokenId, uint256 indexed customTokenId);

    modifier onlyMintingRole(uint256 id) {
        (bool success, uint256 requiredPermission) = checkMintingPermissions(msg.sender, id);

        if (!success) {
            revert ErrMissingRole({account: msg.sender, roleId: id});
        }

        _;
    }

    modifier onlyAdmin() {
        if (!isAdmin(_msgSender())) {
            revert ErrAdminRoleRequired();
        }

        _;
    }

    // @TODO check base URI in Ctor.
    constructor(string memory adminTokenUri) ERC1155("ipfs://QmdQNC9ASzTCGwrRYqx4MfKWx1M7JAX4bq1x15nBM9Wc1Q") {
        _create(_msgSender(), TOKEN_ROLE_ADMIN, adminTokenUri);
    }

    function addPermissionSet(uint256 id, string calldata name) external onlyRole(TOKEN_ROLE_DEPLOYER) {
        _addPermissionSet(id, name);
    }

    function removePermissionSet(uint256 id) external onlyRole(TOKEN_ROLE_DEPLOYER) {
        _removePermissionSet(id);
    }

    function registerPermissionSet(string calldata name) external onlyRole(TOKEN_ROLE_DEPLOYER) {
        _registerPermissionSet(name);
    }

    function addCustomTokenSet(uint256 roleTokenId, uint256 customTokenId) external onlyRole(TOKEN_ROLE_DEPLOYER) {
        _customTokenSets[roleTokenId].add(customTokenId);
        _customTokenSetsReversed[customTokenId].add(roleTokenId);

        emit CustomTokenSetAdded(roleTokenId, customTokenId);
    }

    function balanceOf(address account, uint256 id)
        public
        view
        virtual
        override(ERC1155, IPermissions55)
        returns (uint256)
    {
        return super.balanceOf(account, id);
    }

    function uri(uint256 id) public view virtual override returns (string memory) {
        return _tokenUris[id];
    }

    function setTokenUri(uint256 id, string calldata tokenUri) external onlyAdmin {
        _tokenUris[id] = tokenUri;
    }

    function create(
        address to,
        uint256 id,
        string memory tokenUri
    ) public onlyMintingRole(id) {
        require(!exists(id), "The token has already been created yet");

        _create(to, id, tokenUri);
    }

    function _create(
        address to,
        uint256 id,
        string memory tokenUri
    ) internal {
        _tokenUris[id] = tokenUri;
        _mint(to, id);
    }

    function mint(address to, uint256 id) public onlyMintingRole(id) {
        require(exists(id), "The token has not been created yet");

        _mint(to, id);
    }

    function _mint(address to, uint256 id) internal {
        bytes memory data = new bytes(0);
        _mint(to, id, 1, data);
    }

    function ownersOf(uint256 tokenId) external view returns (address[] memory) {
        return _tokenMembers[tokenId].content();
    }

    function getTokenMember(uint256 tokenId, uint256 index) public view returns (address) {
        return _tokenMembers[tokenId].at(index);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getTokenMemberCount(uint256 tokenId) public view returns (uint256) {
        return _tokenMembers[tokenId].length();
    }

    function checkMintingPermissions(address account, uint256 tokenId)
        public
        view
        returns (bool success, uint256 requiredPermission)
    {
        if (isAdmin(account)) {
            return (true, 0);
        }

        // To be improved ...
        if (
            tokenId == TOKEN_ROLE_ADMIN ||
            tokenId == TOKEN_ROLE_DEPLOYER ||
            tokenId == TOKEN_ROLE_WHITELIST_ADMIN ||
            tokenId == TOKEN_ROLE_BLACKLIST_ADMIN
        ) {
            return (balanceOf(account, TOKEN_ROLE_ADMIN) > 0, TOKEN_ROLE_ADMIN);
        }

        if (tokenId == TOKEN_ROLE_IS_WHITELISTED) {
            return (_hasRole(TOKEN_ROLE_WHITELIST_ADMIN, account), TOKEN_ROLE_WHITELIST_ADMIN);
        }

        if (tokenId == TOKEN_ROLE_IS_BLACKLISTED) {
            return (balanceOf(account, TOKEN_ROLE_BLACKLIST_ADMIN) > 0, TOKEN_ROLE_BLACKLIST_ADMIN);
        }

        // check custom token set
        for (uint256 i = 0; i < _customTokenSetsReversed[tokenId].length(); i++) {
            uint256 customRoleId = _customTokenSetsReversed[tokenId].at(i + 1);
            if (balanceOf(account, customRoleId) > 0) {
                return (true, customRoleId);
            }
        }

        return (false, 0);
    }

    function isAdmin(address account) public view returns (bool) {
        return balanceOf(account, TOKEN_ROLE_ADMIN) > 0;
    }

    function isWhiteListAdmin(address account) public view returns (bool) {
        return isAdmin(account) || balanceOf(account, TOKEN_ROLE_WHITELIST_ADMIN) > 0;
    }

    function isBlackListAdmin(address account) public view returns (bool) {
        return isAdmin(account) || balanceOf(account, TOKEN_ROLE_BLACKLIST_ADMIN) > 0;
    }

    function isWhitelisted(address account) public view returns (bool) {
        return balanceOf(account, TOKEN_ROLE_IS_WHITELISTED) > 0;
    }

    function isBlacklisted(address account) public view returns (bool) {
        return balanceOf(account, TOKEN_ROLE_IS_BLACKLISTED) > 0;
    }

    function burnFor(address account, uint256 id) public onlyAdmin {
        _burn(account, id, balanceOf(account, id));
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override(ERC1155, ERC1155Supply) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

        if (from == address(0) && to != address(0)) {
            for (uint256 i = 0; i < ids.length; i++) {
                uint256 id = ids[i];

                if (balanceOf(to, id) > 0) {
                    revert(ERROR_TOKEN_ALREADY_EXISTS);
                }

                _tokenMembers[id].add(to);
            }

            // issuing is okay
            return;
        }
        if (from != address(0) && to == address(0)) {
            // burn is okay
            for (uint256 i = 0; i < ids.length; i++) {
                uint256 id = ids[i];

                _tokenMembers[id].remove(from);
            }

            return;
        }

        // transfer is not permitted.
        revert(ERROR_TRANSFER_IS_NOT_ALLOWED);
    }

    function _hasRole(uint256 roleTokenId, address account) internal view virtual override returns (bool) {
        if (balanceOf(account, roleTokenId) > 0) {
            return true;
        }

        // @TODO: Check this

        for (uint256 i = 0; i < _customTokenSets[roleTokenId].length(); i++) {
            if (balanceOf(account, _customTokenSets[roleTokenId].at(i + 1)) > 0) {
                return true;
            }
        }

        return false;
    }
}