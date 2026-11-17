# inkOS-Patcher

Builds [inkOS](https://github.com/gezimos/inkOS) releases with two extra patches:

- **Hide until search: the app drawer stays empty until you search.** A new setting, Settings → App Drawer → Search → **Show Apps**, picks when the drawer lists apps:

  | Mode | The drawer shows apps… |
  | --- | --- |
  | Always | right away (stock inkOS) |
  | While typing | once the search box has text, filtering as you type |
  | **After Search key** (default) | only after you type and press Search on the keyboard |

- **Page indicator options: more control over the home page dots.** Five new rows in Settings → Home, under **Enable Page Indicator**:

  | Setting | Choices |
  | --- | --- |
  | Page Indicator Side | **Auto** (stock: opposite the apps), Left, Right. Left and Right sit in the side margin, so they never cover an app name. |
  | Page Indicator Auto-hide | **Off**, 1s, 2s, 5s, 10s. That long after the page changes, the dots fade out; they fade back in on the next swipe or when you return Home. Fades follow Android's animation speed, so with animations off (e-ink) they're instant. |
  | Page Indicator Fades To | **Nothing** (0%) or 10–90%: how visible the dots stay after auto-hide |
  | Page Indicator Opacity | 10–**100%** for the whole indicator |
  | Page Indicator Style | **Classic** (stock), Pill (small dimmed dots, the current page as a long pill, on a light backing) |

  Bold = default, which looks exactly like stock inkOS.

Unofficial build, not made by the inkOS developer. Supports inkOS **v0.6 and later**.

## Download

| Where | Link |
| --- | --- |
| App hub (always the newest build) | [inkOS.apk](https://github.com/fabiantorrestech/android-apps/releases/download/inkos/inkOS.apk), also listed on [fabiantorrestech.github.io/android-apps](https://fabiantorrestech.github.io/android-apps/) |
| Debug build (`app.inkos.debug`, "inkOS Debug", installs next to the real one) | [inkOS-debug.apk](https://github.com/fabiantorrestech/android-apps/releases/download/inkos/inkOS-debug.apk) |
| Every build, by version | [Releases](https://github.com/fabiantorrestech/inkOS-Patcher/releases) (`<version>-patched`) |
| Automatic updates | In [Obtainium](https://github.com/ImranR98/Obtainium), add `https://github.com/fabiantorrestech/inkOS-Patcher` |

## How it works

```
Daily at 09:00 UTC, or when you press "Run workflow"
        |
        v
1. Find the inkOS release to build ("latest" asks GitHub for the newest one)
2. Already built "<version>-patched"?  yes -> stop (unless "force" is ticked)
3. Download the official inkOS source code for that release
4. Apply every patches/*.patch, in name order
5. Build the release and debug APKs, both signed with the PERSONAL key
6. Check both signers match PERSONAL in android-apps/apps.json (stops if not)
7. Publish release "<version>-patched" here (release APK only)
8. If it is the newest inkOS release, also replace inkOS.apk and inkOS-debug.apk on the app hub
```

A patch is a list of edits, like "in this file, replace this line with that one." Each new inkOS release gets a fresh copy of the official code, and the edits are applied on top. Applying only fails when inkOS itself changed the same lines the patch edits.

### What the hide-until-search patch changes

- **New file `ui/DrawerReveal.kt`.** The three modes and their rules, with no Android code.
- **New file `res/values/strings_drawer_reveal.xml`.** The setting's 5 strings, kept out of `strings.xml` so upstream text changes never conflict.
- **`AppsFragment.kt` (inkOS's drawer).** About 25 added lines: one extra branch in the list filter, a "submitted text" value, and the Search key handler.
- **`Prefs.kt` and `SettingsFragment.kt`.** One stored setting (`APP_DRAWER_REVEAL_MODE`) and one row in the Search settings.

Behavior details:

- **After Search key:** results show only for the text you pressed Search on. Change the text and the drawer empties until you press Search again. Pressing Search a second time opens the top result, as in stock inkOS. inkOS's "Auto-launch result" still works, but only fires after Search.
- **Only the normal drawer is affected.** Hidden apps, picking a home app, editing favorites and private space show their full lists. Tapping a letter in the A-Z filter still lists that letter's apps.
- **Search bar switched off:** the drawer acts like stock inkOS, since there would be no way to reveal anything.
- **Settings export and import:** the mode is saved in the inkOS settings file. Stock inkOS ignores it.

### What the page-indicator-options patch changes

- **New file `ui/PageIndicatorOptions.kt`.** The five settings, the placement and auto-hide fade logic, and the Pill dots.
- **New file `res/values/strings_page_indicator.xml`.** The settings' strings.
- **`HomeUI.kt`.** The page indicator call now goes through `PatchedPageIndicator` (one import, one call).
- **`Prefs.kt` and `SettingsFragment.kt`.** Five stored settings (`PAGE_INDICATOR_SIDE`, `_AUTO_HIDE`, `_FADED_OPACITY`, `_OPACITY`, `_STYLE`) and five rows under Enable Page Indicator, greyed out while it's off.

Only the page indicator beside the home apps changes. The bottom "Page Dots" widget keeps the stock look.

## Installing

The app keeps inkOS's ID (`app.inkos`), so it replaces stock inkOS. Android can't install it over a copy signed with a different key, so the first time:

1. In inkOS, open Settings → **Backup/Restore** → **Backup All Data** and save the `.json` file.
2. Set another launcher as default, then uninstall inkOS.
3. Install `inkOS.apk` and set it as the default launcher.
4. Settings → **Backup/Restore** → **Restore Data** with that file, then re-grant notification access and any other permissions.

## Patching it yourself

### Usually: nothing

A new inkOS release is built the next morning. Obtainium notifies you, and the hub link updates on its own.

### Build a specific version now

1. On github.com, open this repo → **Actions** → **Build patched inkOS** → **Run workflow**.
2. In **release**, type the version (for example `v0.7`), or leave `latest`.
3. Tick **force** only to rebuild a version that already exists.
4. Press **Run workflow**. The APK appears under **Releases** after about 5 minutes.

### A new inkOS release won't patch

GitHub emails you that the run failed. Its summary lists the conflicting files. On the PC, using Git Bash:

```bash
cd ~/Documents/Developer/repos/inkOS-Patcher
scripts/refresh-patch.sh ../inkOS v0.7      # v0.7 = the new inkOS release
scripts/refresh-patch.sh ../inkOS v0.7 page-indicator-options   # then the other patch
```

The script:
1. downloads inkOS v0.7
2. moves the patch (one commit on branch `patch/hide-until-search` in `../inkOS`) on top of it
3. builds the debug APK
4. rewrites `patches/hide-until-search.patch`

If it stops on a conflict:
1. Open each listed file in `../inkOS`.
2. Keep inkOS's new code and put the patch's lines back. Every added line in an inkOS file sits next to an `inkOS-Patcher` comment.
3. Run `git add <file>`, then `git rebase --continue`.
4. Run the script again with the same arguments.

Then commit and push `patches/hide-until-search.patch` and run the workflow with the new release.

No local clone yet? `git clone https://github.com/gezimos/inkOS ../inkOS`, then `git -C ../inkOS switch -c patch/hide-until-search v0.6` and `git -C ../inkOS am -3 patches/hide-until-search.patch`.

### Change what the patch does

1. In `../inkOS`, run `git switch patch/hide-until-search`.
2. Edit the files and run `./gradlew assembleDebug`. The debug build is `app.inkos.debug` ("inkOS Debug") and installs next to the real one, so you can test without uninstalling anything.
3. Run `git commit -a --amend`. The patch must stay **one** commit.
4. Run `scripts/refresh-patch.sh ../inkOS <current version>`.
5. Commit and push the patch, then run the workflow with **force** ticked.

## Signing

- APKs are signed with the **PERSONAL** key, the same key as SleepyGuy, Shortcut Hub, GrayScaler+ and patched Curbox (android-apps ADR 2 and 8). The key and its password live in 1Password, vault "Android Signing", item `PERSONAL` (android-apps ADR 5).
- inkOS's own `build.gradle.kts` signs from the env vars `KEYSTORE_FILE`, `KEYSTORE_PASSWORD`, `KEY_ALIAS`, `KEY_PASSWORD`; the workflow fills them from these Actions secrets (names only; values never go in any file):

  | Secret | Holds |
  | --- | --- |
  | `SIGNING_KEY` | the PERSONAL keystore, base64 |
  | `ALIAS` | its key alias |
  | `KEY_STORE_PASSWORD`, `KEY_PASSWORD` | its password |
  | `APP_HUB_TOKEN` | fine-grained token with contents read/write on `android-apps` only; without it the hub step is skipped with a warning |

- To set them from 1Password without printing anything:

  ```bash
  R=fabiantorrestech/inkOS-Patcher; V="Android Signing"
  base64 -w0 ~/.android-signing/PERSONAL.keystore | gh secret set SIGNING_KEY -R $R
  op read "op://$V/PERSONAL/alias"    | tr -d '\r\n' | gh secret set ALIAS -R $R
  op read "op://$V/PERSONAL/password" | tr -d '\r\n' | gh secret set KEY_STORE_PASSWORD -R $R
  op read "op://$V/PERSONAL/password" | tr -d '\r\n' | gh secret set KEY_PASSWORD -R $R
  gh secret set APP_HUB_TOKEN -R $R     # paste the token at the prompt
  ```

## Cost

- GitHub Actions is free for public repositories.
- A daily check takes about 20 seconds; a build takes about 5 minutes.
- GitHub pauses scheduled workflows after 60 days without repository activity. It emails first; turn it back on with **Enable workflow** on the Actions tab.

## License

GPL-3.0, the same as inkOS. The patch source is in `patches/`.
