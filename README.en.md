---
i18n:
  source: README.md
  source_hash: sha256:6427cab17acbad79d455de21a05a72bc6210150cf5c9dae8e19161a4acccd861
---
# linkml-datamodellering-no

!!! warning "Proof of Concept"

    This repository is a **Proof of Concept** for LinkML-based data modeling in the Norwegian public sector.
    
    **What this means:**
    
    - Models and tools are under development and may change
    - The documentation may be incomplete or outdated
    - Some features are only partially implemented
    - There are [known limitations and bugs](#limitations)
    - No guaranteed stability or support SLA
    
    **For external organizations:** Read [for contributors](#for-contributors) for expectations regarding stability and responsibility.

---

## Purpose

  This repository aims to implement parts of the [Framework for Information Management](https://www.digdir.no/informasjonsforvaltning/rammeverk-informasjonsforvaltning/3626) (Rammeverk for informasjonsforvaltning) that concern concept modeling, information modeling, metadata and publishing to the national concept catalog and data catalog, in accordance with national guidelines and standards. See [Standards compliance](https://audunautomat.github.io/linkml-datamodellering-no/en/arkitektur/standardetterleving/) for details.  
  It is intended as a shared toolbox for working with concepts and data models. Both models and tools can be used locally in other git repositories. 

---

## Contents

> [LinkML](https://linkml.io/) is an open-source modeling language where you write schemas in YAML that describe your data structure, and which you can use to generate schemas, data, diagrams and documentation in other formats ([LinkML generators](https://linkml.io/linkml/generators/index.html)). The generators convert both to traditional formats (JSON Schema, Python, Protobuf) and to W3C semantic formats (RDF/Turtle, OWL, SHACL, JSON-LD) without the need for additional mapping.

This [code repository](https://github.com/AudunAutomat/linkml-datamodellering-no) contains:

* LinkML [models](#schemas) for Norwegian [W3C application profiles](https://data.norge.no/showroom/overview) and public domain models for reuse.
* [mcp-linkml-modell-utkast](https://github.com/AudunAutomat/linkml-datamodellering-no/blob/main/src/mcp-linkml-modell-utkast/README.md) for generating drafts of new information models in LinkML format according to the [Framework for Information Management](https://www.digdir.no/informasjonsforvaltning/rammeverk-informasjonsforvaltning/3626).
* [mcp-linkml-begrep-utkast](https://github.com/AudunAutomat/linkml-datamodellering-no/blob/main/src/mcp-linkml-begrep-utkast/README.md) for generating drafts of new concepts in LinkML format according to the [SKOS-AP-NO standard](https://data.norge.no/specification/skos-ap-no-begrep).
* [mcp-linkml-validator](https://github.com/AudunAutomat/linkml-datamodellering-no/blob/main/src/mcp-linkml-validator/README.md) for validating LinkML schemas according to the [Common modeling rules for public administration](https://www.digdir.no/informasjonsforvaltning/felles-modelleringsregler-offentlig-forvaltning/3029) (Felles modelleringsregler for offentlig forvaltning) and the [FAIR principles](https://www.go-fair.org/fair-principles/). The validator implements quality policies (bronze, silver, gold), publishing policies (national concept catalog and national data catalog) and supports custom policies.
* [Model analyses](https://audunautomat.github.io/linkml-datamodellering-no/en/modellanalyse/) that help find deviations and follow-up points in individual models and across models.
* LinkML [generators](#generated-artifacts) for producing artifacts in other formats from LinkML schemas.
* GitHub Actions [pipelines](https://github.com/AudunAutomat/linkml-datamodellering-no/actions) for automatically generating, validating and publishing artifacts from LinkML schemas.
* A guide for publishing concepts to the [national concept catalog](https://audunautomat.github.io/linkml-datamodellering-no/en/publisering/publisering-begrep/) (Felles Begrepskatalog) according to the [SKOS-AP-NO standard](https://data.norge.no/specification/skos-ap-no-begrep).
* A guide for publishing information models to the [national data catalog](https://audunautomat.github.io/linkml-datamodellering-no/en/publisering/publisering-modell/) (Felles Datakatalog) according to the [ModelDCAT-AP-NO standard](https://data.norge.no/specification/modelldcat-ap-no).
* A GitHub Pages [documentation portal](https://audunautomat.github.io/linkml-datamodellering-no/en/) with an overview of all LinkML schemas and generated artifacts, styled according to [designsystemet.no](https://designsystemet.no/no).
* A setup for [bootstrapping](https://audunautomat.github.io/linkml-datamodellering-no/en/arkitektur/ekstern-bruk/) an external repository for local LinkML modeling.

---

## Limitations

> The repository is in a PoC phase and has some known limitations. See these documents for a complete overview:

- **[SCOPE.md](https://github.com/AudunAutomat/linkml-datamodellering-no/blob/main/SCOPE.md)** — what the repository is, what it is not, and what belongs here
- **[BUGS.md](https://github.com/AudunAutomat/linkml-datamodellering-no/blob/main/BUGS.md)** — complete list of known bugs and workarounds

**Report new problems:** Open a [GitHub Issue](https://github.com/AudunAutomat/linkml-datamodellering-no/issues) with the label `bug`.

**Questions and ideas:** Use [GitHub Discussions](https://github.com/AudunAutomat/linkml-datamodellering-no/discussions) for questions, ideas and sharing experience — Issues are for bug reports and concrete change proposals.

---

## Getting started

> Here is a quick introduction to setting up a local environment to get started with data modeling and concept work.

**Prerequisites:** Linux, or Windows with [WSL2](https://learn.microsoft.com/en-us/windows/wsl/install), [Git](https://git-scm.com/), [jq](https://jqlang.org/), [Podman](https://podman.io/) (rootless) and [GNU make](https://www.gnu.org/software/make/).

```bash
# Step 1 — before make/podman are installed: run the check script directly
bash src/assets/scripts/makefile/check-prereqs.bash
```
```bash
# Once make is confirmed installed, you can use the make target instead
make check-prereqs
```
```bash
# Build the container images (once)
make linkml-build-docker && make python-build-docker && make mcp-val-build && make mcp-mod-build && make mcp-begrep-build
```

### Data modeling

> Use the recipe below to get started with data modeling.

> Replace **`domene`** and **`modell`** with your own domain and model names.

```bash
# 1. Create a new empty LinkML schema (schema + file structure)
make new-modell DOMAIN=domene NAME=modell

# 1b. (optional) Generate from an existing JSON Schema
# Put the JSON Schema file in tmp/, e.g. tmp/modellnavn.json
make mcp-linkml-modell-utkast SCHEMA=tmp/modellnavn.json
# → generates tmp/modell-schema.yaml. Copy it to src/linkml/domene/modell/
```
```bash
# 2. Edit the model file as needed
#    → src/linkml/domene/modell/modell-schema.yaml
```
```bash
# 3. Validate the schema
make mcp-linkml-valider-modell \
  SCHEMA=src/linkml/domene/modell/modell-schema.yaml \
  POLICY=felles-datakatalog
```
```bash
# 4. (optional) specify which artifacts to generate and publish in build.yaml
# → src/linkml/domene/modell/build.yaml

# 4b. Generate artifacts and publish to the documentation portal
make <domene> && make docs-publish && make docs-serve DOCS_LANG=en   # → http://localhost:8000/linkml-datamodellering-no/en/
```

New schemas under `src/linkml/<domene>/<modell>/` are discovered automatically.

For the complete guide, see [New domain model](https://audunautomat.github.io/linkml-datamodellering-no/en/kom-i-gang/ny-domenemodell/) and [Publish to Felles Datakatalog](https://audunautomat.github.io/linkml-datamodellering-no/en/publisering/publisering-modell/).

### Concept modeling

> Use the recipe below to get started with concept modeling.

> Replace **`domene`**, **`begrepssamling`** and **`organisasjon`** with your own domain, concept collection and organization names.

```bash
# 1a. Create a new concept collection (file structure for concepts)
make new-begrepssamling DOMAIN=domene NAME=begrepssamling

# 1b. (optional) Generate concept drafts from existing text
make mcp-linkml-begrep-utkast INPUT=<path-to-text-file>
# → generates concept drafts in tmp/; copy them to src/linkml/domene/begrepssamling/begrep/begrepnavn.yaml
```
```bash
# 2. Edit the concepts as needed
#    → src/linkml/domene/begrepssamling/begrep/<begrep-slug>.yaml
```
```bash
# 3. Aggregate into a concept catalog
make gen-begrepskatalog-instance
```
```bash
# 4. Validate the concept catalog
make mcp-linkml-valider-modell \
  SCHEMA=src/linkml/begrepskatalog/<organisasjon>-begrepskatalog/<organisasjon>-begrepskatalog-schema.yaml \
  POLICY=felles-begrepskatalog
```
```bash
# 5a. (optional) specify which artifacts to generate from the concept catalog in build.yaml
#    → src/linkml/begrepskatalog/<organisasjon>-begrepskatalog/data/<organisasjon>-begrepskatalog/build.yaml

# 5b. Generate artifacts and publish to the documentation portal
make begrepskatalog && make docs-publish && make docs-serve DOCS_LANG=en   # → http://localhost:8000/linkml-datamodellering-no/en/
```

New concept collections under `src/linkml/<domene>/<begrepssamling>/` are discovered automatically.

For the complete guide, see [New concept catalog](https://audunautomat.github.io/linkml-datamodellering-no/en/kom-i-gang/ny-begrepsmodell/) and [Publish to Felles Begrepskatalog](https://audunautomat.github.io/linkml-datamodellering-no/en/publisering/publisering-begrep/).

See [CLAUDE.md](https://github.com/AudunAutomat/linkml-datamodellering-no/blob/main/CLAUDE.md) for modeling principles and [COMMANDS.md](https://github.com/AudunAutomat/linkml-datamodellering-no/blob/main/COMMANDS.md) for all available commands.

### Use from an external repository

> Want to use the AP-NO profiles in your own repository without working inside this monorepo?
> The bootstrap script adds the two files you need in a minute:

```bash
curl -sSL https://raw.githubusercontent.com/AudunAutomat/linkml-datamodellering-no/main/bootstrap.sh | bash
```

Then import the AP-NO profiles directly into your schema via a GitHub Raw URL:

```yaml
imports:
  - linkml:types
  - https://raw.githubusercontent.com/AudunAutomat/linkml-datamodellering-no/dcat-ap-no-v2.8.0/src/linkml/ap-no/dcat-ap-no/dcat-ap-no-schema
```

Validation and generation run through reusable GitHub Actions workflows in this repository — no local installation is required. See [Use from an external repository](https://audunautomat.github.io/linkml-datamodellering-no/en/arkitektur/ekstern-bruk/) for the complete guide.

---

## Domains

> The data models are grouped into domains.

The domains are located under `src/linkml/<domene>/`

| Domain | Description | Documentation |
|---|---|---|
| [FELLES](https://github.com/AudunAutomat/linkml-datamodellering-no/tree/main/src/linkml/felles/) | Reusable common components (address, actor, time, types) derived from the internal reference models of the Brønnøysund Register Centre (BR). Can be imported by domain models. |
| [REFERANSE](https://github.com/AudunAutomat/linkml-datamodellering-no/tree/main/src/linkml/referanse/) | Simple examples of valid LinkML models (reference implementations) 
| [FAIR](https://github.com/AudunAutomat/linkml-datamodellering-no/tree/main/src/linkml/fair/) | **FAIR** metadata superstructure — **F**indable, **A**ccessible, **I**nteroperable, **R**eusable. Can be imported by all domain models. | [FAIR principles](https://www.go-fair.org/fair-principles/)
| [AP-NO](https://github.com/AudunAutomat/linkml-datamodellering-no/tree/main/src/linkml/ap-no/) | Norwegian W3C application profiles — DCAT, SKOS, CPSV, DQV and more. Imported by domain models. | [RDF-based machine-readable resources](https://data.norge.no/showroom/overview)
| [NGR](https://github.com/AudunAutomat/linkml-datamodellering-no/tree/main/src/linkml/ngr/) | National master data (Nasjonale grunndata) — address, property, person and business. | [Nasjonale grunndata](https://informasjonsforvaltning.github.io/nasjonale-grunndata/#OmNasjonaleGrunndata)
| [OREG](https://github.com/AudunAutomat/linkml-datamodellering-no/tree/main/src/linkml/oreg/) | Public registers. |
| [FINT](https://github.com/AudunAutomat/linkml-datamodellering-no/tree/main/src/linkml/fint/) | FINT common component — integration models for the county municipality sector. | [FINT information model](https://informasjonsmodell.felleskomponent.no/docs?v=v4.0.20)
| [SAMT](https://github.com/AudunAutomat/linkml-datamodellering-no/tree/main/src/linkml/samt/) | SAMT — integration models for the municipal sector. | [The SAMT project](https://docs.samt-bu.no/om/)
| [BEGREPSKATALOG](https://github.com/AudunAutomat/linkml-datamodellering-no/tree/main/src/linkml/begrepskatalog/) | Concept catalog according to SKOS-AP-NO-Begrep. Instance data files are automatically converted to SKOS/RDF for publishing to Felles Begrepskatalog. | [SKOS-AP-NO-Begrep](https://data.norge.no/specification/skos-ap-no-begrep)
| [MODELLKATALOG](https://github.com/AudunAutomat/linkml-datamodellering-no/tree/main/src/linkml/modellkatalog/) | Model catalog for information models according to ModelDCAT-AP-NO for publishing to Felles Datakatalog. | [ModelDCAT-AP-NO](https://data.norge.no/specification/modelldcat-ap-no)

---

## Schemas

> There is one schema in LinkML format for each data model.

The schemas are located under `src/linkml/<domene>/<modell>/`. Schema descriptions are model content and are shown in Norwegian.

<!-- BEGIN AUTO-GENERATED: src/assets/scripts/makefile/generate-readme-tables.sh generate_schema_table -->
| Domain | Schema | Description | Documentation
|---|---|---|---|
| [FELLES](https://audunautomat.github.io/linkml-datamodellering-no/en/felles/) | [brreg-felles-aktoer](https://audunautomat.github.io/linkml-datamodellering-no/en/felles/brreg-felles-aktoer/) | Gjenbrukbare aktørklassar (Aktør, Virksomhet, Person, Rolle m.fl.) utleia frå Brønnøysundregistrene (BR) sin interne BRReferansemodell_v3 (MagicDraw/XMI), pakken "Aktør", pluss dei aktør-relaterte komplekstypane frå Strukturtypekatalog_v1 (Personnavn, Personidentifikator, Virksomhetsidentifikator) som aktørklassane er avhengige av. Importerer brreg-felles-geografisk-adresse for GeografiskAdresse og brreg-felles-digital-adresse for DigitalAdresse. Sjå specs/done/felles-typar-enhetsregisteret-fra-br-katalogar.md for bakgrunn, metode og avklaringane denne modellen byggjer på. | 
| [FELLES](https://audunautomat.github.io/linkml-datamodellering-no/en/felles/) | [brreg-felles-digital-adresse](https://audunautomat.github.io/linkml-datamodellering-no/en/felles/brreg-felles-digital-adresse/) | Gjenbrukbare digitale adresseklassar utleia frå Brønnøysundregistrene (BR) sin interne BRReferansemodell_v3 (MagicDraw/XMI), pakken "Adresse" (DigitalAdresse-hierarkiet). Sjå specs/done/felles-typar-enhetsregisteret-fra-br-katalogar.md for bakgrunn, metode og avklaringane denne modellen byggjer på.  BR sin eigen `Nettadresse`-undertype "Aksesspunkt" er medvite utelaten her: feltet `aksesspunktoperatoer` peikar til `Virksomhet` (definert i brreg-felles-aktoer, som importerer denne modellen) og ville gjort importgrafen sirkulær. Sjå nemnde spec § Funn 4. | 
| [FELLES](https://audunautomat.github.io/linkml-datamodellering-no/en/felles/) | [brreg-felles-geografisk-adresse](https://audunautomat.github.io/linkml-datamodellering-no/en/felles/brreg-felles-geografisk-adresse/) | Gjenbrukbare geografiske adresseklassar utleia frå Brønnøysundregistrene (BR) sin interne BRReferansemodell_v3 (MagicDraw/XMI), pakken "Adresse" (GeografiskAdresse-hierarkiet), pluss dei adresse-relaterte komplekstypane frå Strukturtypekatalog_v1 (Poststed, Kommune, Fylke, Matrikkelnummer, Adressenummer) som adressehierarkiet er avhengig av. Sjå specs/done/felles-typar-enhetsregisteret-fra-br-katalogar.md for bakgrunn, metode og avklaringane denne modellen byggjer på. | 
| [FELLES](https://audunautomat.github.io/linkml-datamodellering-no/en/felles/) | [brreg-felles-tid](https://audunautomat.github.io/linkml-datamodellering-no/en/felles/brreg-felles-tid/) | Gjenbrukbare tidsperiode-klassar utleia frå Brønnøysundregistrene (BR) sin interne Strukturtypekatalog_v1 (MagicDraw/XMI), pakken "Komplekstyper" (Tidsperiode, TidsperiodeDatoKlokkeslett). Sjå specs/done/felles-typar-enhetsregisteret-fra-br-katalogar.md for bakgrunn, metode og avklaringane denne modellen byggjer på. | 
| [FELLES](https://audunautomat.github.io/linkml-datamodellering-no/en/felles/) | [brreg-felles-typer](https://audunautomat.github.io/linkml-datamodellering-no/en/felles/brreg-felles-typer/) | Gjenbrukbare primitivtypar utleia frå Brønnøysundregistrene (BR) sin interne Løsningstypekatalog_v1 (MagicDraw/XMI). Skjemaet er den felles kjelda for typar som elles vart lokalt (og inkonsistent) redefinert i kvart av dei sju enhetsregisteret-*-skjemaa, jf. specs/done/felles-typar-enhetsregisteret-fra-br-katalogar.md. Berre denne kjeldekatalogen ("Løsningsmodell"-laget hos BR) er brukt her — BRReferansemodell_v3 sitt eige, arva typelag i Strukturtypekatalog_v1 er eit separat, ikkje-importert lag (sjå nemnde spec, Funn 3). | 
| [FAIR](https://audunautomat.github.io/linkml-datamodellering-no/en/fair/) | [fair-metadata](https://audunautomat.github.io/linkml-datamodellering-no/en/fair/fair-metadata/) | "FAIR-metadataoverbygning (FAIR-prinsippa)" | [www.go-fair.org](https://www.go-fair.org/fair-principles/)
| [AP-NO](https://audunautomat.github.io/linkml-datamodellering-no/en/ap-no/) | [common-ap-no](https://audunautomat.github.io/linkml-datamodellering-no/en/ap-no/common-ap-no/) | Felles slot-definisjonar for alle AP-NO-profilar | 
| [AP-NO](https://audunautomat.github.io/linkml-datamodellering-no/en/ap-no/) | [cpsv-ap-no](https://audunautomat.github.io/linkml-datamodellering-no/en/ap-no/cpsv-ap-no/) | Offentlege tenester og hendingar | [data.norge.no](https://data.norge.no/specification/cpsv-ap-no)
| [AP-NO](https://audunautomat.github.io/linkml-datamodellering-no/en/ap-no/) | [dcat-ap-no](https://audunautomat.github.io/linkml-datamodellering-no/en/ap-no/dcat-ap-no/) | Datakatalogar og datasett | [data.norge.no](https://data.norge.no/specification/dcat-ap-no)
| [AP-NO](https://audunautomat.github.io/linkml-datamodellering-no/en/ap-no/) | [dqv-ap-no](https://audunautomat.github.io/linkml-datamodellering-no/en/ap-no/dqv-ap-no/) | Datakvalitet | [data.norge.no](https://data.norge.no/specification/dqv-ap-no)
| [AP-NO](https://audunautomat.github.io/linkml-datamodellering-no/en/ap-no/) | [dqv-core](https://audunautomat.github.io/linkml-datamodellering-no/en/ap-no/dqv-core/) | DQV-kjerneklasser og -slots utan referanse til dcat-ap-no. Denne fila vert importert av dcat-ap-no for å gje tilgang til Kvalitetsmerknad og Kvalitetsmaaling på Datasett, utan å skape sirkulær import. dqv-ap-no importerer dcat-ap-no og narrowar har_maal.range via slot_usage. | 
| [AP-NO](https://audunautomat.github.io/linkml-datamodellering-no/en/ap-no/) | [modelldcat-ap-no](https://audunautomat.github.io/linkml-datamodellering-no/en/ap-no/modelldcat-ap-no/) | Informasjonsmodellar | [data.norge.no](https://data.norge.no/specification/modelldcat-ap-no)
| [AP-NO](https://audunautomat.github.io/linkml-datamodellering-no/en/ap-no/) | [modelldcat-katalog](https://audunautomat.github.io/linkml-datamodellering-no/en/ap-no/modelldcat-katalog/) | Katalogklasser frå ModelDCAT-AP-NO: Modellkatalog, Informasjonsmodell og modelldcat-spesifikke hjelpeklasser (Lisensdokument, Dokument). Klasser som er felles med DCAT-AP-NO (Aktoer, Kontaktopplysning, Standard, Tidsrom, KatalogisertRessurs) er arvde via import av dcat-ap-no-schema. Basert på https://data.norge.no/specification/modelldcat-ap-no#Egenskaper-katalogdel | 
| [AP-NO](https://audunautomat.github.io/linkml-datamodellering-no/en/ap-no/) | [modelldcat-modell](https://audunautomat.github.io/linkml-datamodellering-no/en/ap-no/modelldcat-modell/) | Modellelement-klasser frå ModelDCAT-AP-NO: Objekttype, Datatype, Kodeliste, Egenskap og alle subklasser, samt Kodeelement. Basert på https://data.norge.no/specification/modelldcat-ap-no#Modeldel | 
| [AP-NO](https://audunautomat.github.io/linkml-datamodellering-no/en/ap-no/) | [skos-ap-no](https://audunautomat.github.io/linkml-datamodellering-no/en/ap-no/skos-ap-no/) | Omgrepsamlingar | [data.norge.no](https://data.norge.no/specification/skos-ap-no-begrep)
| [AP-NO](https://audunautomat.github.io/linkml-datamodellering-no/en/ap-no/) | [xkos-ap-no](https://audunautomat.github.io/linkml-datamodellering-no/en/ap-no/xkos-ap-no/) | Utvida klassifikasjon | [data.norge.no](https://data.norge.no/specification/xkos-ap-no)
| [REFERANSE](https://audunautomat.github.io/linkml-datamodellering-no/en/referanse/) | [referansemodell-bronze](https://audunautomat.github.io/linkml-datamodellering-no/en/referanse/referansemodell-bronze/) | Viser krava i bronsepolicyen (generisk LinkML-baseline): HTTP(S)-id, schema-metadata (title, version, license), default_prefix som absolutt URI og LinkML-navnekonvensjonar. Inneheld i tillegg class_uri, identifier-slot, slot_uri og begrepsidentifikator, som er krav frå basis-no. | 
| [REFERANSE](https://audunautomat.github.io/linkml-datamodellering-no/en/referanse/) | [referansemodell-gold](https://audunautomat.github.io/linkml-datamodellering-no/en/referanse/referansemodell-gold/) | Viser minstekrava for å bestå gullpolicyen: alle sølv-krav pluss FAIR-metadata (title, version, prefiks, lisens, proveniens). | 
| [REFERANSE](https://audunautomat.github.io/linkml-datamodellering-no/en/referanse/) | [referansemodell-silver](https://audunautomat.github.io/linkml-datamodellering-no/en/referanse/referansemodell-silver/) | Viser minstekrava for å bestå sølvpolicyen: alle bronse-krav pluss DCAT-AP-NO og DQV-AP-NO-klasser med påkravde slots og containerklasse. | 
| [REFERANSE](https://audunautomat.github.io/linkml-datamodellering-no/en/referanse/) | [referansemodell](https://audunautomat.github.io/linkml-datamodellering-no/en/referanse/referansemodell/) | Enkel eksempelmodell for å demonstrere gyldig LinkML-struktur | 
| [NGR](https://audunautomat.github.io/linkml-datamodellering-no/en/ngr/) | [ngr-adresse](https://audunautomat.github.io/linkml-datamodellering-no/en/ngr/ngr-adresse/) | Adresse | [informasjonsforvaltning.github.io](https://informasjonsforvaltning.github.io/nasjonale-grunndata/#Adresse)
| [NGR](https://audunautomat.github.io/linkml-datamodellering-no/en/ngr/) | [ngr-eiendom](https://audunautomat.github.io/linkml-datamodellering-no/en/ngr/ngr-eiendom/) | Fast eigedom, matrikkeleining og bygning | [informasjonsforvaltning.github.io](https://informasjonsforvaltning.github.io/nasjonale-grunndata/#Temaomr%C3%A5deEiendom)
| [NGR](https://audunautomat.github.io/linkml-datamodellering-no/en/ngr/) | [ngr-person](https://audunautomat.github.io/linkml-datamodellering-no/en/ngr/ngr-person/) | Person, identifikasjon og familierelasjonar | [informasjonsforvaltning.github.io](https://informasjonsforvaltning.github.io/nasjonale-grunndata/#Person)
| [NGR](https://audunautomat.github.io/linkml-datamodellering-no/en/ngr/) | [ngr-virksomhet](https://audunautomat.github.io/linkml-datamodellering-no/en/ngr/ngr-virksomhet/) | Verksemder, roller og organisasjonsstruktur | [informasjonsforvaltning.github.io](https://informasjonsforvaltning.github.io/nasjonale-grunndata/#Virksomhet)
| [OREG](https://audunautomat.github.io/linkml-datamodellering-no/en/oreg/) | [enhetsregisteret-bvrbekreftelse](https://audunautomat.github.io/linkml-datamodellering-no/en/oreg/enhetsregisteret-bvrbekreftelse/) | Generert modell for 'enhetsregisteret_bvrbekreftelse'. | 
| [OREG](https://audunautomat.github.io/linkml-datamodellering-no/en/oreg/) | [enhetsregisteret-bvrettersendingavvedlegg](https://audunautomat.github.io/linkml-datamodellering-no/en/oreg/enhetsregisteret-bvrettersendingavvedlegg/) | Generert modell for 'enhetsregisteret_bvrettersendingavvedlegg'. | 
| [OREG](https://audunautomat.github.io/linkml-datamodellering-no/en/oreg/) | [enhetsregisteret-bvrfriv](https://audunautomat.github.io/linkml-datamodellering-no/en/oreg/enhetsregisteret-bvrfriv/) | Generert modell for 'enhetsregisteret_bvrfriv'. | 
| [OREG](https://audunautomat.github.io/linkml-datamodellering-no/en/oreg/) | [enhetsregisteret-bvrinnfelles](https://audunautomat.github.io/linkml-datamodellering-no/en/oreg/enhetsregisteret-bvrinnfelles/) | Berettigede, verger, rettighetshavere i næring (BVRiNN) | 
| [OREG](https://audunautomat.github.io/linkml-datamodellering-no/en/oreg/) | [enhetsregisteret-bvrstiftelsesdokument](https://audunautomat.github.io/linkml-datamodellering-no/en/oreg/enhetsregisteret-bvrstiftelsesdokument/) | Generert modell for 'enhetsregisteret_bvrstiftelsesdokument'. | 
| [OREG](https://audunautomat.github.io/linkml-datamodellering-no/en/oreg/) | [enhetsregisteret-frivilligorganisasjonapi](https://audunautomat.github.io/linkml-datamodellering-no/en/oreg/enhetsregisteret-frivilligorganisasjonapi/) | Generert modell for 'enhetsregisteret_frivilligorganisasjonapi'. | 
| [OREG](https://audunautomat.github.io/linkml-datamodellering-no/en/oreg/) | [javazonetalk](https://audunautomat.github.io/linkml-datamodellering-no/en/oreg/javazonetalk/) | Generert modell for 'javazonetalk'. | 
| [OREG](https://audunautomat.github.io/linkml-datamodellering-no/en/oreg/) | [register-over-aksjeeiere](https://audunautomat.github.io/linkml-datamodellering-no/en/oreg/register-over-aksjeeiere/) | Aksjeeigarar og eigedelar | 
| [FINT](https://audunautomat.github.io/linkml-datamodellering-no/en/fint/) | [fint-administrasjon](https://audunautomat.github.io/linkml-datamodellering-no/en/fint/fint-administrasjon/) | Lønn, arbeidsforhold, organisasjon | [informasjonsmodell.felleskomponent.no](https://informasjonsmodell.felleskomponent.no/docs/package_administrasjon?v=v4.0.20)
| [FINT](https://audunautomat.github.io/linkml-datamodellering-no/en/fint/) | [fint-arkiv](https://audunautomat.github.io/linkml-datamodellering-no/en/fint/fint-arkiv/) | Sak, journal, dokument | [informasjonsmodell.felleskomponent.no](https://informasjonsmodell.felleskomponent.no/docs/package_arkiv?v=v4.0.20)
| [FINT](https://audunautomat.github.io/linkml-datamodellering-no/en/fint/) | [fint-common](https://audunautomat.github.io/linkml-datamodellering-no/en/fint/fint-common/) | Felles klasser for FINT | 
| [FINT](https://audunautomat.github.io/linkml-datamodellering-no/en/fint/) | [fint-okonomi](https://audunautomat.github.io/linkml-datamodellering-no/en/fint/fint-okonomi/) | Økonomi og rekneskap | [informasjonsmodell.felleskomponent.no](https://informasjonsmodell.felleskomponent.no/docs/package_okonomi?v=v4.0.20)
| [FINT](https://audunautomat.github.io/linkml-datamodellering-no/en/fint/) | [fint-personvern](https://audunautomat.github.io/linkml-datamodellering-no/en/fint/fint-personvern/) | Personvernmeldingar | [informasjonsmodell.felleskomponent.no](https://informasjonsmodell.felleskomponent.no/docs/package_personvern?v=v4.0.20)
| [FINT](https://audunautomat.github.io/linkml-datamodellering-no/en/fint/) | [fint-ressurs](https://audunautomat.github.io/linkml-datamodellering-no/en/fint/fint-ressurs/) | Ressursar | [informasjonsmodell.felleskomponent.no](https://informasjonsmodell.felleskomponent.no/docs/package_ressurs?v=v4.0.20)
| [FINT](https://audunautomat.github.io/linkml-datamodellering-no/en/fint/) | [fint-utdanning](https://audunautomat.github.io/linkml-datamodellering-no/en/fint/fint-utdanning/) | Utdanning og skule | [informasjonsmodell.felleskomponent.no](https://informasjonsmodell.felleskomponent.no/docs/package_utdanning?v=v4.0.20)
| [SAMT](https://audunautomat.github.io/linkml-datamodellering-no/en/samt/) | [samt-bu](https://audunautomat.github.io/linkml-datamodellering-no/en/samt/samt-bu/) | Skular og barnehagar | [docs.samt-bu.no](https://docs.samt-bu.no/om/)
<!-- END AUTO-GENERATED: src/assets/scripts/makefile/generate-readme-tables.sh generate_schema_table -->

The **AP-NO profiles** and **FAIR metadata** are schemas without `tree_root` — they are not standalone, but are meant to be imported by domain models.

---

## Generated artifacts

> You can generate artifacts from the LinkML schema.

Generated artifacts are located under `generated/<domene>/<modell>/`.  
Run `make <domene>` to generate all artifacts for a domain.  
Each model can turn off individual generators via `src/linkml/<domene>/<modell>/build.yaml` — see [Generator configuration](https://audunautomat.github.io/linkml-datamodellering-no/en/kom-i-gang/build-config/) for details.

| Artifact | File | Use case | W3C semantic | build.yaml flag | Generator |
|---|---|---|---|---|---|
| Model metadata according to ModelDCAT-AP-NO | `metadata/<skjema>-manifest.yaml` | ModelDCAT-AP-NO metadata for publishing to Felles Datakatalog | ✓ | — | [`gen-informasjonsmodell-instance`](https://github.com/AudunAutomat/linkml-datamodellering-no/blob/main/COMMANDS.md#gen-informasjonsmodell-instance) |
| JSON-LD context | `<skjema>-context.jsonld` | Mapping from JSON to RDF — used together with APIs | ✓ | `jsonld_context` | [`gen-jsonld-context`](https://github.com/AudunAutomat/linkml-datamodellering-no/blob/main/COMMANDS.md#gen-jsonld-context) |
| SHACL shapes | `<skjema>-shapes.ttl` | Validation of RDF data against the schema in triple stores | ✓ | `shacl` | [`gen-shacl`](https://github.com/AudunAutomat/linkml-datamodellering-no/blob/main/COMMANDS.md#gen-shacl) |
| OWL ontology | `<skjema>-ontology.ttl` | Machine-readable ontology for semantic tools | ✓ | `owl` | [`gen-owl`](https://github.com/AudunAutomat/linkml-datamodellering-no/blob/main/COMMANDS.md#gen-owl) |
| RDF/Turtle schema | `<skjema>-schema.ttl` | Complete RDF representation of the schema | ✓ | `rdf` | [`gen-rdf`](https://github.com/AudunAutomat/linkml-datamodellering-no/blob/main/COMMANDS.md#gen-rdf) |
| Example RDF | `<skjema>-eksempel.ttl` | Concrete RDF instance for testing and documentation | ✓ | `example_rdf` | [`convert-instance-rdf`](https://github.com/AudunAutomat/linkml-datamodellering-no/blob/main/COMMANDS.md#convert-instance-rdf) |
| Python classes | `<skjema>-model.py` | Direct use in Python applications via LinkML | — | `python` | [`gen-python`](https://github.com/AudunAutomat/linkml-datamodellering-no/blob/main/COMMANDS.md#gen-python) |
| JSON Schema | `<skjema>-schema.json` | Validation of JSON data in applications and RESTful integration | — | `json_schema` | [`gen-jsonschema`](https://github.com/AudunAutomat/linkml-datamodellering-no/blob/main/COMMANDS.md#gen-jsonschema) |
| XSD schema | `<skjema>-schema.xsd` | XML Schema for XML-based integration | — | `xsd` | [`gen-xsd`](https://github.com/AudunAutomat/linkml-datamodellering-no/blob/main/COMMANDS.md#gen-xsd) |
| Protobuf schema | `<skjema>-schema.proto` | gRPC and Protocol Buffers integration | — | `protobuf` | [`gen-proto`](https://github.com/AudunAutomat/linkml-datamodellering-no/blob/main/COMMANDS.md#gen-proto) |
| GraphQL schema | `<skjema>-schema.graphql` | Type definitions (SDL) for GraphQL APIs | — | `graphql` | [`gen-graphql`](https://github.com/AudunAutomat/linkml-datamodellering-no/blob/main/COMMANDS.md#gen-graphql) |
| Java classes | `java/<Klassenamn>.java` | Direct use in Java applications (Lombok `@Data`) | — | `java` | [`gen-java`](https://github.com/AudunAutomat/linkml-datamodellering-no/blob/main/COMMANDS.md#gen-java) |
| AsyncAPI spec | `<skjema>-asyncapi.yaml` | Asynchronous messaging (event-driven APIs) | — | `asyncapi` | [`gen-asyncapi`](https://github.com/AudunAutomat/linkml-datamodellering-no/blob/main/COMMANDS.md#gen-asyncapi) |
| OpenAPI spec | `<skjema>-openapi.yaml` | RESTful API documentation (OpenAPI 3.1) | — | `openapi` | [`gen-openapi`](https://github.com/AudunAutomat/linkml-datamodellering-no/blob/main/COMMANDS.md#gen-openapi) |
| ER diagram | `<skjema>-erdiagram.md` | Visual overview of classes and relationships (Mermaid) | — | `erdiagram` | [`gen-erdiagram-mermaid`](https://github.com/AudunAutomat/linkml-datamodellering-no/blob/main/COMMANDS.md#gen-erdiagram-mermaid) |
| Class diagram | `diagrams/<skjema>.puml` + `.svg` | Class diagram for presentation and documentation (PlantUML) | — | `plantuml` | [`gen-plantuml`](https://github.com/AudunAutomat/linkml-datamodellering-no/blob/main/COMMANDS.md#gen-plantuml) |
| HTML documentation | `docs/` | Human-readable reference documentation based on Markdown | — | `docs` | [`gen-schema-docs`](https://github.com/AudunAutomat/linkml-datamodellering-no/blob/main/COMMANDS.md#gen-schema-docs) |
| DQV measurements | `dqv-measurements.ttl` | Data quality measurements (data catalog models only) | ✓ | — | [`gen-dqv-measurements`](https://github.com/AudunAutomat/linkml-datamodellering-no/blob/main/COMMANDS.md#gen-dqv-measurements) |
| ModelDCAT elements | `modelldcat-elements.ttl` | Model catalog elements (model catalog models only) | ✓ | — | [`gen-modelldcat-elements`](https://github.com/AudunAutomat/linkml-datamodellering-no/blob/main/COMMANDS.md#gen-modelldcat-elements) |

**Publishing to external systems:** See [Publishing flow](https://audunautomat.github.io/linkml-datamodellering-no/en/publisering/publisering-oversikt/#kva-publiserast-til-eksterne-system) for an overview of GitHub Pages publishing and harvesting to Felles Begrepskatalog/Datakatalog.

---

## Generated concept catalogs

> Concept catalogs are automatically generated overviews of concepts per organization, based on the SKOS-AP-NO standard.

The concept catalogs are located under `src/linkml/begrepskatalog/`

<!-- BEGIN AUTO-GENERATED: src/assets/scripts/makefile/generate-readme-tables.sh generate_begrepskatalog_table -->
| Domain | Concept catalog | Organization | Description | Generator |
|---|---|---|---|---|
| [begrepskatalog](https://audunautomat.github.io/linkml-datamodellering-no/en/begrepskatalog/) | [brreg-begrepskatalog](https://audunautomat.github.io/linkml-datamodellering-no/en/begrepskatalog/brreg-begrepskatalog/) | Registerenheten i Brønnøysund | Concept catalog for the concepts of Registerenheten i Brønnøysund | [`gen-begrepskatalog-instance`](https://github.com/AudunAutomat/linkml-datamodellering-no/blob/main/COMMANDS.md#gen-begrepskatalog-instance) |
<!-- END AUTO-GENERATED: src/assets/scripts/makefile/generate-readme-tables.sh generate_begrepskatalog_table -->

---

## Generated model catalogs

> Model catalogs are automatically generated overviews of information models per organization, based on the ModelDCAT-AP-NO standard.

The model catalogs are located under `src/linkml/modellkatalog/`

<!-- BEGIN AUTO-GENERATED: src/assets/scripts/makefile/generate-readme-tables.sh generate_modellkatalog_table -->
| Domain | Model catalog | Organization | Description | Generator |
|---|---|---|---|---|
| [modellkatalog](https://audunautomat.github.io/linkml-datamodellering-no/en/modellkatalog/) | [brreg-modellkatalog](https://audunautomat.github.io/linkml-datamodellering-no/en/modellkatalog/brreg-modellkatalog/) | Brønnøysundregistra | Model catalog for the information models of Brønnøysundregistra | [`gen-modellkatalog-instance`](https://github.com/AudunAutomat/linkml-datamodellering-no/blob/main/COMMANDS.md#gen-modellkatalog-instance) |
| [modellkatalog](https://audunautomat.github.io/linkml-datamodellering-no/en/modellkatalog/) | [digdir-modellkatalog](https://audunautomat.github.io/linkml-datamodellering-no/en/modellkatalog/digdir-modellkatalog/) | Digitaliseringsdirektoratet | Model catalog for the information models of Digitaliseringsdirektoratet | [`gen-modellkatalog-instance`](https://github.com/AudunAutomat/linkml-datamodellering-no/blob/main/COMMANDS.md#gen-modellkatalog-instance) |
| [modellkatalog](https://audunautomat.github.io/linkml-datamodellering-no/en/modellkatalog/) | [kartverket-modellkatalog](https://audunautomat.github.io/linkml-datamodellering-no/en/modellkatalog/kartverket-modellkatalog/) | Kartverket | Model catalog for the information models of Kartverket | [`gen-modellkatalog-instance`](https://github.com/AudunAutomat/linkml-datamodellering-no/blob/main/COMMANDS.md#gen-modellkatalog-instance) |
| [modellkatalog](https://audunautomat.github.io/linkml-datamodellering-no/en/modellkatalog/) | [ksdigital-modellkatalog](https://audunautomat.github.io/linkml-datamodellering-no/en/modellkatalog/ksdigital-modellkatalog/) | KS Digital | Model catalog for the information models of KS Digital | [`gen-modellkatalog-instance`](https://github.com/AudunAutomat/linkml-datamodellering-no/blob/main/COMMANDS.md#gen-modellkatalog-instance) |
| [modellkatalog](https://audunautomat.github.io/linkml-datamodellering-no/en/modellkatalog/) | [novari-modellkatalog](https://audunautomat.github.io/linkml-datamodellering-no/en/modellkatalog/novari-modellkatalog/) | Novari IKS | Model catalog for the information models of Novari IKS | [`gen-modellkatalog-instance`](https://github.com/AudunAutomat/linkml-datamodellering-no/blob/main/COMMANDS.md#gen-modellkatalog-instance) |
| [modellkatalog](https://audunautomat.github.io/linkml-datamodellering-no/en/modellkatalog/) | [skatteetaten-modellkatalog](https://audunautomat.github.io/linkml-datamodellering-no/en/modellkatalog/skatteetaten-modellkatalog/) | Skatteetaten | Model catalog for the information models of Skatteetaten | [`gen-modellkatalog-instance`](https://github.com/AudunAutomat/linkml-datamodellering-no/blob/main/COMMANDS.md#gen-modellkatalog-instance) |
<!-- END AUTO-GENERATED: src/assets/scripts/makefile/generate-readme-tables.sh generate_modellkatalog_table -->

---

## Directory structure

> Here is an overview of the most central directories in the repository.

```
linkml-datamodellering-no/
├── src/
│   ├── assets/                                    # Containers, scripts and templates
│   ├── linkml/                                    # Source for LinkML models (and concept instances)
│   │   └── <domene>/
│   │       └── <modell>/
│   │           ├── <modell>-schema.yaml           # Data model
│   │           ├── build.yaml                     # Build configuration
│   │           ├── published-uris.lock            # Stable URIs for published catalogs
│   │           ├── examples/                      
│   │           │   └── <modell>-eksempel.yaml     # Example data file
│   │           └── data/                          # Source data for published catalogs
│   │               └── <datafil-katalog>/
│   │                   ├── <datafil-katalog>.yaml # Data file for the concept catalog
│   │                   └── build.yaml             # Data file build configuration
│   │
│   ├── mcp-linkml-validator/                      # MCP server: policy-based LinkML validation
│   ├── mcp-linkml-modell-utkast/                  # MCP server: generation of LinkML model drafts
│   ├── mcp-linkml-begrep-utkast/                  # MCP server: generation of LinkML concept drafts
│   └── tmp/                                       # Temporary files, e.g. JSON Schema files for mcp-linkml-modell-utkast
│
├── bootstrap.sh                                   # Bootstrap script for external repositories
├── bugs/                                          # Known bugs
├── tests/                                         # Tests and fixtures
├── generated/                                     # Generated artifacts (not checked into git)
├── make/                                          # GNU Make files for make commands. See COMMANDS.md for commands.
├── mkdocs/                                        # Documentation portal (MkDocs Material)
│   └── docs/                                      # Source for the documentation portal (Norwegian Nynorsk)
│       └── <domene>/
│          └── <modell>/
│               └── index.md                       # Main documentation for each data model (generated by publish.sh)
└── specs/
    ├── backlog/                                   # Plans for changes and new features
    ├── done/                                      # Completed plans
    └── bugs/                                      # Known bugs

```

---

## For contributors

> Here you will find the central documents for contributors.

If you want to contribute to the repository, read these documents:

- **[PRINCIPLES.md](https://github.com/AudunAutomat/linkml-datamodellering-no/blob/main/PRINCIPLES.md)** — design principles for modeling
- **[CONVENTIONS.md](https://github.com/AudunAutomat/linkml-datamodellering-no/blob/main/CONVENTIONS.md)** — naming conventions, manifest format and commit messages
- **[GOVERNANCE.md](https://github.com/AudunAutomat/linkml-datamodellering-no/blob/main/GOVERNANCE.md)** — roles, ownership and the RFC process
- **[CONTRIBUTING.md](https://github.com/AudunAutomat/linkml-datamodellering-no/blob/main/CONTRIBUTING.md)** — how to contribute (PR process, code review)
- **[README table generation](https://audunautomat.github.io/linkml-datamodellering-no/en/automasjon/readme-tabellgenerering/)** — how the README tables are generated
