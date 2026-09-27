# Plan: fleirspråkleg dokumentasjonsportal (nynorsk + engelsk)

## Bakgrunn

Brukaren ønskjer støtte for fleire språk (localization) i dokumentasjonsportalen
(`mkdocs/`). Det gjeld all portaltekst, både statisk tekst og tekst som vert
generert frå andre kjelder. Specen kartlegg kva mkdocs-økosystemet kan tilby, og
kjem med eit forslag til arkitektur og ei trinnvis gjennomføring.

**Avgrensing (avklart med brukaren):**

- **Språk:** nynorsk (standard, som i dag) + engelsk (alternativ versjon under `/en/`).
- **Omfang:** berre *portaltekst*: statiske sider, nav-meny, overskrifter/etikettar
  som `publish.sh`, `mkdocs/lib/sections/*.sh`, Python-scripta og Jinja-malane
  genererer, og tema-/UI-tekst. **Modellinnhaldet** frå skjemaa (title/description
  på skjema, klasser, slots og enums) vert vist på originalspråket (bokmål) i
  begge språkversjonane og er ikkje med i denne specen.

## Kartlegging: tekstkjelder i portalen i dag

Portalen har fleire språk blanda allereie i dag: nynorsk prosa, bokmål i
modellmetadata og engelske overskrifter frå gen-doc («Classes», «Slots»,
«Description», «Entity-relationship diagram»).

| # | Kjelde | Døme | Type |
|---|---|---|---|
| K1 | Statiske sider i `mkdocs/docs/` (19 sider i `kom-i-gang/`, `arkitektur/`, `publisering/`, `automasjon/`, `om.md`) | `kom-i-gang/ny-domenemodell.md` | Handskriven prosa |
| K2 | `README.md` → `mkdocs/docs/index.md` (`write_index_from_readme` i `publish.sh`) | Framsida | Kopiert frå anna kjelde |
| K3 | `src/mcp-linkml-validator/policies/README.md` → `arkitektur/valideringsregler.md` | Valideringsreglar | Kopiert frå anna kjelde |
| K4 | `src/linkml/<domain>/description.md` → domeneside (`sections/domene_beskrivelse.sh`) | Domeneskildring | Kopiert frå anna kjelde |
| K5 | Heredoc i `publish.sh` Steg 3: `site_name`, `site_description`, `copyright`, statisk `nav` («Rettleiingar», «Kom i gang» ...) | `- Kom i gang:` | Konfig-streng |
| K6 | `mkdocs/lib/sections/*.sh` (17 script) | `## Kom i gang`, `## Versjonslog`, `\| Artefakt \| Fil \|`, `**Kontakt:**` | Generert overskrift/etikett |
| K7 | Jinja-malar i `src/assets/templates/docgen/*.jinja2` (via `gen-doc`) | `## Modellmetadata`, `### Classes`, `\| Class \| Description \|` | Generert overskrift/etikett |
| K8 | `mkdocs/lib/scripts/generate-validation-md.py`, `generate-modellanalyse-md.py` | Forklarande blockquote-tekst per analyse | Generert tekst |
| K9 | Material-temaet sine UI-strengar (søk, «Til toppen», «Kopier» ...) | styrt av `theme.language` | Tema |
| K10 | `mkdocs/overrides/404.html`, `javascripts/*.js` | 404-tekst | Statisk |
| K11 | `CHANGELOG.md` per skjema, valideringsmeldingar frå MCP-validatoren (`validation/*.json`) | «Versjonslog»-innhald | Generert av andre verktøy |

**Funn undervegs:** `theme.language` er sett til `nb`, men portalen er skriven på
nynorsk. Material støttar `nn`. Dette bør rettast uavhengig av resten (sjå steg 1).

## Kva mkdocs kan gi oss

### Alternativ A: `mkdocs-static-i18n`-plugin

- Éin mkdocs-konfig, éin `docs_dir`. Omsetjingar ligg anten som suffiks
  (`side.en.md` ved sida av `side.md`) eller i mapper (`docs/nn/`, `docs/en/`).
- Byggjer `/` (standardspråk) og `/en/` i same køyring, med språkveljar i
  Material, nav-omsetjing per språk, eigen søkjeindeks per språk og
  **fallback til standardspråket** for sider som ikkje er omsette.
