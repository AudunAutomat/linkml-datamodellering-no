# Rule: artefakt-testar skal krevje ferske filer og spegle build.yaml-gatinga

## Bakgrunn

Under `specs/done/rett-feil-i-make-test.md` (2026-11-06) synte det seg at Fase B i
`tests/test_make.sh` berre sjekka at artefakta fanst, og at han ikkje las `build.yaml`:

- 36 testar feila med «Fil manglar» fordi generatoren var slått av.
- 13 skjema med same flagg slått av passerte i tre månader på gamle artefakter i den
  gitignorerte `generated/`.

## Steg

1. Sjekk om ei eksisterande rule dekkjer `tests/**`
2. Skriv rula
3. Logg avgjerder

## Handlingsliste

- [x] Ingen eksisterande rule har `tests/**` i `paths:`
- [x] Ny fil `.claude/rules/testar.md`

## Avgjerder

- **Ny fil, ikkje utviding.** Ingen eksisterande rule har `tests/**` i scopet sitt. `make-conventions.md` dekkjer `src/assets/scripts/**`, der `batch-generate.py` ligg, men feilen var i testane og ikkje i produsenten.
- **Begge feilmønstera i éi underseksjon.** Mtime-sjekken og flagg-gatinga er to sider av same feilklasse: testen og produsenten er ueinige om kva som skal finnast. Den eine utan den andre gir anten falske OK eller falske feil.
- **Steg 4 (rein tilstand) er med.** Ein test som berre er køyrd mot ein eksisterande `generated/`, kan ikkje skilje ein generert fil frå ei gamal. Det var nettopp slik feila i `make test` vart verande skjulte.

## Utført

- `.claude/rules/testar.md`: ny rule for `tests/**`
