# SPLAT build & installer container

Automates the manual SPLAT build/package recipe:

1. Clone `Starlink/starjava` from GitHub
2. Build with the bundled Ant (`ant clean`, `ant build install`)
3. Install SPLAT's dependencies (`scripts/targetdeps splat install`)
4. Assemble a release dir, prune it per `removed_files.lis`, drop in the
   extra packaging files
5. Bump the version number
6. Run the IzPack compiler to produce `splat-vo-<version>.jar`

What's **not** automated, on purpose (these stay as your manual
checklist after the jar is built):

- Actually launching/testing the installer
- Copying the jar to `alnilam:/var/www/soft/splat-beta`
- Editing the g-vo.org PmWiki page and checking links

## Setup (one-time)

Populate `resources/` — see `resources/README.md` for exactly what
goes where (JAI jars, IzPack distribution, extra-files, removed_files.lis).

## Setting up the GitHub repository (one-time)

1. Create a new GitHub repo (e.g. `splat-vo/splat-build`)
2. Push this directory to it
3. Commit `resources/install.xml` and `resources/extra-files/` openly —
   they're not proprietary
4. Add the proprietary assets as **GitHub Actions secrets** (repo Settings
   → Secrets and variables → Actions → New repository secret):

**`JAI_JARS_B64`** — base64-encoded tarball of your JAI jars:
```bash
cd resources/jai
tar -czf /tmp/jai.tar.gz *.jar
base64 -i /tmp/jai.tar.gz | pbcopy   # copies to clipboard
```
Paste the clipboard contents as the secret value.

**`IZPACK_B64`** — base64-encoded tarball of your IzPack installation:
```bash
cd resources/izpack
tar -czf /tmp/izpack.tar.gz .
base64 -i /tmp/izpack.tar.gz | pbcopy
```
Paste as the secret value.

## Running a release build on GitHub

1. Go to your repo → Actions → "Build SPLAT installer" → Run workflow
2. Fill in:
   - **Version**: e.g. `4.0.1`
   - **Branch/tag**: e.g. `splat4.0.1-test`
   - **Changes**: type the change notes, one per line — they get formatted as bullet points and prepended to `splat.news` automatically
   - **Pre-release**: yes/no
3. Click Run — takes ~10-15 min on GitHub's servers
4. When done, the jar appears under Releases with a permanent download URL

## Build workflows (local)

### Release build (from GitHub)
Clones a specific branch or tag from `Starlink/starjava` and packages it:

```bash
chmod +x build.sh build-local.sh docker/container-build.sh
./build.sh 4.0.1 splat4.0.1-test     # builds from that branch
./build.sh 4.0.1 splat4.0.1-test 2   # bump last number to force fresh clone
```

### Development build (from local source)
Clone the repo to your Mac, edit normally, then build without pushing to GitHub:

```bash
git clone https://github.com/Starlink/starjava.git ~/starjava
# ... edit files in ~/starjava with your normal editor ...
./build-local.sh 4.0.1 ~/starjava
```

Result in both cases: `./dist/splat-vo-<version>.jar`

### After building
1. Test: `java -jar dist/splat-vo-<version>.jar` → install → run `bin/splat`
2. Deploy: `scp dist/splat-vo-<version>.jar alnilam:/var/www/soft/splat-beta/`
3. Update: http://www.g-vo.org/pmwiki/About/SPLAT — change link and version text
4. Check links are correct

## Platform note (important)

The build is pinned to `--platform linux/amd64` in both the Dockerfile
and `build.sh`. This is **required**, not optional: `jniast` (the JNI
wrapper SPLAT uses for WCS/coordinate handling) only ships a real Linux
`.so` for the `amd64` architecture. The `aarch64` slot in that repo
only contains a macOS `.jnilib` (added specifically for Apple Silicon
Macs, confirmed in `jniast/README`) — there is no Linux ARM64 build at
all. If you're on an Apple Silicon Mac, Docker would otherwise default
to `linux/arm64` and fail with `libjniast.so not found`. Pinning to
`amd64` means Docker Desktop emulates via QEMU on ARM Macs — slower,
but correct.

Same root cause applies to **`resources/jai/`**: don't copy any native
`.dylib`/`.jnilib` files from your Mac in there, only the plain jars
(`jai_core.jar`, `jai_codec.jar`, etc.). JAI runs fine in pure-Java mode
without its native acceleration component; mixing in macOS native libs
would silently fail to load in the Linux container the same way
`jniast` did.

## Confirmed by inspecting the actual repo and your real files

1. **`ant build install`** — confirmed correct. `build` and `install` are
   independent top-level targets, but per-package `install` → `dist` →
   `jars` → `build`, and later packages need earlier ones *installed*
   (not just compiled) to find them on the classpath. This matches the
   officially documented sequence.
2. **Version property** — confirmed at `splat/build.xml` line 94:
   `<property name="version" value="3.15"/>`. The Dockerfile now bumps
   this *before* the build runs (it feeds `splat.version`, which gets
   baked into the build output).
3. **The bundled `ant/bin/ant` launcher works out of the box** on a
   fresh GitHub checkout (tested it) — no separate "build ant from
   source" step needed in the normal case.
4. **`install.xml`** — your real file is now in `resources/`. Standard
   IzPack schema confirmed, version-bump sed tested against it directly.
5. **`removed_files.lis`** — your real file is now in `resources/`.
   Turned out to be an actual shell script (not a path list) —
   `container-build.sh` now runs it directly instead of parsing it.

## Still open

1. **`StarlinkGavo.png` / `shortcutSpec.xml` / `Unix_shortcutSpec.xml` /
   `Starlink.gif`** — none of these are in `resources/extra-files/`
   yet. `install.xml` confirms the first three are required by name;
   see `resources/README.md` for the `Starlink.gif` caveat.
2. **GUI smoke test** — still just checks the launcher script exists,
   since the container is headless. Say the word if you want a real
   headless launch test added (via `xvfb`).
