---
i18n:
  source: description.md
  source_hash: sha256:43d94520bdc883b5ccdb798d42066a48d02bc137dfb886b78432c64350420b3f
---
The FELLES domain contains reusable common components derived from the internal reference models of the Brønnøysund Register Centre (Brønnøysundregistrene, BR) (BRReferansemodell_v3, Strukturtypekatalog_v1, Løsningstypekatalog_v1), intended to be imported into other domain models — primarily the OREG models for the Central Coordinating Register for Legal Entities (Enhetsregisteret).

The domain contains five models: `brreg-felles-typer` (reusable primitive types), `brreg-felles-tid` (time period classes), `brreg-felles-geografisk-adresse` (geographic address), `brreg-felles-digital-adresse` (digital address) and `brreg-felles-aktoer` (Aktør, Virksomhet, Person, Rolle and more). The import order follows this list — each model can import the preceding ones, but not the other way round.

**Typical user:** Modelers at the Brønnøysund Register Centre who need common address, actor, time or type definitions in their own domain models, instead of redefining them locally in each schema.
