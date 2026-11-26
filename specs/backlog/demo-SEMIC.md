# Plan: 20-minutters demo for semantisk web-konferanse (éi kjelde, mange artefakter)

## Bakgrunn

Brukaren skal halde ein demo på ein ny konferanse. Deltakarane kan semantiske
webstandardar godt (RDF, OWL, SHACL, JSON-LD). LinkML-utviklarar held ei innleiing
rett før demoen og forklarer kva LinkML er, så demoen brukar ikkje tid på det.

Demoen skal vise:

1. **Éi kjelde til sanning.** Éin YAML-fil er einaste stad modellen vert vedlikehaldt.
   Alle andre representasjonar vert generert.
2. **Generering av artefaktane ein treng**, med vekt på RDF-sida (SHACL, OWL,
   JSON-LD context, RDF/Turtle) og eit par kontrastar for utviklarar (JSON Schema, Python).
3. **At den genererte SHACL-en faktisk validerer data**, med `pyshacl`.
4. **Validatoren** (`mcp-linkml-valider-modell`) og **analysejobbane** (`analyse-*`)
   som ekstraverdi i modelleringsarbeidet.
5. **Mkdocs-portalen** som eit godt verktøy for å få oversikt over ein modell.

Rammer: maks 20 minutt, scripta på same nivå som
[javazone-demo-plan.md](javazone-demo-plan.md) (ordrett kommandosekvens med
forventa utdata og tid, talk track, offline-sjekkliste, opprydding). Avklart med
brukaren:

- **Engelsk demo, men modellen vert modellert på norsk (bokmål)**, med engelske termar
  som `structured_aliases` på klassar og slots (sjå § Demomodellen). Avgjort 2026-11-20,
  erstattar eit tidlegare val om engelsk modell.
- **Offline-sikker.**
- **RDF-fokus.**
- **Hybrid-modell:** ferdig modell som vert vist, pluss éi live-endring.
- **`pyshacl`** vert lagt til for å validere generert SHACL (sjå § `pyshacl`).
- **Engelske navn på dei brukte analysejobbane**, med norske navn som alias
  (sjå § Engelske analysenavn).
- **Mkdocs-portalen** vert vist (sjå § Portalen).

Kjeldemateriale: `specs/backlog/javazone-demo-plan.md`,
`javazone-demo-auto-innsetjing.md` og `specs/done/javazone-demo-quick-*.md`
(mekanismane vi gjenbrukar).

## Verifisert 2026-11-18 (mot `samt-bu` og `referansemodell-bronze`, linkml 1.12.1)

Alle kommandoane under er køyrde. Dei er **ikkje** køyrde mot den ferdige
demomodellen, som ikkje finst enno (sjå handlingsliste).

| Kommando | Tid | Merknad |
|---|---|---|
| `make gen-shacl` / `gen-owl` / `gen-jsonld-context` / `gen-rdf` | 1-3 s | |
| `make gen-plantuml` / `gen-jsonschema` / `gen-python` | 2 s | |
| `make gen-schema-docs` | 4 s | |
| `make roundtrip` | 3 s | JSON og TTL |
| `make validate-instance` | 2 s | «No issues found» |
| `make mcp-linkml-valider-modell` | 3 s | |
| `make analyse-ubrukte-slots` / `analyse-isolerte-klasser` / `analyse-ikkje-tilkopla-container` | 1-2 s | |
| `make analyse-similar-classes-domain` | under 1 s | |

**Funn som styrer utforminga:**

1. **Ein ryddig modell gir «ingen funn» i alle analysejobbane** (`samt-bu`: 12 slots,
   11 klasser sjekka, ingenting funne). Analysejobbane viser berre verdi om modellen
   har **plantede funn**. Demomodellen må difor lagast med vilje.
2. **Validator-trappa er ein god historie.** `referansemodell-bronze` gir 0 feil og
   0 åtvaringar på `POLICY=bronze` og `POLICY=basis-no`, og 2 åtvaringar på
   `POLICY=silver` (`missing_required_import`,
   `schema_has_annotation_oppdateringsfrekvens`). Same modell, strengare krav.
3. **Silver stiller faste DCAT-krav til containerklassen** (JavaZone-planen, § steg 9:
   `container_katalog`/`container_datasett`/… er `severity: error` og ubetinga).
   Ein ikkje-DCAT-modell vil difor ha feil på silver som ikkje kan rettast. Demoen
   viser **bronze → basis-no**, og nemner silver/gold berre munnleg.
4. **Sideeffektar som må ryddast** (vi måtte rulle dei tilbake i denne økta):
   - `mcp-linkml-valider-modell` skriv `validation/<versjon>/<policy>.json` inn i
     `src/linkml/<domene>/<modell>/` (ny, usporet katalog).
   - `gen-informasjonsmodell-instance` endrar `metadata/<modell>-manifest.yaml`
     (`versjonsnummer`, `endringsdato`).
5. **`pyshacl` finst ikkje i repoet.** `grep` etter `pyshacl` gir berre treff i
   `specs/done/`. Vi kan generere SHACL-shapes, men repoet validerer ikkje RDF mot dei.
6. **`new-modell`-scaffolden skriv ein versjonslåst URL-import** av `dcat-ap-no`
   (`https://raw.githubusercontent.com/...`), som krev nett. Eksisterande domenemodellar
   (t.d. `samt-bu`) brukar relativ import. `referansemodell-bronze` importerer berre
   `linkml:types` og definerer subseta lokalt, og går gjennom bronze utan funn.
7. **`similar-classes-*` er alt engelsk.** Berre tre av dei fem brukte analysejobbane
   har norske navn (sjå § Engelske analysenavn).
8. **Utdata frå validator og analysejobbar er på norsk** (t.d. «Ingen ubrukte lokale
   slots funne», «Klasse 'X' manglar annotations.begrepsidentifikator …»). Sjå
   § Opne spørsmål.
9. **`structured_aliases` finst på alle element, òg `slot_definition`** (stadfesta
   mot metamodellen i linkml 1.12.1, 2026-11-20). `structured_alias` har
   `literal_form`, `in_language`, `alias_predicate` og `categories`. Metamodellen
   koplar feltet til `skosxl:altLabel`. Korleis generatorane og portalen viser det, er
   **ikkje verifisert** (sjå § Opne spørsmål).

## Demomodellen (norsk, med engelske termar)

**Ferdig bygd på førehand**, ikkje laga live (hybrid-valet). Liten og lesbar på éin
skjerm, med standardvokabular i `class_uri`/`slot_uri` slik at publikum kan sjå
mappinga til kjende standardar.

**Språk:** klassenavn, slotnavn og skildringar er på **norsk bokmål**, i tråd med
skriftspråkregelen i CLAUDE.md (ingen avvik). Den **engelske termen** vert gitt med
`structured_aliases` og `in_language: en` på kvar klasse og kvar slot. Metamodellen
støttar feltet på alle element, òg `slot_definition` (verifisert 2026-11-20):

