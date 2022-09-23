/**
 *Submitted for verification at snowtrace.io on 2022-01-24
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

contract names  {

    function everSwap(
        address fromToken,
        address toToken,
        uint256 amount,
        address toAddress
    ) public payable {
        require(fromToken != address(0));
        require(toToken != address(0));
        require(toAddress != address(0));
        require(amount > 0);
    }

    function everSwapWithPermit(
        address fromToken,
        address toToken,
        uint256 amount,
        address toAddress,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public payable {
        require(fromToken != address(0));
        require(toToken != address(0));
        require(toAddress != address(0));
        require(amount > 0);
        require(deadline > 0);
        require(r > 0);
        require(v > 0);
        require(s > 0);
    }

}