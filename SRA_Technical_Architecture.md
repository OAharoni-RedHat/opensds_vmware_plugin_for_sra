# OpenSDS VMware Plugin for SRA - Technical Architecture

## Overview

This document provides a comprehensive technical overview of the OpenSDS Storage Replication Adapter (SRA) architecture, implementation patterns, and internal design. The SRA serves as a bridge between VMware Site Recovery Manager (SRM) and OpenSDS storage systems, enabling automated disaster recovery and site management.

## System Architecture

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                     VMware Site Recovery Manager                │
└─────────────────────────┬───────────────────────────────────────┘
                          │ XML/Command Interface
                          ▼
┌─────────────────────────────────────────────────────────────────┐
│                      OpenSDS SRA Layer                         │
├─────────────────────────────────────────────────────────────────┤
│                Command Dispatcher & Router                      │
├─────────────────────────────────────────────────────────────────┤
│    SRA API Handlers   │  XML Processing  │   Error Management   │
├─────────────────────────────────────────────────────────────────┤
│              Storage Abstraction Layer                         │
├─────────────────────────────────────────────────────────────────┤
│    REST Adapter      │   TLV Adapter    │   Communication      │
└─────────────────────────┬───────────────────────────────────────┘
                          │ HTTP/REST, TLV Protocol
                          ▼
┌─────────────────────────────────────────────────────────────────┐
│                   OpenSDS Storage Arrays                       │
│              (OceanStor, FusionStorage, etc.)                  │
└─────────────────────────────────────────────────────────────────┘
```

## Core Components

### 1. Main Entry Point (`sra.cpp`)

The SRA application follows a command-pattern architecture with centralized dispatch:

```cpp
int main(int argc, char* argv[])
{
    // Initialize function registry
    sra_init_reg_function();
    
    // Read XML input from SRM
    XmlReader reader;
    reader.load_from_string(input, TIXML_DEFAULT_ENCODING);
    
    // Dispatch to appropriate handler
    int ret = dispatch(reader);
    
    return (ret == RETURN_OK) ? 0 : -1;
}
```

**Key Responsibilities:**
- Command-line argument processing (`-v` for version, `-h` for help)
- XML input parsing from stdin
- Configuration loading (`config.txt`)
- Logging initialization
- Command dispatch to registered handlers

### 2. Command Dispatcher

The dispatcher uses a function registry pattern for loose coupling:

```cpp
map<string, SRA_ENTRY> g_mapFunc;

void sra_init_reg_function()
{
    register_fun("queryInfo", (SRA_ENTRY)query_info);
    register_fun("discoverArrays", (SRA_ENTRY)discover_arrays);
    register_fun("failover", (SRA_ENTRY)failover);
    // ... other commands
}

int dispatch(XmlReader &reader)
{
    string commandName = reader.get_string("/Command/Name");
    auto handler = g_mapFunc.find(commandName);
    return handler->second(reader);
}
```

**Design Benefits:**
- Dynamic command registration
- Extensible architecture for new commands
- Centralized error handling
- Command validation

### 3. Base Class Hierarchy

#### SraBasic - Abstract Base Class

All SRA command handlers inherit from `SraBasic`, implementing the Template Method pattern:

```cpp
class SraBasic
{
public:
    // Template method defining processing flow
    int entry(XmlReader &reader)
    {
        _read_common_info(reader);      // Parse common parameters
        _read_command_para(reader);     // Parse command-specific parameters
        _outband_process();             // Execute storage operations
        _write_response(writer);        // Generate XML response
    }

protected:
    // Template methods (virtual - subclasses override)
    virtual int _read_command_para(XmlReader &reader) = 0;
    virtual void _write_response(XmlWriter &writer) = 0;
    virtual int _outband_process() = 0;
    
    // Common infrastructure
    int _read_common_info(XmlReader &reader);
    int _write_error_info(XmlWriter &writer);
};
```

**Template Method Benefits:**
- Consistent processing flow across all commands
- Common parameter parsing and error handling
- Extensible for command-specific logic
- Built-in XML validation and response generation

#### Concrete Command Classes

Each API command implements a specialized class:

```cpp
class DiscoverArrays : public SraBasic
{
protected:
    virtual int _read_command_para(XmlReader &reader) override;
    virtual void _write_response(XmlWriter &writer) override;
    virtual int _outband_process() override;
    
private:
    // Command-specific data members
    list<string> peer_arrays;
    string array_name;
    string system_type;
};
```

### 4. XML Processing Layer

#### XmlReader - Input Processing

Built on TinyXML library with path-based access:

```cpp
class XmlReader
{
public:
    bool load_from_string(string xml, TiXmlEncoding encoding);
    bool get_string(const char *path, char *value, int index);
    bool get_int(const char *path, int &value, int index);
    int get_count(const char *path);
    bool get_xml(const char* path, XmlSerializable* obj, int index);
};
```

**Features:**
- XPath-like parameter access: `"/Command/SyncOnceParameters/ArrayId"`
- Multi-dimensional indexing for arrays
- Type-safe value extraction
- Automatic validation

#### XmlWriter - Output Generation

Structured XML response generation:

```cpp
class XmlWriter
{
public:
    bool set_string(const char *path, const char *value);
    bool set_int(const char *path, int value);
    bool set_xml(const char* path, XmlSerializable* obj);
    bool save_to_file(const char *filename);
};
```

#### Serializable Objects

Domain objects implement `XmlSerializable` for automatic marshalling:

```cpp
class ArrayInfo : public XmlSerializable
{
public:
    char id[LENGTH_COMMON];
    char name[LENGTH_COMMON];
    list<string> peer_arrays;
    
