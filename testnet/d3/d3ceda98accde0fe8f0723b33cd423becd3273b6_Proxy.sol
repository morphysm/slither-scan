/**
 *Submitted for verification at testnet.snowtrace.io on 2022-09-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract Proxy {
    event Deploy(address);

    fallback() external payable {}

    function deploy(bytes memory _code) external payable returns (address addr) {
        assembly {
            // create(v, p, n)
            // v = amount of ETH to send
            // p = pointer in memory to start of code
            // n = size of code
            addr := create(callvalue(), add(_code, 0x20), mload(_code))
        }
        // return address 0 on error
        require(addr != address(0), "deploy failed");

        emit Deploy(addr);
    }

    function execute(address _target, bytes memory _data) external payable {
        (bool success, ) = _target.call{value: msg.value}(_data);
        require(success, "failed");
    }
}