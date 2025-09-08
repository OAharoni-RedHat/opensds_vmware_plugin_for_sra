# OpenSDS SRA Demo Guide

## Overview

This guide demonstrates how to use the OpenSDS Storage Replication Adapter (SRA) with sample XML input files and expected responses. This demo can be run without an actual storage array, making it perfect for testing, development, and training purposes.

## Prerequisites

- Windows Server 2008 R2 or later (64-bit)
- OpenSDS SRA executable (`sra.exe`)
- Demo XML input files (provided in this guide)
- Basic understanding of VMware Site Recovery Manager concepts

## Demo Architecture

```
Demo Input Files → OpenSDS SRA → Mock Responses → Output XML Files
```

The demo operates by:
1. Providing pre-configured XML input files
2. Running the SRA executable with demo configurations
3. Receiving standardized XML responses
4. Demonstrating typical SRA workflows

## Setup Instructions

### 1. Prepare Demo Environment

Create the following directory structure:
```
demo/
├── sra.exe                 # SRA executable
├── config.txt             # Configuration file
├── inputs/                 # Demo input files
├── outputs/                # Generated response files
└── logs/                   # Log files
```

### 2. Configure Demo Settings

Create `config.txt` with demo-friendly settings:
```
BandInfo=OceanStor_Demo
ManuFactoryInfo=OpenSDS_Demo
SraName=OpenSDS_Storage_SRA_Demo
isSupportNfs=true
isSupportStretched=true
isFusionStorage=false
```

## Demo Scenarios

### Scenario 1: Basic SRA Information Query

**Purpose**: Verify SRA installation and basic functionality

**Command**: `queryInfo`

**Input File**: `demo_query_info.xml`
```xml
<?xml version="1.0" encoding="UTF-8"?>
<Command xmlns="http://www.vmware.com/srm/client">
    <Name>queryInfo</Name>
    <OutputFile>outputs/query_info_response.xml</OutputFile>
    <LogDirectory>logs</LogDirectory>
    <LogLevel>info</LogLevel>
</Command>
```

**Expected Response**: `query_info_response.xml`
```xml
<?xml version="1.0" encoding="UTF-8"?>
<Response xmlns="http://www.vmware.com/srm/client">
    <AdapterInfo>
        <Name stringId="SRAname">OpenSDS_Storage_SRA_Demo</Name>
        <Version>2.1.16</Version>
        <Vendor>OpenSDS</Vendor>
        <Uuid>12345678-1234-5678-9abc-123456789def</Uuid>
    </AdapterInfo>
</Response>
```

**How to Run**:
```cmd
sra.exe < inputs/demo_query_info.xml
```

### Scenario 2: Array Discovery

**Purpose**: Demonstrate storage array discovery functionality

**Command**: `discoverArrays`

**Input File**: `demo_discover_arrays.xml`
```xml
<?xml version="1.0" encoding="UTF-8"?>
<Command xmlns="http://www.vmware.com/srm/client">
    <Name>discoverArrays</Name>
    <Connections>
        <Connection>
            <Username>demo_admin</Username>
            <Password>demo_password</Password>
            <Addresses>
                <Address>192.168.1.100</Address>
            </Addresses>
        </Connection>
    </Connections>
    <OutputFile>outputs/discover_arrays_response.xml</OutputFile>
    <LogDirectory>logs</LogDirectory>
    <LogLevel>info</LogLevel>
</Command>
```

