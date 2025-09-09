#!/bin/bash

# Build script for TlvCom library with proper ACE integration

set -e

echo "************************************************************"
echo "Building TlvCom library..."
echo "************************************************************"

# Get current directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Create lib directory
mkdir -p lib

# Find ACE installation
ACE_INCLUDE_DIR=""
ACE_LIB_DIR=""

# Check for different ACE versions in build directory
for ace_version in 7.0.11 7.1.0 6.2.4; do
    ace_path="../../third_party_groupware/build_scripts/build/ACE-$ace_version"
    if [ -d "$ace_path/include" ] && [ -f "$ace_path/include/ace/OS.h" ]; then
        ACE_INCLUDE_DIR="$ace_path/include"
        ACE_LIB_DIR="$ace_path/lib"
        echo "Found ACE $ace_version at: $ace_path"
        break
    fi
done

# If not found in standard location, check ACE_wrappers directories
if [ -z "$ACE_INCLUDE_DIR" ]; then
    for ace_dir in ../../third_party_groupware/build_scripts/build/ACE_wrappers*; do
        if [ -d "$ace_dir" ] && [ -f "$ace_dir/ace/OS.h" ]; then
            ACE_INCLUDE_DIR="$ace_dir"
            ACE_LIB_DIR="$ace_dir/ace"
            echo "Found ACE in source directory: $ace_dir"
            break
        fi
    done
fi

if [ -z "$ACE_INCLUDE_DIR" ]; then
    echo "Error: ACE headers not found!"
    echo "Please ensure ACE is built first using one of:"
    echo "  ./build_ACE.sh"
    echo "  ./build_ACE_minimal.sh" 
    echo "  ./build_ACE_core.sh"
    exit 1
fi

echo "Using ACE headers from: $ACE_INCLUDE_DIR"
echo "Using ACE libraries from: $ACE_LIB_DIR"

# Check if ACE SSL is available
ACE_SSL_AVAILABLE=false
if [ -f "$ACE_INCLUDE_DIR/ace/SSL/SSL_SOCK_Connector.h" ]; then
    ACE_SSL_AVAILABLE=true
    echo "ACE SSL support detected"
else
    echo "ACE SSL not available - building without SSL support"
fi

# Compile flags
CPPFLAGS="-fPIC -O2 -Wall -Wno-deprecated-declarations"
INCLUDES="-I../common/os -I$ACE_INCLUDE_DIR"
DEFINES=""

# Add SSL support if available
if [ "$ACE_SSL_AVAILABLE" = true ]; then
    DEFINES="$DEFINES -DACE_HAS_SSL=1"
else
    DEFINES="$DEFINES -DACE_LACKS_SSL=1"
fi

# Check if om_connecter.cpp needs SSL and disable it if not available
if [ "$ACE_SSL_AVAILABLE" = false ]; then
    if grep -q "SSL_SOCK_Connector" om_connecter.cpp; then
        echo "Warning: om_connecter.cpp requires SSL but ACE SSL not available"
        echo "Creating SSL-disabled version..."
        
        # Create a modified version without SSL
        sed 's/#include <ace\/SSL\/SSL_SOCK_Connector.h>/\/\* SSL disabled \*\//' om_connecter.cpp > om_connecter_no_ssl.cpp
        sed -i 's/SSL_SOCK_Connector/SOCK_Connector/g' om_connecter_no_ssl.cpp
        sed -i 's/ACE_SSL_/ACE_/g' om_connecter_no_ssl.cpp
        
        CONNECTER_FILE="om_connecter_no_ssl.cpp"
    else
        CONNECTER_FILE="om_connecter.cpp"
    fi
else
    CONNECTER_FILE="om_connecter.cpp"
fi

echo "Building TlvCom library..."
echo "Compile command:"
echo "g++ -shared $CPPFLAGS $INCLUDES $DEFINES -o lib/libTLVCom.so msg_package.cpp $CONNECTER_FILE"

# Build the library
if g++ -shared $CPPFLAGS $INCLUDES $DEFINES -o lib/libTLVCom.so msg_package.cpp "$CONNECTER_FILE"; then
    echo "TlvCom library built successfully!"
    
    # Verify the library
    if [ -f "lib/libTLVCom.so" ]; then
        echo "Library verification:"
        ls -la lib/libTLVCom.so
        file lib/libTLVCom.so
        
        # Check dependencies
        echo "Library dependencies:"
        ldd lib/libTLVCom.so || echo "ldd not available"
        
        echo "TlvCom build completed successfully!"
        exit 0
    else
        echo "Error: libTLVCom.so was not created"
        exit 1
    fi
else
    echo "Error: Failed to compile TlvCom library"
    echo ""
    echo "Troubleshooting steps:"
    echo "1. Ensure ACE is properly built"
    echo "2. Check ACE headers are accessible: ls $ACE_INCLUDE_DIR/ace/OS.h"
    echo "3. Try building ACE with SSL support if needed"
    echo "4. Check compiler error messages above"
    exit 1
fi
