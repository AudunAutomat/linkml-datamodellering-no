---
i18n:
  source: build-config.md
  source_hash: sha256:c073237ce572f10ad12538e3dd233c6696c399c699a6b84324d9a6fe99d3af69
---
# Build manifest (build.yaml) {#byggmanifest-buildyaml}

!!!note "What is `build.yaml`?"

    Each model under `src/linkml/<domain>/<modell>/` has a `build.yaml` that controls which artifacts are generated, which flags are used, and whether the model is to be published to an external catalog. `make new-modell` creates the file automatically with the default configuration.

## Two types of manifest {#to-typar-manifest}

### Schema manifest (has a `generators:` section) {#skjema-manifest-har-generators-seksjon}

Located next to the schema file:

```
src/linkml/<domain>/<modell>/build.yaml
```

```yaml
publish_external: false          # true to trigger publishing to an external catalog
validation_policy: silver        # bronze / basis-no / silver / gold / felles-datakatalog / felles-begrepskatalog
external_spec_url: https://informasjonsforvaltning.github.io/cpsv-ap-no/  # link to the official specification


generators:
  # Artifact generators
  jsonld_context: true
  shacl: true
  shacl_flags: ""
  python: true
  json_schema: true
  owl: true
  owl_flags: ""
  rdf: true
  protobuf: true
  example_rdf: true
  openapi: true
  graphql: true

  # Documentation generators
  erdiagram: true
  docs: true
  plantuml: true
```

### Data file manifest (lacks a `generators:` section) {#datafil-manifest-manglar-generators-seksjon}

Located inside `data/<datafil-katalog>/`:

```
src/linkml/<domain>/<modell>/data/<datafil-katalog>/build.yaml
```

```yaml
publish_external: true
validation_policy: felles-begrepskatalog

concepts:                   # optional — omit to publish the whole data file
  - https://begrep.brreg.no/foretaksnavn
  - https://begrep.brreg.no/nestleder
```

CI distinguishes the two types by whether the `generators:` section is present.

## Fields in the schema manifest {#felta-i-skjema-manifest}

### `submodels` (optional, not in active use) {#submodels-valfritt-ikkje-i-aktiv-bruk}

List of submodels belonging to this main model. The submodels must be located in the same
directory as the main model's schema.

The documentation portal (`make docs-publish`) will then:
- Show the submodels as indented sub-items under the main model in the navigation menu
- Add a "Submodels" section to the main model's `index.md`
- Add a "Submodel of" box to each submodel's `index.md`

**Use case:** Models split into several schemas to handle circular imports,
or to separate logical components that follow the structure of an external specification.

**Status (2026-08-17):** The field currently has **no active use cases**. The three
former uses (`dqv-core` under `dqv-ap-no`; `modelldcat-modell`/`modelldcat-katalog`
under `modelldcat-ap-no`) were turned into ordinary, standalone model directories —
see `specs/backlog/submodels-eigne-modellkatalogar-vurdering.md`. The rationale: physical
co-location was never what solved the circular import problem (it was the existence
of a separate, importable schema), and release-please's directory-based
package concept does not know `submodels:` — shared directories therefore never got correct
independent versioning/`endringsdato` (see
`specs/backlog/release-please-endringsdato-dekning-evaluering.md`). The field is kept
as a documented mechanism for a possible future, genuine circular import case
— not deleted.

**Example:**
```yaml
submodels:
  - <delmodell-navn>
```

### `external_spec_url` (optional) {#externalspecurl-valfritt}

URL to the official specification at the standardization organization (e.g. Digdir). 
If set, an info box with a link to the external specification is shown in `index.md`.

**Use case:** AP-NO profiles based on Digdir standards (DCAT-AP-NO, 
SKOS-AP-NO etc.). Domain model schemas usually do not have this field.

**Example:**
```yaml
external_spec_url: https://informasjonsforvaltning.github.io/dcat-ap-no/
```

### `external_spec_label` (optional) {#externalspeclabel-valfritt}

Link text for the official specification. If omitted, the schema name is used.

**Use case:** Give the link in the "Official reference" box a descriptive title
instead of the short schema name (e.g. "Spesifikasjon for tjeneste- og hendelsesbeskrivelser (CPSV-AP-NO)"
instead of "cpsv-ap-no").

**Example:**
```yaml
external_spec_url: https://informasjonsforvaltning.github.io/cpsv-ap-no/
external_spec_label: "Spesifikasjon for tjeneste- og hendelsesbeskrivelser (CPSV-AP-NO)"
```

### `publish_external` {#publishexternal}

