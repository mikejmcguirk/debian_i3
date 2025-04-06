#!/bin/bash

set -e # quit on error
cp "$HOME/.bashrc" "$HOME/.bashrc.bak"

###################
# Declare variables
###################

# FUTURE: It would be better for the update flags to be handled through args
# That way, you don't need to do post-run cleanup

# https://www.spotify.com/de-en/download/linux/
# Check directions for updated key
new_spotify_key=false
spotify_key="https://download.spotify.com/debian/pubkey_C85668DF69375001.gpg"

libsecret_update=false

i3_color_repo="https://github.com/Raymo111/i3lock-color"
i3_color_tag="2.13.c.5"
i3_color_update=false

magick_repo="https://github.com/ImageMagick/ImageMagick"
magick_tag="7.1.1-46"
magic_url="https://github.com/ImageMagick/ImageMagick/releases/download/7.1.1-47/ImageMagick-82572af-gcc-x86_64.AppImage"
magick_file=$(basename "$magic_url")
magick_update=false

# https://github.com/betterlockscreen/betterlockscreen
# Last Tag: 4.4.0
# The install script automatically picks the latest tag, so just include above for reference and
# set update to true when needed
betterlock_update=true

# https://obsidian.md/download
obsidian_update=false
obsidian_url="https://github.com/obsidianmd/obsidian-releases/releases/download/v1.8.9/obsidian_1.8.9_amd64.deb"
obsidian_file=$(basename "$obsidian_url")

# https://github.com/neovim/neovim/releases
# NOTE: Check the instructions as well as the tar URL in case they change
nvim_update=false
nvim_url="https://github.com/neovim/neovim/releases/download/v0.11.0/nvim-linux-x86_64.tar.gz"
nvim_tar=$(basename "$nvim_url")
nvim_config_repo="https://github.com/mikejmcguirk/Neovim-Win10-Lazy"

# https://github.com/aristocratos/btop
btop_update=false
btop_url="https://github.com/aristocratos/btop/releases/download/v1.4.0/btop-x86_64-linux-musl.tbz"
btop_file=$(basename "$btop_url")

# https://github.com/LuaLS/lua-language-server
lua_ls_update=false
lua_ls_url="https://github.com/LuaLS/lua-language-server/releases/download/3.13.9/lua-language-server-3.13.9-linux-x64.tar.gz"
lua_ls_file=$(basename "$lua_ls_url")

# https://github.com/nvm-sh/nvm
# Check where this is used to make sure install cmd is still up-to-date
nvm_update=false
nvm_install_url="https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.2/install.sh"

# https://go.dev/doc/install
go_update=false
go_dl_url="https://go.dev/dl/go1.24.1.linux-amd64.tar.gz"
go_tar=$(basename "$go_dl_url")

# https://golangci-lint.run/welcome/install/#local-installation
# NOTE: Because the full cmd relies on go env GOPATH, we cannot declare it here
# Check the full curl|sh command on the website relative to what I have below
go_lint_update=false
go_lint_url="https://raw.githubusercontent.com/golangci/golangci-lint/HEAD/install.sh"
go_lint_dir="bin v1.64.7"

tmux_update=false
tmux_url="https://github.com/tmux/tmux"
tmux_branch="tmux-3.5a"
tpm_repo="https://github.com/tmux-plugins/tpm"
tmux_power_repo="https://github.com/wfxr/tmux-power"

# https://github.com/neovim/neovim/releases
ghostty_update=false
ghostty_url="https://github.com/psadi/ghostty-appimage/releases/download/v1.1.2%2B4/Ghostty-1.1.2-x86_64.AppImage"

# https://www.nerdfonts.com/font-downloads
nerd_font_update=false
nerd_font_url="https://github.com/ryanoasis/nerd-fonts/releases/download/v3.3.0/Cousine.zip"
nerd_font_filename=$(basename "$nerd_font_url")

discord_update=false
discord_url="https://discord.com/api/download?platform=linux&format=deb"

