# SentinelOne Windows Installation Diagnostic
<hr>

### Current Version: 1.0

<hr>

This script performs the following tasks:
1. Logs system information such as hostname, Windows version, processor info, and architecture.
2. Fetches SentinelOne agent JSON data and checks if SentinelOne is installed.
3. Checks for SentinelOne services and processes.
4. Pings the SentinelOne management URL for network connectivity.
5. Tests WMI functionality and verifies if WMI is functioning correctly.
6. Verifies the installed certificate and machine cipher suite.
7. Generates SentinelOne agent event viewer logs.
8. Reads Sentinel Installer logs including exit code and MSI logs for Errors.
9. Provides disk information, memory information, and hotfixes installed.
10. Searches for SentinelOne related information in Application and System event logs.

### Version 1.0
Base Configuration