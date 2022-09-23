/**
 *Submitted for verification at snowtrace.io on 2022-06-15
*/

//
// .MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM.
// MMMMMMMMMMMMMMMWNKOdolc:::cclodk0NWMMMMMMMMMMMMMMM
// MMMMMMMMMMMMNOd:'....,;;::;;,....':oONMMMMMMMMMMMM
// MMMMMMMMMW0o,..,cdOKNWWWMMWWWNKOxc,..'l0WMMMMMMMMM
// MMMMMMMWOc..,o0NMMMMMMMMMMMMMMMMMMN0d,..:OWMMMMMMM
// MMMMMMKl. ;kNMMMMMMMMMMMMMMMMMMMMMMMMNk;..cKWMMMMM
// MMMMWO, .dNMMMMMMMMMMMMMNXNMMMMMMMMMMMMNx' 'kWMMMM
// MMMWO' ,0WMMMMMMMMMMMMXx;.,dXMMMMMMMMMMMMK; .kWMMM
// MMM0, ,0MMMMMMMMMMMMXx, ... 'dXMMMMMMMMMMMK; 'OMMM
// MMNl .xWMMMMMMMMMMXd' .l0X0l. 'dXMMMMMMMMMMO. :XMM
// MM0' :XMMMXdlkNMXd' .l0WMMMWKl. 'dXMNxcxNMMNc .OMM
// MMk. oWMMMKc..:l' .lKWWKdokNMWKl. 'c, .oNMMWd..dMM
// MMx. dWMMMMNo.   ;0WWKl.   ;kNMWO,   .xWMMMMx. dWM
// MMO. lNMMWXd' .. .oko. 'lo:..;xk:..'. 'dXMMWo .xMM
// MMK; ,0MXd' .oKXd.   .dXMMWO:   .;kNKl. 'dXK; ,0MM
// MMWx. :l' .oKWMMMKl. .xNMMWKc. ,kNMMMWKl. ',..oWMM
// MMMNl   .oKWMMMMMMW0c..;dkl. 'xNMMMMMMMWKc.  :XMMM
// MMMMXc  :XMMMMMMMMMMWO:.   .dXMMMMMMMMMMNo. :KMMMM
// MMMMMNo. ,kNMMMMMMMMMMX:  .kWMMMMMMMMMWO; .lXMMMMM
// MMMMMMW0:..;kXMMMMMMMMNc  .OMMMMMMMMNk:..;OWMMMMMM
// MMMMMMMMNO:..'ckKNMMMMNc  .OMMMMWKkl'..:kNMMMMMMMM
// MMMMMMMMMMWKd:...,:odkk,  .okxoc,...;o0WMMMMMMMMMM
// MMMMMMMMMMMMMWXkoc,.....   ....,:okKWMMMMMMMMMMMMM
// 'MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM'
//
//                    AVVY DOMAINS
//

// Sources flattened with hardhat v2.8.3 https://hardhat.org

// File contracts/PoseidonInterface.sol


pragma solidity ^0.8.0;

interface PoseidonInterface {
  function poseidon(bytes32[3] memory input) external pure returns(bytes32);
  function poseidon(uint256[3] memory input) external pure returns(uint256);
}


// File contracts/RainbowTableInterface.sol


pragma solidity ^0.8.0;

interface RainbowTableInterface {
  function reveal(uint256[] memory preimage, uint256 hash) external;
  function lookup(uint256 hash) external returns (uint256[] memory preimage);
  function getHash(uint256 hash, uint256[] calldata preimage) external view returns (uint256);
  function isRevealed(uint256 hash) external view returns (bool);
}


// File contracts/ContractRegistryInterface.sol


pragma solidity ^0.8.0;

interface ContractRegistryInterface {
  function get(string memory contractName) external view returns (address);
}


// File contracts/RainbowTableV1.sol


pragma solidity ^0.8.0;



/** The rainbow table stores mappings from hash to preimage for "revealed" domains. */
/** Once a name is revealed, it cannot be hidden again. */
contract RainbowTableV1 is RainbowTableInterface { 
  event Revealed(uint256 indexed hash);
  ContractRegistryInterface public immutable contractRegistry;
  mapping(uint256 => uint256[]) entries;
  
  function reveal(uint256[] calldata preimage, uint256 hash) external override {
    uint256 actual = getHash(0, preimage);
    require(actual == hash, "RainbowTableV1: does not match");
    require(entries[hash].length == 0, "RainbowTableV1: hash already revealed");
    entries[hash] = preimage;
    emit Revealed(hash);
  }

  // computes the hash for a set of labels. each label is represented by two
  // indices in the preimage[] array.
  function getHash(uint256 hash, uint256[] calldata preimage) override public view returns (uint256) {
    PoseidonInterface pos = PoseidonInterface(contractRegistry.get('Poseidon'));
    require(preimage.length % 2 == 0, "RainbowTableV1: preimage length must be divisible by 2");
    require(preimage.length > 0, "RainbowTableV1: preimage length must be greater than 0");
    for (uint256 i = 0; i < preimage.length; i += 1) {
      if (i % 2 == 0) {
        hash = pos.poseidon([hash, preimage[i], preimage[i+1]]);
      }
    }
    return hash;
  }

  function lookup(uint256 hash) external override view returns (uint256[] memory preimage) {
    require(entries[hash].length > 0, "RainbowTableV1: entry not found");
    return entries[hash];
  }

  function isRevealed(uint256 hash) external override view returns (bool) {
    return entries[hash].length > 0;
  }

  constructor(address contractRegistryAddress) {
    contractRegistry = ContractRegistryInterface(contractRegistryAddress);
  }
}