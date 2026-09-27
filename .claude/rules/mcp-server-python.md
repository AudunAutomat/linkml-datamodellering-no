---
name: mcp-server-python
description: Kodepraksis for Python-kjeldekoden i dei tre MCP-serverane (JSON-RPC-feilhandtering, identifikatorsanering, namnekonvensjon, kjend DRY-gjeld i dispatch-boilerplate, eksplisitt LinkML-linterkonfig). Lastast automatisk ved arbeid med filer under src/mcp-*/.
paths:
  - "src/mcp-*/**"
---

## Sjekk `error` før du føreset `result` i eit JSON-RPC-svar

Alle tre MCP-serverane returnerer på feil eit korrekt JSON-RPC 2.0-svar
utan `result`-felt: `{"jsonrpc": "2.0", "id": ..., "error": {...}}`. Kode
som konsumerer eit slikt svar (bash-filter, Python-klient, test) og
ubetinga føreset at `result` finst — t.d. `r['result']['content'][0]['text']`
utan først å sjekke `r.get('error')` — kræsjar med ein kryptisk
`KeyError: 'result'` og gøymer den faktiske feilmeldinga frå brukaren.

**Fell aldri tilbake til** å indeksere rett inn i `result` utan først å
sjekke om `error` finst i responsen.

Rett mønster:

```python
r = json.loads(line)
if r.get("id") == expected_id:
    if "error" in r:
        print(r["error"]["message"], file=sys.stderr)
        sys.exit(1)
    print(r["result"]["content"][0]["text"])
```

Konkret hending: `src/mcp-linkml-validator/flatten-and-validate.bash`
kræsja slik og gøymde `Unknown CURIE prefix: https` (BUG-15) bak eit
uforklarleg `KeyError: 'result'`. Sjå
`specs/done/mcp-validator-feilvising-og-relativ-import-bug.md`.

## Sanering av utleidde identifikatorar må skje på *alle* utleiingsstader

Når ein converter/generator lagar nye LinkML-identifikatorar (klasse-,
slot-, type- eller enum-namn) frå ekstern input (t.d. `$defs`-nøklar i
JSON Schema), er det ikkje nok å sanere (translitterere, erstatte
bindestrek) på éin stad. Same namn vert ofte produsert fleire separate
stader i koden (t.d. når ein type både registrerast i eit oppslag *og*
refererast frå ein annan stad via `$ref`) — dersom saneringa berre er lagt
til éin av desse stadene, oppstår eit ugyldig LinkML/Python-identifikatornamn
akkurat der ho manglar.

**Fell aldri tilbake til** å anta at sanering av éin utleiingsstad (t.d.
slot-namn) dekker alle dei andre (type-namn, enum-namn, klassenamn,
referanseoppløysing).

Framgangsmåte: bruk **éi** delt saneringsfunksjon per navnetype (i
`converter.py`: `_to_pascal_case` for klasse-/type-/enumnavn og
`_to_snake_case` for slotnavn), og grep gjennom heile fila etter alle stader
eit namn hentast direkte frå kjeldedata (nøklar i eit `dict`,
`$ref`-oppløysing, fallback-namn, `schemaName`). Kall funksjonen på kvar
einaste ein, ikkje berre den mest opplagde.

**Saneringslogikken har ein kopi utanfor `src/mcp-*`.** JSON Schema-roundtrip-testen
(`test_roundtrip_json_schema()` i `tests/test_make.sh`) samanliknar originale og
genererte klasse-, property- og `$ref`-navn. Han normaliserer dei med funksjonane
`to_pascal`/`to_snake`, som speglar saneringa i `converter.py`. Testen importerer
ikkje `converter.py`, sidan han køyrer med python3 på verten utan pyyaml.
Endrar du saneringa, må du oppdatere kopien i same endring og køyre
`make roundtrip-json-schema JSONSCHEMA=<fil>` for alle filene i `src/tmp/`. Elles
feilar roundtrip-testen med «manglar properties»/«Manglar klasser» for navn som
berre er sanerte ulikt. Døme: overgangen til UpperCamelCase/snake_case i
`specs/done/modell-utkast-navngjeving.md`, der den gamle normaliseringa i testen
berre gjorde om bindestrek til understrek.

Konkret hending: `converter.py` i `mcp-linkml-modell-utkast` saniterte
slot-namn, men ikkje type-/enum-/klassenamn (fire separate stader:
`_collect_types()`, `_resolve_ref()`, `_collect_enums()`,
`_collect_classes()`). `E-postadresse` vart generert som eit ugyldig
Python-identifikatornamn, og `gen-python` feila. Sjå
`specs/done/mcp-generate-identifikator-sanitering.md`.

## Namnekonvensjon: `mcp-linkml-<funksjon>`

