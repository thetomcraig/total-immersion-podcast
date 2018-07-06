#!/usr/bin/env bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source ${DIR}/helper_functions.sh

makeNewHunk() {
  template_file=$1
  # Todo, make this loop
  path_to_mp3=$(ls $2)
  description=$3
  name="${path_to_mp3%\.*}"

  new_hunk=()

  readarray a < $template_file
  for i in "${a[@]}";
  do
    i=${i/TITLE/$name}
    i=${i/SUMMARY/${description}}
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
      makeNewHunk $2 $3 $4
    ;;
    *)
      echo "Option not recognized ($1);"
      helpStringFunction
    ;;
esac

