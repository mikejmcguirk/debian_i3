WIP

For Debian 12

Designed to produce an i3 system that initializes with startx

When installing:

- I personally don't use the graphical install
- At the software selection prompt, only choose standard system utilities

Login first as root. Do the following:

```bash
apt update
apt install sudo
usermod -aG sudo [your admin user from setup]
reboot
```

Login as your admin user.

Run this script from your home directory with:
```bash
wget https://raw.githubusercontent.com/mikejmcguirk/debian_i3/refs/heads/main/install.sh
bash install.sh
```

<!--Save the update script. Run that with sudo bash as needed-->

Post run steps:

- Enter Neovim to make its packages install
- Install Discord (maybe)
- Enter tmux, use prefix-i to download plugins
- Pull in Wireguard configs
- Setup qbittorrent in GUI
- Configure Brave default pages, add bookmarks, and disable ctrl+w/ctrl+W keys

(The config repo contains an i3 config. Should not need to generate a new one)
