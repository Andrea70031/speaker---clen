# Sonic MD — prova iOS senza Mac

Questo pacchetto serve per il primo obiettivo: verificare nel cloud che il progetto iOS nativo compili correttamente.

## Carica nel repository GitHub
Nella root devono comparire:
- `SonicMD/`
- `SonicMD.xcodeproj/`
- `codemagic.yaml`
- `README_CODEMAGIC_IT.md`

Non eliminare `index.html`.

## Codemagic
1. Accedi a Codemagic e collega GitHub.
2. Aggiungi il repository Sonic MD.
3. Seleziona il branch `main`.
4. Fai rilevare `codemagic.yaml`.
5. Avvia il workflow `Sonic MD - iOS compile check`.

Questo primo build è NON firmato e compila una `.app` per iOS Simulator. Serve a scoprire gli errori Swift/Xcode senza Apple Developer.

## Dopo il build verde
Per TestFlight serviranno Apple Developer Program, App Store Connect, Bundle ID definitivo, firma/certificato e App Store Connect API key collegata a Codemagic.

## Nota
Il Response Index è ancora una metrica comparativa sperimentale, non una diagnosi certificata.
