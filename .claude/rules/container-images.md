---
name: container-images
description: Container-invokeringsmønster i make/01-containers.mk, make/60-mcp.mk, Makefile og Dockerfile*/requirements*.txt under src/assets/containers/ — WORK_MOUNT, eksplisitt env-vidareføring, stdin-fella (BUG-10), attribution-plikt for nye verktøy, full kartlegging av monteringsstader for nye delte moduler (inkl. Dockerfile COPY-lister, frittståande orkestreringsskript og .mcp.json), kartlegging av kommandooverstyringar ved endring av ENTRYPOINT/CMD, pakkemetadata for innkopierte bibliotek (distroless/CVE-skanning). Lastast automatisk ved arbeid med desse filene.
paths:
  - "src/assets/containers/**"
  - "make/01-containers.mk"
  - "make/60-mcp.mk"
  - "Makefile"
  - "src/assets/scripts/scaffolding/**"
  - "src/mcp-*/flatten-and-validate.bash"
  - ".mcp.json"
---

## WORK_MOUNT-mønsteret

Alle container-wrapparar i `make/01-containers.mk` mountar repoet som
`/work` og køyrer med `-w /work` via delt
`WORK_MOUNT := -v "$(CURDIR):/work" -w /work`. **Unntak:** `DOCS_RUN`
(mkdocs) bryt mønsteret medvite — mountar berre `mkdocs/build` (byggjetre og
konfig per språk), `mkdocs/.cache` og `mkdocs/site` som separate
delmonteringar, for å unngå unødvendig I/O av resten av
repoet. Følg same mønster (heile repoet via `WORK_MOUNT`, eller selektive
delmonteringar dersom containeren berre treng ein avgrensa del) når du legg
til ein ny container-wrapper.

## Miljøvariablar må vidareførast eksplisitt

`-e <NAVN>` (utan verdi) i eit `podman run`-kall vidarefører variabelen frå
den kallande prosessen sitt `os.environ` inn i containeren — dette er
**ikkje** det same som å hardkode ein verdi, og variabelen forsvinn stille
dersom `-e`-linja manglar. Container-wrapparane vidarefører i dag:

| Variabel | Kvifor |
|---|---|
| `LOGLVL` | Styrer detaljnivå i batch-scripta (DEBUG/INFO/ERROR) |
| `CLR_STEP`/`CLR_RST`/`CLR_OK`/`CLR_ERR` | Fargekodar for terminaloutput i batch-generate.py/check-import-duplicates.py |
| `BATCH_GENERATE_WORKERS` | Talet på `ProcessPoolExecutor`-workers for parallelle generatorar (defaultar til 6 om usett) |
| `GITHUB_REPOSITORY` | GitHub Actions sin automatisk sette owner/repo-variabel — trygt no-op lokalt |

Legg til ein ny `-e <NAVN>` når eit script under `src/assets/scripts/`
byrjar lese ein ny miljøvariabel — elles ser scriptet han aldri, sjølv om
han er sett i den kallande shellen.

## BUG-10: `podman run -i` et stdin frå omsluttande `while read`-løkker

`PYTHON_RUN` brukar `-i` (interaktiv stdin) for å støtte kallarar som
pipar/heredoc-ar inn data. Dette har ei alvorleg fallgruve: eit
`$(PYTHON_RUN)`-kall inni ei
`while IFS= read -r x; do ... done < <(...)`-løkke (prosess-substitusjon)
**konsumerer resten av løkka sin fd 0** — berre det *første* elementet vert
prosessert, deretter avsluttar løkka **stille**, utan feilmelding og utan
ikkje-null exit code. Sjå
`bugs/podman-interactive-stdin-konsumerer-while-lokke.md` (BUG-10) for full
diagnose — retta i `validate-examples`/`validate-bronze`, men mønsteret kan
reintroduserast i eit nytt target.

**Regel:** eit `$(PYTHON_RUN)`-kall (eller anna `podman run -i`) inni ei
`while read < <(...)`-løkke **må** omdirigere sin eigen stdin:

