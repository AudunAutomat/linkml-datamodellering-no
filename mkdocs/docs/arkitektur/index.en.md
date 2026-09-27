---
i18n:
  source: index.md
  source_hash: sha256:af93739fc32df406e8fe1a39a98d0448dcb17e929f2affaabb2de53adcb0b33d
---
# Architecture {#arkitektur}

!!! note "Description"

    This page gives an overview of how the repository is structured — from the import hierarchy
    between schemas, via validation rules, to the structural choices made
    in the AP-NO profiles and how other repositories can reuse them.

| Page | Contents |
|---|---|
| [Architecture overview](arkitektur-oversikt.md) | Overall diagram from source schemas, via MCP servers and CI, to published artifacts and the national catalogs that harvest from them. |
| [Import hierarchy](importhierarki.md) | The complete import hierarchy for all schemas in the repository — what imports what, and why. |
| [Validation rules](valideringsregler.md) | The bronze/silver/gold policies and the publishing policies — full checklist with Digdir rule and FAIR mapping. |
| [AP-NO architecture and deviations](ap-no-arkitektur.md) | How the AP-NO schemas (DCAT, SKOS, CPSV, DQV and more) are structured in this repository, and where and why they deliberately deviate from the specifications. |
| [Standards compliance](standardetterleving.md) | A mapping of how the repository implements and complies with Digdir's Framework for Information Management — guidelines, standards/specifications and common information models. |
| [Use from an external repository](ekstern-bruk.md) | How another repository can import the AP-NO profiles and use the repository's reusable GitHub Actions workflows without living inside the monorepo. |

## Related documentation {#relatert-dokumentasjon}

- [Getting started](../kom-i-gang/index.md) — practical step-by-step guides for adopting the repository
- [Publishing](../publisering/index.md) — how generated artifacts are made available for harvesting by national catalogs
- [Automation](../automasjon/index.md) — the technical generation details behind each artifact and each portal page, and how to monitor the automation
