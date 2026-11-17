#!/usr/bin/env bash
# Enable the i386 architecture and install the 32-bit NVIDIA and Vulkan libraries.
set -euo pipefail

sudo dpkg --add-architecture i386
sudo apt update
sudo apt install nvidia-driver-libs:i386 libvulkan1:i386
