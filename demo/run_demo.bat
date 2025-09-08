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