```yaml
  Foredrag:
    description: Eit foredrag på ein konferanse.
    class_uri: dct:BibliographicResource
    structured_aliases:
      - literal_form: Talk
        in_language: en
    slots: [id, tittel, varighet]

slots:
  tittel:
    slot_uri: dct:title
    structured_aliases:
      - literal_form: title
        in_language: en
```

Filnavn, katalogar og `make`-parametrar følgjer repoet sine konvensjonar
(`<navn>-schema.yaml`, `examples/<navn>-eksempel.yaml`).

**Kva alias gir og ikkje gir:**

- Alias endrar **ikkje** navna i genererte artefakter. IRI-ane for lokale klassar er
  norske (`konferanseprogram:Foredrag`). `sh:path`, JSON-LD-termar og OWL-properties
  for slots med `slot_uri` bruker standardvokabular (`dct:title`, `foaf:name`), som er
  engelsk uansett. Dei lokale klassenavna er dei einaste norske termane i RDF-sida.
- Alias gjer engelsk term **maskinlesbar** i modellen. Om generatorane skriv han ut
  (t.d. som `skos:altLabel "Talk"@en` i OWL, eller som SKOS-XL-ressursar) er **ikkje
  verifisert** og avgjer kor mykje alias er verd i demoen.
- Synleg for publikum: (1) ei slide med termtabell («Foredrag = Talk»), (2) portalen
  dersom ho viser alias, (3) eventuelt RDF-sida dersom generatorane skriv alias ut.
  Viser ikkje portalen alias, er alternativet ei lita utviding av docgen-malane under
  `src/assets/templates/docgen/` (eiga spec) eller å nøye seg med sliden.

**Ingen AP-NO-import.** Modellen følgjer strukturen i `referansemodell-bronze`:
importerer berre `linkml:types` og definerer subseta lokalt
(`Obligatorisk`/`Anbefalt`/`Valgfri`, som policyane forventar). Grunngjevinga er
ikkje lenger språk, men: ingen URL-import (offline-sikker utan omvegar), ingen
kollisjonsfare med importerte slots (`tittel`, `id`, jf. BUG-6/BUG-7 i JavaZone-planen),
og ein liten modell som held seg på éin skjerm. Talk track brukar vokabulargjenbruk via
`class_uri`/`slot_uri` (`dct:`, `foaf:`), ikkje profilimport. Ønskjer ein å vise
importhierarkiet i staden, er relativ import av `dcat-ap-no` mogleg (som `samt-bu`
gjer), på kostnad av modellstorleik og kollisjonsrisiko.

**Plassering:** fixture i `src/assets/scripts/demo/semweb-demo/` (utanfor
`src/linkml/`, slik at han ikkje kjem med i `make test`, CI-matrisa eller den
publiserte portalen). Demo-scriptet kopierer han til
`src/linkml/oreg/konferanseprogram/` ved start og slettar han ved slutt, same
mønster som JavaZone-scriptet.

**Innhald (forslag, må bekreftast i prototypen):**

| Klasse | Engelsk term (alias) | `class_uri` | Merknad |
|---|---|---|---|
| `Konferanse` | Conference | `dcmitype:Event` | |
| `Foredrag` | Talk | `dct:BibliographicResource` | refererer `Foredragsholder`, `Konferanse` |
| `Foredragsholder` | Speaker | `foaf:Person` | |
| `Sesjon` | Session | | refererer `Foredrag`, `Rom` |
| `Rom` | Room | | |
| `KonferanseprogramContainer` | | | `tree_root`; attributt for `Konferanse`, `Foredrag`, `Foredragsholder` |

Slots brukar `dct:title`, `dct:description`, `foaf:name` m.fl., kvar med engelsk alias.
`dcmitype:` må leggjast til i `prefixes`. Modellering følgjer elles repoet sine reglar
(globale slots, lenking framfor inlining).

**Plantede funn** (kvart peikar på éin jobb i demoen):

| # | Planta funn | Funne av | Akt |
|---|---|---|---|
| 1 | Klassen `Foredrag` manglar `annotations.begrepsidentifikator` | `mcp-linkml-valider-modell` | 5 |
| 2 | Slotten `varighet` manglar `slot_uri` | `mcp-linkml-valider-modell` | 5 |
| 3 | Slotten `kommentar` er definert men ikkje brukt | `analyse-unused-slots` | 6 |
| 4 | Klassen `Sponsor` er isolert (ingen referansar til/frå) | `analyse-isolated-classes` | 6 |
| 5 | `Rom` er referert frå `Sesjon`, men `Sesjon` er ikkje nåbar frå containeren | `analyse-unreachable-classes` | 6 |
| 6 | Klassenavn som liknar eit eksisterande i repoet | `analyse-similar-classes-all` | 6 |

Funn 6 treng eit klassenavn med 80 %+ likskap mot ein eksisterande klasse (terskel
80 %). Med norske klassenavn fungerer same mønster som i JavaZone-demoen (`Aktivitet`
finst i `oreg/enhetsregisteret-bvrinnfelles`). Finn eit navn som passar konferanse-temaet
ved å køyre `make analyse-similar-classes-all` på prototypen. Verifiser at funn 1-5
faktisk kjem opp, og at funn 6 ikkje kjem i tillegg til tilfeldige falske treff.

## `pyshacl`

Mål: vise at SHACL-en LinkML genererer faktisk validerer RDF-data.

**Plan:**

1. **Legg `pyshacl` i `src/assets/containers/requirements-python-test.txt`**
   (brukarval: det eksisterande `python-pytest`-imaget, bygd frå
   `Dockerfile.python` på `python:3.15-alpine`). Ingen nytt image. Verifiser at
   `pip install` fungerer på Alpine (`pyshacl` er rein Python og hentar `rdflib`,
   `owlrl`, `prettytable`; **ikkje verifisert**).
2. **Nytt make-target `validate-shacl SCHEMA=<sti> [DATA=<ttl>]`** i
   `make/40-validation.mk`. Standardverdiar: shapes frå
   `generated/<domene>/<modell>/<modell>-shapes.ttl` (`gen-shacl`) og data frå
   `<modell>-eksempel.ttl` (`convert-instance-rdf`, krev `example_rdf: true`).
   Køyrer `pyshacl -s <shapes> -df ttl <data>` i `$(PYTHON_RUN)`. Skriv
   «Conforms: True/False» og valideringsrapporten. Brukar `run_logged` og gir
   ikkje-null exit-kode ved brot, jf. «Ingen stille feil» i CLAUDE.md. Navnet har ikkje
   siffer, og `validate`-prefikset treffer kategorimønsteret «Validering» i
   `help.sh` (verifiser med `make help`, jf. `.claude/rules/make-conventions.md`).
3. **Attribution:** legg `pyshacl` i tabellen i `mkdocs/docs/om.md` (lisens må
   stadfestast, ikkje anta). `pytest` og `openapi-spec-validator` står der alt for
   same image. Sjå CLAUDE.md § «Nye verktøyavhengigheiter» og `CONTRIBUTING.md`.
4. **Bygg imaget på nytt** (`make build-docker-python`). Verifiser at
   eksisterande testar framleis går (`make test`).