`true` triggers publishing to an external catalog (Felles Datakatalog or Felles
Begrepskatalog) in CI. Default: `false`.

### `validation_policy` {#validationpolicy}

Points to the validation policy that `make domain-validate-data` uses for data files
under `data/`. Valid values:

| Value | Use case |
|---|---|
| [`bronze`](https://github.com/AudunAutomat/linkml-datamodellering-no/blob/main/src/mcp-linkml-validator/README.md#bronse) | Minimum requirements — generic, structurally correct LinkML |
| [`basis-no`](https://github.com/AudunAutomat/linkml-datamodellering-no/blob/main/src/mcp-linkml-validator/policies/README.md#basis-no) | Bronze + Digdir/repository requirements (URI mapping, identifier, concept reference) |
| [`silver`](https://github.com/AudunAutomat/linkml-datamodellering-no/blob/main/src/mcp-linkml-validator/README.md#s%C3%B8lv) | Recommended fields are filled in |
| [`gold`](https://github.com/AudunAutomat/linkml-datamodellering-no/blob/main/src/mcp-linkml-validator/README.md#gull) | All fields filled in, with quality checks |
| [`felles-datakatalog`](https://github.com/AudunAutomat/linkml-datamodellering-no/blob/main/src/mcp-linkml-validator/README.md#felles-datakatalog-felles-datakatalog) | ModelDCAT-AP-NO — publishing to Felles Datakatalog |
| [`felles-begrepskatalog`](https://github.com/AudunAutomat/linkml-datamodellering-no/blob/main/src/mcp-linkml-validator/README.md#felles-begrepskatalog-felles-begrepskatalog) | SKOS-AP-NO-Begrep — publishing to Felles Begrepskatalog |

### Generator flags {#generatorflag}

The boolean fields correspond 1:1 to the `build.yaml flag` column in
[the table of generated artifacts](https://github.com/AudunAutomat/linkml-datamodellering-no/blob/main/README.en.md#generated-artifacts)
in the README. All default to `true`.

In addition, there are two flag fields for generators that need extra parameters:

| Field | Type | Default | Description |
|---|---|---|---|
| `shacl_flags` | string | `""` | Extra flags for `gen-shacl`, e.g. `"--exclude-imports"` |
| `owl_flags` | string | `""` | Extra flags for `gen-owl`, e.g. `"--log_level ERROR"` |

## Examples {#eksempel}

**Default configuration** (NGR, OREG — all generators on, no flags):

```yaml
publish_external: false
validation_policy: silver

generators:
  # Artifact generators
  jsonld_context: true
  shacl: true
  shacl_flags: ""
  python: true
  json_schema: true
  owl: true
  owl_flags: ""
  rdf: true
  protobuf: true
  example_rdf: true
  openapi: true
  graphql: true

  # Documentation generators
  erdiagram: true
  docs: true
  plantuml: true
```

**FINT** (`rdf: false` because of HTTP errors when looking up the JSON-LD context; SHACL and OWL flags
to handle cross-schema class inheritance; `example_rdf: false` where the example file uses
FINT-style CURIEs that are not valid URIs):

```yaml
publish_external: false
validation_policy: silver

generators:
  jsonld_context: true
  shacl: true
  shacl_flags: "--exclude-imports"
  python: true
  json_schema: true
  owl: true
  owl_flags: "--log_level ERROR"
  rdf: false
  protobuf: true
  erdiagram: true
  docs: true
  plantuml: true
  example_rdf: false
  openapi: true
  graphql: true
```

**AP-NO / FAIR** (`example_rdf: false` — these schemas have no `tree_root` and
cannot be converted to RDF by `linkml-convert`):

```yaml
publish_external: false
validation_policy: basis-no

generators:
  jsonld_context: true
  shacl: true
  shacl_flags: ""
  python: true
  json_schema: true
  owl: true
  owl_flags: ""
  rdf: true
  protobuf: true
  erdiagram: true
  docs: true
  plantuml: true
  example_rdf: false
  openapi: true
  graphql: true
```

## How it works {#korleis-det-fungerer}

`gen-config.sh` reads all schema `build.yaml` files and writes `config.mk` — a
Makefile fragment with per-model variables that the Makefile includes automatically.
`config.mk` is regenerated automatically when a `build.yaml` file changes. You
can also regenerate it manually:

```bash
make config.mk
```

`config.mk` is generated and must not be edited by hand.

## New models {#nye-modellar}

`make new-modell DOMAIN=... NAME=...` creates a default `build.yaml` together with
the schema file. Adjust it afterwards if the domain requires it — for example for FINT models
where `rdf` and `example_rdf` must be `false`.
