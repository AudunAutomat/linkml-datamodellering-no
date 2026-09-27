---
i18n:
  source: importhierarki.md
  source_hash: sha256:b72403d8d3de049468da38c1a0f5fb51fc38294568174fa87b9e741aa8cdcd5b
---
# Import hierarchy {#importhierarki}

!!! note "Description"

    This document shows the complete import hierarchy for all schemas in the repository.

## How to read the diagrams {#korleis-lese-diagramma}

**Important:** The import hierarchy must be read **from right to left**.

When you import a schema, it automatically includes all dependencies to its left in the tree.

**Example:**

If you import `dcat-ap-no-schema`:

```
linkml:types
    └── common-ap-no-schema
        └── dqv-core-schema
            └── dcat-ap-no-schema  ← you import this
```

...you automatically get both `dqv-core-schema`, `common-ap-no-schema` and `linkml:types` (all dependencies to the left).

---

## AP-NO hierarchy {#ap-no-hierarki}

Norwegian application profiles (AP-NO) for the public sector.

```
linkml:types
    └── common-ap-no-schema
        ├── dqv-core-schema
        │   ├── dcat-ap-no-schema
        │   │   ├── dqv-ap-no-schema
        │   │   └── xkos-ap-no-schema
        │   └── skos-ap-no-schema
        ├── cpsv-ap-no-schema
        └── modelldcat-modell-schema
            └── modelldcat-katalog-schema
                └── modelldcat-ap-no-schema
```

**The rules:**
- `common-ap-no-schema` is the only AP-NO schema that imports directly from `linkml:types`
- Domain model schemas import the AP-NO profiles, **not** `common-ap-no-schema` directly
- `dqv-core-schema` defines common DQV classes (`Kvalitetsmerknad`, `Kvalitetsmaaling` etc.)
- `dcat-ap-no-schema` imports `dqv-core-schema` to put DQV slots on `Datasett`
- `skos-ap-no-schema` imports `dqv-core-schema` for DQV support on SKOS classes
- `dqv-ap-no-schema` and `xkos-ap-no-schema` import `dcat-ap-no-schema` (and thereby also get `dqv-core-schema`)

**See also:**
- [AP-NO architecture](ap-no-arkitektur.md) — architectural choices and deviations in the AP-NO profiles

---

## FAIR metadata {#fair-metadata}

FAIR metadata can be imported by all domain models to add support for the FAIR principles.

```
linkml:types
    └── fair-metadata-schema
```

The FAIR schema is standalone and can be combined with AP-NO, FINT and OREG schemas alike.

---

## FINT hierarchy {#fint-hierarki}

The FINT domain models for education, administration, archives and more.

```
linkml:types
    └── fint-common-schema
        ├── fint-administrasjon-schema
        ├── fint-arkiv-schema
        ├── fint-okonomi-schema
        ├── fint-personvern-schema
        ├── fint-ressurs-schema
        └── fint-utdanning-schema
```

**The rules:**
- `fint-common-schema` is the only FINT schema that imports directly from `linkml:types`
- The FINT domain models import `fint-common-schema`, **not** `linkml:types` directly
- FINT schemas use `camelCase` for slots (inherited from the FINT API specification), not `snake_case`

---

## FELLES hierarchy {#felles-hierarki}

The FELLES domain contains reusable common components (address, actor, time, types) derived from the internal reference models of the Brønnøysund Register Centre (BR). They can be imported by domain models, e.g. the OREG enhetsregisteret-* models.

```
linkml:types
    └── brreg-felles-typer-schema
        ├── brreg-felles-tid-schema
        ├── brreg-felles-geografisk-adresse-schema
        │   └── brreg-felles-aktoer-schema
        └── brreg-felles-digital-adresse-schema
            └── brreg-felles-aktoer-schema
```

**The rules:**
- `brreg-felles-typer-schema` is the only FELLES schema that imports directly from `linkml:types`
- `brreg-felles-tid-schema`, `brreg-felles-geografisk-adresse-schema` and `brreg-felles-digital-adresse-schema` import `brreg-felles-typer-schema` for reusable primitive types
- `brreg-felles-aktoer-schema` imports **both** `brreg-felles-geografisk-adresse-schema` (for `GeografiskAdresse`) and `brreg-felles-digital-adresse-schema` (for `DigitalAdresse`) — and thereby also gets `brreg-felles-typer-schema` transitively. `brreg-felles-aktoer-schema` is therefore drawn as a leaf under both branches above (one node, two parents — strictly speaking the tree is a DAG here, not a pure tree)
- Domain models (e.g. the OREG enhetsregisteret-* models) import one or more FELLES schemas directly, depending on which classes they need

---

## Domain model schemas {#domenemodell-skjema}

Domain model schemas (e.g. SAMT, NGR) import the AP-NO profiles.

**Example — SAMT-BU:**

```
linkml:types
    └── common-ap-no-schema
        └── dqv-core-schema
            └── dcat-ap-no-schema
                └── dqv-ap-no-schema
                    └── samt-bu-schema  ← domain model
```

`samt-bu-schema` imports `dqv-ap-no-schema`, which in turn gives transitive dependencies on `dcat-ap-no-schema`, `dqv-core-schema`, `common-ap-no-schema` and `linkml:types`.

---

## Imports across domain models {#import-pa-tvers-av-domenemodellar}

**Imports between domain models are allowed**, but require care:

!!! warning "Version locking" **Always lock to a specific version** when you import a domain model from another domain model. This is necessary because domain models can change in ways that break backwards compatibility (classes/slots are changed or removed).

**Example — correct version locking:**

```yaml
imports:
  - linkml:types
  - ../../ap-no/dcat-ap-no/dcat-ap-no-schema  # AP-NO profile (stable, relative path)
  - https://raw.githubusercontent.com/AudunAutomat/linkml-datamodellering-no/ngr-adresse-v1.6.0/src/linkml/ngr/ngr-adresse/ngr-adresse-schema  # domain model (version-locked via git tag)
```

**Why version-lock?**
- **AP-NO/FINT/FAIR schemas** follow standards and rarely change — they do not need version locking
- **Domain models** (SAMT, NGR, OREG etc.) can change actively — version locking prevents unexpected breakage

**Alternative to importing:**
- If you only need one or two classes, consider **copying the class definitions** instead of importing the whole schema
- This reduces dependencies and gives more control, but breaks the DRY principle. Use with care!

---

## Why an import hierarchy? {#kvifor-importhierarki}

The import hierarchy is the repository's primary DRY mechanism for schemas: classes and slots are defined in one place and imported downwards.

**Examples:**
- `Datasett`, `Katalog`, `Distribusjon` are defined in `dcat-ap-no-schema`
- All domain model schemas that import `dcat-ap-no-schema` get access to these classes
- No duplication of class definitions

See `specs/done/avvik-modelldcat-ap-no.md` (MC8-MC11) for a practical example of how duplicate classes were removed by importing `dcat-ap-no-schema`.
