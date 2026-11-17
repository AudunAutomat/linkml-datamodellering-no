# Plan: `make check-prereqs` med rette instruksjonar for macOS

**Kortnavn:** `check-prereqs-macos`
**Dato:** 2026-11-17

---

## Bakgrunn

`src/assets/scripts/makefile/check-prereqs.bash` er skriven for WSL2/Debian og
gjev difor feil eller villeiande instruksjonar på macOS. Fyrste køyring på ein
Mac (Darwin, Apple Git, Apple `jq`, GNU Make 3.81, ingen Podman) gav:

```
✓ GNU make tilgjengeleg (GNU Make 3.81)
✓ Git tilgjengeleg (git version 2.54.0 (Apple Git-157))
✓ jq tilgjengeleg (jq-1.7.1-apple)
✗ Podman ikkje funne. Installer: sudo apt-get update && sudo apt-get -y install podman
✗ Podman rootless fungerer ikkje. Prøv: podman system migrate
⚠ User namespace-mapping manglar for '<brukar>'. Prøv: sudo usermod --add-subuids ...
⚠ Ikkje WSL2 — skript er primært testa i WSL2, men kan fungere på vanleg Linux
make: *** [check-prereqs] Error 64
```

### Funn

| # | Problem på macOS | Linje (ca.) |
|---|---|---|
| F1 | Podman-instruksjon er `apt-get` — finst ikkje på macOS. Rett veg er `brew install podman` + `podman machine init` + `podman machine start` | 43-47 |
| F2 | «Podman rootless fungerer ikkje. Prøv: `podman system migrate`» er feil råd når Podman manglar, og på macOS er det `podman machine` (ei Linux-VM) som må køyre, ikkje `system migrate` | 50-54 |
| F3 | `/etc/subuid` og `/etc/subgid` finst ikkje på macOS (dei ligg inni Podman-VM-en). Sjekken og `usermod`-rådet er irrelevante og forvirrande | 57-63 |
| F4 | «Ikkje WSL2 ... vanleg Linux»-åtvaringa nemner ikkje macOS | 66-70 |
| F5 | **Stille feil:** `df -BG .` er GNU-spesifikt og feilar på BSD-`df` (`invalid option -- B`, exit 64). Med `set -euo pipefail` døyr scriptet midt i køyringa, `OK/Åtvaringar/Feil`-oppsummeringa og «Rett feilane»-meldinga vert aldri skrive, og `make` melder berre `Error 64`. Bryt «Ingen stille feil» i CLAUDE.md | 87 |
| F6 | GNU make-sjekken godtek Apple sin 3.81 utan kommentar. Ingen bruk av make-4-funksjonar funnen (`.ONESHELL`, `$(file`, `&:` o.l.), så 3.81 ser ut til å fungere, men dette er ikkje verifisert mot alle targets | 29-34 |
| F9 | **Bash 3.2:** macOS sin `/bin/bash` er 3.2.57, og `Makefile` set `SHELL := /bin/bash`. Fleire script brukar bash 4+ (`mapfile`, `declare -A`/`local -A`): `help.sh`, `run-domain-pipeline.sh`, `generate-readme-tables.sh`, `tests/test_make.sh`, `migrate-schema-metadata.sh`. Verifisert: `make help` feilar med `mapfile: command not found`. `make test` og domene-pipelinen vil feile på same måte | — |
| F10 | **`.SHELLFLAGS` ignorert i make 3.81:** `Makefile:9` set `.SHELLFLAGS := -o pipefail -c`. Variabelen kom først i GNU make 3.82, så på 3.81 køyrer oppskrifter utan `pipefail` — feil i piper vert stille svelgde, i strid med «Ingen stille feil». Må verifiserast (sjå testplanen) | — |
| F7 | Ingen sjekk av at Podman-VM-en deler heimekatalogen (`.mcp.json` og alle `make`-targets monterer `$REPO` med `-v`) | — |
| F8 | Dokumentasjon (`README.md` § oppstart, `COMMANDS.md` § check-prereqs, `mkdocs/docs/kom-i-gang/*`) nemner berre WSL2/apt | — |

