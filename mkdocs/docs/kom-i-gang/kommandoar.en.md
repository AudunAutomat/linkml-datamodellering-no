---
i18n:
  source: kommandoar.md
  source_hash: sha256:3dca8610956ae28224de4c569ffc23860b86308543684be23cbe2cd0af2fb05e
---
# Commands {#kommandoar}

All commands run via containers — no local Python installation is needed.

## Setup and prerequisites {#oppsett-og-fresetnadar}

| Command | Description | Output |
|---|---|---|
| `make check-prereqs` | Checks that Git, Podman, GNU make, user namespaces and free disk space are configured correctly | Writes OK/FEIL per prerequisite to stdout; exits with code 1 on failure |

## Building container images {#container-image-bygging}

Only needed on first use or after changes to a Dockerfile.

| Command | Description | Output |
|---|---|---|
| `make build-docker-linkml` | Builds the container image for artifact generation and validation. Only needed on first use or after changes to the Dockerfile. | Image `localhost/linkml-local:latest` |
| `make build-docker-mkdocs` | Builds the container image for the documentation portal. Only needed on first use or after changes to the Dockerfile. | Image `localhost/mkdocs-local:latest` |
| `make build-docker-python` | Builds the container image for Python tests. Only needed on first use or after changes to the Dockerfile. | Image `localhost/python-pytest:latest` |
| `make build-docker-mcp-modell-utkast` | Builds the container image for the model draft MCP server. | Image `localhost/mcp-linkml-modell-utkast:latest` |
| `make build-docker-mcp-begrep-utkast` | Builds the container image for the concept instance generator MCP server. | Image `localhost/mcp-linkml-begrep-utkast:latest` |
| `make build-docker-mcp-validator` | Builds the container image for the validator MCP server. | Image `localhost/mcp-linkml-validator:latest` |
| `make build-docker-avrotize` | Builds the container image for XSD generation via Avrotize. Needed for `make gen-xsd`. | Image `localhost/avrotize-local:latest` |
| `make build-docker-asyncapi` | Builds the container image for AsyncAPI CLI validation. Needed for `make gen-asyncapi`. | Image `localhost/asyncapi-cli-local:latest` |
| `make build-docker-plantuml` | Builds the container image for PlantUML diagrams. Needed for `make gen-plantuml`. | Image `localhost/plantuml:latest` |

## New model/concept catalog/model catalog {#ny-modellbegrepskatalogmodellkatalog}

| Command | Description | Output |
|---|---|---|
| `make new-modell DOMAIN=<domene> NAME=<modell>` | Creates the directory structure and boilerplate for a new LinkML domain model.  | `src/linkml/<domain>/<modell>/<modell>-schema.yaml`<br>`src/linkml/<domain>/<modell>/examples/<modell>-eksempel.yaml` |
| `make new-modellkatalog ORG=<alias>` | Creates the directory structure and boilerplate for a new organization catalog (model catalog + data catalog). `<alias>` must be registered in the `CODEOWNERS.md` front matter with `catalog_slug`. | `src/linkml/modellkatalog/<catalog_slug>/` |
| `make new-begrepssamling DOMAIN=<domene> NAME=<begrepssamling>` | Creates the directory structure for a new concept collection. | `src/linkml/<domain>/<begrepssamling>/` |

## Validation {#validering}

