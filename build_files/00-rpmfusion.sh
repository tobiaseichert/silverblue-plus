#!/usr/bin/env bash
# Enable RPM Fusion (free + nonfree, incl. the Steam repo).
set -euxo pipefail

FEDORA="$(rpm -E %fedora)"

# Fedora 45 enforces RPM signatures (%_pkgverify_level=all), so import the
# RPM Fusion keys *before* installing the release packages. The 2020 keys
# are the ones RPM Fusion uses for all current Fedora releases.
rpmkeys --import \
    https://mirrors.rpmfusion.org/free/fedora/RPM-GPG-KEY-rpmfusion-free-fedora-2020 \
    https://mirrors.rpmfusion.org/nonfree/fedora/RPM-GPG-KEY-rpmfusion-nonfree-fedora-2020

dnf5 -y install \
    "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-${FEDORA}.noarch.rpm" \
    "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-${FEDORA}.noarch.rpm"

# Steam lives in its own repo
dnf5 config-manager setopt rpmfusion-nonfree-steam.enabled=1

dnf5 repolist
