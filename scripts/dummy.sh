#! /bin/bash

sed -i '' -e '$a\' dummy.polar


while IFS= read -r line
do
  echo $line
done < dummy.polar