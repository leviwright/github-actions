#! /bin/bash

development=development
test=test
staging=staging
production=production

envs=( $development $test $staging $production )
targetEnv=$1
userToken=$2

echo $targetEnv
echo $userToken
echo ${github.actor}
echo ${github}

if [ $# -ne 2 ] || [[ ! " ${envs[*]} " =~ " ${targetEnv} " ]]
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

git checkout -b promote-polar-dev-to-test
echo "Some Text" > "./policies/environments/test.polar"
git config user.email ${github.actor}
git status
git add -A
git commit -m "making a new branch"
git push origin promote-polar-dev-to-test


echo "TOTALLY RAN THE SCRIPT! WOOP WOOP!"
echo $input