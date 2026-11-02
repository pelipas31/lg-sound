<p align="center"><img src="Assets/AppIcon.png" width="150" alt="LG Sound app icon"></p>
<h1 align="center">LG Sound</h1>
<p align="center">Monitor volume and brightness. Under your control.</p>
<p align="center">
  <a href="https://github.com/pelipas31/lg-sound/releases/latest">Download</a> ·
  <a href="README.ru.md">Русский</a> ·
  <a href="https://github.com/pelipas31/lg-sound/issues">Report an issue</a>
</p>
<p align="center">
  <img src="https://img.shields.io/badge/macOS-13%2B-24292f" alt="macOS 13 or later">
  <img src="https://img.shields.io/badge/Apple_Silicon-arm64-007aff" alt="Apple Silicon arm64">
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-34c759" alt="MIT license"></a>
</p>

LG Sound is a small, free menu bar app that controls the hardware speaker volume and display brightness of an LG ULTRAGEAR+ monitor over USB-C / DisplayPort. Use the sliders for both controls, or standard media keys and a compatible keyboard knob for volume.

It started with a simple annoyance: an LG monitor connected to an M3 Mac played audio, but macOS’s volume controls were unavailable. LG Sound sends volume commands directly to the monitor using [m1ddc](https://github.com/waydabber/m1ddc).

## Features

- Menu bar volume slider and percentage.
- Hardware brightness slider in both the menu and controls window, with read-back of the monitor’s actual setting.
- A separate controls window: open LG Sound from Applications to access it even when the menu icon is hidden.
- Volume up/down and mute from standard media keys, including a tested Keychron knob.
- Mute and restore the previous level from the menu.
- Media keys control LG only while it is the default audio output; the slider always targets LG.
- Optional launch at login and automatic connection checks after wake/disconnect.
- Automatic media-key reconnection on audio output changes, with a watchdog for disabled or invalid event taps.
- Live media-key status and a manual Reconnect volume keys action.
- English and Russian interface, chosen by macOS language preferences.
- Local operation, no account, analytics, or app network requests.

The native macOS sliders may remain unavailable for the external DisplayPort output. LG Sound provides its own sliders for hardware volume and brightness. It does not install an audio driver, modify the audio stream, or simulate brightness with a dark overlay. Brightness keys are not intercepted.

## Compatibility

| Requirement | Status |
| --- | --- |
| Mac | Apple Silicon; arm64 build only |
| macOS | 13+ build target; older releases have not been hardware-tested |
| Monitor | Currently targets the display/audio name `LG ULTRAGEAR+` |
| Connection | USB-C / DisplayPort with working DDC/CI volume commands; brightness also needs DDC/CI luminance support |
| Tested setup | LG 52G930B / `LG ULTRAGEAR+`, M3 Pro, macOS 27, USB-C / DisplayPort, Keychron volume knob |

Other LG models, HDMI, docks, Intel Macs, and nonstandard knob mappings are unverified. DDC/CI support varies by monitor and connection. When multiple matching monitors are connected, the first is selected. There is no monitor picker yet.

## Install

1. Download `LG-Sound-1.1.1-arm64.zip` from [Releases](https://github.com/pelipas31/lg-sound/releases/latest) and unzip it.
2. Move **LG Sound.app** into **Applications** before opening it.
3. Release downloads from 1.1.1 are **Developer ID signed, but not notarized**. GitHub Actions artifacts and source builds without a configured certificate are ad-hoc signed. If macOS blocks it, review the source or build it yourself. If you choose to trust the downloaded build, Apple documents the app-specific **Privacy & Security → Open Anyway** flow [here](https://support.apple.com/en-gb/102445).
4. Select **LG ULTRAGEAR+** in **System Settings → Sound → Output**.
5. Use the speaker icon in the menu bar. Neither the volume nor the brightness slider needs Accessibility access.
6. For keys or a knob, choose **Enable volume keys…**, then enable **LG Sound** in **Privacy & Security → Accessibility**. Restart the app if macOS requests it.

Downloads include `SHA256SUMS.txt`. Compare the archive’s SHA-256 hash with `shasum -a 256 LG-Sound-1.1.1-arm64.zip`.

### Brightness is unavailable or limited

Brightness uses the monitor’s hardware DDC/CI luminance control. If it cannot be read, the brightness slider is disabled while volume remains usable. If the monitor clamps a requested setting, the app shows the reported value and a message. HDR, automatic brightness, or picture presets may limit adjustments; check the monitor settings. Changes made with the monitor’s controls are read on the next poll, roughly every eight seconds.

### Menu icon is missing

Open **LG Sound.app** from Applications: this opens the controls window and requests that the menu icon be shown again. On recent macOS versions, also check **System Settings → Menu Bar → Allow in the Menu Bar**. The app’s internal visibility flag can be true while macOS hides its icon.

Version 1.0.1 uses the public bundle identifier `io.github.pelipas31.LGSound` and an explicitly named status item. On the development Mac, installing this build in `/Applications` restored an icon that remained hidden with the old installation. This is a tested recovery on one Mac, not a guarantee for every macOS menu bar issue.

When updating from 1.0.0, quit the old copy and replace it in Applications. Remove any old Accessibility entry and grant access to the new copy. Re-enable optional launch at login if needed. You can still use the window slider while Accessibility access is off.

### Keys or knob do nothing

The controls window shows whether media keys are connected, waiting for the LG output, reconnecting, or denied Accessibility access. Check that LG is the selected audio output. If permission is present but keys stop responding, choose **Reconnect volume keys**. Output changes and wake automatically reconnect the tap; a health check runs every second.

**When migrating from an old ad-hoc build, the Accessibility switch can appear on while the current app is denied.** Remove LG Sound from Accessibility with **−**, add the current `/Applications/LG Sound.app` with **+**, and enable it. Version 1.1.1 uses a stable Developer ID identity for release downloads so subsequent updates with the same signer and bundle ID can retain the grant. Restart if macOS requests it. Source/CI builds with ad-hoc signatures still change identity with each rebuild; [Apple explains code identity here](https://developer.apple.com/documentation/technotes/tn3127-inside-code-signing-requirements).

The knob must send standard volume up/down or mute commands. Custom VIA/QMK mappings may need adjustment. Other apps that intercept media keys can conflict.

### Monitor does not respond

Enable DDC/CI in the monitor’s on-screen menu if available, try a direct USB-C / DisplayPort connection, and choose **Reconnect monitor**. Hardware volume is polled every eight seconds, so changes made with the monitor joystick may appear after a short delay.

## Build from source

Install Apple Command Line Tools if needed (`xcode-select --install`), then:

```sh
git clone https://github.com/pelipas31/lg-sound.git
cd lg-sound
./build.sh
```

The result is `build/LG Sound.app`. Copy it to Applications yourself. Building does **not** replace an installed app. Homebrew, the full Xcode IDE, and a separate m1ddc installation are not required.

Run the media-key recovery regression scenarios with `./scripts/test.sh`. They cover headphone/monitor switching, audio device ID replacement, wake, disabled/invalid taps, installation failures, and permission changes without modifying the machine’s audio output.

To sign local builds with your own certificate, set `CODE_SIGN_IDENTITY` when running the build, or put its name/fingerprint in the ignored `.signing-identity` file. Without either setting, builds are ad-hoc signed. Signing with Developer ID uses Hardened Runtime and an Apple timestamp; notarization is a separate step.

Create the release ZIP and checksum with `./scripts/package.sh`. Regenerate the macOS `.icns` file from the PNG with `./scripts/make-icon.sh`.

The bundled m1ddc helper is compiled locally from the pinned source in `Vendor/m1ddc` and included with its MIT license. GitHub Actions builds and checks the app signature; physical keyboard/monitor tests require hardware.

## Privacy and permissions

Accessibility access lets LG Sound intercept standard volume media commands. The app does not record typed text or audio. A local file at `~/Library/Application Support/LG Sound/status.json` contains the audio output name, display identifier, volume, brightness and its error state, permission/tap state, tap health/reconnection counters, audio device ID, output listener status, and last volume media event. It is not uploaded. Review device names and identifiers before sharing diagnostics.

To uninstall, quit the app, disable its optional login item, remove it from Applications and Accessibility, and optionally delete its `LG Sound` folder inside `~/Library/Application Support`.

## Contribute and license

See [CONTRIBUTING.md](CONTRIBUTING.md). English and Russian bug reports are welcome.

MIT licensed. Built with [m1ddc](https://github.com/waydabber/m1ddc); see [third-party notices](THIRD_PARTY_NOTICES.md). Independent community project, not affiliated with LG Electronics, Apple, or Keychron.
