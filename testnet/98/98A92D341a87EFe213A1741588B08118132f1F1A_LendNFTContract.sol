pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT

import "../core/DaoRegistry.sol";
import "../extensions/nft/NFT.sol";
import "../extensions/erc1155/ERC1155TokenExtension.sol";
import "../extensions/token/erc20/InternalTokenVestingExtension.sol";
import "../adapters/interfaces/IVoting.sol";
import "../helpers/DaoHelper.sol";
import "../guards/AdapterGuard.sol";
import "./modifiers/Reimbursable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

/**
MIT License

Copyright (c) 2021 Openlaw

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
 */

contract LendNFTContract is
    AdapterGuard,
    Reimbursable,
    IERC1155Receiver,
    IERC721Receiver
{
    struct ProcessProposal {
        DaoRegistry dao;
        bytes32 proposalId;
    }

    struct ProposalDetails {
        // The proposal id.
        bytes32 id;
        // The applicant address (who will receive the DAO internal tokens and
        // become a member; this address may be different than the actual owner
        // of the ERC-721 token being provided as tribute).
        address applicant;
        // The address of the ERC-721 or ERC-1155 token that will be transferred to the DAO
        // in exchange for DAO internal tokens.
        address nftAddr;
        // The nft token identifier.
        uint256 nftTokenId;
        uint256 tributeAmount;
        // The amount requested of DAO internal tokens (UNITS).
        uint88 requestAmount;
        // The lending period in milliseconds.
        uint64 lendingPeriod;
        bool sentBack;
        uint64 lendingStart;
        address previousOwner;
    }

    // Keeps track of all nft tribute proposals handled by each DAO.
    mapping(address => mapping(bytes32 => ProposalDetails)) public proposals;

    /**
     * @notice Configures the adapter for a particular DAO.
     * @notice Registers the DAO internal token with the DAO Bank.
     * @dev Only adapters registered to the DAO can execute the function call (or if the DAO is in creation mode).
     * @dev A DAO Bank extension must exist and be configured with proper access for this adapter.
     * @param dao The DAO address.
     * @param token The token address that will be configured as internal token.
     */
    function configureDao(DaoRegistry dao, address token)
        external
        onlyAdapter(dao)
    {
        BankExtension(dao.getExtensionAddress(DaoHelper.BANK))
            .registerPotentialNewInternalToken(dao, token);
    }

    /**
     * @notice Creates and sponsors a tribute proposal to start the voting process.
     * @dev Applicant address must not be reserved.
     * @dev Only members of the DAO can sponsor a tribute proposal.
     * @param dao The DAO address.
     * @param proposalId The proposal id (managed by the client).
     * @param applicant The applicant address (who will receive the DAO internal tokens and become a member).
     * @param nftAddr The address of the ERC-721 token that will be transferred to the DAO in exchange for DAO internal tokens.
     * @param nftTokenId The NFT token id.
     * @param requestAmount The amount requested of DAO internal tokens (UNITS).
     * @param data Additional information related to the tribute proposal.
     */
    // slither-disable-next-line reentrancy-benign
    function submitProposal(
        DaoRegistry dao,
        bytes32 proposalId,
        address applicant,
        address nftAddr,
        uint256 nftTokenId,
        uint88 requestAmount,
        uint64 lendingPeriod,
        bytes memory data
    ) external reimbursable(dao) {
        require(
            DaoHelper.isNotReservedAddress(applicant),
            "applicant is reserved address"
        );

        dao.submitProposal(proposalId);
        IVoting votingContract = IVoting(
            dao.getAdapterAddress(DaoHelper.VOTING)
        );
        address sponsoredBy = votingContract.getSenderAddress(
            dao,
            address(this),
            data,
            msg.sender
        );
        dao.sponsorProposal(proposalId, sponsoredBy, address(votingContract));
        DaoHelper.potentialNewMember(
            applicant,
            dao,
            BankExtension(dao.getExtensionAddress(DaoHelper.BANK))
        );

        votingContract.startNewVotingForProposal(dao, proposalId, data);

        proposals[address(dao)][proposalId] = ProposalDetails(
            proposalId,
            applicant,
            nftAddr,
            nftTokenId,
            0,
            requestAmount,
            lendingPeriod,
            false,
            0,
            address(0x0)
        );
    }

    /**
     * @notice Processes the proposal to handle minting and exchange of DAO internal tokens for tribute token (passed vote).
     * @dev Proposal id must exist.
     * @dev Only proposals that have not already been processed are accepted.
     * @dev Only sponsored proposals with completed voting are accepted.
     * @dev The owner of the ERC-721 token provided as tribute must first separately `approve` the NFT extension as spender of that token (so the NFT can be transferred for a passed vote).
     * @param dao The DAO address.
     * @param proposalId The proposal id.
     */
    // The function can be called only from the _onERC1155Received & _onERC721Received functions
    // Which are protected against reentrancy attacks.
    //slither-disable-next-line reentrancy-no-eth
    function _processProposal(DaoRegistry dao, bytes32 proposalId)
        internal
        returns (
            ProposalDetails storage proposal,
            IVoting.VotingState voteResult
        )
    {
        proposal = proposals[address(dao)][proposalId];
        //slither-disable-next-line timestamp
        require(proposal.id == proposalId, "proposal does not exist");
        require(
            !dao.getProposalFlag(
                proposalId,
                DaoRegistry.ProposalFlag.PROCESSED
            ),
            "proposal already processed"
        );

        IVoting votingContract = IVoting(dao.votingAdapter(proposalId));
        require(address(votingContract) != address(0), "adapter not found");

        voteResult = votingContract.voteResult(dao, proposalId);

        dao.processProposal(proposalId);
        //if proposal passes and its an erc721 token - use NFT Extension
        if (voteResult == IVoting.VotingState.PASS) {
            BankExtension bank = BankExtension(
                dao.getExtensionAddress(DaoHelper.BANK)
            );

            require(
                bank.isInternalToken(DaoHelper.UNITS),
                "UNITS token is not an internal token"
            );

            bank.addToBalance(
                dao,
                proposal.applicant,
                DaoHelper.UNITS,
                proposal.requestAmount
            );

            InternalTokenVestingExtension vesting = InternalTokenVestingExtension(
                    dao.getExtensionAddress(
                        DaoHelper.INTERNAL_TOKEN_VESTING_EXT
                    )
                );
            //slither-disable-next-line timestamp
            proposal.lendingStart = uint64(block.timestamp);
            //add vesting here
            vesting.createNewVesting(
                dao,
                proposal.applicant,
                DaoHelper.UNITS,
                proposal.requestAmount,
                proposal.lendingStart + proposal.lendingPeriod
            );

            return (proposal, voteResult);
        } else if (
            voteResult == IVoting.VotingState.NOT_PASS ||
            voteResult == IVoting.VotingState.TIE
        ) {
            return (proposal, voteResult);
        } else {
            revert("proposal has no votes");
        }
    }

    /**
     * @notice Sends the NFT back to the original owner.
     */
    // slither-disable-next-line reentrancy-benign
    function sendNFTBack(DaoRegistry dao, bytes32 proposalId)
        external
        reimbursable(dao)
    {
        ProposalDetails storage proposal = proposals[address(dao)][proposalId];
        require(proposal.lendingStart > 0, "lending not started");
        require(!proposal.sentBack, "already sent back");
        require(
            msg.sender == proposal.previousOwner,
            "only the previous owner can withdraw the NFT"
        );

        proposal.sentBack = true;
        //slither-disable-next-line timestamp
        uint256 elapsedTime = block.timestamp - proposal.lendingStart;
        //slither-disable-next-line timestamp
        if (elapsedTime < proposal.lendingPeriod) {
            InternalTokenVestingExtension vesting = InternalTokenVestingExtension(
                    dao.getExtensionAddress(
                        DaoHelper.INTERNAL_TOKEN_VESTING_EXT
                    )
                );

            uint256 blockedAmount = vesting.getMinimumBalanceInternal(
                proposal.lendingStart,
                proposal.lendingStart + proposal.lendingPeriod,
                proposal.requestAmount
            );

            BankExtension(dao.getExtensionAddress(DaoHelper.BANK))
                .subtractFromBalance(
                    dao,
                    proposal.applicant,
                    DaoHelper.UNITS,
                    blockedAmount
                );
            vesting.removeVesting(
                dao,
                proposal.applicant,
                DaoHelper.UNITS,
                uint88(blockedAmount)
            );
        }

        // Only ERC-721 tokens will contain tributeAmount == 0
        if (proposal.tributeAmount == 0) {
            NFTExtension(dao.getExtensionAddress(DaoHelper.NFT)).withdrawNFT(
                dao,
                proposal.previousOwner,
                proposal.nftAddr,
                proposal.nftTokenId
            );
        } else {
            ERC1155TokenExtension(
                dao.getExtensionAddress(DaoHelper.ERC1155_EXT)
            ).withdrawNFT(
                    dao,
                    DaoHelper.GUILD,
                    proposal.previousOwner,
                    proposal.nftAddr,
                    proposal.nftTokenId,
                    proposal.tributeAmount
                );
        }
    }

    /**
     *  @notice required function from IERC1155 standard to be able to to receive tokens
     */
    function onERC1155Received(
        address,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external override returns (bytes4) {
        ProcessProposal memory ppS = abi.decode(data, (ProcessProposal));
        return _onERC1155Received(ppS.dao, ppS.proposalId, from, id, value);
    }

    function _onERC1155Received(
        DaoRegistry dao,
        bytes32 proposalId,
        address from,
        uint256 id,
        uint256 value
    ) internal returns (bytes4) {
        ReimbursementData memory rData = ReimbursableLib.beforeExecution(dao);

        (
            ProposalDetails storage proposal,
            IVoting.VotingState voteResult
        ) = _processProposal(dao, proposalId);

        require(proposal.nftTokenId == id, "wrong NFT");
        require(proposal.nftAddr == msg.sender, "wrong NFT addr");
        proposal.tributeAmount = value;
        proposal.previousOwner = from;

        // Strict matching is expect to ensure the vote has passed.
        // slither-disable-next-line incorrect-equality,timestamp
        if (voteResult == IVoting.VotingState.PASS) {
            address erc1155ExtAddr = dao.getExtensionAddress(
                DaoHelper.ERC1155_EXT
            );

            IERC1155(msg.sender).safeTransferFrom(
                address(this),
                erc1155ExtAddr,
                id,
                value,
                ""
            );
        } else {
            IERC1155(msg.sender).safeTransferFrom(
                address(this),
                from,
                id,
                value,
                ""
            );
        }

        ReimbursableLib.afterExecution2(dao, rData, payable(from));

        return this.onERC1155Received.selector;
    }

    /**
     *  @notice required function from IERC1155 standard to be able to to batch receive tokens
     */
    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external pure override returns (bytes4) {
        revert("not supported");
    }

    function onERC721Received(
        address,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external override returns (bytes4) {
        ProcessProposal memory ppS = abi.decode(data, (ProcessProposal));
        return _onERC721Received(ppS.dao, ppS.proposalId, from, tokenId);
    }

    function _onERC721Received(
        DaoRegistry dao,
        bytes32 proposalId,
        address from,
        uint256 tokenId
    ) internal returns (bytes4) {
        ReimbursementData memory rData = ReimbursableLib.beforeExecution(dao);

        (
            ProposalDetails storage proposal,
            IVoting.VotingState voteResult
        ) = _processProposal(dao, proposalId);

        require(proposal.nftTokenId == tokenId, "wrong NFT");
        require(proposal.nftAddr == msg.sender, "wrong NFT addr");
        proposal.tributeAmount = 0;
        proposal.previousOwner = from;
        IERC721 erc721 = IERC721(msg.sender);

        // Strict matching is expect to ensure the vote has passed
        // slither-disable-next-line incorrect-equality,timestamp
        if (voteResult == IVoting.VotingState.PASS) {
            NFTExtension nftExt = NFTExtension(
                dao.getExtensionAddress(DaoHelper.NFT)
            );
            erc721.approve(address(nftExt), proposal.nftTokenId);
            nftExt.collect(dao, proposal.nftAddr, proposal.nftTokenId);
        } else {
            erc721.safeTransferFrom(address(this), from, tokenId);
        }
        ReimbursableLib.afterExecution2(dao, rData, payable(from));
        return this.onERC721Received.selector;
    }

    /**
     * @notice Supports ERC-165 & ERC-1155 interfaces only.
     * @dev https://github.com/ethereum/EIPs/blob/master/EIPS/eip-1155.md
     */
    function supportsInterface(bytes4 interfaceID)
        external
        pure
        override
        returns (bool)
    {
        return
            interfaceID == this.supportsInterface.selector ||
            interfaceID == this.onERC1155Received.selector ||
            interfaceID == this.onERC721Received.selector;
    }
}

pragma solidity ^0.8.0;
import "../extensions/bank/Bank.sol";
import "../core/DaoRegistry.sol";

// SPDX-License-Identifier: MIT

/**
MIT License

Copyright (c) 2021 Openlaw

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
 */
library DaoHelper {
    // Adapters
    bytes32 internal constant VOTING = keccak256("voting");
    bytes32 internal constant ONBOARDING = keccak256("onboarding");
    bytes32 internal constant NONVOTING_ONBOARDING =
        keccak256("nonvoting-onboarding");
    bytes32 internal constant TRIBUTE = keccak256("tribute");
    bytes32 internal constant FINANCING = keccak256("financing");
    bytes32 internal constant MANAGING = keccak256("managing");
    bytes32 internal constant RAGEQUIT = keccak256("ragequit");
    bytes32 internal constant GUILDKICK = keccak256("guildkick");
    bytes32 internal constant CONFIGURATION = keccak256("configuration");
    bytes32 internal constant DISTRIBUTE = keccak256("distribute");
    bytes32 internal constant TRIBUTE_NFT = keccak256("tribute-nft");
    bytes32 internal constant REIMBURSEMENT = keccak256("reimbursement");
    bytes32 internal constant TRANSFER_STRATEGY =
        keccak256("erc20-transfer-strategy");
    bytes32 internal constant DAO_REGISTRY_ADAPT = keccak256("daoRegistry");
    bytes32 internal constant BANK_ADAPT = keccak256("bank");
    bytes32 internal constant ERC721_ADAPT = keccak256("nft");
    bytes32 internal constant ERC1155_ADAPT = keccak256("erc1155-adpt");
    bytes32 internal constant ERC1271_ADAPT = keccak256("signatures");
    bytes32 internal constant SNAPSHOT_PROPOSAL_ADPT =
        keccak256("snapshot-proposal-adpt");
    bytes32 internal constant VOTING_HASH_ADPT = keccak256("voting-hash-adpt");
    bytes32 internal constant KICK_BAD_REPORTER_ADPT =
        keccak256("kick-bad-reporter-adpt");
    bytes32 internal constant COUPON_ONBOARDING_ADPT =
        keccak256("coupon-onboarding");
    bytes32 internal constant LEND_NFT_ADPT = keccak256("lend-nft");
    bytes32 internal constant ERC20_TRANSFER_STRATEGY_ADPT =
        keccak256("erc20-transfer-strategy");

    // Extensions
    bytes32 internal constant BANK = keccak256("bank");
    bytes32 internal constant ERC1271 = keccak256("erc1271");
    bytes32 internal constant NFT = keccak256("nft");
    bytes32 internal constant EXECUTOR_EXT = keccak256("executor-ext");
    bytes32 internal constant INTERNAL_TOKEN_VESTING_EXT =
        keccak256("internal-token-vesting-ext");
    bytes32 internal constant ERC1155_EXT = keccak256("erc1155-ext");
    bytes32 internal constant ERC20_EXT = keccak256("erc20-ext");

    // Reserved Addresses
    address internal constant GUILD = address(0xdead);
    address internal constant ESCROW = address(0x4bec);
    address internal constant TOTAL = address(0xbabe);
    address internal constant UNITS = address(0xFF1CE);
    address internal constant LOOT = address(0xB105F00D);
    address internal constant ETH_TOKEN = address(0x0);
    address internal constant MEMBER_COUNT = address(0xDECAFBAD);

    uint8 internal constant MAX_TOKENS_GUILD_BANK = 200;

    function totalTokens(BankExtension bank) internal view returns (uint256) {
        return memberTokens(bank, TOTAL) - memberTokens(bank, GUILD); //GUILD is accounted for twice otherwise
    }

    /**
     * @notice calculates the total number of units.
     */
    function priorTotalTokens(BankExtension bank, uint256 at)
        internal
        view
        returns (uint256)
    {
        return
            priorMemberTokens(bank, TOTAL, at) -
            priorMemberTokens(bank, GUILD, at);
    }

    function memberTokens(BankExtension bank, address member)
        internal
        view
        returns (uint256)
    {
        return bank.balanceOf(member, UNITS) + bank.balanceOf(member, LOOT);
    }

    function msgSender(DaoRegistry dao, address addr)
        internal
        view
        returns (address)
    {
        address memberAddress = dao.getAddressIfDelegated(addr);
        address delegatedAddress = dao.getCurrentDelegateKey(addr);

        require(
            memberAddress == delegatedAddress || delegatedAddress == addr,
            "call with your delegate key"
        );

        return memberAddress;
    }

    /**
     * @notice calculates the total number of units.
     */
    function priorMemberTokens(
        BankExtension bank,
        address member,
        uint256 at
    ) internal view returns (uint256) {
        return
            bank.getPriorAmount(member, UNITS, at) +
            bank.getPriorAmount(member, LOOT, at);
    }

    //helper
    function getFlag(uint256 flags, uint256 flag) internal pure returns (bool) {
        return (flags >> uint8(flag)) % 2 == 1;
    }

    function setFlag(
        uint256 flags,
        uint256 flag,
        bool value
    ) internal pure returns (uint256) {
        if (getFlag(flags, flag) != value) {
            if (value) {
                return flags + 2**flag;
            } else {
                return flags - 2**flag;
            }
        } else {
            return flags;
        }
    }

    /**
     * @notice Checks if a given address is reserved.
     */
    function isNotReservedAddress(address addr) internal pure returns (bool) {
        return addr != GUILD && addr != TOTAL && addr != ESCROW;
    }

    /**
     * @notice Checks if a given address is zeroed.
     */
    function isNotZeroAddress(address addr) internal pure returns (bool) {
        return addr != address(0x0);
    }

    function potentialNewMember(
        address memberAddress,
        DaoRegistry dao,
        BankExtension bank
    ) internal {
        dao.potentialNewMember(memberAddress);
        require(memberAddress != address(0x0), "invalid member address");
        if (address(bank) != address(0x0)) {
            if (bank.balanceOf(memberAddress, MEMBER_COUNT) == 0) {
                bank.addToBalance(dao, memberAddress, MEMBER_COUNT, 1);
            }
        }
    }

    /**
     * A DAO is in creation mode is the state of the DAO is equals to CREATION and
     * 1. The number of members in the DAO is ZERO or,
     * 2. The sender of the tx is a DAO member (usually the DAO owner) or,
     * 3. The sender is an adapter.
     */
    // slither-disable-next-line calls-loop
    function isInCreationModeAndHasAccess(DaoRegistry dao)
        internal
        view
        returns (bool)
    {
        return
            dao.state() == DaoRegistry.DaoState.CREATION &&
            (dao.getNbMembers() == 0 ||
                dao.isMember(msg.sender) ||
                dao.isAdapter(msg.sender));
    }
}

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT

import "../core/DaoRegistry.sol";
import "../extensions/bank/Bank.sol";
import "../helpers/DaoHelper.sol";

/**
MIT License

Copyright (c) 2020 Openlaw

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
 */
abstract contract MemberGuard {
    /**
     * @dev Only members of the DAO are allowed to execute the function call.
     */
    modifier onlyMember(DaoRegistry dao) {
        _onlyMember(dao, msg.sender);
        _;
    }

    modifier onlyMember2(DaoRegistry dao, address _addr) {
        _onlyMember(dao, _addr);
        _;
    }

    function _onlyMember(DaoRegistry dao, address _addr) internal view {
        require(isActiveMember(dao, _addr), "onlyMember");
    }

    function isActiveMember(DaoRegistry dao, address _addr)
        public
        view
        returns (bool)
    {
        address bankAddress = dao.extensions(DaoHelper.BANK);
        if (bankAddress != address(0x0)) {
            address memberAddr = DaoHelper.msgSender(dao, _addr);
            return
                dao.isMember(_addr) &&
                BankExtension(bankAddress).balanceOf(
                    memberAddr,
                    DaoHelper.UNITS
                ) >
                0;
        }

        return dao.isMember(_addr);
    }
}

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT

import "../core/DaoRegistry.sol";
import "../helpers/DaoHelper.sol";

/**
MIT License

Copyright (c) 2020 Openlaw

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
 */
abstract contract AdapterGuard {
    /**
     * @dev Only registered adapters are allowed to execute the function call.
     */
    modifier onlyAdapter(DaoRegistry dao) {
        require(
            dao.isAdapter(msg.sender) ||
                DaoHelper.isInCreationModeAndHasAccess(dao),
            "onlyAdapter"
        );
        _;
    }

    modifier reentrancyGuard(DaoRegistry dao) {
        require(dao.lockedAt() != block.number, "reentrancy guard");
        dao.lockSession();
        _;
        dao.unlockSession();
    }

    modifier executorFunc(DaoRegistry dao) {
        address executorAddr = dao.getExtensionAddress(
            keccak256("executor-ext")
        );
        require(address(this) == executorAddr, "only callable by the executor");
        _;
    }

    modifier hasAccess(DaoRegistry dao, DaoRegistry.AclFlag flag) {
        require(
            DaoHelper.isInCreationModeAndHasAccess(dao) ||
                dao.hasAdapterAccess(msg.sender, flag),
            "accessDenied"
        );
        _;
    }
}

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT
import "../../../core/DaoRegistry.sol";
import "../../../extensions/IExtension.sol";
import "../../../helpers/DaoHelper.sol";

/**
MIT License

Copyright (c) 2021 Openlaw

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
 */
contract InternalTokenVestingExtension is IExtension {
    enum AclFlag {
        NEW_VESTING,
        REMOVE_VESTING
    }

    bool public initialized;

    DaoRegistry private _dao;

    struct VestingSchedule {
        uint64 startDate;
        uint64 endDate;
        uint88 blockedAmount;
    }

    modifier hasExtensionAccess(DaoRegistry dao, AclFlag flag) {
        require(
            dao == _dao &&
                (DaoHelper.isInCreationModeAndHasAccess(dao) ||
                    !initialized ||
                    _dao.hasAdapterAccessToExtension(
                        msg.sender,
                        address(this),
                        uint8(flag)
                    )),
            "vestingExt::accessDenied"
        );

        _;
    }

    mapping(address => mapping(address => VestingSchedule)) public vesting;

    /// @notice Clonable contract must have an empty constructor
    constructor() {}

    /**
     * @notice Initializes the extension with the DAO that it belongs to.
     * @param dao The address of the DAO that owns the extension.
     */
    function initialize(DaoRegistry dao, address) external override {
        require(!initialized, "already initialized");
        initialized = true;
        _dao = dao;
    }

    /**
     * @notice Creates a new vesting schedule for a member based on the internal token, amount and end date.
     * @param member The member address to update the balance.
     * @param internalToken The internal DAO token in which the member will receive the funds.
     * @param amount The amount staked.
     * @param endDate The unix timestamp in which the vesting schedule ends.
     */
    function createNewVesting(
        DaoRegistry dao,
        address member,
        address internalToken,
        uint88 amount,
        uint64 endDate
    ) external hasExtensionAccess(dao, AclFlag.NEW_VESTING) {
        //slither-disable-next-line timestamp
        require(endDate > block.timestamp, "vestingExt::end date in the past");
        VestingSchedule storage schedule = vesting[member][internalToken];
        uint88 minBalance = getMinimumBalanceInternal(
            schedule.startDate,
            schedule.endDate,
            schedule.blockedAmount
        );

        schedule.startDate = uint64(block.timestamp);
        //get max value between endDate and previous one
        if (endDate > schedule.endDate) {
            schedule.endDate = endDate;
        }

        schedule.blockedAmount = minBalance + amount;
    }

    /**
     * @notice Updates a vesting schedule of a member based on the internal token, and amount.
     * @param member The member address to update the balance.
     * @param internalToken The internal DAO token in which the member will receive the funds.
     * @param amountToRemove The amount to be removed.
     */
    function removeVesting(
        DaoRegistry dao,
        address member,
        address internalToken,
        uint88 amountToRemove
    ) external hasExtensionAccess(dao, AclFlag.REMOVE_VESTING) {
        VestingSchedule storage schedule = vesting[member][internalToken];
        uint88 blockedAmount = getMinimumBalanceInternal(
            schedule.startDate,
            schedule.endDate,
            schedule.blockedAmount
        );

        schedule.startDate = uint64(block.timestamp);
        schedule.blockedAmount = blockedAmount - amountToRemove;
    }

    /**
     * @notice Returns the minimum balance of the vesting for a given member and internal token.
     * @param member The member address to update the balance.
     * @param internalToken The internal DAO token in which the member will receive the funds.
     */
    function getMinimumBalance(address member, address internalToken)
        external
        view
        returns (uint88)
    {
        VestingSchedule storage schedule = vesting[member][internalToken];
        return
            getMinimumBalanceInternal(
                schedule.startDate,
                schedule.endDate,
                schedule.blockedAmount
            );
    }

    /**
     * @notice Returns the minimum balance of the vesting for a given start date, end date, and amount.
     * @param startDate The start date of the vesting to calculate the elapsed time.
     * @param endDate The end date of the vesting to calculate the vesting period.
     * @param amount The amount staked.
     */
    function getMinimumBalanceInternal(
        uint64 startDate,
        uint64 endDate,
        uint88 amount
    ) public view returns (uint88) {
        //slither-disable-next-line timestamp
        if (block.timestamp > endDate) {
            return 0;
        }

        uint88 period = endDate - startDate;
        //slither-disable-next-line timestamp
        uint88 elapsedTime = uint88(block.timestamp) - startDate;

        uint88 vestedAmount = (amount * elapsedTime) / period;

        return amount - vestedAmount;
    }
}

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT

import "../../core/DaoRegistry.sol";
import "../IExtension.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

/**
MIT License

Copyright (c) 2020 Openlaw

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
 */

contract NFTExtension is IExtension, IERC721Receiver {
    // Add the library methods
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableSet for EnumerableSet.AddressSet;

    bool public initialized = false; // internally tracks deployment under eip-1167 proxy pattern
    DaoRegistry public dao;

    enum AclFlag {
        WITHDRAW_NFT,
        COLLECT_NFT,
        INTERNAL_TRANSFER
    }

    event CollectedNFT(address nftAddr, uint256 nftTokenId);
    event TransferredNFT(
        address nftAddr,
        uint256 nftTokenId,
        address oldOwner,
        address newOwner
    );
    event WithdrawnNFT(address nftAddr, uint256 nftTokenId, address toAddress);

    // All the Token IDs that belong to an NFT address stored in the GUILD collection
    mapping(address => EnumerableSet.UintSet) private _nfts;

    // The internal owner of record of an NFT that has been transferred to the extension
    mapping(bytes32 => address) private _ownership;

    // All the NFTs addresses collected and stored in the GUILD collection
    EnumerableSet.AddressSet private _nftAddresses;

    modifier hasExtensionAccess(DaoRegistry _dao, AclFlag flag) {
        require(
            dao == _dao &&
                (DaoHelper.isInCreationModeAndHasAccess(dao) ||
                    !initialized ||
                    dao.hasAdapterAccessToExtension(
                        msg.sender,
                        address(this),
                        uint8(flag)
                    )),
            "erc721::accessDenied"
        );
        _;
    }

    /// @notice Clonable contract must have an empty constructor
    constructor() {}

    /**
     * @notice Initializes the extension with the DAO address that it belongs to.
     * @param _dao The address of the DAO that owns the extension.
     */
    function initialize(DaoRegistry _dao, address) external override {
        require(!initialized, "already initialized");
        initialized = true;
        dao = _dao;
    }

    /**
     * @notice Collects the NFT from the owner and moves it to the NFT extension.
     * @notice It must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * @dev Reverts if the NFT is not in ERC721 standard.
     * @param nftAddr The NFT contract address.
     * @param nftTokenId The NFT token id.
     */
    // slither-disable-next-line reentrancy-benign
    function collect(
        DaoRegistry _dao,
        address nftAddr,
        uint256 nftTokenId
    ) external hasExtensionAccess(_dao, AclFlag.COLLECT_NFT) {
        IERC721 erc721 = IERC721(nftAddr);
        address currentOwner = erc721.ownerOf(nftTokenId);
        //If the NFT is already in the NFTExtension, update the ownership if not set already
        if (currentOwner == address(this)) {
            if (_ownership[getNFTId(nftAddr, nftTokenId)] == address(0x0)) {
                _saveNft(nftAddr, nftTokenId, DaoHelper.GUILD);
                // slither-disable-next-line reentrancy-events
                emit CollectedNFT(nftAddr, nftTokenId);
            }
        } else {
            //If the NFT is not in the NFTExtension, we try to transfer from the current owner of the NFT to the extension
            _saveNft(nftAddr, nftTokenId, DaoHelper.GUILD);
            erc721.safeTransferFrom(currentOwner, address(this), nftTokenId);
            // slither-disable-next-line reentrancy-events
            emit CollectedNFT(nftAddr, nftTokenId);
        }
    }

    /**
     * @notice Transfers the NFT token from the extension address to the new owner.
     * @notice It also updates the internal state to keep track of the all the NFTs collected by the extension.
     * @notice The caller must have the ACL Flag: WITHDRAW_NFT
     * @notice TODO This function needs to be called from a new adapter (RagequitNFT) that will manage the Bank balances, and will return the NFT to the owner.
     * @dev Reverts if the NFT is not in ERC721 standard.
     * @param newOwner The address of the new owner.
     * @param nftAddr The NFT address that must be in ERC721 standard.
     * @param nftTokenId The NFT token id.
     */
    // slither-disable-next-line reentrancy-benign
    function withdrawNFT(
        DaoRegistry _dao,
        address newOwner,
        address nftAddr,
        uint256 nftTokenId
    ) external hasExtensionAccess(_dao, AclFlag.WITHDRAW_NFT) {
        // Remove the NFT from the contract address to the actual owner
        require(
            _nfts[nftAddr].remove(nftTokenId),
            "erc721::can not remove token id"
        );
        IERC721(nftAddr).safeTransferFrom(address(this), newOwner, nftTokenId);
        // Remove the asset from the extension
        delete _ownership[getNFTId(nftAddr, nftTokenId)];

        // If we dont hold asset from this address anymore, we can remove it
        if (_nfts[nftAddr].length() == 0) {
            require(
                _nftAddresses.remove(nftAddr),
                "erc721::can not remove nft"
            );
        }
        //slither-disable-next-line reentrancy-events
        emit WithdrawnNFT(nftAddr, nftTokenId, newOwner);
    }

    /**
     * @notice Updates internally the ownership of the NFT.
     * @notice The caller must have the ACL Flag: INTERNAL_TRANSFER
     * @dev Reverts if the NFT is not already internally owned in the extension.
     * @param nftAddr The NFT address.
     * @param nftTokenId The NFT token id.
     * @param newOwner The address of the new owner.
     */
    function internalTransfer(
        DaoRegistry _dao,
        address nftAddr,
        uint256 nftTokenId,
        address newOwner
    ) external hasExtensionAccess(_dao, AclFlag.INTERNAL_TRANSFER) {
        require(newOwner != address(0x0), "erc721::new owner is 0");
        address currentOwner = _ownership[getNFTId(nftAddr, nftTokenId)];
        require(_dao.notJailed(currentOwner), "member is jailed");
        require(currentOwner != address(0x0), "erc721::nft not found");

        _ownership[getNFTId(nftAddr, nftTokenId)] = newOwner;

        emit TransferredNFT(nftAddr, nftTokenId, currentOwner, newOwner);
    }

    /**
     * @notice Gets ID generated from an NFT address and token id (used internally to map ownership).
     * @param nftAddress The NFT address.
     * @param tokenId The NFT token id.
     */
    function getNFTId(address nftAddress, uint256 tokenId)
        public
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(nftAddress, tokenId));
    }

    /**
     * @notice Returns the total amount of token ids collected for an NFT address.
     * @param tokenAddr The NFT address.
     */
    function nbNFTs(address tokenAddr) external view returns (uint256) {
        return _nfts[tokenAddr].length();
    }

    /**
     * @notice Returns token id associated with an NFT address stored in the GUILD collection at the specified index.
     * @param tokenAddr The NFT address.
     * @param index The index to get the token id if it exists.
     */
    function getNFT(address tokenAddr, uint256 index)
        external
        view
        returns (uint256)
    {
        return _nfts[tokenAddr].at(index);
    }

    /**
     * @notice Returns the total amount of NFT addresses collected.
     */
    function nbNFTAddresses() external view returns (uint256) {
        return _nftAddresses.length();
    }

    /**
     * @notice Returns NFT address stored in the GUILD collection at the specified index.
     * @param index The index to get the NFT address if it exists.
     */
    function getNFTAddress(uint256 index) external view returns (address) {
        return _nftAddresses.at(index);
    }

    /**
     * @notice Returns owner of NFT that has been transferred to the extension.
     * @param nftAddress The NFT address.
     * @param tokenId The NFT token id.
     */
    function getNFTOwner(address nftAddress, uint256 tokenId)
        external
        view
        returns (address)
    {
        return _ownership[getNFTId(nftAddress, tokenId)];
    }

    /**
     * @notice Required function from IERC721 standard to be able to receive assets to this contract address.
     */
    function onERC721Received(
        address,
        address,
        uint256 id,
        bytes calldata
    ) external override returns (bytes4) {
        _saveNft(msg.sender, id, DaoHelper.GUILD);
        return this.onERC721Received.selector;
    }

    /**
     * @notice Must be manually called if the NFT was received via transferFrom function.
     * @notice If this function is not called, the NFT metadata won't be stored in the extension,
     * because the transferFrom call does not trigger the onERC721Received callback.
     * @notice If the NFT is not owner by the Extension, the update call is not allowed, this is done to
     * ensure that the NFT was actually sent to the Extension address.
     */
    function updateCollection(address token, uint256 tokenId) external {
        require(
            IERC721(token).ownerOf(tokenId) == address(this),
            "update not allowed"
        );
        _saveNft(token, tokenId, DaoHelper.GUILD);
    }

    /**
     * @notice Helper function to update the extension states for an NFT collected by the extension.
     * @param nftAddr The NFT address.
     * @param nftTokenId The token id.
     * @param owner The address of the owner.
     */
    function _saveNft(
        address nftAddr,
        uint256 nftTokenId,
        address owner
    ) private {
        // Save the asset, returns false if already saved.
        bool saved = _nfts[nftAddr].add(nftTokenId);
        if (saved) {
            // set ownership to the GUILD.
            _ownership[getNFTId(nftAddr, nftTokenId)] = owner;
            // Keep track of the collected assets.
            if (!_nftAddresses.contains(nftAddr)) {
                //slither-disable-next-line unused-return
                _nftAddresses.add(nftAddr);
            }
        }
    }
}

pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT
import "../../core/DaoRegistry.sol";
import "../../guards/MemberGuard.sol";
import "../../helpers/DaoHelper.sol";
import "../IExtension.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

/**
MIT License

Copyright (c) 2020 Openlaw

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
 */

contract ERC1155TokenExtension is IExtension, IERC1155Receiver {
    using Address for address payable;
    //LIBRARIES
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableSet for EnumerableSet.AddressSet;

    bool public initialized = false; //internally tracks deployment under eip-1167 proxy pattern
    DaoRegistry public dao;

    enum AclFlag {
        WITHDRAW_NFT,
        COLLECT_NFT,
        INTERNAL_TRANSFER
    }

    //EVENTS
    event TransferredNFT(
        address oldOwner,
        address newOwner,
        address nftAddr,
        uint256 nftTokenId,
        uint256 amount
    );
    event WithdrawnNFT(
        address nftAddr,
        uint256 nftTokenId,
        uint256 amount,
        address toAddress
    );

    //MAPPINGS

    // All the Token IDs that belong to an NFT address stored in the GUILD.
    mapping(address => EnumerableSet.UintSet) private _nfts;

    // The internal mapping to track the owners, nfts, tokenIds, and amounts records of the owners that sent ther NFT to the extension
    // owner => (tokenAddress => (tokenId => tokenAmount)).
    mapping(address => mapping(address => mapping(uint256 => uint256)))
        private _nftTracker;

    // The (NFT Addr + Token Id) key reverse mapping to track all the tokens collected and actual owners.
    mapping(bytes32 => EnumerableSet.AddressSet) private _ownership;

    // All the NFT addresses stored in the Extension collection
    EnumerableSet.AddressSet private _nftAddresses;

    //MODIFIERS
    modifier hasExtensionAccess(DaoRegistry _dao, AclFlag flag) {
        require(
            _dao == dao &&
                (DaoHelper.isInCreationModeAndHasAccess(dao) ||
                    !initialized ||
                    dao.hasAdapterAccessToExtension(
                        msg.sender,
                        address(this),
                        uint8(flag)
                    )),
            "erc1155Ext::accessDenied"
        );
        _;
    }

    /// @notice Clonable contract must have an empty constructor
    constructor() {}

    /**
     * @notice Initializes the extension with the DAO address that it belongs to.
     * @param _dao The address of the DAO that owns the extension.
     */
    function initialize(DaoRegistry _dao, address) external override {
        require(!initialized, "already initialized");
        initialized = true;
        dao = _dao;
    }

    /**
     * @notice Transfers the NFT token from the extension address to the new owner.
     * @notice It also updates the internal state to keep track of the all the NFTs collected by the extension.
     * @notice The caller must have the ACL Flag: WITHDRAW_NFT
     * @notice This function needs to be called from a new adapter (RagequitNFT) that will manage the Bank balances, and will return the NFT to the owner.
     * @dev Reverts if the NFT is not in ERC1155 standard.
     * @param newOwner The address of the new owner that will receive the NFT.
     * @param nftAddr The NFT address that must be in ERC1155 standard.
     * @param nftTokenId The NFT token id.
     * @param amount The NFT token id amount to withdraw.
     */
    function withdrawNFT(
        DaoRegistry _dao,
        address from,
        address newOwner,
        address nftAddr,
        uint256 nftTokenId,
        uint256 amount
    ) external hasExtensionAccess(_dao, AclFlag.WITHDRAW_NFT) {
        IERC1155 erc1155 = IERC1155(nftAddr);
        uint256 balance = erc1155.balanceOf(address(this), nftTokenId);
        require(
            balance > 0 && amount > 0,
            "erc1155Ext::not enough balance or amount"
        );

        uint256 currentAmount = _getTokenAmount(from, nftAddr, nftTokenId);
        require(currentAmount >= amount, "erc1155Ext::insufficient funds");
        uint256 remainingAmount = currentAmount - amount;

        // Updates the tokenID amount to keep the records consistent
        _updateTokenAmount(from, nftAddr, nftTokenId, remainingAmount);

        uint256 ownerTokenIdBalance = erc1155.balanceOf(
            address(this),
            nftTokenId
        ) - amount;

        // Updates the mappings if the amount of tokenId in the Extension is 0
        // It means the GUILD/Extension does not hold that token id anymore.
        if (ownerTokenIdBalance == 0) {
            delete _nftTracker[from][nftAddr][nftTokenId];
            //slither-disable-next-line unused-return
            _ownership[getNFTId(nftAddr, nftTokenId)].remove(from);
            //slither-disable-next-line unused-return
            _nfts[nftAddr].remove(nftTokenId);
            // If there are 0 tokenIds for the NFT address, remove the NFT from the collection
            if (_nfts[nftAddr].length() == 0) {
                //slither-disable-next-line unused-return
                _nftAddresses.remove(nftAddr);
                delete _nfts[nftAddr];
            }
        }

        // Transfer the NFT, TokenId and amount from the contract address to the new owner
        erc1155.safeTransferFrom(
            address(this),
            newOwner,
            nftTokenId,
            amount,
            ""
        );
        //slither-disable-next-line reentrancy-events
        emit WithdrawnNFT(nftAddr, nftTokenId, amount, newOwner);
    }

    /**
     * @notice Updates internally the ownership of the NFT.
     * @notice The caller must have the ACL Flag: INTERNAL_TRANSFER
     * @dev Reverts if the NFT is not already internally owned in the extension.
     * @param fromOwner The address of the current owner.
     * @param toOwner The address of the new owner.
     * @param nftAddr The NFT address.
     * @param nftTokenId The NFT token id.
     * @param amount the number of a particular NFT token id.
     */
    function internalTransfer(
        DaoRegistry _dao,
        address fromOwner,
        address toOwner,
        address nftAddr,
        uint256 nftTokenId,
        uint256 amount
    ) external hasExtensionAccess(_dao, AclFlag.INTERNAL_TRANSFER) {
        require(_dao.notJailed(fromOwner), "member is jailed!");
        // Checks if there token amount is valid and has enough funds
        uint256 tokenAmount = _getTokenAmount(fromOwner, nftAddr, nftTokenId);
        require(
            amount > 0 && tokenAmount >= amount,
            "erc1155Ext::invalid amount"
        );

        // Checks if the extension holds the NFT
        require(
            _nfts[nftAddr].contains(nftTokenId),
            "erc1155Ext::nft not found"
        );
        if (fromOwner != toOwner) {
            // Updates the internal records for toOwner with the current balance + the transferred amount
            uint256 toOwnerNewAmount = _getTokenAmount(
                toOwner,
                nftAddr,
                nftTokenId
            ) + amount;
            _updateTokenAmount(toOwner, nftAddr, nftTokenId, toOwnerNewAmount);
            // Updates the internal records for fromOwner with the remaning amount
            _updateTokenAmount(
                fromOwner,
                nftAddr,
                nftTokenId,
                tokenAmount - amount
            );
            //slither-disable-next-line reentrancy-events
            emit TransferredNFT(
                fromOwner,
                toOwner,
                nftAddr,
                nftTokenId,
                amount
            );
        }
    }

    /**
     * @notice Gets ID generated from an NFT address and token id (used internally to map ownership).
     * @param nftAddress The NFT address.
     * @param tokenId The NFT token id.
     */
    function getNFTId(address nftAddress, uint256 tokenId)
        public
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(nftAddress, tokenId));
    }

    /**
     * @notice gets owner's amount of a TokenId for an NFT address.
     * @param owner eth address
     * @param tokenAddr the NFT address.
     * @param tokenId The NFT token id.
     */
    function getNFTIdAmount(
        address owner,
        address tokenAddr,
        uint256 tokenId
    ) external view returns (uint256) {
        return _nftTracker[owner][tokenAddr][tokenId];
    }

    /**
     * @notice Returns the total amount of token ids collected for an NFT address.
     * @param tokenAddr The NFT address.
     */
    function nbNFTs(address tokenAddr) external view returns (uint256) {
        return _nfts[tokenAddr].length();
    }

    /**
     * @notice Returns token id associated with an NFT address stored in the GUILD collection at the specified index.
     * @param tokenAddr The NFT address.
     * @param index The index to get the token id if it exists.
     */
    function getNFT(address tokenAddr, uint256 index)
        external
        view
        returns (uint256)
    {
        return _nfts[tokenAddr].at(index);
    }

    /**
     * @notice Returns the total amount of NFT addresses collected.
     */
    function nbNFTAddresses() external view returns (uint256) {
        return _nftAddresses.length();
    }

    /**
     * @notice Returns NFT address stored in the GUILD collection at the specified index.
     * @param index The index to get the NFT address if it exists.
     */
    function getNFTAddress(uint256 index) external view returns (address) {
        return _nftAddresses.at(index);
    }

    /**
     * @notice Returns owner of NFT that has been transferred to the extension.
     * @param nftAddress The NFT address.
     * @param tokenId The NFT token id.
     */
    function getNFTOwner(
        address nftAddress,
        uint256 tokenId,
        uint256 index
    ) external view returns (address) {
        return _ownership[getNFTId(nftAddress, tokenId)].at(index);
    }

    /**
     * @notice Returns the total number of owners of an NFT addresses and token id collected.
     */
    function nbNFTOwners(address nftAddress, uint256 tokenId)
        external
        view
        returns (uint256)
    {
        return _ownership[getNFTId(nftAddress, tokenId)].length();
    }

    /**
     * @notice Helper function to update the extension states for an NFT collected by the extension.
     * @param nftAddr The NFT address.
     * @param nftTokenId The token id.
     * @param owner The address of the owner.
     * @param amount of the tokenID
     */
    function _saveNft(
        address nftAddr,
        uint256 nftTokenId,
        address owner,
        uint256 amount
    ) private {
        // Save the asset address and tokenId
        //slither-disable-next-line unused-return
        _nfts[nftAddr].add(nftTokenId);
        // Track the owner by nftAddr+tokenId
        //slither-disable-next-line unused-return
        _ownership[getNFTId(nftAddr, nftTokenId)].add(owner);
        // Keep track of the collected assets addresses
        //slither-disable-next-line unused-return
        _nftAddresses.add(nftAddr);
        // Track the actual owner per Token Id and amount
        uint256 currentAmount = _nftTracker[owner][nftAddr][nftTokenId];
        _nftTracker[owner][nftAddr][nftTokenId] = currentAmount + amount;
    }

    /**
     *  @notice required function from IERC1155 standard to be able to to receive tokens
     */
    function onERC1155Received(
        address,
        address,
        uint256 id,
        uint256 value,
        bytes calldata
    ) external override returns (bytes4) {
        _saveNft(msg.sender, id, DaoHelper.GUILD, value);
        return this.onERC1155Received.selector;
    }

    /**
     *  @notice required function from IERC1155 standard to be able to to batch receive tokens
     */
    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata
    ) external override returns (bytes4) {
        require(
            ids.length == values.length,
            "erc1155Ext::ids values length mismatch"
        );
        for (uint256 i = 0; i < ids.length; i++) {
            _saveNft(msg.sender, ids[i], DaoHelper.GUILD, values[i]);
        }

        return this.onERC1155BatchReceived.selector;
    }

    /**
     * @notice Supports ERC-165 & ERC-1155 interfaces only.
     * @dev https://github.com/ethereum/EIPs/blob/master/EIPS/eip-1155.md
     */
    function supportsInterface(bytes4 interfaceID)
        external
        pure
        override
        returns (bool)
    {
        return
            interfaceID == 0x01ffc9a7 || // ERC-165 support (i.e. `bytes4(keccak256('supportsInterface(bytes4)'))`).
            interfaceID == 0x4e2312e0; // ERC-1155 `ERC1155TokenReceiver` support (i.e. `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)")) ^ bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`).
    }

    /**
     *  @notice internal function to update the amount of a tokenID for an NFT an owner has
     */
    function _updateTokenAmount(
        address owner,
        address nft,
        uint256 tokenId,
        uint256 amount
    ) internal {
        _nftTracker[owner][nft][tokenId] = amount;
    }

    /**
     *  @notice internal function to get the amount of a tokenID for an NFT an owner has
     */
    function _getTokenAmount(
        address owner,
        address nft,
        uint256 tokenId
    ) internal view returns (uint256) {
        return _nftTracker[owner][nft][tokenId];
    }
}

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT
import "../../core/DaoRegistry.sol";
import "../IExtension.sol";
import "../../guards/AdapterGuard.sol";
import "../../helpers/DaoHelper.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