Relatert (utanfor scope, sjå «Oppfølging»): `src/assets/scripts/bump-version.sh:106`
bruker `sed -i "..."` utan sufiks, som feilar på BSD-`sed` (macOS krev `sed -i ''`).

---

## Mål

Ein macOS-brukar skal kunne køyre `bash src/assets/scripts/makefile/check-prereqs.bash`
på ei fersk Mac og få:

1. Ingen Linux-/WSL2-spesifikke råd (`apt`, `usermod`, `/etc/subuid`).
2. Konkrete, kopierbare Homebrew-kommandoar for kvar manglande avhengigheit.
3. Alltid ei fullstendig oppsummering — scriptet døyr aldri stille.

---

## Steg

1. **Plattformdeteksjon** øvst i scriptet: `OS=$(uname -s)` → `Darwin` / `Linux`; `IS_WSL` frå `/proc/version` som i dag. Éi variabel, brukt av alle sjekkar under.
2. **Homebrew-sjekk (berre Darwin):** `command -v brew`. Manglar han: `fail` med lenkje/kommando frå <https://brew.sh> (offisiell installasjons-one-liner kopierast frå brew.sh ved implementering, ikkje frå minne).
3. **Instruksjonar per OS** for `make`, `git`, `jq`, `podman`:
   - Linux/WSL2: som i dag (`apt`).
   - Darwin: `brew install <pakke>`. `git` og `make` følgjer med Xcode Command Line Tools (`xcode-select --install`); Apple sin make er 3.81 — beslutt i steg 6 om `brew install make` (gjev `gmake`) skal rådast.
4. **Podman på Darwin:** erstatt rootless-sjekk-rådet med ein trinnvis diagnose:
   1. `podman` manglar → `brew install podman`.
   2. `podman machine list` tom → `podman machine init`.
   3. Maskin finst, men køyrer ikkje → `podman machine start`.
   4. Då køyrer den eksisterande `podman run --rm alpine echo ok`-sjekken.
   `podman system migrate` vert berre foreslått på Linux.
5. **Hopp over user namespace-sjekken på Darwin** (F3); vis i staden `ok`/info om at VM-en handterer det.
6. **Fiks `df`-sjekken (F5):** portabel variant — `df -Pk . | awk 'NR==2 {print int($4/1048576)}'` (POSIX `-P` + KiB → GiB) — og/eller `|| true` med eksplisitt `warn` («kunne ikkje lese diskplass») viss `df` feilar. Scriptet skal aldri avslutte utan oppsummering. Legg på **Darwin**-merknad om at Podman-VM-en har eigen disk (`podman machine init --disk-size`), og at sjekken berre gjeld verts-disken.
7. **Delt heimekatalog (F7, valfritt):** på Darwin, etter at maskina køyrer, test `podman run --rm -v "$PWD:/w:ro" alpine ls /w` og gje `warn` med råd om `podman machine` volume-mount viss han feilar.
8. **Åtvaringa i F4:** byt til OS-bevisst melding — på Darwin `ok "macOS oppdaga (Podman køyrer i VM via podman machine)"`; på Linux utan WSL2 behald eksisterande `warn`.
9. **GNU make (F6, F10, avgjerd 3):** på Darwin krev `check-prereqs` GNU make >= 4.0. Parse `make --version`; er versjonen lågare, `fail` med: `brew install make` og `export PATH="$(brew --prefix make)/libexec/gnubin:$PATH"` (legg i `~/.zshrc`), alternativt bruk `gmake`. Dokumenter same i README/COMMANDS. Fullfør testplanen under («Testplan: GNU make 3.81») mot den installerte versjonen for å stadfeste at alle mål fungerer, og rett F10 (`SHELL := /bin/bash -o pipefail`) uavhengig av utfallet.
9b. **Bash 3.2 (F9):** avgjer strategi — (a) krev `brew install bash` og få `Makefile`/scripta til å bruke Homebrew-bash (`SHELL`, `#!/usr/bin/env bash` + PATH), eller (b) skriv om bash 4-konstruksjonar til 3.2-kompatible. Legg til bash-versjonssjekk i `check-prereqs.bash` (`BASH_VERSINFO[0]`) som gjev Homebrew-råd. Offisiell støtte gjer dette til eit krav, ikkje eit «kan».
10. **Dokumentasjon:** oppdater `README.md` (oppstart), `COMMANDS.md` § `check-prereqs` (tabellen og forklaringa), `mkdocs/docs/kom-i-gang/*` der WSL2 vert nemnt som einaste miljø, og engelske `.en.md`-parallellar. Ingen duplisering: éin macOS-seksjon (t.d. i `COMMANDS.md`), resten lenkjer dit.
11. **Test:** utvid/legg til test for scriptet (sjekk om `tests/` har dekning for `check-prereqs.bash`; følg konvensjonen i `tests/README.md`). Minst: syntakssjekk (`bash -n`), og køyring med `OS`-overstyring/stubba `uname` for å dekke både `Darwin`- og `Linux`-grenar utan å installere noko.
12. **Verifiser** på ein Mac både før og etter `brew install podman` + `podman machine init/start`: scriptet skal gå frå `✗` til `✓` utan kodeendring.
13. Skriv commit-melding (utkast, ingen git-kommandoar).

