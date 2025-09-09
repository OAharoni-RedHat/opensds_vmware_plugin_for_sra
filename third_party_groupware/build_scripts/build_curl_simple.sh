#!/bin/bash

# Simple curl build - bypass configure script issues entirely
# Build curl manually with simple Makefile approach

set -e  # Exit on error

echo "************************************************************"
echo "Start building libcurl (simple manual build)..."
echo "************************************************************"

# Get current directory and set paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="$SCRIPT_DIR/build"
CURL_VERSION="7.52.1"
CURL_SOURCE_DIR="$BUILD_DIR/curl-$CURL_VERSION-simple"
INSTALL_DIR="$BUILD_DIR/curl-$CURL_VERSION"

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
log_info "Start building libcurl (simple manual build)..."
log_info "."

# Download curl if not present
if [ ! -f "curl-$CURL_VERSION.tar.gz" ]; then
    log_info "Downloading curl $CURL_VERSION..."
    if command -v wget >/dev/null 2>&1; then
        wget "https://curl.se/download/curl-$CURL_VERSION.tar.gz"
    else
        curl -L -o "curl-$CURL_VERSION.tar.gz" "https://curl.se/download/curl-$CURL_VERSION.tar.gz"
    fi
fi

# Extract curl
if [ ! -d "curl-$CURL_VERSION-simple" ]; then
    log_info "Extracting curl..."
    tar -xzf "curl-$CURL_VERSION.tar.gz"
    mv "curl-$CURL_VERSION" "curl-$CURL_VERSION-simple"
fi

cd "curl-$CURL_VERSION-simple"

# Try a very basic configure first
log_info "Attempting basic configuration..."

# Set environment for our libraries only
export PKG_CONFIG_PATH="$OPENSSL_DIR/lib/pkgconfig:$ZLIB_DIR/lib/pkgconfig"
export PKG_CONFIG_LIBDIR="$OPENSSL_DIR/lib/pkgconfig:$ZLIB_DIR/lib/pkgconfig"

# Basic configuration that should work
BASIC_CONFIG="--prefix=$INSTALL_DIR"
BASIC_CONFIG="$BASIC_CONFIG --disable-shared --enable-static"
BASIC_CONFIG="$BASIC_CONFIG --with-ssl=$OPENSSL_DIR"
BASIC_CONFIG="$BASIC_CONFIG --with-zlib=$ZLIB_DIR"
BASIC_CONFIG="$BASIC_CONFIG --disable-ldap --disable-ldaps --disable-rtsp"
BASIC_CONFIG="$BASIC_CONFIG --disable-ftp --disable-file --disable-dict"
BASIC_CONFIG="$BASIC_CONFIG --disable-telnet --disable-tftp --disable-pop3"
BASIC_CONFIG="$BASIC_CONFIG --disable-imap --disable-smtp --disable-gopher"
BASIC_CONFIG="$BASIC_CONFIG --without-libssh2 --without-libidn2 --without-nghttp2"

log_info "Configuration: $BASIC_CONFIG"

# Try to configure with cache bypass for runtime check
export ac_cv_host="x86_64-pc-linux-gnu"
export curl_cv_gethostbyname_r_6="yes"
export curl_cv_gethostbyname_r_5="no"
export curl_cv_gethostbyname_r_3="no"

# Set library paths for configure
CPPFLAGS="-I$OPENSSL_DIR/include -I$ZLIB_DIR/include" \
LDFLAGS="-L$OPENSSL_DIR/lib -L$ZLIB_DIR/lib -static" \
LIBS="-lssl -lcrypto -lz" \
LD_LIBRARY_PATH="$OPENSSL_DIR/lib:$ZLIB_DIR/lib" \
./configure $BASIC_CONFIG --cache-file=/dev/null

log_info "Building curl..."
make -j$(nproc)

log_info "Installing curl..."
make install

# Verify build
cd "$BUILD_DIR"

log_info "Verifying build..."
if [ -f "$INSTALL_DIR/lib/libcurl.a" ]; then
    log_info "✓ libcurl.a built successfully"
    ls -la "$INSTALL_DIR/lib/libcurl.a"
else
    log_error "✗ libcurl.a not found"
    # List what was actually built
    find "$INSTALL_DIR" -name "*curl*" -type f || true
    exit 1
fi

if [ -f "$INSTALL_DIR/include/curl/curl.h" ]; then
    log_info "✓ curl headers installed"
else
    log_error "✗ curl headers missing"
    exit 1
fi

log_info "build libcurl (simple) success"
echo "build libcurl (simple) success"
echo "Static library: $INSTALL_DIR/lib/libcurl.a"
echo "Headers: $INSTALL_DIR/include/curl/"

log_info "************************************************************"
echo "************************************************************"
