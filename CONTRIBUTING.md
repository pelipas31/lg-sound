# Contributing

Bug reports and small, focused pull requests are welcome. Please write in English or Russian.

For a compatibility report, include your Mac chip, macOS version, monitor model, connection path (including docks/adapters), and whether the menu slider and volume keys work separately. For a keyboard knob, include the keyboard model and firmware/remapping software if known.

Build with `./build.sh`. Before submitting a change, build successfully and verify the app signature:

```sh
codesign --verify --deep --strict 'build/LG Sound.app'
```

If hardware is available, check volume read/write, mute/restore, switching to another audio output, disconnect/reconnect, and media keys after granting Accessibility access. Never claim hardware coverage you have not tested.

The app can write local diagnostics to `~/Library/Application Support/LG Sound/status.json`. Review and redact device names and display identifiers before sharing it. Do not include the entire file by default.

The app is ad-hoc signed. Rebuilding or replacing it may invalidate its Accessibility grant. Remove the old entry from Accessibility and add the current app again before debugging media key handling.

Keep `Vendor/m1ddc` changes separate, preserve its license, and document an updated upstream commit in `THIRD_PARTY_NOTICES.md`.
