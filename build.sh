#!/bin/bash
# Convenience wrapper around `docker build`.
#
# Usage:
#   ./build.sh <version> [git-ref]
#
# Example:
#   ./build.sh 3.4.0          # builds from master
#   ./build.sh 3.4.0 V3-4-0   # builds from a specific tag/branch
#
# Result lands in ./dist/splat-vo-<version>.jar
set -euo pipefail

VERSION="${1:?Usage: build.sh <version> [git-ref] [cache-bust]}"
SRC_REF="${2:-master}"
CACHE_BUST="${3:-1}"

DOCKER_BUILDKIT=1 docker build \
    --platform linux/amd64 \
    --target export \
    --build-arg VERSION="$VERSION" \
    --build-arg SRC_REF="$SRC_REF" \
    --build-arg CACHE_BUST="$CACHE_BUST" \
    --build-arg MODE=github \
    --build-context source=. \
    --output type=local,dest=./dist \
    .

echo "Done: ./dist/splat-vo-${VERSION}.jar"