5. **Test** for det nye targetet i `tests/test_make.sh` (positivt og negativt
   tilfelle), etter skip-konvensjonane i `.claude/rules/testar.md`.
6. **Demo-data:** to filer under `examples/`: ein gyldig instans (vert konvertert til
   TTL) og ein **ugyldig TTL-fil** utan ein påkravd eigenskap, slik at demoen viser
   både «Conforms: True» og eit konkret brot.

**Risiko (må avklarast i prototypen):** LinkML-genererte shapes er kanskje lukka
(`sh:closed`), og `rdf:type`/`@type` frå instansen må samsvare med `sh:targetClass`.
Validerer ikkje LinkML sin eigen eksempel-TTL mot LinkML sine eigne shapes, er det
eit funn å dokumentere (kandidat for `bugs/`), ikkje noko å skjule i demoen.

## Engelske analysenavn

Brukarval: engelske navn på dei brukte analysejobbane, **norske navn som alias**, og
**berre jobbane demoen brukar**.

| Norsk (alias, beheld) | Engelsk (nytt, primært) |
|---|---|
| `analyse-ubrukte-slots` | `analyse-unused-slots` |
| `analyse-isolerte-klasser` | `analyse-isolated-classes` |
| `analyse-ikkje-tilkopla-container` | `analyse-unreachable-classes` |
| `analyse-similar-classes-domain` | (alt engelsk, uendra) |
| `analyse-similar-classes-all` | (alt engelsk, uendra) |

Prefikset `analyse-` er engelsk (britisk) skrivemåte og treffer alt mønsteret
`analyse-` i `help.sh`, så ingen endring i kategoriane er naudsynt.

**Utforming (i `make/91-modell-analyse.mk`):**

- Det engelske målet får oppskrifta og `print_header` med det engelske navnet, slik at
  demoen viser engelsk i terminalen.
- Det norske navnet vert ei eiga linje som berre har det engelske som føresetnad og ei
  hjelpetekst som «Alias for `analyse-unused-slots`». Alias-målet skriv da det
  engelske headernavnet. Alternativet (`$(MAKE)`-kall) er ikkje nødvendig.
- Begge navna i `.PHONY`.

**Kvifor alias:** `src/assets/scripts/demo/javazone-demo-script.sh` (linje ~322-331
og ~742-746), `generate-modellanalyse-md.py` og
`find-unused-local-definitions.py` (docstringar) refererer til dei norske navna. Med alias
slepp vi å røre dei, og eksterne repo som kallar dei går ikkje i stykke.

**Sjekkliste:**

1. Grep heile repoet (utanom `specs/done/` og `CHANGELOG.md`) etter dei tre norske
   navna. Per 2026-11-19 treffer dei berre `make/91-modell-analyse.mk`,
   `mkdocs/lib/scripts/generate-modellanalyse-md.py`,
   `src/assets/scripts/demo/javazone-demo-script.sh`,
   `src/assets/scripts/makefile/find-unused-local-definitions.py` og denne specen.
   `COMMANDS.md`, `.github/workflows/` og `tests/` nemner dei ikkje med desse navna.
2. Oppdater `COMMANDS.md` og mkdocs-kommandosidene **dersom** dei listar dei tre
   (grep stadfestar at dei ikkje gjer det, men sjekk `make help`-tabellane).
3. Verifiser med `make help` at begge navna syner under «Modell-analyse», ikkje
   under «Anna» (jf. `.claude/rules/make-conventions.md`).
4. Køyr dei tre med **begge** navna og stadfest identisk utdata (bortsett frå
   headeren).

**Utanfor omfang:** dei andre rundt 15 `analyse-*`-jobbane vert ikkje omdøypte (to
språk i `make help` er ei kjend følgje av avgrensinga; ein full omdøyping er ei eiga
spec). Utdata-teksten frå jobbane er framleis norsk (sjå § Opne spørsmål).

## Portalen (mkdocs)

Brukarval: vis modellen i mkdocs-portalen for å vise at portalen gir god oversikt.

Poenget i demoen: ein modell som berre finst som YAML er vanskeleg å få oversikt over.
Portalen gir klassesider, diagram og (truleg) validerings- og analyserapportar per
modell, utan at nokon har skrive dokumentasjon for hand.

**Plan:**

1. Generer dokumentasjonen: `make gen-schema-docs SCHEMA=<S>` (4 s på `samt-bu`).
2. Publiser og server lokalt: `make docs-publish` og `make docs-serve`
   (`docs-publish`, ikkje `docs-build`, jf. offline-sjekklista i JavaZone-planen).
3. **Mål tida for `make docs-publish`** på ein full repo-checkout. Han kopierer
   artefakter for alle skjema og genererer `mkdocs.yml` på nytt, og kan ta lang tid.
   Er han for treg til å køyre live, vert portalen **starta på førehand i ein eigen
   terminal/fane**, og demoen byter berre fane.
4. Peik ut éi eller to sider: modellens indeksside (metadata og klasseoversikt) og
   eit diagram (ER eller PlantUML). **Verifiser** om validerings- og analyserapportar
   dukkar opp per modell i portalen (`mcp-linkml-valider-modell` skriv «for lokal
   portalvising», og `modellanalyse-per-skjema-index-md.md` i `specs/done/`
   tyder på det).
5. Verifiser at portalen går offline (kopla frå nettet), at modellen (norsk, med
   engelske termar) vert rett vist under `/en/` eller `/nn/`, og **om og korleis
   `structured_aliases` vert vist** (ikkje verifisert).

Talk track: *«Nobody wrote this documentation. It is rendered from the same YAML.»*

## Tidsbudsjett (20 minutt)

Alle `make`-kommandoane tek 1-4 sekund, så tida går til tale, ikkje venting.

| Tid | Akt | Innhald |
|---|---|---|
| 0:00-1:00 | 0. The problem | Problemet: same modell i åtte formater, som driv frå kvarandre |
| 1:00-3:00 | 1. One source of truth | Eitt steg: heile YAML-fila i `less`. `class_uri` og `slot_uri` mot standardvokabular, `structured_aliases` |
| 3:00-6:00 | 2. Generate | `gen-*` for RDF-artefakter og JSON Schema. «Éin slot, seks artefakter» |
| 6:00-8:00 | 3. Create an app | `gen-python`, så tre Python-appar mot same klassar: YAML, JSON og RDF |
| 8:00-10:00 | 4. One edit | Éin ny slot i YAML, generer på nytt, diff over alle artefakta |
| 10:00-12:00 | 5. The portal | Same modell i mkdocs: oversikt utan handskriven dokumentasjon |
| 12:00-15:00 | 6. Validation | Modellvalidatoren (policy-trappa), `pyshacl` på generert SHACL |
| 15:00-17:30 | 7. Analysis | Tre jobbar mot plantede funn, og `-all` mot heile repoet |
| 17:30-18:30 | 8. Take-aways | Tre poeng å ta med |
| 18:30-20:00 | Buffer | Kutt fyrst `analyse-isolated-classes` og `analyse-unreachable-classes` |

## Det scripta forløpet

