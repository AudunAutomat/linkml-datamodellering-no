---
i18n:
  source: description.md
  source_hash: sha256:7a2f05a73c0181809333cd9dbc35b2869c56ffa32180fa6793674ea57e374145
---
The NGR domain (Nasjonale grunndata — national master data) contains four complete domain models for central Norwegian base registers: `ngr-adresse` (the Address Register), `ngr-eiendom` (the Cadastre, Matrikkelen), `ngr-person` (the National Population Register, Folkeregisteret) and `ngr-virksomhet` (the Central Coordinating Register for Legal Entities, Enhetsregisteret). These correspond to the four registers that, according to the [Framework for National Master Data](https://www.digdir.no/datadeling/nasjonale-grunndata/7575) (Rammeverk for Nasjonale grunndata), have the status of national master data in Norway.

The models use a `_ref` suffix on reference slots that hold a URI to another resource (e.g. `kommune_ref`, `adressenavn_ref`) — see CONVENTIONS.md.

**Typical user:** Public bodies working with master data from the Norwegian Mapping Authority (Kartverket), the Norwegian Tax Administration (Skatteetaten) or the Brønnøysund Register Centre, and developers implementing APIs based on national master data.
