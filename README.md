# rojanarch

Interactive Flutter project scaffolder. Run one command, pick a state
management approach, and it creates the Flutter project *and* the Clean
Architecture folder structure for you.

```
$ rojanarch
🧩 rojanarch — interactive Flutter architecture scaffolder

📛 Flutter project name (lowercase_with_underscores): my_shop_app
📦 Creating Flutter project 'my_shop_app'...
...
Pick a state management approach:
  1. BLoC
  2. Provider
  3. Riverpod
  4. GetX
  5. Signals
Enter a number [1-5]: 5
🏗  Applying Signals Clean Architecture structure...
...
✅ Done! 'my_shop_app' is set up with Signals.
   cd into it and run: flutter run
```

Non-interactive (e.g. in CI, or if you just don't like prompts):

```bash
rojanarch --name=my_shop_app --state=signals --ci --verbose
```

If you run `rojanarch` from inside a folder that already has a
`pubspec.yaml`, it skips `flutter create` and just scaffolds the
architecture into the current project.

Any flag it doesn't recognize (`--overwrite`, `--no-sample`, `--dry-run`,
`--rollback`, `--no-color`, ...) is forwarded straight to the underlying
`scaffolds/create_structure_<state>.dart` script, so all the options from
the original standalone scripts still work.

## How it's put together

- `bin/rojanarch.dart` — the interactive entry point described above.
- `scaffolds/create_structure_{bloc,provider,riverpod,getx,signals}.dart`
  — the five architecture generators, unchanged and still runnable on
  their own with `dart run scaffolds/create_structure_bloc.dart` inside
  an existing Flutter project.

`rojanarch.dart` just asks a couple of questions, optionally runs
`flutter create`, then shells out to the matching scaffold script in the
new project's directory.

## Installing it so it runs like any other CLI tool

You only need the Dart SDK on PATH (it ships with Flutter, so if you can
run `flutter`, you can run these). No compiling, no OS-specific builds
required for this option — it works the same on Windows, macOS, and
Linux.

### Option A — activate straight from this folder (fastest to try)

```bash
dart pub global activate --source path /path/to/rojanarch
```

### Option B — activate from a git repo (share it with your team)

Push this folder to a repo, then anyone can run:

```bash
dart pub global activate --source git https://github.com/you/rojanarch.git
```

### Option C — publish to pub.dev (the "just like any other CLI tool" option)

```bash
cd rojanarch
dart pub publish
```

Once published, anyone can install it with:

```bash
dart pub global activate rojanarch
```

For A/B/C, make sure Dart's global bin folder is on your PATH (one-time
setup):

| OS | Folder to add to PATH |
|---|---|
| macOS / Linux | `$HOME/.pub-cache/bin` |
| Windows | `%APPDATA%\Pub\Cache\bin` |

After that, `rojanarch` (or `rojanarch.bat` on Windows) works from any
terminal, in any folder, exactly like `flutter` or `dart` do.

### Option D — one curl/iwr command, no Dart SDK, no git at all

This is the "just like brew/deno's installer" option. `.github/workflows/release.yml`
compiles `rojanarch` **and** all five `scaffolds/create_structure_*.dart`
scripts into native binaries (`rojanarch`, `rojanarch_bloc`,
`rojanarch_provider`, `rojanarch_riverpod`, `rojanarch_getx`,
`rojanarch_signals`) for Linux, macOS, and Windows, and attaches a zip
per OS to a GitHub Release whenever you push a version tag:

```bash
git tag v1.1.0
git push origin v1.1.0
```

`bin/rojanarch.dart` looks for a sibling `rojanarch_<state>` binary next
to itself first, and only falls back to `dart run scaffolds/*.dart` if
one isn't found — so once these binaries ship together, the whole flow
runs without Dart installed anywhere.

Your users then run one line, with nothing pre-installed:

```bash
# macOS / Linux
curl -fsSL https://raw.githubusercontent.com/rojanparajuli/My-Folder-Files-Architecture-Script/main/install.sh | bash

# Windows (PowerShell)
iwr https://raw.githubusercontent.com/rojanparajuli/My-Folder-Files-Architecture-Script/main/install.ps1 -useb | iex
```

`install.sh`/`install.ps1` grab the right zip from your latest release,
unpack it into `~/.local/bin` (or `%LOCALAPPDATA%\rojanarch` on
Windows), and add that folder to PATH if it isn't already there. After
that: `rojanarch`, from any folder, no Dart/Flutter SDK required for
the CLI itself (they'll still need Flutter installed to actually build
the app it scaffolds, obviously).

### Option E — the existing Debian package

`rojanarch-package/` (the `.deb` you already had) still works and is
the right call specifically for Debian/Ubuntu users who want `apt`-style
install/uninstall. It's just Linux-only — Options A–D are what makes it
cross-platform.