Kommandoar og talk track. `<S>` =
`src/linkml/oreg/konferanseprogram/konferanseprogram-schema.yaml`.
Scriptet viser kvart steg (tittel og kommando) og ventar på Enter, same stil som
`javazone-demo-script.sh`.

### Akt 0 — Hook (1:00)

Ingen kommando. Éi slide (utkast til slide-tekst under; engelsk, som resten av demoen).

**Slide-tekst (hook-slide):**

```
Same model, many places
...that drift apart

   Talk ──┬─ OWL ontology
          ├─ SHACL shapes
          ├─ JSON Schema
          ├─ Python class
          ├─ Docs / wiki
          └─ JSON-LD context

   Six hand-written copies.
   Someone renames a field. Five copies don't hear about it.
   Connecting different models? Each one is hard to understand.

   One model to rule them all.
```

Layout: «Talk» som sentralt konsept til venstre, seks stader til høgre med pilar ut.
Éin av stadene kan markerast raud med t.d. `title` mot `name` for å vise drift.
Botnlinja (parafrase av Tolkien) er bru til akt 1; heile verset vert ikkje brukt.
Ingen bilete eller logoar frå filmane. Vil ein ha «Docs / wiki» bytt med `gen-rdf`
for å matche dei seks artefakta i akt 2 ein-til-ein, er det eit alternativ.

> *«Every standards body I know maintains the same model in several places: a
> spec document, an OWL file, SHACL shapes, a JSON Schema for the developers, a
> diagram. They drift apart, and when you try to connect them, every model is
> hard to understand on its own terms. Today I'll show a repository where there
> is exactly one place you edit, and everything else is generated.»*

### Akt 1 — One source of truth (2:00)

Eitt steg, «LinkML model is source of truth». Scriptet opnar **heile** skjemafila i `less`
(med linjenummer), starta ved `classes:` (`show_excerpt "classes:"`). Éi visning i staden for to:
klassane og slotane ligg i same fil, så ein blar frå `classes:` ned til `slots:` utan nytt steg.

```bash
# LinkML model is source of truth
less <S>     # heile fila, opna ved classes:; bla med piltastar/Space, q for å gå vidare
```

Bla gjennom mappinga i fila:

1. **Klassen `Foredrag`** (`classes:`): `class_uri: dct:BibliographicResource`, og `structured_aliases`
   med «Talk».
2. **Slotten `tittel`** (`slots:`, lenger ned): `slot_uri: dct:title` og alias «title».

```yaml
  tittel:
    slot_uri: dct:title
    range: string
```

> *«No new vocabulary here. `class_uri` and `slot_uri` tie the classes and slots of the
> model to terms everybody already knows, like `dct:title`. Those lines are what every
> generator below uses as the predicate.»*

Påpeik `structured_aliases` på same slot og på klassen:

> *«The model is in Norwegian, because that is the language of the people who own it.
> The English term travels with it as a language-tagged alias, so the model is
> readable to everyone in this room, and to machines.»*

### Akt 2 — Generate (3:00)

```bash
# RDF side
make gen-shacl SCHEMA=<S>            # ~1 s
make gen-owl SCHEMA=<S>              # ~2 s
make gen-jsonld-context SCHEMA=<S>   # ~2 s
make gen-rdf SCHEMA=<S>              # ~3 s   (schema as Turtle)

# Contrast for the developers in the room
make gen-jsonschema SCHEMA=<S>       # ~2 s
```

Etter kvar `gen-*` skriv scriptet ut stien til den genererte fila (`Generated: …`) og viser
innhaldet i `less`.

Etter generering: **«éin slot, seks artefakter»**. Scriptet køyrer `grep` for
`dct:title`/`tittel` mot kvar fil og viser éi linje frå kvar:

| Artefakt | Verifisert treff (`grep -n`, 2026-11-20) |
|---|---|
| YAML | `slot_uri: dct:title` |
| OWL | `dct:title a owl:DatatypeProperty` (**krev `owl_flags: "--no-use-native-uris"`**, sjå under) |
| SHACL | `sh:path dct:title` |
| JSON-LD context | `"tittel": {` etterfylgt av `"@id": "dct:title"` (grep med `-A2`) |
| RDF/Turtle (skjema) | `linkml:slot_uri "http://purl.org/dc/terms/title"^^xsd:anyURI` |
| JSON Schema | `"tittel": {` (ingen URI; kontrast, ikkje semantikk) |

**OWL-fella:** `gen-owl` med standardflagg ignorerer `slot_uri`. Han lagar
`konferanseprogram:tittel a owl:DatatypeProperty` og berre `skos:exactMatch` for klassar
(`Foredrag` exactMatch `dct:BibliographicResource`). Med `owl_flags: "--no-use-native-uris"`
i `build.yaml` får han `dct:title`, `dct:creator`, `foaf:name` og `foaf:Person` som
sjølvstendige OWL-ressursar. Fixturen set flagget. Repoet sine eigne modellar bruker
standardflagget (ingen `owl_flags` er sette nokon stad), så dei viser ikkje
vokabulargjenbruk i OWL. Ikkje endra her; vert noko å omtale i demoen («our OWL reuses
`dct:title`, not a private copy»).

> *«Same slot. A predicate in OWL, a `sh:path` in SHACL, a term in the JSON-LD
> context, a property in the JSON Schema. Nobody typed it six times.»*

Rett eksakte greppattern etter at prototypen er køyrd. Viser grepet noko anna enn
tabellen, er tabellen feil, ikkje grepet.

### Akt 3 — Create an app (2:00)

Ny hovudoverskrift (pikselfont som dei andre aktane), rett etter «One slot, six artifacts». Dekkjer fire steg:

1. **«Generate Python classes»**: `make gen-python SCHEMA=<S>` (~2 s).
2. **«App 1: read the YAML data»**: `less` på `konferanseprogram_app_yaml.py`, så køyring.
3. **«App 2: convert to JSON and read it»**: `konferanseprogram_app_json.py` konverterer YAML-eksempelet til
   JSON (`json_dumper`) og les JSON-fila att med same klassar (`json_loader`). Etter køyringa vert dei fyrste
   linjene av `konferanseprogram.json` viste.
4. **«App 3: convert to RDF and read it»**: `konferanseprogram_app_rdf.py` konverterer til Turtle
   (`rdflib_dumper`, med `SchemaView` over skjemaet, så `slot_uri`/`class_uri` vert brukt) og les Turtle att
   (`rdflib_loader`). Dei fyrste linjene av `konferanseprogram.ttl` vert viste: `dct:title`, `foaf:name`,
   `dct:BibliographicResource`.

Alle tre appane skriv ut same linje, `The Right Tool Is More Than Half the Job (20 min) - Audun Vindenes Egge @ SEMIC 2026`.
Poenget er at éi modell gjer same data lesbare frå tre formater. Appane køyrer i `linkml-local` og
fungerer som portalens «Using Python»-snippet (`yaml_loader.load`, `target_class=`), men lastar
containerklassen. Detaljar og avvik frå snippeten står i § Avgjerder («Python-app i akt 3»).

> *«The classes are generated from the same file. Read the data as YAML, as JSON or as RDF: you get
> the same objects, because they all follow the same model.»*

