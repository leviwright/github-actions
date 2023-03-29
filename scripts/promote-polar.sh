#! /bin/bash

development=development
test=test
staging=staging
production=production
commentTrigger="#"

envs=( $development $test $staging $production )
targetEnv=$1
actor=$2


if [ $# -ne 2 ] || [[ ! " ${envs[*]} " =~ " ${targetEnv} " ]]
then
echo "Invalid invocation - must provide a target environment with any of the following values: 'development', 'test', 'staging' or 'production' and the github actor"
exit 1
fi

sourceEnv=''
if [[ "${targetEnv}" == $test ]]
then
  sourceEnv=$development
elif [[ "${targetEnv}" == $staging ]]; 
then
  sourceEnv=$test 
elif [[ "${targetEnv}" == $production ]];
then 
  sourceEnv=$staging 
fi

echo "Attempting run to promote to:" $targetEnv
echo "Run triggered by github user:" $actor

echo "Ensure we are starting with the latest changes on the main branch..."
git checkout main 
git pull origin main

echo "Creating new branch before enacting changes..."
branchName="promote-polar-${sourceEnv}-to-${targetEnv}"

git checkout -b $branchName
 
targetFile="./policies/environments/${targetEnv}.polar"
sourceFile="./policies/environments/${sourceEnv}.polar"

echo "Copying file contents from ${sourceEnv} polar file to the ${targetEnv} polar file..."
cp $sourceFile $targetFile
echo "Done!"

echo "Configuring temporary git credentials on linux box to match trigger user"
git config user.name "$(git log -n 1 --pretty=format:%an)" #username from last commit - should always be user triggering the workflow.
git config user.email "$(git log -n 1 --pretty=format:%ae)" #email from last commit - should always be user triggering the workflow. 

echo "Adding and committing changes to new branch..."
git add -A

priorCommitMessage=$(git whatchanged -n 1 --format=%b -- policies/environments/${sourceEnv}.polar)
formattedPriorCommitMessage=${priorCommitMessage%$'\n'*}

git commit -m "${formattedPriorCommitMessage}" 

echo "Pushing changes to remote..."
git push origin $branchName 

echo "Creating pull request..."
if ! gh pr create --title "${actor}: Promoting ${sourceEnv} polar file contents to the ${targetEnv} polar file." --body "${formattedPriorCommitMessage}"
  then
    echo "Failure: There was an issue creating a pull request." 
  exit 1
fi

echo "Success!"