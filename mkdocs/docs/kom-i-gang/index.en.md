---
i18n:
  source: index.md
  source_hash: sha256:bf27ee606203e42a5bd475e371a85ac785fa42265a20e2ddbe6776586e3efc45
---
# Getting started {#kom-i-gang}

!!! note "Description"

    This page is the entry point to the guides for getting started with the repository —
    whether you are registering a new organization, modeling a new domain model,
    modeling a new concept catalog, or just looking up a command.

Choose the guide that matches what you want to do:

| Guide | When do you use it? |
|---|---|
| [Become a model owner](ny-org.md) | Your organization is going to start using the repository for the first time, together with the Brønnøysund Register Centre and other organizations. |
| [New domain model](ny-domenemodell.md) | You are going to create a completely new LinkML domain model — from file structure to RDF export ready for Felles Datakatalog. |
| [New concept catalog](ny-begrepsmodell.md) | You are going to create a new collection of concepts — from file structure to RDF export ready for Felles Begrepskatalog. |
| [Build manifest (build.yaml)](build-config.md) | You need a reference for what `build.yaml` controls — which artifacts are generated, publishing flags and validation policy. |
| [Command overview](kommandoar.md) | You need a complete list of all `make` commands the repository offers. |

## Prerequisites {#fresetnader}

All commands run in containers via [Podman](https://podman.io/) — no
local installation of Python or LinkML tools is needed. See
[the "Getting started" section on the front page](../index.md#getting-started) for the complete
recipe for local setup (WSL2, Git, Podman, GNU make) and the two typical
paths — data modeling and concept modeling — step by step.

## Related documentation {#relatert-dokumentasjon}

- [Architecture](../arkitektur/index.md) — how the schemas fit together
- [Publishing](../publisering/index.md) — how generated artifacts are made available for harvesting by national catalogs
- [Automation](../automasjon/index.md) — technical details of the generation pipeline and monitoring
