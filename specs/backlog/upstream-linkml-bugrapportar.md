# Verifisering av kjende bugs og upstream-klare LinkML-bugrapportar

## Bakgrunn

`bugs/` og `BUGS.md` dokumenterer 24 kjende feil. 13 av dei har rotårsak i
`linkml`/`linkml-runtime`. Fleire av dei er merkte «bør meldast upstream», men
ingen er melde. Bug-filene er skrivne for internt bruk (nynorsk, repo-spesifikke
stiar og skjema) og kan ikkje nyttast direkte som upstream-issues.

Målet er å (1) verifisere at kvar dokumentert bug framleis er relevant, og (2)
skrive upstream-klare rapportar (engelsk, minimal sjølvstendig reproduksjon,
forventa/faktisk åtferd, versjon, rotårsak og framlegg til fiks) for dei
LinkML-relaterte feila som framleis gjeld.

## Steg

1. Kartlegg alle bugs i `BUGS.md` og kategoriser: LinkML-relatert / anna eksternt / internt.
2. Stadfest gjeldande `linkml`/`linkml-runtime`-versjon i containeren og siste utgjevne versjon på PyPI.
3. Verifiser at `løyst`-bugs framleis er løyste (workaround/fiks er på plass).
4. Lag minimal, sjølvstendig reproduksjon (MRE) for kvar LinkML-bug og køyr i `linkml-local`.
5. Sjekk om rotårsaka framleis finst i `linkml/linkml` `main` (upstream-kjeldekode).
6. Søk etter eksisterande upstream-issues for kvar bug.
7. Skriv upstream-klare rapportar (engelsk) for bugs som framleis gjeld.
8. Oppsummer tilrådingar (meld / ikkje meld / oppdater bug-fil).

## Handlingsliste

- [x] Steg 1 — sjå § Verifiseringsmatrise
- [x] Steg 2 — `linkml`/`linkml-runtime` 1.11.1 i `linkml-local`; 1.11.1 er òg siste PyPI-release (2026-05-20)
- [x] Steg 3 — alle 8 `løyst`-bugs er framleis løyste (BUG-16 er forelda: scriptet er fjerna)
- [x] Steg 4 — MRE-ar laga og køyrde mot tre image (sjå § Testoppsett)
- [x] Steg 5 — køyrt mot `main @ 5ef7622e` (2026-09-25)
- [x] Steg 6 — sjå § Eksisterande upstream-issues
- [x] Steg 7 — sjå § Upstream-rapportar (U1-U8)
- [x] Steg 8 — sjå § Tilrådingar
- [ ] Meld U1-U8 upstream (brukaren gjer dette sjølv, sjå § Tilrådingar)
- [x] Oppdater `bugs/*.md` og `BUGS.md` med korrigerte rotårsaker og issue-lenkjer (2026-09-26, sjå § Avgjerder)
- [ ] Fjern forelda `convert-instance-rdf`-skip for NGR i `tests/test_make.sh` og lychee-eksklusjonen for BUG-20 (krev verifisering med `make test`/CI)

## Testoppsett

| Image | Innhald | Bruk |
|---|---|---|
| `localhost/linkml-local:latest` | `linkml==1.11.1` + lokal `docgen-max-chars.patch` | Repoets eige image — verifisering mot ekte skjema |
| `localhost/linkml-vanilla:1.11.1` | `python:3.12-slim` + `pip install linkml==1.11.1`, ingen patchar | Upstream-MRE-ar mot siste release |
| `localhost/linkml-main:5ef7622e` | `linkml`/`linkml-runtime` frå `linkml/linkml@5ef7622e` (monorepo, `packages/*`) | Sjekk om feilen framleis finst på `main` |

MRE-filene ligg i scratchpad (ikkje committa); alle naudsynte YAML-filer og
kommandoar er gjengjevne i kvar upstream-rapport under, slik at rapporten er
sjølvstendig.