# https://www.virtualbox.org/wiki/Linux_Downloads
vbox_update=false
vbox_url="https://download.virtualbox.org/virtualbox/7.1.6/virtualbox-7.1_7.1.6-167084~Debian~bookworm_amd64.deb"

dotfiles_url="https://github.com/mikejmcguirk/dotfiles"

# Rust URL
# Check curl cmd as well
rustup_update=false
rustup_url="https://sh.rustup.rs"

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

echo "Target home directory: $HOME"
echo "Fresh install, update, or quit?"
read -p "Continue? (i/u/q): " choice
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

export PATH=$PATH:$HOME/.local/bin

##################
# System Hardening
##################

if $fresh_install; then
    # sudo passwd -l root # disable root login with a password. Reverse with passwd -u root

    sudo apt install -y ufw
    sudo ufw default deny incoming # Should be default, but let's be sure
    sudo ufw default allow outgoing # Also should be default
    sudo ufw logging on
    sudo ufw --force enable

    [ ! -d "$HOME/.ssh" ] && mkdir -p "$HOME/.ssh"
    chmod 700 "$HOME/.ssh"

    # FUTURE: There are settings that can be added as well to require stronger cryptography
    cat << 'EOF' > ~/.ssh/config
Host *
ServerAliveInterval 60
ServerAliveCountMax 30
EOF
    chmod 600 "$HOME/.ssh/config"
fi


################
# **** NOTE ****
################

# Do not install, directly or as a dependency, xdg-desktop-portal-gtk
# This causes ghostty to take 15+ seconds to load
# Looking at the output when running ghostty in the terminal, GTK errors show
# This rules out using flameshot for screenshots

#################################
# Updates, Cleanup, and Libraries
#################################

sudo apt update
sudo apt upgrade -y
sudo apt autoremove -y
sudo apt autoclean -y

if $fresh_install; then
    sudo apt install -y build-essential
    sudo apt install -y bison # tmux build dep
    sudo apt install -y ncurses-dev # tmux build dep
    sudo apt install -y libevent-dev # tmux build dep
    sudo apt install -y pkg-config # For cargo updater
    sudo apt install -y libssl-dev # For cargo updater
    sudo apt install -y python3-neovim
fi

###########
# Utilities
###########

if $fresh_install; then
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
    # The path to the linux .so files this relies on
    # Just run it now since everything should be dark mode anyway
    gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
fi

###########
# Dev Tools
###########

if $fresh_install; then
    sudo apt install -y shellcheck
    sudo apt install -y llvm
fi

#####
# Git
#####

if $fresh_install; then
    sudo apt install -y git-all
    git config --global user.name "Mike J. McGuirk"
    git config --global user.email "mike.j.mcguirk@gmail.com"
    # Rebase can do goofy stuff
    git config --global pull.rebase false
fi

###########
# Wireguard
###########

if $fresh_install; then
    sudo apt install -y wireguard
    sudo apt install -y openresolv
    sudo apt install -y natpmpc

    natpmpc_file="$HOME/wireguard.txt"
    echo "Writing natpmpc loop to $natpmpc_file..."
    if cat << 'EOF' > "$natpmpc_file"
while true ; do date ; natpmpc -a 1 0 udp 60 -g 10.2.0.1 && natpmpc -a 1 0 tcp 60 -g 10.2.0.1 || { echo -e "ERROR with natpmpc command \a" ; break ; } ; sleep 45 ; done
EOF
    then
        echo "Successfully wrote to $natpmpc_file."
    else
        echo "Error: Failed to write to $natpmpc_file."
        exit 1
    fi
fi

##################
# General Programs
##################

if $fresh_install; then
    sudo apt install -y vlc
    sudo apt install -y hexchat
    sudo apt install -y libreoffice
    sudo apt install -y qbittorrent
    sudo apt install -y kolourpaint
    sudo apt install -y evince
    sudo apt install -y thunar
    sudo apt install -y gtk2-engines-murrine
    sudo apt install -y arc-theme

    mkdir -p ~/.config/gtk-3.0
    cat << EOF > ~/.config/gtk-3.0/settings.ini
