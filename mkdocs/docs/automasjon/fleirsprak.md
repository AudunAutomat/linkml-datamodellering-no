# Fleirspråkleg portal

!!! note "Beskrivelse"

    Dokumentasjonsportalen finst på nynorsk (standard) og engelsk. Denne sida
    forklarer kvar portalteksten kjem frå, korleis språkversjonane vert bygde og
    publiserte, og korleis omsetjingar vert haldne oppdaterte når den nynorske
    originalen endrar seg.

## Kva vert omsett?

| Innhald | Omsett? | Kjelde |
|---|---|---|
| Overskrifter, etikettar og forklaringar på skjemasidene | Ja | Strengkatalogen |
| Gen-doc-sider (klasser, slots, enums, typar) | Ja, utanom LinkML-termar | Strengkatalogen via markørar i gen-doc-malane |
| Nav-meny, tittel, copyright, 404-side | Ja | Strengkatalogen |
| Tema-tekst (søk, knappar) | Ja | Material, styrt av `theme.language` |
| Rettleiingssider, framside, valideringsreglar, domeneskildringar | Når det finst ei omsett side | `x.<lang>.md` ved sida av `x.md` |
| Modellanalyse-rapportar (skjemasider og tvers av domene) | Ja, utanom navn og skildringar frå skjemaa | Strengkatalogen, frå JSON-funna som analysescripta skriv ved sida av `.md`-rapportane |
| Modellinnhald (title/description frå skjemaa) | Nei | Vert vist på originalspråket |
| Versjonslog (`CHANGELOG.md`) og valideringsmeldingar | Nei | Generert av andre verktøy |

LinkML-termar som svarar til nøklar i skjema-YAML-en (Slot, Enumeration, Mixin,
range, domain, Induced, eigenskapsetikettar som «Slot URI») står urørte i alle
språk. Sider utan omsetjing vert viste på nynorsk med merknaden
«Not yet translated», og skjemasidene på engelsk har ein merknad om at
modellinnhaldet er på norsk.

## Adresser

| Adresse | Innhald |
|---|---|
| `/nn/…`, `/en/…` | Portalsidene per språk, med språkveljar øvst |
| `/<domene>/<modell>/<fil>` | Artefakter (`.ttl`, `.json`, `.yaml` …) på same sti som før, felles for alle språk |
| Gamle sideadresser utan språkprefiks | Vidaresending til `/nn/…` (med `#anker`) |

Artefaktadressene er uendra fordi dei vert brukte maskinelt: katalog-`.ttl` vert
hausta av Felles Begrepskatalog og Felles Datakatalog, og `heimeside` i
modellmanifesta er informasjonsmodellidentifikator. Språkveljaren held deg på
same side og same `#anker` når du byter språk. Faste overskriftsanker sikrar at
ankeret er likt i alle språk.

## Kjelder for tekst

### Strengkatalogen

`mkdocs/lib/i18n/strings.yaml` er éi kjelde for all generert portaltekst:

```yaml
languages: [nn, en]
default_language: nn
language_names: {nn: Nynorsk, en: English}
strings:
  seksjon.kom_i_gang.valider_skjema:
    nn: Valider skjemaet mot {policy}-policy
    en: Validate the schema against the {policy} policy
```

- Alle språk er påkravde for kvar nøkkel, og `{navn}`-plasshaldarar må vere like
  i alle språk.
- Bash (`mkdocs/lib/sections/*.sh`, `publish.sh`): `i18n_load <lang>` éin gong,
  deretter `$(t <nøkkel> navn=verdi)` (`mkdocs/lib/utils/i18n.sh`).
- Python (`mkdocs/lib/scripts/generate-*-md.py`): `load_catalog().t(nøkkel, lang, navn=verdi)`
  (`mkdocs/lib/scripts/i18n_strings.py`).
- Gen-doc-malar (`src/assets/templates/docgen/*.jinja2`): markørar
  `@@i18n:docgen.<nøkkel>@@`, som `publish.sh` byter ut til slutt. Omsette
  overskrifter har faste anker `{: #slug }` lik den opphavlege sluggen.

`make i18n-check` validerer katalogen og kontrollerer at alle nøklar som vert
brukte, finst.

### Omsette sider

Ei omsett side ligg ved sida av originalen med språkkode i filnavnet:
`mkdocs/docs/om.en.md`, `README.en.md`, `src/mcp-linkml-validator/policies/README.en.md`
og `src/linkml/<domene>/description.en.md`. Portal-lenkjer i omsette sider peikar
på `/<lang>/`-adressene.

