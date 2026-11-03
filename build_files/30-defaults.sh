#!/usr/bin/env bash
# System defaults that keep the Silverblue experience intact.
# Static files (ntsync, units, scripts) come from system_files/.
set -euxo pipefail

# --- Automatic OS updates: download + stage in the background, apply on the
#     next reboot you do yourself (never reboots on its own).
if grep -qE '^#?AutomaticUpdatePolicy=' /etc/rpm-ostreed.conf; then
    sed -i -E 's/^#?AutomaticUpdatePolicy=.*/AutomaticUpdatePolicy=stage/' /etc/rpm-ostreed.conf
else
    printf '[Daemon]\nAutomaticUpdatePolicy=stage\n' >> /etc/rpm-ostreed.conf
fi
systemctl enable rpm-ostreed-automatic.timer

# --- Monthly Btrfs scrub (finds silent data corruption early)
systemctl enable btrfs-scrub-monthly.timer

# --- Homebrew (unpacked at first boot, see 28-homebrew.sh) and Zed
#     (official script, per user on first login)
chmod 0755 /usr/libexec/brew-setup /usr/libexec/zed-install
systemctl enable brew-setup.service
systemctl --global enable zed-install.service

# --- Flatpak: one-time switch from Fedora's remote to Flathub
#     (GNOME Software keeps Flatpaks updated on its own)
chmod 0755 /usr/libexec/flathub-migrate
systemctl enable flathub-migrate.service

# --- Signature policy so `bootc upgrade` verifies our cosign signatures
dnf5 -y install jq
REPO="${IMAGE_REGISTRY}/${IMAGE_NAME}"
KEY="/etc/pki/containers/${IMAGE_NAME}.pub"

install -Dm0644 "${CTX}/../cosign.pub" "${KEY}"

# Fedora ships the default in /usr/share; /etc overrides it if present.
POLICY=/etc/containers/policy.json
SRC="${POLICY}"
[ -f "${SRC}" ] || SRC=/usr/share/containers/policy.json
jq --arg repo "${REPO}" --arg key "${KEY}" \
   '.transports.docker[$repo] = [{
        "type": "sigstoreSigned",
        "keyPath": $key,
        "signedIdentity": {"type": "matchRepository"}
    }]' "${SRC}" > /tmp/policy.json
install -Dm0644 /tmp/policy.json "${POLICY}"

install -d /etc/containers/registries.d
cat > "/etc/containers/registries.d/${IMAGE_NAME}.yaml" <<EOF
docker:
  ${REPO}:
    use-sigstore-attachments: true
EOF

# --- Image metadata (handy for `cat /usr/share/image-info.json`)
cat > /usr/share/image-info.json <<EOF
{
  "image-name": "${IMAGE_NAME}",
  "image-ref": "ostree-image-signed:docker://${REPO}",
  "base-image": "quay.io/fedora-ostree-desktops/silverblue",
  "fedora-version": "$(rpm -E %fedora)"
}
EOF
