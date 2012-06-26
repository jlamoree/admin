#!/bin/bash

# Create a SSL/TLS certificate for a client using a local certificate authority
# Usage: create-client-cert.sh ca_name key_name

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
PKCS12_FILE="$SSL_PRIVATE/$KEY_NAME.p12"
PEM_FILE="$SSL_PRIVATE/$KEY_NAME.pem"

function usage {
  echo "Usage: `basename $0` [ca_name] [key_name]"
}

function error {
  echo "Error: $@"
  usage
  exit 1
}

# Check that the current user has permission to the certificates
if [ ! -r "$CA_PRIVATE" ]; then
  error "The CA directory ($CA_PRIVATE) is not accessible by user `whoami`"
fi

# Validate CA files
if [ ! -r "$CA_KEY_FILE" ]; then
  error "The CA private key ($CA_KEY_FILE) is not found."
elif [ ! -r "$CA_CERT_FILE" ]; then
  error "The CA certificate file ($CA_CERT_FILE) is not found."
fi

# Validate the CA serial number file
if [ ! -e "$CA_SERIAL_FILE" ]; then
  error "The CA serial number file ($CA_SERIAL_FILE) does not exist."         
fi

# Verify the client key file
if [ ! -r "$KEY_FILE" ]; then
  KEY_REQD="yes"
  read -n 1 -p "The client key ($KEY_FILE) does not exist. Create it? (y/n): "
  echo
  if [ $REPLY != "y" -a $REPLY != "Y" ]; then
    error "Cannot continue without a client key."
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
  openssl genrsa -out "$KEY_FILE" 2048 
  chmod 440 "$KEY_FILE"
fi

# Get next serial number
chmod 600 "$CA_SERIAL_FILE"
echo -e "`date`\t$CERT_FILE" >> "$CA_SERIAL_FILE"
chmod 400 "$CA_SERIAL_FILE"
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

# Export as PKCS#12
openssl pkcs12 -export -clcerts -aes256 -in "$CERT_FILE" -inkey "$KEY_FILE" -out "$PKCS12_FILE"

# Export as PEM
openssl rsa -aes256 -in "$KEY_FILE" -out "$PEM_FILE"
cat "$CERT_FILE" >> "$PEM_FILE"


