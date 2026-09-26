---
name: make-conventions
description: Batching- og wrapper-target-mønster for make/*.mk-generatorar, src/assets/scripts/** og mkdocs/lib/scripts/**, orkestratorar som startar containerar (verten, ikkje PYTHON_RUN), pluss peikar til "ingen stille feil"-prinsippet. Lastast automatisk ved arbeid med filer under make/, src/assets/scripts/ eller mkdocs/lib/scripts/.
paths:
  - "make/**"
  - "src/assets/scripts/**"
  - "mkdocs/lib/scripts/**"
---

## Ingen stille feil

Sjå CLAUDE.md § "Ingen stille feil" for full regel: aldri `> /dev/null 2>&1`
rundt ein kommando som kan feile — bruk `run_logged "<label>" <kommando>` frå
`LOG_FUNCTIONS` (`make/00-settings.mk`). I Python: bruk
`error_handler.log_error()` for uventa unntak, og skriv alltid ei linje til
stderr ved bevisste, mjuke fallback-verdiar.

## Batching vs. parallellisering

To ulike mekanismar — ikkje forveksle:

- **Batching** styrer kor mange **kontainarar** som startast i det heile —
  fleire kommandoar samlar N skjema inn i **éin** `podman run`-prosess i
  staden for éin per skjema (t.d. `batch-generate.py --generator <format>`,
  `batch-lint.py`). Gevinsten er størst for `linkml`-baserte kommandoar, der
  import av `linkml`/`linkml_runtime` (~5-8 s) elles vert betalt på nytt for
  kvart einaste skjema uavhengig av kor lite arbeid sjølve kallet gjer.
- **Parallellisering** styrer kor mange skjema som køyrer **samstundes**
  (fleire prosessar) — handtert av `run-domain-pipeline.sh` for
  `domain-*`-targeta (fase-parallellisering), ikkje eit brukarstyrt jobb-tal.

Sjekk "Batching"-kolonna i `COMMANDS.md` for mekanismen til eit gitt
`gen-*`/`validate-*`-target før du legg til eit nytt.

## Wrapper-target-mønster

Nokre target gjer ikkje arbeidet sjølv, men **delegerer** via eit rekursivt
`$(MAKE) <target>`-kall i oppskrifta — usynleg i `make help`-output. Tre
variantar, ikkje forveksle:

1. **Reelle wrapper-target** — delegerer heile jobben til eit internt target.
   T.d. `mcp-linkml-valider-modell` → `_mcp-valider-modell-with-header`
   (POLICY-deteksjon frå `build.yaml`), `gource-preview`/`gource-video` →
   `_gource-render` (delt render-oppskrift, ulike flagg), `new-modell` med
   `.json`-input → `roundtrip-json-schema` (sjølvverifisering etter
   generering).
2. **"Bygg image berre viss det manglar"-vakt** — same `$(MAKE)`-mønster
   brukt for lat biletbygging: `podman image exists ... || $(MAKE)
   build-docker-*`. **Kontrasterande mønster:** fleire smoke-/test-/
   gource-target listar i staden `build-docker-*` som ein vanleg
   Make-prerequisite (`target: build-docker-x`) — sidan `build-docker-*` er
   `.PHONY`, byggjer desse biletet **på nytt kvar gong** dei køyrer. Vel
   medvite mellom desse to mønstra når du legg til eit nytt target som er
   avhengig av eit container-image — ikkje berre av stil.
3. **Konseptuelle wrapparar** (ikkje `$(MAKE)`-kall) — t.d.
   `validate-informasjonsmodell-instance`/`validate-modellkatalog-instance`
   vert omtala som "convenience wrapper" for `validate-instance`, men kallar
   **ikkje** `make validate-instance` via `$(MAKE)`. Dei gjenbruker same
   underliggande `linkml validate`-logikk direkte, med SCHEMA/INSTANCE-stiar
   auto-utleia frå høvesvis `SCHEMA=`/`ORG=`.

Full referanse med alle target-namn og grunngjeving: `COMMANDS.md` §§
"Logging", "Batching" og "Wrapper-target".

## Orkestratorar som startar containerar skal ikkje køyre i `$(PYTHON_RUN)`

`$(PYTHON_RUN)` (python-pytest-imaget) og `$(LINKML_RUN)` inneheld verken
`podman` eller `bash`. Eit Python-skript som sjølv startar containerar, direkte
(`podman run`) eller via eit shell-skript (`subprocess.run(["bash", …])` →
`podman run`), feilar difor med `FileNotFoundError` når det køyrer inne i ein
av dei. Feilen kjem berre fram ved faktisk køyring: syntaks- og importkontrollar
går gjennom.

**Aldri** flytt eit slikt orkestreringsskript inn i `$(PYTHON_RUN)`/`$(LINKML_RUN)`
berre for å fjerne eit verts-`python3`-kall, heller ikkje som del av ei
generell containerisering av Python-kall.

Gjer i staden slik:

1. Før du endrar kor eit Python-skript køyrer: grep skriptet (og shell-skripta
   det kallar) etter `podman`, `docker`, `bash` og `subprocess`. Treff tyder på
   at skriptet er ein orkestrator.
2. Ein orkestrator køyrer **på verten** (`python3 …` direkte i
   make-oppskrifta) og skal berre bruke **stdlib**, slik at han ikkje krev
   pakkar i verts-Python. Mønster: `src/mcp-linkml-validator/batch-flatten-and-validate.py`
   i `validate-data`/`validate-capture` (`make/40-validation.mk`).
3. Arbeid som treng tredjepartspakkar (PyYAML, linkml), skal skiljast ut i eit
   eige steg som køyrer i `$(PYTHON_RUN)`/`$(LINKML_RUN)` (t.d.
   `save-validation-log.py` per resultat). Det skal ikkje liggje i orkestratoren.
4. Verifiser alltid ei endring av køyremiljø med **ei faktisk køyring** av
   targetet, ikkje berre `py_compile`/`--help`.

**Grunngjeving:** `run-schema-validation.py` startar validator-containeren via
`flatten-and-validate.bash`/`batch-flatten-and-validate.py`. Han vart flytta inn i
`$(PYTHON_RUN)` i `a1833a2d` (2026-07-30), sjølv om kartlegginga i
`specs/done/containerisering-python-kall.md` §12 åtvara om nett dette («krev
teknisk verifikasjon»). Begge modusane av `make validate-capture` feila deretter i
om lag 8 veker utan at nokon merka det. Sjå F3 i
`specs/done/validate-capture-utan-schema.md`.
