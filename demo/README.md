# OpenSDS SRA Demo Environment

## Quick Start

This demo folder contains everything needed to test the OpenSDS SRA functionality without requiring an actual storage array.

### Directory Structure

```
demo/
├── README.md               # This file
├── config.txt             # Demo configuration
├── run_demo.bat           # Windows automation script
├── run_demo.sh            # Linux/macOS automation script
├── inputs/                # Demo XML input files
│   ├── demo_query_info.xml
│   ├── demo_discover_arrays.xml
│   ├── demo_discover_devices.xml
│   ├── demo_query_sync_status.xml
│   ├── demo_prepare_failover.xml
│   ├── demo_test_failover_start.xml
│   └── demo_error_handling.xml
├── outputs/               # Generated response files (created when demo runs)
└── logs/                  # Log files (created when demo runs)
```

### Prerequisites

1. Copy the compiled `sra.exe` (Windows) or `sra` (Linux) to this directory
2. Ensure the executable has proper permissions
3. Make sure you have write access to outputs/ and logs/ directories

### Running Individual Commands

```bash
# Windows
sra.exe < inputs/demo_query_info.xml

# Linux/macOS
./sra < inputs/demo_query_info.xml
```

### Running Complete Demo

```bash
# Windows
run_demo.bat

# Linux/macOS
./run_demo.sh
```

### Expected Results

After running the demo:
- Response XML files will appear in `outputs/`
- Detailed logs will appear in `logs/`
- Return code 0 indicates success

### Demo Commands Included

1. **queryInfo** - Basic SRA information
2. **discoverArrays** - Storage array discovery
3. **discoverDevices** - Replicated device discovery
4. **querySyncStatus** - Synchronization status check
5. **prepareFailover** - Failover preparation
6. **testFailoverStart** - Test failover execution
7. **Error Handling** - Example error scenario

### Configuration

The `config.txt` file contains demo-specific settings:
- Demo brand information
- SRA name customization
- Feature flags for testing

### Troubleshooting

1. **Permission Denied**: Make scripts executable with `chmod +x`
2. **Missing Executable**: Copy the SRA binary to this directory
3. **Path Issues**: Use absolute paths if relative paths fail
4. **XML Errors**: Ensure proper XML formatting in input files

### Customization

You can modify the demo by:
- Editing XML input files to test different scenarios
- Changing configuration in `config.txt`
- Adding new XML commands to the inputs/ directory
- Modifying automation scripts for different workflows

For detailed information, see the main SRA_Demo_Guide.md in the project root.
