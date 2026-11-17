# Rule: verifiser generert skjema med `make lint`

## Bakgrunn
Prefikset `schema:` frå `generate_linkml` passerte generatorens eigen validering,
men feila `make lint` (`check-import-duplicates`). Sjå `specs/done/fiks-generator-prefiks-kollisjon.md`.

## Steg / handlingsliste
- [x] Legg ny seksjon i `.claude/rules/mcp-server-python.md` (same scope `src/mcp-*/**`)

## Avgjerder
- Ny seksjon i eksisterande rule, ikkje ny fil: same `paths:`-scope som resten.

## Utført
- `.claude/rules/mcp-server-python.md`: ny seksjon om `make lint`-verifisering av generert skjema
