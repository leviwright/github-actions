#! /bin/bash

branchName="promote-polar-development-to-test"

if [ `git branch -r --list "origin/${branchName}"` ]
then
   echo "${branchName} already exists. Merge or delete existing branch to continue."
   exit 1
fi


git branch --list $branchName