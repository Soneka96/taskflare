# Learnings

Problems encountered during development and what we learned from them.

---

## Relative-cursor clearing breaks when content overflows the viewport

**Problem:** The original `TerminalScreen` cleared its output by moving the cursor up N lines (`\x1B[NA`) then erasing to end of screen (`\x1B[0J`). This worked as long as all previously printed content was still visible. When a screen (e.g. the test-command detail page) was tall enough to cause the terminal to scroll, earlier content (e.g. the main menu logo) moved into the scrollback buffer above row 1. The ANSI cursor-up sequence clamps at the top of the visible viewport and cannot enter scrollback, so the erase landed in the wrong place and the old content was never cleared.

**Fix:** All interactive TUI flows now run inside the terminal's **alternate screen buffer** (`\x1B[?1049h` to enter, `\x1B[?1049l` to exit). The alt buffer has no scrollback — it is a fixed-size viewport — so `\x1B[H\x1B[2J` (home + erase display) reliably clears everything on each redraw regardless of how much was printed before. On exit, the original terminal contents are restored exactly as they were.

**Implementation:** `TerminalSession` in `lib/src/cli/terminal.dart` owns the alt buffer lifecycle. One instance is created at the top-level entry point and injected into every sub-screen. A SIGINT handler inside `TerminalSession.run()` ensures the buffer is exited even on Ctrl-C.

---

## Windows toast notification icon doesn't appear from registry alone

**Problem:** Setting `IconUri` under `HKCU\Software\Classes\AppUserModelId\{AppId}` is documented as the way to register an unpackaged app for WinRT toast notifications. In practice, Windows uses the registry to resolve the display name and to allow `ToastNotificationManager::CreateToastNotifier` to succeed, but the **notification header icon** (the small square to the left of the app name) comes from the **Start Menu shortcut**, not from `IconUri`.

**What works:** Create a `.lnk` shortcut in `%APPDATA%\Microsoft\Windows\Start Menu\Programs\` with the `System.AppUserModel.ID` shell property set to match the `appId`. Windows reads the shortcut's icon and AppUserModelID to populate the notification header. The `IconUri` registry value still matters as a fallback and for the Action Center grouping, but without the shortcut the header icon never appears.

**Implementation:** `WindowsInitializer._createStartMenuShortcut()` runs a PowerShell `Add-Type` C# block that uses `IShellLink` + `IPropertyStore` + `IPersistFile` COM interfaces to create the shortcut and stamp the AppUserModelID on it in one atomic operation.

---

## `ref` on a `readonly static` field is a C# compile error

**Problem:** The `IPropertyStore.SetValue` signature requires `ref PropertyKey`. Passing a `static readonly PropertyKey` directly as `ref` is rejected by the C# compiler ("Cannot pass ref or out argument to a readonly field except in a static constructor").

**Fix:** Copy the field into a local variable before passing it:
```csharp
var key = PKEY_AppUserModel_ID;
ps.SetValue(ref key, ref pv);
```

---

## Shell quoting masks C# Add-Type errors when testing from Bash

**Problem:** When testing PowerShell `Add-Type` scripts interactively from Bash using `powershell -Command '...'`, escaped double quotes (`\"`) inside the PowerShell `@"..."@` heredoc are consumed by the shell layer, so the C# compiler sees malformed GUIDs and reports "unexpected character '\'". The same script passed via `Process.run` from Dart (which bypasses all shell quoting) compiles correctly.

**Lesson:** Always test PowerShell scripts invoked from Dart by writing them to a `.ps1` file and running `powershell -File`, which exactly mimics what Dart's `Process.run` delivers to PowerShell.

---

## `appLogoOverride` puts the icon in the notification body, not the header

**Problem:** The toast XML element `<image placement="appLogoOverride" src="..."/>` was added to show the app icon, but it renders as a large circle in the **notification body**, not next to the app name in the header.

