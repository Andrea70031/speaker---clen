# Sonic MD — Codemagic senza cartella .xcodeproj

Questa configurazione elimina il problema del caricamento manuale della cartella `SonicMD.xcodeproj`.

## Da caricare nella root di GitHub

- `project.yml`
- sostituisci `codemagic.yaml` con quello nuovo

La cartella `SonicMD/` che hai già caricato resta invariata.

## Come funziona

Durante la build Codemagic:

1. installa XcodeGen;
2. legge `project.yml`;
3. genera automaticamente `SonicMD.xcodeproj`;
4. esegue un compile check per iOS Simulator;
5. salva il log della build come artifact.

Quindi non serve più caricare `.xcodeproj` su GitHub.
