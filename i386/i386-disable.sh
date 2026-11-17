#!/usr/bin/env bash
# Remove all i386 packages and disable the i386 architecture.
set -euo pipefail

sudo apt purge '?architecture(i386)'
sudo dpkg --remove-architecture i386
sudo apt update
