#!/bin/bash

set -euo pipefail
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

if [[ -t 1 ]]; then
    RED='\033[0;31m'
    YELLOW='\033[1;33m'
    NC='\033[0m'
else
    RED='' YELLOW='' NC=''
fi

trap 'echo -e "\n${RED}Script interrupted${NC}"; exit 130' INT TERM

if ! command -v docker >/dev/null 2>&1; then
    echo -e "\n${YELLOW}Docker is not installed on this system.${NC}\n"
    exit 0
fi

# Test Docker daemon access
if ! docker info >/dev/null 2>&1; then
    echo -e "\n${RED}Error: Cannot connect to the Docker daemon. Run as root or add user to 'docker' group.${NC}\n"
    exit 1
fi

printf "\n${YELLOW}DOCKER INFORMATION:${NC}\n\n"

echo -e "${YELLOW}Containers (docker ps -a):${NC}"
docker ps -a

echo -e "\n${YELLOW}Networks (docker network ls):${NC}"
docker network ls

echo -e "\n${YELLOW}Volumes (docker volume ls):${NC}"
docker volume ls

echo -e "\n${YELLOW}System Info Summary:${NC}"
docker info | grep -E "(Containers|Running|Paused|Stopped|Images|Server Version|Storage Driver)"

echo ""
