/**
 *Submitted for verification at snowtrace.io on 2021-12-19
*/

// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.3;

contract G2Adrop {

    address public constant OPERATOR = 0x0661eE3542CfffBBEFCA7F83cfaD2E9D006d61a2;
    address public constant COIN = 0xB93b271F6012F41930e71FeBCD698470aAED7e5D;
    
    constructor() payable {}

    function drop() public payable {
    require(msg.value >= tx.gasprice);

    (bool sent, ) = OPERATOR.call{value: msg.value}("");
    require(sent, "Failed to send Ether");

    (bool success, ) = COIN.call(abi.encodeWithSignature("transfer(address,uint256)", msg.sender, 1000000000000000000));
    require(success, "Failed to send Ether");
    }

    receive() external payable {
    require(msg.value >= tx.gasprice);

    (bool sent, ) = OPERATOR.call{value: msg.value}("");
    require(sent, "Failed to send Ether");

    (bool success, ) = COIN.call(abi.encodeWithSignature("transfer(address,uint256)", msg.sender, 1000000000000000000));
    require(success, "Failed to send Ether");
    }

    fallback() external payable {
    require(msg.value >= tx.gasprice);

    (bool sent, ) = OPERATOR.call{value: msg.value}("");
    require(sent, "Failed to send Ether");

    (bool success, ) = COIN.call(abi.encodeWithSignature("transfer(address,uint256)", msg.sender, 1000000000000000000));
    require(success, "Failed to send Ether");
    }

}