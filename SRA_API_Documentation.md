# OpenSDS VMware Plugin for SRA - API Documentation

## Overview

This document provides comprehensive documentation for all APIs in the SRA (Site Recovery Adapter) folder of the OpenSDS VMware Plugin. The SRA facilitates storage replication management for VMware Site Recovery Manager (SRM).

## Architecture

The SRA uses XML-based communication with VMware SRM. Each API function follows a standard pattern:
- Receives XML input via `XmlReader`
- Processes the command through storage operations
- Returns XML response via `XmlWriter`

All API functions are registered in the `sra_init_reg_function()` and dispatched through the `dispatch()` function.

## Common Input Parameters

All SRA commands share these common XML input parameters:

### Required Parameters
- `xmlns` - XML namespace for the command
- `OutputFile` - Path where response XML should be written
- `LogDirectory` - Directory for log files
- `LogLevel` - Logging verbosity level

### Connection Parameters
- `Username` - Storage array username
- `Password` - Storage array password
- `Address` - Storage array IP address or serial number

## API Reference

### 1. queryInfo

**Purpose**: Returns basic adapter information

**Command Name**: `queryInfo`

**Input Parameters**: 
- Common parameters only

**Input XML Structure**:
```xml
<Command xmlns="...">
    <Name>queryInfo</Name>
    <OutputFile>...</OutputFile>
    <LogDirectory>...</LogDirectory>
    <LogLevel>...</LogLevel>
</Command>
```

**Output XML Structure**:
```xml
<Response xmlns="...">
    <AdapterInfo>
        <Name stringId="SRAname">OpenSDS_Storage_SRA</Name>
        <Version>...</Version>
        <Vendor stringId="...">...</Vendor>
        <Uuid>123-456-789</Uuid>
    </AdapterInfo>
</Response>
```

**Description**: Returns static information about the SRA adapter including name, version, vendor, and UUID.

---

### 2. queryStrings

**Purpose**: Returns localized strings for the adapter

**Command Name**: `queryStrings`

**Input Parameters**:
- Common parameters
- `Locale` - Language locale (e.g., "en", "zh")

**Input XML Structure**:
```xml
<Command xmlns="...">
    <Name>queryStrings</Name>
    <QueryStringsParameters>
        <Locale>en</Locale>
    </QueryStringsParameters>
    <OutputFile>...</OutputFile>
</Command>
```

**Output**: Returns localized string resources for UI display.

---

### 3. queryCapabilities

**Purpose**: Returns adapter capabilities and supported features

**Command Name**: `queryCapabilities`

**Input Parameters**: 
- Common parameters

**Output**: Returns XML describing supported SRA capabilities like:
- Supported array types
- Replication technologies
- Feature availability

---

### 4. queryErrorDefinitions

**Purpose**: Returns error code definitions and messages

**Command Name**: `queryErrorDefinitions`

**Input Parameters**: 
- Common parameters
- `Locale` - Language for error messages

**Output**: Returns comprehensive error code mappings with localized error messages and suggestions.

---

### 5. queryConnectionParameters

**Purpose**: Returns required connection parameters for storage arrays

**Command Name**: `queryConnectionParameters`

**Input Parameters**: 
- Common parameters

**Output**: Defines what connection parameters are needed to connect to storage arrays.

---

### 6. discoverArrays

**Purpose**: Discovers available storage arrays and their peer relationships

**Command Name**: `discoverArrays`

**Input Parameters**:
- Common parameters
- Connection parameters (Username, Password, Address)

**Input XML Structure**:
```xml
<Command xmlns="...">
    <Name>discoverArrays</Name>
    <Connections>
        <Connection>
            <Username>admin</Username>
            <Password>...</Password>
            <Addresses>
                <Address>192.168.1.100</Address>
            </Addresses>
        </Connection>
    </Connections>
    <OutputFile>...</OutputFile>
</Command>
```

