#!/usr/bin/env bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source ${DIR}/helper_functions.sh

bucket="total-immersion-podcast/"
URL_prefix="https://s3-us-west-2.amazonaws.com/${bucket}"


makeNewHunk() {
  OIFS=$IFS;
  IFS=" ";
  IFS=$OIFS

  commands=($1)
  mp3s_dir=${commands[1]}
  mp3_name=$(ls $mp3s_dir)
  path_to_mp3=${mp3s_dir}/${mp3_name}

  name="${mp3_name%\.*}"
  time=$(mp3info -p "%m:%02s\n" "${path_to_mp3}")
  description="${commands[@]:2}"
  bytes=$(wc -c < "${path_to_mp3}")

  # Upload the file
  source env/bin/activate
  # s3cmd put ${path_to_mp3} s3://${bucket}
  # Get the link from the uploaded file
  s3_episode_url=$(echo ${URL_prefix}${mp3_name} | sed 's/ /+/g')

  new_hunk=()
  template_file=./episode_hunk.txt
  readarray a < $template_file
  for i in "${a[@]}";
  do
    i=${i/TITLE/$name}
    i=${i/SUMMARY/${description}}
    i=${i/TIME/${time}}
    i=${i/LENGTH/${bytes}}
    i=${i/LINK/${s3_episode_url}}
    new_hunk+=("$i")
  done

  echo ${new_hunk[@]}
}

helpStringFunction() {
  echo "usage:  apollo [option]"
  echo "Options and arguments:"
  echo "-n|--new_hunk <template file> <path to mp3> : show this help message"
  echo "-h|--help                                   : show this help message"
}

case $1 in
    -h*|--help)
      helpStringFunction
    ;;
    -n|--new_hunk)
      makeNewHunk "$*"
    ;;
    *)
      echo "Option not recognized ($1);"
      helpStringFunction
    ;;
esac