[Settings]
gtk-theme-name=Arc-Dark
gtk-application-prefer-dark-theme=1
EOF

    cat << EOF > ~/.gtkrc-2.0
gtk-theme-name="Arc-Dark"
gtk-icon-theme-name="Adwaita"
EOF
fi

##########
# Redshift
##########

if $fresh_install; then
    sudo apt install -y redshift-gtk
    sudo systemctl disable geoclue

    redshift_conf_dir="$HOME/.config"
    [ ! -d "$redshift_conf_dir" ] && mkdir -p "$redshift_conf_dir"
    redshift_conf="$redshift_conf_dir/redshift.conf"

    echo "Checking/creating redshift conf dir"
    if ! mkdir -p "$(dirname "$redshift_conf")"; then
        echo "Unable to create directory $(dirname "$redshift_conf"). Check permissions"
        exit 1
    fi

    echo "Writing Redshift configuration to $redshift_conf..."
    if cat << 'EOF' > "$redshift_conf"
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
        echo "Successfully wrote to $redshift_conf."
    else
        echo "Error: Failed to write to $redshift_conf."
        exit 1
    fi
fi

##############
# Get Dotfiles
##############

if $fresh_install; then
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
    sudo cp "$HOME/.config/templates/login" "$pam_d_dir"

    chmod +x "$HOME/.config/polybar/launch-polybar"
    chmod +x "$HOME/.local/bin/maim-script"
    chmod +x "$HOME/.local/bin/rofi-scripts/rofi-power"
fi


###########
# libsecret
###########

# This is installed to prevent Brave from trying to use KWallet
# This is also installed to store git tokens

if $fresh_install; then
    sudo apt install -y gnome-keyring
    sudo apt install -y libsecret-tools
    sudo apt install -y libsecret-1-0
    sudo apt install -y libsecret-1-dev

fi

libsecret_path="/usr/share/doc/git/contrib/credential/libsecret"
if $fresh_install || $libsecret_update; then
    cd $libsecret_path
    sudo make

    git config --global credential.helper libsecret
fi

if $fresh_install; then
    cat << EOF >> "$HOME/.bashrc"

export PATH="\$PATH:$libsecret_path"
EOF
fi

################
# Window Manager
################

if $fresh_install; then
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

# Startup Options:

# - brave throws dbus errors like crazy

# i3 + lightdm:
# - user paths are not imported

# i3 + default session script
# - brave keyring error
# - other brave SSL errors

######
# rofi
######

if $fresh_install; then
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

##############
# i3lock-color
##############

if $fresh_install && $i3_color_update; then
    echo "Cannot fresh install and update i3_color"
    exit 1
fi

if $fresh_install; then
    sudo apt remove -y i3lock

    # i3lock-color deps
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

i3_color_git_dir="$HOME/.local/bin/i3lock-color"
if $fresh_install || $i3_color_update; then
    [ ! -d "$i3_color_git_dir" ] && mkdir -p "$i3_color_git_dir"
    cd "$i3_color_git_dir" || { echo "Error: Cannot cd to $i3_color_git_dir"; exit 1; }
fi

if $fresh_install; then
    git clone $i3_color_repo "$i3_color_git_dir"
elif $i3_color_update; then
    git pull
fi

i3_color_build_dir="$i3_color_git_dir/build"
if $fresh_install || $i3_color_update; then
    git checkout "$i3_color_tag" || { echo "Error: Cannot checkout $i3_color_tag"; exit 1; }
    ./install-i3lock-color.sh
    # betterlockscreen requirement
    mv "$i3_color_build_dir/i3lock" "$i3_color_build_dir/i3lock-color"

    cd "$HOME"
fi

if $fresh_install; then
    cat << EOF >> "$HOME/.bashrc"

