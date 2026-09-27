---
i18n:
  source: ny-begrepsmodell.md
  source_hash: sha256:3e5439a6a781ba1fef4f8d96e05c5f7988f76087ebfc141663dfd3700dd6501f
---
# Guide: new concept catalog {#rettleiing-ny-begrepskatalog}

!!! warning "The scaffolding command has been removed"

    `make new-begrepskatalog` (scaffolding for the monolithic
    `BegrepContainer` format this page describes) has been removed, see
    [the specification for the rationale](https://github.com/AudunAutomat/linkml-datamodellering-no/blob/main/specs/done/make-target-namn-vs-funksjon.md).
    Use `make new-begrepssamling DOMAIN=<domene> NAME=<begrepssamling>` for
    new concept collections (a `begrep/` directory with one file per concept) — see
    [COMMANDS.md](https://github.com/AudunAutomat/linkml-datamodellering-no/blob/main/COMMANDS.md#ny-modellbegrepskatalogmodellkatalog).
    The rest of this page is maintained as a reference for the existing,
    monolithic format (`src/linkml/begrepskatalog/brreg-begrepskatalog`) —
    scaffold a new schema of that kind manually by copying that directory as a template
    should it ever be needed.

!!! note "Description"

    This guide shows how to create a new concept catalog in the repository —
    from file structure to RDF export ready for Felles Begrepskatalog.

## 0 — Prerequisites (once) {#0-fresetnader-ein-gong}

```bash
make check-prereqs
make mcp-begrep-build    # builds mcp-linkml-begrep-utkast
make mcp-val-build       # builds mcp-linkml-validator (for policy validation)
```

---

## 1 — Scaffold {#1-scaffold}

**Naming pattern:** `<org>-begrep` or `<fagdomene>-begrep` (subject domain), e.g. `digdir-begrep`, `ssb-begrep`, `ngr-begrep`.

```bash
# NO LONGER a make target — shown as a reference for the file structure
# the script (now removed) generated. Copy src/linkml/begrepskatalog/
# brreg-begrepskatalog/ as a template if a new monolithic schema is needed.
```

This creates:

```
src/linkml/begrepskatalog/<katalog>/
├── <katalog>-schema.yaml  ← schema with BegrepContainer and an import of skos-ap-no
├── build.yaml              ← publishing and generator configuration
├── description.md             ← optional description, injected into the portal
└── examples/
    └── <katalog>-eksempel.yaml  ← empty BegrepContainer stub
```

Then fill in `title`, `description` and `utgiver` in the schema file.

With `NAME=test-begrep` the generated files looked like this:

**`test-begrep-schema.yaml`**

```yaml
id: https://data.norge.no/begrepskatalog/test-begrep
name: test_begrep
title: 'TODO: <Organisasjon> - Begrepskatalog'
description: 'TODO: beskriv katalogen'
version: "0.1.0"
license: https://data.norge.no/nlod/no/2.0

annotations:
  utgiver: 'TODO: https://data.norge.no/organizations/<orgnr>'
  status: http://purl.org/adms/status/UnderDevelopment

prefixes:
  linkml: https://w3id.org/linkml/

default_prefix: https://data.norge.no/begrepskatalog/test-begrep/
default_range: string

imports:
  - linkml:types
  - ../../ap-no/skos-ap-no/skos-ap-no-schema

classes:

  BegrepContainer:
    tree_root: true
    attributes:
      begrep:
        range: Begrep
        multivalued: true
        inlined: true
        inlined_as_list: true
      # ... (collections, definitions, relations, organizations, contact points)
```

**`build.yaml`**

```yaml
publish_external: false
validation_policy: felles-begrepskatalog

generators:
  jsonld_context: true
  shacl: false
  python: false
  json_schema: true
  owl: false
  rdf: true
  protobuf: false
  erdiagram: true
  docs: true
  plantuml: false
  example_rdf: true
```

**`examples/test-begrep-eksempel.yaml`**

```yaml
# Eksempel for test-begrep
# Generer YAML-blokker med: make mcp-linkml-begrep-utkast-run (sjå steg 2)
---
BegrepContainer:
  begrep: []
```

---

## 2 — Generate YAML instances {#2-generer-yaml-instansar}

Use the `opprett_begrep` tool in `mcp-linkml-begrep-utkast` to build
YAML blocks.

### Example — generate one concept according to the concept catalog schema {#eksempel-generer-eitt-begrep-ihht-skjema-for-begrepskatalog}

Put the arguments in a JSON file, e.g. `tmp/mitt-begrep.json`:

```json
{
  "profil": "default",
  "base_uri": "https://begrep.<org>.no",
  "slug": "mitt-begrep",
  "anbefalt_term_nb": "mitt begrep",
  "definisjon_nb": "ein klar og presis formulering av kva omgrepet tyder",
  "kjelde_relasjon": "self-composed",
  "utgjevar_uri": "https://data.norge.no/organizations/<orgnr>",
  "fagomrade_uri": "https://psi.norge.no/los/tema/<slug>"
}
```

```bash
make mcp-linkml-begrep-utkast INPUT=tmp/mitt-begrep.json
```

The result is YAML blocks that can be pasted into the instance file
(`src/linkml/begrepskatalog/<katalog>/examples/<katalog>-eksempel.yaml`):

```yaml
# Generert av mcp-linkml-begrep-utkast — legg til i instansfila di
# Begrep: https://begrep.eksempel.no/mitt-begrep

begrep:
- id: https://begrep.eksempel.no/mitt-begrep
  anbefalt_term:
  - mitt begrep
  har_definisjon:
  - https://begrep.eksempel.no/def/mitt-begrep-nb
  identifikator_literal: https://begrep.eksempel.no/mitt-begrep
  kontaktpunkt_vcard:
  - https://begrep.eksempel.no/kontakt/begrepsansvarleg
  utgjevar: https://data.norge.no/organizations/<orgnr>
  fagomrade:
  - https://psi.norge.no/los/tema/<slug>
definisjoner:
- id: https://begrep.eksempel.no/def/mitt-begrep-nb
  tekst: ein klar og presis formulering av kva omgrepet tyder
  kjelde_relasjon: https://data.norge.no/vocabulary/relationship-with-source-type#self-composed
organisasjonar:
- id: https://data.norge.no/organizations/<orgnr>
kontaktpunkt:
- id: https://begrep.eksempel.no/kontakt/begrepsansvarleg
```

### Profile for your own organization {#profil-for-eigen-organisasjon}

Create `src/mcp-linkml-begrep-utkast/profiles/<org>.yaml` to preset
`base_uri`, `utgjevar_uri` and the contact point pattern — so you do not have to specify them
for each call. See `profiles/brreg.yaml` as an example.

### Mandatory fields per `Begrep` {#obligatoriske-felt-per-begrep}

| Field | Note |
|---|---|
| `id` | URI under the organization's own domain |
| `anbefalt_term` | At least one; nb and nn recommended |
| `definisjon` or `har_definisjon` | At least one |
| `identifikator_literal` | Same value as `id` |
| `kontaktpunkt_vcard` | URI to a contact point object defined locally |
| `utgjevar` | URI to an organization object defined locally |

---

## 3 — Validate {#3-valider}

```bash
# Quick syntax validation directly against the schema (via mcp-begrep-generator):
# → use the valider_begrep tool with yaml_innhald and skjema_sti

# Full policy validation — recommended before every commit:
make mcp-linkml-valider-modell \
  SCHEMA=src/linkml/begrepskatalog/<katalog>/<katalog>-schema.yaml \
  POLICY=basis-no
```

| Policy | Checks |
|---|---|
| `basis-no` | `id`, `name`, `title`, `description`; all classes have an identifier and a concept reference (inherits the generic `bronze`) |

---

## 4 — Generate RDF/Turtle {#4-generer-rdfturtle}

```bash
make domain-gen-examples DOMAIN=begrepskatalog
```

Output: `generated/begrepskatalog/<katalog>/<katalog>-eksempel.ttl`

This Turtle file is only for checking locally that the YAML instance is correctly
serialized. For publishing to Felles Begrepskatalog — see
[Publish to Felles Begrepskatalog](../publisering/publisering-begrep.md).

---

## 5 — CI pipeline {#5-ci-pipeline}

No changes to workflow files are needed. `validate.yml` and `generate.yml` automatically
pick up new schemas under `src/linkml/begrepskatalog/`. The pipeline runs on push to
`main` when files under `src/linkml/begrepskatalog/**` have changed.

---

## 6 — Data file for publishing (optional) {#6-datafil-for-publisering-valfritt}

Only needed for catalogs that are to be published to Felles Begrepskatalog.

**1.** Create `src/linkml/begrepskatalog/<katalog>/data/<katalog>/<katalog>.yaml` with stable production URIs.
Use `src/linkml/begrepskatalog/brreg-begrepskatalog/data/brreg-begrepskatalog/brreg-begrepskatalog.yaml` as a template — the same structure as the example file,
but without "under development" notes and with permanent `id:` values.

**2.** Create an empty URI lock file:

```bash
cat > src/linkml/begrepskatalog/<katalog>/published-uris.lock << 'EOF'
# Publiserte URI-ar for <katalog> — IKKJE endre eller slett eksisterande linjer.
# Nye URI-ar leggast til nedst etter publisering.
EOF
```

**3.** Validate the data file against the publishing policy:

```bash
make mcp-linkml-valider-modell \
  SCHEMA=src/linkml/begrepskatalog/<katalog>/<katalog>-schema.yaml \
  POLICY=felles-begrepskatalog \
  INSTANCE=src/linkml/begrepskatalog/<katalog>/data/<katalog>/<katalog>.yaml
```

For the complete guide on registration and URI stability:
see [Publish to Felles Begrepskatalog](../publisering/publisering-begrep.md).

---

## Related documentation {#relatert-dokumentasjon}

- [Concepts - domain index](../begrepskatalog/index.md)
- [Publish to Felles Begrepskatalog](../publisering/publisering-begrep.md) — pipeline and URI stability
- [`specs/done/begrep-modellering.md`](https://github.com/AudunAutomat/linkml-datamodellering-no/blob/main/specs/done/begrep-modellering.md) — complete technical specification
- [`src/mcp-linkml-begrep-utkast/README.md`](https://github.com/AudunAutomat/linkml-datamodellering-no/blob/main/src/mcp-linkml-begrep-utkast/README.md) — documentation for the MCP server
