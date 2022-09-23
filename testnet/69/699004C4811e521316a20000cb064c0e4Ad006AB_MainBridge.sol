// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

//Remix style import
import "./IERC20.sol";

contract MainBridge {

    IERC20 private mainToken;
    bool bridgeInitState;
    address gateway;
    address owner;

    event TokensLocked(address indexed requester, bytes32 indexed mainDepositHash, uint amount, uint timestamp);
    event TokensUnlocked(address indexed requester, bytes32 indexed sideDepositHash, uint amount, uint timestamp);

    constructor (address _mainToken, address _gateway) {
        mainToken = IERC20(_mainToken);
        gateway = _gateway;
        owner = msg.sender;
    }

    function lockTokens (address _requester, uint _bridgedAmount, bytes32 _mainDepositHash) onlyGateway external {
        emit TokensLocked(_requester, _mainDepositHash, _bridgedAmount, block.timestamp);
    }

    function unlockTokens (address _requester, uint _bridgedAmount, bytes32 _sideDepositHash) onlyGateway external {
        mainToken.transfer(_requester, _bridgedAmount);
        emit TokensUnlocked(_requester, _sideDepositHash, _bridgedAmount, block.timestamp);
    }


    modifier onlyGateway {
        require(msg.sender == gateway, "Only gateway can execute this function");
        _;
    }

}