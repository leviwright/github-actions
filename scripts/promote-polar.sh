#! /bin/bash

development=development
test=test
staging=staging
production=production
endCommentTrigger="# -- End Comment Section --"

envs=( $development $test $staging $production )
targetEnv=$1
actor=$2


if [ $# -ne 2 ] || [[ ! " ${envs[*]} " =~ " ${targetEnv} " ]]
then
echo "Invalid invocation - must provide a target environemnt with any of the following values: 'development', 'test', 'staging' or 'production' and the github actor"
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



echo '=========' $targetEnv
echo '=========' $sourceEnv

echo "Attempting run to promote to:" $targetEnv
echo "Run triggered by:" $actor

# echo "Installing homebrew to obtain needed packages..."
# /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
#  (echo; echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"') >> /home/runner/.bash_profile
#     eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

# echo "Installing github cli tool to enable easy pull request creation..."
# brew install gh

type -p curl >/dev/null || (sudo apt update && sudo apt install curl -y)
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
&& sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
&& echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
&& sudo apt update \
&& sudo apt install gh -y


echo "Ensure we are start with the latest changes on the master branch..."
git checkout main 
git pull origin main
echo "Creating new branch before enacting changes..."
branchName="promote-polar-${sourceEnv}-to-${targetEnv}"
echo $branchName 'THIS IS THE BRANCH NAME'
git checkout -b $branchName



targetFile="./policies/environments/${targetEnv}.polar"
echo $targetFile "THIS IS THE TARGET FILE"
lineToStart="`grep -n '# -- End Comment Section --' $targetFile | cut -d: -f 1`"
((lineToStart++))

#==================================================================
# Important -- uncomment and swap the line below if running locally on mac OS for debugging purposes, 
# the '' following the -i flag is required for Mac users because Mac OS uses the BSD version of sed that
# works slightly different than the Linux version. Linux uses the GNU version which will behave differently 
# with the -i flag.
#===================================================================

#sed -i '' "${lineToStart},\$d" $targetFile
sed -i "${lineToStart},\$d" $targetFile


sourceFile="./policies/environments/development.polar" #do some interpolation here for input
isPastCommentSection=false
while IFS= read -r line
do
  if [ $isPastCommentSection = true ]
  then 
    echo $line
    echo $line >> "./policies/environments/test.polar"
  fi
  if [[ "$line" == *"$endCommentTrigger"* ]]
  then 
    isPastCommentSection=true
  fi
done < "$sourceFile"

echo "Configuring temporary git credentials on linux box to match trigger user"
git config user.name $actor
echo "Adding and committing changes to new branch..."
git status
git add -A
git status
git commit -m "Promoting changes from ${sourceEnv} to ${targetEnv}..."
git status
echo "Pushing changes to remote..."
git push origin $branchName
echo "Creating pull request..."
gh pr create --title "${actor}: Promoting ${sourceEnv} polar file contents to the ${targetEnv} polar file" --body "@${actor} is promoting ${sourceEnv} polar file contents to ${targetEnv} polar file."


echo "Success!"










