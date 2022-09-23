#!/bin/bash

# [filepath]: solidityVersion
declare -A mapFileSolVersion

# Extract the correct version from every *.sol file and put it in mapFileSolVersion array
find ./ -name '*.sol' -print0 | while IFS= read -r -d '' file
do
  pragmas=$(grep "pragma" $file)
  
  versions=$(echo $pragmas | grep -Eo '[0-9]\.[0-9]+')
  echo $file contains $versions
done

# Run sol-select and slither for each file
for i in "${!array[@]}"
do
echo i 
echo "${array[$i]}"
  solc-select install "${array[$i]}"
  solc-select use "${array[$i]}"
  slither "$i" --json /tmp/json
done
