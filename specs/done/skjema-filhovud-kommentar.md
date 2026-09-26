# `add-schema-header-comments.py` er broten, og filhovudkommentaren manglar i 15 skjema

## Bakgrunn

Funne som K5 under `specs/done/validate-capture-utan-schema.md` (2026-09-26).
`src/assets/scripts/add-schema-header-comments.py` vart skriven i
`9d1695ef` (2026-06-19, `specs/done/auto-forvalta-felt-kommentar.md`) for å
leggje ein tolinjes filhovudkommentar i alle skjema som release-please
forvaltar:

```yaml
# version, endringsdato og utgivelsesdato vert automatisk oppdatert av CI.
# Sjå CONTRIBUTING.md for detaljar om kva som er manuelt vs. automatisk.
```

Skjema med `##`-innleiing får same tekst med `##` inni den eksisterande
opningsblokka. Skriptet er idempotent (merke: `MARKER`) og var meint å køyrast
éin gong.

## Kartlegging (2026-09-26)

### Skriptet er broten på same måte som F1/F2 i `validate-capture-utan-schema`

| Feil | Stad | Verknad |
|---|---|---|
| Utdatert config-sti | `--config` standard `release-please-config.json` i rota, flytta til `.github/` i `1f76478d` (2026-07-28) | `FEIL: kunne ikkje lese …`, exit 1 (synleg) |
| `extra-files` finst ikkje | skjemasti frå `config["packages"][pkg]["extra-files"][0]["path"]`, fjerna i `1d20298b` (2026-07-04) | med rett sti: `continue` for alle pakkar, «0 fil(ar) oppdatert» (stille) |

Skriptet har ingen make-target, ikkje noko CI-kall og ingen andre kallarar (`grep`
utanom `specs/done/`).

### Jobben er berre halvgjord: 15 av 36 komponentar manglar kommentaren

Av 37 pakkar i `.github/release-please-config.json` (36 med eksisterande
skjemafil, sjå K6):

| Status | Tal | Komponentar |
|---|---|---|
| Har kommentaren | 21 | dei som fanst då skriptet vart køyrt i juni |
| **Manglar** | **15** | `common-ap-no`, `dcat-ap-no`, `dqv-core`, `modelldcat-katalog`, `modelldcat-modell`, `xkos-ap-no`, `digdir-/kartverket-/ksdigital-/novari-/skatteetaten-modellkatalog`, `referansemodell-bronze/-silver/-gold`, `enhetsregisteret-bvrinnfelles` |

Dei 15 er komponentar som vart lagde til (eller flytta, t.d. `dqv-core`,
`modelldcat-modell`) etter køyringa i juni. Frå 2026-07-04 kunne skriptet
uansett ikkje finne dei. Ingenting anna i repoet skriv kommentaren:
scaffoldinga (`new-modell.sh`) legg han ikkje til, og `update-schema-dates.py`
heller ikkje. Kommentaren står i 21 skjema, alle frå juni-køyringa.

### Naturleg eigar: `update-schema-dates.py`

`src/assets/scripts/update-schema-dates.py` er skriptet som faktisk forvaltar
dei tre felta kommentaren handlar om. Det køyrer i CI på kvar release-PR
(«Oppdater schema-versjonar i release-PR» i `.github/workflows/release-please.yml`),
berre med stdlib. Det finn skjemaet med `resolve_schema_path()` (ikkje
`extra-files`), og skriv berre når versjonen er endra (`sync_package`).

### Sidefunn K6: `lunchregisteret` er ein spøkjelseskomponent

`src/linkml/oreg/lunchregisteret` står framleis i
`.github/release-please-config.json` og `.github/release-please-manifest.json`
(`0.2.0`), men katalogen inneheld berre `CHANGELOG.md`. Skjemaet er borte.
`update-schema-dates.py` skriv difor `ÅTVARING: … finst ikkje` ved kvar køyring,
og release-please held fram med å spore ein pakke utan innhald. Det ligg
utanfor kommentarjobben, men vert rydda her (O3 = «rydd no»).

Kartlagt 2026-09-26: skjemaet vart fjerna i `64387d86` (2026-08-23, «scaffold
seks nye enhetsregisteret-domenemodellar»). Att står:

