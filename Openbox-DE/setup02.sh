#! /bin/bash

RC='\033[0m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
GREEN='\033[0;32m'

# Check if the opt directory and Proxmox-DE folder exist, create them if they don't
# add variables to top level so can easily be accessed by all functions

PROXDIR="/opt/Proxmox-DE"
SUDO_CMD=""
SUGROUP=""
GITPATH="$PROXDIR/Openbox-DE/Openbox-DE/bash"
mkdir -p /usr/share/backgrounds

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
    # Install the downloaded deb file using apt-get
    sudo apt-get install $PROXDIR/Openbox-DE/Openbox-DE/Packages/fastfetch-linux-amd64.deb
    sudo apt-get install -f
    echo "Successfully installed the fastfetch"
    
    # Download the webkit-lightdm deb file
    sudo apt-get install $PROXDIR/Openbox-DE/Openbox-DE/Packages/web-greeter-3.5.3-debian.deb
    sudo apt-get install -f
    echo "Successfully installed the web-greeter"
			
    # Download the lightdm-webkit2-greeter deb file
    sudo apt-get install $PROXDIR/Openbox-DE/Openbox-DE/Packages/lightdm-webkit2-greeter.deb
    sudo apt-get install -f
    echo "Successfully installed the lightdm-webkit2-greeter"

    # Install the Lightdm-Webkit2-greeter source file
    chmod +x $PROXDIR/Openbox-DE/Openbox-DE/Scripts/webkit2.sh
    bash $PROXDIR/Openbox-DE/Openbox-DE/Scripts/webkit2.sh
    chmod -R 755 /usr/share/lightdm-webkit/themes/
    # Set default lightdm-webkit2-greeter theme to litarvan
    sudo sed -i 's/^webkit_theme\s*=\s*\(.*\)/webkit_theme = litarvan #\1/g' /etc/lightdm/lightdm-webkit2-greeter.conf

    # Set default lightdm greeter to lightdm-webkit2-greeter
    sudo sed -i 's/^\(#?greeter\)-session\s*=\s*\(.*\)/greeter-session = lightdm-webkit2-greeter #\1/ #\2g' /etc/lightdm/lightdm.conf

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
	#Installation process: place the obmenu-generator file inside your PATH
    	#place the schema.pl file inside ~/.config/obmenu-generator/
     	chmod +x $PROXDIR/Openbox-DE/Openbox-DE/Packages/obmenu-generator/obmenu-generator
      	cp $PROXDIR/Openbox-DE/Openbox-DE/Packages/obmenu-generator/obmenu-generator /usr/local/bin/obmenu-generator
 	cp $PROXDIR/Openbox-DE/Openbox-DE/Packages/obmenu-generator/config.pl $HOME/.config/obmenu-generator/config.pl
  	cp $PROXDIR/Openbox-DE/Openbox-DE/Packages/obmenu-generator/schema.pl $HOME/.config/obmenu-generator/schema.pl
   
	#Installation process: place the fbmenugen file inside your PATH
    	#place the schema.pl file inside ~/.config/fbmenugen/
     	chmod +x $PROXDIR/Openbox-DE/Openbox-DE/Packages/obmenu-generator/fbmenugen
	cp $PROXDIR/Openbox-DE/Openbox-DE/Packages/obmenu-generator/fbmenugen /usr/local/bin/fbmenugen
 	cp $PROXDIR/Openbox-DE/Openbox-DE/Packages/obmenu-generator/config.pl $HOME/.config/fbmenugen/config.pl
  	cp $PROXDIR/Openbox-DE/Openbox-DE/Packages/obmenu-generator/config.pl $HOME/.config/fbmenugen/schema.pl
    fi
}

install_Chezmoi() {
	if command_exists chezmoi; then
 		echo "chezmoi already installed"
   		return
  	fi
   	if ! curl -fsLS get.chezmoi.io | sh; then
    		echo "${RED}Something went wrong during chezmoi install!${RC}"
      	fi
}

install_StarshipAndFzf() {
    # Install the Nerd Fonts
    chmod +x $PROXDIR/Openbox-DE/Openbox-DE/Scripts/Nerd-Fonts.sh
    bash $PROXDIR/Openbox-DE/Openbox-DE/Scripts/Nerd-Fonts.sh
    echo "Successfully installed the Nerd Fonts"
    
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

install_blesh() {
	curl -LO https://github.com/akinomyoga/ble.sh/releases/download/v0.4.0-devel3/ble-0.4.0-devel3.tar.xz
 	tar xJf ble-0.4.0-devel3.tar.xz -C ~/.local/share/
  	mv ~/.local/share/ble-0.4.0-devel3 ~/.local/share/blesh
  	# Add the following line near the top of ~/.bashrc
	[[ $- == *i* ]] && source ~/.local/share/blesh/ble.sh --attach=none
	# Add the following line at the end of ~/.bashrc
	[[ ${BLE_VERSION-} ]] && ble-attach
}

final() {
	chmod +x /opt/Proxmox/Openbox-DE/Openbox-DE/bash/00-bashrc.sh
	cp /opt/Proxmox-DE/Openbox-DE/Openbox-DE/bash/00-bashrc.sh /etc/profile.d/00-bashrc.sh
 	cp /opt/Proxmox-DE/Openbox-DE/Openbox-DE/bash/config.jsonc /etc/profile.d/config.jsonc
	cp /opt/Proxmox-DE/Openbox-DE/Openbox-DE/bash/starship.toml /etc/profile.d/starship.toml  
}

install_Packages
install_Obmenu
install_Chezmoi
install_StarshipAndFzf
install_blesh
final
