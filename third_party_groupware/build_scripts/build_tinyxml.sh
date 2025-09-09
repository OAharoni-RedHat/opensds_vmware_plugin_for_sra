#!/bin/bash

# Linux shell script equivalent of build_tinyxml.bat
# Downloads and copies TinyXML files for OpenSDS SRA

set -e  # Exit on error

echo "************************************************************"
echo "Setting up TinyXML..."
echo "************************************************************"

# Get current directory and set paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="$SCRIPT_DIR/build"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"
TINYXML_DEST_DIR="$PROJECT_ROOT/source/common/xmlserial"
TINYXML_VERSION="2.6.2"

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
log_info "Setting up TinyXML..."
log_info "."
log_info "-------------------download and copy TinyXML-------------------"
log_info "."

# Check if destination directory exists
if [ ! -d "$TINYXML_DEST_DIR" ]; then
    log_error "Destination directory does not exist: $TINYXML_DEST_DIR"
    echo "ERROR: TinyXML destination directory not found"
    exit 1
fi

# Download TinyXML if not present
if [ ! -f "tinyxml_2_6_2.tar.gz" ]; then
    log_info "Downloading TinyXML $TINYXML_VERSION..."
    if command -v wget >/dev/null 2>&1; then
        wget -O "tinyxml_2_6_2.tar.gz" "https://sourceforge.net/projects/tinyxml/files/tinyxml/2.6.2/tinyxml_2_6_2.tar.gz/download"
    else
        curl -L -o "tinyxml_2_6_2.tar.gz" "https://sourceforge.net/projects/tinyxml/files/tinyxml/2.6.2/tinyxml_2_6_2.tar.gz/download"
    fi
fi

# Extract TinyXML if not already extracted
if [ ! -d "tinyxml" ]; then
    log_info "Extracting TinyXML..."
    tar -xzf "tinyxml_2_6_2.tar.gz"
fi

cd tinyxml

log_info "Copying TinyXML files to destination..."

# Copy header files
log_info "Copying header files..."
cp tinyxml.h "$TINYXML_DEST_DIR/"
cp tinystr.h "$TINYXML_DEST_DIR/"

# Copy source files
log_info "Copying source files..."
cp tinyxmlparser.cpp "$TINYXML_DEST_DIR/"
cp tinyxmlerror.cpp "$TINYXML_DEST_DIR/"
cp tinystr.cpp "$TINYXML_DEST_DIR/"
cp tinyxml.cpp "$TINYXML_DEST_DIR/"

cd "$BUILD_DIR"

# Verify all files were copied
log_info "Verifying TinyXML files..."
REQUIRED_FILES=(
    "tinyxml.h"
    "tinystr.h"
    "tinyxml.cpp"
    "tinystr.cpp"
    "tinyxmlparser.cpp"
    "tinyxmlerror.cpp"
)

all_files_present=true
for file in "${REQUIRED_FILES[@]}"; do
    if [ ! -f "$TINYXML_DEST_DIR/$file" ]; then
        log_error "Missing file: $file"
        all_files_present=false
    else
        log_info "✓ Found: $file"
    fi
done

if [ "$all_files_present" = true ]; then
    log_info "TinyXML setup success"
    echo "TinyXML setup success"
    echo "All TinyXML files copied to: $TINYXML_DEST_DIR"
    exit_code=0
else
    log_error "TinyXML setup fail - missing files"
    echo "TinyXML setup fail"
    exit_code=1
fi

log_info "************************************************************"
echo "************************************************************"

exit $exit_code