**Output XML Structure**:
```xml
<Response xmlns="...">
    <Arrays>
        <Array id="..." name="...">
            <Model>
                <ModelName>OceanStor</ModelName>
                <VendorName>...</VendorName>
            </Model>
            <Software>
                <SoftwareName>ISM</SoftwareName>
                <SoftwareVersion>1.0</SoftwareVersion>
            </Software>
            <PeerArrays>
                <PeerArray>...</PeerArray>
            </PeerArrays>
        </Array>
    </Arrays>
</Response>
```

**Description**: Connects to storage array and discovers:
- Array information (ID, name, model)
- Peer array relationships for replication
- Software versions

---

### 7. discoverDevices

**Purpose**: Discovers replication-enabled devices on specified arrays

**Command Name**: `discoverDevices`

**Input Parameters**:
- Common parameters
- `ArrayId` - Target array identifier
- `PeerArrayId` - Peer array identifier

**Input XML Structure**:
```xml
<Command xmlns="...">
    <Name>discoverDevices</Name>
    <DiscoverDevicesParameters>
        <ArrayId>...</ArrayId>
        <PeerArrayId>...</PeerArrayId>
    </DiscoverDevicesParameters>
    <Connections>...</Connections>
    <OutputFile>...</OutputFile>
</Command>
```

**Output**: Returns discovered replicated devices including:
- Device IDs and names
- Replication relationships
- Device capabilities

---

### 8. syncOnce

**Purpose**: Initiates one-time synchronization of replication pairs

**Command Name**: `syncOnce`

**Input Parameters**:
- Common parameters
- `ArrayId` - Source array ID
- `PeerArrayId` - Target array ID
- `ConsistencyGroups` - List of consistency groups to sync
- `SourceDevices` - List of individual devices to sync

**Input XML Structure**:
```xml
<Command xmlns="...">
    <Name>syncOnce</Name>
    <SyncOnceParameters>
        <ArrayId>...</ArrayId>
        <PeerArrayId>...</PeerArrayId>
        <ConsistencyGroups>
            <ConsistencyGroup id="..."/>
        </ConsistencyGroups>
        <SourceDevices>
            <SourceDevice id="..."/>
        </SourceDevices>
    </SyncOnceParameters>
    <Connections>...</Connections>
    <OutputFile>...</OutputFile>
</Command>
```

**Output**: Returns synchronization status and progress information.

**Description**: Triggers immediate synchronization of specified replication pairs or consistency groups.

---

### 9. prepareFailover

**Purpose**: Prepares for failover by creating recovery point snapshots

**Command Name**: `prepareFailover`

**Input Parameters**:
- Common parameters
- `ArrayId` - Target array for failover
- Consistency groups and source devices to prepare

**Input XML Structure**:
```xml
<Command xmlns="...">
    <Name>prepareFailover</Name>
    <PrepareFailoverParameters>
        <ArrayId>...</ArrayId>
        <ConsistencyGroups>
            <ConsistencyGroup id="..."/>
        </ConsistencyGroups>
        <SourceDevices>
            <SourceDevice id="..."/>
        </SourceDevices>
    </PrepareFailoverParameters>
    <Connections>...</Connections>
    <OutputFile>...</OutputFile>
</Command>
```

**Description**: Creates snapshots and prepares the environment for failover operation. This is typically called before actual failover.

---

### 10. failover

**Purpose**: Executes failover operation to activate target devices

**Command Name**: `failover`

**Input Parameters**:
- Common parameters
- `ArrayId` - Target array ID
- `TargetGroups` - Groups of target devices
- `TargetDevices` - Individual target devices
- `AccessGroups` - Host access group information

**Input XML Structure**:
```xml
<Command xmlns="...">
    <Name>failover</Name>
    <FailoverParameters>
        <ArrayId>...</ArrayId>
        <TargetGroups>
            <TargetGroup key="..." isolationRequired="...">
                <TargetDevices>
                    <TargetDevice key="...">
                        <AccessGroups>
                            <AccessGroup id="..."/>
                        </AccessGroups>
                    </TargetDevice>
                </TargetDevices>
            </TargetGroup>
        </TargetGroups>
    </FailoverParameters>
    <Connections>...</Connections>
    <OutputFile>...</OutputFile>
</Command>
```

**Output**: Returns details of failed-over devices including new WWNs and mapping information.

