---
i18n:
  source: ny-domenemodell.md
  source_hash: sha256:54a458980a6882cdbf14f57eb63dc19d6a2ca3ab06acbdc1c92b1530859c517c
---
# Guide: new domain model {#rettleiing-ny-domenemodell}

!!! note "Description"

    This guide shows how to create a new domain model in the repository —
    from file structure to RDF export ready for Felles Datakatalog.

!!! tip "Where does this fit into «Orden i eget hus»?"

    If your organization follows Digdir's guideline
    [«Orden i eget hus»](https://www.digdir.no/informasjonsforvaltning/veileder-orden-i-eget-hus/2716) ("Getting your own house in order"),
    this guide covers step 3 (map — model datasets and concepts in LinkML),
    step 5 (describe — DCAT-AP-NO/SKOS-AP-NO metadata fields) and step 6
    (make available — pull-based publishing to Felles datakatalog/begrepskatalog).
    Steps 1 (plan), 2 (prioritize) and 4 (assess access level) are organizational
    clarifications that should be done in your own organization before you start here — see
    [step 1](https://www.digdir.no/informasjonsforvaltning/steg-1-planlegge/2718),
    [step 2](https://www.digdir.no/informasjonsforvaltning/steg-2-prioritere/2719) and
    [step 4](https://www.digdir.no/informasjonsforvaltning/steg-4-vurdere-tilgangsniva/2723).


## 0 — Check prerequisites and build images (once) {#0-sjekk-fresetnader-og-bygg-images-ein-gong}

```bash
make check-prereqs
make build-docker-linkml && make build-docker-python && make build-docker-mcp-validator
```

## 1a. — Scaffold {#1a-scaffold}

```bash
make new-modell DOMAIN=<domene> NAME=<modell>
```

This creates:
```
src/linkml/<domain>/<modell>/
├── <modell>-schema.yaml       ← main schema with a stub class and a container class
├── build.yaml              ← publishing and generator configuration
├── description.md             ← optional description of the model (10–20 lines), injected into the portal index before the metadata table
└── examples/
    └── <modell>-eksempel.yaml ← example file with a minimal instance
```




For `make new-modell DOMAIN=eksempel NAME=tilskudd` the generated files look like this:

**`tilskudd-schema.yaml`**

```yaml
id: https://data.norge.no/eksempel/tilskudd
name: tilskudd
title: 'TODO: tittel for tilskudd'
description: Generert modell for 'tilskudd'.
version: 0.1.0
license: https://data.norge.no/nlod/no/2.0  # Andre gyldige lisensar: https://audunautomat.github.io/linkml-datamodellering-no/ap-no/common-ap-no/klasser/eulicence/
annotations:
  utgiver: https://data.norge.no/organizations/<orgnr>
  endringsdato: '<dagens dato>'
  utgivelsesdato: '<dagens dato>'
  status: http://purl.org/adms/status/UnderDevelopment

prefixes:
  linkml:   https://w3id.org/linkml/
  tilskudd: https://data.norge.no/eksempel/tilskudd/
  dct:      http://purl.org/dc/terms/
  dcat:     http://www.w3.org/ns/dcat#
  foaf:     http://xmlns.com/foaf/0.1/
  skos:     http://www.w3.org/2004/02/skos/core#
  xsd:      http://www.w3.org/2001/XMLSchema#
  rdf:      http://www.w3.org/1999/02/22-rdf-syntax-ns#
  rdfs:     http://www.w3.org/2000/01/rdf-schema#

default_prefix: https://data.norge.no/eksempel/tilskudd/
default_range: string

imports:
  - linkml:types
  - https://raw.githubusercontent.com/AudunAutomat/linkml-datamodellering-no/dcat-ap-no-v2.13.0/src/linkml/ap-no/dcat-ap-no/dcat-ap-no-schema  # TODO: endre/legg til imports etter behov

subsets:
  Obligatorisk:
    description: Obligatoriske eigenskapar.
  Anbefalt:
    description: Anbefalte eigenskapar.
  Valgfri:
    description: Valfrie eigenskapar.

classes:
  TilskuddContainer:
    description: containerklasse for serialisering av klasser i tilskudd modellen
    tree_root: true
    attributes:
      tilskudder:
        description: TODO: beskriv eigenskapen
        range: Tilskudd
        multivalued: true
        inlined: true
        inlined_as_list: true

  Tilskudd:                        # ← stub — already PascalCase, but give it a more meaningful name
    description: TODO: beskriv klassen
    class_uri: tilskudd:tilskudd   # ← replace with the actual vocabulary URI
    annotations:
      begrepsidentifikator: https://concept-catalog.fellesdatakatalog.digdir.no/collections/TODO
    slots:
      - id

slots:
  tilskudd_kontaktinformasjon:
    description: Kontaktinformasjon for ressursen.
    slot_uri: dcat:contactPoint
    range: uriorcurie

# TODO: Gi stub-klassen eit meir meiningsfullt navn.
# TODO: Legg til slots og slot_usage for eigenskapane i modellen.
```

The generated content (titles, descriptions and TODO comments) is in Norwegian, since
the models in this repository are written in Norwegian Bokmål.

The `id` slot is not defined locally in the draft — it is inherited via
the `common-ap-no` import of `dcat-ap-no`, which has the shared
`id` slot (`identifier: true`, `range: uriorcurie`). The `tilskudd_kontaktinformasjon` slot
is generated globally, prefixed with the schema's own unique name
(`tilskudd`) — structurally collision-free against all fixed AP-NO vocabulary slots
(e.g. the imported `kontaktpunkt` slot from `dcat-ap-no`, which has a
different `range`), since no AP-NO profile will ever use exactly your
schema name as a prefix. The slot is
**not** automatically added to the stub class's `slots:` list
(`dcat:contactPoint` typically belongs to dataset- or distribution-like
classes, not necessarily the generic domain stub) — add it to the
classes where it is relevant.

**What the TODO stubs mean**

| Stub | What to fill in |
|-------|-----------------|
| `title: 'TODO: tittel for …'` | A Norwegian Bokmål title, e.g. `Tilskuddsregister` |
| `class Tilskudd` (generic name) | Give the class a more meaningful Norwegian name, e.g. `Tilskuddsvedtak` (the name is already PascalCase) |
| `class_uri: tilskudd:tilskudd` | The actual RDF URI, e.g. `dcat:Dataset` or your own namespace |
| `begrepsidentifikator: …/TODO` | A URI from [data.norge.no/concepts](https://data.norge.no/concepts) |
| `description: TODO: beskriv klassen` | A Norwegian description of what the class represents |
| The `dcat-ap-no` import (TODO comment on the import line) | `dcat-ap-no` is already set as the default AP-NO profile, version-locked to a specific git tag. Switch to another profile or add more imports if the common slots of `dcat-ap-no` do not cover your needs |
| `license: https://data.norge.no/nlod/no/2.0` | Already set to the default (NLOD 2.0) — only change it if the model requires a different license, see [valid licenses](https://audunautomat.github.io/linkml-datamodellering-no/en/ap-no/common-ap-no/klasser/eulicence/) |
| `annotations.utgiver` | Derived automatically from the `path_patterns` lookup in `CODEOWNERS.md` for `DOMAIN`. Becomes `https://data.norge.no/organizations/TODO` if the domain has no registered owner there (the script then writes a warning to stderr) |
| `annotations.endringsdato`/`utgivelsesdato` | Set to today's date automatically — adjust if needed |
| `annotations.status` | Already set to `UnderDevelopment` ("Under preparation") — update as the model matures (see the ADMS status table in `CLAUDE.md`) |

`build.yaml` and `description.md` are also created with default content — see [Model manifest](build-config.md) for the list of fields.




**`examples/tilskudd-eksempel.yaml`**

```yaml
# Eksempel for tilskudd
# Tilpass instansane med reelle verdiar etter at skjemaet er ferdigstilt.
---
tilskudder:
  - id: tilskudd:eksempel-1
```



---

## 1b. (optional) Generate directly from an existing JSON Schema {#1b-om-nskjeleg-generer-direkte-fra-eksisterande-json-schema}

If you have a JSON Schema exported from another system, `new-modell` can generate
the schema **directly into the new directory structure** instead of the empty
stub schema from step 1a — with the same post-processing (id/name/title,
`annotations.utgiver`/dates, version-locked import) and an example data file filled with
placeholder values for mandatory/identifier slots:

```bash
make new-modell DOMAIN=<domene> NAME=<modell> JSON_SCHEMA=<path to json-schema>
```

Then continue to [step 2](#2-rediger-skjemaet) — class names are taken from the JSON
Schema's `$defs`/`definitions` names and are usually sensible already, but
descriptions, `slot_uri`/`class_uri` and example values are still marked TODO
and must be reviewed (see the TODO comments at the top of the generated schema).

## 1c. (alternative) Generate from JSON Schema in two steps, with inspection along the way {#1c-alternativ-generer-fra-json-schema-i-to-steg-med-inspeksjon-undervegs}

If you want to see/adjust the raw conversion before it lands in `src/linkml/`
(e.g. for a large or unusual JSON Schema), you can instead use the old,
manual three-step pattern. Put the JSON Schema file in `tmp/`, e.g. `tmp/modell.json`:

```bash
make mcp-linkml-modell-utkast SCHEMA=tmp/modell.json
# Silver annotations (utgiver, endringsdato, status) automatically:
make mcp-linkml-modell-utkast SCHEMA=tmp/modell.json POLICY=silver
```

→ generates `tmp/modell-schema.yaml` and runs an **automatic roundtrip test** to verify that the conversion is correct. Copy it to `src/linkml/<domain>/<modell>/<modell>-schema.yaml` if the test passes (note: this path does **not** do the post-processing from steps 1a/1b — id/name/title/annotations/import must be corrected manually after copying, and the example file must be written by hand).

## 2 — Edit the schema {#2-rediger-skjemaet}

See the [reference schema](https://github.com/AudunAutomat/linkml-datamodellering-no/blob/main/src/linkml/referanse/referansemodell/referansemodell-schema.yaml) for an example of a valid schema with explanations.

Open `src/linkml/<domain>/<modell>/<modell>-schema.yaml` and add classes, slots and imports. See [Import hierarchy](#importhierarki) and [What do you import?](#kva-importerer-du) below.



## 3 — Validate along the way {#3-valider-undervegs}

For quick validation you can lint the schema:
`make lint SCHEMA=src/linkml/<domain>/<modell>/<modell>-schema.yaml`

If you add new slots/classes or new `imports:` by hand (step 2), also check
that none of them collide with a name that already exists in the import chain —
`make new-modell` does this automatically when scaffolding, but it is not
repeated automatically on later manual editing:
`make check-import-duplicates SCHEMA=src/linkml/<domain>/<modell>/<modell>-schema.yaml`

Lint + validation against the medallion levels:
```bash
make mcp-linkml-valider-modell SCHEMA=src/linkml/<domain>/<modell>/<modell>-schema.yaml POLICY=bronze
make mcp-linkml-valider-modell SCHEMA=src/linkml/<domain>/<modell>/<modell>-schema.yaml POLICY=basis-no
make mcp-linkml-valider-modell SCHEMA=src/linkml/<domain>/<modell>/<modell>-schema.yaml POLICY=silver
make mcp-linkml-valider-modell SCHEMA=src/linkml/<domain>/<modell>/<modell>-schema.yaml POLICY=gold
```

| Policy | Checks |
|---|---|
| [`bronze`](https://github.com/AudunAutomat/linkml-datamodellering-no/blob/main/src/mcp-linkml-validator/policies/README.md) | Generic LinkML: `id`, `name`, `title` (error); `default_prefix` (absolute URI, error); `description`, `version`, `license` (warning); LinkML linter incl. PascalCase classes and snake_case slots (warning) |
| [`basis-no`](https://github.com/AudunAutomat/linkml-datamodellering-no/blob/main/src/mcp-linkml-validator/policies/README.md#basis-no) | Bronze + literal HTTPS `default_prefix` (error); `class_uri`, `slot_uri`, identifier, `begrepsidentifikator`, controlled vocabularies, ER diagram (warning) |
| [`silver`](https://github.com/AudunAutomat/linkml-datamodellering-no/blob/main/src/mcp-linkml-validator/policies/README.md) | Basis-no + `annotations.utgiver`, `annotations.endringsdato`, `annotations.status` (warning) + DCAT-AP-NO/DQV-AP-NO structural requirements (error) |
| [`gold`](https://github.com/AudunAutomat/linkml-datamodellering-no/blob/main/src/mcp-linkml-validator/policies/README.md) | Silver + FAIR F1-R1.3: full semantic interoperability |

See [Validation rules](../arkitektur/valideringsregler.md) for a complete overview of what is checked at each level.

`make mcp-linkml-valider-modell` additionally writes the result to
`src/linkml/<domain>/<modell>/validation/<versjon>/<policy>.json` and copies
it to `generated/<domain>/<modell>/validation/<versjon>/<policy>.json` — a
local `make docs-serve`/`docs-build` (after `make docs-publish`) will therefore
show the validation result immediately, without any extra step.

## 4 — Full test suite {#4-full-testsuite}
Lint + validation + all generators for one schema. Without `SCHEMA=` the test suite runs for all schemas.
```
make test SCHEMA=src/linkml/<domain>/<modell>/<modell>-schema.yaml
```



---

## Deleting a model {#slette-ein-modell}

```bash
make remove-modell DOMAIN=<domene> NAME=<modell>            # dry run — shows checks and files, deletes nothing
make remove-modell DOMAIN=<domene> NAME=<modell> CONFIRM=1  # deletes for real
```

Without `CONFIRM=1` the command only runs the checks and shows what would be
deleted. The command checks:

| Check | Type | Consequence |
|---|---|---|
| The model is listed under `submodels:` in another schema's `build.yaml` | Blocking | Remove the reference from the parent manifest before trying again |
| The model's schema is imported by another schema | Blocking | Remove the import from the other schema before trying again |
| `publish_external: true` and/or `published-uris.lock` exists | Warning | External catalog entries are **not** removed automatically — the repository never pushes. Consider deprecating instead, see [publisering-begrep.md](../publisering/publisering-begrep.md) § "Deprecating a concept" |

`generated/<domain>/<modell>/` and `mkdocs/docs/<domain>/<modell>/` are
build output and need no manual cleanup — they disappear automatically the next
time the generators and `make docs-publish`, respectively, run.

---

## Import hierarchy {#importhierarki}

```
linkml:types          (always)
    ↓
common-ap-no          (only the AP-NO profiles import this directly)
    ↓
dcat-ap-no / dqv-ap-no / skos-ap-no / …   (AP-NO profiles)
    ↓
domain model          (imports one or more AP-NO profiles)

fint-common           (only the FINT domain models import this)
    ↓
fint-administrasjon / fint-arkiv / …

fair-metadata         (can be imported by all domain models)
```

Domain models import the **AP-NO profiles** — not `common-ap-no` directly. They inherit types, subsets and slots from AP-NO automatically through the profiles.

---

## What do you import? {#kva-importerer-du}

| You are creating … | Import |
|---|---|
| An AP-NO profile | `linkml:types` + `../common/common-ap-no-schema` |
| A domain model (NGR etc.) | `linkml:types` + relevant AP-NO profile(s) |
| A FINT domain model | `linkml:types` + `../fint-common/fint-common-schema` |
| A model with FAIR metadata | `linkml:types` + `../../fair/fair-metadata/fair-metadata-schema` |

---

## What you get from the AP-NO profiles {#kva-far-du-fra-ap-no-profilane}

By importing an AP-NO profile you automatically inherit everything from `common-ap-no` — you do not need to import `common-ap-no` directly.

**Types from `common-ap-no`**

| Name | RDF type | Use |
|---|---|---|
| `LangString` | `rdf:langString` | Multilingual strings (title, description …) |
| `Duration` | `xsd:duration` | Duration, e.g. `PT15M` |
| `GYear` | `xsd:gYear` | Year, e.g. `2024` |
| `NonNegativeInteger` | `xsd:nonNegativeInteger` | Counts, sizes |

**Reusable slots (examples)**

```yaml
classes:
  MittObjekt:
    slots:
      - id          # identifier: true, range: uriorcurie
      - tittel      # slot_uri: dct:title, range: LangString
      - beskrivelse # slot_uri: dct:description, range: LangString
      - utgiver     # slot_uri: dct:publisher, range: uriorcurie
      - lisens      # slot_uri: dct:license, range: uriorcurie
```

See `src/linkml/ap-no/common/common-ap-no-schema.yaml` for the full list.

---

## FAIR compliance with fair-metadata {#fair-konformitet-med-fair-metadata}

To document that a resource is FAIR-compliant, import `fair-metadata`:

```yaml
imports:
  - linkml:types
  - ../../ap-no/dcat-ap-no/dcat-ap-no-schema
  - ../../fair/fair-metadata/fair-metadata-schema
```

Validate against the gold policy (the gold policy specifically validates FAIR compliance):

```bash
make mcp-linkml-valider-modell SCHEMA=src/linkml/<domain>/<modell>/<modell>-schema.yaml POLICY=gold
```

---

## Generated artifacts {#genererte-artefakter}

See [Generated artifacts](https://github.com/AudunAutomat/linkml-datamodellering-no/blob/main/README.en.md#generated-artifacts) in the README for a full overview of what is generated per schema.

---

## Adapting the manifest for generation and publishing {#tilpass-manifest-for-generering-og-publisering}

Each model has a `build.yaml` next to the schema file that controls which artifacts
are generated. `make new-modell` creates the default configuration automatically — all
generators on, no extra flags.

To turn off a generator or add flags, edit `build.yaml` and run:

```bash
make config.mk   # regenerate the Makefile configuration from all build.yaml files
```

See [Model manifest](build-config.md) for the list of fields and examples per
domain type (standard, FINT, AP-NO/FAIR).

---

## Reference schema {#referanseskjema}

[`src/linkml/referanse/referansemodell/referansemodell-schema.yaml`](https://github.com/AudunAutomat/linkml-datamodellering-no/blob/main/src/linkml/referanse/referansemodell/referansemodell-schema.yaml) is an annotated example schema showing all the main patterns used in this repository: container class, global slots, import from an AP-NO profile, `class_uri`/`slot_uri`, `LangString` and `in_subset`. Use it as a reference when you start a new schema.

---

## Modeling principles {#modelleringsprinsipp}

**Norwegian Bokmål** — all class names, slot names and descriptions are written in Bokmål. Exception: technical terms fixed in a specification (e.g. `dcat:Dataset` → `Datasett`).

**Slots, not attributes** — all properties are defined as global `slots:` at the top level, never as `attributes:` inside a class.

**Linking instead of inlining** — classes that can exist independently get an `id` slot with `identifier: true`. References to such classes shall *not* have `inlined: true`.

**Explicit URIs** — all classes shall have `class_uri` (except `tree_root` container classes). All slots shall have `slot_uri`.

**`slot_usage` for class-specific restrictions** — `required: true` and `in_subset:` are set in `slot_usage` on the class, not in the global slot definition.

---

## Checklist before committing {#sjekkliste-fr-innsjekking}

```
[ ] id is an HTTPS URI
[ ] title and description are set at schema level
[ ] version is set (e.g. "1.0.0")
[ ] license is set to https://data.norge.no/nlod/no/2.0
[ ] default_prefix is an absolute HTTPS URI ending in /
[ ] Imports AP-NO profile(s) — not common-ap-no directly
[ ] Class and slot names are in Norwegian Bokmål
[ ] All classes (except tree_root) have class_uri
[ ] All global slots have slot_uri
[ ] make mcp-linkml-valider-modell POLICY=bronze gives 0 errors
[ ] If validation_policy is silver or higher: annotations.utgiver, annotations.endringsdato,
    annotations.utgivelsesdato, annotations.status and annotations.oppdateringsfrekvens
    are filled in
[ ] make test runs without errors
```

### Optional: English description for internationally visible schemas {#valfritt-engelsk-skildring-for-internasjonalt-synlege-skjema}

Digdir's guideline for open data recommends English descriptions for data that are to be
visible internationally. This is **not a policy requirement**, but can be added as:

```yaml
annotations:
  title_en: "TODO: English title"
  description_en: "TODO: English description"
```

The translation requires domain knowledge about the content and is a judgment for the codeowner of the
individual schema — not something that is generated automatically or required by CI.

---

## Known limitations {#kjende-avgrensingar}

This guide covers the basic workflow for domain modeling in LinkML. 
The following limitations apply in the PoC phase:

### Validation {#validering}

- **BUG-1**: `rdflib_loader` does not reconstruct `LangString` values correctly from TTL in roundtrip testing ([bugs/langstring-rdflib-roundtrip.md](https://github.com/AudunAutomat/linkml-datamodellering-no/blob/main/bugs/langstring-rdflib-roundtrip.md))
- The MCP validator only runs the bronze/basis-no/silver/gold policies — no automatic validation against external APIs yet

### Generators {#generatorar}

- PlantUML diagrams are not generated for schemas with more than 50 classes (performance)
- The JSON Schema generator does not support `union_of` with more than two types
- AsyncAPI generation is experimental and not enabled by default

### Publishing {#publisering}

- Publishing to Felles Begrepskatalog is partially implemented — see [publisering-begrep.md](../publisering/publisering-begrep.md) for the actual status
- Model catalogs with `publish_external: true` are not yet registered automatically in data.norge.no — harvesting must be coordinated manually

**Complete overview:** See [BUGS.md](https://github.com/AudunAutomat/linkml-datamodellering-no/blob/main/BUGS.md) for a complete list of known bugs and workarounds.

**Report new problems:** Open a [GitHub Issue](https://github.com/AudunAutomat/linkml-datamodellering-no/issues) with the label `bug`.

## Related documentation {#relatert-dokumentasjon}

- [Publish to Felles Datakatalog](../publisering/publisering-modell.md) — pipeline and URI stability for the new schema
- [Import hierarchy](../arkitektur/importhierarki.md) — what you can import from and how
- [New organization](ny-org.md) — if the domain model belongs to a new organization
