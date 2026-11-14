# inkOS-Patcher

Builds releases of [inkOS](https://github.com/gezimos/inkOS) (Kotlin/Compose e-ink launcher, GPL-3.0) with extra patches applied, the same way `../curbox-patcher` does for Curbox.

## Layout

- `patches/*.patch`: one `git format-patch` file per feature, applied in name order with `git am -3` on an upstream release tag. Never edit by hand; regenerate with `scripts/refresh-patch.sh`.
- `scripts/refresh-patch.sh`: rebases a patch branch onto a new inkOS tag, builds, re-exports the patch.
- `.github/workflows/build.yml`: daily CI build of the newest inkOS release, signed with PERSONAL, published here and to the `fabiantorrestech/android-apps` hub (tag `inkos`, asset `inkOS.apk`).

## Rules

- Upstream tags look like `v0.6`. Build from tags only, never `main`. Oldest supported: `v0.6`.
- Each patch is exactly **one commit** on branch `patch/<name>` in the local clone `../inkOS` (no fork on GitHub; the `.patch` file is the durable copy).
- Keep upstream edits minimal: put logic in new files (e.g. `ui/DrawerReveal.kt`, `res/values/strings_drawer_reveal.xml`) and only add small hooks to upstream files, so new releases rarely conflict.
- Build: `./gradlew assembleDebug` (local check) / `assembleRelease` (CI). No product flavors. Upstream CI uses JDK 17; local machine has JDK 21.
- Debug builds are `app.inkos.debug` ("inkOS Debug") and install next to vanilla; release builds keep `app.inkos` and replace it (different signer, so vanilla must be uninstalled first).
- Signing and patched-build policy are decided in `../android-apps/doc/adr` (ADR 2, 5, 8). Release signing in CI uses inkOS's own Gradle env vars: `KEYSTORE_FILE`, `KEYSTORE_PASSWORD`, `KEY_ALIAS`, `KEY_PASSWORD`.
- `.patch` files are byte-exact (`.gitattributes`: `*.patch -text`).

## Patches

| Patch | What |
| --- | --- |
| `hide-until-search` | Settings > App Drawer > Search > "Show Apps": Always / While typing / After Search key (default). The normal drawer lists nothing until the chosen moment. |
