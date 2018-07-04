new_title=$1
new_hunk=()

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
IFS=$'\n' a=($(cat ${DIR}/episode_hunk.txt))


for i in "${a[@]}";
do
  i=${i/TITLE/$new_title}
  new_hunk+=("$i")
done


echo ${new_hunk[@]}
