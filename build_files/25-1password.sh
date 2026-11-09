#!/usr/bin/env bash
# 1Password desktop app + `op` CLI from 1Password's official repo, baked into the image
# so the browser integration with the (RPM) Firefox works.
#
# Atomic-specific handling:
#  - /opt is a symlink to /var/opt, and /var is not updated by image
#    upgrades. The app is therefore moved to /usr/lib/1Password and linked
#    back to /opt/1Password at boot via tmpfiles.d.
#  - The "onepassword" group gets a fixed GID and a sysusers.d entry, so it
#    exists on the deployed system and matches the file ownership in the image
#    (BrowserSupport is setgid onepassword). Same for "onepassword-cli",
#    which owns the setgid `op` CLI, and "onepassword-mcp", which owns the
#    setgid 1password-mcp server (1Password checks the group of connecting
#    peers via SO_PEERCRED).
#  - The repo file is removed after install: updates come with the image.
set -euxo pipefail

GID_ONEPASSWORD=1500
GID_ONEPASSWORD_CLI=1600
GID_ONEPASSWORD_MCP=1700

# Package signing key (Fedora 45 enforces RPM signatures)
rpmkeys --import https://downloads.1password.com/linux/keys/1password.asc

cat > /etc/yum.repos.d/1password.repo <<'EOF'
[1password]
name=1Password Stable Channel
baseurl=https://downloads.1password.com/linux/rpm/stable/$basearch
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://downloads.1password.com/linux/keys/1password.asc
EOF

# Pre-create the groups with fixed GIDs; the RPM scriptlets reuse them
groupadd -g "${GID_ONEPASSWORD}" onepassword
groupadd -g "${GID_ONEPASSWORD_CLI}" onepassword-cli
groupadd -g "${GID_ONEPASSWORD_MCP}" onepassword-mcp

# /opt -> /var/opt only exists at runtime; give the RPM somewhere to write
mkdir -p /var/opt

dnf5 -y install 1password 1password-cli

# Move out of /var into the immutable image, keep the old path working
mv /var/opt/1Password /usr/lib/1Password
rmdir /var/opt || true

# rpm no longer owns the moved files; tag them so rechunking (see the build
# workflow) puts them in their own layer and not the catch-all layer
find /usr/lib/1Password ! -type l -exec setfattr -n user.component -v 1password {} +

cat > /usr/lib/tmpfiles.d/onepassword.conf <<'EOF'
d /var/opt 0755 root root -
L /opt/1Password - - - - /usr/lib/1Password
EOF

cat > /usr/lib/sysusers.d/onepassword.conf <<EOF
g onepassword ${GID_ONEPASSWORD}
g onepassword-cli ${GID_ONEPASSWORD_CLI}
g onepassword-mcp ${GID_ONEPASSWORD_MCP}
EOF

# Sanity checks: launcher symlink and setgid helper survived the move
test -x /usr/lib/1Password/1password
stat -c '%A %G' /usr/lib/1Password/1Password-BrowserSupport | grep -q '^-..x..s... onepassword$'
# op is setgid onepassword-cli (needed for the desktop-app integration)
stat -c '%A %G' /usr/bin/op | grep -q '^-..x..s... onepassword-cli$'
# The MCP server is setgid onepassword-mcp
stat -c '%A %G' /usr/lib/1Password/1password-mcp | grep -q '^-..x..s... onepassword-mcp$'

rm -f /etc/yum.repos.d/1password.repo
