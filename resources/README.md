# resources/ — assets you need to supply

Everything else in this project is fetched automatically (the source
clones straight from GitHub). These things can't be, either because
they're proprietary/no-longer-freely-distributed, or because they're
internal to your release process:

## resources/jai/
Java Advanced Imaging jars (e.g. `jai_core.jar`, `jai_codec.jar`,
`mlibwrapper_jai.jar`, plus any native `.so` libs you currently have
installed under your JDK 8's `jre/lib/ext`). Copy whatever you have on
your Mac at that location into this folder. The Dockerfile copies the
whole folder into the container JDK's `jre/lib/ext`.

## resources/izpack/
Your IzPack installation — the directory that contains `bin/compile`
(currently `/Application/IzPack` on your Mac). Copy the whole IzPack
distribution directory here. Note its version somewhere (e.g. in a
comment in this README) so we know which IzPack schema `install.xml`
needs to target.

## resources/splat.news
The running changelog file that gets copied into the installer. Copy
your current `splat/src/docs/splat.news` here. The workflow
automatically prepends a new entry (version header + change notes) each
time you run a release build — you never need to edit this file by hand.

## resources/extra-files/
The files mentioned in your packaging recipe — flat, directly in this
folder (not nested), since `install.xml` resolves them relative to the
release dir root: `shortcutSpec.xml`, `Unix_shortcutSpec.xml`,
`StarlinkGavo.png` (confirmed required, see note below), and
`Starlink.gif`. Any supplementary `bin/`, `lib/`, `etc/` content you
want merged on top of what `ant install` already produced also goes
here — it gets overlaid onto the release dir, not used as a full
replacement.

## resources/install.xml
✅ Included — your real file. Confirmed it's standard IzPack schema
(`<appversion>4.0-beta</appversion>` etc.) and not part of the public
`Starlink/starjava` repo, so it has to live here.

One thing worth double-checking: `install.xml` references
`StarlinkGavo.png` as the installer banner image (not `Starlink.gif`
as your earlier note suggested). Both files are probably still
needed — `Starlink.gif` is likely referenced *inside*
`shortcutSpec.xml`/`Unix_shortcutSpec.xml` as a shortcut icon, but I
haven't seen those files yet to confirm. Make sure `StarlinkGavo.png`,
`shortcutSpec.xml`, and `Unix_shortcutSpec.xml` all end up directly in
`resources/extra-files/` (flat, not nested) since `install.xml`
resolves them relative to the release dir root.

## resources/removed_files.lis
✅ Included — your real file. Confirmed this is an actual shell script
(rm / rm -r -f commands with glob patterns), not a plain path list —
`docker/container-build.sh` now runs it directly rather than parsing
it line by line.

One line worth a second look on your end: `rm -f lib/*.jar` is
commented "libraries that have been copied twice ???" in the original
— sounds like even the original author wasn't fully sure. I'm
reproducing it exactly as written, but flagging it in case it's worth
tightening up at the source.

---

None of this folder's contents should be committed to a public repo if
JAI or IzPack redistribution terms don't allow it — keep `resources/`
out of version control (or in a private repo) and treat it as local
build input, the same way you'd treat a `.env` file with secrets.