```bash
$(PYTHON_RUN) python3 /work/src/assets/scripts/... < /dev/null
# eller, dersom kallet faktisk treng input frå ein variabel:
$(PYTHON_RUN) python3 /work/src/assets/scripts/... <<< "$$var"
```

Alternativt: bygg om til `for x in $$(...)`-mønsteret, som ikkje deler fd 0
mellom iterasjonar (uegna for svært store lister, sidan heile ordlista må
evaluerast i minnet før løkka startar). `validate-data` brukar dette
mønsteret og er ikkje råka av same feil.

## Ein ny påkravd delt modul krev full kartlegging av alle monteringsstader

Ei fil under `src/assets/scripts/utils/` som eit `server.py`/script **ikkje
kan starte utan** (i motsetnad til ein valfri bug-workaround med mjuk
try/except-fallback, t.d. `linkml_relative_import_patch.py`) må vere
tilgjengeleg i **kvar einaste** kontainarinvokering av det scriptet — ikkje
berre det opplagte `-run`/`-smoke`-make-targetet. Same fallgruve som
env-variabel-vidareføringa over («forsvinn stille dersom `-e`-linja
manglar»), berre for filmonteringar: mankar mounten éin stad, feilar akkurat
den kodevegen med `ModuleNotFoundError` — gjerne først i CI eller hos ein
ekstern brukar, lenge etter at dei "opplagte" targeta er verifiserte.

**Framgangsmåte** (jf. konsolideringa av `mcp_jsonrpc_stdio.py` på tvers av
dei tre MCP-serverane, `specs/done/mcp-server-python-tiltak.md`): grep heile
repoet etter **alle** stader det aktuelle scriptet vert køyrt i ein
kontainer, ikkje berre Makefile-targeta:

1. Make-variablar for interaktiv køyring (t.d. `MCP_RUN`, `LINKML_MOD_RUN`
   i `Makefile`/`make/60-mcp.mk`)
2. `-test`-oppskrifter som monterer kjeldekatalogen separat frå
   `-run`/`-smoke` (ofte ein annan monteringssti/`PYTHONPATH`, difor ikkje
   automatisk dekt av (1))
3. Scaffolding-/orkestreringsscript som byggjer sine eigne `podman run`-kall
   direkte (t.d. `src/assets/scripts/scaffolding/new-modell.sh`,
   `src/mcp-linkml-validator/flatten-and-validate.bash`) — desse
   duplekserer make-variablane sine monteringar manuelt og må oppdaterast
   separat
4. `tests/test_make.sh` sine direkte `podman run`-kall (skil seg frå
   make-targeta sine, søk spesifikt etter scriptnamnet)
5. CI-cache-nøklar i `.github/workflows/*.yml` som eksplisitt listar
   avhengige filer (`hashFiles(...)`) — ei ny transitiv avhengigheit må
   leggjast til der, elles gjev ei framtidig endring i modulet eit stille
   cache-hit i staden for reell re-køyring
6. **`Dockerfile*` sine `COPY`-lister** — den avgjerande, lett gløymde
   staden: eit `podman run`-kall utan eksplisitt filmontering (t.d. det
   publiserte `ghcr.io/audunautomat/*`-biletet brukt av reusable workflows/eksterne
   repo) er heilt avhengig av at modulen faktisk vart bygd inn i biletet.
   Sjekk **kvart** `FROM ... AS <stadium>`-steg i `Dockerfile.mcp-linkml`
   (validator/modell-utkast/begrep-utkast har separate `COPY`-linjer) —
   ikkje anta at éin retta `COPY`-linje dekker alle tre. Verifiser med ein
   reell `podman build` + køyring **utan** noka ekstra `-v`-montering
   utover det biletet sjølv inneheld — det er den einaste måten å fange opp
   at ei fil berre finst via lokal bind-mount, ikkje i biletet.
