/**
 *Submitted for verification at snowtrace.io on 2022-05-22
*/

// Sources flattened with hardhat v2.6.0 https://hardhat.org

// File @openzeppelin/contracts-upgradeable/utils/[email protected]

// SPDX-License-Identifier: MIT

// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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


// File @openzeppelin/contracts-upgradeable/proxy/utils/[email protected]

// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}


// File @openzeppelin/contracts-upgradeable/utils/[email protected]

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}


// File @openzeppelin/contracts-upgradeable/security/[email protected]

// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}


// File @openzeppelin/contracts-upgradeable/access/[email protected]

// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}


// File @openzeppelin/contracts-upgradeable/utils/[email protected]

// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
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


// File @openzeppelin/contracts-upgradeable/utils/introspection/[email protected]

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
interface IERC165Upgradeable {
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


// File @openzeppelin/contracts-upgradeable/utils/introspection/[email protected]

// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;


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
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}


// File @openzeppelin/contracts-upgradeable/access/[email protected]

// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;





/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal onlyInitializing {
    }

    function __AccessControl_init_unchained() internal onlyInitializing {
    }
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        StringsUpgradeable.toHexString(uint160(account), 20),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}


// File @openzeppelin/contracts-upgradeable/interfaces/[email protected]

// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822ProxiableUpgradeable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}


// File @openzeppelin/contracts-upgradeable/proxy/beacon/[email protected]

// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}


// File @openzeppelin/contracts-upgradeable/utils/[email protected]

// OpenZeppelin Contracts v4.4.1 (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlotUpgradeable {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly {
            r.slot := slot
        }
    }
}


// File @openzeppelin/contracts-upgradeable/proxy/ERC1967/[email protected]

// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;





/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable {
    function __ERC1967Upgrade_init() internal onlyInitializing {
    }

    function __ERC1967Upgrade_init_unchained() internal onlyInitializing {
    }
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822ProxiableUpgradeable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(AddressUpgradeable.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return AddressUpgradeable.verifyCallResult(success, returndata, "Address: low-level delegate call failed");
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}


// File @openzeppelin/contracts-upgradeable/proxy/utils/[email protected]

// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;



/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is Initializable, IERC1822ProxiableUpgradeable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal onlyInitializing {
    }

    function __UUPSUpgradeable_init_unchained() internal onlyInitializing {
    }
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Check that the execution is not being performed through a delegate call. This allows a function to be
     * callable on the implementing contract but not through proxies.
     */
    modifier notDelegated() {
        require(address(this) == __self, "UUPSUpgradeable: must not be called through delegatecall");
        _;
    }

    /**
     * @dev Implementation of the ERC1822 {proxiableUUID} function. This returns the storage slot used by the
     * implementation. It is used to validate that the this implementation remains valid after an upgrade.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy. This is guaranteed by the `notDelegated` modifier.
     */
    function proxiableUUID() external view virtual override notDelegated returns (bytes32) {
        return _IMPLEMENTATION_SLOT;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}


// File @openzeppelin/contracts-upgradeable/token/ERC721/[email protected]

// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}


// File @openzeppelin/contracts-upgradeable/token/ERC721/utils/[email protected]

// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;


/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721HolderUpgradeable is Initializable, IERC721ReceiverUpgradeable {
    function __ERC721Holder_init() internal onlyInitializing {
    }

    function __ERC721Holder_init_unchained() internal onlyInitializing {
    }
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}


// File @openzeppelin/contracts-upgradeable/security/[email protected]

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}


// File contracts/erc20/IPunkToken.sol

pragma solidity >=0.8.2 <0.9.0;


/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IPunkToken {
    function mint(address to, uint256 amount) external;

    function burn(address from, uint256 amount) external;
}


// File contracts/IBase.sol

pragma solidity >=0.8.2 <0.9.0;


/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IBase {
    struct TokenDetail {
        uint8 generation; // represents the generation of the token that was minted
        uint8 tokenType; // punk type that can be 0(KIND),1(alpha),2(UNKNOWN),3(ALIEN)
        uint8 alienType; // valid just for tokenType 3 that represents the alien
    }
}


// File contracts/erc721/IPunkNFT.sol

pragma solidity >=0.8.2 <0.9.0;


