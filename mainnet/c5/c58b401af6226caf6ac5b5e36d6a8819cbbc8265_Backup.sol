/**
 *Submitted for verification at snowtrace.io on 2022-03-29
*/

// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.8.13;

contract Backup {
    mapping(address => bytes) public backups;

    function backup(bytes calldata ciphertext) external {
        backups[msg.sender] = ciphertext;
    }
}