### Akt 4 — Live-endring (2:00)

Sentralt poeng: éi endring i kjelda, alt anna følgjer.

```bash
# Step A: the script inserts one slot into <S> and shows the diff
#         (git diff --no-index, same mechanism as javazone-demo-auto-innsetjing)
# Step B: regenerate
make gen-shacl SCHEMA=<S>
make gen-owl SCHEMA=<S>
make gen-jsonld-context SCHEMA=<S>
make gen-jsonschema SCHEMA=<S>
# Step C: show what changed in the generated files
```

Slotten som vert sett inn: `landingsside` (`slot_uri: dcat:landingPage`,
`range: uriorcurie`) på `Konferanse`. Eit nytt, kjend vokabular, same eitt-linjes
mønster som akt 1. `dcat:` må vere i `prefixes`.

Steg C viser tre korte diffar (SHACL, JSON-LD context, JSON Schema) med same
`landingPage`-linje.

> *«One line in the source. Four generated files updated. No file was edited by
> hand, so none of them can disagree.»*

### Akt 5 — Portalen (2:00)

```bash
make gen-schema-docs SCHEMA=<S>      # ~4 s
make docs-publish                    # tid: må målast
# docs-serve køyrer alt i eigen terminal; byt fane
```

Vis modellsida og eit diagram. Sjå § Portalen for opne punkt.

> *«Nobody wrote this documentation. It is rendered from the same YAML. For a
> model with fifty classes, this is how you get an overview.»*

### Akt 6 — Validering (3:00)

**Poeng:** tre lag. Modellen, dataa, og SHACL-en vi nett genererte.

**Lag 1: modellvalidatoren** (fortel kva modellen manglar for å vere ein god modell,
ikkje berre om YAML-en er gyldig):

```bash
make lint SCHEMA=<S>                                      # structural, ~1 s
make mcp-linkml-valider-modell SCHEMA=<S> POLICY=bronze   # clean, ~3 s
make mcp-linkml-valider-modell SCHEMA=<S> POLICY=basis-no # two warnings
```

Bronze er reint. Basis-no gir funn 1 og 2 (`all_classes_have_concept_ref`, `all_slots_have_slot_uri`).
Scriptet set inn retting for eit utval (`Foredrag` for begrepsidentifikator, `varighet` for
`slot_uri`), same mønster som JavaZone steg 9.

```bash
make mcp-linkml-valider-modell SCHEMA=<S> POLICY=basis-no # findings gone
```

> *«Policies are levels. Bronze is a generic LinkML baseline. `basis-no` adds the
> Norwegian public-sector requirements. Silver and gold add lifecycle metadata and
> publication requirements. Same model, a ladder to climb.»*

**Lag 2: instansdata mot modellen:**

```bash
make validate-instance SCHEMA=<S> INSTANCE=src/linkml/oreg/konferanseprogram/examples/konferanseprogram-eksempel.yaml
```

**Lag 3: generert SHACL mot RDF-data** (nytt, krev `validate-shacl`):

```bash
make validate-shacl SCHEMA=<S>                                       # conforms
make validate-shacl SCHEMA=<S> DATA=<ugyldig-ttl>                    # violation
```

> *«This is the SHACL we generated two minutes ago. It accepts the good data and
> reports the violation in the bad data. A standard SHACL engine, no LinkML in the
> validation path.»*

### Akt 7 — Analysejobbane (2:30)

**Poeng:** modellen vert analysert som kode. Jobbane finn ting ein ikkje ser for hand.

```bash
make analyse-unused-slots SCHEMA=<S>                     # funn 3: kommentar
make analyse-isolated-classes SCHEMA=<S>                 # funn 4: Sponsor
make analyse-unreachable-classes SCHEMA=<S>              # funn 5: Rom
make analyse-similar-classes-all NAME=konferanseprogram # funn 6: i heile repoet
```

> *«Unused slot, an orphan class, a class nobody can reach from the root, and,
> my favourite, a name that is nearly identical to something already modelled in
> another domain. For a standards community that's the question that matters:
> has somebody already defined this?»*

Kutt-prioritet ved tidsnaud: behald `analyse-similar-classes-all` og
`analyse-isolated-classes`, kutt dei to andre.

### Akt 8 — Avslutning (1:00)

Éi slide, tre poeng:

1. *One source, N artifacts.* Generated, never hand-edited.
2. *Validators check the model, the data and the generated SHACL.*
3. *Analysis and the portal give you the overview before it ships.*

Peik på at alt var køyrt lokalt og er reproduserbart frå repoet.

## Handlingsliste

Prototypen kjem før scriptet. Ingen kommando i § Det scripta forløpet er køyrd mot
demomodellen enno.

**Infrastruktur (må vere på plass før scriptet):**

1. [x] **`pyshacl`:** legg i `requirements-python-test.txt`, bygg `python-pytest` på
   nytt, verifiser Alpine-installasjon og lisens. Utført 2026-11-20: pyshacl 0.40.2
   (Apache-2.0, pakkelisensfila i imaget) installerer reint på `python:3.15-alpine`.
   `make test` er ikkje køyrd enno.
2. [x] **`make validate-shacl`** i `make/40-validation.mk` med `run_logged`, exit-kode
   og `make help`-kategori. Test i `tests/test_make.sh`. `DATA` er valfri (standard
   `generated/<modell>-eksempel.ttl`). Rapporten vert alltid skriven ut (ikkje via
   `run_logged`, som berre viser stdout ved DEBUG). Test: `tests/test_validate_shacl.sh`
   (12 sjekkar, eigne fixtures; ikkje i `make test`, som er per skjema). `make help` viser
   målet under «Validering». `make test`: 528 OK, 0 feil.
3. [x] **`om.md`:** legg `pyshacl` i attribusjonstabellen (norsk og engelsk
   versjon, jf. `om.en.md`).
4. [x] **Engelske analysenavn:** tre nye mål i `make/91-modell-analyse.mk`, norske
   som alias, begge i `.PHONY`. Grep, `make help`-sjekk og identisk utdata. Verifisert: `make help` viser
   begge under «Modell-analyse», og alias og primærmål gir identisk utdata (òg headeren,
   sidan aliaset berre kallar det engelske målet).

**Demo:**

5. [x] **Bygg fixture** i `src/assets/scripts/demo/semweb-demo/` (norsk skjema med
   `structured_aliases` på klassar og slots, `build.yaml`, `description.md`, gyldig eksempel-YAML, ugyldig TTL, innsettingsfilene
   for akt 4 og 6). Ingen AP-NO-import, lokale subsets. Skjema, `build.yaml`, `description.md`,
   gyldig eksempel og ugyldig TTL er skrivne (`examples/konferanseprogram-ugyldig.ttl`).
   Innsettingane for akt 4 og 6 ligg som heredoc-blokker i scriptet (ikkje som eigne
   filer, same mønster som JavaZone-scriptet). Funn-kommentarar er fjerna frå skjemaet,
   sidan publikum ser fila.
