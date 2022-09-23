/**
 *Submitted for verification at testnet.snowtrace.io on 2022-04-03
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 < 0.9.0;

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

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    function hasRole(bytes32 role, address account) external view returns (bool);
    function getRoleAdmin(bytes32 role) external view returns (bytes32);
    function grantRole(bytes32 role, address account) external;
    function revokeRole(bytes32 role, address account) external;
    function renounceRole(bytes32 role, address account) external;
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
 * @dev Context variant with ERC2771 support.
 */
abstract contract ERC2771Context is Context {
    address private _trustedForwarder;
    
    constructor(address trustedForwarder) {
        _trustedForwarder = trustedForwarder;
    }

    function isTrustedForwarder(address forwarder) public view virtual returns (bool) {
        return forwarder == _trustedForwarder;
    }

    function _setTrustedForwarder(address trustedForwarder) internal virtual {
      _trustedForwarder = trustedForwarder;
    }

    function _msgSender() internal view virtual override returns (address sender) {
        if (isTrustedForwarder(msg.sender)) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return super._msgSender();
        }
    }

    function _msgData() internal view virtual override returns (bytes calldata) {
        if (isTrustedForwarder(msg.sender)) {
            return msg.data[:msg.data.length - 20];
        } else {
            return super._msgData();
        }
    }
}

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
abstract contract AccessControl is IAccessControl, ERC165 {
    struct RoleData {
        mapping (address => bool) members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

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
     * bearer except when using {_setupRole}.
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
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId
            || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
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
    function grantRole(bytes32 role, address account) public virtual override {
        require(hasRole(getRoleAdmin(role), msg.sender), "AccessControl: sender must be an admin to grant");

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
    function revokeRole(bytes32 role, address account) public virtual override {
        require(hasRole(getRoleAdmin(role), msg.sender), "AccessControl: sender must be an admin to revoke");

        _revokeRole(role, account);
    }

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
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == msg.sender, "AccessControl: can only renounce roles for self");

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
        emit RoleAdminChanged(role, getRoleAdmin(role), adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, msg.sender);
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, msg.sender);
        }
    }
}

