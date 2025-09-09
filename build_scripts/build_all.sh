#!/bin/bash

# OpenSDS SRA Build Script for Linux
# This script automates the entire build process

set -e  # Exit on any error

echo "=========================================="
echo "OpenSDS SRA Linux Build Script"
echo "=========================================="

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
THIRD_PARTY_DIR="$PROJECT_ROOT/third_party_groupware/build_scripts"
SOURCE_DIR="$PROJECT_ROOT/source"

echo "Project root: $PROJECT_ROOT"
echo "Third party dir: $THIRD_PARTY_DIR"
echo "Source dir: $SOURCE_DIR"

# Check prerequisites
echo ""
echo "Checking prerequisites..."
command -v gcc >/dev/null 2>&1 || { echo "ERROR: gcc is required but not installed."; exit 1; }
command -v g++ >/dev/null 2>&1 || { echo "ERROR: g++ is required but not installed."; exit 1; }
command -v cmake >/dev/null 2>&1 || { echo "ERROR: cmake is required but not installed."; exit 1; }
command -v make >/dev/null 2>&1 || { echo "ERROR: make is required but not installed."; exit 1; }
command -v wget >/dev/null 2>&1 || command -v curl >/dev/null 2>&1 || { echo "ERROR: wget or curl is required but not installed."; exit 1; }

echo "✓ All prerequisites found"

# Create build directory
BUILD_ROOT="$THIRD_PARTY_DIR/build"
mkdir -p "$BUILD_ROOT"
cd "$BUILD_ROOT"

# Set environment variables
export THIRD_PARTY_ROOT="$BUILD_ROOT"
export PATH="$THIRD_PARTY_ROOT/bin:$PATH"
export LD_LIBRARY_PATH="$THIRD_PARTY_ROOT/lib:$LD_LIBRARY_PATH"
export PKG_CONFIG_PATH="$THIRD_PARTY_ROOT/lib/pkgconfig:$PKG_CONFIG_PATH"

echo ""
echo "Building third-party dependencies..."

# Function to download file
download_file() {
    local url="$1"
    local filename="$2"
    
    if [ ! -f "$filename" ]; then
        echo "Downloading $filename..."
        if command -v wget >/dev/null 2>&1; then
            wget -O "$filename" "$url"
        else
            curl -L -o "$filename" "$url"
        fi
    else
        echo "✓ $filename already exists"
    fi
}

# Build OpenSSL 1.0.2j
echo ""
echo "Building OpenSSL 1.0.2j..."
if [ ! -d "openssl-1.0.2j" ]; then
    download_file "https://www.openssl.org/source/old/1.0.2/openssl-1.0.2j.tar.gz" "openssl-1.0.2j.tar.gz"
    tar -xzf openssl-1.0.2j.tar.gz
    cd openssl-1.0.2j
    ./config --prefix="$BUILD_ROOT/openssl-1.0.2j" shared no-asm
    make && make install
    cd "$BUILD_ROOT"
else
    echo "✓ OpenSSL already built"
fi

# Build zlib
echo ""
echo "Building zlib..."
if [ ! -d "zlib-1.2.11" ]; then
    download_file "https://zlib.net/fossils/zlib-1.2.11.tar.gz" "zlib-1.2.11.tar.gz"
    tar -xzf zlib-1.2.11.tar.gz
    cd zlib-1.2.11
    ./configure --prefix="$BUILD_ROOT/zlib-1.2.11"
    make && make install
    cd "$BUILD_ROOT"
else
    echo "✓ zlib already built"
fi

# Build libssh2 1.7.0
echo ""
echo "Building libssh2 1.7.0..."
if [ ! -d "libssh2-1.7.0" ]; then
    download_file "https://www.libssh2.org/download/libssh2-1.7.0.tar.gz" "libssh2-1.7.0.tar.gz"
    tar -xzf libssh2-1.7.0.tar.gz
    cd libssh2-1.7.0
    ./configure --prefix="$BUILD_ROOT/libssh2-1.7.0" \
                --with-openssl="$BUILD_ROOT/openssl-1.0.2j" \
                --with-zlib="$BUILD_ROOT/zlib-1.2.11"
    make && make install
    cd "$BUILD_ROOT"
else
    echo "✓ libssh2 already built"
fi

# Build curl 7.52.1
echo ""
echo "Building curl 7.52.1..."
if [ ! -d "curl-7.52.1" ]; then
    download_file "https://curl.se/download/curl-7.52.1.tar.gz" "curl-7.52.1.tar.gz"
    tar -xzf curl-7.52.1.tar.gz
    cd curl-7.52.1
    ./configure --prefix="$BUILD_ROOT/curl-7.52.1" \
                --with-ssl="$BUILD_ROOT/openssl-1.0.2j" \
                --with-zlib="$BUILD_ROOT/zlib-1.2.11" \
                --with-libssh2="$BUILD_ROOT/libssh2-1.7.0"
    make && make install
    cd "$BUILD_ROOT"
else
    echo "✓ curl already built"
fi

