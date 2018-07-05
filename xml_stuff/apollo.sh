#!/usr/bin/env bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source ${DIR}/helper_functions.sh

makeNewHunk() {
  template_file=$1
  path_to_mp3=$2
  filename=$(basename -- "$path_to_mp3")
  extension="${filename##*.}"
  filenameShort="${filename%.*}"

  echo $filename
  echo $extension
  echo $filenameShort

  # new_hunk=()


  # for i in "${a[@]}";
  # do
    # i=${i/TITLE/$new_title}
    # new_hunk+=("$i")
  # done

  # echo ${new_hunk[@]}
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
      makeNewHunk $2 $3
    ;;
    *)
      echo "Option not recognized ($1);"
      helpStringFunction
    ;;
esac