| Command | Description | Output |
|---|---|---|
| `make lint` | Lints all schemas in the repository. | OK/FEIL per schema to stdout; exits with code 1 on failure |
| `make lint SCHEMA=<sti>` | Lints a single schema quickly without running generators. Useful as a quick check during development. | OK/FEIL to stdout; exits with code 1 on failure |
| `make validate-instance SCHEMA=<sti> INSTANCE=<sti>` | Validates a data file against a schema without lint and generators. The fastest single check of data content. | OK/FEIL to stdout; exits with code 1 on failure |
| `make roundtrip SCHEMA=<sti>` | Runs only the roundtrip tests (JSON and TTL) for one schema. Faster than the full test suite — useful after schema changes that may affect serialization. | Test report for `roundtrip-json` and `roundtrip-ttl` to stdout; exits with code 1 on failure |
| `make roundtrip` | Runs roundtrip tests for all schemas in the repository. | Test report to stdout; exits with code 1 on failure |
| `make roundtrip-json-schema SCHEMA=<sti>` | Runs a roundtrip test specifically for JSON Schema generation. Verifies that YAML → JSON Schema → YAML gives the same result. | Test report to stdout; exits with code 1 on failure |
| `make test SCHEMA=<sti>` | Runs the full test suite (lint + validation + all generators) for one schema. | Combined test report to stdout; exits with code 1 on failure |
| `make test` | Lints all schemas and validates all example files in the whole repository. | Combined test report to stdout; exits with code 1 on failure |
| `make validate [DOMAIN=<domene>\|SCHEMA=<sti>]` | Validates all schemas (or limited to a domain/one schema) against the LinkML metaschema (structural validation, not policy). | Validation result per schema to stdout |
| `make mcp-linkml-valider-modell SCHEMA=<sti>` | Policy validation against `validation_policy` from build.yaml. POLICY can be overridden with `POLICY=<bronze\|silver\|gold\|felles-datakatalog\|felles-begrepskatalog>`. | Pass/fail per policy rule to stdout |
| `make validate-capture` | Generates validation results for all schemas and saves them to `src/linkml/<domain>/<modell>/validation/<version>/<policy>.json`. | JSON files with validation results |
| `make validate-capture DOMAIN=<domene>` | As above, limited to one domain. | JSON files with validation results |
| `make validate-capture SCHEMA=<sti>` | Generates validation results for one schema and saves them to `src/linkml/<domain>/<modell>/validation/<version>/<policy>.json`. | JSON file with validation results |
| `make validate-data DOMAIN=<domene>` | Validates all data files in `data/` directories in a domain against their `validation_policy` from build.yaml. Used in CI per domain. | Pass/fail per data file to stdout |
| `make validate-examples DOMAIN=<domene>` | Validates all example files in a domain against the corresponding schema. Used in CI per domain. | Pass/fail per example file to stdout; exits with code 1 on failure |
| `make validate-policy-logg SCHEMA=<sti>` | Policy validation with a full JSON log. Useful for debugging policy rules. | JSON log to stdout |
| `make validate-instance-logg SCHEMA=<sti> INSTANCE=<sti>` | Instance validation with a full JSON log. Useful for debugging validation errors. | JSON log to stdout |

### Validation policies {#validerings-policyar}

| Policy | Description |
|---|---|
| `bronze` | Generic LinkML baseline: mandatory metadata (`id`, `name`, `title`), `default_prefix`, recommended `description`/`version`/`license`, LinkML linter (incl. naming conventions) |
| `basis-no` | Bronze + Digdir/repository requirements: `class_uri`/`slot_uri`, identifier, concept reference, controlled vocabularies, ER diagram |
| `silver` | Basis-no + the schema imports DCAT-AP-NO and DQV-AP-NO |
| `gold` | Silver + FAIR checks F1-R1.3 (class_uri, license, provenance and more) |

`mcp-linkml-valider-modell` automatically flattens relative imports with LinkML's `gen-linkml --mergeimports` before validation, so that domain models with several schema layers work without adaptation.

### Publishing policies {#publiserings-policyar}

Used for schemas with `publish_external: true` in `build.yaml`. Checks that the schema
complies with the requirements of a specific external catalog. Inherits the `basis-no` layer.

| Policy | Description |
|---|---|
| `felles-datakatalog` | Bronze + import of ModelDCAT-AP-NO, a container class with `Modellkatalog` and `Informasjonsmodell`, mandatory fields for these classes (title, description, identifier, publisher, contact point) |
| `felles-begrepskatalog` | Bronze + import of SKOS-AP-NO-Begrep, a container class with `Begrep`, mandatory fields for `Begrep` (preferred term, definition, identifier, publisher, contact point) and `Samling` |

## Generating artifacts {#generering-av-artefakter}

### Per domain (recommended) {#per-domene-anbefalt}

Each `domain-*` target runs the following steps for all schemas in the domain:

1. **Validation**: `merge-imports` merges imports and validates the schema (the output is discarded)
2. **Artifact generation** (in parallel): JSON-LD context, SHACL, Python, JSON Schema, OWL, RDF, PlantUML, docs
3. **Example conversion**: Converts `*-eksempel.yaml` to RDF/Turtle (if `example_rdf: true`)
4. **Model manifest** (in parallel): Generates an information model instance according to ModelDCAT-AP-NO to `src/linkml/<domain>/<modell>/metadata/<modell>-manifest.yaml`

