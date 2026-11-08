#!/usr/bin/env bash
# Multimedia: full codecs from RPM Fusion and AMD hardware video acceleration.
set -euxo pipefail

# Full ffmpeg instead of Fedora's ffmpeg-free/libav*-free (H.264/HEVC/AAC).
# Used system-wide, e.g. by the preinstalled Firefox RPM. This is RPM Fusion's
# documented command; --allowerasing lets ffmpeg-libs replace the *-free libs.
dnf5 -y swap ffmpeg-free ffmpeg --allowerasing

# VA-API driver with H.264/HEVC (Fedora's Mesa disables them). It must match
# Fedora's Mesa version; if RPM Fusion is ahead, keep Fedora's driver for now.
# Install it, don't swap it: Fedora's VA drivers now live inside
# mesa-dri-drivers (which Provides mesa-va-drivers), so swapping would try to
# remove mesa-dri-drivers. The freeworld build installs alongside it in
# /usr/lib64/dri-freeworld, which Fedora's libva searches before /usr/lib64/dri.
MESA_VER="$(rpm -q --qf '%{VERSION}\n' mesa-dri-drivers.x86_64)"
FW_VER="$(dnf5 -q repoquery --available --latest-limit=1 --qf '%{version}\n' \
    mesa-va-drivers-freeworld.x86_64 | head -n1)"
if [ -n "${FW_VER}" ] && [ "${FW_VER}" = "${MESA_VER}" ]; then
    dnf5 -y install mesa-va-drivers-freeworld
    rpm -q mesa-va-drivers-freeworld
else
    echo "::warning::mesa-va-drivers-freeworld ${FW_VER:-not found} does not match Fedora Mesa ${MESA_VER}; keeping Fedora's mesa-va-drivers (no HW H.264/HEVC in this image)"
fi

# GStreamer codecs for GStreamer-based apps on the RPM side (GNOME, WebKitGTK)
dnf5 -y install \
    gstreamer1-plugin-libav \
    gstreamer1-plugins-bad-freeworld \
    gstreamer1-plugins-ugly

# Diagnostics: vainfo, vulkaninfo
dnf5 -y install \
    libva-utils \
    vulkan-tools
