#!/bin/bash

set -e # quit on error
cp "$HOME/.bashrc" "$HOME/.bashrc.bak"

###################
# Declare variables
###################

# https://www.spotify.com/de-en/download/linux/
# Check directions for updated key
spotify_key="https://download.spotify.com/debian/pubkey_C85668DF69375001.gpg"

# https://obsidian.md/download
obsidian_url="https://github.com/obsidianmd/obsidian-releases/releases/download/v1.8.9/obsidian_1.8.9_amd64.deb"
obsidian_file=$(basename "$obsidian_url")

# https://github.com/neovim/neovim/releases
# NOTE: Check the instructions as well as the tar URL in case they change
nvim_url="https://github.com/neovim/neovim/releases/download/v0.10.4/nvim-linux-x86_64.tar.gz"
nvim_tar=$(basename "$nvim_url")
nvim_config_repo="https://github.com/mikejmcguirk/Neovim-Win10-Lazy"

# https://github.com/neovim/neovim/releases
btop_url="https://github.com/aristocratos/btop/releases/download/v1.4.0/btop-x86_64-linux-musl.tbz"
btop_file=$(basename "$btop_url")

# https://github.com/neovim/neovim/releases
lua_ls_url="https://github.com/LuaLS/lua-language-server/releases/download/3.13.9/lua-language-server-3.13.9-linux-x64.tar.gz"
lua_ls_file=$(basename "$lua_ls_url")

# https://github.com/nvm-sh/nvm
# Check where this is used to make sure install cmd is still up-to-date
nvm_install_url="https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.2/install.sh"

# https://go.dev/doc/install
go_dl_url="https://go.dev/dl/go1.24.1.linux-amd64.tar.gz"
go_tar=$(basename "$go_dl_url")
# https://golangci-lint.run/welcome/install/#local-installation
# NOTE: Because the full cmd relies on go env GOPATH, we cannot declare it here
# Check the full curl|sh command on the website relative to what I have below
go_lint_url="https://raw.githubusercontent.com/golangci/golangci-lint/HEAD/install.sh"
go_lint_dir="bin v1.64.7"

tmux_url="https://github.com/tmux/tmux"
tmux_branch="tmux-3.5a"
tpm_repo="https://github.com/tmux-plugins/tpm"
tmux_power_repo="https://github.com/wfxr/tmux-power"

# https://github.com/neovim/neovim/releases
ghostty_url="https://github.com/psadi/ghostty-appimage/releases/download/v1.1.2%2B4/Ghostty-1.1.2-x86_64.AppImage"

# https://www.nerdfonts.com/font-downloads
nerd_font_url="https://github.com/ryanoasis/nerd-fonts/releases/download/v3.3.0/Cousine.zip"
nerd_font_filename=$(basename "$nerd_font_url")

discord_url="https://discord.com/api/download?platform=linux&format=deb"

dotfiles_url="https://github.com/mikejmcguirk/dotfiles"

# Rust URL
# Check curl cmd as well
rust_url=https://sh.rustup.rs

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

echo "This is a fresh install script. It will configure your system."
echo "Target home directory: $HOME"
read -p "Continue? (y/N): " choice
if [[ "$choice" != "y" && "$choice" != "Y" ]]; then
    echo "Exiting."
    exit 0
fi

##################
# System Hardening
##################

sudo passwd -l root # disable root login with a password. Reverse with passwd -u root

sudo apt install -y ufw
sudo ufw default deny incoming # Should be default, but let's be sure
sudo ufw default allow outgoing # Also should be default
sudo ufw logging on
sudo ufw --force enable

[ ! -d "$HOME/.ssh" ] && mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"

# FUTURE: There are settings that can be added as well to specify stronger cryptography
cat << 'EOF' > ~/.ssh/config
Host *
    ServerAliveInterval 60
    ServerAliveCountMax 30
EOF
chmod 600 "$HOME/.ssh/config"

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

sudo apt install -y build-essential
sudo apt install -y bison # tmux build dep
sudo apt install -y ncurses-dev # tmux build dep
sudo apt install -y libevent-dev # tmux build dep
sudo apt install -y pkg-config # For cargo updater
sudo apt install -y libssl-dev # For cargo updater
sudo apt install -y python3-neovim

###########
# Utilities
###########

sudo apt install -y curl
sudo apt install -y xclip # For copy/paste out of Neovim
sudo apt install -y fd-find
sudo apt install -y fzf
sudo apt install -y vim
sudo apt install -y unzip
sudo apt install -y qalculate-gtk
sudo apt install -y mesa-utils # Get OpenGL info
sudo apt install -y automake # tmux build dep
sudo apt install -y autoconf # tmux build dep
# NOTE: The Debian repo has a couple tools for reading perf off of Rust source code
# At least for now, I'm going to avoid speculatively installing them
# They can be checked with apt search linux-perf
sudo apt install -y linux-perf
sudo apt install -y sqlite3
sudo apt install -y gnome-disk-utility

# TODO: Virtual Box Info: https://www.virtualbox.org/wiki/Linux_Downloads

