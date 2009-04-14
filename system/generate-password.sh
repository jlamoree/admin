#!/bin/sh

DICT=/usr/share/dict/words
DELIM="."
NUM=2
WORDS=`cat $DICT | wc -l`
BUF=""

while getopts "d:n:" FLAG; do
  case $FLAG in
    "d")
       DELIM=$OPTARG
    ;;
    "n")
       NUM=$OPTARG
    ;;
  esac
done

for I in `seq $NUM`; do
  WORD=`perl -e "print int(rand($WORDS))"`
  test -n "$BUF" && BUF="${BUF}${DELIM}"
  BUF="${BUF}`head -n $WORD $DICT | tail -n 1`"
done
echo "$BUF"