`README.md` og `README.en.md` har tabellar mellom
`<!-- BEGIN/END AUTO-GENERATED -->`-markørar. `generate-readme-tables.sh`
fyller dei på språket til fila, med tabelltekst frå `readme_tabell.*`-nøklane i
strengkatalogen og portal-lenkjer til `/<lang>/` for andre språk enn
standardspråket. Skildringa av skjemaa er modellinnhald og står på
originalspråket. Blokkene er ikkje med i `source_hash`, så nye tabellrader gjer
ikkje omsetjinga utdatert.

## Bygging

| Kommando | Kva skjer |
|---|---|
| `make docs-publish` | Genererer innhald for standardspråket i `mkdocs/docs/`, for kvart anna språk i `mkdocs/build/src-<lang>/`, byggjetre `mkdocs/build/<lang>/` + `mkdocs/build/rot/` (artefakter og vidaresendingar) og `mkdocs/build/mkdocs.<lang>.yml` |
| `make docs-build` | Byggjer alle språk parallelt til `mkdocs/site/<lang>/` og legg `rot/` og 404-sida på rota. Dette er det som vert publisert til GitHub Pages |
| `make docs-serve [DOCS_LANG=en]` | Live-førehandsvising av eitt språk. Artefaktlenkjer og språkveljar fungerer ikkje her |
| `make docs-serve-site` | Viser den ferdig bygde portalen under same base-sti som GitHub Pages, med alle språk, artefakter og vidaresendingar |

## Omsetjing og endringsdeteksjon

Kvar omsetjing hugsar ein hash (sha256) av den nynorske originalen ho vart laga
frå:

- **Sider** har front-matter som `publish.sh` fjernar før innhaldet vert brukt:

    ```yaml
    ---
    i18n:
      source: om.md
      source_hash: sha256:…
    ---
    ```

- **Katalognøklar** har hashen sin i `mkdocs/lib/i18n/strings.lock.yaml`. Fila
  vert generert, så ikkje rediger ho for hand.

| Kommando | Kva skjer |
|---|---|
| `make i18n-status [STRICT=1]` | Listar sider og nøklar som manglar omsetjing, er ustempla eller er utdaterte fordi originalen er endra. Gjev åtvaringar; `STRICT=1` feilar ved utdaterte/ustempla |
| `make i18n-stamp FILE=<x.en.md>` | Stemplar ei omsett side etter omsetjing |
| `make i18n-stamp KEYS="k1 k2"` | Stemplar katalognøklar etter at den engelske verdien er oppdatert |
| `make i18n-stamp` | Stemplar berre nøklar som manglar hash, t.d. nye nøklar |

Stemplar du ei side under `mkdocs/docs/`, får kvar overskrift i omsetjinga eit
fast anker (`{#slug}`) lik sluggen av den tilsvarande nynorske overskrifta.
Stemplinga feilar dersom overskriftene ikkje har same tal og nivå som i
originalen. Sider som òg vert viste på GitHub (`README.en.md`,
`policies/README.en.md`, `description.en.md`), får ikkje faste anker.

Arbeidsflyt når den nynorske teksten er endra:

1. `make i18n-status` — sjå kva omsetjingar som er utdaterte.
2. Oppdater `x.en.md` eller den engelske verdien i `strings.yaml`.
3. `make i18n-stamp FILE=…` eller `make i18n-stamp KEYS="…"`.
4. `make i18n-check`.

Omsetjinga vert gjord av ein LLM. Framgangsmåten ligg i
[`.claude/rules/i18n-omsetjing.md`](https://github.com/AudunAutomat/linkml-datamodellering-no/blob/main/.claude/rules/i18n-omsetjing.md).

## Nytt språk

1. Legg språkkoden til i `languages` og eit navn i `language_names` i
   `strings.yaml`, og legg inn verdi for språket på alle nøklar
   (`make i18n-check` feilar til alle er på plass).
2. `make i18n-stamp DOCS_LANG=<lang>` for å stemple nøklane.
3. `make docs-publish && make docs-build` — språket får eige tre, eigen
   konfig, eigen søkjeindeks og plass i språkveljaren automatisk.

Material må støtte språkkoden i `theme.language`.

## Kjende avgrensingar

- Portalen byggjer på Material for MkDocs, som får kritisk vedlikehald fram til
  mai 2027. Løysinga brukar ingen plugin, berre `theme.language` og
  `extra.alternate`, som òg er støtta i etterfølgjaren Zensical.

Bakgrunn, alternativ og alle avgjerder:
[`specs/done/lokalisering-dokumentasjonsportal.md`](https://github.com/AudunAutomat/linkml-datamodellering-no/blob/main/specs/done/lokalisering-dokumentasjonsportal.md).
