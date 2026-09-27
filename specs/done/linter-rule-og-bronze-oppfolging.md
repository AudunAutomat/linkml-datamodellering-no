# Linter-rule og oppfølging av bronze-gjennomgangen

## Bakgrunn

`specs/done/gjennomgang-bronze-policy-generisk.md` (B23) fann at
`linkml.linter.linter.Linter()` kalla utan konfig slår av **alle** lint-reglar
(LinkML 1.11.1 sin `default.yaml` har kvar regel `level: disabled`). Då
køyrer berre metamodell-valideringa (og berre om `validate_schema=True`).
Feilen var stille, sidan eit tomt resultat ser ut som «ingen problem». Same kall
finst i `src/mcp-linkml-modell-utkast/validator.py`. Specen lista i tillegg tre
oppfølgingspunkt som ikkje vart utførte.

## Steg

1. Legg til ei rule mot `Linter()` utan eksplisitt konfig (ny seksjon i
   `.claude/rules/mcp-server-python.md`, same scope som begge kallestadene).
2. Rett `Linter()`-kallet i `mcp-linkml-modell-utkast/validator.py`.
3. Rett skildringa av `referansemodell-bronze`, som framleis listar krav som no
   ligg i `basis-no`.
4. Byggj MCP-bileta på nytt, slik at policyane og koden som er bakte inn er oppdaterte.

## Handlingsliste

- [x] H1: Rule-seksjon i `.claude/rules/mcp-server-python.md`
- [x] H2: Eksplisitt linterkonfig i `modell-utkast/validator.py` + testkøyring
- [x] H3: `referansemodell-bronze` description (+ README-tabellrad)
- [x] H4: `make build-docker-mcp-validator` (+ modell-utkast-biletet) og røyktest

## Avgjerder

- **Rule som ny seksjon i `mcp-server-python.md`, ikkje eiga fil:** begge
  kallestadene ligg under `src/mcp-*/**`, som er scopet til den eksisterande rula.
  `batch-lint.py` sender alt konfig og treng ikkje dekkjast.
- **Ikkje-verifisert påstand fjerna frå rula:** første utkast hevda at eldre
  LinkML-versjonar gav `standard_naming`-funn frå `Linter()`. Kjelda
  (`specs/done/forbedr-mcp-generate-linkml-output.md`) viste seg å gjelde
  `linkml-lint`-CLI-en, så setninga vart bytt ut med det som er stadfesta.
- **modell-utkast-konfig som modulkonstant, ikkje delt med validatoren:** biletet
  inneheld ikkje validatoren sine policyfiler, og kopling mellom komponentane ville
  vore ny avhengigheit for to tilfelle (under DRY-terskelen). Konstanten speglar
  bronze, men har `recommended` påslått. For eit utkast er manglande description
  nyttig informasjon, og her finst ingen `required:`/`recommended:`-mekanisme som
  dublerer han.
- **Ingen manuell versjonsbump av `referansemodell-bronze`:** `release-please.yml`
  oppdaterer `version`/`endringsdato` i `*-schema.yaml` ut frå commit-typen. Ein
  `fix(referansemodell-bronze)`-commit gjev patch-bump. `metadata/*-manifest.yaml`
  og modellkatalogdata er CI-genererte og vart ikkje rørte. README-tabellraden vart
  oppdatert til same tekst som `generate-readme-tables.sh` ville gjeve.
- **Valideringslogg fjerna:** `make mcp-linkml-valider-modell` skreiv
  `validation/1.2.2/bronze.json` som bieffekt. Loggar per versjon vert laga ved
  release, så fila vart sletta.

## Utført

- `.claude/rules/mcp-server-python.md`: ny seksjon «Kall aldri LinkML-`Linter()`
  utan eksplisitt konfig», og `description` i frontmatter er utvida.
- `src/mcp-linkml-modell-utkast/validator.py`: `_LINTER_CONFIG` og
  `Linter(_LINTER_CONFIG)`. Verifisert: eit skjema med camelCase-attributt gav før
  0 lint-funn, no `standard_naming` og `recommended`. `make mcp-linkml-modell-utkast-test`:
  51/51.
- `referansemodell-bronze-schema.yaml` + `README.md`: skildringa speglar den nye
  bronze-policyen. `make lint` og `make mcp-linkml-valider-modell` (bronze) gjev 0 funn.
- Bilete bygde på nytt: `mcp-linkml-validator` og `mcp-linkml-modell-utkast`.
  Røyktestane er grøne, og policytestane gjev 67/67.

**Nye funn (ikkje retta):** med linteren aktiv viser `make mcp-linkml-modell-utkast-smoke`
at generatoren sjølv lagar navn som bryt konvensjonen: klassen `mitt_skjema`
(frå `schemaName` ved `inputFormat: empty`), sloten `mitt-skjema_kontaktinformasjon`
(bindestrek frå `schemaName`) og `nedlastingsURL` (camelCase frå JSON Schema).
Kandidat for eigen spec i `mcp-linkml-modell-utkast/converter.py`.