export PATH="\$PATH:$i3_color_build_dir"
EOF
fi

####################################
# ImageMagick (betterlockscreen dep)
####################################

# if $fresh_install && $magick_update; then
#     echo "Cannot fresh install and update magick"
#     exit 1
# fi
#
# magick_git_dir="$HOME/.local/bin/magick"
# if $fresh_install || $magick_update; then
#     [ ! -d "$magick_git_dir" ] && mkdir -p "$magick_git_dir"
#     cd "$magick_git_dir" || { echo "Error: Cannot cd to $magick_git_dir"; exit 1; }
# fi
#
# if $fresh_install; then
#     git clone $magick_repo "$magick_git_dir"
# elif $magick_update; then
#     git pull
# fi
#
# if $fresh_install || $magick_update; then
#     git checkout "$magick_tag" || { echo "Error: Cannot checkout $magick_tag"; exit 1; }
#     ./configure
#     make
#     sudo ldconfig /usr/local/lib
#     sudo make install
#
#     cd "$HOME"
# fi

wget -O $magic_url "$HOME/.local/bin/magick"

##################
# betterlockscreen
##################

if $fresh_install; then
    sudo apt install -y bc
    sudo apt install -y xautolock
fi

if $fresh_install || $betterlock_update; then
    wget https://raw.githubusercontent.com/betterlockscreen/betterlockscreen/main/install.sh -O - -q | bash -s user latest
fi

if $fresh_install; then
    betterlockscreen -u "$HOME/.config/wallpaper/alena-aenami-rooflinesgirl-1k-2-someday.jpg" --fx dim
fi

##################
# Custom Apt Repos
##################

if $fresh_install; then
    sudo curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg
    echo "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg] https://brave-browser-apt-release.s3.brave.com/ stable main"|sudo tee /etc/apt/sources.list.d/brave-browser-release.list
    echo "deb https://repository.spotify.com stable non-free" | sudo tee /etc/apt/sources.list.d/spotify.list
fi

if $fresh_install || $new_spotify_key; then
    sudo curl -sS $spotify_key | sudo gpg --dearmor --yes -o /etc/apt/trusted.gpg.d/spotify.gpg
    sudo apt update
fi

if $fresh_install; then
    sudo apt install -y brave-browser
    sudo apt install -y spotify-client

    username="$USER"
    spotify_prefs_dir="$HOME/.config/spotify/Users/${username}-user"
    [ ! -d "$spotify_prefs_dir" ] && mkdir -p "$spotify_prefs_dir"
    prefs_file="$spotify_prefs_dir/prefs"

    if [ -f "$prefs_file" ]; then
        if grep -q "ui.track_notifications_enabled=false" "$prefs_file"; then
            echo "The line 'ui.track_notifications_enabled=false' already exists in $prefs_file. Skipping..."
        else
            echo "Appending 'ui.track_notifications_enabled=false' to $prefs_file..."
            echo "ui.track_notifications_enabled=false" >> "$prefs_file"
        fi
    else
        echo "Creating $prefs_file and adding the configuration line..."
        if ! touch "$prefs_file"; then
            echo "Error: Failed to create $prefs_file. Check permissions."
            exit 1
        fi
        echo "ui.track_notifications_enabled=false" > "$prefs_file"
    fi

    echo "Spotify preferences updated successfully."
fi


###########
# Dumb hack
###########

sudo apt remove -y neovim
bad_neovim_dir="$HOME/.config/neovim"
if [ -d "$bad_neovim_dir" ]; then
    rm -rf "$bad_neovim_dir"
fi

########
# Neovim
########

nvim_root_dir="/opt"
nvim_install_dir="$nvim_root_dir/nvim-linux-x86_64"

