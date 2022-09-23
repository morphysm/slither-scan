/**
 *Submitted for verification at snowtrace.io on 2021-12-28
*/

// File contracts/interfaces/IzBOOFI_WithdrawalFeeCalculator.sol
// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

interface IzBOOFI_WithdrawalFeeCalculator {
    function withdrawalFee(uint256 amountZBoofiWithdrawn) external view returns(uint256);
}


// File @openzeppelin/contracts/token/ERC20/[email protected]

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
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


// File @openzeppelin/contracts/token/ERC20/extensions/[email protected]

pragma solidity ^0.8.0;

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}


// File @openzeppelin/contracts/utils/[email protected]

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


// File @openzeppelin/contracts/token/ERC20/[email protected]

pragma solidity ^0.8.0;



/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}


// File contracts/tokens/ERC20WithVoting.sol
pragma solidity ^0.8.6;

contract ERC20WithVoting is ERC20 {

    constructor(string memory name_, string memory symbol_) 
        ERC20(name_, symbol_)
    {
        DOMAIN_SEPARATOR = getDomainSeparator();
    }

    /// @notice A record of each accounts delegate
    mapping (address => address) internal _delegates;

    /// @notice A checkpoint for marking number of votes from a given block
    struct Checkpoint {
        uint32 fromBlock;
        uint256 votes;
    }

    /// @notice A record of votes checkpoints for each account, by index
    mapping (address => mapping (uint32 => Checkpoint)) public checkpoints;

    /// @notice The number of checkpoints for each account
    mapping (address => uint32) public numCheckpoints;

    /// @notice The EIP-712 typehash for the contract's domain
    bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");

    /// @notice The EIP-712 typehash for the delegation struct used by the contract
    bytes32 public constant DELEGATION_TYPEHASH = keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");

    /// @notice EIP-712 Domain separator
    bytes32 public immutable DOMAIN_SEPARATOR;

    /// @notice A record of states for signing / validating signatures
    mapping (address => uint) public nonces;

      /// @notice An event thats emitted when an account changes its delegate
    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);

    /// @notice An event thats emitted when a delegate account's vote balance changes
    event DelegateVotesChanged(address indexed delegate, uint previousBalance, uint newBalance);

    function getDelegationDigest(address delegatee, uint nonce, uint expiry) public view returns(bytes32) {
        bytes32 structHash = keccak256(
            abi.encode(
                DELEGATION_TYPEHASH,
                delegatee,
                nonce,
                expiry
            )
        );
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                structHash
            )
        );
        return digest;
    }

    /**
     * @notice Delegate votes from `msg.sender` to `delegatee`
     * @param delegator The address to get delegatee for
     */
    function delegates(address delegator)
        external
        view
        returns (address)
    {
        return _delegates[delegator];
    }

  /**
    * @notice Delegate votes from `msg.sender` to `delegatee`
    * @param delegatee The address to delegate votes to
    */
    function delegate(address delegatee) external {
        return _delegate(msg.sender, delegatee);
    }

    /**
     * @notice Delegates votes from signatory to `delegatee`
     * @param delegatee The address to delegate votes to
     * @param nonce The contract state required to match the signature
     * @param expiry The time at which to expire the signature
     * @param v The recovery byte of the signature
     * @param r Half of the ECDSA signature pair
     * @param s Half of the ECDSA signature pair
     */
    function delegateBySig(
        address delegatee,
        uint nonce,
        uint expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
        external
    {
        bytes32 structHash = keccak256(
            abi.encode(
                DELEGATION_TYPEHASH,
                delegatee,
                nonce,
                expiry
            )
        );

        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                structHash
            )
        );

        address signatory = ecrecover(digest, v, r, s);
        require(signatory != address(0), "ERC20WithVoting::delegateBySig: invalid signature");
        require(nonce == nonces[signatory]++, "ERC20WithVoting::delegateBySig: invalid nonce");
        require(block.timestamp <= expiry, "ERC20WithVoting::delegateBySig: signature expired");
        return _delegate(signatory, delegatee);
    }

    /**
     * @notice Gets the current votes balance for `account`
     * @param account The address to get votes balance
     * @return The number of current votes for `account`
     */
    function getCurrentVotes(address account)
        external
        view
        returns (uint256)
    {
        uint32 nCheckpoints = numCheckpoints[account];
        return nCheckpoints > 0 ? checkpoints[account][nCheckpoints - 1].votes : 0;
    }

    /**
     * @notice Determine the prior number of votes for an account as of a block number
     * @dev Block number must be a finalized block or else this function will revert to prevent misinformation.
     * @param account The address of the account to check
     * @param blockNumber The block number to get the vote balance at
     * @return The number of votes the account had as of the given block
     */
    function getPriorVotes(address account, uint blockNumber)
        external
        view
        returns (uint256)
    {
        require(blockNumber < block.number, "ERC20WithVoting::getPriorVotes: not yet determined");

        uint32 nCheckpoints = numCheckpoints[account];
        if (nCheckpoints == 0) {
            return 0;
        }

        // First check most recent balance
        if (checkpoints[account][nCheckpoints - 1].fromBlock <= blockNumber) {
            return checkpoints[account][nCheckpoints - 1].votes;
        }

        // Next check implicit zero balance
        if (checkpoints[account][0].fromBlock > blockNumber) {
            return 0;
        }

        uint32 lower = 0;
        uint32 upper = nCheckpoints - 1;
        while (upper > lower) {
            uint32 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
            Checkpoint memory cp = checkpoints[account][center];
            if (cp.fromBlock == blockNumber) {
                return cp.votes;
            } else if (cp.fromBlock < blockNumber) {
                lower = center;
            } else {
                upper = center - 1;
            }
        }
        return checkpoints[account][lower].votes;
    }

    function _delegate(address delegator, address delegatee)
        internal
    {
        address currentDelegate = _delegates[delegator];
        uint256 delegatorBalance = balanceOf(delegator); // balance of underlying token (not scaled);
        _delegates[delegator] = delegatee;

        emit DelegateChanged(delegator, currentDelegate, delegatee);

        _moveDelegates(currentDelegate, delegatee, delegatorBalance);
    }

    function _moveDelegates(address srcRep, address dstRep, uint256 amount) internal {
        if (srcRep != dstRep && amount > 0) {
            if (srcRep != address(0)) {
                // decrease old representative
                uint32 srcRepNum = numCheckpoints[srcRep];
                uint256 srcRepOld = srcRepNum > 0 ? checkpoints[srcRep][srcRepNum - 1].votes : 0;
                uint256 srcRepNew = (srcRepOld - amount);
                _writeCheckpoint(srcRep, srcRepNum, srcRepOld, srcRepNew);
            }

            if (dstRep != address(0)) {
                // increase new representative
                uint32 dstRepNum = numCheckpoints[dstRep];
                uint256 dstRepOld = dstRepNum > 0 ? checkpoints[dstRep][dstRepNum - 1].votes : 0;
                uint256 dstRepNew = (dstRepOld + amount);
                _writeCheckpoint(dstRep, dstRepNum, dstRepOld, dstRepNew);
            }
        }
    }

    function _writeCheckpoint(
        address delegatee,
        uint32 nCheckpoints,
        uint256 oldVotes,
        uint256 newVotes
    )
        internal
    {
        uint32 blockNumber = safe32(block.number, "ERC20WithVoting::_writeCheckpoint: block number exceeds 32 bits");

        if (nCheckpoints > 0 && checkpoints[delegatee][nCheckpoints - 1].fromBlock == blockNumber) {
            checkpoints[delegatee][nCheckpoints - 1].votes = newVotes;
        } else {
            checkpoints[delegatee][nCheckpoints] = Checkpoint(blockNumber, newVotes);
            numCheckpoints[delegatee] = nCheckpoints + 1;
        }

        emit DelegateVotesChanged(delegatee, oldVotes, newVotes);
    }

    function safe32(uint n, string memory errorMessage) internal pure returns (uint32) {
        require(n < 2**32, errorMessage);
        return uint32(n);
    }

    /**
     * @notice EIP-712 Domain separator
     * @return Separator
     */
    function getDomainSeparator() internal view returns (bytes32) {
        return keccak256(
            abi.encode(
                DOMAIN_TYPEHASH,
                keccak256(bytes(name())),
                _getChainId(),
                address(this)
            )
        );
    }

    function _getChainId() internal view returns (uint256) {
        return block.chainid;
    }

    function _mint(address account, uint256 amount) internal override {
        super._mint(account, amount);
        _moveDelegates(address(0), _delegates[account], amount);
    }

    function _burn(address account, uint256 amount) internal override {
        super._burn(account, amount);
        _moveDelegates(_delegates[account], address(0), amount);
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual override {
        super._transfer(sender, recipient, amount);
        _moveDelegates(_delegates[sender], _delegates[recipient], amount);
    }
}


