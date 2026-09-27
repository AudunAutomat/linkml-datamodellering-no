# Gjennomgang av bronze-policyen — generisk LinkML-baseline

## Bakgrunn

`src/mcp-linkml-validator/policies/bronze.yaml` er rotpolicyen i hierarkiet
(`silver`, `felles-datakatalog` og `felles-begrepskatalog` har alle
`extends: bronze`). I dag blandar han tre typar krav:

1. **Generiske LinkML-krav** som gjeld alle som modellerer i LinkML
2. **Norsk offentleg/Digdir-spesifikke krav** (Felles begrepskatalog, Digdir-regel 5/6)
3. **Repo-spesifikke konvensjonar** (`default_prefix` som literal URI, `build.yaml`,
   `gyldige_verdier`/`vokabular_krav`-annotasjonar, hardkoda FINT-schemanavn)

Målet er at bronze skal vere **generisk nok til å kunne brukast av alle som
modellerer i LinkML**. Ein ekstern modellerar med eit idiomatisk LinkML-skjema
skal då kunne passere bronze utan norske eller repo-spesifikke tilpassingar.

Denne specen evaluerer kvar sjekk og tilrår kva som bør bli verande og kva som
bør flyttast. Specen er sjølve leveransen (kartlegging/vurdering). Tiltaka under
§ Handlingsliste skal realiserast i ein eigen, seinare arbeidsøkt og er **ikkje
utførte**.

## Metode

1. Las `bronze.yaml`, `policies/README.md` og sjekkimplementasjonane i
   `src/mcp-linkml-validator/server.py`.
2. Køyrde bronze mot **alle 47 skjema** i repoet
   (`batch-flatten-and-validate.py --policy bronze`, output til scratchpad, ingen
   repo-filer endra) og talde issues per sjekk.
3. Køyrde bronze mot eit **idiomatisk LinkML-skjema** (mønster frå LinkML sin
   `personinfo`-tutorial: `default_prefix: personinfo`, `schema:`-mappingar,
   `tree_root`-container) for å sjå kva ein ekstern brukar ville møtt.
4. Køyrde to målretta minimaltestar (lokal `typeof`-type utan `uri`, `mixin`-klasse
   utan identifikator) for å stadfeste falske positive.
5. Sjekka kva LinkML sin innebygde linter (1.11.1) dekkjer, og korleis
   validatoren konfigurerer han.

### Empiri — bronze mot 47 repo-skjema

| Sjekk (issue-kode) | Issues | Skjema | Merknad |
|---|---:|---:|---|
| `all_classes_have_concept_ref` | 466 | 27 | 91 av dei i `ap-no/*`, som **ikkje skal** ha `begrepsidentifikator` (jf. `.claude/rules/linkml-schema.md`) |
| `slot_names_snake_case` | 132 | 7 | 6 oreg-skjema (camelCase frå XSD-kjelda) + `fair-metadata` |
| `all_slots_have_slot_uri` | 50 | 11 | Dei fleste er identifikator-slotten `id` |
| `all_classes_have_identifier` | 25 | 7 | FINT, `fair-metadata`, `register-over-aksjeeiere` |
| `missing_recommended_metadata` | 6 | 6 | `ModellkatalogContainer.description` |
| `class_count_exceeds_limit` | 1 | 1 | `fint-utdanning` (71 klasser) |
| `all_classes_have_class_uri`, `no_inlined_on_primitive_range`, `controlled_vocabulary_annotations`, `local_types_have_standard_uri`, `schema_har_erdiagram_aktivert`, `default_prefix_*`, `schema_id_is_http_uri`, `license` | 0 | 0 | — |

(15 `jsonschema validation`-feil i 5 oreg-skjema kjem frå instansvalidering av
eksempelfiler, ikkje frå policy-sjekkar, og er haldne utanfor.)

### Empiri — idiomatisk LinkML-skjema (personinfo-mønster)

