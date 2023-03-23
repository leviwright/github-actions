#sed -i '' '/whatever/' dummy.polar

lineToStart="`grep -n '# -- End Comment Section --' dummy.polar | cut -d: -f 1`"
((lineToStart++))

echo $lineToStart
echo "${lineToStart},\$d"

sed -i '' "${lineToStart},\$d" dummy.polar

