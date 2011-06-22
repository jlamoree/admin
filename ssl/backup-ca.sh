#!/bin/sh

# Script to backup the files for a certificate authority
# Usage: backup-ca.sh ca_name destination

CA_NAME=${1:-"_"}
BACKUP_DIR=${2:-"_"}
BACKUP_FILE="$BACKUP_DIR/$CA_NAME-ca-backup-`date +%s`.tar.gz"
CA_PATH="/etc/pki/CA"

function usage {
  echo "Usage: `basename $0` ca_name destination"
}

function error {
  echo "Error: $@"
  usage
  echo
  exit 1
}

# Check that the CA is specified
if [ "$CA_NAME" == "_" ]; then
  error "The CA name must be specified."
fi

# Check that the current user has permission to read the CA directory
if [ ! -r "$CA_PATH" ]; then
  error "The CA directory ($CA_PATH) is not accessible by user `whoami`"
fi

# Check that the backup directory is specified
if [ $BACKUP_DIR == "_" ]; then
  error "The destination directory for the backup file must be specified."
elif [ ! -w $BACKUP_DIR ]; then
  error "The destination directory ($BACKUP_DIR) is not writable."
fi

# Check that the CA specified actually exists
if [ ! -r "$CA_PATH/$CA_NAME.crt" ]; then
  error "The CA specified ($CA_NAME.crt) was not found."
fi

# Archive the bits
tar -zcf "$BACKUP_FILE" -C "$CA_PATH" "$CA_NAME.crt" "$CA_NAME.ser" "private/$CA_NAME.key"

echo "Backup file created: $BACKUP_FILE"
echo
