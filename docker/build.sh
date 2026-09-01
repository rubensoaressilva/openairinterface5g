#!/usr/bin/env bash
# Build ran-base and oai-gnb-aerial, tagged with the current git branch.
#
# Usage (from anywhere in the repo):
#   ./docker/build.sh
#
# The tag is derived from the current branch name, with '/' replaced by '-'
# (e.g. feature/foo -> feature-foo). If HEAD is detached (no branch, e.g. a
# commit was checked out directly) it falls back to the short commit SHA. A
# '-dirty' suffix is appended when the working tree has uncommitted changes.
# No manual tag/version to remember or edit.
#
# Dockerfile.gNB.aerial.ubuntu's FROM line is hardcoded to `ran-base:latest`
# (not templated via ARG), so the ran-base build below is tagged with BOTH
# the branch tag (for you to identify/keep it by) and `latest` (so the second
# build's hardcoded FROM resolves it from the local image store).
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

BRANCH_RAW=$(git symbolic-ref --short -q HEAD || git rev-parse --short HEAD)
BRANCH_TAG=$(echo "$BRANCH_RAW" | tr '/' '-')
if [ -n "$(git status --porcelain)" ]; then
  BRANCH_TAG="${BRANCH_TAG}-dirty"
fi

echo "==> Building ran-base:${BRANCH_TAG} (also tagged ran-base:latest)"
docker build -f docker/Dockerfile.base.ubuntu . \
  -t ran-base:"${BRANCH_TAG}" -t ran-base:latest \
  --progress=plain

echo "==> Building oai-gnb-aerial:${BRANCH_TAG}"
docker build -f docker/Dockerfile.gNB.aerial.ubuntu -t oai-gnb-aerial:"${BRANCH_TAG}" \
  --progress=plain .

echo "==> Done. Images:"
echo "    ran-base:${BRANCH_TAG} (and ran-base:latest)"
echo "    oai-gnb-aerial:${BRANCH_TAG}"
