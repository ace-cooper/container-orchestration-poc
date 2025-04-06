#!/bin/bash

# Source the environment variables
source "$(dirname "$0")/../.env"

# Get the absolute path of the bin directory
BIN_DIR="$(cd "$(dirname "$0")" && pwd)"

# Change to the bin directory
cd "$BIN_DIR"

# Upload all files from bin directory except upload.sh
scp -r \
    $(find . -type f -not -name "upload.sh" | sed 's|^./||') \
    root@$DOMAIN:/root/setup/

echo "Upload completed successfully!"