---

## Handlingsliste

- [x] 1. Plattformdeteksjon (`uname -s`, `IS_WSL`)
- [x] 2. Homebrew-sjekk på Darwin
- [x] 3. OS-spesifikke installasjonsinstruksjonar (make/git/jq/podman)
- [x] 4. Trinnvis Podman-diagnose på Darwin (`brew install` → `machine init` → `machine start`)
- [x] 5. Hopp over subuid/subgid-sjekk på Darwin
- [x] 6. Portabel diskplass-sjekk, ingen stille død (F5)
- [x] 7. (Valfritt) Test av delt heimekatalog i Podman-VM
- [x] 8. OS-bevisst WSL2/macOS-melding
- [x] 9. `check-prereqs`: krev GNU make >= 4.0 på Darwin med Homebrew-instruksjon (avgjerd 3)
- [x] 9a. Lag 1 og 3 av testplanen utført (lag 2-diff mot 3.81 ikkje gjort: macOS krev make >= 4, avgjerd 3)
- [x] 9a2. Rett F10 i `Makefile:8-9` (`SHELL := /bin/bash -o pipefail`) og verifiser mot begge make-versjonar
- [x] 9b. Avgjer bash 3.2-strategi (F9) og legg til bash-versjonssjekk
- [x] 9c. Fiks `sed -i` i `bump-version.sh:106` (portabel variant)
- [ ] 9d. macOS-jobb i CI — utsett (avgjerd 5): eiga spec
- [x] 10. Oppdater dokumentasjon (README, COMMANDS, mkdocs nn/en)
- [x] 11. Testar for Darwin- og Linux-grenar
- [x] 12. Manuell verifisering på Mac (check-prereqs grøn, make test 528 OK)
- [x] 13. Commit-melding

---

## Testplan: GNU make 3.81

**Spørsmål:** fungerer alle prosjektets make-targets (ca. 116 definerte reglar i `Makefile` + `make/*.mk`) på Apple sin GNU Make 3.81? Podman-avhengige targets krev ein fungerande Podman-VM (steg 4 i hovudplanen), så testen deler seg i tre lag, frå billigast til dyrast. Resultat loggast i `## Avgjerder`.

### Lag 1 — Statisk kartlegging av make 3.82+/4.x-funksjonar

Grep `Makefile` og `make/*.mk` etter funksjonar og direktiv som ikkje finst i 3.81:

