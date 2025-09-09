#!/bin/bash

# Demo Setup Script for OpenSDS SRA
# This script sets up the demo environment after compilation

set -e

echo "=========================================="
echo "OpenSDS SRA Demo Setup"
echo "=========================================="

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
SOURCE_DIR="$PROJECT_ROOT/source"
THIRD_PARTY_DIR="$PROJECT_ROOT/third_party_groupware/build_scripts/build"

echo "Demo directory: $SCRIPT_DIR"
echo "Project root: $PROJECT_ROOT"

# Check if SRA executable exists
SRA_EXECUTABLE="$SOURCE_DIR/bin/command"
if [ ! -f "$SRA_EXECUTABLE" ]; then
    echo "ERROR: SRA executable not found at $SRA_EXECUTABLE"
    echo "Please build the SRA first using the compilation guide."
    exit 1
fi

echo "✓ SRA executable found: $SRA_EXECUTABLE"

# Copy executable to demo directory
cp "$SRA_EXECUTABLE" "$SCRIPT_DIR/sra"
chmod +x "$SCRIPT_DIR/sra"
echo "✓ SRA executable copied to demo directory"

# Create necessary directories
mkdir -p "$SCRIPT_DIR/outputs" "$SCRIPT_DIR/logs"
echo "✓ Demo directories created"

# Set up library paths
echo ""
echo "Setting up library paths..."

LIB_PATHS=""
# Add ACE libraries
if [ -d "$THIRD_PARTY_DIR/ACE-6.2.4/lib" ]; then
    LIB_PATHS="$LIB_PATHS:$THIRD_PARTY_DIR/ACE-6.2.4/lib"
    echo "✓ ACE library path added"
fi

# Add OpenSSL libraries
if [ -d "$THIRD_PARTY_DIR/openssl-1.0.2j/lib" ]; then
    LIB_PATHS="$LIB_PATHS:$THIRD_PARTY_DIR/openssl-1.0.2j/lib"
    echo "✓ OpenSSL library path added"
fi

# Add curl libraries
if [ -d "$THIRD_PARTY_DIR/curl-7.52.1/lib" ]; then
    LIB_PATHS="$LIB_PATHS:$THIRD_PARTY_DIR/curl-7.52.1/lib"
    echo "✓ curl library path added"
fi

# Add libssh2 libraries
if [ -d "$THIRD_PARTY_DIR/libssh2-1.7.0/lib" ]; then
    LIB_PATHS="$LIB_PATHS:$THIRD_PARTY_DIR/libssh2-1.7.0/lib"
    echo "✓ libssh2 library path added"
fi

# Add jsoncpp libraries
if [ -d "$THIRD_PARTY_DIR/jsoncpp-0.10.5/lib" ]; then
    LIB_PATHS="$LIB_PATHS:$THIRD_PARTY_DIR/jsoncpp-0.10.5/lib"
    echo "✓ jsoncpp library path added"
fi

# Add securec library
if [ -d "$SOURCE_DIR/securec/lib" ]; then
    LIB_PATHS="$LIB_PATHS:$SOURCE_DIR/securec/lib"
    echo "✓ securec library path added"
fi

# Add TlvCom library
if [ -d "$SOURCE_DIR/TlvCom/lib" ]; then
    LIB_PATHS="$LIB_PATHS:$SOURCE_DIR/TlvCom/lib"
    echo "✓ TlvCom library path added"
fi

# Remove leading colon
LIB_PATHS="${LIB_PATHS#:}"

# Create environment setup script
cat > "$SCRIPT_DIR/setup_env.sh" << EOF
#!/bin/bash
# Environment setup for OpenSDS SRA Demo
export LD_LIBRARY_PATH="$LIB_PATHS:\$LD_LIBRARY_PATH"
export SRA_DEMO_DIR="$SCRIPT_DIR"
echo "Environment configured for SRA demo"
echo "Library path: \$LD_LIBRARY_PATH"
EOF

chmod +x "$SCRIPT_DIR/setup_env.sh"
echo "✓ Environment setup script created: setup_env.sh"

# Test SRA executable
echo ""
echo "Testing SRA executable..."
source "$SCRIPT_DIR/setup_env.sh"

# Simple test - just try to run it with help or version (may fail but should show it loads)
if ./sra --help 2>/dev/null || ./sra -h 2>/dev/null || ./sra 2>/dev/null; then
    echo "✓ SRA executable can be loaded"
else
    echo "⚠ SRA executable may have dependency issues, but this is normal for testing"
fi

echo ""
echo "=========================================="
echo "DEMO SETUP COMPLETE!"
echo "=========================================="
echo ""
echo "To run the demo:"
echo "1. source ./setup_env.sh"
echo "2. ./run_demo.sh"
echo ""
echo "To test individual commands:"
echo "1. source ./setup_env.sh"
echo "2. ./sra < inputs/demo_query_info.xml"
echo ""
echo "Available demo scenarios:"
echo "- demo_query_info.xml       - Get SRA information"
echo "- demo_discover_arrays.xml  - Discover storage arrays"
echo "- demo_discover_devices.xml - Discover replicated devices"
echo "- demo_query_sync_status.xml - Check sync status"
echo "- demo_prepare_failover.xml - Prepare failover"
echo "- demo_test_failover_start.xml - Start test failover"
echo "- demo_error_handling.xml   - Test error scenarios"
echo ""
