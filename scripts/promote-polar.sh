#! /bin/bash

development=development
test=test
staging=staging
production=production

envs=( $development $test $staging $production )
targetEnv=$1
userToken=$2
actor=$3

echo $targetEnv
echo $userToken
echo $actor

if [ $# -ne 3 ] || [[ ! " ${envs[*]} " =~ " ${targetEnv} " ]]
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

git branch
git checkout main
git pull origin main
git checkout -b promote-polar-dev-to-test
echo "Some Text" > "./policies/environments/test.polar"
git config user.name $actor
git config user.email "levi.wright@lumio.com"
git status
git add -A
git status
git commit -m "making a new branch"
git status
git push origin promote-polar-dev-to-test
git request-pull v1.0 origin main


echo "TOTALLY RAN THE SCRIPT! WOOP WOOP!"
echo $input