| Funksjon/direktiv | Innført | Verknad på 3.81 |
|---|---|---|
| `.SHELLFLAGS` | 3.82 | Ignorert → ingen `pipefail` (F10). **Kjent treff: `Makefile:9`** |
| `.ONESHELL`, `.RECIPEPREFIX` | 3.82 | Ignorert / feil oppførsel |
| `undefine`, `private`, `export` inni `define` | 3.82 | Parsefeil |
| `$(file ...)`, `&:` (grupperte mål), `--output-sync`/`-O` | 4.0 | Parsefeil/ukjend flagg |
| `$(let ...)`, `!=` (shell-tilordning) | 4.0 / 4.4 | Tom verdi eller feil |
| `$(intcmp ...)`, `$(guile ...)` | 4.4 / 4.0 | Parsefeil |

Òg sjekk flagg og oppførsel i `$(MAKE)`-kall (`-j`, `--no-print-directory`) og eventuell `MAKEFLAGS`-handtering. Resultat: liste over treff med fil:linje.

### Lag 2 — Parse- og dry-run-samanlikning, 3.81 mot 4.x (ingen containerar)

1. Installer nyare make side om side: `brew install make` (gjev `gmake`, ikkje i konflikt med `/usr/bin/make`).
2. Hent målliste frå databasen: `make -qp | awk -F: '/^[a-zA-Z0-9][^$#\/\t=]*:([^=]|$)/{print $1}' | sort -u` (cross-sjekk mot `grep -hoE "^[a-zA-Z0-9_.%-]+:" make/*.mk Makefile`).
3. For kvart mål: `make -n <mål> [påkravde args]` og `gmake -n <mål> [...]`, lagre stdout/stderr/exit-kode. Mål som krev argument (`SCHEMA=`, `DOMAIN=`, `ORG=`, `INSTANCE=` o.l.) får eit kanonisk testargument frå `COMMANDS.md`.
4. **Diff** 3.81- og 4.x-utdata per mål. Kategoriser avvik: (a) parse-/syntaksfeil, (b) ulik kommandoutvidinga (t.d. tomme variablar), (c) berre ulik støy.
5. Sjekk spesifikt at `make -n` på 3.81 viser at `pipefail` manglar for oppskrifter (F10), og at `$(MAKECMDGOALS)`/`_MAKE_GOALS` (`Makefile:17`) og `$(origin LOGLVL)` (`Makefile:107`) oppfører seg likt.

Dette laget er rask og fangar parse- og utvidingsfeil. Det fangar **ikkje** køyretidsfeil (bash 3.2, BSD-verktøy, Podman).

### Lag 3 — Funksjonell køyring (krev Podman-VM)

1. Føresetnad: `check-prereqs` passerer (Podman køyrer, bash-strategi avgjort, F9), og `make build-docker-all` er gjennomført.
2. Køyr representative targets per `make/*.mk`-fil på **både** `make` (3.81) og `gmake`, minst: `lint`, `validate-instance`, `roundtrip`, `gen-doc`, `gen-plantuml`, `docs-build`, `mcp-linkml-valider-modell`, `mcp-linkml-modell-utkast`, `check-prereqs`, `help`.
3. Køyr heile `make test` på begge (`tests/test_make.sh`), samanlikn bestått/feila/hoppa-over per test (jf. `tests/README.md`). Avvik som berre finst på 3.81 vert klassifisert som make-avhengige; avvik på begge er bash/BSD/Podman-problem og høyrer til F9/BSD-sporet.
4. **Positiv test av F10:** lag eit mål med ein pipe der første kommando feilar (`false | true`) og verifiser at 3.81 *ikkje* feilar medan `gmake` feilar. Dokumenter som `bugs/`-fil + BUGS.md viss stadfesta og workaround vert lagd inn (jf. CLAUDE.md § Kjente feil).

### Resultat (køyrt 2026-11-17, macOS, GNU Make 3.81, ingen Podman)

