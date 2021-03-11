# Manage a DNS Server and Quickly Create Local Domain Zones

## Features

- Add/remove new DNS domain zones
- Add/remove hostname to existing domain zones
- Add domain zones as either master or slave zone
- Available versions for Debian and FreeBSD

## Requirements

FreeBSD
- FreeBSD 12 with `bind914` or later and `bash` packages installed

Debian
- Debian 8 or above with `bind` package installed

## Installation

For FreeBSD:
- Download script file via `curl -L -O https://github.com/alexmekic/dns-server-management-script.sh` to download the script file
- Type `chmod +x dns-server-management.sh` and launch the script via `./dns-server-management.sh`

For Debian:
- Download script file via `curl -L -O https://github.com/alexmekic/dns-server-management-script-linux.sh` to download the script file
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
