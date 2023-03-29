#! /bin/bash

newLine=$'\n'



priorCommitMessage="hey
lskdjf"
y=${priorCommitMessage%$'\n'*}

echo $y