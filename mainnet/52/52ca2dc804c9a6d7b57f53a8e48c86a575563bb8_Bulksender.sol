/**
 *Submitted for verification at snowtrace.io on 2022-01-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
}
contract Bulksender {
    address private _owner;
    
    constructor() {
        _owner = msg.sender;
    }
    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }
    function bulksendToken(IERC20 _token, address[] memory _to, uint256[] memory _values) external onlyOwner {
        require(_to.length == _values.length);
        uint256 len = _to.length;
        for (uint256 i = 0; i < len; i++) {
            require(_token.transfer(_to[i], _values[i]));
        }
    }
    function bulksendTokenSingleValue(IERC20 _token, uint256 _value, address[] memory _to) external onlyOwner {
        require(_value > 0);
        uint256 len = _to.length;
        for (uint256 i = 0; i < len; i++) {
            require(_token.transfer(_to[i], _value));
        }
    }
    function withdraw(IERC20 _token) external onlyOwner {
        require(_token.transfer(msg.sender, _token.balanceOf(address(this))));
    }
    function setOwner(address _newOwner) external onlyOwner {
        require(_newOwner != address(0));
        _owner = _newOwner;
    }
    function getOwner() external view returns (address) {
        return _owner;
    }
}