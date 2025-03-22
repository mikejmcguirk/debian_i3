WIP

For Debian 12

When installing:

- I personally don't use the graphical install
- At the software selection prompt, only choose standard system utilities

Login first as root. Do the following:

```bash
apt update
aupt install sudo
usermod -aG sudo admin_user
reboot
```

Then login as your admin user.

Run this script with ``wget -qO- [raw url] | sudo bash``

Save the update script. Run that with sudo bash as needed
