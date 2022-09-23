// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.4;

import './ERC721.sol';

// import "./utils/Multicall.sol";

/// @notice Roundtable Ricardian LLC NFT minter.
contract RoundtableRicardianLLC is ERC721 {
    error NotGovernance();

    error NotFee();

    error ETHtransferFailed();

    address public governance;

    string public commonURI;

    string public masterOperatingAgreement;

    uint256 public mintFee;

    mapping(uint256 => string) public tokenDetails;

    modifier onlyGovernance() {
        if (msg.sender != governance) revert NotGovernance();
        _;
    }

    constructor(
        string memory name_,
        string memory symbol_,
        string memory commonURI_,
        string memory masterOperatingAgreement_,
        uint256 mintFee_
    ) ERC721(name_, symbol_) {
        governance = msg.sender;

        commonURI = commonURI_;

        masterOperatingAgreement = masterOperatingAgreement_;

        mintFee = mintFee_;
    }

    function tokenURI(uint256) public view virtual override returns (string memory) {
        return commonURI;
    }

    function mintLLC(address to) public payable virtual {
        if (msg.value != mintFee) revert NotFee();

        uint256 tokenId = totalSupply;

        _mint(to, tokenId);
    }

    receive() external payable virtual {
        mintLLC(msg.sender);
    }

    function burn(uint256 tokenId) public virtual {
        if (msg.sender != ownerOf[tokenId]) revert NotOwner();

        _burn(tokenId);
    }

    function updateTokenDetails(uint256 tokenId, string calldata details) public virtual {
        if (msg.sender != ownerOf[tokenId]) revert NotOwner();

        tokenDetails[tokenId] = details;
    }

    /*///////////////////////////////////////////////////////////////
                            GOV LOGIC
    //////////////////////////////////////////////////////////////*/

    function govMint(address to) public virtual onlyGovernance {
        uint256 tokenId = totalSupply;

        _mint(to, tokenId);
    }

    function govBurn(uint256 tokenId) public virtual onlyGovernance {
        _burn(tokenId);
    }

    function updateGov(address governance_) public virtual onlyGovernance {
        governance = governance_;
    }

    function updateURI(string calldata commonURI_) public virtual onlyGovernance {
        commonURI = commonURI_;
    }

    function updateAgreement(string calldata masterOperatingAgreement_)
        public
        virtual
        onlyGovernance
    {
        masterOperatingAgreement = masterOperatingAgreement_;
    }

    function updateFee(uint256 mintFee_) public virtual onlyGovernance {
        mintFee = mintFee_;
    }

    function collectFee() public virtual onlyGovernance {
        _safeTransferETH(governance, address(this).balance);
    }

    function _safeTransferETH(address to, uint256 amount) internal {
        bool callStatus;

        assembly {
            // transfer the ETH and store if it succeeded or not
            callStatus := call(gas(), to, amount, 0, 0, 0, 0)
        }

        if (!callStatus) revert ETHtransferFailed();
    }
}