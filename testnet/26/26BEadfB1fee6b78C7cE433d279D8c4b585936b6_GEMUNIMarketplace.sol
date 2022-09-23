//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "./GENIPassSale.sol";
import "./interfaces/IGEMUNIItem.sol";
import "./interfaces/IGENIPass.sol";
import "./interfaces/IGEMUNIMarketplace.sol";
import "./interfaces/IGENIPassSale.sol";
import "./interfaces/IGENI.sol";
import "./utils/PermissionGroupUpgradeable.sol";

contract GEMUNIMarketplace is IGEMUNIMarketplace, PermissionGroupUpgradeable, PausableUpgradeable, ReentrancyGuardUpgradeable {
    using SafeERC20 for IGENI;

    IGEMUNIItem public gemuniItem;
    IGENIPass public geniPass;
    IGENI public geni;
    IGENIPassSale public geniPassSale;

    address public treasury;
    uint public feeRate;
    uint constant decimalRate = 10000;

    mapping(address => mapping(uint => mapping(address => OfferInfo))) public offerInfos;
    mapping(address => mapping(uint => SaleInfo)) public saleInfos;

    function _initialize (
        IGENI _geni,
        IGENIPass _geniPass,
        address _treasury,
        IGEMUNIItem _gemuniItem,
        uint _feeRate,
        IGENIPassSale _geniPassSale    
    ) external initializer
    {
        __operatable_init();
        __Pausable_init();
        __ReentrancyGuard_init();
        geni = _geni; 
        geniPass = _geniPass; 
        treasury = _treasury;
        gemuniItem = _gemuniItem;
        feeRate = _feeRate;
        geniPassSale = _geniPassSale;
    }
    
    /**
     * @dev Owner set new geniItem contract
     * @param _gemuniItem new address
     */
    function setGemUniItem(IGEMUNIItem _gemuniItem) external onlyOwner {
        require(address(_gemuniItem) != address(0), "GEMUNIMarketplace: new address must be different address(0)");
        gemuniItem = _gemuniItem;
        emit SetGemUniItem(address(_gemuniItem));
    }   

    function setGeniAddress(IGENI _geni) external onlyOwner {
        require(address(_geni) != address(0), "GEMUNIMarketplace: new address must be different address(0)");
        geni = _geni;
        emit SetGeniAddress(address(_geni));
    } 

    function setGeniPassSaleAddress(IGENIPassSale _geniPassSale) external onlyOwner {
        require(address(_geniPassSale) != address(0), "GEMUNIMarketplace: new address must be different address(0)");
        geniPassSale = _geniPassSale;
        emit SetGeniPassSaleAddress(address(_geniPassSale));
    } 

    function setFeeRate(uint value) external onlyOwner {
        require(value < 1000000, "GEMUNIMarketplace: percentage not greater than 100.0000 %");
        feeRate = value;
        emit SetFeeRate(value);
    }

    function setTreasury(address newTreasury) external onlyOwner {
        require(newTreasury != address(0));
        treasury = newTreasury;
        emit SetTreasury(newTreasury);
    }
        
    function putOnSale(address token, uint tokenId, uint price, uint startTime, uint expirationTime) external override whenNotPaused {
        require(token == address(geniPass) || token == address(gemuniItem), "GEMUNIMarketplace: invalid token");
        require(startTime >= block.timestamp, "GEMUNIMarketplace: invalid start time");
        require(expirationTime > startTime, "GEMUNIMarketplace: invalid end time");
        SaleInfo storage saleInfo = saleInfos[token][tokenId];
        saleInfo.seller = msg.sender;
        saleInfo.startTime = startTime;
        saleInfo.expirationTime = expirationTime;
        if(token == address(geniPass)) {
            geniPass.transferFrom(msg.sender, address(this), tokenId);
            saleInfo.price = geniPassSale.getPricePass(tokenId, price, IGENIPass.PriceType.GENI);

            emit PassPutOnSale(tokenId, saleInfo.price, saleInfo.seller, startTime, expirationTime);
        } else {
            require(price > 0, "GEMUNIMarketplace: invalid price");
            gemuniItem.transferFrom(msg.sender, address(this), tokenId);
        
            saleInfo.price = price;
            emit ItemPutOnSale(tokenId, saleInfo.price, saleInfo.seller, startTime, expirationTime);
        }

    }
    
    function updatePriceSale(address token, uint tokenId, uint price) external override whenNotPaused {
        require(token == address(geniPass) || token == address(gemuniItem), "GEMUNIMarketplace: invalid token");
        SaleInfo storage saleInfo = saleInfos[token][tokenId];
        require(msg.sender == saleInfo.seller, "GEMUNIMarketplace: token not put on sale or user is not seller");
        require(block.timestamp <= saleInfo.expirationTime, "GEMUNIMarketplace: expired");
        require(price > 0, "GEMUNIMarketplace: invalid price");
        saleInfo.price = price;

        if(token == address(geniPass)){
            emit PassUpdateOnSale(tokenId, saleInfo.price, msg.sender);
        } else {
            emit ItemUpdateOnSale(tokenId, saleInfo.price, msg.sender);
        }
    }
    
    function removeFromSale(address token, uint tokenId) external override whenNotPaused nonReentrant {
        require(token == address(geniPass) || token == address(gemuniItem), "GEMUNIMarketplace: invalid token");
        SaleInfo memory saleInfo = saleInfos[token][tokenId];
        require(msg.sender == saleInfo.seller, "GEMUNIMarketplace: token not put on sale or user is not seller");
        if(token == address(geniPass)){
            geniPass.transferFrom(address(this), saleInfo.seller, tokenId);
            emit PassRemoveOnSale(tokenId, msg.sender);
        } else {
            gemuniItem.transferFrom(address(this), saleInfo.seller, tokenId);
            emit ItemRemoveOnSale(tokenId, msg.sender);
        }
        delete saleInfos[token][tokenId];
    }

    function purchase(address token, uint tokenId, uint buyPrice) external override whenNotPaused nonReentrant {
        require(token == address(geniPass) || token == address(gemuniItem), "GEMUNIMarketplace: invalid token");
        SaleInfo memory saleInfo = saleInfos[token][tokenId];
        address buyer = msg.sender;
        
        require(saleInfo.seller != address(0), "GEMUNIMarketplace: not for sale");
        require(block.timestamp >= saleInfo.startTime, "GEMUNIMarketplace: Sale has not started");
        require(block.timestamp <= saleInfo.expirationTime, "GEMUNIMarketplace: expired to purchase");
        require(saleInfo.seller != buyer, "GEMUNIMarketplace: owner can not buy");

        uint salePrice = saleInfo.price;
        require(buyPrice == salePrice, "GEMUNIMarketplace: invalid trade price");

        uint geniPrice = buyPrice * (1000000 - feeRate) / decimalRate / 100;
        geni.safeTransferFrom(buyer, saleInfo.seller, geniPrice);
        geni.safeTransferFrom(buyer, treasury, buyPrice - geniPrice);

        if (token == address(geniPass)) {
            geniPass.transferFrom(address(this), buyer, tokenId);
            emit PassBought(tokenId, buyer, saleInfo.seller, buyPrice);
        } else {
            gemuniItem.transferFrom(address(this), buyer, tokenId);
            emit ItemBought(tokenId, buyer, saleInfo.seller, buyPrice);
        }
        
        delete saleInfos[token][tokenId];
    }
    
    function makeOffer(address token, uint tokenId, uint offerPrice, uint expirationTime) external override whenNotPaused nonReentrant {
        require(token == address(geniPass) || token == address(gemuniItem), "GEMUNIMarketplace: invalid token");
        require(expirationTime > block.timestamp, "GEMUNIMarketplace: invalid end time");
        SaleInfo storage saleInfo = saleInfos[token][tokenId];
        address buyer = msg.sender;
        OfferInfo storage offerInfo = offerInfos[token][tokenId][buyer];
        if(saleInfo.seller == address(0)) {
            if(token == address(geniPass)) {
                require(buyer != geniPass.ownerOf(tokenId), "GEMUNIMarketplace: owner cannot offer");
            } else {
                require(buyer != gemuniItem.ownerOf(tokenId), "GEMUNIMarketplace: owner cannot offer");
            }
        } else {
            require(saleInfo.seller != buyer, "GEMUNIMarketplace: seller can not buy");
        }
        require(offerPrice > 0, "GEMUNIMarketplace: invalid price");
        require(offerInfo.priceOffer == 0, "GEMUNIMarketplace: already offered");
        
        geni.safeTransferFrom(buyer, address(this), offerPrice);
        offerInfo.priceOffer = offerPrice;
        offerInfo.expirationTime = expirationTime;
        if (token == address(geniPass)) {
            if(saleInfo.seller == address(0)) {
                emit PassOffered(tokenId, buyer, geniPass.ownerOf(tokenId), offerPrice, expirationTime);
            } else {
                emit PassOffered(tokenId, buyer, saleInfo.seller, offerPrice, expirationTime);
            }
        } else {
            if(saleInfo.seller == address(0)) {
                 emit ItemOffered(tokenId, buyer, gemuniItem.ownerOf(tokenId), offerPrice, expirationTime);
            } else {
                 emit ItemOffered(tokenId, buyer, saleInfo.seller, offerPrice, expirationTime);
            }
        }
    }
    
    function updateOffer(address token, uint tokenId, uint updateOfferPrice) external override whenNotPaused nonReentrant {
        require(token == address(geniPass) || token == address(gemuniItem), "GEMUNIMarketplace: invalid token");
        address buyer = msg.sender;
        OfferInfo storage offerInfo = offerInfos[token][tokenId][buyer];
        require(offerInfo.priceOffer > 0, "GEMUNIMarketplace: not existed offer");
        require(block.timestamp <= offerInfo.expirationTime, "GEMUNIMarketplace: expired");
        require(updateOfferPrice > 0, "GEMUNIMarketplace: invalid price");
        uint currentOffer = offerInfo.priceOffer;
        uint requiredValue = updateOfferPrice < currentOffer ? 0 : updateOfferPrice - currentOffer;
        
        if (requiredValue > 0) {
            IERC20(geni).transferFrom(buyer, address(this), requiredValue);
        }
        
        if (updateOfferPrice < currentOffer) {
            uint returnedValue = currentOffer - updateOfferPrice;
            IERC20(geni).transfer(buyer, returnedValue);
        }
        
        offerInfo.priceOffer = updateOfferPrice;
        if (token == address(geniPass)) {
            emit PassOfferUpdated(tokenId, buyer, updateOfferPrice);
        } else {
            emit ItemOfferUpdated(tokenId, buyer, updateOfferPrice);
        }
    }
    
    function cancelOffer(address token, uint tokenId) external override whenNotPaused nonReentrant {
        require(token == address(geniPass) || token == address(gemuniItem), "GEMUNIMarketplace: invalid token");
        address buyer = msg.sender;
        OfferInfo memory offerInfo = offerInfos[token][tokenId][buyer];
        require(offerInfo.priceOffer > 0, "GEMUNIMarketplace: not existed offer");
        
        IERC20(geni).transfer(buyer, offerInfo.priceOffer);

        delete offerInfos[token][tokenId][buyer];
        if (token == address(geniPass)) {
            emit PassOfferCancelled(tokenId, buyer);
        } else {
            emit ItemOfferCancelled(tokenId, buyer);
        }
    }
    
    function takeOffer(address token, uint tokenId, address buyer, uint takeOfferPrice) external override whenNotPaused nonReentrant {
        require(token == address(geniPass) || token == address(gemuniItem), "GEMUNIMarketplace: invalid token");
        SaleInfo storage saleInfo = saleInfos[token][tokenId];
        OfferInfo memory offerInfo = offerInfos[token][tokenId][buyer];
        require(offerInfo.priceOffer > 0, "GEMUNIMarketplace: not existed offer");

        if (saleInfo.seller == address(0)) {
            require(msg.sender != buyer , "GEMUNIMarketplace: buyer can not take offer");
            if (token == address(geniPass)) {
                require(msg.sender == geniPass.ownerOf(tokenId), "GEMUNIMarketplace: not pass owner");
            } else {
                require(msg.sender == gemuniItem.ownerOf(tokenId), "GEMUNIMarketplace: not item owner");
            } 
        } else {
            require(saleInfo.seller != buyer, "GEMUNIMarketplace: seller can not buy");
            require(saleInfo.seller == msg.sender, "GEMUNIMarketplace: not seller");
        }
        require(block.timestamp <= offerInfo.expirationTime, "GEMUNIMarketplace: expired to purchase");
        
        uint priceOffer = offerInfo.priceOffer;
        require(takeOfferPrice == priceOffer, "GEMUNIMarketplace: invalid price");

        uint price = priceOffer * (1000000 - feeRate) / decimalRate / 100;
        geni.safeTransfer(treasury, priceOffer - price);

        if (token == address(geniPass)) {
            if (saleInfo.seller == address(0)) {
                geni.safeTransfer(msg.sender, price);
                geniPass.transferFrom(msg.sender, buyer, tokenId);
                emit PassBought(tokenId, buyer, msg.sender, priceOffer);
            } else {
                geni.safeTransfer(saleInfo.seller, price);
                geniPass.transferFrom(address(this), buyer, tokenId);
                emit PassBought(tokenId, buyer, saleInfo.seller, priceOffer);
            }
        } else {
            if (saleInfo.seller == address(0)) {
                geni.safeTransfer(msg.sender, price);
                gemuniItem.transferFrom(msg.sender, buyer, tokenId);
                emit ItemBought(tokenId, buyer, msg.sender, priceOffer);
            } else {
                geni.safeTransfer(saleInfo.seller, price);
                gemuniItem.transferFrom(address(this), buyer, tokenId);
                emit ItemBought(tokenId, buyer, saleInfo.seller, priceOffer);
            }
        }
        
        delete saleInfos[token][tokenId];
        delete offerInfos[token][tokenId][buyer];
    }
    
    function pause() external onlyOperator {
        _pause();
    }

    function unpause() external onlyOperator {
        _unpause();
    }
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library VerifySignature {

    function getEthSignedMessageHash(bytes32 _messageHash)
        public
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    _messageHash
                )
            );
    }

    function recoverSigner(
        bytes32 _ethSignedMessageHash,
        bytes memory _signature
    ) public pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);

        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function splitSignature(bytes memory sig)
        public
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        require(sig.length == 65, "invalid signature length");

        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

