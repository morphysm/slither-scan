// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IArableOracle.sol";
import "./interfaces/IArableSynth.sol";
import "./interfaces/IArableFarming.sol";
import "./interfaces/IArableCollateral.sol";
import "./interfaces/IArableAddressRegistry.sol";

// Generalized epoch basis staking contract (epoch = 1 day)
contract ArableFarming is Ownable, IArableFarming {
    address public addressRegistry;
    uint256 public epochZeroTime;
    // TODO: on testnet, this could be configured to 1 min
    uint256 public epochDuration = 1 days;

    // rewardRateSum[farmId][rewardToken][epoch]: rewardRateSum from epoch0 to epoch for stakingFarm's rewardToken
    mapping(uint256 => mapping(address => mapping(uint256 => uint256))) public rewardRateSum;
    // lastClaimEpoch[farmId][rewardToken][address]: last claimed epoch by address
    mapping(uint256 => mapping(address => mapping(address => uint256))) public lastClaimEpoch;
    mapping(uint256 => mapping(address => uint256)) public lastRewardRateSumEpoch;

    address[] public stakingTokens;
    mapping(uint256 => bool) public isDisabledFarm;

    // staking amount by farm and address
    mapping(uint256 => mapping(address => uint256)) public stakingAmount;

    // staking pools per address
    // user_address => staking_pools 
    mapping(address => uint256[]) public usedFarmingPools;
    // user_address => staking_pool => bool 
    mapping(address => mapping(uint256 => bool)) public isUsedFarmingPool;

    // reward tokens per staking pool, limit to 3 tokens to be simple
    mapping(uint256 => mapping(uint256 => address)) public rewardTokens;
    mapping(uint256 => uint256) public rewardTokenLengths;
    mapping(uint256 => mapping(address => bool)) public _isRewardToken;

    event RegisterStakingPool(uint256 farmId, address stakingToken);

    constructor(address addressRegistry_) {
        addressRegistry = addressRegistry_;
        epochZeroTime = block.timestamp;
    }

    // create a new farm
    function registerFarm(address stakingToken) public override onlyOwner returns(uint256 farmId) {
        require(stakingToken != address(0x0), "stakingToken should be set");
        stakingTokens.push(stakingToken);
        farmId = stakingTokens.length - 1;
        emit RegisterStakingPool(farmId, stakingToken);
        return farmId;
    }

    function setRewardTokens(uint256 farmId, address[] memory _rewardTokens) public override onlyOwner {
        deleteRewardTokens(farmId);
        for (uint256 i =0; i < _rewardTokens.length; i ++) {
            rewardTokens[farmId][i] = _rewardTokens[i];
            _isRewardToken[farmId][_rewardTokens[i]] = true;
        }
        rewardTokenLengths[farmId] = _rewardTokens.length;
    }

    function bulkRegisterFarm(address[] calldata farmToken_) external onlyOwner {
        for(uint256 i=0; i < farmToken_.length; i++) {
            registerFarm(farmToken_[i]);
        }
    }

    function bulkSetRewardTokens(uint256[] calldata farmId_, address[][] calldata rewardTokens_) external onlyOwner {
        require(farmId_.length == rewardTokens_.length, "Please check you input data.");
        for(uint256 i=0; i < farmId_.length; i++) {
            setRewardTokens(farmId_[i], rewardTokens_[i]);
        }
    }

    function currentEpoch() public view override returns (uint256) {
        return (block.timestamp - epochZeroTime) / epochDuration;
    }

    // run by bot or anyone per epoch
    function updateRewardRateSum(uint256 farmId, address rewardToken) external override {
        uint256 lastEpoch = lastRewardRateSumEpoch[farmId][rewardToken];
        uint256 curEpoch = currentEpoch();
        require(curEpoch > lastEpoch, "Refresh already up-to-date");


        address oracle = IArableAddressRegistry(addressRegistry).getArableOracle();
        IArableOracle oracleContract = IArableOracle(oracle);
        uint256 dailyRewardRate = oracleContract.getDailyRewardRate(farmId, rewardToken);
        lastRewardRateSumEpoch[farmId][rewardToken] = curEpoch;
        uint256 lastEpochRewardSum = rewardRateSum[farmId][rewardToken][lastEpoch];

        // TODO: in most of cases, this should run on daily basis and for loop depth should be 1
        for (lastEpoch = lastEpoch + 1; lastEpoch <= curEpoch; lastEpoch ++) {
            rewardRateSum[farmId][rewardToken][lastEpoch] = lastEpochRewardSum + dailyRewardRate;
        }
    }

    function deleteRewardTokens(uint256 farmId) public override onlyOwner {
        for (uint256 i = 0; i < rewardTokenLengths[farmId]; i ++) {
            _isRewardToken[farmId][rewardTokens[farmId][i]] = false;
        }
        rewardTokenLengths[farmId] = 0;
    }

    function setIsDisabledFarm(uint256 farmId, bool isDisabled) external override onlyOwner {
        isDisabledFarm[farmId] = isDisabled;
    }

    function stake(uint256 farmId, uint256 amount) external override {
        require(amount > 0, "should stake positive amount");
        IERC20(stakingTokens[farmId]).transferFrom(msg.sender, address(this), amount);
        stakingAmount[farmId][msg.sender] += amount;

        // register usedFarmingPools
        if (isUsedFarmingPool[msg.sender][farmId] == false) {
            usedFarmingPools[msg.sender].push(farmId);
            isUsedFarmingPool[msg.sender][farmId] = true;
        }
    }

    function unstake(uint256 farmId, uint256 amount) external override {
        require(amount > 0, "should unstake positive amount");
        // TODO: we might need to add unstake notice period 
        stakingAmount[farmId][msg.sender] -= amount;
        IERC20(stakingTokens[farmId]).transfer(msg.sender, amount);
    }

    function claimReward(uint256 farmId, address rewardToken) external override {
        uint256 curEpoch = currentEpoch();
        uint256 claimAmount = estimatedReward(farmId, rewardToken, msg.sender);

        lastClaimEpoch[farmId][rewardToken][msg.sender] = curEpoch;
        IArableSynth(rewardToken).mint(msg.sender, claimAmount);

        // update totalDebt for reward claim event    
        IArableAddressRegistry _addressRegistry = IArableAddressRegistry(addressRegistry);
        IArableOracle oracle = IArableOracle(_addressRegistry.getArableOracle());
        IArableCollateral collateral = IArableCollateral(_addressRegistry.getArableCollateral());
        uint256 tokenPrice = oracle.getPrice(rewardToken);
        if (tokenPrice > 0) {
            collateral.addToDebt(claimAmount * tokenPrice / 1 ether);
        }

        // TODO: handle the case someone mint after pretty long time which could make big system debt changes
        // - Possibly set maximum amount of tokens to be able to claim for specific token
        // - Too big rewards for long time stake should be cut
    }

    function estimatedReward(uint256 farmId, address rewardToken, address user) public view override returns (uint256) {
        uint256 curEpoch = currentEpoch();
        uint256 claimedEpoch = lastClaimEpoch[farmId][rewardToken][user];
        uint256 curRewardRateSum = rewardRateSum[farmId][rewardToken][curEpoch];
        uint256 lastRewardRateSum = rewardRateSum[farmId][rewardToken][claimedEpoch];
        uint256 stakingAmt = stakingAmount[farmId][user];
        uint256 claimAmount = (curRewardRateSum - lastRewardRateSum) * stakingAmt / 1 ether;
        return claimAmount;
    }

    function getRewardTokens(uint256 farmId)
        external
        view
        override
        returns (address[] memory)
    {
        address[] memory tokens = new address[](rewardTokenLengths[farmId]);
        for (uint256 i = 0; i < rewardTokenLengths[farmId]; i++) {
            tokens[i] = rewardTokens[farmId][i];
        }
        return tokens;
    }

    function isRewardToken(uint256 farmId, address rewardToken) external view override returns (bool) {
        return _isRewardToken[farmId][rewardToken];
    }
}

