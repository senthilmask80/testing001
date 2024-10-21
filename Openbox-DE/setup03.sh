#! /bin/bash

RC='\033[0m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
GREEN='\033[0;32m'

# Check if the opt directory and Proxmox-DE folder exist, create them if they don't
# add variables to top level so can easily be accessed by all functions

xdg-user-dirs-update
PROXDIR="/tmp"

if [ ! -d "$PROXDIR" ]; then
    echo "${YELLOW}Creating Proxmox-DE directory: $PROXDIR${RC}"
    mkdir -p "$PROXDIR/Openbox-DE"
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

if [ -d "$PROXDIR/ProxDot" ]; then rm -rf "$PROXDIR/ProxDot"; fi
	echo "${YELLOW}Cloning Proxmox-Dotfiles repository into: $PROXDIR/ProxDot${RC}"
	git clone https://github.com/senthilmask80/Proxmox-Dotfiles "$PROXDIR/ProxDot"
if [ $? -eq 0 ]; then
	echo "${GREEN}Successfully cloned Proxmox-Dotfiles repository${RC}"
else
    	echo "${RED}Failed to clone Proxmox-Dotfiles repository${RC}"
exit 1
fi

cd "$PROXDIR/Openbox-DE" || exit

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
    sudo apt-get -y --ignore-missing install $(< $PROXDIR/Openbox-DE/Openbox-DE/Scripts/debian-packages.list)
    sudo apt autoclean && sudo apt autoremove -y && sudo rm -rf /var/cache/apt/archives/*
    # To enable and active the services
    xdg-user-dirs-update
    sudo systemctl is-active --quiet avahi-daemon
    sudo systemctl is-enabled --quiet avahi-daemon
    sudo systemctl is-active --quiet acpid
    sudo systemctl is-enabled --quiet acpid
    sudo systemctl is-active --quiet lightdm
    sudo systemctl is-enabled --quiet lightdm
    echo "${GREEN}LightDM and Openbox Successfully Installed${RC}"
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

install_Packages() {
    # Install the Lightdm-Webkit2-greeter source file
    mkdir -p /usr/share/backgrounds
    mkdir -p /usr/share/lightdm-webkit/themes/
    chmod +x $PROXDIR/Openbox-DE/Openbox-DE/Scripts/webkit2.sh
    bash $PROXDIR/Openbox-DE/Openbox-DE/Scripts/webkit2.sh
    chmod -R 755 /usr/share/lightdm-webkit/themes/
    echo "Successfully installed the lightdm-webkit2-greeter"

    # Install the downloaded deb file using apt-get
    sudo apt-get install $PROXDIR/ProxDot/packages/bunsen-thunar_11.0-2_all.deb
    sudo apt-get install -f
    echo "Successfully installed the bunsen-thunar"

    # Install the downloaded deb file using apt-get
    sudo apt-get install $PROXDIR/ProxDot/packages/fonts-jetbrains-mono_2.242+ds-2_all.deb
    sudo apt-get install -f
    echo "Successfully installed the fonts-jetbrains-mono"

    # Install the downloaded deb file using apt-get
    sudo apt-get install $PROXDIR/ProxDot/packages/gammy_0.9.64-1~ld1_amd64.deb
    sudo apt-get install -f
    echo "Successfully installed the gammy"

    # Install the downloaded deb file using apt-get
    sudo apt-get install $PROXDIR/ProxDot/packages/jgmenu_4.4.0-1_amd64.deb
    sudo apt-get install -f
    echo "Successfully installed the jqmenu"

    # Install the downloaded deb file using apt-get
    #sudo apt-get install $PROXDIR/ProxDot/packages/nala-legacy_0.11.0_amd64.deb
    #sudo apt-get install -f
    #echo "Successfully installed the fastfetch"

    # Install the downloaded deb file using apt-get
    sudo apt-get install $PROXDIR/proxDot/Packages/obkey_22.10.16_all.deb
    sudo apt-get install -f
    echo "Successfully installed the obkey"

    # Install the downloaded deb file using apt-get
    sudo apt-get install $PROXDIR/proxDot/Packages/fastfetch-linux-amd64.deb
    sudo apt-get install -f
    echo "Successfully installed the fastfetch"
    
    # Download the webkit-lightdm deb file
    sudo apt-get install $PROXDIR/proxDot/Packages/web-greeter-3.5.3-debian.deb
    sudo apt-get install -f
    echo "Successfully installed the web-greeter"
			
    # Download the lightdm-webkit2-greeter deb file
    sudo apt-get install $PROXDIR/proxDot/Packages/lightdm-webkit2-greeter.deb
    sudo apt-get install -f
    echo "Successfully installed the lightdm-webkit2-greeter"

}

install_Obmenu() {
    if command_exists obmenu-generator; then
        echo "obmenu-generator already installed"
        return
    else
	#cpan -i Gtk3
	curl -L http://cpanmin.us | perl - --sudo Gtk3
	#cpan -i Data::Dump
	curl -L http://cpanmin.us | perl - --sudo Data::Dump
	#cpan -i Linux::DesktopFiles
	curl -L http://cpanmin.us | perl - --sudo Linux::DesktopFiles
	#cpan -i File::DesktopEntry
	curl -L http://cpanmin.us | perl - --sudo File::DesktopEntry
	fi
}

install_StarshipAndFzf() {
    
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


final() {
	sudo cp -rf /tmp/ProxDot/backgrounds /usr/share/
 	sudo cp -rf /tmp/ProxDot/themes /usr/share/
  	sudo cp -rf /tmp/ProxDot/icons /usr/share/
  	sudo cp -rf /tmp/ProxDot/fonts /usr/share/
   	sudo cp -rf /tmp/ProxDot/bin/* /usr/local/bin/.
    	#sudo cp -rf /tmp/ProxDot/lightdm/* /etc/lightdm/.
    	sudo cp -rf /tmp/ProxDot/config /etc/skel/
     	sudo mv /etc/skel/config /etc/skel/.config
    	sudo cp -rf /tmp/ProxDot/local /etc/skel/
     	sudo mv /etc/skel/local /etc/skel/.local
      	sudo cp -rf /tmp/ProxDot/fluxbox /etc/skel/
       	sudo mv /etc/skel/fluxbox /etc/skel/.fluxbox
 	sudo cp /tmp/ProxDot/bash/.bashrc /etc/skel/.bashrc
 	sudo cp /tmp/ProxDot/bash/config.jsonc /etc/skel/config.jsonc
	sudo cp /tmp/ProxDot/bash/starship.toml /etc/skel/starship.toml
 	mkdir -p $HOME/.local/bin
	ln -s /usr/local/bin/obmenu-generator $HOME/.local/bin/obmenu-generator
 	ln -s /usr/local/bin/fbmenugen $HOME/.local/bin/fbmenugen
  	ln -s /usr/local/bin/zoxide $HOME/.local/bin/zoxide
   	ln -s /usr/local/bin/chozmoi $HOME/.local/bin/chezmoi
}

install_Obmenu
install_Packages
install_StarshipAndFzf
final

