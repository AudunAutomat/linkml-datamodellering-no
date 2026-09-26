# Utgreiing: exact_mappings, annotations.begrepsidentifikator og class_uri — treng vi alle tre?

## Bakgrunn

Repoet nyttar i dag tre (reelt sett fire, jf. funn under) ulike mekanismar som alle
kan opplevast som «semantisk mapping»:

1. `class_uri` — RDF-URI-en klassen sjølv får ved serialisering
2. `exact_mappings` / `close_mappings` — SKOS-mappingslottar frå LinkML
3. `annotations.begrepsidentifikator` — repo-eigen annotasjon som peikar til eit
   fagomgrep i Felles begrepskatalog (FBK)
4. `see_also` — brukt i praksis til å peike til FBK-omgrep (`data.norge.no/concepts/<uuid>`),
   sjølv om han ikkje var nemnd i oppdraget

Denne specen er ei **utgreiing** — ho landar på ei tilråding, men gjer *ingen*
skjemaendringar. Endring av `annotations.begrepsidentifikator`-konvensjonen
råkar alle domenemodellar, MCP-verktøy (`mcp-linkml-modell-utkast`,
`mcp-linkml-validator`) og policy-sjekkane (bronze/silver/gold), og bør difor
handterast som eiga oppfølgingssak — jf. GOVERNANCE.md RFC-krav for
`class_uri`-relaterte breaking changes.

---

## 1. Kartlegging av faktisk bruk

| Mekanisme | Kor mange skjema | Kor brukt |
|---|---|---|
| `class_uri` | 30 skjema, 495 førekomstar | Alle domenemodellar og AP-NO-profilar (obligatorisk, bronze warning → silver/gold error) |
| `annotations.begrepsidentifikator` | 9 skjema (`enhetsregisteret-bvrinn`, `javazonetalk`, `lunchregisteret`, `referansemodell*` (4), `samt-bu`) | Krevst frå bronze (warning) → gold (error), jf. `policies/bronze.yaml:133`, `policies/gold.yaml:105` |
| `exact_mappings` / `close_mappings` | **Berre `samt-bu-schema.yaml`** (8 førekomstar av `exact_mappings`) | Ikkje policy-kravd nokon stad, ikkje generert av `mcp-linkml-modell-utkast` |
| `see_also` | Brukt ad hoc i `samt-bu-schema.yaml` og `brreg-begrepskatalog` (`sja_ogsa_omgrep`) | Ikkje policy-kravd, men CLAUDE.md nemner han som «legitim» for FBK-referansar |

**Funn 1:** `exact_mappings`/`close_mappings` er i praksis **eit eksperiment i eitt
skjema**, ikkje ein etablert konvensjon. `mcp-linkml-modell-utkast/converter.py`
genererer aldri desse feltene (kun `class_uri` og ein
`begrepsidentifikator`-stubb, sjå `converter.py:390-392`) — så alle andre
skjema manglar dei fullstendig, ikkje fordi dei er irrelevante, men fordi
ingen dokumentasjon eller verktøystøtte har bedt forfattarane om å fylle dei ut.

---

## 2. Kva gjer kvar mekanisme teknisk (verifisert mot generert RDF)

Eg har inspisert generert `.ttl` for `samt-bu` (`generated/samt/samt-bu/samt-bu-ontology.ttl`)
for å sjå kva som faktisk kjem ut, ikkje berre kva YAML seier:

```turtle
# class_uri + exact_mappings — samtbuskole:Skole (linje 2078-2093)
samtbu:Skole a owl:Class ;
    rdfs:label "Skole" ;
    rdfs:seeAlso <https://data.norge.no/concepts/fc9d0dda-71a2-3925-8688-52f849cf0f49> ;
    skos:definition "En skole er en privat eller offentlig institusjon ..." ;
    skos:exactMatch <http://schema.org/EducationalOrganization>,
        org:OrganizationalUnit,
        samtbuskole:Skole ;
    ...
    samtbu:begrepsidentifikator "https://concept-catalog.fellesdatakatalog.digdir.no/collections/964338531/concepts/017cdf77-afb1-44e3-8845-08fe570e251d" .
```

