/**
 *Submitted for verification at snowtrace.io on 2022-08-28
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

interface IUniswapPair {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );
}

library UniswapLibrary {    
    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB)
        internal
        pure
        returns (address token0, address token1)
    {
        require(tokenA != tokenB, "UniswapLibrary: IDENTICAL_ADDRESSES");
        (token0, token1) = tokenA < tokenB
            ? (tokenA, tokenB)
            : (tokenB, tokenA);
        require(token0 != address(0), "UniswapLibrary: ZERO_ADDRESS");
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(
        address tokenA,
        address tokenB,
        address factory
    ) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            hex"ff",
                            factory,
                            keccak256(abi.encodePacked(token0, token1)),
                            hex"0bbca9af0511ad1a1da383135cf3a8d2ac620e549ef9f6ae3a4c33c2fed0af91"
                        )
                    )
                )  
            )
        );
    }

    // fetches and sorts the reserves for a pair
    function getReserves(
        address tokenA,
        address tokenB,
        address factory
    ) internal view returns (uint256 reserveA, uint256 reserveB) {
        (address token0, ) = sortTokens(tokenA, tokenB);
        (uint256 reserve0, uint256 reserve1, ) = IUniswapPair(
            pairFor(tokenA, tokenB, factory)
        ).getReserves();
        (reserveA, reserveB) = tokenA == token0
            ? (reserve0, reserve1)
            : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) internal pure returns (uint256 amountB) {
        require(amountA > 0, "UniswapLibrary: INSUFFICIENT_AMOUNT");
        require(
            reserveA > 0 && reserveB > 0,
            "UniswapLibrary: INSUFFICIENT_LIQUIDITY"
        );
        amountB = (amountA * reserveB) / reserveA;
    }
}

interface IERC20 {
    function decimals() external view returns (uint8);
}

contract PriceCalculatorAVAX {
    address constant public usdc = 0xB97EF9Ef8734C71904D8002F8b6Bc66Dd9c48a6E; // USDC ADDRESS
    address constant public factory = 0x9Ad6C38BE94206cA50bb0d90783181662f0Cfa10; // JOE FACTORY

    // returns the total $ value of the amount of tokens
    function getUSDValue(address token_, uint256 amount_) external view returns (uint256) {
        if (amount_ == 0) {
            return 0;
        }
        if (token_ == usdc) {
            return amount_;
        }
        return price(token_, usdc, amount_);
    }

    function price(address _token, address _quote, uint256 _amount) private view returns (uint256) {
        (uint256 reserve0, uint256 reserve1) = UniswapLibrary.getReserves(_token, _quote, factory);
        return UniswapLibrary.quote(_amount, reserve0, reserve1);
    }
}