**Parallelization**: Steps 2 and 4 are phase-parallelized automatically — no
user-controlled job count.

Parallel runs show a timer per job: `→ gen-jsonld-context ap-no/dcat-ap-no (5.1s)`

| Command | Description | Output |
|---|---|---|
| `make domain-ap-no` | Validate + generate all artifacts for all AP-NO profiles (in parallel) | `generated/ap-no/` |
| `make domain-begrepskatalog` | Validate + generate all artifacts for the concept catalog models | `generated/begrepskatalog/` |
| `make domain-fair` | Validate + generate all artifacts for FAIR metadata | `generated/fair/` |
| `make domain-fint` | Validate + generate all artifacts for the FINT models | `generated/fint/` |
| `make domain-modellkatalog` | Validate + generate all artifacts for the model catalog models | `generated/modellkatalog/` |
| `make domain-ngr` | Validate + generate all artifacts for the NGR models | `generated/ngr/` |
| `make domain-oreg` | Validate + generate all artifacts for the OREG registers | `generated/oreg/` |
| `make domain-samt` | Validate + generate all artifacts for the SAMT models | `generated/samt/` |

### Individual artifacts {#enkeltartefakter}

All `gen-*` targets support three modes of use:
- **`make gen-<format>`** — generate for **all** schemas
- **`make gen-<format> DOMAIN=<domene>`** — generate for all schemas in **one domain**
- **`make gen-<format> SCHEMA=<sti>`** — generate for **one** specific schema

| Command | Description | Output |
|---|---|---|
| <a id="gen-jsonld-context"></a>`make gen-jsonld-context [DOMAIN=...] [SCHEMA=...]` | JSON-LD context | `generated/<domain>/<modell>/<modell>-context.jsonld` |
| <a id="gen-shacl"></a>`make gen-shacl [DOMAIN=...] [SCHEMA=...]` | SHACL shapes | `generated/<domain>/<modell>/<modell>-shapes.ttl` |
| <a id="gen-python"></a>`make gen-python [DOMAIN=...] [SCHEMA=...]` | Python data classes | `generated/<domain>/<modell>/<modell>-model.py` |
| <a id="gen-jsonschema"></a>`make gen-jsonschema [DOMAIN=...] [SCHEMA=...]` | JSON Schema | `generated/<domain>/<modell>/<modell>-schema.json` |
| <a id="gen-owl"></a>`make gen-owl [DOMAIN=...] [SCHEMA=...]` | OWL/Turtle ontology | `generated/<domain>/<modell>/<modell>-ontology.ttl` |
| <a id="gen-rdf"></a>`make gen-rdf [DOMAIN=...] [SCHEMA=...]` | RDF/Turtle graph of the schema | `generated/<domain>/<modell>/<modell>-schema.ttl` |
| <a id="gen-erdiagram-mermaid"></a>`make gen-erdiagram-mermaid [DOMAIN=...] [SCHEMA=...]` | Mermaid ER diagram | `generated/<domain>/<modell>/<modell>-erdiagram.md` |
| <a id="gen-schema-docs"></a>`make gen-schema-docs [DOMAIN=...] [SCHEMA=...]` | HTML class reference and Mermaid ER diagram | `generated/<domain>/<modell>/docs/` |
| <a id="gen-proto"></a>`make gen-proto [DOMAIN=...] [SCHEMA=...]` | Protocol Buffers schema | `generated/<domain>/<modell>/<modell>-schema.proto` |
| <a id="gen-plantuml"></a>`make gen-plantuml [DOMAIN=...] [SCHEMA=...]` | PlantUML diagram and SVG | `generated/<domain>/<modell>/diagrams/<modell>.svg` |
| <a id="gen-xsd"></a>`make gen-xsd [DOMAIN=...] [SCHEMA=...]` | XSD schema via Avrotize (only schemas with `xsd: true` in build.yaml) | `generated/<domain>/<modell>/<modell>-schema.xsd` |
| <a id="gen-asyncapi"></a>`make gen-asyncapi [DOMAIN=...] [SCHEMA=...]` | AsyncAPI 3.0 spec (only schemas with `asyncapi: true` in build.yaml) | `generated/<domain>/<modell>/<modell>-asyncapi.yaml` |
| <a id="gen-openapi"></a>`make gen-openapi [DOMAIN=...] [SCHEMA=...]` | OpenAPI 3.1 spec (only schemas with `openapi: true` in build.yaml) | `generated/<domain>/<modell>/<modell>-openapi.yaml` |
| <a id="gen-config"></a>`make gen-config [DOMAIN=...] [SCHEMA=...]` | Generator configuration from build.yaml | `generated/<domain>/<modell>/config.yaml` |
| <a id="gen-dqv-measurements"></a>`make gen-dqv-measurements [DOMAIN=...] [SCHEMA=...]` | DQV quality measurements for data catalog data | `generated/<domain>/<modell>/dqv-measurements.ttl` |
| <a id="gen-modelldcat-elements"></a>`make gen-modelldcat-elements [DOMAIN=...] [SCHEMA=...]` | ModelDCAT elements for model catalog data | `generated/<domain>/<modell>/modelldcat-elements.ttl` |
| <a id="convert-instance-rdf"></a>`make convert-instance-rdf [DOMAIN=<domene>]` | Convert example YAML to RDF/Turtle | `generated/<domain>/<modell>/<modell>-eksempel.ttl` |
| <a id="convert-data"></a>`make convert-data` | Convert production data files in `data/` subdirectories to RDF/Turtle (only `publish_external: true`) | `generated/<domain>/<katalog>/<katalog>.ttl` |
| <a id="clean"></a>`make clean` | Delete `generated/` | — |

