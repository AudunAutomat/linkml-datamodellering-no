# `linkml_relative_import_patch` mot linkml 1.12.1

## Bakgrunn

MCP-bileta (`Dockerfile.mcp-linkml`) har eit ope versjonskrav: `linkml>=1.11.1,<2.0.0`. Ved nybygging får dei
difor linkml/linkml-runtime 1.12.1. `linkml-local` er pinna til `linkml==1.11.1` og er ikkje råka.

Med 1.12.1 skriv `src/assets/scripts/utils/linkml_relative_import_patch.py` at han «hoppar over patching av
SchemaView.imports_closure()». Merkøren `_EXPECTED_SOURCE_MARKER_SCHEMAVIEW` finst ikkje lenger i kjelda.
Dette vart oppdaga i distroless-piloten (`specs/backlog/evaluering-distroless-baseimage.md`).

Den patcha `imports_closure()` gjer to ting:
- rettar BUG-15 (`bugs/relativ-import-via-versjonslast-url.md`)
- tømer `namespaces()`-cachen, som er workarounden for BUG-24 (`bugs/schemaview-namespaces-cache-importerte-prefiks.md`)

Når patchen vert hoppa over, forsvinn begge.

## Funn (2026-11-06)

Reproduksjonen brukar `src/linkml/oreg/javazonetalk/javazonetalk-schema.yaml`, som har ein versjonslåst
URL-import av `dcat-ap-no` v2.14.4 med relative importar vidare.

| | 1.11.1 utan patch | 1.11.1 med patch | 1.12.1 utan patch | 1.12.1 med patch (vert hoppa over) |
|---|---|---|---|---|
| BUG-15: `imports_closure()` | `Unknown CURIE prefix: https` | OK (5 skjema) | **OK (5 skjema)** | OK |
| BUG-24: `expand_curie("dqv:value")` | – | `http://www.w3.org/ns/dqv#value` | `dqv:value` | **`dqv:value`** |

1. **BUG-15 er retta upstream i 1.12.1.**
   - `imports_closure()` normaliserer ikkje lenger URL-nøklar (`"://" not in sn`).
   - Importar vert lasta med `_load_closure_import()`, som løyser rå-importen mot kjelda til importøren.
   - Denne delen av patchen trengst ikkje på 1.12.1.
2. **BUG-24 er ikkje retta i 1.12.1, og workarounden er tapt.**
   - `namespaces()` er framleis `@lru_cache(None)`, og ingen kode i `schemaview.py` kallar `cache_clear()`.
   - Konsekvens for validatoren: sjekken `schema_declares_standard_prefix` (`server.py`, brukt i `gold`, `felles-datakatalog` og `felles-begrepskatalog`) les `sv.namespaces()` etter `imports_closure()`.
   - Med eit minimalt skjema som berre får prefiksa sine via URL-importen, ga `namespaces()` **2 prefiks på 1.12.1 mot 27 på 1.11.1 med patch**. Det gir ein falsk feil «Ingen standard vokabularprefiks deklarert».
   - Ingen skjema i repoet er råka i dag. `javazonetalk` deklarerer `dct`/`dcat`/`skos` lokalt, og alle seks policyane gir identisk resultat på 1.11.1 og 1.12.1. Eksterne repo via `reusable-validate.yml` kan derimot bli råka.
3. **Patchen for `mergeutils` (punkt 2) er framleis aktiv.** Merkøren matchar. Han brukast berre av SchemaLoader-generatorane i `linkml-local` (1.11.1). Om han trengst på 1.12.1, er ikkje undersøkt.
4. **Det hastar.** `Dockerfile.mcp-linkml` er endra av distroless-piloten, så biletet-taggen (`hashFiles`) endrar seg. Ved neste push byggjer `ensure-images` `mcp-linkml-validator` på nytt med 1.12.1 og publiserer han til GHCR.

## Steg

