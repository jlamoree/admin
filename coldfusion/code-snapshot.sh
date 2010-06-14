#!/bin/bash

SNAME=${1:-_}
SPATH=${2:-_}
SNAPSHOT="$SNAME-snapshot-`date +%Y%m%d`.tar.gz"
SELF="`basename $0`"

function usage {
  echo "Usage: $SELF name path"
}

function error {
  echo "Error: $1"
  exit 1
}

if [ "$SNAME" == _ -o "$SPATH" == _ ]; then
  usage
  exit 1
fi
if [ ! -d "$SPATH" ]; then
  error "The path $SPATH is not accessible."
fi

find "$SPATH" -name '*.cf?' -print0 | xargs -0 tar -zcf "$SNAPSHOT"
