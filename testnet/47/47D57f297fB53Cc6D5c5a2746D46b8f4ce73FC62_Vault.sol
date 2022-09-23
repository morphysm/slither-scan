//SPDX-License-Identifier: Unlicense
pragma solidity ^0.4.25;

import "./interfaces/IToken.sol";
import "./Whitelist.sol";

contract Vault is Whitelist{

  IToken internal token; // address of the BEP20 token traded on this contract

  //We receive Drip token on this vault
  constructor(address token_addr) public{
      token = IToken(token_addr);
  }

  function withdraw(uint256 _amount) public onlyWhitelisted {
      require(token.transfer(msg.sender, _amount));
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity >=0.4.25;

interface IToken {
  function remainingMintableSupply() external view returns (uint256);

  function calculateTransferTaxes(address _from, uint256 _value) external view returns (uint256 adjustedValue, uint256 taxAmount);

  function transferFrom(
      address from,
      address to,
      uint256 value
  ) external returns (bool);

  function transfer(address to, uint256 value) external returns (bool);

  function balanceOf(address who) external view returns (uint256);

  function mintedSupply() external returns (uint256);

  function allowance(address owner, address spender)
  external
  view
  returns (uint256);

  function approve(address spender, uint256 value) external returns (bool);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.4.25;

import "./Ownable.sol";

contract Whitelist is Ownable {
  mapping(address => bool) public whitelist;

  event WhitelistedAddressAdded(address addr);
  event WhitelistedAddressRemoved(address addr);

  /**
   * @dev Throws if called by any account that's not whitelisted.
   */
  modifier onlyWhitelisted() {
      require(whitelist[msg.sender], 'not whitelisted');
      _;
  }

  /**
   * @dev add an address to the whitelist
   * @param addr address
   * @return true if the address was added to the whitelist, false if the address was already in the whitelist
   */
  function addAddressToWhitelist(address addr) onlyOwner public returns(bool success) {
      if (!whitelist[addr]) {
          whitelist[addr] = true;
          emit WhitelistedAddressAdded(addr);
          success = true;
      }
  }

  /**
   * @dev add addresses to the whitelist
   * @param addrs addresses
   * @return true if at least one address was added to the whitelist,
   * false if all addresses were already in the whitelist
   */
  function addAddressesToWhitelist(address[] memory addrs) onlyOwner public returns(bool success) {
      for (uint256 i = 0; i < addrs.length; i++) {
          if (addAddressToWhitelist(addrs[i])) {
              success = true;
          }
      }
  }

  /**
   * @dev remove an address from the whitelist
   * @param addr address
   * @return true if the address was removed from the whitelist,
   * false if the address wasn't in the whitelist in the first place
   */
  function removeAddressFromWhitelist(address addr) onlyOwner public returns(bool success) {
      if (whitelist[addr]) {
          whitelist[addr] = false;
          emit WhitelistedAddressRemoved(addr);
          success = true;
      }
  }

  /**
   * @dev remove addresses from the whitelist
   * @param addrs addresses
   * @return true if at least one address was removed from the whitelist,
   * false if all addresses weren't in the whitelist in the first place
   */
  function removeAddressesFromWhitelist(address[] memory addrs) onlyOwner public returns(bool success) {
      for (uint256 i = 0; i < addrs.length; i++) {
          if (removeAddressFromWhitelist(addrs[i])) {
              success = true;
          }
      }
  }

}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.4.25;

contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
      owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
      require(msg.sender == owner, 'only owner');
      _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
      require(newOwner != address(0));
      emit OwnershipTransferred(owner, newOwner);
      owner = newOwner;
  }

}