# Native iOS build

A native SwiftUI proof-of-concept has already been prepared for Sonic MD.

## Planned stack

- SwiftUI
- AVFoundation
- AVAudioEngine
- AVAudioSession
- Accelerate

The native version is required to properly control the iPhone audio session, including speaker routing and expected behaviour with the silent switch.

Because the current development environment does not include macOS/Xcode, the native project must be compiled and signed using Xcode on macOS or a cloud macOS build environment, then distributed to the test iPhone through TestFlight.

## Important

Do not treat the current acoustic Response Index as a medical, laboratory or certified hardware diagnostic value.

The native build should preserve the same product principles as the web prototype:

- local processing where possible
- no fake diagnostic claims
- safe volume limits
- clear Before / After comparison
- premium iOS-native interface
