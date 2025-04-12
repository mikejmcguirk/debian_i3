This is my personal use script for getting an i3 startx system running on Debian 12. This script:

- Relies on my personal dotfiles
- Requires post-run steps
- Contains some personal convenience settings for me that might not be a fit for all users
- Might contain untested steps

This also functions as an update script for the applications not managed by apt. The beginning of the script will prompt if this is a fresh install or an update. To update specific programs, enter them as args when running. The specific args can be found in the code

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

## Post Install Steps/Checks:

- If installing nvidia drivers:

```bash
nvidia-detect # To verify the card is detected
sudo apt install nvidia-driver firmware-misc-nonfree # Hit OK at the nouveau conflict window
sudo apt install nvidia-xconfig
sudo nvidia-xconfig
reboot # To resolve nouveau conflict

# After reboot
nvidia-smi # Verify nVidia drivers are running
```

- Open i3 with startx
- Open a terminal and run the command below:

```bash
betterlockscreen -u "$HOME/.config/wallpaper/alena-aenami-rooflinesgirl-1k-2-someday.jpg" --fx dim
```

- The comments in the install script contain the post-install checks

- The following steps need to be completed manually:
  - Setup backup jobs
  - Adjust mouse speed/acceleration

- Other post-install checks:
  - Verify copy/paste works in Neovim
  - Use ``which nvim`` to verify correct path
  - Verify that gnome-disks can detect and mount all desired drives
  - Verify VLC plays audio and video
  - Set redshift latitude and longitude
  - Verify you can do cargo flamegraph with Rust
  - Setup any backups you want to run
  - Configure wireguard
  - Confirm Spotify works. Update GUI settings (mainly stream quality)
  - Verify that reboot and poweroff work without sudo
  - Restore Brave settings
  - Open tmux and use prefix+I to load plugins
  - Restore Obsidian vault. Verify that Neovim extension works
  - Verify that Discord audio calling works both ways

## Known Issues:

- Brave might not be able to access Gnome Keyring on first login. This issue should not recur after a restart. Run from the terminal to check for this

DOTFILES INFO:

- https://www.atlassian.com/git/tutorials/dotfiles
- https://wiki.archlinux.org/title/Dotfiles
