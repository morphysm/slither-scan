/**
 *Submitted for verification at testnet.snowtrace.io on 2022-05-08
*/

/*
OMNISTAKE - BNB/AVAX/MATIC/CRO/FTM Multi-Chain Miner
*/

// SPDX-License-Identifier: MIT

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

pragma solidity 0.8.9;

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

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract OmniStake is Context, Ownable {
    using SafeMath for uint256;

    //accept funds from external
    receive() external payable {}

    bool private initialized = false;
    uint256 public startDate;
    address payable public WALLET_PROJECT;
    address payable public WALLET_MARKETING;
    address payable public WALLET_FUND;
    address payable public WALLET_SPONSOR;

    uint256 public constant PROJECT_FEE = 30; // project fee 3% of deposit
    uint256 public constant MARKETING_FEE = 30; // marketing fee 3% of deposit
    uint256 public constant FUND_FEE = 30; // fund fee 3% of deposit
    uint256 public constant SPONSOR_FEE = 30; // sponsor fee 3% of deposit
    uint256 public constant PERCENTS_DIVIDER = 1000;

    uint256 private SHARES_TO_HATCH_1MINERS = 864000; //for final version should be seconds in a day
    uint256 private PSN = 10000;
    uint256 private PSNH = 5000;

    mapping(address => uint256) private shareMiners;
    mapping(address => uint256) private claimedShares;
    mapping(address => uint256) private lastHatch;
    mapping(address => address) private referrals;
    mapping(address => uint256) private referralsIncome;
    mapping(address => uint256) private referralsCount;

    uint256 private marketShares;

    event FeePayed(address indexed user, uint256 totalAmount);

    constructor(
        address payable _walletMarketing,
        address payable _walletFund,
        address payable _walletSponsor,
        uint256 startTime
    ) {
        WALLET_PROJECT = payable(msg.sender);
        WALLET_MARKETING = _walletMarketing;
        WALLET_FUND = _walletFund;
        WALLET_SPONSOR = _walletSponsor;

        if (startTime > 0) {
            startDate = startTime;
        } else {
            startDate = block.timestamp;
        }
    }

    function FeePayout(uint256 amount) internal {
        uint256 dfee = amount / 4;
        uint256 mfee = amount / 4;
        uint256 ffee = amount / 4;
        uint256 sfee = amount / 4;

        WALLET_PROJECT.transfer(dfee);
        WALLET_MARKETING.transfer(mfee);
        WALLET_FUND.transfer(ffee);
        WALLET_SPONSOR.transfer(sfee);

        emit FeePayed(msg.sender, dfee.add(mfee).add(ffee).add(sfee));
    }

    function hatchShares(address ref) public {
        seedMarket();

        require(initialized, "OmniStake is not initialized");

        if (ref == msg.sender) {
            ref = address(0);
        }

        if (
            referrals[msg.sender] == address(0) &&
            referrals[msg.sender] != msg.sender
        ) {
            referrals[msg.sender] = ref;
            referralsCount[ref] += 1;
        }

        uint256 sharesUsed = getMyShares(msg.sender);
        uint256 newMiners = SafeMath.div(sharesUsed, SHARES_TO_HATCH_1MINERS);
        shareMiners[msg.sender] = SafeMath.add(
            shareMiners[msg.sender],
            newMiners
        );
        claimedShares[msg.sender] = 0;
        lastHatch[msg.sender] = block.timestamp;

        //send referral shares
        claimedShares[referrals[msg.sender]] = SafeMath.add(
            claimedShares[referrals[msg.sender]],
            SafeMath.div(sharesUsed, 8)
        );

        referralsIncome[ref] = SafeMath.add(
            referralsIncome[ref],
            SafeMath.div(sharesUsed, 8)
        );

        //boost market to nerf miners hoarding
        marketShares = SafeMath.add(marketShares, SafeMath.div(sharesUsed, 5));
    }

    function sellShares() public {
        seedMarket();
        require(initialized);
        uint256 hasShares = getMyShares(msg.sender);
        uint256 shareValue = calculateShareSell(hasShares);
        uint256 fee = operativeFee(shareValue);
        claimedShares[msg.sender] = 0;
        lastHatch[msg.sender] = block.timestamp;
        marketShares = SafeMath.add(marketShares, hasShares);

        FeePayout(fee);
        payable(msg.sender).transfer(SafeMath.sub(shareValue, fee));
    }

    function shareRewards(address adr) public view returns (uint256) {
        uint256 hasShares = getMyShares(adr);
        uint256 shareValue = 0;
        if (hasShares > 0) {
            shareValue = calculateShareSell(hasShares);
        }
        return shareValue;
    }

    function buyShares(address ref) public payable {
        seedMarket();
        require(initialized);
        uint256 sharesBought = calculateShareBuy(
            msg.value,
            SafeMath.sub(address(this).balance, msg.value)
        );
        sharesBought = SafeMath.sub(sharesBought, operativeFee(sharesBought));
        uint256 fee = operativeFee(msg.value);
        FeePayout(fee);
        claimedShares[msg.sender] = SafeMath.add(
            claimedShares[msg.sender],
            sharesBought
        );
        hatchShares(ref);
    }

    function calculateTrade(
        uint256 rt,
        uint256 rs,
        uint256 bs
    ) private view returns (uint256) {
        return
            SafeMath.div(
                SafeMath.mul(PSN, bs),
                SafeMath.add(
                    PSNH,
                    SafeMath.div(
                        SafeMath.add(
                            SafeMath.mul(PSN, rs),
                            SafeMath.mul(PSNH, rt)
                        ),
                        rt
                    )
                )
            );
    }

    function calculateShareSell(uint256 shares) public view returns (uint256) {
        return calculateTrade(shares, marketShares, address(this).balance);
    }

    function calculateShareBuy(uint256 eth, uint256 contractBalance)
        public
        view
        returns (uint256)
    {
        return calculateTrade(eth, contractBalance, marketShares);
    }

    function calculateShareBuySimple(uint256 eth)
        public
        view
        returns (uint256)
    {
        return calculateShareBuy(eth, address(this).balance);
    }

    function operativeFee(uint256 amount) private pure returns (uint256) {
        uint256 dfee = (amount * PROJECT_FEE) / PERCENTS_DIVIDER;
        uint256 mfee = (amount * MARKETING_FEE) / PERCENTS_DIVIDER;
        uint256 ffee = (amount * FUND_FEE) / PERCENTS_DIVIDER;
        uint256 sfee = (amount * SPONSOR_FEE) / PERCENTS_DIVIDER;

        return dfee.add(mfee).add(ffee).add(sfee);
    }

    function seedMarket() public {
        if (block.timestamp > startDate && !initialized) {
            require(marketShares == 0);
            initialized = true;
            marketShares = 86400000000;
        }
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getMyReferralsCount(address adr) public view returns (uint256) {
        return referralsCount[adr];
    }

    function getMyReferralsIncome(address adr) public view returns (uint256) {
        return calculateShareSell(referralsIncome[adr]);
    }

    function getMyMiners(address adr) public view returns (uint256) {
        return shareMiners[adr];
    }

    function getMyShares(address adr) public view returns (uint256) {
        return SafeMath.add(claimedShares[adr], getSharesSinceLastHatch(adr));
    }

    function getSharesSinceLastHatch(address adr)
        public
        view
        returns (uint256)
    {
        uint256 secondsPassed = min(
            SHARES_TO_HATCH_1MINERS,
            SafeMath.sub(block.timestamp, lastHatch[adr])
        );
        return SafeMath.mul(secondsPassed, shareMiners[adr]);
    }

    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }
}