```
False 1 4
error   default_prefix_is_https_uri    schema          | schema.default_prefix 'personinfo' er ikkje ein absolutt HTTPS-URI ...
warning missing_recommended_metadata   class:Container | Manglar anbefalt metadata: description
warning all_slots_have_slot_uri        slot:age        | Slot 'age' manglar slot_uri
warning all_classes_have_concept_ref   class:NamedThing| ... begrep i https://concept-catalog.fellesdatakatalog.digdir.no/...
warning all_classes_have_concept_ref   class:Person    | ...
```

**Eit heilt korrekt, idiomatisk LinkML-skjema feilar bronze** (1 error) berre
fordi `default_prefix` er eit prefiksnavn og ikkje ein literal URI. Attributtet
`hasFriend` (camelCase) vart **ikkje** fanga, sidan navnesjekkane berre ser på
globale `slots:`.

## Evaluering per sjekk

Kategoriar: **G** = generisk LinkML, **N** = norsk offentleg / Digdir, **R** = repo-konvensjon.

### Felt-krav (`required:` / `recommended:`)

| # | Sjekk | Alvor | Kat. | Tilråding | Grunngjeving |
|---|---|---|---|---|---|
| B1 | `schema.id` påkravd | error | G | **Bli** | Påkravd av LinkML-metamodellen òg. Redundant, men ufarleg. |
| B2 | `schema.name` påkravd | error | G | **Bli** | Som B1. |
| B3 | `schema.title` påkravd | error | G | **Bli** | Generisk god praksis, brukt av `gen-doc`. |
| B4 | `schema.description` anbefalt | warning | G | **Bli** | Generisk (F2). |
| B5 | `schema.version` anbefalt | warning | G | **Bli** | Generisk (sporbarheit). |
| B6 | `class.description` anbefalt | warning | G | **Bli** | Svarar til linter-regelen `recommended`. |
| B7 | `slot.description` anbefalt | warning | G | **Bli, utvid** | Dekkjer berre globale `slots:`, ikkje `attributes:`. Bør òg dekkje attributt. |

### `checks:`

