# Rule: saneringslogikken har ein kopi i roundtrip-testen

## Bakgrunn

Under `specs/done/modell-utkast-navngjeving.md` vart saneringa i
`mcp-linkml-modell-utkast/converter.py` endra til UpperCamelCase/snake_case.
JSON Schema-roundtrip-testen i `tests/test_make.sh` har ein eigen kopi av
normaliseringa (bindestrek → understrek), og han måtte oppdaterast for å ikkje
feile på alle 7 filene i `src/tmp/`. Rula om sanering på alle utleiingsstader
(`.claude/rules/mcp-server-python.md`) nemnde ikkje denne kopien.

## Steg

1. Utvid sanerings-seksjonen i `.claude/rules/mcp-server-python.md` med kopien i
   roundtrip-testen og verifiseringskommandoen.
2. Oppdater «éi delt saneringsfunksjon» til éin funksjon per navnetype.

## Handlingsliste

- [x] Seksjonen er utvida i `.claude/rules/mcp-server-python.md`

## Avgjerder

- **Utviding av eksisterande seksjon, ikkje ny rule-fil:** emnet er same feilklasse
  (sanering på alle stader). Rula lastast når `converter.py` vert endra, og det er
  nettopp då påminninga trengst, sjølv om `tests/test_make.sh` ligg utanfor
  `paths:`-scopet.

## Utført

- `.claude/rules/mcp-server-python.md`: nytt avsnitt om testkopien, og framgangsmåten
  namngjev `_to_pascal_case`/`_to_snake_case`.