###########
# Dev Tools
###########

sudo apt install -y shellcheck
sudo apt install -y llvm

#####
# Git
#####

sudo apt install -y git
git config --global user.name "Mike J. McGuirk"
git config --global user.email "mike.j.mcguirk@gmail.com"
# Rebase can do goofy stuff
git config --global pull.rebase false
# FUTURE: This is dumb
git config --global credential.helper store

###########
# Wireguard
###########

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

##################
# General Programs
##################

sudo apt install -y vlc
sudo apt install -y qbittorrent
sudo apt install -y hexchat
sudo apt install -y libreoffice
# FUTURE: Should learn GIMP 3
sudo apt install -y pinta

##########
# Redshift
##########

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

# Write the Redshift configuration file using cat with a heredoc
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

#########
# Display
#########

sudo apt install -y xorg
sudo apt install -y i3
sudo apt install -y feh
sudo apt install -y picom

echo "Creating ~/.xinitrc to start i3 with startx..."
cat << 'EOF' > "$HOME/.xinitrc"
#!/bin/sh
# Optional: Add custom startup commands here (e.g., set display settings)
# xrdb -merge ~/.Xresources  # Uncomment if you use Xresources for config
exec i3
EOF
chmod +x "$HOME/.xinitrc"

# TODO: This is apparently supposed to ignore the nVidia stuff if it's a VM
# if [ -n "$(lspci | grep -i nvidia)" ]; then
#     echo "Detected NVIDIA GPU, installing drivers..."
#     sudo apt install -y nvidia-driver linux-headers-$(uname -r)
#     sudo nvidia-xconfig
# else
#     echo "No NVIDIA GPU detected, skipping driver installation (safe for VMs)."
# fi

##################
# Custom Apt Repos
##################

sudo curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg] https://brave-browser-apt-release.s3.brave.com/ stable main"|sudo tee /etc/apt/sources.list.d/brave-browser-release.list

sudo curl -sS $spotify_key | sudo gpg --dearmor --yes -o /etc/apt/trusted.gpg.d/spotify.gpg
echo "deb https://repository.spotify.com stable non-free" | sudo tee /etc/apt/sources.list.d/spotify.list

sudo apt update
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

###########
# Dumb hack
###########

sudo apt remove -y neovim
sudo apt autoremove -y
sudo apt autoclean -y

################
# Install Neovim
################

if [ -z "$nvim_url" ] || [ -z "$nvim_tar" ] || [ -z "$nvim_config_repo" ] ; then
    echo "Error: nvim_url, nvim_tar, and nvim_config_repo must be set"
    exit 1
fi

nvim_conf_dir="$HOME/.config/nvim"
[ ! -d "$nvim_conf_dir" ] && mkdir -p "$nvim_conf_dir"
git clone $nvim_config_repo "$nvim_conf_dir"

nvim_install_dir="/opt/nvim"
if [ -d "$nvim_install_dir" ]; then
    echo "Removing existing Nvim installation at $nvim_install_dir..."
    sudo rm -rf $nvim_install_dir
else
    echo "No existing Nvim installation found at $nvim_install_dir"
fi

nvim_tar_dir="$HOME/.local"
[ ! -d "$nvim_tar_dir" ] && mkdir -p "$nvim_tar_dir"
curl -LO --output-dir "$nvim_tar_dir" "$nvim_url"
sudo tar -C /opt -xzf "$nvim_tar_dir/$nvim_tar"
rm "$nvim_tar_dir/$nvim_tar"

cat << 'EOF' >> "$HOME/.bashrc"

export PATH="$PATH:/opt/nvim-linux-x86_64/bin"
EOF

##############
# Install Btop
##############

if [ -z "$btop_url" ] || [ -z "$btop_file" ] ; then
    echo "Error: btop_url and btop_file must be set"
    exit 1
fi

btop_install_dir="/opt/btop"

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

cat << 'EOF' >> "$HOME/.bashrc"

export PATH="$PATH:/opt/btop/bin"
EOF

################
# Install Lua LS
################

if [ -z "$lua_ls_url" ] || [ -z "$lua_ls_file" ] ; then
    echo "Error: lua_ls_url and lua_ls_file must be set"
    exit 1
fi

lua_ls_install_dir="$HOME/.local/bin/lua_ls"

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

cat << 'EOF' >> "$HOME/.bashrc"

export PATH="$PATH:$HOME/.local/bin/lua_ls/bin"
EOF

##########
# Obsidian
##########

if [ -z "$obsidian_url" ] || [ -z "$obsidian_file" ] ; then
    echo "Error: obsidian_url and obsidian_file must be set"
    exit 1
fi

obsidian_deb_dir="$HOME/.local"
curl -LO --output-dir "$obsidian_deb_dir" "$obsidian_url"
sudo apt install -y "$obsidian_deb_dir/$obsidian_file"
rm "$obsidian_deb_dir/$obsidian_file"

##################
# Python Ecosystem
##################

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

######################
# Javascript Ecosystem
######################

if [ -z "$nvm_install_url" ] ; then
    echo "nvim_install_url must be set"
    exit 1
