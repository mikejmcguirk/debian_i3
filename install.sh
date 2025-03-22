#!/bin/bash

set -e # quit on error

###################################################
# Declare all variables up front for easier editing
###################################################

# TODO: The Go filename should derive from the url
go_dl_url="https://go.dev/dl/go1.24.1.linux-amd64.tar.gz"
go_tar="go1.24.1.linux-amd64.tar.gz"
go_lint="https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh"

# TODO: the filename at least should derive from the font URL
nerd_font_url="https://github.com/ryanoasis/nerd-fonts/releases/download/v3.3.0/Cousine.zip"
nerd_font_filename="Cousine.zip"

##########################
# Check we are a Sudo user
##########################

if [ -z "$SUDO_USER" ]; then
    echo "You ain't sudoin'"
    exit 1
fi
user_home=$(getent passwd "$SUDO_USER" | cut -d: -f6)

#############################
# Confirm we want to continue
#############################

echo "This is a fresh install script. It will configure your system."
echo "Target user: $SUDO_USER"
echo "Target home directory: $user_home"
read -p "Continue? (y/N): " choice
if [[ "$choice" != "y" && "$choice" != "Y" ]]; then
    echo "Exiting."
    exit 0
fi

####################
# Create Directories
####################

[ ! -d "$user_home/.local" ] && mkdir "$user_home/.local"
[ ! -d "$user_home/.fonts" ] && mkdir "$user_home/.fonts"

##################
# System Hardening
##################

passwd -l root # disable root login with a password. Reverse with passwd -u root

apt install -y ufw
ufw default deny incoming # Should be default, but let's be sure
ufw default allow outgoing # Also should be default
ufw logging on
ufw --force enable

chmod 600 /etc/shadow

# TODO: How to make SSH out work. My Mint machine doesn't have an SSH service so I guess
# that's not necessary
# TODO: SSH hardening

##############################
# Install apt managed software
##############################

apt update
apt upgrade -y
apt autoremove -y # TODO: Does this replace clean and autoclean?

apt install -y build-essential
apt install -y xclip # For copy/paste out of Neovim
apt install -y vlc
apt install -y curl
apt install -y qbittorrent
apt install -y wireguard
apt install -y openresolv
apt install -y natpmpc
apt install -y shellcheck
apt install -y fd-find
apt install -y fzf
apt install -y llvm
apt install -y sqlite3
# NOTE: The Debian repo has a couple tools for reading perf off of Rust source code
# At least for now, I'm going to avoid speculatively installing them
# They can be checked with apt search linux-perf
apt install -y linux-perf
# apt install -y libreoffice

# TODO: Do we need Vim? Or does Nvim replace it if we build from source?

# TODO: Virtual Box Info: https://www.virtualbox.org/wiki/Linux_Downloads

apt install -y git
git config --global user.name "Mike J. McGuirk"
git config --global user.email "mike.j.mcguirk@gmail.com"
# sudo apt install git-credential-manager # TODO: I think this is the move

curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg] https://brave-browser-apt-release.s3.brave.com/ stable main"|sudo tee /etc/apt/sources.list.d/brave-browser-release.list

curl -fsSL https://apt.fury.io/wez/gpg.key | sudo gpg --yes --dearmor -o /etc/apt/keyrings/wezterm-fury.gpg
echo 'deb [signed-by=/etc/apt/keyrings/wezterm-fury.gpg] https://apt.fury.io/wez/ * *' | sudo tee /etc/apt/sources.list.d/wezterm.list

apt update
apt install -y brave-browser
apt install -y wezterm

################
# Rust Ecosystem
################

# TODO: Is there a way to automatically proceed with the standard installation?
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# TODO: I have some weird hack in my script to add rust-analyzer to make it run on
# stable instead of nightly. Feels silly
# rustup component add rust-analyzer
"$user_home/.cargo/bin/cargo" install --features lsp --locked taplo-cli
"$user_home/.cargo/bin/cargo" install stylua
"$user_home/.cargo/bin/cargo" install tokei
"$user_home/.cargo/bin/cargo" install flamegraph
"$user_home/.cargo/bin/cargo" install --features 'pcre2' ripgrep # For Perl Compatible Regex
"$user_home/.cargo/bin/cargo" install cargo-update

