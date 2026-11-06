# Oppgrader linkml til 1.12.1

## Bakgrunn

Alle eigenbygde LinkML-bilete er pinna til `linkml==1.11.1`: `linkml-local` (`Dockerfile.linkml`) og
MCP-bileta (`Dockerfile.mcp-linkml`). Patchen `linkml_relative_import_patch.py` er gjort versjonsbevisst
og testa mot 1.12.1 (`specs/done/linkml-relative-import-patch-1-12.md`). Brukaren ber no om at linkml
vert pinna til 1.12.1 i begge bileta.

`linkml-local` køyrer alle generatorane, så oppgraderinga kan endre genererte artefakter. Endringane må
difor målast mot ein baseline.

## Steg

1. Bygg `linkml-local` og `mcp-linkml-validator` på nytt med 1.11.1 (`make build-docker-linkml`, `make build-docker-mcp-validator`), og generer alle domene (`make domain-<d>`) som baseline. Kopier `generated/` til scratchpad.
2. Pin `linkml==1.12.1` (og `linkml-runtime==1.12.1`) i `Dockerfile.linkml` og `Dockerfile.mcp-linkml`.
3. Bygg bileta på nytt. Stadfest versjonen og at `docgen-max-chars.patch` vert brukt.
4. Generer alle domene på nytt, og samanlikn med baseline. Klassifiser kvart avvik.
5. Køyr testane:
   - `make mcp-linkml-valider-modell-test`
   - `make test`
   - `make mcp-linkml-modell-utkast-test` (om det finst)
6. Oppdater referansar som skildrar dagens versjon (ikkje historiske reproduksjonsnotat i `bugs/`).
7. Sjekk om linter-standardkonfigurasjonen er endra i 1.12.1 (`policies/README.md` «Kartlagt mot LinkML 1.11.1», `.claude/rules/mcp-server-python.md`).

## Handlingsliste

- [x] Steg 1: baseline
- [x] Steg 2: pinning
- [x] Steg 3: ombygging
- [x] Steg 4: samanlikning av artefakter
- [x] Steg 5: testar
- [x] Steg 6: referansar
- [x] Steg 7: linter-konfig

## Funn

| Område | 1.11.1 → 1.12.1 | Vurdering |
|---|---|---|
| `gen-java` (`samt-bu`, `referansemodell`) | `cannot be mapped to a type` for `LangString`/`GYear`/`Duration`/`NonNegativeInteger` | **Regresjon**, BUG-25. Retta med `javagen-custom-typemap.patch`. Java-filer frå 1.11.1 er uendra bortsett frå `metamodel_version`. Java vert no òg generert for importerte klassar (t.d. 47 mot 18 filer for `samt-bu`). |
| JSON Schema (16 filer) | `additionalProperties` på rotnivå `true` → `false` | Strengare. `mcp-validate-instance` og `linkml-validate` går gjennom for alle eksempel. |
| JSON Schema/OpenAPI (2 filer) | valfrie enum-slots: `$ref` → `anyOf: [$ref, null]` | Mjukare (nullable), ufarleg |
| XSD (`samt-bu`) | 9 kunstige typar (`AnyValue`, `document_wrapper*`) er borte | Forbetring (følgje av `additionalProperties: false`) |
| OWL (`*-ontology.ttl`) | importerte slots får rett IRI i staden for `.../<skjema>/:<slot>` | Forbetring. Ugyldige `/:`-IRI-ar: 3728 → 1787 (resten finst frå før, ikkje dokumentert i `bugs/`). |
| `*-schema.ttl` | `exact_mappings` som `skos:exactMatch` (før `skos:mappingRelation`), `metamodel_version` | Forbetring |
| SHACL (20 filer) | berre blanke nodar og rekkjefølgje | Semantisk identisk (shape-sett, `ignoredProperties`, property-shapes og `sh:in` er samanlikna) |
| JSON-LD context (10 filer) | berre `generation_date` | Identisk |
| Protobuf (10 filer) | formatering (`syntax = "proto3";`, `package <navn>;`) | Ikkje vurdert semantisk i detalj |
| Docs (`.md`, 452 filer) | `from_schema` på *induserte* slots viser klassen sitt skjema, ikkje skjemaet der sloten er definert | Kosmetisk. Eigne script brukar berre `from_schema` på klassar/element. |
| `make test` | 487 OK / 41 feil på **både** 1.11.1 og 1.12.1 (identisk feilliste) | Ingen regresjon. Dei 41 feila finst frå før, sjå under. |
| Linter (`recommended.yaml`) | identisk. 2 nye reglar (`no_invalid_slot_group`, `no_undeclared_subsets`) er `disabled` i `default.yaml` | Ingen endring i lint-åtferd |
| `metadata/*-manifest.yaml` | endra av `make domain-*`, men like i begge versjonane | Uavhengig av versjonen. Rulla tilbake med `git restore`. |

