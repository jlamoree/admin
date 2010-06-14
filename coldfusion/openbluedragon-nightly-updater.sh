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

curl -'#' -A "$UA" -o "$DOWNLOAD" $URL
test -f "$DOWNLOAD" || exit 1

mv "$DOWNLOAD" "$ARCHIVE"
md5 -r "$ARCHIVE"
unzip -qq -j -d "$WORK" "$ARCHIVE" WEB-INF/lib/OpenBlueDragon.jar
unzip -qq -c "$WORK/OpenBlueDragon.jar" openbd.properties
mv -f "$WORK/OpenBlueDragon.jar" "$DEPLOY/$CONTEXT/WEB-INF/lib/OpenBlueDragon.jar"
rm -rf "$WORK"
exit 0