    virtual void writexml(XmlWriter& writer);
    virtual void readxml(XmlReader& reader);
};
```

### 5. Storage Abstraction Layer

#### Command Adapter Pattern

The storage layer uses the Adapter pattern to support multiple storage backends:

```cpp
class CCmdAdapter  // Abstract interface
{
public:
    virtual int CMD_showarrayinfo(list<REMOTE_ARRAY_STRU>& arrays) = 0;
    virtual int CMD_showconsistgrmember(string groupID, list<HYMIRROR_INFO_STRU>& mirrors) = 0;
    virtual int CMD_syncconsistgr(string groupID) = 0;
    // ... 200+ virtual methods
};

class CRESTCmd : public CCmdAdapter  // REST implementation
{
    // Implements all methods using HTTP REST calls
};

class CTLVCmd : public CCmdAdapter   // TLV implementation  
{
    // Implements all methods using TLV protocol
};
```

#### REST Communication Layer

Modern storage arrays use HTTP REST APIs:

```cpp
class CRESTConn
{
private:
    string m_strDeviceIP;
    string m_strSessionKey;
    string m_prefixUrl;
    
public:
    int doRequest(string url, REST_REQUEST_MODE mode, 
                  string bodyData, CRestPackage &response);
};

class CRESTCmd : public CCmdAdapter
{
private:
    list<pair<string, CRESTConn *>> m_connList;
    CRESTConn *getConn(string &ip, string &user, string &pwd);
};
```

**REST Features:**
- Session management with automatic re-authentication
- Connection pooling for performance
- JSON request/response processing
- SSL/TLS support
- Comprehensive error handling

#### TLV Communication Layer

Legacy systems use TLV (Type-Length-Value) protocol:

```cpp
class COMConnecter : public CConnecter
{
private:
    ACE_SOCK_Stream m_connToOM;
    ACE_SSL_SOCK_Stream m_connToOMOUT;
    
public:
    virtual int sendMsg(CS5KPackageV3 & msg, int timeout);
    int receiveMsg(CS5KPackageV3 & msg, int timeout);
};
```

**TLV Features:**
- Binary protocol for efficient communication
- ACE framework for network handling
- SSL support for secure communication
- Message packaging and serialization

### 6. Error Management System

#### Comprehensive Error Handling

The SRA implements multi-layered error management:

```cpp
// Global error code mappings
map<int, pair<string, string>> g_map_err_en;  // English errors
map<int, pair<string, string>> g_map_err_cn;  // Chinese errors

// Error categories
#define ERROR_COMMAND_NOT_SUPPORTED    50331649
#define ERROR_INTERNAL_PROCESS_FAIL    50331650
#define ERROR_INVALIDATE_DEVICE_ID     50331651
// ... hundreds more error codes

