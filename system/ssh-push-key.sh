#!/bin/bash

#
# Script to send a SSH public key to a remove server for key-based login
# Joseph Lamoree <joseph@lamoree.com>
#

SSH_DIR="$HOME/.ssh"
SSH_PRIVATE_KEY="id_rsa"
SSH_PUBLIC_KEY="id_rsa.pub"
SSH_KNOWN_HOSTS="known_hosts"
SSH_AUTHORIZED_KEYS="authorized_keys2"
REMOTE_USER="`/usr/bin/whoami`"
REMOTE_HOST="${!#}"
REMOTE_PORT=22
REPLACE="no"
KEY_TYPE="dsa"

function help {
  echo "Usage: `basename $0` [options] host"
  echo "Options:"
  echo "  -h : Help (this message)."
  echo "  -r : Replace current key pair, if they exist."
  echo "  -k : Key pair encryption type (RSA/DSA). Default is RSA. Ex: -k rsa"
  echo "  -l : Specify username. Default is current user. Ex: -l username"
  echo "  -p : Remote port. Ex: -p 10022"
  echo 
}

function error {
  echo "Error: $@"
  echo "Use '`basename $0` -h' for help."
  exit 1
}

while getopts ":hrk:l:p:" FLAG; do
  case $FLAG in
    "h")
       help 
       exit 0
    ;;
    "r")
       REPLACE="yes"
    ;;
    "k")
       KEY_TYPE=$OPTARG
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

# Last argument is hostname, which could be the zeroth argument
if [ $# -eq 0 ]; then
  REMOTE_HOST=""
fi

# Verify SSH directory exists
if [ ! -d "$SSH_DIR" ]; then
  mkdir -m 0700 -p "$SSH_DIR"
fi

# Set key type
if [ "$KEY_TYPE" == "dsa" ]; then
  SSH_PUBLIC_KEY="id_dsa"
  SSH_PRIVATE_KEY="id_dsa.pub"
  echo "Key type is DSA"
elif [ "$KEY_TYPE" = "rsa" ]; then
  SSH_PUBLIC_KEY="id_rsa"
  SSH_PRIVATE_KEY="id_rsa.pub"
  echo "Key type is RSA"
else
  error "The key type specified is not supported."
fi

# Check for existing key pair already exists
if [ "$REPLACE" == no ]; then
  if [ -f "$SSH_DIR/$SSH_PRIVATE_KEY" -o -f "$SSH_DIR/$SSH_PUBLIC_KEY" ]; then
    CREATE=no
    echo "Existing key found: $SSH_DIR:$SSH_PRIVATE_KEY"
  fi
fi

# Remove an existing local key pair
if [ "$REPLACE" == yes ]; then
  CREATE=yes
  test -f "$SSH_DIR/$SSH_PRIVATE_KEY" && rm -f "$SSH_DIR/$SSH_PRIVATE_KEY"
  test -f "$SSH_DIR/$SSH_PUBLIC_KEY" && rm -f "$SSH_DIR/$SSH_PUBLIC_KEY"
fi

# Generate private/public keys on localhost
if [ "$CREATE" == yes ]; then
  echo "Creating a new key pair."
  if [ "$KEY_TYPE" == rsa ]; then
    ssh-keygen -t rsa -b 2048 -q -f "$SSH_DIR/$SSH_PRIVATE_KEY" -N ''
  elif [ "$KEY_TYPE" == dsa ]; then 
    ssh-keygen -t dsa -b 1024 -q -f "$SSH_DIR/$SSH_PRIVATE_KEY" -N ''
  fi
fi

# Copy keys to remote host
if [ -z "$REMOTE_HOST" ]; then
  echo "No host specified. Keys not transferred."
else
  echo "Sending key pair to $REMOTE_HOST"
  cat "$SSH_DIR/$SSH_PUBLIC_KEY" | ssh -p $REMOTE_PORT -l "$REMOTE_USER" "$REMOTE_HOST" \
    "test ! -d ~/.ssh && mkdir -m 0700 ~/.ssh; umask 0077; cat >> ~/.ssh/$SSH_AUTHORIZED_KEYS"
fi

echo "Done."
echo

