#!/bin/sh

#
# Script to create a set of random words from a dictionary file.
# Install 'words.noarch' package for /usr/share/dict/words
# Command line args:
#   -d : Delimiter between words. Default is '.'. Ex: -d ' '
#   -n : Number of words. Default is 2. Ex: -n 4
#   -i : Iterations. Default is zero, which means infinite
#

DICT=/usr/share/dict/words
DELIM="."
NUM=2
WORDS=`cat $DICT | wc -l`
BUF=""

while getopts "d:n:i:" FLAG; do
  case $FLAG in
    "d")
       DELIM=$OPTARG
    ;;
    "n")
       NUM=$OPTARG
    ;;
    "i")
       ITERS=$OPTARG
    ;;
  esac
done

for I in `seq $NUM`; do
  WORD=`perl -e "print int(rand($WORDS))"`
  test -n "$BUF" && BUF="${BUF}${DELIM}"
  BUF="${BUF}`head -n $WORD $DICT | tail -n 1`"
done
echo "$BUF"
