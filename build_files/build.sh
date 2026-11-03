#!/usr/bin/env bash
# Entry point called from the Containerfile. Runs the numbered steps in order.
set -euxo pipefail

CTX="$(dirname "$(readlink -f "$0")")"
export CTX

for step in "${CTX}"/[0-9][0-9]-*.sh; do
    echo "::group:: ===== $(basename "${step}") ====="
    bash "${step}"
    echo "::endgroup::"
done