**Expected Response**: `discover_arrays_response.xml`
```xml
<?xml version="1.0" encoding="UTF-8"?>
<Response xmlns="http://www.vmware.com/srm/client">
    <Arrays>
        <Array id="210235G7H00001" name="OceanStor-Demo-Primary">
            <Model>
                <ModelName>OceanStor 5600 V3</ModelName>
                <VendorName>OpenSDS</VendorName>
            </Model>
            <Software>
                <SoftwareName>ISM</SoftwareName>
                <SoftwareVersion>V300R006C60</SoftwareVersion>
            </Software>
            <PeerArrays>
                <PeerArray>210235G7H00002</PeerArray>
            </PeerArrays>
        </Array>
        <Array id="210235G7H00002" name="OceanStor-Demo-Secondary">
            <Model>
                <ModelName>OceanStor 5600 V3</ModelName>
                <VendorName>OpenSDS</VendorName>
            </Model>
            <Software>
                <SoftwareName>ISM</SoftwareName>
                <SoftwareVersion>V300R006C60</SoftwareVersion>
            </Software>
            <PeerArrays>
                <PeerArray>210235G7H00001</PeerArray>
            </PeerArrays>
        </Array>
    </Arrays>
</Response>
```

**How to Run**:
```cmd
sra.exe < inputs/demo_discover_arrays.xml
```

### Scenario 3: Device Discovery

**Purpose**: Show replication-enabled device discovery

**Command**: `discoverDevices`

**Input File**: `demo_discover_devices.xml`
```xml
<?xml version="1.0" encoding="UTF-8"?>
<Command xmlns="http://www.vmware.com/srm/client">
    <Name>discoverDevices</Name>
    <DiscoverDevicesParameters>
        <ArrayId>210235G7H00001</ArrayId>
        <PeerArrayId>210235G7H00002</PeerArrayId>
    </DiscoverDevicesParameters>
    <Connections>
        <Connection>
            <Username>demo_admin</Username>
            <Password>demo_password</Password>
            <Addresses>
                <Address>192.168.1.100</Address>
            </Addresses>
        </Connection>
    </Connections>
    <OutputFile>outputs/discover_devices_response.xml</OutputFile>
    <LogDirectory>logs</LogDirectory>
    <LogLevel>info</LogLevel>
</Command>
```

**Expected Response**: `discover_devices_response.xml`
```xml
<?xml version="1.0" encoding="UTF-8"?>
<Response xmlns="http://www.vmware.com/srm/client">
    <ReplicatedDevices>
        <SourceDevices>
            <SourceDevice id="1001" state="synchronized">
                <Name>Demo_LUN_001</Name>
                <TargetDevice key="2001">
                    <Name>Demo_LUN_001_Target</Name>
                </TargetDevice>
                <Identity>
                    <SourceWwn>6003048001234567890123456789ABCD</SourceWwn>
                    <TargetWwn>6003048001234567890123456789ABCE</TargetWwn>
                </Identity>
                <DeviceSync>
                    <SyncId>sync_001</SyncId>
                    <SyncState>synchronized</SyncState>
                    <SyncPercent>100</SyncPercent>
                </DeviceSync>
            </SourceDevice>
            <SourceDevice id="1002" state="synchronizing">
                <Name>Demo_LUN_002</Name>
                <TargetDevice key="2002">
                    <Name>Demo_LUN_002_Target</Name>
                </TargetDevice>
                <Identity>
                    <SourceWwn>6003048001234567890123456789ABCF</SourceWwn>
                    <TargetWwn>6003048001234567890123456789ABC0</TargetWwn>
                </Identity>
                <DeviceSync>
                    <SyncId>sync_002</SyncId>
                    <SyncState>synchronizing</SyncState>
                    <SyncPercent>85</SyncPercent>
                </DeviceSync>
            </SourceDevice>
        </SourceDevices>
    </ReplicatedDevices>
</Response>
```

**How to Run**:
```cmd
sra.exe < inputs/demo_discover_devices.xml
```

### Scenario 4: Synchronization Status Query

**Purpose**: Monitor replication synchronization status

**Command**: `querySyncStatus`

