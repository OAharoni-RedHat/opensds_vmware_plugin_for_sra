#!/bin/bash

# Linux shell script equivalent of build_zlib_86.bat
# Builds zlib library for OpenSDS SRA

set -e  # Exit on error

echo "************************************************************"
echo "Start building zlib..."
echo "************************************************************"

# Get current directory and set paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="$SCRIPT_DIR/build"
ZLIB_VERSION="1.2.11"
ZLIB_SOURCE_DIR="$BUILD_DIR/zlib-$ZLIB_VERSION-src"
INSTALL_DIR="$BUILD_DIR/zlib-$ZLIB_VERSION"

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
log_info "Start building zlib..."
log_info "."
log_info "-------------------compile zlib-------------------"
log_info "."

# Download zlib if not present
if [ ! -f "zlib-$ZLIB_VERSION.tar.gz" ]; then
    log_info "Downloading zlib $ZLIB_VERSION..."
    if command -v wget >/dev/null 2>&1; then
        wget "https://zlib.net/fossils/zlib-$ZLIB_VERSION.tar.gz"
    else
        curl -L -o "zlib-$ZLIB_VERSION.tar.gz" "https://zlib.net/fossils/zlib-$ZLIB_VERSION.tar.gz"
    fi
fi

# Extract and build zlib
if [ ! -d "zlib-$ZLIB_VERSION-src" ]; then
    log_info "Extracting zlib..."
    tar -xzf "zlib-$ZLIB_VERSION.tar.gz"
    # Move to source directory with different name to avoid conflicts
    mv "zlib-$ZLIB_VERSION" "zlib-$ZLIB_VERSION-src"
fi

cd "zlib-$ZLIB_VERSION-src"

log_info "Configuring zlib..."
./configure --prefix="$INSTALL_DIR" --shared

log_info "Building zlib..."
make -j$(nproc)

log_info "Installing zlib..."
make install

# Create directory structure for compatibility
mkdir -p "$INSTALL_DIR/include"
mkdir -p "$INSTALL_DIR/lib"

# Copy headers and libraries
log_info "Copying compiled zlib files..."
cp zlib.h zconf.h "$INSTALL_DIR/include/"
cp libz.so* "$INSTALL_DIR/lib/" 2>/dev/null || true
cp libz.a "$INSTALL_DIR/lib/" 2>/dev/null || true

cd "$BUILD_DIR"

log_info "Build zlib end"

# Check for build success
if [ -f "$INSTALL_DIR/lib/libz.so" ] || [ -f "$INSTALL_DIR/lib/libz.a" ]; then
    log_info "Build zlib success"
    echo "build zlib success"
    exit_code=0
else
    log_error "Build zlib fail"
    echo "build zlib fail"
    exit_code=1
fi

log_info "************************************************************"
echo "************************************************************"

exit $exit_code
