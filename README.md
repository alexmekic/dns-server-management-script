# DNS Server Management Script
Quickly create and manage DNS domains with forward and reverse zones, and populated desired hostnames and associated IP addresses on DNS servers running FreeBSD (soon available for Linux)

## Features

- Add new DNS domain zones, allowing user to specify network ID, hostnames of client/server computers and their associated IP address with default settings
- Add new DNS domain zones within a single server or main/backup DNS server environment
- Remove DNS domain zones
- Add or remove hostname and associated IP addresses to existing domain zones
- Add domain zones to the server as either a master or slave zone

## Requirements

- FreeBSD with `bind914` or later and `bash` packages installed

## Installation (to be updated with released version)

### Method 1

- Install git via command `pkg install -y git`
- Type `git clone git://github.com/kuroyoshi10/dns-server-management-script.git` to download the script file
- Type `chmod +x dns-server-management.sh` and launch the script via `./dns-server-management.sh`

### Method 2

- Manually down the script file to a USB stick or local disk to be transferred via STFTP

## To be added

- Allow other record types to be used when adding entries/hostnames to new or existing domain zones (MX, AAAA, additional NS records, CNAME)
- Conditional forwarding
- Create a version of the script for Linux

## Release history

- 1.0
  - Initial Release
