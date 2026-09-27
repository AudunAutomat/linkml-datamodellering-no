# Rule: sjekk i18n-markørar i gen-doc-output før sandkassebygg

## Bakgrunn

Under steg 10 i `specs/done/omset-statiske-sider-engelsk.md` feila
`make docs-publish` i sandkassa for alle skjema. `generated/` i repoet hadde
gen-doc-output laga før i18n-markørane (`@@i18n:`) kom inn i malane (0 av 48
skjema hadde markørar). Bygget gjekk gjennom etter at `generated/` frå ein
tidlegare sandkasse (`box-s5-after`, 47 av 48 med markørar) vart brukt i staden.
Brukaren bad om at dette vert lagt inn i rula.

## Steg

1. Utvid sandkassemetoden i `.claude/rules/mkdocs-portal.md` med ein
   førehandssjekk for markørar i gen-doc-outputen.

## Handlingsliste

- [x] 1. Utvid `.claude/rules/mkdocs-portal.md`

## Avgjerder

- **Eksisterande rule:** lagt til i `mkdocs-portal.md` under sandkassemetoden
  (same scope, `mkdocs/**`), ikkje som ny fil.

## Utført

- `.claude/rules/mkdocs-portal.md`: nytt avsnitt om å sjekke `@@i18n`-markørar
  (`grep -L '@@i18n' generated/*/*/docs/index.md`) før sandkassebygg.