New schemas under `src/linkml/<domain>/<modell>/` are discovered automatically — no Makefile changes needed.

### Maintenance {#vedlikehald}

| Command | Description | Output |
|---|---|---|
| <a id="gen-informasjonsmodell-instance"></a>`make gen-informasjonsmodell-instance SCHEMA=<sti>` | Generates a ModelDCAT metadata file (`metadata/modelldcat.yaml`) for a single schema. Collects data from 6 sources: schema.yaml (top level + annotations), build.yaml, CODEOWNERS.md, local classes, generated artifacts, er_profil_av. Generates inline Kontaktopplysning and Standard instances. | `src/linkml/<domain>/<modell>/metadata/modelldcat.yaml` |
| <a id="validate-informasjonsmodell-instance"></a>`make validate-informasjonsmodell-instance SCHEMA=<sti>` | Validates generated ModelDCAT metadata against modelldcat-katalog-schema.yaml with full LinkML validation. Checks YAML structure, mandatory fields, LangString format and inline instances. Runs in the LinkML container for correct schema resolution. **Convenience wrapper** for `make validate-instance` that auto-detects `metadata/modelldcat.yaml` and the schema path. | Pass/fail to stdout; exits with code 1 on failure |
| <a id="gen-modellkatalog-instance"></a>`make gen-modellkatalog-instance` | Generates per-organization model catalogs from all `metadata/modelldcat.yaml` files. Groups information model instances by publisher (from CODEOWNERS.md) and generates one catalog file per organization for publishing to Felles datakatalog. Converts standard URIs (`https://data.norge.no/...`) to organization-specific URIs (`https://<org-domene>/modellkatalogar/<catalog_slug>/...`). | `src/linkml/modellkatalog/<org>/data/<org>/<org>.yaml` |
| <a id="validate-modellkatalog-instance"></a>`make validate-modellkatalog-instance ORG=<alias>` | Validates a generated model catalog data file against the organization-specific schema. Example: `ORG=digdir`. `ORG=` is the CODEOWNERS alias (same form as `new-modellkatalog`/`gen-modelldcat-elements`), looked up against `catalog_slug`. Validates `src/linkml/modellkatalog/<catalog_slug>/data/<catalog_slug>/<catalog_slug>.yaml` against `src/linkml/modellkatalog/<catalog_slug>/<catalog_slug>-schema.yaml`. **Convenience wrapper** for `make validate-instance` that constructs the schema and instance paths automatically. | Pass/fail to stdout; exits with code 1 on failure |

## Documentation portal {#dokumentasjonsportal}

| Command | Description | Output |
|---|---|---|
| `make docs-publish` | Generate portal content for all languages, build trees and `mkdocs/build/mkdocs.<lang>.yml` | `mkdocs/docs/`, `mkdocs/build/` |
| `make docs-serve [DOCS_LANG=<lang>]` | Start a local dev server with live reload for one language | `http://localhost:8000/linkml-datamodellering-no/<lang>/` |
| `make docs-serve-site` | Serve the built portal (all languages, artifacts, redirects). Requires `make docs-build` | `http://localhost:8000/linkml-datamodellering-no/` |
| `make docs-build` | Build the static portal for all languages (CI pipeline for production) | `mkdocs/site/` |

