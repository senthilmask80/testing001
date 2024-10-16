#!/bin/bash

RC='\033[0m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
GREEN='\033[0;32m'

# Check if the opt directory and Proxmox-DE folder exist, create them if they don't
# add variables to top level so can easily be accessed by all functions
SCRIPTPATH="$( dirname "$( cd "$(dirname "$0")" >/dev/null 2>&1 || exit ; pwd -P )" )"
PROXDIR="/opt/Proxmox-DE"
PROXPACK="/opt/Proxmox-DE/Openbox-DE/Openbox-DE/Packages/debian-packages.list"
PACKAGER="/opt/Proxmox-DE/Openbox-DE/Openbox-DE/Packages/"
SUDO_CMD=""
SUGROUP=""
GITPATH="$PROXDIR/Openbox-DE/Openbox-DE/bash"
OBMENU="$PROXDIR/Openbox-DE/Openbox-DE"
mkdir -p ~/.local/bin/
mkdir -p ~/.config/obmenu-generator
mkdir -p $HOME/.nvm

if [ ! -d "$PROXDIR" ]; then
    echo "${YELLOW}Creating Proxmox-DE directory: $PROXDIR${RC}"
    mkdir -p "$PROXDIR"
    echo "${GREEN}Proxmox-DE directory created: $PROXDIR${RC}"
fi

if [ -d "$PROXDIR/Openbox-DE" ]; then rm -rf "$PROXDIR/Openbox-DE"; fi
	echo "${YELLOW}Cloning Openbox-DE repository into: $PROXDIR/Openbox-DE${RC}"
	git clone https://github.com/senthilmask80/testing001.git "$PROXDIR/Openbox-DE"
if [ $? -eq 0 ]; then
	echo "${GREEN}Successfully cloned Openbox-DE repository${RC}"
else
    	echo "${RED}Failed to clone Openbox-DE repository${RC}"
exit 1
fi

