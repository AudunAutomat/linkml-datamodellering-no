# Rett dei 41 feila i `make test`

## Bakgrunn

`make test` (`tests/test_make.sh`) gir **487 OK og 41 feil**, med identisk feilliste på linkml 1.11.1 og
1.12.1 (`specs/done/oppgrader-linkml-1-12-1.md`). Feila har altså ikkje med linkml-versjonen å gjere.
`make test` køyrer ikkje i CI (ingen treff på `make test`/`test_make.sh` i `.github/workflows/`), og det
forklarar truleg kvifor feila ikkje er oppdaga.

Feila fell i to grupper med ulik rotårsak.

### Gruppe A: 36 «Fil manglar» i Fase B (generator slått av i `build.yaml`)

| Test | Skjema (9 ap-no-profilar) |
|---|---|
| `gen-jsonld`, `gen-python`, `gen-jsonschema`, `gen-proto` | `cpsv-ap-no`, `dcat-ap-no`, `dqv-ap-no`, `dqv-core`, `modelldcat-ap-no`, `modelldcat-katalog`, `modelldcat-modell`, `skos-ap-no`, `xkos-ap-no` |

**Rotårsak (stadfesta):**
- **Fase A** genererer artefakter via `batch-generate.py` og hoppar over generatorar som ikkje er `true` i
  `build.yaml` (`read_build_yaml_flag()`: `^  <flag>: true$`, manglande fil/flagg = av). Flagg-namna:
  `jsonld_context`, `python`, `json_schema`, `protobuf`.
- **Fase B** (`run_schema_tests()`, `test_gen_jsonld`/`test_gen_python`/`test_gen_jsonschema`/
  `test_gen_proto`) sjekkar at artefakta finst **utan** å lese `build.yaml`.
- Artefakter som er slått av, vert difor aldri genererte, og Fase B rapporterer «Fil manglar».

**Feilen er større enn 36 tilfelle.** 13 andre skjema med same flagg slått av passerer berre fordi gamle
artefakter frå 2026-08-04/05 ligg att i `generated/`, som er gitignorert og aldri vert rydda:
- `fair-metadata`
- alle 7 `fint-*`
- alle 5 `*-modellkatalog`

Flagga vart slått av 2026-08-07 (`0987f9cb`). Testane «passerer» altså på artefakter som ikkje lenger
vert produserte. I ein rein checkout vil desse òg feile.

### Gruppe B: 5 `roundtrip-ttl`-feil (BUG-3)

| Skjema | Feil |
|---|---|
| `fint-administrasjon`, `fint-okonomi`, `fint-personvern`, `fint-utdanning`, `samt-bu` | `MappingError: No pred for <container-attributt-URI>` i ttl→yaml-steget |

**Rotårsak (stadfesta, `bugs/mappingerror-rdflib-roundtrip.md`):**
- `RDFLibDumper` brukar `induced_slot()` (URI-en til attributtet).
- `RDFLibLoader` byggjer predikattabellen frå `all_slots()`, der ein global slot med same navn vinn.
- Status er `upstream`, og feilen er framleis til stades i 1.12.1.

**Same kodelinje som BUG-2.** Både BUG-2 (`bugs/inlined-as-list-rdflib-roundtrip.md`) og BUG-3 kjem frå
`rdflib_loader.py` linje 99 (1.12.1):

```python
uri_to_slot = {URIRef(schemaview.get_uri(s, expand=True)): s for s in schemaview.all_slots().values()}
```

Tabellen er global og bygd frå `all_slots()`:
- BUG-2: når to slots deler `slot_uri`, vinn den siste.
- BUG-3: når eit attributt har same navn som ein global slot, vinn den globale sloten.

Ein tabell bygd per subjektklasse frå `induced_slot()` vil truleg rette begge. Det er ikkje stadfesta før
MRE-ane i `specs/backlog/upstream-linkml-bugrapportar.md` § U1 og § U2 er køyrde med ein slik endring.
`.claude/rules/bug-diagnostisering.md` punkt 6 (slå saman bugs med same rotårsak) må vurderast etter at
dette er stadfesta. Mekanismane er ulike, men kodelinja er den same.

