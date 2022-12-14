//SPDX-License-Identifier: UNLICENSE
pragma solidity ^0.8.4;

import "../../satellite/loanAgent/interfaces/ILoanAgent.sol";
import "../../satellite/loanAgent/LoanAgentStorage.sol";
import "../../satellite/loanAgent/LoanAgent.sol";
import "../../satellite/loanAgent/LoanAgentAdmin.sol";
import "../../satellite/loanAgent/LoanAgentMessageHandler.sol";
import "../interfaces/IDelegator.sol";
import "./events/LoanAgentDelegatorEvents.sol";

contract LoanAgentDelegator is
    LoanAgentStorage,
    ILoanAgent,
    LoanAgentDelegatorEvents,
    IDelegator
{
    constructor(
        address _delegateeAddress,
        address eccAddress
    ) {
        admin = delegatorAdmin = payable(msg.sender);

        setDelegateeAddress(_delegateeAddress);

        _delegatecall(abi.encodeWithSelector(
            SatelliteLoanAgent.initialize.selector,
            eccAddress
        ));
    }

    function borrow(
        uint256 borrowAmount,
        address route,
        address loanMarketAsset
    ) external payable override {
        _delegatecall(abi.encodeWithSelector(
            SatelliteLoanAgent.borrow.selector,
            borrowAmount,
            route,
            loanMarketAsset
        ));
    }

    function repayBorrow(
        uint256 repayAmount,
        address route,
        address loanMarketAsset
    ) external payable override returns (bool success) {
        bytes memory data = _delegatecall(abi.encodeWithSelector(
            SatelliteLoanAgent.repayBorrow.selector,
            repayAmount,
            route,
            loanMarketAsset
        ));

        (success) = abi.decode(data, (bool));

        emit RepayBorrow(success);
    }

    function repayBorrowBehalf(
        address borrower,
        uint256 repayAmount,
        address route,
        address loanMarketAsset
    ) external payable override returns (bool success) {
        bytes memory data = _delegatecall(abi.encodeWithSelector(
            SatelliteLoanAgent.repayBorrowBehalf.selector,
            borrower,
            repayAmount,
            route,
            loanMarketAsset
        ));

        (success) = abi.decode(data, (bool));

        emit RepayBorrowBehalf(success);
    }

    function borrowApproved(
        IHelper.FBBorrow memory params,
        bytes32 metadata
    ) external payable override {
        _delegatecall(abi.encodeWithSelector(
            LoanAgentMessageHandler.borrowApproved.selector,
            params,
            metadata
        ));
    }

    function setMidLayer(address newMiddleLayer) external override {
        _delegatecall(abi.encodeWithSelector(
            LoanAgentAdmin.setMidLayer.selector,
            newMiddleLayer
        ));
    }

    function setMasterCID(uint256 newChainId) external override {
        _delegatecall(abi.encodeWithSelector(
            LoanAgentAdmin.setMasterCID.selector,
            newChainId
        ));
    }

    // ? Controlled delegate call is a misdetection here as the address is controlled by the contract
    // ? The only options the user is in controll of here is the function selector and params,
    // ? both of which are safe for the user to controll given that the implmentation is addressing msg.sender and
    // ? admin when in context of admin functions.
    // controlled-delegatecall,low-level-calls
    // slither-disable-next-line all
    fallback() external {
        /* If a function is not defined above, we can still call it using msg.data. */
        (bool success,) = delegateeAddress.delegatecall(msg.data);

        assembly {
            let free_mem_ptr := mload(0x40)
            returndatacopy(free_mem_ptr, 0, returndatasize())

            switch success
            case 0 { revert(free_mem_ptr, returndatasize()) }
            default { return(free_mem_ptr, returndatasize()) }
        }
    }
}

//SPDX-License-Identifier: UNLICENSE
pragma solidity ^0.8.4;

import "../LoanAgentStorage.sol";
import "../../../interfaces/IHelper.sol";