`make docs-publish` runs `mkdocs/publish.sh`, which copies artifacts and documentation from `generated/` to `mkdocs/docs/`, generates `index.md` per schema and domain for each language, and writes the navigation structure to `mkdocs/build/mkdocs.<lang>.yml`. See [Multilingual portal](../automasjon/fleirsprak.md). New domains and schemas appear automatically the next time `publish` runs.

## LinkML model draft (mcp-linkml-modell-utkast) {#linkml-modell-utkast-mcp-linkml-modell-utkast}

| Command | Description | Output |
|---|---|---|
| `make build-docker-mcp-modell-utkast` | Builds the container image for the MCP server (one-time operation). | Image `localhost/mcp-linkml-modell-utkast:latest` |
| `make mcp-linkml-modell-utkast-smoke` | Runs a smoke test with example messages to verify that the server responds correctly. | Test result to stdout; exits with code 1 on failure |
| `make mcp-linkml-modell-utkast-test` | Runs all unit tests for the MCP server. | Test result to stdout; exits with code 1 on failure |
| `make mcp-linkml-modell-utkast SCHEMA=<sti>` | Generates a LinkML schema draft from a JSON Schema file using the MCP server. | `<same directory>/<modell>-schema.yaml` |
| `make mcp-linkml-modell-utkast SCHEMA=<sti> FORMAT=json-schema POLICY=default` | Same as above with explicit format and policy. | `<same directory>/<modell>-schema.yaml` |
| `make mcp-linkml-modell-utkast-run` | Starts the MCP server interactively. Useful for manual testing and troubleshooting. | JSON-RPC on stdin/stdout |

## LinkML concept draft (mcp-linkml-begrep-utkast) {#linkml-begrep-utkast-mcp-linkml-begrep-utkast}

| Command | Description | Output |
|---|---|---|
| `make build-docker-mcp-begrep-utkast` | Builds the container image for the MCP server (one-time operation). | Image `localhost/mcp-linkml-begrep-utkast:latest` |
| `make mcp-linkml-begrep-utkast-smoke` | Runs a smoke test with example messages to verify that the server responds correctly. | Test result to stdout; exits with code 1 on failure |
| `make mcp-linkml-begrep-utkast-list-profiles` | Lists all available organization profiles that can be used when creating concepts. | JSON list of profile IDs to stdout |
| `make mcp-linkml-begrep-utkast INPUT=<sti>` | Generates a YAML draft of a concept from a JSON file with arguments for `opprett_begrep`. | YAML blocks to stdout |
| `make mcp-linkml-begrep-utkast-run` | Starts the MCP server interactively. Useful for manual testing and troubleshooting. | JSON-RPC on stdin/stdout |

## LinkML validator (mcp-linkml-validator) {#linkml-validator-mcp-linkml-validator}

| Command | Description | Output |
|---|---|---|
| `make build-docker-mcp-validator` | Builds the container image for the validator MCP server (one-time operation). | Image `localhost/mcp-linkml-validator:latest` |
| `make mcp-linkml-valider-modell-smoke` | Runs a smoke test with example messages to verify that the server responds correctly. | Test result to stdout; exits with code 1 on failure |
| `make mcp-linkml-valider-modell-test` | Runs all policy tests for the validator MCP server. | Test result to stdout; exits with code 1 on failure |
| `make mcp-linkml-valider-modell-run` | Starts the validator MCP server interactively. Useful for manual testing and troubleshooting. | JSON-RPC on stdin/stdout |

## Easter egg: Gource visualization {#paskeegg-gource-visualisering}

Requires `make build-docker-gource` once (or after changes to the Dockerfile). Output files end up in `tmp/`.

| Command | Description | Output |
|---|---|---|
| `make build-docker-gource` | Builds the container image with Gource and ffmpeg. | Image `localhost/gource-local:latest` |
| `make gource-preview` | Generates a 30 fps preview video of the whole git history (fast, lower quality). | `tmp/gource-preview.mp4` |
| `make gource-video` | Generates a 60 fps full-quality video of the whole git history. | `tmp/gource.mp4` |