int send_error_info(XmlReader &reader, int error_code)
{
    XmlWriter writer;
    writer.set_int(XML_RESPONSE_ERROR, error_code);
    writer.set_string(XML_RESPONSE_TITLE, xmlns);
    writer.save_to_file(output_file);
}
```

**Error Management Features:**
- Hierarchical error codes with detailed descriptions
- Localized error messages (English/Chinese)
- Contextual error information
- Suggested remediation actions
- Automatic error XML response generation

### 7. Configuration Management

#### Configuration System

```cpp
class CISMConfig
{
public:
    bool open(const char* fileName, const char* suffix = ".cfg");
    bool getIntValue(const char* key, int& value);
    bool getStringValue(const char* key, string& value);
    bool modify(const string& key, const string& value, ...);
};
```

**Configuration Parameters:**
- `BandInfo` - Storage brand information
- `ManuFactoryInfo` - Manufacturer details
- `SraName` - Display name for SRA
- `isSupportNfs` - NFS protocol support
- `isSupportStretched` - Stretched cluster support
- `isFusionStorage` - FusionStorage backend support

### 8. Logging Framework

#### Comprehensive Logging

```cpp
#define COMMLOG(level, format, ...) \
    g_objLogger.WriteLog(level, __FILE__, __LINE__, format, ##__VA_ARGS__)

void sra_init_log(char* program_name)
{
    g_objLogger.SetPath(program_name);
    g_objLogger.SetFile(LOG_FILE_NAME);
    g_objLogger.SetMaxFileSize(100*1024*1024);
    g_objLogger.SetLogCount(5);
    g_objLogger.SetLevel(OS_LOG_INFO);
}
```

**Logging Features:**
- Configurable log levels (DEBUG, INFO, WARNING, ERROR)
- Automatic log rotation (100MB max, 5 files)
- File and line number tracking
- Structured log format
- Performance impact minimization

## Data Flow Architecture

### 1. Command Processing Flow

```
SRM Request → XML Parse → Command Dispatch → Parameter Validation → 
Storage Operation → Response Generation → XML Output → SRM Response
```

### 2. Storage Operation Flow

```
SRA Command → Adapter Selection → Connection Management → 
Protocol Communication → Response Processing → Error Handling → 
Data Transformation → Result Return
```

### 3. Error Handling Flow

```
Error Detection → Error Code Mapping → Localization → 
Context Enhancement → XML Error Response → Cleanup → 
Log Recording → SRM Notification
```

## Key Design Patterns

### 1. Template Method Pattern
- `SraBasic` defines processing skeleton
- Subclasses implement specific steps
- Ensures consistent flow across commands

### 2. Adapter Pattern
- `CCmdAdapter` provides unified interface
- Multiple implementations for different storage types
- Seamless backend switching

### 3. Factory Pattern
- Connection factories for REST/TLV
- Configuration-driven adapter selection
- Runtime polymorphism

### 4. Command Pattern
- Function registry for command dispatch
- Decoupled command registration
- Extensible command set

### 5. Observer Pattern
- Error notification system
- Progress reporting callbacks
- Status update mechanisms

## Storage Technology Support

### 1. Protocol Support

#### REST API (Primary)
- Modern HTTP-based communication
- JSON request/response format
- RESTful resource operations
- Session-based authentication
- SSL/TLS encryption

#### TLV Protocol (Legacy)
- Binary message format
- ACE networking framework
- Direct socket communication
- Custom serialization

### 2. Storage Operations

#### Replication Management
- Remote replication pairs
- HyperMetro active-active
- Consistency groups
- Synchronization control

#### Snapshot Operations
- Point-in-time snapshots
- Snapshot activation/deactivation
- Clone operations
- Recovery point management

#### Host/LUN Management
- LUN discovery and mapping
- Host group management
- Access control
- Storage provisioning

## Performance Considerations

### 1. Connection Management
- Connection pooling for efficiency
- Session reuse across operations
- Timeout management
- Automatic reconnection

### 2. Memory Management
- RAII pattern throughout
- Secure memory operations (`memset_s`)
- Proper cleanup in destructors
- Exception safety

### 3. Scalability
- Batch operations where possible
- Efficient XML processing
- Minimal memory footprint
- Optimized data structures

## Security Architecture

### 1. Communication Security
- SSL/TLS encryption for all protocols
- Certificate validation
- Secure credential storage
- Session token management

### 2. Input Validation
- XML schema validation
- Parameter boundary checking
- SQL injection prevention
- Buffer overflow protection

### 3. Error Information Security
- Sensitive data sanitization
- Error message filtering
- Audit trail logging
- Secure credential handling

## Deployment Architecture

### 1. Installation Structure
```
SRA_ROOT/
├── sra.exe                 # Main executable
├── config.txt             # Configuration file
├── logs/                  # Log directory
├── third_party/           # Dependencies
│   ├── ACE/              # Network framework
│   ├── curl/             # HTTP client
│   ├── jsoncpp/          # JSON processing
│   ├── openssl/          # Cryptography
│   └── tinyxml/          # XML processing
└── certificates/         # SSL certificates
```

### 2. Integration Points
- VMware SRM integration via SRA interface
- Storage array REST APIs
- Configuration management
- Log file monitoring
- Certificate management

## Extensibility Framework

### 1. Adding New Commands
1. Implement `SraBasic` subclass
2. Register in `sra_init_reg_function()`
3. Add XML schema definitions
4. Implement error codes
5. Add documentation

### 2. Adding Storage Support
1. Implement `CCmdAdapter` interface
2. Add protocol-specific communication
3. Update configuration options
4. Add authentication methods
5. Test integration

### 3. Protocol Extensions
1. Define new communication protocol
2. Implement connector interface
3. Add to adapter factory
4. Update configuration system
5. Validate security model

## Testing Strategy

### 1. Unit Testing
- Individual command testing
- Mock storage adapters
- XML parsing validation
- Error code verification

### 2. Integration Testing
- End-to-end SRM workflows
- Multiple storage backend testing
- Network failure scenarios
- Performance benchmarking

### 3. Security Testing
- Penetration testing
- Certificate validation
- Credential security
- Communication encryption

This technical architecture provides a robust, scalable, and maintainable foundation for storage replication management in VMware environments, with comprehensive error handling, security features, and extensibility for future storage technologies.
