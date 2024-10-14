#!/bin/bash

RC='\033[0m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
GREEN='\033[0;32m'

# Check if the opt directory and Proxmox-DE folder exist, create them if they don't
PROXMOXDEDIR="/opt/Proxmox-DE"

if [ ! -d "$PROXMOXDEDIR" ]; then
    echo "${YELLOW}Creating Proxmox-DE directory: $PROXMOXDEDIR${RC}"
    mkdir -p "$PROXMOXDEDIR"
    echo "${GREEN}Proxmox-DE directory created: $PROXMOXDEDIR${RC}"
fi

if [ -d "$PROXMOXDEDIR/Openbox-DE" ]; then rm -rf "$PROXMOXDEDIR/Openbox-DE"; fi

echo "${YELLOW}Cloning Openbox-DE repository into: $PROXMOXDEDIR/Openbox-DE${RC}"
git clone https://github.com/senthilmask80/testing001.git "$PROXMOXDEDIR/Openbox-DE"
if [ $? -eq 0 ]; then
    echo "${GREEN}Successfully cloned Openbox-DE repository${RC}"
else
    echo "${RED}Failed to clone Openbox-DE repository${RC}"
    exit 1
fi

# add variables to top level so can easily be accessed by all functions
PACKAGER=""
SUDO_CMD=""
SUGROUP=""
GITPATH=""

cd "$PROXMOXDEDIR/Openbox-DE/Openbox-DE" || exit
maindir=$PWD

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

packagesNeeded=(curl jq)
if [ -x "$(command -v apk)" ];
then
    sudo apk add --no-cache "${packagesNeeded[@]}"
elif [ -x "$(command -v apt-get)" ];
then
    sudo apt-get -y update && sudo apt-get -y upgrade 
    sudo apt-get -y --ignore-missing install $(< debian-packages.list)
elif [ -x "$(command -v dnf)" ];
then
    sudo dnf install "${packagesNeeded[@]}"
elif [ -x "$(command -v zypper)" ];
then
    sudo zypper install "${packagesNeeded[@]}"
else
    echo "FAILED TO INSTALL PACKAGE: Package manager not found. You must manually install: "${packagesNeeded[@]}"">&2;
fi
