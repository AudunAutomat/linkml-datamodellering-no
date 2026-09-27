# modell-utkast: navngjeving etter LinkML-konvensjon

## Bakgrunn

Etter at `mcp-linkml-modell-utkast` fekk eksplisitt linterkonfig
(`specs/done/linter-rule-og-bronze-oppfolging.md`) viste
`make mcp-linkml-modell-utkast-smoke` at generatoren sjølv lagar navn som bryt
`standard_naming`:

- Klassen `mitt_skjema`: `$defs`-nøklar og `schemaName` vert berre sanerte
  (bindestrek → understrek), ikkje gjort om til UpperCamelCase.
- Sloten `mitt-skjema_kontaktinformasjon`: prefikset er `schemaName` rått, med bindestrek.
- `nedlastingsURL`: JSON-property-navn vert brukte som slotnavn i camelCase.
  Tiltak 3 i `specs/done/forbedr-mcp-generate-linkml-output.md` bad om
  camelCase → snake_case, men det vart aldri innført.

Brukaren har valt snake_case med originalnavnet teke vare på i `aliases:`.

## Steg

1. Kartlegg alle stader klasse-, type-, enum- og slotnavn vert utleidde
   (jf. `.claude/rules/mcp-server-python.md`: sanering på *alle* utleiingsstader).
2. Innfør éin funksjon for klassenavn (UpperCamelCase, translitterert) og éin for
   slotnavn (snake_case, translitterert). Bruk dei på kvar utleiingsstad.
3. Legg originalnavnet i `aliases:` når eit JSON-property-navn vert endra.
   Åtvar dersom to ulike property-navn fell saman til same slot.
4. Oppdater/utvid testar. Verifiser med smoke (0 `standard_naming`-funn).

## Handlingsliste

- [x] H1: Kartlegging av utleiingsstader
- [x] H2: `_to_class_name` / `_to_slot_name` og bruk på alle stader
- [x] H3: `aliases` + kollisjonsåtvaring
- [x] H4: Testar og smoke

## Avgjerder

- **Slotnavn frå JSON-properties:** snake_case med originalnavnet i `aliases:`
  (brukaren sitt val). Alternativa var å behalde kjeldenavna (som
  `slot_naming: camel` for oreg) eller å styre det med ein parameter.
- **Éin funksjon per navnetype:** `_to_pascal_case` (klasser, typar, enum, `$ref`,
  allOf-foreldre, containerklasse) og `_to_snake_case` (slots, kontaktinformasjon-slot,
  containerattributt). `_sanitize_identifier` og `_sanitize_slot_name` er fjerna.
  Typar og enum får same UpperCamelCase som klasser, sidan dei deler `$defs`-nøkkelrommet
  og `$ref` peikar på alle tre.
- **Store bokstavar inne i eit ledd vert behaldne** (`p[0].upper() + p[1:]`, ikkje
  `capitalize()`), slik at `geografiskAdresse` → `GeografiskAdresse` og ikkje
  `Geografiskadresse`.
- **Slotnavn vert translittererte:** linterens snake-mønster (`[a-z][_a-z0-9]+`)
  avviser æ/ø/å, og klassenavna vart alt translittererte.
- **`slot_uri` brukar det nye snake_case-navnet:** prefikset er uansett ein placeholder
  som skal erstattast.
- **Aliasa vert sette etter slot-løkka:** då får både ny slot og slot som vert
  erstatta ved typekonflikt aliasa, utan at logikken må dublerast i begge greinene.
- **Roundtrip-testen speglar funksjonane:** normaliseringa i `test_roundtrip_json_schema()`
  (`tests/test_make.sh`) speglar `to_pascal`/`to_snake`, i staden for å importere
  `converter.py`, som krev pyyaml, og det finst ikkje på verten. To kopiar er under
  DRY-terskelen. Kommentaren i testen peikar på kjelda.

## Utført

- `src/mcp-linkml-modell-utkast/converter.py`: `_to_pascal_case`/`_to_snake_case` på alle
  utleiingsstader, `aliases` for endra property-navn, åtvaring ved samanfall og
  dedup av `slots`-lista.
- `src/mcp-linkml-modell-utkast/policies/bronze.yaml`: kommentarar oppdaterte.
- `src/mcp-linkml-modell-utkast/README.md`: navngjeving og linterkonfig skildra.
- `tests/test_mcp_linkml_generator.py`: ny `TestNavngjeving` (5 testar). 56/56 passerer.
- `tests/test_make.sh`: roundtrip-normalisering speglar ny navngjeving.
  `make roundtrip-json-schema` er OK for alle 7 filer i `src/tmp/`.
- Verifisert: `make mcp-linkml-modell-utkast-smoke` gjev `lintIssues: []` (før: 3
  `standard_naming`). Utkast frå `bvrinnfelles_lm_v1` og `virksomhetregisterinfoapi_lm_v1`
  gjev 0 lint-funn, med 52 og 70 alias, og ingen samanfall.
