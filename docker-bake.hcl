# docker buildx bake file for ran-base + oai-gnb-aerial.
#
# Usage (from repo root):
#   ./docker/bake.sh
# or directly:
#   BRANCH=$(git rev-parse --abbrev-ref HEAD) docker buildx bake
#
# Slashes in BRANCH are sanitized to '-' by sanitize_tag() below, so you never
# need to pipe through `tr` yourself. The gnb-aerial target uses a named
# "context" to point its `FROM ran-base:latest` reference straight at the
# output of the base target, so buildx orders base -> gnb-aerial correctly
# and gnb-aerial always uses the base image just built in this invocation
# (no reliance on the local image store already having a matching tag).
#
# IMPORTANT: the contexts key below ("ran-base:latest") must match the exact,
# literal text of the FROM line in Dockerfile.gNB.aerial.ubuntu. That match is
# done on the raw Dockerfile text, so it will NOT work if that FROM line uses
# an ARG-substituted tag (e.g. `FROM ran-base:${BASE_TAG}`) -- the override
# silently falls through to a real registry pull in that case. Keep that FROM
# line hardcoded to `ran-base:latest`; use the `tags` below to control what
# the *built* images end up named as.

variable "BRANCH" {
  default = "latest"
}

function "sanitize_tag" {
  params = [name]
  result = replace(name, "/", "-")
}

target "base" {
  context    = "."
  dockerfile = "docker/Dockerfile.base.ubuntu"
  tags       = ["ran-base:${sanitize_tag(BRANCH)}"]
  # Load into the local docker engine (not just the BuildKit cache) so
  # `docker images` shows it, same as a plain `docker build` would.
  output     = ["type=docker"]
}

target "gnb-aerial" {
  context    = "."
  dockerfile = "docker/Dockerfile.gNB.aerial.ubuntu"
  contexts = {
    "ran-base:latest" = "target:base"
  }
  tags   = ["oai-gnb-aerial:${sanitize_tag(BRANCH)}"]
  output = ["type=docker"]
}

group "default" {
  targets = ["base", "gnb-aerial"]
}