fi

wget -qO- $nvm_install_url | bash

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

nvm install --lts
nvm alias default lts/*

# FUTURE: If needed, add eslint_d and prettier_d
npm i -g typescript-language-server typescript
npm i -g eslint
npm i -g --save-dev prettier
npm i -g vscode-langservers-extracted
npm i -g bash-language-server

##############
# Go Ecosystem
##############

if [ -z "$go_dl_url" ] || [ -z "$go_tar" ]; then
    echo "Error: go_dl_url and go_tar must be set."
    exit 1
fi

go_install_dir="/usr/local/go"
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

export PATH=$PATH:$go_install_dir/bin
export GOPATH=$(go env GOPATH)
export PATH=$PATH:$GOPATH/bin
go version
echo "Adding Go paths to $HOME/.bashrc..."
cat << EOF >> "$HOME/.bashrc"

# Go environment setup
export PATH=\$PATH:$go_install_dir/bin
export GOPATH=\$(go env GOPATH)
export PATH=\$PATH:\$GOPATH/bin
EOF

go install mvdan.cc/gofumpt@latest
go install golang.org/x/tools/gopls@latest
go install github.com/nametake/golangci-lint-langserver@latest

curl -sSfL $go_lint_url | sh -s -- -b $(go env GOPATH)/$go_lint_dir
golangci-lint --version

#########
# Discord
#########

discord_dl_dir="$HOME/.local"
[ ! -d "$discord_dl_dir" ] && mkdir -p "$discord_dl_dir"
deb_file="$discord_dl_dir/discord_deb.deb"

echo "Downloading Discord .deb from $discord_url..."
curl -L -o "$deb_file" "$discord_url" || {
    echo "Error: Download failed."
}

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

###############
# Add Nerd Font
###############

fonts_dir="$HOME/.fonts"
[ ! -d "$fonts_dir" ] && mkdir -p "$fonts_dir"

wget -P "$fonts_dir" $nerd_font_url
unzip -o "$fonts_dir/$nerd_font_filename" -d fonts_dir
rm "$fonts_dir/$nerd_font_filename"

##############
# Get Dotfiles
##############

if ! grep -q ".bashrc_custom" "$HOME/.bashrc"; then
    cat << 'EOF' >> "$HOME/.bashrc"

if [ -f "$HOME/.bashrc_custom" ]; then
    . "$HOME/.bashrc_custom"
fi
EOF
fi

dotfile_dir="$HOME/.cfg"
[ ! -d "$dotfile_dir" ] && mkdir -p "$dotfile_dir"
git clone --bare $dotfiles_url "$dotfile_dir"
git --git-dir="$dotfile_dir" --work-tree="$HOME" checkout main

#########
# Ghostty
#########

ghostty_dir="$HOME/.local/bin"
ghostty_file="$ghostty_dir/ghostty"
curl -L -o "$ghostty_file" "$ghostty_url"
chmod +x "$ghostty_file"

######
# Tmux
######

tmux_git_dir="$HOME/.local/bin/tmux"
[ ! -d "$tmux_git_dir" ] && mkdir -p "$tmux_git_dir"
git clone $tmux_url "$tmux_git_dir"
cd "$tmux_git_dir"

git checkout "$tmux_branch"
sh autogen.sh
# Makes into the download folder, so don't delete
./configure && make

echo "tmux build complete"
cd "$HOME"

cat << EOF >> "$HOME/.bashrc"

export PATH="\$PATH:/$tmux_git_dir"
EOF

# tmux list-keys to see where the binding looks to run the script
tmux_plugins_dir="$HOME/.config/tmux/plugins"
[ ! -d "$tmux_plugins_dir" ] && mkdir -p "$tmux_plugins_dir"
tpm_dir="$tmux_plugins_dir/tpm"
power_dir="$tmux_plugins_dir/power"

git clone $tpm_repo "$tpm_dir"
git clone $tmux_power_repo "$power_dir"

################
# Rust Ecosystem
################

# Rust is added last because it takes the longest (insert Rust comp times meme here)
# If you do this in the middle of the install, the sudo "session" actually times out

curl --proto '=https' --tlsv1.2 -sSf $rust_url | sh

# NOTE: My old script manually added rust-analyzer. Unsure why, but keeping the cmd here
# rustup component add rust-analyzer
cargo_bin="$HOME/.cargo/bin/cargo"
"$cargo_bin" install --features lsp --locked taplo-cli
"$cargo_bin" install stylua
"$cargo_bin" install tokei
"$cargo_bin" install flamegraph
"$cargo_bin" install --features 'pcre2' ripgrep # For Perl Compatible Regex
"$cargo_bin" install cargo-update

#########
# Wrap Up
#########

# TODO: Unsure if I need this. Allows function keys to work properly on Keychron K2
# echo "options hid_apple fnmode=2" | sudo tee /etc/modprobe.d/hid_apple.conf
# sudo update-initramfs -u

echo "Install script complete"
echo "Reboot (or at least resource .bashrc) to ensure all changes take effect"
