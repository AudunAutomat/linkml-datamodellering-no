# Plan: åtvaring frå generatoren om subset som berre er refererte

## Bakgrunn

`generate_linkml` (`mcp-linkml-modell-utkast`) set `in_subset: [Obligatorisk]` /
`[Anbefalt]` på `slot_usage` for kvar eigenskap (`converter.py`, ca. linje
645-660, namn frå policyen sin `subsets.required_maps_to` /
`non_required_default`). Per bronze-policy vert subseta berre *refererte*, ikkje
definerte lokalt: dei skal komme frå importgrafen (`common-ap-no-schema.yaml`,
`subsets:` ca. linje 312).

Utkastet importerer berre `linkml:types`. Resultat for alle utkast frå
`json-schema`-input med minst éin eigenskap:

- MCP-svaret viser `warnings: []`, `lintIssues: []`, `dummyValidation.valid: true`
- `make lint` feilar med `Subset: Obligatorisk is not defined` /
  `Undefined subset references` (`check-import-duplicates`)

Oppdaga 2026-11-17 ved test av prefiks-fiksen
(`specs/done/fiks-generator-prefiks-kollisjon.md`): prefikset var greitt, men
`make lint` feila på subseta. Feilen er forventa etter designet, men stille i
MCP-svaret, same hol som i `.claude/rules/mcp-server-python.md` § «Generert
skjema skal verifiserast med `make lint`».

## Mål

Brukaren skal sjå i MCP-svaret, før `make lint`, at subseta er refererte men
ikkje definerte, og kva som må gjerast.

## Forslag (anbefalt)

1. I `convert`: samle alle subsetnamn generatoren set i `in_subset`
   (`req_subset`, `def_subset`). Er mengda ikkje tom og skjemaet ikkje har ein
   eigen `subsets:`-seksjon (generatoren definerer ingen), legg til **ei**
   åtvaring i `warnings`, t.d.:
   `Subseta 'Obligatorisk', 'Anbefalt' er refererte via in_subset, men ikkje
   definerte — importer ein AP-NO-profil (t.d. common-ap-no-schema) eller legg til
   subsets: før make lint passerer`
2. Éi åtvaring per kall (ikkje per slot), med subsetnamna frå policyen, ikkje
   hardkoda.
3. Ingen endring i generert YAML: bronze-policyen krev at subseta ikkje vert
   definerte lokalt (DRY, jf. `PRINCIPLES.md` § 3).
4. Dokumenter åtvaringa i `src/mcp-linkml-modell-utkast/README.md` (tabellen i
   «Konverteringsreglar» der `subsets` alt er omtala).

## Steg

1. Les `converter.py` rundt `req_subset`/`def_subset` (linje ~512) og stadene
   `in_subset` vert sett (~654-656); finn rett stad å samle namna.
2. Implementer åtvaringa.
3. Testar i `tests/test_mcp_linkml_generator.py`:
   - JSON Schema med eigenskapar gir ei åtvaring med begge subseta
   - `inputFormat: empty` / skjema utan eigenskapar gir ingen subset-åtvaring
   - åtvaringa kjem berre éin gong ved fleire klassar og eigenskapar
   - policy med andre subsetnamn gir dei namna i åtvaringa
4. Køyr `make mcp-linkml-modell-utkast-test` og
   `make mcp-linkml-modell-utkast-smoke`.
5. Restart MCP-serveren (`/mcp`), kall `generate_linkml` med eit JSON Schema og
   sjekk at `warnings` inneheld åtvaringa.
6. Sjekk om `tests/test-mcp-linkml-generator.json` (smoke) eller andre testar
   forventar `warnings: []` for slike input.

## Handlingsliste

