#!/usr/bin/env bash

# nvidia32-deploy.sh - deploy a self-contained 32-bit NVIDIA userspace stack inside the prefix, WITHOUT enabling the i386 architecture on the host.
# Fetches i386 .debs from a Debian mirror, version matched to the host driver.

# Usage:  put it in the prefix root and run ./nvidia32-deploy.sh (no arguments)
# Output: <prefix>/nvidia_libs/{lib32,nvidia_icd32.json,env.txt}

# Requires: curl, xz, dpkg-deb, awk, readelf (binutils)

set -euo pipefail

MIRROR=http://deb.debian.org/debian
COMP=non-free
SUITE=$(. /etc/os-release 2>/dev/null && echo "${VERSION_CODENAME:-}")
SUITE=${SUITE:-trixie}
SEED=(libgl1-nvidia-glvnd-glx libnvidia-glcore libnvidia-eglcore libegl-nvidia0
      libgles-nvidia1 libgles-nvidia2 libnvidia-glvkspirv libnvidia-gpucomp)

# Prefix root = directory of this script
ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/nvidia_libs
LIB="$ROOT/lib32"

for t in curl xz dpkg-deb awk readelf; do
  command -v "$t" >/dev/null || { echo "Missing tool: $t" >&2; exit 1; }
done

# Host driver version
HOSTVER=$(awk '/NVRM version/ {for(i=1;i<=NF;i++) if($i ~ /^[0-9]+\.[0-9]+(\.[0-9]+)?$/) v=$i} END{print v}' \
          /proc/driver/nvidia/version 2>/dev/null || true)
[[ -n $HOSTVER ]] || { echo "Cannot detect the driver version (/proc/driver/nvidia/version)." >&2; exit 1; }
echo "Host driver: $HOSTVER"

mkdir -p "$ROOT"/{debs,tmp,lib32}
cd "$ROOT"

echo "Fetching the package index: $SUITE/$COMP/i386."
curl -fsSL "$MIRROR/dists/$SUITE/$COMP/binary-i386/Packages.xz" | xz -dc > tmp/Packages

# Package record: Version<TAB>Filename<TAB>Depends
pkginfo() {
  awk -v p="$1" 'BEGIN{RS="";FS="\n"}
    { n=""; v=""; f=""; d="";
      for(i=1;i<=NF;i++){
        if($i ~ /^Package: /)  n=substr($i,10);
        if($i ~ /^Version: /)  v=substr($i,10);
        if($i ~ /^Filename: /) f=substr($i,11);
        if($i ~ /^Depends: /)  d=substr($i,10);
      }
      if(n==p){print v "\t" f "\t" d; exit}
    }' tmp/Packages
}

# Resolve dependencies recursively, nvidia packages only
declare -A seen
queue=("${SEED[@]}")
todo=()
while ((${#queue[@]})); do
  p=${queue[0]}; queue=("${queue[@]:1}")
  [[ -n ${seen[$p]:-} ]] && continue
  seen[$p]=1
  info=$(pkginfo "$p")
  if [[ -z $info ]]; then echo "Skipping $p: not in the index."; continue; fi
  IFS=$'\t' read -r ver file deps <<<"$info"
  if [[ $ver != "$HOSTVER"* ]]; then
    echo "WARNING: $p is $ver but the host driver is $HOSTVER. The versions must match." >&2
  fi
  todo+=("$file")
  # First name of each alternative, without version constraints or :arch
  while read -r d; do
    [[ $d == *nvidia* ]] && queue+=("$d")
  done < <(tr ',' '\n' <<<"$deps" | sed -E 's/\|.*//; s/\(.*//; s/:[a-z0-9]+//; s/[[:space:]]//g')
done

((${#todo[@]})) || { echo "Nothing to download." >&2; exit 1; }

for f in "${todo[@]}"; do
  b=${f##*/}
  [[ -s debs/$b ]] || { echo "Downloading $b."; curl -fsSL -o "debs/$b" "$MIRROR/$f"; }
  dpkg-deb -x "debs/$b" tmp/x
done

# Flatten all shared objects into lib32
find tmp/x -type f -name '*.so*' -exec cp -f {} "$LIB"/ \;
find tmp/x -type l -name '*.so*' -exec cp -fP {} "$LIB"/ \; 2>/dev/null || true

# SONAME symlinks (Debian creates these in postinst/alternatives)
for so in "$LIB"/*.so.*; do
  [[ -f $so && ! -L $so ]] || continue
  sn=$(readelf -d "$so" 2>/dev/null | awk '/SONAME/ {gsub(/[\[\]]/,"",$NF); print $NF}')
  [[ -n $sn && ! -e $LIB/$sn ]] && ln -s "$(basename "$so")" "$LIB/$sn"
done

# 32-bit Vulkan ICD
cat > nvidia_icd32.json <<EOF
{
  "file_format_version": "1.0.1",
  "ICD": {
    "library_path": "$LIB/libGLX_nvidia.so.0",
    "api_version": "1.3.277"
  }
}
EOF

[[ -e $LIB/libGLX_nvidia.so.0 ]] || echo "WARNING: libGLX_nvidia.so.0 was not found in $LIB." >&2

cat > env.txt <<EOF
STEAM_COMPAT_LIBRARY_PATHS=$LIB
LD_LIBRARY_PATH=$LIB
VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/nvidia_icd.json:$ROOT/nvidia_icd32.json
EOF

rm -rf tmp
echo
echo "Done: $ROOT"
echo "Environment variables for Heroic (also saved to $ROOT/env.txt):"
cat env.txt
