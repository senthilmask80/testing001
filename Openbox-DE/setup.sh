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
git clone https://github.com/ChrisTitusTech/mybash "$PROXMOXDEDIR/Openbox-DE"
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

cd "$PROXMOXDEDIR/Openbox-DE" || exit
maindir=$PWD

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

create_users() {
if [ $(id -u) -eq 0 ]; then
read -p "Enter username : " username
read -p "Enter password : " password
GROUP=Proxmox-DE


egrep "^$username" /etc/passwd >/dev/null

if id "$username" &>/dev/null; then
	echo "User $username already exists. Skipping..."
fi

# Create personal group with the same name as the user
if ! getent group "$username" &>/dev/null; then
	if ! groupadd "$username" 2>/dev/null; then
		echo "Failed to create group $username. Permission denied."
	fi
		echo "\nGroup $username created."
	fi

	# Create the user with the personal group
	if ! useradd -m -g "$username" -s /bin/bash "$username" 2>/dev/null; then
		echo "Failed to create user $username. Permission denied."
	fi
	echo "User $username created with home directory."

	if ! getent group "$GROUP" &>/dev/null; then
		if ! groupadd "$GROUP" 2>/dev/null; then
			echo "Failed to create group $GROUP. Permission denied."
		fi
		echo "Group $GROUP created."
	fi
	if ! usermod -aG "$GROUP" "$username" 2>/dev/null; then
		echo "Failed to add user $username to group $group. Permission denied."
	fi
		echo "User $username added to group $group."

	# Set up home directory permissions
	chmod 700 "/home/$username"
	chown "$username:$username" "/home/$username"
	echo "$username:$password" | sudo chpasswd
	echo "User creation process completed." 
	chown -R :$GROUP /opt/Proxmox-DE
fi
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

installRustup() {
    if command_exists cargo; then
        echo "Cargo Rust Programming Language already installed"
        return
    fi

    if ! curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh; then
        echo "${RED}Something went wrong during Cargo Rust Programming install!${RC}"
        exit 1
    fi
}

installNVM() {
    if command_exists nvm; then
        echo "NVM and NodeJS already installed"
        return
    fi

    if ! curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | sh; then
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

# Show the current distribution
distribution () {
    local dtype="unknown"  # Default to unknown

    # Use /etc/os-release for modern distro identification
    if [ -r /etc/os-release ]; then
        source /etc/os-release
        case $ID in
            fedora|rhel|centos)
                dtype="redhat"
                ;;
            sles|opensuse*)
                dtype="suse"
                ;;
            ubuntu|debian)
                dtype="debian"
                ;;
            gentoo)
                dtype="gentoo"
                ;;
            arch|manjaro)
                dtype="arch"
                ;;
            slackware)
                dtype="slackware"
                ;;
            *)
                # Check ID_LIKE only if dtype is still unknown
                if [ -n "$ID_LIKE" ]; then
                    case $ID_LIKE in
                        *fedora*|*rhel*|*centos*)
                            dtype="redhat"
                            ;;
                        *sles*|*opensuse*)
                            dtype="suse"
                            ;;
                        *ubuntu*|*debian*)
                            dtype="debian"
                            ;;
                        *gentoo*)
                            dtype="gentoo"
                            ;;
                        *arch*)
                            dtype="arch"
                            ;;
                        *slackware*)
                            dtype="slackware"
                            ;;
                    esac
                fi

                # If ID or ID_LIKE is not recognized, keep dtype as unknown
                ;;
        esac
    fi

    echo $dtype
}


DISTRIBUTION=$(distribution)
if [ "$DISTRIBUTION" = "redhat" ] || [ "$DISTRIBUTION" = "arch" ]; then
      alias cat='bat'
else
      alias cat='batcat'
fi 

# Show the current version of the operating system
ver() {
    local dtype
    dtype=$(distribution)

    case $dtype in
        "redhat")
            if [ -s /etc/redhat-release ]; then
                cat /etc/redhat-release
            else
                cat /etc/issue
            fi
            uname -a
            ;;
        "suse")
            cat /etc/SuSE-release
            ;;
        "debian")
            lsb_release -a
            ;;
        "gentoo")
            cat /etc/gentoo-release
            ;;
        "arch")
            cat /etc/os-release
            ;;
        "slackware")
            cat /etc/slackware-version
            ;;
        *)
            if [ -s /etc/issue ]; then
                cat /etc/issue
            else
                echo "Error: Unknown distribution"
                exit 1
            fi
            ;;
    esac
}