Bug-fila seier at skjemaa «ikkje er i skip-lista — dei køyrer og feilar». Det bryt konvensjonen i
CLAUDE.md (§ Kjente feil): ein kjend feil med workaround skal ha eit skip-vilkår med BUG-referanse,
slik BUG-2 og BUG-19 har i `roundtrip_ttl_job()`/`test_roundtrip_ttl()`.

## Steg

1. **Gruppe A, gate Fase B på `build.yaml`.**
   - I `run_schema_tests()`: køyr `gen-jsonld`/`gen-python`/`gen-jsonschema`/`gen-proto` berre når høvesvis `jsonld_context`/`python`/`json_schema`/`protobuf` er `true`. Elles skal testen skrive ei «Hoppar over … (<flag>: false i build.yaml)»-linje, same mønster som `example_rdf`-sjekken (linje ~108/~1358).
   - Bruk same tolking som `read_build_yaml_flag()` i `batch-generate.py` (berre eksplisitt `true` er på).
   - Vurder om dei andre flagg-styrte Fase B-testane (`gen-rdf`/`rdf`, `gen-shacl`/`shacl`, `gen-owl`/`owl`, `gen-erdiagram-mermaid`/`erdiagram`, `gen-schema-docs`/`docs`, `gen-plantuml`/`plantuml`) har same svakheit. Rett dei i same omgang dersom dei har det.
2. **Gruppe A, hindre falske OK frå gamle artefakter.** Fase B må ikkje kunne passere på filer som Fase A ikkje har skrive i same køyring. Brukaren vel alternativ. Sjå «Val 1» under.
3. **Gruppe B, BUG-3.** Brukaren vel alternativ. Sjå «Val 2» under.
   - Ved (a): skip i `roundtrip_ttl_job()` og `test_roundtrip_ttl()` for dei 5 skjemaa, etter konvensjonen («Hoppar over roundtrip-ttl for $name (BUG-3: …)»). Oppdater `bugs/mappingerror-rdflib-roundtrip.md` (fjern «ikkje i skip-lista») og `BUGS.md`.
   - Ved (b): patch i `src/assets/containers/patches/` og nytt steg i `Dockerfile.linkml`. Køyr MRE-ane U1/U2 med og utan patch. Fjern BUG-2-skip som patchen gjer overflødige. Køyr `make test` og `convert-instance-rdf` på nytt.
4. **Verifiser i rein tilstand.**
   - Flytt `generated/` til side (eller bruk alternativ 2c), og køyr `make test`.
   - Forventa: 0 feil, og skip-linjer for alle generatorar som er slått av og for BUG-3-skjemaa.
   - Køyr deretter `make test` på nytt med eksisterande `generated/`, for å stadfeste at resultatet er likt.
5. **Vurder `make test` i CI** (valfritt, eiga avgjerd). At feila ikkje vart oppdaga, kjem av at testen ikkje køyrer automatisk. Eit CI-steg må vurderast mot køyretida (~150 s lokalt) og eksisterande jobbar i `validate.yml`.

## Val som må takast

### Val 1 (steg 2): hindre falske OK frå gamle artefakter

Fase B sjekkar berre at ei fil *finst* i `generated/`, og katalogen vert aldri tømd.

| | (a) Slett før generering | (b) Sjekk mtime | (c) Eigen output-katalog |
|---|---|---|---|
| **Korleis** | Fase A slettar artefakta `make test` produserer, før generering | Testen legg ei markørfil ved oppstart. Fase B krev at artefakta er nyare enn markøren. | `make test` skriv til t.d. `tmp/test-generated/` i staden for `generated/` |
| **Omfang** | Middels. Kvar generator må ha liste over filene han eig. | Lite. Om lag 5 linjer i `assert_file_nonempty()` og oppstarten | Størst. `GEN_DIR` er hardkoda i `test_make.sh` (linje 23) og sett med `:=` i `make/00-settings.mk`, så han må sendast eksplisitt til kvart make-kall. Andre sjekkar kan ha hardkoda stiar. |
| **Fangar gamle filer** | Ja | Ja, for alle Fase B-sjekkar | Ja, fullt isolert |
| **Ryddar `generated/`** | Ja | Nei, gamle filer ligg att | Nei, men testen rører ikkje `generated/` |
| **Bieffekt** | Må ikkje slette filer som berre `make domain-*` produserer (java, xsd, openapi). Elles manglar dei i den lokale portalen til neste domene-køyring. | Ingen | `make test` gir ikkje lenger ferske artefakter i `generated/` |

