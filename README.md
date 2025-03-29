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

- Set qalculate to dark mode
- Set Gnome Disk Utility to dark mode
- Pull in Wireguard configs
- Test VLC
- Setup qbittorrent in GUI
- Fix Redshift config and test
- Brave
  - Verify no errors when opening in terminal
  - Configure default pages
  - Add bookmarks
  - Disable ctrl+w/ctrl+W keys (might need Shortkeys)
  - Extensions:
    - Dark reader
    - Return Youtube dislike
    - Youtube non-stop
    - 7TV
    - Onetab
- Edit GUI Spotify settings
- Test that config pathing works
- Setup Github token
- Nvim
  - Run ``which nvim`` to verify the right path is being seen
  - Run nvim to pull in plugins
  - Verify the LSP/formatter/linter work for the following:
    - lua
    - bash
    - Javascript
    - html
    - css
    - go
    - rust
    - toml
- Check btop
- Obsidian
  - Make sure app works
  - Import vault and make sure it loads
  - Test that Nvim integration (screencaps, renames, Obsidian open) works
- Check nvitop
- Verify Discord works (including audio)
- ghostty should open with mod+enter in i3 with Cousine Nerd Font
- Enter tmux, use prefix-I to download plugins
- Setup backup jobs
- Adjust mouse speed/acceleration
- Rust
  - Make sure cargo flamegraph --release works
  - Test tokei and rg

Known Issues:

- Brave might not be able to access the keyring properly on the first login. This should be fixed after another restart. Run Brave from the terminal to see if this is occurring

DOTFILES INFO:

https://www.atlassian.com/git/tutorials/dotfiles
https://wiki.archlinux.org/title/Dotfiles
