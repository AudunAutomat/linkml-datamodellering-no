---
i18n:
  source: arkitektur-oversikt.md
  source_hash: sha256:db5e3a48c80ae64e1784d294ea414cbb83d2af1fe95645c32daf60722f520796
---
# Architecture overview {#arkitekturoversikt}

!!! note "Description"

    This page shows the essential parts of the repository and how they interact with external public services — from source schemas, via MCP servers and CI, to published artifacts and the national catalogs/organizations that harvest from them.

---

The sketch is split into two diagrams (instead of one wide one) to keep the text boxes
large and readable: part 1 covers the internal flow from source schemas to
published artifacts, part 2 covers how national catalogs, KUDAF and
organizations harvest from the published points. Invisible links (`~~~`) are only used
to force nodes without a real relationship to stack vertically instead of
spreading out horizontally — they do not represent a dependency.

## Part 1 — From source schemas to published artifacts {#del-1-fra-kildeskjema-til-publiserte-artefakter}

```mermaid
%%{init: {'themeVariables': {'fontSize': '20px'}}}%%
flowchart TB
    subgraph KILDE["src/linkml/ — source schemas"]
        direction TB
        PADKILDE[" "]
        COMMON["ap-no/common<br/>common slot definitions"]
        APNO["ap-no/*<br/>dcat-ap-no, skos-ap-no,<br/>modelldcat-ap-no, cpsv-ap-no,<br/>dqv-ap-no, xkos-ap-no"]
        FAIR["fair/fair-metadata"]
        FINTCOMMON["fint/fint-common"]
        DOMENE["domain models<br/>ngr-*, oreg-*, fint-*, samt-bu<br/>(tree_root container classes)"]
        BEGREP["begrepskatalog/*<br/>SKOS-AP-NO-Begrep + data/*.yaml"]
        MODELLKAT["modellkatalog/*<br/>ModelDCAT-AP-NO"]

        PADKILDE ~~~ COMMON
        COMMON --> APNO
        APNO --> DOMENE
        FAIR --> DOMENE
        FINTCOMMON --> DOMENE
        APNO --> BEGREP
        APNO --> MODELLKAT

   

    end

    subgraph MCP["MCP servers (local, podman)"]
        direction TB
        PADMCP[" "]
        AI["AI assistant<br/>(Claude and others)"]
        MCPMOD["mcp-linkml-modell-utkast"]
        MCPBEGREP["mcp-linkml-begrep-utkast"]
        MCPVAL["mcp-linkml-validator<br/>bronze/basis-no/silver/gold/<br/>felles-datakatalog/felles-begrepskatalog"]

        PADMCP ~~~ AI
        AI --> MCPMOD
        AI --> MCPBEGREP
        AI --> MCPVAL

    end

    MCPMOD -.->|"generates drafts of"| DOMENE
    MCPBEGREP -.->|"generates drafts of"| BEGREP
    MCPVAL -.->|"validates"| DOMENE
    MCPVAL -.->|"validates"| BEGREP
    MCPVAL -.->|"validates"| MODELLKAT
    MCPVAL ~~~ PADKILDE

    MCPVAL -.->|"validation results"| GHPAGES

    subgraph CI["GitHub Actions"]
        direction TB
        PADCI[" "]
        WFVALIDATE["validate.yml<br/>PR validation"]
        WFGENERATE["generate.yml<br/>build artifacts + mkdocs"]
        WFRELEASE["release.yml<br/>container images"]
        WFRELEASEPLEASE["release-please.yml<br/>versioning"]
        PADCI ~~~ WFVALIDATE
        PADCI ~~~ WFGENERATE
        PADCI ~~~ WFRELEASE
        PADCI ~~~ WFRELEASEPLEASE

    end

    DOMENE -->|"push / PR"| WFVALIDATE
    DOMENE --> WFGENERATE
    WFGENERATE --> GHPAGES
    PADKILDE ~~~ PADCI
    BEGREP ~~~ PADCI
    MODELLKAT ~~~ PADCI

    subgraph PUBLISERT["Published pull points"]
        direction LR
        PADPUB[" "]
        GHPAGES["GitHub Pages<br/>documentation portal"]
        GHRELEASES["GitHub Releases"]
        GHCR["GHCR<br/>container images"]
        RAWGH["raw.githubusercontent.com"]
        PADPUB ~~~ GHPAGES
        PADPUB ~~~ GHRELEASES
        PADPUB ~~~ GHCR
        PADPUB ~~~ RAWGH
    end

    WFRELEASE --> GHCR
    WFRELEASEPLEASE -->|"tag → release"| GHRELEASES
    PADCI ~~~ PADPUB
    WFVALIDATE ~~~ PADPUB
    WFGENERATE ~~~ PADPUB
    WFRELEASE ~~~ PADPUB
    WFRELEASEPLEASE ~~~ PADPUB

    DOMENE -.->|"imports via tag URL"| RAWGH
    APNO -.->|"imports via tag URL"| RAWGH

    classDef default fill:#f5f5f5,color:#000000,stroke:#888888;
    classDef ekstern fill:#fdeaea,color:#000000,stroke:#e74c3c;
    classDef ci fill:#e3f2fd,color:#000000,stroke:#2196f3;
    classDef mcp fill:#e1f5e1,color:#000000,stroke:#4caf50;
    classDef usynlig fill:none,stroke:none,color:transparent;
    class GHPAGES,GHRELEASES,GHCR,RAWGH ekstern
    class WFVALIDATE,WFGENERATE,WFRELEASE,WFRELEASEPLEASE ci
    class MCPMOD,MCPBEGREP,MCPVAL,AI mcp
    class PADKILDE,PADMCP,PADCI,PADPUB usynlig

    style KILDE fill:#fafafa,color:#000000,stroke:#cccccc
    style MCP fill:#fafafa,color:#000000,stroke:#cccccc
    style CI fill:#fafafa,color:#000000,stroke:#cccccc
    style PUBLISERT fill:#fafafa,color:#000000,stroke:#cccccc
```