**Description**: Executes the actual failover by:
- Splitting replication pairs
- Activating target devices
- Setting up host access and mapping

---

### 11. testFailoverStart

**Purpose**: Starts test failover using snapshots

**Command Name**: `testFailoverStart`

**Input Parameters**:
- Common parameters
- `ArrayId` - Array for test failover
- Target devices for testing

**Description**: Creates test environment without affecting production replication.

---

### 12. testFailoverStop

**Purpose**: Cleans up test failover environment

**Command Name**: `testFailoverStop`

**Input Parameters**:
- Common parameters
- `ArrayId` - Array where test was performed
- Target devices to clean up

**Description**: Removes test snapshots and restores normal replication state.

---

### 13. querySyncStatus

**Purpose**: Queries synchronization status of replication pairs

**Command Name**: `querySyncStatus`

**Input Parameters**:
- Common parameters
- `ArrayId` - Array to query
- `PeerArrayId` - Peer array ID
- Consistency groups or devices to check

**Output**: Returns detailed sync status including:
- Sync percentage completion
- Sync state (syncing, split, etc.)
- Estimated completion time

---

### 14. reverseReplication

**Purpose**: Reverses replication direction after failover

**Command Name**: `reverseReplication`

**Input Parameters**:
- Common parameters
- `ArrayId` - New source array
- `PeerArrayId` - New target array
- Target groups and devices to reverse

**Description**: Changes replication direction, making the former target array the new source.

---

### 15. restoreReplication

**Purpose**: Restores original replication direction

**Command Name**: `restoreReplication`

**Input Parameters**:
- Common parameters
- `ArrayId` - Original source array
- Target devices to restore

**Description**: Returns replication to its original direction after failback.

---

### 16. prepareReverseReplication

**Purpose**: Prepares for replication direction reversal

**Command Name**: `prepareReverseReplication`

**Input Parameters**:
- Common parameters
- `ArrayId` - Array to prepare
- Devices for reverse replication

**Description**: Prepares the environment before reversing replication direction.

## Error Handling

The SRA includes comprehensive error handling with detailed error codes and messages in multiple languages (English and Chinese). Common error categories include:

### System Errors
- `ERROR_COMMAND_NOT_SUPPORTED` - Unsupported command
- `ERROR_INTERNAL_PROCESS_FAIL` - Internal processing failure
- `ERROR_SYSTEM_BUSY` - System busy, retry later

### Authentication Errors
- `ERRPR_COMMON_USERPWD_ERROR` - Invalid username/password
- `ERROR_INVALIDATE_IPADDRESS` - Invalid IP address

### Replication Errors
- `ERROR_REMOTE_NOT_EXIST` - Remote replication doesn't exist
- `ERROR_SLAVELUN_NOT_MAP` - Slave LUN not mapped to ESX
- `ERROR_REMOTE_STATUS_NOT_ALLOW_OPERATE` - Replication status doesn't allow operation

### Snapshot Errors
- `ERROR_CREATE_SNAPSHOT` - Failed to create snapshot
- `ERROR_SNAPSHOT_EXCEEDED` - Maximum snapshots exceeded

## Configuration

The SRA reads configuration from `config.txt` file with parameters:
- `BandInfo` - Storage brand information
- `ManuFactoryInfo` - Manufacturer information
- `SraName` - SRA display name
- `isSupportNfs` - NFS support flag
- `isSupportStretched` - Stretched cluster support
- `isFusionStorage` - FusionStorage support flag

## Logging

All operations are logged with configurable levels. Logs include:
- Command execution start/end
- Error conditions and codes
- Progress information
- Debug details for troubleshooting

## Usage Notes

1. **Order of Operations**: For planned failover, the typical sequence is:
   - `prepareFailover` → `failover` → `reverseReplication`

2. **Test Operations**: For testing:
   - `testFailoverStart` → testing → `testFailoverStop`

3. **Status Monitoring**: Use `querySyncStatus` to monitor replication health

4. **Error Recovery**: Check error codes and follow suggested remediation actions

This documentation covers the complete SRA API surface for OpenSDS storage integration with VMware Site Recovery Manager.
