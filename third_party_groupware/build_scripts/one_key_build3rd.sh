#!/bin/bash

# Linux shell script equivalent of one_key_build3rd.bat
# Master script to build all third-party dependencies for OpenSDS SRA

set -e  # Exit on error

echo "************************************************************"
echo "Start building third-party packages..."
echo "************************************************************"

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Initialize variables
var1=""
var2=""
var3=""
var4=""
var5=""
var6=""

# Log function
log_info() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')][Info] $1" | tee -a build.log
}

log_error() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')][Error] $1" | tee -a build.log
}

# Function to check if build failed
check_build_result() {
    local component="$1"
    local log_pattern="$2"
    
    if grep -q "$log_pattern" build.log 2>/dev/null; then
        log_error "Build $component failed"
        echo "Build third-party packages fail, see log in ./build.log"
        log_error "Build third-party packages fail, see log in ./build.log"
        exit 1
    fi
}

# Make all scripts executable
chmod +x *.sh

log_info "Starting third-party build sequence..."

# Build OpenSSL
echo ""
echo "Step 1/7: Building OpenSSL..."
log_info "Building OpenSSL..."
./build_openssl.sh
check_build_result "OpenSSL" "build openssl fail"

# Build zlib
echo ""
echo "Step 2/7: Building zlib..."
log_info "Building zlib..."
./build_zlib_86.sh
check_build_result "zlib" "build zlib fail"

# Build libssh2
echo ""
echo "Step 3/7: Building libssh2..."
log_info "Building libssh2..."
./build_libssh2.sh
check_build_result "libssh2" "build libssh2 fail"

# Build curl
echo ""
echo "Step 4/7: Building curl..."
log_info "Building curl..."
./build_curl.sh
check_build_result "curl" "build libcurl fail"

# Build ACE
echo ""
echo "Step 5/7: Building ACE..."
log_info "Building ACE..."
./build_ACE.sh
check_build_result "ACE" "build ACE fail"

# Build jsoncpp
echo ""
echo "Step 6/7: Building jsoncpp..."
log_info "Building jsoncpp..."
./build_jsoncpp.sh
check_build_result "jsoncpp" "build jsoncpp fail"

# Setup TinyXML
echo ""
echo "Step 7/7: Setting up TinyXML..."
log_info "Setting up TinyXML..."
./build_tinyxml.sh
log_info "build Tinyxml"

# Success
echo ""
echo "************************************************************"
echo "Build third-party packages success"
echo "************************************************************"
log_info "Build third-party packages success"

echo ""
echo "All third-party dependencies built successfully!"
echo "Build outputs are in: $SCRIPT_DIR/build/"
echo ""
echo "Built components:"
echo "- OpenSSL: $SCRIPT_DIR/build/openssl-1.0.2j/"
echo "- zlib: $SCRIPT_DIR/build/zlib-1.2.11/"
echo "- libssh2: $SCRIPT_DIR/build/libssh2-1.7.0/"
echo "- curl: $SCRIPT_DIR/build/curl-7.52.1/"
echo "- ACE: $SCRIPT_DIR/build/ACE-6.2.4/"
echo "- jsoncpp: $SCRIPT_DIR/build/jsoncpp-0.10.5/"
echo "- TinyXML: copied to source/common/xmlserial/"
echo ""
echo "You can now proceed to build the main SRA executable."
echo ""