**Viktig:** `linkml/linkml-runtime` er **arkivert**. Runtime ligg no i
monorepoet `linkml/linkml` under `packages/linkml_runtime/`. Alle issues —
også runtime-feil — skal meldast i
[linkml/linkml](https://github.com/linkml/linkml/issues). Bug-filene
BUG-15 og BUG-24 peika til det arkiverte repoet; retta 2026-09-26.

## Verifiseringsmatrise

| ID | Komponent | Status i `BUGS.md` | Reprodusert i repo | 1.11.1 (vanilla) | `main` 5ef7622e | Konklusjon |
|---|---|---|---|---|---|---|
| BUG-1 | linkml-runtime | `upstream` | Ja | Ja | Ja | **Framleis relevant — men feil rotårsak dokumentert.** Den faktiske krasjen skuldast delt `slot_uri` (→ U1). LangString-problemet finst òg, men er ein separat feil (→ U5) |
| BUG-2 | linkml-runtime | `upstream` | Ja (roundtrip-ttl) | Ja | Ja | **Framleis relevant — feil rotårsak dokumentert.** Same rotårsak som BUG-1: `adressekode_ref` og `har_adressekode` deler `ngr:harAdressekode` (→ U1). `inlined_as_list` + `identifier` er ikkje årsaka. Stub-objekt-delen (`test_convert_rdf`) reproduserer **ikkje** lenger: YAML→TTL går for alle tre NGR-skjema |
| BUG-3 | linkml-runtime | `open` | Ja | Ja | Ja | **Framleis relevant — rotårsak funnen.** Container-attributt med same navn som ein global slot med anna `slot_uri` (→ U2) |
| BUG-4 | Makefile | `løyst` | — | — | — | Framleis løyst |
| BUG-5 | mcp-linkml-validator | `løyst` | — | — | — | Framleis løyst (`walk()` handterer lister) |
| BUG-6 | linkml | `workaround` | Ja (MRE) | Ja | Ja | **Framleis relevant** (→ U6). `main` (`679eba10`) slår no saman *strukturelt identiske* klasser, men ikkje-identisk redeklarering krasjar framleis/vert stilt erstatta |
| BUG-7 | linkml | `workaround` | Ja (MRE) | Ja | **Nei** | **Fiksa på `main`** (`679eba10`, 2026-06-10), ikkje utgjeven. Ikkje meld |
| BUG-8 | linkml-runtime | `open` | Ja (MRE) | Ja | Ja | **Ikkje ein upstream-bug.** LinkML krev ein `designates_type`-slot for polymorfi. Med global slot `designates_type: true` + `range: uriorcurie` går full YAML→TTL→YAML-roundtrip. Relaterte, allereie melde feil: #2107, #2399, #3663, #2506 |
| BUG-9 | avrotize | `upstream` | Ikkje re-verifisert | — | — | Utanfor LinkML-scope; ikkje re-verifisert i denne runden |
| BUG-10 | make | `løyst` | — | — | — | Framleis løyst (`< /dev/null` på plass) |
| BUG-11 | make | `løyst` | — | — | — | Framleis løyst (`<modell>-manifest.yaml`) |
| BUG-12 | make | `løyst` | — | — | — | Framleis løyst (felles `validation_log.py`) |
| BUG-13 | linkml (docgen) | `upstream` | Ja (fersk `make gen-schema-docs`) | Ja | Ja | **Framleis relevant** (→ U7). Krev `--no-mergeimports --no-render-imports --diagram-type mermaid_class_diagram` |
| BUG-14 | mermaid | `open` | Ikkje re-verifisert | — | — | Mermaid-avgrensing, ikkje LinkML |
| BUG-15 | linkml-runtime | `workaround` | Ja (MRE) | Ja | **Nei** | **Fiksa på `main`** (#3855, `9cf563ce`, 2026-09-24), ikkje utgjeven. Ikkje meld |
| BUG-16 | script | `løyst` | — | — | — | Forelda — `update-modellkatalog.py` er fjerna |
| BUG-17 | linkml | `workaround` | Ja (MRE) | Ja | Ja (URL-import) | **Framleis relevant for URL-importar** (→ U8). Lokal-import-varianten er fiksa på `main` (#3641, `b07ae874`) |
| BUG-18 | linkml-runtime | `workaround` | Ja (MRE) | Ja | Ja | **Framleis relevant**, men låg alvorsgrad — begge formene er gyldige `uriorcurie` (→ U4, valfri) |
| BUG-19 | linkml-runtime | `open` | Ja | Ja | Ja | **Framleis relevant — rotårsak funnen.** Gjeld berre eigendefinert type `uri: xsd:dateTime` + `base: str`; innebygd `datetime` roundtrippar korrekt (→ U3) |
| BUG-20 | linkml (docgen) | `open` | **Nei** | **Nei** | **Nei** | **Ikkje reproduserbar.** Fersk `make gen-schema-docs` bevarer backticks. Diagnosen var basert på forelda `generated/`-output (frå før backtickane vart lagde til i `7e1a2ac7`, 2026-08-16). Tilrådd lukka |
| BUG-21 | make | `løyst` | Sjå merknad | — | — | Løyst for `date +%s%3N`, men sjå sidefunn under (negativ tid) |
| BUG-22 | CI | `løyst` | — | — | — | Framleis løyst (`ref: ${{ steps.config.outputs.version }}`) |
| BUG-23 | mkdocs | `open` | Ja | — | — | Framleis relevant — `javazonetalk`, `brreg-felles-*` m.fl. manglar release-please-komponent og taggar |
| BUG-24 | linkml-runtime | `upstream` | Ja (MRE) | Ja | Ja | **Framleis relevant, allereie meldt**: #3896 og #3933 (begge opne). Ikkje meld på nytt. Utløysaren er import-navn med `:` (URL eller ikkje-`linkml:` CURIE) — ikkje «alle importar» slik bug-fila hevdar |

### Sidefunn

- **Negativ elapsed-tid:** `make gen-schema-docs` logga `→ erdiagram ap-no/dcat-ap-no (-1.88s)`. Tyder på at tidtakinga for dette steget ikkje brukar den monotone klokka frå BUG-21-fiksen. Ikkje gransa vidare.
- **Forelda skip i `tests/test_make.sh`:** `convert_rdf_job()` (linje ~112-116) og `test_convert_rdf()` (linje ~1366) hoppar over `ngr-adresse`/`ngr-eiendom`/`ngr-virksomhet` med grunngjeving BUG-2, men YAML→TTL fungerer no for alle tre. `roundtrip_ttl_job()`-skippen for NGR er framleis naudsynt (U1).

## Eksisterande upstream-issues

| Vårt funn | Upstream | Tilråding |
|---|---|---|
| BUG-24 namespaces-cache | [#3896](https://github.com/linkml/linkml/issues/3896), [#3933](https://github.com/linkml/linkml/issues/3933) (opne) | Ikkje meld. Eventuelt 👍 / kommentar med vår MRE (URL-import) |
| BUG-7 identiske duplikat-slots | Fiksa i `679eba10` (etter 1.11.1) | Vent på release, fjern workaround-regel |
| BUG-15 relativ import i URL-skjema | Fiksa i [#3855](https://github.com/linkml/linkml/pull/3855) (`9cf563ce`) | Vent på release, fjern `linkml_relative_import_patch.py`-greina |
| BUG-17 lokal import | Fiksa i [#3641](https://github.com/linkml/linkml/pull/3641) (`b07ae874`) | URL-varianten står att → U8 |
| BUG-8 type-designator som attributt | [#2107](https://github.com/linkml/linkml/issues/2107), [#2399](https://github.com/linkml/linkml/issues/2399), [#3663](https://github.com/linkml/linkml/issues/3663) | Ikkje meld; bruk global designator-slot |
| BUG-8 designator med `range: string` i `rdflib_loader` (`KeyError: 'Association'`) | Nært [#2506](https://github.com/linkml/linkml/issues/2506) | Kommenter på #2506 med `range: string`-varianten i staden for nytt issue |
| BUG-1b LangString | Relatert: [#3548](https://github.com/linkml/linkml/issues/3548) (ingen språktagg-mekanisme) | Meld U5 som eige issue med referanse til #3548 |
| BUG-6 klasse-redeklarering | [#417](https://github.com/linkml/linkml/issues/417) (lukka 2023 — union-semantikk avvist) | Meld U6 om **inkonsistensen** mellom generatorar, ikkje om union |

Ingen treff for U1, U2, U3, U4, U7 og U8 (søk på `rdflib_loader`, `RDFLibLoader`,
`No pred for`, `MappingError`, `slot_uri`, `link_mermaid`, `context.jsonld`,
`datetime` m.fl., 2026-09-26).

## Upstream-rapportar

Prioritert rekkjefølgje (størst verknad for oss først): U1, U2, U3, U7, U8, U6, U5, U4.

Felles miljølinje for alle rapportane:

> **Environment:** linkml 1.11.1 / linkml-runtime 1.11.1 (PyPI, `python:3.12-slim`), and re-verified on `linkml/linkml` main @ `5ef7622e` (2026-09-25).

---

### U1 — `RDFLibLoader` maps a predicate to the wrong slot when several slots share the same `slot_uri`

*Dekkjer BUG-1 og BUG-2 (roundtrip-ttl-skippa for 7 modellkatalog-/begrepskatalog-skjema og 3 NGR-skjema).*

**Title:** `rdflib_loader`: predicate→slot lookup ignores the subject's class when two slots share a `slot_uri` (TypeError: unexpected keyword argument)

**Description**

When two different slots in a schema have the same `slot_uri` (common when
reusing vocabulary terms such as `dct:title` or `skos:prefLabel` with
different ranges on different classes), loading RDF with `RDFLibLoader` fails.
The loader picks one global slot per predicate, regardless of which slots the
subject's class actually has, and then passes that slot name to the class
constructor.

**Schema** (`schema.yaml`)

```yaml
id: https://example.org/b01
name: b01
prefixes:
  linkml: https://w3id.org/linkml/
  ex: https://example.org/b01/
  dct: http://purl.org/dc/terms/
default_prefix: ex
imports: [linkml:types]
slots:
  id:
    identifier: true
    range: uriorcurie
  title:
    slot_uri: dct:title
    range: string
  title_literal:            # second slot mapped to the same predicate
    slot_uri: dct:title
    range: string
classes:
  Catalog:
    tree_root: true
    slots: [id, title]
  Dataset:                  # unrelated class that uses the other slot
    slots: [id, title_literal]
```

**Data** (`data.yaml`)

```yaml
id: ex:cat1
title: My catalog
```

**Steps**

```sh
linkml-convert -s schema.yaml -o out.ttl data.yaml     # OK
linkml-convert -s schema.yaml -o back.yaml out.ttl     # fails
```

**Expected:** `back.yaml` equals `data.yaml`.

**Actual:**

```
TypeError: Catalog.__init__() got an unexpected keyword argument 'title_literal'
```

**Root cause**

`packages/linkml_runtime/src/linkml_runtime/loaders/rdflib_loader.py:99`:

```python
uri_to_slot = {URIRef(schemaview.get_uri(s, expand=True)): s for s in schemaview.all_slots().values()}
```

The dict is keyed by URI only, so the last slot with a given URI wins
globally. The subsequent `schemaview.induced_slot(uri_to_slot[p].name, subject_class)`
(line ~137) does not check that the slot belongs to `subject_class`.

**Suggested fix:** resolve the predicate per subject class, e.g. build
`{uri: [slots...]}` and choose the slot among
`schemaview.class_induced_slots(subject_class)` whose (induced) URI matches
`p`; fall back to the global map only if the class has no match.

---

### U2 — `RDFLibLoader` raises `MappingError` when an attribute has the same name as a global slot with a different `slot_uri`

*Dekkjer BUG-3 (`fint-administrasjon`, `fint-okonomi`, `fint-personvern`, `fint-utdanning`, `samt-bu`).*

**Title:** `rdflib_loader`: "No pred for …" when a class attribute shadows a global slot of the same name

**Description**

A class attribute with the same name as a schema-level slot is serialised by
`RDFLibDumper` using the attribute's own (induced) URI, but `RDFLibLoader`
builds its predicate map from `SchemaView.all_slots()`, where the global slot
wins for that name. The attribute's URI is therefore unknown to the loader,
and a YAML→TTL→YAML round-trip fails.

**Schema** (`schema.yaml`)

```yaml
id: https://example.org/b03
name: b03
prefixes:
  linkml: https://w3id.org/linkml/
  ex: https://example.org/b03/
  other: https://example.org/other/
default_prefix: ex
default_range: string
imports: [linkml:types]
slots:
  id:
    identifier: true
    range: uriorcurie
  items:
    slot_uri: other:items     # global slot with explicit slot_uri
    range: Item
    multivalued: true
classes:
  Item:
    slots: [id]
  Container:
    tree_root: true
    attributes:
      items:                  # attribute with the SAME name as the global slot
        range: Item
        multivalued: true
        inlined_as_list: true
```

**Data** (`data.yaml`)

```yaml
items:
  - id: ex:item1
```

**Steps**

```sh
linkml-convert -s schema.yaml -o out.ttl data.yaml     # emits ex:items
linkml-convert -s schema.yaml -o back.yaml out.ttl     # fails
```

**Expected:** round-trip succeeds (the dumper and loader agree on the predicate).

**Actual:**

```
linkml_runtime.MappingError: No pred for https://example.org/b03/items <class 'rdflib.term.URIRef'>
```

Diagnostics:

```python
sv.get_uri(sv.all_slots()['items'], expand=True)          # https://example.org/other/items
sv.get_uri(sv.induced_slot('items', 'Container'), expand=True)  # https://example.org/b03/items
```

**Root cause:** same line as U1 (`rdflib_loader.py:99`): `all_slots()` is
name-keyed, so the attribute definition is not represented in `uri_to_slot`.
The dumper, by contrast, uses `induced_slot(name, class)`.

**Suggested fix:** build the predicate map from the induced slots of each
class (or look up per subject class as in U1) so the loader uses the same URI
resolution as the dumper. U1 and U2 can likely be fixed together.

---

### U3 — `RDFLibLoader` loses the lexical form of typed literals for custom types with `base: str`

*Dekkjer BUG-19 (`enhetsregisteret-bvrinnfelles`, `enhetsregisteret-bvrfriv`).*

**Title:** `rdflib_loader`: `xsd:dateTime` literal becomes `"2024-01-01 10:30:00"` (space instead of `T`) for a custom type with `base: str`

**Description**

For a custom type that maps to `xsd:dateTime` in RDF but is a plain string
in Python (`base: str`), the loader converts the literal via
`Literal.value` (a `datetime.datetime`) and the value is later stringified
with `str()`, producing `2024-01-01 10:30:00` instead of the original lexical
form `2024-01-01T10:30:00`. The built-in `datetime` type round-trips correctly;
only custom `str`-based types are affected.

**Schema** (`schema.yaml`)

```yaml
id: https://example.org/b19
name: b19
prefixes:
  linkml: https://w3id.org/linkml/
  ex: https://example.org/b19/
  xsd: http://www.w3.org/2001/XMLSchema#
default_prefix: ex
imports: [linkml:types]
types:
  DateTimeString:          # xsd:dateTime in RDF, plain str in Python
    uri: xsd:dateTime
    base: str
classes:
  Event:
    tree_root: true
    attributes:
      id:
        identifier: true
        range: uriorcurie
      timestamp:
        range: DateTimeString
```

**Data** (`data.yaml`)

```yaml
id: ex:e1
timestamp: "2024-01-01T10:30:00"
```

**Steps**

```sh
linkml-convert -s schema.yaml -o out.ttl data.yaml
# out.ttl: ex:timestamp "2024-01-01T10:30:00"^^xsd:dateTime   (correct)
linkml-convert -s schema.yaml -o back.yaml out.ttl
```

**Expected:** `timestamp: '2024-01-01T10:30:00'`

**Actual:** `timestamp: '2024-01-01 10:30:00'`

**Root cause:** `rdflib_loader.py:148` — `v = o.value`. For XSD-typed
literals rdflib returns a native Python object; when the slot's type has
`base: str`, the lexical form should be used.

**Suggested fix:** when the induced range type's `base` is `str` (or,
more generally, when the Python target type is `str`), use `str(o)`
(the lexical form) instead of `o.value`.

---

### U4 — (valfri, låg prioritet) Full-URI identifier in the schema's own namespace comes back as a CURIE after TTL round-trip

*Dekkjer BUG-18. Upstream kan rimeleg svare «working as intended», sidan begge formene er gyldige `uriorcurie`. Meld som spørsmål/forbetring, ikkje bug.*

**Title:** `rdflib_loader`: `uriorcurie` identifier written as a full URI is returned as a CURIE after YAML→TTL→YAML

**Schema**

```yaml
id: https://example.org/b18
name: b18
prefixes:
  linkml: https://w3id.org/linkml/
  ex: https://example.org/b18/
default_prefix: ex
imports: [linkml:types]
classes:
  Thing:
    attributes:
      id:
        identifier: true
        range: uriorcurie
  Container:
    tree_root: true
    attributes:
      things:
        range: Thing
        multivalued: true
        inlined_as_list: true
```

**Data**

```yaml
things:
  - id: https://example.org/b18/thing1
```

**Expected:** `id: https://example.org/b18/thing1`
**Actual:** `id: ex:thing1`

**Root cause:** `_uri_to_id()` / `namespaces.curie_for()` always contracts
when a prefix matches. Round-trip tests that compare JSON output therefore
fail even though the data is semantically identical.

**Suggestion:** an option on the loader (e.g. `contract_uris=False`), or
documenting that round-trip equality is only guaranteed modulo CURIE
contraction.

---

### U5 — Custom `rdf:langString` type: dumper emits ill-formed literal, loader silently drops the value

*Dekkjer den opphavlege BUG-1-skildringa (LangString-verdiar forsvinn). Relatert til #3548.*

**Title:** Type with `uri: rdf:langString` produces `"x"^^rdf:langString` (ill-formed RDF) and the value is silently dropped on load

**Description**

LinkML has no native language-tagged string (see #3548), so schemas
commonly declare a type with `uri: rdf:langString`. `RDFLibDumper` then
emits a literal with datatype `rdf:langString` and **no** language tag, which
is ill-formed in RDF 1.1 (a `rdf:langString` literal must have a language
tag). On load, the value is silently dropped — no error or warning — so data
is lost.

**Schema**

```yaml
id: https://example.org/b01a
name: b01a
prefixes:
  linkml: https://w3id.org/linkml/
  ex: https://example.org/b01a/
  rdf: http://www.w3.org/1999/02/22-rdf-syntax-ns#
  dct: http://purl.org/dc/terms/
default_prefix: ex
imports: [linkml:types]
types:
  LangString:
    uri: rdf:langString
    base: str
classes:
  Catalog:
    tree_root: true
    attributes:
      id:
        identifier: true
        range: uriorcurie
      title:
        slot_uri: dct:title
        range: LangString
        multivalued: true
```

**Data**

```yaml
id: ex:cat1
title:
  - My catalog
```

**Actual**

```turtle
ex:cat1 a ex:Catalog ;
    dct:title "My catalog"^^rdf:langString .
```

…and loading that TTL returns `id: ex:cat1` with `title` missing.

**Expected (minimum):** the loader should not silently drop data — either
keep the lexical value or raise/warn. **Ideally:** the dumper should not emit
`^^rdf:langString` without a language tag (emit a plain literal, or fail
with a clear error).

**Root cause:** `rdflib_dumper.py:~114` uses `Literal(element, datatype=...)`
for any type URI; `rdflib_loader.py:148` uses `o.value`, which is `None` for
the ill-formed literal, and `None` values are later filtered out.

---

### U6 — Redeclaring an imported class: SchemaLoader-based generators raise, SchemaView-based generators silently replace the class

*Dekkjer BUG-6. #417 avviste union-semantikk; dette issuet gjeld **inkonsistensen** og den stille dataforringinga.*

**Title:** Inconsistent handling of a class redeclared in an importing schema: `gen-python`/`gen-rdf`/`gen-jsonld-context` raise, `gen-json-schema`/`gen-shacl`/`gen-owl` silently drop the imported slots

**base.yaml**

```yaml
id: https://example.org/b06/base
name: base
prefixes: {linkml: https://w3id.org/linkml/, ex: https://example.org/b06/}
default_prefix: ex
default_range: string
imports: [linkml:types]
slots:
  id: {identifier: true, range: uriorcurie}
  title: {}
classes:
  Standard:
    slots: [id, title]
```

**schema.yaml**

```yaml
id: https://example.org/b06/main
name: main
prefixes: {linkml: https://w3id.org/linkml/, ex: https://example.org/b06/}
default_prefix: ex
default_range: string
imports: [linkml:types, base]
slots:
  extra: {}
classes:
  Standard:            # re-declared to "add" a slot
    slots: [extra]
```

**Actual**

| Generator | Result |
|---|---|
| `gen-python`, `gen-rdf`, `gen-jsonld-context` | `ValueError: Conflicting URIs (https://example.org/b06/base, https://example.org/b06/main) for item: Standard` |
| `gen-pydantic`, `gen-json-schema`, `gen-shacl`, `gen-owl` | exit 0; `Standard` has only `extra` — `id` and `title` are silently lost (JSON Schema `$defs.Standard.properties == ["extra"]`) |

Also reproduced on main @ `5ef7622e` (commit `679eba10` only merges
*structurally identical* duplicates).

**Expected:** consistent behaviour across generators. Either (a) a clear,
early error in all generators (and ideally in `linkml lint`), or (b) the same
documented override semantics everywhere. Silent loss of the identifier slot
is the worst outcome: downstream validation then rejects valid data and
references to `Standard` are treated as inlined objects.

---

### U7 — `gen-doc` mermaid class diagrams: `link_mermaid()` prefixes `../` to absolute URLs of imported `linkml:types`

*Dekkjer BUG-13.*

**Title:** `DocGenerator.link_mermaid()` produces `click Uri href "../http://www.w3.org/2001/XMLSchema#anyURI/"` with `--no-render-imports`

**Schema**

```yaml
id: https://example.org/b13
name: b13
prefixes: {linkml: https://w3id.org/linkml/, ex: https://example.org/b13/}
default_prefix: ex
imports: [linkml:types]
classes:
  Person:
    attributes:
      homepage: {range: uri}
      name: {range: string}
```

**Steps**

```sh
gen-doc --no-mergeimports --no-render-imports --diagram-type mermaid_class_diagram -d docs schema.yaml
grep click docs/Person.md
```

**Actual**

```
click Person href "../Person/"
click Uri href "../http://www.w3.org/2001/XMLSchema#anyURI/"
click String href "../http://www.w3.org/2001/XMLSchema#string/"
```

**Expected:** type ranges are either not drawn as related boxes (as with
render-imports), or linked with the absolute URL unchanged:
`click Uri href "http://www.w3.org/2001/XMLSchema#anyURI"`.

**Root cause (two parts)**

1. `class_diagram.md.jinja2` filters type ranges with
   `s.range not in gen.all_type_object_names()`, but
   `all_type_objects()` (`docgen.py:~851`) uses `imports=self.render_imports`,
   so with `--no-render-imports` imported `linkml:types` are not in the list and
   are drawn as related classes.
2. `link_mermaid()` (`docgen.py:458-471`) unconditionally returns
   `f"../{link}/"`, even when `link()` returned an absolute URL for an external
   type (`_is_external()`).

**Suggested fix:** in `link_mermaid()`, return absolute URLs unchanged
(`if link.startswith(("http://", "https://")): return link`), and/or use
`imports=True` when computing the type-name filter.

---

### U8 — `gen-rdf` fetches `<import>.context.jsonld` over the network for URL imports

*Dekkjer BUG-17 (URL-varianten; lokal-import-varianten er fiksa i #3641).*

**Title:** `gen-rdf` fails with HTTP 404 for schemas that import another schema by URL (fetches `<import-url>.context.jsonld`)

**Setup:** serve `leaf.yaml` over HTTP (e.g. `python -m http.server 8000` in a directory containing `schemas/leaf.yaml`).

**schemas/leaf.yaml**

```yaml
id: http://localhost:8000/schemas/leaf
name: leaf
prefixes:
  linkml: https://w3id.org/linkml/
  dqv: http://www.w3.org/ns/dqv#
default_prefix: http://localhost:8000/schemas/
imports: [linkml:types]
slots:
  value: {slot_uri: dqv:value}
classes:
  Measurement: {slots: [value]}
```

**main.yaml** (local)

```yaml
id: https://example.org/main
name: main
prefixes: {linkml: https://w3id.org/linkml/, ex: https://example.org/}
default_prefix: ex
imports:
  - linkml:types
  - http://localhost:8000/schemas/leaf
classes:
  MyMeasurement: {is_a: Measurement}
```

**Steps:** `gen-rdf main.yaml`

**Actual:** HTTP server log shows `GET /schemas/leaf.yaml` (OK) followed by
`GET /schemas/leaf.context.jsonld` → `urllib.error.HTTPError: HTTP Error 404`.

**Expected:** `gen-rdf` should produce RDF from the schema alone. The
imported schema has already been loaded; its JSON-LD context can be generated
in-process instead of being fetched from a URL that the schema publisher may
never have published.

**Root cause:** `jsonldgen.py:205` —
`context_list.append(imp[0] + ".context.jsonld")` for every import. #3641
drops unresolvable *local* references before parsing, but URL-based ones are
still fetched by rdflib's JSON-LD parser.

**Suggested fix:** in `RDFGenerator`, build a single merged context in memory
(e.g. `ContextGenerator(..., mergeimports=True)`) rather than referencing
per-import remote context files; or extend #3641's filtering to URL imports
whose context cannot be fetched.

## Tilrådingar

1. **Meld U1, U2, U3, U7, U8, U6, U5** i [linkml/linkml](https://github.com/linkml/linkml/issues/new) (ikkje det arkiverte `linkml-runtime`). U4 er valfri (spørsmål/forbetring). Rapporttekstane over kan limast inn direkte.
2. **Ikkje meld** BUG-24 (dekt av #3896/#3933), BUG-7 og BUG-15 (fiksa på `main`), BUG-8 (bruksfeil; relaterte issues finst). Legg eventuelt ein kommentar på #2506 om `range: string`-designatoren (`KeyError` i `rdflib_loader.py:118`).
3. **Oppdater bug-filene** (eiga oppgåve):
   - BUG-1: rett rotårsak til delt `slot_uri` (U1); skil ut LangString-delen (U5).
   - BUG-2: rett rotårsak til delt `slot_uri` (`adressekode_ref`/`har_adressekode` → `ngr:harAdressekode`); fjern den forelda `convert-instance-rdf`-skippen for NGR i `tests/test_make.sh`.
   - BUG-3: sett status `upstream`, dokumenter rotårsaka (attributt skuggar global slot). Intern workaround: gi container-attributta eksplisitt `slot_uri` lik den globale sloten, eller gi dei eit anna navn.
   - BUG-8: dokumenter den interne løysinga (global slot med `designates_type: true`, `range: uriorcurie`) og at det ikkje er ein upstream-bug.
   - BUG-15, BUG-24: byt lenkje til `linkml/linkml`; BUG-24 får issue-referanse #3896/#3933; BUG-24 si påstand «ikkje URL-spesifikk» må presiserast (utløysast av import-navn med `:`).
   - BUG-17: noter at lokal-import-varianten er fiksa i #3641.
   - BUG-19: presiser at feilen berre gjeld eigendefinert type `DateTime` (`base: str`) i `brreg-felles-typer`. Intern workaround: `typeof: datetime` i staden for `base: str` (må verifiserast).
   - BUG-20: lukk som ikkje-reproduserbar; vurder å fjerne lychee-eksklusjonen `^https://psi\.norge\.no/los/tema/$`.
4. **Ved neste `linkml`-release > 1.11.1:** verifiser at BUG-7 og BUG-15 er løyste og fjern workaround-greina i `linkml_relative_import_patch.py` (behald `cache_clear()` for BUG-24 til #3896/#3933 er løyst).
5. **Sidefunn:** grans negativ elapsed-tid for `erdiagram` i `make gen-schema-docs`.

## Avgjerder

- **Specen vert verande i `specs/backlog/`:** leveransen er kartlegginga og rapporttekstane; sjølve innmeldinga upstream og oppdatering av bug-filene er att som opne punkt.
- **Bug-filene og `BUGS.md` er ikkje endra:** brukaren bad om verifisering og dokumentasjon i `specs/`. Korrigerte rotårsaker er lista under § Tilrådingar i staden for å endre fleire filer utan avklaring.
- **Direkte `linkml-convert`/`gen-*`/`podman run` i staden for Makefile-targets for MRE-ar:** feilsøkingsunntaket i CLAUDE.md. Syntetiske MRE-ar har ingen Makefile-target, og `make roundtrip` respekterer skip-lista, så han kan ikkje avsløre om skippa bugs framleis finst. For repo-skjema vart `batch-convert.py` køyrd utan skip, med same argumentform som testane; `make gen-schema-docs` vart brukt for BUG-13/20.
- **Tre image (`linkml-local`, vanilla 1.11.1, `main`):** upstream-rapportar må vere fri for lokale patchar (`docgen-max-chars.patch`) og må vise om feilen finst på `main`.
- **Upstream-rapportane er på engelsk:** målgruppa er LinkML-utviklarane. Resten av specen er på nynorsk, jf. skriftspråkregelen.
- **U4 (BUG-18) er merkt valfri:** begge representasjonane er gyldige `uriorcurie`; upstream kan rimeleg sjå det som tilsikta åtferd.
- **BUG-9 og BUG-14 er ikkje re-verifiserte:** dei gjeld avrotize og mermaid, ikkje LinkML, og fell utanfor målet om upstream-rapportar for LinkML.
- **BUG-1 behalde som LangString-bug, krasjane flytta til BUG-2:** BUG-1 er referert som «LangString» i mkdocs, policy-README og fleire specs, og den skildringa er framleis sann (U5). BUG-2 fekk den korrigerte rotårsaka (delt `slot_uri`) og dekkjer no både NGR og dei sju katalogskjemaa. Dette oppfyller samanslåingskravet i `.claude/rules/bug-diagnostisering.md` utan å omnummerere.
- **Filnavnet `bugs/inlined-as-list-rdflib-roundtrip.md` er behalde** sjølv om det no er misvisande, for å ikkje bryte lenkjer i `tests/README.md`, `.claude/rules/linkml-schema.md` og fleire specs. Fila har ein merknad om dette.
- **`tests/test_make.sh`: berre kommentarar og skip-meldingar er endra**, ikkje skip-åtferd. Skip-konvensjonen i CLAUDE.md krev at BUG-ID i kommentaren stemmer med bug-fila. Å fjerne den forelda NGR-skippen for `convert-instance-rdf` er ei åtferdsendring som krev testkøyring, og står som eige ope punkt.
- **BUG-8 endra frå `open` til `workaround`:** det er ikkje ein upstream-bug, og workarounden (eige containerattributt per subklasse) er allereie regel. Modelleringsregelen i `linkml-schema.md` er ikkje endra; designator-alternativet er berre dokumentert i bug-fila.
- **BUG-20 sett til `løyst`** (ikkje reproduserbar). Lychee-eksklusjonen er ikkje fjerna før ein lenkjesjekk i CI har stadfesta at han er overflødig.
- **Følgjerettingar utanfor `bugs/`/`BUGS.md`:** `tests/README.md` (skip-tabell, inkl. manglande BUG-19-skip for `bvrinnfelles`), `.claude/rules/linkml-schema.md` (setning som grunngav inlining-regelen med gammal BUG-2-diagnose) og ein merknad om forelda premiss i `specs/backlog/fix-roundtrip-ngr-inlined-as-list.md`.