**Input File**: `demo_query_sync_status.xml`
```xml
<?xml version="1.0" encoding="UTF-8"?>
<Command xmlns="http://www.vmware.com/srm/client">
    <Name>querySyncStatus</Name>
    <QuerySyncStatusParameters>
        <ArrayId>210235G7H00001</ArrayId>
        <PeerArrayId>210235G7H00002</PeerArrayId>
        <SourceDevices>
            <SourceDevice id="1001"/>
            <SourceDevice id="1002"/>
        </SourceDevices>
    </QuerySyncStatusParameters>
    <Connections>
        <Connection>
            <Username>demo_admin</Username>
            <Password>demo_password</Password>
            <Addresses>
                <Address>192.168.1.100</Address>
            </Addresses>
        </Connection>
    </Connections>
    <OutputFile>outputs/query_sync_status_response.xml</OutputFile>
    <LogDirectory>logs</LogDirectory>
    <LogLevel>info</LogLevel>
</Command>
```

**Expected Response**: `query_sync_status_response.xml`
```xml
<?xml version="1.0" encoding="UTF-8"?>
<Response xmlns="http://www.vmware.com/srm/client">
    <SyncStatusResults>
        <SourceDevices>
            <SourceDevice id="1001" state="synchronized">
                <DeviceSync>
                    <SyncId>sync_001</SyncId>
                    <SyncState>synchronized</SyncState>
                    <SyncPercent>100</SyncPercent>
                    <EstimatedTimeToComplete>0</EstimatedTimeToComplete>
                </DeviceSync>
            </SourceDevice>
            <SourceDevice id="1002" state="synchronizing">
                <DeviceSync>
                    <SyncId>sync_002</SyncId>
                    <SyncState>synchronizing</SyncState>
                    <SyncPercent>90</SyncPercent>
                    <EstimatedTimeToComplete>300</EstimatedTimeToComplete>
                </DeviceSync>
            </SourceDevice>
        </SourceDevices>
    </SyncStatusResults>
</Response>
```

**How to Run**:
```cmd
sra.exe < inputs/demo_query_sync_status.xml
```

### Scenario 5: Failover Preparation

**Purpose**: Demonstrate failover preparation process

**Command**: `prepareFailover`

**Input File**: `demo_prepare_failover.xml`
```xml
<?xml version="1.0" encoding="UTF-8"?>
<Command xmlns="http://www.vmware.com/srm/client">
    <Name>prepareFailover</Name>
    <PrepareFailoverParameters>
        <ArrayId>210235G7H00002</ArrayId>
        <SourceDevices>
            <SourceDevice id="1001"/>
            <SourceDevice id="1002"/>
        </SourceDevices>
    </PrepareFailoverParameters>
    <Connections>
        <Connection>
            <Username>demo_admin</Username>
            <Password>demo_password</Password>
            <Addresses>
                <Address>192.168.1.101</Address>
            </Addresses>
        </Connection>
    </Connections>
    <OutputFile>outputs/prepare_failover_response.xml</OutputFile>
    <LogDirectory>logs</LogDirectory>
    <LogLevel>info</LogLevel>
</Command>
```

**Expected Response**: `prepare_failover_response.xml`
```xml
<?xml version="1.0" encoding="UTF-8"?>
<Response xmlns="http://www.vmware.com/srm/client">
    <PrepareFailoverResults>
        <RecoveryPoints>
            <RecoveryPoint>
                <TimeStamp>2023-12-01T10:30:00Z</TimeStamp>
                <SnapshotId>snap_001_20231201_1030</SnapshotId>
                <Description>Pre-failover snapshot for demo</Description>
            </RecoveryPoint>
        </RecoveryPoints>
        <TargetDevices>
            <TargetDevice key="2001">
                <Name>Demo_LUN_001_Target</Name>
                <PreparedState>ready</PreparedState>
            </TargetDevice>
            <TargetDevice key="2002">
                <Name>Demo_LUN_002_Target</Name>
                <PreparedState>ready</PreparedState>
            </TargetDevice>
        </TargetDevices>
    </PrepareFailoverResults>
</Response>
```

