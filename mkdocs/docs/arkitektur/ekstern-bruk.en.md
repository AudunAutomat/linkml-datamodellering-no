---
i18n:
  source: ekstern-bruk.md
  source_hash: sha256:b203a3ba23503065f51ce2a5dd31f31d32e23c1d4797ef00ffac4906eaacf92f
---
# Use from an external repository {#bruk-fra-eksternt-repo}

!!! note "Description"

    This guide shows how an external repository can use the AP-NO profiles and the tools in this repository — without copying files or living inside the monorepo.

All you need is **two files** and a simple bootstrap step.

---

## Bootstrap (one command) {#bootstrap-ein-kommando}

In the root of your own repository:

```bash
curl -sSL https://raw.githubusercontent.com/AudunAutomat/linkml-datamodellering-no/main/bootstrap.sh | bash
```

To pin a specific version of the tools (repository-level tag `vX.Y.Z`):

```bash
curl -sSL https://raw.githubusercontent.com/AudunAutomat/linkml-datamodellering-no/main/bootstrap.sh \
  | AP_NO_VERSION=v1.1.0 bash
```

Without a version, bootstrap resolves `latest` to the newest `vX.Y.Z` and locks
`uses: …@vX.Y.Z` in the generated workflow.

The script creates:

| File | Contents |
|---|---|
| `linkml-datamodellering.yaml` | Pins the AP-NO version for this repository |
| `.github/workflows/linkml.yml` | Minimal GitHub Actions setup for validation |

---

## Schema URLs and versioning {#versjonerte-artefakter}

All schemas in this repository are available via GitHub Raw with a
version tag or `main`:

```
https://raw.githubusercontent.com/AudunAutomat/linkml-datamodellering-no/{versjon}/{sti}
```

GitHub Pages URLs (`https://audunautomat.github.io/linkml-datamodellering-no/...`)
always point to the latest version on `main`. For a **stable, versioned
address** to a historical version — e.g. for imports from an external
repository — use instead:

