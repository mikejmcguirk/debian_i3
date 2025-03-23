#!/bin/bash

set -e # quit on error
cp "$HOME/.bashrc" "$HOME/.bashrc.bak"

###################################################
# Declare all variables up front for easier editing
###################################################

# https://www.spotify.com/de-en/download/linux/
# Check directions for updated key
spotify_key="https://download.spotify.com/debian/pubkey_C85668DF69375001.gpg"

# https://obsidian.md/download
obsidian_url="https://github.com/obsidianmd/obsidian-releases/releases/download/v1.8.9/obsidian_1.8.9_amd64.deb"
obsidian_file=$(basename "$obsidian_url")

# NOTE: Check the instructions as well as the tar URL in case they change
nvim_url="https://github.com/neovim/neovim/releases/download/v0.10.4/nvim-linux-x86_64.tar.gz"
nvim_tar=$(basename "$nvim_url")
nvim_config="https://github.com/mikejmcguirk/Neovim-Win10-Lazy"

btop_url="https://github.com/aristocratos/btop/releases/download/v1.4.0/btop-x86_64-linux-musl.tbz"
btop_file=$(basename "$btop_url")

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

ghostty_url="https://github.com/psadi/ghostty-appimage/releases/download/v1.1.2%2B4/Ghostty-1.1.2-x86_64.AppImage"

# https://www.nerdfonts.com/font-downloads
nerd_font_url="https://github.com/ryanoasis/nerd-fonts/releases/download/v3.3.0/Cousine.zip"
nerd_font_filename=$(basename "$nerd_font_url")

discord_url="https://discord.com/api/download?platform=linux&format=deb"

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

####################
# Create Directories
####################

[ ! -d "$HOME/.local" ] && mkdir "$HOME/.local"
[ ! -d "$HOME/.local/bin" ] && mkdir "$HOME/.local/bin"
[ ! -d "$HOME/.config" ] && mkdir "$HOME/.config"
[ ! -d "$HOME/.fonts" ] && mkdir "$HOME/.fonts"
[ ! -d "$HOME/.ssh" ] && mkdir "$HOME/.ssh"

##################
# System Hardening
##################

sudo passwd -l root # disable root login with a password. Reverse with passwd -u root

sudo apt install -y ufw
sudo ufw default deny incoming # Should be default, but let's be sure
sudo ufw default allow outgoing # Also should be default
sudo ufw logging on
sudo ufw --force enable

sudo chmod 600 /etc/shadow

chmod 700 "$HOME/.ssh"

# FUTURE: There are settings that can be added as well to specify stronger cryptography
cat << 'EOF' > ~/.ssh/config
Host *
    ServerAliveInterval 60
    ServerAliveCountMax 30
EOF
chmod 600 "$HOME/.ssh/config"

##############################
# Install apt managed software
##############################

sudo apt update
sudo apt upgrade -y
sudo apt autoremove -y
sudo apt autoclean -y

sudo apt install -y build-essential
sudo apt install -y xclip # For copy/paste out of Neovim
sudo apt install -y vlc
sudo apt install -y curl
sudo apt install -y qbittorrent
sudo apt install -y wireguard
sudo apt install -y openresolv
sudo apt install -y natpmpc
sudo apt install -y shellcheck
sudo apt install -y fd-find
sudo apt install -y fzf
sudo apt install -y llvm
sudo apt install -y sqlite3
sudo apt install -y vim
sudo apt install -y unzip
sudo apt install -y python3-neovim
# NOTE: The Debian repo has a couple tools for reading perf off of Rust source code
# At least for now, I'm going to avoid speculatively installing them
# They can be checked with apt search linux-perf
sudo apt install -y linux-perf
# NOTE: Commented out for testing
# sudo apt install -y libreoffice
sudo apt install -y pkg-config # For cargo updater
sudo apt install -y libssl-dev # For cargo updater
sudo apt install -y mesa-utils # Get OpenGL info
sudo apt install -y bison # tmux build dep
sudo apt install -y ncurses-dev # tmux build dep
sudo apt install -y libevent-dev # tmux build dep

sudo apt install -y xorg
sudo apt install -y i3

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

# TODO: Virtual Box Info: https://www.virtualbox.org/wiki/Linux_Downloads

sudo apt install -y git
git config --global user.name "Mike J. McGuirk"
git config --global user.email "mike.j.mcguirk@gmail.com"
# TODO: sudo apt install git-credential-manager # TODO: I think this is the move
# But need to actually get into i3 so I can do testing before working on this

sudo curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg] https://brave-browser-apt-release.s3.brave.com/ stable main"|sudo tee /etc/apt/sources.list.d/brave-browser-release.list

curl -fsSL https://apt.fury.io/wez/gpg.key | sudo gpg --yes --dearmor -o /etc/apt/keyrings/wezterm-fury.gpg
echo 'deb [signed-by=/etc/apt/keyrings/wezterm-fury.gpg] https://apt.fury.io/wez/ * *' | sudo tee /etc/apt/sources.list.d/wezterm.list

sudo curl -sS $spotify_key | sudo gpg --dearmor --yes -o /etc/apt/trusted.gpg.d/spotify.gpg
echo "deb https://repository.spotify.com stable non-free" | sudo tee /etc/apt/sources.list.d/spotify.list

sudo apt update
sudo apt install -y brave-browser
sudo apt install -y wezterm
sudo apt install -y spotify-client

sudo apt remove -y neovim # Hacky, but whatever
sudo apt autoremove -y
sudo apt autoclean -y

################
# Install Neovim
################

