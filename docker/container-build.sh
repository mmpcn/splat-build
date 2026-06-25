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

# 1. Start the release dir from the installed (ant build install /
#    targetdeps install) output -- this is what DEV_INSTALL points at.
cp -ax "$DEV_INSTALL"/. "$RELEASE_DIR"/

# 2. Run the prune script supplied in resources/removed_files.lis.
#    Confirmed by inspecting the real file: it's an actual csh-flavored
#    shell script (rm / rm -r -f commands, glob patterns, comments),
#    not a plain path list. Run it directly from inside the release
#    dir, same as the original recipe does. The csh shebang line and
#    `unalias rm` are harmless no-ops under bash (the shebang is just
#    a comment to bash; unalias on a non-existent alias fails quietly
#    since we don't use `set -e` for this call).
if [ -s /build/removed_files.lis ]; then
  (cd "$RELEASE_DIR" && bash /build/removed_files.lis)
fi

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

# 6. Run the IzPack compiler.
cd "$RELEASE_DIR"
compile install.xml -b . -o "/build/splat-vo-${VERSION}.jar" -k standard

# 7. Hand the result to the output dir, named with the version.
mv "/build/splat-vo-${VERSION}.jar" "$OUTPUT_DIR/"
echo "Built $OUTPUT_DIR/splat-vo-${VERSION}.jar"

