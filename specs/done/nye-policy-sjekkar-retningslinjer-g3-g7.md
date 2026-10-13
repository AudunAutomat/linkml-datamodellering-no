# Nye policy-sjekkar for opne gap mot retningslinjene (G3-G7)

**Opphav:** `specs/done/gap-policyar-retningslinjer-apne-data.md`, funn G3-G7 (haldne utanfor samanstillinga fordi dei endrar valideringsåtferd)
**Kjelde:** [Retningslinjer ved tilgjengeliggjøring av offentlige data](https://www.regjeringen.no/no/dokumenter/retningslinjer-ved-tilgjengeliggjoring-av-offentlige-data/id2536870/)
**Dato:** 2026-10-13
**Status:** Utført 2026-10-13 etter tilrådingane (G3 og G4 gjennomførte, G5-G7 ikkje).

---

## Bakgrunn

Etter samanstillinga står fem retningslinjer som 🟡 i dekningsgradstabellen i
`src/mcp-linkml-validator/policies/README.md`. Specen gjer kvart gap om til eit
konkret tiltak, kartlegg kva eksisterande skjema som blir råka, og tilrår om
tiltaket bør gjennomførast.

### Kartlagt omfang (2026-10-13)

- **Lisensverdiar:** alle 47 skjema under `src/linkml/` har
  `license: https://data.norge.no/nlod/no/2.0`. Ingen manglar `license`.
- **Lokale `Datasett`/`Distribusjon`-klassar:** `class_has_slot_with_uri` slår berre
  til når skjemaet sjølv definerer klassen (`own_class_names`). Det gjeld tre skjema:

  | Skjema | Policy | `accrualPeriodicity` | `landingPage` | `foaf:page` | `downloadURL` | `format`/`mediaType` | `availability` |
  |---|---|---|---|---|---|---|---|
  | `ap-no/dcat-ap-no` | gold | ✓ | ✓ | ✓ | ✓ | ✓ (via `common-ap-no`) | ✓ |
  | `referanse/referansemodell-silver` | silver | — | — | — | — | — | — |
  | `referanse/referansemodell-gold` | gold | — | — | — | — | — | — |

- **Tilgjengelege sjekktypar i `server.py`:** `class_has_slot_with_uri` (éin URI),
  `merged_class_has_any_slot_with_uri` (minst éin av fleire URI-ar),
  `schema_has_annotation` (støttar `value_pattern`/`allowed_values`) og
  `schema_field_present` (berre at feltet finst, **ingen** verdikontroll).
- **Instansnivå for lisens:** `lisens`-sloten i `common-ap-no` har
  `gyldige_verdier: …/authority/licence/` og `vokabular_krav: skal`.
  `instance_controlled_vocabulary_pattern` kontrollerer difor at verdien høyrer til
  EU Licence-vokabularet, men ikkje at lisensen er open.

---

## G3 — Kontroller at `schema.license` er ein open lisens (retningslinje 1)

**Gap:** `schema_has_license` sjekkar berre at feltet finst. Skildringa i
`bronze.yaml` lovar «URI til ein open lisens».

**Tiltak:**
1. Utvid `_check_schema_field_present` i `server.py` med valfrie `value_pattern`
   og `allowed_values`, på same måte som `_check_schema_has_annotation`. Då kan
   sjekkar på eksisterande felt òg kontrollere verdien, utan ein ny sjekktype.
2. Ny sjekk `schema_license_is_open` i `basis-no.yaml` (warning). Han høyrer til
   basis-no, ikkje bronze, fordi NLOD er norsk. Bronze skal vere ein generisk baseline.

   ```yaml
   schema_license_is_open:
     severity: warning
     description: >
       schema.license bør vere ein open lisens (NLOD 2.0, CC BY 4.0 eller CC0 1.0),
       jf. retningslinje 1 i Retningslinjer ved tilgjengeliggjøring av offentlige data.
     check: schema_field_present
     field: license
     value_pattern: "^(https://data\\.norge\\.no/nlod/(no|en)/2\\.0/?|https?://creativecommons\\.org/(licenses/by/4\\.0|publicdomain/zero/1\\.0)/?|http://publications\\.europa\\.eu/resource/authority/licence/(NLOD_2_0|CC_BY_4_0|CC0))$"
     digdir_rule: 7
     retningslinje: 1
     fair_principle: R1.1
   ```
3. Oppgrader til `error` i `gold.yaml`. Det er påkravd av `TestPolicyKoherens`.
4. Testar i `tests/test_mcp_policies.py`: NLOD og CC BY gir ingen funn, ein
   proprietær URI gir warning på basis-no og error på gold, og bronze er upåverka.
5. Oppdater README (basis-no- og gold-tabellen, retningslinje 1 → ✅, teljingar).

**Konsekvens:** 0 nye funn i dagens skjema (alle brukar NLOD 2.0).
**Tilråding:** Gjennomfør. Tiltaket kostar lite og fangar ein reell svakheit.

---

## G4 — Sjekk av `Anbefalt`-slots på `Datasett`/`Distribusjon` (retningslinje 4, 6, 8, 10)

**Gap:** Desse slotane er `Anbefalt` i `dcat-ap-no-schema.yaml` (RÅ2/RÅ3), men
ingen policy fangar opp eit skjema som droppar dei.

**Tiltak:** Fem nye sjekkar i `silver.yaml` (warning) under dei eksisterande
seksjonane for `Datasett`/`Distribusjon`:

| Sjekk | Type | Klasse | URI(-ar) | Retningslinje | Digdir | FAIR |
|---|---|---|---|---|---|---|
| `datasett_frekvens` | `class_has_slot_with_uri` | `Datasett` | `dct:accrualPeriodicity` | 6 | 9 | R1 |
| `datasett_landingsside` | `class_has_slot_with_uri` | `Datasett` | `dcat:landingPage` | 4 | 1 | F2 |
| `datasett_dokumentasjon` | `class_has_slot_with_uri` | `Datasett` | `foaf:page` | 4 | 1 | R1 |
| `distribusjon_nedlastningslenke` | `class_has_slot_with_uri` | `Distribusjon` | `dcat:downloadURL` | 10 | — | A1 |
| `distribusjon_format` | `merged_class_has_any_slot_with_uri` | `Distribusjon` | `dct:format`, `dcat:mediaType` | 8 | 8 | I1 |

`distribusjon_format` brukar «minst éin av», fordi DCAT-AP-NO godtek både format
og medietype.

**Gull:** Skal alle fem oppgraderast til `error`? `TestPolicyKoherens` krev det,
med mindre dei blir lagde i `_TILSIKTA_UNNTAK` med grunngjeving. Desse slotane er
`Anbefalt` og ikkje `Obligatorisk` i DCAT-AP-NO, så det er ein reell avveging
(sjå avklaring A1).

**Følgjeendringar:**
- `referansemodell-silver` og `referansemodell-gold` manglar alle fem. Legg til
  slotane i begge, slik at referansemodellane framleis viser eit reint resultat på
  sitt nivå. Køyr `make lint`, `make roundtrip` og
  `make mcp-linkml-valider-modell` mot begge.
- Kontroller testfixturane i `tests/test_mcp_policies.py` (t.d.
  `test_gyldig_skjema_har_ingen_feil` i `TestSilver`). Nye warnings kan bryte
  testar som krev null funn.
- README: nye rader i silver- og gold-tabellen, retningslinje 4/6/8/10 i
  dekningsgradstabellen, teljinga «Sølv legg til 12 …».

**Konsekvens:** 5 nye warnings i `referansemodell-silver` og 5 nye errors i
`referansemodell-gold` før følgjeendringane. `dcat-ap-no` er upåverka.
**Tilråding:** Gjennomfør. Det er lite arbeid, og mønsteret finst alt (`distribusjon_lisens`).

---

## G5 — Publiseringspolicy for datasett (retningslinje 7)

**Gap:** `felles-datakatalog` dekkjer berre modellar (ModelDCAT-AP-NO). Det finst
ingen tilsvarande `felles-datasettkatalog` for DCAT-AP-NO.

**Vurdering:**
- Ingen skjema i repoet publiserer datasettskildringar. `publish_external: true`
  blir i dag berre brukt for begreps- og modellkatalogar.
- DCAT-AP-NO-krava ligg alt i `silver.yaml` (`katalog_*`, `datasett_*`,
  `distribusjon_*`, `datatjeneste_*`). Ein ny policy som `extends: basis-no` må
  deklarere dei på nytt. Det gir tre kopiar (silver, gold, ny policy) og bryt
  DRY-terskelen i CLAUDE.md.
- Eit alternativ er å flytte DCAT-krava ut av silver til ein eigen policy og la
  silver arve frå han. Det krev fleirforeldre-`extends`, som `_merge_policies`
  ikkje støttar i dag.

**Tilråding:** Ikkje gjennomfør no. Tiltaket er spekulativt så lenge ingen
datasettkatalog finst i repoet. Dokumenter i README (§ Publiseringspolicyer) at
DCAT-AP-NO-konformitet i dag blir validert av `silver`. Ta saka opp att når den
første datasettkatalogen kjem, og vurder då fleirforeldre-`extends` som eigen spec.

---

## G6 — Engelske skildringar (retningslinje 7)

**Gap:** Retningslinja seier at verksemda «bør vurdere å tilby beskrivelser på
engelsk». Ingen policy kontrollerer dette. `ny-domenemodell.md` tilrår
`annotations.title_en`/`description_en` som valfri konvensjon.

**Tiltak (alternativ):**
- **(a) Skjemanivå, `info`:** ny sjekk `schema_has_annotation_title_en` i
  `basis-no.yaml` med `severity: info`. Han blir unnateken frå gull-oppgradering
  via `_TILSIKTA_UNNTAK` og grunngjeven, sidan retningslinja berre seier «bør
  vurdere». Ein må kontrollere at `info` blir handtert i rapportering og
  sortering for `checks:` (i dag kjem `info` berre frå linter og instansvalidering,
  jf. `server.py:40`).
- **(b) Instansnivå:** utvid `instance_begrep_definisjon_language_coverage`-mønsteret
  med `en`. Same LangString-avgrensing som SK5 (`specs/bugs/langstring-rdflib-roundtrip.md`)
  gjeld.
- **(c) Berre dokumentasjon:** behald dagens tilråding i `ny-domenemodell.md` og
  merk retningslinje 7 som ⚪/🟡 med forklaring.

**Tilråding:** (c) no, eventuelt (a) seinare. Retningslinja seier «bør vurdere»,
og ein ny sjekk ville gi `info` på alle 47 skjema utan at nokon har bede om
engelske skjemaskildringar.

---

## G7 — Tenestenivå / `dcatap:availability` (retningslinje 6)

**Gap:** Ingen sjekk av `dcatap:availability` (`tilgjengelighet`) på `Distribusjon`.

**Tiltak:** ny sjekk `distribusjon_tilgjengelighet` (`class_has_slot_with_uri`,
`dcatap:availability`, warning i silver), med retningslinje 6, ingen Digdir-regel
og FAIR A1.

**Vurdering:** `tilgjengelighet` er valfri i DCAT-AP-NO, og retningslinja om
«passende tjenestenivå» er vag. Med gull-oppgradering blir ein valfri DCAT-eigenskap
eit krav.

**Tilråding:** Gjennomfør berre saman med G4, og berre om A1 blir avgjort slik at
`Anbefalt`/valfrie slots ikkje blir oppgraderte til error i gull. Elles: ikkje
gjennomfør.

---

## Avklaringar før utføring

- **A1 — Gull-oppgradering for G4/G7:** Skal sjekkar for `Anbefalt`-slots bli
  `error` i gull (dagens prinsipp: «alle brot gir feil»), eller skal dei inn i
  `_TILSIKTA_UNNTAK` og bli verande `warning`?
- **A2 — Lisensliste i G3:** Er NLOD 2.0, CC BY 4.0 og CC0 1.0 (pluss EU-ekvivalentane)
  rett avgrensing? Eller skal t.d. CC BY-SA 4.0 og NLOD 1.0 òg godtakast?
- **A3 — G5 og G6:** Godtek du tilrådinga om å ikkje innføre nye sjekkar no?

---

## Steg

1. Avklar A1-A3 med brukaren.
2. **G3:** utvid `_check_schema_field_present`, legg til `schema_license_is_open`
   (basis-no warning, gold error), testar.
3. **G4:** fem nye sjekkar i `silver.yaml`, gull-handtering etter A1, testar.
4. **G4-følgjeendringar:** legg til slotane i `referansemodell-silver`/`-gold`,
   køyr `make lint`, `make roundtrip` og `make mcp-linkml-valider-modell` for begge.
5. **G7** (berre om A1 tillèt det): `distribusjon_tilgjengelighet`.
6. **G5/G6:** dokumentasjonsmerknad i README etter tilrådinga (eller tiltak etter A3).
7. **README og README.en:** nye rader, dekningsgradstabellar (retningslinje
   1/4/6/8/10 → ✅), nivåtabell, teljingar. `make translate-stamp`.
8. `make mcp-linkml-valider-modell-test` og `make mcp-linkml-valider-modell` mot
   alle silver/gold-skjema. Rapporter nye funn.

---

## Handlingsliste

- [x] A1-A3 avklarte
- [x] G3: verdikontroll for open lisens
- [x] G4: fem nye silver-sjekkar
- [x] G4: referansemodell-silver/-gold oppdaterte
- [x] G7: ikkje gjennomført (vilkåret i A1 ikkje oppfylt)
- [x] G5/G6: dokumentert i README
- [x] README/README.en oppdaterte og stempla
- [x] Testar og validering mot alle silver/gold-skjema

---

## Avgjerder

- **Éin spec for G3-G7.** Gapa har same opphav og same følgjeendringar (README,
  koherenstest, gull-oppgradering). Ein samla spec gjer det lettare å sjå dei
  samla konsekvensane. Tiltaka kan likevel utførast kvar for seg.
- **G3 utvidar ein eksisterande sjekktype i staden for å lage ein ny.**
  `schema_has_annotation` har alt `value_pattern`/`allowed_values`. Same parameter
  på `schema_field_present` held talet på sjekktypar nede.
- **G3 på basis-no, ikkje bronze.** NLOD er eit norsk krav, og bronze skal vere
  generisk (`specs/done/gjennomgang-bronze-policy-generisk.md`).
- **G5 og G6 er tilrådde utsette.** Begge ville vere spekulative eller gi støy
  utan ein konkret brukar i repoet (jf. CLAUDE.md om minimale endringar).
- **A1 → gull-oppgradering beheld (error i gull).** Brukaren bad om å følgje
  tilrådingane, men A1 hadde inga tilråding. Dagens dokumenterte prinsipp i gull
  («alle brot gir feil», handheva av `TestPolicyKoherens`) vart difor følgt. G4-sjekkane
  er `error` i gull. Konsekvensen er at G7 ikkje vart gjennomført, jf. vilkåret i G7.
- **A2 → foreslått lisensliste.** NLOD 2.0 (no/en), CC BY 4.0 og CC0 1.0, som
  data.norge.no-/creativecommons.org-URI eller EU Licence-URI (`NLOD_2_0`, `CC_BY_4_0`, `CC0`).
- **A3 → G5/G6 utsette (tilrådinga).** Begge er dokumenterte i README: retningslinje 7-rada
  forklarar kvifor, og § Publiseringspolicyer har ein merknad om datasettkatalog.
- **`skip_if_missing` i `schema_field_present`.** Utan han ville eit manglande
  `schema.license` bli rapportert av både `schema_has_license` og `schema_license_is_open`.
  Det er same type dobbelrapportering som vart fjerna i
  `specs/done/full-gjennomgang-policy-alvorsgrad-og-overlapp.md` (B1/B2).
- **`distribusjon_format` brukar `merged_class_has_any_slot_with_uri`.** Denne sjekktypen
  slår til for importerte klassar òg (`sv.get_class`), ikkje berre lokale som
  `class_has_slot_with_uri`. Silver-skjema som importerer `dcat-ap-no` består likevel, fordi
  `Distribusjon` der har både `format` og `medietype`.
- **Slotdefinisjonar i referansemodellane på bokmål** (modelleringsspråket), utan
  `gyldige_verdier`-annotasjonar. Slike annotasjonar ville utløyse
  `controlled_vocabulary_annotations` og krevje SKAL/BØR-formulering. Det er ikkje naudsynt
  for å vise minstekrava.
- **Ingen `make docs-publish`.** `valideringsregler.md` er ikkje versjonskontrollert og blir
  generert i CI. Ei lokal køyring med utdatert `generated/` overskriv sporte filer
  (jf. `.claude/rules/mkdocs-portal.md`).

---

## Utført

- **G3:** `_check_schema_field_present` (`server.py`) støttar no `value_pattern`,
  `allowed_values` og `skip_if_missing`. Ny sjekk `schema_license_is_open`: warning i
  `basis-no.yaml`, error i `gold.yaml`. Tre testar i `TestBasisNo`: open lisens gir ingen
  funn; lukka lisens gir warning i basis-no, error i gull og ingen funn i bronze; ingen
  dobbelrapportering ved manglande lisens.
- **G4:** fem nye sjekkar i `silver.yaml` (warning) og `gold.yaml` (error):
  `datasett_frekvens`, `datasett_landingsside`, `datasett_dokumentasjon`,
  `distribusjon_nedlastningslenke` og `distribusjon_format`. `_GOLD_PASS`-fixturen er utvida.
  To testar i `TestGold`: kvar manglande slot gir warning i sølv og error i gull, og
  `dct:format` er nok i staden for `dcat:mediaType`.
- **Referansemodellar:** `referansemodell-silver`/`-gold` har fått `frekvens`,
  `landingsside`, `dokumentasjon` (Datasett) og `nedlastningslenke`, `medietype`
  (Distribusjon), alle `Anbefalt`. `make lint` og `make roundtrip` er OK.
  `make mcp-linkml-valider-modell`: 0 feil og 0 åtvaringar for begge.
- **`dcat-ap-no` (gold):** 2 feil (`oppdateringsfrekvens`-annotasjon, `fair_r11`), begge
  frå før (finst i den versjonskontrollerte 2.14.1-loggen). Ingen nye funn frå G3/G4.
  Valideringsloggane som vart skrivne til `src/linkml/**/validation/` under kontrollen,
  er sletta igjen (CI genererer dei).
- **README/README.en:** nye rader i basis-no-, silver- og gold-tabellane. Retningslinje
  1/4/8/10 er no ✅, 6/7 er 🟡 med grunngjeving. FAIR-tabellen har dei nye sjekkane.
  Teljingar er oppdaterte (basis-no 8, sølv 17). Merknad om datasettkatalog under
  § Publiseringspolicyer. `make translate-stamp` er køyrd, og `make translate-status` viser 0 utdaterte.
- **Testar:** `make mcp-linkml-valider-modell-test`: 74 testar OK.
