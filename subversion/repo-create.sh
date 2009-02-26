#!/bin/bash

APACHE=apache
REPOS_NAME=${1:-_}
REPOS_DIR="/home/svn/repositories/$REPOS_NAME"

if [ "$REPOS_NAME" == _ ]; then
  echo "Usage: `basename $0` name"
  exit 1
fi

if [ -d "$REPOS_DIR" ]; then
  echo "Error: $REPOS_DIR already exists."
  exit 1
fi

svnadmin create "$REPOS_DIR"
chown $APACHE:$APACHE -R "$REPOS_DIR"

echo "Created $REPOS_DIR"