/**
MIT License

Copyright (c) 2020 Openlaw

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
 */

contract BankExtension is IExtension, ERC165 {
    using Address for address payable;
    using SafeERC20 for IERC20;

    uint8 public maxExternalTokens; // the maximum number of external tokens that can be stored in the bank

    bool public initialized = false; // internally tracks deployment under eip-1167 proxy pattern
    DaoRegistry public dao;

    enum AclFlag {
        ADD_TO_BALANCE,
        SUB_FROM_BALANCE,
        INTERNAL_TRANSFER,
        WITHDRAW,
        REGISTER_NEW_TOKEN,
        REGISTER_NEW_INTERNAL_TOKEN,
        UPDATE_TOKEN
    }

    modifier noProposal() {
        require(dao.lockedAt() < block.number, "proposal lock");
        _;
    }

    /// @dev - Events for Bank
    event NewBalance(address member, address tokenAddr, uint160 amount);

    event Withdraw(address account, address tokenAddr, uint160 amount);

    event WithdrawTo(
        address accountFrom,
        address accountTo,
        address tokenAddr,
        uint160 amount
    );

    /*
     * STRUCTURES
     */

    struct Checkpoint {
        // A checkpoint for marking number of votes from a given block
        uint96 fromBlock;
        uint160 amount;
    }

    address[] public tokens;
    address[] public internalTokens;
    // tokenAddress => availability
    mapping(address => bool) public availableTokens;
    mapping(address => bool) public availableInternalTokens;
    // tokenAddress => memberAddress => checkpointNum => Checkpoint
    mapping(address => mapping(address => mapping(uint32 => Checkpoint)))
        public checkpoints;
    // tokenAddress => memberAddress => numCheckpoints
    mapping(address => mapping(address => uint32)) public numCheckpoints;

    /// @notice Clonable contract must have an empty constructor
    constructor() {}

    // slither-disable-next-line calls-loop
    modifier hasExtensionAccess(DaoRegistry _dao, AclFlag flag) {
        require(
            dao == _dao &&
                (address(this) == msg.sender ||
                    address(dao) == msg.sender ||
                    !initialized ||
                    DaoHelper.isInCreationModeAndHasAccess(dao) ||
                    dao.hasAdapterAccessToExtension(
                        msg.sender,
                        address(this),
                        uint8(flag)
                    )),
            "bank::accessDenied"
        );
        _;
    }

    /**
     * @notice Initialises the DAO
     * @dev Involves initialising available tokens, checkpoints, and membership of creator
     * @dev Can only be called once
     * @param creator The DAO's creator, who will be an initial member
     */
    function initialize(DaoRegistry _dao, address creator) external override {
        require(!initialized, "already initialized");
        require(_dao.isMember(creator), "not a member");
        dao = _dao;

        availableInternalTokens[DaoHelper.UNITS] = true;
        internalTokens.push(DaoHelper.UNITS);

        availableInternalTokens[DaoHelper.MEMBER_COUNT] = true;
        internalTokens.push(DaoHelper.MEMBER_COUNT);
        uint256 nbMembers = _dao.getNbMembers();
        for (uint256 i = 0; i < nbMembers; i++) {
            //slither-disable-next-line calls-loop
            addToBalance(
                _dao,
                _dao.getMemberAddress(i),
                DaoHelper.MEMBER_COUNT,
                1
            );
        }

        _createNewAmountCheckpoint(creator, DaoHelper.UNITS, 1);
        _createNewAmountCheckpoint(DaoHelper.TOTAL, DaoHelper.UNITS, 1);
        initialized = true;
    }

    function withdraw(
        DaoRegistry _dao,
        address payable member,
        address tokenAddr,
        uint256 amount
    ) external hasExtensionAccess(_dao, AclFlag.WITHDRAW) {
        require(
            balanceOf(member, tokenAddr) >= amount,
            "bank::withdraw::not enough funds"
        );
        subtractFromBalance(_dao, member, tokenAddr, amount);
        if (tokenAddr == DaoHelper.ETH_TOKEN) {
            member.sendValue(amount);
        } else {
            IERC20(tokenAddr).safeTransfer(member, amount);
        }

        //slither-disable-next-line reentrancy-events
        emit Withdraw(member, tokenAddr, uint160(amount));
    }

    function withdrawTo(
        DaoRegistry _dao,
        address memberFrom,
        address payable memberTo,
        address tokenAddr,
        uint256 amount
    ) external hasExtensionAccess(_dao, AclFlag.WITHDRAW) {
        require(
            balanceOf(memberFrom, tokenAddr) >= amount,
            "bank::withdraw::not enough funds"
        );
        subtractFromBalance(_dao, memberFrom, tokenAddr, amount);
        if (tokenAddr == DaoHelper.ETH_TOKEN) {
            memberTo.sendValue(amount);
        } else {
            IERC20(tokenAddr).safeTransfer(memberTo, amount);
        }

        //slither-disable-next-line reentrancy-events
        emit WithdrawTo(memberFrom, memberTo, tokenAddr, uint160(amount));
    }

    /**
     * @return Whether or not the given token is an available internal token in the bank
     * @param token The address of the token to look up
     */
    function isInternalToken(address token) external view returns (bool) {
        return availableInternalTokens[token];
    }

    /**
     * @return Whether or not the given token is an available token in the bank
     * @param token The address of the token to look up
     */
    function isTokenAllowed(address token) public view returns (bool) {
        return availableTokens[token];
    }

    /**
     * @notice Sets the maximum amount of external tokens allowed in the bank
     * @param maxTokens The maximum amount of token allowed
     */
    function setMaxExternalTokens(uint8 maxTokens) external {
        require(!initialized, "already initialized");
        require(
            maxTokens > 0 && maxTokens <= DaoHelper.MAX_TOKENS_GUILD_BANK,
            "maxTokens should be (0,200]"
        );
        maxExternalTokens = maxTokens;
    }

    /*
     * BANK
     */

    /**
     * @notice Registers a potential new token in the bank
     * @dev Cannot be a reserved token or an available internal token
     * @param token The address of the token
     */
    function registerPotentialNewToken(DaoRegistry _dao, address token)
        external
        hasExtensionAccess(_dao, AclFlag.REGISTER_NEW_TOKEN)
    {
        require(DaoHelper.isNotReservedAddress(token), "reservedToken");
        require(!availableInternalTokens[token], "internalToken");
        require(
            tokens.length <= maxExternalTokens,
            "exceeds the maximum tokens allowed"
        );

        if (!availableTokens[token]) {
            availableTokens[token] = true;
            tokens.push(token);
        }
    }

    /**
     * @notice Registers a potential new internal token in the bank
     * @dev Can not be a reserved token or an available token
     * @param token The address of the token
     */
    function registerPotentialNewInternalToken(DaoRegistry _dao, address token)
        external
        hasExtensionAccess(_dao, AclFlag.REGISTER_NEW_INTERNAL_TOKEN)
    {
        require(DaoHelper.isNotReservedAddress(token), "reservedToken");
        require(!availableTokens[token], "availableToken");

        if (!availableInternalTokens[token]) {
            availableInternalTokens[token] = true;
            internalTokens.push(token);
        }
    }

    function updateToken(DaoRegistry _dao, address tokenAddr)
        external
        hasExtensionAccess(_dao, AclFlag.UPDATE_TOKEN)
    {
        require(isTokenAllowed(tokenAddr), "token not allowed");
        uint256 totalBalance = balanceOf(DaoHelper.TOTAL, tokenAddr);

        uint256 realBalance;

        if (tokenAddr == DaoHelper.ETH_TOKEN) {
            realBalance = address(this).balance;
        } else {
            IERC20 erc20 = IERC20(tokenAddr);
            realBalance = erc20.balanceOf(address(this));
        }

        if (totalBalance < realBalance) {
            addToBalance(
                _dao,
                DaoHelper.GUILD,
                tokenAddr,
                realBalance - totalBalance
            );
        } else if (totalBalance > realBalance) {
            uint256 tokensToRemove = totalBalance - realBalance;
            uint256 guildBalance = balanceOf(DaoHelper.GUILD, tokenAddr);
            if (guildBalance > tokensToRemove) {
                subtractFromBalance(
                    _dao,
                    DaoHelper.GUILD,
                    tokenAddr,
                    tokensToRemove
                );
            } else {
                subtractFromBalance(
                    _dao,
                    DaoHelper.GUILD,
                    tokenAddr,
                    guildBalance
                );
            }
        }
    }

    /**
     * Public read-only functions
     */

    /**
     * Internal bookkeeping
     */

    /**
     * @return The token from the bank of a given index
     * @param index The index to look up in the bank's tokens
     */
    function getToken(uint256 index) external view returns (address) {
        return tokens[index];
    }

    /**
     * @return The amount of token addresses in the bank
     */
    function nbTokens() external view returns (uint256) {
        return tokens.length;
    }

    /**
     * @return All the tokens registered in the bank.
     */
    function getTokens() external view returns (address[] memory) {
        return tokens;
    }

    /**
     * @return The internal token at a given index
     * @param index The index to look up in the bank's array of internal tokens
     */
    function getInternalToken(uint256 index) external view returns (address) {
        return internalTokens[index];
    }

    /**
     * @return The amount of internal token addresses in the bank
     */
    function nbInternalTokens() external view returns (uint256) {
        return internalTokens.length;
    }

    /**
     * @notice Adds to a member's balance of a given token
     * @param member The member whose balance will be updated
     * @param token The token to update
     * @param amount The new balance
     */
    function addToBalance(
        DaoRegistry _dao,
        address member,
        address token,
        uint256 amount
    ) public payable hasExtensionAccess(_dao, AclFlag.ADD_TO_BALANCE) {
        require(
            availableTokens[token] || availableInternalTokens[token],
            "unknown token address"
        );
        uint256 newAmount = balanceOf(member, token) + amount;
        uint256 newTotalAmount = balanceOf(DaoHelper.TOTAL, token) + amount;

        _createNewAmountCheckpoint(member, token, newAmount);
        _createNewAmountCheckpoint(DaoHelper.TOTAL, token, newTotalAmount);
    }

    /**
     * @notice Remove from a member's balance of a given token
     * @param member The member whose balance will be updated
     * @param token The token to update
     * @param amount The new balance
     */
    function subtractFromBalance(
        DaoRegistry _dao,
        address member,
        address token,
        uint256 amount
    ) public hasExtensionAccess(_dao, AclFlag.SUB_FROM_BALANCE) {
        uint256 newAmount = balanceOf(member, token) - amount;
        uint256 newTotalAmount = balanceOf(DaoHelper.TOTAL, token) - amount;

        _createNewAmountCheckpoint(member, token, newAmount);
        _createNewAmountCheckpoint(DaoHelper.TOTAL, token, newTotalAmount);
    }

    /**
     * @notice Make an internal token transfer
     * @param from The member who is sending tokens
     * @param to The member who is receiving tokens
     * @param amount The new amount to transfer
     */
    function internalTransfer(
        DaoRegistry _dao,
        address from,
        address to,
        address token,
        uint256 amount
    ) external hasExtensionAccess(_dao, AclFlag.INTERNAL_TRANSFER) {
        require(dao.notJailed(from), "no transfer from jail");
        require(dao.notJailed(to), "no transfer from jail");
        uint256 newAmount = balanceOf(from, token) - amount;
        uint256 newAmount2 = balanceOf(to, token) + amount;

        _createNewAmountCheckpoint(from, token, newAmount);
        _createNewAmountCheckpoint(to, token, newAmount2);
    }

    /**
     * @notice Returns an member's balance of a given token
     * @param member The address to look up
     * @param tokenAddr The token where the member's balance of which will be returned
     * @return The amount in account's tokenAddr balance
     */
    function balanceOf(address member, address tokenAddr)
        public
        view
        returns (uint160)
    {
        uint32 nCheckpoints = numCheckpoints[tokenAddr][member];
        return
            nCheckpoints > 0
                ? checkpoints[tokenAddr][member][nCheckpoints - 1].amount
                : 0;
    }

    /**
     * @notice Determine the prior number of votes for an account as of a block number
     * @dev Block number must be a finalized block or else this function will revert to prevent misinformation.
     * @param account The address of the account to check
     * @param blockNumber The block number to get the vote balance at
     * @return The number of votes the account had as of the given block
     */
    function getPriorAmount(
        address account,
        address tokenAddr,
        uint256 blockNumber
    ) external view returns (uint256) {
        require(
            blockNumber < block.number,
            "bank::getPriorAmount: not yet determined"
        );

        uint32 nCheckpoints = numCheckpoints[tokenAddr][account];
        if (nCheckpoints == 0) {
            return 0;
        }

        // First check most recent balance
        if (
            checkpoints[tokenAddr][account][nCheckpoints - 1].fromBlock <=
            blockNumber
        ) {
            return checkpoints[tokenAddr][account][nCheckpoints - 1].amount;
        }

        // Next check implicit zero balance
        if (checkpoints[tokenAddr][account][0].fromBlock > blockNumber) {
            return 0;
        }

        uint32 lower = 0;
        uint32 upper = nCheckpoints - 1;
        while (upper > lower) {
            uint32 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
            Checkpoint memory cp = checkpoints[tokenAddr][account][center];
            if (cp.fromBlock == blockNumber) {
                return cp.amount;
            } else if (cp.fromBlock < blockNumber) {
                lower = center;
            } else {
                upper = center - 1;
            }
        }
        return checkpoints[tokenAddr][account][lower].amount;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            super.supportsInterface(interfaceId) ||
            this.subtractFromBalance.selector == interfaceId ||
            this.addToBalance.selector == interfaceId ||
            this.getPriorAmount.selector == interfaceId ||
            this.balanceOf.selector == interfaceId ||
            this.internalTransfer.selector == interfaceId ||
            this.nbInternalTokens.selector == interfaceId ||
            this.getInternalToken.selector == interfaceId ||
            this.getTokens.selector == interfaceId ||
            this.nbTokens.selector == interfaceId ||
            this.getToken.selector == interfaceId ||
            this.updateToken.selector == interfaceId ||
            this.registerPotentialNewInternalToken.selector == interfaceId ||
            this.registerPotentialNewToken.selector == interfaceId ||
            this.setMaxExternalTokens.selector == interfaceId ||
            this.isTokenAllowed.selector == interfaceId ||
            this.isInternalToken.selector == interfaceId ||
            this.withdraw.selector == interfaceId ||
            this.withdrawTo.selector == interfaceId;
    }

    /**
     * @notice Creates a new amount checkpoint for a token of a certain member
     * @dev Reverts if the amount is greater than 2**64-1
     * @param member The member whose checkpoints will be added to
     * @param token The token of which the balance will be changed
     * @param amount The amount to be written into the new checkpoint
     */
    function _createNewAmountCheckpoint(
        address member,
        address token,
        uint256 amount
    ) internal {
        bool isValidToken = false;
        if (availableInternalTokens[token]) {
            require(
                amount < type(uint88).max,
                "token amount exceeds the maximum limit for internal tokens"
            );
            isValidToken = true;
        } else if (availableTokens[token]) {
            require(
                amount < type(uint160).max,
                "token amount exceeds the maximum limit for external tokens"
            );
            isValidToken = true;
        }
        uint160 newAmount = uint160(amount);

        require(isValidToken, "token not registered");

        uint32 nCheckpoints = numCheckpoints[token][member];
        if (
            // The only condition that we should allow the amount update
            // is when the block.number exactly matches the fromBlock value.
            // Anything different from that should generate a new checkpoint.
            //slither-disable-next-line incorrect-equality
            nCheckpoints > 0 &&
            checkpoints[token][member][nCheckpoints - 1].fromBlock ==
            block.number
        ) {
            checkpoints[token][member][nCheckpoints - 1].amount = newAmount;
        } else {
            checkpoints[token][member][nCheckpoints] = Checkpoint(
                uint96(block.number),
                newAmount
            );
            numCheckpoints[token][member] = nCheckpoints + 1;
        }
        //slither-disable-next-line reentrancy-events
        emit NewBalance(member, token, newAmount);
    }
}

