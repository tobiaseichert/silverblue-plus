#!/usr/bin/env bash
# Hardware helpers, monitoring and Btrfs tools from Fedora.
set -euxo pipefail

# ddcutil: control external monitors over DDC/CI (brightness, contrast,
# input source), e.g. via a GNOME brightness extension. Fedora's package
# ships its own modules-load.d entry (i2c-dev) and udev rules that give the
# logged-in user access to the monitor's I2C bus.
dnf5 -y install ddcutil

# nvtop: terminal GPU monitor (load, VRAM, clocks, per-process usage; AMD too)
dnf5 -y install nvtop

# compsize: real on-disk size of files on Btrfs (after zstd compression)
dnf5 -y install compsize

# Btrfs Assistant: GUI for subvolumes, space usage, scrub/balance (Qt app)
dnf5 -y install btrfs-assistant
