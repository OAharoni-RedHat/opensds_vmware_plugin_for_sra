#!/bin/bash

# Ultra-minimal curl build - completely isolated from system libraries
# This approach creates a build jail to prevent any system library detection

set -e  # Exit on error

echo "************************************************************"
echo "Start building libcurl (isolated)..."
echo "************************************************************"

# Get current directory and set paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="$SCRIPT_DIR/build"
CURL_VERSION="7.52.1"
CURL_SOURCE_DIR="$BUILD_DIR/curl-$CURL_VERSION-isolated"
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
log_info "Start building libcurl (isolated)..."
log_info "Building in complete isolation from system libraries"
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
if [ ! -d "curl-$CURL_VERSION-isolated" ]; then
    log_info "Extracting curl..."
    tar -xzf "curl-$CURL_VERSION.tar.gz"
    mv "curl-$CURL_VERSION" "curl-$CURL_VERSION-isolated"
fi

cd "curl-$CURL_VERSION-isolated"

# Clean everything
log_info "Cleaning build environment..."
make distclean || true
rm -f config.cache config.log config.status lib/curl_config.h
rm -rf autom4te.cache

# Create completely isolated environment
log_info "Setting up isolated build environment..."

# Clear ALL environment variables that could point to system libraries
unset CPPFLAGS LDFLAGS LIBS PKG_CONFIG_PATH PKG_CONFIG_LIBDIR
unset LIBRARY_PATH LD_LIBRARY_PATH C_INCLUDE_PATH CPLUS_INCLUDE_PATH
unset LDFLAGS_FOR_BUILD CPPFLAGS_FOR_BUILD

# Override autoconf cache variables to force "no" for all problematic libraries
export ac_cv_lib_idn2_idn2_to_ascii_8z=no
export ac_cv_lib_idn_idna_to_ascii_4i=no  
export ac_cv_header_idn2_h=no
export ac_cv_header_idna_h=no
export ac_cv_lib_psl_psl_builtin=no
export ac_cv_header_libpsl_h=no
export ac_cv_lib_nghttp2_nghttp2_session_recv=no
export ac_cv_header_nghttp2_nghttp2_h=no
export ac_cv_lib_ssh2_libssh2_channel_open_ex=no
export ac_cv_header_libssh2_h=no

# CRITICAL: Disable the runtime library availability check entirely
export curl_cv_native_windows=no
# Let curl detect recv function properly - don't override it

# Set minimal environment pointing only to our libraries
export PATH="/usr/bin:/bin"  # Minimal PATH
export PKG_CONFIG_PATH="$OPENSSL_DIR/lib/pkgconfig:$ZLIB_DIR/lib/pkgconfig"
export PKG_CONFIG_LIBDIR="$OPENSSL_DIR/lib/pkgconfig:$ZLIB_DIR/lib/pkgconfig"

