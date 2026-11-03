# Custom Fedora Silverblue image: stock Silverblue + RPM Fusion media/gaming
# addons + a handful of sensible desktop defaults.

ARG FEDORA_VERSION=45

# Build context stage: scripts and the public signing key are mounted into
# the build, but never end up as layers in the final image.
FROM scratch AS ctx
COPY build_files /build_files
COPY cosign.pub /cosign.pub

FROM quay.io/fedora-ostree-desktops/silverblue:${FEDORA_VERSION}

# Set by the CI workflow. Used for the signature policy and image metadata.
ARG IMAGE_REGISTRY="ghcr.io/changeme"
ARG IMAGE_NAME="silverblue-plus"

# Static config files (modules-load, systemd units, helper scripts)
COPY system_files /

RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    IMAGE_REGISTRY="${IMAGE_REGISTRY}" \
    IMAGE_NAME="${IMAGE_NAME}" \
    /ctx/build_files/build.sh

# Fails the build if the result is not a valid bootc image
RUN bootc container lint