| Stad | Kva | Tiltak |
|---|---|---|
| `.github/release-please-config.json:146–149` | pakkeoppføring `lunchregisteret` | fjern |
| `.github/release-please-manifest.json:30` | `"src/linkml/oreg/lunchregisteret": "0.2.0"` | fjern |
| `src/linkml/oreg/lunchregisteret/CHANGELOG.md` | einaste fil i katalogen | slett katalogen (historikken finst i git og i taggane) |
| `tests/test_make.sh:1202` | død BUG-17-skip `lunchregisteret)` i `test_gen_rdf` | fjern linja, sjå K7 |
| taggar `lunchregisteret-v0.1.1`, `-v0.1.2`, `-v0.2.0` | historikk | **behald**: å slette taggar er ei endring i versjonskontroll og kan bryte eksterne som har låst seg til dei |
| `bugs/*.md` (4 filer) | historiske døme frå då skjemaet fanst | behald |

### Sidefunn K7: BUG-17-skip i testane dekkjer ikkje dei faktiske skjemaa

`tests/test_make.sh:1197–1203` (`test_gen_rdf`) hoppar over RDF-testen for
skjema med versjonslåst URL-import (BUG-17), men **hardkodar** berre
`lunchregisteret`. Genereringa i `batch-generate.py` oppdagar same tilfelle
**automatisk** (`schema_has_versioned_import()`, `skip_if_versioned_import`).
Dei seks `oreg`-skjemaa `enhetsregisteret-{bvrbekreftelse,
bvrettersendingavvedlegg,bvrfriv,bvrstiftelsesdokument,
frivilligorganisasjonapi}` og `javazonetalk` har `rdf: true` og versjonslåst
import (`dcat-ap-no-v2.14.1`), men står ikkje i skip-lista. Genereringa hoppar
over dei, medan testen vil forvente ein `.ttl`-fil. Når
`lunchregisteret`-linja vert fjerna (K6), står `case`-blokka tom (sjå O4).

## Alternativ

| | Kva | For | Mot |
|---|---|---|---|
| **A** | **Slett skriptet** og aksepter at 15 (og alle nye) komponentar manglar kommentaren | Minst arbeid | Varig inkonsistens: nokre skjema har merknaden, andre ikkje. Merknaden mistar verdi |
| **B** | **Reparer skriptet** (`.github/`-sti, `resolve_schema_path`) og køyr det éin gong for dei 15 | Rettar dagens hol | Same hol oppstår att for kvar ny komponent, sidan skriptet er manuelt og lett å gløyme (jf. at det alt har vore broten i 12 veker utan at nokon merka det) |
| **C** | **Flytt logikken inn i `update-schema-dates.py`** (`ensure_header()` i `sync_package`), og slett `add-schema-header-comments.py` | Éin eigar for «CI-forvalta felt». Nye komponentar får kommentaren automatisk ved første release. Ingen manuelt verktøy å halde ved like | Endrar eit CI-køyrt skript. Release-PR-ar får to ekstra linjer første gong ein komponent utan kommentar vert releasa |

## Tilråding

**C.** Kommentaren seier at CI forvaltar felta, og då bør CI-skriptet som
forvaltar dei, òg sørgje for kommentaren. Det løyser både dagens hol og det
framtidige, og fjernar eit manuelt verktøy som har vist seg å rote seg vekk.

## Steg (ved C)

1. **`update-schema-dates.py`:**
   - Flytt `COMMENT_1`, `COMMENT_2`, `COMMENT_1_HASH`, `COMMENT_2_HASH`,
     `MARKER` og logikken i `add_header()` inn som ein rein funksjon
     `ensure_header(content: str) -> str` (ingen fil-I/O, returnerer uendra
     innhald viss `MARKER` finst). Behald handteringa av `##`-blokka, inkludert
     stderr-åtvaringa når avsluttande `##` manglar. Då vert innhaldet returnert
     uendra, og det skal ikkje vere nokon stille feil.
   - Kall `ensure_header()` i `sync_package()` etter `update_dates()`, altså
     berre når versjonen er endra (ingen massediff utanom release).
   - Oppdater docstringen (fjerde punkt: «filhovudkommentar vert lagd til
     dersom han manglar»).
2. **Tilbakefylling (O2):** viss O2 = «no», køyr `ensure_header()` éin gong for
   dei 15 skjemaa (eingongs Python-snutt i `$(PYTHON_RUN)`, ingen ny CLI-flagg).
   Viss O2 = «ved neste release» (tilrådd), er det ingenting å gjere.
