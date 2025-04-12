#!/bin/bash

set -e # quit on error
cp "$HOME/.bashrc" "$HOME/.bashrc.bak"

# NOTE: Any program that needs to be manually updated should have an associated variable with
# "_update" in the name for easier search/grep

#############################################
# Check that the script is being run properly
#############################################

if [ -n "$SUDO_USER" ]; then
    echo "Running this script with sudo will cause pathing to break. Exiting..."
    exit 1
fi

if [ "$PWD" != "$HOME" ]; then
    echo "Error: This script must be run from the home directory ($HOME)."
    exit 1
fi

#############################
# Confirm we want to continue
#############################

fresh_install=false

echo "Install script for Debian 12 i3 startx system"
echo "Note: Make sure to run apt update, upgrade, autoremove, and autoclean separately with sudo"
echo "This might be necessary to make kernel updates install"
echo ""

echo "Target home directory: $HOME"
read -p "Fresh install, update, or quit? (i/u/q): " choice

if [[ "$choice" != "i" && "$choice" != "I" && "$choice" != "u" && "$choice" != "U" ]]; then
    echo "Exiting."
    exit 0
fi

if [[ "$choice" == "i" || "$choice" == "I" ]]; then
    fresh_install=true
fi

################
# Catchall Stuff
################

local_dir="$HOME/.local"
local_bin_dir="$HOME/.local/bin"
conf_dir="$HOME/.config"

# Not sure if I need this, but a useful code snippet
# if [[ ":$PATH:" != *":/usr/local/bin:"* ]]; then
#     export PATH=/usr/local/bin:$PATH
# fi

##################
# System Hardening
##################

if [[ "$fresh_install" == true ]] ; then
    sudo apt install -y ufw

    sudo ufw default deny incoming # Should be default, but let's be sure
    sudo ufw default allow outgoing # Also should be default
    sudo ufw logging on
    sudo ufw --force enable

    ssh_dir="$HOME/.ssh"
    [ ! -d "$ssh_dir" ] && mkdir -p "$ssh_dir"
    chmod 700 "$ssh_dir"

    # FUTURE: There are settings that can be added as well to require stronger cryptography
    cat << 'EOF' > "$ssh_dir/config"
Host *
ServerAliveInterval 60
ServerAliveCountMax 30
EOF
    chmod 600 "$ssh_dir/config"
fi

############
# Apt Basics
############

sudo apt update
sudo apt upgrade -y

####################
# Network Connection
####################

sudo apt install -y network-manager

sudo systemctl stop networking
sudo systemctl stop systemd-networkd
sudo systemctl disable networking
sudo systemctl disable systemd-networkd

if ! grep -q "managed=true" /etc/NetworkManager/NetworkManager.conf; then
    echo "Configuring NetworkManager to manage all devices..."
    sudo sed -i -e '/\[ifupdown\]/a managed=true' -e '/managed=false/d' /etc/NetworkManager/NetworkManager.conf
fi

sudo systemctl enable NetworkManager
sudo systemctl restart NetworkManager # Restart to pickup the re-written config

echo "Available network devices:"
nmcli device

WIFI_DEVICE=$(nmcli device | grep wifi | awk '{print $1}' || true)
if [ -n "$WIFI_DEVICE" ]; then
    echo "Scanning for WiFi networks on $WIFI_DEVICE..."
    nmcli device wifi list ifname "$WIFI_DEVICE"
else
    echo "No WiFi device detected."
fi

echo "Available devices from 'nmcli device':"
nmcli device | awk 'NR>1 {print $1 " (" $2 ")"}'
read -p "Enter the device name to connect (e.g., enp0s3 or wlan0): " DEVICE

if nmcli device show "$DEVICE" | grep -q "GENERAL.TYPE:.*wifi"; then
    echo "WiFi device selected: $DEVICE"
    nmcli device wifi list ifname "$DEVICE"
    read -p "Enter the SSID of the WiFi network: " SSID
    read -s -p "Enter the password for '$SSID': " PASSWORD
    echo
    nmcli device wifi connect "$SSID" password "$PASSWORD" ifname "$DEVICE"
else
    echo "Wired/bridge device selected: $DEVICE"
    nmcli device connect "$DEVICE"
fi

echo "Checking connectivity..."
if ping -c 4 google.com >/dev/null 2>&1; then
    echo "Network is up!"
else
    echo "Network failed. Check 'nmcli device' or logs with 'journalctl -u NetworkManager'."
    exit 1
fi

#######################
# Build Tools/Libraries
#######################

# These installs are kept up here because so many different things can depend on them

if [[ "$fresh_install" == true ]] ; then
    sudo apt install -y build-essential
    sudo apt install -y bison # tmux build dep
    sudo apt install -y ncurses-dev # tmux build dep
    sudo apt install -y libevent-dev # tmux build dep
    sudo apt install -y pkg-config # For cargo updater
    sudo apt install -y libssl-dev # For cargo updater
    # sudo apt install -y python3-neovim
fi

###########
# Utilities
###########

