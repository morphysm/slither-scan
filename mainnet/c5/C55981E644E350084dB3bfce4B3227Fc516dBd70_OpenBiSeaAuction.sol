// SPDX-License-Identifier: UNLICENSED
// (c) Oleksii Vynogradov 2021, All rights reserved, contact [email protected] if you like to use code
pragma solidity ^0.6.8;
import "./access/TeamRole.sol";
import "./utils/EnumerableUintSet.sol";
import "./utils/EnumerableSet.sol";
import "./math/SafeMath.sol";
import "./interface/IERC721.sol";
import "./interface/IERC1155.sol";
import "./interface/IERC721Receiver.sol";
import "./interface/IERC1155Receiver.sol";
import "./interface/IERC20.sol";
import "./interface/IPoolRegistry.sol";

contract OpenBiSeaAuction is TeamRole,IERC721Receiver,IERC1155Receiver {

    uint256 private _totalIncomeNFT;
    uint256 private _initialPriceInt;
    uint256 private _auctionCreationFeeMultiplier;
    uint256 private _auctionContractFeeMultiplier;
    address private _tokenForTokensale;
    address private _openBiSeaMainContract;
    address private _busdContract;
    IPoolRegistry private _poolRegistry;

    constructor (
        uint256 initialPriceInt,
        uint256 auctionCreationFeeMultiplier,
        uint256 auctionContractFeeMultiplier,
        address tokenForTokensale,
        address openBiSeaMainContract,
        address busdContract,
        address poolRegistry
    ) public {
        _initialPriceInt = initialPriceInt;
        _auctionCreationFeeMultiplier = auctionCreationFeeMultiplier;
        _auctionContractFeeMultiplier = auctionContractFeeMultiplier;
        _tokenForTokensale = tokenForTokensale;
        _openBiSeaMainContract = openBiSeaMainContract;
        _busdContract = busdContract;
        _poolRegistry = IPoolRegistry(poolRegistry);
    }

    mapping(address => uint256) private _consumersRevenueAmount;

    using SafeMath for uint256;

    using EnumerableUintSet for EnumerableUintSet.UintSet;
    using EnumerableSet for EnumerableSet.AddressSet;

    EnumerableSet.AddressSet private _contractsWhitelisted;
    event ContractNFTWhitelisted(address indexed contractNFT);
    event ContractNFTDeWhitelisted(address indexed contractNFT);

    function isContractNFTWhitelisted( address _contractNFT ) public view returns (bool) {
        return _contractsWhitelisted.contains(_contractNFT);
    }
    function contractsNFTWhitelisted() public view returns (address[] memory) {
        return _contractsWhitelisted.collection();
    }

    function whitelistContractAdmin( address _contractNFT ) public onlyTeam {
        _contractsWhitelisted.add(_contractNFT);
        emit ContractNFTWhitelisted(_contractNFT);
    }
    function deWhitelistContractAdmin( address _contractNFT ) public onlyTeam {
        _contractsWhitelisted.remove(_contractNFT);
        emit ContractNFTDeWhitelisted(_contractNFT);
    }

    function setAuctionCreationFeeMultiplierAdmin( uint256 auctionCreationFeeMultiplier ) public onlyTeam {
        _auctionCreationFeeMultiplier = auctionCreationFeeMultiplier;
    }

    function whitelistContractCreator( address _contractNFT, uint256 fee ) public  {
        require(msg.sender == _openBiSeaMainContract, "OpenBiSea: only main contract can send it");
        _totalIncomeNFT = _totalIncomeNFT.add(fee);
        _contractsWhitelisted.add(_contractNFT);
        emit ContractNFTWhitelisted(_contractNFT);
    }

    function whitelistContractCreatorTokens( address _contractNFT, uint256 fee ) public {
        require(msg.sender == _openBiSeaMainContract, "OpenBiSea: only main contract can send it");
        _totalIncomeNFT = _totalIncomeNFT.add(fee);
        _contractsWhitelisted.add(_contractNFT);
        emit ContractNFTWhitelisted(_contractNFT);
    }

    struct Auction {
        address seller;
        address latestBidder;
        uint256 latestBidTime;
        uint256 deadline;
        uint256 price;
        bool isUSD;
    }

    mapping(uint256 => Auction) private _contractsPlusTokenIdsAuction;
    mapping(address => EnumerableUintSet.UintSet) private _contractsTokenIdsList;
    mapping(address => uint256) private _consumersDealFirstDate;
    mapping(uint256 => address) private _auctionIDtoSellerAddress;

    function getNFTsAuctionList( address _contractNFT) public view returns (uint256[] memory) {
        return _contractsTokenIdsList[_contractNFT].collection();
    }
    function sellerAddressFor( uint256 _auctionID) public view returns (address) {
        return _auctionIDtoSellerAddress[_auctionID];
    }

    function revenueFor( address _consumer) public view returns (uint256) {
        return _consumersRevenueAmount[_consumer];
    }
    function getAuction(
        address _contractNFT,
        uint256 _tokenId
    ) public view returns
    (
        address seller,
        address latestBidder,
        uint256 latestBidTime,
        uint256 deadline,
        uint price,
        bool isUSD
    ) {
        uint256 index = uint256(_contractNFT).add(_tokenId);
        return (
        _contractsPlusTokenIdsAuction[index].seller,
        _contractsPlusTokenIdsAuction[index].latestBidder,
        _contractsPlusTokenIdsAuction[index].latestBidTime,
        _contractsPlusTokenIdsAuction[index].deadline,
        _contractsPlusTokenIdsAuction[index].price,
        _contractsPlusTokenIdsAuction[index].isUSD);
    }

    event AuctionNFTCreated(address indexed contractNFT, uint256 tokenId,uint256 price,uint256 deadline, bool isERC1155,address seller, bool isUSD);

    function createAuction( address _contractNFT, uint256 _tokenId, uint256 _price, uint256 _deadline, bool _isERC1155, address _sender, bool _isUSD ) public {
        require(msg.sender == _openBiSeaMainContract, "OpenBiSea: only main contract can send it");
        require(_contractsWhitelisted.contains(_contractNFT), "OpenBiSea: contract must be whitelisted");
        require(!_contractsTokenIdsList[_contractNFT].contains(uint256(_sender).add(_tokenId)), "OpenBiSea: auction is already created");
        require(IERC20(_tokenForTokensale).balanceOf(_sender) >= (10 ** uint256(18)).mul(_auctionCreationFeeMultiplier).div(10000), "OpenBiSea: you must have 1 OBS on account to start");
        if (_isERC1155) {
            IERC1155(_contractNFT).safeTransferFrom( _sender, address(this), _tokenId,1, "0x0");
        } else {
            IERC721(_contractNFT).safeTransferFrom( _sender, address(this), _tokenId);
        }
        Auction memory _auction = Auction({
            seller: _sender,
            latestBidder: address(0),
            latestBidTime: 0,
            deadline: _deadline,
            price:_price,
            isUSD:_isUSD
        });
        _contractsPlusTokenIdsAuction[uint256(_contractNFT).add(_tokenId)] = _auction;
        _auctionIDtoSellerAddress[uint256(_sender).add(_tokenId)] = _sender;
        _contractsTokenIdsList[_contractNFT].add(uint256(_sender).add(_tokenId));
        emit AuctionNFTCreated( _contractNFT, _tokenId, _price, _deadline, _isERC1155, _sender, _isUSD);
    }
    function updateFirstDateAndValue(address buyer, address seller, uint256 value, bool isUSD) private {
        uint256 valueFinal = value;
        if (isUSD) {
            uint256 priceMainToUSD;
            uint8 decimals;
            (priceMainToUSD,decimals) = _poolRegistry.getOracleContract().getLatestPrice();
//            uint256 tokensToPay;
            valueFinal = value.div((priceMainToUSD).div(10 ** uint256(decimals)));
        }
        _totalIncomeNFT = _totalIncomeNFT.add(valueFinal);
        _consumersRevenueAmount[buyer] = _consumersRevenueAmount[buyer].add(value);
        _consumersRevenueAmount[seller] = _consumersRevenueAmount[seller].add(value);
        if (_consumersDealFirstDate[buyer] == 0) {
            _consumersDealFirstDate[buyer] = now;
        }
        if (_consumersDealFirstDate[seller] == 0) {
            _consumersDealFirstDate[seller] = now;
        }
    }
    event AuctionNFTBid(address indexed contractNFT, uint256 tokenId,uint256 price,uint256 deadline, bool isERC1155,address buyer,address seller, bool isDeal, bool isUSD);

    function _bidWin (
        bool _isERC1155,
        address _contractNFT,
        address _sender,
        uint256 _tokenId,
        address _auctionSeller,
        uint256 _price,
        bool _auctionIsUSD,
        uint256 _deadline

    ) private  {
        if (_isERC1155) {
            IERC1155(_contractNFT).safeTransferFrom( address(this), _sender, _tokenId, 1, "0x0");
        } else {
            IERC721(_contractNFT).safeTransferFrom( address(this), _sender, _tokenId);
        }
        updateFirstDateAndValue(_sender, _auctionSeller, _price, _auctionIsUSD);
        emit AuctionNFTBid(_contractNFT,_tokenId,_price,_deadline,_isERC1155,_sender,_auctionSeller, true, _auctionIsUSD);
        delete _contractsPlusTokenIdsAuction[ uint256(_contractNFT).add(_tokenId)];
        delete _auctionIDtoSellerAddress[uint256(_auctionSeller).add(_tokenId)];
        _contractsTokenIdsList[_contractNFT].remove(uint256(_auctionSeller).add(_tokenId));
    }
    function bid( address _contractNFT,uint256 _tokenId, uint256 _price, bool _isERC1155, address _sender ) public returns (bool, uint256, address, bool) {
        require(msg.sender == _openBiSeaMainContract, "OpenBiSea: only main contract can send it");
        require(_contractsWhitelisted.contains(_contractNFT), "OpenBiSea: contract must be whitelisted");
        Auction storage auction = _contractsPlusTokenIdsAuction[uint256(_contractNFT).add(_tokenId)];
        require(auction.seller != address(0), "OpenBiSea: wrong seller address");
        require(_contractsTokenIdsList[_contractNFT].contains(uint256(auction.seller).add(_tokenId)), "OpenBiSea: auction is not created"); // ERC1155 can have more than 1 auction with same ID and , need mix tokenId with seller address
        require(_price >= auction.price, "OpenBiSea: price must be more than previous bid");

        if (block.timestamp > auction.deadline) {
            address auctionSeller = address(auction.seller);
            bool auctionIsUSD = bool(auction.isUSD);
            _bidWin(
                _isERC1155,
                _contractNFT,
                _sender,
                _tokenId,
                auctionSeller,
                _price,
                auctionIsUSD,
                auction.deadline
            );
            return (true,0,auctionSeller,auctionIsUSD);
        } else {
            auction.price = _price;
            auction.latestBidder = _sender;
            auction.latestBidTime = block.timestamp;
            emit AuctionNFTBid(_contractNFT,_tokenId,_price,auction.deadline,_isERC1155,_sender,auction.seller, false, auction.isUSD);
            if (auction.latestBidder != address(0)) {
                return (false,auction.price,auction.latestBidder,auction.isUSD);
            }
        }
        return (false,0, address(0),false);
    }
    event AuctionNFTCanceled(address indexed contractNFT, uint256 tokenId,uint256 price,uint256 deadline, bool isERC1155,address seller);

    function _cancelAuction( address _contractNFT, uint256 _tokenId, address _sender, bool _isERC1155, bool _isAdmin ) private {
        uint256 index = uint256(_contractNFT).add(_tokenId);

        Auction storage auction = _contractsPlusTokenIdsAuction[index];
        if (!_isAdmin) require(auction.seller == _sender, "OpenBiSea: only seller can cancel");
        if (_isERC1155) {
            IERC1155(_contractNFT).safeTransferFrom(address(this),auction.seller, _tokenId,1,"0x0");
        } else {
            IERC721(_contractNFT).safeTransferFrom(address(this),auction.seller, _tokenId);
        }
        address auctionSeller = address(auction.seller);
        emit AuctionNFTCanceled(_contractNFT,_tokenId,auction.price,auction.deadline,_isERC1155,auction.seller);
        delete _contractsPlusTokenIdsAuction[index];
        delete _auctionIDtoSellerAddress[uint256(auctionSeller).add(_tokenId)];
        _contractsTokenIdsList[_contractNFT].remove(uint256(auctionSeller).add(_tokenId));
    }

    function cancelAuction( address _contractNFT, uint256 _tokenId, address _sender , bool _isERC1155 ) public {
        require(msg.sender == _openBiSeaMainContract, "OpenBiSea: only main contract can send it");
        require(_contractsWhitelisted.contains(_contractNFT), "OpenBiSea: contract must be whitelisted");
        require(_contractsTokenIdsList[_contractNFT].contains(uint256(_sender).add(_tokenId)), "OpenBiSea: auction is not created");
        _cancelAuction( _contractNFT, _tokenId, _sender, _isERC1155, false );
    }
    function cancelAuctionAdmin( address _contractNFT, uint256 _tokenId, bool _isERC1155 ) public onlyTeam {
        _cancelAuction( _contractNFT, _tokenId, address(0) , _isERC1155, true );
    }
    mapping(address => uint256) private _consumersReceivedMainTokenLatestDate;
    uint256 minimalTotalIncome1 = 10000;
    uint256 minimalTotalIncome2 = 500000;
    uint256 minimalTotalIncome3 = 5000000;
    function _tokensToDistribute(uint256 amountTotalUSDwei, uint256 priceMainToUSD, bool newInvestor) private view returns (uint256,uint256) {
        uint256 balanceLeavedOnThisContractProjectTokens = IERC20(_tokenForTokensale).balanceOf(_openBiSeaMainContract);/* if total sales > $10k and < $500k, balanceLeavedOnThisContractProjectTokens = balanceLeavedOnThisContractProjectTokens * 0.1%   if total sales >  $500k and total sales < $5M, balanceLeavedOnThisContractProjectTokens = balanceLeavedOnThisContractProjectTokens * 1% if total sales >  $5M, balanceLeavedOnThisContractProjectTokens = balanceLeavedOnThisContractProjectTokens * 10% */
        uint256 totalIncomeUSDwei = _totalIncomeNFT.mul(priceMainToUSD);
        if (totalIncomeUSDwei < minimalTotalIncome1.mul(10 ** uint256(18))) {
            balanceLeavedOnThisContractProjectTokens = balanceLeavedOnThisContractProjectTokens.div(10000); // balanceLeavedOnThisContractProjectTokens = 0;
        } else if (totalIncomeUSDwei < minimalTotalIncome2.mul(10 ** uint256(18))) {
            balanceLeavedOnThisContractProjectTokens = balanceLeavedOnThisContractProjectTokens.div(1000);
        } else if (totalIncomeUSDwei < minimalTotalIncome3.mul(10 ** uint256(18))) {
            balanceLeavedOnThisContractProjectTokens = balanceLeavedOnThisContractProjectTokens.div(30);
        } else {
            balanceLeavedOnThisContractProjectTokens = balanceLeavedOnThisContractProjectTokens.div(10);
        } /*  amountTotalUSD / TAV - his percent of TAV balanceLeavedOnThisContractProjectTokens * his percent of pool = amount of tokens to pay if (newInvestor) amount of tokens to pay = amount of tokens to pay * 1.1 _investorsReceivedMainToken[msg.sender][time] = amount of tokens to pay*/
        uint256 percentOfSales = amountTotalUSDwei.mul(10000).div(totalIncomeUSDwei);
        if (newInvestor) {
            return (balanceLeavedOnThisContractProjectTokens.mul(percentOfSales).div(10000).mul(11).div(10),percentOfSales);
        } else {
            return (balanceLeavedOnThisContractProjectTokens.mul(percentOfSales).div(10000),percentOfSales);
        }
    }

    function checkTokensForClaim( address customer, uint256 priceMainToUSD) public view returns (uint256,uint256,uint256,bool) {
        uint256 amountTotalUSDwei = _consumersRevenueAmount[customer].mul(priceMainToUSD);
        if (amountTotalUSDwei == 0) {
            return (0,0,0,false);
        }
        uint256 tokensForClaim;
        uint256 percentOfSales;
        bool newCustomer = ((now.sub(_consumersDealFirstDate[customer])) < 4 weeks);
        if (_consumersReceivedMainTokenLatestDate[customer] > now.sub(4 weeks)) {
            return (tokensForClaim,amountTotalUSDwei,percentOfSales,newCustomer);// already receive reward 4 weeks ago
        }
        (tokensForClaim, percentOfSales) = _tokensToDistribute(amountTotalUSDwei,priceMainToUSD,newCustomer);
        return (tokensForClaim,amountTotalUSDwei,percentOfSales,newCustomer);
    }
    function setConsumersReceivedMainTokenLatestDate(address _sender) public {
        require(msg.sender == _openBiSeaMainContract, "OpenBiSea: only main contract can send it");
        _consumersReceivedMainTokenLatestDate[_sender] = now;
    }

    /**
     * Always returns `IERC721Receiver.onERC721Received.selector`.
    */
    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    )
    external
    override
    returns(bytes4)
    {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    )
    external
    override
    returns(bytes4)
    {
        return this.onERC1155BatchReceived.selector;
    }
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return this.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: UNLICENSED
// (c) Oleksii Vynogradov 2021, All rights reserved, contact [email protected] if you like to use code
pragma solidity ^0.6.8;
import "./lib/Roles.sol";
contract TeamRole {
    using Roles for Roles.Role;
    event TeamAdded(address indexed account);
    event TeamRemoved(address indexed account);
    event OracleAdded(address indexed account);
    event OracleRemoved(address indexed account);
    Roles.Role private _team;
    Roles.Role private _oracle;
    constructor () internal {
        _addTeam(msg.sender);
    }
    modifier onlyTeam() {
        require(isTeam(msg.sender), "TeamRole: caller does not have the Team role");
        _;
    }
    modifier onlyRegistryOracle() {
        require(isOracle(msg.sender), "TeamRole: caller does not have the Oracle role");
        _;
    }

    function isOracle(address account) public view returns (bool) {
        return _oracle.has(account);
    }
    function getOracleAddresses() public view returns (address[] memory) {
        return _oracle.accounts;
    }

    function addOracle(address account) public onlyTeam {
        _addOracle(account);
    }
    function _addOracle(address account) internal {
        _oracle.add(account);
        emit OracleAdded(account);
    }
    function renounceOracle() public {
        _removeOracle(msg.sender);
    }
    function _removeOracle(address account) internal {
        _oracle.remove(account);
        emit OracleRemoved(account);
    }

    function isTeam(address account) public view returns (bool) {
        return _team.has(account);
    }
    function getTeamAddresses() public view returns (address[] memory) {
        return _team.accounts;
    }
    function addTeam(address account) public onlyTeam {
        _addTeam(account);
    }
    function renounceTeam() public onlyTeam {
        _removeTeam(msg.sender);
    }
    function _addTeam(address account) internal {
        _team.add(account);
        emit TeamAdded(account);
    }
    function _removeTeam(address account) internal {
        _team.remove(account);
        emit TeamRemoved(account);
    }
}

