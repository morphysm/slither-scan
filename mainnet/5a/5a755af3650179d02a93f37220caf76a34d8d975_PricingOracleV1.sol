/**
 *Submitted for verification at snowtrace.io on 2022-06-15
*/

//
// .MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM.
// MMMMMMMMMMMMMMMWNKOdolc:::cclodk0NWMMMMMMMMMMMMMMM
// MMMMMMMMMMMMNOd:'....,;;::;;,....':oONMMMMMMMMMMMM
// MMMMMMMMMW0o,..,cdOKNWWWMMWWWNKOxc,..'l0WMMMMMMMMM
// MMMMMMMWOc..,o0NMMMMMMMMMMMMMMMMMMN0d,..:OWMMMMMMM
// MMMMMMKl. ;kNMMMMMMMMMMMMMMMMMMMMMMMMNk;..cKWMMMMM
// MMMMWO, .dNMMMMMMMMMMMMMNXNMMMMMMMMMMMMNx' 'kWMMMM
// MMMWO' ,0WMMMMMMMMMMMMXx;.,dXMMMMMMMMMMMMK; .kWMMM
// MMM0, ,0MMMMMMMMMMMMXx, ... 'dXMMMMMMMMMMMK; 'OMMM
// MMNl .xWMMMMMMMMMMXd' .l0X0l. 'dXMMMMMMMMMMO. :XMM
// MM0' :XMMMXdlkNMXd' .l0WMMMWKl. 'dXMNxcxNMMNc .OMM
// MMk. oWMMMKc..:l' .lKWWKdokNMWKl. 'c, .oNMMWd..dMM
// MMx. dWMMMMNo.   ;0WWKl.   ;kNMWO,   .xWMMMMx. dWM
// MMO. lNMMWXd' .. .oko. 'lo:..;xk:..'. 'dXMMWo .xMM
// MMK; ,0MXd' .oKXd.   .dXMMWO:   .;kNKl. 'dXK; ,0MM
// MMWx. :l' .oKWMMMKl. .xNMMWKc. ,kNMMMWKl. ',..oWMM
// MMMNl   .oKWMMMMMMW0c..;dkl. 'xNMMMMMMMWKc.  :XMMM
// MMMMXc  :XMMMMMMMMMMWO:.   .dXMMMMMMMMMMNo. :KMMMM
// MMMMMNo. ,kNMMMMMMMMMMX:  .kWMMMMMMMMMWO; .lXMMMMM
// MMMMMMW0:..;kXMMMMMMMMNc  .OMMMMMMMMNk:..;OWMMMMMM
// MMMMMMMMNO:..'ckKNMMMMNc  .OMMMMWKkl'..:kNMMMMMMMM
// MMMMMMMMMMWKd:...,:odkk,  .okxoc,...;o0WMMMMMMMMMM
// MMMMMMMMMMMMMWXkoc,.....   ....,:okKWMMMMMMMMMMMMM
// 'MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM'
//
//                    AVVY DOMAINS
//

// Sources flattened with hardhat v2.8.3 https://hardhat.org

// File @chainlink/contracts/src/v0.8/interfaces/[email protected]

pragma solidity ^0.8.0;

interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(
    uint80 _roundId
  )
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}


// File @openzeppelin/contracts/utils/math/[email protected]

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= type(int128).min && value <= type(int128).max, "SafeCast: value doesn't fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= type(int64).min && value <= type(int64).max, "SafeCast: value doesn't fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= type(int32).min && value <= type(int32).max, "SafeCast: value doesn't fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= type(int16).min && value <= type(int16).max, "SafeCast: value doesn't fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= type(int8).min && value <= type(int8).max, "SafeCast: value doesn't fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}


// File contracts/PricingOracleInterface.sol

pragma solidity ^0.8.0;

interface PricingOracleInterface {
  function getPriceForName(uint256 name, bytes memory data) external view returns (uint256 price, uint256 priceCentsUsd);
  function convertWeiToUsdCents(uint256 amount) external view returns (uint256 usdCents);
}


// File contracts/VerifierInterface.sol

pragma solidity ^0.8.0;

interface VerifierInterface {
  function verifyProof(bytes memory proof, uint[] memory pubSignals) external view returns (bool);
}


// File contracts/PricingOracleV1.sol

pragma solidity ^0.8.0;



contract PricingOracleV1 is PricingOracleInterface {
  using SafeCast for int256;
  AggregatorV3Interface immutable public priceFeed;
  VerifierInterface immutable public _verifier;

  function _getLatestRoundData() internal view returns (uint256 price) {
    if (address(priceFeed) == address(0)) {
      return 10000000000;
    } else {
      (
        ,
        int feedPrice,
        ,
        ,
        
      ) = priceFeed.latestRoundData();
      return feedPrice.toUint256();
    }
  }

  function _getWeiPerUSDCent() internal view returns (uint256 price) {
    uint256 feedPrice = _getLatestRoundData();
    require(feedPrice > 0, "PricingOracleV1: Chainlink Oracle returned feedPrice of 0");
    uint256 factor = 10**24;
    return factor / feedPrice;
  }

  function getPriceForName(
    uint256 name, 
    bytes memory data
  ) external view override returns (uint256 price, uint256 priceCentsUsd) {
    uint[] memory pubSignals;
    bytes memory proof;
    (pubSignals, proof) = abi.decode(data, (uint[], bytes));
    require(_verifier.verifyProof(proof, pubSignals), "PricingOracleV1: Verifier failed");
    require(pubSignals.length == 2, "PricingOracleV1: Invalid pubSignals");
    require(pubSignals[0] == name, "PricingOracleV1: Hash doesnt match");
    uint256 minLength = pubSignals[1];
    require(minLength >= 3, "PricingOracleV1: Length less than 3");
    uint256 namePrice = 500;
    if (minLength == 3) {
      namePrice = 64000;
    } else if (minLength == 4) {
      namePrice = 16000;
    }
    uint256 weiPerUSDCent = _getWeiPerUSDCent();
    uint256 _price = namePrice * weiPerUSDCent;
    return (_price, namePrice);
  }

  function convertWeiToUsdCents(
    uint256 amount
  ) external view override returns (uint256 usdCents) {
    uint256 weiPerUsdCent = _getWeiPerUSDCent();
    return amount / weiPerUsdCent;
  }

  constructor(VerifierInterface verifier) {
    _verifier = verifier;
    uint256 id;
    assembly {
      id := chainid()
    }
    address priceFeedAddress;
    if (id == 43113) {
      priceFeedAddress = 0x5498BB86BC934c8D34FDA08E81D444153d0D06aD;
    } else if (id == 43114) {
      priceFeedAddress = 0x0A77230d17318075983913bC2145DB16C7366156;
    }
    priceFeed = AggregatorV3Interface(priceFeedAddress);
  }
}