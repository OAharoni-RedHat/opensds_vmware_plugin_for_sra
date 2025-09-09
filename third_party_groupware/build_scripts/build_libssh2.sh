#!/bin/bash

# Linux shell script equivalent of build_libssh2.bat
# Builds libssh2 library for OpenSDS SRA

set -e  # Exit on error

echo "************************************************************"
echo "Start building libssh2..."
echo "************************************************************"

# Get current directory and set paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="$SCRIPT_DIR/build"
LIBSSH2_VERSION="1.7.0"
LIBSSH2_DIR="$BUILD_DIR/libssh2-$LIBSSH2_VERSION"
INSTALL_DIR="$BUILD_DIR/libssh2-$LIBSSH2_VERSION"

# Dependencies
OPENSSL_DIR="$BUILD_DIR/openssl-1.0.2j"
ZLIB_DIR="$BUILD_DIR/zlib-1.2.11"

# Create build directory
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

# Log function
log_info() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')][Info] $1" | tee -a build.log
}

log_error() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')][Error] $1" | tee -a build.log
}

log_info "************************************************************"
log_info "Start building libssh2..."
log_info "."
log_info "-------------------compile libssh2-------------------"
log_info "."

# Download libssh2 if not present
if [ ! -f "libssh2-$LIBSSH2_VERSION.tar.gz" ]; then
    log_info "Downloading libssh2 $LIBSSH2_VERSION..."
    if command -v wget >/dev/null 2>&1; then
        wget "https://www.libssh2.org/download/libssh2-$LIBSSH2_VERSION.tar.gz"
    else
        curl -L -o "libssh2-$LIBSSH2_VERSION.tar.gz" "https://www.libssh2.org/download/libssh2-$LIBSSH2_VERSION.tar.gz"
    fi
fi

# Extract and build libssh2
if [ ! -d "libssh2-$LIBSSH2_VERSION" ]; then
    log_info "Extracting libssh2..."
    tar -xzf "libssh2-$LIBSSH2_VERSION.tar.gz"
fi

cd "libssh2-$LIBSSH2_VERSION"

log_info "build libssh2, please wait..."
log_info "start compiling libssh2..."

# Configure libssh2 with dependencies
CONFIGURE_OPTIONS="--prefix=$INSTALL_DIR --enable-shared --disable-static"

# Add OpenSSL support if available
if [ -d "$OPENSSL_DIR" ]; then
    log_info "Configuring with OpenSSL support from $OPENSSL_DIR"
    CONFIGURE_OPTIONS="$CONFIGURE_OPTIONS --with-openssl=$OPENSSL_DIR"
    export PKG_CONFIG_PATH="$OPENSSL_DIR/lib/pkgconfig:$PKG_CONFIG_PATH"
    export LD_LIBRARY_PATH="$OPENSSL_DIR/lib:$LD_LIBRARY_PATH"
fi

# Add zlib support if available
if [ -d "$ZLIB_DIR" ]; then
    log_info "Configuring with zlib support from $ZLIB_DIR"
    CONFIGURE_OPTIONS="$CONFIGURE_OPTIONS --with-zlib=$ZLIB_DIR"
    export PKG_CONFIG_PATH="$ZLIB_DIR/lib/pkgconfig:$PKG_CONFIG_PATH"
    export LD_LIBRARY_PATH="$ZLIB_DIR/lib:$LD_LIBRARY_PATH"
fi

log_info "Configuring libssh2 with options: $CONFIGURE_OPTIONS"
./configure $CONFIGURE_OPTIONS

log_info "Building libssh2..."
make -j$(nproc)

log_info "Installing libssh2..."
make install

log_info "copying temp files..."
# Create directory structure for compatibility
mkdir -p "$INSTALL_DIR/bin"
mkdir -p "$INSTALL_DIR/lib"
mkdir -p "$INSTALL_DIR/include"

# Verify installation
if [ -f "$INSTALL_DIR/lib/libssh2.so" ] || [ -f "$INSTALL_DIR/lib/libssh2.a" ]; then
    log_info "libssh2 libraries found in $INSTALL_DIR/lib"
fi

if [ -f "$INSTALL_DIR/include/libssh2.h" ]; then
    log_info "libssh2 headers found in $INSTALL_DIR/include"
fi

cd "$BUILD_DIR"

log_info "build libssh2 end"

# Check for build success
build_failed=false
if [ ! -f "$INSTALL_DIR/lib/libssh2.so" ] && [ ! -f "$INSTALL_DIR/lib/libssh2.a" ]; then
    build_failed=true
fi

if [ ! -f "$INSTALL_DIR/include/libssh2.h" ]; then
    build_failed=true
fi

if [ "$build_failed" = true ]; then
    log_error "build libssh2 fail"
    echo "build libssh2 fail"
    exit_code=1
else
    log_info "build libssh2 success"
    echo "build libssh2 success"
    exit_code=0
fi

log_info "************************************************************"
echo "************************************************************"

exit $exit_code
