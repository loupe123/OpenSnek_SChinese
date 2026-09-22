<p align="center">
  <img src="OpenSnek/App/Resources/Assets.xcassets/AppIcon.appiconset/icon_512x512@2x.png" alt="open-snek app icon" width="200">
</p>

<h1 align="center">OpenSnek</h1>

<p align="center">
  Configure supported Razer mice on macOS without Synapse, Windows, or vendor lock-in.
</p>

<h2 align="center"><a href="https://github.com/gh123man/OpenSnek/releases">Download</a></h2>

![Screenshot](/docs/media/screenshot.png)

OpenSnek is an open source native macOS app for configuring supported Razer mice over USB or Bluetooth, with early lighting-only support for select Razer keyboards and keypads.

## Highlights

- Lightweight native macOS app bundle with no unnecessary runtime bloat
- Very low idle and background overhead, so it stays out of the way when you are not using it
- Optional menu bar control for quick, on-the-fly DPI adjustments  
  <img src="docs/media/menu-icon.png" alt="open-snek app icon" width="250">
- Manage onboard profiles on supported devices  
  <img src="docs/media/profiles.png" alt="open-snek onboard profiles screenshot" width="450">
- Rebind all supported mouse buttons and write to onboard storage  
  <img src="docs/media/bindings.png" alt="open-snek app icon" width="300">
- Official-style button mapping page: a vector top-down mouse map with leader-line call-outs, actions grouped the way Synapse groups them (mouse / keyboard / media / DPI / other), and full HyperShift layer support — including choosing which button acts as the HyperShift trigger
- Detail area split into pages (Buttons / Performance / Lighting / Settings) instead of one long scroll

## Simplified Chinese localization

