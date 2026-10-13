# «Anna»-gruppe i `make help`

## Bakgrunn

`src/assets/scripts/makefile/help.sh` utelèt stille target som ikkje samsvarer
med noko kategori-mønster (sjå `specs/done/translate-make-targets.md` og
`specs/done/rule-make-help-synlegheit.md`). I dag gjeld det `gource-preview`,
`gource-video` og `print-domains`. Ei avsluttande «Anna»-gruppe skal vise slike
target i staden for å skjule dei.

## Steg

1. `help.sh`: vis target som ikkje er viste under nokon kategori, under «Anna»
   til slutt. Gruppa vert berre skriven ut når ho ikkje er tom.
2. Oppdater seksjonen i `.claude/rules/make-conventions.md`, slik at han
   skildrar fallbacken.
3. Verifiser med `make help`.

## Handlingsliste

- [x] Steg 1
- [x] Steg 2
- [x] Steg 3

## Avgjerder
- **Fallback som siste kategori med mønsteret `.`.** Gjenbruker den
  eksisterande løkka og `shown`-oppslaget, så det trengst inga eiga
  utskriftslogikk. Gruppa vert hoppa over når alle target alt er viste.
- **Siffer i targetnavn er framleis utelatne.** Regex-en for innlesing
  (`[a-zA-Z_-]+`) er ikkje endra, fordi brukaren berre bad om «Anna»-gruppa.
  Rula krev framleis navn utan siffer.
- **Dei tre targeta under «Anna» er ikkje flytta til eigne kategoriar.**
  `print-domains`, `gource-preview` og `gource-video` står der inntil vidare.

## Utført

- `src/assets/scripts/makefile/help.sh`: fallback-gruppa «Anna» viser target
  utan kategori, og vert berre skriven ut når ho ikkje er tom
- `.claude/rules/make-conventions.md`: skildrar fallbacken, verifiseringssteget
  sjekkar «Anna»
- Verifisert: `make help` viser `print-domains`, `gource-preview` og
  `gource-video` under «Anna». Med berre `make/50-docs.mk` som input vert
  «Anna» ikkje skriven ut.
