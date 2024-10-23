#! /bin/bash

PROXDIR="/opt"
mkdir -p /usr/share/backgrounds

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
	apt-get install -y .$PROXDIR/ProxDot/packages/bunsen/bunsen-keyring_2023.01.14-1_all.deb
	apt-get install -f
	
	apt-get install -y .$PROXDIR/ProxDot/packages/bunsen/bunsen-python-apt-template_13.0-1_all.deb
	apt-get install -f

	apt-get install -y .$PROXDIR/ProxDot/packages/bunsen/bunsen-os-release_13.0-1_all.deb
	apt-get install -f

 	apt-get update -y && apt-get upgrade -y && apt-get autoremove -y
  
 	apt-get install -y .$PROXDIR/ProxDot/packages/bunsen/bunsen-apt-update-checker_13.0-1_all.deb
	apt-get install -f
	echo "Successfully installed the bunsen-apt-os-release"

	# Install the downloaded deb file using apt-get
	apt-get install -y .$PROXDIR/ProxDot/packages/bunsen/bunsen-blob_13.0-1_all.deb
	apt-get install -f
	echo "Successfully installed the bunsen-blob"

	# Install the downloaded deb file using apt-get
	apt-get install -y .$PROXDIR/ProxDot/packages/bunsen/bunsen-common_13.0.1-1_all.deb
	apt-get install -f
	echo "Successfully installed the bunsen-common"

	# Install the downloaded deb file using apt-get
	apt-get install -y .$PROXDIR/ProxDot/packages/bunsen/bunsen-configs_13.1-1_all.deb
	apt-get install -f
	
	apt-get install -y .$PROXDIR/ProxDot/packages/bunsen/bunsen-configs-pulse_10.0-1_all.deb
	apt-get install -f
	echo "Successfully installed the bunsen-configs"
	
	# Install the downloaded deb file using apt-get
	apt-get install -y .$PROXDIR/ProxDot/packages/bunsen/bunsen-meta-packaging_13.1-1_all.deb
	apt-get install -f
	echo "Successfully installed the bunsen-meta"

	# Install the downloaded deb file using apt-get
	apt install .$PROXDIR/ProxDot/packages/bunsen/bunsen-utilities_13.0-1_all.deb 
	apt install -f
	echo "Successfully installed the bunsen-utilities"

	# Install the downloaded deb file using apt-get
	apt install .$PROXDIR/ProxDot/packages/bunsen/bunsen-pipemenus_13.0-1_all.deb
	apt install -f
	echo "Successfully installed the bunsen-pipemenus"

	# Install the downloaded deb file using apt-get
	apt install .$PROXDIR/ProxDot/packages/bunsen/bunsen-meta-ssh_13.1-1_all.deb
	apt install -f
	echo "Successfully installed the bunsen-ssh"

	# Install the downloaded deb file using apt-get
	apt install .$PROXDIR/ProxDot/packages/bunsen/bunsen-meta-vcs_13.1-1_all.deb
	apt install -f
	echo "Successfully installed the bunsen-vcs"

	# Install the downloaded deb file using apt-get
	apt install .$PROXDIR/ProxDot/packages/bunsen/xfce4-power-manager-data.deb
	apt install -f
	
	apt install .$PROXDIR/ProxDot/packages/bunsen/xfce4-power-manager-dbgsym.deb
	apt install -f
	
	apt install .$PROXDIR/ProxDot/packages/bunsen/xfce4-power-manager-plugins.deb
	apt install -f

	apt install .$PROXDIR/ProxDot/packages/bunsen/xfce4-power-manager.deb
	apt install -f
	echo "Successfully installed the bunsen-xfce4-power-manager"

	# Install the downloaded deb file using apt-get
	apt install .$PROXDIR/ProxDot/packages/bunsen/bunsen-docs_13.0-1_all.deb
	apt install -f
	echo "Successfully installed the bunsen-docs"
	
	# Install the downloaded deb file using apt-get
	apt install .$PROXDIR/ProxDot/packages/bunsen/bunsen-exit_13.2.1-2_all.deb
	apt install -f
	echo "Successfully installed the bunsen-exit"

	# Install the downloaded deb file using apt-get
	apt install .$PROXDIR/ProxDot/packages/jgmenu_4.4.1-2~bpo.bl11+1_amd64.deb 
	apt install -f
	echo "Successfully installed the bunsen-jgmenu"

	# Install the downloaded deb file using apt-get
	apt install .$PROXDIR/ProxDot/packages/bunsen/bunsen-conky_13.0-1_all.deb
	apt install -f
	echo "Successfully installed the bunsen-conky"
	
	# Install the downloaded deb file using apt-get
	apt install .$PROXDIR/ProxDot/packages/bunsen/bunsen-fortune_13.0-1_all.deb
	apt install -f
	echo "Successfully installed the bunsen-fortune"

	# Install the downloaded deb file using apt-get
	apt install .$PROXDIR/ProxDot/packages/bunsen/terminator_2.1.2-1.1~bl1_all.deb
	apt install -f
	echo "Successfully installed the bunsen-terminator"

	# Install the downloaded deb file using apt-get
	apt install .$PROXDIR/ProxDot/packages/bunsen/tint2_16.7+bl10r1-1_amd64.deb
	apt install -f
	echo "Successfully installed the bunsen-tint2"

	# Install the downloaded deb file using apt-get
	apt install .$PROXDIR/ProxDot/packages/bunsen/bunsen-images-base_13.1-1_all.deb
	apt install -f
	
	apt install .$PROXDIR/ProxDot/packages/bunsen/bunsen-images_13.1-1_all.deb
	apt install -f

	apt install .$PROXDIR/ProxDot/packages/bunsen/bunsen-images-archives_13.0-1_all.deb
	apt install -f
	echo "Successfully installed the bunsen-images"

	# Install the downloaded deb file using apt-get
	apt install .$PROXDIR/ProxDot/packages/bunsen/bunsen-faenza-icon-theme_13.0-1_all.deb
	apt install -f

	apt install .$PROXDIR/ProxDot/packages/bunsen/bunsen-numix-icon-theme_13.0-1_all.deb
	apt install -f

	apt install .$PROXDIR/ProxDot/packages/bunsen/bunsen-paper-icon-theme_13.0-1_all.deb
	apt install -f

	apt install .$PROXDIR/ProxDot/packages/bunsen/bunsen-papirus-icon-theme_13.0-1_all.deb
	apt install -f

	apt install .$PROXDIR/ProxDot/packages/bunsen/labbe-material-icons_0.1.0-1_all.deb 
	apt install -f

	apt install .$PROXDIR/ProxDot/packages/bunsen/material-solarized-suruplusplus-icon-theme_13.0-1_all.deb
	apt install -f

	wget https://pkg.bunsenlabs.org/debian/pool/main/p/paper-icon-theme/paper-icon-theme_1.5.728%2Bbunsen1-1_all.deb
	apt install ./paper-icon-theme_1.5.728+bunsen1-1_all.deb
	apt install -f
	echo "Successfully installed the bunsen-theme"

	# Install the downloaded deb file using apt-get
	apt install .$PROXDIR/ProxDot/packages/bunsen/bunsen-meta-java_13.1-1_all.deb
	apt install -f
	echo "Successfully installed the bunsen-java"

	# Install the downloaded deb file using apt-get
	apt install .$PROXDIR/ProxDot/packages/bunsen/bunsen-meta-lamp_13.1-1_all.deb
	apt install -f
	echo "Successfully installed the bunsen-lamp"

	# Install the downloaded deb file using apt-get
	apt install .$PROXDIR/ProxDot/packages/bunsen/bunsen-welcome_13.1-1_all.deb
	apt install -f
	echo "Successfully installed the bunsen-welcome"

    
    # Install the downloaded deb file using apt-get
    sudo apt-get install -y $PROXDIR/ProxDot/packages/fonts-jetbrains-mono_2.242+ds-2_all.deb
    sudo apt-get install -f
    echo "Successfully installed the fonts-jetbrains-mono"

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

    # Download the lightdm-webkit2-greeter deb file
    #cpan -i Gtk3
    curl -L http://cpanmin.us | perl - --sudo Gtk3
    #cpan -i Data::Dump
    curl -L http://cpanmin.us | perl - --sudo Data::Dump
    #cpan -i Linux::DesktopFiles
    curl -L http://cpanmin.us | perl - --sudo Linux::DesktopFiles
    #cpan -i File::DesktopEntry
    curl -L http://cpanmin.us | perl - --sudo File::DesktopEntry
    #sudo apt-get install -y $PROXDIR/ProxDot/packages/obmenu-generator_0.91-1_all.deb
    #sudo apt-get install -f
    echo "Successfully installed the lightdm-webkit2-greeter"

    # Install the Lightdm-Webkit2-greeter source file
    #mkdir -p /usr/share/backgrounds
    #mkdir -p /usr/share/lightdm-webkit/themes/
    #bash $PROXDIR/ProxDot/Scripts/webkit2.sh
    #chmod -R 755 /usr/share/lightdm-webkit/themes/
    # Set default lightdm-webkit2-greeter theme to litarvan
    #sudo sed -i 's/^webkit_theme\s*=\s*\(.*\)/webkit_theme = litarvan #\1/g' /etc/lightdm/lightdm-webkit2-greeter.conf

    # Set default lightdm greeter to lightdm-webkit2-greeter
    #sudo sed -i 's/^\(#?greeter\)-session\s*=\s*\(.*\)/greeter-session = lightdm-webkit2-greeter #\1/ #\2g' /etc/lightdm/lightdm.conf
    #sed -i 's/^#greeter-session=example-gtk-gnome/greeter-session=lightdm-webkit2-greeter/' /etc/lightdm/lightdm.conf
    #sed -i 's/^#user-session=default/user-session=openbox/' /etc/lightdm/lightdm.conf
    #sed -i 's/^    theme: gruvbox/    theme: LightdmTheme/' /etc/lightdm/web-greeter.yml
    #echo "Successfully installed the lightdm-webkit2-greeter"

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

install_StarshipAndFzf
install_Packages
