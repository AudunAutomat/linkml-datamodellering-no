---
i18n:
  source: ny-org.md
  source_hash: sha256:ed25b2d9cb37c6e2735754f70121e2a85a9124a4a4669118f5bc17783dc6a332
---
# Guide: new model owner {#rettleiing-ny-modelleigar}

!!! note "Description"

    This guide explains how a new organization starts using the repository to
    publish its own information models together with the Brønnøysund Register Centre and other organizations.

## Prerequisites {#fresetnader}

Same as for a [new domain model](ny-domenemodell.md):

```bash
make check-prereqs
make linkml-build-docker && make python-build-docker && make mcp-val-build
```

## Step 1 — Register the organization in CODEOWNERS.md {#steg-1-registrer-organisasjonen-i-codeownersmd}

Add the organization to the YAML front matter in `CODEOWNERS.md` (repository root).

```yaml
organizations:
  # ... existing organizations ...
  - alias: <alias>                          # short key, e.g. digdir, ssb, kartverket
    name: <Organisasjonsnavn>
    org_uri: https://data.norge.no/organizations/<9-digit organization number>
    catalog_slug: <alias>-modellkatalog     # directory name, e.g. digdir-modellkatalog
    catalog_title: "<Org> - Modellkatalog"
    contact_uri: https://<org-domene>/kontakt/modellforvaltning
    github_team: "@<github-org>/<team>"
    path_patterns:
      - src/linkml/<domain>/**              # the directories the organization owns
```

Send a **pull request** against `main` with this change. The repository administrator approves
the PR and gives the GitHub team write access to the repository (see `GOVERNANCE.md`).

## Step 2 — Scaffold the model catalog {#steg-2-scaffold-modellkatalog}

After the PR has been approved, create the directory structure:

```bash
make new-modellkatalog ORG=<alias>
```

This creates:
```
src/linkml/modellkatalog/<alias>-modellkatalog/
├── <alias>-modellkatalog-schema.yaml    ← LinkML schema for the catalog
├── build.yaml                         ← publish_external: true
├── examples/
│   └── <alias>-modellkatalog-eksempel.yaml
└── data/
    └── <alias>-modellkatalog/
        ├── <alias>-modellkatalog.yaml    ← catalog data file (with TODO values)
        └── build.yaml
```

Fill in the `TODO` values in the data file manually:
- `tittel` and `beskrivelse` of the catalog
- the `har_del` list (synchronized automatically later by `gen-modellkatalog-instance`, see Step 4)
- names of contact points in the `aktoerer` list

## Step 3 — Create domain models {#steg-3-opprett-domenemodellar}

```bash
make new-modell DOMAIN=<domene> NAME=<modell>
```

Open the generated schema file and set `annotations.utgiver` to the organization's URI:

```yaml
annotations:
  utgiver: https://data.norge.no/organizations/<orgnr>
  endringsdato: "YYYY-MM-DD"
  utgivelsesdato: "YYYY-MM-DD"
  status: http://purl.org/adms/status/UnderDevelopment
  oppdateringsfrekvens: http://publications.europa.eu/resource/authority/frequency/IRREG
```

See [New domain model](ny-domenemodell.md) for the complete guide on how to model.

## Step 4 — Synchronize the model catalog {#steg-4-synkroniser-modellkatalog}

!!! note "The whole catalog file is regenerated"

    `make gen-modellkatalog-instance` **regenerates the whole catalog file from
    scratch** based on each schema's generated information model instance, and
    writes no `TODO` stubs for fields such as `tema`/`lisens`/`kontaktpunkt` that
    lack a source. Top-level keys owned by other generators or by manual
    maintenance (e.g. `aktoerer`, `kvalitetsmaalingar`) are preserved.
    Check the diff after running it.

Once the schema has the correct `annotations.utgiver`, generate the
information model instance (if it does not exist already, e.g. via
`make domain-<domene>`) and then synchronize the catalog data file:

```bash
make gen-informasjonsmodell-instance SCHEMA=<path-to-schema>
make gen-modellkatalog-instance
```

The command finds all generated information model instances
(`metadata/modelldcat.yaml`) with `utgiver` matching the organization URI, and rebuilds
the organization's catalog data file from them.

**Convention:** The model catalog shall list **all** schemas the organization manages — including
models that are not finished yet. Set `annotations.status` to
`http://purl.org/adms/status/UnderDevelopment` for drafts. The model catalog is the
machine-readable overview required by the guideline *Veileder for tilgjengeliggjøring av åpne data*
(guideline for making open data available; cf. item 12 — "also for data that are not yet available"), so incomplete
models shall be visible in the catalog with the correct status, not left out until they are
ready.

