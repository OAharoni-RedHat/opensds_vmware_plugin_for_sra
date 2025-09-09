#!/bin/bash

# Minimal curl build script - avoids runtime library detection issues
# This builds only what's needed for the SRA without problematic system libraries

set -e  # Exit on error

echo "************************************************************"
echo "Start building libcurl (minimal)..."
echo "************************************************************"

# Get current directory and set paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="$SCRIPT_DIR/build"
CURL_VERSION="7.52.1"
CURL_SOURCE_DIR="$BUILD_DIR/curl-$CURL_VERSION-src"
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
log_info "Start building libcurl (minimal)..."
log_info "."
log_info "-------------------compile libcurl-------------------"
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

# Extract and build curl
if [ ! -d "curl-$CURL_VERSION-src" ]; then
    log_info "Extracting curl..."
    tar -xzf "curl-$CURL_VERSION.tar.gz"
    mv "curl-$CURL_VERSION" "curl-$CURL_VERSION-src"
fi

cd "curl-$CURL_VERSION-src"

# Clean any previous build
log_info "Cleaning previous build..."
make clean || true
rm -f config.cache config.log config.status

log_info "Configuring minimal curl build..."

# Set up environment to use only our libraries
export PKG_CONFIG_PATH="$OPENSSL_DIR/lib/pkgconfig:$ZLIB_DIR/lib/pkgconfig"
export LD_LIBRARY_PATH="$OPENSSL_DIR/lib:$ZLIB_DIR/lib"
export CPPFLAGS="-I$OPENSSL_DIR/include -I$ZLIB_DIR/include"
export LDFLAGS="-L$OPENSSL_DIR/lib -L$ZLIB_DIR/lib -Wl,-rpath,$OPENSSL_DIR/lib -Wl,-rpath,$ZLIB_DIR/lib"

# Minimal configuration - only HTTPS support, no problematic libraries
MINIMAL_CONFIG="--prefix=$INSTALL_DIR"
MINIMAL_CONFIG="$MINIMAL_CONFIG --enable-http --enable-https --disable-ftp --disable-file"
MINIMAL_CONFIG="$MINIMAL_CONFIG --disable-ldap --disable-ldaps --disable-rtsp --disable-proxy"
MINIMAL_CONFIG="$MINIMAL_CONFIG --disable-dict --disable-telnet --disable-tftp --disable-pop3"
MINIMAL_CONFIG="$MINIMAL_CONFIG --disable-imap --disable-smb --disable-smtp --disable-gopher"
MINIMAL_CONFIG="$MINIMAL_CONFIG --disable-manual --disable-libcurl-option --disable-sspi"
MINIMAL_CONFIG="$MINIMAL_CONFIG --without-libssh2 --without-nghttp2 --without-libidn2"
MINIMAL_CONFIG="$MINIMAL_CONFIG --without-libpsl --without-brotli --without-librtmp"
MINIMAL_CONFIG="$MINIMAL_CONFIG --without-libmetalink --without-libgsasl"
MINIMAL_CONFIG="$MINIMAL_CONFIG --with-ssl=$OPENSSL_DIR --with-zlib=$ZLIB_DIR"
MINIMAL_CONFIG="$MINIMAL_CONFIG --enable-static --disable-shared"
MINIMAL_CONFIG="$MINIMAL_CONFIG --disable-dependency-tracking"

log_info "Configuration options: $MINIMAL_CONFIG"

./configure $MINIMAL_CONFIG

log_info "Building curl..."
make -j$(nproc)

log_info "Installing curl..."
make install

# Verify installation
if [ -f "$INSTALL_DIR/lib/libcurl.a" ]; then
    log_info "✓ Static libcurl.a built successfully"
fi

if [ -f "$INSTALL_DIR/bin/curl" ]; then
    log_info "✓ curl binary built successfully"
fi

if [ -f "$INSTALL_DIR/include/curl/curl.h" ]; then
    log_info "✓ curl headers installed successfully"
fi

cd "$BUILD_DIR"

log_info "build libcurl (minimal) end"

# Check for build success
if [ -f "$INSTALL_DIR/lib/libcurl.a" ] && [ -f "$INSTALL_DIR/include/curl/curl.h" ]; then
    log_info "build libcurl (minimal) success"
    echo "build libcurl (minimal) success"
    echo "Static library: $INSTALL_DIR/lib/libcurl.a"
    echo "Headers: $INSTALL_DIR/include/curl/"
    exit_code=0
else
    log_error "build libcurl (minimal) fail"
    echo "build libcurl (minimal) fail"
    exit_code=1
fi

log_info "************************************************************"
echo "************************************************************"

exit $exit_code
