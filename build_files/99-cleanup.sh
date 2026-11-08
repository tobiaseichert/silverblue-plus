#!/usr/bin/env bash
# Leave /var and /tmp clean so `bootc container lint` is happy.
# (/var/cache, /var/log and /tmp are build-time mounts and never land in the image.)
set -euxo pipefail

# RPM Fusion is only needed while building: its packages are already in the
# image and get updated with each new image. Removing the release RPMs drops
# the repo files (free, nonfree, nonfree-steam). rpm -e touches nothing else.
rpm -e rpmfusion-nonfree-release rpmfusion-free-release
test -z "$(ls /etc/yum.repos.d/rpmfusion-* 2>/dev/null)"

dnf5 clean all
rm -rf /var/lib/dnf

# /run is a tmpfs at runtime; drop what dnf and SELinux left there during the build
rm -rf /run/dnf /run/setrans