Dette gir tre viktige, ikkje-openbare observasjonar:

- **`exact_mappings` → `skos:exactMatch`** — ein ekte, standardisert RDF
  **objektrelasjon** (peikar til ein IRI-node i grafen). Verktøy som forstår SKOS
  kan følgje han.
- **`see_also` → `rdfs:seeAlso`** — også ein ekte objektrelasjon, standard RDF,
  ingen typerestriksjon på kva han peikar til.
- **`annotations.begrepsidentifikator` → `samtbu:begrepsidentifikator "..."^^xsd:anyURI`**
  — dette er **ikkje** ein objektrelasjon. Det er ein eigendefinert, skjemalokal
  datatype-property med ein **strengverdi** som *ser ut som* ein URI, men som
  ikkje er ein resolverbar RDF-lenke. Ingen ekstern SKOS/RDF-verktøy kjenner
  igjen `samtbu:begrepsidentifikator` som noko anna enn ein vilkårleg tekststreng.

**Funn 2:** Mekanismen som policyen *krev* frå bronse og oppover
(`begrepsidentifikator`) er den **teknisk svakaste** av dei tre/fire —
han produserer ikkje ei ekte semantisk lenke i det publiserte RDF-et, medan
`see_also` (som ikkje er kravd av nokon policy) allereie gjer den jobben
riktig.

---

## 3. Overlapp-analyse

| Par | Overlappar dei? | Grunngjeving |
|---|---|---|
| `class_uri` vs. `exact_mappings` | **Nei** | `class_uri` er klassen si eiga identitet (kva han *er*). `exact_mappings` seier kva han *tilsvarar* i andre vokabular (foaf:Person, org:Organization). Komplementære, ikkje konkurrerande. |
| `class_uri` vs. `begrepsidentifikator` | **Nei, ulik ressurstype** | `class_uri` peikar til ein RDF-**klasse** (`owl:Class`/`rdfs:Class`). Eit FBK-omgrep er ein `skos:Concept`-**instans**. Å bruke `class_uri` til å peike på eit omgrep ville vore ein typefeil (klasse referert som om han var ein instans). |
| `exact_mappings` vs. `begrepsidentifikator` | **Delvis, men bør ikkje brukast om kvarandre** | Begge er "peik til noko relatert eksternt", men SKOS-mappingslottane (`exact_mappings`/`close_mappings`/`related_mappings`) har formelt domene/rekkevidde `skos:Concept ↔ skos:Concept` (skos:exactMatch er definert mellom omgrep). Ei domeneklasse (`owl:Class`) er *ikkje* eit `skos:Concept`. Å bruke `exact_mappings` til å peike på eit FBK-omgrep ville difor vore den same typefeilen som over — berre med eit standardisert i staden for eigendefinert predikat. `see_also` (`rdfs:seeAlso`) har derimot **inga** typerestriksjon, og er difor det korrekte verktøyet for akkurat denne klasse→omgrep-koplinga. |
| `see_also` vs. `begrepsidentifikator` | **Delvis — same begrep, to ulike URI-system, ikkje data-drift** | Begge peikar til *same* omgrep i FBK, men via to ulike identifikator-ordningar FBK sjølv held: éin resolverbar, éin ikkje. Sjå revidert Funn 3. |

**Tillegg — kvifor ein generisk `see_also` ikkje er nok åleine:** `see_also`
er allereie i bruk til noko *anna* enn begrepsreferansar. I `samt-bu-schema.yaml`
peikar eit `see_also`-felt til `https://docs.samt-bu.no/om/` (dokumentasjon),
medan andre `see_also`-felt peikar til FBK-omgrep. `rdfs:seeAlso` er ei rein
RDF-triple — han ber ingen eigen kontekst om *kva slags* relasjon det er
snakk om utover predikatet sjølv. Slår ein alle bruksområde saman i éin
generisk `see_also`-liste, misser ein evna til å skilje «dette er eit
begrepskatalog-omgrep» frå «dette er ei dokumentasjonsside» — verken for
menneske som les skjemaet eller for verktøy som validerer det (jf. § 4,
reviderte skisse).

