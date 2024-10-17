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

mkdir -p ~/.local/bin/
mkdir -p ~/.config/obmenu-generator
mkdir -p ~/.config/fbmenugen
mkdir -p /usr/share/backgrounds
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

    echo "Successfully installed the obmenu-generator"
    
}

installNVM() {
    source ~/.bashrc
    if command_exists nvm; then
	# I chose the latest LTS version, by the time I'm writing this * Gist *, it's v8.9.1. You can install it by typing:
	nvm install v8.9.1
	# To set a version of the node as default, run the following command:
	nvm alias default 8.9.1
	# Installing the vue-cli
	npm install -g vue-cli
	npm install -g vue-cli --force
	# Download the obmenu deb file
	git clone https://github.com/Demonstrandum/Saluto.git /tmp/Saluto
	cd /tmp/Saluto
  	sh ./install.sh
	echo "Successfully installed the Saluto installed"
        return
    fi

    if ! curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash; then
        echo "${RED}Something went wrong during NVM and NodeJS install!${RC}"
	# I chose the latest LTS version, by the time I'm writing this * Gist *, it's v8.9.1. You can install it by typing:
 	source ~/.bashrc
	nvm install v8.9.1
	# To set a version of the node as default, run the following command:
	nvm alias default 8.9.1
	# Installing the vue-cli
	npm install -g vue-cli
	npm install -g vue-cli --force
	# Download the obmenu deb file
	git clone https://github.com/Demonstrandum/Saluto.git /tmp/Saluto
	cd /tmp/Saluto
  	sh ./install.sh
	echo "Successfully installed the Saluto installed"
        return
    fi 	
}

final_steps() {
    cp -rf $PACKAGER/obmenu-generator/ ~/.config/
    cp -rf $PACKAGER/obmenu-generator/config.pl ~/.config/fbmenugen/config.pl
    cp -rf $PACKAGER/obmenu-generator/schema.pl ~/.config/fbmenugen/schema.pl
    cp -rf $PACKAGER/obmenu-generator/obmenu-generator ~/.local/bin/obmenu-generator
    cp -rf $PACKAGER/obmenu-generator/fbmenugen ~/.local/bin/fbmenugen
    cp -rf $PACKAGER/openbox/ ~/.config/
    cp -rf $PACKAGER/backgrounds/ ~/.config/
    cp -rf $PACKAGER/dunst/ ~/.config/
    cp -rf $PACKAGER/kitty/ ~/.config/
    cp -rf $PACKAGER/picom/ ~/.config/
    cp -rf $PACKAGER/tint2/ ~/.config/
    mv /etc/lightdm/lightdm.conf /etc/lightdm/lightdm.conf.bak1
    mv /etc/lightdm/lightdm-gtk-greeter.conf /etc/lightdm/lightdm-gtk-greeter.conf.bak1
    mv /etc/lightdm/lightdm-webkit2-greeter.conf /etc/lightdm/lightdm-webkit2-greeter.conf.bak1
    cp -rf $PACKAGER/lightdm/ /etc/
    chmod +x ~/.local/bin/obmenu-generator
    chmod 755 ~/.local/bin/obmenu-generator
    chmod +x ~/.local/bin/fbmenugen
    chmod 755 ~/.local/bin/fbmenugen
    chmod -R 755 /usr/share/lightdm-webkit/themes/
    obmenu-generator -p -i
    fbmenugen -g -i
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
 	mkdir -p /home/$username/.local/bin
	mkdir -p /home/$username/.config/obmenu-generator
	mkdir -p /home/$username/.config/fbmenugen
	mkdir -p $HOME/.nvm
 	cp -rf $PACKAGER/obmenu-generator/ /home/$username/.config/
  	cp -rf $PACKAGER/obmenu-generator/schema.pl /home/$username/.config/fbmenugen/schema.pl
   	cp -rf $PACKAGER/obmenu-generator/config.pl /home/$username/.config/fbmenugen/config.pl
    	cp -rf $PACKAGER/obmenu-generator/obmenu-generator /home/$username/.local/bin/obmenu-generator
    	cp -rf $PACKAGER/obmenu-generator/fbmenugen /home/$username/.local/bin/fbmenugen
    	cp -rf $PACKAGER/openbox/ /home/$username/.config/
    	cp -rf $PACKAGER/backgrounds/ /home/$username/.config/
    	cp -rf $PACKAGER/dunst/ /home/$username/.config/
    	cp -rf $PACKAGER/kitty/ /home/$username/.config/
    	cp -rf $PACKAGER/picom/ /home/$username/.config/
    	cp -rf $PACKAGER/tint2/ /home/$username/.config/
     	cp -rf $PACKAGER/obmenu-generator/obmenu-generator /home/$username/obmenu-generator
      	cp -rf $PACKAGER/obmenu-generator/fbmenugen /home/$username/fbmenugen
	chmod +x /home/$username/.local/bin/obmenu-generator
    	chmod 755 /home/$username/.local/bin/obmenu-generator
     	chmod +x /home/$username/.local/bin/fbmenugen
    	chmod 755 /home/$username/.local/bin/fbmenugen
     	chmod -R 755 /usr/share/lightdm-webkit/themes/
    	obmenu-generator -p -i
     	fbmenugen -g -i
fi
}

linkConfig
installRustup
installStarshipAndFzf
installZoxide
create_fastfetch_config
install_Obmenu
installNVM
final_steps
create_users
