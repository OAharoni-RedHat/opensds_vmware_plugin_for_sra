#!/bin/bash

# Minimal ACE build - uses latest version with maximum compatibility patches
# For systems with very strict compilers or missing system headers

set -e  # Exit on error

echo "************************************************************"
echo "Start building ACE (minimal/compatibility mode)..."
echo "************************************************************"

# Get current directory and set paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="$SCRIPT_DIR/build"
ACE_VERSION="7.1.0"  # Even newer version
ACE_DIR="$BUILD_DIR/ACE_wrappers"
INSTALL_DIR="$BUILD_DIR/ACE-$ACE_VERSION"

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
log_info "Start building ACE (minimal/compatibility mode)..."
log_info "."
log_info "-------------------compile ACE-------------------"
log_info "."

# Download ACE if not present
if [ ! -f "ACE-$ACE_VERSION.tar.bz2" ]; then
    log_info "Downloading ACE $ACE_VERSION..."
    if command -v wget >/dev/null 2>&1; then
        wget "https://github.com/DOCGroup/ACE_TAO/releases/download/ACE%2BTAO-7_1_0/ACE-$ACE_VERSION.tar.bz2"
    else
        curl -L -o "ACE-$ACE_VERSION.tar.bz2" "https://github.com/DOCGroup/ACE_TAO/releases/download/ACE%2BTAO-7_1_0/ACE-$ACE_VERSION.tar.bz2"
    fi
fi

# Extract and build ACE
if [ ! -d "ACE_wrappers-minimal" ]; then
    log_info "Extracting ACE..."
    tar -xjf "ACE-$ACE_VERSION.tar.bz2"
    mv ACE_wrappers ACE_wrappers-minimal
fi

cd ACE_wrappers-minimal

# Set ACE environment
export ACE_ROOT="$PWD"

log_info "Configuring ACE (minimal mode)..."
# Create config files for Linux with maximum compatibility
cat > ace/config.h << 'EOF'
#include "ace/config-linux.h"
#define ACE_LACKS_STROPTS_H 1
#define ACE_HAS_CPU_SET_T 1
#define ACE_LACKS_STREAMS_ENVIRONMENT 1
#define ACE_LACKS_XTI 1
EOF

echo 'include $(ACE_ROOT)/include/makeinclude/platform_linux.GNU' > include/makeinclude/platform_macros.GNU

# Add maximum compatibility flags and disable all problematic features
cat >> include/makeinclude/platform_macros.GNU << 'EOF'
CPPFLAGS += -Wno-deprecated-declarations -Wno-unused-variable -Wno-implicit-fallthrough -Wno-error -DACE_LACKS_STROPTS_H -DACE_HAS_CPU_SET_T
CCFLAGS += -Wno-deprecated-declarations -Wno-unused-variable -Wno-implicit-fallthrough -Wno-error -w -DACE_LACKS_STROPTS_H -DACE_HAS_CPU_SET_T
ace_no_stropts = 1
ace_with_x11 = 0
ace_no_nameservice = 1
ace_no_tests = 1
ace_no_examples = 1
ace_no_apps = 1
EOF

# Enable SSL support if OpenSSL is available
OPENSSL_DIR="$BUILD_DIR/openssl-1.0.2j"
if [ -d "$OPENSSL_DIR" ]; then
    log_info "Enabling SSL support with OpenSSL from $OPENSSL_DIR"
    echo 'ssl=1' >> include/makeinclude/platform_macros.GNU
    echo "PLATFORM_SSL_CPPFLAGS += -I$OPENSSL_DIR/include" >> include/makeinclude/platform_macros.GNU
    echo "PLATFORM_SSL_LDFLAGS += -L$OPENSSL_DIR/lib" >> include/makeinclude/platform_macros.GNU
fi

log_info "Patching ACE source files (aggressive)..."
# Aggressively patch problematic header files
if [ -f "ace/os_include/os_stropts.h" ]; then
    # Completely disable stropts.h inclusion
    sed -i 's/#  include \/\*\*\/ <stropts.h>/\/\* stropts.h disabled for modern Linux \*\//' ace/os_include/os_stropts.h
fi

if [ -f "ace/os_include/os_sched.h" ]; then
    # Remove conflicting cpu_set_t definition
    sed -i '/struct cpu_set_t/,/} cpu_set_t;/d' ace/os_include/os_sched.h
fi

# Patch Name Service related files that use stropts
for file in ace/Name_*.cpp; do
    if [ -f "$file" ]; then
        sed -i 's/#include "ace\/OS_NS_stropts.h"/\/\* stropts disabled \*\//' "$file"
    fi
done

log_info "Compiling ACE (minimal)..."
echo "build ACE (minimal), please wait..."

# Build only essential ACE components
cd ace
make -j$(nproc) || {
    log_info "Parallel build failed, trying single thread..."
    make clean
    make || {
        log_info "Core build also failed, trying with minimal targets..."
        make libACE.so || make libACE.a
    }
}
cd ..

log_info "Copying compiled files..."
# Create installation directory structure
mkdir -p "$INSTALL_DIR/include"
mkdir -p "$INSTALL_DIR/lib"

# Copy headers
cp -r ace "$INSTALL_DIR/include/"

# Copy libraries
if [ -d "lib" ]; then
    cp lib/*.so* "$INSTALL_DIR/lib/" 2>/dev/null || true
    cp lib/*.a "$INSTALL_DIR/lib/" 2>/dev/null || true
fi

# Also check for libraries in ace directory
if [ -d "ace/.libs" ]; then
    cp ace/.libs/*.so* "$INSTALL_DIR/lib/" 2>/dev/null || true
    cp ace/.libs/*.a "$INSTALL_DIR/lib/" 2>/dev/null || true
fi

# Clean up headers (remove build files)
log_info "Removing temp files..."
find "$INSTALL_DIR/include/ace" -name "*.sln" -delete 2>/dev/null || true
find "$INSTALL_DIR/include/ace" -name "*.vcxproj*" -delete 2>/dev/null || true
find "$INSTALL_DIR/include/ace" -name "*.opensdf" -delete 2>/dev/null || true

cd "$BUILD_DIR"

log_info "Build ACE (minimal) end"

# Check for build success
build_failed=false
if [ ! -f "$INSTALL_DIR/lib/libACE.so" ] && [ ! -f "$INSTALL_DIR/lib/libACE.a" ]; then
    log_info "Warning: libACE not found, checking for alternative names..."
    # Check for other possible ACE library names
    if ! ls "$INSTALL_DIR/lib/"*ACE* >/dev/null 2>&1; then
        build_failed=true
    fi
fi

if [ "$build_failed" = true ]; then
    log_error "Build ACE (minimal) fail"
    echo "build ACE (minimal) fail"
    exit_code=1
else
    log_info "Build ACE (minimal) success"
    echo "build ACE (minimal) success"
    
    # List what was actually built
    log_info "ACE libraries built:"
    ls -la "$INSTALL_DIR/lib/" | grep -i ace || true
    
    exit_code=0
fi

log_info "************************************************************"
echo "************************************************************"

exit $exit_code
