#!/usr/bin/env bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source ${DIR}/helper_functions.sh

release_date=$(date '+%a %C %b %Y')
template_filename=./episode_hunk.xml
new_hunk_filename="${template_filename}.new"
validator_url="http://castfeedvalidator.com/?url=https://raw.githubusercontent.com/thetomcraig/total-immersion-podcast/master/xml_stuff/itunes.xml"
s3_search_prefix="https://console.aws.amazon.com/s3/buckets/total-immersion-podcast/?region=us-west-2&tab=overview&prefixSearch=EP"
readme_new_episode_line="| ------ | ---------- | -------------- | ----- | ----------- | ------ | ---------- |"

setupApollo() {
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

}

get_mp3s_from_dir() {
  mp3s_dir=$1
  IFS=$'\n' mp3_paths=( $(ls $mp3s_dir/**.mp3) )
}

uploadMp3sToS3() {
  echo -n "Reading files..."
  get_mp3s_from_dir $1
  echo "Done"
  echo "Begin iteration"
  for i in "${mp3_paths[@]}";
  do
    echo "  Uploading <$i>..."
    s3_url=$(uploadToS3 $i)
    echo "  Uploaded"
  done
}

uploadToS3() {
  mp3_path=$1
  bucket="total-immersion-podcast/"
  URL_prefix="https://s3-us-west-2.amazonaws.com/${bucket}"

  # Upload the file using the S3 python program
  source env/bin/activate
  s3cmd put ${mp3_path} s3://${bucket}
}

uploadToS3DEBUG() {
  echo "fake-s3-url.com"
}

updateXMLForAllMp3s() {
  echo -n "Reading files..."
  get_mp3s_from_dir $1
  echo "Done"
  echo "Begin iteration"
  for i in "${mp3_paths[@]}";
  do
    echo -n "  Description for <$i>: "
    read description
    echo -n "  Date for <$i>[default: ${release_date}]: "
    read date
    if [[ -z "${date}" ]]; then
      date=${release_date}
    fi
    ep_number=$(echo ${i} | 's/(EP)([0-9]+)( - )(.*)/\2/p')
    s3_search_url=${s3_search_prefix}${ep_number}
    echo -n "  Copy URL from browser..."
    open $s3_search_url
    echo -n "  S3 URL for <$i>: "
    read s3_url
    echo "Updating itunes.xml and readme.md..."
    updateXMLAndReadme $i $s3_url $description $date $ep_number
    echo "  Done"
    echo "  Cleaning up..."
    lint
    echo "  Done"
    diffXMLsAndReplace
  done
}

updateXMLAndReadme() {
  mp3_path=$1
  full_url=$2
  description=$3
  date=$4
  ep_number=$5

  url=$(echo $full_url | sed 's/https\:\/\///g')
  mp3_path_no_ext="${mp3_path%\.*}"
  file_name="${mp3_path_no_ext##*/}"
  name="$(echo ${file_name} | sed 's/EP//g')"

  duration=$(mp3info -p "%m:%02s\n" "${mp3_path}")
  bytes=$(wc -c < "${mp3_path}")

  echo -n "  iTunes Link: "
  read listen_link
  echo -n "  Notes Link: "
  read notes_link


  makeNewXMLHunkFile ${name} ${description} ${duration} ${bytes} ${url} ${date}
  updateReade ${name} ${description} ${ep_number} ${listen_link} ${notes_link}
}

makeNewXMLHunkFile() {
  name=$1
  description=$2
  duration=$3
  bytes=$3
  url=$3
  date=$3

  # Bckup the xml file
  cp ./itunes.xml ./itunes.xml.bak

  # Create new hunk array
  # Copy template file and do replacement
  new_hunk=()
  readarray template_file_lines < ${template_filename}
  for i in "${template_file_lines[@]}";
  do
    i=${i/TITLE/$name}
    i=${i/SUMMARY/${description}}
    i=${i/TIME/${time}}
    i=${i/LENGTH/${bytes}}
    i=${i/LINK/${url}}
    i=${i/DATE/${date}}
    new_hunk+=("$i")
  done
  # Hunk complete
  # Open the itunes xml file
  new_itunes_xml=()
  readarray a < "./itunes.xml"
  for i in "${a[@]}";
  do
    i=${i/"<!-- New episodes here -->"/${new_hunk[@]}}
    new_itunes_xml+=("$i")
  done
  printf '%s' "${new_itunes_xml[@]}" > itunes.xml.new
}

updateReadme() {
  name=$1
  description=$2
  ep_number=$3
  listen_link=$4
  notes_link=$5

  new_episode_line="${readme_new_episode_line}"
  new_episode_line+="| 2 | ${ep_number} | ${name} | ${description}| ${listen_link} | ${notes_link} |\n"

  new_readme=()
  readarray a < "../README.md"
  for i in "${a[@]}";
  do
    i=${i}/${readme_new_episode_line}/${new_episode_line}
    new_readme+=("${i}")
  done
  printf '%s' "${new_readme[@]}" > README.md
}


lint() {
  xmllint --format itunes.xml.new > itunes.xml.new.formatted
  mv itunes.xml.new.formatted itunes.xml.new
}

pushXML() {
  echo -n "Pushing to GitHub..."
  # Do the uploading of the xml and validate
  date=$(date '+%a, %d %b %Y')
  # TODO update readme list
  mv itunes.xml.new itunes.xml
  git add itunes.xml
  git commit -m "Episode added for $date"
  git push
  echo "Done"
}

validateXML() {
  echo "  Validated? Answer after success [y/N]:"
  open ${validator_url}
  promptToContinue
}

refreshURL() {
  open "https://podcastsconnect.apple.com/"
  echo "  Refreshed? [y/N]:"
  promptToContinue
}

diffXMLsAndReplace() {
  colordiff itunes.xml itunes.xml.new
  echo "  Diff Ok [Y/n]?"
  promptToContinue
  mv itunes.xml.new itunes.xml
}

fullEpisodeUpload() {
  uploadMp3sToS3 $1
  updateXMLForAllMp3s $1
  pushXML
  validateXML
  refreshURL
  cleanupRootDirectory
}

cleanupRootDirectory() {
  mp3s_dir=$1

  rm -f $mp3s_dir/**.mp3
  rm -f $new_hunk_filename
  rm -f itunes.xml.bak
}

helpStringFunction() {
  echo "usage: apollo [option]"
  echo "Options and arguments:"
  echo "-h|--help                    : Show this help message"
  echo "-f|--full-upload <directory> : Perform a full episode upload and XML update.
                               Same as calling
                                --upload,
                                --xml-update,
                                --push,
                                --validate,
                                --refresh,
                                --clean"
  echo "-u|--upload <directory>      : Read all mp3 files from the directory and upload them to S3"
  echo "-x|--xml-update <directory>  : Read all mp3 files from the directory and make a new  XML entry for each one "
  echo "-p|--push                    : Push the iTunes XML to GitHub"
  echo "-v|--validate                : Validate the XML"
  echo "-r|--refresh                 : Refresh the URL on the iTunes website"
  echo "-e|--update-readme           : Update the Readme file with a section for the new episodes"
  echo "-c|--clean <directory>       : Remove dangling temporary files"
  echo "-s|--setup)                  : Setup Apollo and install requirements"
}

case $1 in
    -h*|--help)
      helpStringFunction
    ;;

    -f|--full-upload)
      fullEpisodeUpload $2
    ;;

    -u|--upload)
      uploadMp3sToS3 $2
    ;;

    -x|--xml-update)
      updateXMLForAllMp3s $2
    ;;
    -p|--push)
      pushXML
    ;;

    -v|--validate)
      validateXML
    ;;

    -r|--refresh)
      refreshURL
    ;;

    -e|--update-readme)
      updateReadme
    ;;

    -c|--clean)
      cleanupRootDirectory $2
    ;;

    -s|--setup)
      setupApollo
    ;;

    *)
      echo "Option not recognized ($1);"
      helpStringFunction
    ;;
esac
