#!/bin/bash

. ../common/functions

BASE=${1:-0}
START=${2:-1}
END=${3:-255}

function usage {
  echo "Usage: `basename $0` base [start] [end]"
  echo "Example: `basename $0` 10.0.0 1 255"
}

if [ "$BASE" == 0 ]; then
  error "Must specify base IP address."
fi

for B3 in `seq $START $END`; do
  HOST=`dig -t PTR +noall +answer -x ${BASE}.${B3} | sed -r -e 's/.*PTR\s+([-\.a-z0-9]+)\.$/\1/i'` 
  if [ "_$HOST" != "_" ]; then
    echo -e ${BASE}.${B3} "\t$HOST"
  fi
done

