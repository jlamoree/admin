#!/bin/sh

# Helper script to create certificate authority with reasonable defaults

CA_NAME="${!#}"
CA_PRIVATE="/etc/pki/CA/private"
CA_PUBLIC="/etc/pki/CA"
CA_SERIAL_FILE="/etc/pki/CA/$CA_NAME.ser"
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

# Check that the CA name is provided
if [ $# == 0 ]; then
  error "The CA name must be provided."
fi

# Check that the current user has permission to the certificates
if [ ! -r "$CA_PRIVATE" ]; then
  error "The CA directory ($CA_PRIVATE) is not accessible by user `whoami`"
fi

# Check that CA does not already exist
if [ -f "$CA_PRIVATE/$CA_NAME.key" ]; then
  error "The CA private key ($CA_PRIVATE/$CA_NAME.key) exists."
fi

# Check that CA certificate does not already exist
if [ -f "$CA_PUBLIC/$CA_NAME.crt" ]; then
  error "The CA certificate file ($CA_PUBLIC/$CA_NAME.crt) exists."
fi

# Create a CA serial number file if it does not exist and get the next serial number
if [ ! -e "$CA_SERIAL_FILE" ]; then
  touch "$CA_SERIAL_FILE"
fi  
chmod 600 "$CA_SERIAL_FILE"
echo -e "`date`\t$CA_NAME certificate authority" >> "$CA_SERIAL_FILE"
chmod 400 "$CA_SERIAL_FILE"
CA_NEXTVAL=`wc -l < "$CA_SERIAL_FILE"`

# Create the CA private key
echo
echo "Generating the certificate authority private key."
echo "-------------------------------------------------"
openssl genrsa -des3 -out "$CA_PRIVATE/$CA_NAME.key" 2048
chmod 400 "$CA_PRIVATE/$CA_NAME.key"

# Create the self-signed CA certificate
echo
echo "Signing the certificate authority key."
echo "--------------------------------------"
openssl req -new -x509 -days 1095 -set_serial $CA_NEXTVAL \
  -key "$CA_PRIVATE/$CA_NAME.key" -out "$CA_PUBLIC/$CA_NAME.crt"

