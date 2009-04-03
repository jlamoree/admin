#!/bin/bash

usage() {
  echo "Usage: $0 {list|delete} pattern [pattern]"  
}

if [ $# -lt 2 ]; then
  usage
  exit 1
fi

COMMAND=$1
shift
PATTERNS="$*"

list() {
  for P in $PATTERNS; do
    postqueue -p | grep -i -E "^ {4,}[^(]*$P" | tr -d ' '
  done
}

delete() {
  DELIDS=`mktemp /tmp/delids.XXXXXX`
  for P in $PATTERNS; do
    postqueue -p | grep -B 2 -E "^ {4,}[^(]*$P" | grep -i -E '^[0-9A-F]' | cut -d ' ' -f 1 > $DELIDS
    postsuper -d - < $DELIDS
  done  
}


case "$COMMAND" in
  list)
    list
    ;;
  delete)
    delete
    ;;
  *)
    usage
    exit 1
    ;;
esac