Nye MCP-server-mapper, Makefile-target og image-namn skal følgje det
etablerte mønsteret `mcp-linkml-<funksjon>` (t.d. `mcp-linkml-validator`,
`mcp-linkml-modell-utkast`, `mcp-linkml-begrep-utkast`) — ikkje
`mcp-<funksjon>` eller `mcp-linkml-<domene>-<funksjon>`. Hjelpetarget følgjer
`mcp-linkml-<funksjon>-<operasjon>` (t.d. `mcp-linkml-validate-smoke`). Sjå
`specs/done/mcp-server-namngjeving.md` og
`specs/done/mcp-target-navnekonvensjon.md` for grunngjeving og full
namneoppgraderingshistorikk.

## Kjend DRY-gjeld: JSON-RPC-dispatch-boilerplate er duplisert tre gonger

Alle tre `server.py`-filene implementerer **uavhengig av kvarandre** same
JSON-RPC 2.0-over-stdio-mekanikk: ein `send()`-hjelpefunksjon,
`initialize`/`initialized`/`tools/list`-handtering, `tools/call`-dispatch
med feilinnpakking, og ei `main()`-løkke som les linje for linje frå
`sys.stdin` med parse-feil-handtering. Dette er over CLAUDE.md sin eigen
DRY-terskel (3+ identiske tilfelle), men er **ikkje** konsolidert enno —
konsolideringa som alt er gjort
(`specs/done/konsolider-mcp-modell-utkast-jsonrpc.md`) gjaldt kallar-sida
(request-bygging i `src/assets/scripts/makefile/`), ikkje sjølve
dispatch-løkka inne i serverane.

**Ikkje** legg til ein fjerde uavhengig kopi av denne mekanikken. Dersom du
legg til ein ny MCP-server, eller gjer ei vesentleg endring i
dispatch-logikken til éin av dei tre eksisterande, konsolider
`send()`/`initialize`/`tools-list`/`main()`-løkka til eit delt modul (t.d.
`src/assets/scripts/utils/mcp_jsonrpc_stdio.py`, i tråd med korleis
`linkml_relative_import_patch.py` alt er delt på tvers av fleire
kallestader) — spør brukaren om godkjenning først, jf. CLAUDE.md sitt
DRY-avsnitt ("Omskriv aldri eksisterande kode... med DRY som einaste
grunngjeving utan å spørje brukaren om løyve først").

## Kall aldri LinkML-`Linter()` utan eksplisitt konfig

`linkml.linter.linter.Linter()` utan argument slår saman eit tomt konfig
med `default.yaml`. I LinkML 1.11.1 har *kvar* regel der `level: disabled`,
så `linter.lint(...)` returnerer då ingen lint-funn i det heile. Om
`validate_schema=True` er sett, køyrer berre metamodell-valideringa. Kallet
feilar ikkje og gjev ikkje noka åtvaring. Eit tomt resultat ser ut som
«skjemaet er reint», og feilen er difor stille. Standardverdiane er upstream sitt
val og kan endre seg mellom versjonar. `make lint` (CLI med
`--config src/assets/containers/.linkmllint.yaml`) er ikkje ramma. Difor kan same
skjema gje funn i `make lint` og ingen funn i MCP-serveren.

**Fell aldri tilbake til** `Linter()` eller `Linter({})`, heller ikkje
«berre for å få metamodell-validering».

Framgangsmåte:

1. Send alltid eit eksplisitt konfig med `extends: recommended` (eller eit
   anna namngjeve regelsett), og overstyr einskildreglar under `rules:`.
2. Hald konfigen éin stad per komponent. I `mcp-linkml-validator` er det
   `linter:`-seksjonen i policy-YAML-ane (arva og merga per regel av
   `_merge_policies()`, bygd av `_linter_config()` i `server.py`). I andre
   komponentar er det ein modulkonstant med kommentar om kvifor kvar regel er
   overstyrt.
3. Verifiser at konfigen faktisk slår inn. Køyr linteren på eit skjema med
   ein kjend regelbrot (t.d. eit camelCase-slotnavn for `standard_naming`, eller
   eit attributt med `range: string` utan `imports: linkml:types` for
   `no_undeclared_ranges`), og sjekk at funnet kjem.

Konkret hending: både `mcp-linkml-validator/server.py` og
`mcp-linkml-modell-utkast/validator.py` kalla `Linter()` utan konfig.
Validatoren sitt lint-steg gav difor aldri lint-funn. Då konfigen vart sett,
viste det seg at testfixturane mangla `imports: linkml:types` og hadde
udefinerte range-klassar, utan at nokon hadde merka det. Sjå
`specs/done/gjennomgang-bronze-policy-generisk.md` (B23) og
`specs/done/linter-rule-og-bronze-oppfolging.md`.
