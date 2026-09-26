# Evaluering: kan `update-modellkatalog.py` slettast?

## Bakgrunn

`src/assets/scripts/makefile/update-modellkatalog.py` vart erstatta av
`generate-modellkatalog.py` (`make gen-modellkatalog-instance`) som verktøy
for å synkronisere modellkatalogar. Make-targetet `update-modellkatalog` vart
fjerna i `specs/done/make-target-namn-vs-funksjon.md` (Funn 5). Under arbeidet
med `specs/done/informasjonsmodellidentifikator-ny-eigar.md` vart fila
observert som «ubrukt» (O2 der). Denne specen evaluerer om ho kan slettast,
og kva som i så fall må ryddast.

## Kartlegging (2026-09-26)

### Fila er ikkje ubrukt: ho er eit bibliotek

`gen-modelldcat-elements.py` (make-target `gen-modelldcat-elements`,
`Makefile:182`) importerer fila dynamisk med
`importlib.util.spec_from_file_location` (`gen-modelldcat-elements.py:50–63`) og
brukar desse symbola:

| Symbol | Brukt i `gen-modelldcat-elements.py` |
|---|---|
| `CODEOWNERS_PATH` | `--codeowners`-standardverdi (:334) |
| `load_org_registry` | :343 |
| `load_release_manifest` | :348 |
| `load_annotated_schemas` | :348 |
| `group_schemas_by_org` | :349 |
| `find_catalog_data` | :273 |
| `entry_name` | :289 |

Desse symbola er avhengige av konstantane `CATALOG_DATA_TEMPLATE`,
`EXCLUDED_DOMAINS` og `RELEASE_MANIFEST_PATH`, og av `utils/codeowners.py`.

Dette er grunnen til at fila vart **gjenoppretta** etter at ho vart sletta i
Funn 5 (sjå «avvik frå planen» i `specs/done/make-target-namn-vs-funksjon.md`).
Docstringen i fila seier det same: «IKKJE slett henne utan å flytte den delte
logikken til ein eigen utils-modul først».

### Resten av fila er død kode

| Del | Linjer (ca.) | Brukt av |
|---|---|---|
| `PORTAL_BASE`, `ANNOTATION_FIELD_MAP` | 40, 47–53 | berre `update_entry`/`make_stub` |
| `update_entry`, `make_stub`, `process_org`, `main` + `argparse`-CLI | 150–303 | ingen: ingen make-target, ingen CI, ingen test, ingen annan import |

Om lag halve fila (~150 av 303 linjer) er CLI-logikk som ingen kallar lenger.
`PORTAL_BASE` vart likevel oppdatert under flyttinga til `AudunAutomat` (steg 5 i
`specs/done/ci-etter-origin-flytting-audunautomat.md`). Det er eit døme på at død
kode kostar vedlikehald.

### Andre avhengigheiter: ingen

- Ingen make-target, `.github/workflows/*`, `tests/` eller `bootstrap.sh`
  kallar fila.
- Ingen `Dockerfile*` `COPY` eller sparse-checkout i `reusable-*.yml`
  inkluderer ho. Make-script køyrer i container med heile repoet montert
  (`/work`).
- `gen-modelldcat-elements` vert berre køyrd manuelt, ikkje i CI.

### Funn under kartlegginga

**K1: Stille feil i `load_release_manifest`.**
`RELEASE_MANIFEST_PATH = ".release-please-manifest.json"` peikar på rot-stien.
Manifestet vart flytta til `.github/release-please-manifest.json` i `1f76478d`
(2026-07-28). `load_release_manifest()` returnerer `{}` **utan melding** når fila
manglar, og det bryt «Ingen stille feil» i CLAUDE.md.
`load_annotated_schemas()` fell då tilbake til `schema.version`, som docstringen
kallar «upålitelig». Verknaden i dag er ingen: `schema.version` og manifestet
er like for alle 36 komponentar, fordi `update-schema-dates.py` held dei
synkrone. Feilen er difor latent, men reell.

**K2: Same utdaterte manifest-sti andre stader.**

| Fil | Verknad |
|---|---|
| `src/assets/scripts/utils/release_helpers.py:14,23` (`find_released_packages`, brukt av `run-schema-validation.py`) | Feilar synleg (`FEIL:`/`INFO:` til stderr) og behandlar alle pakkar som nye |
| `CONTRIBUTING.md:111` | Døme-kommando `jq … .release-please-manifest.json` feilar |
| `mkdocs/docs/automasjon/monitorering.md:89,95,107` | Same døme og tekst i portalen |