## Part 2 — How national catalogs, KUDAF and organizations harvest from this repository {#del-2-korleis-nasjonale-katalogar-kudaf-og-verksemder-hentar-fra-dette-repoet}

```mermaid
%%{init: {'themeVariables': {'fontSize': '20px'}}}%%
flowchart BT
    GHPAGES2["GitHub Pages<br/>documentation portal<br/>(see part 1)"]
    RAWGH2["raw.githubusercontent.com<br/>(see part 1)"]
    REPOCI["this repository:<br/>reusable GitHub Actions"]
    ANCHOR2[" "]

    subgraph KATALOGAR["National catalogs and search services (harvest metadata)"]
        direction BT
        BEGREPSKAT["Felles Begrepskatalog<br/>concept-catalog.fellesdatakatalog.digdir.no"]
        DATAKAT["Felles Datakatalog<br/>data.norge.no"]
        KUDAFNODE["KUDAF data community<br/>Sikt/HK-dir, education and research sector"]
        PADKAT[" "]
        DATAKAT ~~~ BEGREPSKAT
        BEGREPSKAT ~~~ PADKAT
    end

    BEGREPSKAT -.->|"harvests concepts,<br/>see publisering-begrep.md"| GHPAGES2
    DATAKAT -.->|"harvests dataset metadata,<br/>see publisering-modell.md"| GHPAGES2

    subgraph KONSUMENTER["Organizations (PULL) — planned/future"]
        direction TB
        PADKON[" "]
        PRIVATKAT["Organization:<br/>private data catalog"]
        DATAPLATTFORM["Organization:<br/>private data platform"]
        APIGATEWAY["Organization:<br/>private API gateway"]
        PADKON ~~~ PRIVATKAT
        PRIVATKAT ~~~ DATAPLATTFORM
        DATAPLATTFORM -->|"exposes data via"| APIGATEWAY
    end

    subgraph EKSTERNREPO["External repository (bootstrap)"]
        direction TB
        PADEKS[" "]
        BOOTSTRAP["bootstrap.sh<br/>curl script"]
        EKSTERNSKJEMA["own LinkML schema<br/>imports an AP-NO profile"]
        PADEKS ~~~ BOOTSTRAP
        BOOTSTRAP ~~~ EKSTERNSKJEMA
    end

    EKSTERNSKJEMA --> RAWGH2
    BOOTSTRAP -.->|"fetches template from"| RAWGH2
    EKSTERNSKJEMA -->|"validation/generation"| REPOCI

    ANCHOR2 ~~~ PADKAT
    ANCHOR2 ~~~ PADKON

    KUDAFNODE -.->|"harvests dataset metadata<br/>via search API / SPARQL"| DATAKAT
    PRIVATKAT -.->|"search/API for<br/>dataset metadata"| DATAKAT
    PRIVATKAT -.->|"fetches schemas:<br/>SHACL · JSON Schema ·<br/>JSON-LD context · OWL"| GHPAGES2
    DATAPLATTFORM -.->|"fetches schemas for<br/>validation/typing"| GHPAGES2
    DATAPLATTFORM -.->|"imports LinkML schemas<br/>(tag-versioned)"| RAWGH2
    APIGATEWAY -.->|"fetches schemas for<br/>API contracts"| GHPAGES2

    classDef default fill:#f5f5f5,color:#000000,stroke:#888888;
    classDef ekstern fill:#fdeaea,color:#000000,stroke:#e74c3c;
    classDef ci fill:#e3f2fd,color:#000000,stroke:#2196f3;
    classDef konsument fill:#f0e6fa,color:#000000,stroke:#9b59b6;
    classDef usynlig fill:none,stroke:none,color:transparent;
    class GHPAGES2,RAWGH2 ekstern
    class REPOCI ci
    class PRIVATKAT,DATAPLATTFORM,APIGATEWAY konsument
    class PADKAT,PADKON,PADEKS,ANCHOR2 usynlig

    style KATALOGAR fill:#fafafa,color:#000000,stroke:#cccccc
    style EKSTERNREPO fill:#fafafa,color:#000000,stroke:#cccccc
    style KONSUMENTER fill:#fafafa,color:#000000,stroke:#cccccc
```

