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

Post Install Steps/Checks:

- Nvim
  - Run ``which nvim`` to verify the right path is being seen
  - Run nvim to pull in plugins
  - Open a config file to verify lua_ls works
- Enter tmux, use prefix-I to download plugins
- Create a Github token and use it to push
- Pull in Wireguard configs
- Setup qbittorrent in GUI
- Edit GUI Spotify settings
- Configure Brave default pages, add bookmarks, and disable ctrl+w/ctrl+W keys
- Brave
  - Configure default pages
  - Add bookmarks
  - Disable ctrl+w/ctrl+W keys (might need Shortkeys)
  - Extensions:
    - Dark reader
    - Return Youtube dislike
    - Youtube non-stop
    - 7TV
    - Onetab
- Setup backup jobs
- Adjust mouse speed/acceleration
- Verify Redshift is working
- Set qalculate to dark mode
- Rust
  - Open a project and make sure rust-analyzer works
  - Make sure cargo flamegraph --release works
- Open a toml file and make sure taplo works
- Open brave-browser in a terminal and verify no dbus display errors

Known Issues:

- Brave might not be able to access the keyring properly on the first login. This should be fixed after another restart. Run Brave from the terminal to see if this is occurring

DOTFILES INFO:

https://www.atlassian.com/git/tutorials/dotfiles
https://wiki.archlinux.org/title/Dotfiles