| Lag | Status | Resultat |
|---|---|---|
| 1 Statisk | Utført | Eitt reelt treff: `.SHELLFLAGS` (`Makefile:9`). Ingen bruk av `.ONESHELL`, `.RECIPEPREFIX`, `undefine`, `private`, `$(file)`, `$(let)`, `&:`, `--output-sync`. `.DEFAULT_GOAL` (3.81) og `$(or)`/`$(if)` er støtta. `!=`-treff i `make/00-settings.mk` er bash-tester (falske positive) |
| 2 Dry-run 3.81 | Delvis | Alle 103 mål (frå `make -qp`) gir `make -n` exit 0 på 3.81: ingen parse- eller ekspanderingsfeil. Målliste frå grep har 105 namn; tre manglar i databasen (`_gource-render`, `_mcp-valider-modell-with-header`, `config.mk`, interne/hjelpemål). Ikkje utført: **diff mot make 4.x** — `gmake` finst ikkje, og bygging av make 4.4.1 frå kjelde i scratchpad vart avslått av løyvesystemet |
| 3 Funksjonell | Ikkje utført | Krev Podman (manglar på maskina) og avklart bash-strategi (F9) |

**F10 stadfesta (positiv test):** med repoet sine linjer (`SHELL := /bin/bash`, `.SHELLFLAGS := -o pipefail -c`) heldt ein oppskrift med `false | true` fram og gav exit 0 på 3.81, dvs. **utan pipefail**. Med `SHELL := /bin/bash -o pipefail` (utan `.SHELLFLAGS`) feila same oppskrift med `Error 1` som venta, på 3.81. Ei slik endring i `Makefile:8-9` er dermed eit enkelt og kompatibelt tiltak, men må testast mot resten av repoet (t.d. `-c` vert lagt til automatisk av make) og mot make 4.x.

**Delkonklusjon:** 3.81 parsar og ekspanderer repoet utan feil, men **køyrer oppskrifter utan pipefail** (F10) — stille feil. `make help` og fleire script feilar uavhengig av make-versjonen på grunn av bash 3.2 (F9). Endeleg 3.81-avgjerd ventar på lag 2 (diff) og lag 3.

### Utfall og avgjerd

**Avgjort (avgjerd 3):** alternativ 2 under, med macOS-brukarar på oppdatert make via Homebrew; fiks F10 i tillegg. Resten av avsnittet står som bakgrunn.

Ut frå laga over vel vi éi av:

1. **3.81 er støtta** — ingen endring utover dokumentasjon, evt. omskriving av `.SHELLFLAGS` til eksplisitt `SHELL := /bin/bash -o pipefail`-liknande løysing som verkar på 3.81.
2. **3.81 er ikkje støtta** — `check-prereqs` gjev `fail` med `brew install make` og instruksjon om å køyre `gmake` (eller leggje `$(brew --prefix make)/libexec/gnubin` først i `PATH`); dokumentasjonen seier det eksplisitt.

Anbefaling før testane er køyrte: forvent utfall 2 (F10 åleine gjer 3.81 usikker for «Ingen stille feil»), men la testen avgjere.

---

## Oppfølging

- `src/assets/scripts/bump-version.sh:106`: `sed -i` er ikkje portabelt til BSD-`sed` (steg 9c). Ei kartlegging av andre GNU-isme (`readlink -f`, `date -d`, `stat -c`, `xargs -r`, `grep -P`) i `make/` og `src/assets/scripts/` fann ingen andre treff ved denne undersøkinga, men bash 4-konstruksjonar (F9) vart funne.
- Offisiell støtte krev CI-dekning (steg 9d): vurder `macos-latest`-jobb som minst køyrer `check-prereqs` og eit røykjetest-sett. Sjekk først om Podman køyrer på GitHub sine macOS-runnarar (VM i VM), elles kan jobben avgrensast til lag 1-2 i testplanen. Følg `.claude/rules/ci-workflows.md` og køyr `actionlint`.
- Oppdater `SCOPE.md`/`CONTRIBUTING.md`: macOS er offisielt støtta miljø (sjå avgjerd 1).

