#!/bin/bash

RC='\033[0m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
GREEN='\033[0;32m'

# Check if the opt directory and Proxmox-DE folder exist, create them if they don't
SCRIPTPATH="$( dirname "$( cd "$(dirname "$0")" >/dev/null 2>&1 || exit ; pwd -P )" )"
PROXDIR="/opt/Proxmox-DE"
PROXPACK="/opt/Proxmox-DE/Openbox-DE/Openbox-DE/Packages/debian-packages.list"

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

# add variables to top level so can easily be accessed by all functions
PACKAGER=""
SUDO_CMD=""
SUGROUP=""
GITPATH=""

cd "$PROXDIR/Openbox-DE/Openbox-DE" || exit
maindir=$PWD

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

checkEnv() {
    ## Check for requirements.
    REQUIREMENTS='curl wget git groups sudo'
    for req in $REQUIREMENTS; do
        if ! command_exists "$req"; then
            echo "${RED}To run me, you need: $REQUIREMENTS${RC}"
            exit 1
        fi
    done

    ## Check Package Handler
    PACKAGEMANAGER='nala apt dnf yum pacman zypper emerge xbps-install nix-env'
    for pgm in $PACKAGEMANAGER; do
        if command_exists "$pgm"; then
            PACKAGER="$pgm"
            echo "Using $pgm"
            break
        fi
    done

    if [ -z "$PACKAGER" ]; then
        echo "${RED}Can't find a supported package manager${RC}"
        exit 1
    fi

    if command_exists sudo; then
        SUDO_CMD="sudo"
    elif command_exists doas && [ -f "/etc/doas.conf" ]; then
        SUDO_CMD="doas"
    else
        SUDO_CMD="su -c"
    fi

    echo "Using $SUDO_CMD as privilege escalation software"

    ## Check if the current directory is writable.
    GITPATH=$(dirname "$(realpath "$0")")
    if [ ! -w "$GITPATH" ]; then
        echo "${RED}Can't write to $GITPATH${RC}"
        exit 1
    fi

    ## Check SuperUser Group

    SUPERUSERGROUP='wheel sudo root'
    for sug in $SUPERUSERGROUP; do
        if groups | grep -q "$sug"; then
            SUGROUP="$sug"
            echo "Super user group $SUGROUP"
            break
        fi
    done

    ## Check if member of the sudo group.
    if ! groups | grep -q "$SUGROUP"; then
        echo "${RED}You need to be a member of the sudo group to run me!${RC}"
        exit 1
    fi
}

installDepend() {
    ## Check for dependencies.
    DEPENDENCIES='bash bash-completion tar bat tree multitail fastfetch wget unzip fontconfig'
    if ! command_exists nvim; then
        DEPENDENCIES="${DEPENDENCIES} neovim"
    fi

    echo "${YELLOW}Installing dependencies...${RC}"
    if [ "$PACKAGER" = "pacman" ]; then
        if ! command_exists yay && ! command_exists paru; then
            echo "Installing yay as AUR helper..."
            ${SUDO_CMD} ${PACKAGER} --noconfirm -S base-devel
            cd /opt && ${SUDO_CMD} git clone https://aur.archlinux.org/yay-git.git && ${SUDO_CMD} chown -R "${USER}:${USER}" ./yay-git
            cd yay-git && makepkg --noconfirm -si
        else
            echo "AUR helper already installed"
        fi
        if command_exists yay; then
            AUR_HELPER="yay"
        elif command_exists paru; then
            AUR_HELPER="paru"
        else
            echo "No AUR helper found. Please install yay or paru."
            exit 1
        fi
        ${AUR_HELPER} --noconfirm -S ${DEPENDENCIES}
    elif [ "$PACKAGER" = "nala" ]; then
        ${SUDO_CMD} ${PACKAGER} install -y ${DEPENDENCIES}
    elif [ "$PACKAGER" = "emerge" ]; then
        ${SUDO_CMD} ${PACKAGER} -v app-shells/bash app-shells/bash-completion app-arch/tar app-editors/neovim sys-apps/bat app-text/tree app-text/multitail app-misc/fastfetch
    elif [ "$PACKAGER" = "xbps-install" ]; then
        ${SUDO_CMD} ${PACKAGER} -v ${DEPENDENCIES}
    elif [ "$PACKAGER" = "nix-env" ]; then
        ${SUDO_CMD} ${PACKAGER} -iA nixos.bash nixos.bash-completion nixos.gnutar nixos.neovim nixos.bat nixos.tree nixos.multitail nixos.fastfetch  nixos.pkgs.starship
    elif [ "$PACKAGER" = "dnf" ]; then
        ${SUDO_CMD} ${PACKAGER} install -y ${DEPENDENCIES}
    else
        ${SUDO_CMD} ${PACKAGER} install -yq ${DEPENDENCIES}
    fi

    # Check to see if the MesloLGS Nerd Font is installed (Change this to whatever font you would like)
    FONT_NAME=("Meslo" "Noto" "Mononoki" "CascadiaCode" "FiraCode" "Hack" "Inconsolata" "JetBrainsMono" "RobotoMono" "SourceCodePro" "UbunutuMono")
    for FONT in "${FONT_NAME[@]}"
    do
    if fc-list :family | grep -iq "$FONT"; then
        echo "Font '$FONT' is installed."
    else
        echo "Installing font '$FONT'"
        # Change this URL to correspond with the correct font
        FONT_URL="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/v3.2.1/$FONT.zip"
        FONT_DIR="$HOME/.local/share/fonts"
        # check if the file is accessible
        if wget -q --spider "$FONT_URL"; then
            TEMP_DIR=$(mktemp -d)
            wget -q --show-progress $FONT_URL -O "$TEMP_DIR"/"$FONT".zip
            unzip "$TEMP_DIR"/"$FONT".zip -d "$TEMP_DIR"
            mkdir -p "$FONT_DIR"/"$FONT"
            mv "${TEMP_DIR}"/*.ttf "$FONT_DIR"/"$FONT"
            # Update the font cache
            fc-cache -fv
            # delete the files created from this
            rm -rf "${TEMP_DIR}"
            echo "'$FONT' installed successfully."
            continue
        else
            echo "Font '$FONT_NAME' not installed. Font URL is not accessible."
        fi
    fi
    done
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
    sudo apt-get install /opt/Proxmox-DE/Openbox-DE/Openbox-DE/Packages/fastfetch-linux-amd64.deb
    sudo apt-get install -f
    echo "Successfully installed the fastfetch"
    
    # Download the webkit-lightdm deb file
    sudo apt-get install /opt/Proxmox-DE/Openbox-DE/Openbox-DE/Packages/web-greeter-3.5.3-debian.deb
    sudo apt-get install -f
    echo "Successfully installed the web-greeter"
			
    # Download the lightdm-webkit2-greeter deb file
    sudo apt-get install /opt/Proxmox-DE/Openbox-DE/Openbox-DE/Packages//lightdm-webkit2-greeter.deb
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

installNVM() {
    source ~/.bashrc
    if command_exists nvm; then
        echo "NVM and NodeJS already installed"
        return
    fi

    if ! curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash; then
        echo "${RED}Something went wrong during NVM and NodeJS install!${RC}"
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
    source ~/.bashrc
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
        exit 1
}

install_Saluto() {
    source ~/.bashrc
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

checkEnv
installDepend
installRustup
installNVM
installStarshipAndFzf
installZoxide
create_fastfetch_config
linkConfig
install_Obmenu
install_Obmenu
install_Saluto
create_users
