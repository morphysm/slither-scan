#!/bin/bash

find ./ -mtime -7 -name '*.sol' -print0 | while IFS= read -r -d '' file
do
  echo "$file"
done

