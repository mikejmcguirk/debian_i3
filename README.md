WIP

## General Notes

- For Debian 12
- Designed to produce an i3 system that initializes with startx

## OS Installation Notes

- I personally don't use the graphical install
- At the software selection prompt, only choose standard system utilities

# After installing the OS

- Login first as root. Do the following:

```bash
apt update
apt install -y sudo
usermod -aG sudo [your admin user from setup]
reboot
```

- Login as your admin user.
- Run this script from your home directory with:

```bash
wget https://raw.githubusercontent.com/mikejmcguirk/debian_i3/refs/heads/main/install.sh
bash install.sh
```

- When the script is finished, reboot as directed

<!--Save the update script. Run that with sudo bash as needed-->

## Post Install Steps/Checks:

- Open i3 with startx
- Open a terminal and run the commands below:

```bash
cd "$HOME/.local/bin/magick"
./configure
make
sudo make install
sudo ldconfig /usr/local/lib
wget https://raw.githubusercontent.com/betterlockscreen/betterlockscreen/main/install.sh -O - -q | bash -s user latest
betterlockscreen -u "$HOME/.config/wallpaper/alena-aenami-rooflinesgirl-1k-2-someday.jpg" --fx dim
```

*NOTE: I am not sure what part of the process breaks, but the Magick install does not complete correctly when done from the script*

- Verify qalculate is in dark mode
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
    - python
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
- Thunar
  - Verify dark mode
  - Do an open with > image viewer to set that default
- While this script does install rsync, it does not contain automation for file backups. You will need to set that up manually

Known Issues:

- Brave might not be able to access the keyring properly on the first login. This should be fixed after another restart. Run Brave from the terminal to see if this is occurring

DOTFILES INFO:

https://www.atlassian.com/git/tutorials/dotfiles
https://wiki.archlinux.org/title/Dotfiles