7. **`.mcp.json`** i repo-rota — kontributørane sitt eige lokale Claude
   Code MCP-oppsett for dei tre serverane, heilt separat frå
   Makefile-måla og difor ikkje dekt av punkt 1-2.

Konkret hending der punkt 3, 6 og 7 mangla frå denne sjekklista sjølv (ein
tidlegare versjon av dette avsnittet dekte berre punkt 1-5): konsolideringa
av `mcp_jsonrpc_stdio.py` oppdaterte `Makefile`/`make/60-mcp.mk`/
`new-modell.sh`/`tests/test_make.sh`, men verken
`Dockerfile.mcp-linkml` sine `COPY`-linjer,
`flatten-and-validate.bash` (brukt av
`.github/workflows/reusable-validate.yml` — den eksterne
bootstrap-valideringsvegen) eller `.mcp.json`. Stadfesta reprodusert:
`podman build ... --target validator` etterfølgt av `podman run -i --rm
mcp-linkml-validator` (utan `utils`-montering) gav
`ModuleNotFoundError: No module named 'mcp_jsonrpc_stdio'`. Sjå
`specs/done/rule-full-kartlegging-manglar-dockerfile-og-mcp-json.md`.

**Automatisert kontroll (punkt 6 og 7):** `make analyse-container-copy-konsistens`
(`src/assets/scripts/makefile/check-container-copy-coverage.py`) sjekkar
punkt 6 (Dockerfile-`COPY`-dekning for kvar `server.py` med eit
`sys.path.insert(0, "/app/utils")`-mønster) og eit avgrensa tilfelle av
sparse-checkout-dekning for reusable workflows (punkt 5) automatisk — køyr
han etter endringar i `Dockerfile.mcp-linkml` eller ein ny/endra delt
utils-modul. Dekker **ikkje** punkt 1-4 og 7 (`.mcp.json`, make-variablar,
`-test`-oppskrifter, scaffolding-script) — desse må framleis sjekkast for
hand.

For sjølve scriptet: prøv fleire kandidat-`sys.path`-oppføringar (éin per
kjend monteringsmønster: flatt i same katalog som scriptet, `/repo/...` for
heile-repo-monteringar, repo-relativ sti for direkte git-checkout-køyring)
— men **ikkje** legg til ein mjuk try/except-fallback slik
`linkml_relative_import_patch.py` gjer. Den fallbacken er trygg berre fordi
patchen er ein valfri bug-workaround; ein hard avhengigheit skal krasje
høgt med ein naturleg `ImportError` dersom ingen kandidat finn fila.

## Endring av ENTRYPOINT/CMD krev kartlegging av kommandooverstyringar

`podman run <image> <args>` erstattar `CMD`, men legg `<args>` **etter**
`ENTRYPOINT`. Eit bilete som går frå berre `CMD ["python", "server.py"]`
til `ENTRYPOINT ["python3"]` + `CMD ["server.py"]`, oppfører seg likt når
det vert køyrt utan argument. Kvar kallar som sender med ein eigen
kommando (`$(MCP_IMAGE) python3 /work/tests/...`), får derimot
`python3 python3 /work/...`, og det feilar.

**Aldri** avgrens kartlegginga til `--entrypoint`-overstyringar når
`ENTRYPOINT` eller `CMD` vert endra. Det er argumenta *etter*
image-navnet som vert råka.

**Framgangsmåte:**

1. Bruk dei same invokeringsstadene som i lista under «Ein ny påkravd
   delt modul krev full kartlegging av alle monteringsstader» (punkt
   1-4 og 7, pluss `.github/workflows/*.yml`). Søk der etter image-navnet
   og make-variabelen (t.d. `MCP_IMAGE`, `mcp_image`, `MCP_RUN`), ikkje
   etter `--entrypoint`.
2. For kvart treff: sjekk om noko følgjer etter image-referansen. Det
   gjeld argument i shell- og make-linjer (`$(MCP_IMAGE) python3 ...`),
   og element etter `mcp_image` i Python-`subprocess`-lister.
