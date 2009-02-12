#!/bin/bash

REPOS=${1:-_}

if [ "$REPOS" == _ ]; then
  echo "Usage: `basename $0` repository"
  exit 1
fi

if ! echo "$REPOS" | grep -qE '^/'; then
  REPOS="$PWD/$REPOS"
fi

if [ ! -d "$REPOS" ]; then
  echo "Error: $REPOS does not exist."
  exit 1
fi

if [ ! -d "$REPOS/db" ]; then
  echo "Error: $REPOS does not look like a Subversion repository."
  exit 1
fi

if [ ! -z `lsof -t +D "$REPOS"` ]; then
  echo "Error: there seem to be open files in the repository."
  exit 1
fi

read -n 1 -p "About to update repository to Berkely DB 4.3. Continue? (y/n): "
echo
if [ $REPLY != "y" -a $REPLY != "Y" ]; then
  exit 2
fi

cd $REPOS/db
/usr/bin/db42_checkpoint -1
/usr/bin/db42_recover
/usr/bin/db42_archive
/usr/bin/svnlook youngest ..
/usr/bin/db_archive -d
/usr/bin/svnadmin verify ..

echo "Finished. File permissions have changed."
