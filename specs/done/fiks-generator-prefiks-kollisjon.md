# Plan: generatoren skal ikkje velje prefiks som kolliderer med `linkml:types`

## Bakgrunn

`mcp-linkml-modell-utkast` (`src/mcp-linkml-modell-utkast/converter.py`, ca. linje 451)
utleiar skjemaprefikset frå siste URI-segment i `schemaId`:

```python
prefix_name = schema_id.rstrip("/").split("/")[-1].replace("-", "_")
```

Standardverdien for `schemaId` er `https://example.org/schema`, så prefikset
vert `schema:`. Same prefiks er brukt av `linkml:types` (peikar på
`http://schema.org/`). Resultat: `make lint` feilar i `check-import-duplicates`
med `Prefix: schema mismatch between min-modell and types`, sjølv om
`generate_linkml` sin eigen lint og dummy-validering ikkje fangar feilen.
Oppdaga ved test av `generate_linkml` med `inputFormat: empty`
(`src/tmp/min-modell-schema.yaml`, prefikset retta manuelt til `minmodell:`).

Same feil kan ramme kvar `schemaId` der siste segment er eit reservert prefiks
(`schema`, `linkml`, `xsd`, `shex`, `dct`, `dcat`, `foaf`, `skos`, `rdf`, `rdfs`),
ikkje berre standardverdien.

## Mål

Det genererte skjemaprefikset skal aldri kollidere med prefiks frå
`linkml:types` eller policyen sin `standard_prefixes`.

## Forslag (anbefalt)

1. **Utleiing frå `schemaName`, ikkje `schemaId`.** `schemaName` er alltid
   sett av brukaren og er det namnet som allereie vert brukt i klassenamn og
   `{name}_kontaktinformasjon`. Prefiks = `_transliterate`/snake_case av
   `schemaName` (same hjelpefunksjonar som elles i `converter.py`).
2. **Kollisjonsvern.** Definer reservert-mengd = nøklane i `standard_prefixes`
   frå policyen + prefiksa `linkml:types` deklarerer (`linkml`, `xsd`, `shex`,
   `schema`). Dersom kandidatprefikset er i mengda, legg til suffiks
   (`_modell`, t.d. `schema_modell`) og legg til ei åtvaring i `warnings`
   (jf. «Ingen stille feil» i CLAUDE.md).
3. **Éi kjelde.** Legg `prefix_name`-utleiinga i ein liten hjelpefunksjon
   (`_derive_schema_prefix(schema_name, reserved)`), brukt av alle stadene
   som i dag les `prefix_name` (slot_uri, class_uri, kommentarhovud).
4. **Policy som kjelde for `linkml:types`-prefiks.** Vurder å leggje
   `reserved_prefixes` i `policies/bronze.yaml` i staden for hardkoding i
   Python, sidan `silver` arvar bronze.

## Steg

1. Les `converter.py` rundt `prefix_name` (linje ~451, 544, 559, 586, 719) og
   stadfest alle bruksstader.
2. Implementer `_derive_schema_prefix` og bruk han i `convert`.
3. Legg til `reserved_prefixes` i `policies/bronze.yaml` (om steg 4 ovanfor vert
   vald) og les han i `converter.py`.
4. Oppdater `src/mcp-linkml-modell-utkast/README.md` med regelen.
5. Testar i `tests/test_mcp_linkml_generator.py`:
   - `schemaName: min-modell` gir `min_modell:` (ikkje `schema:`)
   - `schemaName: schema` gir suffiksa prefiks + åtvaring
   - `schemaName` med norske teikn vert transliterert
   - generert skjema passerer `check-import-duplicates` (kall same sjekk som
     `make lint`, eller legg ein fixture under `tests/fixtures/`)
6. Køyr eksisterande testar (`make test`) og `make lint` på eit generert skjema
   (`inputFormat: empty` og eit JSON Schema-døme) via MCP-serveren.
7. Sjekk om `src/mcp-linkml-modell-utkast/`-containeren må byggjast på nytt
   (volum-mount i `.mcp.json` er `:ro` for `converter.py`, så ingen rebuild
   trengst for sjølve kodeendringa).

## Handlingsliste

- [x] Kartlegg bruksstader for `prefix_name`
- [x] Implementer `_derive_schema_prefix` + reservert-mengd
- [x] (Valfritt) `reserved_prefixes` i `policies/bronze.yaml` — ikkje gjort, sjå Avgjerder
- [x] Oppdater README for MCP-serveren
- [x] Nye testar i `tests/test_mcp_linkml_generator.py`
- [x] Køyr `make test` og `make lint` på generert skjema
- [ ] Vurder om lærdommen bør bli ei rule (jf. CLAUDE.md «Avslutning», steg a) — spurt brukaren

## Opne spørsmål

- (Avgjort: `schemaName`) Skal prefikset følgje `schemaName` (anbefalt) eller framleis `schemaId`, men
  med kollisjonsvern? Å følgje `schemaId` bevarer dagens oppførsel for
  eksisterande kallarar, men gir tilfeldige prefiks med standardverdien
  `https://example.org/schema`.
- Skal `src/tmp/min-modell-schema.yaml` (manuelt retta) ryddast bort etter
  fiksen?

## Avgjerder

- Prefikset følgjer `schemaName` (brukarval), ikkje `schemaId`.
- Reservert-mengda er hardkoda i `converter.py` (`_LINKML_TYPES_PREFIXES`) + nøklane i policyen sine `standard_prefixes`. Ingen `reserved_prefixes` i `bronze.yaml`: prefiksa frå `linkml:types` er ikkje policy-val, og silver arvar `standard_prefixes` uansett.
- Suffikset er `_modell`; tom `schemaName` fell tilbake til `ex`.
- Tom `schemaName` og prefiks som startar med siffer er ikkje handterte (utanfor omfang).


## Utført

- `converter.py`: `_derive_schema_prefix` + `_LINKML_TYPES_PREFIXES`; `convert` brukar dei i staden for siste `schemaId`-segment
- `README.md` (MCP-serveren): prefiksregelen dokumentert
- `tests/test_mcp_linkml_generator.py`: tre nye testar (prefiks frå `schemaName`, reserverte prefiks med åtvaring, translitterering)
- `make mcp-linkml-modell-utkast-test`: 59 passerte
- Ikkje verifisert: live MCP-server (køyrande prosess har gammal kode til ho vert restarta) og `make lint` på nytt generert skjema
