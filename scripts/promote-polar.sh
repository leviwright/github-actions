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

#content=github-actions/policies/environments/development.polar



input="/policies/environments/development.polar"
while IFS= read -r line
do
  echo "$line"
done < "$input"

echo "TOTALLY RAN THE SCRIPT! WOOP WOOP!"
echo $input