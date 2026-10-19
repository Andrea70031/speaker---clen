# Sonic MD 1.3 — Release notes

Target: iOS 17+, iPhone. Version 1.3.0, build 11.
Base branch: `release/sonic-md-1.2`. Build this exact branch in Codemagic (not `main`).

## Added
- **Sonic Auto Clean**: one-tap initial Smart Scan → balanced acoustic cleaning → final measurement.
- Comparative, appropriately qualified result card; no diagnosis of water, dust, or hardware faults.
- **Water Rescue Plus**: two bounded passes of low-frequency tone patterns with rest intervals.
- User-controlled **Stop session** during playback or measurement.
- Audio route validation before and during tones to prevent playback through connected headphones, Bluetooth audio or accessories.
- Volume preflight with moderate range (35–85%, 50–70% recommended) instead of mandatory maximum volume.
- Rescue-only modes do not request microphone permission; recording permission is requested for scans.
- Updated Italian and English guidance, safety copy, and display texts.
- AdMob banner suppressed while audio operations are active. Google UMP/ATT and existing identifiers unchanged.

## Build and release
- `project.yml`: `MARKETING_VERSION: 1.3.0`, `CURRENT_PROJECT_VERSION: 11`.
- `codemagic.yaml`: release workflow label and final IPA preflight updated.
- Launch `ios-compile-check` in Codemagic from `release/sonic-md-1.3` first. Then use `ios-testflight` with configured Apple signing/integration.

## QA on physical iPhone (still required)
- Normal scan and Auto Clean with microphone allowed and denied.
- Cancel during initial scan, cleaning and final verification.
- Headphones, AirPods/Bluetooth, audio-route change during playback.
- Volume below 35%, within 35–85%, above 85%.
- Water Rescue Plus and Dust/Adaptive Clean playback.
- Background/foreground and interruption by phone call/Siri.
- Italian and English localization, history, ATT consent, and ads not rendered during sounds.
- Final upload and App Store review are separate steps.

**Important:** Acoustic response figures are comparative and depend on the room, volume, and phone positioning. Cleaning is not guaranteed. Do not charge or connect a wet phone; follow Apple liquid-exposure guidance.