pragma solidity ^0.8.0;
import "../core/DaoRegistry.sol";

// SPDX-License-Identifier: MIT

/**
MIT License

Copyright (c) 2020 Openlaw

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
 */

interface IExtension {
    function initialize(DaoRegistry dao, address creator) external;
}

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT

import "../guards/AdapterGuard.sol";
import "../guards/MemberGuard.sol";
import "../extensions/IExtension.sol";
import "../helpers/DaoHelper.sol";

/**
MIT License

Copyright (c) 2020 Openlaw

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
 */

contract DaoRegistry is MemberGuard, AdapterGuard {
    /**
     * EVENTS
     */
    event SubmittedProposal(bytes32 proposalId, uint256 flags);
    event SponsoredProposal(
        bytes32 proposalId,
        uint256 flags,
        address votingAdapter
    );
    event ProcessedProposal(bytes32 proposalId, uint256 flags);
    event AdapterAdded(
        bytes32 adapterId,
        address adapterAddress,
        uint256 flags
    );
    event AdapterRemoved(bytes32 adapterId);
    event ExtensionAdded(bytes32 extensionId, address extensionAddress);
    event ExtensionRemoved(bytes32 extensionId);
    event UpdateDelegateKey(address memberAddress, address newDelegateKey);
    event ConfigurationUpdated(bytes32 key, uint256 value);
    event AddressConfigurationUpdated(bytes32 key, address value);

    enum DaoState {
        CREATION,
        READY
    }

    enum MemberFlag {
        EXISTS,
        JAILED
    }

    enum ProposalFlag {
        EXISTS,
        SPONSORED,
        PROCESSED
    }

    enum AclFlag {
        REPLACE_ADAPTER,
        SUBMIT_PROPOSAL,
        UPDATE_DELEGATE_KEY,
        SET_CONFIGURATION,
        ADD_EXTENSION,
        REMOVE_EXTENSION,
        NEW_MEMBER,
        JAIL_MEMBER
    }

    /**
     * STRUCTURES
     */
    struct Proposal {
        /// the structure to track all the proposals in the DAO
        address adapterAddress; /// the adapter address that called the functions to change the DAO state
        uint256 flags; /// flags to track the state of the proposal: exist, sponsored, processed, canceled, etc.
    }

    struct Member {
        /// the structure to track all the members in the DAO
        uint256 flags; /// flags to track the state of the member: exists, etc
    }

    struct Checkpoint {
        /// A checkpoint for marking number of votes from a given block
        uint96 fromBlock;
        uint160 amount;
    }

    struct DelegateCheckpoint {
        /// A checkpoint for marking the delegate key for a member from a given block
        uint96 fromBlock;
        address delegateKey;
    }

    struct AdapterEntry {
        bytes32 id;
        uint256 acl;
    }

    struct ExtensionEntry {
        bytes32 id;
        mapping(address => uint256) acl;
        bool deleted;
    }

    /**
     * PUBLIC VARIABLES
     */

    /// @notice internally tracks deployment under eip-1167 proxy pattern
    bool public initialized = false;

    /// @notice The dao state starts as CREATION and is changed to READY after the finalizeDao call
    DaoState public state;

    /// @notice The map to track all members of the DAO with their existing flags
    mapping(address => Member) public members;
    /// @notice The list of members
    address[] private _members;

    /// @notice delegate key => member address mapping
    mapping(address => address) public memberAddressesByDelegatedKey;

    /// @notice The map that keeps track of all proposasls submitted to the DAO
    mapping(bytes32 => Proposal) public proposals;
    /// @notice The map that tracks the voting adapter address per proposalId: proposalId => adapterAddress
    mapping(bytes32 => address) public votingAdapter;
    /// @notice The map that keeps track of all adapters registered in the DAO: sha3(adapterId) => adapterAddress
    mapping(bytes32 => address) public adapters;
    /// @notice The inverse map to get the adapter id based on its address
    mapping(address => AdapterEntry) public inverseAdapters;
    /// @notice The map that keeps track of all extensions registered in the DAO: sha3(extId) => extAddress
    mapping(bytes32 => address) public extensions;
    /// @notice The inverse map to get the extension id based on its address
    mapping(address => ExtensionEntry) public inverseExtensions;
    /// @notice The map that keeps track of configuration parameters for the DAO and adapters: sha3(configId) => numericValue
    mapping(bytes32 => uint256) public mainConfiguration;
    /// @notice The map to track all the configuration of type Address: sha3(configId) => addressValue
    mapping(bytes32 => address) public addressConfiguration;

    /// @notice controls the lock mechanism using the block.number
    uint256 public lockedAt;

    /**
     * INTERNAL VARIABLES
     */

    /// @notice memberAddress => checkpointNum => DelegateCheckpoint
    mapping(address => mapping(uint32 => DelegateCheckpoint)) _checkpoints;
    /// @notice memberAddress => numDelegateCheckpoints
    mapping(address => uint32) _numCheckpoints;

    /// @notice Clonable contract must have an empty constructor
    constructor() {}

    /**
     * @notice Initialises the DAO
     * @dev Involves initialising available tokens, checkpoints, and membership of creator
     * @dev Can only be called once
     * @param creator The DAO's creator, who will be an initial member
     * @param payer The account which paid for the transaction to create the DAO, who will be an initial member
     */
    //slither-disable-next-line reentrancy-no-eth
    function initialize(address creator, address payer) external {
        require(!initialized, "dao already initialized");
        initialized = true;
        potentialNewMember(msg.sender);
        potentialNewMember(creator);
        potentialNewMember(payer);
    }

    /**
     * ACCESS CONTROL
     */

    /**
     * @dev Sets the state of the dao to READY
     */
    function finalizeDao() external {
        require(
            isActiveMember(this, msg.sender) || isAdapter(msg.sender),
            "not allowed to finalize"
        );
        state = DaoState.READY;
    }

    /**
     * @notice Contract lock strategy to lock only the caller is an adapter or extension.
     */
    function lockSession() external {
        if (isAdapter(msg.sender) || isExtension(msg.sender)) {
            lockedAt = block.number;
        }
    }

    /**
     * @notice Contract lock strategy to release the lock only the caller is an adapter or extension.
     */
    function unlockSession() external {
        if (isAdapter(msg.sender) || isExtension(msg.sender)) {
            lockedAt = 0;
        }
    }

    /**
     * CONFIGURATIONS
     */

    /**
     * @notice Sets a configuration value
     * @dev Changes the value of a key in the configuration mapping
     * @param key The configuration key for which the value will be set
     * @param value The value to set the key
     */
    function setConfiguration(bytes32 key, uint256 value)
        external
        hasAccess(this, AclFlag.SET_CONFIGURATION)
    {
        mainConfiguration[key] = value;

        emit ConfigurationUpdated(key, value);
    }

    /**
     * @notice Sets an configuration value
     * @dev Changes the value of a key in the configuration mapping
     * @param key The configuration key for which the value will be set
     * @param value The value to set the key
     */
    function setAddressConfiguration(bytes32 key, address value)
        external
        hasAccess(this, AclFlag.SET_CONFIGURATION)
    {
        addressConfiguration[key] = value;

        emit AddressConfigurationUpdated(key, value);
    }

    /**
     * @return The configuration value of a particular key
     * @param key The key to look up in the configuration mapping
     */
    function getConfiguration(bytes32 key) external view returns (uint256) {
        return mainConfiguration[key];
    }

    /**
     * @return The configuration value of a particular key
     * @param key The key to look up in the configuration mapping
     */
    function getAddressConfiguration(bytes32 key)
        external
        view
        returns (address)
    {
        return addressConfiguration[key];
    }

    /**
     * ADAPTERS
     */

    /**
     * @notice Replaces an adapter in the registry in a single step.
     * @notice It handles addition and removal of adapters as special cases.
     * @dev It removes the current adapter if the adapterId maps to an existing adapter address.
     * @dev It adds an adapter if the adapterAddress parameter is not zeroed.
     * @param adapterId The unique identifier of the adapter
     * @param adapterAddress The address of the new adapter or zero if it is a removal operation
     * @param acl The flags indicating the access control layer or permissions of the new adapter
     * @param keys The keys indicating the adapter configuration names.
     * @param values The values indicating the adapter configuration values.
     */
    function replaceAdapter(
        bytes32 adapterId,
        address adapterAddress,
        uint128 acl,
        bytes32[] calldata keys,
        uint256[] calldata values
    ) external hasAccess(this, AclFlag.REPLACE_ADAPTER) {
        require(adapterId != bytes32(0), "adapterId must not be empty");

        address currentAdapterAddr = adapters[adapterId];
        if (currentAdapterAddr != address(0x0)) {
            delete inverseAdapters[currentAdapterAddr];
            delete adapters[adapterId];
            emit AdapterRemoved(adapterId);
        }

        for (uint256 i = 0; i < keys.length; i++) {
            bytes32 key = keys[i];
            uint256 value = values[i];
            mainConfiguration[key] = value;
            emit ConfigurationUpdated(key, value);
        }

        if (adapterAddress != address(0x0)) {
            require(
                inverseAdapters[adapterAddress].id == bytes32(0),
                "adapterAddress already in use"
            );
            adapters[adapterId] = adapterAddress;
            inverseAdapters[adapterAddress].id = adapterId;
            inverseAdapters[adapterAddress].acl = acl;
            emit AdapterAdded(adapterId, adapterAddress, acl);
        }
    }

    /**
     * @notice Looks up if there is an adapter of a given address
     * @return Whether or not the address is an adapter
     * @param adapterAddress The address to look up
     */
    function isAdapter(address adapterAddress) public view returns (bool) {
        return inverseAdapters[adapterAddress].id != bytes32(0);
    }

    /**
     * @notice Checks if an adapter has a given ACL flag
     * @return Whether or not the given adapter has the given flag set
     * @param adapterAddress The address to look up
     * @param flag The ACL flag to check against the given address
     */
    function hasAdapterAccess(address adapterAddress, AclFlag flag)
        external
        view
        returns (bool)
    {
        return
            DaoHelper.getFlag(inverseAdapters[adapterAddress].acl, uint8(flag));
    }

    /**
     * @return The address of a given adapter ID
     * @param adapterId The ID to look up
     */
    function getAdapterAddress(bytes32 adapterId)
        external
        view
        returns (address)
    {
        require(adapters[adapterId] != address(0), "adapter not found");
        return adapters[adapterId];
    }

    /**
     * EXTENSIONS
     */

    /**
     * @notice Adds a new extension to the registry
     * @param extensionId The unique identifier of the new extension
     * @param extension The address of the extension
     */
    // slither-disable-next-line reentrancy-events
    function addExtension(bytes32 extensionId, IExtension extension)
        external
        hasAccess(this, AclFlag.ADD_EXTENSION)
    {
        require(extensionId != bytes32(0), "extension id must not be empty");
        require(
            extensions[extensionId] == address(0x0),
            "extensionId already in use"
        );
        require(
            !inverseExtensions[address(extension)].deleted,
            "extension can not be re-added"
        );
        extensions[extensionId] = address(extension);
        inverseExtensions[address(extension)].id = extensionId;
        emit ExtensionAdded(extensionId, address(extension));
    }

    /**
     * @notice Removes an adapter from the registry
     * @param extensionId The unique identifier of the extension
     */
    function removeExtension(bytes32 extensionId)
        external
        hasAccess(this, AclFlag.REMOVE_EXTENSION)
    {
        require(extensionId != bytes32(0), "extensionId must not be empty");
        address extensionAddress = extensions[extensionId];
        require(extensionAddress != address(0x0), "extensionId not registered");
        ExtensionEntry storage extEntry = inverseExtensions[extensionAddress];
        extEntry.deleted = true;
        //slither-disable-next-line mapping-deletion
        delete extensions[extensionId];
        emit ExtensionRemoved(extensionId);
    }

    /**
     * @notice Looks up if there is an extension of a given address
     * @return Whether or not the address is an extension
     * @param extensionAddr The address to look up
     */
    function isExtension(address extensionAddr) public view returns (bool) {
        return inverseExtensions[extensionAddr].id != bytes32(0);
    }

    /**
     * @notice It sets the ACL flags to an Adapter to make it possible to access specific functions of an Extension.
     */
    function setAclToExtensionForAdapter(
        address extensionAddress,
        address adapterAddress,
        uint256 acl
    ) external hasAccess(this, AclFlag.ADD_EXTENSION) {
        require(isAdapter(adapterAddress), "not an adapter");
        require(isExtension(extensionAddress), "not an extension");
        inverseExtensions[extensionAddress].acl[adapterAddress] = acl;
    }

    /**
     * @notice Checks if an adapter has a given ACL flag
     * @return Whether or not the given adapter has the given flag set
     * @param adapterAddress The address to look up
     * @param flag The ACL flag to check against the given address
     */
    function hasAdapterAccessToExtension(
        address adapterAddress,
        address extensionAddress,
        uint8 flag
    ) external view returns (bool) {
        return
            isAdapter(adapterAddress) &&
            DaoHelper.getFlag(
                inverseExtensions[extensionAddress].acl[adapterAddress],
                uint8(flag)
            );
    }

    /**
     * @return The address of a given extension Id
     * @param extensionId The ID to look up
     */
    function getExtensionAddress(bytes32 extensionId)
        external
        view
        returns (address)
    {
        require(extensions[extensionId] != address(0), "extension not found");
        return extensions[extensionId];
    }

    /**
     * PROPOSALS
     */

    /**
     * @notice Submit proposals to the DAO registry
     */
    function submitProposal(bytes32 proposalId)
        external
        hasAccess(this, AclFlag.SUBMIT_PROPOSAL)
    {
        require(proposalId != bytes32(0), "invalid proposalId");
        require(
            !getProposalFlag(proposalId, ProposalFlag.EXISTS),
            "proposalId must be unique"
        );
        proposals[proposalId] = Proposal(msg.sender, 1); // 1 means that only the first flag is being set i.e. EXISTS
        emit SubmittedProposal(proposalId, 1);
    }

    /**
     * @notice Sponsor proposals that were submitted to the DAO registry
     * @dev adds SPONSORED to the proposal flag
     * @param proposalId The ID of the proposal to sponsor
     * @param sponsoringMember The member who is sponsoring the proposal
     */
    function sponsorProposal(
        bytes32 proposalId,
        address sponsoringMember,
        address votingAdapterAddr
    ) external onlyMember2(this, sponsoringMember) {
        // also checks if the flag was already set
        Proposal storage proposal = _setProposalFlag(
            proposalId,
            ProposalFlag.SPONSORED
        );

        uint256 flags = proposal.flags;

        require(
            proposal.adapterAddress == msg.sender,
            "only the adapter that submitted the proposal can sponsor it"
        );

        require(
            !DaoHelper.getFlag(flags, uint8(ProposalFlag.PROCESSED)),
            "proposal already processed"
        );
        votingAdapter[proposalId] = votingAdapterAddr;
        emit SponsoredProposal(proposalId, flags, votingAdapterAddr);
    }

    /**
     * @notice Mark a proposal as processed in the DAO registry
     * @param proposalId The ID of the proposal that is being processed
     */
    function processProposal(bytes32 proposalId) external {
        Proposal storage proposal = _setProposalFlag(
            proposalId,
            ProposalFlag.PROCESSED
        );

        require(proposal.adapterAddress == msg.sender, "err::adapter mismatch");
        uint256 flags = proposal.flags;

        emit ProcessedProposal(proposalId, flags);
    }

    /**
     * @notice Sets a flag of a proposal
     * @dev Reverts if the proposal is already processed
     * @param proposalId The ID of the proposal to be changed
     * @param flag The flag that will be set on the proposal
     */
    function _setProposalFlag(bytes32 proposalId, ProposalFlag flag)
        internal
        returns (Proposal storage)
    {
        Proposal storage proposal = proposals[proposalId];

        uint256 flags = proposal.flags;
        require(
            DaoHelper.getFlag(flags, uint8(ProposalFlag.EXISTS)),
            "proposal does not exist for this dao"
        );

        require(
            proposal.adapterAddress == msg.sender,
            "invalid adapter try to set flag"
        );

        require(!DaoHelper.getFlag(flags, uint8(flag)), "flag already set");

        flags = DaoHelper.setFlag(flags, uint8(flag), true);
        proposals[proposalId].flags = flags;

        return proposals[proposalId];
    }

    /**
     * @return Whether or not a flag is set for a given proposal
     * @param proposalId The proposal to check against flag
     * @param flag The flag to check in the proposal
     */
    function getProposalFlag(bytes32 proposalId, ProposalFlag flag)
        public
        view
        returns (bool)
    {
        return DaoHelper.getFlag(proposals[proposalId].flags, uint8(flag));
    }

    /**
     * MEMBERS
     */

    /**
     * @notice Sets true for the JAILED flag.
     * @param memberAddress The address of the member to update the flag.
     */
    function jailMember(address memberAddress)
        external
        hasAccess(this, AclFlag.JAIL_MEMBER)
    {
        require(memberAddress != address(0x0), "invalid member address");

        Member storage member = members[memberAddress];
        require(
            DaoHelper.getFlag(member.flags, uint8(MemberFlag.EXISTS)),
            "member does not exist"
        );

        member.flags = DaoHelper.setFlag(
            member.flags,
            uint8(MemberFlag.JAILED),
            true
        );
    }

    /**
     * @notice Sets false for the JAILED flag.
     * @param memberAddress The address of the member to update the flag.
     */
    function unjailMember(address memberAddress)
        external
        hasAccess(this, AclFlag.JAIL_MEMBER)
    {
        require(memberAddress != address(0x0), "invalid member address");

        Member storage member = members[memberAddress];
        require(
            DaoHelper.getFlag(member.flags, uint8(MemberFlag.EXISTS)),
            "member does not exist"
        );

        member.flags = DaoHelper.setFlag(
            member.flags,
            uint8(MemberFlag.JAILED),
            false
        );
    }

    /**
     * @notice Checks if a given member address is not jailed.
     * @param memberAddress The address of the member to check the flag.
     */
    function notJailed(address memberAddress) external view returns (bool) {
        return
            !DaoHelper.getFlag(
                members[memberAddress].flags,
                uint8(MemberFlag.JAILED)
            );
    }

    /**
     * @notice Registers a member address in the DAO if it is not registered or invalid.
     * @notice A potential new member is a member that holds no shares, and its registration still needs to be voted on.
     */
    function potentialNewMember(address memberAddress)
        public
        hasAccess(this, AclFlag.NEW_MEMBER)
    {
        require(memberAddress != address(0x0), "invalid member address");

        Member storage member = members[memberAddress];
        if (!DaoHelper.getFlag(member.flags, uint8(MemberFlag.EXISTS))) {
            require(
                memberAddressesByDelegatedKey[memberAddress] == address(0x0),
                "member address already taken as delegated key"
            );
            member.flags = DaoHelper.setFlag(
                member.flags,
                uint8(MemberFlag.EXISTS),
                true
            );
            memberAddressesByDelegatedKey[memberAddress] = memberAddress;
            _members.push(memberAddress);
        }

        address bankAddress = extensions[DaoHelper.BANK];
        if (bankAddress != address(0x0)) {
            BankExtension bank = BankExtension(bankAddress);
            if (bank.balanceOf(memberAddress, DaoHelper.MEMBER_COUNT) == 0) {
                bank.addToBalance(
                    this,
                    memberAddress,
                    DaoHelper.MEMBER_COUNT,
                    1
                );
            }
        }
    }

    /**
     * @return Whether or not a given address is a member of the DAO.
     * @dev it will resolve by delegate key, not member address.
     * @param addr The address to look up
     */
    function isMember(address addr) external view returns (bool) {
        address memberAddress = memberAddressesByDelegatedKey[addr];
        return getMemberFlag(memberAddress, MemberFlag.EXISTS);
    }

    /**
     * @return Whether or not a flag is set for a given member
     * @param memberAddress The member to check against flag
     * @param flag The flag to check in the member
     */
    function getMemberFlag(address memberAddress, MemberFlag flag)
        public
        view
        returns (bool)
    {
        return DaoHelper.getFlag(members[memberAddress].flags, uint8(flag));
    }

    /**
     * @notice Returns the number of members in the registry.
     */
    function getNbMembers() external view returns (uint256) {
        return _members.length;
    }

    /**
     * @notice Returns the member address for the given index.
     */
    function getMemberAddress(uint256 index) external view returns (address) {
        return _members[index];
    }

    /**
     * DELEGATE
     */

    /**
     * @notice Updates the delegate key of a member
     * @param memberAddr The member doing the delegation
     * @param newDelegateKey The member who is being delegated to
     */
    function updateDelegateKey(address memberAddr, address newDelegateKey)
        external
        hasAccess(this, AclFlag.UPDATE_DELEGATE_KEY)
    {
        require(newDelegateKey != address(0x0), "newDelegateKey cannot be 0");

        // skip checks if member is setting the delegate key to their member address
        if (newDelegateKey != memberAddr) {
            require(
                // newDelegate must not be delegated to
                memberAddressesByDelegatedKey[newDelegateKey] == address(0x0),
                "cannot overwrite existing delegated keys"
            );
        } else {
            require(
                memberAddressesByDelegatedKey[memberAddr] == address(0x0),
                "address already taken as delegated key"
            );
        }

        Member storage member = members[memberAddr];
        require(
            DaoHelper.getFlag(member.flags, uint8(MemberFlag.EXISTS)),
            "member does not exist"
        );

        // Reset the delegation of the previous delegate
        memberAddressesByDelegatedKey[
            getCurrentDelegateKey(memberAddr)
        ] = address(0x0);

        memberAddressesByDelegatedKey[newDelegateKey] = memberAddr;

        _createNewDelegateCheckpoint(memberAddr, newDelegateKey);
        emit UpdateDelegateKey(memberAddr, newDelegateKey);
    }

    /**
     * @param checkAddr The address to check for a delegate
     * @return the delegated address or the checked address if it is not a delegate
     */
    function getAddressIfDelegated(address checkAddr)
        external
        view
        returns (address)
    {
        address delegatedKey = memberAddressesByDelegatedKey[checkAddr];
        return delegatedKey == address(0x0) ? checkAddr : delegatedKey;
    }

    /**
     * @param memberAddr The member whose delegate will be returned
     * @return the delegate key at the current time for a member
     */
    function getCurrentDelegateKey(address memberAddr)
        public
        view
        returns (address)
    {
        uint32 nCheckpoints = _numCheckpoints[memberAddr];
        return
            nCheckpoints > 0
                ? _checkpoints[memberAddr][nCheckpoints - 1].delegateKey
                : memberAddr;
    }

    /**
     * @param memberAddr The member address to look up
     * @return The delegate key address for memberAddr at the second last checkpoint number
     */
    function getPreviousDelegateKey(address memberAddr)
        external
        view
        returns (address)
    {
        uint32 nCheckpoints = _numCheckpoints[memberAddr];
        return
            nCheckpoints > 1
                ? _checkpoints[memberAddr][nCheckpoints - 2].delegateKey
                : memberAddr;
    }

    /**
     * @notice Determine the prior number of votes for an account as of a block number
     * @dev Block number must be a finalized block or else this function will revert to prevent misinformation.
     * @param memberAddr The address of the account to check
     * @param blockNumber The block number to get the vote balance at
     * @return The delegate key of the member
     */
    function getPriorDelegateKey(address memberAddr, uint256 blockNumber)
        external
        view
        returns (address)
    {
        require(blockNumber < block.number, "getPriorDelegateKey: NYD");

        uint32 nCheckpoints = _numCheckpoints[memberAddr];
        if (nCheckpoints == 0) {
            return memberAddr;
        }

        // First check most recent balance
        if (
            _checkpoints[memberAddr][nCheckpoints - 1].fromBlock <= blockNumber
        ) {
            return _checkpoints[memberAddr][nCheckpoints - 1].delegateKey;
        }

        // Next check implicit zero balance
        if (_checkpoints[memberAddr][0].fromBlock > blockNumber) {
            return memberAddr;
        }

        uint32 lower = 0;
        uint32 upper = nCheckpoints - 1;
        while (upper > lower) {
            uint32 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
            DelegateCheckpoint memory cp = _checkpoints[memberAddr][center];
            if (cp.fromBlock == blockNumber) {
                return cp.delegateKey;
            } else if (cp.fromBlock < blockNumber) {
                lower = center;
            } else {
                upper = center - 1;
            }
        }
        return _checkpoints[memberAddr][lower].delegateKey;
    }

    /**
     * @notice Creates a new delegate checkpoint of a certain member
     * @param member The member whose delegate checkpoints will be added to
     * @param newDelegateKey The delegate key that will be written into the new checkpoint
     */
    function _createNewDelegateCheckpoint(
        address member,
        address newDelegateKey
    ) internal {
        uint32 nCheckpoints = _numCheckpoints[member];
        // The only condition that we should allow the deletegaKey upgrade
        // is when the block.number exactly matches the fromBlock value.
        // Anything different from that should generate a new checkpoint.
        if (
            //slither-disable-next-line incorrect-equality
            nCheckpoints > 0 &&
            _checkpoints[member][nCheckpoints - 1].fromBlock == block.number
        ) {
            _checkpoints[member][nCheckpoints - 1].delegateKey = newDelegateKey;
        } else {
            _checkpoints[member][nCheckpoints] = DelegateCheckpoint(
                uint96(block.number),
                newDelegateKey
            );
            _numCheckpoints[member] = nCheckpoints + 1;
        }
    }
}

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT

import "../../core/DaoRegistry.sol";

/**
MIT License

Copyright (c) 2020 Openlaw

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
 */

interface IReimbursement {
    function reimburseTransaction(
        DaoRegistry dao,
        address payable caller,
        uint256 gasUsage,
        uint256 spendLimitPeriod
    ) external;

    function shouldReimburse(DaoRegistry dao, uint256 gasLeft)
        external
        view
        returns (bool, uint256);
}

pragma solidity ^0.8.0;

import "../../core/DaoRegistry.sol";
import "../../companion/interfaces/IReimbursement.sol";
import "./Reimbursable.sol";

// SPDX-License-Identifier: MIT

/**
MIT License

Copyright (c) 2021 Openlaw

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
 */
library ReimbursableLib {
    function beforeExecution(DaoRegistry dao)
        internal
        returns (Reimbursable.ReimbursementData memory data)
    {
        data.gasStart = gasleft();
        require(dao.lockedAt() != block.number, "reentrancy guard");
        dao.lockSession();
        address reimbursementAdapter = dao.adapters(DaoHelper.REIMBURSEMENT);
        if (reimbursementAdapter == address(0x0)) {
            data.shouldReimburse = false;
        } else {
            data.reimbursement = IReimbursement(reimbursementAdapter);

            (bool shouldReimburse, uint256 spendLimitPeriod) = data
                .reimbursement
                .shouldReimburse(dao, data.gasStart);

            data.shouldReimburse = shouldReimburse;
            data.spendLimitPeriod = spendLimitPeriod;
        }
    }

    function afterExecution(
        DaoRegistry dao,
        Reimbursable.ReimbursementData memory data
    ) internal {
        afterExecution2(dao, data, payable(msg.sender));
    }

    function afterExecution2(
        DaoRegistry dao,
        Reimbursable.ReimbursementData memory data,
        address payable caller
    ) internal {
        if (data.shouldReimburse) {
            data.reimbursement.reimburseTransaction(
                dao,
                caller,
                data.gasStart - gasleft(),
                data.spendLimitPeriod
            );
        }
        dao.unlockSession();
    }
}

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT

