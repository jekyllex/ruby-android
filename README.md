# Ruby for Android

This is a custom build of ruby programming language built for native execution of [Jekyll](https://jekyllrb.com) software on the Android app [JekyllEx](https://jekyllex.xyz).

The original [patches for ruby](https://github.com/termux/termux-packages/tree/master/packages/ruby) to work on Android were developed by the [Termux team](https://github.com/termux). The [custom patches](https://github.com/jekyllex/ruby-android/tree/main/patches) for tools to work on Android 10 & above, build scripts and workflows are developed by [Gourav Khunger](https://github.com/gouravkhunger).

This repository [releases](https://github.com/jekyllex/ruby-android/releases) 4 `zip` bootstrapped files available for download through `dl.jekyllex.xyz`, to provide support for [each CPU type](https://developer.android.com/ndk/guides/abis#sa) that Android devices support:

- x86 (i686)
- x86_64 (x86_64)
- armeabi-v7a (arm)
- arm64-v8a (aarch64)

The latest bootstraps can be found at these links:

- x86: https://dl.jekyllex.xyz/ruby/v0.1.2/i686.zip
- x86_64: https://dl.jekyllex.xyz/ruby/v0.1.2/x86_64.zip
- armeabi-v7a: https://dl.jekyllex.xyz/ruby/v0.1.2/arm.zip
- arm64-v8a: https://dl.jekyllex.xyz/ruby/v0.1.2/aarch64.zip

These files are downloaded by [Jekyllex](https://github.com/jekyllex/jekyllex-android) at build time based on the target device architecture and extracted to the app's home directoy upon app installation. This simulates a linux-like working environment which can execute ruby and thus jekyll.
