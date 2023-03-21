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

#content=$(curl -L https://raw.githubusercontent.com/LumioHX/lumio-oso/main/policies/environments/development.polar?token=GHSAT0AAAAAABYFPQFLVV5FFQ4TARUPFMTCZAY5GYQ) 




LINE=1

#while read -r CURRENT_LINE
  #do
    #echo "$LINE: $CURRENT_LINE"
    #((LINE++))
#done < $content

echo "TOTALLY RAN THE SCRIPT! WOOP WOOP!"