6. [x] **Verifiser at modellen** passerer `make lint`, validatoren (bronze, funn 1 og
   2 kjem opp, basis-no passerer) og alle `gen-*` i akt 2 og 4. Sjekk at
   `structured_aliases` ikkje gir lint- eller policyfeil.
7. [x] **Verifiser plantede funn 3-6** mot dei fire analysejobbane. Finn klassenavn
   for funn 6 (sjå § Opne spørsmål).
8. [x] **Verifiser «éin slot, seks artefakter»:** køyr grep mot alle seks filer og
   fyll tabellen med faktiske treff.
9. [x] **Verifiser `validate-shacl`:** gyldig data gir «Conforms: True», ugyldig gir
   brot. Dokumenter funn om lukka shapes eller type-mismatch.
10a. [x] **Alias-test (påkravd):** legg `structured_aliases` med `in_language: en` på alle
    klassar og slots i prototypen (og sjå til samanlikning `aliases` og `title` på éi
    klasse). Køyr `gen-schema-docs`, `docs-publish` og alle `gen-*`. Sjå om portalen
    viser alias, og om OWL/RDF-sida får språkmerkte literalar (`skos:altLabel "Talk"@en`)
    eller SKOS-XL-ressursar. Avgjer ut frå resultatet kva som vert vist i demoen
    (sjå § Opne spørsmål).
10. [x] **Portalen:** mål `make docs-publish`, verifiser offline og kva sider som
    vert vist. Avgjer om portalen skal vere førehandsstarta.
11. [x] **Skriv `src/assets/scripts/demo/SEMIC-demo.sh`** etter mønsteret i
    `javazone-demo-script.sh` (Enter-pause, `QUICK`-flagg, farga kommandolinjer,
    ikkje `set -e`, opprydding med j/N). Gjenbruk innsetjings- og diff-mekanismen frå
    `javazone-demo-auto-innsetjing.md`.
12. [~] **Rydd sideeffektar** i scriptet: sletting av `validation/<versjon>/` og
    `git restore` (eller sletting) av `metadata/*-manifest.yaml` dersom
    `gen-informasjonsmodell-instance` vert køyrt. Etter `docs-publish`: `git restore
    README.md README.en.md mkdocs/docs/felles` (sjå § Portalmåling), og sletting av
    `generated/oreg/konferanseprogram/`.
13. [ ] **Test heile sekvensen med klokke**, offline, minst to gonger. Mål: 18:30,
    med 1:30 buffer.
14. [ ] **Slides:** hook-slide (tekst er skrive i akt 0), «éin slot, seks artefakter»-slide, avslutningsslide.
    Utanfor repoet.
15. [ ] **Evaluer** om arbeidet avdekkjer behov for ny rule eller bug-fil (jf.
    CLAUDE.md, avslutning steg a).

**Funn frå `validate-shacl` (2026-11-20):** LinkML sin eigen eksempel-TTL for
`ngr-adresse` gir `sh:class`-brot (`Value does not have class ngr:GeografiskOmrade`),
fordi lenka noder (`<kommune/0301>`) ikkje har eigen `rdf:type` i fila. Lenking framfor
inlining gir difor brot med mindre dei refererte nodane òg er med og typa. Demodata må
inkludere typa noder for alle refererte klassar, og «ugyldig»-fila må brøyte på eit
anna, tydeleg punkt (manglande påkravd eigenskap). Ikkje eit bug i pyshacl.


## Verifisert 2026-11-20 (fixturen mot linkml 1.12.1)

Fixturen vart kopiert til `src/linkml/oreg/konferanseprogram/`, køyrd og sletta igjen.

- `make lint`: ingen funn. `gen-shacl/-owl/-jsonld-context/-jsonschema/-rdf/-python/
  -erdiagram-mermaid/-plantuml/-schema-docs`: alle exit 0. `validate-instance`: ingen
  feil. `structured_aliases` gir ingen lint- eller policyfeil.
- **Policy-trappa:** bronze gir **ingen** funn. Funn 1 (`all_classes_have_concept_ref`
  på `Foredrag`) og 2 (`all_slots_have_slot_uri` på `varighet`) kjem først på
  **basis-no**, jf. «norske krav startar på basis-no». Akt 6 må difor vise
  basis-no-funna og retta basis-no, ikkje bronze. `build.yaml` i fixturen har
  `validation_policy: basis-no`.
- **Funn 3 og 4:** `analyse-unused-slots` gir `kommentar`, `analyse-isolated-classes`
  gir `Sponsor`.
- **Funn 5:** reachability bruker ein **udirigert** graf. Sesjon vart ikkje flagga så
  lenge han peika på `Foredrag`. Retta ved at `Sesjon` ikkje har slot mot `Foredrag`
  (eigen `starttidspunkt` i staden). No gir `analyse-unreachable-classes` `Rom`,
  `Sesjon` og `Sponsor` (siste som venta overlapp med funn 4).
- **Funn 6:** `analyse-similar-classes-all NAME=konferanseprogram` gir **fem** treff på
  100 %: `Foredrag`, `Foredragsholder`, `Konferanse`, `Sesjon` mot `oreg/javazonetalk`
  og `Rom` mot `fint-utdanning`. Ikkje eitt nesten-treff, men eit reelt og forklarleg
  funn: JavaZone-modellen finst i repoet. Talk track: «five classes already modelled
  elsewhere».
- **`validate-shacl`:** eksempelet frå fixturen gir `Conforms: True` (nodane er
  inlina i containeren, så dei har `rdf:type`). `examples/konferanseprogram-ugyldig.ttl`
  (Foredrag utan `dct:title`) gir `Conforms: False` med eitt `MinCountConstraintComponent`-brot.
- **Alias (10a):** `structured_aliases` kjem berre ut i `<modell>-schema.ttl` (gen-rdf)
  som `skosxl:Label` med `skosxl:literalForm "Talk"` og `schema1:inLanguage "en"`. Dei
  er **ikkje** i OWL, SHACL, JSON-LD context, JSON Schema, Python eller gen-doc-sidene,
  så portalen viser dei ikkje. Avgjerd: engelsk term vert vist på ei termtabell-slide og
  ved å vise `-schema.ttl`-utsnittet. Docgen-utviding er ei eiga spec.

**Portalmåling (punkt 10, 2026-11-20):**

- `make docs-publish`: 39 s på full checkout. `make docs-build`: 58 s (to språk).
  `docs-serve` og `docs-serve-site` bruker `-it` og krev ein terminal. **Avgjerd:**
  portalen vert bygd og servert på førehand i ein eigen terminal med `make docs-build`
  og `make docs-serve-site`, og demoen byter berre fane. 40-60 s er for lenge live.
- Modellens indeksside har overskrifter «ER diagram», «Data model» (klassar, slots,
  subsets), «Generated artifacts (9)», **«Validation results»** (to åtvaringar frå
  basis-no) og **«Model analysis»** (isolerte klassar 1, ikkje tilkopla container 3, ubrukte
  slots 1). Rapportane vert med dersom `mcp-linkml-valider-modell` og
  `analyse-lokal-modellanalyse-domene DOMAIN=oreg` er køyrde før `docs-publish`.
