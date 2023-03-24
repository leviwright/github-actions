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
echo "Installing github cli in order to provide easy hook for creating a pull request..."
type -p curl >/dev/null || (sudo apt update && sudo apt install curl -y)
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
&& sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
&& echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
&& sudo apt update \
&& sudo apt install gh -y

echo "Ensure we are start with the latest changes on the main branch..."
git checkout main 
git pull origin main

echo "Creating new branch before enacting changes..."
branchName="promote-polar-${sourceEnv}-to-${targetEnv}"

git checkout -b $branchName
 
sourceFile="./policies/environments/${targetEnv}.polar" 

echo "Clearing out contents of ${targetEnv} from location ${sourceFile}"
isPastCommentSection=false
lineToStart=1
previousLineValue=''
while IFS= read -r line
do
    if [[ "$line" != *"$commentTrigger"* ]] &&  [[ ! -z "$line" ]]
    then
      isPastCommentSection=true
      break
    else
      ((lineToStart++))
    fi
  previousLineValue=$line
done < "$sourceFile"

#==================================================================
# Important -- uncomment and swap the line below if running locally on mac OS for debugging purposes, 
# the '' following the -i flag is required for Mac users because Mac OS uses the BSD version of sed that
# works slightly different than the Linux version. Linux uses the GNU version which will behave differently 
# with the -i flag.
#===================================================================
#sed -i '' "${lineToStart},\$d" $targetFile
sed -i "${lineToStart},\$d" $sourceFile

sourceFile="./policies/environments/${sourceEnv}.polar" 
targetFile="./policies/environments/${targetEnv}.polar"

echo "Populating contents from the ${sourceEnv} file located at ${sourceFile} to the ${targetEnv} file located at ${targetFile}. Preserving all comments."
isPastCommentSection=false
while IFS= read -r line
do
   if [[ "$line" != *"$commentTrigger"* ]] &&  [[ ! -z "$line" ]]
  then 
    isPastCommentSection=true
  fi
  if [ $isPastCommentSection = true ]
  then 
    echo $line >> $targetFile
  fi
done < "$sourceFile"

echo "Configuring temporary git credentials on linux box to match trigger user"
git config user.name "$(git log -n 1 --pretty=format:%an)" #username from last commit - should always be user triggering the workflow.
git config user.email "$(git log -n 1 --pretty=format:%ae)" #email from last commit - should always be user triggering the workflow. 

echo "Adding and committing changes to new branch..."
git status
git add -A
git status
if ! git commit -m "Promoting changes from ${sourceEnv} to ${targetEnv}..." 
  then
    echo "Failure: There was an issue making a commit on the branch."
    exit 1
fi

git status

echo "Pushing changes to remote..."
if ! git push origin $branchName 
  then
    echo "Failure: There was an issue pushing changes to remote." 
  exit 1
fi

echo "Creating pull request..."
if ! gh pr create --title "${actor}: Promoting ${sourceEnv} polar file contents to the ${targetEnv} polar file" --body "@${actor} is promoting ${sourceEnv} polar file contents to ${targetEnv} polar file."
  then
    echo "Failure: There was an issue creating a pull request." 
  exit 1
fi

echo "Success!"