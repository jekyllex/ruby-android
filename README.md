# Ruby for Android

This is a custom build of ruby programming language built for native execution of [Jekyll](https://jekyllrb.com) software on the Android app [JekyllEx](https://jekyllex.xyz).

The original [patches for ruby](https://github.com/termux/termux-packages/tree/master/packages/ruby) to work on Android were developed by the [Termux team](https://github.com/termux). The [custom patches](https://github.com/jekyllex/ruby-android/tree/main/patches) for tools to work on Android 10 & above, build scripts and workflows are developed by [Gourav Khunger](https://github.com/gouravkhunger).

## Build system (aligned with Termux)

Bootstraps are built with a pinned [termux-packages](https://github.com/termux/termux-packages) tree:

| Piece | Source |
|-------|--------|
| Package recipes / NDK toolchain | termux-packages @ pin in `.github/workflows/build-bootstraps.yml` (`TERMUX_PACKAGES_REF`) |
| NDK | **r29** (upstream default; 16 KB ELF `LOAD` alignment by default) |
| App id / install prefix | `xyz.jekyllex` via `apply-jekyllex-identity.sh` |
| Bootstrap package set + `ruby-*.zip` | `build-bootstraps.sh` (JekyllEx) |
| Ruby / git / libxml2 / gems | `patches/` overlay (keeps JekyllEx ruby 3.3.x and Android 10 fixes) |

Do **not** replace upstream `scripts/properties.sh` with a fork; only run `apply-jekyllex-identity.sh` on it.

This repository [releases](https://github.com/jekyllex/ruby-android/releases) 4 `zip` bootstrapped files available for download through `dl.jekyllex.xyz`, to provide support for [each CPU type](https://developer.android.com/ndk/guides/abis#sa) that Android devices support:

- x86 (i686)
- x86_64 (x86_64)
- armeabi-v7a (arm)
- arm64-v8a (aarch64)

The latest bootstraps can be found at these links:

- x86: https://dl.jekyllex.xyz/ruby/v0.1.4/i686.zip
- x86_64: https://dl.jekyllex.xyz/ruby/v0.1.4/x86_64.zip
- armeabi-v7a: https://dl.jekyllex.xyz/ruby/v0.1.4/arm.zip
- arm64-v8a: https://dl.jekyllex.xyz/ruby/v0.1.4/aarch64.zip

These files are downloaded by [Jekyllex](https://github.com/jekyllex/jekyllex-android) at build time based on the target device architecture and extracted to the app's home directory upon app installation. This simulates a linux-like working environment which can execute ruby and thus jekyll.

## Local / CI shape

```text
termux-packages @ TERMUX_PACKAGES_REF
  + apply-jekyllex-identity.sh   → properties (package name xyz.jekyllex)
  + build-bootstraps.sh          → --android10 → ruby-$arch.zip
  + patches/*                    → packages/
  + scripts/run-docker.sh        → ghcr.io/termux/package-builder (NDK r29)
```

Workflow: **Actions → Build bootstraps** (Termux docker builder, `-f` force rebuild).

Local (same as Termux):

```bash
# in a termux-packages checkout with overlays applied
./scripts/run-docker.sh ./scripts/setup-android-sdk.sh
./scripts/run-docker.sh ./scripts/build-bootstraps.sh --android10 -f --architectures aarch64
```
