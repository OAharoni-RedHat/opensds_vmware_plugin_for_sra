#!/bin/bash

# Linux shell script equivalent of init_dir.bat
# Initializes directory structure for third-party dependencies

echo "************************************************************"
echo "Initializing directory structure..."
echo "************************************************************"

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
THIRD_PARTY_PATH="$(dirname "$SCRIPT_DIR")"

echo "Script directory: $SCRIPT_DIR"
echo "Third party path: $THIRD_PARTY_PATH"

# Log function
log_info() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')][Info] $1"
}

log_info "Initializing OpenSDS Storage Plugins directory structure..."

# Create build directory (Linux equivalent of source directories)
BUILD_DIR="$SCRIPT_DIR/build"
mkdir -p "$BUILD_DIR"
log_info "Created build directory: $BUILD_DIR"

# Note: In Linux, we don't need to pre-create source directories
# as they will be created during the download and extract process
# This is different from Windows where the directory structure
# is expected to exist beforehand

log_info "Directory structure initialized successfully"
log_info "Build directory ready at: $BUILD_DIR"

echo ""
echo "Directory initialization complete!"
echo "Build directory: $BUILD_DIR"
echo ""
echo "You can now run the build scripts:"
echo "- ./one_key_build3rd.sh  (builds all dependencies)"
echo "- Individual scripts: ./build_openssl.sh, ./build_zlib_86.sh, etc."
echo ""