abstract contract PermissionGroupUpgradeable is OwnableUpgradeable {

    mapping(address => bool) public operators;
    event AddOperator(address newOperator);
    event RemoveOperator(address operator);

    function __operatable_init() internal initializer {
        __Ownable_init();
        operators[owner()] = true;
    }

    modifier onlyOperator {
        require(operators[msg.sender], "Operatable: caller is not the operator");
        _;
    }

    function addOperator(address operator) external onlyOwner {
        operators[operator] = true;
        emit AddOperator(operator);
    }

    function removeOperator(address operator) external onlyOwner {
        operators[operator] = false;
        emit RemoveOperator(operator);
    }
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";

contract PermissionGroup is Ownable {
    // List of authorized address to perform some restricted actions
    mapping(address => bool) public operators;
    event AddOperator(address newOperator);
    event RemoveOperator(address operator);

    modifier onlyOperator() {
        require(operators[msg.sender], "PermissionGroup: not operator");
        _;
    }

    /**
     * @notice Adds an address as operator.
     */
    function addOperator(address operator) external onlyOwner {
        operators[operator] = true;
        emit AddOperator(operator);
    }

    /**
    * @notice Removes an address as operator.
    */
    function removeOperator(address operator) external onlyOwner {
        operators[operator] = false;
        emit RemoveOperator(operator);
    }
}

pragma solidity ^0.8.0;
import "./IGENIPass.sol";

interface IGENIPassSale {
    struct SaleInfo {
        uint price;
        IGENIPass.PriceType priceType;
        uint startTime;
        uint expirationTime;
    }
    
    struct CreateSalePasses{
        string serialNumber;
        uint price;
        IGENIPass.PassType passType;
        IGENIPass.PriceType priceType;
        uint startTime;
        uint expirationTime;
    }

    struct CreateSalePassesWithoutMint{
        uint passId;
        uint price;
        IGENIPass.PriceType priceType;
        uint startTime;
        uint expirationTime;
    }

    struct ReferalBonus {
        uint referralBonusLv0;
        uint referralBonusLv1;
        uint referralBonusLv2;
        uint referralBonusLv3;
        uint referralBonusLv4;
    }

    struct ReferalLevelParams {
        uint startLv0;
        uint startLv1;
        uint startLv2;
        uint startLv3;
        uint startLv4;
    }
    event SetServer(address newServer);
    event SetTreasury(address newTreasury);
    event SetGeni(address newGeni);
    event SetDiscountRate(uint value);
    event SetExchange(address _exchange);
    event SetReferralLevel(uint startLv0, uint startLv1, uint startLv2, uint startLv3, uint startLv4);
    event SetReferralBonusLevel0(uint _rate);
    event SetReferralBonusLevel1(uint _rate);
    event SetReferralBonusLevel2(uint _rate);
    event SetReferralBonusLevel3(uint _rate);
    event SetReferralBonusLevel4(uint _rate);

    event PassPutOnSale(uint indexed passId, uint price, uint priceType, address seller, uint startTime, uint expirationTime);
    event PassUpdateSale(uint indexed passId, uint newPrice, address seller);
    event PassRemoveFromSale(uint indexed passId, address seller);
    event PassBought(uint indexed passId, address buyer, address seller, uint256 price, uint discountedPrice);
    event PassBoughtWithReferral(uint indexed passId, address buyer, address seller, address referal, uint nonce, uint256 price, uint discountedPrice, uint referalBonus);
    event WithdrawGeniPass(address seller, address to, uint indexed tokenId);
    event WithdrawToken(address token, address to, uint amount);
    event WithdrawETH(address recipient, uint amount);
    
    function putOnSale(uint passId, uint price, IGENIPass.PriceType priceType, uint startTime, uint expirationTime) external;
    function mintForSale(string memory serialNumber, uint price, IGENIPass.PassType passType, IGENIPass.PriceType priceType, uint startTime, uint expirationTime) external;
    function updateSale(uint passId, uint price) external;
    function removeFromSale(uint passId) external;
    function getPricePass(uint passId, uint price, IGENIPass.PriceType priceType) external view returns(uint);
    function putOnSaleBatch(CreateSalePassesWithoutMint[] memory input) external;
    function mintForSaleBatch(CreateSalePasses[] memory input) external;
    function purchase(uint passId, uint buyPrice) external payable;
    function purchaseWithReferral(uint passId, uint buyPrice, address referalAddress, uint nonce, bytes memory signature) external payable;
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";

interface IGENIPass is IERC721Upgradeable {
    enum PassType { Stone, Topaz, Citrine, Ruby, Diamond }
    enum PriceType { BNB, GENI }

    struct GeniPass {
        string serialNumber;
        PassType passType;
        bool isActive;
    }
    
    event SetActive(uint indexed passId, bool isActive);
    event PassCreated(address indexed owner, uint indexed passId, uint passType, string serialNumber);
    event LockPass(uint indexed passId);
    event UnLockPass(uint indexed passId);
    
    function burn(uint tokenId) external;
    
    function mint(address to, string memory serialNumber, PassType passType) external returns(uint tokenId);
    
    function getPass(uint passId) external view returns (GeniPass memory pass);

    function exists(uint passId) external view returns (bool);

    function setActive(uint tokenId, bool _isActive) external;

    function lockPass(uint passId) external;

    function unLockPass(uint passId) external;

    function permit(address owner, address spender, uint tokenId, bytes memory _signature) external;
    
    function isLocked(uint tokenId) external returns(bool);
}

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IGENI is IERC20 {
    function mint(address to, uint256 amount) external;
    
    function burn(uint amount) external;

    event SetLpToken(address lpToken);
    event SetBusd(address _busd);
    event SetExchange(address lpToken);
    event SetAntiWhaleAmountBuy(uint256 amount);
    event SetAntiWhaleAmountSell(uint256 amount);
    event SetAntiWhaleTimeSell(uint256 timeSell);
    event SetAntiWhaleTimeBuy(uint256 timeBuy);
    event AddListWhales(address[] _whales);
    event RemoveFromWhales(address[] _whales);
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "./IGENIPass.sol";

interface IGEMUNIMarketplace {
    struct OfferInfo {
        uint priceOffer;
        uint expirationTime;
    }
    struct SaleInfo {
        address seller;
        uint price;
        uint startTime;
        uint expirationTime;
    }
    event SetGemUniItem(address newGemuniItem);
    event SetGeniAddress(address newGeni);
    event SetGeniPassSaleAddress(address newGeniPassSale);
    event SetFeeRate(uint value);
    event SetTreasury(address newTreasury);

    event PassPutOnSale(uint indexed passId, uint price, address indexed seller, uint startTime, uint expirationTime);
    event PassUpdateOnSale(uint indexed passId, uint newPrice, address seller);
    event PassRemoveOnSale(uint indexed passId, address seller);
    event PassBought(uint indexed passId, address buyer, address seller, uint256 price);
    event PassBoughtWithReferal(uint indexed passId, address buyer, address seller, address referal, uint256 price);
    event PassOffered(uint indexed passId, address buyer, address seller, uint price, uint expirationTime);
    event PassOfferCancelled(uint indexed passId, address buyer);
    event PassOfferUpdated(uint indexed passId, address buyer, uint newOfferPrice);

    event ItemPutOnSale(uint indexed itemId, uint price, address indexed seller, uint startTime, uint expirationTime);
    event ItemUpdateOnSale(uint indexed itemId, uint newPrice, address seller);
    event ItemRemoveOnSale(uint indexed itemId, address seller);
    event ItemBought(uint indexed itemId, address buyer, address seller,  uint256 price);
    event ItemOffered(uint indexed itemId, address buyer, address seller, uint price, uint expirationTime);
    event ItemOfferCancelled(uint indexed itemId, address buyer);
    event ItemOfferUpdated(uint indexed itemId, address buyer, uint newPriceOffer);

    event withdrawNft(address token, address seller, address to, uint indexed tokenId);
    event withdrawToken(address token, address to, uint amount);
    
    function putOnSale(address token, uint tokenId, uint price, uint startTime, uint expirationTime) external;
    function updatePriceSale(address token, uint tokenId, uint price) external;
    function removeFromSale(address token, uint tokenId) external;
    function makeOffer(address token, uint itemId, uint offerPrice, uint expirationTime) external;
    function cancelOffer(address token, uint tokenId) external;
    function takeOffer(address token, uint tokenId, address buyer, uint takeOfferPrice) external;
    function updateOffer(address token, uint tokenId, uint updateOfferPrice) external;
    function purchase(address token, uint tokenId, uint buyPrice) external;
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IGEMUNIItem is IERC721 {
    event LockItem(uint indexed tokenId);
    
    event UnLockItem(uint indexed tokenId);

    function lockItem(uint tokenId) external;

    function unLockItem(uint tokenId) external;

    function permit(address owner, address spender, uint tokenId, bytes memory _signature) external;
    
    function isLocked(uint tokenId) external returns(bool);
}

//SPDX-License-Identifier: MIT

pragma solidity >=0.6.2;

interface IExchangeRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./utils/VerifySignature.sol";
import "./utils/PermissionGroup.sol";
import "./interfaces/IGENIPass.sol";
import "./interfaces/IExchangeRouter.sol";
import "./interfaces/IGENIPassSale.sol";
import "./interfaces/IGENI.sol";

contract GENIPassSale is IGENIPassSale, IERC721Receiver, PermissionGroup, ReentrancyGuard, Pausable {
    using SafeERC20 for IGENI;
    
    IGENIPass public immutable geniPass;
    IGENI public geni;
    uint private constant SECONDS_PER_MONTH = 2629743; //2629743

    uint public referralBonusLv0;
    uint public referralBonusLv1;
    uint public referralBonusLv2;
    uint public referralBonusLv3;
    uint public referralBonusLv4;

    uint public startLv0;
    uint public startLv1;
    uint public startLv2;
    uint public startLv3;
    uint public startLv4;

    uint public discountRate = 100000;
    address public treasury;
    address public server;
    address public exchange;

    uint decimalRate = 10000;
    
    address public immutable busd;
    address public immutable bnb;
    
    mapping(uint => SaleInfo) public saleInfos;
    mapping(address => bool) public isEnterReferral;
    mapping(uint => bool) public isUsedNonce;
    mapping(address => mapping(uint => uint)) public passCount;

    constructor(
        IGENI geniAddr,
        IGENIPass geniPassAddr,
        address _treasury,
        address _server,
        address _exchange,
        address _busd,
        address _bnb, 
        ReferalLevelParams memory params,
        ReferalBonus memory bonusParams
    ) {
        geni = geniAddr;
        geniPass = geniPassAddr;
        server = _server;
        treasury = _treasury;
        exchange = _exchange;
        busd = _busd;
        bnb = _bnb;
        startLv0 = params.startLv0;
        startLv1 = params.startLv1;
        startLv2 = params.startLv2;
        startLv3 = params.startLv3;
        startLv4 = params.startLv4;
        referralBonusLv0 = bonusParams.referralBonusLv0;
        referralBonusLv1 = bonusParams.referralBonusLv1;
        referralBonusLv2 = bonusParams.referralBonusLv2;
        referralBonusLv3 = bonusParams.referralBonusLv3;
        referralBonusLv4 = bonusParams.referralBonusLv4;
    }

    function setGeniAddress(IGENI _geni) external onlyOwner {
        require(address(_geni) != address(0), "GEMUNIMarketplace: new address must be different address(0)");
        geni = _geni;
        emit SetGeni(address(_geni));
    }  
    
    function setTreasury(address newTreasury) external onlyOwner {
        require(newTreasury != address(0));
        treasury = newTreasury;
        emit SetTreasury(newTreasury);
    }
    
    function setServer(address newServer) external onlyOwner {
        require(newServer != address(0));
        server = newServer;
        emit SetServer(newServer);
    }
    
    function setDiscountRate(uint value) external onlyOwner {
        require(value <= 1000000, "GENIPassSale: percentage not greater than 100.0000 %");
        discountRate = value;
        emit SetDiscountRate(value);
    }
    
    function setExchange(address _exchange) external onlyOwner {
        exchange = _exchange;
        emit SetExchange(_exchange);
    }

    function setReferralLevel(ReferalLevelParams memory params) external onlyOperator {
        require(params.startLv0 >= 0, "GENIPassSale: invalid level 0");
        require(params.startLv1 > params.startLv0, "GENIPassSale: invalid level 1");
        require(params.startLv2 > params.startLv1, "GENIPassSale: invalid level 2");
        require(params.startLv3 > params.startLv2, "GENIPassSale: invalid level 3");
        require(params.startLv4 > params.startLv3, "GENIPassSale: invalid level 4");
        startLv0 = params.startLv0;
        startLv1 = params.startLv1;
        startLv2 = params.startLv2;
        startLv3 = params.startLv3;
        startLv4 = params.startLv4;
        emit SetReferralLevel(startLv0, startLv1, startLv2, startLv3, startLv4);
    }

    function setReferralBonusLevel0(uint _rate) external onlyOperator {
        require(_rate <= 1000000, "GENIPassSale: percentage not greater than 100.0000 %");
        referralBonusLv0 = _rate;
        emit SetReferralBonusLevel0(_rate);
    }

    function setReferralBonusLevel1(uint _rate) external onlyOperator {
        require(_rate <= 1000000, "GENIPassSale: percentage not greater than 100.0000 %");
        referralBonusLv1 = _rate;
        emit SetReferralBonusLevel1(_rate);
    }

    function setReferralBonusLevel2(uint _rate) external onlyOperator {
        require(_rate <= 1000000, "GENIPassSale: percentage not greater than 100.0000 %");
        referralBonusLv2 = _rate;
        emit SetReferralBonusLevel2(_rate);
    }

    function setReferralBonusLevel3(uint _rate) external onlyOperator {
        require(_rate <= 1000000, "GENIPassSale: percentage not greater than 100.0000 %");
        referralBonusLv3 = _rate;
        emit SetReferralBonusLevel3(_rate);
    }

    function setReferralBonusLevel4(uint _rate) external onlyOperator {
        require(_rate <= 1000000, "GENIPassSale: percentage not greater than 100.0000 %");
        referralBonusLv4 = _rate;
        emit SetReferralBonusLevel4(_rate);
    }
    
    function putOnSale(uint passId, uint price, IGENIPass.PriceType priceType, uint startTime, uint expirationTime) public override whenNotPaused onlyOperator {
        require(startTime >= block.timestamp, "GEMUNIMarketplace: invalid start time");
        require(expirationTime > startTime, "GEMUNIMarketplace: invalid end time");
        IGENIPass.GeniPass memory pass =  geniPass.getPass(passId);
        geniPass.transferFrom(msg.sender, address(this), passId);
        
        SaleInfo storage saleInfo = saleInfos[passId];
        saleInfo.priceType = priceType;
        IGENIPass.PassType passType = pass.passType;
        saleInfo.price = getPricePass(passId, price, priceType);
        saleInfo.startTime = startTime;
        saleInfo.expirationTime = expirationTime;
    
        emit PassPutOnSale(passId, saleInfo.price, uint(priceType), treasury, startTime, expirationTime);
    }
    
    function mintForSale(string memory serialNumber, uint price, IGENIPass.PassType passType, IGENIPass.PriceType priceType, uint startTime, uint expirationTime) public override whenNotPaused onlyOperator {
        require(startTime >= block.timestamp, "GEMUNIMarketplace: invalid start time");
        require(expirationTime > startTime, "GEMUNIMarketplace: invalid end time");
        uint passId = geniPass.mint(address(this), serialNumber, passType);
        SaleInfo storage saleInfo = saleInfos[passId];
        saleInfo.priceType = priceType;
        saleInfo.price = getPricePass(passId, price, priceType);
        saleInfo.startTime = startTime;
        saleInfo.expirationTime = expirationTime;
    
        emit PassPutOnSale(passId, saleInfo.price, uint(priceType), treasury, startTime, expirationTime);
    }

    function updateSale(uint passId, uint price) external override onlyOperator whenNotPaused {
        SaleInfo storage saleInfo = saleInfos[passId];
        require(saleInfo.price > 0, "GENIPassSale: not for sale");
        require(block.timestamp <= saleInfo.expirationTime, "GEMUNIMarketplace: expired");
        require(price > 0, "GENIPassSale: invalid price");

        saleInfo.price = price;

        emit PassUpdateSale(passId, saleInfo.price, treasury);
    }
    
    function removeFromSale(uint passId) external override onlyOperator whenNotPaused nonReentrant {
        SaleInfo storage saleInfo = saleInfos[passId];
        require(saleInfo.price > 0, "GENIPassSale: not for sale");

        geniPass.transferFrom(address(this), msg.sender, passId);

        emit PassRemoveFromSale(passId, treasury);
        delete saleInfos[passId];
    }

    function getPricePass(uint passId, uint price, IGENIPass.PriceType priceType) public view override returns(uint pricePass) {
        bool isExistedToken = geniPass.exists(passId);
        require(isExistedToken, "GENIPassSale: invalid tokenId");
        IGENIPass.PassType passType = geniPass.getPass(passId).passType;  
        if(price != 0) {
            pricePass = price;
        } else {
            if (priceType == IGENIPass.PriceType.BNB) {
                uint defaultPrice = 10 ** ERC20(address(busd)).decimals() / 10;
                address[] memory pair = new address[](2);
                (pair[0], pair[1]) = (busd, bnb);
                uint256[] memory amounts = IExchangeRouter(exchange).getAmountsOut(defaultPrice, pair);
                pricePass = amounts[1];
            } else {
                if (passType == IGENIPass.PassType.Stone) {
                    pricePass = 375;
                } else if (passType == IGENIPass.PassType.Topaz) {
                    pricePass = 850;
                } else if (passType == IGENIPass.PassType.Citrine) {
                    pricePass = 1450;
                } else if (passType == IGENIPass.PassType.Ruby) {
                    pricePass = 2100;
                } else if (passType == IGENIPass.PassType.Diamond) {
                    pricePass = 3100;
                }
                pricePass = pricePass * 10 ** ERC20(address(geni)).decimals();
            }
        }
    }

    function putOnSaleBatch(CreateSalePassesWithoutMint[] memory input) external override whenNotPaused onlyOperator {
        for (uint i = 0; i < input.length; i++) {
            putOnSale(input[i].passId, input[i].price, input[i].priceType, input[i].startTime, input[i].expirationTime);
        }
    }
    
    function mintForSaleBatch(CreateSalePasses[] memory input) external override whenNotPaused onlyOperator {
        for (uint i = 0; i < input.length; i++) {
             mintForSale(input[i].serialNumber, input[i].price, input[i].passType, input[i].priceType, input[i].startTime, input[i].expirationTime);
        }
    }
    
    function purchase(uint passId, uint buyPrice) external payable override whenNotPaused nonReentrant {
        SaleInfo storage saleInfo = saleInfos[passId];
        
        address buyer = msg.sender;
        require(saleInfo.price > 0, "GENIPassSale: not for sale");
        require(block.timestamp >= saleInfo.startTime, "GEMUNIMarketplace: Sale has not started");
        require(block.timestamp <= saleInfo.expirationTime, "GEMUNIMarketplace: expired to purchase");
        require(buyer != treasury, "GENIPassSale: treasury can not buy");
        
        uint salePrice = saleInfo.price;
        uint payPrice = geniPass.balanceOf(buyer) > 0 ? (salePrice - (salePrice * discountRate / 100 / decimalRate)) : salePrice;

        if (saleInfo.priceType == IGENIPass.PriceType.GENI) 
            require(buyPrice == payPrice, "GENIPassSale: invalid trade price");
        else require(msg.value == payPrice, "GENIPassSale: invalid trade price");
        
        if (saleInfo.priceType == IGENIPass.PriceType.GENI) {
            geni.safeTransferFrom(buyer, treasury, payPrice);
        } else {
            treasury.call{value: payPrice}("");
        }
        
        geniPass.transferFrom(address(this), buyer, passId);
        emit PassBought(passId, buyer, treasury, saleInfo.price, payPrice);
        delete saleInfos[passId];
    }

    function getMessageHash(
        address _to,
        uint256 _nonce
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_to, _nonce));
    }
    
    function purchaseWithReferral(uint passId, uint buyPrice, address referralAddress, uint nonce, bytes memory signature) external payable override whenNotPaused nonReentrant {
        SaleInfo storage saleInfo = saleInfos[passId];
        
        address buyer = msg.sender;
        require(saleInfo.price > 0, "GENIPassSale: not for sale");
        require(block.timestamp >= saleInfo.startTime, "GEMUNIMarketplace: Sale has not started");
        require(block.timestamp <= saleInfo.expirationTime, "GEMUNIMarketplace: expired to purchase");
        require(buyer != treasury, "GENIPassSale: owner can not buy");
        
        uint salePrice = saleInfo.price;
        uint payPrice = geniPass.balanceOf(buyer) > 0 ? (salePrice - (salePrice * discountRate / 100 / decimalRate)) : salePrice;

        if (saleInfo.priceType == IGENIPass.PriceType.GENI) 
            require(buyPrice == payPrice, "GENIPassSale: invalid trade price");
        else require(msg.value == payPrice, "GENIPassSale: invalid trade price");
        
        address recoverAddress = VerifySignature.recoverSigner(VerifySignature.getEthSignedMessageHash(getMessageHash(referralAddress, nonce)), signature);
        
        require(recoverAddress == server, "GENIPassSale: invalid signature");
        require(referralAddress != buyer, "GENIPassSale: invalid buyer");
        require(!isUsedNonce[nonce], "GENIPassSale: can only use nonce 1 time");
        require(!isEnterReferral[buyer], "GENIPassSale: can only enter referral code 1 time");
        uint monthIndex = getMonthIndex(saleInfo.startTime);

        uint passAmount = passCount[referralAddress][monthIndex];
        
        salePrice = payPrice * (1000000 -  getDiscountReferral(passAmount)) / decimalRate / 100;
        if (saleInfo.priceType == IGENIPass.PriceType.GENI) {
            geni.safeTransferFrom(buyer, treasury, salePrice);
            if(getDiscountReferral(passAmount) > 0){
                geni.safeTransferFrom(buyer, referralAddress, payPrice - salePrice);
            }
        } else {
            treasury.call{value: salePrice}("");
            if(getDiscountReferral(passAmount) > 0){
                referralAddress.call{value: payPrice - salePrice}("");
            }
        }

        geniPass.transferFrom(address(this), buyer, passId);
        isUsedNonce[nonce] = true;
        isEnterReferral[buyer] = true;
        passCount[referralAddress][monthIndex] +=  1;
        emit PassBoughtWithReferral(passId, buyer, treasury, referralAddress, nonce, saleInfo.price, payPrice, payPrice - salePrice);
        delete saleInfos[passId];
    }
    
    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function pause() external onlyOperator {
        _pause();
    }

    function unpause() external onlyOperator {
        _unpause();
    }

    function withdrawNftEmergency(uint tokenId, address recipient) external whenPaused onlyOperator {
        SaleInfo memory saleInfo = saleInfos[tokenId];
        require(saleInfo.price > 0, "GENIPassSale: not for sale");

        geniPass.transferFrom(address(this), recipient, tokenId);
        emit WithdrawGeniPass(treasury, recipient, tokenId);

        delete saleInfos[tokenId];
    }

    function withdrawTokenEmergency(address token, uint amount, address recipient) external whenPaused onlyOperator {
        require(amount > 0, "GENIPassSale: invalid price");
        require(IERC20(token).balanceOf(address(this)) >= amount, "GENIPassSale: not enough balance");

        IERC20(token).transferFrom(address(this), recipient, amount);

        emit WithdrawToken(token, recipient, amount);
    }

    function withdrawETHEmergency(uint amount, address recipient) external payable whenPaused onlyOperator {
        require(amount > 0, "GENIPassSale: invalid price");
        require((address(this).balance) >= amount, "GENIPassSale: not enough balance");
        require(msg.value == amount, "GENIPassSale: invalid amount");

        recipient.call{value: amount}("");

        emit WithdrawETH(recipient, amount);
    }

    function getMonthIndex(uint startTime) public view returns (uint monthIndex){
        uint index = (block.timestamp - startTime) / SECONDS_PER_MONTH;
        monthIndex = index + 1;
    }

    function getDiscountReferral(uint amount) internal returns (uint referralBonus){
        if (amount >= startLv0 && amount < startLv1)
            referralBonus = referralBonusLv0;
        else if (amount >= startLv1 && amount < startLv2)
            referralBonus = referralBonusLv1;
        else if (amount >= startLv2 && amount < startLv3)
            referralBonus = referralBonusLv2;
        else if (amount >= startLv3 && amount < startLv4)
            referralBonus = referralBonusLv3;
        else if (amount >= startLv4)
            referralBonus = referralBonusLv4;
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

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
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

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

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
     * by making the `nonReentrant` function external, and make it call a
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

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/introspection/IERC165.sol)

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
interface IERC165Upgradeable {
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
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
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
// OpenZeppelin Contracts v4.4.0 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal initializer {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal initializer {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}