3. **Slett `src/assets/scripts/add-schema-header-comments.py`.**
4. **Verifiser:**
   - Kopier eitt skjema utan kommentar og eitt med `##`-blokk til ein
     scratch-katalog. Køyr `ensure_header()` på innhaldet og kontroller
     resultatet (begge variantane). Køyr ein gong til og kontroller at
     innhaldet er uendra (idempotens).
   - `python3 src/assets/scripts/update-schema-dates.py --dry-run` gir same
     «OPPDATERT»-liste som før endringa (i dag: 0, sidan versjonane er
     synkrone). Einaste `ÅTVARING` er for `lunchregisteret` (K6).
   - `grep -rn add-schema-header-comments --exclude-dir=specs .` gir 0 treff.
5. **K6 (O3 = rydd no):** fjern pakkeoppføringa i `.github/release-please-config.json`
   og nøkkelen i `.github/release-please-manifest.json`. Slett
   `src/linkml/oreg/lunchregisteret/`, og fjern `lunchregisteret)`-linja i
   `tests/test_make.sh:1202`. Taggar og `bugs/`-historikk vert behaldne.
   Verifiser med tørrkøyring av release-please (same kommando som steg 9.3 i
   `specs/done/ci-etter-origin-flytting-audunautomat.md`): 36 komponentar,
   ingen feil, `Would open 0 pull requests`. `update-schema-dates.py --dry-run`
   skal gå utan `ÅTVARING`.
6. **K7 (O4):** sjå O4.

## Handlingsliste

- [x] 1. Avgjer O1 (C), O2 (ved neste release), O3 (rydd no) og O4 (a, generaliser)
- [x] 2. `ensure_header()` i `update-schema-dates.py`, kalla frå `sync_package()`
- [x] 3. Tilbakefylling etter O2: ingen (O2 = ved neste release)
- [x] 4. Slett `add-schema-header-comments.py`
- [x] 5. Verifiser (begge header-variantar, idempotens, dry-run, grep)
- [x] 6. K6: fjern `lunchregisteret` frå config og manifest, slett katalogen, fjern død test-skip
- [x] 7. K7 etter O4 (generalisert BUG-17-skip)
- [~] 8. Verifiser K6/K7 (release-please-tørrkøyring står att til etter push, sjå Utført): `release-please --dry-run` (36 komponentar, ingen feil), `update-schema-dates.py --dry-run` utan `ÅTVARING`, `bash -n tests/test_make.sh`

## Opne spørsmål

- ~~**O1:** A, B eller C?~~ **Avgjort 2026-09-26: C** (tilrådinga).
- ~~**O2:** Tilbakefylling no eller ved neste release?~~ **Avgjort 2026-09-26:
  ved neste release** (tilrådinga). Ingen tilbakefyllingskode.
- ~~**O3:** K6 her eller i eigen spec?~~ **Avgjort 2026-09-26: rydd no**, i denne
  specen (brukaren valde mot tilrådinga om eigen spec). Taggane vert behaldne,
  og `CHANGELOG.md` forsvinn med katalogen (sjå tabellen under K6).
- ~~**O4:**~~ **Avgjort 2026-09-26: a) generaliser** (tilrådinga). K7: kva skal skje med BUG-17-`case`-blokka i `test_gen_rdf` når
  `lunchregisteret` er fjerna?
  a) **Generaliser**, slik at testen hoppar over på same kriterium som genereringa
  (versjonslåst URL-import i `imports:`, same mønster som
  `schema_has_versioned_import()` i `batch-generate.py`). Då vert dei seks
  `oreg`-skjemaa dekte, og framtidige skjema òg. **Tilrådd.**
  b) Fjern berre den døde linja, og la K7 vere ein eigen bug eller spec.

## Avgjerder

- Lærdom (brukar stadfesta 2026-09-26): den gjentekne feilklassen med utdaterte
  stiar etter flytting er lagd til som punkt «Flytting/omdøyping av filer» under
  «Førende prinsipper» i `CLAUDE.md`, ikkje som ei stiavgrensa rule. Flytting kan
  skje kvar som helst i repoet, så regelen må gjelde ubetinga (jf.
  avgjerdstreet i `.claude/skills/ny-rule/SKILL.md` steg 2).
- `ensure_header()` tek `schema_path` som argument berre for stderr-åtvaringa
  (manglande avsluttande `##`). Funksjonen gjer framleis ingen fil-I/O.
- K7: bash-hjelparen `schema_has_versioned_import` i `tests/test_make.sh` er ein
  medviten duplikat av Python-kriteriet i `batch-generate.py` (to stader, under
  terskelen på 3+). `test_make.sh` køyrer på verten utan PyYAML, så han kan ikkje
  importere Python-funksjonen. Likskapen er verifisert mot alle 47 skjema (sjå
  Utført). YAML-kommentarar vert strippa, fordi Python-varianten parsar YAML og
  ignorerer dei.