**How to Run**:
```cmd
sra.exe < inputs/demo_prepare_failover.xml
```

### Scenario 6: Test Failover

**Purpose**: Execute a non-disruptive test failover

**Command**: `testFailoverStart`

**Input File**: `demo_test_failover_start.xml`
```xml
<?xml version="1.0" encoding="UTF-8"?>
<Command xmlns="http://www.vmware.com/srm/client">
    <Name>testFailoverStart</Name>
    <TestFailoverStartParameters>
        <ArrayId>210235G7H00002</ArrayId>
        <TargetGroups>
            <TargetGroup key="demo_test_group" isolationRequired="false">
                <TargetDevices>
                    <TargetDevice key="2001">
                        <AccessGroups>
                            <AccessGroup id="demo_host_group"/>
                        </AccessGroups>
                    </TargetDevice>
                    <TargetDevice key="2002">
                        <AccessGroups>
                            <AccessGroup id="demo_host_group"/>
                        </AccessGroups>
                    </TargetDevice>
                </TargetDevices>
            </TargetGroup>
        </TargetGroups>
    </TestFailoverStartParameters>
    <Connections>
        <Connection>
            <Username>demo_admin</Username>
            <Password>demo_password</Password>
            <Addresses>
                <Address>192.168.1.101</Address>
            </Addresses>
        </Connection>
    </Connections>
    <OutputFile>outputs/test_failover_start_response.xml</OutputFile>
    <LogDirectory>logs</LogDirectory>
    <LogLevel>info</LogLevel>
</Command>
```

**Expected Response**: `test_failover_start_response.xml`
```xml
<?xml version="1.0" encoding="UTF-8"?>
<Response xmlns="http://www.vmware.com/srm/client">
    <TestFailoverResults>
        <TargetDevices>
            <TargetDevice key="2001">
                <Name>Demo_LUN_001_Target_Test</Name>
                <Identity>
                    <TargetWwn>6003048001234567890123456789TEST1</TargetWwn>
                </Identity>
                <TestState>active</TestState>
                <TestSnapshotId>test_snap_001</TestSnapshotId>
            </TargetDevice>
            <TargetDevice key="2002">
                <Name>Demo_LUN_002_Target_Test</Name>
                <Identity>
                    <TargetWwn>6003048001234567890123456789TEST2</TargetWwn>
                </Identity>
                <TestState>active</TestState>
                <TestSnapshotId>test_snap_002</TestSnapshotId>
            </TargetDevice>
        </TargetDevices>
    </TestFailoverResults>
</Response>
```

**How to Run**:
```cmd
sra.exe < inputs/demo_test_failover_start.xml
```

## Running Complete Demo Workflow

### Automated Demo Script

Create `run_demo.bat` for Windows:

```batch
@echo off
echo ======================================
echo OpenSDS SRA Demo Workflow
echo ======================================

echo.
echo 1. Querying SRA Information...
sra.exe < inputs/demo_query_info.xml
if %errorlevel% neq 0 (
    echo ERROR: Query Info failed
    exit /b 1
)
echo SUCCESS: SRA Information retrieved

echo.
echo 2. Discovering Storage Arrays...
sra.exe < inputs/demo_discover_arrays.xml
if %errorlevel% neq 0 (
    echo ERROR: Array Discovery failed
    exit /b 1
)
echo SUCCESS: Arrays discovered

echo.
echo 3. Discovering Replicated Devices...
sra.exe < inputs/demo_discover_devices.xml
if %errorlevel% neq 0 (
    echo ERROR: Device Discovery failed
    exit /b 1
)
echo SUCCESS: Devices discovered

echo.
echo 4. Checking Synchronization Status...
sra.exe < inputs/demo_query_sync_status.xml
if %errorlevel% neq 0 (
    echo ERROR: Sync Status Query failed
    exit /b 1
)
echo SUCCESS: Sync status retrieved

echo.
echo 5. Preparing for Failover...
sra.exe < inputs/demo_prepare_failover.xml
if %errorlevel% neq 0 (
    echo ERROR: Failover Preparation failed
    exit /b 1
)
echo SUCCESS: Failover preparation completed

echo.
echo 6. Starting Test Failover...
sra.exe < inputs/demo_test_failover_start.xml
if %errorlevel% neq 0 (
    echo ERROR: Test Failover Start failed
    exit /b 1
)
echo SUCCESS: Test failover started

echo.
echo ======================================
echo Demo completed successfully!
echo Check the outputs/ directory for responses
echo Check the logs/ directory for detailed logs
echo ======================================
```

### Running the Demo

1. **Prepare Environment**:
   ```cmd
   mkdir demo
   cd demo
   mkdir inputs outputs logs
   copy sra.exe .
   ```

2. **Create Input Files**: Copy all the XML input files above to the `inputs/` directory

3. **Create Configuration**: Create `config.txt` with the demo configuration

4. **Run Individual Commands**:
   ```cmd
   sra.exe < inputs/demo_query_info.xml
   ```

5. **Run Complete Workflow**:
   ```cmd
   run_demo.bat
   ```

## Expected Output Analysis

### Success Indicators

1. **Return Code**: `0` indicates successful execution
2. **Response XML**: Well-formed XML with expected structure
3. **Log Files**: Detailed operation logs without critical errors

### Common Response Patterns

All successful responses include:
- Proper XML namespace
- Complete data structures
- No error codes in response

### Error Handling Demo

Create `demo_error_handling.xml` to demonstrate error responses:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<Command xmlns="http://www.vmware.com/srm/client">
    <Name>discoverArrays</Name>
    <Connections>
        <Connection>
            <Username>invalid_user</Username>
            <Password>invalid_password</Password>
            <Addresses>
                <Address>999.999.999.999</Address>
            </Addresses>
        </Connection>
    </Connections>
    <OutputFile>outputs/error_response.xml</OutputFile>
    <LogDirectory>logs</LogDirectory>
    <LogLevel>info</LogLevel>
</Command>
```

Expected error response:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<Response xmlns="http://www.vmware.com/srm/client">
    <Error code="50331651">
        <Message>Invalid IP address or connection failed</Message>
        <Suggestion>Check the IP address and network connectivity</Suggestion>
    </Error>
</Response>
```

## Troubleshooting

### Common Issues

1. **Missing Configuration**: Ensure `config.txt` exists with proper settings
2. **Path Issues**: Use absolute paths for input/output files
3. **XML Formatting**: Ensure proper XML structure and encoding
4. **Log Directory**: Ensure log directory exists and is writable

### Debug Mode

Enable verbose logging by setting `LogLevel` to `debug` in input XML:
```xml
<LogLevel>debug</LogLevel>
```

## Demo Customization

### Modifying Demo Data

You can customize the demo by:

1. **Changing Array Names**: Modify the array IDs and names in XML files
2. **Adding More Devices**: Include additional source/target device pairs
3. **Simulating Different States**: Change sync states and percentages
4. **Testing Error Scenarios**: Use invalid credentials or addresses

### Configuration Options

Modify `config.txt` to test different scenarios:
```
BandInfo=Custom_Storage_Brand
SraName=Custom_SRA_Name
isSupportNfs=false
isSupportStretched=false
```

## Conclusion

This demo provides a comprehensive overview of OpenSDS SRA functionality without requiring actual storage hardware. It demonstrates:

- Basic SRA operations and responses
- Typical disaster recovery workflows
- Error handling and troubleshooting
- XML interface patterns

Use this demo for training, development, testing, and integration validation with VMware Site Recovery Manager.

## Support

For additional help and advanced scenarios:
- Review the SRA Technical Architecture document
- Check the API Documentation for detailed parameter descriptions
- Examine log files for troubleshooting information
- Test with actual storage arrays for production validation
