# Byte-tak på Step Summary i modell-analyse

## Bakgrunn

`.claude/rules/ci-workflows.md` § «Step Summary: byte-tak på rapportar»
(sjå `specs/done/rule-step-summary-byte-tak.md`) krev byte-tak på rapportar
med ubegrensa storleik. To stader brot med regelen:

- `.github/actions/run-modell-analyse/action.yml`: `cat` av rapporten.
- `.github/workflows/modell-analyse.yml`, steget «Generer sammendrag»: `cat`
  av `sammendrag-report.md`. Rapporten vart heller ikkje lasta opp som
  artefakt.

`lenkje-og-mermaid-sjekk.yml` har alt avkortingslogikken inline. Med to nye
stader vert det tre kopiar. CI-terskelen for DRY er 2+.

## Steg

1. Nytt skript `.github/scripts/step-summary-report.sh <tittel> <rapport>
   <artefakt>`, som skriv til `$GITHUB_STEP_SUMMARY` med byte-tak
   (`SUMMARY_MAX_BYTES`, standard 900 000).
2. Bruk skriptet i `run-modell-analyse/action.yml`.
3. Bruk skriptet i «Generer sammendrag» og last opp `sammendrag-report.md`
   som artefakt.
4. Erstatt inline-logikken i `lenkje-og-mermaid-sjekk.yml` med skriptet.
5. Test skriptet lokalt (under og over taket), og køyr actionlint mot dei
   endra workflowane.
6. Oppdater rula slik at ho peikar på skriptet.

## Handlingsliste

- [x] Steg 1: `.github/scripts/step-summary-report.sh`
- [x] Steg 2: `run-modell-analyse/action.yml`
- [x] Steg 3: «Generer sammendrag» + nytt steg «Last opp sammendrag»
  (`sammendrag-report`)
- [x] Steg 4: `lenkje-og-mermaid-sjekk.yml`
- [x] Steg 5: lokal test (135 byte urørt; 2 100 000 → 900 112 byte med
  avkortingslinje og logglinje; manglande rapport → `::error::`, rc 1; feil
  tal argument → rc 2); shellcheck rein; actionlint rein for begge
  workflowane; `action.yml` YAML-parse OK
- [x] Steg 6: rula viser til skriptet i staden for awk-snutten

## Avgjerder

- **Delt skript, ikkje composite action:** brukaren valde det. Eitt kall per stad.
- **`.github/scripts/`, ikkje `src/assets/scripts/`:** `generate.yml` vert
  trigga av `src/assets/scripts/**`. Eit CI-skript der ville utløyst full
  generering.
- **Kallast med `bash …`, ikkje som køyrbar fil:** repoet har
  `core.fileMode=false` (WSL på `/mnt/c`), så eksekveringsbiten vert ikkje
  med i git. Same mønster som `run-validation.sh` i `generate.yml`.
- **Skriptet feilar synleg når rapporten manglar** (`::error::`, rc 1). Det
  er siste kommando i alle tre stega, så steget vert raudt (jf. «Ingen stille
  feil»).
- **Ingen trigger- eller cache-oppdatering:** begge workflowane køyrer berre
  på schedule/dispatch, og skriptet inngår ikkje i noko cacha artefakt.

## Utført

Avkortingslogikken ligg i `.github/scripts/step-summary-report.sh` og vert
brukt i lenkjesjekk, run-modell-analyse og sammendraget. Sammendraget vert no
lasta opp som artefakt.
