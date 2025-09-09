#!/bin/bash

# Compatibility jsoncpp build - uses latest version with maximum compatibility flags
# For systems with very strict compilers

set -e  # Exit on error

echo "************************************************************"
echo "Start building jsoncpp (compatibility mode)..."
echo "************************************************************"

# Get current directory and set paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="$SCRIPT_DIR/build"
JSONCPP_VERSION="1.9.6"  # Even newer version
JSONCPP_SOURCE_DIR="$BUILD_DIR/jsoncpp-$JSONCPP_VERSION-src"
INSTALL_DIR="$BUILD_DIR/jsoncpp-$JSONCPP_VERSION"

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
log_info "Start building jsoncpp (compatibility mode)..."
log_info "."
log_info "-------------------compile jsoncpp-------------------"
log_info "."

# Download jsoncpp if not present
if [ ! -f "jsoncpp-$JSONCPP_VERSION.tar.gz" ]; then
    log_info "Downloading jsoncpp $JSONCPP_VERSION..."
    if command -v wget >/dev/null 2>&1; then
        wget -O "jsoncpp-$JSONCPP_VERSION.tar.gz" "https://github.com/open-source-parsers/jsoncpp/archive/$JSONCPP_VERSION.tar.gz"
    else
        curl -L -o "jsoncpp-$JSONCPP_VERSION.tar.gz" "https://github.com/open-source-parsers/jsoncpp/archive/$JSONCPP_VERSION.tar.gz"
    fi
fi

# Extract and build jsoncpp
if [ ! -d "jsoncpp-$JSONCPP_VERSION-src" ]; then
    log_info "Extracting jsoncpp..."
    tar -xzf "jsoncpp-$JSONCPP_VERSION.tar.gz"
    mv "jsoncpp-$JSONCPP_VERSION" "jsoncpp-$JSONCPP_VERSION-src"
fi

cd "jsoncpp-$JSONCPP_VERSION-src"

log_info "build jsoncpp (compatibility), please wait..."
log_info "Compiling jsoncpp with maximum compatibility..."

# Create build directory
mkdir -p build
cd build

# Configure with maximum compatibility flags
log_info "Configuring jsoncpp with CMake (compatibility mode)..."
cmake -DCMAKE_INSTALL_PREFIX="$INSTALL_DIR" \
      -DCMAKE_BUILD_TYPE=Release \
      -DJSONCPP_WITH_TESTS=OFF \
      -DJSONCPP_WITH_POST_BUILD_UNITTEST=OFF \
      -DBUILD_SHARED_LIBS=ON \
      -DCMAKE_CXX_STANDARD=11 \
      -DCMAKE_CXX_FLAGS="-Wno-deprecated-declarations -Wno-implicit-fallthrough -Wno-error -w" \
      -DCMAKE_C_FLAGS="-Wno-error -w" \
      ..

log_info "Building jsoncpp..."
make -j$(nproc)

log_info "Installing jsoncpp..."
make install

log_info "Copying compiled files..."
# Create directory structure for compatibility
mkdir -p "$INSTALL_DIR/bin"
mkdir -p "$INSTALL_DIR/lib"
mkdir -p "$INSTALL_DIR/include/json"

cd "$BUILD_DIR"

log_info "build jsoncpp (compatibility) end"

# Check for build success
build_failed=false
if [ ! -f "$INSTALL_DIR/lib/libjsoncpp.so" ] && [ ! -f "$INSTALL_DIR/lib/libjsoncpp.a" ] && \
   [ ! -f "$INSTALL_DIR/lib/libjson.so" ] && [ ! -f "$INSTALL_DIR/lib/libjson.a" ]; then
    build_failed=true
fi

# Check for headers
if [ ! -f "$INSTALL_DIR/include/json/json.h" ] && [ ! -f "$INSTALL_DIR/include/jsoncpp/json/json.h" ]; then
    build_failed=true
fi

if [ "$build_failed" = true ]; then
    log_error "build jsoncpp (compatibility) fail"
    echo "build jsoncpp (compatibility) fail"
    exit_code=1
else
    log_info "build jsoncpp (compatibility) success"
    echo "build jsoncpp (compatibility) success"
    
    # List what was actually built
    log_info "jsoncpp libraries built:"
    ls -la "$INSTALL_DIR/lib/" | grep -i json || true
    
    exit_code=0
fi

log_info "************************************************************"
echo "************************************************************"

exit $exit_code
