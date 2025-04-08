#!/bin/bash
# Generates self-signed SSL certificates for PostgreSQL

# Check if OpenSSL is installed
if ! command -v openssl &> /dev/null; then
    echo "OpenSSL not found. Installing..."
    sudo apt-get update && sudo apt-get install -y openssl
fi

# Create directory for certificates
CERT_DIR="$(dirname "$0")/postgres_ssl"
mkdir -p "$CERT_DIR"
cd "$CERT_DIR" || exit

# Generate self-signed certificate (valid for 10 years)
openssl req -new -x509 -days 3650 -nodes -text -out server.crt \
  -keyout server.key -subj "/CN=postgres.db.local" \
  -addext "subjectAltName=DNS:localhost,DNS:postgres.db.local"

# Adjust permissions
chmod 600 server.key
chmod 644 server.crt

# Create .pem version for some clients
cat server.crt server.key > $(dirname "$0")/../server.pem

echo "Certificates generated in:"
echo "• $CERT_DIR/server.crt"
echo "• $CERT_DIR/server.key"
echo "• ./server.pem"