if [[ "$fresh_install" == true ]] ; then
    sudo apt install -y curl
    sudo apt install -y xclip # For copy/paste out of Neovim
    sudo apt install -y fd-find
    sudo apt install -y fzf
    sudo apt install -y vim
    sudo apt install -y unzip
    sudo apt install -y mesa-utils # Get OpenGL info
    sudo apt install -y automake # tmux build dep
    sudo apt install -y autoconf # tmux build dep
    sudo apt install -y sqlite3
    sudo apt install -y qalculate-gtk
    sudo apt install -y gnome-disk-utility
    sudo apt install -y rsync
    sudo apt install -y maim
    sudo apt install -y libglib2.0-bin
    # NOTE: The Debian repo has a couple tools for reading perf off of Rust source code
    # At least for now, I'm going to avoid speculatively installing them
    # They can be checked with apt search linux-perf
    sudo apt install -y linux-perf
    echo "kernel.perf_event_paranoid = -1" | sudo tee /etc/sysctl.conf

    systemctl --user start dconf.service
    # When you run this with the ghostty appimage open, the appimage environment breaks
    # the path to the linux .so files this relies on
    # Just run it now since everything should be dark mode anyway
    gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
fi

# Post-install steps:
# - Verify that copy/paste works in Nvim
# - Verify that the tmux windowizer works
# - Check that qalculate is in Dark mode
# - Verify that gnome-disks is in dark mode and can detect all drives
# - Setup rsync backups
# - Test maim screenshot hotkey
# - Verify you can do a cargo flamegraph with rust

###########
# Dev Tools
###########

if [[ "$fresh_install" == true ]] ; then
    sudo apt install -y shellcheck
    sudo apt install -y llvm
fi

# Post-install steps:
# - Verify in Nvim that shellcheck works

#####
# Git
#####

if [[ "$fresh_install" == true ]] ; then
    sudo apt install -y git-all

    git config --global user.name "Mike J. McGuirk"
    git config --global user.email "mike.j.mcguirk@gmail.com"
    # Rebase can do goofy stuff
    git config --global pull.rebase false
fi

###########
# Wireguard
###########

if [[ "$fresh_install" == true ]] ; then
    sudo apt install -y wireguard
    sudo apt install -y openresolv
    sudo apt install -y natpmpc
fi

# TODO: Note where wireguard files actually go

# Post-install steps:
# - Configure Wireguard files

##################
# General Programs
##################

if [[ "$fresh_install" == true ]] ; then
    sudo apt install -y vlc
    sudo apt install -y hexchat
    sudo apt install -y libreoffice
    sudo apt install -y qbittorrent
    sudo apt install -y kolourpaint
    sudo apt install -y evince
    sudo apt install -y thunar
    sudo apt install -y gtk2-engines-murrine
    sudo apt install -y arc-theme
fi

# Post-Install steps:
# - Verify VLC players audio and video
# - Verify Thunar is in dark mode
# - Do open with > image viewer in Thunar to set default option
# - Configure qbittorrent

##########
# Redshift
##########

if [[ "$fresh_install" == true ]] ; then
    sudo apt install -y redshift-gtk
    sudo systemctl disable geoclue

    [ ! -d "$conf_dir" ] && mkdir -p "$conf_dir"
    redshift_conf_file="$conf_dir/redshift.conf"

    # Day and night are both initially set for 6500k to make it more obvious when setting a low
    # Kelvin value for testing
    # lat and lon are set for zero to avoid dox
    echo "Writing Redshift configuration to $redshift_conf_file..."
    if cat << 'EOF' > "$redshift_conf_file"
[redshift]
#temp-day=6500
#temp-night=4000
temp-day=6500
temp-night=6500
adjustment-method=randr
location-provider=manual

[manual]
lat=00.0000
lon=00.0000
EOF
    then
        echo "Successfully wrote to $redshift_conf_file"
    else
        echo "Error: Failed to write to $redshift_conf_file"
        exit 1
    fi
fi

# Post-install steps:
# - Verify Redshift works
# - Edit temp and location configs

##############
# Get Dotfiles
##############

dotfiles_url="https://github.com/mikejmcguirk/dotfiles"

if [[ "$fresh_install" == true ]] ; then
    if [ -z "$dotfiles_url" ] ; then
        echo "Error: dotfiles_url must be set."
        exit 1
    fi

    dotfile_dir="$HOME/.cfg"
    [ ! -d "$dotfile_dir" ] && mkdir -p "$dotfile_dir"
    git clone --bare $dotfiles_url "$dotfile_dir"
    git --git-dir="$dotfile_dir" --work-tree="$HOME" checkout main --force

    old_login_file="/etc/pam.d/login"
    if [ -f $old_login_file ]; then
        sudo rm $old_login_file
    fi

    pam_d_dir="/etc/pam.d"
    [ ! -d "$pam_d_dir" ] && mkdir -p "$pam_d_dir"
    sudo cp "$conf_dir/templates/login" "$pam_d_dir"

    chmod +x "$conf_dir/polybar/launch-polybar"
    chmod +x "$local_bin_dir/maim-script"
    chmod +x "$local_bin_dir/rofi-scripts/rofi-power"
fi

#############################
# Gnome Keyring and libsecret
#############################

# To store Git tokens and stop Brave from trying to use KWallet

if [[ "$fresh_install" == true ]] ; then
    sudo apt install -y gnome-keyring
    sudo apt install -y libsecret-tools
    sudo apt install -y libsecret-1-0
    sudo apt install -y libsecret-1-dev
fi

libsecret_path="/usr/share/doc/git/contrib/credential/libsecret"
cd $libsecret_path
sudo make
cd "$HOME"

if [[ "$fresh_install" == true ]] ; then
    git config --global credential.helper libsecret
    cat << EOF >> "$HOME/.bashrc"

export PATH="\$PATH:$libsecret_path"
EOF
fi

# Post-Install Steps:
# - Verify that Brave opens without asking for a password to unlock the keyring
# - Verify that you can store a git token

################
# Window Manager
################

