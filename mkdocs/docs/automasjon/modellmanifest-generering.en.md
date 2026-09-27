---
i18n:
  source: modellmanifest-generering.md
  source_hash: sha256:81a8a11c5a0b381b903b798cc7eb1da260ddce0f1d7658863534250a15895ff2
---
# Model manifest generation {#modellmanifest-generering}

!!! note "Description"

    This page documents how model manifests (`<modell>-manifest.yaml`) are generated automatically for each LinkML schema as part of the `make domain-*` commands. The manifest is an Informasjonsmodell instance according to ModelDCAT-AP-NO and summarizes metadata about the model from 6 different sources.

## Overview {#oversikt}

The model manifest is a YAML data file containing metadata about a LinkML schema formatted according to [ModelDCAT-AP-NO](https://data.norge.no/specification/modelldcat-ap-no). The file is **generated automatically** by `make domain-*` (via `gen-informasjonsmodell-instance`) and collects metadata from:

1. `<modell>-schema.yaml` (top-level fields and annotations)
2. `build.yaml` (heimeside, har_del)
3. `CODEOWNERS.md` (kontaktpunkt)
4. The schema's local classes (inneholder_modellelement)
5. Generated artifacts (finnes_i_format)
6. `annotations.er_profil_av` (MVP workaround for DX-PROF)

**Output:** `src/linkml/<domain>/<modell>/metadata/<modell>-manifest.yaml`

## Metadata fields and sources {#metadata-felt-og-kjelder}

| ModelDCAT field | Content | Source | Field in source |
|---|---|---|---|
| `id` | URI of the model | `<modell>-schema.yaml` | `id` |
| `tittel` (nb/nn) | LangString transformation | `<modell>-schema.yaml` | `title` → `tittel.nb`, `annotations.tittel_nn` → `tittel.nn` |
| `beskrivelse` (nb/nn) | LangString transformation | `<modell>-schema.yaml` | `description` → `beskrivelse.nb`, `annotations.beskrivelse_nn` → `beskrivelse.nn` |
| `versjonsnummer` | Semantic versioning | `<modell>-schema.yaml` | `version` |
| `lisens` | Absolute URI (e.g. NLOD 2.0) | `<modell>-schema.yaml` | `license` |
| `utgiver` | Organization URI (data.norge.no) | `<modell>-schema.yaml` | `annotations.utgiver` |
| `endringsdato` | ISO 8601 date | `<modell>-schema.yaml` | `annotations.endringsdato` |
| `utgivelsesdato` | ISO 8601 date | `<modell>-schema.yaml` | `annotations.utgivelsesdato` |
| `status` | ADMS Status URI | `<modell>-schema.yaml` | `annotations.status` |
| `tema` | List of LOS theme URIs (optional) | `<modell>-schema.yaml` | `annotations.tema` |
| `dekningsomraade` | Geographic URI (optional) | `<modell>-schema.yaml` | `annotations.dekningsomraade` |
| `nokkelord` | LangString list (optional) | `<modell>-schema.yaml` | `annotations.nokkelord` |
| `heimeside` | `https://audunautomat.github.io/linkml-datamodellering-no/<domain>/<modell>/` | (generated) | mkdocs URL |
| `er_i_samsvar_med` | Standard instance (inline) | `build.yaml` | `external_spec_url` + `external_spec_label` |
| `har_del` | List of submodel URIs | `build.yaml` | `submodels` |
| `kontaktpunkt` | Kontaktopplysning instance (inline) | `CODEOWNERS.md` | `organizations[].contact_uri` + `organizations[].name` |
| `er_profil_av` | MVP workaround (optional) | `<modell>-schema.yaml` | `annotations.er_profil_av` |
| `inneholder_modellelement` | List of class_uri (excl. tree_root) | `<modell>-schema.yaml` | Local classes from `classes:` |
| `finnes_i_format` | GitHub raw URLs to `.ttl`, `.json`, `.owl`, `.yaml` etc. | (generated) | Generated artifacts in `generated/<domain>/<modell>/` |

## Generation process {#genereringsprosess}

### Step 1: `make domain-*` runs all generators {#steg-1-make-domain-kyrer-alle-generatorar}

```bash
make domain-ap-no
```

This runs (in order):

1. `gen-linkml` (merge-imports)
2. `gen-jsonld-context`, `gen-shacl`, `gen-python`, `gen-jsonschema`, `gen-owl`, `gen-rdf`
3. `gen-doc`, `gen-plantuml`, `gen-proto`, `gen-xsd`, `gen-openapi`, `gen-asyncapi`
4. **`gen-informasjonsmodell-instance`** (in parallel, after all artifacts have been generated)

### Step 2: `gen-informasjonsmodell-instance` collects metadata {#steg-2-gen-informasjonsmodell-instance-samlar-metadata}

**Script:** `src/assets/scripts/generate-informasjonsmodell.py`

**Input:** `src/linkml/<domain>/<modell>/<modell>-schema.yaml`

**Process:**

1. Read `<modell>-schema.yaml` (top-level fields + annotations)
2. Read `build.yaml` (heimeside, submodels)
3. Parse the YAML front matter of `CODEOWNERS.md` (match the schema path against `path_patterns`)
4. Extract local classes (from the `classes:` block, excluding `tree_root`)
5. Find generated artifacts (glob `generated/<domain>/<modell>/*`)
6. Generate GitHub raw URLs (auto-detected from `git remote`)
7. LangString transformation (nb/nn)
8. Inline Kontaktopplysning and Standard instances

**Output:** `src/linkml/<domain>/<modell>/metadata/<modell>-manifest.yaml`

### Step 3: Parallel execution {#steg-3-parallell-kyring}

Manifest generation runs phase-parallel together with the other steps in
the `domain-*` pipeline — automatically, with no user-controlled job count.

Error handling: Errors are logged, but the build process does not stop (warning).

## Example: generated manifest {#eksempel-generert-manifest}

**Source:** `src/linkml/ap-no/dcat-ap-no/dcat-ap-no-schema.yaml`

**Output:** `src/linkml/ap-no/dcat-ap-no/metadata/dcat-ap-no-manifest.yaml`

```yaml
# Generert av CI frå generate-informasjonsmodell.py — ikkje rediger manuelt
# Kjelder: <modell>-schema.yaml, build.yaml, CODEOWNERS.md, lokale klasser, genererte artefakter

id: https://data.norge.no/ap-no/dcat-ap-no
tittel:
  nb: DCAT-AP-NO
  nn: DCAT-AP-NO
beskrivelse:
  nb: Norsk applikasjonsprofil av DCAT-AP, modellert i LinkML med lenking framfor inlining.
  nn: Norsk applikasjonsprofil av DCAT-AP, modellert i LinkML med lenking framfor inlining.
versjonsnummer: 2.2.0
lisens: https://data.norge.no/nlod/no/2.0
utgiver: https://data.norge.no/organizations/991825827
endringsdato: '2026-07-04'
utgivelsesdato: '2023-01-01'
status: http://purl.org/adms/status/Completed

heimeside: https://audunautomat.github.io/linkml-datamodellering-no/ap-no/dcat-ap-no/

er_i_samsvar_med:
- id: https://informasjonsforvaltning.github.io/dcat-ap-no/
  tittel:
    nb: DCAT-AP-NO (Norsk applikasjonsprofil av DCAT-AP)
    nn: DCAT-AP-NO (Norsk applikasjonsprofil av DCAT-AP)
  har_referanse: https://informasjonsforvaltning.github.io/dcat-ap-no/

har_del:
- https://data.norge.no/ap-no/common-ap-no

kontaktpunkt:
- id: https://www.digdir.no/om-oss/kontakt-oss/887
  navn_vcard:
    nb: Digitaliseringsdirektoratet
    nn: Digitaliseringsdirektoratet
  har_kontaktside: https://www.digdir.no/om-oss/kontakt-oss/887

inneholder_modellelement:
- https://data.norge.no/ap-no/dcat-ap-no#Datasett
- https://data.norge.no/ap-no/dcat-ap-no#Katalog
- https://data.norge.no/ap-no/dcat-ap-no#Distribusjon

finnes_i_format:
- https://raw.githubusercontent.com/AudunAutomat/linkml-datamodellering-no/main/generated/ap-no/dcat-ap-no/dcat-ap-no-context.jsonld
- https://raw.githubusercontent.com/AudunAutomat/linkml-datamodellering-no/main/generated/ap-no/dcat-ap-no/dcat-ap-no-ontology.ttl
- https://raw.githubusercontent.com/AudunAutomat/linkml-datamodellering-no/main/generated/ap-no/dcat-ap-no/dcat-ap-no-schema.json
- https://raw.githubusercontent.com/AudunAutomat/linkml-datamodellering-no/main/generated/ap-no/dcat-ap-no/dcat-ap-no-shapes.ttl
- https://raw.githubusercontent.com/AudunAutomat/linkml-datamodellering-no/main/src/linkml/ap-no/dcat-ap-no/dcat-ap-no-schema.yaml
```

## Placement in the documentation portal {#plassering-i-dokumentasjonsportalen}

The model manifest is included in the model's `index.md` in two places:

### 1. Data model section (new, after the ER diagram) {#1-datamodell-seksjon-ny-etter-er-diagram}

**Sequence number:** 11 (after the ER diagram, before Classes)

**Source:** `mkdocs/lib/sections/datamodell.sh`

**Output:**

```markdown
## Datamodell

Kjelde-datamodell i LinkML-format: [`dcat-ap-no-schema.yaml`](../../../src/linkml/ap-no/dcat-ap-no/dcat-ap-no-schema.yaml)
```

### 2. Generated artifacts table (first row) {#2-generated-artifacts-tabell-frste-rad}

**Sequence number:** 16 (after Types, before Valideringsresultat)

**Source:** `mkdocs/lib/sections/artifacts.sh`

**Output:**

```markdown
## Generated artifacts

| Artefakt | Fil |
|----------|-----|
| Modellmanifest ihht Modelldcat-ap-no | [`dcat-ap-no-manifest.yaml`](dcat-ap-no-manifest.yaml) |
| SHACL Shapes | [`dcat-ap-no-shapes.ttl`](dcat-ap-no-shapes.ttl) |
| JSON-LD Context | [`dcat-ap-no-context.jsonld`](dcat-ap-no-context.jsonld) |
| ... | ... |
```

## Dependencies between generators {#avhengigheiter-mellom-generatorar}

Model manifest generation requires all artifacts to be generated first (for the `finnes_i_format` list):

```
make gen-linkml (merge-imports)
  ↓
make gen-jsonld-context, gen-shacl, gen-python, gen-jsonschema, gen-owl, gen-rdf (in parallel)
  ↓
make gen-doc, gen-plantuml, gen-proto (in parallel)
  ↓
make gen-informasjonsmodell-instance (in parallel) ← LAST STEP
  ↓
mkdocs/publish.sh (copies the manifest to mkdocs/docs/)
  ↓
mkdocs serve (the portal is ready)
```

## Commands {#kommandoar}

| Command | Description | Output |
|---|---|---|
| `make gen-informasjonsmodell-instance SCHEMA=<path>` | Generates the manifest for one schema | `src/linkml/<domain>/<modell>/metadata/<modell>-manifest.yaml` |
| `make domain-ap-no` | Generates all artifacts + manifests for the ap-no domain | 10 manifest files (common-ap-no, dcat-ap-no, dqv-ap-no, ...) |
| `make validate-informasjonsmodell-instance SCHEMA=<path>` | Validates the generated manifest against `modelldcat-katalog-schema.yaml` | Exit 0 (OK) or Exit 1 (error) |
| `make gen-modellkatalog-instance` | Collects all manifests into per-organization model catalog files | `src/linkml/modellkatalog/<org>/data/<org>/<org>.yaml` |

## Error handling {#feilhandtering}

If `gen-informasjonsmodell-instance` fails for a schema:

- The error message is logged to stdout/stderr
- `make domain-*` does **not** stop (warning instead of exit 1)
- Other schemas in the domain are still processed
- Check the log to find out which schema failed and why

**Common causes of errors:**

- Missing `build.yaml`
- Missing `annotations.utgiver` (required by the silver/gold policy)
- Invalid URI format in annotations
- CODEOWNERS.md is missing YAML front matter or a matching organization

## Related documentation {#relatert-dokumentasjon}

- [specs/done/manifest-som-modelldcat-datafil.md](https://github.com/AudunAutomat/linkml-datamodellering-no/blob/main/specs/done/manifest-som-modelldcat-datafil.md) — main spec for the ModelDCAT manifest design
- [specs/done/autogenerer-modellmanifest-i-domain-make.md](https://github.com/AudunAutomat/linkml-datamodellering-no/blob/main/specs/done/autogenerer-modellmanifest-i-domain-make.md) — implementation spec (generation in domain-*)
- [index-md-struktur.md](index-md-struktur.md) — structure of `index.md` per model
- [COMMANDS.md](https://github.com/AudunAutomat/linkml-datamodellering-no/blob/main/COMMANDS.md) — command reference (make targets)
