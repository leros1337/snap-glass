# SnapGlass

SnapGlass is a small Apple silicon macOS menu bar app inspired by Snap.

![SnapGlass preferences preview](preview.png)

It provides:

- automatic Dock shortcuts using a selected modifier plus number keys
- manual shortcuts for any installed app
- app peeking, where pressing a shortcut again shortly after activation hides the app
- a macOS 26 Liquid Glass preferences window

## Requirements

- Apple silicon Mac
- macOS 26 or newer
- Xcode 26.5 or newer
- The app is packaged as `arm64` only
- I am not ios developer and dont have dev account, so allow run it manually in Security settings or build yourself

## Install With Homebrew

```sh
brew tap leros1337/tap
brew install --cask snap-glass
```

## Package DMG

```sh
Scripts/package-dmg.sh
open .build/dist/SnapGlass-0.1.0.dmg
```

The DMG contains `SnapGlass.app` and an `/Applications` shortcut. Drag the app onto the shortcut to install it.

To package a specific version:

```sh
SNAPGLASS_VERSION=1.2.3 SNAPGLASS_BUILD=42 Scripts/package-dmg.sh
```

## Development

```sh
swift test
swift run SnapGlass
```

If SwiftPM attempts to write module cache files outside the repository in a restricted environment:

```sh
env CLANG_MODULE_CACHE_PATH="$PWD/.build/clang-module-cache" swift test
```

## Package App

```sh
Scripts/package-app.sh
open .build/SnapGlass.app
```