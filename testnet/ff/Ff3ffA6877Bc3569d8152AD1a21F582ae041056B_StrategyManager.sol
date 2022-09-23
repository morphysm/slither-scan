// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
                                      
import {Ownable            } from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard    } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IERC20, SafeERC20  } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ICurrencyManager   } from "./interfaces/ICurrencyManager.sol";
import {IStrategyManager   } from "./interfaces/IStrategyManager.sol";
import {IExecutionStrategy } from "./interfaces/IExecutionStrategy.sol";
import {IRoyaltyFeeManager } from "./interfaces/IRoyaltyFeeManager.sol";
import {IExchange          } from "./interfaces/IExchange.sol";
import {ITransferManagerNFT} from "./interfaces/ITransferManagerNFT.sol";
import {ITransferSelector  } from "./interfaces/ITransferSelector.sol";
import {IWAVAX             } from "./interfaces/IWAVAX.sol";

import {OrderTypes         } from "./libraries/OrderTypes.sol";
import {SignatureChecker   } from "./libraries/SignatureChecker.sol";

                                                 /*                                                 
                                                 77                                                 
                                               .?YY?.                                               
                                              :AVASEA:                                              
                                             ~AVASEAAV~                                             
                                            !AVASEAAVAS!                                            
                                          .?AVASEAAVASEA?.                                          
                                         :AVASEAAVASEAAVAS:                                         
                                        :AVASEAAVASEAAVASEA~                                        
                                         ^AVASEAAVASEAAVASEA!                                       
                                          :?AVASEAAVASEAAVASE?.                                     
                                    ::     .AVASEAAVASEAAVASEAA^                                   .
                                   ~AV^      !AVASEAAVASEAAVASEAA~                                ^:
                                  AVASE~      ^AVASEAAVASEAAVASEAAV                             :7^ 
                                .?AVASEAA.     :?AVASEAAVASEAAVASEA?.                         :7?:  
                               ^JAVASEAAVAS:     .AVASEAAVASEAAVASEAA^                      :7A7.   
                              .~!AVASEAAVA!~       ~!AVASEAAVASEAAVAS!~.                 .~?AV~     
                                                                                      .^AVAS?:      
   .:^~^:.                                                                         .^AVASEA!.       
.~?AVASEAA?!:                                                                  .^!?AVASEA?^         
AVASEAAVASEAAV^                                                          .:^~7?AVASEAAVA!.          
^AVASEAAVASEAAV?:                                                 ..:^!7?AVASEAAVASEAA?:            
  .:^~7??AVASEAAVA:                                      ..:^~~!7?AVASEAAVASEAAVASEAAV^             
         ..::^^~~!!:^^:::::...............:::::^^~~!77??AVASEAAVASEAAVASEAAVASEAAVA~.               
                    :?AVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEA!.                
                      ~AVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAV!.                   
                       :AVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASE!.                     
                         ^AVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAA~.                       
                          .!AVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVA^                          
                            .!AVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVA?~.                            
                              :!AVASEAAVASEAAVASEAAVASEAAVASEAAVAS?!:                               
                                .~?AVASEAAVASEAAVASEAAVASEAAVASE~:                                  
                                   :!?AVASEAAVASEAAVASEAAV?7~:.                                     
                                      .^!7?AVASEAAVA?7!^:.*/        