# Build jsoncpp 0.10.5
echo ""
echo "Building jsoncpp 0.10.5..."
if [ ! -d "jsoncpp-0.10.5" ]; then
    download_file "https://github.com/open-source-parsers/jsoncpp/archive/0.10.5.tar.gz" "jsoncpp-0.10.5.tar.gz"
    tar -xzf jsoncpp-0.10.5.tar.gz
    cd jsoncpp-0.10.5
    mkdir -p build && cd build
    cmake -DCMAKE_INSTALL_PREFIX="$BUILD_ROOT/jsoncpp-0.10.5" \
          -DCMAKE_BUILD_TYPE=Release \
          -DJSONCPP_WITH_TESTS=OFF \
          -DJSONCPP_WITH_POST_BUILD_UNITTEST=OFF \
          ..
    make && make install
    cd "$BUILD_ROOT"
else
    echo "✓ jsoncpp already built"
fi

# Build ACE 6.2.4
echo ""
echo "Building ACE 6.2.4..."
if [ ! -d "ACE-6.2.4" ]; then
    download_file "http://download.dre.vanderbilt.edu/previous_versions/ACE-6.2.4.tar.gz" "ACE-6.2.4.tar.gz"
    tar -xzf ACE-6.2.4.tar.gz
    cd ACE_wrappers
    export ACE_ROOT="$PWD"
    
    # Configure ACE for Linux
    echo '#include "ace/config-linux.h"' > ace/config.h
    echo 'include $(ACE_ROOT)/include/makeinclude/platform_linux.GNU' > include/makeinclude/platform_macros.GNU
    echo 'ssl=1' >> include/makeinclude/platform_macros.GNU
    echo "PLATFORM_SSL_CPPFLAGS += -I$BUILD_ROOT/openssl-1.0.2j/include" >> include/makeinclude/platform_macros.GNU
    echo "PLATFORM_SSL_LDFLAGS += -L$BUILD_ROOT/openssl-1.0.2j/lib" >> include/makeinclude/platform_macros.GNU
    
    # Build ACE
    make -j$(nproc)
    
    # Install ACE
    mkdir -p "$BUILD_ROOT/ACE-6.2.4/include" "$BUILD_ROOT/ACE-6.2.4/lib"
    cp -r ace "$BUILD_ROOT/ACE-6.2.4/include/"
    cp lib/*.so* "$BUILD_ROOT/ACE-6.2.4/lib/" || true
    cp lib/*.a "$BUILD_ROOT/ACE-6.2.4/lib/" || true
    
    cd "$BUILD_ROOT"
else
    echo "✓ ACE already built"
fi

# Build TinyXML (if not included in source)
echo ""
echo "Setting up TinyXML..."
TINYXML_DIR="$SOURCE_DIR/common/xmlserial"
if [ ! -f "$TINYXML_DIR/tinyxml.cpp" ]; then
    echo "Downloading TinyXML 2.6.2..."
    cd /tmp
    download_file "https://sourceforge.net/projects/tinyxml/files/tinyxml/2.6.2/tinyxml_2_6_2.tar.gz/download" "tinyxml_2_6_2.tar.gz"
    tar -xzf tinyxml_2_6_2.tar.gz
    cp tinyxml/tinyxml.h tinyxml/tinystr.h tinyxml/tinyxml.cpp tinyxml/tinystr.cpp tinyxml/tinyxmlerror.cpp tinyxml/tinyxmlparser.cpp "$TINYXML_DIR/"
    cd "$BUILD_ROOT"
    echo "✓ TinyXML files copied"
else
    echo "✓ TinyXML already present"
fi

echo ""
echo "Building SRA source code..."

# Build securec library
cd "$SOURCE_DIR/securec"
mkdir -p lib
gcc -fPIC -shared -o lib/libsecurec.so memset_s.c
echo "✓ securec library built"

# Build TlvCom library
cd "$SOURCE_DIR/TlvCom"
mkdir -p lib
g++ -fPIC -shared -o lib/libTLVCom.so \
    -I../common/os \
    -I"$BUILD_ROOT/ACE-6.2.4/include" \
    -L"$BUILD_ROOT/ACE-6.2.4/lib" \
    -L"$BUILD_ROOT/openssl-1.0.2j/lib" \
    -lACE -lACE_SSL -lssl -lcrypto \
    msg_package.cpp om_connecter.cpp
echo "✓ TlvCom library built"

# Build main SRA executable
cd "$SOURCE_DIR"
mkdir -p cmake_build && cd cmake_build

echo "Configuring CMake..."
cmake ..

echo "Building SRA executable..."
make -j$(nproc)

if [ -f "../bin/command" ]; then
    echo ""
    echo "=========================================="
    echo "BUILD SUCCESSFUL!"
    echo "=========================================="
    echo "SRA executable: $SOURCE_DIR/bin/command"
    echo ""
    echo "To test the demo:"
    echo "1. cd $PROJECT_ROOT/demo"
    echo "2. cp ../source/bin/command ./sra"
    echo "3. export LD_LIBRARY_PATH=$BUILD_ROOT/ACE-6.2.4/lib:$BUILD_ROOT/openssl-1.0.2j/lib:$BUILD_ROOT/curl-7.52.1/lib:$BUILD_ROOT/libssh2-1.7.0/lib:$SOURCE_DIR/securec/lib:$SOURCE_DIR/TlvCom/lib:\$LD_LIBRARY_PATH"
    echo "4. ./run_demo.sh"
    echo ""
else
    echo ""
    echo "=========================================="
    echo "BUILD FAILED!"
    echo "=========================================="
    echo "Check the output above for errors."
    exit 1
fi