**Lesson:** There is no toast XML attribute for the header icon. It comes exclusively from the registered app (shortcut icon or packaged app manifest). `appLogoOverride` is for replacing the content-area logo and is a different visual slot entirely.

---

## PNG-inside-ICO (Vista+ format) for registry IconUri

**Problem:** The registry `IconUri` value is used by Windows for Action Center grouping and taskbar pinning. PNG files work but ICO is the safest format for compatibility across all Windows surfaces.

**Solution:** Wrap the bundled PNG inside a minimal ICO container at runtime. The Vista+ ICO format allows embedding a raw PNG directly — no pixel decoding or re-encoding needed:

```
ICONDIR   (6 bytes)   reserved=0, type=1, count=1
ICONDIRENTRY (16 bytes)  width=0 (256), height=0 (256), colorCount=0, reserved=0,
                          planes=1, bitCount=32, imageSize=len(png), offset=22
PNG bytes (verbatim)
```

`WindowsInitializer._pngToIco()` implements this.

---

## Isolate.resolvePackageUri for bundled assets in a Dart CLI

**Problem:** Dart CLI tools don't have a Flutter-style asset bundling system. Embedding a large binary file as a byte literal in Dart source is impractical to maintain and review.

**Solution:** Place the asset under `lib/assets/` so it is part of the package. At runtime, resolve it with:
```dart
final uri = await Isolate.resolvePackageUri(Uri.parse('package:taskflare/assets/icon.png'));
final bytes = await File.fromUri(uri!).readAsBytes();
```
This works for `dart run`, `dart pub global activate`, and `dart pub global run` because the package root is always resolvable. It does **not** work for compiled `dart compile exe` binaries (the package filesystem is unavailable after compilation).

---

## Automated pub.dev publishing via GitHub Actions

**Goal:** Merge a PR into `main` → package automatically published to pub.dev.

**Architecture:** Two workflows are required because pub.dev's OIDC check requires the workflow to be triggered by a tag push (not a branch push). A single workflow on push-to-main cannot satisfy this.

1. **auto-tag.yml** — triggers on push to `main`, reads `version:` from `pubspec.yaml`, creates and pushes `v{version}` tag if it doesn't already exist.
2. **publish.yml** — triggers on tag push matching `v*`, runs `dart pub publish --dry-run` then `dart pub publish -f` using OIDC (`id-token: write` permission).

**Why a PAT is required for auto-tag:** GitHub blocks `GITHUB_TOKEN` pushes from triggering other workflow runs (security policy). A classic Personal Access Token with `repo` scope must be stored as `GH_PAT` secret and passed to `actions/checkout` so the tag push triggers `publish.yml`.

**pub.dev configuration (one-time):** Enable automated publishing at pub.dev → package Admin tab. Set tag pattern to `v{{version}}`, check "Enable publishing from push events", check "Require GitHub Actions environment", set environment name to `pub.dev`.

**GitHub environment protection rules gotcha:** The environment must allow **both** branch `main` (for auto-tag.yml) and tag pattern `v*` (for publish.yml). Without the `v*` tag rule, publish.yml fails with "Tag is not allowed to deploy to pub.dev due to environment protection rules" even though the tag was created from main.

**YAML gotcha:** `run: echo "..." | sed 's/version: *//'` fails YAML parsing because `version: ` (colon followed by space) inside an unquoted scalar is treated as a nested mapping key. Always use `run: |` block scalar for commands containing colon-space sequences.

---

## _isRegistered must check all components to avoid silent skips

**Problem:** The initial `_isRegistered` check only verified the registry key. If the icon file or Start Menu shortcut was missing (e.g. after a manual deletion or a first run without the icon), the check returned `true` and re-registration was skipped, leaving the notification broken.

**Fix:** `_isRegistered` returns `true` only when **all three** are present: registry key, ICO file, and Start Menu shortcut. Any missing component triggers a full re-registration.
