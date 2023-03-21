#! /bin/bash

development=development
test=test
staging=staging
production=production

envs=( $development $test $staging $production )
targetEnv=$1


if [ $# -ne 1 ] || [[ ! " ${envs[*]} " =~ " ${targetEnv} " ]]
then
echo "Invalid argument - must provide only one argument with any of the following values: 'development', 'test', 'staging' or 'production'"
exit 1
fi


input="./policies/environments/development.polar" #do some interpolation here for input
index=1
while IFS= read -r line
do
  echo "$line"
  if [ $index == 1 ]
  then
  echo "this line should not make it"
  echo $index
  ((index++))
  fi




done < "$input"

echo "TOTALLY RAN THE SCRIPT! WOOP WOOP!"
echo $input