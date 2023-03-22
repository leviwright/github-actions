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
#Update this message to be correct.
echo "Invalid argument - must provide only one argument with any of the following values: 'development', 'test', 'staging' or 'production'"
exit 1
fi

output=''


input="./policies/environments/development.polar" #do some interpolation here for input
index=1
while IFS= read -r line
do
  if [  $index -gt 1  ]
  then 
    echo "====>>>>> printing line" "$line" 
    output+="${line}\n"
  fi
  ((index++))

done < "$input"

echo "^^^^^^^^^^^^^" "$output"


/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
 (echo; echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"') >> /home/runner/.bash_profile
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
echo "about to install gh"
brew install gh
git checkout main #just to be safe
git pull origin main #just to be safe
git checkout -b promote-polar-dev-to-test #figure out a unique way to version branches or something? 
echo $output > "./policies/environments/test.polar"
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
echo $input