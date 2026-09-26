# `make validate-capture` utan `SCHEMA` er broten

## Bakgrunn

Funne som K4 under `specs/done/fjern-update-modellkatalog.md` (2026-09-26).
`make validate-capture` har to modusar (`make/40-validation.mk:210–216`):

| Modus | Kall | Status |
|---|---|---|
| `make validate-capture SCHEMA=<sti>` | `run-schema-validation.py --schema <sti>` | ikkje del av dette funnet |
| `make validate-capture` | `run-schema-validation.py` (utan argument) | **broten** |

Modusen utan `SCHEMA` feilar i dag med:

```
FEIL: kunne ikkje lese release-please-config.json: [Errno 2] No such file or directory: 'release-please-config.json'
make: *** [make/40-validation.mk:213: validate-capture] Error 1
```

Kommentaren i `make/40-validation.mk:195–209` seier at modusen er eit
«manuelt batch-verktøy … ikkje brukt frå CI».

## Kartlegging (2026-09-26)

### To uavhengige feil

**F1: Utdatert config-sti (synleg feil).**
`run-schema-validation.py --config` har standardverdien
`release-please-config.json` i rota. Fila vart flytta til
`.github/release-please-config.json` i `1f76478d` (2026-07-28, «rydd
prosjekt-root»), same flytting som gav K1/K2 i
`specs/done/fjern-update-modellkatalog.md`.

**F2: `extra-files` finst ikkje lenger (stille feil, eldre).** For kvar
releasa pakke les skriptet skjemastien frå
`config["packages"][pkg]["extra-files"][0]["path"]`
(`run-schema-validation.py:~194–203`) og hoppar over pakken med `continue`
utan melding viss feltet manglar. **Ingen** av dei 37 pakkane i
`.github/release-please-config.json` har `extra-files`. Feltet vart fjerna i
`1d20298b` (2026-07-04, «synk schema-versjon med release-nummer
automatisk»), då versjonssynkroniseringa vart flytta til
`update-schema-dates.py`. Sidan 2026-07-04 har modusen difor ende i «Ingen
skjema å validere.» (stdout, exit 0), altså ein stille no-op.

**F3: Heile skriptet køyrer i feil container (synleg feil, funne under
steg 2 den 2026-09-26).** Baseline av `SCHEMA`-modusen feila:

```
FileNotFoundError: [Errno 2] No such file or directory: 'bash'
make: *** [make/40-validation.mk:213: validate-capture] Error 1
```

`make/40-validation.mk` køyrer `run-schema-validation.py` i `$(PYTHON_RUN)`
(python-pytest-imaget). Men skriptet er ein **orkestrator** som sjølv må
starte validator-containeren: `process_schema()` kallar `bash
flatten-and-validate.bash` (→ `podman run`), og `process_schemas_batch()`
kallar `python3 batch-flatten-and-validate.py` (→ `podman run`). Inne i
`PYTHON_RUN` finst verken `bash` eller `podman`. Skriptet vart flytta inn i
containeren i `a1833a2d` (2026-07-30, «containeriser alle Python-kall»), sjølv om
`specs/done/containerisering-python-kall.md` §12 åtvara: «Dersom
`run-schema-validation.py` sjølv startar Podman-containerar, må du vurdere om
… dette scriptet framleis bør køyre på hosten. … krev teknisk verifikasjon.»
**Begge modusane (med og utan `SCHEMA`) har difor vore brotne sidan
2026-07-30.** Påstanden i Bakgrunn om at `SCHEMA`-modusen ikkje er del av
funnet, er feil.

**Fungerande mønster i repoet (`validate-data`, `make/40-validation.mk:~55–100`):**
1. Shell byggjer `jobs.tsv` (skjema, policy frå `build.yaml` via `grep`,
   datafil).
2. `python3 src/mcp-linkml-validator/batch-flatten-and-validate.py` køyrer **på
   verten**. Han brukar berre stdlib og startar `podman` sjølv (éin container).