if [[ "$fresh_install" == true ]] ; then
    # Xserver
    sudo apt install -y xorg

    # Wm
    sudo apt install -y i3
    sudo apt install -y i3-wm # Because sure why not

    # Wallpaper/compositing
    sudo apt install -y feh
    sudo apt install -y picom

    # polybar
    sudo apt install -y polybar
    sudo apt install -y psmisc # For killall

    # Backend
    sudo apt install -y dbus
    sudo apt install -y dbus-x11

    sudo apt install -y upower # Brave uses this to check laptop power
    # Brave complains/has dbus issues if it cannot see the policykit user
    # Reinstall to make sure it's there
    sudo apt install -y policykit-1
    sudo apt install -y at-spi2-core # Re-installation also seems to help with this
    sudo apt install -y libpam-gnome-keyring # This should already be installed but let's be safe

    if ! grep -q ".bashrc_custom" "$HOME/.bashrc"; then
        cat << 'EOF' >> "$HOME/.bashrc"

if [ -f "$HOME/.bashrc_custom" ]; then
    . "$HOME/.bashrc_custom"
fi
EOF
    fi

    # FUTURE: This seems like a cool tool: https://github.com/svenstaro/rofi-calc
    # But skipping from now because it looks to require a lot of building from source

    # TODO: This is apparently supposed to ignore the nVidia stuff if it's a VM
    # if [ -n "$(lspci | grep -i nvidia)" ]; then
    #     echo "Detected NVIDIA GPU, installing drivers..."
    #     sudo apt install -y nvidia-driver linux-headers-$(uname -r)
    #     sudo nvidia-xconfig
    # else
    #     echo "No NVIDIA GPU detected, skipping driver installation (safe for VMs)."
    # fi
fi

######
# rofi
######

if [[ "$fresh_install" == true ]] ; then
    sudo apt install -y rofi

    # We want to be able to reboot and shutdown from Rofi
    if ! getent group sudo > /dev/null; then
        echo "Error: The 'sudo' group does not exist on this system"
        echo "Please create the group or modify the script to use a different group/username"
        exit 1
    fi

    reboot_shutdown_file="/etc/sudoers.d/reboot-shutdown"
    if ! sudo touch "$reboot_shutdown_file"; then
        echo "Failed to create $reboot_shutdown_file"
        exit 1
    fi

    if ! echo "%sudo ALL=(ALL) NOPASSWD: /sbin/reboot, /sbin/shutdown" | sudo tee "$reboot_shutdown_file" > /dev/null; then
        echo "Failed to write to $reboot_shutdown_file"
        sudo rm -f "$reboot_shutdown_file"
        exit 1
    fi

    if ! sudo chmod 440 "$reboot_shutdown_file"; then
        echo "Failed to set permissions on $reboot_shutdown_file"
        sudo rm -f "$reboot_shutdown_file"
        exit 1
    fi

    if ! sudo visudo -c -f "$reboot_shutdown_file"; then
        echo "Syntax check failed for $reboot_shutdown_file"
        sudo rm -f "$reboot_shutdown_file"
        exit 1
    fi

    cat << EOF >> "$HOME/.bashrc"

export PATH="\$PATH:/sbin"
EOF

    echo "Successfully configured $reboot_shutdown_file"
fi

# Post-install steps:
# - Verify that reboot/poweroff work from cmd without sudo

##############
# i3lock-color
##############

# Installed as a dep for betterlockscreen

i3lock_repo="https://github.com/Raymo111/i3lock-color"
i3lock_tag="2.13.c.5"

i3lock_update=false
for arg in "$@"; do
    if [[ "$arg" == "i3lock" ]]; then
        i3lock_update=true
        echo "Updating i3lock-color..."

        break
    fi
done

if [[ "$fresh_install" == true && "$i3lock_update" == true ]]; then
    echo "Cannot fresh install and update i3lock-color"
    exit 1
fi

if [[ "$fresh_install" == true && "$i3lock_update" != true ]]; then
    echo "Installing i3lock-color..."
fi

if [ "$fresh_install" == true ]; then
    sudo apt remove -y i3lock

    # deps
    sudo apt install -y autoconf
    sudo apt install -y gcc
    sudo apt install -y make
    sudo apt install -y pkg-config
    sudo apt install -y libpam0g-dev
    sudo apt install -y libcairo2-dev
    sudo apt install -y libfontconfig1-dev
    sudo apt install -y libxcb-composite0-dev
    sudo apt install -y libev-dev
    sudo apt install -y libx11-xcb-dev
    sudo apt install -y libxcb-xkb-dev
    sudo apt install -y libxcb-xinerama0-dev
    sudo apt install -y libxcb-randr0-dev
    sudo apt install -y libxcb-image0-dev
    sudo apt install -y libxcb-util0-dev
    sudo apt install -y libxcb-xrm-dev
    sudo apt install -y libxkbcommon-dev
    sudo apt install -y libxkbcommon-x11-dev
    sudo apt install -y libjpeg-dev
    sudo apt install -y libgif-dev
fi

i3_color_git_dir="$local_bin_dir/i3lock-color"
if [[ "$fresh_install" == true || "$i3lock_update" == true ]]; then
    [ ! -d "$i3_color_git_dir" ] && mkdir -p "$i3_color_git_dir"
    cd "$i3_color_git_dir" || { echo "Error: Cannot cd to $i3_color_git_dir"; exit 1; }
fi

if [ "$fresh_install" == true ]; then
    git clone "$i3lock_repo" "$i3_color_git_dir"
elif [ "$i3lock_update" == true ]; then
    git pull
fi