| # | Sjekk | Alvor | Kat. | Tilråding | Grunngjeving |
|---|---|---|---|---|---|
| B8 | `schema_id_is_http_uri` | error | G | **Bli** | Generisk krav om persistent, oppløyseleg identifikator (F1). |
| B9 | `schema_has_default_prefix` | error | G | **Bli** | Generisk. LinkML har ein fallback, men eksplisitt `default_prefix` er etablert god praksis. |
| B10 | `default_prefix_is_https_uri` | error | **R** | **Skriv om i bronze + flytt konvensjonen til silver** | Sjekken les `default_prefix` som ein literal streng. Idiomatisk LinkML (`default_prefix: personinfo` + `prefixes:`) får **error**. Han avviser òg `http://`-namnerom (t.d. purl.org), og feilmeldinga har hardkoda `data.norge.no` som døme. **Bronze:** `default_prefix` skal ekspandere (via `prefixes:`, eller direkte) til ein absolutt HTTP(S)-URI som sluttar på `/` eller `#`. **Silver:** repokonvensjonen (literal HTTPS-URI lik `id` + `/`, jf. `CONVENTIONS.md`). |
| B11 | `schema_has_license` | warning | G | **Bli** | Generisk (R1.1). |
| B12 | `class_names_pascal_case` | warning | G | **Bli, stram inn** | LinkML-standardkonvensjon. Sjekkar i dag berre første bokstav, så `Min_Klasse`/`Min-Klasse` passerer. Bør sjekke `^[A-Z][A-Za-z0-9]*$`. Treng ikkje hoppe over `tree_root`. |
| B13 | `slot_names_snake_case` | warning | G (+R) | **Bli, men fjern repo-spesifikk konfig og utvid** | Konvensjonen er generisk (LinkML `standard_naming`). Men: (a) `exclude_schemas` har 7 hardkoda FINT-navn, som er repo-spesifikt og ikkje høyrer heime i ein generisk policy. Erstatt med ein per-skjema-mekanisme (sjå T3). (b) Attributt vert ikkje sjekka (stadfesta med `hasFriend`). (c) 6 oreg-skjema har same grunn til unntak som FINT (camelCase arva frå kjelda), men er ikkje unntekne. |
| B14 | `all_classes_have_class_uri` | warning | N/R | **Flytt til silver** | LinkML genererer alltid ein URI frå `default_prefix`. Repoet sin eigen regel (`.claude/rules/linkml-schema.md` § Slot-uri og class-uri) seier at eit lokalt `class_uri` «gir inga ny RDF-semantikk». Kravet er difor ei semantisk-interoperabilitets-ambisjon (I1), ikkje ein baseline. Sjekken godtek dessutan eit lokalt `class_uri` og måler difor ikkje det han hevdar (mapping til standardvokabular). 0 treff i repoet, så flyttinga får ingen praktisk verknad. |
| B15 | `all_slots_have_slot_uri` | warning | N/R | **Flytt til silver, unnta identifikator-slots** | Same grunngjeving som B14. I tillegg er dei fleste av dei 50 treffa slotten `id` (`identifier: true`). Han vert subjekt-URI i RDF og gir ingen trippel, så `slot_uri` er meiningslaus der. Dekkjer heller ikkje attributt. |
| B16 | `all_classes_have_identifier` | warning | N | **Flytt til silver, med unntak** | Lenka-data-ideal (Digdir-regel 4). Mange LinkML-skjema har legitime verdiobjekt (inlina klasser utan identitet). Falske positive stadfesta: `mixin`-klasser (og `abstract`) vert flagga sjølv om dei aldri vert instansierte. I silver bør `mixin: true`/`abstract: true` unntakast, og helst klasser som berre vert brukte inlina. |
| B17 | `class_count_limit` (maks 50) | warning | N | **Flytt til silver** | Grensa kjem frå Digdir-regel 6 og er vilkårleg. Store, legitime LinkML-skjema (t.d. Biolink) har hundrevis av klasser. |
| B18 | `no_inlined_on_primitive_range` | warning | G | **Bli** | Reint LinkML-teknisk (daud konfigurasjon). Gjeld alle. Kandidat for upstream-linter-regel. |
| B19 | `all_classes_have_concept_ref` | warning | **N** | **Flytt til silver, unnta AP-NO-profilar** | Hardkoda Felles begrepskatalog-URI (`concept-catalog.fellesdatakatalog.digdir.no`), som ingen utanfor norsk offentleg sektor kan oppfylle. **Motstrid med repoet sin eigen regel:** AP-NO-profilar *skal ikkje* ha `begrepsidentifikator`, men får 91 warnings. Står åleine for 466 av 680 policy-warnings i repoet. |
| B20 | `controlled_vocabulary_annotations` | warning | **R** | **Flytt til silver** | Repo-eigen annotasjonskonvensjon (`gyldige_verdier`, `vokabular_krav`, SKAL/BØR/KAN på norsk). Ufarleg for eksterne (no-op utan annotasjonen), men høyrer ikkje heime i ein generisk baseline. Høyrer naturleg saman med `instance_controlled_vocabulary_pattern`, som alt ligg i silver. Merk: sjekken brukar `sv.all_slots()` og rapporterer difor òg importerte slots i nedstraums-skjema. Bør avgrensast til skjemaet sine eigne slots. |
| B21 | `schema_har_erdiagram_aktivert` | warning | **R** | **Flytt ut av bronze** (til silver) | Sjekkar `build.yaml`, som er repoet sitt byggjesystem, ikkje skjemakvalitet. For eksterne brukarar er han alltid ein stille no-op. |
| B22 | `local_types_have_standard_uri` | warning | G | **Bli, rett falsk positiv** | Generisk (typar skal mappe til XSD). **Falsk positiv stadfesta:** ein lokal type med `typeof: string` og utan eigen `uri:` vert flagga, sjølv om han arvar `xsd:string`. Sjekken bør bruke induced/arva `uri` (`sv.induced_type()` eller følgje `typeof`-kjeda). |