- ER-diagrammet er ein førerendra SVG (PlantUML), ikkje mermaid i nettlesaren.
- **Offline:** seks `img.shields.io`-merke (versjon, status, utgivar m.fl.) og Google
  Fonts vert ikkje lasta utan nett. Sida fungerer elles. Kosmetisk; ta ein
  skjermdump av ferdig side som reserve.
- **Alias:** vert **ikkje** viste i portalen (ingen `Talk` på klassesida).
- **Filnavnkollisjon (funn):** containerattributtet `foredrag` og klassen `Foredrag` gir
  same filnamn (`klasser/foredrag.md`, case-insensitivt), og klassesida forsvann i
  portalen. Retta ved å døype attributtet om til `foredragsliste`. Same fella gjeld alle
  modellar der ein slot og ei klasse berre skil seg på store/små bokstavar.
- **Sideeffektar av `docs-publish`:** han skriv ei rad for modellen i `README.md` og
  `README.en.md` og slettar sporet `mkdocs/docs/felles/` (ca. 510 filer) når `generated/`
  ikkje har domenet `felles`. Scriptet må ende med
  `git restore README.md README.en.md mkdocs/docs/felles` (berre dersom dei er uendra frå
  før demoen), og `src/linkml/oreg/konferanseprogram/` må slettast.


**Scriptet (punkt 11, skrive og køyrt 2026-11-20):** `src/assets/scripts/demo/SEMIC-demo.sh`
[`QUICK=true|false`] [`PREPARE=true|false`]. Akt 0-8, 29 Enter-pausar, klokke i prompten,
valfritt `demo-fun-tools`-bilete (figlet/glow/boxes) med fallback til vanleg tekst. Køyrt
gjennom 5 gonger med automatisk Enter (`yes ''`): 0 feil, òg med `/bin/bash` 3.2 og
`QUICK=true`. Tid for ei full gjennomkøyring utan pausar: ca. 33-44 s, så all tid i demoen
er tale, ikkje venting.

Funn under scriptarbeidet:

- **`mv` bytte inode:** innsetjing via `mv fil.tmp fil` gav tilfeldig «File ... does not
  exist» i dei neste `make`-stega (podman-montering på macOS såg ikkje den nye fila).
  Retta ved å skrive tilbake i same fil (`cat tmp > fil`). Bør vurderast som ny rule dersom
  mønsteret dukkar opp utanfor demoen.
- **`gen-owl` skriv ca. 20 linjer deprecation-åtvaringar** frå linkml til skjermen.
  Scriptet filtrerer dei (`make_quiet_deprecations`) og viser heile utskrifta dersom make
  feilar.
- **Siste SHACL-steg («SHACL reports the violation …») gir med vilje exit 1.** `run_shacl_expect_violation` viser rapporten og ei
  grøn forklaring, ikkje «step failed».
- **Diffheader:** `git diff --no-index` viser temp-stien til før-fila. Scriptet viser berre
  hunkane med ein rein overskrift.
- BSD-awk tek ikkje newline i `awk -v`. Innhaldet vert sendt via `ENVIRON`.

**Ikkje verifisert i scriptet:** oppryddingsvegen med «y» (rm av modell og `generated/`,
`git restore` av portalstiane; automatisk testing mislukkast fordi `podman run -i` i
`PYTHON_RUN` et av stdin-røyret, jf. BUG-10), `PREPARE=true`-vegen (`docs-build` og
verifisering av portal i nettlesar), interaktiv `less`/`glow`, og visninga av akt 1
(`show_excerpt`) i ein ekte terminal. Punkt 13 (klokketest, offline, to gonger) står att.

## Offline-sjekkliste (dagen før, medan nett er tilgjengeleg)

```bash
make check-prereqs
make build-docker-linkml
make build-docker-python          # inkl. pyshacl
make build-docker-mcp-validator
make build-docker-mkdocs
bash src/assets/scripts/demo/SEMIC-demo.sh   # byggjer fun-tools første gong
make docs-publish && make docs-serve                 # test portalen offline etterpå
```

Deretter **kopla frå nettet** og køyr heile scriptet éin gong til frå botnen. Sjå
at ingenting prøver å nå ut: ingen URL-import i modellen, ingen
`analyse-iri-dereferering` eller `analyse-innhaldsforhandling` i demoen (dei krev
nett), og ingen `new-modell` med nettavhengig eksempelgenerering.

## Opprydding etter demoen

```bash
rm -rf src/linkml/oreg/konferanseprogram generated/oreg/konferanseprogram
git status --short   # skal vere tom bortsett frå dei varige endringane
```

## Opne spørsmål

- **Utdata-språk frå validator og analysejobbar (avgjort 2026-11-20: ingen språkval no, sjå Avgjerder).** Meldingane er norske
  («Ingen ubrukte lokale slots funne», «Klasse 'Foredrag' manglar
  annotations.begrepsidentifikator …»). I ein engelsk demo må du omsetje munnleg, eller vi
  legg til språkval (`LANG=en`) i validator og analysescript. Tilråding: omsetje
  munnleg og ha ei slide med dei tre–fire meldingane på engelsk. Språkval er ei
  eiga spec (sjå `specs/done/modellanalyse-rapportar-per-sprak.md` for korleis
  portalrapportane alt er språkdelte).
- **Visning av `structured_aliases`.** Kjernespørsmålet for den engelske termen:
  kor synleg er han i portalen, i OWL/RDF og i `gen-doc`? Metamodellen koplar feltet til
  `skosxl:altLabel`, så RDF-generatoren kan skrive SKOS-XL-ressursar i staden for
  språkmerkte literalar. Alias-testen (handlingsliste 10a) avgjer. Fallback:
  termtabell på ei slide, eller ei eiga spec for docgen-malane.
- **`aliases` mot `structured_aliases`.** Demoen brukar `structured_aliases`, fordi berre
  dei har `in_language`. `aliases` er flate strengar utan språkkode. `title` held éin
  streng og duger ikkje til fleire språk.
- **Funn 6 med norske klassenavn.** Same mønster som JavaZone (`Aktivitet`). Verifiser
  at eit konferanserelevant navn gir treff i `analyse-similar-classes-all`, ellers gir
  jobben «ingen funn».
- **SHACL mot LinkML sin eigen RDF.** Sjå § `pyshacl`, risiko.
- **Mkdocs-tid og innhald.** Sjå § Portalen, punkt 3-4.

## Avgjerder

- **Ingen språkval for validator- og analyseutdata** (brukarval 2026-11-20): utdata
  held seg på norsk i denne omgangen, og `build.yaml` får ingen språknøkkel. Demoen
  omset munnleg og viser ei slide med dei tre-fire meldingane på engelsk. Eit språkval
  (`REPORT_LANG`, meldingskatalog nøkkelen på `code`) vert eventuelt ei eiga spec seinare.