i3_color_build_dir="$i3_color_git_dir/build"
if [[ "$fresh_install" == true || "$i3lock_update" == true ]]; then
    git checkout "$i3lock_tag" || { echo "Error: Cannot checkout $i3lock_tag"; exit 1; }
    ./install-i3lock-color.sh
    # for betterlockscreen
    mv "$i3_color_build_dir/i3lock" "$i3_color_build_dir/i3lock-color"

    cd "$HOME"
fi

if [[ "$fresh_install" == true ]] ; then
    cat << EOF >> "$HOME/.bashrc"

export PATH="\$PATH:$i3_color_build_dir"
EOF
fi

####################################
# ImageMagick (betterlockscreen dep)
####################################

# Last tag: 7.1.1-46
magick_repo="https://github.com/ImageMagick/ImageMagick"
magick_tag="7.1.1-46"
magick_update=false
for arg in "$@"; do
    if [[ "$arg" == "magick" ]]; then
        magick_update=true
        echo "Updating ImageMagick..."

        break
    fi
done

if [[ "$fresh_install" == true && "$magick_update" == true ]]; then
    echo "Cannot fresh install and update magick"
    exit 1
fi

magick_git_dir="$local_bin_dir/magick"
if [[ "$fresh_install" == true || "$magick_update" == true ]]; then
    [ ! -d "$magick_git_dir" ] && mkdir -p "$magick_git_dir"
    cd "$magick_git_dir" || { echo "Error: Cannot cd to $magick_git_dir"; exit 1; }
fi

if [[ "$fresh_install" == true ]]; then
    git clone $magick_repo "$magick_git_dir"
elif [[ "$magick_update" == true ]]; then
    git pull
fi

if [[ "$fresh_install" == true || "$magick_update" == true ]]; then
    git checkout "$magick_tag" || { echo "Error: Cannot checkout $magick_tag"; exit 1; }
    ./configure
    make
    sudo make install
    sudo ldconfig /usr/local/lib

    cd "$HOME"
fi

##################
# betterlockscreen
##################

# https://github.com/betterlockscreen/betterlockscreen
# Last Tag: 4.4.0
# The install script automatically picks the latest tag, but it is noted here for reference
# The URL is outlined for readability. If the install/update command needs changed, handle below
bls_url="https://raw.githubusercontent.com/betterlockscreen/betterlockscreen/main/install.sh"
bls_update=false
for arg in "$@"; do
    if [[ "$arg" == "bls" ]]; then
        bls_update=true
        echo "Updating betterlockscreen..."

        break
    fi
done

if [[ "$fresh_install" == true && "$bls_update" != true ]]; then
    echo "Installing betterlockscreen..."
fi

if [[ "$fresh_install" == true ]]; then
    sudo apt install -y bc
    sudo apt install -y xautolock
fi

# Note: The install script will fail if it fails to find any of the deps, including
# i3lock-color and ImageMagick
if [[ "$fresh_install" == true || "$bls_update" == true ]]; then
    if [ -z "$bls_url" ]; then
        echo "bls_url not set. Exiting..."
        exit 1
    fi
    wget $bls_url -O - -q | bash -s user latest
fi

# Post-Install Checks:
# - After running the wallpaper update command, lock the screen to verify it works
# - When entering the password to unlock, verify the colors show correctly

#########
# Spotify
#########

# https://www.spotify.com/de-en/download/linux/
# Check directions for updated key
spotify_key="https://download.spotify.com/debian/pubkey_C85668DF69375001.gpg"
spotify_update=false
for arg in "$@"; do
    if [[ "$arg" == "spotify" ]]; then
        spotify_update=true
        echo "Updating Spotify key..."

        break
    fi
done

if [[ "$fresh_install" == true && "$spotify_update" != true ]]; then
    echo "Installing Spotify..."
fi

if [[ "$fresh_install" == true ]]; then
    spotify_repo="deb https://repository.spotify.com stable non-free"
    echo "$spotify_repo" | sudo tee /etc/apt/sources.list.d/spotify.list
fi

if [[ "$fresh_install" == true || "$spotify_update" == true ]]; then
    sudo curl -sS $spotify_key | sudo gpg --dearmor --yes -o /etc/apt/trusted.gpg.d/spotify.gpg
    sudo apt update

    sudo apt install -y spotify-client

    username="$USER"
    spotify_prefs_dir="$conf_dir/spotify/Users/${username}-user"
    [ ! -d "$spotify_prefs_dir" ] && mkdir -p "$spotify_prefs_dir"
    prefs_file="$spotify_prefs_dir/prefs"
    spotify_ui_setting="ui.track_notifications_enabled=false"

    if [ -f "$prefs_file" ]; then
        if grep -q "$spotify_ui_setting" "$prefs_file"; then
            echo "The line '$spotify_ui_setting' already exists in $prefs_file. Skipping..."
        else
            echo "Appending '$spotify_ui_setting' to $prefs_file..."
            echo "$spotify_ui_setting" >> "$prefs_file"
        fi
    else
        echo "Creating $prefs_file and adding the configuration line..."
        if ! touch "$prefs_file"; then
            echo "Error: Failed to create $prefs_file. Check permissions."
            exit 1
        fi
        echo "$spotify_ui_setting" > "$prefs_file"
    fi

    echo "Spotify preferences updated successfully."
fi

# Post-install checks:
# - Login to Spotify and verify it can play music
# - Verify that the prefs file was created successfully
# - Editing settings in GUI (such as streaming quality)

###############
# Brave Browser
###############

curl -fsS https://dl.brave.com/install.sh | sh

# Post-install checks:
# - Verify no errors when opening in terminal
# - Configure default pages
# - Add bookmarks
# - Disable ctrl+w/ctrl+W keys (might need Shortkeys)
# - Extensions:
#   - Dark reader
#   - Return Youtube dislike
#   - Youtube non-stop
#   - 7TV
#   - Onetab

