endCommentTrigger="# -- End Comment Section --"

sourceFile="../policies/environments/development.polar" #do some interpolation here for input
isPastCommentSection=false



while IFS= read -r line
do
  if [ $isPastCommentSection = true ]
  then 
    echo $line
    echo $line >> "../policies/environments/test.polar"
  fi
  if [[ "$line" == *"$endCommentTrigger"* ]]
  then 
    isPastCommentSection=true
  fi
done < "$sourceFile"
