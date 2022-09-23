//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./EmeraldNodeStorageV2.sol";

contract EmeraldNodeV2 is EmeraldNodeStorageV2 {

    // modifier for msg.sender is blacklisted.
    modifier isBlacklistedAddress() {
        require(
            blacklistAddresses[msg.sender] == false,
            "EmeraldERC20V1: You are blacklisted"
        );
        _;
    }

    /**
     * @dev updates the Emerald token address
     *  
     * @param _address address of emerald token
     * Requirements:
     * - only owner can update value.
    */

    function updateEmeraldCoinAddress(address _address) external onlyOwner returns(bool){
        EmeraldCoin = IERC20(_address);
        return true;
    }
    
    /**
     * @dev updates the community address
     *  
     * @param _address address of community
     * Requirements:
     * - only owner can update value.
    */

    function updateCommunityAddress(address _address) external onlyOwner returns(bool){
        communityAddress = _address;
        return true;
    }


    /**
     * @dev updates the Tier details
     *  
     * @param num number of tiers to be updated.
     * @param _tier tier number in array.
     * @param _nodePrice node price for tier.
     * @param _rate reward rate.
     * @param _interval reward claim interval in seconds.
     *
     * Requirements:
     * - only owner can update value.
    */
    
    function setTierReward(uint num, uint256[] calldata _tier, uint256[] calldata _nodePrice, uint256[] calldata _nodeAvaxPrice, uint256[] calldata _rate, uint256[] calldata _interval) onlyOwner external returns(bool){

        for(uint i = 0; i < num; i++){
            UpdatedTier storage data = updatedTierDetails[_tier[i]];
            data.nodeTier = _tier[i];
            data.tierEMnodePrice = _nodePrice[i];
            data.tierAVAXnodePrice = _nodeAvaxPrice[i];
            data.rewardRate = _rate[i];
            data.intervalTimestamp = _interval[i];
        }
        return true;
    }

    // setReward details = //setTierReward(6, [1,2,3,4,5,6], [10000000000000000000,10000000000000000000,10000000000000000000,9000000000000000000,8000000000000000000,6000000000000000000],[500000000000000000,200000000000000000,100000000000000000,750000000000000000,50000000000000000,25000000000000000], [86400,86400,86400,86400,86400,86400]);

    /**
     * @dev updates the range of Node Ids
     *  
     * @param _ids array of Ids
     *
     * Requirements:
     * - only owner can update value.
    */

    function updateNodeIds(uint256[] calldata _ids) external onlyOwner returns(bool){
        delete nodeIds;
        for(uint i = 0; i < _ids.length; i++){
          nodeIds.push(_ids[i]);
        }
        return true;
    }

    /**
     * @dev updates the Emerald token address
     *  
     * @param _num updates the count for whitelist address in Tier X.
     *
     * Requirements:
     * - only owner can update value.
    */

    function updateCount(uint256 _num, uint256 _count) external onlyOwner returns(bool){
        count = _num;
        RegularNodeCounter = _count;
        return true;
    }

    /**
     * @dev whitelist addresses
     *  
     * @param _addresses array of whitlist address.
     *
     * Requirements:
     * - only owner can update value.
    */

    function whiteListAddresses(address[] calldata _addresses) external onlyOwner returns(bool){
        for(uint i = 0; i < _addresses.length; i++){
          whiteListAddress[_addresses[i]] = true;
        }
        return true;
    }

    /**
     * @dev creates new node w.r.t their Tier.
     *
     * @param order order struct details.
     * @param signature signature to validate the user.
     *  
     * Requirements:
     * - must have nodePrice Emerald token in users wallet.
     * 
     * Returns
     * - boolean.
     *
     * Emits a {nodeCreated} event.
    */

    function buyNode(Order memory order, bytes memory signature) payable isBlacklistedAddress external returns(bool){
        uint256 _tier;
        uint256 nodeId;
        require(owner() == ECDSAUpgradeable.recover(order.key, signature), "EmeraldNodeV1: ERROR");
        require(referenceDetails[msg.sender][order.ReferenceId] == false, "EmeraldNodeV1: ReferenceId is already used");

        if(whiteListAddress[msg.sender] && addressCount[msg.sender] < count && nodeCounter <= nodeIds[1]){
            _tier = 1;
            addressCount[msg.sender] += 1;
            nodeId = nodeCounter;
            nodeCounter += 1;
        }else{
            for(uint256 i = 0; i < 5; i++){
                if(nodeIds[i] < RegularNodeCounter && nodeIds[i+1] >= RegularNodeCounter){
                    _tier = i+1;
                    nodeId = RegularNodeCounter;
                    RegularNodeCounter += 1;
                    break;
                }
                if(nodeIds[5] < RegularNodeCounter){
                    _tier = 6;
                    nodeId = RegularNodeCounter;
                    RegularNodeCounter += 1;
                    break;
                }
            }
            
        }

        require(updatedTierDetails[_tier].rewardRate != 0 && updatedTierDetails[_tier].tierEMnodePrice <= EmeraldCoin.balanceOf(msg.sender) && updatedTierDetails[_tier].tierAVAXnodePrice == msg.value, "EmeraldERC20V1: Invalid price or Insufficient balance");

        EmeraldCoin.safeTransfer(msg.sender, communityAddress, updatedTierDetails[_tier].tierEMnodePrice);
        payable(communityAddress).transfer(msg.value);

        Node storage data = nodeDetails[nodeId];
        data.nodeId = nodeId;
        data.tireId = _tier;
        data.nodeOwner = msg.sender;
        data.nodeCreatedTimestamp = block.timestamp;
        data.lastClaimTimestamp = block.timestamp;

        ownerNodes[msg.sender].push(nodeId);

        emit nodeCreated(nodeId, _tier, order.ReferenceId, msg.sender, order.NodeName,  updatedTierDetails[_tier].tierEMnodePrice, msg.value );

        referenceDetails[msg.sender][order.ReferenceId] = true;

        return true;
    }

    /**
     * @dev User can view its total rewards details.
     *
     * @param _address user address
     *  
     * Requirements:
     * - user must own atleast one node.
     * 
     * Returns
     * - boolean.
    */

    function viewTotalReward(address _address) public view returns(uint256 RewardToBeClaimed, uint256 RewardAlreadyClaimed, uint256 TotalUserReward){
        for(uint256 i = 0; i < ownerNodes[_address].length; i++){
            (   uint256 tierId,
                uint256 rewardToBeClaimed, 
                uint256 rewardAlreadyClaimed,
                uint256 totalNodeReward
            ) = node(ownerNodes[_address][i]);

            RewardToBeClaimed += rewardToBeClaimed;
            RewardAlreadyClaimed += rewardAlreadyClaimed;
        }
        TotalUserReward = RewardAlreadyClaimed + RewardToBeClaimed;
    }

    /**
     * @dev User can view details of perticular node.
     *
     * @param _nodeId node Id.
     *  
     * Requirements:
     * - user must own atleast one node.
     * 
     * Returns
     * - boolean.
    */

    function viewNodeDetails(uint256 _nodeId) public view returns(
        uint256 NodeId, 
        uint256 TierId, 
        address NodeOwnerAddress, 
        uint256 NodeCreatedAt, 
        uint256 LastClaimTime, 
        uint256 RewardToBeClaimed, 
        uint256 RewardAlreadyClaimed,
        uint256 TotalNodeReward,
        uint256 Number){

        uint256 tierId = nodeDetails[_nodeId].tireId;

        NodeId = _nodeId;
        TierId = tierId;
        NodeOwnerAddress = nodeDetails[_nodeId].nodeOwner;
        NodeCreatedAt = nodeDetails[_nodeId].nodeCreatedTimestamp;
        LastClaimTime = nodeDetails[_nodeId].lastClaimTimestamp;

        uint256 number =  uint256(block.timestamp - LastClaimTime) / updatedTierDetails[tierId].intervalTimestamp;
        uint256 rewardAmt = uint256(updatedTierDetails[tierId].rewardRate * number);

        if(rewardAmt == 0){
            RewardToBeClaimed = 0;
        }else{
            RewardToBeClaimed = rewardAmt;
        }

        RewardAlreadyClaimed = nodeDetails[_nodeId].totalReward;
        TotalNodeReward = RewardToBeClaimed + RewardAlreadyClaimed;
        Number += number;
    }

    /**
     * @dev User can claim their rewards w.r.t their owned nodes.
     *  
     * Requirements:
     * - user must own atleast one node.
     * 
     * Returns
     * - boolean.
     *
     * Emits a {rewardClaimed} event.
    */

    function claimRewards() isBlacklistedAddress external returns(bool){
        require(ownerNodes[msg.sender].length != 0, "EmeraldERC20V1: You do not owned any node");
        
        uint256 totalReward = 0;
        for(uint256 i = 0; i < ownerNodes[msg.sender].length; i++){
            ( uint256 NodeId, 
            uint256 TierId, 
            address NodeOwnerAddress, 
            uint256 NodeCreatedAt, 
            uint256 LastClaimTime, 
            uint256 RewardToBeClaimed, 
            uint256 RewardAlreadyClaimed,
            uint256 TotalNodeReward,
            uint256 Number
            ) = viewNodeDetails(ownerNodes[msg.sender][i]);

            totalReward += RewardToBeClaimed;

            Node storage data = nodeDetails[NodeId];
            data.lastClaimTimestamp += ( updatedTierDetails[TierId].intervalTimestamp * Number);
            data.totalReward += RewardToBeClaimed;

        }

        require(totalReward != 0, "EmeraldNodeV1: Zero reward cannot be claimed");

        EmeraldCoin.safeTransfer(owner(), msg.sender, totalReward);

        emit rewardClaimed(msg.sender, totalReward);

        return true;
    }

    /**
     * @dev private function to calculate rewards of given node Id.
     *
     * @param _node nodeId
     *  
     * Requirements:
     * - user must own atleast one node.
     * 
     * Returns
     * - boolean.
    */

    function node(uint256 _node) private view returns(  
        uint256 tierId,
        uint256 rewardToBeClaimed, 
        uint256 rewardAlreadyClaimed,
        uint256 totalNodeReward
    ){
             ( uint256 NodeId, 
                uint256 TierId, 
                address NodeOwnerAddress, 
                uint256 NodeCreatedAt, 
                uint256 LastClaimTime, 
                uint256 RewardToBeClaimed, 
                uint256 RewardAlreadyClaimed,
                uint256 TotalNodeReward,
                uint256 Number
            ) = viewNodeDetails(_node);

            tierId = TierId;
            rewardToBeClaimed = RewardToBeClaimed;
            rewardAlreadyClaimed = RewardAlreadyClaimed;
            totalNodeReward = TotalNodeReward;
    }

    /**
     * @dev User can view all node details.
     *
     * @param _user user address
     *  
     * Requirements:
     * - user must own atleast one node.
     * 
     * Returns
     * - boolean.
    */

    function viewAllDetails(address _user) public view returns(
        address NodeOwnerAddress,
        uint256[] memory NodeIds, 
        uint256[] memory TierIds,
        uint256[] memory RewardToBeClaimeds, 
        uint256[] memory RewardAlreadyClaimeds,
        uint256[] memory TotalNodeRewards
    ){
            NodeOwnerAddress = _user;
            uint256 number = ownerNodes[_user].length;

            NodeIds = new uint256[](number);
            TierIds = new uint256[](number);
            RewardToBeClaimeds = new uint256[](number);
            RewardAlreadyClaimeds = new uint256[](number);
            TotalNodeRewards = new uint256[](number);

            for(uint256 i = 0; i < number; i++){
                uint256 _node = ownerNodes[_user][i];
                (uint256 tierId,
                 uint256 rewardToBeClaimed, 
                 uint256 rewardAlreadyClaimed,
                 uint256 totalNodeReward) = node(_node);

                NodeIds[i] = _node;
                TierIds[i] = tierId;
                RewardToBeClaimeds[i] = rewardToBeClaimed;
                RewardAlreadyClaimeds[i] = rewardAlreadyClaimed;
                TotalNodeRewards[i] = totalNodeReward;
            }
    }

    /**
     * @dev blacklist the address.
     *
     * @param _address address to be blacklist.
     * @param _status boolean status.
     *
     * Requirements:
     * - msg.sender must be owner of contract.
     *
     * Returns
     * - boolean.
     */

    function blacklistAddress(address _address, bool _status)
        external
        onlyOwner
        returns (bool)
    {
        require(blacklistAddresses[_address] != _status, "EmeraldNodeV1: Status is already updated");
        blacklistAddresses[_address] = _status;
        return _status;
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20{
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

    function safeTransfer(address from, address to, uint256 amount) external returns(bool);

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

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";

contract EmeraldNodeStorageV2 is Initializable, OwnableUpgradeable{

    // node counter for Tier X
    uint256 public nodeCounter;

    // node counter for Tier 1 to 5
    uint256 public RegularNodeCounter;

    // ERC20 contract address of new Emerald token
    IERC20 EmeraldCoin;

    // range of tier Ids
    uint256[] nodeIds;

    // node count on Tier X
    uint256 count;

    // order struct for creating node
    struct Order{
        string ReferenceId;
        string NodeName;
        bytes32 key;
    }
    
    // node struct for storing node details
    struct Node{
        uint256 nodeId;
        uint256 tireId;
        address nodeOwner;
        uint256 nodeCreatedTimestamp;
        uint256 lastClaimTimestamp;
        uint256 rewardAmount;
        uint256 totalReward;
    }

    // mapping of node struct with its ID
    mapping(uint256 => Node) public nodeDetails;

    // Tier struct for storing tier details
    struct Tier{
        uint nodeTier;
        uint256 rewardRate;
        uint256 tierNodePrice;
        uint256 intervalTimestamp;
    }

    // mapping tier details with its ID
    mapping(uint256 => Tier) private tierDetails;

    // mapping of address and their owned nodes
    mapping(address => uint256[]) public ownerNodes;

    // mapping for no reduplication of reference Id
    mapping(address => mapping(string => bool)) public referenceDetails;

    // mapping for whiteListAddress
    mapping(address => bool) public whiteListAddress;

    // mapping for whitelist address with node count on tier X
    mapping(address => uint256) public addressCount; 

    // Community Address
    address internal communityAddress;

    //mapping of blacklist address
    mapping(address => bool) public blacklistAddresses;

    struct UpdatedTier{
        uint nodeTier;
        uint256 rewardRate;
        uint256 tierEMnodePrice;
        uint256 tierAVAXnodePrice;
        uint256 intervalTimestamp;
    }

    // mapping tier details with its ID
    mapping(uint256 => UpdatedTier) public updatedTierDetails;
    
    // Events

    /**
     * @dev Emitted when new node created.
    */
    event nodeCreated(uint256 nodeId, uint256 tierId, string referenceId, address nodeOwner, string nodeName, uint256 nodeEMprice, uint256 AVAXprice);

    /**
     * @dev Emitted when reward is claimed by user.
    */
    event rewardClaimed(address nodeOwner, uint256 rewardAmount);


}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../StringsUpgradeable.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSAUpgradeable {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", StringsUpgradeable.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
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
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

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

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}