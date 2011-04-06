#!/bin/bash

function help {
  echo "Usage: `basename $0` [options] files"
  echo "Options:"
  echo "  -h : Help (this message)."
  echo "  -u : Convert line endings to Unix (default)."
  echo "  -d : Convert line endings to DOS."
  echo 
}

function error {
  echo "Error: $@"
  echo "Use '`basename $0` -h' for help."
  exit 1
}

function getperl {
  local PERL=""
  for P in /usr/bin/perl /usr/local/bin/perl; do
    test -x $P && PERL=$P
  done
  if [ "_$PERL" != "_" ]; then
    echo $PERL
  else
    error "Could not locate Perl."
  fi
}

PERL=`getperl`
FORMAT=unix
while getopts ":hud" FLAG; do
  case $FLAG in
    "h")
      help
      exit 1
    ;;
    "u")
      FORMAT=unix
    ;;
    "d")
      FORMAT=dos
    ;;
  esac
done

shift $(($OPTIND - 1))
for F in $*; do
  T=`mktemp`
  # Normalize line endings
  $PERL -p -e 's/\r\n?$/\n/g; s/[ \t]+$//g' "$F" > $T

  if [ $FORMAT == "dos" ]; then
    $PERL -p -i -e 's/\n$/\r\n/g' $T
  fi

  if [ -s $T ]; then
    echo "$F"
    mv $T "$F"
  fi
done
