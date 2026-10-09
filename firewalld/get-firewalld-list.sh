#!/bin/bash

# ---DOC-START---
# summary: Display firewalld ports and services for public and home zones
# description: Lists configured ports and services for the public and home firewalld zones.
# sudo: true
# interactive: false
# idempotent: true
# dependencies: none
# ---DOC-END---

set -euo pipefail
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

if [[ $EUID -ne 0 ]]; then
    echo "Please log in as root and run this script."
    exit 1
fi

echo ""
echo "List of ports, zone=public"
firewall-cmd --zone=public --list-ports

echo ""
echo "List of ports, zone=home"
firewall-cmd --zone=home --list-ports

echo ""
echo "List of services, zone=public"
firewall-cmd --zone=public --list-services

echo ""
echo "List of services, zone=home"
firewall-cmd --zone=home --list-services
