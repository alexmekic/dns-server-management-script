# DNS Server Management Script
Quickly create and manage DNS domains with forward and reverse zones, and populated desired hostnames and associated IP addresses on DNS servers running FreeBSD (soon available for Linux)

## Features

- Add new DNS domain zones, allowing user to specify network ID, hostnames of client/server computers and their associated IP address with default settings
- Add new DNS domain zones within a single server or main/backup DNS server environment
- Remove DNS domain zones
- Add or remove hostname and associated IP addresses to existing domain zones
- Add domain zones to the server as either a master or slave zone

## Requirements

FreeBSD
- FreeBSD 12 with `bind914` or later and `bash` packages installed


Debian
- Debian 8 or above with `bind` package installed

## Installation

For FreeBSD:
- Download script file via `curl https://github.com/alexmekic/dns-server-management-script.sh` to download the script file
- Type `chmod +x dns-server-management.sh` and launch the script via `./dns-server-management.sh`

For Debian:
- Download script file via `curl https://github.com/alexmekic/dns-server-management-script-linux.sh` to download the script file
- Type `chmod +x dns-server-management-linux.sh` and launch the script via `./dns-server-management-linux.sh`

## To be added

- Allow other record types to be used when adding entries/hostnames to new or existing domain zones (MX, AAAA, additional NS records, CNAME)

## Release history

- 1.0
  - Initial Release
- 1.1
  - Linux for Debian version available
  - Redirected location of zones to the following directories:
    - FreeBSD: `/usr/local/etc/namedb/zones`
    - Debian: `/etc/bind/zones`