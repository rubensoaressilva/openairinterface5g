#!/usr/bin/env bash
# Build ran-base and oai-gnb-aerial via `docker buildx bake`, tagged with the
# current git branch. See ../docker-bake.hcl for how the dependency between
# the two targets and the tag sanitization are wired up.
#
# Usage (from anywhere in the repo):
#   ./docker/bake.sh [extra buildx bake args, e.g. --progress=plain]
#
# The gnb-aerial target uses a cross-target "contexts" entry to consume the
# base target's build output directly. That only works with the
# docker-container driver -- the default classic "docker" driver builds each
# target in isolation and can't share outputs between them, so it silently
# falls back to pulling ran-base:latest from a registry instead. This script
# creates (once) and reuses a dedicated docker-container builder for that
# reason; it does not touch your default builder.
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

BUILDER_NAME=oai-bake-builder

if ! docker buildx inspect "$BUILDER_NAME" >/dev/null 2>&1; then
  echo "==> Creating buildx builder '${BUILDER_NAME}' (driver=docker-container)"
  docker buildx create --name "$BUILDER_NAME" --driver docker-container
fi

# Falls back to the short commit SHA when HEAD is detached (no branch name),
# and appends '-dirty' when the working tree has uncommitted changes.
# docker-bake.hcl's sanitize_tag() still replaces '/' with '-' on this value.
BRANCH_RAW=$(git symbolic-ref --short -q HEAD || git rev-parse --short HEAD)
if [ -n "$(git status --porcelain)" ]; then
  BRANCH_RAW="${BRANCH_RAW}-dirty"
fi
export BRANCH="$BRANCH_RAW"

docker buildx bake -f docker-bake.hcl --builder "$BUILDER_NAME" "$@"
