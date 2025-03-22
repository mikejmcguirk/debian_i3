#!/bin/bash

# TODO: Make two scripts. One to run as sudo and one to run as not
# At least on Mint this weird thing happens where if you don't run apt as sudo then like
# It won't actually install the Kernal upgrades
# Maybe Debian and/or apt are different though? But I don't know how to test this

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