**Funn 3 (revidert) — same begrep, to ulike identifikator-format, éin
resolverbar og éin ikkje:** For klassen `Skole` i `samt-bu-schema.yaml`:

```yaml
see_also:
  - https://data.norge.no/concepts/fc9d0dda-71a2-3925-8688-52f849cf0f49
annotations:
  begrepsidentifikator: https://concept-catalog.fellesdatakatalog.digdir.no/collections/964338531/concepts/017cdf77-afb1-44e3-8845-08fe570e251d
```

Dette er **ikkje** data-drift mellom to usamde felt, slik førre versjon av
denne specen konkluderte. Dei to URI-ane peikar til det *same* omgrepet i
Felles begrepskatalog, men uttrykt gjennom to ulike identifikator-ordningar
FBK sjølv held:

- `see_also` → `https://data.norge.no/concepts/<uuid>` — **den resolverbare**
  offentlege URL-en til omgrepet (den «pene» framsida ein kan opne i
  nettlesar).
- `annotations.begrepsidentifikator` → `https://concept-catalog.fellesdatakatalog.digdir.no/collections/<collection-id>/concepts/<uuid>`
  — **den ikkje-resolverbare** samlings-/API-interne URI-en til det same
  omgrepet (identifiserer kva `collection` — dvs. kva verksemd sin
  begrepskatalog — omgrepet høyrer til).

Dei to UUID-ane er difor forskjellige *identifikatorar i to system*, ikkje
to ulike omgrep. Dette endrar konklusjonen frå § 2 (Funn 2) frå «to felt
kan drifte frå kvarandre» til noko meir presist: **policyen krev i dag
(bronse→gull) den ikkje-resolverbare identifikatoren
(`begrepsidentifikator`), medan den resolverbare, brukarvendte lenka
(`see_also`) er valfri.** Det gjer § 4 sin `begrep_ref`-skisse (som skal
halde den resolverbare `data.norge.no/concepts/<uuid>`-forma, ikkje
`collections/`-forma) endå meir grunngjeven — han byter ut den
ikkje-resolverbare, policy-kravde identifikatoren med den resolverbare
varianten FBK sjølv publiserer.

---

## 4. Spesifikt: kan vi endre måten vi refererer til FBK-omgrep? Eigen begrepsontologi?

**Vi har allereie ein eigen begrepsontologi.** `src/linkml/begrepskatalog/brreg-begrepskatalog/`
er nøyaktig det spurt om: eit lokalt SKOS-AP-NO-Begrep-skjema
(`Begrep`-klasse = `skos:Concept`) med eigne, midlertidige URI-ar
(`https://begrep.brreg.no/<slug>`), meint som mellomstasjon før hausting til
FBK — dokumentert i detalj i `specs/done/begrep-modellering.md`. Mønsteret
brukar allereie `sja_ogsa_omgrep` (= `rdfs:seeAlso`) for å peike vidare til
FBK-UUID-en når han er kjend.

**Men mekanismen er i dag ikkje brukande i praksis:** `begrep.brreg.no`
løyser ikkje opp (`ECONNREFUSED`, domenet er lagt ned) — dokumentert som ope,
ikkje-løyst avvik **PO2** i `specs/backlog/avvik-peikarar-til-offentlege-ressursar.md`.
Så lenge dette står ope, vil enhver ny konvensjon som ber domenemodellar
referere til `brreg-begrepskatalog` sine URI-ar bryte det same
kravet om persistente, oppløysbare URI-ar som resten av repoet elles held seg til
(jf. PRINCIPLES.md/CLAUDE.md sin URI-praksis).

**Kan `exact_mappings` eller `class_uri` brukast til å referere til ein slik
begrepsontologi (lokal eller FBK)?** Nei, av same grunn som i § 3: begge peikar
i LinkML-/OWL-semantikk til andre **klassar**, ikkje til `skos:Concept`-instansar.
Riktig verktøy for klasse→omgrep-referansen er `see_also` (`rdfs:seeAlso`),
som er typenøytral og allereie brukt slik i praksis (om enn inkonsekvent, jf. Funn 3).

