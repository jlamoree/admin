#!/bin/sh

# Helper script to create certificate authority with reasonable defaults

CA_NAME="${!#}"
CA_PRIVATE="/etc/pki/CA/private"
CA_PUBLIC="/etc/pki/CA"
CA_SERIAL="/etc/pki/CA/$CA_NAME.ser"
CA_NEXTVAL=0

function help {
  echo "Usage: `basename $0` [options] ca_name"
  echo "Options:"
  echo "  -h : Help (this message)."
  echo
}

function error {
  echo "Error: $@"
  echo "Use '`basename $0` -h' for help."
  exit 1
}

while getopts ":h" FLAG; do
  case $FLAG in
    "h")
       help 
       exit 0
    ;;
    "?")
       error "Invalid option '$OPTARG'"
       exit 1
    ;;
  esac
done

# Check that CA does not already exist
if [ -f "$CA_PRIVATE/$CA_NAME.key" ]; then
  error "The CA private key ($CA_PRIVATE/$CA_NAME.key) exists."
fi

# Check that CA certificate does not already exist
if [ -f "$CA_PUBLIC/$CA_NAME.crt" ]; then
  error "The CA certificate file ($CA_PUBLIC/$CA_NAME.crt) exists."
fi

# Check that a CA serial number file does not already exist
if [ -e "$CA_SERIAL" ]; then
  error "The CA serial number file ($CA_SERIAL) exists." 
fi


# Create a CA serial number file
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

