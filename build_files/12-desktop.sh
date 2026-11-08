#!/usr/bin/env bash
# Desktop tools from Fedora.
set -euxo pipefail

# GNOME Tweaks: fonts, titlebar buttons, legacy app theme, startup apps.
# Not on Flathub, so it has to be in the image.
dnf5 -y install gnome-tweaks