**K3: Tredje CODEOWNERS-parsar.** `generate-modellkatalog.py:35–73`
(`load_codeowners()`) parsar ` ```yaml `-blokka i `CODEOWNERS.md` sjølv i
staden for å bruke `utils/codeowners.py`. Det strir mot
`.claude/rules/codeowners-format.md` («Nye script … skal ikkje implementere
eiga parsing»). Han verkar i dag, men er same type duplisering som førte til
BUG-16.

## Vurdering

**Ja, fila kan slettast, men ikkje direkte.** Dei 7 delte symbola må flyttast
til ein utils-modul først, elles bryt `make gen-modelldcat-elements`. Det er nett
den feilen som skjedde i Funn 5. Deretter er resten død kode og kan slettast
utan andre konsekvensar.

Tilrådd mål: `src/assets/scripts/utils/modellkatalog.py`, same mønster som
`utils/codeowners.py` og `utils/release_helpers.py`. `gen-modelldcat-elements.py`
får då ein vanleg import (`sys.path` til `src/assets/scripts`, slik
`update-modellkatalog.py` alt gjer for `utils.codeowners`) i staden for
`importlib`-kunsten.

## Filer som skal ryddast

| Fil | Endring | Kategori |
|---|---|---|
| `src/assets/scripts/utils/modellkatalog.py` | **ny**: `CODEOWNERS_PATH`, `CATALOG_DATA_TEMPLATE`, `EXCLUDED_DOMAINS`, `RELEASE_MANIFEST_PATH`, `load_org_registry`, `load_release_manifest`, `load_annotated_schemas`, `group_schemas_by_org`, `find_catalog_data`, `entry_name` (uendra logikk, bortsett frå K1 om O2 = ja) | kode |
| `src/assets/scripts/makefile/update-modellkatalog.py` | **slett** | kode |
| `src/assets/scripts/makefile/gen-modelldcat-elements.py` | erstatt `importlib`-blokka (:50–63) med `from utils.modellkatalog import …`. Header-tekst :322 «Delvis generert av update-modellkatalog.py / gen-modelldcat-elements.py» → «… av gen-modelldcat-elements.py» | kode |
| `src/assets/scripts/makefile/generate-modellkatalog.py` | kommentarane :8 («erstatter update-modellkatalog.py») og :302 («sjå update-modellkatalog.py») vert oppdaterte eller fjerna | kommentar |
| `specs/backlog/del-opp-ap-no-profilar-i-moduler.md` | :422, :474 og :902 viser til `update-modellkatalog.py:86/94`. Oppdater til `utils/modellkatalog.py` med nye linjenummer | backlog-spec |
| `mkdocs/docs/kom-i-gang/ny-org.md:85–` | `!!! warning "Endra frå update-modellkatalog til gen-modellkatalog-instance"`. Overgangsmerknad frå 2026-08 (O3) | portal |
| `.claude/rules/codeowners-format.md:26` | nemner `update-modellkatalog.py::load_org_registry()` som historisk døme på BUG-16. Behald, med merknad «(funksjonen ligg no i `utils/modellkatalog.py`)» | rule |
| `BUGS.md` (BUG-16-rada), `bugs/codeowners-frontmatter-format-mismatch.md` | historikk for ein **løyst** bug. Behald teksten, og legg ev. til éi linje om at komponenten er flytta | bug-historikk |
| `specs/done/**` (~20 filer) | **ikkje rør** (arkiv, jf. CLAUDE.md) | – |

Ingen genererte datafiler inneheld i dag header-teksten frå
`gen-modelldcat-elements.py` :322 (`grep` i `src/linkml/` gir 0 treff), så
regenerering er ikkje naudsynt.

## Steg

1. **Baseline:** `make gen-modelldcat-elements DRYRUN=1` for alle org-ar før
   endringa. Ta vare på utdata.
2. **Flytt delte symbol** til `utils/modellkatalog.py` (uendra logikk, eller med
   K1-fiksen dersom O2 = ja).
3. **Oppdater `gen-modelldcat-elements.py`** til vanleg import. Oppdater header-tekst.
4. **Slett `update-modellkatalog.py`.**
5. **Oppdater kommentarar og dokumentasjon** jf. tabellen over (O3 avgjer `ny-org.md`).
6. **Verifiser:**
   - `make gen-modelldcat-elements DRYRUN=1` gir same utdata som baseline
     (med O2 = ja: eventuelle skilnader berre i `versjonsnummer`, og i dag er det
     venta 0).
   - `grep -rn 'update-modellkatalog\|update_modellkatalog' --exclude-dir=specs .`
     gir berre historiske treff i `BUGS.md`/`bugs/`/rule (bevisst behaldne).
   - `make analyse-container-copy-konsistens` (ny utils-modul, jf.
     `.claude/rules/container-images.md`).
7. **Valfritt (O1):** K3, der `generate-modellkatalog.py` brukar
   `utils.codeowners.load_codeowners()` (eller `utils/modellkatalog.load_org_registry`)
   i staden for eigen parsar. Verifiser med `make gen-modellkatalog-instance`,
   og følg rula «Committa genererte filer» i `.claude/rules/linkml-schema.md`
   for diffen.
8. **Valfritt (O4):** K2, det vil seie å rette `.release-please-manifest.json` →
   `.github/release-please-manifest.json` i `release_helpers.py`,
   `CONTRIBUTING.md` og `monitorering.md`.

## Handlingsliste

- [x] 1. Baseline-dry-run av `gen-modelldcat-elements`
- [x] 2. Ny `utils/modellkatalog.py` med dei 7 delte symbola og konstantane
- [x] 3. `gen-modelldcat-elements.py`: vanleg import og header-tekst
- [x] 4. Slett `update-modellkatalog.py`
- [x] 5. Kommentarar/dokumentasjon/backlog-spec/rule oppdaterte
- [x] 6. Verifiser (dry-run-diff, grep, container-copy-analyse)
- [x] 7. (O1) K3: `generate-modellkatalog.py` på delt CODEOWNERS-parsar
- [x] 8. (O4) K2: rett manifest-sti i `release_helpers.py` og dokumentasjon

## Opne spørsmål

- ~~**O1:**~~ **Godkjent (ja) 2026-09-26.** Skal K3 (tredje CODEOWNERS-parsar i `generate-modellkatalog.py`) tas
  med her? Tilråding: **ja**. Han er nabokode til det som vert flytta, og same
  modul (`utils/modellkatalog.load_org_registry`) kan dekkje behovet.
- ~~**O2:**~~ **Godkjent (ja) 2026-09-26.** Skal K1 (feil manifest-sti og stille `{}` i `load_release_manifest`)
  rettast når funksjonen vert flytta? Tilråding: **ja**. Det er éi linje for
  stien og éi stderr-linje ved manglande fil. Det er venta 0 endringar i utdata
  i dag (0 avvik mellom `schema.version` og manifest).
- ~~**O3:**~~ **Godkjent (ja) 2026-09-26.** Skal overgangsmerknaden i `mkdocs/docs/kom-i-gang/ny-org.md` fjernast?
  Tilråding: **ja**. Kommandoen har vore borte sidan 2026-08, og merknaden
  nemner ein kommando som ikkje finst.
- ~~**O4:**~~ **Godkjent (ja) 2026-09-26.** Skal K2 (same utdaterte sti i `release_helpers.py`, `CONTRIBUTING.md`,
  `monitorering.md`) rettast her eller i eigen spec? Tilråding: **her**, som
  eige steg. Det er same rotårsak (flyttinga i `1f76478d`), og éin
  `release_helpers.py`-feil påverkar `run-schema-validation.py`.

## Avgjerder

- O1–O4 godkjende av brukaren 2026-09-26.
- O3: Overgangsmerknaden i `ny-org.md` er erstatta med ein kort `!!! note`, ikkje
  fjerna heilt. Merknaden nemner ikkje lenger den fjerna kommandoen, men tek vare
  på det som framleis gjeld (heile fila vert regenerert, ingen `TODO`-stubs,
  `aktoerer`/`kvalitetsmaalingar` vert bevarte, kontroller diffen).
- K3: `import yaml` i `generate-modellkatalog.py` vart ubrukt då den lokale
  parsaren forsvann, og er fjerna (CodeQL flaggar ubrukte importar).
- `BUGS.md` (BUG-16-rada) er uendra. Tittelen skildrar den historiske feilen.
  Merknaden om flyttinga ligg i bug-fila (`**Komponent:**`) og i
  `codeowners-format.md`.
- K4 (nytt funn under K2, sjå Utført) er **ikkje** retta. Det ligg utanfor O4
  («same utdaterte manifest-sti»). Berre å rette config-stien ville gjort ein
  synleg feil om til ein stille no-op, og det bryt «Ingen stille feil».

- Specen er ei evaluering. Ingen kode eller dokumentasjon er endra. Han står i
  `specs/backlog/` fram til tiltaka vert gjennomførte.
- Konklusjonen er «kan slettast etter flytting», ikkje «kan slettast no», fordi
  fila er eit aktivt bibliotek for `gen-modelldcat-elements.py`. Det er same
  felle som i Funn 5 i `specs/done/make-target-namn-vs-funksjon.md`.

## Utført

Gjennomført 2026-09-26 (O1–O4 = ja):

1. **Baseline:** `make gen-modelldcat-elements DRYRUN=1` → exit 0 (56 linjer utdata).
2. **`src/assets/scripts/utils/modellkatalog.py` (ny):** `CODEOWNERS_PATH`,
   `CATALOG_DATA_TEMPLATE`, `RELEASE_MANIFEST_PATH`, `EXCLUDED_DOMAINS` og dei
   6 funksjonane. AST-samanlikning mot originalen: 5 funksjonar identiske. Berre
   `load_release_manifest` er endra (K1/O2: sti `.github/release-please-manifest.json`
   og stderr-linje når fila manglar).
3. **`gen-modelldcat-elements.py`:** `importlib`-blokka er erstatta med
   `from utils.modellkatalog import …`, og header-teksten i skrivne katalogfiler er
   no «Delvis generert av gen-modelldcat-elements.py».
4. **`update-modellkatalog.py` sletta** (303 linjer, av dei ~150 død CLI-kode).
5. **Dokumentasjon:** `generate-modellkatalog.py`-docstring og -kommentar,
   `specs/backlog/del-opp-ap-no-profilar-i-moduler.md` (3 stader → `utils/modellkatalog.py:69/77`),
   `mkdocs/docs/kom-i-gang/ny-org.md` (O3), `.claude/rules/codeowners-format.md`
   (merknad), `bugs/codeowners-frontmatter-format-mismatch.md` (`Komponent`-merknad).
6. **Verifisering:**
   - `make gen-modelldcat-elements DRYRUN=1` etter endringa: **identisk** med
     baseline, og ingen `ÅTVARING` (manifestet vert no funne).
   - `make analyse-container-copy-konsistens` → «Ingen avvik funne».
   - `grep update-modellkatalog` utanom `specs/done/` gir berre bevisste
     historiske treff (BUG-16, codeowners-rula) og tilvisingar til denne specen.
7. **K3 (O1):** `generate-modellkatalog.py` brukar `utils.modellkatalog.load_org_registry()`.
   Den lokale `load_codeowners()` (40 linjer) og ubrukt `import yaml` er fjerna.
   Førehandskontroll: begge parsarane gav identisk resultat (6 org-ar).
   `make gen-modellkatalog-instance` gav **0 endringar** i katalogdata, som var
   forventa omfang jf. rula «Committa genererte filer».
8. **K2 (O4):** `utils/release_helpers.py` brukar konstanten
   `RELEASE_MANIFEST_PATH = ".github/release-please-manifest.json"` for både
   `HEAD~1` og arbeidstreet. `CONTRIBUTING.md` (1) og `monitorering.md` (3) er
   retta. `grep '\.release-please-manifest\.json'` utan `.github/`-prefiks gir 0
   treff utanom `specs/`.

**Nytt funn, ikkje retta: K4.** `make validate-capture` utan `SCHEMA` er
broten i dag: `run-schema-validation.py --config` har standardverdien
`release-please-config.json` i rota, men fila ligg i `.github/` (same
flytting, `1f76478d`). Køyringa feilar med `FEIL: kunne ikkje lese
release-please-config.json`. I tillegg har **ingen** av dei 37 pakkane i
config-en `extra-files`, som `run-schema-validation.py` brukar til å finne
skjemafila per releasa pakke. Å rette berre stien ville difor gi 0 skjema
utan melding. Tilråding: eigen spec eller bug som anten skriv om
skjema-oppslaget (t.d. `update-schema-dates.py --print-schema-path`, slik
`release-please.yml` gjer) eller fjernar modusen utan `SCHEMA` dersom han ikkje
er i bruk.