/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IPunkNFT is IBase {
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) external;

    function tokenDetails(uint256 tokenId) external returns (TokenDetail memory);

    function ownerOf(uint256 tokenId) external returns (address);
}


// File contracts/stake/PunkLaboratory.sol

pragma solidity >=0.8.2 <0.9.0;









contract PunkLaboratory is Initializable, PausableUpgradeable, AccessControlUpgradeable, UUPSUpgradeable, ERC721HolderUpgradeable, ReentrancyGuardUpgradeable, IBase {
    struct IndexDetails {
        uint16 index;
        uint16 tokenId;
        address owner;
        uint8 tokenType;
        uint8 alienType;
        uint256 tokensPerPower;
        uint256 stakeTime;
        uint8 generation;
    }

    event StatisticsUpdate(address owner, uint16 tokenId, uint8 generation, uint8 nftType, uint8 alienType, bool staked, bool directlyStaked);

    bytes32 public ADMIN_ROLE;
    bytes32 public PAUSER_ROLE;
    bytes32 public MINTER_ROLE;
    bytes32 public UPGRADER_ROLE;
    bytes32 public STAKE_OF;

    IPunkToken public token;
    IPunkNFT public nft;

    uint8 private kindPunkStolenChanceDecrease;
    uint8 public kindPunkGenerationRewardDecrease;
    uint8 private alphaPunkDividentPercentage;
    uint8 private alphaStealCollectiveChancePercentage;
    uint8 private alienKindPercentageRewardIncrease;
    uint8 private alienKindPercentageDividendsDecrease;
    uint8 private claimUnstakeRiskPercent;
    uint16 private alphaStealChancePercentage;
    uint16 private enlightenedPunkStealChancePercentage;
    uint16 private alienAlphaPercentageEnlightenedStealDecrease;
    // collective percentage chance to take all the $PUNKZ tokens from KIND Punks when they are unstaking them
    uint16 public alienAlphaCollectiveChanceToTakeFees;
    uint16 private alienEnlightenedIncreaseStealFees;
    // collective percentage chance to take the fees from ALPHA Punks when are unstaked
    uint16 public alienEnlightenedCollectiveChanceToTakeFees;
    uint16 private alienEnlightenedPercentageCollectIncrease;
    // number of seconds in one day
    uint32 private oneDay;
    uint256 private randomNumber;
    uint256 private enlightenedPunkRewardPerDay;
    uint256 private kindPunkRewardPerDay;
    uint256 public totalPowerStakedAlphaPunks;
    uint256 public tokensPerPowerAlphaPunks;
    uint256 public alphaPunksTokensToDistribute;
    uint256 public totalPowerStakedEnlightenedPunks;
    uint256 public tokensPerPowerEnlightenedPunks;
    uint256 public enlightenedPunksTokensToDistribute;

    // staking statistics: generation => nft type => staked count
    mapping(uint8 => mapping(uint8 => uint16)) public statistics;
    // staked token by type Kind/Alpha/Enlightened
    // used to reward randomly a holder with a new minted NFT
    mapping(uint8 => uint16[]) public stakedNFTsByType;
    // staked tokenIds to index of staked token list;
    mapping(uint16 => uint16) public stakedNFTsByTypeIndex;
    // number of staked aliens for an owner based on it's type;
    mapping(address => mapping(uint8 => uint16)) public aliensStakedByOwner;
    // stores the tokenDetails for an address based on it's type
    mapping(address => mapping(uint8 => mapping(uint16 => uint16))) public stakedNftDetails;
    // details of how tokenDetails can be accessed
    mapping(uint16 => IndexDetails) public stakedNftDetailsIndex;
    // number of staked NFTs by type used to get all the tokenDetails
    mapping(address => mapping(uint8 => uint16)) public stakedByOwner;

    function initialize(IPunkNFT nft_) public initializer {
        __Pausable_init();
        __AccessControl_init();
        __UUPSUpgradeable_init();

        ADMIN_ROLE = keccak256("ADMIN_ROLE");
        PAUSER_ROLE = keccak256("PAUSER_ROLE");
        MINTER_ROLE = keccak256("MINTER_ROLE");
        UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
        STAKE_OF = keccak256("STAKE_OF");

        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(ADMIN_ROLE, _msgSender());
        _grantRole(PAUSER_ROLE, _msgSender());
        _grantRole(MINTER_ROLE, _msgSender());
        _grantRole(UPGRADER_ROLE, _msgSender());
        _grantRole(STAKE_OF, address(nft_));

        // the PUNK NFT contract to be called in order to get NFT details and make NFT transfers when are unstaked
        nft = nft_;

        // number of seconds in one day
        oneDay = 86400;

        // ------   KIND PUNKS  ------
        // 300 $PUNKZ tokens received for one day of staking
        kindPunkRewardPerDay = 300 ether;
        // 1% percentage decrease chance of $PUNKZ tokens to get stolen when the KIND Punk are unstaked
        kindPunkStolenChanceDecrease = 100;
        // 10% $PUNKZ tokens reward decrease for each generation:
        // Gen 0 (0 decreaase)
        // Gen 1 (10 decrease)
        // Gen 2 (20 decrease)
        // Gen 3 (30 decrease)
        kindPunkGenerationRewardDecrease = 10;

        // ------   ALPHA PUNKS  ------
        // 20% dividends received from KIND Punks
        alphaPunkDividentPercentage = 200;
        // 15% chance for ALPHA Punk to steal the collected $PUNKZ tokens of KIND Punks when they unstake it
        alphaStealChancePercentage = 1500;
        // collective percentage chance increase of 0.01% for each ALPHA Alien staked to steal the collected $PUNKZ tokens from KIND Punks when they unstake it
        alphaStealCollectiveChancePercentage = 1;

        // ------   Enlightened PUNKS  ------
        // 500 $PUNKZ tokens received for one day of staking
        enlightenedPunkRewardPerDay = 500 ether;
        // 10% chance for Enlightened Punks to steal the $PUNKZ tokens from ALPHA Punks when they are unstaking the ALPHA Punks
        enlightenedPunkStealChancePercentage = 1000;

        // ------   ALIENS  ------
        // each staked KIND Alien will decrease with 0.5% the $PUNKZ tokens paid as dividents
        alienKindPercentageDividendsDecrease = 5;
        // each staked KIND Alien will boost the collected number of tokens with 5% for all staked KIND PUNKS
        alienKindPercentageRewardIncrease = 5;
        // 1% chance decrease of minted NFT to be stolen

        // 3% decrease chance for each ALPHA Alien staked to have the token stolen by Enlightened Punks
        alienAlphaPercentageEnlightenedStealDecrease = 300;

        // 5% token reward increase for each Enlightened Alien staked by the token owner
        alienEnlightenedPercentageCollectIncrease = 5;
        // 0,05% chance of stealing the $PUNKZ tokens from ALPHA Punks when they are unstaking it
        alienEnlightenedIncreaseStealFees = 5;

        // percentage chance to lose all the tokens when claiming or unstaking
        claimUnstakeRiskPercent = 35;
    }

    function stake(uint16[] memory tokenIds) public nonReentrant {
        require(tokenIds.length > 0, "No tokens to stake");
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint16 tokenId = tokenIds[i];

            require(_msgSender() == nft.ownerOf(tokenId), "not the owner of the token");

            TokenDetail memory tokenDetail = nft.tokenDetails(tokenId);

            _increaseStaked(tokenDetail);

            _stake(_msgSender(), tokenId, tokenDetail, true);

            emit StatisticsUpdate(_msgSender(), tokenId, tokenDetail.generation, tokenDetail.tokenType, tokenDetail.alienType, true, false);
        }
    }

    function stakeOf(
        address owner,
        uint16[] memory tokenIds,
        TokenDetail[] memory tokenDetails
    ) public nonReentrant onlyRole(STAKE_OF) {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            TokenDetail memory tokenDetail = tokenDetails[i];

            _increaseStaked(tokenDetail);

            _stake(owner, tokenIds[i], tokenDetail, false);

            emit StatisticsUpdate(owner, tokenIds[i], tokenDetail.generation, tokenDetail.tokenType, tokenDetail.alienType, true, true);
        }
    }

    function _stake(
        address from,
        uint16 tokenId,
        TokenDetail memory tokenDetail,
        bool transfer
    ) private {
        uint256 tokensPerPower;
        uint8 power = getPower(tokenDetail.generation);
        if (tokenDetail.tokenType == 1) {
            totalPowerStakedAlphaPunks += power;
            tokensPerPower = tokensPerPowerAlphaPunks;
        } else if (tokenDetail.tokenType == 2) {
            totalPowerStakedEnlightenedPunks += power;
            tokensPerPower = tokensPerPowerEnlightenedPunks;
        } else if (tokenDetail.tokenType == 3) {
            aliensStakedByOwner[from][tokenDetail.alienType]++;
            if (tokenDetail.alienType == 1) {
                alienAlphaCollectiveChanceToTakeFees += alphaStealCollectiveChancePercentage;
            } else if (tokenDetail.alienType == 2) {
                alienEnlightenedCollectiveChanceToTakeFees += alienEnlightenedIncreaseStealFees;
            }
        }

        stakedNFTsByTypeIndex[tokenId] = uint16(stakedNFTsByType[tokenDetail.tokenType].length);
        stakedNFTsByType[tokenDetail.tokenType].push(tokenId);

        uint16 length = stakedByOwner[from][tokenDetail.tokenType];
        stakedByOwner[from][tokenDetail.tokenType]++;
        stakedNftDetails[from][tokenDetail.tokenType][length] = tokenId;
        stakedNftDetailsIndex[tokenId] = IndexDetails(length, tokenId, from, tokenDetail.tokenType, tokenDetail.alienType, tokensPerPower, block.timestamp, tokenDetail.generation);

        if (transfer) {
            nft.safeTransferFrom(_msgSender(), address(this), tokenId, "");
        }
    }

    /**
     * @dev Claim $PUNKZ lifeforce from multiple NFTs
     * @param tokenIds are the ids to get $PUNKZ from
     * @param unstake flag in case the NFT has to be also unstacked
     */
    function claimMany(uint16[] memory tokenIds, bool unstake) public nonReentrant {
        uint256 totalTokensCollected;
        for (uint8 i = 0; i < tokenIds.length; i++) {
            uint16 tokenId = tokenIds[i];

            IndexDetails memory indexDetail = stakedNftDetailsIndex[tokenId];
            require(_msgSender() == indexDetail.owner, "not the owner of the nft");
            if (unstake && indexDetail.tokenType < 2) {
                require(block.timestamp - indexDetail.stakeTime > 2 * oneDay, "The nft can't be unstaked yet");
            }

            if (indexDetail.tokenType == 0) {
                // calculate how many tokens the KIND punk has collected in the period of time it was staked
                uint256 tokensCollected = (kindPunkRewardPerDay * (block.timestamp - indexDetail.stakeTime)) / oneDay;
                if (indexDetail.generation > 0) {
                    tokensCollected -= (tokensCollected * indexDetail.generation) / kindPunkGenerationRewardDecrease;
                }
                uint16 numberOfKindAliens = aliensStakedByOwner[_msgSender()][0];
                uint32 bonusPercent = (numberOfKindAliens > 20 ? 20 : numberOfKindAliens) * alienKindPercentageRewardIncrease;
                // add the additional token rewards for the staked kind aliens;
                tokensCollected += (tokensCollected * bonusPercent) / 100;

                // if the KIND punk is unstaked, there is a possibility that the ALPHA punks to take the collected $PUNKZ tokens
                if (unstake) {
                    // decrease chance of getting the tokens stolen based on how many KIND aliens are staked for this token owner
                    uint32 decreaseChance = numberOfKindAliens * kindPunkStolenChanceDecrease;
                    // ALPHA punks total chance of stealing the tokens from KIND punks when they unstake it
                    uint32 chanceToTakeTheTokens = alphaStealChancePercentage + alienAlphaCollectiveChanceToTakeFees;
                    // check if the $PUNKZ tokens will be stolen from KIND punks
                    if (chanceToTakeTheTokens > decreaseChance) {
                        randomNumber = getRandomNumber(randomNumber, 10000);
                        chanceToTakeTheTokens = chanceToTakeTheTokens - decreaseChance;
                        if (randomNumber < (chanceToTakeTheTokens > 35 ? 35 : chanceToTakeTheTokens)) {
                            // distribute the tokens to ALPHA punks
                            distributeTokensToAlphaPunks(tokensCollected);
                            // remove any $PUNKZ tokens from the KIND punk owner
                            tokensCollected = 0;
                        }
                    }
                }
                // check if the kind punk has any tokens to claim
                if (tokensCollected > 0) {
                    // pay dividends to ALPHA punks
                    // decrease the percentage of dividends based on the number of kind aliens that are staked by the token owner
                    uint16 percentDividends = alphaPunkDividentPercentage - numberOfKindAliens * alienKindPercentageDividendsDecrease;
                    // number of dividends to distribute to alpha punks
                    uint256 distributeTokens = (tokensCollected * percentDividends) / 1000;
                    // distribute the dividends to the alpha punks
                    distributeTokensToAlphaPunks(distributeTokens);
                    // subtract the dividends from the total collected tokens
                    tokensCollected -= distributeTokens;
                }
                // if the KIND punk is not unstaked then set the current time in order to have a minimum of 2 days before claim/unstake again
                if (!unstake) {
                    stakedNftDetailsIndex[tokenId].stakeTime = block.timestamp;
                }
                // if there are tokens send them to the token owner
                if (tokensCollected > 0) {
                    totalTokensCollected += tokensCollected;
                }
            } else if (indexDetail.tokenType == 1) {
                // power of each ALPHA Punk to get $PUNKZ tokens based on each generation
                uint8 power = getPower(indexDetail.generation);
                // number of tokens collected by alpha punk
                uint256 tokensCollected = (tokensPerPowerAlphaPunks - indexDetail.tokensPerPower) * power;
                // if the ALPHA Punk is unstaked then check if the Enlightened Punks will steal the tokens
                if (unstake) {
                    // number of ALPHA aliens staked by the token owner
                    uint16 numberOfAlphaAliens = aliensStakedByOwner[_msgSender()][1];
                    // decrease chance for $PUNKZ tokens to be taken by Enlightened punks
                    uint32 decreaseChanceForAlphaTokensToBeStolen = alienAlphaPercentageEnlightenedStealDecrease * numberOfAlphaAliens;
                    // total chance of enlightened punks to steal the tokens from alpha punks
                    uint32 enlightenedTotalStealChance = enlightenedPunkStealChancePercentage + alienEnlightenedCollectiveChanceToTakeFees;
                    if (enlightenedTotalStealChance > decreaseChanceForAlphaTokensToBeStolen) {
                        randomNumber = getRandomNumber(randomNumber, 10000);
                        enlightenedTotalStealChance = enlightenedTotalStealChance - decreaseChanceForAlphaTokensToBeStolen;
                        if (randomNumber < (enlightenedTotalStealChance < 35 ? 35 : enlightenedTotalStealChance)) {
                            // distribute $PUNKZ tokens to Enlightened punks
                            distributeTokensToEnlightenedPunks(tokensCollected);
                            // remove all the $PUNKZ tokens from the ALPHA punk
                            tokensCollected = 0;
                        }
                    }
                } else {
                    // as the ALPHA punk is not unstaked, set the time and tokens per power to be claimed after a minimum of 2 more days
                    stakedNftDetailsIndex[tokenId].stakeTime = block.timestamp;
                    stakedNftDetailsIndex[tokenId].tokensPerPower = tokensPerPowerAlphaPunks;
                }
                // if the ALPHA punk has collected some tokens send them to the token owner
                if (tokensCollected > 0) {
                    totalTokensCollected += tokensCollected;
                }
            } else if (indexDetail.tokenType == 2) {
                // collecting power for $PUNKZ tokens based on each generation
                uint8 power = getPower(indexDetail.generation);
                // number of $PUNKZ tokens collected by Enlightened punk
                uint256 tokensCollected = (enlightenedPunkRewardPerDay * (block.timestamp - indexDetail.stakeTime)) / oneDay;
                if (indexDetail.generation > 0) {
                    tokensCollected -= (tokensCollected * indexDetail.generation) / 10;
                }
                // number of enlightened aliens staked by the token owner
                uint16 numberOfEnlightenedAliens = aliensStakedByOwner[_msgSender()][2];
                uint32 bonusPercent = (numberOfEnlightenedAliens > 20 ? 20 : numberOfEnlightenedAliens) * alienEnlightenedPercentageCollectIncrease;
                // percent increase of token reward based on how many enlightened punks are staked by the token owner
                tokensCollected += (tokensCollected * bonusPercent) / 100;

                // add tokens collected from the alpha punks
                tokensCollected += (tokensPerPowerEnlightenedPunks - indexDetail.tokensPerPower) * power;

                // if the Enlightened punk is not unstaked then set the stakeTime and token per power to be claimed after a minimum of 2 more days
                if (!unstake) {
                    stakedNftDetailsIndex[tokenId].stakeTime = block.timestamp;
                    stakedNftDetailsIndex[tokenId].tokensPerPower = tokensPerPowerEnlightenedPunks;
                }

                // if there are any tokens then send them to the token owner
                if (tokensCollected > 0) {
                    totalTokensCollected += tokensCollected;
                }
            } else if (unstake && indexDetail.tokenType == 3) {
                // decrease the number of staked aliens for the token owner
                aliensStakedByOwner[_msgSender()][indexDetail.alienType]--;
                if (indexDetail.alienType == 1) {
                    // subtract percent of the collective chance of taking the $PUNKZ tokens when the KIND punks are unstaked
                    alienAlphaCollectiveChanceToTakeFees -= alphaStealCollectiveChancePercentage;
                } else if (indexDetail.alienType == 2) {
                    // subtract percent of the collective chance of taking the $PUNKZ tokens when the ALPHA punks are unstaked
                    alienEnlightenedCollectiveChanceToTakeFees -= alienEnlightenedIncreaseStealFees;
                }
            }

            if (unstake) {
                statistics[indexDetail.generation][indexDetail.tokenType + indexDetail.alienType]--;
                emit StatisticsUpdate(_msgSender(), tokenId, indexDetail.generation, indexDetail.tokenType, indexDetail.alienType, false, false);

                stakedByOwner[_msgSender()][indexDetail.tokenType]--;

                uint16 index = stakedNFTsByTypeIndex[tokenId];

                uint256 stakedLength = stakedNFTsByType[indexDetail.tokenType].length;

                if (stakedLength > 1 && index != stakedLength - 1) {
                    uint16 lastTokenId = stakedNFTsByType[indexDetail.tokenType][stakedLength - 1];
                    stakedNFTsByType[indexDetail.tokenType][index] = lastTokenId;
                    stakedNFTsByTypeIndex[lastTokenId] = index;

                    IndexDetails memory indexDetailLast = stakedNftDetailsIndex[lastTokenId];
                    stakedNftDetailsIndex[lastTokenId].index = indexDetail.index;

                    stakedNftDetails[_msgSender()][indexDetail.tokenType][indexDetail.index] = stakedNftDetails[_msgSender()][indexDetailLast.tokenType][indexDetailLast.index];
                    delete stakedNftDetails[_msgSender()][indexDetail.tokenType][indexDetailLast.index];
                }
                stakedNFTsByType[indexDetail.tokenType].pop();
                delete stakedNFTsByTypeIndex[tokenId];
                delete stakedNftDetailsIndex[tokenId];

                nft.safeTransferFrom(address(this), _msgSender(), tokenId, "");
            }
        }

        // if there are tokens send them to the token owner
        if (totalTokensCollected > 0) {
            token.mint(_msgSender(), totalTokensCollected);
        }
    }

    /**
     * @dev Increase stacked NFTs by type and generation
     */
    function _increaseStaked(TokenDetail memory tokenDetail) internal {
        statistics[tokenDetail.generation][tokenDetail.tokenType + tokenDetail.alienType]++;
    }

    /**
     * @dev Give $PUNKZ lifeforce for
     * @param numberOfTokens to be assinged to Alpha Punks
     */
    function distributeTokensToAlphaPunks(uint256 numberOfTokens) internal {
        if (totalPowerStakedAlphaPunks == 0) {
            alphaPunksTokensToDistribute += numberOfTokens;
            return;
        }
        tokensPerPowerAlphaPunks += (numberOfTokens + alphaPunksTokensToDistribute) / totalPowerStakedAlphaPunks;
        alphaPunksTokensToDistribute = 0;
    }

    /**
     * @dev Give $PUNKZ lifeforce for
     * @param numberOfTokens to be assinged to Alpha Punks
     */
    function distributeTokensToEnlightenedPunks(uint256 numberOfTokens) internal {
        if (totalPowerStakedEnlightenedPunks == 0) {
            enlightenedPunksTokensToDistribute += numberOfTokens;
            return;
        }
        tokensPerPowerEnlightenedPunks += (numberOfTokens + enlightenedPunksTokensToDistribute) / totalPowerStakedEnlightenedPunks;
        if (enlightenedPunksTokensToDistribute > 0) {
            enlightenedPunksTokensToDistribute = 0;
        }
    }

    /**
     * @dev get the power that Alpha And Enlightened have
     * @param generation that will compare the result power
     */
    function getPower(uint8 generation) internal pure returns (uint8) {
        if (generation > 3) {
            return 0;
        }
        return 10 - generation;
    }

    /**
     * @dev Return number of NFTs stacked for each generation
     */
    function getStatistics() public view returns (uint16[24] memory) {
        uint16[24] memory result;
        for (uint8 i = 0; i < 4; i++) {
            for (uint8 j = 0; j < 6; j++) {
                result[i * 6 + j] = statistics[i][j];
            }
        }
        return result;
    }

    /**
     * @dev Get the list of tokens for a specific owner
     * @param _owner address to retrieve token ids for
     */
    function getStakedNFT(address _owner) external view returns (IndexDetails[] memory) {
        uint16 tokenCount;
        
        for (uint8 i = 0; i < 4; i++) {
            tokenCount += stakedByOwner[_owner][i];
        }

        IndexDetails[] memory tokenDetails = new IndexDetails[](tokenCount);
        if (tokenCount == 0) {
            return tokenDetails;
        }
        uint16 index;
        for (uint8 i = 0; i < 4; i++) {
            for (uint16 j; j < stakedByOwner[_owner][i]; j++) {
                tokenDetails[index] = stakedNftDetailsIndex[stakedNftDetails[_owner][i][j]];
                index++;
            }
        }
        return tokenDetails;
    }

    /**
     * @dev Select from the current list of staked Punk holders a winner to receive a free NFT
     */
    function selectWinner() public onlyRole(STAKE_OF) returns (address) {
        uint16 stakedTotal = uint16(stakedNFTsByType[0].length + stakedNFTsByType[1].length + stakedNFTsByType[2].length);
        randomNumber = getRandomNumber(randomNumber, stakedTotal);

        uint8 tokenType;
        uint256 typeChosen = randomNumber % 100;
        if (typeChosen <= 10) {
            tokenType = stakedNFTsByType[0].length > 0 ? 0 : 4;
        } else if (typeChosen <= 45) {
            tokenType = stakedNFTsByType[1].length > 0 ? 1 : 4;
        } else {
            tokenType = stakedNFTsByType[2].length > 0 ? 2 : 4;
        }
        if (tokenType > 3) {
            return address(0);
        }

        uint16 chosenTokenId = stakedNFTsByType[tokenType][randomNumber % stakedNFTsByType[tokenType].length];

        return stakedNftDetailsIndex[chosenTokenId].owner;
    }

    /**
     * Set the ERC20 $PUNKZ token address
     * @param token_ address
     */
    function setToken(IPunkToken token_) public onlyRole(ADMIN_ROLE) {
        require(address(token) == address(0), "token already set");
        token = token_;
    }

    /**
     * @dev Get a random number
     * @param nonce to help the generate number to be unpredictible
     * @param n - 1 is the max number that a random number can have
     */
    function getRandomNumber(uint256 nonce, uint256 n) internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(nonce, block.coinbase, block.difficulty, block.timestamp))) % n;
    }

    /*
     * accepts AVAX sent with no txData
     */
    receive() external payable {}

    /*
     * refuses AVAX sent with txData that does not match any function signature in the contract
     */
    fallback() external {}

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    /**
     * @dev Setup a specific role to an address
     * @param role name to be assigned
     * @param to address to have the role assigned
     */
    function setupRole(string memory role, address to) external onlyRole(ADMIN_ROLE) {
        _setupRole(keccak256(bytes(role)), to);
    }

    /**
     * @dev Send an amount of value to a specific address
     * @param to_ address that will receive the value
     * @param value to be sent to the address
     */
    function sendValueTo(address to_, uint256 value) internal {
        address payable to = payable(to_);
        (bool success, ) = to.call{ value: value }("");
        require(success, "Function call error");
    }

    /**
     * @dev Withdraw remaining contract balance to owner
     */
    function withdrawContractBalance() public onlyRole(ADMIN_ROLE) {
        sendValueTo(_msgSender(), address(this).balance);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     */
    function _authorizeUpgrade(address newImplementation) internal override onlyRole(UPGRADER_ROLE) {}

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view override(AccessControlUpgradeable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}