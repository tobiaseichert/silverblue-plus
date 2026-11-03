# silverblue-plus

Stock **Fedora Silverblue 45** (`quay.io/fedora-ostree-desktops/silverblue`) with
**RPM Fusion** as the main external source, media & gaming addons, and a few
sensible desktop defaults. Built, signed and published daily by GitHub Actions.
No Steam Gaming Mode, same GNOME as Silverblue.

## What's added

| Area | Content |
|---|---|
| Repos | RPM Fusion free, nonfree, nonfree-steam and 1Password's repo, at build time only (not left on the system) |
| Apps | 1Password desktop app + `op` CLI (works with the preinstalled Firefox RPM) |
| Codecs | full `ffmpeg`, GStreamer libav/bad-freeworld/ugly |
| HW video | `mesa-va-drivers-freeworld` (H.264/HEVC on AMD); skipped for a day if RPM Fusion's build doesn't match Fedora's Mesa yet (warning in the build log) |
| Gaming | `steam`, `steam-devices`, `gamescope`, `mangohud` (+ i686) |
| Shell & CLI | `zsh`, `vim`, `btop`, `duf`, `fastfetch`, `glow`, `gum`, `lsb_release`; archives: `lzip`, 7-Zip, `unrar` (RPM Fusion); `fuse-libs` for AppImages |
| Tools | `distrobox`, `libva-utils`, `vulkan-tools`, `ddcutil` (monitor control via DDC/CI), `nvtop` (GPU monitor), `compsize` (Btrfs on-disk size), Btrfs Assistant |
| Defaults | `ntsync` loaded, monthly Btrfs scrub, Fractal Adjust udev rule (WebHID), staged auto-updates (never auto-reboot), cosign signature policy, one-time switch to Flathub-only Flatpaks |

### Homebrew & Zed

Neither can live in the image (`/home` is per machine), so two one-time
services set them up on the installed system:

- `brew-setup.service` (boot, root): clones Homebrew to
  `/home/linuxbrew/.linuxbrew` and hands it to UID 1000, the first user.
  `/etc/profile.d/brew.sh` puts `brew` on the `PATH`. Use it for CLI
  toolchains (Go, Node, kubectl …) or `brew bundle` with your Mac `Brewfile`.
- `zed-install.service` (user, first login): runs Zed's official
  `install.sh` into `~/.local`. Zed updates itself.

Both retry every minute until the network is up. Logs:
`journalctl -u brew-setup` and `journalctl --user -u zed-install`.

### 1Password

Installed from 1Password's official repo during the build, so every image
carries the current release; the repo itself is not left on the system.
Browser integration needs a native browser, so Firefox stays the Fedora RPM.
Because `/opt` lives in `/var` on atomic systems, the app is moved to
`/usr/lib/1Password` and linked back to `/opt/1Password` at boot. The
`onepassword` (1500) and `onepassword-cli` (1600) groups have fixed GIDs via
`sysusers.d`.

### Flathub-only Flatpaks

A fresh Silverblue install puts some GNOME apps (Calculator, Calendar, Clocks,
LibreOffice, …) on the system as Flatpaks from Fedora's remote.
`flathub-migrate.service` runs once after the first boot with network:

1. adds and enables Flathub,
2. reinstalls every Fedora-remote app from Flathub (app data is kept),
3. removes the Fedora runtime and the `fedora` / `fedora-testing` remotes,
4. installs Bazaar (app store, alongside GNOME Software), Mission Center
   (system monitor with GPU stats), Pika Backup, Chromium, GNOME Boxes, Lutris and Warehouse from Flathub,
5. writes `/var/lib/silverblue-plus/flathub-migrate.done` and never runs again.

If it fails (e.g. offline) it retries every minute. If an app is not on
Flathub, the Fedora build and remote are kept. Check progress with
`journalctl -u flathub-migrate`. When GNOME's first-boot setup asks about
third-party repositories, choose **Enable** so Flathub stays switched on.

## Setup (one time)

1. **Create the repo** on GitHub and push these files (`main` branch).
2. **Signing key** – on any machine with cosign:
   ```bash
   COSIGN_PASSWORD="" cosign generate-key-pair   # press Enter, no password
   gh secret set SIGNING_SECRET < cosign.key      # or: Settings → Secrets → Actions
   git add cosign.pub && git commit -m "Add signing key" && git push
   ```
   Never commit `cosign.key` (it's in `.gitignore`). `cosign.pub` is required:
   the build fails without it.
3. **Actions** tab → enable workflows if prompted. After the first green run,
   set the package visibility to *public* (Profile → Packages → *image* →
   Package settings) so `rpm-ostree` can pull without credentials.

## Switching an existing Silverblue/Fedora Atomic install

```bash
# Drop layered packages and RPM Fusion release RPMs — the image ships them now
rpm-ostree reset

# 1st rebase: unverified (the signature policy isn't on the system yet)
rpm-ostree rebase ostree-unverified-registry:ghcr.io/<user>/<repo>:latest
systemctl reboot

# 2nd rebase: switch to the signed transport (policy now ships in the image)
rpm-ostree rebase ostree-image-signed:docker://ghcr.io/<user>/<repo>:latest
systemctl reboot
```
Pin to a release with `:45`, or to a specific day with `:45-YYYYMMDD`. Roll back with
`rpm-ostree rollback`.

## Customizing

- **Packages:** edit `build_files/10-media.sh` / `20-gaming.sh`, or drop a new
  `NN-something.sh` into `build_files/` – all scripts run in numeric order.
- **Static files:** anything under `system_files/` is copied 1:1 to `/`.
- **Fedora version bump:** change `FEDORA_VERSION` in `.github/workflows/build.yml`.

## Local test build

```bash
podman build -t silverblue-plus:test .
```

## Next steps worth considering

- **Rechunking** (`rpm-ostree compose build-chunked-oci`) for much smaller update
  downloads.
- **ISO** via `bootc-image-builder` for fresh installs.
- **Flatpaks** (Heroic for GOG/Epic, ProtonPlus, Flatseal) stay Flatpaks
  rather than going into the image.
