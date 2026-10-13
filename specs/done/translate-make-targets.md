# Omdøyp i18n-make-targets til translate-*

## Bakgrunn

«i18n» er lite skildrande for brukarar som ikkje kjenner forkortinga. Brukaren
ønskjer å starte med brukarflata: make-targets og dokumentasjonen av dei får
engelske, sjølvforklarande navn. Interne filer, mapper, front-matter-nøkkelen
`i18n:`, `@@i18n:`-markørane og katalognøklane `i18n.*` står urørte inntil
vidare.

| Gammalt | Nytt |
|---|---|
| `make i18n-check` | `make translate-check` |
| `make i18n-status` | `make translate-status` |
| `make i18n-stamp` | `make translate-stamp` |

## Steg

1. Omdøyp targets, `print_header` og hjelpetekst i `make/50-docs.mk`.
2. Oppdater overskrifta i statusutskrifta i `mkdocs/lib/scripts/i18n_status.py`.
3. Oppdater referansar i `COMMANDS.md`, `mkdocs/README.md`, `.claude/rules/*.md`,
   `mkdocs/lib/utils/i18n.sh`, `tests/test_i18n_*.py` og `specs/backlog/TODO.md`.
4. Oppdater `mkdocs/docs/automasjon/fleirsprak.md` og den engelske omsetjinga,
   og stempla omsetjinga.
5. Grep etter gamle target-navn (utanom `specs/done/`) og verifiser med
   `make help`, `make translate-check` og `make translate-status`.

## Handlingsliste

- [x] Steg 1
- [x] Steg 2
- [x] Steg 3
- [x] Steg 4
- [x] Steg 5

## Avgjerder
- **Gamle navn utan alias.** `i18n-*` vert ikkje haldne som alias. Dei vart
  ikkje brukte i CI, og to navn på same target ville gjere brukarflata meir
  uklar.
- **Interne navn står urørte.** `.claude/rules/i18n-omsetjing.md`,
  `mkdocs/lib/i18n/`, `i18n_*.py`, `i18n.sh` og `make/50-docs.mk`-kommentarar
  som viser til filnavna står urørte, i tråd med avgrensinga til brukarflata.
- **`help.sh`-kategori utvida (utanfor opphavleg steg).** `i18n-*` var aldri
  synlege i `make help`, fordi `help.sh` berre les targetnavn som samsvarer med
  `[a-zA-Z_-]+` (sifferet i «i18n» stoppa dei). `translate-*` vart lesne inn,
  men vart stille borte fordi ingen kategori samsvara. Dei vart lagde til under
  «Dokumentasjonsportal» (`(docs-|translate-)`).
- **`README.en.md` omsett** i same økt (ny linje om uoffisielle modellar) og
  stempla.

## Utført

- `make/50-docs.mk`: `translate-check`, `translate-status`, `translate-stamp`
- `src/assets/scripts/makefile/help.sh`: `translate-*` under «Dokumentasjonsportal»
- `mkdocs/lib/scripts/i18n_status.py`: statusoverskrift `translate-status`
- `COMMANDS.md`, `mkdocs/README.md`, `.claude/rules/{i18n-omsetjing,jinja2-templates,mkdocs-portal}.md`,
  `mkdocs/lib/utils/i18n.sh`, `mkdocs/lib/i18n/strings.yaml` (kommentar),
  `tests/test_i18n_*.py`, `specs/backlog/TODO.md`: nye target-navn
- `mkdocs/docs/automasjon/fleirsprak{,.en}.md`: nye target-navn, `.en` stempla
- `README.en.md`: ny linje omsett og stempla
- Verifisert: `make translate-check` (26 testar OK), `make translate-status`
  (0 utdaterte), `make help`, grep utan gamle target-navn utanom `specs/done/`