// SPDX-License-Identifier: MIT

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
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
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
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
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

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IArableOracle {
    function getPrice(address token) external view returns (uint256);
    function getDailyRewardRate(uint256 farmId, address rewardToken) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IArableSynth is IERC20 {
    function mint(address toAddress, uint256 amount) external;
    function burn(uint256 amount) external;
    function burnFrom(address account, uint256 amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IArableFarming {
    function isRewardToken(uint256 farmId, address rewardToken) external view returns (bool);
    function getRewardTokens(uint256 farmId) external view returns (address[] memory);
    function currentEpoch() external view returns (uint256);
    function updateRewardRateSum(uint256 farmId, address rewardToken) external;
    function registerFarm(address stakingToken) external returns (uint256);
    function setRewardTokens(uint256 farmId, address[] memory _rewardTokens) external;
    function deleteRewardTokens(uint256 farmId) external;
    function setIsDisabledFarm(uint256 farmId, bool isDisabled) external;
    function stake(uint256 farmId, uint256 amount) external;
    function unstake(uint256 farmId, uint256 amount) external;
    function claimReward(uint256 farmId, address rewardToken) external;
    function estimatedReward(uint256 farmId, address rewardToken, address user) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IArableCollateral {
    function addToDebt(uint amount) external returns (bool);
    function removeFromDebt(uint256 amount) external returns (bool);
    function getTotalDebt() external returns (uint);
    function addSupportedCollateral(address token, uint allowedRate) external returns (bool);
    function removeSupportedCollateral(address token) external returns (bool);
    function changeAllowedRate(address token, uint newAllowedRate) external returns (bool);
    function maxIssuableArUSD(address user) external view returns (uint);
    function currentDebt(address user) external view returns (uint);
    function calculateCollateralValue(address user) external view returns (uint);
    function _liquidateCollateral(address user, address beneficiary, uint liquidationAmount) external;
}

// SPDX-License-Identifier: GNU-GPL v3.0 or later

pragma solidity ^0.8.0;

/**
 * @title Provider interface for Arable
 * @dev
 */
interface IArableAddressRegistry {
    function initialize(
        address arableOracle_,
        address arableFarming_,
        address arableExchange_,
        address arableManager_,
        address arableCollateral_,
        address arableLiquidation_,
        address arableFeeCollector_
    ) external;

    function getAddress(bytes32 id) external view returns (address);

    function setAddress(bytes32 id, address address_) external;

    function getArableOracle() external view returns (address);

    function setArableOracle(address arableOracle_) external;

    function getArableExchange() external view returns (address);

    function setArableExchange(address arableExchange_) external;

    function getArableManager() external view returns (address);

    function setArableManager(address arableManager_) external;

    function getArableFarming() external view returns (address);

    function setArableFarming(address arableFarming_) external;
    
    function getArableCollateral() external view returns (address);

    function setArableCollateral(address arableCollateral_) external;

    function getArableLiquidation() external view returns (address);

    function setArableLiquidation(address arableLiquidation_) external;
    
    function getArableFeeCollector() external view returns (address);

    function setArableFeeCollector(address arableFeeCollector_) external;
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
        return msg.data;
    }
}