### Konkret skisse: namngjevne slots som deler `slot_uri: rdfs:seeAlso`

Ein generisk `see_also`-liste løyser RDF-standardkonformiteten, men mistar
konteksten om *kva* kvar lenke gjeld (jf. tillegget over). RDF-triplar kan
ikkje bere eiga metadata utan reifikasjon, og å pakke lenka inn i eit objekt
(`{uri, kommentar}`) ville endra `rdfs:seeAlso` frå ei direkte, oppløysbar
lenke til ein indirekte peikar via ein mellomnode — eit standardavvik i seg
sjølv.

Løysinga er å la **slotnamnet vere labelen**, ikkje verdien. LinkML tillèt at
fleire ulikt namngjevne slots deler same `slot_uri` — dette er alt etablert
praksis i repoet (`kommunenummer` og `fylkesnummer` i `samt-bu-schema.yaml`
deler begge `slot_uri: dcat:identifier`). Same mønster brukt her:

```yaml
slots:
  begrep_ref:
    slot_uri: rdfs:seeAlso
    description: >-
      Peikar til begrepet si definisjon — anten i organisasjonens eigen
      begrepsontologi (før hausting) eller i Felles begrepskatalog (etter
      hausting). Same felt, oppdatert verdi ved overgang.
    range: uriorcurie
    multivalued: true

  dokumentasjon_ref:
    slot_uri: rdfs:seeAlso
    description: Peikar til utfyllande dokumentasjon (t.d. spesifikasjon, rettleiing).
    range: uriorcurie
    multivalued: true

classes:
  Skole:
    class_uri: samtbuskole:Skole              # eiga RDF-identitet — uendra
    exact_mappings:                            # cross-vokabular alignment — uendra formål
      - org:OrganizationalUnit
      - schema:EducationalOrganization
    description: En skole er en privat eller offentlig institusjon ...
    slots:
      - begrep_ref
      - dokumentasjon_ref
    # FØR hausting til FBK: peik til lokal begrepsontologi (brreg-begrepskatalog)
    begrep_ref:
      - https://begrep.brreg.no/skole            # krev PO2 løyst for å vere gyldig
    # ETTER hausting til FBK: same felt, oppdatert verdi (éin kjelde, ingen duplikat)
    # begrep_ref:
    #   - https://data.norge.no/concepts/fc9d0dda-71a2-3925-8688-52f849cf0f49
```

I generert RDF vert begge slots vanlege `rdfs:seeAlso <mål>`-triplar —
identisk med korleis `see_also` alt serialiserer i dag (§ 2) — så ekstern
SKOS/RDF-tooling ser ingenting uvanleg. Skiljet finst berre i skjemaet,
JSON/YAML-instansdata og genererte docs, der det faktisk trengst.

`annotations.begrepsidentifikator` går ut som eige felt til fordel for
`begrep_ref`. Policy-sjekken `all_classes_have_concept_ref` (`server.py:291-306`)
endrar kjelde frå `cls.annotations.begrepsidentifikator` til `cls.begrep_ref`,
og **prefikset ho godtek endrar seg til den resolverbare forma**
(`https://data.norge.no/concepts/`) **eller** organisasjonen sin eigen
`begrep.<org>.no`-base for mellomstadium-verdiar (per `begrep-modellering.md`)
— ikkje lenger den ikkje-resolverbare `concept-catalog.fellesdatakatalog.digdir.no/collections/`-forma
frå dagens `begrepsidentifikator` (jf. revidert Funn 3).

---

## 5. Tilråding

**R1 — Løys PO2 (`begrep.brreg.no` er nede) før noko anna vurderast.**
Utan resolverbare URI-ar har ein «eigen begrepsontologi»-referanse ingen
praktisk verdi, uavhengig av kva LinkML-felt han knyter seg til. Dette er
allereie eit ope tiltak i `specs/backlog/avvik-peikarar-til-offentlege-ressursar.md` (PO2/PO3) — inga ny spec trengst for sjølve URI-fiksen.

