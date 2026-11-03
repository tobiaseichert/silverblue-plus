#!/usr/bin/env bash
# Gaming: Steam (RPM Fusion), Gamescope, MangoHud. No Steam Gaming Mode.
set -euxo pipefail

dnf5 -y install \
    steam \
    steam-devices \
    gamescope \
    mangohud \
    mangohud.i686

# Distrobox: run other distros in containers, export their apps
dnf5 -y install distrobox
