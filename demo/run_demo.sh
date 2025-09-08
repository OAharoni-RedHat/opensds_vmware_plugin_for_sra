#!/bin/bash
echo "======================================"
echo "OpenSDS SRA Demo Workflow"
echo "======================================"

echo
echo "1. Querying SRA Information..."
./sra < inputs/demo_query_info.xml
if [ $? -ne 0 ]; then
    echo "ERROR: Query Info failed"
    exit 1
fi
echo "SUCCESS: SRA Information retrieved"

echo
echo "2. Discovering Storage Arrays..."
./sra < inputs/demo_discover_arrays.xml
if [ $? -ne 0 ]; then
    echo "ERROR: Array Discovery failed"
    exit 1
fi
echo "SUCCESS: Arrays discovered"

echo
echo "3. Discovering Replicated Devices..."
./sra < inputs/demo_discover_devices.xml
if [ $? -ne 0 ]; then
    echo "ERROR: Device Discovery failed"
    exit 1
fi
echo "SUCCESS: Devices discovered"

echo
echo "4. Checking Synchronization Status..."
./sra < inputs/demo_query_sync_status.xml
if [ $? -ne 0 ]; then
    echo "ERROR: Sync Status Query failed"
    exit 1
fi
echo "SUCCESS: Sync status retrieved"

echo
echo "5. Preparing for Failover..."
./sra < inputs/demo_prepare_failover.xml
if [ $? -ne 0 ]; then
    echo "ERROR: Failover Preparation failed"
    exit 1
fi
echo "SUCCESS: Failover preparation completed"

echo
echo "6. Starting Test Failover..."
./sra < inputs/demo_test_failover_start.xml
if [ $? -ne 0 ]; then
    echo "ERROR: Test Failover Start failed"
    exit 1
fi
echo "SUCCESS: Test failover started"

echo
echo "======================================"
echo "Demo completed successfully!"
echo "Check the outputs/ directory for responses"
echo "Check the logs/ directory for detailed logs"
echo "======================================"
