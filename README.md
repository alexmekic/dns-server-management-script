# DNS Server Setup Script
Quickly create and manage DNS domains with forward and reverse zones, and populated desired hostnames and associated IP addresses on DNS servers running FreeBSD

## Features

- Add new DNS domain zones, allowing user to specify network ID, hostnames of client/server computers and their associated IP address with default settings
- Add new DNS domain zones within a single server or main/backup DNS server environment
- Remove DNS domain zones
- Add or remove hostname and associated IP addresses to existing domain zones
- Add domain zones to the server as either a master or slave zone

## Requirements

- FreeBSD with `bind914` or later and `bash` package installed
  - Soon will be available for Linux

## To be added

- Allow other record types to be used when adding entries/hostnames to new or existing domain zones
- Create a version for Linux

## Release history

- 1.0
  - Initial Release