## Step 5 — Validate {#steg-5-valider}

Validate each individual domain model:
```bash
make mcp-linkml-valider-modell SCHEMA=src/linkml/<domain>/<modell>/<modell>-schema.yaml POLICY=bronze
make mcp-linkml-valider-modell SCHEMA=src/linkml/<domain>/<modell>/<modell>-schema.yaml POLICY=silver
```

Validate the model catalog against the publishing policy:
```bash
make mcp-linkml-valider-modell \
  SCHEMA=src/linkml/modellkatalog/<alias>-modellkatalog/<alias>-modellkatalog-schema.yaml \
  POLICY=felles-datakatalog \
  INSTANCE=src/linkml/modellkatalog/<alias>-modellkatalog/data/<alias>-modellkatalog/<alias>-modellkatalog.yaml
```

See [Validation rules](../arkitektur/valideringsregler.md) for a complete overview.

## Step 6 — Send a pull request {#steg-6-send-pull-request}

Create a PR against `main` with:
- New domain models in `src/linkml/<domain>/`
- Updated `CODEOWNERS.md` (if not done in step 1)
- New catalog structure in `src/linkml/modellkatalog/<alias>-modellkatalog/`

CI runs lint, instance validation and policy checks automatically. All checks must pass
before the PR can be merged.

---

## Cross-agency collaboration {#tverretatleg-samarbeid}

### Importing an AP-NO profile {#importere-ap-no-profil}

All AP-NO profiles in `src/linkml/ap-no/` are common infrastructure and can be imported
by all domain models regardless of the owning organization:

```yaml
imports:
  - linkml:types
  - ../../ap-no/dcat-ap-no/dcat-ap-no-schema
```

### Proposing changes to common infrastructure {#foresla-endringar-i-felles-infrastruktur}

Changes to `src/linkml/ap-no/`, `src/assets/` or the `Makefile` require approval from the
repository administrator (see `GOVERNANCE.md`). Send a PR and state clearly in the PR description
why the change is needed and whether it is backwards compatible.

Breaking changes (removing/changing existing slots or classes) require an RFC process
with a 14-day discussion period — see `GOVERNANCE.md` for details.

### Referring to another organization's model {#referere-til-ein-annan-org-sin-modell}

All models in this repository are public and can be reused in other models.

Use the `schema_id` URI from the other organization's model as `slot_uri` or `class_uri`:

```yaml
imports:
  - linkml:types
  - ../../dcat-ap-no/dcat-ap-no-schema
  # Do not import directly from another organization's domain model —
  # use a common AP-NO import layer instead
```

---

## Access and contact {#tilgang-og-kontakt}

To get write access to the repository, contact the repository administrator via GitHub Issues.
See `GOVERNANCE.md` for the formal requirements and process.

---

## Known limitations {#kjende-avgrensingar}

This guide covers onboarding of new organizations in the repository. 
The following limitations apply in the PoC phase:

### Organizational structure {#organisasjonsstruktur}

- Every organization must have one common model catalog — support for several catalogs per organization is not implemented
- The GitHub team configuration requires all members to have write access to the whole repository (not only their own models)

### Automation {#automatisering}

- `make gen-modellkatalog-instance` regenerates the catalog file from information model instances, but does not automatically fill in fields without a source (e.g. `tema`/`lisens`)
- The `.github/CODEOWNERS` file must be updated manually based on `CODEOWNERS.md` — no automatic synchronization yet

### Collaboration {#samhandling}

- If two organizations need conflicting changes to the same AP-NO profile, this must be resolved through the RFC process (see GOVERNANCE.md)
- Conflict resolution mechanisms are not yet fully documented

**Complete overview:** See [BUGS.md](https://github.com/AudunAutomat/linkml-datamodellering-no/blob/main/BUGS.md) for a complete list of known bugs and workarounds.

**Report new problems:** Open a [GitHub Issue](https://github.com/AudunAutomat/linkml-datamodellering-no/issues) with the label `bug`.

## Related documentation {#relatert-dokumentasjon}

- [New domain model](ny-domenemodell.md) — create a new schema for the new organization
- [New concept catalog](ny-begrepsmodell.md) — create a new concept catalog for the new organization
- [GOVERNANCE.md](https://github.com/AudunAutomat/linkml-datamodellering-no/blob/main/GOVERNANCE.md) — roles, ownership and the RFC process
