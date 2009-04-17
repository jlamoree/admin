#!/bin/bash

#
# Script to send a SSH public key to a remove server for key-based login
#

SSH_DIR="$HOME/.ssh"
SSH_PRIVATE_KEY="id_dsa"
SSH_PUBLIC_KEY="id_dsa.pub"
SSH_KNOWN_HOSTS="known_hosts"
SSH_AUTHORIZED_KEYS="authorized_keys2"
REMOTE_USER="`/usr/bin/whoami`"
REMOTE_HOST="${!#}"
REMOTE_PORT=22
REPLACE="no"

function help {
  echo "Usage: `basename $0` [options] host"
  echo "Options:"
  echo "  -h : Help (this message)."
  echo "  -r : Replace current key pair, if they exist."
  echo "  -l : Specify username. Default is current user. Ex: -l username"
  echo "  -p : Remote port. Ex: -p 10022"
  echo 
}

function error {
  echo "Error: $@"
  echo "Use '`basename $0` -h' for help."
  exit 1
}


while getopts ":hrl:p:" FLAG; do
  case $FLAG in
    "h")
       help 
       exit 0
    ;;
    "r")
       REPLACE="yes"
    ;;
    "l")
       REMOTE_USER=$OPTARG
    ;;
    "p")
       REMOTE_PORT=$OPTARG
    ;;
    "?")
       error "Invalid option '$OPTARG'"
       exit 1
    ;;
  esac
done

# Check that remote host is specified
if [ "$REMOTE_HOST" == "" ]; then
  error "A remote host name was not specified."
fi

# Verify SSH directory exists
if [ ! -d "$SSH_DIR" ]; then
  mkdir -m 0700 -p "$SSH_DIR"
fi

# Abort if a key pair already exists
if [ "$REPLACE" == "no" ]; then
  if [ -f "$SSH_DIR/$SSH_PRIVATE_KEY" -o -f "$SSH_DIR/$SSH_PUBLIC_KEY" ]; then
    error "A key pair already exists in $SSH_DIR."
  fi
fi

# Remove an existing local key pair
if [ "$REPLACE" == "yes" ]; then
  test -f "$SSH_DIR/$SSH_PRIVATE_KEY" && rm -f "$SSH_DIR/$SSH_PRIVATE_KEY"
  test -f "$SSH_DIR/$SSH_PUBLIC_KEY" && rm -f "$SSH_DIR/$SSH_PUBLIC_KEY"
fi

# Generate private/public keys on localhost
ssh-keygen -t dsa -q -f "$SSH_DIR/$SSH_PRIVATE_KEY" -N ''

# Copy keys to remote host
cat "$SSH_DIR/$SSH_PUBLIC_KEY" | ssh -q -p $REMOTE_PORT -l "$REMOTE_USER" "$REMOTE_HOST" \
  "test ! -d ~/.ssh && mkdir -m 0700 ~/.ssh; umask 0077; cat >> ~/.ssh/$SSH_AUTHORIZED_KEYS"

echo "Done."
echo