import "../../core/DaoRegistry.sol";
import "../../companion/interfaces/IReimbursement.sol";
import "./ReimbursableLib.sol";

/**
MIT License

Copyright (c) 2021 Openlaw

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
 */
abstract contract Reimbursable {
    struct ReimbursementData {
        uint256 gasStart; // how much gas is left before executing anything
        bool shouldReimburse; // should the transaction be reimbursed or not ?
        uint256 spendLimitPeriod; // how long (in seconds) is the spend limit period
        IReimbursement reimbursement; // which adapter address is used for reimbursement
    }

    /**
     * @dev Only registered adapters are allowed to execute the function call.
     */
    modifier reimbursable(DaoRegistry dao) {
        ReimbursementData memory data = ReimbursableLib.beforeExecution(dao);
        _;
        ReimbursableLib.afterExecution(dao, data);
    }
}

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT

import "../../core/DaoRegistry.sol";

/**
MIT License

Copyright (c) 2020 Openlaw

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
 */

interface IVoting {
    enum VotingState {
        NOT_STARTED,
        TIE,
        PASS,
        NOT_PASS,
        IN_PROGRESS,
        GRACE_PERIOD
    }

    function getAdapterName() external pure returns (string memory);

    function startNewVotingForProposal(
        DaoRegistry dao,
        bytes32 proposalId,
        bytes calldata data
    ) external;

    function getSenderAddress(
        DaoRegistry dao,
        address actionId,
        bytes memory data,
        address sender
    ) external returns (address);

    function voteResult(DaoRegistry dao, bytes32 proposalId)
        external
        returns (VotingState state);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}