---
i18n:
  source: description.md
  source_hash: sha256:d087dfcb4cd759f8b3cd6f847435665100e6b8dad3a960ea61d4bf3be9d7db2d
---
Concept catalog models contain concept definitions from Norwegian public bodies, modeled according to SKOS-AP-NO and published to the [national concept catalog](https://data.norge.no/concepts) (Felles begrepskatalog).

Unlike the AP-NO profiles and the domain models, the schemas in this domain also contain production data, in `data/` subdirectories per organization (e.g. `brreg-begrepskatalog`). Each data file has its own `build.yaml` with a `publish_external` flag and an optional `concepts:` list that limits which concepts are published.

**Typical user:** Subject-matter experts in public bodies who manage concepts, and external users searching for concept definitions via Felles begrepskatalog.