3. For kvart resultat: `$(PYTHON_RUN) python3 …/save-validation-log.py
   --schema … --type … --result …` (i container, PyYAML).

`save-validation-log.py --type <policy>` skriv til
`src/linkml/<domain>/<modell>/validation/<versjon>/<policy>.json` med same
`utils.validation_log`-funksjonar som `run-schema-validation.py`. Formatet er
identisk.

### Tidslinje

| Dato | Commit | Konsekvens for modusen utan `SCHEMA` |
|---|---|---|
| 2026-07-04 | `1d20298b` | `extra-files` fjerna → 0 skjema, exit 0 (stille) |
| 2026-07-28 | `1f76478d` | config flytta → `FEIL`, exit 1 (synleg) |
| 2026-07-30 | `a1833a2d` | `run-schema-validation.py` flytta inn i `PYTHON_RUN` → **begge** modusane feilar (`bash`/`podman` finst ikkje) |
| 2026-08-10 | `94235607` | «batch validate-capture»: batching lagt til på ein kodeveg som alt sidan 07-04 aldri fann skjema |

Modusen har altså ikkje validert eitt einaste skjema på om lag 12 veker utan at
nokon har merka det. Det tyder sterkt på at han ikkje er i bruk.

### Sprik mellom dokumentasjon og åtferd

| Stad | Seier | Faktisk (når F1/F2 er retta) |
|---|---|---|
| `COMMANDS.md:172`, `mkdocs/docs/kom-i-gang/kommandoar.md:49` | «Generer valideringsresultat for **alle skjema**» | berre pakkar der versjonen i manifestet er endra mellom `HEAD~1` og `HEAD` (`utils/release_helpers.find_released_packages`) |
| `COMMANDS.md:172` | «Ikkje batcha — parallellisert (`--parallel`, ThreadPool)» | batcha til éin container sidan `94235607`. `--parallel` er fjerna |
| `make/40-validation.mk:198–199` | «avgrensa til release-please-config.json sine "released packages"» | stemmer med koden, men ikkje med `COMMANDS.md` |

### Gjenbrukbar byggjekloss

`src/assets/scripts/update-schema-dates.py:26` `resolve_schema_path(pkg_path)`
utleier `<pkg_path>/<basename>-schema.yaml`. Det er same konvensjon som
`release-please.yml` brukar via `--print-schema-path` for artefakt- og
tag-stega. Han kan erstatte `extra-files`-oppslaget.

## Alternativ

| | Kva | For | Mot |
|---|---|---|---|
| **A** | **Reparer som «releasa pakkar»:** `--config` → `.github/release-please-config.json`, skjemasti via `resolve_schema_path` (flytta til `utils/release_helpers.py`, delt med `update-schema-dates.py`), stderr-melding når ein releasa pakke manglar skjema. `COMMANDS.md`/`kommandoar.md` retta til «releasa pakkar (HEAD~1→HEAD)», og `--parallel`-teksten fjerna | Held på det make-kommentaren seier er føremålet | Held liv i ein modus ingen har brukt på 12 veker. «Releasa mellom HEAD~1 og HEAD» er lite nyttig lokalt (avheng av kva commit som tilfeldigvis er HEAD~1) |
| **B** | **Omdefiner til «alle skjema»**, slik dokumentasjonen seier: iterer alle `*-schema.yaml` med `validation_policy` i `build.yaml`, batcha | Samsvarar med dokumentasjonen, og er nyttig som lokal fullvalidering med logging | Overlappar med `validate-policy-logg`/`validate-instance-logg` (CI-kritiske) og med CI-jobbane som alt skriv `validation/`-loggar. Ny semantikk for eit verktøy utan kjende brukarar |
| **C** | **Fjern modusen utan `SCHEMA`:** `validate-capture` krev `SCHEMA=` (feilar med tydeleg melding elles). Fjern `find_released_packages`-/`--config`-grenene i `run-schema-validation.py`. `utils/release_helpers.py` vert fjerna dersom han ikkje har andre brukarar | Minst kode. Fjernar ein kodeveg som har vore broten i 12 veker. Ingen overlapp | `make validate-capture` utan argument forsvinn. Den som vil validere mange skjema, brukar `validate-policy-logg` eller CI |

