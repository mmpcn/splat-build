#!/bin/bash
# Runs inside the build container. Reproduces "Part 2" of the manual recipe:
# assemble a release directory, prune it, drop in extra files, and run
# the IzPack compiler to produce the installer jar.
set -euo pipefail

VERSION="${1:?Usage: container-build.sh <version>}"
DEV_INSTALL="${DEV_INSTALL:-/build/install}"
RELEASE_DIR="/build/release"
OUTPUT_DIR="/output"

mkdir -p "$RELEASE_DIR" "$OUTPUT_DIR"


# 1. Copy the install dir directly into the release dir.
#    targetdeps splat install already installed only SPLAT's dependencies,
#    so DEV_INSTALL is already clean -- no selective copy needed.
cp -ax "$DEV_INSTALL"/. "$RELEASE_DIR"/
 
echo "Release dir size after copy: $(du -sh "$RELEASE_DIR" | cut -f1)"



# Keep current architectures' native libs only.
#for arch in amd64 aarch64 x86_64; do
#  src="$DEV_INSTALL/lib/$arch"
#  [ -d "$src" ] && cp -a "$src" "$RELEASE_DIR/lib/"
#done


# 2. Still run removed_files.lis on top -- it strips a few specific
#    files (ant jars accidentally pulled in via deps above, javadocs,
#    etc.) that selective copying alone doesn't catch.
if [ -s /build/removed_files.lis ]; then
  (cd "$RELEASE_DIR" && bash /build/removed_files.lis 2>/dev/null || true)
fi

echo "Release dir size after removed_files.lis: $(du -sh "$RELEASE_DIR" | cut -f1)"

# 3. Copy in install.xml and splat.news (both not part of the build
#    output -- supplied via resources/).
cp /build/install.xml "$RELEASE_DIR/install.xml"
cp /build/splat.news "$RELEASE_DIR/etc/splat.news"
sed -i -E "s#(<appversion>)[^<]*(</appversion>)#\1${VERSION}\2#" \
    "$RELEASE_DIR/install.xml"

# 4. Make sure scripts are executable.
find "$RELEASE_DIR" -type d -name bin -exec chmod -R a+rx {} \;
find "$RELEASE_DIR" \( -name "*.sh" -o -name "*.csh" \) \
    -exec chmod a+rx {} \;

# 5. Drop in the extra files (shortcuts, icon, bin/lib/etc skeleton).
cp -r /build/extra-files/. "$RELEASE_DIR"/

# 6. Run the IzPack compiler using Coursier-downloaded jars.
cd "$RELEASE_DIR"

izpack-compile install.xml -b . -o "/build/splat-vo-${VERSION}.jar" -k standard


# 7. Hand the result to the output dir, named with the version.
mv "/build/splat-vo-${VERSION}.jar" "$OUTPUT_DIR/"
echo "Built $OUTPUT_DIR/splat-vo-${VERSION}.jar"

