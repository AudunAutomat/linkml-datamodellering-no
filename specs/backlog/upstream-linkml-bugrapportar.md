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
- [x] Fjern forelda `convert-instance-rdf`-skip for NGR i `tests/test_make.sh` og lychee-eksklusjonen for BUG-20 (2026-09-26; verifisert med `make test`-filter og `lychee --dump`, endeleg CI-stadfesting ved neste lenkjesjekk)

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

Prioritert rekkjefølgje: U1, U2, U3, U7, U8, U6, U5, U4.

Kvar rapport følgjer same mal: tittel, éi setning om problemet, minimal
reproduksjon, forventa/faktisk, årsak og framlegg til fiks. Alle MRE-ar er
køyrde på nytt i denne forma (2026-09-27) og reproduserer på både 1.11.1 og
`main`. Legg til denne linja nedst i kvart issue:

> **Environment:** linkml 1.11.1 (PyPI); also reproduced on `main` @ `5ef7622e`.

---

### U1 — Two slots with the same `slot_uri` break RDF loading

*Dekkjer BUG-1/BUG-2 (10 skjema skippa i roundtrip-ttl).*

**Title:** `RDFLibLoader`: two slots with the same `slot_uri` → `TypeError: unexpected keyword argument`

If two slots share a `slot_uri`, the loader uses one of them for **every** class — even a class that doesn't have that slot.

```yaml
id: https://example.org/s
name: s
prefixes: {linkml: https://w3id.org/linkml/, ex: https://example.org/}
default_prefix: ex
default_range: string
imports: [linkml:types]
slots:
  id: {identifier: true, range: uriorcurie}
  title: {slot_uri: ex:title}
  title_literal: {slot_uri: ex:title}   # same slot_uri as title
classes:
  Catalog: {tree_root: true, slots: [id, title]}
  Dataset: {slots: [id, title_literal]}
```

```sh
echo '{id: ex:c1, title: My catalog}' > data.yaml
linkml-convert -s schema.yaml -o out.ttl data.yaml    # OK
linkml-convert -s schema.yaml -o back.yaml out.ttl    # fails
```

- **Expected:** `back.yaml` equals `data.yaml`.
- **Actual:** `TypeError: Catalog.__init__() got an unexpected keyword argument 'title_literal'`
- **Cause:** `rdflib_loader.py:99` builds `uri_to_slot` keyed by URI only, so the last slot with that URI wins for all classes.
- **Suggested fix:** resolve the predicate among the subject class's own slots (`class_induced_slots`).

---

### U2 — An attribute with the same name as a global slot breaks RDF loading

*Dekkjer BUG-3 (`fint-administrasjon`, `fint-okonomi`, `fint-personvern`, `fint-utdanning`, `samt-bu`).*

**Title:** `RDFLibLoader`: `MappingError: No pred for …` when an attribute has the same name as a global slot

The dumper writes the **attribute's** URI, but the loader only knows the **global slot's** URI.

```yaml
id: https://example.org/s
name: s
prefixes: {linkml: https://w3id.org/linkml/, ex: https://example.org/}
default_prefix: ex
default_range: string
imports: [linkml:types]
slots:
  id: {identifier: true, range: uriorcurie}
  items: {slot_uri: ex:globalItems, range: Item, multivalued: true}
classes:
  Item: {slots: [id]}
  Container:
    tree_root: true
    attributes:
      items: {range: Item, multivalued: true, inlined_as_list: true}   # same name as the global slot
```

```sh
echo '{items: [{id: ex:i1}]}' > data.yaml
linkml-convert -s schema.yaml -o out.ttl data.yaml    # writes ex:items
linkml-convert -s schema.yaml -o back.yaml out.ttl    # fails
```

- **Expected:** `back.yaml` equals `data.yaml`.
- **Actual:** `MappingError: No pred for https://example.org/items`
- **Cause:** `rdflib_loader.py:99` builds the predicate map from `all_slots()`, which is keyed by name, so the global slot hides the attribute. The dumper uses `induced_slot(name, class)`.
- **Suggested fix:** use `induced_slot` per class in the loader, like the dumper. Likely the same fix as U1.

---

### U3 — Custom `xsd:dateTime` type loses the `T` on RDF load

*Dekkjer BUG-19 (`enhetsregisteret-bvrinnfelles`, `enhetsregisteret-bvrfriv`).*

**Title:** `RDFLibLoader`: custom type `uri: xsd:dateTime, base: str` turns `2024-01-01T10:30:00` into `2024-01-01 10:30:00`

The built-in `datetime` type works; only custom `str`-based types are affected.

