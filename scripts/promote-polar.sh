#! /bin/bash

development=development
test=test
staging=staging
production=production
endCommentTrigger="# -- End Comment Section --"

envs=( $development $test $staging $production )
targetEnv=$1
userToken=$2
actor=$3

echo $targetEnv
echo $userToken
echo $actor


if [ $# -ne 3 ] || [[ ! " ${envs[*]} " =~ " ${targetEnv} " ]]
then
#Update this message to be correct.
echo "Invalid argument - must provide only one argument with any of the following values: 'development', 'test', 'staging' or 'production'"
exit 1
fi

echo "Installing homebrew to obtain needed packages..."
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
 (echo; echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"') >> /home/runner/.bash_profile
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
echo "Installing github cli tool to enable easy pull request creation..."
brew install gh
echo "Ensure we are start with the latest changes on the master branch..."
git checkout main #just to be safe
git pull origin main #just to be safe
git checkout -b promote-polar-dev-to-test #figure out a unique way to version branches or something? 

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

git config user.name $actor
git config user.email "levi.wright@lumio.com" #figure out how to get user email
git status
git add -A
git status
git commit -m "making a new branch"
git status
git push origin promote-polar-dev-to-test
gh pr create --title "Promoting dev polar file contents to test polar file" --body "Most recent changes"


echo "TOTALLY RAN THE SCRIPT! WOOP WOOP!"
echo $sourceFile










