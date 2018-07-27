#!/usr/bin/env bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source ${DIR}/helper_functions.sh

new_hunk_filename="episode_hunk.xml.new"

get_mp3s_from_dir() {
  mp3s_dir=$1
  IFS=$'\n' mp3_paths=( $(ls $mp3s_dir/**.mp3) )
}

uploadToS3DEBUG() {
  echo "fake-s3-url.com"
}
uploadToS3() {
  mp3_path=$1
  bucket="total-immersion-podcast/"
  URL_prefix="https://s3-us-west-2.amazonaws.com/${bucket}"

  # Upload the file using the S3 python program
  source env/bin/activate
  # TODO, this outputs improperly
  s3cmd put ${mp3_path} s3://${bucket}
  # Get the link from the uploaded file
  s3_episode_url=$(echo ${URL_prefix}${mp3_name} | sed 's/ /+/g')
  echo $s3_episode_url
}

makeNewHunk() {
  mp3_path=$1
  full_url=$2
  url=$(echo $full_url | sed 's/https\:\/\///g')
  description=$3
  mp3_path_no_ext="${mp3_path%\.*}"
  file_name="${mp3_path_no_ext##*/}"
  name="$(echo ${file_name} | sed 's/EP//g')"

  date=$(date '+%a, %C %b %Y')
  time=$(mp3info -p "%m:%02s\n" "${mp3_path}")
  bytes=$(wc -c < "${mp3_path}")

  # Create new hunk array
  # Copy template file and do replacement
  new_hunk=()
  template_file=./episode_hunk.xml
  readarray a < $template_file
  for i in "${a[@]}";
  do
    i=${i/TITLE/$name}
    i=${i/SUMMARY/${description}}
    i=${i/TIME/${time}}
    i=${i/LENGTH/${bytes}}
    i=${i/LINK/${url}}
    i=${i/DATE/${date}}
    new_hunk+=("$i")
  done

  printf '%s' "${new_hunk[@]}" > $new_hunk_filename
}

updateXML () {
  cp ./itunes.xml ./itunes.xml.bak
  new_hunk_text=$(cat $new_hunk_filename)

  new_itunes_xml=()
  readarray a < "./itunes.xml"
  for i in "${a[@]}";
  do
    i=${i/"<!-- New episodes here -->"/$new_hunk_text}
    new_itunes_xml+=("$i")
  done
  printf '%s' "${new_itunes_xml[@]}" > itunes.xml.new
}

lint() {
  xmllint --format itunes.xml.new > itunes.xml.new.formatted
  mv itunes.xml.new.formatted itunes.xml.new
}

messageRylan() {
  pushbullet_key="o.qQi1AYMsiP7uL6VCSELe08UjbK8HjJho"
  curl --header "Access-Token: $pushbullet_key" \
    -H "Content-Type: application/json" \
    -d "{ \"email\": \"rylansedivy@gmail.com\", \
                    \"title\": \"$1\", \
                    \"type\": \"note\" \
       }" \
    -X POST \
    https://api.pushbullet.com/v2/pushes
}

diffXMLs() {
  echo "here"
  colordiff itunes.xml itunes.xml.new
}

removeFilesAndFinishXML() {
  rm $new_hunk_filename
  mv itunes.xml.new itunes.xml
  rm itunes.xml.bak
}

helpStringFunction() {
  echo "usage:  apollo [option]"
  echo "Options and arguments:"
  echo "-h|--help               : Show this help message"
  echo "-s|--setup)             : Setup apollo and install requirements"
}

case $1 in
    -h*|--help)
      helpStringFunction
    ;;

    -u|--upload)
      echo -n "Reading files..."
      get_mp3s_from_dir $2
      echo "Done"
      echo "Begin iteration"
      for i in "${mp3_paths[@]}";
      do
        echo "  Uploading <$i>..."
        s3_url=$(uploadToS3 $i)
        echo "  Uploaded"
      done
    ;;
    -x|--xml-update)
      echo -n "Reading files..."
      get_mp3s_from_dir $2
      echo "Done"
      echo "Begin iteration"
      for i in "${mp3_paths[@]}";
      do
        echo -n "  Description for <$i>: "
        read description
        echo -n "  S3 URL for <$i>: "
        read s3_url 
        echo "  Making new hunk..."
        makeNewHunk $i $s3_url $description
        echo "  Done"
        echo "  Updating itunes.xml..."
        updateXML
        echo "  Done"
        echo "  Cleaning up..."
        lint
        echo "  Done"
        echo "  Diff:"
        diffXMLs
        echo "  Does this look correct? [y/N]:"
        promptToContinue
        # TODO validate
        removeFilesAndFinishXML 
      done
    ;;
    -f|--finish)
      # Do the uploading of the xml and validate
      date=$(date '+%a, %C %b %Y')
      # TODO update readme list
      git add itunes.xml
      git commit -m "Episode added for $date"
      git push
      echo "Pushed to master"
      open "https://podcastsconnect.apple.com/"
      echo "  Refreshed? [y/N]:"
      promptToContinue
      echo "  Tell Rylan? [y/N]:"
      promptToContinue
      messageRylan "DONE"
    ;;

    -c|--clean)
      removeFilesAndFinishXML
    ;;

    -s|--setup)
      echo "Installing mp3info"
      brew install mp3info > /dev/null
      echo "Installing colordiff"
      brew install colordiff > /dev/null
      echo "DONE"
      echo "Installing python requirements"
      virtualenv env > /dev/null
      source env/bin/activate > /dev/null
      pip install -r requirements.txt > /dev/null
      pip freeze
      echo "DONE"
    ;;

    *)
      echo "Option not recognized ($1);"
      helpStringFunction
    ;;
esac
