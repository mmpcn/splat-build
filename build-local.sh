#!/bin/bash
# Build SPLAT from a local source directory instead of cloning from GitHub.
# Use this for development -- edit the source on your Mac normally, then
# run this script to build and package.
#
# Usage:
#   ./build-local.sh <version> <path-to-starjava>
#
# Example:
#   ./build-local.sh 4.0.1 ~/Development/starjava
#
# Result: ./dist/splat-vo-<version>.jar
set -euo pipefail

VERSION="${1:?Usage: build-local.sh <version> <path-to-starjava>}"
SOURCE_DIR="${2:?Usage: build-local.sh <version> <path-to-starjava>}"

# Resolve to absolute path
SOURCE_DIR="$(cd "$SOURCE_DIR" && pwd)"

DOCKER_BUILDKIT=1 docker build \
    --platform linux/amd64 \
    --target export \
    --build-arg VERSION="$VERSION" \
    --build-arg MODE=local \
    --build-context source="$SOURCE_DIR" \
    --output type=local,dest=./dist \
    .

echo "Done: ./dist/splat-vo-${VERSION}.jar"