```yaml
id: https://example.org/s
name: s
prefixes: {linkml: https://w3id.org/linkml/, ex: https://example.org/, xsd: "http://www.w3.org/2001/XMLSchema#"}
default_prefix: ex
default_range: string
imports: [linkml:types]
types:
  DateTimeString: {uri: xsd:dateTime, base: str}
classes:
  Event:
    tree_root: true
    attributes:
      id: {identifier: true, range: uriorcurie}
      timestamp: {range: DateTimeString}
```

```sh
echo '{id: ex:e1, timestamp: "2024-01-01T10:30:00"}' > data.yaml
linkml-convert -s schema.yaml -o out.ttl data.yaml    # TTL is correct
linkml-convert -s schema.yaml -o back.yaml out.ttl
```

- **Expected:** `timestamp: '2024-01-01T10:30:00'`
- **Actual:** `timestamp: '2024-01-01 10:30:00'`
- **Cause:** `rdflib_loader.py:148` uses `o.value` (a Python `datetime`), which is later turned into a string with `str()`.
- **Suggested fix:** use the lexical form `str(o)` when the type's base is `str`.

---

### U4 — (valfri) Full URI comes back as a CURIE after RDF round-trip

*Dekkjer BUG-18. Begge formene er gyldige `uriorcurie`, så meld som forbetringsframlegg, ikkje bug.*

**Title:** `RDFLibLoader`: identifier written as a full URI is returned as a CURIE

```yaml
id: https://example.org/s
name: s
prefixes: {linkml: https://w3id.org/linkml/, ex: https://example.org/}
default_prefix: ex
default_range: string
imports: [linkml:types]
classes:
  Thing:
    attributes:
      id: {identifier: true, range: uriorcurie}
  Container:
    tree_root: true
    attributes:
      things: {range: Thing, multivalued: true, inlined_as_list: true}
```

```sh
echo '{things: [{id: "https://example.org/thing1"}]}' > data.yaml
linkml-convert -s schema.yaml -o out.ttl data.yaml
linkml-convert -s schema.yaml -o back.yaml out.ttl
```

- **Expected:** `id: https://example.org/thing1`
- **Actual:** `id: ex:thing1`
- **Suggestion:** a loader option to keep full URIs, or document that round-trips are only equal up to CURIE contraction.

---

### U5 — `rdf:langString` values are written as invalid RDF and silently lost

