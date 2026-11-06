# Evaluering: Google distroless som baseimage

## Bakgrunn

Alle eigenbygde containerbilete i repoet brukar i dag Alpine-baserte basisbilete
(`python:3.15-alpine`, `node:26-alpine`, `eclipse-temurin:25-jre-alpine`,
`alpine:3.24`). Spørsmålet er om
[Google distroless](https://github.com/GoogleContainerTools/distroless) kan erstatte
desse, med mål om mindre angrepsflate (ingen shell, ingen pakkehandsamar, færre
CVE-ar) for dei publiserte bileta på `ghcr.io/audunautomat/*`.

Denne specen er ei rein vurdering. Ingen Dockerfile er endra.

### Kva distroless tilbyr (per 2026-11-06)

Kjelde: README i GoogleContainerTools/distroless.

- Alle støtta bilete er på **Debian 13**. Andre tags er «deprecated and no longer updated».
- Relevante bilete:
  - `python3-debian13`: systempython frå Debian 13, altså **CPython 3.13**. README-en oppgir ikkje versjonen, så den må stadfestast i steg 1.
  - `java25-debian13`
  - `nodejs22|24|26-debian13`
  - `cc-debian13`
  - `base-debian13`
  - `static-debian13`
- Tags per bilete: `latest`, `nonroot` (uid 65532), `debug` og `debug-nonroot` (med busybox-shell).
- Bileta er glibc-baserte, ikkje musl. Bileta har ingen `sh`, `apk`/`apt`, `git`, `find`, `patch` eller `adduser`.
- Eit image-navn utan distro-suffiks vil seinare peike på ein nyare Debian-versjon, så suffikset må alltid pinnast (t.d. `-debian13`).

## Kartlegging per bilete

| Bilete | Noverande base | Distroless-kandidat | Blokkerande hinder | Vurdering |
|---|---|---|---|---|
| `linkml-local` | `python:3.15-alpine` | `cc-debian13` + Python 3.15 kopiert inn (alt. `python3-debian13`, 3.13) | `RUN patch` (docgen-patch) må flyttast til builder. Builder må vere Debian 13-basert med same Python-ABI. | Mogleg, middels innsats |
| `mcp-linkml-validator` / `-modell-utkast` / `-begrep-utkast` | `python:3.15-alpine` | `cc-debian13:nonroot` + Python 3.15 kopiert inn | `RUN adduser` → `:nonroot`. `RUN pip install pytest` (modell-utkast) må til builder. `CMD ["python", ...]` må peike på `/usr/local/bin/python3`. | Mogleg, best gevinst (publisert og brukt eksternt) |
| `python-pytest` | `python:3.15-alpine` + `git` | – | `check-scaffold-todo-age.py` køyrer `git log`, og `collect-schema-metadata.py` køyrer `find`, begge via `subprocess`. Biletet er ein testkøyrar som ikkje vert publisert til eksterne brukarar. | Ikkje eigna |
| `avrotize-local` | `python:3.15-alpine` | `cc-debian13` + Python kopiert inn | `make/10-generator-macros.mk` køyrer `--entrypoint sh` + `batch-gen-xsd.sh`. Det krev shell, eller at scriptet vert skrive om til Python. Berre 1 domene brukar biletet. | Ikkje no |
| `asyncapi-cli-minimal` | `node:26-alpine` | `nodejs26-debian13` | `--entrypoint /bin/sh` + `batch-asyncapi-validate.sh` krev shell, eller omskriving til Node. `RUN chmod`/`addgroup` må bort. | Ikkje no |
| `plantuml` | `temurin:25-jre-alpine` + `graphviz` | `java25-debian13` | Treng `dot`-binæren med alle `.so`-avhengigheiter og fontconfig. Å kopiere graphviz inn i distroless er skjørt. Krav om byte-identisk SVG mot upstream (jf. kommentar i Dockerfile) må verifiserast på nytt. | Høg risiko, ikkje tilrådd |
| `mkdocs-local` | `squidfunk/mkdocs-material` | – | Tredjepartsbilete, ikkje eigenbygd | Utanfor scope |
| `gource` | `alpine:3.24` | – | `ffmpeg`, `xvfb-run`, `git` | Ikkje eigna |

CI-steget for commitlint i `.github/workflows/validate.yml` (`node:22-alpine` + `sh -c`) brukar
eit eksternt bilete ad hoc og er utanfor scope.

## Vurdering

**Fordelar**

1. **Angrepsflate.** Biletet har ingen shell og ingen pakkehandsamar. Det gir typisk færre CVE-funn i skanning av publiserte GHCR-bilete. Det har mest å seie for `mcp-linkml-validator`, som eksterne repo pullar via `reusable-validate.yml`.
2. **Ikkje-root som standard.** `:nonroot` erstattar dei manuelle `adduser`-stega.
3. **Signerte bilete.** Distroless-bileta er signerte med cosign og kan verifiserast i CI om det er ønskt. Dette må stadfestast.
4. **glibc.** Builderen kan bruke ferdige `manylinux`-wheels. Då slepp han kanskje `gcc musl-dev g++`-laget, og byggjetida kan gå ned. Dette må målast.

**Ulemper / risiko**

1. **Python-versjonen og ferdig `python3`-bilete.** Det ferdige biletet `python3-debian13` er låst til Debian sin systempython (3.13). Det går ikkje å installere eller oppgradere Python inne i eit distroless-bilete, fordi det verken har pakkehandsamar eller shell. Det går derimot an å **kopiere inn** ein Python som er bygd ein annan stad: bygg i `python:3.15-slim-trixie` (offisielt bilete, Debian 13/glibc) og kopier `/usr/local` over til `gcr.io/distroless/cc-debian13:nonroot`. Då kan Python 3.15 behaldast, og Dependabot kan framleis bumpe versjonen via builderen sin `FROM`. Det kostar dette:
   - Delte bibliotek som `python3` og `.so`-filene i site-packages treng, men som `cc-debian13` manglar (t.d. zlib, libffi, libexpat), må kartleggjast med `ldd` og kopierast inn eksplisitt. Ein manglande `.so` feilar først når den aktuelle modulen blir importert, så ein import-røyktest i bygget er påkravd.
   - Tryggleiksoppdateringar for Python kjem frå `python:*-slim-trixie`, ikkje frå Google.
2. **Builder og runtime må samsvare.** Builderen må vere Debian 13-basert (glibc) for at binærane skal fungere i distroless debian13. Det er annleis enn i dei bileta som blir verande på Alpine/musl.
3. **Inga `RUN` i runtime-stadiet.** All patching, `chmod` og `pip install` må flyttast til builderen.
4. **Biletstorleiken vert neppe mindre.** `python3-debian13` er om lag like stor som `python:alpine`, og glibc-wheels er ofte større enn musl-bygg. Gevinsten er tryggleik, ikkje storleik. Dette må målast.
5. **Feilsøking.** `podman run -it ... sh` fungerer ikkje lenger. Ein må bruke `:debug`-varianten.
6. **Avvik frå ein felles base.** Ein delvis migrering gir to basisfamiliar (Alpine og Debian/distroless) å halde ved like og oppdatere med Dependabot.

**Tilråding:** Python-versjonen er ikkje noko hinder (sjå Ulemper 1). Ikkje gjennomfør ein generell migrering. Dersom tryggleiksgevinsten for
dei publiserte bileta vert vurdert som viktig, kan det gjerast ein **avgrensa pilot på
`mcp-linkml-validator`**. Bileta `python-pytest`, `gource`, `plantuml` og `mkdocs-local`
skal ikkje migrerast. `avrotize-local` og `asyncapi-cli-minimal` vert berre aktuelle
dersom batch-shellscripta likevel skal skrivast om (10+ skjema er venta å ta i bruk
xsd/asyncapi). Det skal i så fall vere ei eiga avgjerd.

## Steg (dersom piloten vert godkjend)

1. Vel variant: ferdig `python3-debian13` (Python 3.13) eller `cc-debian13` med Python 3.15 kopiert inn (tilrådd, sjå Ulemper 1).
2. Lag eit pilot-stadium i `Dockerfile.mcp-linkml`:
   - Builder: `python:3.15-slim-trixie` og `pip install`.
   - Runtime: `gcr.io/distroless/cc-debian13:nonroot` med `COPY --from=builder /usr/local /usr/local` og dei delte biblioteka som `ldd` viser at manglar.
   - Legg til ein import-røyktest i bygget (`python3 -c "import linkml, linkml_runtime, yaml"` i eit test-stadium).
   - Erstatt `CMD ["python", "server.py"]` med `ENTRYPOINT ["/usr/local/bin/python3"]` og `CMD ["server.py"]`.
3. Kartlegg alle invokeringsstader etter `.claude/rules/container-images.md`:
   - `make/60-mcp.mk`
   - `Makefile`
   - `.mcp.json`
   - `flatten-and-validate.bash`
   - `batch-*-validate*.py`
   - `tests/test_make.sh`
   - `reusable-validate.yml`

   Sjekk at ingen av dei overstyrer entrypoint med `python`/`sh`.
4. Bygg og køyr biletet **utan** ekstra `-v`-montering, og køyr `make analyse-container-copy-konsistens`.
5. Mål pilotbiletet mot dagens Alpine-bilete. Bruk same maskin, og ta medianen av minst 10 køyringar for tidsmålingane (med `time` i shell, utan nye lokale verktøy):

   | Målepunkt | Korleis |
   |---|---|
   | Biletstorleik | `podman images` |
   | Byggjetid | `podman build --no-cache --target validator`. Mål både kald bygging og ombygging med varm cache. |
   | CVE-funn | t.d. trivy køyrt som container |
   | Oppstartstid | Tid frå `podman run -i --rm` til første svar på ein JSON-RPC `initialize`-førespurnad over stdio. Biletet må vere pulla på førehand, slik at pull-tid ikkje kjem med. |
   | Køyretid | `make mcp-linkml-valider-modell` mot eit stort skjema (t.d. `dcat-ap-no`). Dersom piloten vert utvida til `linkml-local`, mål òg ein tung generator (t.d. `make gen-doc` for same skjema). |

   Køyretid er teke med fordi Python på musl (Alpine) i nokre tilfelle køyrer tregare enn på glibc. Oppstartstid vert venta å vere om lag uendra, sidan han i hovudsak er Python-import.
6. Avgjer ut frå måledata om piloten skal utvidast til `modell-utkast`/`begrep-utkast` og `linkml-local`.

## Pilotresultat (2026-11-06)

**Implementering:** stadia `distroless-cc`, `distroless-builder` og `validator-distroless` er lagde til i `src/assets/containers/Dockerfile.mcp-linkml`. Stadiet `validator` er urørt, og `release.yml` og `make/60-mcp.mk` byggjer framleis Alpine-varianten.
- Builderen finn delte bibliotek med `ldd`. Bibliotek som ikkje finst i `cc-debian13` (12 stk: libffi, libsqlite3, liblzma, libbz2, libmpdec, libuuid, libreadline, libncursesw/libpanelw, libtinfo, libgdbm, libdb) blir kopierte inn saman med dpkg-oppføringa si i `/var/lib/dpkg/status.d/`.
- Ein import-røyktest i builderen køyrer berre mot cc-root og dei innsamla biblioteka.
- `pip` er avinstallert i runtime-biletet.

**Verifisering (steg 3-4):**
- Ingen invokeringsstader overstyrer entrypoint eller kommando for validator-biletet.
- `tests/test-mcp-linkml-validator.json` gir svar på `initialize`, `tools/list` og `tools/call` utan `-v`-montering.
- Prosessen køyrer som uid 65532, og `--entrypoint sh` feilar med «executable file `sh` not found».
- `make analyse-container-copy-konsistens` fann ingen avvik.
- Valideringsresultatet for `dcat-ap-no` (silver) er identisk i begge bileta (valid, 0 feil, 1 åtvaring, like issues).

**Målingar (steg 5).** Begge bileta er nybygde på same maskin (WSL2/podman) med same linkml-oppløysing (1.12.1). Tidane er median av 10 køyringar.

| Målepunkt | Alpine (`validator`) | Distroless (`validator-distroless`) |
|---|---|---|
| Biletstorleik | 249 MB | 265 MB |
| Byggjetid, kald (`--no-cache`, 1 køyring) | 74 s | 55 s |
| Byggjetid, varm cache | 6,0 s | 8,5 s |
| Oppstartstid (til første `initialize`-svar) | 3,20 s (3,04-3,34) | 2,05 s (1,96-2,32) |
| Køyretid (`flatten-and-validate.bash` dcat-ap-no silver) | 6,27 s (6,05-6,50) | 4,62 s (4,51-4,88) |
| CVE OS-pakkar (trivy 0.58.1) | 0 | 70 (11 HIGH, 45 MEDIUM, 14 LOW), **alle utan fiks** |
| CVE Python-pakkar | 8 (5 HIGH), alle i pakkar som pip har bunta inn | 0 (pip avinstallert) |

**Tolking:**
- **Byggjetid:** Kald bygging er raskare med distroless. Alpine kompilerer fleire pakkar frå kjeldekode (antlr4-runtime, pyyaml, cfgraph, watchdog m.fl.). Talet byggjer på éi køyring og avheng av nettverket.
- **Oppstart og køyretid:** Begge er om lag 25-35 % raskare med distroless. Det er i tråd med at musl er tregare enn glibc for CPython. Årsaka er ikkje isolert vidare.
- **CVE-funn:** Tala kan ikkje samanliknast direkte. Debian rapporterer òg sårbarheiter som ikkje blir fiksa («no-DSA» og «unfixed»), medan Alpine sin secdb stort sett berre listar sårbarheiter med fiks. Ingen av bileta har funn i OS-pakkar som kan fiksast. Python-funna i Alpine forsvinn dersom pip blir avinstallert der òg.
- **Storleik:** Distroless er 16 MB større, som venta (sjå Ulemper 4).

**Trimming av stdlib-utvidingar (2026-11-06).** `_sqlite3`, `_curses`, `_curses_panel`, `readline`, `_dbm` og `_gdbm` er fjerna frå `lib-dynload` i `distroless-builder` før `ldd`-innsamlinga.
- **Import-sjekk:** Ein statisk sjekk av site-packages viste at berre `sqlalchemy` (sqlite-dialekten), `_pytest` og `sphinx` importerer desse modulane. Ingen av dei kodevegane blir brukte av validatoren.
- **Verifisering:**
  - Røyktesten går gjennom utan montering.
  - Alle 75 policy-testane (`tests/test_mcp_policies.py`) passerer.
  - Alle 33 `*-schema.yaml` i `src/linkml/` gir byte-identisk output og same exit-kode som Alpine-biletet (silver). Ingen `No module named`-feil.

| Målepunkt | Distroless før trimming | Distroless etter trimming |
|---|---|---|
| Innkopierte bibliotek | 12 | 5 (libbz2, libffi, liblzma, libmpdec, libuuid) |
| Biletstorleik | 265 MB | 261 MB |
| CVE OS-pakkar | 70 (11 HIGH) | 52 (6 HIGH, 37 MEDIUM, 9 LOW), alle utan fiks |
| Oppstartstid (median, 10×) | 2,05 s | 2,01 s |
| Køyretid (median, 10×) | 4,62 s | 4,60 s |

**Retta invokeringsfeil.** `make mcp-linkml-valider-modell-test` køyrer `$(MCP_IMAGE) python3 /work/tests/test_mcp_policies.py`. Med `ENTRYPOINT ["/usr/local/bin/python3"]` frå første pilotversjon ville det blitt `python3 python3 ...`. Kartlegginga i steg 3 fanga ikkje dette, fordi ho berre såg etter entrypoint-overstyringar. Stadiet brukar no same `CMD ["python", "server.py"]` som `validator`, utan ENTRYPOINT.

**Hovudgevinst:** Biletet har ikkje noko shell og køyrer som nonroot som standard. Det gir òg målbart raskare oppstart og køyring.

**Hovudkostnad:**
- Lista over delte bibliotek må haldast ved like.
- Trivy fann 70 Debian-funn utan fiks. Dei kan krevje ein policy for kva funn ein skal ignorere dersom CVE-skanning blir innført i CI.

## Estimert konsekvens for «Generate and publish» (2026-11-06)

Grunnlag: steg-tider frå siste fullstendige køyring utan cache (run `41668442621`, 2026-11-03, 7 min 0 s totalt). Lokalt målt faktor for distroless: 0,74 på køyretid og 0,74 på kald bygging.

| Fase | Brukar validatoren? | I dag | Estimat distroless | Verknad på total køyretid |
|---|---|---|---|---|
| `oppsett / build-image / mcp-linkml-validator` | byggjer biletet berre når hashen av `Dockerfile.mcp-linkml` er endra | 69 s (lengst av alle bilete; `linkml-local` 66 s) | ~51 s | **−3 s**, sidan `linkml-local` (66 s) då blir flaskehalsen. 0 s når biletet finst i GHCR. |
| `valider-og-analyser` (8 domene, parallelt med `generate`) | ja, «Valider alle skjema» | 4-18 s per domene, 85 s til saman | 3-13 s, ~63 s til saman | **0 s.** Lengste valideringsjobb (fint, 49 s) er ferdig før lengste `generate`-jobb (ap-no, 58 s). Validering ligg ikkje på den kritiske stien. Sparer ~22 s runner-tid. |
| pull av biletet (valider-/generate-jobbar) | – | 8-15 s for alle bileta | +12 MB ukomprimert | < 1 s |
| `generate` / `publish` | nei (`make validate` brukar `linkml-local`, publish brukar `mkdocs-local`/`python-pytest`) | – | – | 0 s |
| cacha køyringar | valideringssteget vert hoppa over | – | – | 0 s |

**Konklusjon:** Distroless-validatoren endrar i praksis ikkje den totale køyretida for workflowen: 0 s i vanlege køyringar, og om lag −3 s når `Dockerfile.mcp-linkml` er endra. Gevinsten er ~22 s runner-tid per ukacha køyring, og raskare validering i `validate.yml`/`reusable-validate.yml` og lokalt.

**Atterhald:**
- Faktoren 0,74 er målt i WSL2. På `ubuntu-22.04`-runnarane køyrer valideringa parallelt per manifest, og CPU-konkurransen der kan gi ein annan faktor.
- Steg-tidene byggjer på éi køyring.

## Handlingsliste

- [x] Brukaren avgjer om pilot på `mcp-linkml-validator` skal gjennomførast (ja, 2026-11-06)
- [x] Brukaren vel variant: `cc-debian13` med Python 3.15 kopiert inn frå `python:3.15-slim-trixie`
- [x] (Pilot) Steg 1-5 over, sjå «Pilotresultat»
- [ ] (Pilot) Steg 6: brukaren avgjer om `validator-distroless` skal erstatte `validator` (`release.yml`, `make/60-mcp.mk`) og om piloten skal utvidast
- [x] (Valfritt) Ikkje kopier inn stdlib-modular som validatoren ikkje brukar (`_sqlite3`, `_curses`, `readline`, `_dbm`/`_gdbm`), og dermed heller ikkje libsqlite3, ncurses, readline, libdb og gdbm. Gjennomført, sjå «Trimming av stdlib-utvidingar».
- [ ] (Valfritt) Vurder `pip uninstall -y pip` òg i Alpine-variantane. Det er dei pip-vendra pakkane som står for alle Python-CVE-funna der.
- [ ] (Valfritt, eiga avgjerd) Skriv om `batch-gen-xsd.sh`/`batch-asyncapi-validate.sh` til Python/Node før distroless for avrotize/asyncapi vert vurdert på nytt

## Avgjerder

- **Berre vurdering, ingen implementering.** Instruksen var å evaluere og skrive spec, så specen vert verande i `specs/backlog/`. (Seinare er piloten gjennomført etter eksplisitt instruks. Specen vert likevel verande i backlog fordi steg 6 er ei open brukaravgjerd.)
- **Pilot på `mcp-linkml-validator` i staden for `linkml-local`.** Validatoren er det einaste biletet som eksterne repo brukar direkte. Der er tryggleiksgevinsten størst, og bruksflata (stdio-JSON-RPC, ingen shell) er enklast.
- **Python 3.15 kopiert inn er tilrådd variant (retta etter oppfølgingsspørsmål).** Den første versjonen av specen rekna Python-nedgraderinga som hovudhinderet. Det var for strengt, sidan Python kan kopierast inn frå eit glibc-basert builder-bilete. Kostnaden er at ein sjølv må halde ved like lista over delte bibliotek.
- **Oppstartstid og køyretid er eigne målepunkt (brukarønske).** Oppstartstid er målt som tid til første JSON-RPC-svar, og køyretid som validering av eit stort skjema. Det gjer at pull-tid og Python-import kan skiljast frå sjølve arbeidet, og at ein eventuell musl/glibc-skilnad blir synleg.
- **Pilot som eige stadium, ikkje erstatning.** `validator-distroless` er lagt til ved sida av `validator`, slik at begge kan byggjast og målast frå same Dockerfile. Å byte publisert bilete (`release.yml`/`make/60-mcp.mk`) er ei eiga avgjerd.
- **Ingen nytt make-target for piloten.** Bygging og måling er gjort med direkte `podman build`/`podman run`. Det er innanfor unntaket «utvikling/feilsøking» i CLAUDE.md. Make-targeta blir oppdaterte dersom varianten vert vald som standard.
- **cc-debian13 i staden for cc-debian12.** Brukaren skreiv `cc-debian12`, men valde `cc-debian13` etter oppklaring. Debian 12 har glibc 2.36, mens slim-trixie har glibc 2.41, og distroless oppdaterer ikkje lenger debian12-tags.
- **dpkg-oppføringar for innkopierte bibliotek.** Utan dei såg ikkje trivy dei 12 innkopierte biblioteka: 25 funn, 9 av dei HIGH, var usynlege. Det ville ha undergrave tryggleiksgevinsten som piloten skal måle.
- **`pip uninstall -y pip` i runtime.** pip har ingen funksjon i eit bilete utan shell. Det fjernar òg dei pip-vendra pakkane frå CVE-skanninga.
- **Fjern berre `.so`-filene, ikkje reine Python-pakkar.** `sqlite3/`, `curses/` og `dbm/` ligg att i stdlib. Ein import feilar då med ein tydeleg `ModuleNotFoundError` for `_sqlite3` o.l. i staden for ein uklar feil, og endringa er minimal.
- **Policy-testane køyrde direkte mot pilotbiletet.** `make mcp-linkml-valider-modell-test` er avhengig av `build-docker-mcp-validator`. Med `MCP_IMAGE=mcp-linkml-validator-distroless` ville det targetet ha bygd Alpine-stadiet og overskrive pilot-taggen. Kommandoen frå targetet vart difor køyrd direkte med `podman run`.
- **Rettferdig samanlikning med nybygd Alpine-bilete.** Det lokale `mcp-linkml-validator` var bygd med linkml 1.11.1. Med dei opne versjonskrava vart pilotbiletet bygd med 1.12.1. Alpine-varianten vart difor bygd på nytt som `mcp-linkml-validator-alpine-pilot` (same oppløysing) i staden for å overskrive den lokale taggen.
- **Funn utanfor scope: linkml 1.12.1 og `linkml_relative_import_patch`.** Med linkml 1.12.1 skriv patchen «hoppar over patching ... kjeldekoden har endra seg». Dette gjeld begge variantane og kjem frå versjonskravet `>=1.11.1,<2.0.0`, ikkje frå distroless. Retta seinare ved å pinne `linkml==1.11.1` i `Dockerfile.mcp-linkml`, sjå `specs/backlog/linkml-relative-import-patch-1-12.md`. Pilotmålingane over er gjort med 1.12.1 i begge variantane, så samanlikninga står seg.
- **Ingen storleiksgevinst er lagt til grunn.** Distroless-python og python-alpine er om lag like store. Grunngjevinga er difor tryggleik, ikkje storleik, og dette må verifiserast med måling i steg 5.