if $fresh_install || $nvim_update; then
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

    nvim_tar_dir="$HOME/.local"
    [ ! -d "$nvim_tar_dir" ] && mkdir -p "$nvim_tar_dir"
    curl -LO --output-dir "$nvim_tar_dir" "$nvim_url"
    sudo tar -C $nvim_root_dir -xzf "$nvim_tar_dir/$nvim_tar"
    rm "$nvim_tar_dir/$nvim_tar"
fi

if $fresh_install; then
    if [ -z "$nvim_config_repo" ] ; then
        echo "No Nvim config repo to clone. Exiting..."
        exit 1
    fi

    nvim_conf_dir="$HOME/.config/nvim"
    [ ! -d "$nvim_conf_dir" ] && mkdir -p "$nvim_conf_dir"
    git clone $nvim_config_repo "$nvim_conf_dir"

    cat << EOF >> "$HOME/.bashrc"

export PATH="\$PATH:$nvim_install_dir/bin"
EOF
fi

######
# Btop
######

btop_install_dir="/opt/btop"

if $fresh_install || $btop_update; then
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

if $fresh_install; then
    cat << EOF >> "$HOME/.bashrc"

export PATH="\$PATH:$btop_install_dir/bin"
EOF
fi

################
# Install Lua LS
################

lua_ls_install_dir="$HOME/.local/bin/lua_ls"

if $fresh_install || $lua_ls_update; then
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

    # This tar file unpacks in the same directory it's in
    wget -P "$lua_ls_install_dir" $lua_ls_url
    tar xzf "$lua_ls_install_dir/$lua_ls_file" -C "$lua_ls_install_dir"
    rm "$lua_ls_install_dir/$lua_ls_file"
fi

if $fresh_install; then
    cat << EOF >> "$HOME/.bashrc"

export PATH="\$PATH:$lua_ls_install_dir/bin"
EOF
fi

##########
# Obsidian
##########

if $fresh_install || $obsidian_update; then
    if [ -z "$obsidian_url" ] || [ -z "$obsidian_file" ] ; then
        echo "Error: obsidian_url and obsidian_file must be set"
        exit 1
    fi

    obsidian_deb_dir="$HOME/.local"
    curl -LO --output-dir "$obsidian_deb_dir" "$obsidian_url"
    sudo apt install -y "$obsidian_deb_dir/$obsidian_file"
    rm "$obsidian_deb_dir/$obsidian_file"
fi

##################
# Python Ecosystem
##################

if $fresh_install; then
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

if $fresh_install || $nvm_update; then
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

go_install_dir="/usr/local/go"

if $fresh_install || $go_update ; then
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

    go_dl_dir="$HOME/.local"
    wget -P "$go_dl_dir" "$go_dl_url"
    sudo tar -C /usr/local -xzf "$go_dl_dir/$go_tar"
    rm "$go_dl_dir/$go_tar"
fi

go_install_bin=$go_install_dir/bin
export PATH=$PATH:$go_install_bin
export GOPATH=$(go env GOPATH)
export PATH=$PATH:$GOPATH/bin

if $fresh_install; then
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

if $fresh_install || $discord_update; then
    if [ -z "$discord_url" ] ; then
        echo "Error: discord_url must be set."
        exit 1
    fi

    discord_dl_dir="$HOME/.local"
    [ ! -d "$discord_dl_dir" ] && mkdir -p "$discord_dl_dir"

    deb_file="$discord_dl_dir/discord_deb.deb"
    echo "Downloading Discord .deb from $discord_url..."
    # curl -L -o "$deb_file" "$discord_url" || {
    #     echo "Error: Download failed."
    # }

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

############
# VirtualBox
############

if $fresh_install || $vbox_update; then
    vbox_dl_dir="$HOME/.local"
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

fonts_dir="$HOME/.fonts"
[ ! -d "$fonts_dir" ] && mkdir -p "$fonts_dir"

if $fresh_install || $nerd_font_update; then
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

