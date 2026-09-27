---
i18n:
  source: standardetterleving.md
  source_hash: sha256:3fa3080b6e3d0c9ff484a8619a2c6eb980896930a53c5d70ec4185e9763c9fe9
---
# Standards compliance {#standardetterleving}

!!! note "Description"

    This page maps how the repository implements and complies with
    [Digdir's Framework for Information Management](https://www.digdir.no/informasjonsforvaltning/rammeverk-informasjonsforvaltning/3626) (Rammeverk for informasjonsforvaltning)
    — the Norwegian guidelines, standards and common information models that
    govern how the public sector is to model and share data. The repository has
    the explicit aim of being a national tool for this framework
    (cf. [SCOPE.md](https://github.com/AudunAutomat/linkml-datamodellering-no/blob/main/SCOPE.md)).

The framework is structured in three pillars plus four core principles. The tables
below show the status per resource, with a link to a more detailed mapping where
one exists.

**Status symbols:** ✅ mapped and mainly covered · 🟡 mapped, some remaining
measures · ⚪ mapped, limited/no technical relevance for a shared tool repository

---

## Pillar 1 — Guidelines {#pilar-1-veiledere}

| Resource | Status | Assessment |
|---|---|---|
| [Orden i eget hus](https://www.digdir.no/informasjonsforvaltning/orden-i-eget-hus/2115) ("Getting your own house in order") | ✅ | The repository supports the mapping/description steps with a schema library, validation and publishing — anchoring/prioritization/access assessment itself is the responsibility of the organization. See [Publishing — Digdir's data provider checklist](../publisering/publisering-oversikt.md). |
| [Modenhetsmodell for orden i eget hus](https://www.digdir.no/informasjonsforvaltning/modenhetsmodell-orden-i-eget-hus/2124) (maturity model) | ⚪ | A self-assessment tool for an individual organization — not directly applicable to a shared tool repository, but the repository raises the maturity of organizations that adopt it. |
| [Tilgjengeliggjøring av åpne data](https://fellesdatakatalog.digdir.no/guide/veileder-apne-data) (making open data available) | ✅ | Done for the core requirements (license, format, download, persistent identifiers). All 6 organizations now have their own model catalog with real entries (was 2 of 21 schemas at the previous mapping). Remaining, low priority: no live queryable API (static files only), no active user encouragement/surveys — see [`avvik-veileder-apne-data.md`](https://github.com/AudunAutomat/linkml-datamodellering-no/blob/main/specs/done/avvik-veileder-apne-data.md). |
| [Beskrivelse av kvalitet på datasett](https://fellesdatakatalog.digdir.no/specification/spesifikasjon-for-beskrivelse-av-kvalitet-pa-datasett) (describing dataset quality) | ✅ | Quantifiable quality measures (DQV-AP-NO) implemented and done. `make gen-dqv-measurements` verified as working for all 7 data files (concept catalog + 6 model catalogs): the key name mismatch `data_policy`/`validation_policy` has been corrected, the `kvalitetsmaalingar` attribute has been added to the 5 model catalog schemas that lacked it, and `brreg-begrepskatalog.yaml` has got its `samlingar:` container back (restored from historical, verified values). The root cause — that both `collect-concepts.py` and `generate-modellkatalog.py` overwrote whole files and therefore wiped out DQV data on every regeneration — has been fixed to preserve existing `kvalitetsmaalingar`/`samlingar` across runs. See [`fiks-dqv-measurements-data-policy-nokkel.md`](https://github.com/AudunAutomat/linkml-datamodellering-no/blob/main/specs/done/fiks-dqv-measurements-data-policy-nokkel.md) and [`fiks-dqv-gap-7a-7b.md`](https://github.com/AudunAutomat/linkml-datamodellering-no/blob/main/specs/done/fiks-dqv-gap-7a-7b.md). |
| [Internkontroll i praksis for informasjonssikkerheit](https://www.digdir.no/informasjonssikkerhet/internkontroll-i-praksis-informasjonssikkerhet/2601) (internal control for information security) | ⚪ | An organizational governance activity — limited direct relevance for a schema library. The repository has adjacent infrastructure (traffic light system mapping, CODEOWNERS, SBOM/secure CI). |
| [Veileder for informasjonsmodellar (ModellDCAT-AP-NO)](https://fellesdatakatalog.digdir.no/guide/veileder-modelldcat-ap-no) (guideline for information models) | ✅ | Done — 23 information models registered across 6 organization catalogs, version/status synchronized, and model elements (object type/attribute/association/code list) exposed for machine harvesting. See [`avvik-veileder-modelldcat-ap-no.md`](https://github.com/AudunAutomat/linkml-datamodellering-no/blob/main/specs/done/avvik-veileder-modelldcat-ap-no.md). |
| [Veileder for høsting og deling av språkdata](https://www.digdir.no/datadeling/sprakdata-korleis-kan-vi-hauste-og-dele/2367) (harvesting and sharing language data) | ⚪ | Relevant (`brreg-begrepskatalog` is a concept system), but an explicit contribution to the Norwegian Language Bank (Språkbanken) is a publishing decision for the individual codeowner, not an architectural gap. |

## Pillar 2 — Standards and specifications {#pilar-2-standarder-og-spesifikasjoner}

| Resource | Status | Assessment |
|---|---|---|
| DCAT-AP-NO | ✅ | Done — DA1-DA5 (bug fix, six new optional slots) implemented and verified. One remaining item: DA6 (verify that the `data.norge.no/organizations/<orgnr>` pattern is resolved correctly by Felles datakatalog) has not been done. See [AP-NO architecture and deviations](ap-no-arkitektur.md). |
| SKOS-AP-NO Begrep | ✅ | Mainly done (SK1-SK4 + SK5 Proposal A). Remaining: SK5 Proposal B (full language tagging of `LangString` across AP-NO) is deliberately deferred, no spec created yet; Deviations 8/9 (`relasjontype`/`verdiomrade` range) have not been addressed. See [AP-NO architecture and deviations](ap-no-arkitektur.md). |
| [Termlosen](https://www.digdir.no/standarder/termlosen/1733) (concept analysis) | ✅ | Done — TL1-TL3 implemented: `relasjontype.range` changed to `Konsept` (a structured Termlosen typology for associative relations), `kjelde_tekst` added for non-URI sources (printed laws/standards), and the three missing matching predicates (`breitt_samsvar`/`smalt_samsvar`/`relatert_samsvar`) added to `Begrep`. Illustration of concept relationships is covered by the generated `gen-doc`/`gen-erdiagram` documentation. One limited item deliberately postponed: TL4 (a SHACL regex check for poor definition patterns such as «som er»/«betegnar») is not implemented — cross-referenced to the corresponding postponed item SK5 Proposal B for SKOS-AP-NO. Process and text quality requirements (working group size, definition wording) are deliberately kept outside the schema, since they are not data structure requirements. See [`avvik-termlosen.md`](https://github.com/AudunAutomat/linkml-datamodellering-no/blob/main/specs/done/avvik-termlosen.md). |
| [Forvaltningsstandard for begrepsharmonisering/-differensiering](https://www.digdir.no/standarder/forvaltningsstandard-omgrepsharmonisering-og-omgrepsdifferensiering/1683) (concept harmonization/differentiation) | ⚪ | A procedural standard — the `GeneriskRelasjon` class in `skos-ap-no-schema` provides the technical prerequisite. |
| [TBX-AP-NO](https://www.digdir.no/standarder/tbx-ap-no-forvaltningsstandard-tilgjengeleggjering-av-omgrepsbeskrivingar-basert-pa-tbx/1684) | 🟡 | **Real gap:** no TBX export for concept catalog data (TBX is recommended, not mandatory). |
| [Retningslinjer ved tilgjengeliggjøring av offentlege data](https://www.digdir.no/informasjonsforvaltning/retningslinjer-ved-tilgjengeliggjoring-av-offentlige-data/2722) (guidelines for making public data available) | ✅ | Done — all 4 measures (RÅ1-RÅ4) implemented and validated (incl. the `distribusjon_lisens` silver check). Deviation 7 (structural gap for non-open datasets) had no recommended measure in the original mapping and has therefore not been addressed. |
| DQV-AP-NO | ✅ | Resolved — all 6 measures (DQ1-DQ6) done (`Standard` moved to `dcat-ap-no`, `har_verdi` split into typed variants, the `DqvMotivasjon` enum added). One known limitation: `har_maal.range` is `uriorcurie` (not `KatalogisertRessurs` as originally planned) because of a LinkML limitation on slot_usage narrowing — instance data are unaffected. See [AP-NO architecture and deviations](ap-no-arkitektur.md). |
| ModelDCAT-AP-NO | ✅ | Done — split into model/catalog schemas (MC8-MC11 deduplication completed, no duplicate classes left). See [AP-NO architecture and deviations](ap-no-arkitektur.md). |
| [Los](https://www.digdir.no/informasjonsforvaltning/los-felles-vokabular-klassifisering-av-offentlige-tjenester-og-ressurser/2434) (classification vocabulary) | ✅ | Done — all 5 measures (LO1-LO5), incl. data errors/documentation deviations, corrected. |
| Standards for URI pointers to public resources | 🟡 | Partially done — 4 of 6 items still open: (1) `begrep.brreg.no` instance URIs do not resolve, (2) `brreg.no/modellkatalogar/` URIs probably do not resolve, (3) schema IDs lack content negotiation (return HTML, not RDF), (4) no documented URI construction policy. See [`avvik-peikarar-til-offentlege-ressursar.md`](https://github.com/AudunAutomat/linkml-datamodellering-no/blob/main/specs/backlog/avvik-peikarar-til-offentlege-ressursar.md). |
| XKOS-AP-NO | ✅ | Mainly done — 11 of 13 deviations corrected (XK1-XK11). The remaining item is a documented design choice (use of `dct:temporal` rather than `schema:validFrom`/`schema:validThrough`), not an unresolved deviation. See [AP-NO architecture and deviations](ap-no-arkitektur.md). |
| CPSV-AP-NO *(not listed on the framework page, same standard family)* | ✅ | Done — all 5 deviations corrected: the `Regel` class got the correct mandatory level on `tittel`/`beskrivelse`/`identifikator_literal`, and a new `LovpaalagdTjeneste` class (`cpsvno:StatutoryService`) with a `realiserer` slot was added. 19 classes in total. See [AP-NO architecture and deviations](ap-no-arkitektur.md). |

## Pillar 3 — Information models {#pilar-3-informasjonsmodellar}

| Resource | Status | Assessment |
|---|---|---|
| [Ni designprinsipper for informasjonsmodellar](https://www.digdir.no/informasjonsforvaltning/prinsipper-informasjonsmodeller/3030) (nine design principles for information models) | ✅ | 7 of 9 principles fully covered. Two remaining items: `begrepsidentifikator` is consistently missing on domain model classes outside `oreg/*` (P3 Terminology, see gap 4), and there is no explicit `owl:sameAs`/cross-reference for semantically overlapping classes across NGR/DCAT/FINT (P6 Reuse, see gap 5, low priority). FINT schemas above the 50-class limit (P7) are an accepted deviation, not a gap. Full principle-by-principle assessment: [`avvik-prinsipper-informasjonsmodeller.md`](https://github.com/AudunAutomat/linkml-datamodellering-no/blob/main/specs/done/avvik-prinsipper-informasjonsmodeller.md). |
| [Felles modelleringsregler for offentleg forvaltning](https://www.digdir.no/informasjonsforvaltning/felles-modelleringsregler-offentlig-forvaltning/3029) (common modeling rules, 15 rules) | ✅ | All 15 rules are addressed by the MCP validator — 11 with an automatic bronze/silver check, 4 (Visualization, Relationships, Reuse, Data types) via tools/conventions/manual review. Actual compliance varies: `begrepsidentifikator` (rule 13) is missing on 30/43 schemas (see gap 4 below). Full checklist: [Validation rules](valideringsregler.md). |
| [Person og Enhet — felles informasjonsmodell](https://www.digdir.no/informasjonsforvaltning/person-og-enhet-felles-informasjonsmodell/2018) (Person and Entity — common information model) | ⚪ | Strong correspondence in substance (all core fields represented, mostly with greater precision), but no 1:1 mapping — the repository's `ngr-person`/`enhetsregisteret-bvrinnfelles` are source-authoritative register models, not a simplification. An intended deviation, not a gap. |
| [Adresse — felles informasjonsmodell](https://www.digdir.no/informasjonsforvaltning/adresse-felles-informasjonsmodell/2019) (Address — common information model) | ✅ | Strong structural and semantic correspondence with `ngr-adresse` (same authoritative source: Kartverket/Matrikkelen/Posten). An earlier precision deviation (`Representasjonspunkt` used a local `class_uri` instead of a standard geometry vocabulary URI) has been corrected to `locn:Geometry` as part of the full `class_uri` review — see [`undersokelse-class-uri-kryssreferansar.md`](https://github.com/AudunAutomat/linkml-datamodellering-no/blob/main/specs/done/undersokelse-class-uri-kryssreferansar.md). |

## Core principles {#kjerneprinsipp}

| Principle | Assessment |
|---|---|
| **Orden i eget hus** ("Getting your own house in order") | The repository provides the tools (schema library, validation, publishing) that the mapping/description step in the guideline needs, but cannot carry out anchoring, prioritization or access assessment for an individual organization — this is by design, since the repository is a shared tool (cf. [SCOPE.md](https://github.com/AudunAutomat/linkml-datamodellering-no/blob/main/SCOPE.md)). |
| **The "once only" principle** | Strongly implemented through the import hierarchy (classes/slots defined in one place, imported downwards — see [Import hierarchy](importhierarki.md)) and the linking principle (URI references between instances instead of duplication). |
| **Machine-readable data exchange** | The core of the tool chain: LinkML generates RDF/TTL, JSON-LD, JSON Schema, SHACL, OWL, PlantUML/ER diagrams and several other formats from one source. |
| **Common standards** | The repository is largely a collection of implementations of DCAT-AP-NO, SKOS-AP-NO, ModelDCAT-AP-NO, DQV-AP-NO, XKOS-AP-NO, CPSV-AP-NO and Los. |

---

## Remaining gaps {#attverande-gap}

| # | Gap | Source | Priority |
|---|---|---|---|
| 1 | Resolve 4 open items: `begrep.brreg.no` and `brreg.no/modellkatalogar/` URIs do not resolve, schema IDs lack content negotiation (HTML instead of RDF), no documented URI construction policy | [Standards for URI pointers](https://github.com/AudunAutomat/linkml-datamodellering-no/blob/main/specs/backlog/avvik-peikarar-til-offentlege-ressursar.md) | Open from before |
| 2 | Consider TBX export for `brreg-begrepskatalog` | TBX-AP-NO | Medium — real, but an optional format |
| 3 | Document a cross-reference to Digdir's Person/Entity model in `description.md` for `ngr-person`/`enhetsregisteret-bvrinnfelles` | Person og Enhet — common information model | Low — documentation |
| 4 | Add `annotations.begrepsidentifikator` to key classes in `ngr-*`, `fint-*` and the AP-NO profiles. The search tool (`sok_begrepskatalog`) and the Phase 2 batch search are done: 121 candidate hits found among 326 searchable classes (of 463 in scope in total) — remaining are Phase 3 (human confirmation of the candidates) and Phase 4 (new registration for the 205 without hits + 130 without a description) | Nine design principles (P3) / Common modeling rules (rule 13) — [`plan-konsekvent-begrepsidentifikator.md`](https://github.com/AudunAutomat/linkml-datamodellering-no/blob/main/specs/backlog/plan-konsekvent-begrepsidentifikator.md), [gap list Phase 2](https://github.com/AudunAutomat/linkml-datamodellering-no/blob/main/specs/backlog/begrepsidentifikator-gap-liste-fase2.md) | Medium — tools and mapping ready, awaiting human confirmation per class |
| 5 | Document an `owl:sameAs`/`skos:exactMatch` cross-reference for semantically overlapping classes (e.g. NGR `Virksomhet`/DCAT `Aktor`/the FINT equivalent) | Nine design principles (P6 Reuse and exchange) | Low — relevant only for a concrete model integration |
| 6 | 6 `oreg` schemas (`enhetsregisteret-bvrbekreftelse`, `-bvrettersendingavvedlegg`, `-bvrfriv`, `-bvrinnfelles`, `-bvrstiftelsesdokument`, `-frivilligorganisasjonapi`) have now got `metadata/*-manifest.yaml` generated by CI, but are not yet in the `informasjonsmodeller` list of `brreg-modellkatalog.yaml` — this only requires a new CI regeneration of the model catalog data, not a code change | [`fiks-digdir-katalog-referanse.md`](https://github.com/AudunAutomat/linkml-datamodellering-no/blob/main/specs/done/fiks-digdir-katalog-referanse.md) | Low — the root cause (missing manifest) is fixed, only regeneration remains |

Gaps 1, 2, 4 and 5 are real, limited extension points or errors; gap 3 is a
precision fix without functional consequence. Gap 4 (begrepsidentifikator) has
gone from "not started" to "tools built and mapping done" — see
`specs/backlog/plan-konsekvent-begrepsidentifikator.md` for the complete
phase description. Gap 6 (oreg manifests) has gone from "manifest missing entirely"
to "manifest exists, but the model catalog data has not been regenerated" — the
underlying data drift work is described in
`specs/done/modellkatalog-datadrift-undersokt.md` and
`specs/done/fiks-digdir-katalog-referanse.md`.

---

## See also {#sja-ogsa}

- [Validation rules](valideringsregler.md) — full checklist for the 15 Digdir modeling rules and the FAIR principles, with a rule-by-rule mapping to the bronze/silver/gold policies
- [AP-NO architecture and deviations](ap-no-arkitektur.md) — how DCAT-, SKOS-, ModelDCAT-, CPSV-, DQV- and XKOS-AP-NO are structured in the repository
- [Publishing](../publisering/publisering-oversikt.md) — Digdir's data provider checklist and the "Orden i eget hus" traffic light system set against the publishing flow
- [Complete mapping (source spec)](https://github.com/AudunAutomat/linkml-datamodellering-no/blob/main/specs/done/rammeverk-informasjonsforvaltning.md) — the underlying analysis this page is based on, including a class-by-class comparison for Person/Entity and Address
- 18 detailed `avvik-*.md` mappings in [`specs/done/`](https://github.com/AudunAutomat/linkml-datamodellering-no/tree/main/specs/done) — one per standard/guideline
