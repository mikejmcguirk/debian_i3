# WIP

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

## Post Install Steps/Checks:

- Open i3 with startx
- Open a terminal and run the command below:

```bash
betterlockscreen -u "$HOME/.config/wallpaper/alena-aenami-rooflinesgirl-1k-2-someday.jpg" --fx dim
```

- The comments in the install script contain the post-install checks

- The following steps need to be completed manually:
  - Setup backup jobs
  - Adjust mouse speed/acceleration

## Known Issues:

- Brave might not be able to access Gnome Keyring on first login. This issue should not recur after a restart. Run from the terminal to check for this

DOTFILES INFO:

https://www.atlassian.com/git/tutorials/dotfiles
https://wiki.archlinux.org/title/Dotfiles