### Implisitte steg i `validate_schema()` for bronze

| # | Steg | Tilråding |
|---|---|---|
| B23 | LinkML-linter (berre for rotpolicyen, `_is_base_policy`) | **Bli, men aktiver regelsett.** `Linter()` vert kalla utan konfig. I LinkML 1.11.1 er då **alle** lint-reglar `disabled` (`default.yaml`), og berre metamodell-validering (`validate_schema=True`) køyrer. `make lint` brukar derimot `src/assets/containers/.linkmllint.yaml` (`extends: recommended`). Bronze bør bruke `recommended` (minus `canonical_prefixes`). Då får alle generiske, upstream-vedlikehaldne reglar (`no_undeclared_slots`, `no_undeclared_ranges`, `one_identifier_per_class`, `no_invalid_slot_usage`, `standard_naming` m.fl.) utan eigen kode. `standard_naming` dekkjer attributt òg, og kan på sikt erstatte B12/B13. |
| B24 | Instansvalidering (om instans er gjeven) | **Bli.** Generisk. |
| B25 | `common_classes.must_use: []` | **Bli** (tom). |

## Oppsummering av tilrådinga

**Blir i bronze (generisk LinkML-baseline):** B1-B9, B11, B12, B13, B18, B22-B25,
nokre med forbetringar (B7, B12, B13, B22, B23), og B10 i omskriven, generisk form.

**Flyttast ut av bronze:** B14 `all_classes_have_class_uri`, B15 `all_slots_have_slot_uri`,
B16 `all_classes_have_identifier`, B17 `class_count_limit`,
B19 `all_classes_have_concept_ref`, B20 `controlled_vocabulary_annotations`,
B21 `schema_har_erdiagram_aktivert`, samt den repo-spesifikke delen av B10.

Etter endringa vil eit idiomatisk LinkML-skjema som personinfo-dømet passere
bronze utan error og med berre éin generisk warning (manglande `description`
på `Container`).

## Konsekvensar som må handterast

1. **Arv:** `felles-datakatalog` og `felles-begrepskatalog` har `extends: bronze`.
   Flyttar vi sjekkar til silver, mistar desse policyane dei. Silver inneheld òg
   AP-NO-krav (Katalog/Datasett/containerklasser) som *ikkje* skal gjelde dei.
   **Tilrådd løysing:** eit nytt mellomlag med norske/Digdir-basiskrav (arbeidsnavn
   `basis-no`) som arvar bronze. Både `silver` og `felles-*` arvar så dette
   mellomlaget. Hierarkiet vert då `bronze → basis-no → silver → gold`, og
   `felles-*` får `extends: basis-no`.
2. **Lint-steget:** `_is_base_policy()` avgjer om linteren køyrer, og han køyrer
   berre for policyar utan `extends`. Det må ikkje endrast utilsikta når
   hierarkiet får eit nytt lag.
3. **Gold-oppgradering:** `gold.yaml` redeklarerer alle bronse-warnings som
   error. Dei flytta sjekkane må framleis finnast i gold si arvekjede (via
   `basis-no`/silver), elles slår koherenstesten i `tests/test_mcp_policies.py` til.
4. **12 skjema med `validation_policy: bronze`:** `ap-no/common-ap-no`,
   `felles/brreg-felles-typer`, 6 × `modellkatalog/*`,
   `oreg/begrepssamling-foretaksregisteret`, `oreg/register-over-aksjeeiere`,
   `referanse/referansemodell-bronze`, `referanse/referansemodell`. Desse vil få
   færre warnings. Kvart av dei må vurderast: skal det bli på bronze eller gå til
   `basis-no`?
