# Linux Compilation Guide for OpenSDS SRA

## Prerequisites

### 1. Install Build Dependencies

```bash
# Ubuntu/Debian
sudo apt-get update
sudo apt-get install -y build-essential cmake git wget curl
sudo apt-get install -y libssl-dev zlib1g-dev libcurl4-openssl-dev
sudo apt-get install -y libssh2-1-dev libjsoncpp-dev

# CentOS/RHEL/Rocky Linux
sudo yum groupinstall -y "Development Tools"
sudo yum install -y cmake git wget curl
sudo yum install -y openssl-devel zlib-devel libcurl-devel
sudo yum install -y libssh2-devel jsoncpp-devel

# Fedora
sudo dnf groupinstall -y "Development Tools"
sudo dnf install -y cmake git wget curl
sudo dnf install -y openssl-devel zlib-devel libcurl-devel
sudo dnf install -y libssh2-devel jsoncpp-devel
```

## Step-by-Step Compilation Process

### 1. Clone and Navigate to Project
```bash
git clone <your-sra-repository-url>
cd opensds_vmware_plugin_for_sra
```

### 2. Build Third-Party Dependencies

The SRA requires specific versions of third-party libraries. Build them in order:

```bash
cd third_party_groupware/build_scripts

# Create build directory structure
mkdir -p build

# Set environment variables
export THIRD_PARTY_ROOT=$(pwd)/build
export PATH=$THIRD_PARTY_ROOT/bin:$PATH
export LD_LIBRARY_PATH=$THIRD_PARTY_ROOT/lib:$LD_LIBRARY_PATH
export PKG_CONFIG_PATH=$THIRD_PARTY_ROOT/lib/pkgconfig:$PKG_CONFIG_PATH

# Make scripts executable
chmod +x *.bat

# Build dependencies in order (note: .bat scripts work on Linux with proper shell)
# You may need to convert these to .sh or run manually

# 1. Build zlib
./build_zlib_86.bat

# 2. Build OpenSSL
./build_openssl.bat

# 3. Build libssh2
./build_libssh2.bat

# 4. Build curl
./build_curl.bat

# 5. Build jsoncpp
./build_jsoncpp.bat

# 6. Build TinyXML
./build_tinyxml.bat

# 7. Build ACE (most complex dependency)
./build_ACE.bat
```

### 3. Manual Third-Party Build (Alternative Approach)

If the batch scripts don't work, build manually:

```bash
cd third_party_groupware/build_scripts
mkdir -p build && cd build

# Build OpenSSL 1.0.2j
wget https://www.openssl.org/source/old/1.0.2/openssl-1.0.2j.tar.gz
tar -xzf openssl-1.0.2j.tar.gz
cd openssl-1.0.2j
./config --prefix=$PWD/../openssl-1.0.2j shared
make && make install
cd ..

# Build curl 7.52.1
wget https://curl.se/download/curl-7.52.1.tar.gz
tar -xzf curl-7.52.1.tar.gz
cd curl-7.52.1
./configure --prefix=$PWD/../curl-7.52.1 --with-ssl=$PWD/../openssl-1.0.2j
make && make install
cd ..

# Build libssh2 1.7.0
wget https://www.libssh2.org/download/libssh2-1.7.0.tar.gz
tar -xzf libssh2-1.7.0.tar.gz
cd libssh2-1.7.0
./configure --prefix=$PWD/../libssh2-1.7.0 --with-openssl=$PWD/../openssl-1.0.2j
make && make install
cd ..

# Build jsoncpp 0.10.5
wget https://github.com/open-source-parsers/jsoncpp/archive/0.10.5.tar.gz
tar -xzf 0.10.5.tar.gz
cd jsoncpp-0.10.5
mkdir build && cd build
cmake -DCMAKE_INSTALL_PREFIX=$PWD/../../jsoncpp-0.10.5 -DCMAKE_BUILD_TYPE=Release ..
make && make install
cd ../..

# Build ACE 6.2.4 (most important)
wget http://download.dre.vanderbilt.edu/previous_versions/ACE-6.2.4.tar.gz
tar -xzf ACE-6.2.4.tar.gz
cd ACE_wrappers
export ACE_ROOT=$PWD
echo '#include "ace/config-linux.h"' > ace/config.h
echo 'include $(ACE_ROOT)/include/makeinclude/platform_linux.GNU' > include/makeinclude/platform_macros.GNU
make
mkdir -p ../ACE-6.2.4/{include,lib}
cp -r ace ../ACE-6.2.4/include/
cp lib/*.so* ../ACE-6.2.4/lib/
cd ..
```

