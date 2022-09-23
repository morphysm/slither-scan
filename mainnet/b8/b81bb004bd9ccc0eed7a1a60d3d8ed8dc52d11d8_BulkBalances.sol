/**
 *Submitted for verification at snowtrace.io on 2022-04-05
*/

// SPDX-License-Identifier: LGPL-3.0-or-later
pragma abicoder v2;
pragma solidity ^0.8.9;

contract BulkBalances {
    struct TokenBalance {
        address token_address;
        address holder_address;
        uint balance;
    }
    
    struct EthBalance {
        address holder_address;
        uint balance;
    }

  function tokenBalancesManyTokensManyHolders(address[] calldata holders,  address[] calldata tokens) external view returns (TokenBalance[] memory balances) {
    balances = new TokenBalance[](holders.length);
    
    for(uint i = 0; i < holders.length; i++) {
      if(isAContract(tokens[i])) { 
        (uint _balance) = getTokenBalance(tokens[i], holders[i]); 
        balances[i] = TokenBalance(tokens[i], holders[i], _balance); 
      } else {
        balances[i] = TokenBalance(tokens[i], holders[i], 0);   
      }
    }
    return balances;
  }
  
  function ethBalances(address[] calldata holders) external view returns (EthBalance[] memory balances) {
    balances = new EthBalance[](holders.length);
    
    for(uint i = 0; i < holders.length; i++) {
        balances[i] = EthBalance(holders[i], address(holders[i]).balance); 
    }
    return balances;
  }
  
    function getTokenBalance(address token, address holder) internal view returns (uint) {
        try ERC20(token).balanceOf(holder) returns (uint balance) {
            return (balance);
        } catch Error(string memory /*reason*/) {
            return (0);
        } catch (bytes memory /*lowLevelData*/) {
            return (0);
        }
    }

  // check if contract (token, exchange) is actually a smart contract and not a 'regular' address
  function isAContract(address contractAddr) internal view returns (bool) {
    uint256 codeSize;
    assembly { codeSize := extcodesize(contractAddr) } // contract code size
    return codeSize > 0; 
    // Might not be 100% foolproof, but reliable enough for an early return in 'view' functions 
  }
}

interface ERC20 {
    function balanceOf(address _owner) external view returns (uint balance);
}