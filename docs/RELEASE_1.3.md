# Sonic MD 1.3 — Release notes

Target: iOS 17+, iPhone. Version 1.3.0, build 13.
Codemagic source branch: `feature/liquid-glass-restyle` (do not build `main` for this TestFlight release).

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
- `project.yml`: `MARKETING_VERSION: 1.3.0`, `CURRENT_PROJECT_VERSION: 13`.
- `codemagic.yaml`: release workflow label and final IPA preflight updated.
- Launch `ios-compile-check` in Codemagic from `feature/liquid-glass-restyle` first. Then use `ios-testflight` with configured Apple signing/integration.

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

## Build 13 — Volume preflight + Liquid Glass refresh (November 7, 2026)
- Audio preflight now activates a playback session before reading the output volume. A stale zero is shown as unavailable (—), not falsely as 0%.
- On an unavailable reading, users can confirm they have manually selected a moderate volume; a detected volume outside 35–85% still requires adjustment. The built-in speaker route remains mandatory.
- New animated Aurora backdrop (respects Reduce Motion), acoustic response dial, native iOS 26 glass buttons, interactive rescue cards, and coordinated glass metric containers.
- Native Liquid Glass is only available on iOS 26+; earlier iOS versions retain readable material-based controls.
- App Store Connect build number increased to 13 to avoid the duplicate build 12.

### Regression checklist for build 13 (must be done on physical iPhone)
- [ ] Test the volume sheet after cold launch when `outputVolume` initially reports 0: show “—” and allow explicit manual confirmation.
- [ ] Adjust volume with the hardware buttons and the native slider; check the reading refreshes.
- [ ] Verify a detected value over 85% blocks “Avvia funzione” until lowered.
- [ ] Verify a detected value under 35% blocks until raised.
- [ ] Verify plugged-in headphones, AirPods and Bluetooth output are rejected.
- [ ] Run Smart Scan, Auto Clean, manual rescue modes, and Stop.
- [ ] Verify iOS 26 native glass, text contrast, and dark/light mode. Verify iOS 17–25 fallback if available.
- [ ] Verify UMP/ATT consent, banner behavior and local history.
- [ ] Confirm the signed IPA says `CFBundleShortVersionString=1.3.0` and `CFBundleVersion=13` before TestFlight upload.

Do not merge into main or publish to the App Store before successful device QA.