########
# Neovim
########

# TODO: I think this is needed because of the neovim-python installation
# Confirm that. Do I really need that installation?
# Dumb hack
sudo apt remove -y neovim
bad_neovim_dir="$conf_dir/neovim"
if [ -d "$bad_neovim_dir" ]; then
    rm -rf "$bad_neovim_dir"
fi

# https://github.com/neovim/neovim/releases
# NOTE: Check the instructions as well as the tar URL in case they change
nvim_url="https://github.com/neovim/neovim/releases/download/v0.11.0/nvim-linux-x86_64.tar.gz"
nvim_tar=$(basename "$nvim_url")
nvim_config_repo="https://github.com/mikejmcguirk/Neovim-Win10-Lazy"

nvim_update=false
for arg in "$@"; do
    if [[ "$arg" == "nvim" ]]; then
        nvim_update=true
        echo "Updating Nvim..."

        break
    fi
done

nvim_root_dir="/opt"
nvim_install_dir="$nvim_root_dir/nvim-linux-x86_64"

if [[ "$fresh_install" == true || "$nvim_update" == true ]]; then
    if [ -z "$nvim_url" ] || [ -z "$nvim_tar" ] ; then
        echo "Error: nvim_url and nvim_tar must be set"
        exit 1
    fi

    if [ -d "$nvim_install_dir" ]; then
        echo "Removing existing Nvim installation at $nvim_install_dir..."
        sudo rm -rf $nvim_install_dir
    else
        echo "No existing Nvim installation found at $nvim_install_dir"
    fi

    nvim_tar_dir="$local_dir"
    [ ! -d "$nvim_tar_dir" ] && mkdir -p "$nvim_tar_dir"

    curl -LO --output-dir "$nvim_tar_dir" "$nvim_url"
    sudo tar -C $nvim_root_dir -xzf "$nvim_tar_dir/$nvim_tar"
    rm "$nvim_tar_dir/$nvim_tar"
fi

if [[ "$fresh_install" == true ]]; then
    if [ -z "$nvim_config_repo" ] ; then
        echo "No Nvim config repo to clone. Exiting..."
        exit 1
    fi

    nvim_conf_dir="$conf_dir/nvim"
    [ ! -d "$nvim_conf_dir" ] && mkdir -p "$nvim_conf_dir"

    git clone $nvim_config_repo "$nvim_conf_dir"

    cat << EOF >> "$HOME/.bashrc"

export PATH="\$PATH:$nvim_install_dir/bin"
EOF
fi

# Post-install steps:
# - Run ``which nvim`` to verify the right path is being seen
# - Run nvim to pull in plugins
# - Verify the LSP/formatter/linter work for the following:
#   - lua
#   - python
#   - Javascript
#   - html
#   - css
#   - go
#   - rust
#   - toml

######
# Btop
######

# https://github.com/aristocratos/btop
btop_url="https://github.com/aristocratos/btop/releases/download/v1.4.0/btop-x86_64-linux-musl.tbz"
btop_file=$(basename "$btop_url")

btop_update=false
for arg in "$@"; do
    if [[ "$arg" == "btop" ]]; then
        btop_update=true
        echo "Updating Btop..."

        break
    fi
done

btop_install_dir="/opt/btop"

if [[ "$fresh_install" == true || "$btop_update" == true ]]; then
    if [ -z "$btop_url" ] || [ -z "$btop_file" ] ; then
        echo "Error: btop_url and btop_file must be set"
        exit 1
    fi

    if [ -d "$btop_install_dir" ]; then
        echo "Removing existing Btop installation at $btop_install_dir..."
        sudo rm -rf "$btop_install_dir"
    else
        echo "No existing Btop installation found at $btop_install_dir"
    fi

    sudo wget -P "/opt" "$btop_url"
    sudo tar xjvf "/opt/$btop_file" -C "/opt/"
    sudo bash "$btop_install_dir/install.sh"
    sudo rm "/opt/$btop_file"
fi

if [[ "$fresh_install" == true ]]; then
    cat << EOF >> "$HOME/.bashrc"

export PATH="\$PATH:$btop_install_dir/bin"
EOF
fi

# Post-install steps:
# - Verify btop works

################
# Install Lua LS
################

# https://github.com/LuaLS/lua-language-server
lua_ls_url="https://github.com/LuaLS/lua-language-server/releases/download/3.13.9/lua-language-server-3.13.9-linux-x64.tar.gz"
lua_ls_file=$(basename "$lua_ls_url")

lua_ls_update=false
for arg in "$@"; do
    if [[ "$arg" == "lua_ls" ]]; then
        lua_ls_update=true
        echo "Updating Lua LS..."

        break
    fi
done

lua_ls_install_dir="$local_bin_dir/lua_ls"

if [[ "$fresh_install" == true || "$lua_ls_update" == true ]]; then
    if [ -z "$lua_ls_url" ] || [ -z "$lua_ls_file" ] ; then
        echo "Error: lua_ls_url and lua_ls_file must be set"
        exit 1
    fi

    if [ -d "$lua_ls_install_dir" ]; then
        echo "Removing existing lua_ls installation at $lua_ls_install_dir..."
        rm -rf "$lua_ls_install_dir"
    else
        echo "No existing lua_ls installation found at $lua_ls_install_dir"
    fi

    # Files are in the top level of the tar
    wget -P "$lua_ls_install_dir" $lua_ls_url
    tar xzf "$lua_ls_install_dir/$lua_ls_file" -C "$lua_ls_install_dir"
    rm "$lua_ls_install_dir/$lua_ls_file"
