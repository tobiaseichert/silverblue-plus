#!/usr/bin/env bash
# Multimedia: full codecs from RPM Fusion and AMD hardware video acceleration.
set -euxo pipefail

# Full ffmpeg instead of Fedora's ffmpeg-free/libav*-free (H.264/HEVC/AAC).
# Used system-wide, e.g. by the preinstalled Firefox RPM. This is RPM Fusion's
# documented command; --allowerasing lets ffmpeg-libs replace the *-free libs.
dnf5 -y swap ffmpeg-free ffmpeg --allowerasing

# VA-API driver with H.264/HEVC enabled (Fedora's Mesa disables them)
dnf5 -y swap mesa-va-drivers mesa-va-drivers-freeworld

# GStreamer codecs for GStreamer-based apps on the RPM side (GNOME, WebKitGTK)
dnf5 -y install \
    gstreamer1-plugin-libav \
    gstreamer1-plugins-bad-freeworld \
    gstreamer1-plugins-ugly

# Diagnostics: vainfo, vulkaninfo
dnf5 -y install \
    libva-utils \
    vulkan-tools