**Tilråding: (b).** Det er den minste endringa og fangar problemet generelt. Gamle filer ligg framleis lokalt i
`generated/`, men CI startar med ein rein checkout. Lokal opprydding kan leggjast til seinare som (a), avgrensa
til generatorar som er slått av.

### Val 2 (steg 3): BUG-3

| | (a) Skip med BUG-3-referanse | (b) Lokal patch av `rdflib_loader` | (c) Modellendring |
|---|---|---|---|
| **Korleis** | 5 skjema til skip-lista, som for BUG-2/BUG-19 | Predikattabell per subjektklasse frå `induced_slot()`. Same mekanisme som `docgen-max-chars.patch`/`javagen-custom-typemap.patch`. | Gi containerattributtet nytt navn, eller eksplisitt `slot_uri` |
| **Omfang** | Lite: skip-liste, bug-fil og `BUGS.md` | Middels: 10-15 linjer patch, MRE-test og verifisering | Middels til stort: 5 skjema, nye skjemaversjonar |
| **Testdekning** | Inga roundtrip-TTL-dekning for 5 skjema | Truleg dekning for dei 5 BUG-3-skjemaa **og** BUG-2-skjemaa som er skippa i dag (`ngr-adresse`, `ngr-eiendom`, `ngr-virksomhet`, 5 `*-modellkatalog`) | Berre dei 5 BUG-3-skjemaa |
| **Vedlikehald** | Ingen. Skip vert fjerna når upstream rettar feilen. | Patchen må verifiserast ved kvar linkml-oppgradering (`.claude/rules/container-images.md` § linkml-pinning) | Ingen |
| **Risiko** | Ingen | Endrar korleis TTL vert lasta. `convert-instance-rdf` og `make test` må køyrast på nytt. | Endrar serialiseringsformatet (nytt attributtnavn), eller bryt `.claude/rules/linkml-schema.md` § Containerklasse (ingen `slot_uri` på containerattributt) |

**Tilråding:** (a) for ein grøn test raskt og med minst risiko. (b) dersom roundtrip-dekning er viktig: gevinsten
er større enn dei 5 testane, sidan patchen truleg òg rettar BUG-2. Det er ikkje stadfesta før U1/U2 er
køyrde med patchen.

**Mellomveg:** (a) no, og (b) som eigen spec seinare. Då vert skipa for BUG-3 fjerna når patchen er på plass.

## Handlingsliste

- [x] Steg 1: gate Fase B-testar på `build.yaml`-flagg
- [x] Brukaren vel alternativ for Val 1 (steg 2): **(b) sjekk mtime** (2026-11-06)
- [x] Brukaren vel alternativ for Val 2 (steg 3): **(a) skip med BUG-3-referanse** (2026-11-06)
- [x] Steg 2: hindre falske OK frå gamle artefakter
- [x] Steg 3: BUG-3
- [x] Steg 4: verifiser `make test` i rein tilstand og med eksisterande `generated/`
- [ ] Steg 5: (valfritt) vurder `make test` i CI. **Ikkje gjennomført**, eiga avgjerd.

## Avgjerder

