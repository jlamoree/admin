#!/bin/sh

# Helper script to create certificate authority with reasonable options
# Usage: create-ca.sh [ca_name]

CA_NAME=${1:-"ca"}
CA_PRIVATE="/etc/pki/CA/private"
CA_PUBLIC="/etc/pki/CA"
CA_SERIAL="/etc/pki/CA/$CA_NAME.ser"
CA_NEXTVAL=0

function usage {
  echo "Usage: `basename $0` [ca_name]"
}

function error {
  echo "Error: $@"
  usage
  exit 1
}

# Check that CA does not already exist
if [ -f "$CA_PRIVATE/$CA_NAME.key" ]; then
  error "The CA private key ($CA_PRIVATE/$CA_NAME.key) exists."
elif [ -f "$CA_PUBLIC/$CA_NAME.key" ]; then
  error "The CA certificate file ($CA_PUBLIC/$CA_NAME.key) exists."
fi

# Create a CA serial number file
if [ -e "$CA_SERIAL" ]; then
  error "The CA serial number file ($CA_SERIAL) exists." 
fi
date > "$CA_SERIAL"
CA_NEXTVAL=`wc -l < "$CA_SERIAL"`

# Create the CA private key
echo
echo "Generating the certificate authority private key."
echo "-------------------------------------------------"
openssl genrsa -des3 -out "$CA_PRIVATE/$CA_NAME.key" 1024
chmod 400 "$CA_PRIVATE/$CA_NAME.key"

# Create the self-signed CA certificate
echo
echo "Signing the certificate authority key."
echo "--------------------------------------"
openssl req -new -x509 -days 365 -set_serial $CA_NEXTVAL \
  -key "$CA_PRIVATE/$CA_NAME.key" -out "$CA_PUBLIC/$CA_NAME.crt"