// File contracts/tokens/ERC20WithVotingAndPermit.sol
pragma solidity ^0.8.6;

contract ERC20WithVotingAndPermit is ERC20WithVoting {
    bytes32 public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;

    mapping(address => uint) public permitNonces;

    constructor(string memory name_, string memory symbol_) 
        ERC20WithVoting(name_, symbol_)
    {
    }

    function getPermitDigest(address owner, address spender, uint256 nonce, uint256 value, uint256 deadline) public view returns(bytes32) {
        bytes32 encodeData = keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonce, deadline));
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                encodeData
            )
        );
        return digest;
    }

    /**
     * @notice Triggers an approval from owner to spender
     * @param owner The address to approve from
     * @param spender The address to be approved
     * @param value The number of tokens that are approved (2^256-1 means infinite)
     * @param deadline The time at which to expire the signature
     * @param v The recovery byte of the signature
     * @param r Half of the ECDSA signature pair
     * @param s Half of the ECDSA signature pair
     */
    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external {
        require(deadline >= block.timestamp, "permit::expired");

        bytes32 encodeData = keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, permitNonces[owner]++, deadline));
        _validateSignedData(owner, encodeData, v, r, s);

        _approve(owner, spender, value);
    }

    /**
     * @notice Recovers address from signed data and validates the signature
     * @param signer Address that signed the data
     * @param encodeData Data signed by the address
     * @param v The recovery byte of the signature
     * @param r Half of the ECDSA signature pair
     * @param s Half of the ECDSA signature pair
     */
    function _validateSignedData(address signer, bytes32 encodeData, uint8 v, bytes32 r, bytes32 s) internal view {
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                encodeData
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        // Explicitly disallow authorizations for address(0) as ecrecover returns address(0) on malformed messages
        require(recoveredAddress != address(0) && recoveredAddress == signer, "Arch::validateSig: invalid signature");
    }
}