cd "$PROXDIR/Openbox-DE/Openbox-DE" || exit
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
    sudo apt update && sudo apt upgrade -y
    sudo apt-get -y --ignore-missing install $(< $PROXPACK)
    sudo apt autoclean && sudo apt autoremove -y && sudo rm -rf /var/cache/apt/archives/* 

    # Install the downloaded deb file using apt-get
    sudo apt-get install $PACKAGER/fastfetch-linux-amd64.deb
    sudo apt-get install -f
    echo "Successfully installed the fastfetch"
    
    # Download the webkit-lightdm deb file
    sudo apt-get install $PACKAGER/web-greeter-3.5.3-debian.deb
    sudo apt-get install -f
    echo "Successfully installed the web-greeter"
			
    # Download the lightdm-webkit2-greeter deb file
    sudo apt-get install $PACKAGER/lightdm-webkit2-greeter.deb
    sudo apt-get install -f
    echo "Successfully installed the lightdm-webkit2-greeter"
			
    # To enable and active the services
    xdg-user-dirs-update
    sudo systemctl is-active --quiet avahi-daemon
    sudo systemctl is-enabled --quiet avahi-daemon
    sudo systemctl is-active --quiet acpid
    sudo systemctl is-enabled --quiet acpid
    sudo systemctl is-active --quiet lightdm
    sudo systemctl is-enabled --quiet lightdm
elif [ -x "$(command -v dnf)" ];
then
    sudo dnf update -y 
    sudo dnf install "${packagesNeeded[@]}"
    sudo dnf clean all && sudo dnf autoremove -y 
elif [ -x "$(command -v zypper)" ];
then
    sudo zypper install "${packagesNeeded[@]}"
else
    echo "FAILED TO INSTALL PACKAGE: Package manager not found. You must manually install: "${packagesNeeded[@]}"">&2;
fi

installRustup() {
    source ~/.bashrc
    if command_exists cargo; then
        echo "Cargo Rust Programming Language already installed"
        return
    fi

    if ! curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- --no-modify-path; then
        echo "${RED}Something went wrong during Cargo Rust Programming install!${RC}"
        exit 1
    fi
}

installStarshipAndFzf() {
    if command_exists starship; then
        echo "Starship already installed"
        return
    fi

    if ! curl -sS https://starship.rs/install.sh | sh; then
        echo "${RED}Something went wrong during starship install!${RC}"
        exit 1
    fi
    if command_exists fzf; then
        echo "Fzf already installed"
    else
        git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
        ~/.fzf/install
    fi
}

installZoxide() {
    if command_exists zoxide; then
        echo "Zoxide already installed"
        return
    fi

    if ! curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh; then
        echo "${RED}Something went wrong during zoxide install!${RC}"
        exit 1
    fi
}

create_fastfetch_config() {
    ## Get the correct user home directory.
    USER_HOME=$(getent passwd "${SUDO_USER:-$USER}" | cut -d: -f6)
    
    if [ ! -d "$USER_HOME/.config/fastfetch" ]; then
        mkdir -p "$USER_HOME/.config/fastfetch"
    fi
    # Check if the fastfetch config file exists
    if [ -e "$USER_HOME/.config/fastfetch/config.jsonc" ]; then
        rm -f "$USER_HOME/.config/fastfetch/config.jsonc"
    fi
    ln -svf "$GITPATH/config.jsonc" "$USER_HOME/.config/fastfetch/config.jsonc" || {
        echo "${RED}Failed to create symbolic link for fastfetch config${RC}"
        exit 1
    }
}

linkConfig() {
    ## Get the correct user home directory.
    USER_HOME=$(getent passwd "${SUDO_USER:-$USER}" | cut -d: -f6)
    ## Check if a bashrc file is already there.
    OLD_BASHRC="$USER_HOME/.bashrc"
    if [ -e "$OLD_BASHRC" ]; then
        echo "${YELLOW}Moving old bash config file to $USER_HOME/.bashrc.bak${RC}"
        if ! mv "$OLD_BASHRC" "$USER_HOME/.bashrc.bak"; then
            echo "${RED}Can't move the old bash config file!${RC}"
            exit 1
        fi
    fi

    echo "${YELLOW}Linking new bash config file...${RC}"
    ln -svf "$GITPATH/.bashrc" "$USER_HOME/.bashrc" || {
        echo "${RED}Failed to create symbolic link for .bashrc${RC}"
        exit 1
    }
    ln -svf "$GITPATH/starship.toml" "$USER_HOME/.config/starship.toml" || {
        echo "${RED}Failed to create symbolic link for starship.toml${RC}"
        exit 1
    }
}

install_Obmenu() {
    #source ~/.bashrc
    if command_exists obmenu-generator; then
        echo "obmenu-generator already installed"
        return
    fi
	cpan -i Gtk3
	#curl -L http://cpanmin.us | perl - --sudo Gtk3
	cpan -i Data::Dump
	#curl -L http://cpanmin.us | perl - --sudo Data::Dump
	cpan -i Linux::DesktopFiles
	#curl -L http://cpanmin.us | perl - --sudo Linux::DesktopFiles
	cpan -i File::DesktopEntry
	#curl -L http://cpanmin.us | perl - --sudo File::DesktopEntry

    # Download the obmenu deb file
    git clone https://github.com/trizen/Linux-DesktopFiles.git /tmp/Linux-DesktopFiles
    cd /tmp/Linux-DesktopFiles
    perl Build.PL
	./Build
	./Build test
    sudo ./Build install
    cp -rf $OBMENU/obmenu/ ~/.local/bin/
    obmenu-generator -p -i
    echo "Successfully installed the obmenu-generator"
    exit 1
}

installNVM() {
    #source ~/.bashrc
    if command_exists nvm; then
        echo "NVM and NodeJS already installed"
        return
    fi

    if ! curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash; then
        echo "${RED}Something went wrong during NVM and NodeJS install!${RC}"
        
    fi
}

install_Saluto() {
    #source ~/.bashrc
    if command_exists nvm; then
		nvm install v8.9.1
		nvm alias default 8.9.1
		npm install -g vue-cli
		npm install -g vue-cli --force
		if ! curl -o- https://raw.githubusercontent.com/Demonstrandum/Saluto/refs/heads/master/install.sh | sh; then
		echo "Saluto installed"
        return
        fi
    fi
}

linkConfig
installRustup
installStarshipAndFzf
installZoxide
create_fastfetch_config
install_Obmenu
installNVM
install_Saluto
create_users
