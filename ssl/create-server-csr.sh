#!/bin/bash

# Create a SSL/TLS private key (if needed) and certificate signing request
# Usage: create-server-csr.sh key_name

SSL_PRIVATE="/etc/pki/tls/private"
SSL_PUBLIC="/etc/pki/tls/certs"

KEY_NAME="$1"
KEY_FILE="$SSL_PRIVATE/$KEY_NAME.key"
KEY_REQD="no"
CERT_CSR=`mktemp`

function usage {
  echo "Usage: `basename $0` key_name"
}

function error {
  echo "Error: $@"
  usage
  exit 1
}

# Verify key_name
if [ "$KEY_NAME" == "" ]; then
  error "The key_name argument was not provided."
fi

# Check that the current user has permission to the certificates
if [ ! -r "$SSL_PRIVATE" ]; then
  error "The SSL directory ($SSL_PRIVATE) is not accessible by user `whoami`"
fi

# Verify the server key file
if [ ! -r "$KEY_FILE" ]; then
  KEY_REQD="yes"
  read -n 1 -p "The server key ($KEY_FILE) does not exist. Create it? (y/n): "
  echo
  if [ $REPLY != "y" -a $REPLY != "Y" ]; then
    error "Cannot continue without a server key."
  fi
else
  read -n 1 -p "The server key ($KEY_FILE) exists. Do you want to use it? (y/n): "
  echo
  if [ $REPLY != "y" -a $REPLY != "Y" ]; then
    KEY_REQD="yes"
    cat $KEY_FILE >> $KEY_FILE.archive
    echo "Previous key archived as $KEY_FILE.archive"
    chmod 400 "$KEY_FILE.archive"
  fi
fi

# Create server key
if [ "$KEY_REQD" == "yes" ]; then
  echo
  echo "Generating the private server key."
  echo "----------------------------------"
  openssl genrsa -out "$KEY_FILE" 2048
  chmod 440 "$KEY_FILE"
fi

# Create the CSR and certificate
echo
echo "Creating the certificate signing request."
echo "-----------------------------------------"
openssl req -new -key "$KEY_FILE" -out "$CERT_CSR"

echo "Finished. CSR to follow."
echo
cat "$CERT_CSR"

