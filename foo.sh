#!/bin/bash

function findpragma () {
    solcOutput=$(solc "$1" 2>&1)
    pragma="$(echo "$solcOutput" | grep pragma)"
    version=$(echo "$pragma" | grep -Eo '[0-9]\.[0-9].[0-9]+')
    echo "$version"
}

versionWanted=$(findpragma "./0aec2d7bb31d3c4271b1753da1e1b255464bf577_MasterChef.sol")
echo $greeting

if [ ! -z "$versionWanted" ]
then
    solc-select install 0.6.2
    solc-select use 0.6.2
fi

slither "./0aec2d7bb31d3c4271b1753da1e1b255464bf577_MasterChef.sol"