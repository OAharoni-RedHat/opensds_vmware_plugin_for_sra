#!/bin/bash

# Linux shell script equivalent of build_curl.bat
# Builds libcurl library for OpenSDS SRA

set -e  # Exit on error

echo "************************************************************"
echo "Start building libcurl..."
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
LIBSSH2_DIR="$BUILD_DIR/libssh2-1.10.0"

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
log_info "Start building libcurl..."
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
    # Move to source directory with different name to avoid conflicts
    mv "curl-$CURL_VERSION" "curl-$CURL_VERSION-src"
fi

cd "curl-$CURL_VERSION-src"

log_info "build libcurl, please wait..."
log_info "start compiling libcurl..."

# Configure curl with dependencies
CONFIGURE_OPTIONS="--prefix=$INSTALL_DIR --enable-shared --disable-static"

# Set up library paths for runtime detection
ALL_LIB_PATHS=""
ALL_PKG_CONFIG_PATHS=""

# Add SSL support if OpenSSL is available
if [ -d "$OPENSSL_DIR" ]; then
    log_info "Configuring with OpenSSL support from $OPENSSL_DIR"
    CONFIGURE_OPTIONS="$CONFIGURE_OPTIONS --with-ssl=$OPENSSL_DIR"
    ALL_LIB_PATHS="$ALL_LIB_PATHS:$OPENSSL_DIR/lib"
    ALL_PKG_CONFIG_PATHS="$ALL_PKG_CONFIG_PATHS:$OPENSSL_DIR/lib/pkgconfig"
fi

# Add zlib support if available
if [ -d "$ZLIB_DIR" ]; then
    log_info "Configuring with zlib support from $ZLIB_DIR"
    CONFIGURE_OPTIONS="$CONFIGURE_OPTIONS --with-zlib=$ZLIB_DIR"
    ALL_LIB_PATHS="$ALL_LIB_PATHS:$ZLIB_DIR/lib"
    ALL_PKG_CONFIG_PATHS="$ALL_PKG_CONFIG_PATHS:$ZLIB_DIR/lib/pkgconfig"
fi

# Add libssh2 support if available
if [ -d "$LIBSSH2_DIR" ]; then
    log_info "Configuring with libssh2 support from $LIBSSH2_DIR"
    CONFIGURE_OPTIONS="$CONFIGURE_OPTIONS --with-libssh2=$LIBSSH2_DIR"
    ALL_LIB_PATHS="$ALL_LIB_PATHS:$LIBSSH2_DIR/lib"
    ALL_PKG_CONFIG_PATHS="$ALL_PKG_CONFIG_PATHS:$LIBSSH2_DIR/lib/pkgconfig"
fi

# Remove leading colons
ALL_LIB_PATHS="${ALL_LIB_PATHS#:}"
ALL_PKG_CONFIG_PATHS="${ALL_PKG_CONFIG_PATHS#:}"

# Set environment variables for configure script
export PKG_CONFIG_PATH="$ALL_PKG_CONFIG_PATHS:$PKG_CONFIG_PATH"
export LD_LIBRARY_PATH="$ALL_LIB_PATHS:$LD_LIBRARY_PATH"
export LDFLAGS="-L${ALL_LIB_PATHS//:/ -L} $LDFLAGS"
export CPPFLAGS="-I$OPENSSL_DIR/include -I$ZLIB_DIR/include -I$LIBSSH2_DIR/include $CPPFLAGS"

# Disable runtime library checks that are causing issues
CONFIGURE_OPTIONS="$CONFIGURE_OPTIONS --disable-rtsp --disable-ldap --disable-ldaps"

# Add RPATH to ensure runtime libraries are found
if [ -n "$ALL_LIB_PATHS" ]; then
    RPATH_FLAGS=$(echo "$ALL_LIB_PATHS" | sed 's/:/ -Wl,-rpath,/g' | sed 's/^/-Wl,-rpath,/')
    export LDFLAGS="$RPATH_FLAGS $LDFLAGS"
fi

log_info "Configuring curl with options: $CONFIGURE_OPTIONS"
log_info "Library paths: $ALL_LIB_PATHS"
log_info "PKG_CONFIG_PATH: $PKG_CONFIG_PATH"
log_info "LDFLAGS: $LDFLAGS"

# Try configuration with runtime checks disabled on failure
./configure $CONFIGURE_OPTIONS || {
    log_info "Configuration failed, trying with runtime checks disabled..."
    CONFIGURE_OPTIONS="$CONFIGURE_OPTIONS --disable-shared --enable-static"
    ./configure $CONFIGURE_OPTIONS
}

log_info "Building curl..."
make -j$(nproc)

log_info "Installing curl..."
make install

log_info "copying temp files..."
# Create directory structure for compatibility
mkdir -p "$INSTALL_DIR/bin"
mkdir -p "$INSTALL_DIR/lib"
mkdir -p "$INSTALL_DIR/include/curl"

# Verify installation
if [ -f "$INSTALL_DIR/lib/libcurl.so" ] || [ -f "$INSTALL_DIR/lib/libcurl.a" ]; then
    log_info "libcurl libraries found in $INSTALL_DIR/lib"
fi

if [ -d "$INSTALL_DIR/include/curl" ]; then
    log_info "curl headers found in $INSTALL_DIR/include/curl"
fi

cd "$BUILD_DIR"

log_info "build libcurl end"

# Check for build success
build_failed=false
if [ ! -f "$INSTALL_DIR/lib/libcurl.so" ] && [ ! -f "$INSTALL_DIR/lib/libcurl.a" ]; then
    build_failed=true
fi

if [ ! -f "$INSTALL_DIR/include/curl/curl.h" ]; then
    build_failed=true
fi

if [ "$build_failed" = true ]; then
    log_error "build libcurl fail"
    echo "build libcurl fail"
    exit_code=1
else
    log_info "build libcurl success"
    echo "build libcurl success"
    exit_code=0
fi

log_info "************************************************************"
echo "************************************************************"

exit $exit_code