---

## Avgjerder

1. **Støttenivå for macOS: offisiell støtte** (brukaren, 2026-11-17). Konsekvens: F9 (bash 3.2), `sed -i` og CI-dekning vert innanfor scope, ikkje berre «oppfølging».
2. **GNU make 3.81:** brukaren bad først om testplan (sjå «Testplan: GNU make 3.81»; lag 1 og 2 delvis utført, F10 stadfesta).
3. **Oppdatert make på macOS** (brukaren, 2026-11-17): macOS-brukarar skal installere ein nyare GNU make (`brew install make`) i staden for å halde seg til Apple sin 3.81. Dette erstattar spørsmålet om 3.81 skal støttast: `check-prereqs` skal på Darwin gje `fail` (ikkje `warn`) viss `make --version` er < 4.0, med råd om å installere via Homebrew og leggje `$(brew --prefix make)/libexec/gnubin` først i `PATH` (så `make` peikar på GNU make; elles må brukaren køyre `gmake`). Diffen i lag 2 og lag 3 vert køyrt mot den installerte versjonen i staden for ei kjelde-bygd kopi. F10 (`.SHELLFLAGS`) vert uansett retta, sidan han ikkje kostar noko og gjer repoet robust mot 3.81 òg.

4. **Bash 3.2 (F9): krev Homebrew bash >= 4** (brukaren, 2026-11-17). `check-prereqs` sjekkar bash i `PATH`; `Makefile` brukar `bash` frå `PATH` i staden for `/bin/bash`. Scripta vert ikkje omskrivne til 3.2. `check-prereqs.bash` og `tests/test_check_prereqs.sh` er sjølve haldne bash 3.2-kompatible, sidan dei køyrer før Homebrew-bash er installert.
5. **CI (steg 9d): berre oppfølging** (brukaren, 2026-11-17). Ingen macOS-jobb no; Podman-i-VM på GitHub sine macOS-runnarar er uavklart.
6. **F10 retta via `SHELL`** (eigen avgjerd): `SHELL := $(or $(shell command -v bash),/bin/bash) -o pipefail`, `.SHELLFLAGS` fjerna. Verifisert på make 3.81 (oppskrift med `false | true` gir `Error 1`) og at `SHELL` evaluerer til `/bin/bash -o pipefail` utan Homebrew-bash. Ikkje verifisert på make 4.x/WSL2 (idiomet er vanleg og forventa å fungere).
7. **Test av `check-prereqs` som frittståande bash-script** (`tests/test_check_prereqs.sh`), ikkje i `make test`: scriptet skal kunne testast utan podman, og `make test` krev containerar. 16 testar passerer på macOS med stubba PATH og `PREREQS_OS`.
8. **Diskplass:** `df -Pk` (POSIX) erstattar `df -BG`; feil gir åtvaring i staden for stille avslutning (F5). På macOS vert alltid ei åtvaring om Podman-VM-ens eigen disk vist.

## Utført

2026-11-17. macOS er no offisielt støtta miljø for lokal utvikling. Verifisert på macOS (Darwin, Apple Silicon) med GNU make 4.4.1, bash 5.3, Podman-VM 8 GiB og PyYAML i brukarmappa:

- `make check-prereqs`: grøn (OS-bevisste Homebrew-råd; make >= 4, bash >= 4, python3 + PyYAML, podman machine, VM-minne, portabel diskplass).
- `make test`: **528 OK, 0 feil** (67 s). `tests/test_check_prereqs.sh`: 21 testar OK.
- `make domain-*` (alle 8 domene): 17 OK, 0 feil per domene.
- `make docs-publish`: exit 0 (i repoet og i sandkasse-kopi).