// SPDX-License-Identifier: UNLICENSED
// (c) Oleksii Vynogradov 2021, All rights reserved, contact [email protected] if you like to use code
pragma solidity ^0.6.8;
library Roles {
    struct Role {
        address[] accounts;
        mapping (address => bool) bearer;
        mapping (bytes32 => uint256) _indexes;
    }
    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
        role.accounts.push(account);
        role._indexes[bytes32(uint256(account))] = role.accounts.length;
    }
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        uint256 valueIndex = role._indexes[bytes32(uint256(account))];
        if (valueIndex != 0) { // Equivalent to contains()
            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = role.accounts.length - 1;
            address lastValue = role.accounts[lastIndex];
            role.accounts[toDeleteIndex] = lastValue;
            role.accounts.pop();
            delete role._indexes[bytes32(uint256(account))];
        }
//        for (uint256 i; i < role.accounts.length; i++) {
//            if (role.accounts[i] == account) {
//                _removeIndexArray(i, role.accounts);
//                break;
//            }
//        }
        role.bearer[account] = false;
    }
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
//    function _removeIndexArray(uint256 index, address[] storage array) internal virtual {
//        for(uint256 i = index; i < array.length-1; i++) {
//            array[i] = array[i+1];
//        }
//        array.pop();
//    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

