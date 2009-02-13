#!/bin/sh

LOG=/var/log/messages
ORDER=${1:-name}

function parse_log {
  grep -i -E -o ' yum: (installed|updated): .*' $LOG \
    | gawk 'BEGIN { FS=" " } { print "  " $3 " " $5 }'
}

if [ "$ORDER" == "name" ]; then
  parse_log | sort
else
  parse_log
fi
