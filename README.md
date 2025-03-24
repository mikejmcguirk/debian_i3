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

Reboot as directed

<!--Save the update script. Run that with sudo bash as needed-->

Post run steps:

- Enter Neovim to make its packages install
- Enter tmux, use prefix-I to download plugins
- Create a Github token and use it to push
- Pull in Wireguard configs
- Setup qbittorrent in GUI
- Edit GUI Spotify settings
- Configure Brave default pages, add bookmarks, and disable ctrl+w/ctrl+W keys
- Setup backup jobs
- Adjust mouse speed/acceleration
- Verify Redshift is working

(The config repo contains an i3 config. Should not need to generate a new one)

DOTFILES INFO:

https://www.atlassian.com/git/tutorials/dotfiles
https://wiki.archlinux.org/title/Dotfiles