3. Føretrekk berre `CMD` utan `ENTRYPOINT` når bilete i repoet
   allereie vert køyrde med eksplisitt kommando. Då er semantikken for
   eksisterande kallarar uendra.
4. Verifiser med minst éin reell køyring som overstyrer kommandoen
   (t.d. kommandoen frå eit `-test`-target), ikkje berre køyring utan
   argument.

Konkret hending: første versjon av distroless-piloten for
`mcp-linkml-validator` innførte `ENTRYPOINT ["/usr/local/bin/python3"]`.
Kartlegginga fann ingen `--entrypoint`-overstyringar og vart rekna som
ferdig. `make mcp-linkml-valider-modell-test` (`make/60-mcp.mk`) sender
likevel `python3 /work/tests/test_mcp_policies.py` som kommando og ville
ha feila. Feilen vart først oppdaga i neste testrunde. Sjå
`specs/backlog/evaluering-distroless-baseimage.md` (Retta invokeringsfeil)
og `specs/done/rule-entrypoint-cmd-kartlegging.md`.

## Innkopierte bibliotek må ha pakkemetadata

CVE-skannarar som trivy finn OS-pakkar via pakkedatabasen i biletet
(`/var/lib/dpkg/status.d/` i distroless, `/var/lib/dpkg/status` i Debian,
`/lib/apk/db/installed` i Alpine), ikkje ved å sjå på filene. Eit delt
bibliotek som vert kopiert inn med `COPY --from=<builder>` utanom
pakkehandsamaren, er difor **usynleg** for skanninga. Biletet ser
tryggare ut enn det er, og CVE-ar i biblioteket vert aldri rapporterte.

**Aldri** kopier inn `.so`-filer (t.d. funne med `ldd` for å få Python
til å køyre i `gcr.io/distroless/cc-*`) utan å òg kopiere inn
pakkeoppføringa for pakken som eig fila.

**Framgangsmåte** (Debian-basert builder → distroless):

1. Finn eigarpakken: `pkg=$(dpkg -S "$(readlink -f "$lib")" | cut -d: -f1)`
   (bruk `readlink -f`, sidan `ldd` kan rapportere ein sti via
   `/lib`-symlenkja som dpkg ikkje kjenner).
2. Skriv oppføringa i distroless-format, éi fil per pakke:
   `dpkg-query -s "$pkg" > /runtime-libs/var/lib/dpkg/status.d/$pkg`,
   og kopier `/runtime-libs/` inn i runtime-stadiet saman med biblioteka.
3. Verifiser med ei skanning av det ferdige biletet at kvar innkopierte
   pakke dukkar opp (`trivy image --input <tar>` køyrt som container). Ein
   innkopiert pakke med null treff, sjølv om han er kjend for å ha
   CVE-ar, er eit teikn på at oppføringa manglar.

Konkret hending: i distroless-piloten for `mcp-linkml-validator` vart 12
bibliotek (libsqlite3, libuuid, libffi, libncursesw m.fl.) kopierte inn
utan dpkg-oppføring. Den første trivy-skanninga viste 45 OS-funn. Med
oppføringane på plass viste ho 70: 25 funn var usynlege, 9 av dei HIGH.
Sjå `specs/backlog/evaluering-distroless-baseimage.md` (Pilotresultat
og Avgjerder) og `src/assets/containers/Dockerfile.mcp-linkml`
(`distroless-builder`).

## Attribution-plikt for nye verktøyavhengigheiter

Legg du til eit nytt verktøy i `Dockerfile*` eller `requirements*.txt` som
endar opp bundla i eit publisert containerbilete: sjekk om lisensen krev
attribution (typisk MIT, BSD, Apache-2.0, EPL) og oppdater
attributions-tabellen i `mkdocs/docs/om.md` ved behov. Sjå `CONTRIBUTING.md`
§ "Nye verktøyavhengigheiter" og `specs/done/verktoy-lisensoversikt.md` for
metode og eksisterande klassifisering.