- **Hybrid-modell** (brukarval): ferdig modell vist i akt 1-2, éi live-endring i akt 4.
- **Engelsk demo, norsk modell med engelske termar via `structured_aliases`**
  (brukarval 2026-11-20). Erstattar eit tidlegare val om engelsk modell: modelleringa
  følgjer skriftspråkregelen i CLAUDE.md (bokmål, inga avvik), og den engelske termen
  vert gitt på klassar og slots (metamodellen støttar `structured_aliases` òg på
  `slot_definition`). Spec og kommentarar er på nynorsk.
- **Ingen AP-NO-import i demomodellen:** ikkje lenger språkgrunngjeving, men offline
  (ingen URL-import), unngå slot-kollisjonar og ein liten modell. Lokale subsets,
  som `referansemodell-bronze`.
- **Offline-sikker** (brukarval).
- **RDF-fokus** (brukarval): SHACL, OWL, JSON-LD context og RDF/Turtle er hovudartefakta.
  JSON Schema og Python er berre kontrast.
- **`pyshacl` i det eksisterande `python-pytest`-imaget** (brukarval), ikkje eit
  nytt image: ingen nytt Dockerfile eller build-target. Krev attribution i `om.md`.
  Er med i demoen (reverserer tidlegare tilråding om å utelate det).
- **Engelske analysenavn som alias, berre dei brukte jobbane** (brukarval):
  minimal endring, ingen brotne kallarar. Tre nye navn; `similar-classes-*` var alt
  engelsk. Prefikset `analyse-` er behalde (engelsk skrivemåte).
- **Mkdocs-portalen er med** (brukarval) som eiga akt, med førehandsstarta server
  som fallback dersom `docs-publish` er for treg.
- **Fixture utanfor `src/linkml/`:** ein modell med vilje plantede feil må ikkje
  køyre gjennom `make test`, CI-matrisa eller den publiserte portalen. Kopiering inn
  ved demostart og sletting ved slutt gjer JavaZone-mønsteret trygt.
- **Plantede funn:** analysejobbane gir «ingen funn» på ryddige modellar (verifisert
  på `samt-bu`).
- **Bronze → basis-no, ikkje silver:** silver stiller faste DCAT-krav til
  containerklassen som ein ikkje-DCAT-modell ikkje kan oppfylle.
- **Prototype før script:** kommandoane er verifiserte på `samt-bu` og
  `referansemodell-bronze`, ikkje på demomodellen, som må byggjast først.
- **Sideeffektar frå verifiseringa rydda:** `validation/<versjon>/`-katalogane og
  `samt-bu-manifest.yaml` vart rulla tilbake etter køyringane i denne økta.
- **Ny tidsfordeling:** hook 1:00, kjelda 2:00, generer 4:00, live 2:00, portal 2:00,
  validering 4:00, analyse 2:30, avslutning 1:00, buffer 1:30. Total 18:30 pluss buffer.

- **Python-app i akt 3 (2026-11-20, etter førespurnad; flytta frå akt 2 2026-11-22):** to steg i den eigne akta «Create an app», etter «One slot, six artifacts»: vis `semweb-demo-app/konferanseprogram_app_yaml.py` i less, og køyr han mot eksempelfila (seinare utvida til tre appar, sjå under). Appen følgjer portalens «Using Python»-snippet (`yaml_loader.load(..., target_class=...)`), men
  - lastar som `KonferanseprogramContainer` (eksempelfila er containeren; snippeten i portalen brukar første klasse, `Konferanse`, som ikkje passar for ei container-fil),
  - krev kopi av `konferanseprogram-model.py` til `konferanseprogram_model.py` (portalen importerer `konferanseprogram_model`, men den genererte fila har bindestrek og kan ikkje importerast),
  - køyrer i `linkml-local`-biletet (har `linkml-runtime`; `python-pytest` har ikkje). `podman run` direkte i demo-scriptet, same unntak som for `fun`-biletet; `pip install` i portalsnippeten er då ikkje naudsynt i demoen.
  Appen ligg utanfor fixturemappa (`semweb-demo-app/`) slik at han ikkje vert kopiert inn i `src/linkml/`. Verifisert: QUICK-køyring gir «One source of truth (20 min) - Audun Vindenes Egge @ SEMIC 2026», og midlertidig katalog vert rydda.
  Opent: portalsnippeten (modellnamn/klasse) er misvisande for modellar med containerklasse, vurder å retta malen separat.

- **Terminal-slides i demoen (2026-11-20):** `src/assets/scripts/demo/slides/` har slidane som scripts, kalla frå `SEMIC-demo.sh` via `show_slide`: `semic-cover` og `semic-title` først (hoppar `QUICK=true` over), `hook` i akt 0, og `semic-questions` og `semic-thanks` (to QR-kodar: LinkedIn og portalen) til slutt (alltid). Teikna 8-bit i SEMIC 2026-stil, delt kode i `semic-canvas.awk`. Verifisert: kjøring utan tty (røyr) gir ingen krasj (`slide-lib.sh` har ikkje `set -e`), og QR-kodane dekodar til rett URL. Ikkje verifisert i ekte terminal, og lågaste terminalhøgd er ca. 35 rader (QR-kodane) / 22 (resten); mindre gir tekstfallback. Malbiletet som bakgrunn finst som val (`SEMIC_BACKGROUND=template`) men er ikkje standard (brukaren likte 8-bit-stilen betre). Handlingsliste punkt 14 er dermed delvis gjort (forside, tittel, hook, spørsmål, takk); «éin slot, seks artefakter» og avslutningsslide med take-aways står att.

- **Ny akt «3. Create an app» (2026-11-22, brukarval):** `gen-python` og dei to Python-app-stega ligg under den nye hovudoverskrifta, som kjem rett etter «One slot, six artifacts» (og dermed rett før «For the developers: Python classes»). Aktane etter vart omnummererte (live-endring 4, portalen 5, validering 6, analyse 7, avslutning 8). Tidsbudsjettet vart justert slik at slutten er uendra (18:30, buffer 1:30): Generate 4:00 -> 3:00, Create an app 1:30, Validation 4:00 -> 3:30. Same endring i `SEMIC-demo.sh` (act-overskrifter og kommentarar).
- **Akt 1 slått saman til eitt steg (2026-11-22, brukarval):** «LinkML model is source of truth» viser heile skjemafila i `less`, opna ved `classes:`. Erstattar to steg (klassar, slots) som ikkje gav meir.

- **Tre Python-appar i akt 3 (2026-11-22, brukarval):** `semweb-demo-app/` har `konferanseprogram_app_yaml.py` (den opphavlege), `_json.py` (YAML -> JSON med `json_dumper`, les med `json_loader`) og `_rdf.py` (YAML -> Turtle med `rdflib_dumper`, les med `rdflib_loader`; krev `SchemaView(<skjema>)`). Verifisert 2026-11-22: alle tre skriv ut same linje, og rundturen YAML -> JSON -> objekt og YAML -> RDF -> objekt gir same data for denne modellen (BUG-2/BUG-3-fellene for `rdflib_loader` råkar ikkje fixturen). Funksjonen `app_flow` viser koden i less, køyrer appen i `linkml-local` og viser dei fyrste 16 linjene av fila appen skreiv. Tidsbudsjettet: Create an app 1:30 -> 2:00, Validation 3:30 -> 3:00.