contract AvaSeaExchange is IExchange, ReentrancyGuard, Ownable {

    // AVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEA
    // AVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEA
    // AVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEA

    using SafeERC20    for              IERC20                ;
    using OrderTypes   for              OrderTypes.MakerOrder ;
    using OrderTypes   for              OrderTypes.TakerOrder ;
    ICurrencyManager   public           currencyManager       ;
    IStrategyManager   public           strategyManager       ;
    IRoyaltyFeeManager public           royaltyFeeManager     ;
    ITransferSelector  public           transferSelector      ;
    address            public           feeRecipient          ;
    bool               public           paused                ;
    address            public immutable WAVAX                 ;
    bytes32            public immutable DOMAIN_SEPARATOR      ;

    mapping(address => uint256)                  public userMinOrderNonce;
    mapping(address => mapping(uint256 => bool)) private _isUserOrderNonceExecutedOrCancelled;

    // AVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEA
    // AVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEA
    // AVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEA

    event CurrencyManagerUpdate   (address indexed currencyManager);
    event StrategyManagerUpdate   (address indexed strategyManager);
    event RoyaltyFeeManagerUpdate (address indexed royaltyFeeManager);
    event CancelOrdersBelowNonce  (address indexed user, uint256 newMinNonce);
    event TransferSelectorUpdate  (address indexed transferSelectorNFT);
    event FeeRecipientUpdate      (address indexed protocolFeeRecipient);
    event CancelMultipleOrders    (address indexed user, uint256[] orderNonces);
    event RoyaltyFeeTransfer      (address indexed collection, uint256 indexed tokenId, address indexed royaltyRecipient, address currency, uint256 amount);

    event TakerAsk                (bytes32 orderHash, uint256 orderNonce, address indexed taker, address indexed maker, address indexed strategy,
                                   address currency, address collection, uint256 tokenId, uint256 amount, uint256 price);

    event TakerBid                (bytes32 orderHash, uint256 orderNonce, address indexed taker, address indexed maker, address indexed strategy,
                                   address currency, address collection, uint256 tokenId, uint256 amount, uint256 price);

    // AVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEA
    // AVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEA
    // AVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEA

    constructor(
        address _currencyManager,
        address _strategyManager,
        address _royaltyFeeManager,
        address _WAVAX,
        address _feeRecipient
    ) {
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f, // keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)")
                0x51ad4688d60759b766bf485a3a7bbdd63f5e5c9085a9cca8a05a996b205c96ac, // keccak256("AvaSeaExchange")
                0xc89efdaa54c0f20c7adf612882df0950f5a951637e0307cdcb4c672f298b8bc6, // keccak256(bytes("1")) for versionId = 1
                block.chainid, // chain ID
                address(this) // this contract address
            )
        );

        royaltyFeeManager = IRoyaltyFeeManager(_royaltyFeeManager);
        currencyManager   = ICurrencyManager(_currencyManager);
        strategyManager   = IStrategyManager(_strategyManager);
        feeRecipient      = _feeRecipient;
        WAVAX             = _WAVAX;
        paused            = false;
    }

    // AVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEA
    // AVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEA
    // EXCHANGECOREEXCHANGECOREEXCHANGECOREEXCHANGECOREEXCHANGECOREEXCHANGECOREEXCHANGECOREEXCHANGECOREEXCHANGECOREEXCHANGECOREEXCHANGECOREEXCHANGECOREEXCHANGECOREEXCHANGECOREEXCHAN

    /**
     *
     * @param nonce uint256 nonce 
     * @notice sets all orders below the nonce to be invalid
     */
    function cancelOrdersBelowNonce(uint256 nonce) external {
        require(nonce > userMinOrderNonce[msg.sender], "Exchange: {cancelOrdersBelowNonce} nonce lower than sender current nonce");
        require(nonce < userMinOrderNonce[msg.sender] + 999999, "Exchange: {cancelOrdersBelowNonce} too many orders " );
        userMinOrderNonce[msg.sender] = nonce;
        emit CancelOrdersBelowNonce(msg.sender, nonce);
    }

    /**
     *
     * @param nonces uint256[] multiple nonces to cancel
     * @notice sets multiple off chain order to be invalid
     */
    function cancelMultipleOffChainOrders(uint256[] calldata nonces) external {
        require(nonces.length > 0, "Exchange: {cancelMultipleOffChainOrders} No nonces provided");
        for (uint256 i = 0; i < nonces.length; i++) {
            require(nonces[i] >= userMinOrderNonce[msg.sender], "Exchange: {cancelMultipleOffChainOrders} one of the nonces is lower than sender current nonce");
            _isUserOrderNonceExecutedOrCancelled[msg.sender][nonces[i]] = true;
        }
        emit CancelMultipleOrders(msg.sender, nonces);
    }

    /**
     *
     * @param takerBid TakerOrder On chain Buy Order from taker
     * @param makerAsk MakerOrder off chain Sell Order from maker
     * @notice taker buys the off chain order using AVAX, the avax gets wrapped and transfered to the maker
     */
    function matchAskWithTakerBidUsingAVAXAndWAVAX(OrderTypes.TakerOrder calldata takerBid, OrderTypes.MakerOrder calldata makerAsk) external payable override nonReentrant{
        require(!paused, "Exchange: Activity is paused");
        require((makerAsk.isAsk) && (!takerBid.isAsk), "Exchange: No match found between orders");
        require(makerAsk.currency == WAVAX, "Exchange: NFT Sell Order currency must be in WAVAX");
        require(takerBid.taker == msg.sender, "Exchange: Buyer must be sender");

        if (takerBid.price > msg.value) {
            IERC20(WAVAX).safeTransferFrom(msg.sender, address(this), (takerBid.price - msg.value));
        }
        else{
            require(takerBid.price == msg.value, "Exchange: Buyer sent extra AVAX");
        }
        IWAVAX(WAVAX).deposit{value: msg.value}();

        bytes32 askHash = makerAsk.hash(); 
        _validateOrder(makerAsk, askHash);

        (bool isExecutionValid, uint256 tokenId, uint256 amount) = IExecutionStrategy(makerAsk.strategy).canExecuteTakerBid(takerBid, makerAsk);

        require(isExecutionValid,"Exchange: Strategy is not valid");

        _isUserOrderNonceExecutedOrCancelled[makerAsk.signer][makerAsk.nonce] = true;

        _transferFeesAndFundsWithWAVAX(
            makerAsk.strategy,
            makerAsk.collection,
            tokenId,
            makerAsk.signer,
            takerBid.price,
            makerAsk.minPercentageToAsk
        );

        _transferNonFungibleToken(makerAsk.collection, makerAsk.signer, takerBid.taker, tokenId, amount);

        emit TakerBid(
            askHash,
            makerAsk.nonce,
            takerBid.taker,
            makerAsk.signer,
            makerAsk.strategy,
            makerAsk.currency,
            makerAsk.collection,
            tokenId,
            amount,
            takerBid.price
        );
    }

    /**
     *
     * @param takerBid TakerOrder On chain Buy Order from taker
     * @param makerAsk MakerOrder off chain Sell Order from maker
     * @notice taker buys the off chain order using using any ERC20 whitelisted currency then transfered to the maker
     */
    function matchAskWithTakerBid(OrderTypes.TakerOrder calldata takerBid, OrderTypes.MakerOrder calldata makerAsk) external override nonReentrant {
        require(!paused, "Exchange: Activity is paused");
        require((makerAsk.isAsk) && (!takerBid.isAsk), "Exchange: No match found between orders");
        require(takerBid.taker == msg.sender, "Exchange: Buyer must be sender");

         bytes32 askHash = makerAsk.hash(); 
        _validateOrder(makerAsk, askHash);

        (bool isExecutionValid, uint256 tokenId, uint256 amount) = IExecutionStrategy(makerAsk.strategy).canExecuteTakerBid(takerBid, makerAsk);

        require(isExecutionValid,"Exchange: Trade can not be executed");

        _isUserOrderNonceExecutedOrCancelled[makerAsk.signer][makerAsk.nonce] = true;
        
         _transferFeesAndFunds(
            makerAsk.strategy,
            makerAsk.collection,
            tokenId,
            makerAsk.currency,
            msg.sender,
            makerAsk.signer,
            takerBid.price,
            makerAsk.minPercentageToAsk
        );

        // Execution part 2/2
        _transferNonFungibleToken(makerAsk.collection, makerAsk.signer, takerBid.taker, tokenId, amount);

        emit TakerBid(
            askHash,
            makerAsk.nonce,
            takerBid.taker,
            makerAsk.signer,
            makerAsk.strategy,
            makerAsk.currency,
            makerAsk.collection,
            tokenId,
            amount,
            takerBid.price
        );
    }

    /**
     *
     * @param takerAsk TakerOrder On chain Sell order (ex. sell NFT to bidder) from taker
     * @param makerBid MakerOrder off chain Buy order from maker in most cases is an Auction Bid or Offer 
     * @notice taker sells the asset to the off chain bid order 
     */
    function matchBidWithTakerAsk(OrderTypes.TakerOrder calldata takerAsk, OrderTypes.MakerOrder calldata makerBid) external override nonReentrant {
        require(!paused, "Exchange: Activity is paused");
        require((!makerBid.isAsk) && (takerAsk.isAsk), "Exchange: No match found between orders");
        require(takerAsk.taker == msg.sender, "Exchange: Seller must be sender");

        bytes32 bidHash = makerBid.hash(); 
        _validateOrder(makerBid, bidHash);

        (bool isExecutionValid, uint256 tokenId, uint256 amount) = IExecutionStrategy(makerBid.strategy).canExecuteTakerAsk(takerAsk, makerBid);

        require(isExecutionValid, "Exchange: Trade can not be executed");

        _isUserOrderNonceExecutedOrCancelled[makerBid.signer][makerBid.nonce] = true;

        _transferNonFungibleToken(makerBid.collection, takerAsk.taker, makerBid.signer, tokenId, amount);


        _transferFeesAndFunds(makerBid.strategy, makerBid.collection, tokenId, makerBid.currency, makerBid.signer, takerAsk.taker, takerAsk.price, takerAsk.minPercentageToAsk);

        emit TakerAsk(
            bidHash,
            makerBid.nonce,
            takerAsk.taker,
            makerBid.signer,
            makerBid.strategy,
            makerBid.currency,
            makerBid.collection,
            tokenId,
            amount,
            takerAsk.price
        );

    }

    /**
     *
     * @param collection address NFT collection
     * @param from address NFT owner 
     * @param to address NFT Buyer
     * @param tokenId uint256 tokenId
     * @param amount uint256 amount of tokens (for ERC1155)
     * @notice transfer the asset using a whitelisted transfer manager for ERC721 - ERC115 - specific managers for special cases 
     */ 
    function _transferNonFungibleToken(address collection, address from, address to, uint256 tokenId, uint256 amount) internal {
        address _transferManager = transferSelector.checkTransferManagerForToken(collection);
        require(_transferManager != address(0), "Exchange: {_transferNonFungibleToken} No transfer manager found for this collection");
        ITransferManagerNFT(_transferManager).transferToken(collection, from, to, tokenId, amount);
    }

    /**
     *
     * @param strategy address to calculate strategy protocol fee
     * @param collection address to calculate collection royalty fee
     * @param tokenId address to calculate collection royalty fee for a specific tokenId(if exists)
     * @param currency address whitelisted ERC20 currency to pay all parties with
     * @param from address NFT buyer or bidder
     * @param to address NFT Owner or seller
     * @param amount uint256 sale price to transfer
     * @param minPercentageToAsk uint256 protection against sudden changes in royalty fee
     * @notice transfer the Funds using a whitelisted Currency to all parties (protocol - royalty - seller)
     */ 
    function _transferFeesAndFunds(address strategy, address collection, uint256 tokenId, address currency, address from, address to, uint256 amount, uint256 minPercentageToAsk) internal {
        // transfer protocol fee
        uint _finalAmount = amount;
        uint256 _protocolFee = (IExecutionStrategy(strategy).viewProtocolFee() * amount) / 10000 ;
        if ((feeRecipient != address(0)) && (_protocolFee != 0)) {
            IERC20(currency).safeTransferFrom(from, feeRecipient, _protocolFee);
            _finalAmount = _finalAmount - _protocolFee;
        }
        // transfer royalty fee
         (address _royaltyReceipent, uint256 _royaltyFee)= royaltyFeeManager.calculateRoyaltyFeeAndGetRecipient(collection, tokenId, amount);
         if ((_royaltyReceipent != address(0)) && (_royaltyFee != 0)) {
            IERC20(currency).safeTransferFrom(from, _royaltyReceipent, _royaltyFee);
            _finalAmount = _finalAmount - _royaltyFee;

            emit RoyaltyFeeTransfer(collection, tokenId, _royaltyReceipent, currency, _royaltyFee);
         }
        //transfer fund to seller
        require((_finalAmount * 10000) >= (amount * minPercentageToAsk), "Exchange, Amount sent is below the threshold" );
        IERC20(currency).safeTransferFrom(from, to, _finalAmount);

    }

    /**
     *
     * @param strategy address to calculate strategy protocol fee
     * @param collection address to calculate collection royalty fee
     * @param tokenId address to calculate collection royalty fee for a specific tokenId(if exists)
     * @param to address NFT Owner or seller
     * @param amount uint256 sale price to transfer
     * @param minPercentageToAsk uint256 protection against sudden changes in royalty fee
     * @notice transfer the Funds using a whitelisted Currency to all parties (protocol - royalty - seller)
     */ 
    function _transferFeesAndFundsWithWAVAX(address strategy, address collection, uint256 tokenId, address to, uint256 amount, uint256 minPercentageToAsk) internal {
        uint256 _finalAmount = amount;
        uint256 _protocolFee = (IExecutionStrategy(strategy).viewProtocolFee() * amount) / 10000;        
        if ((feeRecipient != address(0)) && (_protocolFee != 0)) {
            IERC20(WAVAX).safeTransfer(feeRecipient, _protocolFee);
            _finalAmount = _finalAmount - _protocolFee;
        }

        (address _royaltyReceipent, uint256 _royaltyFee)= royaltyFeeManager.calculateRoyaltyFeeAndGetRecipient(collection, tokenId, amount);
        if ((_royaltyReceipent != address(0)) && (_royaltyFee != 0)) {
            IERC20(WAVAX).safeTransfer(_royaltyReceipent, _royaltyFee);
            _finalAmount = _finalAmount - _royaltyFee;

            emit RoyaltyFeeTransfer(collection, tokenId, _royaltyReceipent, WAVAX, _royaltyFee);
        }
        require((_finalAmount * 10000) >= (amount * minPercentageToAsk), "Exchange, Amount sent is below the minPercentageToAsk threshold" );
        IERC20(WAVAX).safeTransfer(to, _finalAmount);

    }

    /**
     *
     * @param makerOrder MakerOrder off chain bid or ask order 
     * @param orderHash bytes32 off chain order hash
     * @notice checks if the order nonce is not canceled , amount > 0 , signer exists , signature is valid , currency is listed , strategy is listed
     */ 
    function _validateOrder(OrderTypes.MakerOrder calldata makerOrder, bytes32 orderHash) internal view {
        require(
            (!_isUserOrderNonceExecutedOrCancelled[makerOrder.signer][makerOrder.nonce]) &&
                (makerOrder.nonce >= userMinOrderNonce[makerOrder.signer]),
            "Exchange: {_validateOrder} Order cancelled"
        );

        require(makerOrder.signer != address(0), "Exchange: {_validateOrder} Invalid signer address");
        require(makerOrder.amount > 0, "Exchange: {_validateOrder} sale price must be more than 0");
        require(
            SignatureChecker.verify(
                orderHash,
                makerOrder.signer,
                makerOrder.v,
                makerOrder.r,
                makerOrder.s,
                DOMAIN_SEPARATOR
            ),
            "Exchange: {_validateOrder} Signature is Invalid"
        );

        require(currencyManager.isCurrencyListed(makerOrder.currency), "Exchange: {_validateOrder} currnecy is not listed");
        require(strategyManager.isStrategyListed(makerOrder.strategy), "Exchange: {_validateOrder} strategy is not listed");
    }



    // AVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEA
    // AVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEA
    // AVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEA
    
    /**
     *
     * @notice pauses trading for matchBidWithTakerAsk, matchAskWithTakerBid and matchAskWithTakerBidUsingAVAXAndWAVAX
     */
    function pauseActivity() external onlyOwner {
        require(!paused, "Exchange: Already paused");
        paused = true;
    }

    /**
     *
     * @notice unPauses trading for matchBidWithTakerAsk, matchAskWithTakerBid and matchAskWithTakerBidUsingAVAXAndWAVAX
     */
    function unPauseActivity() external onlyOwner {
        require(paused, "Exchange: Already working");
        paused = false;
    }

    /**
     *
     * @param _strategyManager address new contract address
     * @notice updates the strategyManager, only allowed by contract owner
     */
    function updateStrategyManager(address _strategyManager) external onlyOwner {
        require(_strategyManager != address(0), "Exchange: {updateExecutionManager} new strategyManager Cannot be null address");
        strategyManager = IStrategyManager(_strategyManager);
        emit StrategyManagerUpdate(_strategyManager);
    }

    /**
     *
     * @param _transferSelectorNFT address new contract address
     * @notice updates the transferSelectorNFT, only allowed by contract owner
     */
    function updateTransferSelectorNFT(address _transferSelectorNFT) external onlyOwner {
        require(_transferSelectorNFT != address(0), "Exchange: {updateTransferSelectorNFT} new transferSelectorNFT Cannot be null address");
        transferSelector = ITransferSelector(_transferSelectorNFT);
        emit TransferSelectorUpdate(_transferSelectorNFT);
    }

    /**
     *
     * @param _currencyManager address new contract address
     * @notice updates the currencyManager, only allowed by contract owner
     */
    function updateCurrencyManager(address _currencyManager) external onlyOwner {
        require(_currencyManager != address(0), "Exchange: {updateCurrencyManager} new currencyManager Cannot be null address");
        currencyManager = ICurrencyManager(_currencyManager);
        emit CurrencyManagerUpdate(_currencyManager);
    }

    /**
     *
     * @param _royaltyFeeManager address new contract address
     * @notice updates the royaltyFeeManager, only allowed by contract owner
     */
    function updateRoyaltyFeeManager(address _royaltyFeeManager) external onlyOwner {
        require(_royaltyFeeManager != address(0), "Exchange: {updateRoyaltyFeeManager} new royaltyFeeManager Cannot be null address");
        royaltyFeeManager = IRoyaltyFeeManager(_royaltyFeeManager);
        emit RoyaltyFeeManagerUpdate(_royaltyFeeManager);
    }

    /**
     *
     * @param _feeRecipient address new contract address
     * @notice updates the feeRecipient, only allowed by contract owner
     */
    function updateProtocolFeeRecipient(address _feeRecipient) external onlyOwner {
        feeRecipient = _feeRecipient;
        emit FeeRecipientUpdate(_feeRecipient);
    }

    /**
     *
     * @param user wallet of the user
     * @param orderNonce nonce of the order
     * @notice Check whether user order nonce is executed or cancelled
     */
    function isUserOrderNonceExecutedOrCancelled(address user, uint256 orderNonce) external view returns (bool) {
        return _isUserOrderNonceExecutedOrCancelled[user][orderNonce];
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

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

interface ICurrencyManager {

    function listCurrency(address currency) external;

    function delistCurrency(address currency) external;

    function isCurrencyListed(address currency) external view returns (bool);

    function getListedCurrencies(uint256 cursor, uint256 size) external view returns (address[] memory, uint256);

    function getListedCurrenciesCount() external view returns (uint256);
    
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IStrategyManager {

    function listStrategy(address strategy) external;

    function delistStrategy(address strategy) external;

    function isStrategyListed(address strategy) external view returns (bool);

    function getListedStrategies(uint256 cursor, uint256 size) external view returns (address[] memory, uint256);

    function getListedStrategiesCount() external view returns (uint256);
    
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {OrderTypes} from "../libraries/OrderTypes.sol";

interface IExecutionStrategy {
    function canExecuteTakerAsk(OrderTypes.TakerOrder calldata takerAsk, OrderTypes.MakerOrder calldata makerBid)
        external
        view
        returns (
            bool,
            uint256,
            uint256
        );

    function canExecuteTakerBid(OrderTypes.TakerOrder calldata takerBid, OrderTypes.MakerOrder calldata makerAsk)
        external
        view
        returns (
            bool,
            uint256,
            uint256
        );

    function viewProtocolFee() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IRoyaltyFeeManager {

    function calculateRoyaltyFeeAndGetRecipient(address collection, uint256 tokenId, uint256 salePrice) external view returns (address, uint256);
    
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {OrderTypes} from "../libraries/OrderTypes.sol";

interface IExchange {

    function matchAskWithTakerBidUsingAVAXAndWAVAX(OrderTypes.TakerOrder calldata takerBid, OrderTypes.MakerOrder calldata makerAsk) external payable;

    function matchAskWithTakerBid(OrderTypes.TakerOrder calldata takerBid, OrderTypes.MakerOrder calldata makerAsk)external;

    function matchBidWithTakerAsk(OrderTypes.TakerOrder calldata takerAsk, OrderTypes.MakerOrder calldata makerBid) external;
    
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITransferManagerNFT {
    function transferToken(address collection, address from, address to, uint256 tokenId, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITransferSelector {
    function checkTransferManagerForToken(address collection) external view returns (address);
}

// SPDX-License-Identifier: GNU
pragma solidity >=0.5.0;

interface IWAVAX {
    function deposit() external payable;

    function transfer(address to, uint256 value) external returns (bool);

    function withdraw(uint256) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library OrderTypes {
    
    bytes32 internal constant MAKER_ORDER_HASH = 0x337e87154a3b7bbf1daf798d210b85bb02a39cebcfa98778f9f74bde68350ed2;
    
    struct MakerOrder {
        bool isAsk;
        address signer;
        address collection;
        uint256 price;
        uint256 tokenId;
        uint256 amount;
        address strategy;
        address currency;
        uint256 nonce;
        uint256 startTime;
        uint256 endTime;
        uint256 minPercentageToAsk;
        bytes params;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    struct TakerOrder {
        bool isAsk;
        address taker;
        uint256 price;
        uint256 tokenId;
        uint256 minPercentageToAsk;
        bytes params;
    }

    function hash(MakerOrder memory makerOrder) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    MAKER_ORDER_HASH,
                    makerOrder.isAsk,
                    makerOrder.signer,
                    makerOrder.collection,
                    makerOrder.price,
                    makerOrder.tokenId,
                    makerOrder.amount,
                    makerOrder.strategy,
                    makerOrder.currency,
                    makerOrder.nonce,
                    makerOrder.startTime,
                    makerOrder.endTime,
                    makerOrder.minPercentageToAsk,
                    keccak256(makerOrder.params)
                )
            );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {IERC1271} from "@openzeppelin/contracts/interfaces/IERC1271.sol";

// https://eips.ethereum.org/EIPS/eip-712#specification

library SignatureChecker {

    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        require(
            uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0,
            "SignatureChecker: Invalid s parameter"
        );

        require(v == 27 || v == 28, "SignatureChecker: Invalid v parameter");
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0), "SignatureChecker: Invalid signer");
        return signer;
    }


    function verify(bytes32 hash, address signer, uint8 v, bytes32 r, bytes32 s, bytes32 domainSeparator) internal view returns (bool){
        bytes32 _hash = keccak256(abi.encodePacked("\x19\x01", domainSeparator, hash));
        if (Address.isContract(signer)) {
            return IERC1271(signer).isValidSignature(_hash, abi.encodePacked(r, s, v)) == 0x1626ba7e;//MUST return the bytes4 magic value 0x1626ba7e
        }
        return recover(_hash, v, r, s) == signer;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1271.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC1271 standard signature validation method for
 * contracts as defined in https://eips.ethereum.org/EIPS/eip-1271[ERC-1271].
 *
 * _Available since v4.1._
 */
interface IERC1271 {
    /**
     * @dev Should return whether the signature provided is valid for the provided data
     * @param hash      Hash of the data to be signed
     * @param signature Signature byte array associated with _data
     */
    function isValidSignature(bytes32 hash, bytes memory signature) external view returns (bytes4 magicValue);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/ERC1155.sol)

pragma solidity ^0.8.0;

import "./IERC1155.sol";
import "./IERC1155Receiver.sol";
import "./extensions/IERC1155MetadataURI.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {
    using Address for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    constructor(string memory uri_) {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: balance query for the zero address");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, _asSingletonArray(id), _asSingletonArray(amount), data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, _asSingletonArray(id), _asSingletonArray(amount), data);

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), _asSingletonArray(id), _asSingletonArray(amount), "");

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC1155: setting approval status for self");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
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
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

import "../IERC1155.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

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

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {ITransferSelector} from "./interfaces/ITransferSelector.sol";

contract TransferSelector is ITransferSelector, Ownable {

    bytes4 public constant INTERFACE_ID_ERC721 = 0x80ac58cd; //ERC721
    bytes4 public constant INTERFACE_ID_ERC1155 = 0xd9b67a26; // ERC1155
    address public immutable TRANSFER_MANAGER_ERC721;
    address public immutable TRANSFER_MANAGER_ERC1155;
    // used for sepecial collections that do not implement ERC721 || ERC1155 standards
    mapping(address => address) public transferManagerSelectorForCollection; 

    event CollectionTransferManagerAdded(address indexed collection, address indexed transferManager);
    event CollectionTransferManagerRemoved(address indexed collection);

    constructor(address _transferManagerERC721, address _transferManagerERC1155) {
        TRANSFER_MANAGER_ERC721 = _transferManagerERC721;
        TRANSFER_MANAGER_ERC1155 = _transferManagerERC1155;
    }

    /**
     *
     * @param collection contract address of the NFT collection
     * @param transferManager contract address of the costume transfer manager
     * @notice adds a new transfer manager to handle special cases
     */
    function addTransferManager(address collection, address transferManager) external onlyOwner{
        require(collection != address(0), "TransferSelector: Collection can not be null");
        require(transferManager != address(0), "TransferSelector: Transfer manager can not be null");
        transferManagerSelectorForCollection[collection] = transferManager;
        emit CollectionTransferManagerAdded(collection, transferManager);
    }

    /**
     *
     * @param collection contract address of the NFT collection
     * @notice removes the costume transfer manager if exists
     */
    function removeTransferManager (address collection) external onlyOwner{
        require(transferManagerSelectorForCollection[collection] != address(0), "TransferSelector: Transfer manager for this collection does not exist" );
        transferManagerSelectorForCollection[collection] = address(0);
        emit CollectionTransferManagerRemoved(collection);
    }

    /**
     *
     * @param collection contract address of the NFT collection
     * @notice returns the transfer manager of the collection ERC721 || ERC1155 || costume transfer manager
     */
    function checkTransferManagerForToken(address collection) external view override returns (address transferManager) {
        transferManager = transferManagerSelectorForCollection[collection];
        if(transferManager == address(0)){
            if(IERC165(collection).supportsInterface(INTERFACE_ID_ERC721)){
                return TRANSFER_MANAGER_ERC721;
            }
            else if(IERC165(collection).supportsInterface(INTERFACE_ID_ERC1155)){
                return TRANSFER_MANAGER_ERC1155;
            }
        }
        return transferManager;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {IStrategyManager} from "./interfaces/IStrategyManager.sol";


 /**
  *
  * @title StrategyManager
  * @notice handles Strategies listing and delisting for execution on the Exchange
  */
contract StrategyManager is IStrategyManager, Ownable{
    using EnumerableSet for EnumerableSet.AddressSet;
    EnumerableSet.AddressSet private _listedStrategies;

    event ListStrategy(address indexed strategy);
    event DelistStrategy(address indexed strategy);

    /**
     * 
     * @param strategy contract address 
     * @notice lists a new strategy 
     */
    function listStrategy(address strategy) external override onlyOwner {
        require(!_listedStrategies.contains(strategy), "StrategyManager: Already listed");
        _listedStrategies.add(strategy);

        emit ListStrategy(strategy);
    }

    /**
     * 
     * @param strategy contract address 
     * @notice delists an existing strategy 
     */
    function delistStrategy(address strategy) external override onlyOwner {
        require(_listedStrategies.contains(strategy), "StrategyManager: Not listed");
        _listedStrategies.remove(strategy);

        emit DelistStrategy(strategy);
    }

    /**
     * 
     * @param strategy contract address 
     * @notice checks if a strategy is listed
     * @return boolean
     */
    function isStrategyListed(address strategy) external view override returns (bool) {
        return _listedStrategies.contains(strategy);
    }

    /**
     * 
     * @param cursor the start of pagination
     * @param size of pagination
     * @notice gets listed strategies and the length of listed strategies
     * @return address[], uint256
     */
    function getListedStrategies (uint256 cursor, uint256 size) external view override returns (address[] memory, uint256) {
        uint256 length = size;

        if (length > _listedStrategies.length() - cursor) {
            length = _listedStrategies.length() - cursor;
        }

        address[] memory listedStrategies = new address[](length);

        for (uint256 i = 0; i < length; i++) {
            listedStrategies[i] = _listedStrategies.at(cursor + i);
        }

        return (listedStrategies, cursor + length);
    }

    /**
     * 
     * @notice Counts listed strategies
     * @return uint256
     */
    function getListedStrategiesCount() external view override returns (uint256){
        return _listedStrategies.length();
    }


}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/structs/EnumerableSet.sol)

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

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {ICurrencyManager} from "./interfaces/ICurrencyManager.sol";

 /**
  *
  * @title CurrencyManager
  * @notice handles currencies listing and delisting on the Exchange
  */
contract CurrencyManager is ICurrencyManager, Ownable {

    using EnumerableSet for EnumerableSet.AddressSet;
    EnumerableSet.AddressSet private _listedCurrencies;

    event ListCurrency(address indexed currency);
    event DelistCurrency(address indexed currency);

    /**
     * 
     * @param currency contract address 
     * @notice lists a new currency 
     */
    function listCurrency(address currency) external override onlyOwner{
        require(!_listedCurrencies.contains(currency), "CurrencyManager: Already listed");
        _listedCurrencies.add(currency);

        emit ListCurrency(currency);
    }

    /**
     * 
     * @param currency contract address 
     * @notice delists an existing currency 
     */
    function delistCurrency(address currency) external override onlyOwner{
        require(_listedCurrencies.contains(currency), "CurrencyManager: Not listed");
        _listedCurrencies.remove(currency);

        emit DelistCurrency(currency);
    }

    /**
     * 
     * @param currency contract address 
     * @notice checks if a currency is listed
     * @return boolean
     */
    function isCurrencyListed(address currency) external view override returns (bool) {
        return _listedCurrencies.contains(currency);
    }

    /**
     * 
     * @param cursor the start of pagination
     * @param size of pagination
     * @notice gets listed addresses and the length of listed addresses
     * @return address[], uint256
     */
    function getListedCurrencies(uint256 cursor, uint256 size) external view override returns (address[] memory, uint256) {
        uint256 length = size;

        if(length > _listedCurrencies.length() - cursor) {
            length = _listedCurrencies.length() - cursor;
        }

        address[] memory listedCurrencies = new address[](length);

        for (uint256 i = 0; i < length; i++) {
            listedCurrencies[i] = _listedCurrencies.at( i + cursor);
        }

        return (listedCurrencies, cursor + length);
    }

    /**
     * 
     * @notice Counts listed addresses
     * @return uint256
     */
    function getListedCurrenciesCount() external view override returns (uint256){
        return _listedCurrencies.length();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {IRoyaltyFeeRegistry} from "./interfaces/IRoyaltyFeeRegistry.sol";
import {IOwnable} from "./interfaces/IOwnable.sol";

/**
 *
 * @title RoyaltyFeeSetter
 * @notice Controlls collections fee in the royalty fee registry.
 */
contract RoyaltyFeeSetter is Ownable {
    
    bytes4 public constant INTERFACE_ID_ERC721 = 0x80ac58cd; // ERC721
    bytes4 public constant INTERFACE_ID_ERC1155 = 0xd9b67a26; // ERC1155 
    bytes4 public constant INTERFACE_ID_ERC2981 = 0x2a55205a; // ERC2981

    address public immutable royaltyFeeRegistry;


    constructor(address _royaltyFeeRegistry) {
        royaltyFeeRegistry = _royaltyFeeRegistry;
    }

    /**
     *
     * @param collection address of the NFT Collection 
     * @param setter address that can update the info 
     * @param receiver address that recieves royalty fee
     * @param fee royalty fee according to basis_points
     * @notice Updates royalty info for an NFT collection, can only be called by this contract owner
     */
    function updateRoyaltyInfoForCollection(address collection, address setter, address receiver, uint256 fee) external onlyOwner {
        IRoyaltyFeeRegistry(royaltyFeeRegistry).updateRoyaltyInfoForCollection(collection, setter, receiver, fee);
    }


    /**
     *
     * @param _owner address of the new contract owner 
     * @notice Updates the owner of RoyaltyFeeRegistry Contract
     */
    function updateOwnerOfRoyaltyFeeRegistry(address _owner) external onlyOwner {
        IOwnable(royaltyFeeRegistry).transferOwnership(_owner);
    }

    /**
     *
     * @param _royaltyFeeLimit new fee limit according to basis_points
     * @notice Updates the fee limit in the RoyaltyFeeRegistry Contract
     */
    function updateRoyaltyFeeLimit(uint256 _royaltyFeeLimit) external onlyOwner {
        IRoyaltyFeeRegistry(royaltyFeeRegistry).updateRoyaltyFeeLimit(_royaltyFeeLimit);
    }

    /**
     *
     * @param collection address of the NFT Collection
     * @notice chekcs royalty info for collections
     * @return the setter if exists
     * 0 = current setter
     * 1 = Contracts supports eip2981 no setter in registry
     * 2 = setter is the contract owner
     * 3 = setter is the contract admin
     * 4 = setter cannot be set in any method (use updateRoyaltyInfoForCollection in this case)
     */
    function checkForCollectionSetter(address collection) external view returns (address, uint8) {
        (address currentSetter, , ) = IRoyaltyFeeRegistry(royaltyFeeRegistry).collectionRoyaltyFeeInfo(collection);

        if (currentSetter != address(0)) {
            return (currentSetter, 0);
        }

        try IERC165(collection).supportsInterface(INTERFACE_ID_ERC2981) returns (bool interfaceSupport) {
            if (interfaceSupport) {
                return (address(0), 1);
            }
        } catch {}

        try IOwnable(collection).owner() returns (address setter) {
            return (setter, 2);
        } catch {
            try IOwnable(collection).admin() returns (address setter) {
                return (setter, 3);
            } catch {
                return (address(0), 4);
            }
        }
    }

    /**
     *
     * @param collection address of the NFT Collection 
     * @param setter address that can update the info 
     * @param receiver address that recieves royalty fee
     * @param fee royalty fee according to basis_points
     * @notice Updates royalty info for an NFT collection, can only be called by collection contract setter
     */
    function updateRoyaltyInfoForCollectionIfSetter(address collection, address setter, address receiver, uint256 fee) external {
        (address _setter, , ) = IRoyaltyFeeRegistry(royaltyFeeRegistry).collectionRoyaltyFeeInfo(collection);
        require(msg.sender == _setter, "RoyaltyFeeSetter: message sender is not the collection setter");
        IRoyaltyFeeRegistry(royaltyFeeRegistry).updateRoyaltyInfoForCollection(collection, setter, receiver, fee);
    }

    /**
     *
     * @param collection address of the NFT Collection 
     * @param setter address that can update the info 
     * @param receiver address that recieves royalty fee
     * @param fee royalty fee according to basis_points
     * @notice Updates royalty info for an NFT collection, can only be called by collection contract admin
     */
    function updateRoyaltyInfoForCollectionIfAdmin(address collection, address setter, address receiver, uint256 fee) external {
        require(!IERC165(collection).supportsInterface(INTERFACE_ID_ERC2981), "RoyaltyFeeSetter: Royalty already set, must not support ERC2981");
        require(msg.sender == IOwnable(collection).admin(), "RoyaltyFeeSetter: message sender is not the collection admin");
        _updateRoyaltyInfoForCollectionIfOwnerOrAdmin(collection, setter, receiver, fee);
    }

    /**
     *
     * @param collection address of the NFT Collection 
     * @param setter address that can update the info 
     * @param receiver address that recieves royalty fee
     * @param fee royalty fee according to basis_points
     * @notice Updates royalty info for an NFT collection, can only be called by collection contract owner
     */
    function updateRoyaltyInfoForCollectionIfOwner(address collection, address setter, address receiver, uint256 fee) external {
        require(!IERC165(collection).supportsInterface(INTERFACE_ID_ERC2981), "RoyaltyFeeSetter: Royalty already set, must not support ERC2981");
        require(msg.sender == IOwnable(collection).owner(), "RoyaltyFeeSetter: message sender is not the collection owner");
        _updateRoyaltyInfoForCollectionIfOwnerOrAdmin(collection, setter, receiver, fee);
    }

    /**
     *
     * @param collection address of the NFT Collection 
     * @param setter address that can update the info 
     * @param receiver address that recieves royalty fee
     * @param fee royalty fee according to basis_points
     * @notice called in updateRoyaltyInfoForCollectionIfOwner && updateRoyaltyInfoForCollectionIfAdmin to check if the collection supports ERC721 | ERC115 && new setter
     */
    function _updateRoyaltyInfoForCollectionIfOwnerOrAdmin(address collection, address setter, address receiver, uint256 fee) internal {
        (address currentSetter, , ) = IRoyaltyFeeRegistry(royaltyFeeRegistry).collectionRoyaltyFeeInfo(collection);
        require(currentSetter == address(0), "RoyaltyFeeSetter: Setter Already set, update using updateRoyaltyInfoForCollectionIfSetter() instead");
        require( (IERC165(collection).supportsInterface(INTERFACE_ID_ERC721) || IERC165(collection).supportsInterface(INTERFACE_ID_ERC1155)),
            "RoyaltyFeeSetter: Contract is not ERC721 || ERC1155");
        IRoyaltyFeeRegistry(royaltyFeeRegistry).updateRoyaltyInfoForCollection(collection, setter, receiver, fee);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IRoyaltyFeeRegistry {

    function updateRoyaltyInfoForCollection(address collection, address setter, address receiver, uint256 fee) external;

    function updateRoyaltyFeeLimit(uint256 _royaltyFeeLimit) external;

    function royaltyInfo(address collection, uint256 salePrice) external view returns (address, uint256);

    function collectionRoyaltyFeeInfo(address collection) external view returns (address, address, uint256);
    
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IOwnable {
    function transferOwnership(address newOwner) external;

    function owner() external view returns (address);

    function admin() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IRoyaltyFeeRegistry} from "./interfaces/IRoyaltyFeeRegistry.sol";

/**
 * @title RoyaltyFeeRegistry
 * @notice Handles collections fee to be distributed in NFT sales 
 */
contract RoyaltyFeeRegistry is IRoyaltyFeeRegistry, Ownable {

    struct RoyaltyFeeInfo {
        address setter;
        address receiver;
        uint256 fee;
    }

    uint256 public royaltyFeeLimit;

    mapping(address => RoyaltyFeeInfo) private _collectionRoyaltyFeeInfo;

    event NewRoyaltyFeeLimit(uint256 royaltyFeeLimit);
    event RoyaltyFeeUpdate(address indexed collection, address indexed setter, address indexed receiver, uint256 fee);

    /**
     *
     * @param _royaltyFeeLimit declare fee limit 100 = 1%  read more at : https://en.wikipedia.org/wiki/Basis_point
     */
    constructor(uint256 _royaltyFeeLimit) {
        require(_royaltyFeeLimit <= 9500, "RoyaltyFeeRegistry: Fee too high, must be lower than 9500 equivalent to (95%)");
        royaltyFeeLimit = _royaltyFeeLimit;
    }

    /**
     *
     * @param collection address of the NFT Collection 
     * @param setter address that can update the info 
     * @param receiver address that recieves royalty fee
     * @param fee royalty fee according to basis_points
     * @notice Updates royalty info for an NFT collection
     */
    function updateRoyaltyInfoForCollection(address collection, address setter, address receiver, uint256 fee) external override onlyOwner{
        require(fee <= royaltyFeeLimit, "RoyaltyFeeRegistry: Fee is too high");
        _collectionRoyaltyFeeInfo[collection] = RoyaltyFeeInfo({setter:setter, receiver: receiver, fee: fee });

        emit RoyaltyFeeUpdate(collection, setter, receiver, fee);
    }

    /**
     *
     * @param _royaltyFeeLimit update royalty fee limit for all collections 100 = 1%
     * @notice Updates the royalty fee limit
     */
    function updateRoyaltyFeeLimit(uint256 _royaltyFeeLimit) external override onlyOwner{
        require(_royaltyFeeLimit <= 9500, "RoyaltyFeeRegistry: Fee too high, must be lower than 9500 equivalent to (95%)");
        royaltyFeeLimit = _royaltyFeeLimit;

        emit NewRoyaltyFeeLimit(_royaltyFeeLimit);
    }

    /**
     *
     * @param collection address of the NFT Collection 
     * @param salePrice the transfer value
     * @notice finds the royalty receiever and royalty amount in wei 
     * @return (address, uint256)
     */    
    function royaltyInfo(address collection, uint256 salePrice) external view override returns (address, uint256){
        return (_collectionRoyaltyFeeInfo[collection].receiver, (salePrice * _collectionRoyaltyFeeInfo[collection].fee) / 10000);
    }

    /**
     *
     * @param collection address of the NFT Collection 
     * @notice returns the collection Royalty Info (setter, receiver, fee) 
     * @return (address, address, uint256)
     */    
    function collectionRoyaltyFeeInfo(address collection)external view override returns (address, address, uint256) {
        return (_collectionRoyaltyFeeInfo[collection].setter, _collectionRoyaltyFeeInfo[collection].receiver, _collectionRoyaltyFeeInfo[collection].fee);
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC165, IERC2981} from "@openzeppelin/contracts/interfaces/IERC2981.sol";
import {IRoyaltyFeeManager} from "./interfaces/IRoyaltyFeeManager.sol";
import {IRoyaltyFeeRegistry} from "./interfaces/IRoyaltyFeeRegistry.sol";

/**
 *
 * @title RoyaltyFeeManager
 * @notice It handles the logic to check and transfer royalty fees if it exists.
 */
contract RoyaltyFeeManager is IRoyaltyFeeManager, Ownable {
    bytes4 public constant INTERFACE_ID_ERC2981 = 0x2a55205a; // erc2981

    IRoyaltyFeeRegistry public immutable royaltyFeeRegistry;
    
    constructor( address _royaltyFeeRegistry) {
        royaltyFeeRegistry = IRoyaltyFeeRegistry(_royaltyFeeRegistry);
    }

    /**
     * @param collection Address of the NFT Collection
     * @param tokenId tokenId of the NFT in Collection
     * @param salePrice the transfer value
     * @notice finds the royalty receiever and royalty amount in wei 
     * @return (address, uint256)
     */
    function calculateRoyaltyFeeAndGetRecipient(
        address collection,
        uint256 tokenId,
        uint256 salePrice
    ) external view override returns (address, uint256) {

        (address receiver, uint256 royaltyAmount) = royaltyFeeRegistry.royaltyInfo(collection, salePrice);
        if ((receiver == address(0)) || (royaltyAmount == 0)) {// calculated by the NFT contract not this contract (if exists) 
            if (IERC165(collection).supportsInterface(INTERFACE_ID_ERC2981)) {
                (receiver, royaltyAmount) = IERC2981(collection).royaltyInfo(tokenId, salePrice);
            }
        }
        return (receiver, royaltyAmount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be payed in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC165.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ERC1155Test is ERC1155, Ownable {
    constructor() ERC1155("") {
        _mint(msg.sender, 0, 100, "");
    }

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    function mint(address account, uint256 id, uint256 amount, bytes memory data)
        public
        onlyOwner
    {
        _mint(account, id, amount, data);
    }

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        public
        onlyOwner
    {
        _mintBatch(to, ids, amounts, data);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {ITransferManagerNFT} from "./interfaces/ITransferManagerNFT.sol";


contract TransferManagerERC721 is ITransferManagerNFT {
    address public immutable EXCHANGE;

    constructor(address _exchange) {
        EXCHANGE = _exchange;
    }

    /**
     *
     * @param collection address NFT collection
     * @param from address of the sender
     * @param to address of the recipient
     * @param tokenId tokenId
     * @param - transfeToken interface parameter used for ERC1155, empyt for ERC721 tokens
     * @notice Transfers ERC721 tokens
     */
    function transferToken(address collection, address from, address to, uint256 tokenId, uint256) external override {
        require(msg.sender == EXCHANGE, "TransferManagerERC721: Invalid Exchange address");
        IERC721(collection).safeTransferFrom(from, to, tokenId);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import {ITransferManagerNFT} from "./interfaces/ITransferManagerNFT.sol";


contract TransferManagerERC1155 is ITransferManagerNFT {
    address public immutable EXCHANGE;

    constructor(address _exchange) {
        EXCHANGE = _exchange;
    }

    /**
     *
     * @param collection address NFT collection
     * @param from address of the sender
     * @param to address of the recipient
     * @param tokenId tokenId
     * @param amount amount of ERC1155 tokens
     * @notice Transfers ERC1155 tokens
     */
    function transferToken(address collection,address from, address to, uint256 tokenId, uint256 amount) external override {
        require(msg.sender == EXCHANGE, "TransferManagerERC1155: Invalid Exchange address");
        IERC1155(collection).safeTransferFrom(from, to, tokenId, amount, "");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import {IExecutionStrategy} from './interfaces/IExecutionStrategy.sol';
import {OrderTypes} from './libraries/OrderTypes.sol';
contract PrivateSale is IExecutionStrategy {

    uint256 public immutable PROTOCOL_FEE;

    constructor(uint256 _protocolFee) {//2% = 200 basis points
        PROTOCOL_FEE = _protocolFee;
    }

    function canExecuteTakerAsk( OrderTypes.TakerOrder calldata takerAsk, OrderTypes.MakerOrder calldata makerBid) external view override returns (bool, uint256, uint256){
        return(false, 0,0);
    }

    function canExecuteTakerBid(OrderTypes.TakerOrder calldata takerBid, OrderTypes.MakerOrder calldata makerAsk) external view override returns (bool, uint256, uint256){
        address targetBuyer = abi.decode(makerAsk.params, (address));

        bool _valid = (makerAsk.price == takerBid.price)      &&
                      (targetBuyer == takerBid.taker)         &&
                      (makerAsk.tokenId == takerBid.tokenId)  &&
                      (makerAsk.startTime <= block.timestamp) &&
                      (makerAsk.endTime >= block.timestamp);

        return(_valid, makerAsk.tokenId, makerAsk.amount);

    }

    function viewProtocolFee()  external view override returns (uint256){
        return PROTOCOL_FEE;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import {IExecutionStrategy} from './interfaces/IExecutionStrategy.sol';
import {OrderTypes} from './libraries/OrderTypes.sol';
contract CollectionSale is IExecutionStrategy {

    uint256 public immutable PROTOCOL_FEE;

    constructor(uint256 _protocolFee) {//2% = 200 basis points
        PROTOCOL_FEE = _protocolFee;
    }

    function canExecuteTakerAsk( OrderTypes.TakerOrder calldata takerAsk, OrderTypes.MakerOrder calldata makerBid) external view override returns (bool, uint256, uint256){
        bool _valid = (makerBid.price == takerAsk.price)      &&
                      (makerBid.startTime <= block.timestamp) &&
                      (makerBid.endTime >= block.timestamp);

        return(_valid, takerAsk.tokenId, makerBid.amount);
    }

    function canExecuteTakerBid(OrderTypes.TakerOrder calldata takerBid, OrderTypes.MakerOrder calldata makerAsk) external pure override returns (bool, uint256, uint256){
        return(false, 0, 0);
    }

    function viewProtocolFee()  external view override returns (uint256){
        return PROTOCOL_FEE;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import {IExecutionStrategy} from './interfaces/IExecutionStrategy.sol';
import {OrderTypes} from './libraries/OrderTypes.sol';
contract BasicSale is IExecutionStrategy {

    uint256 public immutable PROTOCOL_FEE;

    constructor(uint256 _protocolFee) {//2% = 200 basis points
        PROTOCOL_FEE = _protocolFee;
    }

    function canExecuteTakerAsk( OrderTypes.TakerOrder calldata takerAsk, OrderTypes.MakerOrder calldata makerBid) external view override returns (bool, uint256, uint256){
        bool _valid = (makerBid.price == takerAsk.price)      &&
                      (makerBid.tokenId == takerAsk.tokenId)  &&
                      (makerBid.startTime <= block.timestamp) &&
                      (makerBid.endTime >= block.timestamp);

        return(_valid, makerBid.tokenId, makerBid.amount);
    }

    function canExecuteTakerBid(OrderTypes.TakerOrder calldata takerBid, OrderTypes.MakerOrder calldata makerAsk) external view override returns (bool, uint256, uint256){
        bool _valid = (makerAsk.price == takerBid.price)      &&
                      (makerAsk.tokenId == takerBid.tokenId)  &&
                      (makerAsk.startTime <= block.timestamp) &&
                      (makerAsk.endTime >= block.timestamp);

        return(_valid, makerAsk.tokenId, makerAsk.amount);

    }

    function viewProtocolFee()  external view override returns (uint256){
        return PROTOCOL_FEE;
    }
}