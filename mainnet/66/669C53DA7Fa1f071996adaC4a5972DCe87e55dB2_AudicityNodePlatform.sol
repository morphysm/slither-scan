//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./interfaces/IAudicityNodePlatform.sol";
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import "./TraderJoe/libraries/JoeLibrary.sol";
import "./TraderJoe/interfaces/IJoeRouter02.sol";

contract AudicityNodePlatform is OwnableUpgradeable, IAudicityNodePlatform {
    using SafeMath for uint256;
    
    address public communityTokenAddress;
    uint256 public totalNodeCount;
    uint256 public totalActiveNodeCount;
    uint256 public totalInactiveNodeCount;
    uint256 public totalDeletedNodeCount;
    address joeFactoryAddress;
    address joeRouterAddress;

    uint256 public nodeCost;
    uint256 public nodeDistribution;
    uint256 public nodeCap;
    uint256 public nodeUsdMonthlyFee;
    uint256 public nodeClaimLimit;    

    address distributionPoolAddress;
    uint256 nodePurchaseLimit;
    address payable treasuryAddress;

    uint256 public halvingNodeAmount;
    uint256 public halvingAmount;
    uint256 thirtyDaySeconds;
    uint256 sixtyDaySeconds;
    uint256 ninetyDaySeconds;

    AggregatorV3Interface internal priceFeed;

    mapping(uint256 => NodeIdInfo) public userByNodeId;
    mapping(address => uint256[]) public nodesByUser;
    mapping(uint256 => NodeInfo) public nodes;
    mapping(uint256 => uint256) public halvingTimes;

    function initialize(
        address _communityTokenAddress,
        uint256 _halvingNodeAmount,
        address _priceOracleAddress,
        address _joeRouterAddress,
        address _joeFactoryAddress
    ) public initializer {

        __Ownable_init();

        communityTokenAddress = _communityTokenAddress;

        distributionPoolAddress = payable(0x231C3B95b0F91cE2bcaCA14B6Be8Ebe02790Bb62);
        treasuryAddress = payable(0xa158e0e2c17D6e29a5Ef43B58c6182814D736fa6);

        joeRouterAddress = _joeRouterAddress;
        joeFactoryAddress = _joeFactoryAddress;

        nodeCost = 10 ether;
        nodeDistribution = 0.1 ether;
        nodeCap = 40;

        nodeClaimLimit = 86400;
        nodeUsdMonthlyFee = 12;
        nodePurchaseLimit = 10;

        halvingNodeAmount = _halvingNodeAmount;

        thirtyDaySeconds = 2592000;
        sixtyDaySeconds = 5184000;
        ninetyDaySeconds = 7776000;

        priceFeed = AggregatorV3Interface(_priceOracleAddress);

        IERC20Upgradeable(communityTokenAddress).approve(joeRouterAddress, type(uint256).max);
    }

    function purchaseNode(uint256 amount) public {
        require(amount <= nodePurchaseLimit, "Exceed One-Time Max Purchase");
        _purchaseNode(amount, false);
    }

    function _purchaseNode(uint256 amount, bool compounded) internal {
        uint256 payment;
        if (totalActiveNodeCount.add(amount) > halvingNodeAmount) {
            if (halvingAmount.mod(2) == 1) {
                uint256 pendingNodesFromOldHalving = halvingNodeAmount.sub(totalActiveNodeCount);
                if (!compounded) payment = payment.add(nodeCost.mul(pendingNodesFromOldHalving));
                _setupNewNodes(
                    msg.sender,
                    pendingNodesFromOldHalving,
                    0,
                    compounded
                );
                amount = amount.sub(pendingNodesFromOldHalving); 
            }
            _executeHalving();
        }
        if (!compounded) payment = payment.add(nodeCost.mul(amount));

        uint256 remainingActiveNodes = _getRemainingActiveNodes();
        uint256 inactiveNodes = 0;

        if (remainingActiveNodes < amount) {
            inactiveNodes = amount.sub(remainingActiveNodes);
            amount = remainingActiveNodes;
        }
        _setupNewNodes(msg.sender, amount, inactiveNodes, compounded);
        if (!compounded) {
            uint256 distributionTokens = (payment.mul(975)).div(1000);
            uint256 liquidityTokens = payment.sub(distributionTokens);
            require(
                IERC20Upgradeable(communityTokenAddress).transferFrom(
                    msg.sender,
                    distributionPoolAddress,
                    distributionTokens
                ),
                "Transfer failed"
            );
            require(
                IERC20Upgradeable(communityTokenAddress).transferFrom(
                    msg.sender,
                    address(this),
                    liquidityTokens
                ),
                "Transfer failed"
            );
            uint256 swapToAvaxToken = liquidityTokens.div(2);
            address[] memory paths = new address[](2);
            paths[0] = communityTokenAddress;
            paths[1] = IJoeRouter02(joeRouterAddress).WAVAX();
            address wAvax = IJoeRouter02(joeRouterAddress).WAVAX();
            (uint256 reserveA, uint256 reserveB) = JoeLibrary.getReserves(
                joeFactoryAddress,
                communityTokenAddress,
                wAvax
            );
            IJoeRouter02(joeRouterAddress).swapExactTokensForAVAX(
                swapToAvaxToken, 
                0, 
                paths, 
                address(this), 
                block.timestamp
            );
            uint256 avaxBalance = address(this).balance;
            wAvax = IJoeRouter02(joeRouterAddress).WAVAX();
            (reserveA, reserveB) = JoeLibrary.getReserves(
                joeFactoryAddress,
                communityTokenAddress,
                wAvax
            );
            if (reserveA == 0 && reserveB == 0) return;
            uint256 liquidityAvax = JoeLibrary.quote(
                swapToAvaxToken,
                reserveA,
                reserveB
            );
            if (liquidityAvax > avaxBalance) return;
            IJoeRouter02(joeRouterAddress).addLiquidityAVAX{value: avaxBalance}(
                communityTokenAddress,
                swapToAvaxToken,
                0,
                0,
                address(this),
                block.timestamp
            );
            (reserveA, reserveB) = JoeLibrary.getReserves(
                joeFactoryAddress,
                communityTokenAddress,
                wAvax
            );
        }
    }

    function _getRemainingActiveNodes() internal view returns (uint256 remainingActiveNodes) {
        uint256[] memory nodeIds = nodesByUser[msg.sender];
        uint256 currentNodeId;

        uint256 activeCount;
        for (uint256 index = 0; index < nodeIds.length; index++) {
            currentNodeId = nodeIds[index];
            if (nodes[currentNodeId].isActive) {
                activeCount = activeCount.add(1);
            }
        }
        remainingActiveNodes = nodeCap.sub(activeCount);
    }

    function _setupNewNodes(address nodeOwnerAddress, uint256 activeNodes, uint256 inactiveNodes, bool compounded) internal {
        uint256 index;
        for (index = 0; index < activeNodes; index++) {
            _addNodesToAddress(
                nodeOwnerAddress,
                totalNodeCount.add(index),
                true,
                compounded
            );
        }
        totalNodeCount += activeNodes;
        totalActiveNodeCount += activeNodes;
        for (index = 0; index < inactiveNodes; index++) {
            _addNodesToAddress(
                nodeOwnerAddress,
                totalNodeCount.add(index),
                false,
                compounded
            );
        }
        totalNodeCount = totalNodeCount.add(inactiveNodes);
        totalInactiveNodeCount = totalInactiveNodeCount.add(inactiveNodes);
    }

    function _addNodesToAddress(address nodeOwnerAddress, uint256 id, bool status, bool compounded) internal {
        NodeInfo memory info;
        info.id = id;
        info.owner = nodeOwnerAddress;
        info.creationTimestamp = block.timestamp;
        info.isCompounded = compounded;
        info.isActive = status;
        info.isDistributionAvailable = status;
        info.lastClaimTimestamp = block.timestamp;
        info.nextAvailableClaimTimestamp = block.timestamp.add(nodeClaimLimit);
        info.operationalUntilTimestamp = block.timestamp.add(thirtyDaySeconds);

        nodes[id] = info;
        nodesByUser[nodeOwnerAddress].push(id);

        NodeIdInfo memory idInfo;
        idInfo.owner = nodeOwnerAddress;
        idInfo.index = (nodesByUser[nodeOwnerAddress].length).sub(1);
        userByNodeId[id] = idInfo;
    }

    function _getPayAmountForMonthlyCharge(uint256 lastMoment) internal view returns (uint256) {
        uint256 index;
        uint256 historicMonthlyFee = nodeUsdMonthlyFee;
        uint256 usdPayAmount;
        uint256[] memory checkPoints = new uint256[](3);
        for (index = 0; index < 3; index++)
            checkPoints[index] = lastMoment.add(index.mul(thirtyDaySeconds));
        for (index = 1; index < halvingAmount; index += 2)
            historicMonthlyFee = historicMonthlyFee.mul(2);
        for (index = 1; index < halvingAmount; index += 2) {
            if (
                halvingTimes[index] >= checkPoints[0] &&
                halvingTimes[index] < checkPoints[1] &&
                checkPoints[0] != 0
            ) {
                usdPayAmount = usdPayAmount.add(historicMonthlyFee);
                checkPoints[0] = 0;
            } else if (
                halvingTimes[index] >= checkPoints[1] &&
                halvingTimes[index] < checkPoints[2] &&
                checkPoints[1] != 0
            ) {
                if (checkPoints[0] == 0) {
                    usdPayAmount = usdPayAmount.add(historicMonthlyFee);
                } else {
                    usdPayAmount = usdPayAmount.add(historicMonthlyFee.mul(2));
                }
                checkPoints[1] = 0;
            }
            historicMonthlyFee = historicMonthlyFee.div(2);
        }
        return usdPayAmount;
    }

    function getAllPayNodeFeesInfo(address nodeOwnerAddress) external view returns (uint256){
        uint256[] memory nodeIds = nodesByUser[nodeOwnerAddress];
        uint256 totalNodesAdditionTime = 0;

        for (uint256 index = 0; index < nodeIds.length; index++) {
            NodeInfo storage nodeInfo = nodes[nodeIds[index]];
            uint256 operationalUntilTimestamp = nodeInfo.operationalUntilTimestamp;

            uint256 elapsedTime = 0;
            uint256 totalNodeTime = thirtyDaySeconds;
            if(nodeInfo.isActive){
                if(operationalUntilTimestamp <= block.timestamp){
                    elapsedTime = block.timestamp - operationalUntilTimestamp;
                    if(elapsedTime >= sixtyDaySeconds){
                        totalNodeTime = ninetyDaySeconds;
                    } else if(elapsedTime >= thirtyDaySeconds){
                        totalNodeTime = sixtyDaySeconds;
                    }
                }
                totalNodesAdditionTime += totalNodeTime;
            }
        }
        return totalNodesAdditionTime / thirtyDaySeconds;
    }

    function _updateNodeFee(uint256 nodeId, address user, uint256 advancedPayMonths) internal returns (uint256) {
        NodeIdInfo memory idInfo = userByNodeId[nodeId];
        require(idInfo.owner == user, "Owner mismatch");
        uint256[] memory nodeIds = nodesByUser[user];
        uint256 payNodeId = nodeIds[idInfo.index];
        NodeInfo storage nodeInfo = nodes[payNodeId];
        if (!nodeInfo.isActive) return 0;
        uint256 operationalUntilTimestamp = nodeInfo.operationalUntilTimestamp;
        if (operationalUntilTimestamp >= block.timestamp) {
            if (
                (operationalUntilTimestamp.add(advancedPayMonths.mul(thirtyDaySeconds))).sub(block.timestamp) > ninetyDaySeconds
            ) return 0;
            nodeInfo.operationalUntilTimestamp = nodeInfo.operationalUntilTimestamp.add(thirtyDaySeconds.mul(advancedPayMonths));
            return nodeUsdMonthlyFee.mul(advancedPayMonths);
        }
        uint256 timeElapsed = block.timestamp.sub(operationalUntilTimestamp);
        if (timeElapsed > sixtyDaySeconds) {
            nodeInfo.operationalUntilTimestamp = nodeInfo.operationalUntilTimestamp.add(sixtyDaySeconds.add(thirtyDaySeconds.mul(advancedPayMonths)));
        } else if (timeElapsed > thirtyDaySeconds) {
            nodeInfo.operationalUntilTimestamp = nodeInfo.operationalUntilTimestamp.add(thirtyDaySeconds.add(thirtyDaySeconds.mul(advancedPayMonths)));
        } else {
            nodeInfo.operationalUntilTimestamp = nodeInfo.operationalUntilTimestamp.add(thirtyDaySeconds.mul(advancedPayMonths));
        }
        nodeInfo.isDistributionAvailable = true;
        uint256 usdPayAmount = _getPayAmountForMonthlyCharge(operationalUntilTimestamp).add(nodeUsdMonthlyFee.mul(advancedPayMonths));
        return usdPayAmount;
    }

    function payNodeFee(uint256 nodeId, uint256 advancedPayMonths) external payable {
        require(
            advancedPayMonths <= 5 && advancedPayMonths >= 1,
            "Minimum of one month payment"
        );
        address user = msg.sender;
        uint256 usdPayAmount = _updateNodeFee(nodeId, user, advancedPayMonths);
        uint256 avaxPayAmount = ((usdPayAmount * (10 ** 10)) / getAvaxUsdLatestPrice()) + 1;
        uint256 avaxAmount = avaxPayAmount * (10 ** 16);
        require(msg.value >= avaxAmount, "Wrong payment");
        uint256 returnAmt = msg.value - avaxAmount;
        bool success = false;
        (success, ) = address(treasuryAddress).call{
            value: avaxAmount,
            gas: 200000
        }("");
        if (returnAmt > 0) {
            payable(msg.sender).transfer(returnAmt);
        }
    }

    function payAllAvailableNodeFees() external payable {
        address user = msg.sender;
        uint256[] memory nodeIds = nodesByUser[user];
        uint256 usdPayAmount;
        for (uint256 index = 0; index < nodeIds.length; index++) {
            usdPayAmount += _updateNodeFee(nodeIds[index], user, 1);
        }
        uint256 avaxPayAmount = ((usdPayAmount * (10 ** 10)) / getAvaxUsdLatestPrice()) + 1;
        uint256 avaxAmount = avaxPayAmount * (10 ** 16);
        require(msg.value >= avaxAmount, "Wrong payment");
        uint256 returnAmt = msg.value - avaxAmount;
        bool success = false;
        (success, ) = address(treasuryAddress).call{
            value: avaxAmount,
            gas: 200000
        }("");
        if (returnAmt > 0) {
            payable(msg.sender).transfer(returnAmt);
        }
    }

    function _executeHalving() internal {
        if (halvingAmount % 2 != 0) {
            nodeCost /= 2;
            nodeUsdMonthlyFee /= 2;
        }
        nodeDistribution /= 2;
        nodeCap *= 2;
        halvingNodeAmount *= 2;
        halvingTimes[halvingAmount] = block.timestamp;
        halvingAmount += 1;
    }

    function getNodeClaimableDistribution(uint256 nodeId) public view returns (uint256) {
        NodeInfo memory nodeInfo = nodes[nodeId];
        if (!nodeInfo.isDistributionAvailable) return 0;
        if (nodeInfo.nextAvailableClaimTimestamp > block.timestamp) return 0;
        return getDistributionByNode(nodeInfo.lastClaimTimestamp);
    }

    function getNodeUnClaimableDistribution(uint256 nodeId) public view returns (uint256) {
        NodeInfo memory nodeInfo = nodes[nodeId];
        if (!nodeInfo.isActive || nodeInfo.isDeleted) return 0;
        if (nodeInfo.isDistributionAvailable && uint256(nodeInfo.nextAvailableClaimTimestamp) <= block.timestamp) return 0;
        return getDistributionByNode(nodeInfo.lastClaimTimestamp);
    }

    function getDistributionByNode(uint256 lastTime) public view returns (uint256) {
        uint256 historicNodeDistribution = nodeDistribution;
        uint256 lastCheckPoint = block.timestamp;
        uint256 timeElapsed = lastCheckPoint - lastTime;
        
        if (halvingAmount == 0) {
            return (historicNodeDistribution * timeElapsed) / nodeClaimLimit;
        }
        uint256 index;
        uint256 availableDistribution;
        for (; index < halvingAmount; index++) historicNodeDistribution *= 2;
        for (index = 0; index < halvingAmount; index++) {
            uint256 checkPoint = halvingTimes[index];
            if (lastTime < checkPoint) {
                availableDistribution += 
                    (lastCheckPoint - checkPoint) *
                    historicNodeDistribution;
            } else {
                break;
            }
            lastCheckPoint = checkPoint;
            historicNodeDistribution /= 2;
        }
        availableDistribution += (lastCheckPoint - lastTime) * historicNodeDistribution;
        return availableDistribution / nodeClaimLimit;
    }

    function _claimNodeDistribution(uint256 nodeId, address user, bool isCompounding) internal returns (uint256) {
        NodeInfo storage nodeInfo = nodes[nodeId];
        require(nodeInfo.owner == user, "Owner mismatch");
        require(nodeInfo.isDistributionAvailable == true, "Distribution is unavailable");
        require(
            nodeInfo.nextAvailableClaimTimestamp <= block.timestamp,
            "Need to wait for next claim time"
        );
        uint256 distribution = getDistributionByNode(nodeInfo.lastClaimTimestamp);
        nodeInfo.lastClaimTimestamp = block.timestamp;
        if(!isCompounding) nodeInfo.nextAvailableClaimTimestamp = block.timestamp + nodeClaimLimit;
        return distribution;
    }

    function claimSpecificNodeDistribution(uint256 nodeId) public {
       IERC20Upgradeable(communityTokenAddress).transferFrom(distributionPoolAddress, msg.sender, _claimNodeDistribution(nodeId, msg.sender, false));
    }

    function claimAllDistributions() public {
        address user = msg.sender;
        uint256[] memory nodeIds = nodesByUser[user];
        uint256 distribution;
        for (uint256 index = 0; index < nodeIds.length; index++) {
            if (!nodes[nodeIds[index]].isDistributionAvailable) continue;
            if (nodes[nodeIds[index]].lastClaimTimestamp >= block.timestamp - nodeClaimLimit) continue;
            distribution += _claimNodeDistribution(nodeIds[index], user, false);
        }
        IERC20Upgradeable(communityTokenAddress).transferFrom(distributionPoolAddress, user, distribution);
    }

    function compoundDistributions(uint256 nodeAmount) public {
        require(nodeAmount <= nodePurchaseLimit, "Exceed One-Time Max Compound");
        address user = msg.sender;
        uint256[] memory nodeIds = nodesByUser[user];
        uint256 compoundRequiredPayment;
        uint256 internalNodeCost = nodeCost;
        uint256 internalNodeAmount = nodeAmount;
        if (totalActiveNodeCount + internalNodeAmount > halvingNodeAmount) {
            if (halvingAmount % 2 == 1) {
                uint256 pendingNodesFromOldHalving = halvingNodeAmount -
                    totalActiveNodeCount;
                compoundRequiredPayment +=
                    internalNodeCost *
                    pendingNodesFromOldHalving;
                internalNodeAmount -= pendingNodesFromOldHalving;
                internalNodeCost /= 2;
            }
        }
        compoundRequiredPayment += internalNodeCost * internalNodeAmount;

        uint256 distribution;
        for (uint256 index = 0; index < nodeIds.length; index++) {
            distribution += _claimNodeDistribution(nodeIds[index], user, true);
            if (distribution >= compoundRequiredPayment) {
                break;
            }
        }
        if (distribution < compoundRequiredPayment) revert('Insufficient Distribution');
        distribution -= compoundRequiredPayment;
        _purchaseNode(nodeAmount, true);
        IERC20Upgradeable(communityTokenAddress).transferFrom(distributionPoolAddress, msg.sender, distribution);
    }

    function addNodesToAddress(address userAddress, uint256 nodeAmount) external onlyOwner {
        _setupNewNodes(userAddress, nodeAmount, 0, false);
    }

    function reDistributeNodesToAddress(address oldUser, address newUser, uint256[] calldata nodeIds) external onlyOwner {
        uint256[] storage nodesForOldUser = nodesByUser[oldUser];
        uint256[] storage nodesForNewUser = nodesByUser[newUser];
        for (uint256 index = 0; index < nodeIds.length; index++) {
            NodeIdInfo storage idInfo = userByNodeId[nodeIds[index]];
            require(idInfo.owner == oldUser, "Owner mismatch");

            nodesForNewUser.push(nodesForOldUser[idInfo.index]);
            nodesForOldUser[idInfo.index] = nodesForOldUser[
                nodesForOldUser.length - 1
            ];
            nodesForOldUser.pop();

            uint256 updatedOldUserNode = nodesForOldUser[idInfo.index];
            userByNodeId[updatedOldUserNode].index = idInfo.index;

            idInfo.owner = newUser;
            idInfo.index = nodesForNewUser.length - 1;

            NodeInfo storage nodeInfo = nodes[nodeIds[index]];
            nodeInfo.owner = newUser;
            nodeInfo.isCompounded = false;
            nodeInfo.isActive = true;
            nodeInfo.isDeleted = false;
            nodeInfo.isDistributionAvailable = true;
            nodeInfo.lastClaimTimestamp = block.timestamp;
            nodeInfo.nextAvailableClaimTimestamp =
                block.timestamp +
                nodeClaimLimit;
            nodeInfo.operationalUntilTimestamp =
                block.timestamp +
                thirtyDaySeconds;
        }
    }

    function removeNodes(uint256[] calldata nodeIds) external onlyOwner {
        for (uint256 index = 0; index < nodeIds.length; index++) {
            NodeInfo storage nodeInfo = nodes[nodeIds[index]];
            nodeInfo.isDeleted = true;
            nodeInfo.isDistributionAvailable = false;
            totalDeletedNodeCount += 1;
        }
    }

    function setNodesUnclaimable(uint256[] calldata nodeIds) external onlyOwner {
        for (uint256 index = 0; index < nodeIds.length; index++) {
            nodes[nodeIds[index]].isDistributionAvailable = false;
        }
    }

    function activateNode(uint256[] calldata nodeIds, uint256 operationStartTimestamp) external onlyOwner {
        for (uint256 index = 0; index < nodeIds.length; index++) {
            NodeInfo storage nodeInfo = nodes[nodeIds[index]];
            nodeInfo.isActive = true;
            nodeInfo.isDistributionAvailable = true;
            nodeInfo.lastClaimTimestamp = block.timestamp;
            nodeInfo.nextAvailableClaimTimestamp =
                operationStartTimestamp +
                nodeClaimLimit;
            nodeInfo.operationalUntilTimestamp =
                operationStartTimestamp +
                thirtyDaySeconds;
        }
    }

    function getTotalActiveNodeCount() external view returns (uint256) {
        return totalActiveNodeCount;
    }

    function getUserTotalNodes(address user) external view returns (uint256) {
        return getUserActiveNodes(user) + getUserInactiveNodes(user);
    }

    function getUserActiveNodes(address user) public view returns (uint256 count) {
        uint256[] memory nodeIds = nodesByUser[user];
        uint256 nodeId;
        for (uint256 i = 0; i < nodeIds.length; i++) {
            nodeId = nodeIds[i];
            if (nodes[nodeId].isActive) count += 1;
        }
    }

    function getUserInactiveNodes(address user) public view returns (uint256 count) {
        uint256[] memory nodeIds = nodesByUser[user];
        uint256 nodeId;
        for (uint256 i = 0; i < nodeIds.length; i++) {
            nodeId = nodeIds[i];
            if (!nodes[nodeId].isActive && !nodes[nodeId].isDeleted) count += 1;
        }
    }

    function getUserPurchasedNodes(address user) external view returns (uint256 count) {
        uint256[] memory nodeIds = nodesByUser[user];
        uint256 nodeId;
        for (uint256 i = 0; i < nodeIds.length; i++) {
            nodeId = nodeIds[i];
            if (!nodes[nodeId].isCompounded) count += 1;
        }
    }

    function getUserCompoundedNodes(address user) external view returns (uint256 count) {
        uint256[] memory nodeIds = nodesByUser[user];
        uint256 nodeId;
        for (uint256 i = 0; i < nodeIds.length; i++) {
            nodeId = nodeIds[i];
            if (nodes[nodeId].isCompounded) count += 1;
        }
    }

    function getUserTotalDistributions(address user) external view returns (uint256) {
        return getUserClaimableDistributions(user) + getUserUnClaimableDistributions(user);
    }

    function getUserClaimableDistributions(address user) public view returns (uint256) {
        uint256[] memory nodeIds = nodesByUser[user];
        uint256 allDistribution;
        for (uint256 i = 0; i < nodeIds.length; i++) {
            allDistribution += getNodeClaimableDistribution(nodeIds[i]);
        }
        return allDistribution;
    }

    function getUserUnClaimableDistributions(address user) public view returns (uint256) {
        uint256[] memory nodeIds = nodesByUser[user];
        uint256 allDistribution;
        for (uint256 i = 0; i < nodeIds.length; i++) {
            allDistribution += getNodeUnClaimableDistribution(nodeIds[i]);
        }
        return allDistribution;
    }

    function getUserPendingFees(address user) external view returns (uint256) {
        uint256[] memory nodeIds = nodesByUser[user];
        uint256 pendingFees;
        for (uint256 i = 0; i < nodeIds.length; i++) {
            pendingFees += getNodePendingFee(nodeIds[i]);
        }
        return pendingFees;
    }

    function getNodePendingFee(uint256 nodeId) public view returns (uint256) {
        if (!nodes[nodeId].isActive) return 0;
        if (nodes[nodeId].operationalUntilTimestamp >= block.timestamp) return 0;
        return _getPayAmountForMonthlyCharge(nodes[nodeId].operationalUntilTimestamp);
    }

    function getUserNodeIds(address user) public view returns(uint256[] memory nodeIds) {
       nodeIds = nodesByUser[user];
    }

    function getNodeDataById(uint256 nodeId) public view returns(NodeInfo memory nodeData) {
       nodeData = nodes[nodeId];
    }

    function getAvaxUsdLatestPrice() public view returns (uint) {
        (, int price, , , ) = priceFeed.latestRoundData();
        return uint(price);
    }

    receive() external payable {}
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

interface IAudicityNodePlatform {  
    struct NodeInfo {
        uint256 id;
        address owner;
        uint256 creationTimestamp;
        bool isCompounded;
        bool isActive;
        bool isDeleted;
        bool isDistributionAvailable;
        uint256 lastClaimTimestamp;
        uint256 nextAvailableClaimTimestamp;
        uint256 operationalUntilTimestamp;
    }
    struct NodeIdInfo {
        address owner;
        uint256 index;
    }

    function purchaseNode(uint256 amount) external;

    function getAllPayNodeFeesInfo(address nodeOwnerAddress) external view returns (uint256);

    function payNodeFee(uint256 nodeId, uint256 advancedPayMonths) external payable;

    function payAllAvailableNodeFees() external payable;

    function getNodeClaimableDistribution(uint256 nodeId) external view returns (uint256);

    function getNodeUnClaimableDistribution(uint256 nodeId) external view returns (uint256);

    function getDistributionByNode(uint256 lastTime) external view returns (uint256);

    function claimSpecificNodeDistribution(uint256 nodeId) external;

    function claimAllDistributions() external;

    function compoundDistributions(uint256 nodeAmount) external;

    function addNodesToAddress(address userAddress, uint256 nodeAmount) external;

    function reDistributeNodesToAddress(address oldUser, address newUser, uint256[] calldata nodeIds) external;

    function removeNodes(uint256[] calldata nodeIds) external;

    function setNodesUnclaimable(uint256[] calldata nodeIds) external;

    function activateNode(uint256[] calldata nodeIds, uint256 operationStartTimestamp) external;

    function getTotalActiveNodeCount() external view returns (uint256);

    function getUserTotalNodes(address user) external view returns (uint256);

    function getUserActiveNodes(address user) external view returns (uint256 count);

    function getUserInactiveNodes(address user) external view returns (uint256 count);

    function getUserPurchasedNodes(address user) external view returns (uint256 count);

    function getUserCompoundedNodes(address user) external view returns (uint256 count);

    function getUserTotalDistributions(address user) external view returns (uint256);

    function getUserClaimableDistributions(address user) external view returns (uint256);

    function getUserUnClaimableDistributions(address user) external view returns (uint256);

    function getUserPendingFees(address user) external view returns (uint256);

    function getNodePendingFee(uint256 nodeId) external view returns (uint256);

    function getUserNodeIds(address user) external view returns(uint256[] memory nodeIds);

    function getNodeDataById(uint256 nodeId) external view returns(NodeInfo memory nodeData);

    function getAvaxUsdLatestPrice() external view returns (uint);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0;

import "../interfaces/IJoePair.sol";
import "../interfaces/IJoeFactory.sol";

import "./SafeMath.sol";

library JoeLibrary {
    using SafeMathJoe for uint256;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB)
        internal
        pure
        returns (address token0, address token1)
    {
        require(tokenA != tokenB, "JoeLibrary: IDENTICAL_ADDRESSES");
        (token0, token1) = tokenA < tokenB
            ? (tokenA, tokenB)
            : (tokenB, tokenA);
        require(token0 != address(0), "JoeLibrary: ZERO_ADDRESS");
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(
        address factory,
        address tokenA,
        address tokenB
    ) internal view returns (address pair) {
        // (address token0, address token1) = sortTokens(tokenA, tokenB);
        // pair = address(
        //     uint160(
        //         uint256(
        //             keccak256(
        //                 abi.encodePacked(
        //                     hex"ff",
        //                     factory,
        //                     keccak256(abi.encodePacked(token0, token1)),
        //                     hex"0bbca9af0511ad1a1da383135cf3a8d2ac620e549ef9f6ae3a4c33c2fed0af91" // init code fuji
        //                 )
        //             )
        //         )
        //     )
        // );
        pair = IJoeFactory(factory).getPair(tokenA, tokenB);
    }

    // fetches and sorts the reserves for a pair
    function getReserves(
        address factory,
        address tokenA,
        address tokenB
    ) internal view returns (uint256 reserveA, uint256 reserveB) {
        (address token0, ) = sortTokens(tokenA, tokenB);
        (uint256 reserve0, uint256 reserve1, ) = IJoePair(
            pairFor(factory, tokenA, tokenB)
        ).getReserves();
        (reserveA, reserveB) = tokenA == token0
            ? (reserve0, reserve1)
            : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) internal pure returns (uint256 amountB) {
        require(amountA > 0, "JoeLibrary: INSUFFICIENT_AMOUNT");
        require(
            reserveA > 0 && reserveB > 0,
            "JoeLibrary: INSUFFICIENT_LIQUIDITY"
        );
        amountB = amountA.mul(reserveB) / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountOut) {
        require(amountIn > 0, "JoeLibrary: INSUFFICIENT_INPUT_AMOUNT");
        require(
            reserveIn > 0 && reserveOut > 0,
            "JoeLibrary: INSUFFICIENT_LIQUIDITY"
        );
        uint256 amountInWithFee = amountIn.mul(997);
        uint256 numerator = amountInWithFee.mul(reserveOut);
        uint256 denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountIn) {
        require(amountOut > 0, "JoeLibrary: INSUFFICIENT_OUTPUT_AMOUNT");
        require(
            reserveIn > 0 && reserveOut > 0,
            "JoeLibrary: INSUFFICIENT_LIQUIDITY"
        );
        uint256 numerator = reserveIn.mul(amountOut).mul(1000);
        uint256 denominator = reserveOut.sub(amountOut).mul(997);
        amountIn = (numerator / denominator).add(1);
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(
        address factory,
        uint256 amountIn,
        address[] memory path
    ) internal view returns (uint256[] memory amounts) {
        require(path.length >= 2, "JoeLibrary: INVALID_PATH");
        amounts = new uint256[](path.length);
        amounts[0] = amountIn;
        for (uint256 i; i < path.length - 1; i++) {
            (uint256 reserveIn, uint256 reserveOut) = getReserves(
                factory,
                path[i],
                path[i + 1]
            );
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(
        address factory,
        uint256 amountOut,
        address[] memory path
    ) internal view returns (uint256[] memory amounts) {
        require(path.length >= 2, "JoeLibrary: INVALID_PATH");
        amounts = new uint256[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint256 i = path.length - 1; i > 0; i--) {
            (uint256 reserveIn, uint256 reserveOut) = getReserves(
                factory,
                path[i - 1],
                path[i]
            );
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }
}

// SPDX-License-Identifier: GPL-3.0

import "./IJoeRouter01.sol";

pragma solidity ^0.8.9;

interface IJoeRouter02 is IJoeRouter01 {
    function removeLiquidityAVAXSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountAVAX);

    function removeLiquidityAVAXWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountAVAX);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactAVAXForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForAVAXSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.9;

interface IJoePair {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to)
        external
        returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.9;

// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)

library SafeMathJoe {
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, "ds-math-add-overflow");
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x, "ds-math-sub-underflow");
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x, "ds-math-mul-overflow");
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0;

interface IJoeFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint256);

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function migrator() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;

    function setMigrator(address) external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.9;

interface IJoeRouter01 {
    function factory() external view returns (address);

    function WAVAX() external view returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityAVAX(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountAVAX,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityAVAX(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountAVAX);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityAVAXWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountAVAX);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactAVAXForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactAVAX(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForAVAX(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapAVAXForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
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
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
                /// @solidity memory-safe-assembly
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