## Explanation of the essential parts {#forklaring-av-dei-vesentlege-delane}

- **Source schemas** (`src/linkml/`) — LinkML schemas organized in an
  import hierarchy (see `CLAUDE.md` § "LinkML Importhierarki"): the AP-NO profiles
  and FAIR metadata are non-standalone building blocks that the domain models
  import. `begrepskatalog/` and `modellkatalog/` are special cases that
  import AP-NO profiles in order to publish to external catalogs.
- **MCP servers** — three local container-based MCP servers let AI assistants
  generate schema drafts from JSON Schema, generate SKOS concept drafts, and
  validate schemas/instances against policy levels, without leaving the local environment.
- **GitHub Actions** — validates PRs, builds artifacts + the portal on push to
  `main`, builds/pushes container images on release tags, and captures
  validation history on release-please versioning. See
  [Artifact generation — sources and pipeline](../automasjon/artefakt-generering.md) § 5 for
  the detailed CI order, and [Monitoring the automation](../automasjon/monitorering.md)
  for how to read the logs from these workflows.
- **Published pull points** — the repository **is never pulled into, only from**: GitHub
  Pages is the published portal; GitHub Releases and
  `raw.githubusercontent.com` are stable fetch points for importing schemas from
  other repositories; GHCR distributes container images. See
  the [Publishing overview](../publisering/publisering-oversikt.md) section "Where
  generated files end up" for a full overview of what is located where.
- **National catalogs** — publishing to Felles Begrepskatalog and Felles
  Datakatalog are **manual** steps performed by a person following
  the guides in the portal — the repository does not push directly to these catalogs
  (cf. the "Pull, not push" principle in `CLAUDE.md`, fully explained with
  diagrams and examples in the [Publishing overview](../publisering/publisering-oversikt.md)).
- **External repository** — other repositories can bootstrap themselves with
  `bootstrap.sh` and import AP-NO profiles directly via tag-based
  `raw.githubusercontent.com` URLs, and validate/generate via the same
  reusable GitHub Actions workflows that this repository exposes.
- **Consumers of Felles Datakatalog and the published schemas** — these are
  future/planned integrations (see
  `specs/backlog/nasjonal-datamesh-arkitektur.md` for the full assessment), not
  something implemented in this repository today:
  - **KUDAF** (the data community of Sikt/HK-dir for the education and research sector) harvests
    dataset metadata from the search API/SPARQL endpoint of Felles Datakatalog —
    the same pattern data.norge.no itself uses to harvest
    DCAT-AP-NO metadata from GitHub Pages. The repository thus delivers data to KUDAF
    *indirectly*, via Felles Datakatalog as an intermediate store/hub.
  - **Private data catalogs, data platforms and API gateways** in organizations
    can fetch schema artifacts (SHACL, JSON Schema, JSON-LD context, OWL)
    directly from GitHub Pages, or import LinkML schemas tag-versioned
    via `raw.githubusercontent.com` — see the Publishing overview section
    "Private systems that can harvest" for format and usage details per
    consumer type.
  - All these connections are **pull**: none of the consumers receive pushes from
    this repository, in line with the "Pull, not push" principle.

## Related documentation {#relatert-dokumentasjon}

- [Artifact generation — sources and pipeline](../automasjon/artefakt-generering.md) — detailed source tracing for each automatically generated artifact
- [Publishing overview](../publisering/publisering-oversikt.md) — the "Pull, not push" principle, where generated files end up, and the step-by-step flow to data.norge.no
- [Monitoring the automation](../automasjon/monitorering.md) — how to monitor that the CI workflows actually work
