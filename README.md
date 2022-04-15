# Ruby for Android

This is a custom build of ruby programming language built for native execution of [Jekyll](https://jekyllrb.com) software on the Android app [JekyllEx](https://jekyllex.xyz).

The [original patches](https://github.com/termux/termux-packages/tree/master/packages/ruby) for ruby to work on Android were developed by the [Termux team](https://github.com/termux). The custom build scripts, properties scripts and workflows for building the package are developed by [Gourav Khunger](https://github.com/gouravkhunger).

This repository hosts 4 `zip` bootstraped files at `dl.jekyllex.xyz` for ruby, to have support for [each CPU type](https://developer.android.com/ndk/guides/abis#sa) that Android devices support:

- armeabi-v7a (arm)
- arm64-v8a (aarch64)
- x86 (i686)
- x86_64 (x86_64)

The bootstraps of which can be found at these links:

- armeabi-v7a: https://dl.jekyllex.xyz/ruby-arm.zip
- arm64-v8a: https://dl.jekyllex.xyz/ruby-aarch64.zip
- x86: https://dl.jekyllex.xyz/ruby-i686.zip
- x86_64: https://dl.jekyllex.xyz/ruby-x86_64.zip

These files would be downloaded by [Jekyllex Android app](https://github.com/jekyllex/jekyllex-android) at runtime based on device cpu architecture and extracted to the App Home directoy. This simulates a linux working environment which can run ruby and thus jekyll.