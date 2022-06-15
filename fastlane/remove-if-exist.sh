#!/bin/bash                                                                 

file=$1
if [ -e "$file" ] # check if file exists
then
  rm -rf "$file" # remove file
  base=$(basename "$file")
  rm -rf "info/$base.trashinfo" # remove second file in info/<file>.trashinfo

  echo 'files deleted!'
fi