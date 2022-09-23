// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.6;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IsHPTToken.sol";
import "./interfaces/IHPTToken.sol";
import "./interfaces/IStaking.sol";


contract HighPointStaking is Ownable,IStaking{
    address public immutable HPT;
    address public immutable sHPT;

    uint public AnnualTotalBlocks;

    uint public FixedAPY;

    uint public UnStakeLimit = 2000 * 10 **18;

    mapping(address => stakedInfo)public info;

    struct stakedInfo{
        uint amount;
        uint lastRewardBlock;
    }

    constructor(address _HPT,address _sHPT,uint _annualTotalBlocks,uint _FixedAPY){
        HPT = _HPT;
        sHPT = _sHPT;
        AnnualTotalBlocks = _annualTotalBlocks;
        FixedAPY = _FixedAPY;
    }

    function stake(uint _amount)public returns(bool){
        IHPT( HPT ).transferFrom( msg.sender, address(this), _amount );

        stakedInfo memory Info = info[ msg.sender ];
        

        info[ msg.sender ] = stakedInfo ({
            amount: Info.amount + _amount,
            lastRewardBlock: block.number
        });
        
        IsHPT( sHPT ).mint( msg.sender, _amount );
        return true;
    }

    function claim(address _recipient)public returns(bool){
        uint balance = IERC20(sHPT).balanceOf(_recipient);
        require( balance > 0,"Claim after staked");

        uint lastRewardBlock = info[_recipient].lastRewardBlock;

        uint activeBlocks = block.number - lastRewardBlock;

        uint rewardAmount = balance * FixedAPY * activeBlocks/AnnualTotalBlocks;

        IHPT(HPT).mint(_recipient,rewardAmount);

        info[_recipient].lastRewardBlock = block.number;

        return true;
    }

    function unstake(uint _amount)public returns(bool){
        require(_amount <= UnStakeLimit,"Unstake Limit is 2000");
        info[msg.sender].amount = info[msg.sender].amount - _amount;
        IHPT( HPT ).transfer(address(this), _amount);
        IsHPT(sHPT).burnFrom(msg.sender,_amount);
        return true;
    }

    function setAnnualTotalBlocks(uint _blocks)public onlyOwner returns(bool){
        AnnualTotalBlocks = _blocks;
        return true;
    }

    function setFixedApy(uint _APY)public onlyOwner returns(bool){
        FixedAPY = _APY;
        return true;
    }

    function setOwnerforHPT(address _newOwner)public onlyOwner returns(bool){
        Ownable(HPT).transferOwnership(_newOwner);
        return true;
    }

    function setOwnerforsHPT(address _newOwner)public onlyOwner returns(bool){
        Ownable(sHPT).transferOwnership(_newOwner);
        return true;
    }

    function pendingRewards(address _address)public view returns(uint){
        uint balance = IERC20(sHPT).balanceOf(_address);
        uint lastRewardBlock = info[_address].lastRewardBlock;

        uint activeBlocks = block.number - lastRewardBlock;

        uint rewardAmount = balance/FixedAPY * activeBlocks/AnnualTotalBlocks;

        return rewardAmount;
    }

    function transferStakingToken(address _from, address _to,uint _amount) external override returns(bool){
        require(msg.sender == sHPT,"Access denied");


        info[_from].amount = info[_from].amount - uint(_amount);

        stakedInfo memory receiverInfo = info[_to];

        info[msg.sender] = stakedInfo({
            amount : receiverInfo.amount + _amount,
            lastRewardBlock: block.number
        });

        return true;

    }

    function setUnstakeLimit(uint _unstakeLimit)public onlyOwner returns(bool){
        UnStakeLimit = _unstakeLimit * 10**18;
        return true;
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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

pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IsHPT is IERC20 {
    function mint(address account_, uint256 amount_) external;

    function burn(uint256 amount) external;

    function burnFrom(address account_, uint256 amount_) external;
}

pragma solidity 0.8.6;

interface IStaking{
    function transferStakingToken(address _from,address _to,uint _amount)external returns(bool);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IHPT is IERC20 {
    function mint(address _to, uint256 _amount) external;
    
}