`release_helpers.find_released_packages` har i dag berre éin brukar
(`run-schema-validation.py`), så C fjernar òg K2-rettinga frå
`fjern-update-modellkatalog`. Det er greitt, fordi rettinga då ikkje lenger har
nokon funksjon.

## Avgjort alternativ: B

**Brukaren valde B (2026-09-26):** `make validate-capture` utan `SCHEMA` skal
validere **alle skjema**, slik `COMMANDS.md` og `kommandoar.md` alt seier.
Semantikken «releasa pakkar» (release-please-config/-manifest) vert fjerna.
Tilrådinga i kartlegginga var C. Grunngjevinga for B er at dokumentasjonen
alltid har lova «alle skjema», og at ei lokal fullvalidering med logging til
`validation/` er nyttig. Overlappen med `validate-policy-logg` og CI er kjend og
akseptert.

### Design

- **Skjemaoppdaging:** Make-targetet sender `$(call get_target_schemas)`
  (`make/02-schema-discovery.mk`) til skriptet, same mekanisme som `validate`,
  `lint` og `check-import-duplicates`. Då følgjer òg `DOMAIN=<domene>` med
  gratis: ingen argument gir alle 47 skjema, `DOMAIN=` gir eitt domene, og
  `SCHEMA=` gir eitt skjema. Skriptet treng ikkje lenger vite noko om
  release-please.
- **Køyring:** Fleire skjema går til den eksisterande
  `process_schemas_batch()` (éin delt `mcp-linkml-validator`-container,
  `batch-flatten-and-validate.py`). Eitt skjema går til den eksisterande
  `process_schema()` (direkte `flatten-and-validate.bash`), som i dag.
- **Policy per skjema:** uendra, `utils.schema_meta.detect_policy()`
  (`validation_policy` i `build.yaml`, elles `bronze`).
- **Fjernast:** `--config`, `find_released_packages`-kallet og
  `extra-files`-oppslaget i `run-schema-validation.py`. Deretter har
  `utils/release_helpers.py` ingen kallarar (`grep` 2026-09-26: berre
  `run-schema-validation.py:23`) og vert sletta. Det same gjeld tilvisinga i
  cache-kommentaren i `.github/workflows/generate.yml:434`.

### Konsekvensar å vere klar over

- `make validate-capture` utan argument skriv valideringsloggar for **alle 47
  skjema** til `src/linkml/<domain>/<modell>/validation/<versjon>/<policy>.json`
  (104 tracka filer i dag). Diffen etter ei køyring skal vurderast etter rula
  «Committa genererte filer» i `.claude/rules/linkml-schema.md`: forventa
  omfang er berre `validation/**/*.json`.
- Køyretida aukar frå «0 skjema» til alle 47 i éin container. Det er akseptabelt
  for eit manuelt verktøy. `DOMAIN=` gir avgrensing.

## Steg (B)

1. **Baseline av `SCHEMA`-modusen:**
   `make validate-capture SCHEMA=src/linkml/referanse/referansemodell/referansemodell-schema.yaml`.
   Noter resultatet og diffen i `validation/`, og set fila tilbake viss ho ikkje
   skal committast.
2. **`make/40-validation.mk`:**
   - Grena utan `SCHEMA` kallar `run-schema-validation.py --schemas $(call get_target_schemas)`
     (eller posisjonelle argument). `SCHEMA`-grena kan samlast i same kall,
     sidan `get_target_schemas` alt returnerer éitt skjema når `SCHEMA` er sett.
   - Hjelpetekst: `## MCP-validering med logging til validation/ [DOMAIN=<domene>|SCHEMA=<sti>]`.
   - Header: `(alle skjema, batcha)` / `DOMAIN=…` / `SCHEMA=…`.
   - Kommentaren `:195–209`: byt «avgrensa til release-please-config.json sine
     "released packages"» med «alle skjema (eller DOMAIN/SCHEMA), batcha».
     Overlapp-merknaden mot `validate-policy-logg` vert ståande.
