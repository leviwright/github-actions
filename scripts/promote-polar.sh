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

echo "Ensure we are starting with the latest changes on the main branch..."
git checkout main 
git pull origin main

echo "Creating new branch before enacting changes..."
uuid=$(uuidgen)
uuid=${uuid^^}
branchName="promote-polar-${sourceEnv}-to-${targetEnv}-${uuid}"

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


targetFile="./policies/environments/${targetEnv}.polar"
sourceFile="./policies/environments/${sourceEnv}.polar"

#==================================================================
# Important -- uncomment and swap the line below if running locally on mac OS for debugging purposes, 
# the '' following the -i flag is required for Mac users because Mac OS uses the BSD version of sed that
# works slightly different than the Linux version. Linux uses the GNU version which will behave differently 
# with the -i flag.
#===================================================================
#sed -i '' "${lineToStart},\$d" $targetFile
sed -i "${lineToStart},\$d" $targetFile 

#ensure that we have an empty line at the end of our source file. If not, bash cannot read all the way through our contents.
sed -i -e '$a\' $sourceFile


echo "Populating contents from the ${sourceEnv} file located at ${sourceFile} to the ${targetEnv} file located at ${targetFile}. Preserving all comments."
isPastCommentSection=false
declarationBodyLineCounter=0



while IFS= read -r line
do
  if [[ "$line" != *"$commentTrigger"* ]] &&  [[ ! -z "$line" ]]
  then 
    isPastCommentSection=true
  fi

  if $isPastCommentSection
  then 
    inputLength=${#line}
    firstCharacter={$line:0:1}

     if [[ "$line" == *"{"* ]]
      then
       isInsideDeclarationBody=true
     fi

     if [[ $inputLength == 1 && "$line" == "}" ]]
      then
        isInsideDeclarationBody=false
        declarationBodyLineCounter=0
     fi  
 
     if [[ $inputLength -gt 1 && $isInsideDeclarationBody && $declarationBodyLineCounter -gt 0 ]]
      then 
        echo "  ${line}" >> $targetFile
      else
        echo $line >> $targetFile
     fi
  if $isInsideDeclarationBody
    then
     ((declarationBodyLineCounter++))
  fi
  fi
done < "$sourceFile"


echo "Configuring temporary git credentials on linux box to match trigger user"
git config user.name "$(git log -n 1 --pretty=format:%an)" #username from last commit - should always be user triggering the workflow.
git config user.email "$(git log -n 1 --pretty=format:%ae)" #email from last commit - should always be user triggering the workflow. 

echo "Adding and committing changes to new branch..."
git status
git add -A
git status

priorCommitMessage=$(git whatchanged -n 1 --format=%b -- policies/environments/development.polar)
echo $priorCommitMessage

git commit -m "Promoting changes from ${sourceEnv} to ${targetEnv}. Here is the prior commit and associated message: ${priorCommitMessage}" 
git commit -m "Promoting changes from ${sourceEnv} to ${targetEnv}. Here is the prior commit and associated message: ${priorCommitMessage}"
git status
echo "Pushing changes to remote..."
git push origin $branchName 
echo "Creating pull request..."
newLine=$'\n'
gh pr create --title "${actor}: Promoting ${sourceEnv} polar file contents to the ${targetEnv} polar file" --body "@${actor} is promoting ${sourceEnv} polar file contents to the ${targetEnv} polar file. These changes stem from a prior commit. ${newLine} ${newLine} prior commit message and associated info: ${newLine} ${newLine} ${priorCommitMessage}"

echo "Success!"