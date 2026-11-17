---
name: make-conventions
description: Batching- og wrapper-target-mønster for make/*.mk-generatorar, src/assets/scripts/** og mkdocs/lib/scripts/**, orkestratorar som startar containerar (verten, ikkje PYTHON_RUN), synlegheit for nye target i make help, portabelt shell mellom macOS (BSD) og Linux (GNU), pluss peikar til "ingen stille feil"-prinsippet. Lastast automatisk ved arbeid med filer under make/, src/assets/scripts/, mkdocs/lib/, mkdocs/publish.sh, tests/*.sh eller Makefile.
paths:
  - "make/**"
  - "src/assets/scripts/**"
  - "mkdocs/lib/**"
  - "mkdocs/publish.sh"
  - "tests/**/*.sh"
  - "Makefile"
---

## Ingen stille feil

Sjå CLAUDE.md § "Ingen stille feil" for full regel: aldri `> /dev/null 2>&1`
rundt ein kommando som kan feile — bruk `run_logged "<label>" <kommando>` frå
`LOG_FUNCTIONS` (`make/00-settings.mk`). I Python: bruk
`error_handler.log_error()` for uventa unntak, og skriv alltid ei linje til
stderr ved bevisste, mjuke fallback-verdiar.

## Nye target skal vere synlege i `make help`

`src/assets/scripts/makefile/help.sh` les berre target der navnet samsvarer med
`[a-zA-Z_-]+`. Target med siffer i navnet vert difor **stille** utelatne, utan
åtvaring. Eit target som ikkje samsvarer med noko mønster i `categories`-lista
(der første treff vinn), havner i fallback-gruppa «Anna» nedst. Det er synleg,
men ligg på feil stad.

**Aldri** rekn eit nytt eller omdøypt target som ferdig berre fordi det har ein
`## `-hjelpetekst.

Gjer i staden slik:

1. Gje targetet eit navn utan siffer.
2. Sjekk at navnet samsvarer med eit eksisterande kategori-mønster i `help.sh`.
   Elles utvidar du mønsteret til den kategorien som passar
   (t.d. `(docs-|translate-)`).
3. Verifiser med `make help` at targetet syner under rett kategori og ikkje
   under «Anna».

**Grunngjeving:** `i18n-check`/`i18n-status`/`i18n-stamp` var aldri synlege i
`make help` på grunn av sifferet. Etter omdøypinga til `translate-*` vart dei
lesne inn, men forsvann framleis, til mønsteret for «Dokumentasjonsportal»
vart utvida. Sjå `specs/done/translate-make-targets.md`.

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

## Portabelt shell: macOS (BSD) og Linux (GNU)

macOS er offisielt støtta (krav og installasjon: `COMMANDS.md` § macOS og
`make check-prereqs`). macOS leverer BSD-verktøy, bash 3.2 og Apple make 3.81.
Script og make-oppskrifter skrivne mot GNU feilar der. Feilen syner seg ofte
langt frå årsaka (aritmetikkfeil, «Fil manglar», tapt `pipefail`) og vert aldri
fanga av WSL2/Ubuntu eller CI, som begge har GNU-verktøy.

**Aldri** bruk ein GNU-spesifikk konstruksjon i nytt eller endra script utan
portabelt alternativ:

| Konstruksjon | Problem på macOS | Portabelt alternativ |
|---|---|---|
| `cp -t <mål> …`, `mv -t` | `-t` finst berre i GNU | `find_cp_into` (`mkdocs/lib/copy_artifacts.sh`), eller `find … -exec sh -c 'd=$1; shift; cp "$@" "$d"' _ "$mål" {} +` |
| `sed -i 's/…/'` | BSD krev argument til `-i` | `sed -i.bak … && rm -f fil.bak` |
| `\L`, `\U`, `\E`, `sed -r`, `\+`/`\|` i sed | GNU-utvidingar | `perl -pi -e '…'` (`lc($1)` / `\L$1\E`) |
| `date +%s%N`, `%3N` | BSD skriv ein bokstavleg `N` | `now_ms` frå `LOG_FUNCTIONS` (monotonisk, jf. BUG-21) |
| `/proc/uptime`, `/proc/version` | finst ikkje | gard med `[ -r … ]` og ha ein macOS-gren (`now_ms` har ein) |
| `mktemp /sti/x_XXXXXX.log` | BSD erstattar berre `X` heilt sist, og gir ei bokstavleg fil | `mktemp_ext <prefiks> <suffiks>` (`tests/test_make.sh`) |
| `mktemp -d` utan mal | macOS les ikkje `TMPDIR` | `mktemp -d "${TMPDIR:-/tmp}/navn.XXXXXX"` |
| `df -BG`, `stat -c`, `readlink -f`, `date -d`, `xargs -r`, `grep -P`, `sort -V`, `find -printf`, `base64 -w` | GNU-flagg | POSIX-variant (`df -Pk`, `stat -f%z`-fallback, …) |
| `mapfile`/`readarray`, `declare -A`/`local -A`, `${v,,}`, `${v^^}`, `\|&` | bash 4+; `/bin/bash` er 3.2 | tillate i scripta som køyrer via `make` (bash >= 4 vert kravd og sjekka), **ikkje** i `check-prereqs.bash` og `tests/test_check_prereqs.sh`, som køyrer før Homebrew-bash er installert |
| `.SHELLFLAGS`, `.ONESHELL`, `$(file)`, `undefine`, `&:` i make | make 3.82+/4.x; `.SHELLFLAGS` vert ignorert på 3.81 utan feilmelding | macOS-brukarar har make >= 4 (sjekka), men sett `pipefail` i `SHELL` (`SHELL := … -o pipefail`), ikkje i `.SHELLFLAGS` |
| `python3` på verten som importerer ein tredjepartspakke (t.d. `yaml`) | pakken følgjer med Ubuntu, ikkje macOS | legg avhengigheita i `check-prereqs.bash`, eller køyr kallet i container |

**Framgangsmåte:**

1. Slå opp konstruksjonen i tabellen før du skriv han. Vel det portable alternativet.
2. Grep dei endra filene:
   `grep -nE 'cp (-[a-zA-Z]+ )*-t |sed -i( |$)|date \+[^ ]*%[0-9]*N|/proc/|mktemp [^|;]*X{3,}\.[a-z]+|mapfile|readarray|declare -A|df -B|stat -c|readlink -f|date -d|xargs -r|grep -P|sort -V'`.
   Kvart treff må rettast, eller grunngjevast (t.d. bash 4 i eit script som
   alltid køyrer under `make`).
3. Verifiser på macOS når du kan (`make test`; `make docs-publish` i ein
   sandkasse-kopi, jf. `mkdocs-portal.md`). Linux/CI-grøn seier ingenting om
   macOS. Kan du ikkje køyre på macOS, skriv det eksplisitt i rapporten.
4. `make test` på macOS med mange feil og `Error 137` frå `podman` tyder at
   Podman-VM-en er for liten (OOM-kill), ikkje at koden er feil. Sjekk
   `make check-prereqs` (åtvarar under 4 GiB) før du jaktar kodefeil.

Konkret tilfelle: fyrste `make test` på ein Mac stoppa på `date +%s%3N`
(«value too great for base») og `mktemp …_XXXXXX.log` («File exists»). Etter
retting avdekte `make test`/`domain-*`/`docs-publish` òg `/proc/uptime` i
`now_ms`, `cp -t`/`sed -i`/`\L` i `copy_artifacks.sh` og `.SHELLFLAGS` (tapt
`pipefail` på make 3.81). Sjå `specs/done/check-prereqs-macos.md` (F10-F14).
