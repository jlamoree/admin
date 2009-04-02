#!/bin/sh

# Script to add a certificate to the CA path as its hash symlink
# Usage: import-ca.sh crt_file

CRT_FILE=${1:-"_"}
CA_PATH="/etc/pki/tls/certs"

function usage {
  echo "Usage: `basename $0` crt_name"
}

function error {
  echo "Error: $@"
  usage
  exit 1
}

# Check that the cert exists
if [ "$CRT_FILE" == "_" ]; then
  error "The certificate file is a required argument."
elif [ ! -f "$CRT_FILE" ]; then
  error "The certificate file ($CRT_FILE) does not exist."
fi

# Compute the (first 8 bytes of the) hash
CRT_HASH=$(openssl x509 -noout -hash -in "$CRT_FILE")
if [ ! -n "$CRT_HASH" ]; then
  error "The certificate file hash was not created properly."
fi

# Create the symlink
for I in `seq 0 9`; do
  CRT_LINK="${CA_PATH}/${CRT_HASH}.${I}"
  if [ -f "$CRT_LINK" ]; then
    echo "Warning: File $CRT_LINK exists. Continuing..."
    continue
  fi
  ln -s "$CRT_FILE" "$CRT_LINK"
  break
done

echo "Created symlink $CRT_FILE to $CRT_LINK"
echo
