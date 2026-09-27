---
i18n:
  source: index.md
  source_hash: sha256:91a2b6aeff7f0393e89d8084ff8164b23131b4f74cc563428b730b39ed29a493
---
# Publishing {#publisering}

!!! note "Description"

    This page gives an overview of the publishing flow from the repository to external
    catalogs — what is published where, and how Felles Begrepskatalog and
    Felles Datakatalog can be configured to harvest from the repository.

| Page | Contents |
|---|---|
| [Publishing flow](publisering-oversikt.md) | The "pull, not push" principle, where generated files end up (GitHub Pages, Releases, GHCR, raw.githubusercontent.com), and how national catalogs harvest from there. |
| [Publish to Felles Begrepskatalog](publisering-begrep.md) | How concept definitions are converted to SKOS/Turtle and made available for harvesting by Felles Begrepskatalog (the national concept catalog). |
| [Publish to Felles Datakatalog](publisering-modell.md) | How information models are described in ModelDCAT-AP-NO format and made available for harvesting by Felles Datakatalog (the national data catalog). |

## Related documentation {#relatert-dokumentasjon}

- [Architecture](../arkitektur/index.md) — import hierarchy, validation rules and the structural choices behind the published schemas
- [Automation](../automasjon/index.md) — the technical generation details behind each artifact and each portal page, and how to monitor the automation
