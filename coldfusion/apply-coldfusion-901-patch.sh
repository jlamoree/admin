#!/bin/sh

#
# The following is specific to ColdFusion 9.01 installed in multiserver configuration.
# Requires Cygwin with curl (if hotfix is not local), unzip, sha1sum (included in coreutils), and tar
#

INSTANCE="$1"
HOTFIX="$2"
HOTFIX_URL="http://kb2.adobe.com/cps/890/cpsid_89094/attachments/CF901.zip"
HOTFIX_SHA1="ad76e1e7e40501d18e71d4d344125dee7f8a5361"

function usage {
  echo -e "Usage: `basename $0` instance [hotfix]\n"
}

function error {
  echo "Error: $@"
  usage
  exit 1
}

# Validate the instance name
if [ "$INSTANCE" == "" ]; then
  error "The ColdFusion instance name within the JRun servers directory must be specified."
fi

if [ "$JRUN_HOME" == "" ]; then
  for D in /cygdrive/d/JRun4 /cygdrive/d/cf9/JRun4 /cygdrive/c/JRun4; do
    if [ -d "$D" ]; then
      JRUN_HOME="$D"
	  break
    fi
  done
elif [ ! -d "$JRUN_HOME" ]; then
  error "The JRUN_HOME environment variable specifies a location that is not accessible: $JRUN_HOME"
fi

if [ "$JRUN_HOME" == "" ]; then
  error "The JRUN_HOME environment variable was not set, and JRun was not found in a typical location."
fi

# Locate the instance directory within the valid JRun path
DEPLOY_ROOT="$JRUN_HOME/servers/$INSTANCE"
if [ ! -d "$DEPLOY_ROOT" ]; then
  error "The specified instance is not accessible: $DEPLOY_ROOT"
fi

if [ -d "$DEPLOY_ROOT/cfusion.ear/cfusion.war/WEB-INF" ]; then
  WEBAPP_ROOT="$DEPLOY_ROOT/cfusion.ear/cfusion.war"
elif [ -d "$DEPLOY_ROOT/cfusion-ear/cfusion-war/WEB-INF" ]; then
  WEBAPP_ROOT="$DEPLOY_ROOT/cfusion-ear/cfusion-war"
else
  error "The specified instance does not appear to contain a ColdFusion web application: $DEPLOY_ROOT"
fi

WORK_DIR=`mktemp -d`

# If the hotfix is not specified, try to fetch from Adobe
if [ "$HOTFIX" == "" ]; then
  HOTFIX=$WORK_DIR/CF901.zip
  echo "Downloading the ColdFusion Hotfix file."
  curl -s -o $HOTFIX "$HOTFIX_URL"
  if [ $? != 0 ]; then
    error "The ColdFusion Hotfix file could not be downloaded."
  fi
fi

# Check that the hotfix exists and verify the file.
if [ ! -f "$HOTFIX" ]; then
  error "The ColdFusion Hotfix file was not found: $HOTFIX"
elif [ $HOTFIX_SHA1 != `sha1sum "$HOTFIX" | cut -f 1 -d ' '` ]; then
  error "The ColdFusion Hotfilx verification failed; correct SHA1 hash is $HOTFIX_SHA1"
fi
echo "The ColdFusion Hotfix zip file has the correct SHA1 hash."
unzip -qq -d $WORK_DIR "$HOTFIX"

# Ready to patch
echo "The ColdFusion Hotfix is ready to be applied."
read -n 1 -p "The server should be stopped before continuing. Ready? (y/n): "
echo
if [ $REPLY != "y" -a $REPLY != "Y" ]; then
  echo -e "Exiting before making any changes.\n"
  exit 0
fi

# Test for existing hotfix jar
REPLACE=0
EXISTS=0
if [ -f "$WEBAPP_ROOT/WEB-INF/cfusion/lib/updates/hf901-00001.jar" ]; then
  EXISTS=1
  read -n 1 -p "The ColdFusion Hotfix update jar already exists. Do you want to replace it? (y/n): "
  echo
  if [ $REPLY == "y" -o $REPLY == "Y" ]; then
    REPLACE=1
  fi
fi

# Copy hotfix update jar
if [ $EXISTS == 0 -o $REPLACE == 1 ]; then
  echo "Copying hotfix jar file."
  cp $WORK_DIR/CF901/lib/updates/hf901-00001.jar "$WEBAPP_ROOT/WEB-INF/cfusion/lib/updates/hf901-00001.jar"
  if [ $? != 0 ]; then
    error "The ColdFusion Hotfix update jar was not copied. Perhaps the server is running."
  fi
fi

# Backup existing paths that will be modified by the hotfix
BACKUP="$HOME/${INSTANCE}-`date +%Y%m%d%H%M%S`.tar.gz"
echo "Creating a backup of existing ColdFusion files as $BACKUP"
tar -z -c -C "$WEBAPP_ROOT" -f "$BACKUP" \
  CFIDE/administrator CFIDE/componentutils CFIDE/wizards \
  WEB-INF/debug WEB-INF/exception \
  WEB-INF/cfusion/lib/log4j.properties

# Patch the instance application files
echo "Replacing the hotfix application files."
unzip -o -qq $WORK_DIR/CF901/CFIDE.zip -d "$WEBAPP_ROOT"
unzip -o -qq $WORK_DIR/CF901/WEB-INF.zip -d "$WEBAPP_ROOT"
find $WORK_DIR/CF901/lib -type f | xargs -i cp {} "$WEBAPP_ROOT/WEB-INF/cfusion/lib"

echo -e "Finished!\n"
exit 0