# Automatically install the needed support files for this .bashrc file
install_Common_Packages() {
	local dtype
	dtype=$(distribution)
	pkgs=(zoxide trash-cli fzf fastfetch build-essential aptitude apt-transport-https  \
			software-properties-common gnupg ca-certificates openbox tint2 terminator firefox-esr xfce4-appfinder xorg \
			xinit dialog menu obconf xfce4-power-manager acpi acpid autoconf libnotify-bin xinput xdotool xcompmgr \
			dosfstools mtools xdg-user-dirs xserver-xorg xserver-common xserver-xephyr xbacklight xbindkeysxvkbd \
			lxappearance lxappearance-obconf feh redshift lightdm lightdm-settings lightdm-gtk-greeter policykit-1-gnome \
			lightdm-gtk-greeter-settings slick-greeter gnome-common liblightdm-gobject-dev libgtk-3-dev libwebkit2gtk-4.0-dev \
			network-manager network-manager-gnome avahi-daemon gvfs-backends binutils dnsutils rofi dunst fileroller \
			unzip p7zip zip exa scrot xclip nitrogen ristretto gmrun numlockx dbus-x11 hsetroot qt5-style-plugin htop \
			xscreensaver-gl-extra xscreensaver-data-extra conky cairo-dock pulseaudio pavucontrol volumeicon-alsa pamixer \
			pulsemixer fonts-recommended fonts-font-awesome fonts-terminus fonts-noto libdbus-glib-1-dev \
			perl perl-doc libmodule-build-perl libgtk3-perl libssl-dev)

	case $dtype in
		"redhat")
			sudo yum install multitail tree zoxide trash-cli fzf bash-completion fastfetch
			;;
		"suse")
			sudo zypper install multitail tree zoxide trash-cli fzf bash-completion fastfetch
			;;
		"debian")
			#sudo apt-get -y --ignore-missing install "${pkgs[@]}"
			# https://unix.stackexchange.com/questions/717483/creating-a-bash-script-to-install-packages
			sudo apt-get -y --ignore-missing install $(< debian-packages.list)
			
			# Fetch the latest fastfetch release URL for linux-amd64 deb file
			FASTFETCH_URL=$(curl -s https://api.github.com/repos/fastfetch-cli/fastfetch/releases/latest | grep "browser_download_url.*linux-amd64.deb" | cut -d '"' -f 4)

			# Download the latest fastfetch deb file
			curl -sL $FASTFETCH_URL -o /tmp/fastfetch_latest_amd64.deb

			# Install the downloaded deb file using apt-get
			sudo apt-get install /tmp/fastfetch_latest_amd64.deb
			sudo apt-get install -f
			echo "Successfully installed the fastfetch"
			
			# Download the webkit-lightdm deb file
			wget https://github.com/senthilmask80/Proxmox-DE/blob/main/webkit-lightdm/web-greeter-3.5.3-debian.deb -o /tmp/web-greeter-3.5.3-debian.deb
			sudo apt-get install /tmp/web-greeter-3.5.3-debian.deb
			sudo apt-get install -f
			echo "Successfully installed the web-greeter"
			
			# Download the lightdm-webkit2-greeter deb file
			wget https://github.com/senthilmask80/Proxmox-DE/blob/main/webkit-lightdm/lightdm-webkit2-greeter.deb -o /tmp/lightdm-webkit2-greeter.deb
			sudo apt-get install /tmp/lightdm-webkit2-greeter.deb
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
			;;
		"arch")
			sudo paru multitail tree zoxide trash-cli fzf bash-completion fastfetch
			;;
		"slackware")
			echo "No install support for Slackware"
			;;
		*)
			echo "Unknown distribution"
			;;
	esac
}

install_additional_dependencies() {
    # we have PACKAGER so just use it
    # for now just going to return early as we have already installed neovim in `installDepend`
    # so I am not sure why we are trying to install it again
    return
   case "$PACKAGER" in
        *apt)
            if [ ! -d "/opt/neovim" ]; then
                curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim.appimage
                chmod u+x nvim.appimage
                ./nvim.appimage --appimage-extract
                ${SUDO_CMD} mv squashfs-root /opt/neovim
                ${SUDO_CMD} ln -s /opt/neovim/AppRun /usr/bin/nvim
            fi
            ;;
        *zypper)
            ${SUDO_CMD} zypper refresh
            ${SUDO_CMD} zypper -n install neovim # -y doesn't work on opensuse -n is short for -non-interactive which is equivalent to -y
            ;;
        *dnf)
            ${SUDO_CMD} dnf check-update
            ${SUDO_CMD} dnf install -y neovim
            ;;
        *pacman)
            ${SUDO_CMD} pacman -Syu
            ${SUDO_CMD} pacman -S --noconfirm neovim
            ;;
        *)
            echo "No supported package manager found. Please install neovim manually."
            exit 1
            ;;
    esac
}


install_Obmenu() {
    if command_exists obmenu-generator; then
        echo "obmenu-generator already installed"
        return
    fi

    if ! curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh; then
		cpan -i Gtk3
		#curl -L http://cpanmin.us | perl - --sudo Gtk3
		cpan -i Data::Dump
		#curl -L http://cpanmin.us | perl - --sudo Data::Dump
		cpan -i Linux::DesktopFiles
		#curl -L http://cpanmin.us | perl - --sudo Linux::DesktopFiles
		cpan -i File::DesktopEntry
		#curl -L http://cpanmin.us | perl - --sudo File::DesktopEntry
        echo "${RED}Something went wrong during Cargo Rust Programming install!${RC}"
        exit 1
    fi
}

install_Saluto() {
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
installStarshipAndFzf
installZoxide
create_fastfetch_config
linkConfig
install_Common_Packages
install_additional_dependencies
install_Obmenu
install_Saluto
create_users