if [ -z "$nvim_url" ] || [ -z "$nvim_tar" ] || [ -z "$nvim_config" ] ; then
    echo "Error: nvim_url, nvim_tar, and nvim_config must be set"
    exit 1
fi

[ ! -d "$HOME/.config/nvim" ] && mkdir "$HOME/.config/nvim"
git clone $nvim_config "$HOME/.config/nvim"

if [ -d "/opt/nvim" ]; then
    echo "Removing existing Nvim installation at /opt/nvim..."
    sudo rm -rf /opt/nvim
else
    echo "No existing Nvim installation found at /opt/nvim"
fi

curl -LO --output-dir "$HOME/.local" "$nvim_url"
sudo tar -C /opt -xzf "$HOME/.local/$nvim_tar"
rm "$HOME/.local/$nvim_tar"

cat << 'EOF' >> "$HOME/.bashrc"

export PATH="$PATH:/opt/nvim-linux-x86_64/bin"
EOF

##############
# Install Btop
##############

btop_install_dir="/opt/btop"

if [ ! -w "/opt" ]; then
    echo "This script needs root privileges to install to /opt. Please run with sudo."
    exit 1
fi

if [ -d "$btop_install_dir" ]; then
    echo "Removing existing Btop installation at $btop_install_dir..."
    rm -rf "$btop_install_dir"
else
    echo "No existing Btop installation found at $btop_install_dir"
fi

wget -P "/opt" "$btop_url"
tar xjvf "/opt/$btop_file" -C "/opt/"
bash "$btop_install_dir/install.sh"
rm "/opt/$btop_file"

cat << 'EOF' >> "$HOME/.bashrc"

export PATH="$PATH:/opt/btop/bin"
EOF

################
# Install Lua LS
################

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

curl -LO --output-dir "$HOME/.local" "$obsidian_url"
sudo apt install "$HOME/.local/$obsidian_file"
rm "$HOME/.local/$obsidian_file"

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

wget -qO- $nvm_install_url | bash

export NVM_DIR="$HOME/.nvm"
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
# TODO: lua_ls

##############
# Go Ecosystem
##############

if [ -z "$go_dl_url" ] || [ -z "$go_tar" ]; then
    echo "Error: go_dl_url and go_tar must be set."
    exit 1
fi

if [ -d "/usr/local/go" ]; then
    echo "Removing existing Go installation at /usr/local/go..."
    sudo rm -rf /usr/local/go
else
    echo "No existing Go installation found at /usr/local/go."
fi

wget -P "$HOME/.local" "$go_dl_url"
sudo tar -C /usr/local -xzf "$HOME/.local/$go_tar"
rm "$HOME/.local/$go_tar"

export PATH=$PATH:/usr/local/go/bin
export GOPATH=$(go env GOPATH)
export PATH=$PATH:$GOPATH/bin
go version
echo "Adding Go paths to $HOME/.bashrc..."
cat << 'EOF' >> "$HOME/.bashrc"

# Go environment setup
export PATH=$PATH:/usr/local/go/bin
export GOPATH=$(go env GOPATH)
export PATH=$PATH:$GOPATH/bin
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
[ ! -d "$discord_dl_dir" ] && mkdir "$discord_dl_dir"
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

wget -P "$HOME/.fonts" $nerd_font_url
unzip -o "$HOME/.fonts/$nerd_font_filename" -d ~/.fonts
rm "$HOME/.fonts/$nerd_font_filename"

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

# TODO: The URL should be a variable
git clone --bare https://github.com/mikejmcguirk/dotfiles "$HOME/.cfg"
git --git-dir="$HOME/.cfg" --work-tree="$HOME" checkout main

# TODO: For pulling my programming projects, do I pull from github or my local backups?

#########
# Ghostty
#########

ghostty_file="$HOME/.local/bin/ghostty"
curl -L -o "$ghostty_file" "$ghostty_url"
chmod +x "$ghostty_file"

######
# Tmux
######

tmux_git_dir="$HOME/.local/tmux-get"
[ ! -d "$tmux_git_dir" ] && mkdir "$tmux_git_dir"

git clone $tmux_url "$tmux_git_dir"
cd "$tmux_git_dir"

git checkout "$tmux_branch"
sh autogen.sh
./configure && make

cd "$HOME"
rm -rf "$tmux_git_dir"

tmux_plugins_dir="$HOME/.tmux/plugins"
[ ! -d "$tmux_plugins_dir" ] && mkdir "$tmux_plugins_dir"
tpm_dir="$tmux_plugins_dir/tpm"
rm -rf "$tpm_dir"

git clone https://github.com/tmux-plugins/tpm "$tpm_dir"

################
# Rust Ecosystem
################

# NOTE: Commented out for testing

# Rust is added last because it takes the longest (insert Rust comp times meme here)
# If you do this in the middle of the install, the sudo "session" actually times out

# curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# NOTE: My old script manually added rust-analyzer. Unsure why, but keeping the cmd here
# rustup component add rust-analyzer
# "$HOME/.cargo/bin/cargo" install --features lsp --locked taplo-cli
# "$HOME/.cargo/bin/cargo" install stylua
# "$HOME/.cargo/bin/cargo" install tokei
# "$HOME/.cargo/bin/cargo" install flamegraph
# "$HOME/.cargo/bin/cargo" install --features 'pcre2' ripgrep # For Perl Compatible Regex
# "$HOME/.cargo/bin/cargo" install cargo-update

# TODO: Unsure if I need this. Allows function keys to work properly on Keychron K2
# echo "options hid_apple fnmode=2" | sudo tee /etc/modprobe.d/hid_apple.conf
# sudo update-initramfs -u

echo "Install script complete"
echo "Reboot (or at least resource .bashrc) to ensure all changes take effect"
