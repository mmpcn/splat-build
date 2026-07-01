# SPLAT build & installer

Automated build pipeline for the [SPLAT-VO](http://www.g-vo.org/pmwiki/About/SPLAT)
spectral analysis tool. Clones [Starlink/starjava](https://github.com/Starlink/starjava)
from GitHub, builds it, and packages it into an IzPack installer jar.

Finished releases are published automatically under
[Releases](https://github.com/mmpcn/splat-build/releases).

## Running a release build on GitHub (normal workflow)

1. Go to **Actions → "Build SPLAT installer" → Run workflow**
2. Fill in:
   - **Version**: e.g. `4.0.1`
   - **Branch/tag**: e.g. `splat4.0.1-test`
   - **Changes**: one line per change — prepended to `splat.news` on full releases
   - **Pre-release**: yes for test builds, no for real releases
3. Click **Run** — takes ~15 min
4. The jar appears under **Releases** when done

## Local build (for development)

Clone the starjava source locally, edit normally, then build:

```bash
git clone https://github.com/Starlink/starjava.git ~/starjava
# edit files in ~/starjava with your normal editor
./build-local.sh 4.0.1 ~/starjava
```

Or build directly from a GitHub branch:

```bash
./build.sh 4.0.1 splat4.0.1-test        # from that branch
./build.sh 4.0.1 splat4.0.1-test 2      # bump last number to force fresh clone
```

Result: `./dist/splat-vo-<version>.jar`

*Windows users:** requires Docker Desktop with WSL2 backend.

Test it:
```bash
java -jar dist/splat-vo-4.0.1.jar
```

## Platform note

The build is pinned to `--platform linux/amd64`. This is required: `jniast`
only ships a real Linux `.so` for `amd64` — the `aarch64` slot contains only
a macOS `.jnilib`. On Apple Silicon, Docker Desktop emulates via QEMU, which
is slower but produces a correct Linux installer.

## What's in resources/

- `install.xml` — IzPack config (not in the public starjava repo)
- `removed_files.lis` — shell script that prunes the release dir before packaging
- `splat.news` — running changelog, auto-updated on full releases
- `extra-files/` — shortcut specs, icons, and other packaging assets
- `jai/` — JAI 1.1.3 jars (`jai_core.jar`, `jai_codec.jar`), committed directly
  since they're not available on Maven Central

