# MICROSOFT WINDOWS FIREWALL WITH ADVANCED SECURITY STIG

## Overview

This role is based on STIG WNFWA: Version 2 Release 1  - 01 November 2021

Set of configuration files and directories to run the audit using goss on windows firewall.

It consists of a powershell script to be run on the host and query that the correct registry entries have been added.

## System Requirements

You must have

- [goss](https://github.com/aelsabbahy/goss/) available to your host you would like to test.
- Permissions to query the registry
- Powershell 5.1
- Confirm if domain based policy of standalone policies are to be checked (default domain - see below STIG.yml)

## Usage

Running the audit via script:

- Variables: The ability to set variables is contained in the file run_audit.ps1 (see below for futher information)
  - The location of goss must be correct in the script
- Output: Summary conatined at the completion of the script as well as location for detailed output

## Detailed

### Breakdown

The script itself discovers some items abouyt the host it is running on to discover which registry paths to check.

Discovers if

- it is a workstation or a server
- domain member
- hostname
- time (epoch based)
- locale
- os build version
- os name
- machine uuid

### Variables

- run_audit.ps1 # host based and discovered variables
  - variables passed to the goss.yml to decide which set of set of test to run
  - either
    - domain based
    - standalone based
- STIG.yml # variables used to defined which benchmark tests are carried out

Normally Only the first lines in the run_audit.ps1 should be changed

These variables alongside those discovered in STIG.yml

#### run_audit.ps1

- Set the goss executable location
- Set the content location for goss configurations and detailed outputs

```ps
$AUDIT_BIN = "C:\vagrant\goss.exe" - Ensure this is set to the correct location
$AUDIT_CONTENT_LOCATION = "C:\vagrant" - Path to store/read the content

# The following shouldnt be changed unless you understand what you are changing.
$BENCHMARK = "STIG"
$AUDIT_FILE = "WNFWA\goss.yml" - should not be changed unless using an alterative variables file
$AUDIT_VARS = "WNFWA\$BENCHMARK.yml" - No reason to change this
$AUDIT_CONTENT_VERSION = "WNFWA-$BENCHMARK-Audit" - No reason to change this
$AUDIT_CONTENT_DIR = "$AUDIT_CONTENT_LOCATION\$AUDIT_CONTENT_VERSION" 
```

#### STIG.yml

This is the benchmark control file and allows which specific benchmarks to check for, using which set of rules.

By default it would be looking to check the registry keys associated with a domain based system

```ps
Registry path:
HKLM:/SOFTWARE/Policies/Microsoft/WindowsFirewall
```

By following value to false

- domain_based_policy

This will check the alternate registry location for configurations

```ps
Registry path:
HKLM:SYSTEM/CurrentControlSet/Services/SharedAccess/Parameters/FirewallPolicy
```
