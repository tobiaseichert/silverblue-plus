#!/usr/bin/env bash
# Leave /var and /tmp clean so `bootc container lint` is happy.
# (/var/cache, /var/log and /tmp are build-time mounts and never land in the image.)
set -euxo pipefail

dnf5 clean all
rm -rf /var/lib/dnf
