#!/bin/bash

# Linux shell script equivalent of build_openssl.bat
# Builds OpenSSL library for OpenSDS SRA

set -e  # Exit on error

echo "************************************************************"
echo "Start building openssl..."
echo "Build openssl, please waiting..."
echo "************************************************************"

# Get current directory and set paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="$SCRIPT_DIR/build"
OPENSSL_VERSION="1.0.2j"
OPENSSL_DIR="$BUILD_DIR/openssl-$OPENSSL_VERSION"
INSTALL_DIR="$BUILD_DIR/openssl-$OPENSSL_VERSION"

# Create build directory
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

# Backup existing log if present
if [ -f "build.log" ]; then
    mv build.log "build_$(date '+%H%M%S').log"
fi

# Log function
log_info() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')][Info] $1" | tee -a build.log
}

log_error() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')][Error] $1" | tee -a build.log
}

log_info "************************************************************"
log_info "Start building openssl..."
log_info "Setting environment..."
log_info "."
log_info "-------------------compile openssl-------------------"
log_info "."

# Download OpenSSL if not present
if [ ! -f "openssl-$OPENSSL_VERSION.tar.gz" ]; then
    log_info "Downloading OpenSSL $OPENSSL_VERSION..."
    if command -v wget >/dev/null 2>&1; then
        wget "https://www.openssl.org/source/old/1.0.2/openssl-$OPENSSL_VERSION.tar.gz"
    else
        curl -L -o "openssl-$OPENSSL_VERSION.tar.gz" "https://www.openssl.org/source/old/1.0.2/openssl-$OPENSSL_VERSION.tar.gz"
    fi
fi

# Extract and build OpenSSL
if [ ! -d "openssl-$OPENSSL_VERSION" ]; then
    log_info "Extracting OpenSSL..."
    tar -xzf "openssl-$OPENSSL_VERSION.tar.gz"
fi

cd "openssl-$OPENSSL_VERSION"

log_info "Configuring OpenSSL..."
# Configure for Linux with shared libraries
./config --prefix="$INSTALL_DIR" shared no-asm

log_info "Building OpenSSL..."
make -j$(nproc)

log_info "Installing OpenSSL..."
make install

log_info "Copying compiled files"
# Create directory structure for compatibility
mkdir -p "$INSTALL_DIR/bin"
mkdir -p "$INSTALL_DIR/lib"
mkdir -p "$INSTALL_DIR/include"

# Copy files to expected locations
if [ -d "$INSTALL_DIR/bin" ]; then
    log_info "OpenSSL binaries available in $INSTALL_DIR/bin"
fi

if [ -d "$INSTALL_DIR/lib" ]; then
    log_info "OpenSSL libraries available in $INSTALL_DIR/lib"
fi

if [ -d "$INSTALL_DIR/include" ]; then
    log_info "OpenSSL headers available in $INSTALL_DIR/include"
fi

cd "$BUILD_DIR"

log_info "Build openssl end"

# Check for build success
build_failed=false
if [ ! -f "$INSTALL_DIR/lib/libssl.so" ] && [ ! -f "$INSTALL_DIR/lib/libssl.a" ]; then
    build_failed=true
fi

if [ ! -f "$INSTALL_DIR/lib/libcrypto.so" ] && [ ! -f "$INSTALL_DIR/lib/libcrypto.a" ]; then
    build_failed=true
fi

if [ "$build_failed" = true ]; then
    log_error "Build openssl fail"
    echo "build openssl fail"
    exit_code=1
else
    log_info "Build openssl success"
    echo "build openssl success"
    exit_code=0
fi

log_info "************************************************************"
echo "************************************************************"

exit $exit_code
