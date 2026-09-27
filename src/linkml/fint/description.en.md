---
i18n:
  source: description.md
  source_hash: sha256:6e2917c72325ccc2b74b01f6f8aa10813548f43b16a52e83df11d16e45f9f789
---
The FINT domain contains LinkML models converted from the Java-based API model of FINT (Felles Integrasjonsplattform for Norske Kommunar/fylkeskommunar — a common integration platform for Norwegian municipalities and county municipalities), and covers integrations for county municipalities and municipalities.

`fint-common` is the base layer with common concepts (identifiers, periods, addresses, contact information) that the other FINT models build on: `fint-administrasjon` (HR and organizational structure), `fint-arkiv` (Noark 5-based case management), `fint-okonomi` (invoice processing and procurement), `fint-personvern` (GDPR documentation), `fint-ressurs` (access management) and `fint-utdanning` (student data and teaching organization).

The FINT models inherit `camelCase` naming from the FINT API specification — a deliberate deviation from the repository's otherwise `snake_case` convention for slot names.

**Typical user:** Municipalities and county municipalities that use the FINT APIs, and developers implementing FINT-based integrations.