fi

if [[ "$fresh_install" == true ]]; then
    cat << EOF >> "$HOME/.bashrc"

export PATH="\$PATH:$lua_ls_install_dir/bin"
EOF
fi

##########
# Obsidian
##########

# https://obsidian.md/download
obsidian_url="https://github.com/obsidianmd/obsidian-releases/releases/download/v1.8.9/obsidian_1.8.9_amd64.deb"
obsidian_file=$(basename "$obsidian_url")

obsidian_update=false
for arg in "$@"; do
    if [[ "$arg" == "obsidian" ]]; then
        obsidian_update=true
        echo "Updating Obsidian..."

        break
    fi
done

if [[ "$fresh_install" == true && "$obsidian_update" != true ]]; then
    echo "Installing Obsidian..."
fi

if [[ "$fresh_install" == true || "$obsidian_update" == true ]]; then
    if [ -z "$obsidian_url" ] || [ -z "$obsidian_file" ] ; then
        echo "Error: obsidian_url and obsidian_file must be set"
        exit 1
    fi

    curl -LO --output-dir "$local_dir" "$obsidian_url" || { echo "Obsidian curl failed"; exit 1; }
    sudo apt install -y "$local_dir/$obsidian_file" || { echo "Unable to install Obsidian Deb file"; exit 1; }
    rm "$local_dir/$obsidian_file" || { echo "Unable to delete Obsidian Deb file"; exit 1; }
fi

# Post-Install Checks:
# - After moving the vault to the new system, make Obsidian open to it by default
# - If using the Nvim Obsidian extension, make sure using the Obsidian Open command works

##################
# Python Ecosystem
##################

if [[ "$fresh_install" == true ]]; then
    sudo apt install -y python3-full
    sudo apt install -y python3-pip
    sudo apt install -y pipx

    pipx ensurepath # Adds ~/.local/bin to path
    # Add pipx completions
    cat << 'EOF' >> "$HOME/.bashrc"

eval "$(register-python-argcomplete pipx)"
EOF

    pipx install nvitop
    pipx install beautysh
    pipx install ruff
    pipx install python-lsp-server[all]
fi

######################
# Javascript Ecosystem
######################

# https://github.com/nvm-sh/nvm
# Check that the install cmd is up to date as well
nvm_install_url="https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.2/install.sh"
nvm_update=false
for arg in "$@"; do
    if [[ "$arg" == "nvm" ]]; then
        nvm_update=true
        echo "Updating Nvm..."

        break
    fi
done

if [[ "$fresh_install" == true || "$nvm_update" == true ]]; then
    if [ -z "$nvm_install_url" ] ; then
        echo "nvim_install_url must be set"
        exit 1
    fi

    wget -qO- $nvm_install_url | bash
fi

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

