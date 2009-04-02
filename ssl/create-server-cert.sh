#!/bin/bash

# Create a SSL/TLS certificate for an existing key using a local certificate authority
# Usage: create-server-cert.sh ca_name key_name

CA_PRIVATE="/etc/pki/CA/private"
CA_PUBLIC="/etc/pki/CA"
SSL_PRIVATE="/etc/pki/tls/private"
SSL_PUBLIC="/etc/pki/tls/certs"

CA_NAME=${1:-"ca"}
CA_KEY_FILE="$CA_PRIVATE/$CA_NAME.key"
CA_CERT_FILE="$CA_PUBLIC/$CA_NAME.crt"
CA_SERIAL_FILE="$CA_PUBLIC/$CA_NAME.ser"
CA_SERIAL_NEXTVAL=0

KEY_NAME=${2:-"localhost"}
KEY_FILE="$SSL_PRIVATE/$KEY_NAME.key"
KEY_REQD="no"
CERT_FILE="$SSL_PUBLIC/$KEY_NAME.crt"
CERT_CSR=`mktemp`

function usage {
  echo "Usage: `basename $0` [ca_name] [key_name]"
}

function error {
  echo "Error: $@"
  usage
  exit 1
}

# Validate CA files
if [ ! -r "$CA_KEY_FILE" ]; then
  error "The CA private key ($CA_KEY_FILE) is not found."
elif [ ! -r "$CA_CERT_FILE" ]; then
  error "The CA certificate file ($CA_CERT_FILE) is not found."
fi

# Validate the CA serial number file
if [ ! -r "$CA_SERIAL_FILE" -o ! -w "$CA_SERIAL_FILE" ]; then
  error "The CA serial number file ($CA_SERIAL_FILE) exists, but cannot be read and written."         
fi

# Verify the server key file
if [ ! -r "$KEY_FILE" ]; then
  KEY_REQD="yes"
  read -n 1 -p "The server key ($KEY_FILE) does not exist. Create it? (y/n): "
  echo
  if [ $REPLY != "y" -a $REPLY != "Y" ]; then
    error "Cannot continue without a server key."
  fi
fi

# Verify the cert file
if [ -f "$CERT_FILE" ]; then
  error "The certificate file ($CERT_FILE) already exists."
fi

# Create server key
if [ "$KEY_REQD" == "yes" ]; then
  echo
  echo "Generating the private server key."
  echo "----------------------------------"
  openssl genrsa -out "$KEY_FILE" 1024
  chmod 440 "$KEY_FILE"
fi

# Get next serial number
date >> "$CA_SERIAL_FILE"
CA_SERIAL_NEXTVAL=`wc -l < "$CA_SERIAL_FILE"`

# Create the CSR and certificate
echo
echo "Creating the certificate signing request."
echo "-----------------------------------------"
openssl req -new -key "$KEY_FILE" -out "$CERT_CSR"

echo
echo "Signing the server key as local CA."
echo "-----------------------------------"
openssl x509 -req -days 365 -set_serial $CA_SERIAL_NEXTVAL \
  -CA "$CA_CERT_FILE" -CAkey "$CA_KEY_FILE" \
  -in "$CERT_CSR" -out "$CERT_FILE"
chmod 444 "$CERT_FILE"

# Apache configuration information
echo
echo "Finished! The following directives may be used with Apache."
echo "  SSLCACertificateFile $CA_CERT_FILE"
echo "  SSLCertificateFile $CERT_FILE"
echo "  SSLCertificateKeyFile $KEY_FILE"
echo