This repository is a fork of [gh123man/OpenSnek](https://github.com/gh123man/OpenSnek) that adds a Simplified Chinese (`zh-Hans`) localization. It follows the upstream architecture rather than patching strings ad hoc:

- Every user-facing string is resolved through `Localizable.strings`, so the app picks the language from the system setting — no in-app language switch and no separate Chinese-only build.
- Device names, status labels, diagnostics, error messages and the menu bar view are localized alongside the main window.
- The localization is non-invasive: upstream English remains the development language, and `en` is still a supported localization.

Build and run the Chinese build exactly like upstream:

```bash
git clone https://github.com/loupe123/OpenSnek_SChinese.git
cd OpenSnek_SChinese/OpenSnek
./scripts/build_macos_app.sh --configuration release
```

## Supported Devices

Support is transport-specific. A mouse may be supported over USB, Bluetooth, or both, depending on what has been captured, tested, and validated in the app.

| Device | USB | Bluetooth | Notes |
|---|---|---|---|
| Basilisk V3 X HyperSpeed | Validated | Validated | |
| Basilisk V3 | Mapped | No | OpenRazer-backed USB profile, sharing the Basilisk V3 USB family configuration with a `26,000` DPI ceiling |
| Basilisk V3 Pro | Validated | Validated | |
| Basilisk V3 35K | Validated | No | Shares the Basilisk V3 USB family configuration |
| Orochi V2 | Not yet | Contributor validated | Contributor validated Bluetooth DPI stages and battery; button remap is profile-mapped pending hardware readback validation. 2.4 GHz HyperSpeed dongle not yet supported. Mouse has no RGB lighting. |
| Basilisk (2017) | Contributor validated | No | Contributor validated DPI (scalar, X/Y, live 5-stage table), poll-rate reads, and logo/scroll lighting; button remap not yet mapped |
| Lancehead Tournament Edition | Contributor validated | No | Contributor validated DPI (scalar, X/Y, live 5-stage table), poll-rate reads, and all four lighting zones; button remap not yet mapped |
| Huntsman Mini | Contributor validated | No | Keyboard: contributor validated backlight lighting and brightness. First non-mouse profile; key remap not supported |
| Tartarus Pro | Contributor validated | No | Keypad: contributor validated backlight lighting and brightness. Analog actuation and key remap have no public protocol |

Status key:
- `Validated` = supported and locally capture/test validated in OpenSnek
- `Contributor validated` = support is based on external contributor hardware validation and has not been locally validated by OpenSnek maintainers
- `Mapped` = supported through a shipped profile, but not yet locally validated on OpenSnek hardware
- `Not yet` = the transport exists on the hardware but OpenSnek does not support it yet
- `No` = that transport is not available on the device

Not every feature is fully supported on every listed transport yet. Some controls and readback paths are still partial while capture, testing, and validation continue.

Support docs:
- Per-device USB/BT feature matrix: [docs/DEVICE_SUPPORT.md](docs/DEVICE_SUPPORT.md)
- Getting started with new device support: [docs/development/ADDING_DEVICE_SUPPORT.md](docs/development/ADDING_DEVICE_SUPPORT.md)
- Protocol and transport docs: [docs/protocol/PROTOCOL.md](docs/protocol/PROTOCOL.md)
- Contribution and new-device workflow: [CONTRIBUTING.md](CONTRIBUTING.md)

Unsupported Razer mice still get a best-effort experience when possible. OpenSnek will probe for controls that already match known behavior, show a light warning that the device is not fully supported, and avoid exposing UI for features that have not been mapped safely yet.

Support for more devices is welcome. New device support can land either through outside contributors or as more hardware becomes available for capture, testing, and validation.

## Motivation

Razer does not support the Basilisk V3 X HyperSpeed on macOS at all, so this project started by reverse engineering the BLE protocol from Windows traffic between the mouse and Synapse.

The goal is simple: make supported Razer mice configurable on macOS without needing Synapse, Windows, or a second machine just to change settings.

More device support is welcome, whether that comes from new hardware captures or pull requests. For USB protocol reference work, this project also builds on the excellent documentation and reverse-engineering effort from [OpenRazer](https://github.com/openrazer/openrazer).

## Features

- Change DPI, stage count, and active stage
- Adjusts supported lighting settings
- Remaps supported buttons, with actions grouped by category (mouse buttons, keyboard, media, DPI, other)
- Switch between the normal and HyperShift button layers, and choose which button acts as the HyperShift trigger
- Works over USB and Bluetooth where the device protocol allows it
- Avoids the need for Synapse or a separate Windows machine

### Button mapping notes

HyperShift behaves the way Synapse users expect:

- **One trigger per layer.** Assigning a button as the HyperShift trigger automatically returns the previous trigger to its default action, so two buttons can never fight over the layer.
- **The trigger is locked inside its own layer.** While you are editing the HyperShift layer the trigger button's dropdown is disabled, because that button is what activates the layer in the first place.

The HyperShift trigger action was decoded from hardware rather than documented protocol: `OpenSnekProbe usb-profile-read --button-slots 5` on a Basilisk V3 (`1532:0099`) reports the trigger as function class `0x0C` (`0c 01 01 00 00 00 00`), while ordinary mouse buttons use class `0x01`.

## Download and Install

1. Download the latest DMG from [GitHub Releases](https://github.com/gh123man/OpenSnek/releases).
2. Open the DMG.
3. Drag `OpenSnek.app` into `Applications`.
4. Launch `OpenSnek`.

Official builds use the latest Xcode/macOS SDK. Local source builds can use
either full Xcode or Command Line Tools. Minimum supported macOS version:
macOS 14.

If macOS asks for permissions:

- For USB control, grant `Input Monitoring` to `OpenSnek` in `System Settings > Privacy & Security`.
- For Bluetooth control, allow Bluetooth access when prompted.

## Build From Source

From the repo root:

```bash
./run.sh
```

With full Xcode, that rebuilds the canonical `OpenSnek.app` target. On a
Command Line Tools-only Mac, it builds with SwiftPM and assembles the same
stable `.dist` app bundle before launching it through
`OpenSnek/scripts/run_macos_app.sh`. If Command Line Tools provides an older
Swift than the package requires, install the current toolchain with
`brew install swift`; the script detects it without changing `xcode-select` or
`PATH`.

If you want to reuse the current app bundle without rebuilding:

```bash
./run.sh --no-build
```

## Build

```bash
swift build --package-path OpenSnek
```

Direct SwiftPM commands require Swift 6.2 or newer. After `brew install swift`,
either call `/opt/homebrew/opt/swift/bin/swift` directly on Apple silicon or
prepend the Homebrew Swift directory to `PATH`.

## Test

```bash
swift test --package-path OpenSnek
```

Running tests with the above command as-is still requires a full Xcode installation
due to XCTest, but if desired, it is possible to run the test suite on a machine with
only Xcode CLT installed, by extracting XCTest from an Xcode .xip for standalone
usage and pointing swift test to it, but due to the non-reproducible nature of
that procedure, caused by the need to match the Xcode version XCTest is extracted
from to the user's installed Xcode CLT version, which differs by macOS version,
that process will not be documented in detail here, other than noting it can be achieved.

## Xcode

```bash
./OpenSnek/scripts/generate_xcodeproj.sh --open
```

`OpenSnek/OpenSnek.xcodeproj` is generated from `OpenSnek/project.yml` on demand and is not checked into git.

## Project Docs

- App build, run, probe, and validation details: [OpenSnek/README.md](OpenSnek/README.md)
- Device support and reverse-engineering workflow: [CONTRIBUTING.md](CONTRIBUTING.md)
- Getting started with new device support: [docs/development/ADDING_DEVICE_SUPPORT.md](docs/development/ADDING_DEVICE_SUPPORT.md)
- Device support matrix by feature and transport: [docs/DEVICE_SUPPORT.md](docs/DEVICE_SUPPORT.md)
- DMG release and notarization setup: [docs/release/DMG_RELEASE.md](docs/release/DMG_RELEASE.md)
- Protocol documentation: [docs/protocol/PROTOCOL.md](docs/protocol/PROTOCOL.md)
- Kraken Kitty V2 research (unsupported on macOS): [protocol and transport findings](docs/research/KRAKEN_KITTY_V2_MACOS_TRANSPORT_FINDINGS.md)
- Supported Python tooling: [tools/python/README.md](tools/python/README.md)
- BLE capture corpus: [captures/README.md](captures/README.md)

## License

This repository is licensed under the Apache License 2.0. See [LICENSE](LICENSE).
