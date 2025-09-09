#!/bin/bash

# Linux shell script equivalent of build_jsoncpp.bat
# Builds jsoncpp library for OpenSDS SRA

set -e  # Exit on error

echo "************************************************************"
echo "Start building jsoncpp..."
echo "************************************************************"

# Get current directory and set paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="$SCRIPT_DIR/build"
JSONCPP_VERSION="1.9.5"
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
log_info "Start building jsoncpp..."
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
    # Move to source directory with different name to avoid conflicts
    mv "jsoncpp-$JSONCPP_VERSION" "jsoncpp-$JSONCPP_VERSION-src"
fi

cd "jsoncpp-$JSONCPP_VERSION-src"

log_info "build jsoncpp, please wait..."
log_info "Compiling jsoncpp..."

# Create build directory
mkdir -p build
cd build

# Configure with CMake
log_info "Configuring jsoncpp with CMake..."
# Add compiler flags to handle modern GCC strictness
cmake -DCMAKE_INSTALL_PREFIX="$INSTALL_DIR" \
      -DCMAKE_BUILD_TYPE=Release \
      -DJSONCPP_WITH_TESTS=OFF \
      -DJSONCPP_WITH_POST_BUILD_UNITTEST=OFF \
      -DBUILD_SHARED_LIBS=ON \
      -DCMAKE_CXX_FLAGS="-Wno-deprecated-declarations -Wno-implicit-fallthrough" \
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

# Create symlinks from lib64 to lib for compatibility if needed
if [ -d "$INSTALL_DIR/lib64" ] && [ ! -f "$INSTALL_DIR/lib/libjsoncpp.so" ]; then
    log_info "Creating compatibility symlinks from lib64 to lib..."
    ln -sf ../lib64/libjsoncpp.so* "$INSTALL_DIR/lib/" 2>/dev/null || true
    ln -sf ../lib64/libjsoncpp.a "$INSTALL_DIR/lib/" 2>/dev/null || true
fi

# Verify installation - check both lib and lib64 directories
JSONCPP_LIB_FOUND=false
if [ -f "$INSTALL_DIR/lib/libjsoncpp.so" ] || [ -f "$INSTALL_DIR/lib/libjsoncpp.a" ]; then
    log_info "jsoncpp libraries found in $INSTALL_DIR/lib"
    JSONCPP_LIB_FOUND=true
elif [ -f "$INSTALL_DIR/lib64/libjsoncpp.so" ] || [ -f "$INSTALL_DIR/lib64/libjsoncpp.a" ]; then
    log_info "jsoncpp libraries found in $INSTALL_DIR/lib64"
    JSONCPP_LIB_FOUND=true
fi

if [ -d "$INSTALL_DIR/include/json" ]; then
    log_info "jsoncpp headers found in $INSTALL_DIR/include/json"
fi

# Also check for alternative library naming
if [ -f "$INSTALL_DIR/lib/libjson.so" ] || [ -f "$INSTALL_DIR/lib/libjson.a" ] || \
   [ -f "$INSTALL_DIR/lib64/libjson.so" ] || [ -f "$INSTALL_DIR/lib64/libjson.a" ]; then
    log_info "jsoncpp libraries found with alternative naming"
    JSONCPP_LIB_FOUND=true
fi

cd "$BUILD_DIR"

log_info "build jsoncpp end"

# Check for build success
build_failed=false

# Check for libraries in both lib and lib64
if [ "$JSONCPP_LIB_FOUND" = false ]; then
    build_failed=true
fi

# Check for headers
if [ ! -f "$INSTALL_DIR/include/json/json.h" ] && [ ! -f "$INSTALL_DIR/include/jsoncpp/json/json.h" ]; then
    build_failed=true
fi

if [ "$build_failed" = true ]; then
    log_error "build jsoncpp fail"
    echo "build jsoncpp fail"
    exit_code=1
else
    log_info "build jsoncpp success"
    echo "build jsoncpp success"
    
    # List what was actually built
    log_info "jsoncpp libraries built:"
    ls -la "$INSTALL_DIR/lib/" 2>/dev/null | grep -i json || true
    ls -la "$INSTALL_DIR/lib64/" 2>/dev/null | grep -i json || true
    
    exit_code=0
fi

log_info "************************************************************"
echo "************************************************************"

exit $exit_code
