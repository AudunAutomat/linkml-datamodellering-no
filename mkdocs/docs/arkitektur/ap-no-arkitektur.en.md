---
i18n:
  source: ap-no-arkitektur.md
  source_hash: sha256:14ef89b5ffd188ccc54041bd762823ff03cb90c5ae9a2cfb5a9bb7bc89b45246
---
# AP-NO - Architecture, deviations and structural choices {#ap-no-arkitektur-avvik-og-strukturelle-val}

!!! note "Description"

    This document is the central reference for understanding how the AP-NO schemas are structured in this repository: which choices have been made, where we deliberately deviate from the specifications, and why. It is written to be easy to read both for humans and for LLMs.

Detailed mapping documents per schema are located in `specs/done/` and `specs/backlog/`.

---

## Import chain {#importkjede}

See [Import hierarchy](importhierarki.md#ap-no-hierarki) for a complete overview of the AP-NO import chain and how it relates to FINT, OREG and other domains.

---

## Architectural limitations in LinkML {#arkitektoniske-avgrensingar-i-linkml}

Two limitations in LinkML directly affect how the AP-NO schemas are
structured:

### Limitation 1 — A class override replaces (does not merge) the `slots:` list {#avgrensing-1-class-override-erstattar-merge-ikkje-slots-lista}

When a subschema redeclares a class with a `slots:` list (instead of
only `slot_usage:`), the JSON Schema generator REPLACES the parent schema's
`slots:` list — it does not merge them. As a result, all slots from the
parent schema disappear from JSON Schema validation.

**Consequence:** We cannot let `dqv-ap-no` redeclare `Datasett` with extra
DQV slots — all `dcat-ap-no` slots (tittel, beskrivelse and more) would disappear
from validation.

**Solution:** `har_kvalitetsmerknad` and `har_kvalitetsmaaling` are defined directly
on `Datasett` in `dcat-ap-no-schema.yaml`. The DQV slots are available without
`dqv-ap-no` having to redeclare `Datasett`.

### Limitation 2 — `no_invalid_slot_usage` requires the slot to be declared in `slots:` {#avgrensing-2-noinvalidslotusage-krev-at-slot-er-deklarert-i-slots}

The lint rule `no_invalid_slot_usage` requires a slot used in `slot_usage:`
in a subschema to already be declared in the class's own `slots:` list. It is
not possible to use `slot_usage:` in an importing schema to narrow a
slot from an imported schema through `slot_usage:` alone.

**Consequence:** `dqv-ap-no` cannot narrow `har_maal.range` from `uriorcurie`
to `KatalogisertRessurs` via `slot_usage:` — the class `Kvalitetsmerknad` does not own
`har_maal` in its own `slots:` list in `dqv-ap-no`.

**Solution:** `har_maal.range` remains `uriorcurie` in `dqv-core-schema.yaml`.
URI values still pass validation correctly.

---

## Schema overview {#skjemaoversikt}

### `common-ap-no` — The common base layer {#common-ap-no-felles-basislaget}

**File:** `src/linkml/ap-no/common/common-ap-no-schema.yaml`

Shared layer for all the AP-NO profiles. Defines:
- Base types: `LangString`, `Konsept`, `Begrepssamling`, `Spraak`, `Mediatype`
- Shared slots: `id`, `tittel`, `beskrivelse`, `nokkelord`, `endringsdato`,
  `utgivelsesdato`, `versjonsnummer`, `versjonsmerknad`, `status`, `heimeside`,
  `format`, `spraak`, `identifikator_literal`, `type_concept`, `dekningsomraade`,
  `har_referanse`, `har_merknad`

**Known deviations:** None documented.

---

### `dcat-ap-no` — Datasets and distributions {#dcat-ap-no-datasett-og-distribusjon}

**File:** `src/linkml/ap-no/dcat-ap-no/dcat-ap-no-schema.yaml`  
**Specification:** <https://informasjonsforvaltning.github.io/dcat-ap-no/>

**Architectural choices:**
- The `Standard` class is defined here (not in `dqv-ap-no`) to avoid a circular import
- `har_kvalitetsmerknad` and `har_kvalitetsmaaling` are put directly on `Datasett`
  here (DQV slots obtained via the import of `dqv-core`)
- Imports `dqv-core-schema` (not `dqv-ap-no-schema`) to break the circular import

**Known deviations:** None.

---

### `dqv-core` — DQV core classes (bridge file) {#dqv-core-dqv-kjerneklasser-bridge-fil}

**File:** `src/linkml/ap-no/dqv-ap-no/dqv-core-schema.yaml`  
**Origin:** Created as a solution to a circular import (MC11)

This file is not an AP-NO profile of its own — it is an architectural layer that breaks
the circular dependency between `dcat-ap-no` and `dqv-ap-no`.

**Contains:**
- All DQV core classes: `Kvalitetsdimensjon`, `Kvalitetsdeldimensjon`,
  `Kvalitetsmaal`, `Kvalitetsmerknad`, `Brukartilbakemelding`,
  `Kvalitetssertifikat`, `Kvalitetsmaaling`, `Tekstdel`
- All DQV slots: `har_kvalitetsmerknad`, `har_kvalitetsmaaling`, `har_maal` and more
- Enum: `DqvMotivasjon`

**Deliberate deviations from the DQV-AP-NO specification:**

| Field | Implementation | Specification | Reason |
|------|---------------|---------------|-------|
| `har_maal.range` | `uriorcurie` | `KatalogisertRessurs` | Avoid a circular import (see limitation 2 above) |

---

### `dqv-ap-no` — Data quality {#dqv-ap-no-datakvalitet}

**File:** `src/linkml/ap-no/dqv-ap-no/dqv-ap-no-schema.yaml`  
**Specification:** <https://informasjonsforvaltning.github.io/dqv-ap-no/>

**Known deviation:**

| Code | Deviation | Reason |
|------|-------|-------|
| DQ5 | `har_maal.range: uriorcurie` (spec: `dcat:Resource`) | Bridge architecture + LinkML limitation 2 |

**Explanation of DQ5:** `dqv-core` cannot refer to `KatalogisertRessurs` (which lives in `dcat-ap-no`, which imports `dqv-core`). `dqv-ap-no` cannot narrow the range via `slot_usage` without redeclaring `slots: [har_maal]`, which would trigger limitation 1. Validation works in practice, since instance data use URI values.

---

### `skos-ap-no` — Concepts and concept catalog {#skos-ap-no-omgrep-og-begrepskatalog}

**File:** `src/linkml/ap-no/skos-ap-no/skos-ap-no-schema.yaml`  
**Specification:** <https://informasjonsforvaltning.github.io/skos-ap-no-begrep/>

**Known deviation:**

| Code | Deviation | Status |
|------|-------|--------|
| SK5 | The bilingual requirement (nb+nn) on `anbefalt_term` is not enforced in instance validation | **Partially resolved** (2026-07-27) — schema check implemented |

**Explanation of SK5:** 
- **`har_definisjon`** — instance check implemented (`begrep_har_definisjon_pa_nb_og_nn` in the `felles-begrepskatalog` policy) via an ID suffix convention
- **`anbefalt_term`** — schema check implemented (`begrep_anbefalt_term_er_multivalued_langstring`), which verifies that the schema has `range: LangString` and `multivalued: true`
- **Limitation:** LangString values in YAML do not carry a language tag per value (see [`bugs/langstring-rdflib-roundtrip.md`](https://github.com/AudunAutomat/linkml-datamodellering-no/blob/main/bugs/langstring-rdflib-roundtrip.md)), so instance validation of bilingual coverage must be done in the RDF phase (TTL + SHACL)
- See [`specs/done/spraaktagging-langstring.md`](https://github.com/AudunAutomat/linkml-datamodellering-no/blob/main/specs/done/spraaktagging-langstring.md) for details and future SHACL validation

---

### `xkos-ap-no` — Classifications {#xkos-ap-no-klassifikasjonar}

**File:** `src/linkml/ap-no/xkos-ap-no/xkos-ap-no-schema.yaml`  
**Specification:** <https://data.norge.no/specification/xkos-ap-no>

**Design choice:** XKOS-AP-NO uses `dct:temporal` (a Tidsrom intermediate class) instead of `schema:validFrom`/`schema:validThrough` directly — to harmonize with the DCAT-AP-NO pattern.

**Known deviations:** None.

---

### `modelldcat-ap-no` — Information models {#modelldcat-ap-no-informasjonsmodellar}

**Main file (pass-through):** `src/linkml/ap-no/modelldcat-ap-no/modelldcat-ap-no-schema.yaml`  
**Model part:** `src/linkml/ap-no/modelldcat-ap-no/modelldcat-modell-schema.yaml`  
**Catalog part:** `src/linkml/ap-no/modelldcat-ap-no/modelldcat-katalog-schema.yaml`  
**Specification:** <https://data.norge.no/specification/modelldcat-ap-no>

**Architectural choice:**

The schema is split into two files to match the structure of the specification:
- `modelldcat-modell-schema` — all the model element classes (27 classes)
- `modelldcat-katalog-schema` — Modellkatalog, Informasjonsmodell, Dokument
- `modelldcat-ap-no-schema` — pass-through for backwards compatibility

`modelldcat-katalog` imports `dcat-ap-no` and reuses helper classes (`Aktoer`, `Kontaktopplysning`, `Standard`, `Tidsrom`).

**Known deviations:** None.

---

### `cpsv-ap-no` — Public services {#cpsv-ap-no-offentlege-tenester}

**File:** `src/linkml/ap-no/cpsv-ap-no/cpsv-ap-no-schema.yaml`  
**Specification:** <https://informasjonsforvaltning.github.io/cpsv-ap-no/>

**Status:** Systematic deviation mapping carried out 2026-07-27 — 5 deviations identified and **all fixed the same day**.

**Result:** 19 of 19 classes correctly implemented. See `specs/done/avvik-cpsv-ap-no.md` for details.

---

## Patterns that apply to all AP-NO schemas {#mnster-som-gjeld-alle-ap-no-skjema}

### Linking instead of inlining {#lenking-framfor-inlining}

All classes with identity (all except pure helper classes such as `LangString`)
have an `id` slot with `identifier: true` and `range: uriorcurie`. References to
other classes are **not** `inlined: true` — they are URI references in data files.

### `slot_usage` for mandatory/recommended/optional {#slotusage-for-obligatoriskanbefaltvalgfri}

`in_subset` with the values `Obligatorisk` (mandatory), `Anbefalt` (recommended), `Valgfri` (optional) (and `Metadata`)
marks which level a property belongs to according to the specification. `required: true`
is set **only** for `Obligatorisk` properties that require machine checking.

### Container class {#containerklasse}

All top-level domain model schemas (not the AP-NO profiles) have one container class
with `tree_root: true` and `attributes:` (not `slots:`). AP-NO profile schemas do
not have a container class of their own.

### Norwegian transliteration in identifiers {#norsk-translitterering-i-identifikatorar}

Norwegian-specific letters are transliterated in class names, slot names and the URI local part:
`æ→ae`, `ø→oe`, `å→aa`. This does not apply to free-text fields (`title`, `description`).

---

## Related documentation {#relatert-dokumentasjon}

- [`specs/done/avvik-dcat-ap-no.md`](https://github.com/AudunAutomat/linkml-datamodellering-no/blob/main/specs/done/avvik-dcat-ap-no.md) — detailed mapping of DCAT-AP-NO
- [`specs/done/avvik-dqv-ap-no.md`](https://github.com/AudunAutomat/linkml-datamodellering-no/blob/main/specs/done/avvik-dqv-ap-no.md) — detailed mapping of DQV-AP-NO (DQ5 documented)
- [`specs/done/avvik-skos-ap-no.md`](https://github.com/AudunAutomat/linkml-datamodellering-no/blob/main/specs/done/avvik-skos-ap-no.md) — mapping of SKOS-AP-NO (SK1-SK5)
- [`specs/done/avvik-xkos-ap-no.md`](https://github.com/AudunAutomat/linkml-datamodellering-no/blob/main/specs/done/avvik-xkos-ap-no.md) — mapping of XKOS-AP-NO (XK1-XK7 done)
- [`specs/done/xkos-ap-no-resterande-avvik.md`](https://github.com/AudunAutomat/linkml-datamodellering-no/blob/main/specs/done/xkos-ap-no-resterande-avvik.md) — XKOS-AP-NO XK8-XK11 (done 2026-07-07)
- [`specs/done/avvik-modelldcat-ap-no.md`](https://github.com/AudunAutomat/linkml-datamodellering-no/blob/main/specs/done/avvik-modelldcat-ap-no.md) — mapping of ModelDCAT-AP-NO (MC3, MC8 done)
- [`specs/done/avvik-cpsv-ap-no.md`](https://github.com/AudunAutomat/linkml-datamodellering-no/blob/main/specs/done/avvik-cpsv-ap-no.md) — systematic mapping of CPSV-AP-NO (DEVIATIONS 1-5 done 2026-07-27)
- [`specs/done/spraaktagging-langstring.md`](https://github.com/AudunAutomat/linkml-datamodellering-no/blob/main/specs/done/spraaktagging-langstring.md) — SK5 bilingual requirement (partially resolved)
- [`specs/done/ap-no-arkitektur-audit-2026-07.md`](https://github.com/AudunAutomat/linkml-datamodellering-no/blob/main/specs/done/ap-no-arkitektur-audit-2026-07.md) — complete audit of all 6 AP-NO schemas (July 2026)
- [`specs/done/avvik-felles-modelleringsregler.md`](https://github.com/AudunAutomat/linkml-datamodellering-no/blob/main/specs/done/avvik-felles-modelleringsregler.md) — Digdir modeling rules
