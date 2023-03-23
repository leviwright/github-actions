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
git checkout main 
git pull origin main
echo "Creating new branch before enacting changes..."
git checkout -b promote-polar-dev-to-test #figure out a unique way to version branches or something? 

targetFile="./policies/environments/test.polar" #do some interpolation here for input
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
git commit -m "Promoting changes from ENV to ENV..."
git status
echo "Pushing changes to remote..."
git push origin promote-polar-dev-to-test
echo "Creating pull request..."
gh pr create --title "Promoting dev polar file contents to test polar file" --body "@${actor} is making changes"


echo "Success!"