- **Val 1: (b) sjekk mtime (brukarval).** Markørfila `tmp/.test_make_start` vert laga ved oppstart. `assert_file_nonempty()` krev at fila er nyare (`-nt`). Ingen generator hoppar over skriving av uendra filer (sjekka i `batch-generate.py` og `batch-render-plantuml.sh`), så sjekken gjev ikkje falske feil.
- **Val 2: (a) skip med BUG-3-referanse (brukarval).** Same mønster som BUG-2/BUG-19: `case` i `roundtrip_ttl_job()` og ei forklarande `elif`-grein i `test_roundtrip_ttl()`.
- **Flagg-gating for alle 10 flagg-styrte Fase B-testar, ikkje berre dei 4 som feila.** `shacl`, `owl`, `rdf`, `erdiagram`, `docs` og `plantuml` hadde same svakheit (flagg av for fleire skjema). Dei vart maskerte av gamle filer og ville feila saman med mtime-sjekken.
- **Gating i testfunksjonen, ikkje i `run_schema_tests()`.** `skip_disabled_generator` vert kalla først i kvar `test_gen_*`, same stad som eksisterande skip (BUG-17 i `test_gen_rdf`). Då står skip-linja i testloggen, og testen tel som OK.
- **For `gen-rdf` kjem flagg-sjekken etter BUG-17-sjekken.** Skjema med versjonslåst import får difor framleis BUG-17-grunngjevinga.
- **`generated/` vart flytta til side og lagt tilbake for den reine køyringa.** Backup i scratchpad (8928 filer, 85 MB). Etter testen vart katalogen erstatta med backupen, slik at artefakter som berre `make domain-*` lagar (java, xsd o.l.), ikkje forsvann lokalt.

- **Ein spec for begge gruppene.** Brukaren bad om éin spec for dei 41 feila. Gruppene har ulik rotårsak og kan gjennomførast uavhengig av kvarandre, og steg 1-2 og 3 er difor skilde.
- **Gruppe A-omfanget er utvida til skjema som passerer falskt.** Å berre rette dei 36 synlege tilfella ville la dei 13 skjemaa som passerer på gamle artefakter, stå att som ein skjult feil. Dei ville då feile i ein rein checkout.
- **Tilråding gitt, men valet er brukaren sitt.** For Val 1 er (b) tilrådd (minst endring, generell). For Val 2 er (a) eller mellomvegen (a, så b) tilrådd. Valet mellom testdekning og vedlikehald av endå ein lokal patch er ei prioritering brukaren må gjere.
- **BUG-2-funnet er teke med i Val 2.** At BUG-2 og BUG-3 kjem frå same linje i `rdflib_loader.py`, vart oppdaga under utgreiinga av vala. Det endrar kost/nytte for (b) vesentleg, og står difor i specen sjølv om BUG-2 ikkje er ein del av dei 41 feila.

## Utført

2026-11-06:
- `tests/test_make.sh`:
  - `TEST_START_MARKER` og mtime-sjekk i `assert_file_nonempty()`
  - nye hjelpefunksjonar `generator_enabled()` og `skip_disabled_generator()`
  - flagg-gating i `test_gen_{jsonld,python,jsonschema,rdf,erdiagram,docs,shacl,owl,proto,plantuml}`
  - BUG-3-skip i `roundtrip_ttl_job()` og `test_roundtrip_ttl()`
- `bugs/mappingerror-rdflib-roundtrip.md`: skip dokumentert, merknad om felles kodelinje med BUG-2.
- `BUGS.md`: BUG-3-rada markerer at roundtrip-ttl vert hoppa over.
- `tests/README.md`: BUG-3-radene i roundtrip-tabellen er endra frå FEIL til skip, og det er lagt til ein merknad om flagg-gating og mtime-sjekk.

Verifisert:

| Køyring | Resultat |
|---|---|
| Før (1.11.1 og 1.12.1) | 487 OK, 41 feil |
| `make test` med eksisterande `generated/` (gamle filer til stades) | **528 OK, 0 feil** (141 s) |
| `make test` utan `generated/` (rein tilstand) | **528 OK, 0 feil** (159 s) |
| mtime-sjekken isolert: fil frå 2026-08-05 / ny fil | feil / OK, som forventa |

Skip i køyringa:
- etter `build.yaml`-flagg: 21 × gen-python, gen-proto og gen-jsonld, 15 × gen-jsonschema, 11 × gen-shacl, 5 × gen-owl
- 5 × roundtrip-ttl (BUG-3)

Steg 5 (`make test` i CI) er ikkje gjennomført.

**Merknad:** Roundtrip-tabellen i `tests/README.md` listar framleis skjema som er fjerna frå repoet
(`brreg-begrepskatalog`, `brreg-modellkatalog`, `register-over-aksjeeiere`, `enhetsregisteret-bvrinnfelles`,
jf. `537e0190`). Det er ikkje retta her.