**R2 — Erstatt `annotations.begrepsidentifikator` med eit dedikert
`begrep_ref`-slot som deler `slot_uri: rdfs:seeAlso`.** *(Revidert etter
oppfølgingsspørsmål — sjå § 4 for full skisse.)* Ein generisk, delt
`see_also`-liste vart vurdert først, men forkasta: han løyser
RDF-standardkonformiteten (§ 2, Funn 2), men gir ingen måte å seie *kva*
kvar lenke gjeld — og `see_also` er alt i bruk til anna enn begrepsreferansar
(dokumentasjonslenker, jf. § 3-tillegget). Løysinga er difor eit eige,
namngjeve slot (`begrep_ref`) som framleis serialiserer til ekte
`rdfs:seeAlso`-triplar i RDF (identisk med korleis `see_also` gjer det i dag),
men som held konteksten synleg i skjema, instansdata og genererte docs via
slotnamnet — same mønster som alt finst i repoet for delte `slot_uri`-verdiar
(`kommunenummer`/`fylkesnummer` → `dcat:identifier` i `samt-bu-schema.yaml`).
Dette gir det beste av begge: standardkonform RDF *og* eksplisitt kontekst,
utan reifikasjon. Framleis ei **breaking endring** for 9 skjema +
policy-sjekkane + `mcp-linkml-modell-utkast` sin stubb-generator, og bør
handterast med RFC-prosess (GOVERNANCE.md), ikkje som del av denne
utgreiinga.

**R3 — Behald `exact_mappings`/`close_mappings` uendra, men dokumenter
formålet eksplisitt.** Dei gjer noko reelt og standardbasert (SKOS-mapping
mellom domeneklassar og andre RDF-vokabular), er berre underdokumenterte —
i dag finst konvensjonen kun implisitt i eitt skjema (`samt-bu`). Legg til ei
kort forklaring i CONVENTIONS.md som skil dei eksplisitt frå
begreps-referansen: *«`exact_mappings`/`close_mappings` er for å knyte ein
klasse til tilsvarande klassar i andre RDF-vokabular (foaf, org, schema.org).
For å knyte ein klasse til eit fagomgrep i ein begrepskatalog, bruk
`see_also` — ikkje `exact_mappings`, sidan omgrep er SKOS-instansar, ikkje
RDF-klassar.»* Dette er ei rein dokumentasjonsendring, ikkje ei breaking
endring, og kan gjerast utan RFC.

**R4 — Behald `class_uri` heilt uendra.** Han er ikkje ein
mapping-mekanisme i same forstand som dei andre — han er klassen si eiga
definisjon, ikkje ei bru til noko anna. Ingen overlapp å rydde opp i.

### Prioritert handlingsliste (dersom ein vel å gå vidare)

| # | Tiltak | Avheng av | Type |
|---|---|---|---|
| 1 | R1: Løys `begrep.brreg.no`-resolvabilitet (PO2) | Ekstern (Brreg-infra) | Føresetnad |
| 2 | R3: Dokumenter `exact_mappings` vs. `see_also`-skiljet i CONVENTIONS.md | — | Dokumentasjon, ingen RFC |
| 3 | R2: RFC for å erstatte `begrepsidentifikator` med `begrep_ref` (delt `slot_uri: rdfs:seeAlso`) | #1 bør vere løyst først | RFC-prosess, breaking |
| 4 | R2 (oppfølging): Legg til `begrep_ref`-slot i relevante skjema, oppdater `server.py`, `bronze/silver/gold.yaml`, `converter.py`, migrer 9 skjema | RFC godkjent | Implementering |

---

## Ikkje-mål

Denne specen **gjer ikkje** noka av desse endringane. Ho svarar på
utgreiingsoppdraget (er mekanismane overlappande? kan vi bruke
`class_uri`/`exact_mappings` til eigen begrepsontologi?) og legg fram eit
konkret forslag. R2 (den einaste endringa med reelt migreringsomfang) skal
ikkje startast før brukaren har teke stilling til tilrådinga og eventuelt
opna RFC-issue per GOVERNANCE.md.
