# Rule: fulle nøklar i t-kall og skanning av katalogbruk

## Bakgrunn

Under `specs/done/modellanalyse-rapportar-per-sprak.md` hadde
`modellanalyse_render.py` først ein lokal hjelpefunksjon `t(key)` som tok
forkorta nøklar (`liknande.tittel`). Nøkkelskanninga i `i18n_strings.py` les
kvar `t("x.y")` i skanna `.py`-filer som ein full katalognøkkel, og ville ha
rapportert dei forkorta nøklane som manglande. Hjelpefunksjonen vart omdøypt
til `tr`. I `specs/done/engelsk-framside-genererte-tabellar.md` måtte
`generate-readme-tables.sh` leggjast til i `DEFAULT_SCAN_ROOTS` for at
`make i18n-check` skulle fange nøklane der. Brukaren bad om at dette vert lagt
inn som rule.

## Steg

1. Utvid § «Fleirspråkleg portal» i `.claude/rules/mkdocs-portal.md`.

## Handlingsliste

- [x] 1. Utvid `.claude/rules/mkdocs-portal.md`

## Avgjerder

- **`mkdocs-portal.md`, ikkje `i18n-omsetjing.md`:** regelen gjeld kode som
  hentar portaltekst (`mkdocs/**`), ikkje omsetjing. `i18n-omsetjing.md` lastar
  berre ved `*.en.md` og `mkdocs/lib/i18n/**`.
- **Skanningsrøtene er tekne med i same punkt:** same mekanisme (statisk
  nøkkelskanning), og det konkrete tilfellet med `generate-readme-tables.sh`.

## Utført

- `.claude/rules/mkdocs-portal.md`: to nye punkt: berre fulle nøklar i
  `t`-kall (hjelpefunksjonar med forkorta nøklar heiter noko anna), og nye
  katalogbrukarar utanfor `mkdocs/` vert lagde til i `DEFAULT_SCAN_ROOTS`.
