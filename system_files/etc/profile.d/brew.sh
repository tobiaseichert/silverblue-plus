# shellcheck shell=sh
# Homebrew environment for login shells (bash; zsh via Fedora's /etc/zprofile)
if [ -x /home/linuxbrew/.linuxbrew/bin/brew ] && [ "$(id -u)" -ne 0 ]; then
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi
