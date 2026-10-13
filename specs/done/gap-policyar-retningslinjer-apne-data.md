# Samanstilling av tre autoritative kjelder i policy-sjekklista (mcp-linkml-validator)

**Mål:** `src/mcp-linkml-validator/policies/README.md` skal stille saman alle tre
autoritative kjelder for valideringsreglane, slik at kvar policy-sjekk kan sporast
til ei eller fleire av dei, og slik at dekningsgraden per kjelde er synleg.

**Dei tre autoritative kjeldene:**

| Kjelde | Utgjevar | Type | Gjeld primært | Kortform i README |
|---|---|---|---|---|
| [Retningslinjer ved tilgjengeliggjøring av offentlige data](https://www.regjeringen.no/no/dokumenter/retningslinjer-ved-tilgjengeliggjoring-av-offentlige-data/id2536870/) | KMD (no DFD), 27.01.2017 | 15 tilrådde retningslinjer (politisk styringsdokument) | Data og datasettskildringar | Retningslinje 1-15 |
| [Felles modelleringsregler for offentlig forvaltning](https://www.digdir.no/informasjonsforvaltning/felles-modelleringsregler-offentlig-forvaltning/3029) | Digdir, v1.0, juni 2022 | 15 modelleringsreglar | Informasjonsmodellar | Digdir-regel 1-15 |
| [FAIR-prinsippa](https://www.go-fair.org/fair-principles/) | GO FAIR | 15 prinsipp (F1-F4, A1, A1.1, A1.2, A2, I1-I3, R1, R1.1-R1.3) | (Meta)data generelt | F1 … R1.3 |

**Dato:** 2026-10-13 (oppdatert same dag: utvida frå gap-analyse til samanstilling)
**Status:** Utført 2026-10-13 (steg 1-8). G3-G7 står opne som moglege oppfølgingsspecar.

---

## Bakgrunn

README-en byggjer i dag på to av dei tre kjeldene: Digdir-reglane (eigen
dekningsgradstabell og kolonne per sjekk) og FAIR (berre som kolonne, ingen eigen
dekningsgradstabell). Retningslinjene er ikkje nemnde i README-en. Likevel siterer
`silver.yaml`/`gold.yaml` dei, under feil navn (sjå G1).

`specs/done/avvik-retningslinjer-apne-data.md` kartla retningslinjene mot
**skjemaet** `dcat-ap-no-schema.yaml` (RÅ1-RÅ4 utførte). Denne specen gjeld
**policy-laget**: kva validatoren handhevar, og korleis det blir dokumentert.

Policyane validerer **skjemakvalitet**, ikkje instansdata (jf. README § «To typar
validering»). For retningslinjene, som primært gjeld data, betyr det at ein policy
kan sikre at skjemaet *gjer det mogleg* å uttrykkje kravet. Om dataverdien faktisk
oppfyller kravet, kan berre instanssjekkar kontrollere. Retningslinjene gjeld òg
sjølve modellen når han blir publisert som ressurs (t.d. `schema.license` →
retningslinje 1).

---

## Del A — Gap-analyse: retningslinjene mot dagens policyar

Teiknforklaring: ✅ handheva i policy · 🟡 delvis · ❌ ikkje handheva (men modellerbart) · ⚪ ikkje modellerbart / utanfor scope

| # | Retningslinje | Skjemastøtte (dcat-ap-no) | Policy-dekning i dag | Status |
|---|---|---|---|---|
| 1 | Bruk åpne standardlisenser (CC BY 4.0 / NLOD) | `lisens` med `gyldige_verdier` (RÅ1) | `schema_has_license` (bronze warning → gold), `distribusjon_lisens` (silver warning → gold), `r11_license` (gold). **Verdien blir ikkje kontrollert.** | 🟡 |
| 2 | Tilby data gratis | — | — | ⚪ |
| 3 | Ingen brukerregistrering | `tilgangsrettigheter` (RÅ4) | `datasett_tilgangsrettigheter` (silver warning → gold) | ✅ (skjemanivå) |
| 4 | Dokumenter datasettene | `dokumentasjon`, `landingsside` Anbefalt (RÅ3) | `datasett_tittel`/`_beskrivelse`/`_kontaktpunkt`/`_tema` (silver). **Ikkje `foaf:page`/`dcat:landingPage`.** | 🟡 |
| 5 | Informer om datakvalitet | DQV-AP-NO, `har_kvalitetsmerknad` | `schema_importerer_dqv_ap_no`, `container_kvalitets*` (silver/gold) | ✅ / 🟡 |
| 6 | Tilby oppdaterte data | `frekvens` Anbefalt (RÅ2), `tilgjengelighet` | `schema_has_annotation_oppdateringsfrekvens` gjeld **modellen**. **Ikkje `dct:accrualPeriodicity` på `Datasett`.** | 🟡 |
| 7 | Gjør data synlige (data.norge.no, engelsk) | — | `felles-datakatalog` dekkjer berre **modellar**. Ingen datasett-publiseringspolicy, ingen `en`-sjekk. | 🟡 |
| 8 | Maskinlesbare standardformater | `format`, `medietype` Anbefalt | `i2_standard_prefixes` gjeld modellen. **Ikkje `dct:format`/`dcat:mediaType` på `Distribusjon`.** | 🟡 |
| 9 | Tilby API | `Datatjeneste` | `datatjeneste_*` (silver), `container_datatjeneste` (gold) | ✅ |
| 10 | Tilby komplett nedlasting | `nedlastningslenke` Anbefalt (RÅ3) | `distribusjon_tilgangsurl` (silver). **Ikkje `dcat:downloadURL`.** | 🟡 |
| 11 | Faste adresser og unike identifikatorer | `identifikator_literal` Anbefalt | `schema_id_is_http_uri`, `default_prefix_*`, `all_classes_have_class_uri`/`_identifier`, `all_slots_have_slot_uri` | ✅ (skjemanivå) |
| 12 | Publiser oversikt over dataene | `Katalog`, `NON_PUBLIC` | `container_katalog`, `katalog_*` (silver) | ✅ / ⚪ |
| 13 | Tilpass data til brukernes behov | fleire `Distribusjon`-ar | — | ⚪ |
| 14 | Oppmuntre til bruk | — | — | ⚪ |
| 15 | Legg til rette for tilbakemeldinger | `kontaktpunkt` | `*_kontaktpunkt` (silver) dekkjer kanalen indirekte | ⚪ / ✅ |
| — | Merknad: taushetsplikt/personopplysningar | `tilgangsrettigheter`, `gjeldende_lovgivning` | `datasett_tilgangsrettigheter`, `datasett_lovgivning` | ✅ |

### Funn

- **G1 — Retningslinjene manglar i README, og YAML har feil kjeldetilvising.**
  `silver.yaml:80` og `gold.yaml:198` skriv «Digdir-rettleiar for åpne data,
  punkt 6». Dokumentet er frå departementet, ikkje frå Digdir.
  `mkdocs/docs/arkitektur/standardetterleving.md:42` lenkjer til ein
  digdir.no-kopi (`/2722`) i staden for regjeringen.no-sida.
- **G2 — `oppdateringsfrekvens` manglar i silver-tabellen i README.** Sjekken finst
  i `silver.yaml:75`. Teljinga «Sølv legg til 12 eigne nye `warning`-sjekkar» må
  kontrollerast på nytt.
- **G3 — Lisensverdien blir ikkje kontrollert (retningslinje 1).**
  `schema_has_license` er `schema_field_present`. Skildringa lovar «URI til ein
  open lisens», men sjekken handhevar det ikkje.
- **G4 — `Anbefalt`-slots frå RÅ2/RÅ3 har ingen policy-sjekk (retningslinje 4, 6, 8, 10):**
  `Datasett.frekvens` (`dct:accrualPeriodicity`), `Datasett.landingsside`
  (`dcat:landingPage`), `Datasett.dokumentasjon` (`foaf:page`),
  `Distribusjon.nedlastningslenke` (`dcat:downloadURL`) og
  `Distribusjon.format`/`medietype` (`dct:format`/`dcat:mediaType`).
- **G5 — Ingen publiseringspolicy for datasett (retningslinje 7).** Gapet gjeld
  validering av konformitet, ikkje push til data.norge.no (jf. PRINCIPLES.md § 1).
- **G6 — Ingen sjekk av engelske skildringar (retningslinje 7, «bør vurdere»).**
  Han har same LangString-avgrensing som SK5.
- **G7 — `dcatap:availability` (tenestenivå, retningslinje 6) blir ikkje sjekka.**

---

## Del B — Gap i samanstillinga av dei tre kjeldene

- **G8 — FAIR har ingen eigen dekningsgradstabell.** FAIR finst berre som kolonne
  per sjekk og i Digdir-tabellen. Det er difor ikkje synleg kva FAIR-prinsipp som
  er udekte (t.d. A1.1, A1.2, R1).
- **G9 — Fleire FAIR-mappingar bør verifiserast mot go-fair.org-teksten:**
  - `annotations.begrepsidentifikator` → **A2**. A2 seier at metadata skal vere
    tilgjengelege sjølv når data ikkje lenger er det. Kopling til omgrep passar
    betre med **I2** (vokabular som følgjer FAIR) eller **R1.3**.
  - `schema.version` → **F4**. F4 seier at (meta)data er registrerte/indekserte i
    ein søkbar ressurs. Det passar betre med `felles-datakatalog`-policyen.
    Versjon høyrer heller til **R1** / **R1.3**.
  - Silver-tabellen markerer `Katalogpost` `foaf:primaryTopic` som Digdir-regel 9
    (Datering), noko som truleg er feil.
- **G10 — Ingen YAML-nøkkel for retningslinjene.** `digdir_rule:` og
  `fair_principle:` finst i YAML. Ein tilsvarande nøkkel manglar for
  retningslinjene. Dermed kan ikkje README-kolonnen forankrast i YAML, og same
  type drift som Funn C i `specs/done/full-gjennomgang-policy-alvorsgrad-og-overlapp.md`
  kan oppstå.
- **G11 — Talkollisjon.** Både Digdir-reglane og retningslinjene er nummererte
  1-15. Viss nummera står utan kontekst, blir dei tvetydige.

---

## Del C — Kryssreferanse mellom kjeldene (tematisk)

Denne tabellen er utgangspunktet for den samla dekningsgradsseksjonen i README
(steg 3). Kvar rad er eit tema. «—» betyr at kjelda ikkje har eit tilsvarande punkt.

| Tema | Retningslinje | Digdir-regel | FAIR | Dagens sjekk(ar) |
|---|---|---|---|---|
| Open lisens | 1 | 7 | R1.1 | `schema_has_license`, `distribusjon_lisens`, `r11_license` |
| Gratis / ingen registrering / tilgang | 2, 3 | 7 | A1.1, A1.2 | `datasett_tilgangsrettigheter` |
| Forståeleg skildring og dokumentasjon | 4 | 1, 2 | F2, R1 | `schema.title`/`description`, slot-`description`, `datasett_tittel`/`_beskrivelse` (G4: landingsside/dokumentasjon manglar) |
| Datakvalitet | 5 | 14 (via DQV-gjenbruk) | R1 | `schema_importerer_dqv_ap_no`, `container_kvalitets*` |
| Oppdatering og datering | 6 | 9 | R1 | `schema.version`, `endringsdato`, `oppdateringsfrekvens` (G4: `Datasett.frekvens` manglar) |
| Livssyklusstatus | — | 11 | R1.3 | `schema_has_annotation_status` |
| Synlegheit i felles katalog | 7, 12 | 7 | F4 | `felles-datakatalog`, `felles-begrepskatalog`, `container_katalog` (G5) |
| Maskinlesbare standardformat | 8 | 8, 15 | I1 | linter, `local_types_have_standard_uri`, `i2_standard_prefixes` (G4: format manglar) |
| API og nedlasting | 9, 10 | — | A1 | `datatjeneste_endepunktsurl`, `distribusjon_tilgangsurl` (G4: downloadURL manglar) |
| Faste adresser og identifikatorar | 11 | 4 | F1, F3, A1 | `schema_id_is_http_uri`, `default_prefix_*`, `class_uri`/`slot_uri`, identifikator-slot |
| Ansvar, proveniens og kontakt | 15 | 10 | R1.2 | `utgiver`, `*_utgiver`, `*_kontaktpunkt`, `r12_provenance` |
| Omgrep og felles vokabular | — | 13, 14 | I2, I3 | `all_classes_have_concept_ref`, `i2_standard_prefixes`, `schema_importerer_dqv_ap_no` |
| Navngjeving, visualisering, modularitet | — | 3, 5, 6 | — | `standard_naming`, `schema_har_erdiagram_aktivert`, `class_count_limit` |
| Samanhengar mellom modellar | — | 12 | I3 | `make analyse-modell-sammenhenger` (informativ) |
| Personvern / taushetsplikt | Merknad | — | A1.2 | `datasett_lovgivning`, `datasett_tilgangsrettigheter` |
| Brukartilpassing, oppmuntring | 13, 14 | — | — | ⚪ prosess, ikkje modellerbart |
| Metadata tilgjengelege etter at data er borte | — | — | A2 | Ingen (G9). Kandidat: publisering i felles katalog |

FAIR-koplingane i denne tabellen er forslag. Dei skal verifiserast mot
go-fair.org-teksten i steg 2 før dei blir førte inn i README.

---

## Del D — Målstruktur for README

```
# Policyer for mcp-linkml-validator
  Innleiing: tre autoritative kjelder (tabell: kjelde, utgjevar, type, gjeld primært)

## Dekningsgrad per kjelde
### Retningslinjer ved tilgjengeliggjøring av offentlige data   ← NY (1-15, Del A-matrisa forkorta)
### Felles modelleringsregler (Digdir)                          ← finst, flyttast hit
### FAIR-prinsippa                                              ← NY (F1 … R1.3, inkl. udekte)
### Kryssreferanse mellom kjeldene                              ← NY (Del C)

## To typar validering                                          ← uendra
## Nivå for skjemakvalitet                                      ← + kolonne «Retningslinjer»
## Kvalitetspolicyer
### bronze / basis-no / silver / gold                           ← kolonne «Retningslinje» mellom «Digdir-regel» og «FAIR»
## Publiseringspolicyer                                         ← + merknad om manglande datasett-policy (G5)
## Skiljet mellom skjema- og datavalidering                     ← uendra
## MCP-verktøy                                                  ← uendra
```

Kolonnerekkjefølgja i sjekktabellane blir `Digdir-regel | Retningslinje | FAIR`.
Lenkjeformat for retningslinjer: `[6 — Oppdaterte data](https://www.regjeringen.no/no/dokumenter/retningslinjer-ved-tilgjengeliggjoring-av-offentlige-data/id2536870/)`.
Regjeringen.no-sida har ingen stabile ankre per punkt, så lenkja går til sida.

---

## Steg

1. **YAML-nøkkel for retningslinjene (G10).** Innfør `retningslinje:` (heiltal
   eller liste) på alle sjekkar i `bronze.yaml`, `basis-no.yaml`, `silver.yaml`,
   `gold.yaml`, `felles-datakatalog.yaml` og `felles-begrepskatalog.yaml` der
   Del C gir ei kopling. Nøkkelen er rein metadata, på same måte som `digdir_rule`,
   og `server.py` treng ingen endring. Kontroller at `_merge_policies` ikkje
   avviser ukjende nøklar.
2. **Verifiser FAIR-mappingar (G9).** Hent go-fair.org-teksten, gå gjennom alle
   `fair_principle:`-verdiar og README-kolonnene, og rett A2/F4/R1-koplingane
   som er nemnde i G9. Dette gjeld òg Digdir-regel 9 på
   `katalogpost_primaertema`. Logg kvar endring i `## Avgjerder`.
3. **README: ny innleiing og dekningsgradsseksjon (G1, G8, G11).** Skriv om
   innleiinga etter Del D, legg til retningslinje-tabellen og FAIR-tabellen, og flytt
   den eksisterande Digdir-tabellen inn under same overskrift. Legg til
   kryssreferansen frå Del C.
4. **README: kolonne «Retningslinje» i alle sjekktabellar og nivåtabellen.**
   Verdiane skal hentast frå `retningslinje:` i YAML (steg 1), ikkje skrivast
   inn på fritt grunnlag.
5. **README: rett G2.** Legg `oppdateringsfrekvens` inn i silver-tabellen og
   kontroller teljinga av warning-sjekkar.
6. **Rett kjeldetilvisinga i YAML (G1).** Erstatt «Digdir-rettleiar for åpne data»
   i `silver.yaml`/`gold.yaml` med «Retningslinjer ved tilgjengeliggjøring av
   offentlige data, retningslinje 6» og lenkja. Rett lenkja i
   `mkdocs/docs/arkitektur/standardetterleving.md` (+ `.en.md`) til regjeringen.no.
7. **Koherenstest (valfri, sjå avgjerd).** Utvid `TestPolicyKoherens` i
   `tests/test_mcp_policies.py` med ein test som sjekkar at kvar
   `retningslinje:`-verdi er i 1-15. Viss det let seg gjere, bør han òg sjekke at
   kvar retningslinje som er merkt ✅/🟡 i README, har minst éin sjekk med nøkkelen.
8. **Engelsk versjon og portal.** Oppdater `policies/README.en.md` tilsvarande,
   køyr `make translate-status`/`make translate-stamp` etter
   `.claude/rules/i18n-omsetjing.md` og `make docs-publish`. Kontroller at
   `mkdocs/docs/arkitektur/valideringsregler.md` blir regenerert, og køyr
   lenkjesjekk.

**Utanfor denne specen (eigne specar ved behov):** nye sjekkar frå G3 (verdisjekk
for open lisens), G4 (fem `class_has_slot_with_uri`-sjekkar), G5
(`felles-datasettkatalog`), G6 (`en`-skildring) og G7 (`dcatap:availability`).
Desse endrar valideringsresultat for eksisterande skjema. Samanstillinga skal
i staden gjere gapa *synlege* som 🟡/❌ i dekningsgradstabellane.

---

## Handlingsliste

- [x] Hent og les retningslinjene (regjeringen.no/id2536870)
- [x] Les `policies/README.md` og policyfilene
- [x] Les førre kartlegging og `standardetterleving.md` for å unngå duplisering
- [x] Del A: gap-analyse retningslinjer → policy (G1-G7)
- [x] Del B: gap i samanstillinga (G8-G11)
- [x] Del C: tematisk kryssreferanse mellom kjeldene
- [x] Del D: målstruktur for README
- [x] Steg 1: `retningslinje:`-nøkkel i policy-YAML
- [x] Steg 2: verifiser FAIR-mappingar
- [x] Steg 3: ny innleiing og dekningsgradsseksjon i README
- [x] Steg 4: kolonne «Retningslinje» i sjekktabellane
- [x] Steg 5: `oppdateringsfrekvens` i silver-tabellen
- [x] Steg 6: rett kjeldetilvising i YAML og standardetterleving.md
- [x] Steg 7: koherenstest (valfri)
- [x] Steg 8: README.en.md, translate-stamp, docs-publish

---

## Avgjerder

- **Policy-laget, ikkje skjemaet.** `dcat-ap-no-schema.yaml` er alt evaluert i
  `specs/done/avvik-retningslinjer-apne-data.md`. Denne specen gjeld berre korleis
  validatoren handhevar og dokumenterer kjeldene.
- **Skjemanivå reknast som full dekning.** Policyane validerer per design skjema,
  ikkje data. Ei retningslinje er ✅ når skjemaet kan uttrykkje kravet og policyen
  sjekkar det.
- **Kjelde for retningslinjeteksten.** Regjeringen.no-sida vart henta med WebFetch
  og samanfatta, ikkje sitert ordrett.
- **Utvida same spec i staden for ny.** Samanstillinga byggjer direkte på
  gap-analysen (Del A), så brukaren sin oppfølgingsinstruks er lagd inn her.
  Filnavnet er behalde for å unngå unødig omdøyping. Tittelen speglar no det
  breiare målet.
- **YAML-nøkkel som sannkjelde (steg 1) framfor handskrivne README-kolonner.**
  Det følgjer lærdommen frå Funn C i
  `specs/done/full-gjennomgang-policy-alvorsgrad-og-overlapp.md`: handskrivne
  kolonner glir frå YAML over tid.
- **Talkollisjonen (G11) blir løyst med kolonneoverskrift og prosaform.** I
  tabellar skil kolonna («Digdir-regel» / «Retningslinje»). I prosa skriv ein
  «Digdir-regel 4» og «retningslinje 6». Nye prefiks som «MR»/«RL» er valt bort,
  fordi dei ville krevje omskriving av eksisterande Digdir-referansar.
- **Nye sjekkar (G3-G7) er haldne utanfor.** Instruksen gjaldt samanstilling i
  sjekklista. Nye sjekkar endrar valideringsåtferd og bør avgjerast kvar for seg.
- **Koherenstesten (steg 7) er markert valfri.** Han hindrar drift, men er ikkje
  naudsynt for sjølve samanstillinga.
- **Retningslinje-koplingane er konservative.** `retningslinje:` er berre sett der
  sjekken direkte gjer det mogleg å uttrykkje kravet (t.d. ikkje på `class_count_limit`,
  `standard_naming`, `aktor_navn`, `r12_provenance`). `datasett_lovgivning` har ingen
  talverdi, fordi han svarar til merknaden om taushetsplikt og ikkje til ei nummerert
  retningslinje. README-en viser merknaden i kolonna.
- **Rader utan YAML-sjekk har manuelle verdiar.** Rader som `schema.title`/`description`/`version`
  (via `required:`/`recommended:`), linter-radene og instanssjekkane har ingen `checks:`-oppføring.
  Retningslinje-verdien er difor sett manuelt i README for desse.
- **FAIR-rettingar (steg 2) gjekk litt lenger enn G9.** I tillegg til A2→I2
  (`all_classes_have_concept_ref`), F4→R1 (`schema.version`) og `katalogpost_primaertema`
  (Digdir 9 fjerna, FAIR F3) vart dei generelle `1, 2, 10`/`F2, R1.2`-verdiane på
  AP-NO-klassekrava differensierte: tittel/beskrivelse/tema → Digdir 1, 2 / F2;
  kontaktpunkt → Digdir 10 / F2; utgiver → Digdir 10 / R1.2; `datatjeneste_endepunktsurl` → A1
  utan Digdir-regel. `schema_id_is_http_uri` fekk A1, `datasett_tilgangsrettigheter` A1.2,
  `gold.all_classes_have_class_uri` F3, I1 (lik basis-no). Publiseringspolicyane fekk F4 på
  containerkrava og R1.1 på lisenskrava. Grunngjeving: FAIR-teksten
  (gofair.foundation, vidaresendt frå go-fair.org) — dei gamle verdiane var sette blokkvis.
- **Ingen nye kolonner i publiseringstabellane.** `felles-datakatalog`/`felles-begrepskatalog`
  har kolonna «Kjelde» som peikar til AP-NO-spesifikasjonen. Kjeldemetadataen er lagd i YAML,
  og dekninga går fram av dekningsgradstabellane.
- **Talet «12 warning-sjekkar» i sølv var rett.** Berre rada for `oppdateringsfrekvens`
  mangla i tabellen.
- **Lenkje til specen utan hyperlenkje.** `publish.sh` skriv berre om `specs/done/`-stiar,
  og specen skal ligge der. README-en nemner difor `specs/done/…` som kode, som andre stader.
- **Utover planen:** `mkdocs/docs/kom-i-gang/ny-domenemodell{,.en}.md` hadde same feiltilskriving
  («Digdirs rettleiar for åpne data») og vart retta. CLAUDE.md § «Policy-hierarki» nemner no
  alle tre kjeldene. Ein utdatert sti i README (`specs/backlog/utvid-dekningsgrad-…` → `specs/done/`)
  vart retta.
- **`make docs-publish` utan førehandssjekk.** `.claude/rules/mkdocs-portal.md` krev at ein sjekkar
  `generated/` før køyring. Det vart ikkje gjort. Køyringa feila for 34 domeneskjema (utdatert
  lokal `generated/`) og sletta/endra 59 versjonskontrollerte filer under `mkdocs/docs/felles/`.
  Desse vart rulla tilbake med `git restore mkdocs/docs/felles/` (steg 3 i rula). Ingen var
  brukaren sine. `valideringsregler.md` vart generert korrekt før feilen.

---

## Utført

- **Steg 1:** `retningslinje:` lagt til i alle seks policyfilene (63 sjekk-oppdateringar).
- **Steg 2:** FAIR-/Digdir-koplingar retta (sjå avgjerder). `gold.yaml`-kommentaren om F4 retta.
- **Steg 3-5:** `policies/README.md` har ny innleiing med kjeldetabell, seksjonen «Dekningsgrad per
  kjelde» (retningslinjer, Digdir, FAIR, kryssreferanse), kolonna «Retningslinje» i alle
  kvalitetstabellar og i nivåtabellen, og `oppdateringsfrekvens`-rada i sølv. Kjeldekolonnene i
  sjekktabellane er genererte frå YAML.
- **Steg 6:** «Digdir-rettleiar for åpne data» retta i `silver.yaml`/`gold.yaml`. Lenkja i
  `standardetterleving{,.en}.md` peikar no til regjeringen.no.
- **Steg 7:** to nye testar i `TestPolicyKoherens`: `retningslinje` er heiltal 1-15, og
  kjeldemetadata i gull samsvarar med arva sjekkar. `make mcp-linkml-valider-modell-test`: 69 testar OK.
- **Steg 8:** `policies/README.en.md`, `standardetterleving.en.md` og `ny-domenemodell.en.md`
  oppdaterte og stempla. `make translate-status`: 0 utdaterte. `make docs-publish` genererte
  `valideringsregler.md` med ny struktur (sjå avgjerd om feil i andre skjema). Lenkjesjekk
  (lychee) finst berre i CI og er ikkje køyrd lokalt.
- **Opne etter dette:** G3 (verdisjekk for open lisens), G4 (fem `class_has_slot_with_uri`-sjekkar),
  G5 (`felles-datasettkatalog`), G6 (`en`-skildring), G7 (`dcatap:availability`).