abstract contract FINGZ {
    function totalSupply() public pure virtual returns (uint);
    function balanceOf(address tokenOwner) public pure virtual returns (uint balance);
    function allowance(address tokenOwner, address spender) public pure virtual returns (uint remaining);
    function transfer(address to, uint tokens) public virtual returns (bool success);
    function approve(address spender, uint tokens) public virtual returns (bool success);
    function transferFrom(address from, address to, uint tokens) public virtual returns (bool success);
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

/**
 * @dev FINGAZ contract for handling transactions on the Fingaz.app Platform.  
 * It facilitates buying FINGZ, booking sessions and organizing tournaments.
 */
contract FINGAZ is AccessControl, ERC2771Context {
    
    bytes32 ADMIN_ROLE = bytes32("ADMIN_ROLE");
    bytes32 CONFIRMER_ROLE = bytes32("CONFIRMER_ROLE");

    modifier onlyAdmin() {
        require(hasRole(ADMIN_ROLE, _msgSender()), "NOT_ADMIN");
        _;
    }

    modifier onlyConfirm() {
        require(hasRole(CONFIRMER_ROLE, msg.sender), "NOT_CONFIRMER");
        _;
    }

    enum booking_status { OPEN, SETTLED, REFUNDED }

    enum tournament_status { OPEN, ACTIVE, COMPLETED, CANCELLED }

    address fingz_address = 0x1759ed18Cb20825168C9B4897705C4Ab18eb1D0B; 
    FINGZ fingz = FINGZ(fingz_address);
    uint256 public fingzPerAvax = 1000;

    uint256 private _booking_count = 1;
    uint256 private _tournament_count = 1;

    struct Booking {
        address host;
        address player;
        uint256 amount;
        booking_status status;
        string meta;
    }

    struct Tournament {
        uint256 tournament_id;
        address host;
        tournament_status t_status;
        uint256 player_limit;
        uint256 player_count;
        uint256 entry_deadline;
        uint256 entry_fee;
        address [] players;
        address [] winners;
        string metadata;
    }

    mapping (uint256 => Tournament) public tournaments;
    mapping (uint256 => Booking) public bookings;


    event BuyFingz(address buyer, uint256 avax, uint256 fingzes);
    event FingzWithdrawn(uint256 indexed fingzes);
    event GameBooked(uint256 indexed book_id, uint256 indexed amount, address player);
    event GameSettled(uint256 indexed book_id);
    event GameRefunded(uint256 indexed book_id);
    event TournamentSetup(uint256 indexed tid);
    event PlayerJoined(uint256 indexed tid, uint256 indexed player_index);
    event TournamentConfirmed(uint256 indexed tid, address[] winners, uint256[] payouts);
    event TournamentStatusAdjusted(uint256 indexed tid, uint256 indexed status);

    constructor(address _trustedForwarder) ERC2771Context(_trustedForwarder) {
        _setupRole(CONFIRMER_ROLE, _trustedForwarder);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ADMIN_ROLE, msg.sender);
        _setupRole(CONFIRMER_ROLE, msg.sender);
    }

    function setTrustedForwarder(address trustedForwarder) external onlyAdmin {
      _setTrustedForwarder(trustedForwarder) ;
    }

    /**
        * @notice Allow users to buy FINGZ with AVAX
    */
    function buyFingz() external payable {
        require(msg.value > 0, "Send AVAX to buy some FINGZ");
        uint256 amountToBuy = msg.value * fingzPerAvax;
        uint256 contractBalance = fingz.balanceOf(address(this));
        require(contractBalance >= amountToBuy, "INSUFFICIENT_FUNDS");
        (bool sent) = fingz.transfer(_msgSender(), amountToBuy);
        require(sent, "Failed to transfer token to user");
        emit BuyFingz(msg.sender, msg.value, amountToBuy);
    }

    function withdrawAvax(uint256 amount) public  onlyAdmin{
        uint256 contractBalance = address(this).balance;
        require(contractBalance >= amount, "INSUFFICIENT_FUNDS");
        (bool sent,) = msg.sender.call{value: amount}("");
        require(sent, "WITHDRAW_FAILED");
    }

    function withdrawFingz(uint256 fingzes) external onlyAdmin{
        uint256 ownerBalance = fingz.balanceOf(address(this));
        require(ownerBalance > fingzes, "INSUFFICIENT_FUNDS");
        (bool sent) = fingz.transfer( _msgSender(), fingzes);
        require(sent, "WITHDRAW_FAILED");
    }

    function bookGame(address host, uint256 amount, string memory meta) external onlyConfirm{
        uint256 book_id = _booking_count;
        (bool sent) = fingz.transferFrom(_msgSender(), address(this), amount );
        require(sent, "PAYMENT_FAILED");
        _booking_count++;
        bookings[book_id] = Booking(host, _msgSender(), amount, booking_status.OPEN, meta);
        emit GameBooked(book_id, amount, _msgSender());
    }

    function settleGame(uint256 book_id) external onlyConfirm {
        require(bookings[book_id].status == booking_status.OPEN, "NOT_OPEN");
        require(bookings[book_id].player == _msgSender() || hasRole(ADMIN_ROLE, _msgSender()), "INVALID_ACTOR");
        bookings[book_id].status = booking_status.SETTLED;
        fingz.transfer( bookings[book_id].host, (bookings[book_id].amount) );
        emit GameSettled(book_id);
    }

    function refundGame(uint256 book_id) external onlyAdmin{
        require(bookings[book_id].status == booking_status.OPEN, "NOT_OPEN");
        bookings[book_id].status = booking_status.REFUNDED;
        emit GameRefunded(book_id);
    }

    function setupTournament
        ( uint256 player_limit, uint256 entry_deadline,  uint256 entry_fee, string memory metadata)  external onlyConfirm{
        uint256 tid = _tournament_count;
        _tournament_count++;
        Tournament storage t = tournaments[tid];
        t.player_limit = player_limit;
        t.host = _msgSender();
        t.t_status = tournament_status.OPEN;
        t.player_count = 0;
        t.entry_fee = entry_fee;
        t.entry_deadline = entry_deadline;
        t.metadata = metadata;
        t.players = new  address[](player_limit);
        emit TournamentSetup(tid);
    }

    function joinTournament(uint256 tid) external payable onlyConfirm{
        require(tournaments[tid].player_count < tournaments[tid].player_limit, "TOURNAMENT_FULL");
        (bool sent) = fingz.transferFrom(_msgSender(), address(this), tournaments[tid].entry_fee);
        require(sent, "PAYMENT_FAILED");
        tournaments[tid].players[tournaments[tid].player_count] = _msgSender();
        tournaments[tid].player_count++;
        emit PlayerJoined(tid, tournaments[tid].player_count);
    }

    function confirmTournament(uint256 tid, address[] memory winners, uint256[] memory payouts ) external  onlyAdmin{
        require(winners.length == payouts.length, "INCORRECT_DATA");
        for(uint i=0; i< winners.length; i++){
            fingz.transfer(winners[i], payouts[i]);
        }
        tournaments[tid].winners = winners;
        tournaments[tid].t_status = tournament_status.COMPLETED;
        emit TournamentConfirmed(tid, winners, payouts);
    }

    function adjustTournamentStatus(uint256 tid, uint256 status) external onlyAdmin{
        require(hasRole(ADMIN_ROLE, msg.sender), "NOT_ADMIN");
        require(status == 1 || status == 3, "INVALID_STATUS");
        tournaments[tid].t_status = tournament_status(status);
        emit TournamentStatusAdjusted(tid, status);
    }


}