- **[GitHub Releases](https://github.com/AudunAutomat/linkml-datamodellering-no/releases)** (recommended) — the canonical address for older versions
- **A `raw.githubusercontent.com` URL with a tag**, as above

!!! note "Releases from before September 2026"
    The repository was moved from `brreg/linkml-datamodellering-no` to
    `AudunAutomat/linkml-datamodellering-no` in September 2026. All
    version tags were moved along, but GitHub Releases (with uploaded
    artifacts) from before the move are still located under
    [github.com/brreg/linkml-datamodellering-no/releases](https://github.com/brreg/linkml-datamodellering-no/releases).
    New releases are published in the new repository.

!!! tip "Recommendation"
    Always use a **schema-specific version tag** (e.g. `dcat-ap-no-v2.13.0`, `common-ap-no-v1.0.0`) in imports — never `main` or `latest` — to avoid surprising changes when this repository is updated.

!!! warning "Schema-specific tags"
    General release tags (`v1.0.0`, `v1.1.0`) point to a specific commit, but do **not** guarantee that all schema files exist in that commit. Use **schema-specific tags** (e.g. `dcat-ap-no-v2.13.0`, `common-ap-no-v1.0.0`) for stable import URLs.

### AP-NO profiles {#ap-no-profilar}

| Profile | Import URL (`versjon`) | Use case |
|---|---|---|
| `dcat-ap-no` | `https://raw.githubusercontent.com/AudunAutomat/linkml-datamodellering-no/dcat-ap-no-v2.13.0/src/linkml/ap-no/dcat-ap-no/dcat-ap-no-schema` | Data catalogs and datasets |
| `skos-ap-no` | `https://raw.githubusercontent.com/AudunAutomat/linkml-datamodellering-no/skos-ap-no-v2.16.0/src/linkml/ap-no/skos-ap-no/skos-ap-no-schema` | Concept collections |
| `modelldcat-ap-no` | `https://raw.githubusercontent.com/AudunAutomat/linkml-datamodellering-no/modelldcat-ap-no-v1.10.0/src/linkml/ap-no/modelldcat-ap-no/modelldcat-ap-no-schema` | Information models |
| `dqv-ap-no` | `https://raw.githubusercontent.com/AudunAutomat/linkml-datamodellering-no/dqv-ap-no-v1.15.0/src/linkml/ap-no/dqv-ap-no/dqv-ap-no-schema` | Data quality |
| `cpsv-ap-no` | `https://raw.githubusercontent.com/AudunAutomat/linkml-datamodellering-no/cpsv-ap-no-v1.10.0/src/linkml/ap-no/cpsv-ap-no/cpsv-ap-no-schema` | Public services and events |
| `xkos-ap-no` | `https://raw.githubusercontent.com/AudunAutomat/linkml-datamodellering-no/xkos-ap-no-v1.0.0/src/linkml/ap-no/xkos-ap-no/xkos-ap-no-schema` | Extended classification |

!!! note "The `.yaml` extension is optional"
    LinkML resolves imports without a file extension — both variants work:
    `...dcat-ap-no-schema` and `...dcat-ap-no-schema.yaml`

Example of the import section in an external schema:

```yaml
imports:
  - linkml:types
  - https://raw.githubusercontent.com/AudunAutomat/linkml-datamodellering-no/dcat-ap-no-v2.13.0/src/linkml/ap-no/dcat-ap-no/dcat-ap-no-schema
```

---

## GitHub Actions: reusable workflows {#github-actions-reusable-workflows}

### Validation {#validering}

```yaml
# .github/workflows/linkml.yml
name: LinkML

on: [push, pull_request]

jobs:
  validate:
    uses: AudunAutomat/linkml-datamodellering-no/.github/workflows/reusable-validate.yml@main
    with:
      schema: src/linkml/mitt-domene/min-modell/min-modell-schema.yaml
      policy: bronze
```

| Input | Type | Default | Description |
|---|---|---|---|
| `schema` | string | — (required) | Path to the schema file, relative to the repository root |
| `policy` | string | `bronze` | Validation policy: `bronze` (generic LinkML) / `basis-no` / `silver` / `gold` / `felles-datakatalog` / `felles-begrepskatalog` |
| `instance` | string | (automatic) | Path to the data file — found automatically in `examples/` if not specified |
| `version` | string | (from `linkml-datamodellering.yaml`) | Overrides the version read from the configuration file |

### Lint {#lint}

```yaml
jobs:
  lint:
    uses: AudunAutomat/linkml-datamodellering-no/.github/workflows/reusable-lint.yml@main
    with:
      schema: src/linkml/mitt-domene/min-modell/min-modell-schema.yaml
```

Runs the same style check (`linkml lint`, naming conventions/URIs/mandatory fields) and
name collision check against imported schemas as a local `make lint`.

| Input | Type | Default | Description |
|---|---|---|---|
| `schema` | string | — (required) | Path to the schema file, relative to the repository root |
| `version` | string | (from `linkml-datamodellering.yaml`) | Overrides the version read from the configuration file |

### Generating artifacts {#generering-av-artefakter}

```yaml
jobs:
  generate:
    uses: AudunAutomat/linkml-datamodellering-no/.github/workflows/reusable-generate.yml@main
    with:
      schema: src/linkml/mitt-domene/min-modell/min-modell-schema.yaml

  use-artifact:
    needs: generate
    runs-on: ubuntu-22.04
    steps:
      - uses: actions/download-artifact@v8
        with:
          name: ${{ needs.generate.outputs.artifact-name }}
```

The workflow reads `build.yaml` from the schema directory and runs the generators that are enabled
(`jsonld_context`, `json_schema`, `python`, `shacl`, `owl`, `rdf`, `protobuf`, `example_rdf`).
See [Generator configuration](../kom-i-gang/build-config.md) for details.

---

## Version-pinned setup {#versjonsfesta-oppsett}

`linkml-datamodellering.yaml` in the root of your repository pins the version:

```yaml
# linkml-datamodellering.yaml
ap-no-version: latest
```

The reusable workflows read this file automatically and use the right version of
the container images and AP-NO schemas. You do not need to pass the `version` input explicitly.

| `ap-no-version` | Behavior |
|---|---|
| `latest` | Resolved to the newest repository-level tag `vX.Y.Z` on each run (floating) |
| `v1.1.0` | Uses exactly this tool version: the same tag for scripts and container images |
| (file missing) | Same as `latest` |

!!! warning "Tool version ≠ schema version"
    `ap-no-version` is the **tool version** of this repository (`latest` or
    `vX.Y.Z`). It controls the reusable workflows, scripts and container images.
    The **schema version** of an AP-NO profile (e.g. `dcat-ap-no-v2.14.3`) is
    locked in the `imports:` URL in your schema (see
    [Schema URLs and versioning](#versjonerte-artefakter)). A schema tag used as
    `ap-no-version` is rejected with an error message.

---

## Automatic upgrades with Renovate {#automatisk-oppgradering-med-renovate}

[Renovate](https://docs.renovatebot.com/) can open a PR automatically every time there is
a new release of `linkml-datamodellering-no`. Copy the template to the root of your repository:

```bash
curl -sSL https://raw.githubusercontent.com/AudunAutomat/linkml-datamodellering-no/main/.github/renovate.json \
  -o renovate.json
```

Or fetch it together with bootstrap:

```bash
curl -sSL https://raw.githubusercontent.com/AudunAutomat/linkml-datamodellering-no/main/.github/renovate.json \
  -o renovate.json
# (bootstrap.sh has already been run)
```

`renovate.json` looks for new tool versions in `ap-no-version:` in
`linkml-datamodellering.yaml` **and** in `uses: …/reusable-*.yml@vX.Y.Z` in
your workflows, and uses GitHub Releases for `vX.Y.Z` as the source:

```json
{
  "customManagers": [{
    "customType": "regex",
    "fileMatch": ["^linkml-datamodellering\\.yaml$"],
    "matchStrings": ["ap-no-version:\\s*(?<currentValue>\\S+)"],
    "depNameTemplate": "AudunAutomat/linkml-datamodellering-no",
    "datasourceTemplate": "github-releases"
  }, {
    "customType": "regex",
    "fileMatch": ["^\\.github/workflows/[^/]+\\.ya?ml$"],
    "matchStrings": ["AudunAutomat/linkml-datamodellering-no/\\.github/workflows/[^@\\s]+@(?<currentValue>v\\d+\\.\\d+\\.\\d+)"],
    "depNameTemplate": "AudunAutomat/linkml-datamodellering-no",
    "datasourceTemplate": "github-releases"
  }]
}
```

!!! note "Do you already have a renovate.json?"
    Just add the `customManagers` and `packageRules` blocks from
    [`renovate.json`](https://raw.githubusercontent.com/AudunAutomat/linkml-datamodellering-no/main/.github/renovate.json)
    to your existing configuration. Do not duplicate `extends`.

---

## Local development {#lokal-utvikling}

### 0 — Check prerequisites {#0-sjekk-fresetnader}

Before you run the podman examples below, check that Podman (rootless), user
namespace mapping and disk space are configured correctly:

```bash
curl -sSL https://raw.githubusercontent.com/AudunAutomat/linkml-datamodellering-no/main/src/assets/scripts/makefile/check-prereqs.bash | bash
```

The script requires no access to this repository's Makefile or
directory structure — it only checks system prerequisites (Git, Podman,
rootless Podman, `/etc/subuid`/`/etc/subgid`, disk space) and therefore works
identically in an external repository.

### 1 — Validate and generate artifacts {#1-valider-og-generer-artefakter}

The container images are publicly available from GHCR — no login is needed:

```bash
# Structural validation (fail-fast, no file written)
podman run --rm \
  -v "$(pwd):/work" -w /work \
  ghcr.io/audunautomat/linkml-local:latest \
  gen-linkml src/linkml/mitt-domene/min-modell/min-modell-schema.yaml

# Style check (naming conventions, URIs, mandatory fields)
podman run --rm \
  -v "$(pwd):/work" -w /work \
  ghcr.io/audunautomat/linkml-local:latest \
  linkml lint src/linkml/mitt-domene/min-modell/min-modell-schema.yaml

# Generate JSON Schema
podman run --rm \
  -v "$(pwd):/work" -w /work \
  ghcr.io/audunautomat/linkml-local:latest \
  gen-json-schema src/linkml/mitt-domene/min-modell/min-modell-schema.yaml
```

Available image tags: `latest`, `main`, schema-specific tags (`dcat-ap-no-v2.13.0`, …)

!!! note "`linkml lint` without `--config` uses a different rule set than CI"
    This repository's own lint configuration
    ([`.linkmllint.yaml`](https://raw.githubusercontent.com/AudunAutomat/linkml-datamodellering-no/main/src/assets/containers/.linkmllint.yaml))
    turns off the `standard_naming` rule (which otherwise expects English
    naming conventions, in conflict with Norwegian Bokmål naming). Without this
    configuration, `linkml lint` uses its own default rule set. For
    identical behavior to CI, fetch the configuration and add `--config
    .linkmllint.yaml` to the call above.

!!! warning "Policy validation (bronze/basis-no/silver/gold) requires more than one podman command locally"
    `make mcp-linkml-valider-modell` (see [Guide: new domain model](../kom-i-gang/ny-domenemodell.md#3-valider-undervegs))
    uses `ghcr.io/audunautomat/mcp-linkml-validator` — the image **is** publicly
    available, but unlike `gen-linkml`/`linkml lint` above it is not
    enough to mount the schema into it: the validation logic itself is
    controlled by `flatten-and-validate.bash` and the `policies/` directory, which must be
    fetched from this repository and mounted together with the image (see
    `src/mcp-linkml-validator/flatten-and-validate.bash`). `gen-linkml`/
    `linkml lint` above cover structural validation and the style check directly;
    for the full basis-no/silver/gold policy (`begrepsidentifikator`,
    `annotations.utgiver` etc.) the GitHub Actions workflow from
    [Bootstrap](#bootstrap-ein-kommando) is the simplest route — it fetches
    these support files and runs full policy validation automatically via
    `reusable-validate.yml`.

### 2 — Model/concept draft assistance via MCP {#2-modell-begrepsutkast-assistanse-via-mcp}

`mcp-linkml-modell-utkast` (LinkML schema drafts from JSON Schema/an empty schema) and
`mcp-linkml-begrep-utkast` (SKOS-AP-NO concept drafts) are, unlike
`mcp-linkml-validator` above, **completely self-contained** container images —
the source code is baked in at build time, not bind-mounted from this repository. An
external repository can therefore use them directly from Claude Code (or another
MCP-compatible tool) without any local checkout of the source code, by adding
this to its own `.mcp.json`:

```json
{
  "mcpServers": {
    "linkml-modell-utkast": {
      "type": "stdio",
      "command": "podman",
      "args": ["run", "-i", "--rm", "ghcr.io/audunautomat/mcp-linkml-modell-utkast:latest"]
    },
    "linkml-begrep-utkast": {
      "type": "stdio",
      "command": "bash",
      "args": [
        "-c",
        "REPO=$(git rev-parse --show-toplevel) && podman run -i --rm -v \"$REPO:/repo:ro\" -v \"$REPO/src/linkml:/repo/src/linkml:rw\" ghcr.io/audunautomat/mcp-linkml-begrep-utkast:latest"
      ]
    }
  }
}
```

`mcp-linkml-modell-utkast` needs no mount at all — it generates a
schema draft from input and returns it via the MCP tool call, without reading or
writing files in the calling repository.

`mcp-linkml-begrep-utkast` **writes** generated concept files to
`<repo>/src/linkml/<domain>/<begrepssamling>/begrep/<slug>.yaml` — so mount
the repository (read/write, as above). If the external repository does not follow the
`src/linkml` convention, set `SCHEMA_ROOT` to the right directory:

```json
"args": [
  "-c",
  "REPO=$(git rev-parse --show-toplevel) && podman run -i --rm -e SCHEMA_ROOT=schema -v \"$REPO:/repo:ro\" -v \"$REPO/schema:/repo/schema:rw\" ghcr.io/audunautomat/mcp-linkml-begrep-utkast:latest"
]
```

!!! tip "Version pinning"
    Replace `:latest` with a schema-specific version tag (the same convention as
    [Schema URLs and versioning](#versjonerte-artefakter)) for reproducible
    results — `:latest` may give a different schema draft pattern after a future
    update of the policies in `mcp-linkml-modell-utkast`/`mcp-linkml-begrep-utkast`.
