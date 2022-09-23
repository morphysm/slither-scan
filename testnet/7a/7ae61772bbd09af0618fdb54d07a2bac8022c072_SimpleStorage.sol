/**
 *Submitted for verification at testnet.snowtrace.io on 2022-05-25
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6;

contract SimpleStorage {
    
    // this will get initialized to 0
    uint256 favoriteNumber;
    bool FavoriteBool;

    struct People {
        uint256 favoriteNumber;
        string name;
    }

    People[] public people;
    mapping(string => uint256) public nameToFavoriteNumber;

    function store(uint256 _favoriteNumber) public {
        favoriteNumber = _favoriteNumber;
    }

    function retrieve() public view returns(uint256) {
        return favoriteNumber;
    }

    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        people.push(People(_favoriteNumber, _name));
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }

}