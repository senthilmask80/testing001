#! /bin/bash

PROXDIR="/opt"

if [ -d "$PROXDIR/ProxDot" ]; then rm -rf "$PROXDIR/ProxDot"; fi
	echo "${YELLOW}Cloning Proxmox-Dotfiles repository into: $PROXDIR/ProxDot${RC}"
	git clone https://github.com/senthilmask80/Proxmox-Dotfiles "$PROXDIR/ProxDot"
if [ $? -eq 0 ]; then
	echo "${GREEN}Successfully cloned Proxmox-Dotfiles repository${RC}"
else
    	echo "${RED}Failed to clone Proxmox-Dotfiles repository${RC}"
exit 1
fi

cd "$PROXDIR/ProxDot" || exit

install_Packages() {
    sudo apt update && sudo apt upgrade -y
    # sudo apt-get -y --ignore-missing install $(< $PROXDIR/ProxDot/Scripts/debian-packages.list)
    sudo apt autoclean && sudo apt autoremove -y && sudo rm -rf /var/cache/apt/archives/*

    # Install the downloaded deb file using apt-get
    sudo apt-get install -y $PROXDIR/ProxDot/packages/bunsen-thunar_11.0-2_all.deb
    sudo apt-get install -f
    echo "Successfully installed the bunsen-thunar"

    # Install the downloaded deb file using apt-get
    sudo apt-get install -y $PROXDIR/ProxDot/packages/fonts-jetbrains-mono_2.242+ds-2_all.deb
    sudo apt-get install -f
    echo "Successfully installed the fonts-jetbrains-mono"

    # Install the downloaded deb file using apt-get
    sudo apt-get install -y $PROXDIR/ProxDot/packages/gammy_0.9.64-1~ld1_amd64.deb
    sudo apt-get install -f
    echo "Successfully installed the gammy"

    # Install the downloaded deb file using apt-get
    sudo apt-get install -y $PROXDIR/ProxDot/packages/jgmenu_4.4.0-1_amd64.deb
    sudo apt-get install -f
    echo "Successfully installed the jqmenu"

    # Install the downloaded deb file using apt-get
    #sudo apt-get install -y $PROXDIR/ProxDot/packages/nala-legacy_0.11.0_amd64.deb
    #sudo apt-get install -f
    #echo "Successfully installed the fastfetch"

    # Install the downloaded deb file using apt-get
    sudo apt-get install -y $PROXDIR/ProxDot/packages/obkey_22.10.16_all.deb
    sudo apt-get install -f
    echo "Successfully installed the obkey"

    # Install the downloaded deb file using apt-get
    sudo apt-get install -y $PROXDIR/ProxDot/packages/fastfetch-linux-amd64.deb
    sudo apt-get install -f
    echo "Successfully installed the fastfetch"
    
    # Download the webkit-lightdm deb file
    sudo apt-get install -y $PROXDIR/ProxDot/packages/web-greeter-3.5.3-debian.deb
    sudo apt-get install -f
    echo "Successfully installed the web-greeter"
			
    # Download the lightdm-webkit2-greeter deb file
    sudo apt-get install -y $PROXDIR/ProxDot/packages/lightdm-webkit2-greeter.deb
    sudo apt-get install -f
    echo "Successfully installed the lightdm-webkit2-greeter"

    # Install the Lightdm-Webkit2-greeter source file
    mkdir -p /usr/share/backgrounds
    mkdir -p /usr/share/lightdm-webkit/themes/
    bash $PROXDIR/ProxDot/Scripts/webkit2.sh
    chmod -R 755 /usr/share/lightdm-webkit/themes/
    # Set default lightdm-webkit2-greeter theme to litarvan
    sudo sed -i 's/^webkit_theme\s*=\s*\(.*\)/webkit_theme = litarvan #\1/g' /etc/lightdm/lightdm-webkit2-greeter.conf

    # Set default lightdm greeter to lightdm-webkit2-greeter
    #sudo sed -i 's/^\(#?greeter\)-session\s*=\s*\(.*\)/greeter-session = lightdm-webkit2-greeter #\1/ #\2g' /etc/lightdm/lightdm.conf
    sed -i 's/^#greeter-session=example-gtk-gnome/greeter-session=lightdm-webkit2-greeter/' /etc/lightdm/lightdm.conf
    sed -i 's/^#user-session=default/user-session=openbox/' /etc/lightdm/lightdm.conf
    sed -i 's/^    theme: gruvbox/    theme: LightdmTheme/' /etc/lightdm/web-greeter.yml
    echo "Successfully installed the lightdm-webkit2-greeter"

    # Install the Collorid Themes
    bash $PROXDIR/ProxDot/Scripts/blue.sh
    echo " Successfully installed the Collorid Themes"

    # Install the picom
    bash $PROXDIR/ProxDot/Scripts/picom.sh
    echo "Successfully installed the picom"

    sudo cp -rf $PROXDIR/ProxDot/backgrounds /usr/share/
    sudo cp -rf $PROXDIR/ProxDot/themes /usr/share/
    sudo cp -rf $PROXDIR/ProxDot/icons /usr/share/
    sudo cp -rf $PROXDIR/ProxDot/bin/* /usr/local/bin/.
    sudo cp -rf $PROXDIR/ProxDot/fonts /usr/share/
    fc-cache -f
    
}

install_Packages
