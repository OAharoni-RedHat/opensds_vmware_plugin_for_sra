#!/bin/bash

echo "=== ACE Installation Diagnostic ==="
echo

BUILD_DIR="third_party_groupware/build_scripts/build"

echo "Checking for ACE installations in $BUILD_DIR..."
echo

# Check for ACE installations
ACE_FOUND=false

for ace_path in "$BUILD_DIR"/ACE-* "$BUILD_DIR"/ACE_wrappers*; do
    if [ -d "$ace_path" ]; then
        echo "Found ACE directory: $ace_path"
        
        # Check for headers
        if [ -f "$ace_path/include/ace/OS.h" ]; then
            echo "  ✓ Headers found: $ace_path/include/"
            ACE_FOUND=true
        elif [ -f "$ace_path/ace/OS.h" ]; then
            echo "  ✓ Headers found: $ace_path/"
            ACE_FOUND=true
        else
            echo "  ✗ Headers NOT found"
        fi
        
        # Check for libraries
        if [ -d "$ace_path/lib" ]; then
            echo "  ✓ Library directory: $ace_path/lib/"
            if ls "$ace_path/lib/"*ACE* >/dev/null 2>&1; then
                echo "  ✓ ACE libraries:"
                ls -la "$ace_path/lib/"*ACE* | head -5
            else
                echo "  ✗ No ACE libraries found"
            fi
        elif [ -d "$ace_path/ace" ]; then
            echo "  ? Checking for libraries in source directory..."
            if ls "$ace_path/ace/"lib*.so* >/dev/null 2>&1 || ls "$ace_path/ace/"lib*.a >/dev/null 2>&1; then
                echo "  ✓ ACE libraries in source:"
                ls -la "$ace_path/ace/"lib*ACE* 2>/dev/null | head -3
            else
                echo "  ✗ No ACE libraries in source directory"
            fi
        else
            echo "  ✗ No library directory found"
        fi
        
        # Check for SSL support
        if [ -f "$ace_path/include/ace/SSL/SSL_SOCK_Connector.h" ] || [ -f "$ace_path/ace/SSL/SSL_SOCK_Connector.h" ]; then
            echo "  ✓ SSL support available"
        else
            echo "  ✗ SSL support NOT available"
        fi
        
        echo
    fi
done

if [ "$ACE_FOUND" = false ]; then
    echo "❌ No usable ACE installation found!"
    echo
    echo "To fix this, run one of these ACE build scripts:"
    echo "  cd third_party_groupware/build_scripts"
    echo "  ./build_ACE.sh                 # Enhanced ACE build"
    echo "  ./build_ACE_minimal.sh         # Minimal ACE build"  
    echo "  ./build_ACE_core.sh            # Core-only ACE build"
    echo "  ./one_key_build3rd.sh          # Automated with fallbacks"
    echo
else
    echo "✅ ACE installation(s) found!"
    echo
    echo "To build TlvCom library:"
    echo "  cd source/TlvCom"
    echo "  ./build_tlvcom.sh"
    echo
fi

echo "=== End Diagnostic ==="