1. **Pin versjonen** i `Dockerfile.mcp-linkml` til `linkml==1.11.1` og `linkml-runtime==1.11.1` i begge builder-stadia, slik `Dockerfile.linkml` gjer. Då hindrar ein at 1.12.1 vert publisert før steg 2-3 er gjort.
2. **(Ved medviten oppgradering til 1.12.x)** Gjer patchen versjonsbevisst:
   - Når merkøren manglar og `_load_closure_import` finst (1.12+), skal patchen ikkje erstatte `imports_closure()`. Han skal i staden pakke inn originalen og kalle `SchemaView.namespaces.cache_clear()` etterpå (BUG-24).
   - Åtvaringa skal berre skrivast når ingen av dei kjende variantane vert kjende att.
3. Legg til ein regresjonstest for BUG-24. Bruk `minimal-schema.yaml`-mønsteret frå reproduksjonen: berre `linkml`-prefiks lokalt, URL-import av `dcat-ap-no`, og sjekk at `namespaces()` inneheld `dct`/`dcat`/`skos`.
4. Oppdater `bugs/relativ-import-via-versjonslast-url.md` (BUG-15 retta upstream i 1.12.1), `bugs/schemaview-namespaces-cache-importerte-prefiks.md` (BUG-24 framleis til stades i 1.12.1) og `BUGS.md`.
5. Vurder `mergeutils`-patchen mot linkml 1.12.1 før `linkml-local` vert oppgradert.

## Handlingsliste

- [x] Brukaren avgjer: pin til 1.11.1 no (steg 1). Vald 2026-11-06.
- [x] Steg 1, sjå «Utført»
- [x] Steg 2-3
- [x] Steg 4
- [x] Steg 5

## Avgjerder

- **Steg 2-5 utført utan oppgradering.** Instruksen var å utføre stega, ikkje å oppgradere. Pinninga til 1.11.1 er behalden, og patchen er gjort trygg for begge versjonane, slik at ei seinare oppgradering berre krev endring av versjonsnummeret.
- **Versjonsgjenkjenning på `_load_closure_import`, ikkje på versjonsnummer.** Patchen kjenner att upstream-fiksen for BUG-15 på attributtet. Det er meir robust enn å lese `importlib.metadata`, sidan fiksen kan bli tilbakeført eller endra uavhengig av versjonsnummeret.
- **Wrapper i staden for kopi av upstream-koden på 1.12+.** BUG-15 er retta upstream, så ein kopi av `imports_closure()` ville berre ha bunde patchen til endå meir intern kode. Wrapperen kallar originalet og tømer cachen.
- **Testane ligg i `test_mcp_policies.py`, ikkje i ei ny fil.** Fila køyrer allereie i validator-biletet via `make mcp-linkml-valider-modell-test`. Ei ny fil ville ha kravd eit nytt make-target. BUG-24 viser seg dessutan i ein policy-sjekk.
- **`file://` i staden for HTTP-server i testane.** `file://`-importen gir same kodeveg (namn med `:`, URL-nøkkel, relativ import under URL) som `https://`, og testane vert deterministiske utan nettverk. Det er stadfesta med negative kontrollar på begge versjonane.

- **Reproduksjon i scratchpad, ikkje i repoet.** Testskjemaet med berre URL-import vart lagt utanfor repoet, for å ikkje lage eit nytt domeneskjema berre for diagnose. Steg 3 flyttar mønsteret inn som ein ekte test.
- **Pinning er tilrådd som første tiltak.** Pinninga er eitt-linjes, gjer bileta konsistente med `Dockerfile.linkml` og stoppar regresjonen før publisering. Ein versjonsbevisst patch krev test og bør gjerast saman med ei medviten oppgradering (jf. Python 3.14-diskusjonen).
- **Pinning gjeld begge builder-stadia.** Både `base-builder` (Alpine) og `distroless-builder` (pilot) er pinna, slik at piloten held fram med å kunne samanliknast med den publiserte varianten.
- **`policies/README.md` er omformulert, ikkje berre retta.** Den gamle teksten («kan endre seg med nye versjonar») var grunngjeven med det opne versjonskravet. Han er erstatta med at regelsettet berre endrar seg ved medviten oppgradering. `README.en.md` er oppdatert tilsvarande og stempla på nytt (`make translate-stamp`).

