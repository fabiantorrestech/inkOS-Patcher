# inkOS-Patcher

Builds releases of [inkOS](https://github.com/gezimos/inkOS) (Kotlin/Compose e-ink launcher, GPL-3.0) with extra patches applied, the same way `../curbox-patcher` does for Curbox.

## Layout

- `patches/*.patch`: one `git format-patch` file per feature, applied in name order with `git am -3` on an upstream release tag. Never edit by hand; regenerate with `scripts/refresh-patch.sh`.
- `scripts/refresh-patch.sh`: rebases a patch branch onto a new inkOS tag, builds, re-exports the patch.
- `.github/workflows/build.yml`: `test` input (e.g. `test1`) publishes pre-release `<version>-patched-<name>` with release + debug APKs and skips the hub. Otherwise: daily CI build of the newest inkOS release, signed with PERSONAL, published here and to the `fabiantorrestech/android-apps` hub (tag `inkos`, asset `inkOS.apk`).

## Rules

- Upstream tags look like `v0.6`. Build from tags only, never `main`. Oldest supported: `v0.6`.
- Each patch is exactly **one commit** on branch `patch/<name>` in the local clone `../inkOS` (no fork on GitHub; the `.patch` file is the durable copy).
- Keep upstream edits minimal: put logic in new files (e.g. `ui/DrawerReveal.kt`, `res/values/strings_drawer_reveal.xml`) and only add small hooks to upstream files, so new releases rarely conflict.
- Settings a patch adds end their title with ` ✦` and sit indented under the stock setting they belong to: start padding only, 16dp (scaled) per level, so the value column stays aligned. Sub-rows drop the master's name ("Side ✦" under "Enable Page Indicator"); dialogs keep the full name.
- Build: `./gradlew assembleDebug` (local check) / `assembleRelease` (CI). No product flavors. Upstream CI uses JDK 17; local machine has JDK 21.
- Debug builds are `app.inkos.debug` ("inkOS Debug") and install next to vanilla; release builds keep `app.inkos` and replace it (different signer, so vanilla must be uninstalled first).
- Signing and patched-build policy are decided in `../android-apps/doc/adr` (ADR 2, 5, 8). Release signing in CI uses inkOS's own Gradle env vars: `KEYSTORE_FILE`, `KEYSTORE_PASSWORD`, `KEY_ALIAS`, `KEY_PASSWORD`.
- A patch that adds a setting must also add its key (and type) to `PATCHER_KEYS` in `data/PatcherBackup.kt` (settings-backup patch), plus `THEME_KEYS` if it is look/layout. If its value would break vanilla, add a vanilla-safe fallback there.
- `.patch` files are byte-exact (`.gitattributes`: `*.patch -text`).

## Patches

| Patch | What |
| --- | --- |
| `app-drawer-toggle` | Settings > App Drawer > "Enable App Drawer" (default On). Off: the App Drawer action, Menu key, Backspace on Home, the App Drawer home shortcut and the OPEN_APP_DRAWER intent do nothing. Search action and type-to-search still work. |
| `hide-until-search` | Settings > App Drawer > Search > "Show Apps ✦" (under Show Search Bar): Always / While typing / After Search key (default). The normal drawer lists nothing until the chosen moment. |
| `page-layout` | Edit Favorites > tap the "x/y apps" title > "Arrange pages": home slots with draggable page dividers (arrows too), collision with neighbours and list ends, two together = empty page, add/remove dividers, Even split. Saves `HOME_PAGE_SIZES` (e.g. `3,0,5`) + page count; ignored (stock even split) once home apps or pages count changes. |
| `settings-backup` | Full backups and theme exports put patcher settings in a nested `"inkos_patcher"` section (`format`, `prefs`, `overrides`) that vanilla's importer skips. `HOME_PAGES_NUM` at the top level becomes the vanilla-safe count of non-empty pages (real value in `overrides`). Patched import restores the section after vanilla's import; old top-level-key backups still work. |
| `page-indicator-options` | Settings > Home, under "Enable Page Indicator": Side (Auto / Left / Right, in the side margin), Auto-hide (Off / 1 / 2 / 5 / 10 s, fades out 600 ms / in 250 ms), Fades To (Nothing / 10-90%), Fade (Smooth / Instant, for e-ink), Opacity (10-100%), Style (Classic / Pill, the android_shortcut_hub dot look). Side counter only; the bottom Page Dots widget is untouched. |
