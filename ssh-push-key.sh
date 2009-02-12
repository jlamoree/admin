#!/bin/bash

SSH_DIR="$HOME/.ssh"
SSH_PRIVATE_KEY="id_dsa"
SSH_PUBLIC_KEY="id_dsa.pub"
SSH_KNOWN_HOSTS="known_hosts"
SSH_AUTHORIZED_KEYS="authorized_keys2"
CLEAN="no"

# Check that remote host is specified
if [ $# -ne 2 ]; then
  echo "Usage: $0 remote_host remote_user"
  exit 1
else
  REMOTE_HOST="$1"
  REMOTE_USER="$2"
fi

# Verify SSH directory exists
if [ ! -d "$SSH_DIR" ]; then
  mkdir -m 0700 -p "$SSH_DIR"
fi

# Remove any existing local known hosts and keys
if [ "$CLEAN" == "yes" ]; then
  test -f "$SSH_DIR/$SSH_PRIVATE_KEY" && rm -f "$SSH_DIR/$SSH_PRIVATE_KEY"
  test -f "$SSH_DIR/$SSH_PUBLIC_KEY" && rm -f "$SSH_DIR/$SSH_PUBLIC_KEY"
  test -f "$SSH_DIR/$SSH_KNOWN_HOSTS" && rm -f "$SSH_DIR/$SSH_KNOWN_HOSTS"
fi

# Generate private/public keys on localhost
ssh-keygen -t dsa -q -f "$SSH_DIR/$SSH_PRIVATE_KEY" -N ''

# Copy keys to remote host
cat "$SSH_DIR/$SSH_PUBLIC_KEY" | ssh -q -l "$REMOTE_USER" "$REMOTE_HOST" \
  "test ! -d ~/.ssh && mkdir -m 0700 ~/.ssh; umask 0077; cat >> ~/.ssh/$SSH_AUTHORIZED_KEYS"
