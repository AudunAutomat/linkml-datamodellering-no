# Rule: nye make-target skal vere synlege i `make help`

## Bakgrunn

`src/assets/scripts/makefile/help.sh` viser eit target berre dersom (a) navnet
samsvarer med `[a-zA-Z_-]+` og (b) navnet samsvarer med eit mønster i
`categories`-lista. Andre target vert stille utelatne. `i18n-check`/`-status`/
`-stamp` var aldri synlege (sifferet i «i18n»). Etter omdøyping til
`translate-*` var dei framleis borte til kategori-mønsteret vart utvida. Sjå
`specs/done/translate-make-targets.md`.

## Steg

1. Legg til seksjonen «Nye target skal vere synlege i `make help`» i
   `.claude/rules/make-conventions.md`, og oppdater `description`.

## Handlingsliste

- [x] Steg 1

## Avgjerder
- **Utvida eksisterande rule, ikkje ny fil.** `make-conventions.md` dekkjer
  både `make/**` (der target vert definerte) og `src/assets/scripts/**` (der
  `help.sh` ligg), så scopet er det same.
- **Ingen «Anna»-fallback i `help.sh`.** Rula handterer fallgruva ved
  utviklingstid. Ein fallback-kategori ville vere ei kodeendring som brukaren
  ikkje har bede om.

## Utført

- `.claude/rules/make-conventions.md`: ny seksjon «Nye target skal vere synlege
  i `make help`», `description` oppdatert