3. **`run-schema-validation.py`:**
   - Nytt argument for skjemaliste. 1 skjema → `process_schema()`, fleire →
     `process_schemas_batch()`. Tom liste → feilmelding til stderr og exit 1
     (ingen stille no-op).
   - Ikkje-eksisterande sti i lista → `FEIL` til stderr og exit 1, som
     `--schema` alt gjer.
   - Fjern `--config`, `import json` (viss ubrukt), `find_released_packages`
     og `extra-files`-grena. Oppdater docstringen («Køyrer valideringssteget
     for kvart releasja skjema» → «for dei gitte skjemaa»).
   - Fjern `--schema` (O3 = nei). Skjemalista er einaste inngang, og
     `SCHEMA=` i make gir ei liste med eitt element.
4. **`utils/release_helpers.py`:** slett (0 kallarar etter steg 3). Fjern
   `release_helpers.py` frå kommentaren i `.github/workflows/generate.yml:434`,
   og køyr `actionlint` på fila.
5. **Dokumentasjon:**
   - `COMMANDS.md:106,172–173` og `mkdocs/docs/kom-i-gang/kommandoar.md:49–50`:
     «alle skjema» stemmer no. Legg til `DOMAIN=`-varianten. Byt «Ikkje batcha
     — parallellisert (`--parallel`, ThreadPool)» med «Batcha — éin
     `mcp-linkml-validator`-container for alle skjema».
   - `make/README.md:42`: uendra funksjon, sjekk ordlyden.
6. **Verifiser:**
   - `make validate-capture SCHEMA=…` → same resultat som baseline (steg 1)
   - `make validate-capture DOMAIN=referanse` → batcha køyring av dei 4
     referanse-skjemaa. Diff berre i deira `validation/`
   - `make validate-capture` → alle 47 skjema. Diffen vert vurdert etter rula
     «Committa genererte filer», og brukaren avgjer om loggane skal committast
   - `make help` viser oppdatert hjelpetekst
   - `make analyse-container-copy-konsistens` → ingen avvik (etter at
     `release_helpers.py` er sletta)
   - `grep -rn 'release_helpers\|find_released_packages\|extra-files' --exclude-dir=specs .` → 0 treff

## Handlingsliste

- [x] 1. Avgjer alternativ (O1 = B, O2 = alle skjema)
- [x] 2. Baseline av `SCHEMA`-modusen → avdekte F3 (broten sidan 2026-07-30)
- [x] 3. `make/40-validation.mk`: `validate-capture` skriven om etter `validate-data`-mønsteret (O4)
- [x] 4. `run-schema-validation.py` **sletta** (erstatta av make-oppskrifta, O4)
- [x] 5. `utils/release_helpers.py` sletta, kommentar i `generate.yml` oppdatert + actionlint
- [x] 6. Dokumentasjon (`COMMANDS.md`, `kommandoar.md`, `make/README.md`, header i `40-validation.mk`)
- [x] 7. Verifisering (SCHEMA, DOMAIN, alle, feilvegar, help, container-copy, grep)

## Opne spørsmål

- ~~**O1:** Alternativ A, B eller C?~~ **Avgjort 2026-09-26: B** (tilråding var C).
- ~~**O2:** Kva skal `make validate-capture` utan `SCHEMA` gjere?~~ **Avgjort
  2026-09-26: validere alle skjema** (følgjer av B).
- ~~**O4:** Korleis skal B realiserast når skriptet ikkje kan køyre i
  `PYTHON_RUN` (F3)?~~ **Avgjort 2026-09-26: `validate-data`-mønsteret**
  (brukaren valde tilrådinga). Make-oppskrifta byggjer `jobs.tsv`, køyrer
  `batch-flatten-and-validate.py` på verten og lagrar med
  `save-validation-log.py` i container. `run-schema-validation.py` vert sletta.
  Alternativet var å køyre skriptet på verten, men det krev PyYAML i
  verts-Python.