*Dekkjer BUG-1 (LangString). Relatert til [#3548](https://github.com/linkml/linkml/issues/3548).*

**Title:** Type with `uri: rdf:langString` writes `"x"^^rdf:langString` (invalid RDF) and the loader silently drops it

LinkML has no language-tagged strings (#3548), so schemas often declare a `rdf:langString` type. The value survives the dump but disappears on load, with no error.

```yaml
id: https://example.org/s
name: s
prefixes: {linkml: https://w3id.org/linkml/, ex: https://example.org/, rdf: "http://www.w3.org/1999/02/22-rdf-syntax-ns#"}
default_prefix: ex
default_range: string
imports: [linkml:types]
types:
  LangString: {uri: rdf:langString, base: str}
classes:
  Catalog:
    tree_root: true
    attributes:
      id: {identifier: true, range: uriorcurie}
      title: {range: LangString}
```

```sh
echo '{id: ex:c1, title: My catalog}' > data.yaml
linkml-convert -s schema.yaml -o out.ttl data.yaml    # ex:title "My catalog"^^rdf:langString
linkml-convert -s schema.yaml -o back.yaml out.ttl    # title is gone
```

- **Expected:** at minimum, no silent data loss (keep the value, or raise/warn). Ideally, never write `^^rdf:langString` without a language tag.
- **Actual:** `back.yaml` is `{id: ex:c1}`.
- **Cause:** the dumper writes `Literal(value, datatype=rdf:langString)`; the loader's `o.value` is `None` for that literal, and `None` is dropped.

---

### U6 — Re-declaring an imported class: some generators crash, others silently drop slots

*Dekkjer BUG-6. [#417](https://github.com/linkml/linkml/issues/417) avviste union-semantikk; dette gjeld **inkonsistensen**.*

**Title:** Class re-declared in an importing schema: `gen-python` raises, `gen-json-schema` silently drops the imported slots

`base.yaml`:

```yaml
id: https://example.org/base
name: base
prefixes: {linkml: https://w3id.org/linkml/, ex: https://example.org/}
default_prefix: ex
default_range: string
imports: [linkml:types]
slots:
  id: {identifier: true, range: uriorcurie}
  title: {}
classes:
  Standard: {slots: [id, title]}
```

`schema.yaml`:

```yaml
id: https://example.org/s
name: s
prefixes: {linkml: https://w3id.org/linkml/, ex: https://example.org/}
default_prefix: ex
default_range: string
imports: [linkml:types, base]
slots:
  extra: {}
classes:
  Standard: {slots: [extra]}   # re-declares the imported class to add a slot
```

| Generator | Result |
|---|---|
| `gen-python`, `gen-rdf`, `gen-jsonld-context` | `ValueError: Conflicting URIs (…/base, …/s) for item: Standard` |
| `gen-pydantic`, `gen-json-schema`, `gen-shacl`, `gen-owl` | Succeeds, but `Standard` has only `extra` — `id` and `title` are silently lost |

- **Expected:** the same behaviour in all generators — ideally a clear error (also in `linkml lint`).
- **Note:** `679eba10` on `main` only merges *identical* duplicates; this case still fails.

---

### U7 — `gen-doc` Mermaid diagrams: broken links `../http://…` for built-in types

*Dekkjer BUG-13.*

**Title:** `gen-doc --no-render-imports`: Mermaid `click` links for `linkml:types` become `"../http://www.w3.org/2001/XMLSchema#anyURI/"`

```yaml
id: https://example.org/s
name: s
prefixes: {linkml: https://w3id.org/linkml/, ex: https://example.org/}
default_prefix: ex
default_range: string
imports: [linkml:types]
classes:
  Person:
    attributes:
      homepage: {range: uri}
```

```sh
gen-doc --no-mergeimports --no-render-imports --diagram-type mermaid_class_diagram -d docs schema.yaml
grep click docs/Person.md
```

- **Expected:** no box for the `uri` type (as without `--no-render-imports`), or the absolute URL unchanged.
- **Actual:** `click Uri href "../http://www.w3.org/2001/XMLSchema#anyURI/"`
- **Cause (two parts):**
  1. The template's type filter uses `all_type_object_names()`, which ignores imported types when `render_imports` is off, so `uri` is drawn as a class.
  2. `link_mermaid()` (`docgen.py:458-471`) always returns `f"../{link}/"`, even for absolute URLs.
- **Suggested fix:** return absolute URLs unchanged in `link_mermaid()`, and/or include imported types in the filter.

---

### U8 — `gen-rdf` fails with 404 for schemas that import a schema by URL

*Dekkjer BUG-17 (URL-varianten; lokale importar er fiksa i [#3641](https://github.com/linkml/linkml/pull/3641)).*

**Title:** `gen-rdf` downloads `<import-url>.context.jsonld` and fails with HTTP 404

Serve `schemas/leaf.yaml` with `python -m http.server 8000`:

```yaml
id: http://localhost:8000/schemas/leaf
name: leaf
prefixes: {linkml: https://w3id.org/linkml/}
default_prefix: http://localhost:8000/schemas/
default_range: string
imports: [linkml:types]
classes:
  Measurement:
    attributes:
      value: {}
```

Local `schema.yaml`:

```yaml
id: https://example.org/s
name: s
prefixes: {linkml: https://w3id.org/linkml/, ex: https://example.org/}
default_prefix: ex
imports: [linkml:types, http://localhost:8000/schemas/leaf]
classes:
  MyMeasurement: {is_a: Measurement}
```

```sh
gen-rdf schema.yaml
```

- **Expected:** RDF output. The imported schema is already loaded, so no extra files should be needed.
- **Actual:** the server log shows `GET /schemas/leaf.context.jsonld`, and `gen-rdf` fails with `HTTP Error 404`.
- **Cause:** `jsonldgen.py:205` adds `<import> + ".context.jsonld"` to `@context` for every import; rdflib then downloads it. #3641 only filters out local imports.
- **Suggested fix:** build the context in memory for all imports, or skip remote contexts that can't be fetched.

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
- **Verifisering av lychee-fjerninga lokalt med `lychee --dump`, ikkje full sjekk:** lenkjesjekken har ingen make-target og køyrer berre i CI. `--dump` viser kva URL-ar lychee ekstraherer, og det var nettopp ekstraheringa som var problemet. Ei full nettverkssjekk av ~98 000 lenkjer er ikkje naudsynt for å stadfeste dette. Negativ kontroll mot dei forelda sidene i `mkdocs/docs/` stadfesta at metoden fangar feilen.
- **NGR-skippen fjerna etter `TEST_FILTER=convert-instance-rdf make test SCHEMA=...`** for alle tre skjema (OK i fase A og B). Full `make test` er ikkje køyrd; endringa påverkar berre denne testen for dei tre skjemaa.
- **U1-U8 omskrivne til kortare form (2026-09-27, brukarønske):** felles mal (tittel, éi setning, MRE, forventa/faktisk, årsak, fiks), MRE-ar i flow-stil YAML og same `ex`-prefiks overalt. Kvar rapport er framleis sjølvstendig (eige skjema og eigne kommandoar), sidan dei skal meldast som separate issues. Alle kompakte MRE-ar er køyrde på nytt mot 1.11.1 og `main @ 5ef7622e` og reproduserer uendra.