**Eksisterande feil i `make test` (utanfor scope):**
- 36 «Fil manglar»-feil i Fase B for 9 ap-no-profilar der `build.yaml` slår av generatoren (`python`/`json_schema`/`jsonld_context`/`protobuf: false`).
- 5 `roundtrip-ttl`-feil (`fint-administrasjon`, `fint-okonomi`, `fint-personvern`, `fint-utdanning`, `samt-bu`: «No pred for …»), som ikkje har skip-vilkår.

**Funn under arbeidet:** `Dockerfile.linkml` pinna berre `linkml`, ikkje `linkml-runtime`. Ei nybygging før denne endringa gav difor linkml 1.11.1 med linkml-runtime 1.12.1. No er begge pinna eksakt.

## Avgjerder

- **Begge bileta vert oppgraderte (brukarval).** `linkml-local` og MCP-bileta skal ha same versjon, i tråd med at pinninga var lik før.
- **Baseline med rein 1.11.1.** `linkml-runtime==1.11.1` vart pinna mellombels for baseline-bygget, sidan `Dockerfile.linkml` elles gav blanda versjonar. Samanlikninga måler då berre oppgraderinga.
- **`linkml-runtime` vert òg pinna i `Dockerfile.linkml`.** Det var ikkje eksplisitt bede om, men utan pinning vert runtime-versjonen bestemt av pip ved byggetid. Det er same feilklasse som `specs/done/linkml-relative-import-patch-1-12.md`.
- **BUG-25 løyst med javagen-patch (brukarval)**, ikkje `typeof` i `common-ap-no` og ikkje ved å halde `linkml-local` på 1.11.1. Patchen nyttar same mekanisme som `docgen-max-chars.patch` og krev inga endring i modellen.
- **`xsd:nonNegativeInteger` → `Integer`, ikkje `String`.** 1.11.1 sin fallback ville gitt `String`. `Integer` er meir presis, og ingen Java-fil som fanst i 1.11.1, vert påverka.
- **Eksisterande feil i `make test` vert ikkje retta her.** Dei finst like på 1.11.1 og har ikkje med oppgraderinga å gjere. Rapporterte i «Funn».
- **Ugyldige `/:`-IRI-ar i OWL vert ikkje undersøkte vidare.** Dei finst frå før og er færre etter oppgraderinga. Rapporterte i «Funn».

## Utført

2026-11-06:
- `src/assets/containers/Dockerfile.linkml`: `linkml==1.12.1` og `linkml-runtime==1.12.1`, og nytt steg som brukar `javagen-custom-typemap.patch`.
- `src/assets/containers/Dockerfile.mcp-linkml`: `linkml==1.12.1` og `linkml-runtime==1.12.1` i `base-builder` og `distroless-builder`.
- `src/assets/containers/patches/javagen-custom-typemap.patch`: ny (BUG-25).
- `bugs/javagen-eigendefinerte-typar-utan-typeof.md`: ny, med MRE køyrt mot 1.11.1, 1.12.1 og 1.12.1 med patch.
- `BUGS.md`: BUG-25 i PoC-lista og indeksen, og merknad om versjon under «Upstream-status».
- Referansar til dagens versjon er oppdaterte:
  - `bugs/relativ-import-via-versjonslast-url.md`
  - `linkml_relative_import_patch.py` (docstring)
  - `policies/README.md` og `README.en.md` (stempla på nytt)
  - `.claude/rules/mcp-server-python.md`
  - `specs/backlog/vurdering-codegraph-kompatibilitet.md`

Verifisert på 1.12.1:
- Alle 8 domene med modellar går gjennom `make domain-*`.
- `make test` gir same resultat som 1.11.1 (487/41, identisk feilliste).
- `make mcp-linkml-valider-modell-test` gir 79/79 OK.
- `make translate-check` og `make translate-status` er grøne.