// File @openzeppelin/contracts/utils/[email protected]

pragma solidity ^0.8.0;

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
        assembly {
            size := extcodesize(account)
        }
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


// File @openzeppelin/contracts/token/ERC20/utils/[email protected]

pragma solidity ^0.8.0;


/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}


// File @openzeppelin/contracts/access/[email protected]

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


// File contracts/tokens/ZombieBOOFI.sol
pragma solidity ^0.8.6;




// This contract handles swapping to and from zBOOFI, BooFinances's staking token.
contract ZombieBOOFI is ERC20WithVotingAndPermit("ZombieBOOFI", "zBOOFI"), Ownable {
    using SafeERC20 for IERC20;

    IERC20 public immutable boofi;

    uint256 public constant MAX_WITHDRAWAL_FEE = 2500;
    uint256 public constant MAX_BIPS = 10000;
    uint256 public constant SECONDS_PER_DAY = 86400;
    //zBOOFI per BOOFI, scaled up by 1e18. e.g. 100e18 is 100 zBOOFI per BOOFI
    uint256 public constant INIT_EXCHANGE_RATE = 100e18;

    // tracks total deposits over all time
    uint256 public totalDeposits;
    // tracks total withdrawals over all time
    uint256 public totalWithdrawals;
    // Tracks total BOOFI that has been redistributed via the withdrawalFee.
    uint256 public fundsRedistributedByWithdrawalFee;
    // contract that calculates withdrawal fee
    address public withdrawalFeeCalculator;
    //tracks whether withdrawal fee is enabled or not
    bool withdrawalFeeEnabled;

    //stored historic exchange rates, historic withdrawal + deposit amounts, and their timestamps, separated by ~24 hour intervals
    uint256 public numStoredDailyData;
    uint256[] public historicExchangeRates;
    uint256[] public historicDepositAmounts;
    uint256[] public historicWithdrawalAmounts;
    uint256[] public historicTimestamps;

    //for tracking of statistics in trailing 24 hour period
    uint256 public rollingStartTimestamp;
    uint256 public rollingStartBoofiBalance;
    uint256 public rollingStartTotalDeposits;
    uint256 public rollingStartTotalWithdrawals;

    //stores deposits to help tracking of profits
    mapping(address => uint256) public deposits;
    //stores withdrawals to help tracking of profits
    mapping(address => uint256) public withdrawals;
    //stores cumulative amounts transferred in and out of each address, as BOOFI
    mapping(address => uint256) public transfersIn;
    mapping(address => uint256) public transfersOut;    

    event Enter(address indexed account, uint256 amount);
    event Leave(address indexed account, uint256 amount, uint256 shares);
    event WithdrawalFeeEnabled();
    event WithdrawalFeeDisabled();
    event DailyUpdate(
        uint256 indexed dayNumber,
        uint256 indexed timestamp,
        uint256 amountBoofiReceived,
        uint256 amountBoofiDeposited,
        uint256 amountBoofiWithdrawn
    );

    constructor(IERC20 _boofi) {
        boofi = _boofi;
        //push first "day" of historical data
        numStoredDailyData = 1;
        historicExchangeRates.push(1e36 / INIT_EXCHANGE_RATE);
        historicDepositAmounts.push(0);
        historicWithdrawalAmounts.push(0);
        historicTimestamps.push(block.timestamp);
        rollingStartTimestamp = block.timestamp;
        emit DailyUpdate(1, block.timestamp, 0, 0, 0);
    }

    //PUBLIC VIEW FUNCTIONS
    function boofiBalance() public view returns(uint256) {
        return boofi.balanceOf(address(this));
    }

    //returns current exchange rate of zBOOFI to BOOFI -- i.e. BOOFI per zBOOFI -- scaled up by 1e18
    function currentExchangeRate() public view returns(uint256) {
        uint256 totalShares = totalSupply();
        if(totalShares == 0) {
            return (1e36 / INIT_EXCHANGE_RATE);
        }
        return (boofiBalance() * 1e18) / totalShares;
    }

    //returns expected amount of zBOOFI from BOOFI deposit
    function expectedZBOOFI(uint256 amountBoofi) public view returns(uint256) {
        return (amountBoofi * 1e18) /  currentExchangeRate();
    }

    //returns expected amount of BOOFI from zBOOFI withdrawal
    function expectedBOOFI(uint256 amountZBoofi) public view returns(uint256) {
        return ((amountZBoofi * currentExchangeRate()) * (MAX_BIPS - withdrawalFee(amountZBoofi))) / (MAX_BIPS * 1e18);
    }

    //returns user profits in BOOFI, or negative if they have losses (due to withdrawal fee)
    function userProfits(address account) public view returns(int256) {
        uint256 userDeposits = deposits[account];
        uint256 userWithdrawals = withdrawals[account];
        uint256 totalShares = totalSupply();
        uint256 shareValue = (balanceOf(account) * boofiBalance()) / totalShares;
        uint256 totalAssets = userWithdrawals + shareValue;
        return int256(int256(totalAssets) - int256(userDeposits));
    }

    //similar to 'userProfits', but counts transfersIn as deposits and transfers out as withdrawals
    function userProfitsIncludingTransfers(address account) public view returns(int256) {
        uint256 userDeposits = deposits[account] + transfersIn[account];
        uint256 userWithdrawals = withdrawals[account] + transfersOut[account];
        uint256 totalShares = totalSupply();
        uint256 shareValue = (balanceOf(account) * boofiBalance()) / totalShares;
        uint256 totalAssets = userWithdrawals + shareValue;
        return int256(int256(totalAssets) - int256(userDeposits));
    }

    //returns most recent stored exchange rate and the time at which it was stored
    function getLatestStoredExchangeRate() public view returns(uint256, uint256) {
        return (historicExchangeRates[numStoredDailyData - 1], historicTimestamps[numStoredDailyData - 1]);
    }

    //returns last amountDays of stored exchange rate datas
    function getExchangeRateHistory(uint256 amountDays) public view returns(uint256[] memory, uint256[] memory) {
        uint256 endIndex = numStoredDailyData - 1;
        uint256 startIndex = (amountDays > endIndex) ? 0 : (endIndex - amountDays + 1);
        uint256 length = endIndex - startIndex + 1;
        uint256[] memory exchangeRates = new uint256[](length);
        uint256[] memory timestamps = new uint256[](length);
        for(uint256 i = startIndex; i <= endIndex; i++) {
            exchangeRates[i - startIndex] = historicExchangeRates[i];
            timestamps[i - startIndex] = historicTimestamps[i];            
        }
        return (exchangeRates, timestamps);
    }

    //returns most recent stored daily deposit amount and the time at which it was stored
    function getLatestStoredDepositAmount() public view returns(uint256, uint256) {
        return (historicDepositAmounts[numStoredDailyData - 1], historicTimestamps[numStoredDailyData - 1]);
    }

    //returns last amountDays of stored daily deposit amount datas
    function getDepositAmountHistory(uint256 amountDays) public view returns(uint256[] memory, uint256[] memory) {
        uint256 endIndex = numStoredDailyData - 1;
        uint256 startIndex = (amountDays > endIndex) ? 0 : (endIndex - amountDays + 1);
        uint256 length = endIndex - startIndex + 1;
        uint256[] memory depositAmounts = new uint256[](length);
        uint256[] memory timestamps = new uint256[](length);
        for(uint256 i = startIndex; i <= endIndex; i++) {
            depositAmounts[i - startIndex] = historicDepositAmounts[i];
            timestamps[i - startIndex] = historicTimestamps[i];            
        }
        return (depositAmounts, timestamps);
    }

    //returns most recent stored daily withdrawal amount and the time at which it was stored
    function getLatestStoredWithdrawalAmount() public view returns(uint256, uint256) {
        return (historicWithdrawalAmounts[numStoredDailyData - 1], historicTimestamps[numStoredDailyData - 1]);
    }

    //returns last amountDays of stored daily withdrawal amount datas
    function getWithdrawalAmountHistory(uint256 amountDays) public view returns(uint256[] memory, uint256[] memory) {
        uint256 endIndex = numStoredDailyData - 1;
        uint256 startIndex = (amountDays > endIndex) ? 0 : (endIndex - amountDays + 1);
        uint256 length = endIndex - startIndex + 1;
        uint256[] memory withdrawalAmounts = new uint256[](length);
        uint256[] memory timestamps = new uint256[](length);
        for(uint256 i = startIndex; i <= endIndex; i++) {
            withdrawalAmounts[i - startIndex] = historicWithdrawalAmounts[i];
            timestamps[i - startIndex] = historicTimestamps[i];            
        }
        return (withdrawalAmounts, timestamps);
    }

    //tracks the amount of BOOFI the contract has received as rewards so far today
    function rewardsToday() public view returns(uint256) {
        // Gets the current BOOFI balance of the contract
        uint256 totalBoofi = boofiBalance();
        // gets deposits during the period
        uint256 depositsDuringPeriod = depositsToday();
        // gets withdrawals during the period
        uint256 withdrawalsDuringPeriod = withdrawalsToday();
        // net rewards received is (new boofi balance - old boofi balance) + (withdrawals - deposits)
        return ((totalBoofi + withdrawalsDuringPeriod) - (depositsDuringPeriod + rollingStartBoofiBalance));
    }

    //tracks the amount of BOOFI deposited to the contract so far today
    function depositsToday() public view returns(uint256) {
        uint256 depositsDuringPeriod = totalDeposits - rollingStartTotalDeposits;
        return depositsDuringPeriod;
    }

    //tracks the amount of BOOFI withdrawn from the contract so far today
    function withdrawalsToday() public view returns(uint256) {
        uint256 withdrawalsDuringPeriod = totalWithdrawals - rollingStartTotalWithdrawals;
        return withdrawalsDuringPeriod;
    }

    function timeSinceLastDailyUpdate() public view returns(uint256) {
        return (block.timestamp - rollingStartTimestamp);
    }

    //calculates and returns the current withdrawalFee, in BIPS
    function withdrawalFee() public view returns(uint256) {
        if (!withdrawalFeeEnabled) {
            return 0;
        } else {
            uint256 withdrawalFeeValue = IzBOOFI_WithdrawalFeeCalculator(withdrawalFeeCalculator).withdrawalFee(0);
            if (withdrawalFeeValue >= MAX_WITHDRAWAL_FEE) {
                return MAX_WITHDRAWAL_FEE;
            } else {
                return withdrawalFeeValue;
            }
        }
    }

    //calculates and returns the expected withdrawalFee, in BIPS, for a withdrawal of '_share' zBOOFI
    function withdrawalFee(uint256 _share) public view returns(uint256) {
        if (!withdrawalFeeEnabled) {
            return 0;
        } else {
            uint256 withdrawalFeeValue = IzBOOFI_WithdrawalFeeCalculator(withdrawalFeeCalculator).withdrawalFee(_share);
            if (withdrawalFeeValue >= MAX_WITHDRAWAL_FEE) {
                return MAX_WITHDRAWAL_FEE;
            } else {
                return withdrawalFeeValue;
            }
        }
    }

    //EXTERNAL FUNCTIONS
    // Enter the contract. Pay some BOOFI. Earn some shares.
    // Locks BOOFI and mints zBOOFI
    function enter(uint256 _amount) external {
        _enter(msg.sender, _amount);
    }

    //similar to 'enter', but sends new zBOOFI to address '_to'
    function enterFor(address _to, uint256 _amount) external {
        _enter(_to, _amount);
    }

    // Leave the vault. Claim back your BOOFI.
    // Unlocks the staked + gained BOOFI and redistributes zBOOFI.
    function leave(uint256 _share) external {
        _leave(msg.sender, _share);
    }

    //similar to 'leave', but sends the unlocked BOOFI to address '_to'
    function leaveTo(address _to, uint256 _share) external {
        _leave(_to, _share);
    }

    //similar to 'leave', but the transaction reverts if the dynamic withdrawal fee is above 'maxWithdrawalFee' when the transaction is mined
    function leaveWithMaxWithdrawalFee(uint256 _share, uint256 maxWithdrawalFee) external {
        require(maxWithdrawalFee <= MAX_WITHDRAWAL_FEE, "maxWithdrawalFee input too high. tx will always fail");
        require(withdrawalFee(_share) <= maxWithdrawalFee, "withdrawalFee slippage");
        _leave(msg.sender, _share);
    }

    //similar to 'leaveWithMaxWithdrawalFee', but sends the unlocked BOOFI to address '_to'
    function leaveToWithMaxWithdrawalFee(address _to, uint256 _share, uint256 maxWithdrawalFee) external {
        require(maxWithdrawalFee <= MAX_WITHDRAWAL_FEE, "maxWithdrawalFee input too high. tx will always fail");
        require(withdrawalFee(_share) <= maxWithdrawalFee, "withdrawalFee slippage");
        _leave(_to, _share);
    }

    //OWNER-ONLY FUNCTIONS
    function enableWithdrawalFee() external onlyOwner {
        require(!withdrawalFeeEnabled, "withdrawal fee already enabled");
        withdrawalFeeEnabled = true;
        emit WithdrawalFeeEnabled();
    }

    function disableWithdrawalFee() external onlyOwner {
        require(withdrawalFeeEnabled, "withdrawal fee already disabled");
        withdrawalFeeEnabled = false;
        emit WithdrawalFeeDisabled();
    }

    function setWithdrawalFeeCalculator(address _withdrawalFeeCalculator) external onlyOwner {
        withdrawalFeeCalculator = _withdrawalFeeCalculator;
    }

    //INTERNAL FUNCTIONS
    function _dailyUpdate() internal {
        if (timeSinceLastDailyUpdate() >= SECONDS_PER_DAY) {
            //repeat of rewardsReceived() logic
            // Gets the current BOOFI balance of the contract
            uint256 totalBoofi = boofiBalance();
            // gets deposits during the period
            uint256 depositsDuringPeriod = totalDeposits - rollingStartTotalDeposits;
            // gets withdrawals during the period
            uint256 withdrawalsDuringPeriod = totalWithdrawals - rollingStartTotalWithdrawals;
            // net rewards received is (new boofi balance - old boofi balance) + (withdrawals - deposits)
            uint256 rewardsReceivedDuringPeriod = ((totalBoofi + withdrawalsDuringPeriod) - (depositsDuringPeriod + rollingStartBoofiBalance));

            //store daily data
            //store exchange rate and timestamp
            historicExchangeRates.push(currentExchangeRate());
            historicDepositAmounts.push(depositsDuringPeriod);
            historicWithdrawalAmounts.push(withdrawalsDuringPeriod);
            historicTimestamps.push(block.timestamp);
            numStoredDailyData += 1;

            //emit event
            emit DailyUpdate(numStoredDailyData, block.timestamp, rewardsReceivedDuringPeriod, depositsDuringPeriod, withdrawalsDuringPeriod);

            //update rolling data
            rollingStartTimestamp = block.timestamp;
            rollingStartBoofiBalance = boofiBalance();
            rollingStartTotalDeposits = totalDeposits;
            rollingStartTotalWithdrawals = totalWithdrawals;
        }
    }

    //tracking for profits on transfers
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal override {
        // Gets the amount of zBOOFI in existence
        uint256 totalShares = totalSupply();
        // Gets the current BOOFI balance of the contract
        uint256 totalBoofi = boofiBalance();
        uint256 boofiValueOfShares = (amount * totalBoofi) / totalShares;
        // take part of profit tracking
        transfersIn[recipient] += boofiValueOfShares;
        transfersOut[sender] += boofiValueOfShares;
        //perform the internal transfer
        super._transfer(sender, recipient, amount);
    }

    function _enter(address recipient, uint256 _amount) internal {
        // Gets the amount of BOOFI locked in the contract
        uint256 totalBoofi = boofiBalance();
        // Gets the amount of zBOOFI in existence
        uint256 totalShares = totalSupply();
        // If no zBOOFI exists, mint it according to the initial exchange rate
        if (totalShares == 0 || totalBoofi == 0) {
            _mint(recipient, (_amount * (INIT_EXCHANGE_RATE) / 1e18));
        }
        // Calculate and mint the amount of zBOOFI the BOOFI is worth.
        // The ratio will change over time, as zBOOFI is burned/minted and BOOFI
        // deposited + gained from fees / withdrawn.
        else {
            uint256 what = (_amount * totalShares) / totalBoofi;
            _mint(recipient, what);
        }
        //track deposited BOOFI
        deposits[recipient] = deposits[recipient] + _amount;
        totalDeposits += _amount;
        // Lock the BOOFI in the contract
        boofi.safeTransferFrom(msg.sender, address(this), _amount);

        _dailyUpdate();

        emit Enter(recipient, _amount);
    }

    function _leave(address recipient, uint256 _share) internal {
        // Gets the amount of zBOOFI in existence
        uint256 totalShares = totalSupply();
        // Gets the BOOFI balance of the contract
        uint256 totalBoofi = boofiBalance();  
        // Calculates the amount of BOOFI the zBOOFI is worth      
        uint256 what = (_share * totalBoofi) / totalShares;
        //burn zBOOFI
        _burn(msg.sender, _share);
        //calculate and track tax
        uint256 tax = (what * withdrawalFee(_share)) / MAX_BIPS;
        uint256 toSend = what - tax;
        fundsRedistributedByWithdrawalFee += tax;
        //track withdrawn BOOFI
        withdrawals[recipient] += toSend;
        totalWithdrawals += toSend;
        //Send the person's BOOFI to their address
        boofi.safeTransfer(recipient, toSend);
        
        _dailyUpdate();

        emit Leave(recipient, what, _share);
    }
}