import "./IERC165.sol";

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
    event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values);

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
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids) external view returns (uint256[] memory);

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
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;

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
    function safeBatchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC165.sol";

/**
 * _Available since v3.1._
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
    )
        external
        returns(bytes4);

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
    )
        external
        returns(bytes4);
}

// SPDX-License-Identifier: UNLICENSED
// (c) Oleksii Vynogradov 2021, All rights reserved, contact [email protected] if you like to use code
pragma solidity ^0.6.8;

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

// SPDX-License-Identifier: UNLICENSED
// (c) Oleksii Vynogradov 2021, All rights reserved, contact [email protected] if you like to use code
pragma solidity ^0.6.8;
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function decimals() external view returns (uint8);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: UNLICENSED
// (c) Oleksii Vynogradov 2021, All rights reserved, contact [email protected] if you like to use code
pragma solidity ^0.6.8;

import "./IERC165.sol";

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
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

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
    function transferFrom(address from, address to, uint256 tokenId) external;

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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

// SPDX-License-Identifier: UNLICENSED
// (c) Oleksii Vynogradov 2021, All rights reserved, contact [email protected] if you like to use code
pragma solidity ^0.6.8;
interface IOracle {
    function getLatestPrice() external view returns ( uint256,uint8);
    function getCustomPrice(address aggregator) external view returns (uint256,uint8);
}

// SPDX-License-Identifier: UNLICENSED
// (c) Oleksii Vynogradov 2021, All rights reserved, contact [email protected] if you like to use code
pragma solidity ^0.6.8;
import "./IOracle.sol";
interface IPoolRegistry {
    function isTeam(address account) external view returns (bool);
    function getTeamAddresses() external view returns (address[] memory);
    function getOracleContract() external view returns (IOracle);
    function feesMultipier(address sender) external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
// (c) Oleksii Vynogradov 2021, All rights reserved, contact [email protected] if you like to use code
pragma solidity ^0.6.8;
library SafeMath {
     function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
         if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
}

// SPDX-License-Identifier: UNLICENSED
// (c) Oleksii Vynogradov 2021, All rights reserved, contact [email protected] if you like to use code
pragma solidity ^0.6.8;
library EnumerableSet {
    struct Set {
        bytes32[] _values;
        address[] _collection;
        mapping (bytes32 => uint256) _indexes;
    }
    function _add(Set storage set, bytes32 value, address addressValue) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            set._collection.push(addressValue);
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        uint256 valueIndex = set._indexes[value];
        if (valueIndex != 0) { // Equivalent to contains(set, value)
            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;
            bytes32 lastValue = set._values[lastIndex];
            set._values[toDeleteIndex] = lastValue;
            set._values.pop();

            address lastvalueAddress = set._collection[lastIndex];
            set._collection[toDeleteIndex] = lastvalueAddress;
            set._collection.pop();

            set._indexes[lastValue] = toDeleteIndex + 1; // All indexes are 1-based
            delete set._indexes[value];
            return true;
        } else {
            return false;
        }
    }
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }
    function _collection(Set storage set) private view returns (address[] memory) {
        return set._collection;    
    }

    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }
    struct AddressSet {
        Set _inner;
    }
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(value)), value);
    }
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(value)));
    }
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(value)));
    }
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }
    function collection(AddressSet storage set) internal view returns (address[] memory) {
        return _collection(set._inner);
    }
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint256(_at(set._inner, index)));
    }
}

// SPDX-License-Identifier: UNLICENSED
// (c) Oleksii Vynogradov 2021, All rights reserved, contact [email protected] if you like to use code
pragma solidity ^0.6.8;
library EnumerableUintSet {
    struct Set {
        bytes32[] _values;
        uint256[] _collection;
        mapping (bytes32 => uint256) _indexes;
    }
    function _add(Set storage set, bytes32 value, uint256 savedValue) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            set._collection.push(savedValue);
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        uint256 valueIndex = set._indexes[value];
        if (valueIndex != 0) { // Equivalent to contains(set, value)
            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;
            bytes32 lastValue = set._values[lastIndex];
            set._values[toDeleteIndex] = lastValue;
            set._values.pop();

            uint256 lastvalueAddress = set._collection[lastIndex];
            set._collection[toDeleteIndex] = lastvalueAddress;
            set._collection.pop();

            set._indexes[lastValue] = toDeleteIndex + 1; // All indexes are 1-based
            delete set._indexes[value];
            return true;
        } else {
            return false;
        }
    }
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }
    function _collection(Set storage set) private view returns (uint256[] memory) {
        return set._collection;    
    }

    function _at(Set storage set, uint256 index) private view returns (uint256) {
        require(set._collection.length > index, "EnumerableSet: index out of bounds");
        return set._collection[index];
    }
    struct UintSet {
        Set _inner;
    }
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(value)), value);
    }
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(value)));
    }
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(value)));
    }
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }
    function collection(UintSet storage set) internal view returns (uint256[] memory) {
        return _collection(set._inner);
    }
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return _at(set._inner, index);
    }
}