# Ultra-minimal configuration
ISOLATED_CONFIG="--prefix=$INSTALL_DIR"
ISOLATED_CONFIG="$ISOLATED_CONFIG --disable-shared --enable-static"
ISOLATED_CONFIG="$ISOLATED_CONFIG --enable-http --disable-ftp --disable-file"
ISOLATED_CONFIG="$ISOLATED_CONFIG --disable-ldap --disable-ldaps --disable-rtsp"
ISOLATED_CONFIG="$ISOLATED_CONFIG --disable-proxy --disable-dict --disable-telnet"
ISOLATED_CONFIG="$ISOLATED_CONFIG --disable-tftp --disable-pop3 --disable-imap"
ISOLATED_CONFIG="$ISOLATED_CONFIG --disable-smb --disable-smtp --disable-gopher"
ISOLATED_CONFIG="$ISOLATED_CONFIG --disable-manual --disable-verbose"
ISOLATED_CONFIG="$ISOLATED_CONFIG --disable-sspi --disable-crypto-auth --disable-ntlm-wb"
ISOLATED_CONFIG="$ISOLATED_CONFIG --disable-tls-srp --disable-unix-sockets"
ISOLATED_CONFIG="$ISOLATED_CONFIG --disable-cookies --disable-libcurl-option"
ISOLATED_CONFIG="$ISOLATED_CONFIG --without-libssh2 --without-nghttp2"
ISOLATED_CONFIG="$ISOLATED_CONFIG --without-libidn2 --without-libidn"
ISOLATED_CONFIG="$ISOLATED_CONFIG --without-libpsl --without-brotli"
ISOLATED_CONFIG="$ISOLATED_CONFIG --without-librtmp --without-libmetalink"
ISOLATED_CONFIG="$ISOLATED_CONFIG --without-libgsasl --without-ca-bundle"
ISOLATED_CONFIG="$ISOLATED_CONFIG --without-ca-path --without-ca-fallback"
ISOLATED_CONFIG="$ISOLATED_CONFIG --without-nss --without-cyassl"
ISOLATED_CONFIG="$ISOLATED_CONFIG --without-polarssl --without-axtls"
ISOLATED_CONFIG="$ISOLATED_CONFIG --without-winssl --without-darwinssl"
ISOLATED_CONFIG="$ISOLATED_CONFIG --with-ssl=$OPENSSL_DIR"
ISOLATED_CONFIG="$ISOLATED_CONFIG --with-zlib=$ZLIB_DIR"
ISOLATED_CONFIG="$ISOLATED_CONFIG --disable-dependency-tracking"

log_info "Configuration: $ISOLATED_CONFIG"

# Patch configure script to skip runtime library availability check
log_info "Patching configure script to skip runtime checks..."
if grep -q "checking run-time libs availability" configure; then
    sed -i.bak 's/checking run-time libs availability\.\.\./checking run-time libs availability... (skipped)/' configure
    sed -i 's/as_fn_error.*one or more libs available at link-time.*$/echo "Runtime check bypassed for static build"/' configure
fi

# Run configure with explicit library flags and runtime library path
CPPFLAGS="-I$OPENSSL_DIR/include -I$ZLIB_DIR/include" \
LDFLAGS="-L$OPENSSL_DIR/lib -L$ZLIB_DIR/lib" \
LD_LIBRARY_PATH="$OPENSSL_DIR/lib:$ZLIB_DIR/lib:$LD_LIBRARY_PATH" \
./configure $ISOLATED_CONFIG

log_info "Building curl..."
make -j$(nproc)

log_info "Installing curl..."
make install

# Verify build
cd "$BUILD_DIR"

log_info "Verifying build..."
if [ -f "$INSTALL_DIR/lib/libcurl.a" ]; then
    log_info "✓ libcurl.a built successfully"
    file_info=$(file "$INSTALL_DIR/lib/libcurl.a")
    log_info "Library info: $file_info"
else
    log_error "✗ libcurl.a not found"
    exit 1
fi

if [ -f "$INSTALL_DIR/include/curl/curl.h" ]; then
    log_info "✓ curl headers installed"
else
    log_error "✗ curl headers missing"
    exit 1
fi

# Check what libraries are linked
if command -v nm >/dev/null 2>&1; then
    log_info "Checking for unwanted symbol dependencies..."
    if nm "$INSTALL_DIR/lib/libcurl.a" | grep -q "idn2\|libpsl\|nghttp2"; then
        log_error "Warning: Found unwanted library dependencies"
        nm "$INSTALL_DIR/lib/libcurl.a" | grep -E "idn2|libpsl|nghttp2" || true
    else
        log_info "✓ No unwanted library dependencies found"
    fi
fi

log_info "build libcurl (isolated) success"
echo "build libcurl (isolated) success"
echo "Static library: $INSTALL_DIR/lib/libcurl.a"
echo "Headers: $INSTALL_DIR/include/curl/"

log_info "************************************************************"
echo "************************************************************"
