#!/bin/bash

# Debug script to understand curl build environment issues

echo "=== CURL BUILD ENVIRONMENT DEBUG ==="

echo "System information:"
uname -a
echo

echo "Installed packages that might interfere:"
rpm -qa | grep -E "(idn|psl|nghttp|curl)" | sort
echo

echo "Library paths:"
echo "LD_LIBRARY_PATH: $LD_LIBRARY_PATH"
echo "LIBRARY_PATH: $LIBRARY_PATH"
echo "PKG_CONFIG_PATH: $PKG_CONFIG_PATH"
echo "PKG_CONFIG_LIBDIR: $PKG_CONFIG_LIBDIR"
echo

echo "Standard library locations:"
ls -la /usr/lib64/lib{idn,psl,nghttp}* 2>/dev/null || echo "No problematic libs in /usr/lib64"
ls -la /usr/lib/lib{idn,psl,nghttp}* 2>/dev/null || echo "No problematic libs in /usr/lib"
echo

echo "Headers in standard locations:"
ls -la /usr/include/idn* /usr/include/libpsl.h /usr/include/nghttp2/ 2>/dev/null || echo "No problematic headers"
echo

echo "pkg-config files:"
find /usr -name "*.pc" 2>/dev/null | grep -E "(idn|psl|nghttp)" || echo "No problematic .pc files found"
echo

BUILD_DIR="$(dirname "$0")/build"
if [ -d "$BUILD_DIR" ]; then
    echo "Our dependencies:"
    echo "OpenSSL:"
    ls -la "$BUILD_DIR/openssl-1.0.2j/lib/"*.{so,a} 2>/dev/null || echo "No OpenSSL libs found"
    echo "Zlib:"
    ls -la "$BUILD_DIR/zlib-1.2.11/lib/"*.{so,a} 2>/dev/null || echo "No zlib libs found"
    echo "LibSSH2:"
    ls -la "$BUILD_DIR/libssh2-1.10.0/lib/"*.{so,a} 2>/dev/null || echo "No libssh2 libs found"
fi

echo "=== END DEBUG ==="
