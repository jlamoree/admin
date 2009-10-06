#!/bin/sh

INSTANCE=${1:-_}
JRUN="/cygdrive/c/JRun4"
STORE="$JRUN/lib/wsconfig/$INSTANCE"
SERVER="$JRUN/servers/$INSTANCE"
SCRIPT=`basename "$0"`

function usage {
  echo "Usage: $SCRIPT instance"
  exit 1
}

function error {
  echo "Error: $1"
  exit 1
}

function warning {
  echo "Warning: $1"
}

# If an instance wasn't supplied, show usage and quit
test $INSTANCE == "_" && usage

# Warn the user if the store directory already exists. EX: C:\JRun4\lib\wsconfig\cfusion
if [ -d "$STORE" ]; then
  warning "The directory ($STORE) already exists."
else
  mkdir "$STORE"
fi

# Die if the server isn't found. We need the jrun.xml file. EX: C:\JRun4\servers\cfusion\SERVER-INF\jrun.xml
if [ ! -d "$SERVER" ]; then
  error "The server directory ($SERVER) does not exist."
fi

# Locate the service definition of the proxy
T=`mktemp`
perl -n -e 'undef $/; /(<service class="jrun\.servlet\.jrpp\.JRunProxyService" name="ProxyService">.*?<\/service>)/s && print $1' $SERVER/SERVER-INF/jrun.xml > $T

# Verify that the proxy isn't not undeactivated
grep -q -F '<attribute name="deactivated">false</attribute>' $T || warning "The JRunProxyService is deactivated."

# Get the port value
PORT=$(
  grep -o -E '<attribute name="port">([0-9]+)</attribute>' $T | grep -o -E '[0-9]+'
)

# Resulting block to add to the Apache virutal host
echo -e "\n<IfModule mod_jrun22.c>"
echo "  JRunConfig Serverstore \"`cygpath -m -w $STORE`/jrunserver.store\""
echo "  JRunConfig Bootstrap 127.0.0.1:$PORT"
echo -e "</IfModule>\n"

# Clean up
rm $T