abstract contract ILoanAgent is LoanAgentStorage {

    function borrow(
        uint256 borrowAmount,
        address route,
        address loanMarketAsset
    ) external payable virtual;

    function repayBorrow(
        uint256 repayAmount,
        address route,
        address loanMarketAsset
    ) external payable virtual returns (bool);

    function repayBorrowBehalf(
        address borrower,
        uint256 repayAmount,
        address route,
        address loanMarketAsset
    ) external payable virtual returns (bool);

    function borrowApproved(
        IHelper.FBBorrow memory params,
        bytes32 metadata
    ) external payable virtual;

    function setMidLayer(address newMiddleLayer) external virtual;

    function setMasterCID(uint256 newChainId) external virtual;
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "../../middleLayer/interfaces/IMiddleLayer.sol";
import "../../ecc/interfaces/IECC.sol";

abstract contract LoanAgentStorage {
    /**
    * @notice Administrator for this contract
    */
    address payable public admin;

    // slither-disable-next-line unused-state
    IMiddleLayer internal middleLayer;

    // slither-disable-next-line unused-state
    IECC internal ecc;

    // slither-disable-next-line unused-state
    uint256 internal masterCID;
}

//SPDX-License-Identifier: UNLICENSE
pragma solidity ^0.8.4;

import "./interfaces/ILoanAgent.sol";
import "./LoanAgentAdmin.sol";
import "./LoanAgentEvents.sol";
import "./LoanAgentMessageHandler.sol";
import "./LoanAgentInternals.sol";
import "../../util/CommonModifiers.sol";

contract SatelliteLoanAgent is
    ILoanAgent,
    LoanAgentAdmin,
    LoanAgentMessageHandler,
    LoanAgentInternals,
    CommonModifiers
{
    function initialize(address eccAddress) external onlyOwner() {
        require(address(eccAddress) != address(0), "NON_ZEROADDRESS");
        ecc = IECC(eccAddress);
    }

    /**
     * @notice Users borrow assets from the protocol to their own address
     * @param borrowAmount The amount of the underlying asset to borrow
     */
    function borrow(
        uint256 borrowAmount,
        address route,
        address loanMarketAsset
    ) external payable virtual override {
        _sendBorrow(
            msg.sender,
            borrowAmount,
            route,
            loanMarketAsset
        );
    }

    function repayBorrow(
        uint256 repayAmount,
        address route,
        address loanMarketAsset
    ) external payable virtual override returns (bool) {
        _repayBorrowFresh(msg.sender, msg.sender, repayAmount, route, loanMarketAsset);

        return true;
    }

    function repayBorrowBehalf(
        address borrower,
        uint256 repayAmount,
        address route,
        address loanMarketAsset
    ) external payable virtual override returns (bool) {
        _repayBorrowFresh(msg.sender, borrower, repayAmount, route, loanMarketAsset);

        return true;
    }

    fallback() external payable {}
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./interfaces/ILoanAgent.sol";
import "./LoanAgentModifiers.sol";
import "./LoanAgentEvents.sol";

abstract contract LoanAgentAdmin is ILoanAgent, LoanAgentModifiers, LoanAgentEvents {
    function setMidLayer(
        address newMiddleLayer
    ) external override onlyOwner() {
        if(newMiddleLayer == address(0)) revert AddressExpected();
        middleLayer = IMiddleLayer(newMiddleLayer);

        emit SetMidLayer(newMiddleLayer);
    }

    function setMasterCID(
        uint256 newChainId
    ) external override onlyOwner() {
        masterCID = newChainId;

        emit SetMasterCID(newChainId);
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "../../interfaces/IHelper.sol";
import "./interfaces/ILoanAgent.sol";
import "./interfaces/ILoanAgentInternals.sol";
import "./LoanAgentModifiers.sol";
import "../pusd/interfaces/IPUSD.sol";
import "./LoanAgentEvents.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

abstract contract LoanAgentMessageHandler is ILoanAgent, ILoanAgentInternals, LoanAgentModifiers, LoanAgentEvents {
    // slither-disable-next-line assembly
    function _sendBorrow(
        address user,
        uint256 amount,
        address route,
        address loanMarketAsset
    ) internal virtual override {
        bytes memory payload = abi.encode(
            uint256(0),
            IHelper.MBorrowAllowed(
                IHelper.Selector.MASTER_BORROW_ALLOWED,
                user,
                amount,
                loanMarketAsset
            )
        );

        bytes32 metadata = ecc.preRegMsg(payload, msg.sender);
        assembly {
            mstore(add(payload, 0x20), metadata)
        }

        middleLayer.msend{value: msg.value}(
            masterCID,
            payload, // bytes payload
            payable(msg.sender), // refund address
            route
        );

        emit BorrowSent(
            user,
            address(this),
            amount,
            loanMarketAsset
        );
    }

    function borrowApproved(
        IHelper.FBBorrow memory params,
        bytes32 metadata
    ) external payable override virtual onlyMid() {
        if (!ecc.preProcessingValidation(abi.encode(params), metadata)) revert EccMessageAlreadyProcessed();

        if (!ecc.flagMsgValidated(abi.encode(params), metadata)) revert EccFailedToValidate();

        emit BorrowApproved(
            params.user,
            params.borrowAmount,
            params.loanMarketAsset,
            true
        );

        /////////////////////////
        // EFFECTS & INTERACTIONS
        // (No safe failures beyond this point)

        /*
         * We invoke doTransferOut for the borrower and the borrowAmount.
         *  Note: The pToken must handle variations between ERC-20 and ETH underlying.
         *  On success, the pToken borrowAmount less of cash.
         *  doTransferOut reverts if anything goes wrong, since we can't be sure if side effects occurred.
         */
        // This can be easily simplified because we are only issuing one token - PuSD
        // doTransferOut(borrower, borrowAmount);
        // might need a safe transfer of sorts

        // FIXME: Rename IPUSD to something more generic.
        IPUSD(params.loanMarketAsset).mint(params.user, params.borrowAmount);

        emit BorrowComplete(
            params.user,
            address(this),
            params.loanMarketAsset,
            params.borrowAmount
        );
    }

    // slither-disable-next-line assembly
    function _repayBorrowFresh(
        address payer,
        address borrower,
        uint256 repayAmount,
        address route,
        address loanMarketAsset
    ) internal virtual override returns (uint256) {
        /////////////////////////
        // EFFECTS & INTERACTIONS
        // (No safe failures beyond this point)

        /*
        * We call doTransferIn for the payer and the repayAmount
        *  Note: The pToken must handle variations between ERC-20 and ETH underlying.
        *  On success, the pToken holds an additional repayAmount of cash.
        *  doTransferIn reverts if anything goes wrong, since we can't be sure if side effects occurred.
        *   it returns the amount actually transferred, in case of a fee.
        */
        ERC20Burnable(loanMarketAsset).burnFrom(payer, repayAmount);

        bytes memory payload = abi.encode(
            uint256(0),
            IHelper.MRepay({
                selector: IHelper.Selector.MASTER_REPAY,
                borrower: borrower,
                amountRepaid: repayAmount,
                loanMarketAsset: loanMarketAsset
            })
        );

        bytes32 metadata = ecc.preRegMsg(payload, msg.sender);
        assembly {
            mstore(add(payload, 0x20), metadata)
        }

        middleLayer.msend{ value: msg.value }(
            masterCID,
            payload,
            payable(msg.sender),
            route
        );

        emit RepaySent(
            payer,
            borrower,
            address(this),
            repayAmount,
            loanMarketAsset
        );

        return repayAmount;
    }
}

//SPDX-License-Identifier: UNLICENSE
pragma solidity ^0.8.4;

import "../common/DelegatorModifiers.sol";
import "../common/DelegatorErrors.sol";
import "../common/DelegatorEvents.sol";
import "../common/DelegatorStorage.sol";

abstract contract IDelegator is
    DelegatorEvents,
    DelegatorStorage,
    DelegatorUtil,
    DelegatorModifiers,
    DelegatorErrors
{

    function setDelegateeAddress(
        address newDelegateeAddress
    ) public onlyAdmin() {
        if(newDelegateeAddress == address(0)) revert AddressExpected();
        (delegateeAddress, newDelegateeAddress) = (newDelegateeAddress, delegateeAddress);

        emit DelegateeAddressUpdate(newDelegateeAddress, delegateeAddress);
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

abstract contract LoanAgentDelegatorEvents {

    event RepayBorrow(bool success);
    event RepayBorrowBehalf(bool success);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.4;

interface IHelper {
    enum Selector {
        MASTER_DEPOSIT,
        MASTER_REDEEM_ALLOWED,
        FB_REDEEM,
        MASTER_REPAY,
        MASTER_BORROW_ALLOWED,
        FB_BORROW,
        SATELLITE_LIQUIDATE_BORROW,
        PUSD_BRIDGE
    }

    // !!!!
    // @dev
    // an artificial uint256 param for metadata should be added
    // after packing the payload
    // metadata can be generated via call to ecc.preRegMsg()

    struct MDeposit {
        Selector selector; // = Selector.MASTER_DEPOSIT
        address user;
        address pToken;
        uint256 previousAmount;
        uint256 amountIncreased;
    }

    struct MRedeemAllowed {
        Selector selector; // = Selector.MASTER_REDEEM_ALLOWED
        address pToken;
        address user;
        uint256 amount;
    }

    struct FBRedeem {
        Selector selector; // = Selector.FB_REDEEM
        address pToken;
        address user;
        uint256 redeemAmount;
    }

    struct MRepay {
        Selector selector; // = Selector.MASTER_REPAY
        address borrower;
        uint256 amountRepaid;
        address loanMarketAsset;
    }

    struct MBorrowAllowed {
        Selector selector; // = Selector.MASTER_BORROW_ALLOWED
        address user;
        uint256 borrowAmount;
        address loanMarketAsset;
    }

    struct FBBorrow {
        Selector selector; // = Selector.FB_BORROW
        address user;
        uint256 borrowAmount;
        address loanMarketAsset;
    }

    struct SLiquidateBorrow {
        Selector selector; // = Selector.SATELLITE_LIQUIDATE_BORROW
        address borrower;
        address liquidator;
        uint256 seizeTokens;
        address pTokenCollateral;
    }


    struct PUSDBridge {
        uint8 selector; // = Selector.PUSD_BRIDGE
        address minter;
        uint256 amount;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

abstract contract IMiddleLayer {
    /**
     * @notice routes and encodes messages for you
     * @param params - abi.encode() of the struct related to the selector, used to generate _payload
     * all params starting with '_' are directly sent to the lz 'send()' function
     */
    function msend(
        uint256 _dstChainId,
        bytes memory params,
        address payable _refundAddress,
        address fallbackAddress
    ) external payable virtual;

    function mreceive(
        uint256 _srcChainId,
        bytes memory payload
    ) external virtual;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IECC {
    struct Metadata {
        bytes5 soph; // start of payload hash
        uint40 creation;
        uint16 nonce; // in case the same exact message is sent multiple times the same block, we increase the nonce in metadata
        address sender;
    }

    function preRegMsg(
        bytes memory payload,
        address instigator
    ) external returns (bytes32 metadata);

    function preProcessingValidation(
        bytes memory payload,
        bytes32 metadata
    ) external view returns (bool allowed);

    function flagMsgValidated(
        bytes memory payload,
        bytes32 metadata
    ) external returns (bool);

    // function rsm(uint256 messagePtr) external returns (bool);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

abstract contract LoanAgentEvents {
    event BorrowSent(
        address user,
        address loanAgent,
        uint256 amount,
        address loanMarketAsset
    );

    event BorrowApproved(
        address indexed borrower,
        uint256 borrowAmount,
        address loanMarketAsset,
        bool isBorrowAllowed
    );

    event BorrowComplete(
        address indexed borrower,
        address loanAgent,
        address loanMarketAsset,
        uint256 borrowAmount
    );

    event RepaySent(
        address payer,
        address borrower,
        address loanAgent,
        uint256 repayAmount,
        address loanMarketAsset
    );

    event LiquidateBorrow(
        address liquidator,
        address borrower,
        uint256 repayAmount,
        address cTokenCollateral,
        uint256 seizeTokens
    );

    event SetMidLayer(
        address middleLayer
    );

    event SetMasterCID(
        uint256 newChainId
    );
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./interfaces/ILoanAgentInternals.sol";
import "../../interfaces/IHelper.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

abstract contract LoanAgentInternals is ILoanAgentInternals {

}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./CommonErrors.sol";

abstract contract CommonModifiers is CommonErrors {

    /**
    * @dev Guard variable for re-entrancy checks
    */
    bool internal notEntered;

    constructor() {
        notEntered = true;
    }

    /**
    * @dev Prevents a contract from calling itself, directly or indirectly.
    */
    modifier nonReentrant() {
        if (!notEntered) revert Reentrancy();
        notEntered = false;
        _;
        notEntered = true; // get a gas-refund post-Istanbul
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./LoanAgentStorage.sol";
import "../../util/CommonErrors.sol";

abstract contract LoanAgentModifiers is LoanAgentStorage, CommonErrors {

    modifier onlyOwner() {
        if(msg.sender != admin) revert OnlyOwner();
        _;
    }

    modifier onlyMid() {
        if (msg.sender != address(middleLayer)) revert OnlyMiddleLayer();
        _;
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

abstract contract CommonErrors {
    error AccountNoAssets(address account);
    error AddressExpected();
    error EccMessageAlreadyProcessed();
    error EccFailedToValidate();
    error ExpectedRedeemAmount();
    error ExpectedRepayAmount();
    error InsufficientReserves();
    error InvalidPayload();
    error InvalidPrice();
    error MarketExists();
    error MarketIsPaused();
    error NotInMarket(uint256 chainId, address token);
    error OnlyAuth();
    error OnlyGateway();
    error OnlyMiddleLayer();
    error OnlyOwner();
    error OnlyRoute();
    error Reentrancy();
    error RepayTooMuch(uint256 repayAmount, uint256 maxAmount);
    error RedeemTooMuch();
    error NotEnoughBalance(address token, address who);
    error LiquidateDisallowed();
    error SeizeTooMuch();
    error RouteNotSupported(address route);
    error TransferFailed(address from, address dest);
    error TransferPaused();
    error UnknownRevert();
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "../LoanAgentStorage.sol";

abstract contract ILoanAgentInternals is LoanAgentStorage {

    function _repayBorrowFresh(
        address payer,
        address borrower,
        uint256 repayAmount,
        address route,
        address loanMarketAsset
    ) internal virtual returns (uint256);

    function _sendBorrow(
        address user,
        uint256 amount,
        address route,
        address loanMarketAsset
    ) internal virtual;
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

interface IPUSD {
    function mint(address to, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/extensions/ERC20Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC20.sol";
import "../../../utils/Context.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

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
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
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
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
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
        address owner = _msgSender();
        _approve(owner, spender, _allowances[owner][spender] + addedValue);
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
        address owner = _msgSender();
        uint256 currentAllowance = _allowances[owner][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
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
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
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
     * @dev Spend `amount` form the allowance of `owner` toward `spender`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

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

//SPDX-License-Identifier: UNLICENSE
pragma solidity ^0.8.4;

import "./DelegatorErrors.sol";
import "./DelegatorStorage.sol";

contract DelegatorModifiers is DelegatorStorage {
    // slither-disable-next-line unused-return
    modifier onlyAdmin() {
        if (msg.sender != delegatorAdmin) revert DelegatorErrors.AdminOnly(msg.sender);
        _;
    }
}

//SPDX-License-Identifier: UNLICENSE
pragma solidity ^0.8.4;

import "./DelegatorUtil.sol";
import "./DelegatorStorage.sol";

contract DelegatorErrors {

    error DelegatecallFailed(address delegateeAddress, bytes selectorAndParams);
    error NoValueToFallback(address msgSender, uint256 msgValue);
    error AdminOnly(address msgSender);
}

//SPDX-License-Identifier: UNLICENSE
pragma solidity ^0.8.4;

import "./DelegatorUtil.sol";
import "./DelegatorStorage.sol";

contract DelegatorEvents {

    event DelegateeAddressUpdate(address oldDelegateeAddress, address newDelegateeAddress);
}

//SPDX-License-Identifier: UNLICENSE
pragma solidity ^0.8.4;

contract DelegatorStorage {

    address payable public delegatorAdmin;

    address public delegateeAddress;
}

//SPDX-License-Identifier: UNLICENSE
pragma solidity ^0.8.4;

import "./DelegatorErrors.sol";
import "./DelegatorStorage.sol";
import "../../util/CommonErrors.sol";

contract DelegatorUtil is DelegatorStorage, CommonErrors {
    // slither-disable-next-line assembly
    function _safeRevert(bool success, bytes memory _returnData) internal pure {
        if (success) return;

        // If the _res length is less than 68, then the transaction failed silently (without a revert message)
        if (_returnData.length < 68) revert UnknownRevert();

        assembly {
            // Slice the sighash.
            _returnData := add(_returnData, 0x04)
        }
        revert(abi.decode(_returnData, (string))); // All that remains is the revert string
    }

    // ? This is safe so long as the implmentation contract does not have any obvious
    // ? vulns around calling functions with raised permissions ie admin function callable by anyone
    // controlled-delegatecall,low-level-calls
    // slither-disable-next-line all
    function _delegatecall(
        bytes memory selector
    ) internal returns (bytes memory) {
        (bool success, bytes memory data) = delegateeAddress.delegatecall(selector);
        assembly {
            if eq(success, 0) {
                revert(add(data, 0x20), returndatasize())
            }
        }
        return data;
    }

    function delegateToImplementation(bytes memory selector) public returns (bytes memory) {
        return _delegatecall(selector);
    }

    function _staticcall(
        bytes memory selector
    ) public view returns (bytes memory) {
        (bool success, bytes memory data) = address(this).staticcall(abi.encodeWithSignature("delegateToImplementation(bytes)", selector));
        assembly {
            if eq(success, 0) {
                revert(add(data, 0x20), returndatasize())
            }
        }
        return abi.decode(data, (bytes));
    }
}