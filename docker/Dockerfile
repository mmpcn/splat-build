# syntax=docker/dockerfile:1
#
# Builds SPLAT (from Starlink/starjava) and packages it into an IzPack
# installer jar, reproducing the manual recipe end to end.
#
# Build:
#   DOCKER_BUILDKIT=1 docker build --target export \
#     --build-arg VERSION=3.4.0 \
#     --build-arg SRC_REF=master \
#     --output type=local,dest=./dist .
#
# Result: ./dist/splat-vo-<VERSION>.jar

FROM eclipse-temurin:8-jdk-jammy AS build

# --- OS packages needed for the build + packaging ---
# csh: some Starlink scripts (incl. the original doit.csh) are csh-based
# git: clone the source
RUN apt-get update && apt-get install -y --no-install-recommends \
        git \
        csh \
        unzip \
        wget \
        ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# --- environment, mirroring the original macOS setup script ---
ENV STAR_JAVA=$JAVA_HOME/bin/java \
    DEV_HOME=/build \
    SOURCE_DIR=/build/starjava \
    DEV_INSTALL=/build/install \
    JAVA_TOOL_OPTIONS=-Dfile.encoding=UTF8
ENV ANT_PATH=$SOURCE_DIR/ant/bin
ENV PATH=$ANT_PATH:$DEV_INSTALL/bin:$PATH

# --- JAI 1.1.3 from Maven Central ---
# Confirmed version 1.1.3 from the actual jars. Downloaded directly so
# no local copy or secret is needed.
RUN wget -q https://repo1.maven.org/maven2/com/sun/media/jai-core/1.1.3/jai-core-1.1.3.jar \
        -O "$JAVA_HOME/jre/lib/ext/jai_core.jar" && \
    wget -q https://repo1.maven.org/maven2/com/sun/media/jai-codec/1.1.3/jai-codec-1.1.3.jar \
        -O "$JAVA_HOME/jre/lib/ext/jai_codec.jar"

# --- IzPack 5.2.0 compiler from Maven Central ---
# The standalone compiler jar is all we need -- no installation required.
# It replaces the `compile` command from the original doit.sh.
RUN wget -q https://repo1.maven.org/maven2/org/codehaus/izpack/izpack-compiler/5.2.0/izpack-compiler-5.2.0-standalone.jar \
        -O /opt/izpack-compiler.jar

WORKDIR /build
RUN mkdir -p "$DEV_INSTALL"

# Tell the Starlink build system where source + install dirs live
# (this is what your setup script wrote to ~/.stardev.properties)
RUN printf 'star.dir=%s\nstardev=%s\n' "$DEV_INSTALL" "$SOURCE_DIR" \
        > /root/.stardev.properties

ARG SRC_REF=master
ARG VERSION=0.0.0-dev
ARG MODE=github

# MODE=github (default): clone from GitHub — used by build.sh
# MODE=local:  use local source dir  — used by build-local.sh
#              requires --build-context source=<path-to-starjava>

# Bump CACHE_BUST to force a fresh clone without discarding the slow
# apt/JAI/IzPack layers cached above. Only relevant in MODE=github.
ARG CACHE_BUST=1

RUN if [ "$MODE" = "github" ]; then \
        git clone --branch "$SRC_REF" --depth 1 \
            https://github.com/Starlink/starjava.git "$SOURCE_DIR"; \
    fi

# MODE=local: copy the local source tree in.
# The COPY is always parsed by Docker even in github mode, so we need
# a fallback build-context. build.sh passes --build-context source=.
# (the splat-docker dir itself, which is harmless) so this never fails.
COPY --from=source . /tmp/local-source/
RUN if [ "$MODE" = "local" ]; then \
        cp -r /tmp/local-source/. "$SOURCE_DIR"/; \
    fi \
    && rm -rf /tmp/local-source

# Patch the aarch64 jniast_libs.jar to contain a Linux .so instead of
# the macOS-only .jnilib that ships there by default.
# Background: Docker Desktop on Apple Silicon sometimes runs containers
# as linux/aarch64 even when --platform linux/amd64 is requested.
# The amd64 jar already has a real Linux libjniast.so; we copy it into
# the aarch64 jar so that ant's unpack_jni target puts the right file
# in place regardless of which os.arch the JVM reports at build time.
RUN JNILIB_DIR="$SOURCE_DIR/jniast/src/lib" && \
    mkdir -p /tmp/jniast_patch && \
    cd /tmp/jniast_patch && \
    unzip -p "$JNILIB_DIR/amd64/jniast_libs.jar" libjniast.so > libjniast.so && \
    unzip "$JNILIB_DIR/aarch64/jniast_libs.jar" -d unpacked/ && \
    cp libjniast.so unpacked/ && \
    cd unpacked && zip -r "$JNILIB_DIR/aarch64/jniast_libs.jar" . && \
    cd /tmp && rm -rf jniast_patch

# Bump the version *before* building -- confirmed via the actual repo:
# splat/build.xml line 94 has <property name="version" value="..."/>
# and that property feeds splat.version, which gets baked into the
# build output, not just used for packaging afterward.
RUN sed -i -E \
        's#(<property name="version" value=")[^"]*(")#\1'"${VERSION}"'\2#' \
        "$SOURCE_DIR/splat/build.xml"

# --- build all sources, then install SPLAT + its dependencies ---
WORKDIR $SOURCE_DIR
# Confirmed against the real build.xml: "build" and "install" are
# independent top-level targets (install doesn't depend on build), but
# per-package "install" -> "dist" -> "jars" -> "build", and later
# packages need earlier ones already *installed* (not just built) to
# find their jars on the classpath. `build install` together is the
# officially documented sequence -- this is no longer a guess.
RUN "$ANT_PATH/ant" clean
RUN "$ANT_PATH/ant" build install
RUN ./scripts/targetdeps splat install

# Smoke test: confirm the launcher script exists & is runnable.
# NOTE: this does NOT launch the GUI (no X server in the container).
# If you want a real headless launch test, add xvfb + xvfb-run here.
RUN test -x "$DEV_INSTALL/bin/splat/splat" \
        || (echo "splat launcher missing after install" && exit 1)

# --- packaging assets brought in from the host ---
COPY resources/removed_files.lis /build/removed_files.lis
COPY resources/extra-files/ /build/extra-files/
COPY resources/splat.news /build/splat.news
# install.xml is NOT in the public starjava repo -- confirmed by checking.
# It's your own IzPack config; supply it in resources/.
COPY resources/install.xml /build/install.xml
COPY docker/container-build.sh /build/container-build.sh

RUN chmod +x /build/container-build.sh \
    && /build/container-build.sh "$VERSION"

# --- export stage: just the finished installer jar, nothing else ---
FROM scratch AS export
COPY --from=build /output/ /