######################
# Javascript Ecosystem
######################

# TODO: Do I put this in a variable?
wget -qO- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.2/install.sh | bash
# TODO: Can something similar to this be used to make Cargo work?
export NVM_DIR="$user_home/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

nvm install --lts
nvm alias default lts/* # TODO: Is this needed? Looks like it's handled in install cmd

# FUTURE: If needed, add eslint_d and prettier_d
npm i -g typescript-language-server typescript
npm i -g eslint
npm i -g --save-dev prettier
npm i -g vscode-langservers-extracted
npm i -g bash-language-server

# TODO: btop
# TODO: nvim
# TODO: lua_ls
# TODO: wezterm

##################
# Python Ecosystem
##################

apt install -y python3-full
apt install -y python3-pip # TODO: Wait, do I need this?
apt install -y python3-pipx
pipx ensurepath # TODO: What does this do? Does it contradict my .bashrc?
source "$user_home/.bashrc" # TODO: Get the runner name and make this an absolute path

pipx install nvitop
pipx install beautysh
pipx install ruff
pipx install python-lsp-server[all]

##############
# Go Ecosystem
##############

rm -rf usr/local/go # TODO: Does this need to check if it exists?
wget -P "$user_home/.local" $go_dl_url # TODO: Why is this going to .local?
tar -C /usr/local -xzf "$user_home/.local/$go_tar"
rm "$user_home/.local/$go_tar"

# TODO: I'm pretty sure there's pathing you need to do here to make Go work
go install mvdan.cc/gofumpt@latest
go install golang.org/x/tools/gopls@latest
go install github.com/nametake/golangci-lint-langserver@latest

# TODO: Why does this have a version number? Does it need to be variabled?
curl -sSfL $go_lint | sh -s -- -b $(go env GOPATH)/bin v1.61.0

###############
# Add Nerd Font
###############

wget -P "$user_home/.fonts" $nerd_font_url
unzip -o "$user_home/.fonts/$nerd_font_filename" -d ~/.fonts
rm "$user_home/.fonts/$nerd_font_filename"

##############
# Get Dotfiles
##############

if ! grep -q ".bashrc_custom" "$user_home/.bashrc"; then
    cat << 'EOF' >> "$user_home/.bashrc"
    if [ -f "$user_home/.bashrc_custom" ]; then
        . "$user_home/.bashrc_custom"
    fi
EOF
fi

git clone --bare https://github.com/mikejmcguirk/dotfiles "$user_home/.cfg"
git --git-dir="$user_home/.cfg" --work-tree="$user_home" checkout main
# source "$user_home/.bashrc" # TODO: Maybe?

# TODO: Put the equivalent of autoremove/autoclean at the end

# TODO: Unsure if I need this. Allows function keys to work properly on Keychron K2
# echo "options hid_apple fnmode=2" | sudo tee /etc/modprobe.d/hid_apple.conf
# sudo update-initramfs -u

# TODO: If still using lightdm, add this to config: allow-root=false

###############
# Unused/Extras
###############

# Packages I've previously installed, but don't know the purpose of anymore
# - cmake
# - libssl-dev
# - libsystemd-dev
# - libparted-dev
# - libicu-dev
# - libcairo2
# - libcairo2-dev
# - libcurl4-openssl-dev
# - meson
# - libdbus-1-dev
# - libgirepository1.0-dev
# - doxygen (I forget why I installed this)
# - libmbedtls-dev
# - zlib1g-dev
# - libevent-dev
# - ncurses-dev
# - bison
# - pkg-config
# - gh
# - libc6
# - libgcc1
# - libgcc-s1
# - libgssapi-krb5-2
# - libicu70
# - liblttng-ust1
# - libssl3
# - libstdc++6
# - libunwind8
# - zlib1g
# - peek