Endra: `check-prereqs.bash`, `Makefile` (bash frå `PATH`, `pipefail` i `SHELL`), `make/00-settings.mk` (`now_ms`), `tests/test_make.sh` (`now_ms`, `mktemp_ext`), `mkdocs/lib/copy_artifacts.sh` (`find_cp_into`, `perl -pi`), `bump-version.sh` (`sed -i.bak`), `tests/test_check_prereqs.sh` (ny), `COMMANDS.md § macOS`, `README.md`/`README.en.md`, `mkdocs/docs/kom-i-gang/kommandoar*.md`, `tests/README.md`.

**Ikkje utført / oppfølging:**
- Linux/WSL2-regresjonstest av F11-F14 (endringane er skrivne for uendra Linux-åtferd, men er ikkje køyrde der).
- macOS-jobb i CI (avgjerd 5) — eiga spec; Podman-i-VM på GitHub sine macOS-runnarar er uavklart.
- Lag 2 i make-testplanen (diff 3.81 mot 4.x) — ikkje relevant etter avgjerd 3.
- `mkdocs/docs/felles/` vert sletta av `docs-publish` fordi `generated/felles` ikkje finst (eksisterande åtferd, ikkje macOS-spesifikk).
- Vertskjørte python-kall i `publish.sh` (alternativ b i F16) om «ingen lokale avhengigheiter» skal gjelde portalbygget.

## Funn frå full testkøyring på macOS (2026-11-17)

Fyrste `make test` på Mac (make 4.4.1, bash 5.3, Podman 2 GiB VM) avdekte fleire macOS-feil utanfor `check-prereqs`. Retta i same økt:

| # | Funn | Fiks |
|---|---|---|
| F11 | `tests/test_make.sh` brukte `date +%s%3N` (BSD `date` støttar ikkje `%N` → aritmetikkfeil) — var òg ei attverande BUG-21-kallstad | Bytta til `now_ms` frå `LOG_FUNCTIONS` |
| F12 | `now_ms()` (`make/00-settings.mk`) las `/proc/uptime` som ikkje finst på macOS → all `timed_run`-tidtaking feilar | Linux uendra; på macOS monotonisk klokke via `perl -MTime::HiRes` |
| F13 | BSD `mktemp` erstattar berre `XXXXXX` heilt sist i malen (`..._XXXXXX.log` gav bokstavlege filer og «File exists») | `mktemp_ext`-hjelpar i `test_make.sh` (12 kallstader) |
| F14 | `mkdocs/lib/copy_artifacts.sh`: `cp -t` (GNU), `sed -i` utan suffiks og `\L` i sed-erstatning (GNU) — feilar på macOS og ville broten `make docs-publish` | `find_cp_into`-hjelpar og `perl -pi` (dekt av `copy-artifacts-click-href`-testen) |
| F15 | **Podman-VM med 2 GiB (standard) gir OOM-kill (exit 137)** i parallelle køyringar: 186 av 528 sjekkar feila i Fase B, utan at modellane var feil | `check-prereqs` åtvarar < 4 GiB og viser `podman machine set --memory 8192` |

Verifisert: `make test SCHEMA=src/linkml/ap-no/cpsv-ap-no/cpsv-ap-no-schema.yaml` → 18 OK, 0 feil. **Full `make test` verifisert** etter at Podman-VM vart sett til 8 GiB: **528 OK, 0 feil**, 67 s (make 4.4.1, bash 5.3, macOS). **Ikkje verifisert:** Linux/WSL2-regresjon for F11-F14 (endringane er skrivne for å halde Linux-åtferd uendra, men er ikkje køyrde der). Fleire GNU-isme kan dukke opp i `make docs-publish`, `domain-*`-targets o.l. som `make test` ikkje dekkjer.

Avgjerd 9: F11-F15 retta innanfor «offisiell macOS-støtte» (avgjerd 1), sjølv om dei ikkje stod i opphavleg plan.

## Funn frå `domain-*` og `docs-publish` på macOS (2026-11-17)

