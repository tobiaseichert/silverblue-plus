#!/usr/bin/env bash
# Command-line tools and shell, all from Fedora (unrar from RPM Fusion nonfree).
set -euxo pipefail

dnf5 -y install \
    zsh \
    vim-enhanced \
    btop \
    duf \
    fastfetch \
    glow \
    gum \
    lsb_release

# Archives: lzip, 7-Zip (whichever Fedora package provides /usr/bin/7z),
# and RARLAB's unrar from RPM Fusion nonfree (higher version than Fedora's
# unrar-free wrapper, so dnf picks it). Creating .rar is not packaged.
dnf5 -y install \
    lzip \
    /usr/bin/7z \
    unrar

# Make sure we really got RARLAB's build, not the unrar-free wrapper
# (unrar without arguments prints its banner and exits non-zero)
{ unrar || true; } 2>&1 | grep 'Alexander Roshal' >/dev/null

# FUSE 2 library: needed to run AppImages (e.g. LM Studio)
dnf5 -y install fuse-libs
