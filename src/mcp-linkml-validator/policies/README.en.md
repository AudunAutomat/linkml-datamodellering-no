---
i18n:
  source: README.md
  source_hash: sha256:5b4fcdc5e86192951291e4f27c080815c6935325d54d849d0229794120686863
---
# Policies for mcp-linkml-validator

The checks in the bronze, basis-no, silver and gold policies implement both the
[Felles modelleringsregler for offentlig forvaltning](https://www.digdir.no/informasjonsforvaltning/felles-modelleringsregler-offentlig-forvaltning/3029)
("Common modeling rules for the public sector", Norwegian Digitalisation Agency, v1.0, June 2022) and
the [FAIR principles](https://www.go-fair.org/fair-principles/) (Findable, Accessible, Interoperable, Reusable).

---

## Digdir rules and FAIR principles — coverage

| # | Name | Short description | Covered by | FAIR |
|---|---|---|---|---|
| 1 | [**Forståelighet**](https://www.digdir.no/informasjonsforvaltning/felles-modelleringsregler-offentlig-forvaltning/3029#forstelighet) (understandability) | Names and descriptions are understandable to the target audience | Bronze: `title` (error), `description` (warning) | [F2](https://www.go-fair.org/fair-principles/) |
| 2 | [**Meningsfullhet**](https://www.digdir.no/informasjonsforvaltning/felles-modelleringsregler-offentlig-forvaltning/3029#meningsfullhet) (meaningfulness) | Names reflect content and purpose | Bronze: `title` (error) | [F2](https://www.go-fair.org/fair-principles/) |
| 3 | [**Navne- og skrivekonvensjoner**](https://www.digdir.no/informasjonsforvaltning/felles-modelleringsregler-offentlig-forvaltning/3029#navne_og_skrivekonvensjoner) (naming and writing conventions) | PascalCase for classes, snake_case/camelCase for properties | Bronze: LinkML linter `standard_naming` (warning) | — |
| 4 | [**Identifiserbarhet**](https://www.digdir.no/informasjonsforvaltning/felles-modelleringsregler-offentlig-forvaltning/3029#identifiserbarhet) (identifiability) | Persistent URIs for the model, elements and properties | Bronze: `id`, `default_prefix` (absolute URI) (error); basis-no: literal HTTPS `default_prefix` (error), `class_uri`, `slot_uri`, identifier slot (warning) | [F1, F3](https://www.go-fair.org/fair-principles/) |
| 5 | [**Visualisering**](https://www.digdir.no/informasjonsforvaltning/felles-modelleringsregler-offentlig-forvaltning/3029#visualisering) (visualization) | The model is available with a good visual representation | Basis-no/Gold: `schema_har_erdiagram_aktivert` (build.yaml has `generators.erdiagram: true`) — the Mermaid syntax of the generated ER diagram is additionally validated nightly by the `mermaid-render` job in `lenkje-og-mermaid-sjekk.yml` | — |
| 6 | [**Modularitet**](https://www.digdir.no/informasjonsforvaltning/felles-modelleringsregler-offentlig-forvaltning/3029#modularitet) (modularity) | A manageable number of model elements per module | Basis-no: `class_count_limit` — warning if the schema has more than 50 classes | — |
| 7 | [**Tilgjengeliggjøring**](https://www.digdir.no/informasjonsforvaltning/felles-modelleringsregler-offentlig-forvaltning/3029#tilgjengeliggjring) (availability) | The model is freely available online with an open license | Bronze: `license` (warning) | [R1.1](https://www.go-fair.org/fair-principles/) |
| 8 | [**Maskinprosserbarhet**](https://www.digdir.no/informasjonsforvaltning/felles-modelleringsregler-offentlig-forvaltning/3029#maskinprosserbarhet) (machine processability) | The model is available in open, machine-readable formats | Bronze: `no_inlined_on_primitive_range` (warning), LinkML linter (`recommended`); basis-no: `class_uri`, `slot_uri` (indirectly, via the rule 4 check) | [I1, I2](https://www.go-fair.org/fair-principles/) |
| 9 | [**Datering**](https://www.digdir.no/informasjonsforvaltning/felles-modelleringsregler-offentlig-forvaltning/3029#datering) (dating) | The model is dated with publication, modification and validity dates | Bronze: `version` (warning); Silver: `annotations.endringsdato` (warning) | [F4, R1.3](https://www.go-fair.org/fair-principles/) |
| 10 | [**Ansvar**](https://www.digdir.no/informasjonsforvaltning/felles-modelleringsregler-offentlig-forvaltning/3029#ansvar) (responsibility) | Ownership of and responsibility for the content of the model are clear | Silver: `annotations.utgiver` (warning) | [R1.2](https://www.go-fair.org/fair-principles/) |
| 11 | [**Modellstatus**](https://www.digdir.no/informasjonsforvaltning/felles-modelleringsregler-offentlig-forvaltning/3029#modellstatus) (model status) | The model has an explicit status (under development, completed, deprecated …) | Silver: `annotations.status` (warning) | [R1.3](https://www.go-fair.org/fair-principles/) |
| 12 | [**Sammenhenger mellom modeller**](https://www.digdir.no/informasjonsforvaltning/felles-modelleringsregler-offentlig-forvaltning/3029#sammenhenger_mellom_modeller) (relationships between models) | Relationships with other models are described | *Partially evaluated* — `make analyse-modell-sammenhenger` cross-references LinkML's import graph against `har_del`/`er_i_samsvar_med`/`er_profil_av`/`erstatter`/`er_erstattet_av` in the model catalog (informative, does not block CI) | [F3](https://www.go-fair.org/fair-principles/) |
| 13 | [**Begreper**](https://www.digdir.no/informasjonsforvaltning/felles-modelleringsregler-offentlig-forvaltning/3029#begreper) (concepts) | Model elements and properties are linked to concepts | Basis-no: `annotations.begrepsidentifikator` on all classes except in AP-NO profiles (warning) | [A2](https://www.go-fair.org/fair-principles/) |
| 14 | [**Gjenbruk**](https://www.digdir.no/informasjonsforvaltning/felles-modelleringsregler-offentlig-forvaltning/3029#gjenbruk) (reuse) | Existing model elements are reused rather than defined anew | Silver/Gold: `schema_importerer_dqv_ap_no` (import of dqv-ap-no-schema, warning/error). *Partially evaluated* — `make analyse-ap-no-gjenbruk` additionally checks reuse of `common-ap-no-schema` within `ap-no/*` (informative) | [I3](https://www.go-fair.org/fair-principles/) |
| 15 | [**Standardiserte datatyper**](https://www.digdir.no/informasjonsforvaltning/felles-modelleringsregler-offentlig-forvaltning/3029#standardiserte_datatyper) (standardized data types) | Primitive data types are standardized (XSD, RDFS) | Bronze/Gold: `local_types_have_standard_uri` — locally defined types (`types:`) must have a `uri:` in xsd/rdf/rdfs/owl. Types inherited from `linkml:types` are already guaranteed to be mapped to XSD | [I1](https://www.go-fair.org/fair-principles/) |

> **Note:** Rules 5, 14 and 15 are covered by policy checks (bronze/silver/gold) for what
> can be validated from the schema structure itself. Rule 12 and parts of rule 14 (reuse of
> `common-ap-no-schema`) are cross-schema/cross-catalog analyses that do not fit as a
> single-schema requirement — they are instead handled as informative model analysis jobs that do not block CI
> (`make analyse-modell-sammenhenger`, `make analyse-ap-no-gjenbruk`,
> run weekly by `.github/workflows/modell-analyse.yml`). See
> `specs/backlog/utvid-dekningsgrad-regel-5-12-14-15.md` for the rationale and limitations.

---

## Two kinds of validation

The policy files here are used for two different purposes:

**Schema quality (bronze / basis-no / silver / gold)**  
Checks that a LinkML schema (the `.yaml` file in `src/linkml/`) meets a certain
quality level: metadata, naming, URIs, concept references etc.  
Run with `make mcp-linkml-valider-modell SCHEMA=... POLICY=bronze`.

**Publishing conformance (felles-datakatalog / felles-begrepskatalog)**  
Checks that a schema complies with the requirements of a particular external catalog.
Used for schemas with `publish_external: true` in the manifest.

---

## Levels of schema quality

| Level | Requirements | Digdir rules | FAIR principles |
|---|---|---|---|
| [`bronze`](#bronze) | Generic LinkML baseline: metadata, URIs, naming (linter) and modeling quality — without Norwegian prerequisites | 1, 2, 3, 4, 7, 8, 15 | F1, F2, I1 (warning), R1.1 (warning) |
| [`basis-no`](#basis-no) | Bronze + Digdir/repository requirements: `class_uri`/`slot_uri`, identifier, concept identifier, modularity, ER diagram, controlled vocabularies | 1-8, 13, 15 | Bronze + F3 (warning), A2 (warning) |
| [`silver`](#silver) | Basis-no + AP-NO conformance and lifecycle metadata | 1-11, 13-15 | Basis-no + R1.2, R1.3, I3 |
| [`gold`](#gold) | Silver + FAIR F1-R1.3: full semantic interoperability | 1-11, 13-15 | F1-F4, I1-I3, R1.1-R1.3, A2 (all error) |

Each level inherits the requirements of the levels below (`bronze` → `basis-no` → `silver` → `gold`, via `extends:`).

> **Note — do not confuse with data.norge.no's quality scale:** Bronze/silver/gold
> validate **schema quality** (the structure of the `.yaml` schema itself), not the harvested
> metadata entries. Data.norge.no scores published entries on its own
> FAIR-based percentage scale (Utmerket/Excellent ≥75 %, God/Good 50-75 %, Tilstrekkeleg/Sufficient 25-50 %, Dårleg/Poor <25 %)
> — see [data.norge.no: Metadatakvalitet](https://data.norge.no/nb/docs/metadata-quality).
> A schema that validates at `gold` here therefore does not automatically guarantee "Utmerket" at
> data.norge.no, since the two scales measure different things.

---

## Quality policies

### bronze

Generic LinkML baseline. The requirements apply to everyone who models in LinkML, without Norwegian or
repository-specific prerequisites — an idiomatic LinkML schema (e.g. following the pattern of
LinkML's `personinfo` tutorial) should pass without errors. Regression guard:
`tests/fixtures/bronze-generisk-personinfo-fixture.yaml`. Norwegian/Digdir-specific requirements are
in [`basis-no`](#basis-no). See `specs/done/gjennomgang-bronze-policy-generisk.md`.

| Check | Severity | Upgraded to | Digdir rule | FAIR | Description |
|---|---|---|---|---|---|
| `schema.id` present | error | — (already error) | [4 — Identifiserbarhet](https://www.digdir.no/informasjonsforvaltning/felles-modelleringsregler-offentlig-forvaltning/3029#identifiserbarhet) | [F1](https://www.go-fair.org/fair-principles/) | Persistent identifier for the schema |
| `schema.id` is an HTTP(S) URI | error | — (already error) | [4 — Identifiserbarhet](https://www.digdir.no/informasjonsforvaltning/felles-modelleringsregler-offentlig-forvaltning/3029#identifiserbarhet) | [F1](https://www.go-fair.org/fair-principles/) | Ensures that the identifier is a resolvable URI |
| `schema.name` present | error | — (already error) | [1 — Forståelighet](https://www.digdir.no/informasjonsforvaltning/felles-modelleringsregler-offentlig-forvaltning/3029#forstelighet) | — | Machine-readable name of the schema |
| `schema.title` present | error | — (already error) | [1 — Forståelighet](https://www.digdir.no/informasjonsforvaltning/felles-modelleringsregler-offentlig-forvaltning/3029#forstelighet), [2 — Meningsfullhet](https://www.digdir.no/informasjonsforvaltning/felles-modelleringsregler-offentlig-forvaltning/3029#meningsfullhet) | [F2](https://www.go-fair.org/fair-principles/) | Human-readable title |
| `schema.default_prefix` present | error | — (already error) | [4 — Identifiserbarhet](https://www.digdir.no/informasjonsforvaltning/felles-modelleringsregler-offentlig-forvaltning/3029#identifiserbarhet) | — | Default namespace for local identifiers |
| `schema.default_prefix` expands (via `prefixes:` or directly) to an absolute HTTP(S) URI ending in `/` or `#` | error | — (already error) | [4 — Identifiserbarhet](https://www.digdir.no/informasjonsforvaltning/felles-modelleringsregler-offentlig-forvaltning/3029#identifiserbarhet) | — | Idiomatic LinkML (`default_prefix: personinfo`) and a literal URI are both valid |
| `schema.description` present | warning | error (gold) | [1 — Forståelighet](https://www.digdir.no/informasjonsforvaltning/felles-modelleringsregler-offentlig-forvaltning/3029#forstelighet) | [F2](https://www.go-fair.org/fair-principles/) | Free-text description of the purpose of the schema |
| `schema.version` present | warning | error (gold) | [9 — Datering](https://www.digdir.no/informasjonsforvaltning/felles-modelleringsregler-offentlig-forvaltning/3029#datering) | [F4](https://www.go-fair.org/fair-principles/) | Version number for traceability |
| `schema.license` present | warning | error (gold) | [7 — Tilgjengeliggjøring](https://www.digdir.no/informasjonsforvaltning/felles-modelleringsregler-offentlig-forvaltning/3029#tilgjengeliggjring) | [R1.1](https://www.go-fair.org/fair-principles/) | License for reuse of the schema |
| Slot/attribute `description` present | warning | — | [1 — Forståelighet](https://www.digdir.no/informasjonsforvaltning/felles-modelleringsregler-offentlig-forvaltning/3029#forstelighet) | [F2](https://www.go-fair.org/fair-principles/) | Applies both to global `slots:` and `attributes:` (except attributes on the `tree_root` class) |
| LinkML linter, the `recommended` rule set (without the `recommended` and `canonical_prefixes` rules) | error/warning per rule | — | [8 — Maskinprosserbarhet](https://www.digdir.no/informasjonsforvaltning/felles-modelleringsregler-offentlig-forvaltning/3029#maskinprosserbarhet) | — | Metamodel validation and upstream rules such as `no_undeclared_slots`, `no_undeclared_ranges`, `one_identifier_per_class`, `no_invalid_slot_usage` |
| Linter `standard_naming`: classes/enums `UpperCamelCase`, slots/attributes `snake_case` (local elements only, not permissible values) | warning | error (gold) | [3 — Navne- og skrivekonvensjoner](https://www.digdir.no/informasjonsforvaltning/felles-modelleringsregler-offentlig-forvaltning/3029#navne_og_skrivekonvensjoner) | — | Consistent naming. `build.yaml: slot_naming: camel` gives an exception for schemas that inherit camelCase from their source |
| `inlined`/`inlined_as_list` is only set where the range is a class | warning | error (gold) | [8 — Maskinprosserbarhet](https://www.digdir.no/informasjonsforvaltning/felles-modelleringsregler-offentlig-forvaltning/3029#maskinprosserbarhet) | [I1](https://www.go-fair.org/fair-principles/) | Catches dead configuration — the key has no effect on a primitive range |
| Locally defined types (`types:`) have a `uri:` in a standard namespace (xsd/rdf/rdfs/owl) | warning | error (gold) | [15 — Standardiserte datatyper](https://www.digdir.no/informasjonsforvaltning/felles-modelleringsregler-offentlig-forvaltning/3029#standardiserte_datatyper) | [I1](https://www.go-fair.org/fair-principles/) | Types inherited from `linkml:types` are already guaranteed to be mapped to XSD and need no separate check |

> **The LinkML linter** runs for all policies, with the rule set from the policy's `linter:` section.
> The section is inherited and merged per rule (`_merge_policies` in `server.py`), so that `gold.yaml` can
> raise `standard_naming` to `error` without repeating the rest of the rule configuration. `make lint` uses its
> own configuration (`src/assets/containers/.linkmllint.yaml`) with `standard_naming` switched off.

> **The `snake_case` format:** Slot names may only contain lowercase letters (`a-z`), digits (`0-9`) and underscores (`_`). **Hyphens are not allowed** — use compound words without separation (e.g. `epost`, `epostadresse`) or underscores (`mobilnummer_utgaar`).
>
> FINT schemas and oreg schemas from XSD have `slot_naming: camel` in `build.yaml` — they inherit camelCase from their source.

---

### basis-no

Inherits bronze. Adds requirements from Digdir's common modeling rules and the repository's own
conventions. Inherited by [`silver`](#silver), [`felles-begrepskatalog`](#felles-begrepskatalog) and
[`felles-datakatalog`](#felles-datakatalog). Default policy for Norwegian schemas in the repository that
are not at silver or higher.

| Check | Severity | Upgraded to | Digdir rule | FAIR | Description |
|---|---|---|---|---|---|
| `schema.default_prefix` is an absolute HTTPS URI ending in `/` | error | — (already error) | [4 — Identifiserbarhet](https://www.digdir.no/informasjonsforvaltning/felles-modelleringsregler-offentlig-forvaltning/3029#identifiserbarhet) | — | Repository convention: a literal URI equal to `id` + `/` (cf. `CONVENTIONS.md`) |
| The schema has no more than 50 classes (except `tree_root`) | warning | error (gold) | [6 — Modularitet](https://www.digdir.no/informasjonsforvaltning/felles-modelleringsregler-offentlig-forvaltning/3029#modularitet) | — | A manageable number of model elements per module |
| All classes (except `tree_root`) have a `class_uri` | warning | error (gold) | [4 — Identifiserbarhet](https://www.digdir.no/informasjonsforvaltning/felles-modelleringsregler-offentlig-forvaltning/3029#identifiserbarhet), [8 — Maskinprosserbarhet](https://www.digdir.no/informasjonsforvaltning/felles-modelleringsregler-offentlig-forvaltning/3029#maskinprosserbarhet) | [F3, I1](https://www.go-fair.org/fair-principles/) | Maps the class to an RDF vocabulary |
| All global slots (except identifier slots) have a `slot_uri` | warning | error (gold) | [4 — Identifiserbarhet](https://www.digdir.no/informasjonsforvaltning/felles-modelleringsregler-offentlig-forvaltning/3029#identifiserbarhet), [8 — Maskinprosserbarhet](https://www.digdir.no/informasjonsforvaltning/felles-modelleringsregler-offentlig-forvaltning/3029#maskinprosserbarhet) | [I1](https://www.go-fair.org/fair-principles/) | Maps the property to an RDF vocabulary |
| All classes (except `tree_root`, `mixin`, `abstract`) have an identifier slot | warning | error (gold) | [4 — Identifiserbarhet](https://www.digdir.no/informasjonsforvaltning/felles-modelleringsregler-offentlig-forvaltning/3029#identifiserbarhet) | [F1](https://www.go-fair.org/fair-principles/) | Ensures that instances of the class can be uniquely identified |
| All classes (except `tree_root`; AP-NO profiles excepted) have `annotations.begrepsidentifikator` | warning | error (gold) | [13 — Begreper](https://www.digdir.no/informasjonsforvaltning/felles-modelleringsregler-offentlig-forvaltning/3029#begreper) | [A2](https://www.go-fair.org/fair-principles/) | Links model elements to domain concepts in a concept catalog |
| Own slots with controlled vocabularies have correct annotations | warning | error (gold) | [8 — Maskinprosserbarhet](https://www.digdir.no/informasjonsforvaltning/felles-modelleringsregler-offentlig-forvaltning/3029#maskinprosserbarhet) | [I1](https://www.go-fair.org/fair-principles/) | Ensures machine-readable documentation of vocabulary requirements |
| `build.yaml` has `generators.erdiagram: true` | warning | error (gold) | [5 — Visualisering](https://www.digdir.no/informasjonsforvaltning/felles-modelleringsregler-offentlig-forvaltning/3029#visualisering) | — | Ensures that an ER diagram is generated for the schema. Skipped if there is no `build.yaml` to read |

> **All bronze and basis-no warnings are currently upgraded to `error` at the gold level** (verified in this review — see
> `specs/done/full-gjennomgang-policy-alvorsgrad-og-overlapp.md`). If a future new `warning` check is **not**
> to be upgraded, this must be justified explicitly here and in the YAML file itself, not just silently left out
> of `gold.yaml` — see the coherence test mentioned under § gold.

> **Controlled vocabularies:** Slots with `annotations.gyldige_verdier` must have `annotations.vokabular_krav` (`skal`|`bør`|`kan`, i.e. shall/should/may) and the `description` must contain a matching SKAL/BØR/KAN wording. Ensures consistent and machine-readable documentation of vocabulary requirements. See [CONVENTIONS.md § Kontrollerte vokabular](../../../CONVENTIONS.md#kontrollerte-vokabular--annotation-konvensjon).

---

### silver

Inherits basis-no (and thereby bronze). Adds lifecycle metadata and requirements from DCAT-AP-NO and DQV-AP-NO
for domain models in the Norwegian public sector, as well as instance checks for
controlled vocabularies.

| Check | Severity | Upgraded to | Digdir rule | FAIR | Description |
|---|---|---|---|---|---|
| `schema.annotations.utgiver` is a URI of the form `https://data.norge.no/organizations/<orgnr>` | warning | error (gold) | [10 — Ansvar](https://www.digdir.no/informasjonsforvaltning/felles-modelleringsregler-offentlig-forvaltning/3029#ansvar) | [R1.2](https://www.go-fair.org/fair-principles/) | Identifies who is responsible for the model |
| `schema.annotations.endringsdato` is an ISO 8601 date | warning | error (gold) | [9 — Datering](https://www.digdir.no/informasjonsforvaltning/felles-modelleringsregler-offentlig-forvaltning/3029#datering) | [R1.3](https://www.go-fair.org/fair-principles/) | Date of the last modification |
| `schema.annotations.status` is an ADMS Status URI | warning | error (gold) | [11 — Modellstatus](https://www.digdir.no/informasjonsforvaltning/felles-modelleringsregler-offentlig-forvaltning/3029#modellstatus) | [R1.3](https://www.go-fair.org/fair-principles/) | Explicit lifecycle status (`UnderDevelopment`/`Completed`/`Deprecated`/`Withdrawn`) |
| The schema imports `dqv-ap-no-schema` (directly or transitively) | warning | error (gold) | [14 — Gjenbruk](https://www.digdir.no/informasjonsforvaltning/felles-modelleringsregler-offentlig-forvaltning/3029#gjenbruk) | [I3](https://www.go-fair.org/fair-principles/) | Reuse of the quality vocabulary (Kvalitetsmaal, Kvalitetsmaaling etc.) instead of equivalent classes/slots of its own |
| `Katalog` has `dct:title` | error | — (already error) | [1 — Forståelighet](https://www.digdir.no/informasjonsforvaltning/felles-modelleringsregler-offentlig-forvaltning/3029#forstelighet), [2 — Meningsfullhet](https://www.digdir.no/informasjonsforvaltning/felles-modelleringsregler-offentlig-forvaltning/3029#meningsfullhet), [10 — Ansvar](https://www.digdir.no/informasjonsforvaltning/felles-modelleringsregler-offentlig-forvaltning/3029#ansvar) | [F2, R1.2](https://www.go-fair.org/fair-principles/) | Title of the catalog |
| `Katalog` has `dct:description` | error | — (already error) | [1 — Forståelighet](https://www.digdir.no/informasjonsforvaltning/felles-modelleringsregler-offentlig-forvaltning/3029#forstelighet), [2 — Meningsfullhet](https://www.digdir.no/informasjonsforvaltning/felles-modelleringsregler-offentlig-forvaltning/3029#meningsfullhet), [10 — Ansvar](https://www.digdir.no/informasjonsforvaltning/felles-modelleringsregler-offentlig-forvaltning/3029#ansvar) | [F2, R1.2](https://www.go-fair.org/fair-principles/) | Description of the catalog |
| `Katalog` has `dcat:contactPoint` | error | — (already error) | [1 — Forståelighet](https://www.digdir.no/informasjonsforvaltning/felles-modelleringsregler-offentlig-forvaltning/3029#forstelighet), [2 — Meningsfullhet](https://www.digdir.no/informasjonsforvaltning/felles-modelleringsregler-offentlig-forvaltning/3029#meningsfullhet), [10 — Ansvar](https://www.digdir.no/informasjonsforvaltning/felles-modelleringsregler-offentlig-forvaltning/3029#ansvar) | [F2, R1.2](https://www.go-fair.org/fair-principles/) | Contact point for the catalog |
| `Katalog` has `dct:publisher` | error | — (already error) | [1 — Forståelighet](https://www.digdir.no/informasjonsforvaltning/felles-modelleringsregler-offentlig-forvaltning/3029#forstelighet), [2 — Meningsfullhet](https://www.digdir.no/informasjonsforvaltning/felles-modelleringsregler-offentlig-forvaltning/3029#meningsfullhet), [10 — Ansvar](https://www.digdir.no/informasjonsforvaltning/felles-modelleringsregler-offentlig-forvaltning/3029#ansvar) | [F2, R1.2](https://www.go-fair.org/fair-principles/) | Publisher of the catalog |
| `Katalogpost` has `dct:modified` | error | — (already error) | [9 — Datering](https://www.digdir.no/informasjonsforvaltning/felles-modelleringsregler-offentlig-forvaltning/3029#datering) | [R1.3](https://www.go-fair.org/fair-principles/) | Modification date of the catalog record |
| `Katalogpost` has `foaf:primaryTopic` | error | — (already error) | [9 — Datering](https://www.digdir.no/informasjonsforvaltning/felles-modelleringsregler-offentlig-forvaltning/3029#datering) | [R1.3](https://www.go-fair.org/fair-principles/) | Link to the main resource the catalog record describes |
| `Datasett` has `dct:title` | error | — (already error) | [1 — Forståelighet](https://www.digdir.no/informasjonsforvaltning/felles-modelleringsregler-offentlig-forvaltning/3029#forstelighet), [2 — Meningsfullhet](https://www.digdir.no/informasjonsforvaltning/felles-modelleringsregler-offentlig-forvaltning/3029#meningsfullhet), [10 — Ansvar](https://www.digdir.no/informasjonsforvaltning/felles-modelleringsregler-offentlig-forvaltning/3029#ansvar) | [F2, R1.2](https://www.go-fair.org/fair-principles/) | Title of the dataset |
| `Datasett` has `dct:description` | error | — (already error) | [1 — Forståelighet](https://www.digdir.no/informasjonsforvaltning/felles-modelleringsregler-offentlig-forvaltning/3029#forstelighet), [2 — Meningsfullhet](https://www.digdir.no/informasjonsforvaltning/felles-modelleringsregler-offentlig-forvaltning/3029#meningsfullhet), [10 — Ansvar](https://www.digdir.no/informasjonsforvaltning/felles-modelleringsregler-offentlig-forvaltning/3029#ansvar) | [F2, R1.2](https://www.go-fair.org/fair-principles/) | Description of the dataset |
| `Datasett` has `dcat:contactPoint` | error | — (already error) | [1 — Forståelighet](https://www.digdir.no/informasjonsforvaltning/felles-modelleringsregler-offentlig-forvaltning/3029#forstelighet), [2 — Meningsfullhet](https://www.digdir.no/informasjonsforvaltning/felles-modelleringsregler-offentlig-forvaltning/3029#meningsfullhet), [10 — Ansvar](https://www.digdir.no/informasjonsforvaltning/felles-modelleringsregler-offentlig-forvaltning/3029#ansvar) | [F2, R1.2](https://www.go-fair.org/fair-principles/) | Contact point for the dataset |
| `Datasett` has `dcat:theme` | error | — (already error) | [1 — Forståelighet](https://www.digdir.no/informasjonsforvaltning/felles-modelleringsregler-offentlig-forvaltning/3029#forstelighet), [2 — Meningsfullhet](https://www.digdir.no/informasjonsforvaltning/felles-modelleringsregler-offentlig-forvaltning/3029#meningsfullhet), [10 — Ansvar](https://www.digdir.no/informasjonsforvaltning/felles-modelleringsregler-offentlig-forvaltning/3029#ansvar) | [F2, R1.2](https://www.go-fair.org/fair-principles/) | Theme/category of the dataset (LOS) |
| `Datasett` has `dct:publisher` | error | — (already error) | [1 — Forståelighet](https://www.digdir.no/informasjonsforvaltning/felles-modelleringsregler-offentlig-forvaltning/3029#forstelighet), [2 — Meningsfullhet](https://www.digdir.no/informasjonsforvaltning/felles-modelleringsregler-offentlig-forvaltning/3029#meningsfullhet), [10 — Ansvar](https://www.digdir.no/informasjonsforvaltning/felles-modelleringsregler-offentlig-forvaltning/3029#ansvar) | [F2, R1.2](https://www.go-fair.org/fair-principles/) | Publisher of the dataset |
| `Datasett` has `dct:accessRights` | warning | error (gold) | — | — | Access level of the dataset — corresponds to the traffic light system (green/yellow/red) in Digdir's guideline [«Orden i eget hus», step 4](https://www.digdir.no/informasjonsforvaltning/steg-4-vurdere-tilgangsniva/2723) |
| `Datasett` has `dcatap:applicableLegislation` | warning | error (gold) | — | — | Applicable legislation (legal basis) for access to the dataset — same step as above |
| `Distribusjon` has `dcat:accessURL` | error | — (already error) | — | [A1](https://www.go-fair.org/fair-principles/) | Access address of the distribution |
| `Distribusjon` has a slot with `dct:license` | warning | error (gold) | [7 — Tilgjengeliggjøring](https://www.digdir.no/informasjonsforvaltning/felles-modelleringsregler-offentlig-forvaltning/3029#tilgjengeliggjring) | [R1.1](https://www.go-fair.org/fair-principles/) | License at the distribution level. See the separate note on the three «license» checks under § gold |
| `Datatjeneste` has `dcat:endpointURL` | error | — (already error) | [1 — Forståelighet](https://www.digdir.no/informasjonsforvaltning/felles-modelleringsregler-offentlig-forvaltning/3029#forstelighet), [2 — Meningsfullhet](https://www.digdir.no/informasjonsforvaltning/felles-modelleringsregler-offentlig-forvaltning/3029#meningsfullhet), [10 — Ansvar](https://www.digdir.no/informasjonsforvaltning/felles-modelleringsregler-offentlig-forvaltning/3029#ansvar) | [F2, A1, R1.2](https://www.go-fair.org/fair-principles/) | Endpoint URL of the service |
| `Datatjeneste` has `dcat:contactPoint` | error | — (already error) | [1 — Forståelighet](https://www.digdir.no/informasjonsforvaltning/felles-modelleringsregler-offentlig-forvaltning/3029#forstelighet), [2 — Meningsfullhet](https://www.digdir.no/informasjonsforvaltning/felles-modelleringsregler-offentlig-forvaltning/3029#meningsfullhet), [10 — Ansvar](https://www.digdir.no/informasjonsforvaltning/felles-modelleringsregler-offentlig-forvaltning/3029#ansvar) | [F2, A1, R1.2](https://www.go-fair.org/fair-principles/) | Contact point for the service |
| `Datatjeneste` has `dct:title` | error | — (already error) | [1 — Forståelighet](https://www.digdir.no/informasjonsforvaltning/felles-modelleringsregler-offentlig-forvaltning/3029#forstelighet), [2 — Meningsfullhet](https://www.digdir.no/informasjonsforvaltning/felles-modelleringsregler-offentlig-forvaltning/3029#meningsfullhet), [10 — Ansvar](https://www.digdir.no/informasjonsforvaltning/felles-modelleringsregler-offentlig-forvaltning/3029#ansvar) | [F2, A1, R1.2](https://www.go-fair.org/fair-principles/) | Title of the service |
| `Datatjeneste` has `dct:publisher` | error | — (already error) | [1 — Forståelighet](https://www.digdir.no/informasjonsforvaltning/felles-modelleringsregler-offentlig-forvaltning/3029#forstelighet), [2 — Meningsfullhet](https://www.digdir.no/informasjonsforvaltning/felles-modelleringsregler-offentlig-forvaltning/3029#meningsfullhet), [10 — Ansvar](https://www.digdir.no/informasjonsforvaltning/felles-modelleringsregler-offentlig-forvaltning/3029#ansvar) | [F2, A1, R1.2](https://www.go-fair.org/fair-principles/) | Publisher of the service |
| `Aktør` has `foaf:name` | error | — (already error) | [1 — Forståelighet](https://www.digdir.no/informasjonsforvaltning/felles-modelleringsregler-offentlig-forvaltning/3029#forstelighet) | [F2](https://www.go-fair.org/fair-principles/) | Name of the agent |
| The container class (`tree_root`) has attributes with range `Katalog`, `Datasett`, `Kvalitetsmaal`, `Kvalitetsmaaling` | error | — (already error) | — | — | Ensures that the main classes of DCAT-AP-NO/DQV-AP-NO are connected to the container |
| The container class has attributes with range `Distribusjon`, `Datatjeneste`, `Kvalitetsdimensjon`, `Kvalitetsmerknad` | warning | error (gold) | — | — | Ensures that the supporting classes are connected to the container |
| Instance values for slots with `vokabular_pattern` match the regex pattern **(requires `INSTANCE=`)** | error/warning/info | N/A (depends on `vokabular_krav`, not a level upgrade) | [8 — Maskinprosserbarhet](https://www.digdir.no/informasjonsforvaltning/felles-modelleringsregler-offentlig-forvaltning/3029#maskinprosserbarhet) | [I1](https://www.go-fair.org/fair-principles/) | Code: `instance_slot_invalid_vocabulary_pattern`. Severity depends on `vokabular_krav`: **error** for `skal`, **warning** for `bør`, **info** for `kan` |
| Instance values come from the correct vocabulary domain (`gyldige_verdier`) **(requires `INSTANCE=`)** | error/warning | N/A (depends on `vokabular_krav`, not a level upgrade) | [8 — Maskinprosserbarhet](https://www.digdir.no/informasjonsforvaltning/felles-modelleringsregler-offentlig-forvaltning/3029#maskinprosserbarhet) | [I1](https://www.go-fair.org/fair-principles/) | Code: `instance_slot_invalid_vocabulary_domain`. Checks that URIs start with the `gyldige_verdier` domain |

Valid values for `annotations.status`: `http://purl.org/adms/status/UnderDevelopment`, `Completed`, `Deprecated`, `Withdrawn`.

> **Access level and Digdir's traffic light system:** The `dct:accessRights` values from the EU's
> Access Right vocabulary (`PUBLIC`/`RESTRICTED`/`NON_PUBLIC`, see the `tilgangsrettigheter` slot
> in `dcat-ap-no-schema.yaml`) correspond functionally to green/yellow/red in the traffic light system from
> Digdir's guideline [«Orden i eget hus», step 4 — assessing the access level](https://www.digdir.no/informasjonsforvaltning/steg-4-vurdere-tilgangsniva/2723).
> `dcatap:applicableLegislation` (`gjeldende_lovgivning`) corresponds to the legal basis requirement in the same
> step. These are checked via `datasett_tilgangsrettigheter` and `datasett_lovgivning`
> above.

The annotation keys correspond to `Informasjonsmodell` slots in `modelldcat-ap-no-schema.yaml`
(Digdir rules 10 and 8 — machine processability via ModellDCAT-AP-NO).  
`make gen-informasjonsmodell-instance` generates the `Informasjonsmodell` instance for the schema from these annotations; `make gen-modellkatalog-instance` then aggregates all such instances into per-organization model catalogs.

**Example (instance check):** If the `spraak` slot has `vokabular_krav: skal` and `vokabular_pattern: "^http://publications\\.europa\\.eu/resource/authority/language/[A-Z]{3}$"`, then the value `"http://example.com/NOB"` gives an **error** (wrong domain) and `"http://publications.europa.eu/resource/authority/language/NORSK"` gives an **error** (wrong pattern — should be a 3-letter code).

---

### gold

Inherits silver, basis-no and bronze. Implements the gap to the FAIR principles (Findable, Accessible, Interoperable, Reusable). All violations give `error` — including those that are warnings at bronze.

| Check | Severity | Origin | Digdir rule | FAIR | Description |
|---|---|---|---|---|---|
| `schema.id` present | error | Bronze (already error) | [4 — Identifiserbarhet](https://www.digdir.no/informasjonsforvaltning/felles-modelleringsregler-offentlig-forvaltning/3029#identifiserbarhet) | [F1](https://www.go-fair.org/fair-principles/) | Persistent identifier for the schema |
| `schema.id` is an HTTP(S) URI | error | Bronze (already error) | [4 — Identifiserbarhet](https://www.digdir.no/informasjonsforvaltning/felles-modelleringsregler-offentlig-forvaltning/3029#identifiserbarhet) | [F1](https://www.go-fair.org/fair-principles/) | Ensures that the identifier is a resolvable URI |
| `schema.name` present | error | Bronze (already error) | [1 — Forståelighet](https://www.digdir.no/informasjonsforvaltning/felles-modelleringsregler-offentlig-forvaltning/3029#forstelighet) | — | Machine-readable name of the schema |
| `schema.title` present | error | Bronze (already error) | [1 — Forståelighet](https://www.digdir.no/informasjonsforvaltning/felles-modelleringsregler-offentlig-forvaltning/3029#forstelighet), [2 — Meningsfullhet](https://www.digdir.no/informasjonsforvaltning/felles-modelleringsregler-offentlig-forvaltning/3029#meningsfullhet) | [F2](https://www.go-fair.org/fair-principles/) | The title is part of the rich metadata that makes the resource searchable |
| `schema.default_prefix` present | error | Bronze (already error) | [4 — Identifiserbarhet](https://www.digdir.no/informasjonsforvaltning/felles-modelleringsregler-offentlig-forvaltning/3029#identifiserbarhet) | — | Default namespace for local identifiers |
| `schema.default_prefix` is an absolute HTTPS URI ending in `/` | error | Basis-no (already error) | [4 — Identifiserbarhet](https://www.digdir.no/informasjonsforvaltning/felles-modelleringsregler-offentlig-forvaltning/3029#identifiserbarhet) | — | Ensures correct URI construction |
| `schema.description` present | error | Bronze → gold | [1 — Forståelighet](https://www.digdir.no/informasjonsforvaltning/felles-modelleringsregler-offentlig-forvaltning/3029#forstelighet) | [F2](https://www.go-fair.org/fair-principles/) | Free-text description of the purpose of the schema |
| `schema.version` present | error | Bronze → gold | [9 — Datering](https://www.digdir.no/informasjonsforvaltning/felles-modelleringsregler-offentlig-forvaltning/3029#datering) | [F4](https://www.go-fair.org/fair-principles/) | Versioning supports catalog registration and traceability |
| `schema.license` present | error | Bronze → gold | [7 — Tilgjengeliggjøring](https://www.digdir.no/informasjonsforvaltning/felles-modelleringsregler-offentlig-forvaltning/3029#tilgjengeliggjring) | [R1.1](https://www.go-fair.org/fair-principles/) | License for reuse of the schema |
| The schema has no more than 50 classes (except `tree_root`) | error | Basis-no → gold | [6 — Modularitet](https://www.digdir.no/informasjonsforvaltning/felles-modelleringsregler-offentlig-forvaltning/3029#modularitet) | — | A manageable number of model elements per module |
| Linter `standard_naming` (classes `UpperCamelCase`, slots/attributes `snake_case`) | error | Bronze → gold | [3 — Navne- og skrivekonvensjoner](https://www.digdir.no/informasjonsforvaltning/felles-modelleringsregler-offentlig-forvaltning/3029#navne_og_skrivekonvensjoner) | — | Overridden via `linter.rules.standard_naming.level` in `gold.yaml` |
| All classes (except `tree_root`) have a `class_uri` | error | Basis-no → gold | [4 — Identifiserbarhet](https://www.digdir.no/informasjonsforvaltning/felles-modelleringsregler-offentlig-forvaltning/3029#identifiserbarhet), [8 — Maskinprosserbarhet](https://www.digdir.no/informasjonsforvaltning/felles-modelleringsregler-offentlig-forvaltning/3029#maskinprosserbarhet) | [F3, I1](https://www.go-fair.org/fair-principles/) | Maps the class to an RDF vocabulary |
| All global slots have a `slot_uri` | error | Basis-no → gold | [4 — Identifiserbarhet](https://www.digdir.no/informasjonsforvaltning/felles-modelleringsregler-offentlig-forvaltning/3029#identifiserbarhet), [8 — Maskinprosserbarhet](https://www.digdir.no/informasjonsforvaltning/felles-modelleringsregler-offentlig-forvaltning/3029#maskinprosserbarhet) | [I1](https://www.go-fair.org/fair-principles/) | Maps the property to an RDF vocabulary |
| All classes (except `tree_root`) have an identifier slot | error | Basis-no → gold | [4 — Identifiserbarhet](https://www.digdir.no/informasjonsforvaltning/felles-modelleringsregler-offentlig-forvaltning/3029#identifiserbarhet) | [F1](https://www.go-fair.org/fair-principles/) | Ensures that instances of the class can be uniquely identified |
| All classes (except `tree_root`) have `annotations.begrepsidentifikator` | error | Basis-no → gold | [13 — Begreper](https://www.digdir.no/informasjonsforvaltning/felles-modelleringsregler-offentlig-forvaltning/3029#begreper) | [A2](https://www.go-fair.org/fair-principles/) | Links model elements to domain concepts in a concept catalog |
| Slots with controlled vocabularies have correct annotations | error | Basis-no → gold | [8 — Maskinprosserbarhet](https://www.digdir.no/informasjonsforvaltning/felles-modelleringsregler-offentlig-forvaltning/3029#maskinprosserbarhet) | [I1](https://www.go-fair.org/fair-principles/) | Ensures machine-readable documentation of vocabulary requirements |
| `inlined`/`inlined_as_list` is only set where the range is a class | error | Bronze → gold | [8 — Maskinprosserbarhet](https://www.digdir.no/informasjonsforvaltning/felles-modelleringsregler-offentlig-forvaltning/3029#maskinprosserbarhet) | [I1](https://www.go-fair.org/fair-principles/) | Catches dead configuration — the key has no effect on a primitive range |
| `build.yaml` has `generators.erdiagram: true` | error | Basis-no → gold | [5 — Visualisering](https://www.digdir.no/informasjonsforvaltning/felles-modelleringsregler-offentlig-forvaltning/3029#visualisering) | — | Ensures that an ER diagram is generated for the schema |
| The schema imports `dqv-ap-no-schema` | error | Silver → gold | [14 — Gjenbruk](https://www.digdir.no/informasjonsforvaltning/felles-modelleringsregler-offentlig-forvaltning/3029#gjenbruk) | [I3](https://www.go-fair.org/fair-principles/) | Reuse of the quality vocabulary instead of equivalent classes/slots of its own |
| Locally defined types (`types:`) have a `uri:` in a standard namespace | error | Bronze → gold | [15 — Standardiserte datatyper](https://www.digdir.no/informasjonsforvaltning/felles-modelleringsregler-offentlig-forvaltning/3029#standardiserte_datatyper) | [I1](https://www.go-fair.org/fair-principles/) | Types inherited from `linkml:types` are already guaranteed to be mapped to XSD |
| The schema declares at least one standard vocabulary prefix (`dct`, `dcat`, `skos`, `prov`, `rdf`, `rdfs`, `owl`, `foaf`, `xsd`) | error | New at gold | [8 — Maskinprosserbarhet](https://www.digdir.no/informasjonsforvaltning/felles-modelleringsregler-offentlig-forvaltning/3029#maskinprosserbarhet) | [I2](https://www.go-fair.org/fair-principles/) | Standard vocabularies ensure interoperability across systems |
| The schema has a slot with `dct:license` | error | New at gold | [7 — Tilgjengeliggjøring](https://www.digdir.no/informasjonsforvaltning/felles-modelleringsregler-offentlig-forvaltning/3029#tilgjengeliggjring) | [R1.1](https://www.go-fair.org/fair-principles/) | License information is a prerequisite for reuse. See the separate note on the three «license» checks right below the table |
| The schema has a slot for provenance (`prov:wasAttributedTo`, `prov:wasGeneratedBy`, `dct:creator`, `dct:publisher` or `dct:contributor`) | error | New at gold | [10 — Ansvar](https://www.digdir.no/informasjonsforvaltning/felles-modelleringsregler-offentlig-forvaltning/3029#ansvar) | [R1.2](https://www.go-fair.org/fair-principles/) | Provenance is important for trust in and reuse of data. For AP-NO-conformant schemas this is already covered automatically by the mandatory `dct:publisher` requirements on `Katalog`/`Datasett`/`Datatjeneste` — real added value only for schemas outside the AP-NO domain pattern |
| `schema.annotations.utgiver` present | error | Silver → gold | [10 — Ansvar](https://www.digdir.no/informasjonsforvaltning/felles-modelleringsregler-offentlig-forvaltning/3029#ansvar) | [R1.2](https://www.go-fair.org/fair-principles/) | URI of the responsible organization |
| `schema.annotations.endringsdato` present | error | Silver → gold | [9 — Datering](https://www.digdir.no/informasjonsforvaltning/felles-modelleringsregler-offentlig-forvaltning/3029#datering) | [R1.3](https://www.go-fair.org/fair-principles/) | ISO 8601 date of the last modification |
| `schema.annotations.oppdateringsfrekvens` present | error | Silver → gold | [9 — Datering](https://www.digdir.no/informasjonsforvaltning/felles-modelleringsregler-offentlig-forvaltning/3029#datering) | [R1.3](https://www.go-fair.org/fair-principles/) | URI from the EU's Frequency Named Authority List |
| `schema.annotations.status` present | error | Silver → gold | [11 — Modellstatus](https://www.digdir.no/informasjonsforvaltning/felles-modelleringsregler-offentlig-forvaltning/3029#modellstatus) | [R1.3](https://www.go-fair.org/fair-principles/) | ADMS Status URI for the model status |
| `Distribusjon` has a slot with `dct:license` | error | Silver → gold | [7 — Tilgjengeliggjøring](https://www.digdir.no/informasjonsforvaltning/felles-modelleringsregler-offentlig-forvaltning/3029#tilgjengeliggjring) | [R1.1](https://www.go-fair.org/fair-principles/) | License at the distribution level. See the separate note on the three «license» checks right below the table |
| `Datasett` has `dct:accessRights` | error | Silver → gold | — | — | Access level (the traffic light system) |
| `Datasett` has `dcatap:applicableLegislation` | error | Silver → gold | — | — | Legal basis for access |
| The container class has an attribute with range `Distribusjon` | error | Silver → gold | — | — | — |
| The container class has an attribute with range `Datatjeneste` | error | Silver → gold | — | — | — |
| The container class has an attribute with range `Kvalitetsdimensjon` | error | Silver → gold | — | — | — |
| The container class has an attribute with range `Kvalitetsmerknad` | error | Silver → gold | — | — | — |

> **Upgrade status (verified programmatically, see
> `specs/done/full-gjennomgang-policy-alvorsgrad-og-overlapp.md` and
> `specs/done/gjennomgang-bronze-policy-generisk.md`):** bronze has **5** `warning` checks
> (3 in `checks:` + `schema.description`/`schema.version` via the `required`/`recommended` mechanism) and
> the linter rule `standard_naming`; basis-no adds **7** `warning` checks. All are upgraded to
> `error` at the gold level. Silver adds **12** new `warning` checks of its own, and **all 12** are also
> upgraded. Automated tests exist in `tests/test_mcp_policies.py` (`TestPolicyKoherens`, both for
> `checks:` and `linter:`), and they fail if this ever stops being true.

> **Three different «license» checks — not duplicates, but different aims:** the table has three rows that mention
> `dct:license`/license, and at first glance these may look like duplicates:
>
> - **`schema.license` present** — is the schema **itself** (the artifact) licensed?
> - **The schema has a slot with `dct:license`** (`r11_license`) — is there **a slot anywhere**
>   in the model that lets instances express license information?
> - **`Distribusjon` has a slot with `dct:license`** (`distribusjon_lisens`) — does `Distribusjon`
>   **specifically** have such a slot?
>
> A schema that passes the last (more specific) check will automatically pass the middle one too, since
> `Distribusjon`'s `dct:license` slot counts as «a slot anywhere». This is expected, not an error.

---

## Publishing policies

Domain-specific policies for publishing to national catalogs. They inherit `basis-no`
and are intended to be used in addition to the medallion levels — typically in the CI pipeline for schemas
that have an associated data file.

| Policy | Requirements | Target catalog |
|---|---|---|
| [`felles-begrepskatalog`](#felles-begrepskatalog) | Basis-no + SKOS-AP-NO-Begrep conformance for concept catalog schemas | [data.norge.no/concepts](https://data.norge.no/concepts) |
| [`felles-datakatalog`](#felles-datakatalog) | Basis-no + ModelDCAT-AP-NO conformance for model catalog schemas | [data.norge.no/models](https://data.norge.no/models) |

---

### felles-begrepskatalog

For concept catalog schemas that publish to [data.norge.no/concepts](https://data.norge.no/concepts)
via SKOS-AP-NO-Begrep. See [Publish to Felles Begrepskatalog](https://audunautomat.github.io/linkml-datamodellering-no/en/publisering/publisering-begrep/) for the full guide.

| Category | Requirement | Severity | Code | Source |
|---|---|---|---|---|
| Import and prefix | Imports `skos-ap-no-schema` | **error** | `schema_importerer_skos_ap_no` | Repository requirement¹ |
| Import and prefix | Declares the `skos:` prefix | **error** | `schema_brukar_skos_prefix` | [Vedlegg A — Navnerom brukt i standarden](https://informasjonsforvaltning.github.io/skos-ap-no-begrep/#Navnerom-brukt-i-standarden) |
| Import and prefix | Declares the `dct:` prefix | **error** | `schema_brukar_dct_prefix` | [Vedlegg A — Navnerom brukt i standarden](https://informasjonsforvaltning.github.io/skos-ap-no-begrep/#Navnerom-brukt-i-standarden) |
| Container class | The container has an attribute with range `Begrep` | **error** | `container_har_begrep` | [§ Begrep](https://data.norge.no/specification/skos-ap-no-begrep#Begrep)² |
| Container class | The container has an attribute with range `Samling` | warning | `container_har_samling` | [§ Begrepssamling](https://data.norge.no/specification/skos-ap-no-begrep#Begrepssamling)² |
| `Begrep` requirement | `skos:prefLabel` | **error** | `begrep_har_anbefalt_term` | [§ Begrep – anbefalt term](https://data.norge.no/specification/skos-ap-no-begrep#Begrep-anbefalt-term) |
| `Begrep` requirement | `skos:definition` or `euvoc:xlDefinition` | **error** | `begrep_har_definisjon` | [§ Begrep – definisjon, direkte angivelse](https://data.norge.no/specification/skos-ap-no-begrep#Begrep-definisjon-direkte-angivelse) / [via definisjonsobjekt](https://data.norge.no/specification/skos-ap-no-begrep#Begrep-definisjon-via-definisjonsobjekt) |
| `Begrep` requirement | `dct:identifier` | **error** | `begrep_har_identifikator` | [§ Begrep – identifikator](https://data.norge.no/specification/skos-ap-no-begrep#Begrep-identifikator) |
| `Begrep` requirement | `dct:publisher` | **error** | `begrep_har_utgjevar` | [§ Begrep – publisert av](https://data.norge.no/specification/skos-ap-no-begrep#Begrep-publisert-av) |
| `Begrep` requirement | `dcat:contactPoint` | **error** | `begrep_har_kontaktpunkt` | [§ Begrep – kontaktpunkt](https://data.norge.no/specification/skos-ap-no-begrep#Begrep-kontaktpunkt) |
| `Begrep` requirement | `dct:subject` | warning | `begrep_har_fagomrade` | [§ Begrep – fagområde](https://data.norge.no/specification/skos-ap-no-begrep#Begrep-fagområde) |
| `Begrep` requirement | `dct:creator` | warning | `begrep_har_ansvarleg_verksemd` | [§ Begrep – ansvarlig virksomhet](https://data.norge.no/specification/skos-ap-no-begrep#Begrep-ansvarlig-virksomhet) |
| `Begrep` requirement | `euvoc:startDate` | warning | `begrep_har_gyldig_fra` | [§ Begrep – dato gyldig fra og med](https://data.norge.no/specification/skos-ap-no-begrep#Begrep-dato-gyldig-fra-og-med) |
| `Begrep` requirement | `euvoc:endDate` | warning | `begrep_har_gyldig_til` | [§ Begrep – dato gyldig til og med](https://data.norge.no/specification/skos-ap-no-begrep#Begrep-dato-gyldig-til-og-med) |
| `Begrep` requirement | `dct:created` | warning | `begrep_har_opprettingsdato` | [§ Begrep – dato opprettet](https://data.norge.no/specification/skos-ap-no-begrep#Begrep-dato-opprettet) |
| `Begrep` requirement | `dct:modified` | warning | `begrep_har_endringsdato` | [§ Begrep – dato sist oppdatert](https://data.norge.no/specification/skos-ap-no-begrep#Begrep-dato-sist-oppdatert) |
| `Begrep` requirement | `skos:scopeNote` | warning | `begrep_har_merknad` | [§ Begrep – merknad](https://data.norge.no/specification/skos-ap-no-begrep#Begrep-merknad) |
| `Begrep` requirement | `skos:altLabel` | warning | `begrep_har_tillate_term` | [§ Begrep – tillatt term](https://data.norge.no/specification/skos-ap-no-begrep#Begrep-tillatt-term) |
| Bilingual requirement | `anbefalt_term` (skos:prefLabel) has range `LangString` and `multivalued: true` | warning | `begrep_anbefalt_term_er_multivalued_langstring` | [§ Begrep – anbefalt term](https://data.norge.no/specification/skos-ap-no-begrep#Begrep-anbefalt-term) (Merknad 1) |
| Bilingual requirement | `har_definisjon` has at least one Definisjon per language (nb, nn) | warning | `begrep_har_definisjon_pa_nb_og_nn` | [§ Begrep – anbefalt term](https://data.norge.no/specification/skos-ap-no-begrep#Begrep-anbefalt-term) (Merknad 1+2) |
| Instance check | The `dct:publisher` value is `https://data.norge.no/organizations/<9-digit orgnr>` and is in the list of known publishers | **error** | `utgjevar_er_kjend_org` | Repository-internal³ |

The `Begrep` requirements are mandatory according to SKOS-AP-NO-Begrep. The `Definisjon`, `AssosiativRelasjon`,
`GeneriskRelasjon`, `PartitivRelasjon` and `Samling` requirements are documented in
[`policies/felles-begrepskatalog.yaml`](felles-begrepskatalog.yaml).

¹ **Repository requirement:** a LinkML-technical prerequisite for expressing the vocabulary (import of
the schema, declaration of prefixes) — not a separate item in the specification text.
² **Repository convention:** the container class (`tree_root`) pattern is the repository's own
way of exposing the classes, not a requirement of the specification — the link points to
the class's general description in the specification for context.
³ **Repository-internal:** the list of known publisher URIs is maintained in the repository, not taken
from the specification.

**About the bilingual requirement (SK5, SKOS-AP-NO v.2.0.15):** `begrep_anbefalt_term_er_multivalued_langstring`
is a schema check — it ensures that the schema **can** contain bilingual values.
`begrep_har_definisjon_pa_nb_og_nn` is an instance check via an ID suffix convention.

**Limitation:** The bilingual requirement for `anbefalt_term` can **not** be validated in YAML instances
because of a LinkML limitation (LangString does not carry a language tag per value in YAML — see
`specs/bugs/langstring-rdflib-roundtrip.md`). Use RDF validation (SHACL) or a manual
review of the `.ttl` file to verify that both `@nb` and `@nn` are present.

---

### felles-datakatalog

For model catalog schemas that publish to [data.norge.no/models](https://data.norge.no/models)
via ModelDCAT-AP-NO. See [Publish to Felles Datakatalog](https://audunautomat.github.io/linkml-datamodellering-no/en/publisering/publisering-modell/) for the full guide.

| Category | Requirement | Severity | Code | Source |
|---|---|---|---|---|
| Import and prefix | Imports `modelldcat-ap-no-schema` | **error** | `schema_importerer_modelldcat_ap_no` | Repository requirement¹ |
| Import and prefix | Declares the `dct:` prefix | **error** | `schema_brukar_dct_prefix` | [Vedlegg A — Navnerom](https://data.norge.no/specification/modelldcat-ap-no#Navnerom) |
| Import and prefix | Declares the `dcat:` prefix | **error** | `schema_brukar_dcat_prefix` | [Vedlegg A — Navnerom](https://data.norge.no/specification/modelldcat-ap-no#Navnerom) |
| Container class | The container has an attribute with range `Modellkatalog` | **error** | `container_har_modellkatalog` | [§ Modellkatalog](https://data.norge.no/specification/modelldcat-ap-no#Modellkatalog)² |
| Container class | The container has an attribute with range `Informasjonsmodell` | **error** | `container_har_informasjonsmodell` | [§ Informasjonsmodell](https://data.norge.no/specification/modelldcat-ap-no#Informasjonsmodell)² |
| `Modellkatalog` requirement | `dct:title` | **error** | `modellkatalog_har_tittel` | [§ Modellkatalog – tittel](https://data.norge.no/specification/modelldcat-ap-no#Modellkatalog-tittel) |
| `Modellkatalog` requirement | `dct:description` | **error** | `modellkatalog_har_beskrivelse` | [§ Modellkatalog – beskrivelse](https://data.norge.no/specification/modelldcat-ap-no#Modellkatalog-beskrivelse) |
| `Modellkatalog` requirement | `dct:identifier` | warning | `modellkatalog_har_identifikator` | [§ Modellkatalog – identifikator](https://data.norge.no/specification/modelldcat-ap-no#Modellkatalog-identifikator) |
| `Modellkatalog` requirement | `dct:publisher` | **error** | `modellkatalog_har_utgjevar` | [§ Modellkatalog – utgiver](https://data.norge.no/specification/modelldcat-ap-no#Modellkatalog-utgiver) |
| `Modellkatalog` requirement | `dcat:contactPoint` | **error** | `modellkatalog_har_kontaktpunkt` | [§ Modellkatalog – kontaktpunkt](https://data.norge.no/specification/modelldcat-ap-no#Modellkatalog-kontaktpunkt) |
| `Modellkatalog` requirement | `dct:hasPart` | **error** | `modellkatalog_har_del` | [§ Modellkatalog – har del](https://data.norge.no/specification/modelldcat-ap-no#Modellkatalog-har-del) |
| `Modellkatalog` requirement | `dct:license` | warning | `modellkatalog_har_lisens` | [§ Modellkatalog – lisens](https://data.norge.no/specification/modelldcat-ap-no#Modellkatalog-lisens) |
| `Modellkatalog` requirement | `modelldcatno:model` | warning | `modellkatalog_har_modell` | [§ Modellkatalog – modell](https://data.norge.no/specification/modelldcat-ap-no#Modellkatalog-modell) |
| `Informasjonsmodell` requirement | `dct:title` | **error** | `informasjonsmodell_har_tittel` | [§ Informasjonsmodell – tittel](https://data.norge.no/specification/modelldcat-ap-no#Informasjonsmodell-tittel) |
| `Informasjonsmodell` requirement | `dct:publisher` | **error** | `informasjonsmodell_har_utgjevar` | [§ Informasjonsmodell – utgiver](https://data.norge.no/specification/modelldcat-ap-no#Informasjonsmodell-utgiver) |
| `Informasjonsmodell` requirement | `dcat:contactPoint` | **error** | `informasjonsmodell_har_kontaktpunkt` | [§ Informasjonsmodell – kontaktpunkt](https://data.norge.no/specification/modelldcat-ap-no#Informasjonsmodell-kontaktpunkt) |
| `Informasjonsmodell` requirement | `dct:description` | warning | `informasjonsmodell_har_beskrivelse` | [§ Informasjonsmodell – beskrivelse](https://data.norge.no/specification/modelldcat-ap-no#Informasjonsmodell-beskrivelse) |
| `Informasjonsmodell` requirement | `dct:identifier` | warning | `informasjonsmodell_har_identifikator` | [§ Informasjonsmodell – identifikator](https://data.norge.no/specification/modelldcat-ap-no#Informasjonsmodell-identifikator) |
| `Informasjonsmodell` requirement | `modelldcatno:informationModelIdentifier` | warning | `informasjonsmodell_har_modellidentifikator` | [§ Informasjonsmodell – informasjonsmodellidentifikator](https://data.norge.no/specification/modelldcat-ap-no#Informasjonsmodell-informasjonsmodellidentifikator) |
| `Informasjonsmodell` requirement | `dct:license` | warning | `informasjonsmodell_har_lisens` | [§ Informasjonsmodell – lisens](https://data.norge.no/specification/modelldcat-ap-no#Informasjonsmodell-lisens) |
| `Informasjonsmodell` requirement | `dcat:theme` | warning | `informasjonsmodell_har_tema` | [§ Informasjonsmodell – tema](https://data.norge.no/specification/modelldcat-ap-no#Informasjonsmodell-tema) |
| `Informasjonsmodell` requirement | `modelldcatno:containsModelElement` | warning | `informasjonsmodell_har_modellelement` | [§ Informasjonsmodell – inneholder modellelement](https://data.norge.no/specification/modelldcat-ap-no#Informasjonsmodell-inneholder-modellelement) |
| Instance check | The `dct:publisher` value is `https://data.norge.no/organizations/<9-digit orgnr>` and is in the list of known publishers | **error** | `utgjevar_er_kjend_org` | Repository-internal³ |

The `Modellkatalog` and `Informasjonsmodell` requirements are mandatory according to ModelDCAT-AP-NO,
with the exception of `dct:identifier` (recommended — see the separate footnote in the source table for
`modellkatalog_har_identifikator`; the same applies transitively to
`informasjonsmodell_har_identifikator`, which was already a `warning`). Note also that
`dcat:contactPoint` on `Informasjonsmodell` is mandatory (`error`), corrected from
the earlier `warning` — see `specs/done/kjeldehenvisning-felles-katalog-policyar.md`
for the rationale and source verification.

¹ **Repository requirement:** a LinkML-technical prerequisite for expressing the vocabulary (import of
the schema, declaration of prefixes) — not a separate item in the specification text.
² **Repository convention:** the container class (`tree_root`) pattern is the repository's own
way of exposing the classes, not a requirement of the specification — the link points to
the class's general description in the specification for context.
³ **Repository-internal:** the list of known publisher URIs is maintained in the repository, not taken
from the specification.

---

## The distinction between schema and data validation

| What | Tool | Policy |
|---|---|---|
| Schema quality | `make mcp-linkml-valider-modell POLICY=bronze/basis-no/silver/gold` | The policy files here |
| Data quality (instances) | `make validate-instance` | — |
| Publishing conformance | `make mcp-linkml-valider-modell POLICY=felles-datakatalog` | `felles-datakatalog.yaml` |

`felles-begrepskatalog.yaml` additionally has a separate `instance_checks:` field for
checks that require actual instance data (given via `INSTANCE=` to
`make mcp-linkml-valider-modell`), e.g. `utgjevar_er_kjend_org` (known publisher URIs) and
`begrep_har_definisjon_pa_nb_og_nn` (the bilingual requirement — see
`specs/done/avvik-skos-ap-no.md`, SK5 Forslag A).

---

## MCP tools

| Tool | Description |
|---|---|
| `validate_linkml_schema` | Validates a schema with lint + instance validation + policy checks. Parameters: `schemaText` (required), `policy` (default: `bronze`), `instanceText` (optional). |
| `validate_linkml_instance` | Validates an instance against a schema. Equivalent to `linkml validate --schema`. Parameters: `schemaText`, `instanceText`, `targetClass` (optional). |
