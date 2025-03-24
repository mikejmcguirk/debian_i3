#!/bin/bash

set -e # quit on error
cp "$HOME/.bashrc" "$HOME/.bashrc.bak"

###################
# Declare variables
###################

# https://www.spotify.com/de-en/download/linux/
# Check directions for updated key
new_spotify_key=false
spotify_key="https://download.spotify.com/debian/pubkey_C85668DF69375001.gpg"

# https://obsidian.md/download
obsidian_url="https://github.com/obsidianmd/obsidian-releases/releases/download/v1.8.9/obsidian_1.8.9_amd64.deb"
obsidian_file=$(basename "$obsidian_url")

# https://github.com/neovim/neovim/releases
# NOTE: Check the instructions as well as the tar URL in case they change
nvim_update=false
nvim_url="https://github.com/neovim/neovim/releases/download/v0.10.4/nvim-linux-x86_64.tar.gz"
nvim_tar=$(basename "$nvim_url")

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

#############
# Apt Updates
#############

if $new_spotify_key; then
    sudo curl -sS $spotify_key | sudo gpg --dearmor --yes -o /etc/apt/trusted.gpg.d/spotify.gpg
    echo "deb https://repository.spotify.com stable non-free" | sudo tee /etc/apt/sources.list.d/spotify.list
fi

sudo apt update
sudo apt upgrade -y
sudo apt autoremove -y
sudo apt autoclean -y

###########
# Dumb hack
###########

sudo apt remove -y neovim
sudo apt autoremove -y
sudo apt autoclean -y

########
# Neovim
########

if [ -z "$nvim_url" ] || [ -z "$nvim_tar" ] ; then
    echo "Error: nvim_url, nvim_tar, and nvim_config_repo must be set"
    exit 1
fi

if $nvim_update; then
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
fi

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
