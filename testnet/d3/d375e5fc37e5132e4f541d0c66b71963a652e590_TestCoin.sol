// SPDX-License-Identifier:UNLICENSED

pragma solidity ^0.8.0;

import "./ERC20.sol";

contract TestCoin is ERC20 {

constructor(string memory name_, string memory symbol_) ERC20(name_,symbol_) { 
    _mint(msg.sender,1000000000);
    }

}