if [ "$fresh_install" = true ] || [ "$ghostty_update" = true ]; then
    if [ -z "$ghostty_url" ]; then
        echo "Error: ghostty_url must be set."
        exit 1
    fi

    ghostty_dir="$HOME/.local/bin"
    [ ! -d "$ghostty_dir" ] && mkdir -p "$ghostty_dir"
    ghostty_file="$ghostty_dir/ghostty"

    if [ -f "$ghostty_file" ]; then
        echo "Removing existing $ghostty_file..."
        rm "$ghostty_file"
    fi

    curl -L -o "$ghostty_file" "$ghostty_url"
    chmod +x "$ghostty_file"
fi

######
# Tmux
######

if [ -z "$tmux_url" ] || [ -z "$tmux_branch" ] ; then
    echo "Error: tmux_url and tmux_branch must be set"
    exit 1
fi

# FUTURE: The logic should be improved to just handle this case
if $fresh_install && $tmux_update ; then
    echo "Cannot do a fresh install and a tmux update at the same time"
    exit 1
fi

tmux_git_dir="$HOME/.local/bin/tmux"
[ ! -d "$tmux_git_dir" ] && mkdir -p "$tmux_git_dir"

if $fresh_install ; then
    git clone $tmux_url "$tmux_git_dir"
fi

cd "$tmux_git_dir" || { echo "Error: Cannot cd to $tmux_git_dir"; exit 1; }

if $tmux_update ; then
    git pull
fi

if $fresh_install || $tmux_update ; then
    git checkout "$tmux_branch" || { echo "Error: Cannot checkout $tmux_branch"; exit 1; }
    sh autogen.sh
    # Makes into the download folder, so don't delete
    ./configure && make

    echo "tmux build complete"
    cd "$HOME" || { echo "Error: Cannot cd to $HOME"; exit 1; }
fi

if $fresh_install; then
    cat << EOF >> "$HOME/.bashrc"

export PATH="\$PATH:$tmux_git_dir"
EOF
fi

tmux_plugins_dir="$HOME/.config/tmux/plugins"
[ ! -d "$tmux_plugins_dir" ] && mkdir -p "$tmux_plugins_dir"
tpm_dir="$tmux_plugins_dir/tpm"
power_dir="$tmux_plugins_dir/tmux-power"

if $fresh_install || $tmux_update ; then
    if  [ -z "$tpm_repo" ] || [ -z $tmux_power_repo ]; then
        echo "Error: tpm_repo and tmux_power_repo must be set"
        exit 1
    fi
fi

if $fresh_install; then
    # tmux list-keys to see where the binding looks to run the script to install
    # Should be prefix-I
    git clone $tpm_repo "$tpm_dir"
    git clone $tmux_power_repo "$power_dir"
fi

# FUTURE: Can't the plugin manager just handle this?
if $tmux_update; then
    cd "$power_dir" || { echo "Error: Cannot cd to $tmux_git_dir"; exit 1; }
    git pull
    cd "$HOME" || { echo "Error: Cannot cd to $HOME"; exit 1; }
fi

################
# Rust Ecosystem
################

# Rust is added last because it takes the longest (insert Rust comp times meme here)
# If you do this in the middle of the install, the sudo "session" actually times out

if $fresh_install || $rustup_update ; then
    if  [ -z "$rustup_url" ] ; then
        echo "Error: rustup_url must be set"
        exit 1
    fi

    curl --proto '=https' --tlsv1.2 -sSf $rustup_url | sh
fi

rust_bin_dir="$HOME/.cargo/bin"
rustup_bin="$rust_bin_dir/rustup"
cargo_bin="$rust_bin_dir/cargo"

if $fresh_install ; then
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
sudo systemctl start NetworkManager

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

#########
# Wrap Up
#########

sudo apt autoremove -y
sudo apt autoclean -y

# echo "options hid_apple fnmode=2" | sudo tee /etc/modprobe.d/hid_apple.conf
# sudo update-initramfs -u

what_happened="Update"
if $fresh_install ; then
    what_happend="Install"
fi
echo "$what_happened script complete"

echo "Reboot to ensure all changes take effect"
