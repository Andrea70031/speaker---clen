# Sonic MD — Codemagic

## Struttura corretta del repository

```text
index.html
README.md
codemagic.yaml
README_CODEMAGIC_IT.md

docs/
  ROADMAP.md

ios/
  README.md

SonicMD/
  SonicMDApp.swift
  ContentView.swift
  AcousticEngine.swift
  TermsView.swift
  Info.plist

SonicMD.xcodeproj/
  project.pbxproj
```

Il primo workflow Codemagic compila per iOS Simulator senza firma Apple.

Non serve ancora Apple Developer per questo primo compile check.