- MIT-lisens, mykje brukt (OWASP, Privacy Guides, AWS Copilot).
- **Risiko:** prosjektet er erklært **frose** («Due to the core MkDocs upstream
  being unmaintained and uncertain this project is frozen as-is»), sjå
  [issue #342](https://github.com/ultrabug/mkdocs-static-i18n/issues/342).
  Zensical listar pluginen under «planned compatibility», men utan tidsplan.
- Krev ny avhengigheit i `Dockerfile.mkdocs` (attribution-sjekk i `om.md`).

### Alternativ B: separate bygg per språk + Material `extra.alternate` (tilrådd)

- `publish.sh` byggjer to docs-tre (nynorsk og engelsk) og køyrer `mkdocs build`
  to gonger med kvar sin konfig (engelsk konfig kan arve felles oppsett via
  `INHERIT:`). Resultatet vert samla som `site/` og `site/en/`.
- Språkveljaren kjem frå Material sin innebygde `extra.alternate`
  (`name`/`link`/`lang`). Kvar språkversjon får eigen `theme.language`
  (`nn`/`en`), og dermed omsette UI-strengar (K9) og eigen søkjeindeks.
- **Ingen ny plugin-avhengigheit**, og både `theme.language` og `extra.alternate`
  er dokumentert støtta i Zensical, som er etterfølgjaren til Material for MkDocs.
  Material får kritisk vedlikehald fram til **5. mai 2027**, og Zensical 0.1.0
  startar ei stabil releaselinje **5. november 2026**
  ([zensical.org/upcoming-changes](https://zensical.org/upcoming-changes/)).
- Ulemper: ingen innebygd fallback. `publish.sh` må sjølv kopiere den nynorske
  sida med ein «not yet translated»-merknad når ei engelsk side manglar.
  `mkdocs build` køyrer to gonger. Artefakter (`*.ttl`, `*.json` ...) må anten
  kopierast til begge tre eller lenkjast frå `/en/` til den nynorske stien.

### Alternativ C: gettext/PO-baserte verktøy (t.d. `mdpo`)

- Omset Markdown via `.po`-filer, som passar for omsetjingsverktøy som Weblate
  eller Crowdin. Det er tungt å innføre, gir svak kopling til genererte sider og
  er lite aktivt i mkdocs-samanheng. Vert **ikkje** tilrådd, men kan vurderast
  seinare for statiske sider (K1) dersom eksterne omsetjarar skal involverast.

### Tilråding

**Alternativ B.** Hovudgrunnen er at det ikkje avheng av ein frosen plugin og
kan flyttast direkte til Zensical. Fallback-logikken vi må skrive sjølv er
enkel, sidan `publish.sh` allereie styrer kva som havner i `docs/`. Endeleg
val vert teke i steg 2 (sjå handlingslista).

## Forslag til arkitektur

### 1. Éin strengkatalog for generert tekst (K5-K8, K10)

- Ny fil `mkdocs/lib/i18n/strings.yaml` med éin nøkkel per streng og verdiar per
  språk:

  ```yaml
  section.kom_i_gang:     { nn: "Kom i gang",   en: "Getting started" }
  section.versjonslog:    { nn: "Versjonslog",  en: "Version history" }
  table.artefakt:         { nn: "Artefakt",     en: "Artifact" }
  nav.rettleiingar:       { nn: "Rettleiingar", en: "Guides" }
  ```

- Katalogen er éi kjelde (DRY) for alle forbrukarar:
  - **Bash (`sections/*.sh`, `publish.sh`):** `i18n_load <lang>`
    (`mkdocs/lib/utils/i18n.sh`) rendrar katalogen éin gong per språk via
    `run_python_container` til ein assosiativ tabell `I18N`. Oppslaget skjer via
    `t <nøkkel>`. Manglande nøkkel gir synleg feil (jf. «Ingen stille feil»).
    *(Justert i steg 3: tabell i minnet i staden for `strings.<lang>.sh`-filer.)*
  - **Python (`generate-*-md.py`, `collect-schema-metadata.py`):**
    `load_catalog().t(key, lang)` frå `mkdocs/lib/scripts/i18n_strings.py`,
    med språk frå eit `--lang`-argument.
  - **Jinja-malar (gen-doc):** gen-doc tek ikkje eigne malvariablar. Forslaget er
    at malane skriv markørar (t.d. `@@i18n:table.class@@`) i staden for tekst,
    og at `publish.sh` byter dei ut per språk når filene vert kopierte til
    `docs/`. Då køyrer gen-doc berre éin gong. Utbytinga må vere **siste**
    transformasjon, fordi `classes.sh`/`metadata.sh` parsar gen-doc-outputen på
    overskriftstekst (sjå O2). Parse-mønstra matchar då markørane, ikkje
    omsett tekst. O1 er avklart: `publish.sh` er einaste kjende forbrukar av
    `generated/*/docs/`, så markørane er ikkje synlege for andre.
- `make i18n-check` (`i18n_strings.py check` og `tests/test_i18n_strings.py`)
  sjekkar at alle nøklar har verdi for alle språk, og at alle nøklar som er
  brukte (`@@i18n:`-markørar, `$(t ...)`, `.t("...")`) finst i katalogen.

### 2. Statiske sider og kopierte kjelder (K1-K4)

- Engelske versjonar ligg **ved sida av** originalen med suffiks:
  `mkdocs/docs/om.en.md`, `README.en.md`, `src/linkml/<domain>/description.en.md`,
  `policies/README.en.md`. Omsetjinga står då ved originalen, og det er lett å sjå
  kva som manglar. Suffiksformatet er òg kompatibelt med alternativ A dersom vi
  skulle byte.
- `publish.sh` vel `.en.md` for det engelske treet. Manglar fila, vert den
  nynorske kopiert med ein admonition øvst (tekst frå strengkatalogen, t.d.
  «This page is not yet available in English»). Det nynorske treet ekskluderer
  `*.en.md` (`exclude_docs`).
- Ein rapport (make-target eller logglinje i `publish.sh`) viser kor mange sider
  som manglar omsetjing (maskinlesbar, «pull, ikkje push»).
- **Omsetjing og endringsdeteksjon (O3):** ein LLM gjer omsetjinga. Kvar
  `.en.md` får front-matter med hash av originalen på omsetjingstidspunktet:

  ```yaml
  ---
  i18n:
    source: om.md
    source_hash: sha256:3f2a...   # hash av om.md då omsetjinga vart laga
  ---
  ```

  Ein make-target (t.d. `make i18n-status`) listar sider der originalen har
  endra seg sidan omsetjinga, i tillegg til sider som manglar omsetjing. Det
  gir ei **åtvaring**, ikkje feil, så bygget ikkje stoppar. Ein LLM kan då
  omsetje berre desse sidene på nytt og oppdatere `source_hash`. Same
  mekanisme gjeld strengkatalogen: kvar nøkkel kan ha `source_hash` for den
  nynorske verdien, slik at endra nynorsk tekst gjer den engelske verdien
  utdatert. `source_hash` må fjernast frå front-matter før mkdocs ser fila,
  eller ignorerast (mkdocs godtek ukjende front-matter-felt).

### 3. Innhald som ikkje vert omsett (K11 + modellinnhald)

- `CHANGELOG.md`, valideringsmeldingar frå MCP-validatoren og all
  skjemametadata vert vist uendra. Den engelske versjonen får éin fast merknad
  (frå strengkatalogen) på skjemasider om at modellinnhaldet er på norsk.

### 4. Konfig og språkveljar (K5, K9)

- Heredoc-blokka i `publish.sh` Steg 3 vert parametrisert per språk:
  `site_name`, `site_description`, `copyright`, `theme.language` (`nn`/`en`),
  `site_url` (med `/en/`-suffiks), nav-etikettar via strengkatalogen og
  `extra.alternate` med begge språka.
- Domenenav-etikettane som vert genererte frå `generated/` vert slått opp i
  strengkatalogen dersom dei er tekst, ikkje skjemanavn.
- **Artefakter vert ikkje duplisert (O4) og blir liggjande på dagens adresse (O6/L2):**
  berre `.md`-filer havner i språktrea `/nn/` og `/en/`. Artefakter (`*.ttl`,
  `*.json`, `*.yaml`, `diagrams/*` ...) vert kopierte éin gong til dagens sti
  utan språkprefiks, t.d. `/felles/brreg-felles-tid/brreg-felles-tid-schema.ttl`.
  Begge språktrea lenkjer dit relativt. Omskrivinga legg til `../` for
  språkprefikset og eitt til for sider som ikkje er `index.md`
  (`use_directory_urls`), og vel ut artefakter etter filending (sjå steg 2 (d)).
  Lenkjesjekken (lychee) må stadfeste at lenkjene held.
- **Vidaresending frå gamle adresser (O6/L2):** for kvar side i `/nn/` genererer
  `publish.sh` ei lita HTML-side på den gamle adressa (utan språkprefiks) med
  `<link rel="canonical">`, `<meta http-equiv="refresh">` og
  `location.replace(... + location.hash)`, slik at `#anker` vert med. Rota (`/`)
  vidaresender til `/nn/`. `heimeside` i modellmanifesta
  (`generate-informasjonsmodell.py`, brukt som informasjonsmodellidentifikator)
  **vert ikkje endra**: identifikatoren skal vere stabil, og den gamle adressa
  svarar framleis via vidaresendingssida.
- Søk: `plugins: - search: lang:` sett per språkversjon.

## Steg

1. **Rett `theme.language` til `nn`** i heredoc-blokka i `publish.sh`. Endringa er
   liten og uavhengig, men gir nynorske UI-strengar i dag.
2. **Prototype og endeleg val A/B:** lag ein minimal prototype av alternativ B
   (to bygg + `extra.alternate`) på to statiske sider og éi skjemaside. Verifiser:
   (a) om språkveljaren blir på same side eller hoppar til rota, (b) søk per
   språk, (c) byggtid, (d) relative lenkjer frå `/en/` til artefakter. Logg valet i
   `## Avgjerder`.
   **Resultat av prototypen (2026-09-27)**, bygd i scratchpad med
   `mkdocs.nn.yml`/`mkdocs.en.yml` (`INHERIT: base.yml`), `om.md`,
   `kom-i-gang/kommandoar.md` og heile `felles/brreg-felles-tid/` (77 filer, frå
   `HEAD`). Det engelske treet vart bygd av eit lite Python-script: `.src`-fil
   for framsida, fallback med merknad for resten, og omskrivne artefaktlenkjer.
   - **(a) Språkveljaren:** Material 9.7 (`function ui()` i bundlen) hentar
     `sitemap.xml` for målspråket ved klikk. Finst same sti der, går han til
     same side **med `#anker`**, som passar godt saman med O2-a. Elles går han
     til framsida for målspråket. Logikken krev at ingen språkbase er prefiks
     av ein annan. Ei simulering av logikken med Node, kopiert ordrett frå
     bundlen, gav:
     - nynorsk på rota (`/`) og engelsk på `/en/`: engelsk → nynorsk hamnar
       **alltid** på framsida. Nynorsk → engelsk er avhengig av kva sitemap
       som vert lasta først: nokre gonger same side, nokre gonger framsida.
     - nynorsk under `/nn/` og engelsk under `/en/`: same side og same anker
       i begge retningar.
     - Krev avgjerd om adressestruktur (sjå O6).
   - **(b) Søk:** to separate indeksar, `lang: ["no"]` for nynorsk og
     `lang: ["en"]` for engelsk. `<html lang>` og UI-tekst er rette
     («Gå til innhald» / «Skip to content»). Sider som fell tilbake til
     nynorsk, vert indekserte med den engelske stemminga i det engelske
     søket. Det er akseptabelt.
   - **(c) Byggtid:** prototypen tek om lag 2,4 s per språk. Fullt nynorsk
     `mkdocs build` tok 591 s lokalt (steg 1). Det engelske treet har like
     mange `.md`-sider (fallback), så bygget tek om lag dobbelt så lang tid
     dersom byggja køyrer etter kvarandre. Køyr dei to byggja parallelt til
     kvar sin `site_dir` og slå dei saman etterpå. Alternativ A ville ha
     same kostnad.
   - **(d) Artefaktlenkjer:** 11 av 11 lenkjer frå `/en/` løyste seg til filer
     i det nynorske treet. To fallgruver vart funne og retta:
     (1) mkdocs justerer ikkje lenkjer til filer utanfor `docs_dir` for
     `use_directory_urls`. Sider som ikkje er `index.md`, treng difor eitt
     ekstra `../`. (2) Omskrivinga må velje ut artefakter etter filending
     (`.ttl`, `.svg`, `.puml`, `.yaml`, `.json` ...), ikkje etter
     «ikkje `.md`», elles vert katalog-lenkjer til andre skjemasider
     (`../brreg-felles-typer/#types`) omskrivne feil. Lenkjer som går ut av
     `docs_dir`, gir mkdocs-åtvaringar. Dei er alt undertrykte i portalkonfigen
     (`not_found: ignore`), så lychee må dekkje `/en/`.
3. **Strengkatalog og hjelpefunksjonar:** opprett `mkdocs/lib/i18n/strings.yaml`,
   `i18n_load`/`t` i `mkdocs/lib/utils/i18n.sh`, Python-modulen
   `mkdocs/lib/scripts/i18n_strings.py`, `tests/test_i18n_strings.py` og
   `make i18n-check`.
4. **Trekk ut hardkoda strengar** frå `sections/*.sh`, `publish.sh`,
   `generate-*-md.py` og `404.html` til katalogen. Rekn med at den nynorske
   outputen blir byte-identisk med i dag (regresjonssjekk med diff av
   `mkdocs/docs/` før og etter).
5. **Jinja-malar:** innfør `@@i18n:`-markørar i `src/assets/templates/docgen/`
   og utbyting i `publish.sh` som siste transformasjon. Skriv om parse-mønstra i
   `classes.sh` og `metadata.sh` slik at dei matchar markørar i staden for
   engelsk tekst. Dette rettar samstundes dei engelske overskriftene i den
   nynorske versjonen, som «Classes» og «Description». Alle statiske
   overskrifter i malane og `sections/*.sh` får eksplisitt, språknøytral ID
   lik dagens slug (O2-a), t.d. `## @@i18n:class.inheritance@@ {#inheritance}`.
   Verifiser med diff av genererte `id`-attributt før og etter at ingen anker
   har endra seg.
6. **To språktre i `publish.sh`:** byggjer nynorsk og engelsk tre, med fallback
   og merknad for manglande omsetjingar og `exclude_docs` for `*.en.md`.
   Artefakter vert kopierte éin gong til rot-stien, artefaktlenkjene vert
   omskrivne, og det vert generert vidaresendingssider for gamle adresser
   (O6/L2). Logikken er skildra i steg 2 (d) og i arkitektur § 4. Prototype-scripta
   låg berre i scratchpad for økta og er ikkje tekne vare på.
7. **Konfig per språk:** parametrisert `mkdocs.yml`-generering, `extra.alternate`,
   `site_url` og søk.
8. **Makefile/CI:** oppdater `make docs-publish`/`docs-serve` og
   GitHub Pages-workflowen slik at `site/en/` kjem med. Køyr `actionlint` på
   endra workflowar. Utvid lenkjesjekken (`lenkje-og-mermaid-sjekk.yml`,
   lychee) til å dekkje `/en/`.
9. **Endringsdeteksjon:** `source_hash` i front-matter og i strengkatalogen, og
   `make i18n-status`, som listar manglande og utdaterte omsetjingar som
   åtvaringar (sjå arkitektur § 2).
10. **Første engelske innhald (LLM-omsett):** omset strengkatalogen fullt ut,
    `README.en.md` (framsida) og `om.md`, med `source_hash`. Resten av dei
    statiske sidene fell tilbake til nynorsk inntil vidare.
11. **Dokumentasjon:** oppdater `.claude/rules/mkdocs-portal.md` (korleis
    strengar, `.en.md`-filer og `source_hash` fungerer), `COMMANDS.md` for
    `i18n-status`, `mkdocs/README.md` og ei kort rettleiing for
    LLM-omsetjing (kva som skal omsetjast, korleis `source_hash` vert oppdatert).

## Handlingsliste

- [x] 1. `theme.language: nn` (`publish.sh` Steg 3-heredoc; Material 9.7 har
  `nn.html`, og søket brukar `lang: no` for både nb og nn, så søket er uendra)
- [x] 2. Prototype og endeleg val A/B (B stadfesta; O6 = L2 med artefakter på rot-stien)
- [x] 3. Strengkatalog, renderer, `t`-funksjon, konsistenstest (`make i18n-check`: sjekk + 11 testar + røyktest nn/en, alle grøne)
- [x] 4. Uttrekk av hardkoda strengar (byte-identisk nynorsk output: 8555/8555 filer, òg med fiksturar)
- [ ] 5. i18n-markørar og eksplisitte anker-ID-ar (O2-a) i docgen-malane og `sections/*.sh`
- [ ] 6. To språktre, fallback, artefakter på rot-stien og vidaresendingssider i `publish.sh`
- [ ] 7. `mkdocs.yml` per språk og `extra.alternate`
- [ ] 8. Makefile, CI-deploy og lenkjesjekk for `/en/`
- [ ] 9. `source_hash` og `make i18n-status`
- [ ] 10. Første engelske innhald, LLM-omsett (katalog, framside, `om.md`)
- [ ] 11. Dokumentasjon og rules

## Opne saker

### O2: overskriftsanker ved omsetjing (avgjort: O2-a, sjå `## Avgjerder`)

Steg 5 byter overskriftstekst i gen-doc-sidene. I den nynorske versjonen går
teksten frå engelsk til nynorsk, og i den engelske versjonen går dei
eksisterande nynorske overskriftene over til engelsk. Automatisk genererte
anker (slugs) endrar seg då. Undersøkinga 2026-09-27 fann desse fakta:

**1. Skjemaforsidene (`<domain>/<schema>/index.md`) er allereie trygge.**
Overskriftene «Classes», «Slots», «Enumerations», «Types», «Subsets» og
«Modellmetadata» får eksplisitte, låste anker (`{#classes}`, `{#slots}`,
`{#enumerations}`, `{#types}`, `{#subsets}`, `{#metadata}`) i
`classes.sh:151-186` og `metadata.sh:15`. Dei einaste interne fragmentlenkjene
som finst i generatorlaget, går til desse ankra: `#classes` i
`eksempeldatafil.sh:45` og gen-doc-lenkjer mellom skjema, t.d.
`../../ap-no/dcat-ap-no/#classes`. Dei held så lenge ID-ane står.

**2. Den reelle risikoen er parsing, ikkje lenkjer.** `classes.sh` finn
seksjonane med `awk '/^### Classes/,/^### [^C]/'` og tilsvarande for Slots,
Enumerations og Types. Mønsteret matchar den engelske teksten og brukar i
tillegg *første bokstav i neste overskrift* som stoppkriterium. `sed`-en som set
inn `{#classes}`, matchar òg den engelske teksten. `metadata.sh` matchar
`## Modellmetadata`. Omsette overskrifter direkte i malen (t.d. «Klasser»,
«Kodelister») ville ha brote uttrekket **stille** med feil seksjonsgrenser.
Med markørar og utbyting til sist (O1) er dette løyst, men mønstra må
skrivast om til å matche markørane (steg 5).

**3. Klasse-, slot-, enum- og typesider (`klasser/*.md`) har om lag 80
overskrifter med automatiske anker.** Døme er «Inheritance», «Class
Properties», «Usages», «LinkML Source», «Eigenskapar», «Arva» og «Verdiar».
Det finst ingen interne lenkjer til desse fragmenta i generatorlaget. Endringa
rammar difor berre eksterne djuplenkjer og bokmerke, og om språkveljaren kan
halde brukaren på same seksjon ved språkbyte.

**4. Æ/ø/å-fella** (`.claude/rules/mkdocs-portal.md`): nynorske overskrifter
får uføreseielege anker, t.d. «Åtvaringar» → `atvaringar` og
«Nøkkel» → `nkkel`.

**5. Overskrifter med dynamisk innhald** (`### {{ subset_name }}`,
`### Example: {{ name }}`, `### {{ rule.title }}`) inneheld modelltekst. Berre
prefikset, som «Example:», skal omsetjast.

**Alternativ:**

| | Tiltak | Fordel | Ulempe |
|---|---|---|---|
| **O2-a** (tilrådd) | Språknøytrale, eksplisitte ID-ar på *alle* statiske overskrifter i malane og `sections/*.sh`, lik dagens slug: `## @@i18n:class.inheritance@@ {#inheritance}`. Dynamiske overskrifter får ID frå prefiksnøkkel + slug av verdien. | Same anker i begge språk og som i dag, så eksisterande djuplenkjer held. Unngår æ/ø/å-fella og gjer det mogleg for språkveljaren å halde seksjonen. | Om lag 80 overskrifter må få `{#...}` (`attr_list` er allereie aktivert). |
| **O2-b** | Lås berre ankra som vert lenkja til internt (dei seks på forsida, allereie gjort). Resten får automatisk anker per språk. | Minst arbeid. | Djuplenkjer til klassesider endrar seg i den nynorske versjonen og er ulike mellom språka. Æ/ø/å-fella gjeld. |
| **O2-c** | Behald engelske overskrifter i gen-doc-sidene også i den nynorske versjonen. Berre `sections/*.sh`-tekst vert omsett. | Ingen ankerendring. | Den nynorske versjonen held fram med blanda språk, som strir mot målet. |

### O6: adressestruktur for språkveljaren (avgjort: L2, sjå `## Avgjerder`)

Sjå resultatet for (a) under steg 2. Alternativ:

| | Adresser | Språkveljar | Kostnad |
|---|---|---|---|
| **L1** | nynorsk på `/` (uendra), engelsk på `/en/` + eit lite eige script i `extra_javascript` som erstattar Material sitt sidebyte (byter prefikset `/en/` ↔ `/` og beheld stien og `#anker`) | Same side i begge retningar | Om lag 20 linjer JS å vedlikehalde. Repoet har alt `toc-active-click-fix.js` etter same mønster. Må testast ved Material-/Zensical-oppgradering. |
| **L2** | `/nn/` og `/en/`, rota vidaresender til `/nn/` | Same side, innebygd i Material | Alle eksisterande adresser endrar seg. Eksterne djuplenkjer bryt, med mindre `publish.sh` genererer ei vidaresendingsside per gammal adresse (om lag like mange filer som portalen har sider). |
| **L3** | nynorsk på `/`, engelsk på `/en/`, utan eige script | Engelsk → nynorsk går alltid til framsida. Nynorsk → engelsk er tilfeldig. | Ingen |

### O5: framtidig migrering til Zensical (ope inntil vidare)

Alternativ B er vald for å vere kompatibelt, men kompatibiliteten bør
verifiserast når Zensical 0.1.0 er ute (5. november 2026). Merk: imaget
`squidfunk/mkdocs-material:9.7` skriv no ut ei åtvaring om at MkDocs 2.0 fjernar
plugin-systemet og temaoverstyringar
([analyse](https://squidfunk.github.io/mkdocs-material/blog/2026/02/18/mkdocs-2.0/)).
Det styrkjer valet av ei løysing utan plugin, men `mkdocs/overrides/404.html`
vil òg bli ramma. Brukaren har
valt å la dette stå ope inntil vidare.

## Avgjerder

- **Språk:** nynorsk + engelsk (brukarval, 2026-09-27).
- **Omfang:** berre portaltekst. Modellinnhald frå skjemaa vert ikkje omsett
  (brukarval, 2026-09-27).
- **Tilrådd arkitektur:** alternativ B (separate bygg + `extra.alternate`) framfor
  `mkdocs-static-i18n`, fordi pluginen er frosen og Material for MkDocs er på veg
  mot end-of-life. Er framleis eit forslag og skal stadfestast etter prototypen i
  steg 2.
- **O1, gen-doc-markørar:** `publish.sh` er einaste kjende forbrukar av
  `generated/*/docs/` (brukarsvar, 2026-09-27). gen-doc køyrer éin gong med
  `@@i18n:`-markørar, og utbytinga per språk skjer som siste steg i `publish.sh`.
- **O3, omsetjing:** ein LLM omset, og `source_hash` i front-matter og
  strengkatalog vert brukt til å oppdage utdaterte omsetjingar (brukarval,
  2026-09-27).
- **O4, artefakter:** vert ikkje duplisert. Den engelske versjonen lenkjer til
  artefaktfilene under den nynorske stien (brukarval, 2026-09-27).
- **O2, anker:** O2-a (brukarval, 2026-09-27). Alle statiske overskrifter får
  eksplisitt, språknøytral ID lik dagens slug. Då blir ankra like i begge språk og
  lenkjer utanfrå held, og æ/ø/å-fella vert unngått. Overskrifter med dynamisk
  innhald får ID frå prefiksnøkkel + slug av verdien.
- **O5, Zensical:** står ope inntil vidare (brukarval, 2026-09-27).
- **O6, adressestruktur:** L2, `/nn/` og `/en/` (brukarval, 2026-09-27). Etter
  valet vart det kartlagt at portal-adressene òg vert brukte maskinelt:
  `heimeside` i alle `metadata/*-manifest.yaml` er informasjonsmodellidentifikator
  i Felles datakatalog, og katalog-`.ttl`-filer vert hausta frå portal-adresser
  (`publisering-begrep.md:207`, `publisering-modell.md:166`,
  `publisering-oversikt.md:350`). Haustarar følgjer ikkje vidaresending i
  HTML/JS, og GitHub Pages har ikkje HTTP-vidaresending. L2 vert difor
  realisert slik: (1) artefakter blir liggjande på dagens adresse utan
  språkprefiks, (2) berre HTML-sider flyttar til `/nn/`/`/en/`, (3) ei
  vidaresendingsside per gammal sideadresse, (4) `heimeside` er uendra.
  Prototypen stadfesta dette: 11/11 artefaktlenkjer frå både `/nn/` og `/en/`,
  og 71 vidaresendingssider med 213/213 lenkjer i orden. Per-side-sider vart
  valt framfor éi felles `404.html` med JS-vidaresending, fordi ein
  identifikator-URI bør svare med 200 og ikkje 404.
- **Artefakter blir liggjande på dagens sti (A0)** (brukarval, 2026-09-27). Vurderte
  alternativ for å flytte dei: A1 kopi på både gammal og ny sti i ein
  overgangsperiode, A2 flytte alt unntatt kjende haustingsendepunkt, A3 GitHub
  Releases (`releases/latest/download/`), A4 persistente identifikatorar via
  w3id.org og A5 hosting med HTTP-vidaresending. A0 vart vald fordi artefaktene
  er språkuavhengige, ingenting bryt og ingenting vert duplisert. A3 og A4 kan
  takast opp i eigne specar dersom behovet oppstår.
- **Strengkatalog, format og lastar (steg 3):**
  - `mkdocs/lib/i18n/strings.yaml` har `languages`, `default_language` og
    `strings: {<nøkkel>: {nn: ..., en: ...}}`. Nøklar er `[a-z0-9_]` i minst to
    punktum-separerte ledd. **Alle språk er påkravde per nøkkel.** Det finst
    ingen fallback til nynorsk i katalogen: ein manglande verdi feilar
    `make i18n-check` og `render-sh`. Det er enklare enn mjuk fallback og i tråd
    med «Ingen stille feil». Fallback gjeld berre heile sider (steg 6).
  - Katalogen startar med dei tre nøklane som i18n-mekanismen sjølv treng
    (merknad om ikkje omsett side, tittel og tekst, og merknad om norsk
    modellinnhald). Andre nøklar kjem i steg 4-5 når strengane vert trekte ut.
  - bash: `i18n_load <lang>` rendrar katalogen **éin gong** via
    `run_python_container` til ein assosiativ tabell `I18N`, og `t <nøkkel>`
    slår opp. Tabellen vert arva av bakgrunnsjobbane (`process_schema &`) i
    `publish.sh`, så det trengst ikkje eit container-kall per seksjon. `t`
    feilar synleg ved ukjend nøkkel eller manglande `i18n_load`. Resultatet
    bør tilordnast ein variabel (`x=$(t k)`) for at `set -e` skal slå inn.
  - Python: `mkdocs/lib/scripts/i18n_strings.py` er både bibliotek
    (`load_catalog().t(key, lang)`) og CLI (`render-sh`, `check`, `languages`).
    Filnavnet har understrek (ikkje bindestrek som dei andre scripta i
    katalogen), fordi modulen skal kunne importerast av `generate-*-md.py`.
  - `check` skannar `publish.sh`, `mkdocs/lib/` og docgen-malane etter tre
    bruksmønster: `@@i18n:k@@`, `$(t k)` og `.t("k"`. Nøklar som er brukte men
    manglar i katalogen, feilar med fil:linje. Ubrukte nøklar vert ikkje
    rapporterte, sidan dei tre startnøklane først vert brukte i steg 6.
  - Test: `tests/test_i18n_strings.py` (unittest, køyrd med pytest i
    python-pytest-imaget). Imaget har ikkje bash, så bash-lastaren vert
    røyktesta av `make i18n-check` på verten. Språklista vert henta frå
    katalogen (`languages`) og er ikkje hardkoda.
- **Uttrekk av strengar (steg 4):**
  - **Omfang:** `mkdocs/lib/sections/*.sh` (14 filer), `mkdocs/lib/utils/formatters.sh`
    (`domain_label`/`artifact_label`), `publish.sh` (domeneoversikt,
    modellanalyse-sidene, byggetidspunkt på framsida) og
    `generate-validation-md.py`/`generate-modellanalyse-md.py`. Katalogen har no
    146 nøklar. `generate_index.sh` og `copy_artifacts.sh` har ingen portaltekst.
  - **Ikkje teke med i steg 4:** `site_name`, `site_description`, `copyright` og
    nav-etikettane i `mkdocs.yml`-heredocen høyrer til steg 7 (konfig per
    språk). Kodedøme i «Kom i gang» (YAML/Java/Python, `mine-data.yaml`) er kode,
    ikkje portaltekst. Eigennavn som «Felles Begrepskatalog», «GitHub Issues» og
    «LinkML» er ikkje trekte ut.
  - **`mkdocs/overrides/404.html` var ikkje i bruk:** verken `mkdocs.yml` eller
    `publish.sh` sette `theme.custom_dir`, så portalen viste Material sin
    standard-404, sjølv om `DOCS_RUN` alt monterte `mkdocs/overrides`. Etter
    brukarval (2026-09-27) er sida teken i bruk:
    - Malen er flytta til `mkdocs/lib/templates/404.html` med `@@i18n:side404.*@@`-markørar.
    - `publish.sh` genererer `mkdocs/overrides/404.html` med den nye
      `i18n_render` (`mkdocs/lib/utils/i18n.sh`), som òg skal brukast for
      gen-doc-markørane i steg 5.
    - `theme.custom_dir: overrides` er sett, og `mkdocs/overrides/` ligg i
      `.gitignore`. `docs-build`/`docs-serve` opprettar katalogen, slik at
      podman-monteringa ikkje feilar i ein fersk klone.
    - Lenkja «Gå tilbake» peika på `/`, altså domenerota på GitHub Pages og ikkje
      portalen. Ho brukar no `config.site_url` som Material sin eigen 404.
    - To teiknsett-rettingar (CLAUDE.md § Teiknsett): en-dash i tittelen er
      ASCII-bindestrek, og en-dash i A2-setninga er em-dash.
    - Stadfesta i sandkassa: `site/404.html` viser nynorsk tekst og lenkjer til
      `https://audunautomat.github.io/linkml-datamodellering-no/`. Resten av
      `mkdocs/docs` er uendra, og `mkdocs.yml` skil seg berre med `custom_dir`.
    - Treff på den gamle stien etter flyttinga: `make/01-containers.mk`,
      `.claude/rules/container-images.md` og cache-nøkkelen i `generate.yml`
      (`mkdocs/overrides/**`) gjeld framleis, sidan katalogen er monteringspunkt
      med generert innhald og malen er dekt av `mkdocs/lib/**` i same nøkkel.
      Referansane i denne specen er historiske.
  - **Plasshaldarar:** tekst med variablar inni har `{navn}` i katalogen
    (`t nøkkel navn=verdi` / `t(nøkkel, lang, navn=verdi)`). Utbytinga er
    eksplisitt, ikkje `str.format`, sidan tekstane inneheld Markdown-anker som
    `{#classes}`. Manglande plasshaldar vert sjekka i *malen*, ikkje i resultatet,
    slik at innsette modellverdiar med `{...}` ikkje gjev falsk feil. `check`
    krev same plasshaldarar i alle språk.
  - **Statisk sjekk før bygg:** `t` inne i `echo "$(t k)"` svelgjer feilstatus.
    Difor køyrer `publish.sh` `i18n_strings.py check` før `i18n_load`, og skannaren
    kjenner att alle `t nøkkel`-kall i `.sh` (også `t k; echo` i `formatters.sh`).
    Nøklane i `generate-modellanalyse-md.py` vert sette saman av prefiks
    (`f"{prefix}.tittel"`) og vert ikkje sett av skannaren. Ein manglande nøkkel der
    gjev `CatalogError` ved køyring, og bygget stoppar med traceback.
  - **Python-scripta køyrer på verten** (`python3` i `modellanalyse.sh`/
    `valideringsresultat.sh`) og les katalogen med PyYAML. Det er ikkje ei ny
    avhengigheit: `generate-validation-md.py` importerte alt `yaml` på verten.
    Språket vert sendt som valfritt 4. argument (`$I18N_LANG`).
  - **Engelske verdiar er lagde inn no** fordi katalogen krev alle språk. Dei er
    utkast og skal gjennomgåast i steg 10.
  - **Kjende nynorsk-avvik er behaldne** for byte-likskap: «Entity-relationship
    diagram» (engelsk i den nynorske versjonen) og lenkjeteksten «[Classes]» i
    `seksjon.eksempeldatafil.per_klasse`. Dei kan rettast i steg 5, saman med
    overskriftene frå gen-doc (O2-a: lås anker før tekstendring).
  - **Seks ubrukte nøklar fjerna:** `objekttype` for analysane utan kryssdomene-side
    var daude verdiar òg i den gamle `REPORTS`-lista, sidan fotnoten berre vert
    skriven når det finst ei kryssdomene-side.
  - **Verifisering utan å røre repoet:** `make docs-publish` vart køyrd i ein
    sandkasse-kopi i scratchpad (Makefile, `make/`, `mkdocs/`, `src/`,
    `generated/`, `README.md`) før og etter endringane. Grunnen er at
    `mkdocs/docs/felles/` framleis er versjonskontrollert (jf.
    `.claude/rules/mkdocs-portal.md`). Resultat: 8555/8555 filer identiske,
    bortsett frå byggetidspunktet, og `mkdocs.yml` identisk. Referansedataa køyrde
    berre 112 av 152 nøklar, så begge sandkassane fekk same fiksturar: `CODEOWNERS.md`,
    8 av 9 modellanalyserapportar, ei validering med feil og åtvaringar, ei ugyldig
    valideringsfil, ei godkjend validering, `submodels` på `dqv-ap-no` og status
    Withdrawn. Framleis ingen skilnad utover sandkassestien i meldinga om ugyldig
    fil. Alle nøklar er no dekte, bortsett frå dei tre `i18n.*` for steg 6.
- **Prototypen køyrer containerar direkte (steg 2):** `make docs-publish`/`docs-build`
  byggjer alltid heile portalen og skriv til `mkdocs/docs/`. Prototypen køyrde
  difor `squidfunk/mkdocs-material:9.7` (same image som `Dockerfile.mkdocs`)
  direkte mot scratchpad. Det fell inn under unntaket for utvikling i CLAUDE.md
  («Bruk Makefile-targets»), og ingen repofiler vart endra.
- **Alternativ B er stadfesta (steg 2):** (b), (c) og (d) fungerer utan ny
  avhengigheit. (a) kan løysast innanfor B (O6). Om `mkdocs-static-i18n`
  genererer språkveljarlenkjer per side og dermed unngår (a), er ikkje
  verifisert. Det endrar ikkje valet, sidan pluginen er frosen. Valet av
  adressestruktur er skilt ut som O6.

## Kjelder

- [mkdocs-static-i18n](https://github.com/ultrabug/mkdocs-static-i18n) og [issue #342](https://github.com/ultrabug/mkdocs-static-i18n/issues/342)
- [Zensical: Language](https://zensical.org/docs/setup/language/), [Compatibility](https://zensical.org/compatibility/), [Upcoming changes](https://zensical.org/upcoming-changes/)
- [Material for MkDocs: Zensical-kunngjering](https://squidfunk.github.io/mkdocs-material/blog/2025/11/05/zensical/)
