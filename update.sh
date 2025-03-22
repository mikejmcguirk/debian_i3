#!/bin/bash

apt update
apt upgrade -y
apt autoremove -y # TODO: Does this replace clean and autoclean?

rustup update
cargo install-update -a

# TODO: how do you update nvm? Just re-run the installer?
nvm install --lts
nvm alias default lts/* # TODO: Is this needed? Looks like it's handled in install cmd

# TODO: Right now I'm just using the install commands to update npm packages. Is this best?

# TODO: How do you update pipx software?
