# Rule: byte-tak på rapportar til Step Summary

## Bakgrunn

Lenkjesjekk-køyring 38262481311 fekk annotasjonen «`$GITHUB_STEP_SUMMARY
upload aborted, supports content up to a size of 1024k, got 1075k`». Heile
Step Summary-en for steget forsvann. Feilen vart retta med eit byte-tak i
`specs/done/lenkjesjekk-step-summary-over-1mib.md`.

Det same mønsteret, der heile rapporten vert skriven med `cat`, finst i
`.github/actions/run-modell-analyse/action.yml` og i steget «Generer
sammendrag» i `.github/workflows/modell-analyse.yml`. Desse rapportane veks
med talet på funn.

## Steg

1. Legg til ein underseksjon i `.claude/rules/ci-workflows.md`: ein rapport
   med storleik som veks med talet på funn skal skrivast til Step Summary med
   byte-tak, og full rapport skal lastast opp som artefakt.
2. Oppdater `description` i frontmatter.

## Handlingsliste

- [x] Steg 1: ny underseksjon «Step Summary: byte-tak på rapportar»
- [x] Steg 2: `description` nemner byte-tak i Step Summary

## Avgjerder

- **Utvida `ci-workflows.md`, ikkje ny fil:** same `paths:`-scope
  (`.github/workflows/**`, `.github/actions/**`).
- **Gjeld berre rapportar som veks med talet på funn:** faste
  oppsummeringar og lister som alt er avgrensa (t.d. `head -50` i
  lenkjesjekk-oversikta) treng ikkje tak. Elles ville rula kravd taket på
  alle `>> "$GITHUB_STEP_SUMMARY"`-linjer.
- **Eksisterande brot i modell-analyse er ikkje retta:** brukaren bad berre
  om rula. Dei to stadene er nemnde under Bakgrunn som kandidatar til ein
  eigen fiks.

## Utført

Ny underseksjon «Step Summary: byte-tak på rapportar» i
`.claude/rules/ci-workflows.md`, og `description` er oppdatert.