5. **Dokumentasjon:** `policies/README.md` (bronze-tabell og Digdir-dekningstabell),
   `CLAUDE.md` § Policy-hierarki, `.claude/rules/linkml-schema.md` (snake_case-avsnittet
   refererer til bronze), `mkdocs/docs/`-sider som skildrar nivåa.
6. **Relatert backlog:** `specs/backlog/konsolider-feltnaervaer-sjekk-i-checks-mekanismen.md`
   bør realiserast før eller saman med dette. B7 (attributt-description) er
   lettare å implementere når feltkrava er éin mekanisme.

## Handlingsliste (ikkje utført — for seinare realisering)

- [ ] T1: Avklar målhierarki og navn på mellomlaget (sjå opne spørsmål)
- [ ] T2: Skriv om `default_prefix_is_https_uri` til generisk ekspansjonssjekk (bronze) + repo-konvensjonssjekk (mellomlag/silver) (B10)
- [ ] T3: Erstatt hardkoda `exclude_schemas` i `slot_names_snake_case` med ein per-skjema-mekanisme, t.d. `build.yaml: naming_convention: camelCase` eller ei skjemaannotasjon (B13)
- [ ] T4: Utvid `slot_names_snake_case` og `slot.description` til attributt; stram inn `class_names_pascal_case` (B7, B12, B13)
- [ ] T5: Rett falsk positiv i `local_types_have_standard_uri` for `typeof`-typar (B22)
- [ ] T6: Aktiver `recommended`-regelsettet i validatoren sin `Linter()` (utan `canonical_prefixes`) og vurder om B12/B13 då kan fjernast (B23)
- [ ] T7: Flytt B14-B17, B19-B21 frå `bronze.yaml` til mellomlaget; oppdater `extends:` i `silver.yaml` og `felles-*.yaml`
- [ ] T8: Legg inn unntak i dei flytta sjekkane: identifikator-slots (B15), `mixin`/`abstract` (B16), AP-NO-profilar (B19), berre eigne slots (B20)
- [ ] T9: Oppdater `tests/test_mcp_policies.py` og fixtures; køyr `make mcp-linkml-valider-modell-test`
- [ ] T10: Vurder `validation_policy` for dei 12 bronze-skjemaa
- [ ] T11: Oppdater dokumentasjon (sjå Konsekvensar punkt 5)
- [ ] T12: Legg til personinfo-skjemaet som testfixture (`tests/fixtures/`), slik at bronze vert haldt generisk over tid (regresjonsvern)

## Opne spørsmål til brukaren

1. Skal vi innføre eit eige mellomlag (`basis-no` eller anna navn), eller er det
   greitt at `felles-*`-policyane mistar dei flytta sjekkane / arvar frå silver?
2. Skal B23 (aktivere linter-regelsettet) erstatte B12/B13 heilt, eller skal vi
   ha begge?
3. Skal oreg-skjemaa med camelCase frå XSD-kjelda få same unntak som FINT (T3)?

## Avgjerder

- **Empiri via batch-scriptet direkte, ikkje `make`:** `batch-flatten-and-validate.py`
  vart køyrt direkte med output til scratchpad. `make validate-capture` ville
  skrive valideringslogger inn i repoet, og målet her var ei reint lesande
  analyse (feilsøkingsunntaket i CLAUDE.md).
- **Referanseskjema for «generisk»:** LinkML sitt `personinfo`-tutorialmønster
  vart brukt som målestokk for kva ein ekstern modellerar typisk skriv. Det er
  det mest utbreidde dømet i LinkML-dokumentasjonen.
- **Flytt heller enn å slette:** alle sjekkane som vert tilrådde flytta har
  verdi i norsk offentleg kontekst. Tilrådinga er difor å flytte dei til eit
  lag over bronze, ikkje å fjerne dei.
- **`schema_has_default_prefix` (B9) blir som error:** LinkML har ein fallback,
  men eksplisitt `default_prefix` er så utbreidd praksis at kravet ikkje stengjer
  ute idiomatiske skjema.
