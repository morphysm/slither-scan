#!/bin/bash

function findpragma () {
    solcOutput=$(solc "$1" 2>&1)
    pragma="$(echo "$solcOutput" | grep pragma)"
    version=$(echo "$pragma" | grep -Eo '[0-9]\.[0-9].[0-9]+')
    echo "$version"
}

# Extract the correct version from every *.sol file and put it in mapFileSolVersion array
find ./ -name '*.sol' -print0 | while IFS= read -r -d '' file
do
    versionWanted=$(findpragma $file)
    echo $greeting

    if [ ! -z "$versionWanted" ]
    then
        solc-select install $versionWanted
        solc-select use $versionWanted
    fi

    slither $file

done