- ~~**O3:** Skal `--schema` behaldast ved sida av den nye skjemalista?~~
  **Avgjort 2026-09-26: nei** (brukaren godkjende tilrådinga). Make-targetet er einaste kallar
  (`grep`), og éi inngangsdør (lista, med éitt element for `SCHEMA=`) er enklast.

## Avgjerder

- Rule (brukar stadfesta 2026-09-26): F3-lærdommen er lagd til som seksjon
  «Orkestratorar som startar containerar skal ikkje køyre i `$(PYTHON_RUN)`»
  i `.claude/rules/make-conventions.md`, ikkje i `container-images.md` som
  først foreslått. `make-conventions.md` gjeld for `make/**` og
  `src/assets/scripts/**`, der feilen låg (`make/40-validation.mk`,
  `makefile/run-schema-validation.py`). `container-images.md` gjeld for ingen
  av dei.
- **O4 (brukaren, 2026-09-26): designendring undervegs.** Steg 2 (baseline)
  avdekte F3. Planen i «Steg (B)» om å tilpasse `run-schema-validation.py` var
  difor ikkje gjennomførbar som skildra: skriptet kan ikkje køyre i
  `PYTHON_RUN`. `validate-capture` er i staden skriven som rein make-oppskrift
  etter `validate-data`-mønsteret, og `run-schema-validation.py` er sletta. O3
  (fjern `--schema`) er dermed oppfylt, fordi heile skriptet er borte.
- Exit-semantikk: `validate-capture` er eit *capture*-verktøy, ikkje ein port.
  Ugyldige skjema vert viste (`log_info "⚠ Ugyldig …"`) og talde i eit
  samandrag, men gir exit 0, same som `run-schema-validation.py` gjorde.
  Infrastrukturfeil (ingen skjema, skjema finst ikkje, manglande
  batch-resultat, lagringsfeil i `save-validation-log.py`) gir `log_error` og
  exit ≠ 0 (ingen stille feil).
- `log_info` (ikkje `log_error`) for ugyldige skjema: eit policy-brot er eit
  valideringsresultat, ikkje ein verktøyfeil. Det er synleg ved standard
  `LOGLVL=INFO`. `LOG_FUNCTIONS` har ingen `log_warn`.
- Lagring skjer med éin `$(PYTHON_RUN) save-validation-log.py` per skjema (47
  containerstarter ved full køyring), same mønster som `validate-data`. Det er
  tregare enn éin Python-prosess, men akseptabelt for eit manuelt verktøy og
  konsistent med eksisterande kode.
- Policy-utlesinga frå `build.yaml` (`grep '^validation_policy:'`) finst no i
  to make-oppskrifter (`validate-data`, `validate-capture`). Det er under
  make-terskelen for DRY (3+).
- Testloggar frå verifiseringa er fjerna, og arbeidstreet under `validation/` er
  sett tilbake til HEAD (`git show HEAD:<fil> > <fil>` for den eine endra
  fila). Om loggane frå ei full køyring skal committast, avgjer brukaren, jf.
  «Konsekvensar å vere klar over».

- Specen er ei kartlegging med tilråding. Ingen kode er endra, og specen står i
  `specs/backlog/`.
- O3 = nei (brukaren, 2026-09-26): `--schema` vert fjerna. Éin inngang
  (skjemaliste) i `run-schema-validation.py`.
- O1 = B, O2 = alle skjema (brukaren, 2026-09-26). Designet brukar
  `get_target_schemas` frå `make/02-schema-discovery.mk` i staden for eiga
  skjemaoppdaging i Python. Då følgjer skjemautvalet same reglar som dei andre
  targeta (DRY), og `DOMAIN=` kjem med utan ekstra kode.