### 4. Build the SRA

```bash
cd ../../../source

# Create securec library (dependency for SRA)
cd securec
gcc -fPIC -shared -o lib/libsecurec.so memset_s.c
mkdir -p lib
cd ..

# Create TlvCom library (if not built by ACE)
cd TlvCom
mkdir -p lib
g++ -fPIC -shared -o lib/libTLVCom.so -I../common/os -I../../third_party_groupware/build_scripts/build/ACE-6.2.4/include msg_package.cpp om_connecter.cpp
cd ..

# Build the main SRA executable
mkdir -p cmake_build && cd cmake_build
cmake ..
make -j$(nproc)
```

### 5. Verify Build

```bash
# Check if executable was created
ls -la ../bin/command

# Copy executable to demo directory for testing
cp ../bin/command ../../demo/sra
```

## Running the Demo

### 1. Setup Demo Environment

```bash
cd ../../demo

# Make sure directories exist
mkdir -p outputs logs

# Set up library path
export LD_LIBRARY_PATH=../source/securec/lib:../source/TlvCom/lib:../third_party_groupware/build_scripts/build/ACE-6.2.4/lib:../third_party_groupware/build_scripts/build/openssl-1.0.2j/lib:../third_party_groupware/build_scripts/build/curl-7.52.1/lib:../third_party_groupware/build_scripts/build/libssh2-1.7.0/lib:$LD_LIBRARY_PATH

# Make demo script executable
chmod +x run_demo.sh
```

### 2. Test Individual Commands

```bash
# Test basic SRA info query
./sra < inputs/demo_query_info.xml

# Check output
cat outputs/query_info_response.xml
```

### 3. Run Full Demo

```bash
# Run the complete demo workflow
./run_demo.sh
```

## Troubleshooting

### Common Issues and Solutions

1. **Missing Libraries Error**
   ```bash
   # Add library paths to environment
   export LD_LIBRARY_PATH=/path/to/third_party/libs:$LD_LIBRARY_PATH
   ```

2. **CMake Configuration Fails**
   ```bash
   # Clean and reconfigure
   rm -rf cmake_build/*
   cd cmake_build
   cmake .. -DCMAKE_VERBOSE_MAKEFILE=ON
   ```

3. **ACE Compilation Issues**
   ```bash
   # Ensure ACE environment is set
   export ACE_ROOT=/path/to/ACE_wrappers
   export LD_LIBRARY_PATH=$ACE_ROOT/lib:$LD_LIBRARY_PATH
   ```

4. **Permission Issues**
   ```bash
   # Make sure all scripts are executable
   find . -name "*.sh" -exec chmod +x {} \;
   find . -name "*.bat" -exec chmod +x {} \;
   ```

## Testing the Demo Without Storage Array

The demo is designed to work without an actual storage array by using mock responses. Expected behavior:

1. **Query Info**: Returns SRA version and capabilities
2. **Discover Arrays**: Returns simulated array information
3. **Discover Devices**: Returns mock device listings
4. **Sync Status**: Shows simulated replication status
5. **Failover Operations**: Demonstrate failover workflows with mock data

## Next Steps

After successful compilation:

1. Test with provided demo XML files
2. Customize configuration in `config.txt`
3. Modify demo scenarios for your specific use case
4. Integrate with VMware Site Recovery Manager for production use

## Build Output

Expected files after successful build:
- `source/bin/command` - Main SRA executable
- `source/securec/lib/libsecurec.so` - Security library
- `source/TlvCom/lib/libTLVCom.so` - Communication library
- Third-party libraries in `third_party_groupware/build_scripts/build/`
