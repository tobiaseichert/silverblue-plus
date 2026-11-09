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

# --- Zed (official script, per user on first login)
chmod 0755 /usr/libexec/zed-install
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
# rpm-ostree/bootc refuse signed pulls (ostree-image-signed) while the
# *default* rule is insecureAcceptAnything, even with a rule for our repo.
# So: default = reject, plus a transport-wide "" rule that keeps accepting
# everything else (podman, toolbox, distrobox behave as before). More
# specific scopes (our repo, Red Hat's registries) still require signatures.
jq --arg repo "${REPO}" --arg key "${KEY}" \
   '.default = [{"type": "reject"}]
    | .transports.docker[$repo] = [{
        "type": "sigstoreSigned",
        "keyPath": $key,
        "signedIdentity": {"type": "matchRepository"}
    }]
    | reduce ("docker", "docker-archive", "docker-daemon", "containers-storage",
              "oci", "oci-archive", "dir") as $t
        (.; .transports[$t][""] //= [{"type": "insecureAcceptAnything"}])' \
   "${SRC}" > /tmp/policy.json
jq -e '.default[0].type == "reject"' /tmp/policy.json >/dev/null
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