- Seksjonen «Tilråding» (C) er erstatta av «Avgjort alternativ: B». Tabellen
  over alternativ står att som grunnlag for valet.
- `SCHEMA`-modusen er ikkje testa under kartlegginga, fordi han skriv
  valideringsloggar til tracka filer. Han er lagt inn som baseline i steg 1.

## Utført

Gjennomført 2026-09-26 (O1 = B, O2 = alle skjema, O3 = nei, O4 = `validate-data`-mønsteret).

**Endringar:**
- `make/40-validation.mk`:
  - `validate-capture` er skriven om. Oppskrifta tek skjema frå
    `$(call get_target_schemas)` (alle / `DOMAIN=` / `SCHEMA=`) og policy frå
    `build.yaml` (elles `bronze`), byggjer `jobs.tsv`, køyrer
    `python3 src/mcp-linkml-validator/batch-flatten-and-validate.py` på verten
    (éin container), og lagrar per resultat med `$(PYTHON_RUN)
    save-validation-log.py --type <policy>`. Samandraget viser gyldige og ugyldige.
  - Hjelpetekst `[DOMAIN=<domene>|SCHEMA=<sti>]`. Header og kommentar er
    oppdaterte, og `run-schema-validation.py` er fjerna frå «Relaterte script».
- `src/assets/scripts/makefile/run-schema-validation.py`: **sletta**.
- `src/assets/scripts/utils/release_helpers.py`: **sletta** (0 kallarar).
- `.github/workflows/generate.yml`: cache-kommentaren nemner ikkje lenger dei to
  sletta filene. Nøkkelen er uendra (`makefile/**`, `utils/**`). actionlint: ingen
  funn utanom shellcheck.
- `COMMANDS.md`: `validate-capture`-radene seier no batcha, `DOMAIN=` og
  exit-semantikk, og «`--parallel`, ThreadPool» er fjerna.
  `mkdocs/docs/kom-i-gang/kommandoar.md`: `DOMAIN=`-rad. `make/README.md`: rada for
  `run-schema-validation.py` er fjerna.

**Verifisering:**

| Test | Resultat |
|---|---|
| `SCHEMA=…/referansemodell-schema.yaml` | exit 0. 1 skjema, 1 gyldig. Skreiv `validation/1.5.2/bronze.json`. Same nøkkelstruktur som eksisterande logg, pluss `_generated_by` (provenance-feltet frå `516262b9`) |
| `DOMAIN=referanse` | exit 0. 4 skjema, 4 gyldige. Rett policy per skjema (bronze/silver/gold) |
| utan argument | exit 0. **47 skjema, 27 gyldige, 20 ugyldige**. Diffen var berre under `validation/` (46 nye, 1 endra: `validated_at` + `_generated_by`) |
| `SCHEMA=<finst ikkje>` | `[ERROR] FEIL: … finst ikkje`, exit ≠ 0 |
| `DOMAIN=<finst ikkje>` | `[ERROR] FEIL: ingen skjema funne …`, exit ≠ 0 |
| `make help` | `validate-capture [DOMAIN=<domene>\|SCHEMA=<sti>]` |
| `make analyse-container-copy-konsistens` | «Ingen avvik funne» |
| `grep run-schema-validation\|release_helpers\|find_released_packages` (utan `specs/`) | 0 treff |

Testloggane er fjerna etterpå (sjå Avgjerder).

**Nytt funn, ikkje retta: K5.** `src/assets/scripts/add-schema-header-comments.py`
(manuelt eingongsverktøy frå `9d1695ef`, 2026-06-19, utan make-target eller
CI-kall) har dei same to feila som F1/F2: `--config`-standardverdi
`release-please-config.json` i rota, og skjemasti frå `extra-files`, som ikkje
finst lenger. Køyrd i dag feilar han på config-stien, og med rett sti ville han
gjort ingenting utan å seie frå. Tilråding: vurder å slette han (eingongsjobben
er gjort) eller byte til `update-schema-dates.resolve_schema_path`, i eigen
spec.
