// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.4;

import './TableMultisig.sol';
import './IRicardianLLC.sol';

/// @notice Factory to deploy Kali DAO.
contract RoundtableFactory is Multicall {
    event DAOdeployed(
        TableMultisig indexed tableMultisig,
        string name,
        string symbol,
        string docs,
        bool paused,
        address[] extensions,
        bytes[] extensionsData,
        address[] voters,
        uint256[] shares,
        uint32 votingPeriod,
        uint8[13] govSettings
    );

    error NullDeploy();

    address payable public immutable roundtableMaster;

    IRicardianLLC public immutable ricardianLLC;

    constructor(address payable roundtableMaster_, IRicardianLLC ricardianLLC_) {
        roundtableMaster = roundtableMaster_;

        ricardianLLC = ricardianLLC_;
    }

    function deployTable(
        string memory name_,
        string memory symbol_,
        string memory docs_,
        bool paused_,
        address[] memory extensions_,
        bytes[] memory extensionsData_,
        address[] calldata voters_,
        uint256[] calldata shares_,
        uint32 votingPeriod_,
        uint8[13] memory govSettings_
    ) public payable virtual returns (TableMultisig tableMultisig) {
        tableMultisig = TableMultisig(_cloneAsMinimalProxy(roundtableMaster, name_));

        tableMultisig.init{value: msg.value}(
            name_,
            symbol_,
            docs_,
            paused_,
            extensions_,
            extensionsData_,
            voters_,
            shares_,
            votingPeriod_,
            govSettings_
        );

        bytes memory docs = bytes(docs_);

        if (docs.length == 0) {
            ricardianLLC.mintLLC(address(tableMultisig));
        }

        emit DAOdeployed(
            tableMultisig,
            name_,
            symbol_,
            docs_,
            paused_,
            extensions_,
            extensionsData_,
            voters_,
            shares_,
            votingPeriod_,
            govSettings_
        );
    }

    /// @dev modified from Aelin (https://github.com/AelinXYZ/aelin/blob/main/contracts/MinimalProxyFactory.sol)
    function _cloneAsMinimalProxy(address payable base, string memory name_)
        internal
        virtual
        returns (address payable clone)
    {
        bytes memory createData = abi.encodePacked(
            // constructor
            bytes10(0x3d602d80600a3d3981f3),
            // proxy code
            bytes10(0x363d3d373d3d3d363d73),
            base,
            bytes15(0x5af43d82803e903d91602b57fd5bf3)
        );

        bytes32 salt = keccak256(bytes(name_));

        assembly {
            clone := create2(
                0, // no value
                add(createData, 0x20), // data
                mload(createData),
                salt
            )
        }
        // if CREATE2 fails for some reason, address(0) is returned
        if (clone == address(0)) revert NullDeploy();
    }
}