nvm install --lts
nvm alias default lts/*

npm i -g npm@latest

npm i -g "typescript-language-server"@latest
npm i -g "typescript"@latest
npm i -g "eslint"@latest
npm i -g "prettier"@latest
npm i -g "vscode-langservers-extracted"@latest
npm i -g "bash-language-server"@latest

##############
# Go Ecosystem
##############

# https://go.dev/doc/install
go_dl_url="https://go.dev/dl/go1.24.1.linux-amd64.tar.gz"
go_tar=$(basename "$go_dl_url")

go_update=false
for arg in "$@"; do
    if [[ "$arg" == "go" ]]; then
        go_update=true
        echo "Updating Go..."

        break
    fi
done

if [ "$fresh_install" = true ] && [ "$go_update" != true ]; then
    echo "Installing Go..."
fi

go_install_dir="/usr/local/go"

if [[ "$fresh_install" == true || "$go_update" == true ]]; then
    if [ -z "$go_dl_url" ] || [ -z "$go_tar" ]; then
        echo "Error: go_dl_url and go_tar must be set."
        exit 1
    fi

    if [ -d "$go_install_dir" ]; then
        echo "Removing existing Go installation at $go_install_dir..."
        sudo rm -rf $go_install_dir
    else
        echo "No existing Go installation found at $go_install_dir"
    fi

    go_dl_dir="$local_dir"
    wget -P "$go_dl_dir" "$go_dl_url"
    sudo tar -C /usr/local -xzf "$go_dl_dir/$go_tar"
    rm "$go_dl_dir/$go_tar"
fi

go_install_bin=$go_install_dir/bin
export PATH=$PATH:$go_install_bin
export GOPATH=$(go env GOPATH)
export PATH=$PATH:$GOPATH/bin

if [[ "$fresh_install" == true ]]; then
    echo "Adding Go paths to $HOME/.bashrc..."
    cat << EOF >> "$HOME/.bashrc"

# Go environment setup
export PATH=\$PATH:$go_install_bin
export GOPATH=\$(go env GOPATH)
export PATH=\$PATH:\$GOPATH/bin
EOF
fi

go install mvdan.cc/gofumpt@latest
go install golang.org/x/tools/gopls@latest
go install github.com/nametake/golangci-lint-langserver@latest

# https://golangci-lint.run/welcome/install/#local-installation
# NOTE: Because the full cmd relies on go env GOPATH, we cannot declare it here
# Check the full curl|sh command on the website relative to what I have below
go_lint_url="https://raw.githubusercontent.com/golangci/golangci-lint/HEAD/install.sh"
go_lint_dir="bin v1.64.7"

go_lint_update=false
for arg in "$@"; do
    if [[ "$arg" == "go_lint" ]]; then
        go_lint_update=true
        echo "Updating Go Lint..."

        break
    fi
done

if [ "$fresh_install" = true ] && [ "$go_lint_update" != true ]; then
    echo "Installing Go Lint..."
fi

if [ "$fresh_install" = true ] || [ "$go_lint_update" = true ]; then
    if [ -z "$go_lint_url" ] || [ -z "$go_lint_dir" ]; then
        echo "go_lint_url and go_lint_dir must be set"
        exit 1
    else
        curl -sSfL "$go_lint_url" | sh -s -- -b "$(go env GOPATH)/$go_lint_dir"
    fi
fi

#########
# Discord
#########

discord_url="https://discord.com/api/download?platform=linux&format=deb"
discord_update=false
for arg in "$@"; do
    if [[ "$arg" == "discord" ]]; then
        discord_update=true
        echo "Updating Discord..."

        break
    fi
done

if [ "$fresh_install" = true ] && [ "$discord_update" != true ]; then
    echo "Installing Discord..."
fi

if [[ "$fresh_install" == true || "$discord_update" == true ]]; then
    if [ -z "$discord_url" ] ; then
        echo "Error: discord_url must be set."
        exit 1
    fi

    discord_dl_dir="$local_dir"
    [ ! -d "$discord_dl_dir" ] && mkdir -p "$discord_dl_dir"

    deb_file="$discord_dl_dir/discord_deb.deb"
    echo "Downloading Discord .deb from $discord_url..."

    if ! curl -L -o "$deb_file" "$discord_url"; then
        echo "Unable to download Discord .deb, continuing..."
    else
        file_type=$(file -b "$deb_file")
        if [[ "$file_type" =~ "Debian binary package" ]]; then
            echo "It's a deb file! Installing..."

            if sudo apt install -y "$deb_file"; then
                echo "Discord installed successfully"
            else
                echo "Unable to install Discord .deb, continuing..."
            fi
        else
            echo "Downloaded file is not a .deb package (type: $file_type)."
            echo "Removing and continuing..."
        fi
    fi

    rm -f "$deb_file"
fi

# Post-install steps:
# - Verify login
# - Verify that audio calling works both ways

############
# VirtualBox
############

# https://www.virtualbox.org/wiki/Linux_Downloads
vbox_url="https://download.virtualbox.org/virtualbox/7.1.6/virtualbox-7.1_7.1.6-167084~Debian~bookworm_amd64.deb"
vbox_update=false
for arg in "$@"; do
    if [[ "$arg" == "vbox" ]]; then
        vbox_update=true
        echo "Updating Vbox..."

        break
    fi
done

if [[ "$fresh_install" == true || "$vbox_update" != true ]]; then
    echo "Installing VirtualBox..."
fi

if [[ "$fresh_install" == true || "$vbox_update" == true ]]; then
    vbox_dl_dir="$local_dir"
    [ ! -d "$vbox_dl_dir" ] && mkdir -p "$vbox_dl_dir"

    vbox_deb_file="$vbox_dl_dir/vbox_deb.deb"
    curl -L -o "$vbox_deb_file" "$vbox_url" || {
        echo "Error: Download failed."
    }

    sudo apt install -y "$vbox_deb_file"

    rm -f "$vbox_deb_file"
fi

###############
# Add Nerd Font
###############

# https://www.nerdfonts.com/font-downloads
nerd_font_url="https://github.com/ryanoasis/nerd-fonts/releases/download/v3.3.0/Cousine.zip"
nerd_font_filename=$(basename "$nerd_font_url")

nerd_font_update=false
for arg in "$@"; do
    if [[ "$arg" == "nerd_font" ]]; then
        nerd_font_update=true
        echo "Updating Nerd Font..."

        break
    fi
done

if [[ "$fresh_install" == true || "$nerd_font_update" != true ]]; then
    echo "Installing Nerd Font..."
fi

if [[ "$fresh_install" == true || "$nerd_font_update" == true ]]; then
    fonts_dir="$HOME/.fonts"
    [ ! -d "$fonts_dir" ] && mkdir -p "$fonts_dir"

    if [ -z "$nerd_font_url" ] ; then
        echo "Error: nerd_font_url must be set."
        exit 1
    fi

    wget -P "$fonts_dir" $nerd_font_url
    unzip -o "$fonts_dir/$nerd_font_filename" -d "$fonts_dir"
    rm "$fonts_dir/$nerd_font_filename"
fi

#########
# Ghostty
#########

# TODO: If GTK is up-to-date enough on Debian 12, change this to building from source

# https://github.com/neovim/neovim/releases
ghostty_url="https://github.com/psadi/ghostty-appimage/releases/download/v1.1.2%2B4/Ghostty-1.1.2-x86_64.AppImage"
ghostty_update=false
for arg in "$@"; do
    if [[ "$arg" == "ghostty" ]]; then
        ghostty_update=true
        echo "Updating Ghostty..."

        break
    fi
done

if [ "$fresh_install" = true ] || [ "$ghostty_update" = true ]; then
    echo "Installing Ghostty..."
fi

if [ "$fresh_install" = true ] || [ "$ghostty_update" = true ]; then
    if [ -z "$ghostty_url" ]; then
        echo "Error: ghostty_url must be set."
        exit 1
    fi

    ghostty_dir="$local_bin_dir"
    [ ! -d "$ghostty_dir" ] && mkdir -p "$ghostty_dir"
    ghostty_file="$ghostty_dir/ghostty"

    if [ -f "$ghostty_file" ]; then
        echo "Removing existing $ghostty_file..."
        rm "$ghostty_file"
    fi

    curl -L -o "$ghostty_file" "$ghostty_url"
    chmod +x "$ghostty_file"
fi

# This causes ghostty to take 15+ seconds to load
# Looking at the output when running ghostty in the terminal, GTK errors show
sudo apt remove -y xdg-desktop-portal-gtk

# Post-install steps:
# - Verify this opens in i3 with $mod-enter with the proper font

######
# Tmux
######

tmux_url="https://github.com/tmux/tmux"
tmux_branch="tmux-3.5a"
tpm_repo="https://github.com/tmux-plugins/tpm"
tmux_power_repo="https://github.com/wfxr/tmux-power"

if [ -z "$tmux_url" ] || [ -z "$tmux_branch" ] ; then
    echo "Error: tmux_url and tmux_branch must be set"
    exit 1
fi

tmux_update=false
for arg in "$@"; do
    if [[ "$arg" == "tmux" ]]; then
        if [[ "$fresh_install" == true ]]; then
            echo "Cannot do a fresh install and a tmux update at the same time"
            exit 1
        fi

        tmux_update=true
        echo "Updating tmux..."
        break
    fi
done
if [ "$fresh_install" = true ] && [ "$tmux_update" != true ]; then
    echo "Installing tmux..."
fi

tmux_git_dir="$local_bin_dir/tmux"
[ ! -d "$tmux_git_dir" ] && mkdir -p "$tmux_git_dir"

if [[ "$fresh_install" == true ]]; then
    git clone $tmux_url "$tmux_git_dir"
fi

cd "$tmux_git_dir" || { echo "Error: Cannot cd to $tmux_git_dir"; exit 1; }

if [[ "$tmux_update" == true ]]; then
    git pull
fi

if [ "$fresh_install" = true ] || [ "$tmux_update" = true ]; then
    git checkout "$tmux_branch" || { echo "Error: Cannot checkout $tmux_branch"; exit 1; }
    sh autogen.sh
    ./configure && make

    echo "tmux build complete"
fi

cd "$HOME" || { echo "Error: Cannot cd to $HOME"; exit 1; }

if [[ "$fresh_install" == true ]]; then
    cat << EOF >> "$HOME/.bashrc"

export PATH="\$PATH:$tmux_git_dir"
EOF
fi

tmux_plugins_dir="$conf_dir/tmux/plugins"
[ ! -d "$tmux_plugins_dir" ] && mkdir -p "$tmux_plugins_dir"
tpm_dir="$tmux_plugins_dir/tpm"
power_dir="$tmux_plugins_dir/tmux-power"

if [ "$fresh_install" = true ] || [ "$tmux_update" = true ]; then
    if  [ -z "$tpm_repo" ] || [ -z $tmux_power_repo ]; then
        echo "Error: tpm_repo and tmux_power_repo must be set"
        exit 1
    fi
fi

if [[ "$fresh_install" == true ]]; then
    git clone $tpm_repo "$tpm_dir"
    git clone $tmux_power_repo "$power_dir"
fi

# FUTURE: Can't the plugin manager just handle this?
if [[ "$tmux_update" == true ]]; then
    cd "$power_dir" || { echo "Error: Cannot cd to $power_dir"; exit 1; }
    git pull
    cd "$HOME" || { echo "Error: Cannot cd to $HOME"; exit 1; }
fi

# Post-Install Steps:
# - Open tmux and use prefix+I to load plugins

#############
# Apt Cleanup
#############

sudo apt autoremove -y
sudo apt autoclean -y

################
# Rust Ecosystem
################

# Rust is added last because it takes the longest (insert Rust comp times meme here)
# If you do this in the middle of the install, the sudo "session" actually times out

# Rust URL
# Check curl cmd as well
rustup_url="https://sh.rustup.rs"
rustup_update=false
for arg in "$@"; do
    if [[ "$arg" == "rustup" ]]; then
        if [[ "$fresh_install" == true ]]; then
            echo "Cannot do a fresh install and a rustup update at the same time"
            exit 1
        fi

        rustup_update=true
        echo "Updating rustup..."
        break
    fi
done
if [ "$fresh_install" = true ] && [ "$rustup_update" != true ]; then
    echo "Installing rustup..."
fi


if [ "$fresh_install" = true ] || [ "$rustup_update" = true ]; then
    if  [ -z "$rustup_url" ] ; then
        echo "Error: rustup_url must be set"
        exit 1
    fi

    curl --proto '=https' --tlsv1.2 -sSf $rustup_url | sh
fi

rust_bin_dir="$HOME/.cargo/bin"
rustup_bin="$rust_bin_dir/rustup"
cargo_bin="$rust_bin_dir/cargo"

if [[ "$fresh_install" == true ]] ; then
    #I don't know why but rust-analyzer doesn't work unless you do this
    "$rustup_bin" component add rust-analyzer
    "$cargo_bin" install --features lsp --locked taplo-cli
    "$cargo_bin" install stylua
    "$cargo_bin" install tokei
    "$cargo_bin" install flamegraph
    "$cargo_bin" install --features 'pcre2' ripgrep # For Perl Compatible Regex
    "$cargo_bin" install cargo-update
else
    $cargo_bin install-update -a
fi

# Post-install steps:
# - Verify tokei, rg, and rust-analyzer work

#########
# Wrap Up
#########

# echo "options hid_apple fnmode=2" | sudo tee /etc/modprobe.d/hid_apple.conf
# sudo update-initramfs -u

what_happened="Update"
if [[ "$fresh_install" == true ]] ; then
    what_happened="Install"
fi
echo "$what_happened script complete"

echo "Reboot to ensure all changes take effect"