## Utført

Steg 1 (2026-11-06):
- `src/assets/containers/Dockerfile.mcp-linkml`: `linkml==1.11.1` og `linkml-runtime==1.11.1` i `base-builder` og `distroless-builder`.
- Utdaterte referansar til `>=1.11.1,<2.0.0` er retta:
  - `bugs/relativ-import-via-versjonslast-url.md`
  - `src/assets/scripts/utils/linkml_relative_import_patch.py` (docstring)
  - `src/mcp-linkml-validator/policies/README.md` og `README.en.md`
  - `specs/backlog/vurdering-codegraph-kompatibilitet.md`
- Verifisert:
  - `make build-docker-mcp-validator` og pilotbiletet gir begge linkml-runtime 1.11.1.
  - Ingen patch-åtvaring.
  - `namespaces()` gir 27 prefiks med URL-importtestskjemaet (BUG-24-workarounden er aktiv).
  - `make mcp-linkml-valider-modell-smoke` gir 3 svar.
  - `make mcp-linkml-valider-modell-test` gir 75/75 OK.
  - `javazonetalk` og `dcat-ap-no` validerer (silver).
  - `make translate-check` gir 26 passed, og `make translate-status` viser 0 utdaterte.

Steg 2-5 (2026-11-06, etter eksplisitt instruks):
- **Steg 2:** `linkml_relative_import_patch.py`: ny `_wrap_imports_closure_with_namespaces_reset()`.
  - Når 1.11.1-merkøren manglar og `SchemaView._load_closure_import` finst (1.12+), vert upstream `imports_closure()` pakka inn med `namespaces.cache_clear()`. Wrapperen eksponerer `cache_clear`/`cache_info` som originalet.
  - Åtvaringa vert berre skriven når ingen kjend variant vert kjend att.
  - Docstringen er oppdatert.
- **Steg 3:** `tests/test_mcp_policies.py`: ny `ImportPatchRegressionTest` med 4 testar.
  - Testane: BUG-15 SchemaView, BUG-24 `namespaces()`, BUG-15 mergeutils via `PythonGenerator`, og BUG-24 gjennom `felles-begrepskatalog`-policyen.
  - Testane brukar `file://`-import i tempdir, så dei køyrer utan nettverk.
  - Køyrer via `make mcp-linkml-valider-modell-test`.
- **Steg 4:**
  - `bugs/relativ-import-via-versjonslast-url.md` og `bugs/schemaview-namespaces-cache-importerte-prefiks.md`: ny seksjon «Verifisering 2026-11-06».
  - `BUGS.md`: BUG-15 (SchemaView-delen retta i 1.12.x, mergeutils framleis) og BUG-24 (framleis i 1.12.1).
- **Steg 5:** `mergeutils.resolve_merged_imports()` er identisk i 1.11.1 og 1.12.1. `PythonGenerator` feilar utan patch på begge versjonane. Patchen trengst framleis og fungerer på 1.12.1.

Verifisering:

| Oppsett | Resultat |
|---|---|
| linkml 1.11.1 med patch (`make mcp-linkml-valider-modell-test`) | 79/79 OK |
| linkml 1.12.1 med ny patch (heile suiten, `--network none`) | 79/79 OK, inga åtvaring |
| 1.11.1 utan patch (negativ kontroll) | 4/4 regresjonstestar feilar |
| 1.12.1 utan patch (negativ kontroll) | 3/4 feilar. BUG-15 SchemaView passerer, sidan han er retta upstream |
| `linkml-local` (1.11.1) med patch, offline-reproduksjon | BUG-15, BUG-24 og mergeutils OK |
| `make lint SCHEMA=.../javazonetalk-schema.yaml` | ingen problem |

Pinninga til `linkml==1.11.1` i `Dockerfile.mcp-linkml` er behalden. Ei oppgradering til 1.12.x er no førebudd, men er ei eiga avgjerd.
