#!/bin/sh

DICT=/usr/share/dict/words
DELIM="."
ROUNDS=2
WORDS=`cat $DICT | wc -l`
BUF=""

for I in `seq $ROUNDS`; do
  WORD=`perl -e "print int(rand($WORDS))"`
  test -n "$BUF" && BUF="${BUF}${DELIM}"
  BUF="${BUF}`head -n $WORD $DICT | tail -n 1`"
done
echo "$BUF"
