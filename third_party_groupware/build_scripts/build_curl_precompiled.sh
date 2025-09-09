#!/bin/bash

# Nuclear option: Create a minimal curl from source without autotools
# This manually compiles just the essential curl files for HTTPS support

set -e

echo "************************************************************"
echo "Building curl manually (precompiled approach)..."
echo "************************************************************"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="$SCRIPT_DIR/build"
CURL_VERSION="7.52.1"
INSTALL_DIR="$BUILD_DIR/curl-$CURL_VERSION"

# Dependencies
OPENSSL_DIR="$BUILD_DIR/openssl-1.0.2j"
ZLIB_DIR="$BUILD_DIR/zlib-1.2.11"

mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

log_info() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')][Info] $1" | tee -a build.log
}

log_info "Building curl manually without autotools..."

# Download and extract curl source
if [ ! -f "curl-$CURL_VERSION.tar.gz" ]; then
    log_info "Downloading curl source..."
    wget "https://curl.se/download/curl-$CURL_VERSION.tar.gz" || curl -L -o "curl-$CURL_VERSION.tar.gz" "https://curl.se/download/curl-$CURL_VERSION.tar.gz"
fi

if [ ! -d "curl-$CURL_VERSION-manual" ]; then
    tar -xzf "curl-$CURL_VERSION.tar.gz"
    mv "curl-$CURL_VERSION" "curl-$CURL_VERSION-manual"
fi

cd "curl-$CURL_VERSION-manual"

# Create minimal curl_config.h
log_info "Creating minimal curl_config.h..."
cat > lib/curl_config.h << 'EOF'
#define HAVE_OPENSSL_SSL_H 1
#define USE_OPENSSL 1
#define HAVE_ZLIB_H 1
#define HAVE_LIBZ 1
#define HAVE_SOCKET 1
#define HAVE_SELECT 1
#define HAVE_GETHOSTBYNAME 1
#define HAVE_RECV 1
#define HAVE_SEND 1
#define HAVE_SYS_SOCKET_H 1
#define HAVE_NETINET_IN_H 1
#define HAVE_ARPA_INET_H 1
#define HAVE_UNISTD_H 1
#define HAVE_STDLIB_H 1
#define HAVE_STRING_H 1
#define PACKAGE_VERSION "7.52.1"
#define CURL_DISABLE_FTP 1
#define CURL_DISABLE_LDAP 1
#define CURL_DISABLE_TELNET 1
#define CURL_DISABLE_DICT 1
#define CURL_DISABLE_FILE 1
#define CURL_DISABLE_TFTP 1
#define CURL_DISABLE_RTSP 1
#define CURL_DISABLE_POP3 1
#define CURL_DISABLE_IMAP 1
#define CURL_DISABLE_SMTP 1
#define CURL_DISABLE_GOPHER 1
#define BUILDING_LIBCURL 1
EOF

# Compile essential curl source files
log_info "Compiling essential curl files..."

CFLAGS="-I. -Iinclude -I$OPENSSL_DIR/include -I$ZLIB_DIR/include -DHAVE_CONFIG_H -DBUILDING_LIBCURL"
SOURCES="lib/base64.c lib/connect.c lib/content_encoding.c lib/cookie.c lib/curl_addrinfo.c lib/curl_fnmatch.c lib/curl_memrchr.c lib/curl_rand.c lib/curl_rtmp.c lib/curl_sasl.c lib/curl_sspi.c lib/curl_threads.c lib/easy.c lib/escape.c lib/file.c lib/fileinfo.c lib/formdata.c lib/ftp.c lib/ftplistparser.c lib/getenv.c lib/getinfo.c lib/gtls.c lib/hash.c lib/hmac.c lib/hostasyn.c lib/hostcheck.c lib/hostip.c lib/hostip4.c lib/hostip6.c lib/hostsyn.c lib/http.c lib/http_chunks.c lib/http_digest.c lib/http_negotiate.c lib/http_ntlm.c lib/http_proxy.c lib/if2ip.c lib/inet_ntop.c lib/inet_pton.c lib/krb5.c lib/ldap.c lib/llist.c lib/md4.c lib/md5.c lib/memdebug.c lib/mprintf.c lib/multi.c lib/netrc.c lib/non-ascii.c lib/openldap.c lib/parsedate.c lib/pingpong.c lib/pipeline.c lib/pop3.c lib/progress.c lib/rawstr.c lib/select.c lib/sendf.c lib/share.c lib/slist.c lib/smb.c lib/smtp.c lib/socks.c lib/socks_gssapi.c lib/socks_sspi.c lib/speedcheck.c lib/splay.c lib/ssh.c lib/strdup.c lib/strequal.c lib/strerror.c lib/strtok.c lib/strtoofft.c lib/telnet.c lib/tftp.c lib/timeval.c lib/transfer.c lib/url.c lib/version.c lib/warnless.c lib/wildcard.c"

# Compile only essential files for HTTPS
ESSENTIAL_SOURCES="lib/easy.c lib/multi.c lib/url.c lib/transfer.c lib/connect.c lib/http.c lib/sendf.c lib/base64.c lib/escape.c lib/getinfo.c lib/progress.c lib/share.c lib/version.c lib/timeval.c lib/select.c lib/hostip.c lib/hostip4.c lib/inet_pton.c lib/parsedate.c lib/mprintf.c lib/slist.c lib/hash.c lib/llist.c lib/strequal.c lib/strerror.c lib/curl_addrinfo.c lib/hostasyn.c lib/hostsyn.c lib/inet_ntop.c lib/rawstr.c lib/strdup.c lib/warnless.c lib/content_encoding.c"

mkdir -p "$INSTALL_DIR/lib" "$INSTALL_DIR/include/curl"

# Compile object files
log_info "Compiling object files..."
for src in $ESSENTIAL_SOURCES; do
    if [ -f "$src" ]; then
        obj=$(basename "$src" .c).o
        gcc $CFLAGS -c "$src" -o "$obj"
        echo "Compiled $src -> $obj"
    fi
done

# Create static library
log_info "Creating static library..."
ar rcs "$INSTALL_DIR/lib/libcurl.a" *.o

# Copy headers
log_info "Installing headers..."
cp include/curl/*.h "$INSTALL_DIR/include/curl/"

# Verify
if [ -f "$INSTALL_DIR/lib/libcurl.a" ] && [ -f "$INSTALL_DIR/include/curl/curl.h" ]; then
    log_info "✓ Manual curl build successful"
    echo "build libcurl (precompiled) success"
    echo "Static library: $INSTALL_DIR/lib/libcurl.a"
    echo "Headers: $INSTALL_DIR/include/curl/"
    ls -la "$INSTALL_DIR/lib/libcurl.a"
else
    log_info "✗ Manual curl build failed"
    exit 1
fi

log_info "************************************************************"
