---
name: i18n-omsetjing
description: Framgangsmåte for LLM-omsetjing av portaltekst — omsette sider (x.en.md) og engelske verdiar i strengkatalogen, terminologi, lenkjer/anker, stempling med source_hash. Lastast automatisk ved arbeid med *.en.md eller mkdocs/lib/i18n/.
paths:
  - "**/*.en.md"
  - "mkdocs/lib/i18n/**"
---

## Omsetjing av portaltekst

Mekanismen (strengkatalog, omsette sider, adresser, `source_hash`) er skildra i
`mkdocs/docs/automasjon/fleirsprak.md`. Denne rula gjeld **korleis** ein LLM
omset.

**Aldri** stempla (`make i18n-stamp`) ei side eller ein nøkkel utan at
omsetjinga faktisk er oppdatert mot den gjeldande nynorske originalen.
Stemplinga markerer omsetjinga som oppdatert, og `make i18n-status` vil då ikkje
lenger åtvare.

### Framgangsmåte

1. `make i18n-status` — finn manglande, ustempla og utdaterte omsetjingar.
2. **Side** (`x.en.md` ved sida av `x.md`):
   - Omset prosa, overskrifter, tabelltekst og kommentarar i kodeblokker.
   - Behald kommandoar, filstiar, make-variablar og norske identifikatorar
     (`domene`, `modell`, `begrepssamling`, skjemanavn) urørte.
   - Portal-lenkjer: `https://audunautomat.github.io/linkml-datamodellering-no/<sti>`
     vert `…/en/<sti>`. Artefaktlenkjer (`.ttl`, `.json` …) står utan språkprefiks.
   - **Anker på portalsider (`mkdocs/docs/**`):** behald overskriftsstrukturen
     (same tal og nivå som originalen). `make i18n-stamp` set då fast anker
     (`{#slug}`) lik den nynorske sluggen på kvar overskrift, og feilar om
     strukturen avvik. Interne `#…`-lenkjer til slike sider står difor
     **uendra** frå originalen. Skriv ikkje `{#…}` for hand.
   - **Sider som òg vert viste på GitHub** (`README.en.md`,
     `policies/README.en.md`, `description.en.md`) får ikkje faste anker. Lenkjer
     til overskrifter der må peike på slug-en av den **engelske** overskrifta
     (t.d. `../index.md#getting-started`). Policy-overskriftene i
     `policies/README.en.md` (`bronze`, `basis-no` …) skal vere identiske med
     originalen.
   - Innhaldet mellom `<!-- BEGIN/END AUTO-GENERATED -->`-markørane skal
     **ikkje** omsetjast for hand. `generate-readme-tables.sh` fyller blokkene
     på språket til fila (`make docs-publish`). Tabelltekst vert omsett i
     `readme_tabell.*`-nøklane i strengkatalogen.
   - Ikkje skriv front-matter for hand: `make i18n-stamp FILE=<x.en.md>`.
   - **Ny side utanfor `src/` og `mkdocs/`** (t.d. ein språkvariant på
     rotnivå): fila må inn i CI-fillistene, elles viser portalen stille
     originalen. Sjå `.claude/rules/mkdocs-portal.md` § «Nye inndatafiler til
     `publish.sh` må inn i CI-fillistene».
3. **Katalognøkkel** (`mkdocs/lib/i18n/strings.yaml`): oppdater `en`-verdien,
   behald dei same `{plasshaldarane}`, og køyr deretter `make i18n-stamp KEYS="…"`.
   Rediger aldri `strings.lock.yaml` for hand.
4. `make i18n-check` (og `make i18n-status` på nytt).

### Terminologi

- **Amerikansk engelsk:** *catalog*, *organization*, *modeling*, *license*.
- **LinkML-termar** som svarar til nøklar i skjema-YAML-en (Slot, Enumeration,
  Mixin, range, domain, Induced, Tree Root, eigenskapsetikettar som «Slot URI»)
  vert ikkje omsette, verken i nynorsk eller engelsk.
- **Norske eigennavn** vert ståande, eventuelt med engelsk forklaring første
  gong: Felles Begrepskatalog / Felles Datakatalog («national concept catalog /
  data catalog»), Rammeverk for informasjonsforvaltning («Framework for
  Information Management»), Nasjonale grunndata («National master data»),
  Brønnøysundregistrene («Brønnøysund Register Centre»).
- **Domeneprefiksa** i domeneetikettane (FELLES, AP-NO, Begrepskatalog …) er
  navn og vert ikkje omsette.

Konkret tilfelle: under steg 10 i
`specs/done/lokalisering-dokumentasjonsportal.md` hadde dei engelske
katalogutkasta blanda britisk og amerikansk skrivemåte (*catalogue*/*license*,
*organisation*, *modelling*). Gjennomgangen avdekte òg to feil i den nynorske
originalen. Endringane i originalen vart fanga av `make i18n-status` som
utdaterte nøklar.
