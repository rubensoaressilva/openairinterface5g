#!/usr/bin/env bash
# Run the SA gNB Aerial docker compose stack (nv-cubb + oai-gnb-aerial),
# pointing oai-gnb-aerial at the image built locally by docker/build.sh or
# docker/bake.sh for the current branch, instead of docker-compose.yaml's
# default (oaisoftwarealliance/oai-gnb-aerial:develop from Docker Hub).
#
# Usage (from anywhere):
#   ./run_aerial.sh [extra docker compose up args, e.g. -d]
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

# Same tag derivation as docker/build.sh and docker/bake.sh: current branch
# name (falling back to the short commit SHA on detached HEAD), '/' sanitized
# to '-', with a '-dirty' suffix appended when the working tree has
# uncommitted changes.
BRANCH_RAW=$(git symbolic-ref --short -q HEAD || git rev-parse --short HEAD)
TAG=$(echo "$BRANCH_RAW" | tr '/' '-')
if [ -n "$(git status --porcelain)" ]; then
  TAG="${TAG}-dirty"
fi

# Empty REGISTRY (docker-compose.yaml only falls back to
# oaisoftwarealliance/ when REGISTRY is completely unset) and the default
# GNB_IMG, so the compose file resolves to the locally built
# oai-gnb-aerial:<TAG> image rather than pulling from Docker Hub.
export REGISTRY=""
export GNB_IMG="oai-gnb-aerial"
export TAG

echo "==> Using oai-gnb-aerial image: ${GNB_IMG}:${TAG}"
docker compose -f docker-compose.yaml up "$@"
