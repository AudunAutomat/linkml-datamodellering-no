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
- [x] Steg 7 — sjå § Upstream-rapportar (U1-U3 og U5-U8; U4 sletta 2026-11-26)
- [x] Steg 8 — sjå § Tilrådingar
- [x] Re-verifiser mot `linkml` 1.12.1 (2026-11-18, sjå § Re-verifisering mot 1.12.1)
- [x] Re-analyse mot issue-trackaren (2026-11-26, berre tracker- og kjeldesøk, sjå § Re-analyse mot issue-trackaren)
- [x] Meld U1-U3 og U5-U8 upstream (brukaren meldte dei 2026-11-26, sjå § Meldte issues)
- [x] Oppdater `bugs/*.md` og `BUGS.md` med korrigerte rotårsaker og issue-lenkjer (2026-09-26, sjå § Avgjerder)
- [x] Fjern forelda `convert-instance-rdf`-skip for NGR i `tests/test_make.sh` og lychee-eksklusjonen for BUG-20 (2026-09-26; verifisert med `make test`-filter og `lychee --dump`, endeleg CI-stadfesting ved neste lenkjesjekk)

## Testoppsett

| Image | Innhald | Bruk |
|---|---|---|
| `localhost/linkml-local:latest` | `linkml==1.11.1` + lokal `docgen-max-chars.patch` (frå 2026-11-06: `linkml==1.12.1` + `docgen-max-chars.patch` og `javagen-custom-typemap.patch`) | Repoets eige image — verifisering mot ekte skjema |
| `localhost/linkml-vanilla:1.12.1` | `python:3.12-slim` + `pip install linkml==1.12.1 linkml-runtime==1.12.1`, ingen patchar (2026-11-18) | Re-verifisering mot gjeldande versjon |
| `localhost/linkml-vanilla:1.11.1` | `python:3.12-slim` + `pip install linkml==1.11.1`, ingen patchar | Upstream-MRE-ar mot siste release |
| `localhost/linkml-main:eff06809` | Som under, men frå `eff06809` (2026-11-25, 1.13.0.dev0; bygd 2026-11-26 med `UV_DYNAMIC_VERSIONING_BYPASS`) | Re-analyse U3/U5 |
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
| BUG-7 | linkml | `workaround` | Ja (MRE) | Ja | **Nei** | **Fiksa på `main`** (`679eba10`, 2026-06-10). **Utgjeven i 1.12.1** (verifisert 2026-11-18, sjå § Re-verifisering). Ikkje meld |
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
| BUG-18 | linkml-runtime | `workaround` | Ja (MRE) | Ja | Ja | **Framleis relevant**, men låg alvorsgrad — begge formene er gyldige `uriorcurie` (tidlegare U4, no sletta: tilsikta etter [#4156](https://github.com/linkml/linkml/pull/4156); sjå § Avgjerder) |
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

Ingen treff for U1, U2, U3, U7 og U8 (søk på `rdflib_loader`, `RDFLibLoader`,
`No pred for`, `MappingError`, `slot_uri`, `link_mermaid`, `context.jsonld`,
`datetime` m.fl., 2026-09-26).

## Upstream-rapportar

Prioritert rekkjefølgje: U1, U2, U3, U7, U8, U6, U5. (U4 er sletta; nummera er ikkje omnummererte, slik at referansar til U5-U8 held.)

Kvar rapport følgjer same mal: tittel, éi setning om problemet, minimal
reproduksjon, forventa/faktisk, årsak og framlegg til fiks. Alle MRE-ar er
køyrde på nytt i denne forma (2026-09-27) og reproduserer på både 1.11.1 og
`main`; køyrde mot 1.12.1 2026-11-18, og U1-U8 reproduserer òg der. Kvar rapport har ei eiga miljølinje nedst (same tekst, limast inn i issuen). Testa versjonar for kvar rapport (U1-U3 og U5-U8, same MRE-ar): `linkml` 1.11.1 og `main @ 5ef7622e` (2026-09-27), 1.12.1 (2026-11-18) og `main @ eff06809`, 1.13.0.dev0 (2026-11-26). Dei to siste er køyrde i `linkml-vanilla:1.12.1` og `linkml-main:eff06809`.

---

### U1 — Two slots with the same `slot_uri` break RDF loading

**Meldt:** [linkml/linkml#4285](https://github.com/linkml/linkml/issues/4285) (2026-11-26).

*Radnummer i U1-U3 og U5-U8 er frå 1.11.1/`main` og stemmer i 1.12.1 bortsett frå U8 (`jsonldgen.py:211`, ikkje 205).*

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
- **Cause:** `rdflib_loader.py:99` (line 101 on `main` @ `eff06809`) builds `uri_to_slot` keyed by URI only, so the last slot with that URI wins for all classes.
- **Suggested fix:** resolve the predicate among the subject class's own slots (`class_induced_slots`).

> **Environment:** linkml 1.12.1 (PyPI); also reproduced on 1.11.1 and on `main` @ `eff06809` (1.13.0.dev0).

---

### U2 — An attribute with the same name as a global slot breaks RDF loading

**Meldt:** [linkml/linkml#4286](https://github.com/linkml/linkml/issues/4286) (2026-11-26).

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
- **Cause:** `rdflib_loader.py:99` (line 101 on `main` @ `eff06809`) builds the predicate map from `all_slots()`, which is keyed by name, so the global slot hides the attribute. The dumper uses `induced_slot(name, class)`.
- **Suggested fix:** use `induced_slot` per class in the loader, like the dumper. Likely the same fix as U1.

> **Environment:** linkml 1.12.1 (PyPI); also reproduced on 1.11.1 and on `main` @ `eff06809` (1.13.0.dev0).

---

### U3 — Custom `xsd:dateTime` type loses the `T` on RDF load

**Meldt:** [linkml/linkml#4287](https://github.com/linkml/linkml/issues/4287) (2026-11-26).

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
- **Cause:** `rdflib_loader.py:148` (line 270 on `main` @ `eff06809`) uses `o.value` (a Python `datetime`), which is later turned into a string with `str()`.
- **Suggested fix:** use the lexical form `str(o)` when the type's base is `str`.

> **Environment:** linkml 1.12.1 (PyPI); also reproduced on 1.11.1 and on `main` @ `eff06809` (1.13.0.dev0).

---

### U5 — `rdf:langString` values are written as invalid RDF and silently lost

**Meldt:** [linkml/linkml#4288](https://github.com/linkml/linkml/issues/4288) (2026-11-26).

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

> **Environment:** linkml 1.12.1 (PyPI); also reproduced on 1.11.1 and on `main` @ `eff06809` (1.13.0.dev0).

---

### U6 — Re-declaring an imported class: some generators crash, others silently drop slots

**Meldt:** [linkml/linkml#4289](https://github.com/linkml/linkml/issues/4289) (2026-11-26).

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

> **Environment:** linkml 1.12.1 (PyPI); also reproduced on 1.11.1 and on `main` @ `eff06809` (1.13.0.dev0).

---

### U7 — `gen-doc` Mermaid diagrams: broken links `../http://…` for built-in types

**Meldt:** [linkml/linkml#4290](https://github.com/linkml/linkml/issues/4290) (2026-11-26).

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
  2. `link_mermaid()` (`docgen.py:458-471`; unchanged on `main` @ `eff06809`) always returns `f"../{link}/"`, even for absolute URLs.
- **Suggested fix:** return absolute URLs unchanged in `link_mermaid()`, and/or include imported types in the filter.

> **Environment:** linkml 1.12.1 (PyPI); also reproduced on 1.11.1 and on `main` @ `eff06809` (1.13.0.dev0).

---

### U8 — `gen-rdf` fails with 404 for schemas that import a schema by URL

**Meldt:** [linkml/linkml#4291](https://github.com/linkml/linkml/issues/4291) (2026-11-26).

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
- **Cause:** `jsonldgen.py:211` (1.12.1; line 205 in 1.11.1; line 226 on `main` @ `eff06809`) adds `<import> + ".context.jsonld"` to `@context` for every import; rdflib then downloads it. #3641 only filters out local imports.
- **Suggested fix:** build the context in memory for all imports, or skip remote contexts that can't be fetched.

> **Environment:** linkml 1.12.1 (PyPI); also reproduced on 1.11.1 and on `main` @ `eff06809` (1.13.0.dev0).

## Re-verifisering mot 1.12.1

Køyrt 2026-11-18 i `localhost/linkml-vanilla:1.12.1` (`linkml==1.12.1`,
`linkml-runtime==1.12.1`, ingen patchar), same MRE-ar som i § Upstream-rapportar.
Repoet brukar 1.12.1 sidan 2026-11-06 (`specs/done/oppgrader-linkml-1-12-1.md`).

| Punkt | Resultat i 1.12.1 | Endring frå 1.11.1 |
|---|---|---|
| U1 | `TypeError: Catalog.__init__() got an unexpected keyword argument 'title_literal'` | Ingen |
| U2 | `MappingError: No pred for https://example.org/items` | Ingen |
| U3 | `timestamp: '2024-01-01 10:30:00'` | Ingen |
| U5 | `back.yaml` = `{id: ex:c1}` (tittelen er borte) | Ingen |
| U6 | `gen-python`/`gen-rdf`/`gen-jsonld-context` feilar med `Conflicting URIs`; `gen-json-schema` gir `Standard` med berre `extra` | Ingen |
| U7 | `click Uri href "../http://www.w3.org/2001/XMLSchema#anyURI/"` | Ingen |
| U8 | `GET /schemas/leaf.context.jsonld` → 404 | Ingen (radnummer 205 → 211) |
| BUG-7 | `gen-python`/`gen-rdf`/`gen-jsonld-context` gir `rc=0`, både for lokal redeklarering av identisk slot og for to søsken-importar med same slot | **Fiksa** (`679eba10` er med i 1.12.1) |
| BUG-15 | SchemaView-delen retta, `mergeutils`-varianten framleis til stades | Sjå `specs/done/linkml-relative-import-patch-1-12.md` (ikkje køyrt på nytt her) |
| BUG-24 | Framleis til stades | Sjå same spec (ikkje køyrt på nytt her) |

Ikkje re-verifisert 2026-11-18: BUG-17 (lokal-import-varianten), BUG-20 (ikkje
reproduserbar frå før) og `main` etter `5ef7622e`. Sjekk `main` før U1-U8 vert
meldte, slik at ingen av dei alt er fiksa.

## Meldte issues

Brukaren meldte U1-U3 og U5-U8 i `linkml/linkml` 2026-11-26. Rekkjefølgje og titlar er stadfesta mot GitHub (alle opne same dag, ingen kommentarar sett). U4 vart ikkje meldt (sletta).

| Rapport | Issue | Dekkjer | Tittel |
|---|---|---|---|
| U1 | [#4285](https://github.com/linkml/linkml/issues/4285) | BUG-1/BUG-2 | `RDFLibLoader`: two slots with the same `slot_uri` → `TypeError: unexpected keyword argument` |
| U2 | [#4286](https://github.com/linkml/linkml/issues/4286) | BUG-3 | `RDFLibLoader`: `MappingError: No pred for …` when an attribute has the same name as a global slot |
| U3 | [#4287](https://github.com/linkml/linkml/issues/4287) | BUG-19 | `RDFLibLoader`: custom type `uri: xsd:dateTime, base: str` turns `2024-01-01T10:30:00` into `2024-01-01 10:30:00` |
| U5 | [#4288](https://github.com/linkml/linkml/issues/4288) | BUG-1 (LangString) | Type with `uri: rdf:langString` writes `"x"^^rdf:langString` (invalid RDF) and the loader silently drops it |
| U6 | [#4289](https://github.com/linkml/linkml/issues/4289) | BUG-6 | Class re-declared in an importing schema: `gen-python` raises, `gen-json-schema` silently drops the imported slots |
| U7 | [#4290](https://github.com/linkml/linkml/issues/4290) | BUG-13 | `gen-doc --no-render-imports`: Mermaid `click` links for `linkml:types` become `"../http://www.w3.org/2001/XMLSchema#anyURI/"` |
| U8 | [#4291](https://github.com/linkml/linkml/issues/4291) | BUG-17 (URL) | `gen-rdf` downloads `<import-url>.context.jsonld` and fails with HTTP 404 |

**Oppfølging (opne punkt):**

- ~~Legg issue-lenkjene inn i `bugs/*.md` og `BUGS.md`~~ — gjort 2026-11-26 (BUG-1, -2, -3, -6, -13, -17, -19: `**Upstream:**`-linje i bug-fila, oppdatert prosa, lenkjer i `BUGS.md` PoC-status; BUG-24 fekk #3896/#3933 i `BUGS.md`). Statusar uendra.
- #4285 og #4286 har truleg same fiks (ein `induced_slot` per klasse i `rdflib_loader`); følg med om utviklarane slår dei saman.
- Følg med på #3896/#3933 (BUG-24) og #2506 (BUG-8); ikkje meldte på nytt.
- Når linkml 1.13.0 kjem: køyr MRE-ane og `make roundtrip`/`make test` før oppgradering, og fjern workarounds som er fiksa.

## Re-analyse mot issue-trackaren (2026-11-26)

Berre tracker- og kjeldesøk (GitHub API og `raw.githubusercontent.com`); **ingen
MRE-ar er køyrde på nytt.** «Status» under er difor `main`-kjelda lesen, ikkje
verifisert ved køyring. Utgangspunkt: siste release er framleis **1.12.1**
(2026-10-13, ingen nyare på PyPI); `main` er `eff06809` (2026-11-25), 101 commits
framføre `v1.12.1`, og er det som vert 1.13.0 (deprecation-meldingar i `main`
nemner 1.13.0).

### Status for kjende lenkjer

| Lenkje | Status 2026-11-26 | Endring sidan 2026-11-18 |
|---|---|---|
| [#3896](https://github.com/linkml/linkml/issues/3896), [#3933](https://github.com/linkml/linkml/issues/3933) (BUG-24) | Opne, 0 kommentarar, sist oppdatert 2026-08/09 | Ingen |
| [#3855](https://github.com/linkml/linkml/pull/3855) (BUG-15), [#3641](https://github.com/linkml/linkml/pull/3641) (BUG-17 lokal) | Lukka/fletta | Ingen |
| [#2506](https://github.com/linkml/linkml/issues/2506), [#2107](https://github.com/linkml/linkml/issues/2107), [#2399](https://github.com/linkml/linkml/issues/2399) (BUG-8) | Opne, ikkje rørte sidan 2025 | Ingen |
| [#3663](https://github.com/linkml/linkml/issues/3663) (BUG-8) | Open, 3 kommentarar, oppdatert 2026-10-14 | Ingen nye |
| [#3548](https://github.com/linkml/linkml/issues/3548) (U5) | Open, 1 kommentar | Ingen |
| [#417](https://github.com/linkml/linkml/issues/417) (U6) | Lukka `not_planned` 2023 | Ingen |

### Status per rapport (kjeldelesing av `main`)

| Rapport | Status på `main` | Grunnlag | Tilråding |
|---|---|---|---|
| U1 | **Framleis til stades (køyrt 2026-11-26)** | MRE gir same `TypeError: Catalog.__init__() got an unexpected keyword argument 'title_literal'` på `main @ eff06809` og 1.12.1. Årsak: `rdflib_loader.py:101` byggjer `uri_to_slot` frå `schemaview.all_slots()` (nøkkel URI, siste slot vinn) | Meld (ingen eksisterande issue funne) |
| U2 | **Framleis til stades (køyrt 2026-11-26)** | MRE gir same `MappingError: No pred for https://example.org/items` på `main` og 1.12.1. Same linje; `induced_slot(uri_to_slot[p].name, …)` på linje 139 slår opp den globale sloten sitt navn | Meld saman med eller som oppfølgjar til U1 |
| U3 | **Framleis til stades (køyrt 2026-11-26)** | MRE gir `timestamp: '2024-01-01 10:30:00'` på `main @ eff06809` (1.13.0.dev0), same som 1.12.1. TTL er riktig (`"2024-01-01T10:30:00"^^xsd:dateTime`); feilen er i lastaren (`rdflib_loader.py:270`, `o.value`) | Meld |
| U4 | **Sletta frå lista (2026-11-26).** Reproduserer (`id: ex:thing1` også på `main`), men åtferda er tilsikta | [#4156](https://github.com/linkml/linkml/pull/4156) (fletta 2026-10-30, ikkje utgjeven): «the loader … keeps `uri` values complete, compacts `uriorcurie` values to CURIEs». Åtferda vi melde som avvik er no uttrykkeleg spesifisert | Ikkje meld |
| U5 | **Framleis til stades (køyrt 2026-11-26)** | MRE gir framleis `ex:title "My catalog"^^rdf:langString` og `back.yaml` = `{id: ex:c1}` på `main @ eff06809`, same som 1.12.1. I tillegg skriv dumperen `RDFCanonicalizationWarning: Graph contains non-standard RDF … pyoxigraph cannot parse` (også i 1.12.1, ikkje nemnd i rapporten tidlegare). [#3449](https://github.com/linkml/linkml/pull/3449) (`--default-language`, fletta 2026-06, i 1.12.x) gjeld berre språktagg på annotasjonar i `gen-owl`/`gen-shacl`, ikkje data. #3548 er framleis open | Meld med referanse til #3548 og #3449; ta med åtvaringa som ekstra bevis på ugyldig RDF |
| U6 | **Framleis til stades (køyrt 2026-11-26)** | Uendra på `main` og 1.12.1: `gen-python`/`gen-rdf`/`gen-jsonld-context` gir `ValueError: Conflicting URIs`; `gen-pydantic`/`gen-json-schema`/`gen-shacl`/`gen-owl` lukkast, `Standard` har berre `extra`. `mergeutils.py` er uendra sidan 2026-09-20; ingen issue funne (søk på «Conflicting URIs», «redeclare») | Meld |
| U7 | **Framleis til stades (køyrt 2026-11-26)** | Same `click Uri href "../http://www.w3.org/2001/XMLSchema#anyURI/"` på `main` og 1.12.1. `docgen.py:471` returnerer framleis `f"../{link}/"` og fila er uendra sidan 2026-09-20. Relatert, open og uaktiv sidan 2026-04: [#2550](https://github.com/linkml/linkml/pull/2550) (PR, «class diagram links … should not go up the parent directory») | Meld; referer til #2550 |
| U8 | **Framleis til stades (køyrt 2026-11-26)** | Same `HTTP Error 404` på `main` og 1.12.1; serverlogg viser `GET /schemas/leaf.context.jsonld 404`. `jsonldgen.py:226` legg framleis til `<import>.context.jsonld` for alle importar. Treff i søket ([#2602](https://github.com/linkml/linkml/pull/2602), [#3897](https://github.com/linkml/linkml/pull/3897), #1965) gjeld ikkje denne feilen | Meld |

### Nye funn

- **[#4164](https://github.com/linkml/linkml/issues/4164)** (open, 2026-10-22): relative importar vert løyste mot CWD når ein generator får eit `SchemaDefinition`-objekt. Nærskyld BUG-15/BUG-17 (relative importar), men eit anna kodested (`Generator`, ikkje `SchemaView`). Ingen eigen bug hos oss; følg med.
- **Nye endringar i RDF-kodebanen på `main`** (ikkje i 1.12.1): #4156 (felles `rdf_terms.type_term` for `gen-owl`/`gen-shacl`/`gen-shex`/`gen-jsonld-context`/dumper/loader), `9a0c8371` (dumper avviser relative IRI-verdiar) og `df320116` (`rdf:List` for ordna fleirverdi-slots). Dei kan endre oppførselen i `batch-convert.py`/roundtrip-testane våre når 1.13.0 kjem, uavhengig av U1-U8.
- **Image:** `localhost/linkml-main:eff06809` (`python:3.12-slim`, `pip install` av `packages/linkml_runtime` og `packages/linkml` frå tarball av `eff06809`, med `UV_DYNAMIC_VERSIONING_BYPASS=1.13.0.dev0` fordi tarballen manglar git-versjon). Køyrt saman med `linkml-vanilla:1.12.1` som kontroll.
- **Ingen nye upstream-issues** for U1, U2, U3, U5, U6, U8 (søk 2026-11-26 på `slot_uri`, `No pred for`, `langString`, `Conflicting URIs`, `context.jsonld`, `link_mermaid`, `datetime`).

### Konsekvens

1. **Meld U1, U2, U6, U7, U8 no** — reproduserte på `main @ eff06809` og 1.12.1, rotårsaka stadfesta i kjelda, og ingen eksisterande issue dekkjer dei.
2. **U3 og U5 er køyrde mot `main`** (`localhost/linkml-main:eff06809`, 2026-11-26) og reproduserer uendra; meld dei òg.
3. **U4 er sletta** (tilsikta åtferd i #4156).
4. **Oppdater miljølinja** i rapportane til `linkml 1.12.1 (PyPI); also reproduced on 1.11.1 and on main @ eff06809 (1.13.0.dev0)`. Alle U1-U3 og U5-U8 er køyrde mot `main @ eff06809` og reproduserer.
5. **Plan for 1.13.0:** når han kjem, køyr full `make roundtrip`/`make test` før oppgradering; #4156 og `df320116` endrar RDF-serialiseringa.

## Tilrådingar

1. **(Gjort 2026-11-26, sjå § Meldte issues)** Meld U1, U2, U3, U7, U8, U6, U5 i [linkml/linkml](https://github.com/linkml/linkml/issues/new) (ikkje det arkiverte `linkml-runtime`). Rapporttekstane over kan limast inn direkte.
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
4. **Etter oppgradering til 1.12.1 (2026-11-06):** BUG-15 (SchemaView) er løyst og BUG-7 er løyst (sjå § Re-verifisering). Workaround-greina for BUG-15 i `linkml_relative_import_patch.py` er alt gjort versjonsbevisst (`specs/done/linkml-relative-import-patch-1-12.md`); behald `cache_clear()` for BUG-24 til #3896/#3933 er løyst. Workarounden for BUG-7 (fjerning av lokal redeklarering og duplikat-slots) kan fjernast, men verifiser først med `make roundtrip`/`make test` på `modelldcat-ap-no`/`dcat-ap-no` — MRE-en er syntetisk.
5. **Sidefunn:** grans negativ elapsed-tid for `erdiagram` i `make gen-schema-docs`.

## Avgjerder

- **Re-verifisering mot 1.12.1 (2026-11-18, brukarønske):** specen var skriven mot 1.11.1 medan repoet sidan 2026-11-06 brukar 1.12.1. Berre MRE-ane frå specen er køyrde på nytt, i eit patchfritt `linkml-vanilla:1.12.1`-image bygd i scratchpad (feilsøkingsunntaket i CLAUDE.md gjeld framleis: syntetiske MRE-ar har ingen Makefile-target). Resultat i § Re-verifisering mot 1.12.1.
- **Berre BUG-7 er endra av oppgraderinga.** Rapporttekstane U1-U8 er behaldne, med oppdatert versjon i miljølinja og radnummer for U8. `bugs/*.md` og `BUGS.md` er ikkje endra: BUG-7 står framleis som `workaround`, og status vert først endra etter at `make roundtrip`/`make test` på dei råka skjemaa er køyrt utan workarounden.

- **Innmelding (2026-11-26):** brukaren oppretta sjølv #4285-#4291 (U1, U2, U3, U5, U6, U7, U8) på GitHub; eg har ikkje publisert noko (ingen `gh`/token). Kopla titlar til rapportar via GitHub API (lesing). Specen vert verande i `specs/backlog/` til bug-filene er oppdaterte med lenkjene.
- **Re-analyse mot issue-trackaren (2026-11-26, brukarønske):** berre søk (GitHub API utan innlogging, `raw.githubusercontent.com`) og lesing av `main`-kjelda; ingen MRE-køyringar, ingen nye issues eller kommentarar upstream, `bugs/`/`BUGS.md` urørte. Funn: U4 vert foreslått sletta fordi #4156 gjer åtferda tilsikta. **U3 og U5, og deretter resten (U1, U2, U4, U6, U7, U8), vart køyrde etterpå mot `main @ eff06809` (nytt image, sjå § Testoppsett); begge reproduserer uendra** (direkte `podman build`/`podman run` er feilsøkingsunntaket i CLAUDE.md; sandkassen måtte slåast av for å nå podman).
- **Specen vert verande i `specs/backlog/`:** leveransen er kartlegginga og rapporttekstane; sjølve innmeldinga upstream og oppdatering av bug-filene er att som opne punkt.
- **Bug-filene og `BUGS.md` er ikkje endra:** brukaren bad om verifisering og dokumentasjon i `specs/`. Korrigerte rotårsaker er lista under § Tilrådingar i staden for å endre fleire filer utan avklaring.
- **Direkte `linkml-convert`/`gen-*`/`podman run` i staden for Makefile-targets for MRE-ar:** feilsøkingsunntaket i CLAUDE.md. Syntetiske MRE-ar har ingen Makefile-target, og `make roundtrip` respekterer skip-lista, så han kan ikkje avsløre om skippa bugs framleis finst. For repo-skjema vart `batch-convert.py` køyrd utan skip, med same argumentform som testane; `make gen-schema-docs` vart brukt for BUG-13/20.
- **Tre image (`linkml-local`, vanilla 1.11.1, `main`):** upstream-rapportar må vere fri for lokale patchar (`docgen-max-chars.patch`) og må vise om feilen finst på `main`.
- **Upstream-rapportane er på engelsk:** målgruppa er LinkML-utviklarane. Resten av specen er på nynorsk, jf. skriftspråkregelen.
- **U4 (BUG-18) er sletta frå lista (2026-11-26, brukarønske):** begge representasjonane er gyldige `uriorcurie`, og [#4156](https://github.com/linkml/linkml/pull/4156) (på `main`, ikkje utgjeven) gjer åtferda uttrykkeleg tilsikta («compacts `uriorcurie` values to CURIEs»). U4-rapporten er fjerna; nummera U5-U8 er behaldne for å ikkje bryte referansar. BUG-18 står framleis som `workaround` i `bugs/`.
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