**`domain-*`:** alle 8 domene (`ap-no`, `fair`, `fint`, `modellkatalog`, `ngr`, `oreg`, `referanse`, `samt`) gjekk gjennom: 17 OK, 0 feil per domene (7-17 s kvar). Køyringa regenererte 33 versjonskontrollerte `*-manifest.yaml` (berre `versjonsnummer`, `endringsdato` og to skildringstekstar — drift mellom innsjekka manifest og skjema, ikkje macOS-relatert). Rulla tilbake med `git restore`. Merk: `domain-*` har ingen `felles`/`begrepskatalog`-domene i `DOMAINS`.

**`docs-publish`** (køyrt i sandkasse-kopi i scratchpad, jf. `.claude/rules/mkdocs-portal.md`, fordi `mkdocs/docs/felles/` har 511 versjonskontrollerte filer utan tilsvarande `generated/felles/`): fyrste køyring feila, andre gjekk gjennom (exit 0, 5338 sider per språk nn/en, 580 artefakter).

| # | Funn | Status |
|---|---|---|
| F16 | **Vertsavhengigheit av PyYAML:** `mkdocs/publish.sh:571` (`i18n_strings.py render-tree`) og andre `python3`-kall på verten (`modellanalyse_render.py`, `generate-validation-md.py`, `build_language_trees.py`, `parse-dependency-tree.py`) krev `import yaml` på verten. Fungerer på Ubuntu/WSL fordi `python3-yaml` følgjer med, feilar på macOS med `ModuleNotFoundError: No module named 'yaml'`. Strid med «ingen avhengigheiter lokalt». Verifisert at resten av `docs-publish` fungerer med PyYAML på `PYTHONPATH` (henta frå `python-pytest`-biletet, ingenting installert) | **Retta (avgjerd 10):** `check-prereqs` krev `python3` med PyYAML på verten, med `python3 -m pip install --user --break-system-packages pyyaml` (macOS) / `apt-get install python3-yaml` (Linux)-råd; testa (`tests/test_check_prereqs.sh`, 21 testar) og dokumentert i `COMMANDS.md § macOS` og README |
| F17 | Løkker som `while read ... done < liste` med `make`/`podman run -i` inni et stdin og stoppar stille etter første element (BUG-10-mønsteret). Råka mi eiga testløkke, ikkje repokode | Ingen repoendring |

**Avgjerd 10 (brukaren, 2026-11-17):** alternativ (a) — krev PyYAML på verten. Alternativ (b), flytte dei vertskjørte python-kalla til container (`run_python_container` med skrivbar mount til `mkdocs/docs`/`mkdocs/build`), er ikkje valt, men kan gjerast som eiga spec dersom «ingen lokale avhengigheiter» skal gjelde òg for portalbygget.

**Står att:** installer PyYAML på Mac-en (`python3 -m pip install --user --break-system-packages pyyaml`; `brew install pyyaml` finst ikkje — Homebrew-Python er PEP 668 «externally managed») og køyr `make docs-publish` i repoet (ikkje sandkasse) etter at `generated/felles` er avklart — sjå risikoen med `mkdocs/docs/felles/` over.

**`docs-publish` i repoet (2026-11-17, PyYAML installert):** exit 0, alle steg gjennomførte. Som forventa (jf. `.claude/rules/mkdocs-portal.md`) sletta Steg 1 alle 512 versjonskontrollerte filer under `mkdocs/docs/felles/`, fordi `generated/` ikkje har noko `felles`-domene (`src/linkml/felles/` og `begrepskatalog/` har ingen skjema som gir `DOMAINS`-oppføring). Ingen andre slettingar eller endringar i `mkdocs/docs/`. Rulla tilbake med `git restore -- mkdocs/docs/felles`. Dette er eksisterande åtferd, ikkje macOS-spesifikk; verdt eiga undersøking (skal `felles/` vere versjonskontrollert og vert ikkje regenerert?).