- [x] Samle subsetnamn og legg til åtvaring i `converter.py`
- [x] Oppdater README for MCP-serveren
- [x] Nye testar i `tests/test_mcp_linkml_generator.py`
- [x] Køyr `make mcp-linkml-modell-utkast-test` og `-smoke`
- [x] Verifiser mot restarta MCP-server
- [x] Vurder om lærdommen krev endring i rula om generert skjema — nei, rula dekkjer alt (hol mellom generator og `make lint`)

## Opne spørsmål

- Skal åtvaringa òg vere ein `# TODO`-kommentar i YAML-hovudet (som for
  `begrepsidentifikator`), slik at ho følgjer fila og ikkje berre MCP-svaret?
- Alternativ til åtvaring: køyre `check-import-duplicates`-logikken i
  `validator.py` slik at `lintIssues` fangar det. Meir dekning (fangar òg
  andre importfeil), men tyngre og krev import av repo-logikk inn i
  MCP-containeren. Anbefaling: åtvaring no, vurder utviding som eigen spec.
- Alternativ: **importer eit AP-NO-skjema som standard** i utkastet, slik at
  subseta vert definerte. Vurdert og **ikkje** anbefalt som global standard:
  - `dcat-ap-no-schema` dreg inn rundt 17 DCAT-klassar som ikkje passar eit
    generisk JSON Schema.
  - `common-ap-no-schema` definerer `id` og `tittel`; generatoren lagar sin
    eigen `id`-slot på alle klassar. Det gir duplikatar i
    `check-import-duplicates` (same feilklasse som prefiks-kollisjonen og
    MC8-MC11 i `specs/done/avvik-modelldcat-ap-no.md`).
  - Importstien er relativ (`../ap-no/...`) og avheng av kvar utkastet vert
    plassert, som generatoren ikkje veit.
  - Importhierarkiet (`PRINCIPLES.md` § 3) seier at domenemodellar importerer
    ein AP-NO-profil, ikkje `common-ap-no-schema` direkte. `dcat-ap-no` ville
    berre vere ein omveg for å få subseta.
- Alternativ: **policy-styrt import**, som eigen oppfølgjar til åtvaringa. Nytt
  felt i `schema_defaults.imports` i policyen (t.d. ein silver-variant som
  legg til `common-ap-no-schema`), slik at importen er eit val per policy og
  ikkje ein global standard. Må løysast: (a) stien (relativ til ein antatt
  plassering, eller sett av `new-modell`-scaffolding som veit kvar fila
  hamnar) og (b) `id`-kollisjonen over (t.d. ved at generatoren droppar
  eigen `id`-slot når profilen vert importert). Dei to alternativa utelukkar
  ikkje kvarandre: åtvaringa dekkjer standardtilfellet, policy-import kan komme
  etterpå som eiga spec.

## Avgjerder

- Berre åtvaring i `warnings`; ingen `# TODO`-kommentar i YAML-hovudet og ingen utviding av `validator.py` (anbefalt i specen). Policy-import er eiga spec ved behov.
- Subsetnamna vert samla frå `slot_usage.in_subset` i dei ferdige klassane, ikkje frå policyen direkte, slik at åtvaringa berre nemner subset som faktisk er brukte.
- Tre eksisterande testar sjekka `warnings == []` for andre funksjonar; dei filtrerer no bort subset-åtvaringa via `_utan_subset_aatvaring` i staden for å endre forventinga.


## Utført

- `converter.py`: ei samla åtvaring i `warnings` om subset som er refererte men ikkje definerte
- `README.md` (MCP-serveren): åtvaringa dokumentert i `subsets`-raden
- `tests/test_mcp_linkml_generator.py`: tre nye testar + hjelpefunksjonen `_utan_subset_aatvaring` i tre eksisterande
- `make mcp-linkml-modell-utkast-test`: 62 passerte; `make mcp-linkml-modell-utkast-smoke`: OK
- Verifisert 2026-11-17 mot restarta MCP-server (`/mcp`): `generate_linkml` med JSON Schema gir éi åtvaring med 'Obligatorisk' og 'Anbefalt' i `warnings`
