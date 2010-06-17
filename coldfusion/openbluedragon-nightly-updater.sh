#!/bin/bash

NIGHTLY="OpenBlueDragon-Nightly-`date +%Y-%m-%d`.zip"
SERVER="$HOME/Servers/Tomcat"
DEPLOY="$SERVER/webapps"
CONTEXT="ROOT"
URL="http://www.openbluedragon.org/download/nightly/openbd.war"
ARCHIVE="$HOME/Downloads/$NIGHTLY"
SELF="`basename $0 | sed -E 's/\.[a-z]+\$//'`"
WORK="`mktemp -d /tmp/$SELF.XXXX`"
DOWNLOAD="$WORK/$NIGHTLY"
UA="$SELF/0.01"
FILE="_"
MINIMAL="no"

function help {
  echo "Usage: $SELF [options]"
  echo "Options:"
  echo "  -h : Help (this message)."
  echo "  -m : Minimal update -- just OpenBlueDragon.jar"
  echo "  -f : File to use, rather than downloading"
  echo 
}

function error {
  echo "Error: $1"
  exit 1
}

while getopts ":hmf:" FLAG; do
  case $FLAG in
    "h")
       help 
       exit 0
    ;;
    "m")
       MINIMAL="yes"
    ;;
    "f")
       FILE="$OPTARG"
    ;;
    "?")
       error "Invalid option '$OPTARG'"
       exit 1
    ;;
  esac
done

if [ "$FILE" == "_" ]; then
  curl -'#' -A "$UA" -o "$DOWNLOAD" $URL
  if [ ! -f "$DOWNLOAD" ]; then
    error "The file was not downloaded successfully."
  fi
  mv "$DOWNLOAD" "$ARCHIVE"
elif [ ! -f "$FILE" ]; then
  error "The file specified ($FILE) is not accessible."
else
  ARCHIVE="$FILE"
fi

md5 -r "$ARCHIVE"
if [ "$MINIMAL" == "yes" ]; then
  unzip -qq -j -d "$WORK" "$ARCHIVE" WEB-INF/lib/OpenBlueDragon.jar
  unzip -qq -c "$WORK/OpenBlueDragon.jar" openbd.properties
  mv -f "$WORK/OpenBlueDragon.jar" "$DEPLOY/$CONTEXT/WEB-INF/lib/OpenBlueDragon.jar"
  echo "Finished a minimal update by replacing the OpenBlueDragon.jar file."
else
  unzip -qq -d "$WORK" "$ARCHIVE"
  for D in bluedragon demo manual WEB-INF/lib; do
    rm -rf "$DEPLOY/$CONTEXT/$D"
    mv -f "$WORK/$D" "$DEPLOY/$CONTEXT/$D"
  done
  echo "Finished a complete update of Open BlueDragon."
fi
rm -rf "$WORK"
exit 0
