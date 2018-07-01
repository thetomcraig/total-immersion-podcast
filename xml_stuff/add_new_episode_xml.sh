DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
echo $DIR

cat $(${DIR}/episode_hunk.txt) | while read line
do
  echo "a line: $line"
  # echo ${line//abc/XYZ}; 
done 
# < $DIR/file.txt > $DIR/file.txt.t;

# mv $DIR/file.txt{.t,}
