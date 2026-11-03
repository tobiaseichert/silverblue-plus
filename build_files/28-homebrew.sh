#!/usr/bin/env bash
# Homebrew snapshot for an offline first-boot setup. Homebrew has to live in
# /home/linuxbrew/.linuxbrew (writable, per machine), so the image only carries
# an archive; brew-setup.service unpacks it at first boot.
set -euxo pipefail

# git is needed by brew at runtime, zstd for the archive
dnf5 -y install git-core zstd

# Official installer, unattended. Homebrew only runs as root inside a
# container, which it detects via /.dockerenv.
curl --retry 3 -fsSLo /tmp/brew-install \
    https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh
touch /.dockerenv
# /home is a symlink to /var/home, which doesn't exist at build time
HOMEDIR="$(realpath -m /home)"
[ -d "${HOMEDIR}" ] && NEW_HOMEDIR="" || NEW_HOMEDIR="${HOMEDIR}"
mkdir -p "${HOMEDIR}/linuxbrew"
env -i PATH=/usr/bin:/usr/sbin HOME=/tmp/brew-home NONINTERACTIVE=1 \
    bash /tmp/brew-install
env -i PATH=/usr/bin:/usr/sbin HOME=/tmp/brew-home \
    /home/linuxbrew/.linuxbrew/bin/brew --version
rm -f /.dockerenv

# Archive relative to /home/linuxbrew, so unpacking never touches the /home
# symlink. Then remove the build copy (/var/home is not part of the image).
tar --zstd -C /home/linuxbrew -cf /usr/share/homebrew.tar.zst .linuxbrew
rm -rf "${HOMEDIR}/linuxbrew"
[ -z "${NEW_HOMEDIR}" ] || rmdir "${NEW_HOMEDIR}"
ls -lh /usr/share/homebrew.tar.zst