- K6: JSON-filene vart skrivne om med `json.dumps(indent=2)`. Diffen er
  kontrollert til å vere berre dei 5 linjene for `lunchregisteret` (ingen
  formatendring elles).

- Specen er ei kartlegging med tilråding. Ingen kode er endra, og specen står i
  `specs/backlog/`.
- O1 = C, O2 = ved neste release, O3 = rydd no (brukaren, 2026-09-26). O3
  gjekk mot tilrådinga (eigen spec). Release-avgjerdene som følgjer med, er tekne
  her: taggane vert behaldne (sletting krev git-push og kan bryte eksterne pins),
  og den foreldrelause `CHANGELOG.md` vert sletta saman med katalogen.
- K7 vart funne under kartlegginga av K6. `lunchregisteret` var einaste
  oppføring i BUG-17-skipen i `tests/test_make.sh`, så K6 og K7 rører same
  kodeblokk.
- Kartlegginga telde komponentar via `resolve_schema_path()`-konvensjonen
  (`<pkg>/<basename>-schema.yaml`) og `MARKER`-teksten frå skriptet, same
  kriterium som skriptet sjølv brukar for idempotens.

## Utført

Gjennomført 2026-09-26 (O1 = C, O2 = ved neste release, O3 = rydd no, O4 = a).

**Filhovudkommentar (C):**
- `src/assets/scripts/update-schema-dates.py`: `HEADER_MARKER`/`HEADER_LINE_1/2` og
  `ensure_header(content, schema_path)`. Funksjonen vert kalla i `sync_package()`
  etter `update_dates()`, altså berre når versjonen er endra. Docstringen er
  oppdatert.
- `src/assets/scripts/add-schema-header-comments.py`: **sletta**.
- Verifisert: `ensure_header()` gir **identisk resultat med gamle
  `add_header()` for alle 36 komponentskjema** (21 med kommentar → uendra, 12
  `#`-variant, 3 `##`-variant). Funksjonen er idempotent for alle (andre køyring
  gir uendra innhald). `update-schema-dates.py --dry-run` → «0 fil(ar)
  oppdatert», ingen `ÅTVARING`. `grep add-schema-header-comments` utan `specs/`
  → 1 treff: den bevisste tilvisinga i docstringen til `update-schema-dates.py`
  («erstattar add-schema-header-comments.py»).
- Dei 15 skjemaa utan kommentar får han ved neste release av kvar komponent
  (O2).

**K6, `lunchregisteret`:**
- `.github/release-please-config.json` (−4 linjer) og
  `.github/release-please-manifest.json` (−1 linje): pakken er fjerna.
- `src/linkml/oreg/lunchregisteret/` (berre `CHANGELOG.md`): sletta.
- Taggane `lunchregisteret-v0.1.1/-v0.1.2/-v0.2.0` og `bugs/`-historikken er
  behaldne.

**K7, BUG-17-skip i testane:**
- `tests/test_make.sh`: den hardkoda `case … lunchregisteret)` i `test_gen_rdf`
  er erstatta med den nye hjelparen `schema_has_versioned_import` (eit element i
  toppnivå-`imports:` inneheld `://`, kommentarar strippa).
- Paritet: bash-hjelparen og Python-kriteriet i `batch-generate.py` gir same svar
  for **alle 47 skjema**. Hjelparen treff nøyaktig dei 6 `oreg`-skjemaa med
  versjonslåst import.
- Før: `TEST_FILTER=gen-rdf make test SCHEMA=…/javazonetalk-schema.yaml` →
  `##RESULT:FAIL:gen-rdf (javazonetalk)`, «0 OK, 1 feil».
  Etter: «Hoppar over gen-rdf for javazonetalk (BUG-17 …)», `OK`.
  Kontroll utan versjonslåst import: `gen-rdf (referansemodell)` → `OK`, med
  reell test.

**Står att etter push (steg 8):** Tørrkøyringa av release-please les config og
manifest frå `main` på GitHub, ikkje frå arbeidstreet. Køyrd før push viste ho
framleis `lunchregisteret` (37 forventa). Etter push skal
`release-please release-pr --dry-run` (kommando i steg 9.3 i
`specs/done/ci-etter-origin-flytting-audunautomat.md`) vise 36 komponentar, ingen
omtale av `lunchregisteret` og `Would open 0 pull requests`.
