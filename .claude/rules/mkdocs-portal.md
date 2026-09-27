---
name: mkdocs-portal
description: Korleis mkdocs/publish.sh byggjer dokumentasjonsportalen, heading-slug-fella for æ/ø/å, relative/absolutte lenkjereglar, docs-publish som verifisering, og portal-adresser som identifikatorar/haustingsadresser. Lastast automatisk ved arbeid med mkdocs/publish.sh eller sider under mkdocs/docs/. Jinja2-malkonvensjonar ligg i eiga rule, sjå .claude/rules/jinja2-templates.md.
paths:
  - "mkdocs/**"
---

## Dokumentasjonsportal (mkdocs)

`mkdocs/mkdocs.yml` vert **automatisk regenerert** av `mkdocs/publish.sh` (Steg 4)
kvar gong `make docs-publish` køyrer. Endringar gjort direkte i `mkdocs.yml` vert
overskrivne ved neste publisering.

**Sannkjelda for nav-menyen er `mkdocs/publish.sh`**, ikkje `mkdocs.yml`.

- Nye rettleiingssider (`mkdocs/docs/*.md`) må leggast til i heredoc-blokka i
  `publish.sh` (leit etter `nav:` → `- Rettleiingar:`)
- Domene og skjema vert lagt til automatisk frå `generated/`-strukturen — ikkje
  rediger desse manuelt
- Statisk innhald (`mkdocs/docs/` utanom genererte domene-katalogar) vert aldri
  sletta av `publish.sh`

`mkdocs/docs/` er brukarvendt dokumentasjon og normativ kjelde for steg-for-steg-rettleiingar (t.d. `ny-domenemodell.md`). CLAUDE.md er normativ kjelde for modelleringsprinsipp og AI-instruksjonar — desse to skal ikkje duplisere kvarandre.

### Korleis `publish.sh` fungerer

`mkdocs/publish.sh` transformerer LinkML-genererte artefakter frå `generated/` til ein
publiserbar MkDocs-portal i `mkdocs/docs/`. Scriptet køyrer i fire hovudsteg:

**Steg 1: Rens tidlegare genererte domene-katalogar**
- Slettar `mkdocs/docs/<domain>/` for kvar `generated/<domain>/` som finst
- Fjernar `mkdocs/docs/<domain>/` for domene som ikkje lenger finst i `generated/`
- Beheld statisk innhald (`mkdocs/docs/*.md`, `stylesheets/`, `javascripts/`)

**Steg 2: Generer innhald per domene og skjema (parallelt)**

For kvart skjema i `generated/<domain>/<schema>/`:

1. Kopier artefaktfiler (`*.ttl`, `*.json`, `*.yaml` osv.) frå `generated/<domain>/<schema>/` til `mkdocs/docs/<domain>/<schema>/`
2. Kopier `CHANGELOG.md` frå `src/linkml/<domain>/<schema>/` dersom den finst
3. Kopier PlantUML-diagram frå `generated/<domain>/<schema>/diagrams/` til `mkdocs/docs/<domain>/<schema>/diagrams/`
4. Kopier gen-doc Markdown-filer frå `generated/<domain>/<schema>/docs/` til `mkdocs/docs/<domain>/<schema>/klasser/`
5. Generer `mkdocs/docs/<domain>/<schema>/index.md` med følgjande seksjons-rekkjefølgje:
   - Hovudoverskrift (`# <schema>`)
   - **Metadata-tabell** (`## Metadata` frå gen-doc — name, title, description, versjon, lisens, utgiver, status osv.)
   - Publiseringsinfo (boks dersom `published-uris.lock` finst)
   - **ER-diagram** (`## ER-diagram` med PlantUML SVG — zoombart, lenke til full versjon)
   - Klasseliste (`## Classes`, `## Slots`, `## Enumerations`, `## Types` frå gen-doc)
   - Artefaktabell (`## Generated artifacts` med lenkjer til `.ttl`, `.json`, `.puml` osv.)
   - **Valideringsresultat** (`## Valideringsresultat` frå `validation/<versjon>/<policy>.json`)
   - **Versjonslog** (`## Versjonslog` frå `CHANGELOG.md`)

Alle skjema-jobbar køyrer parallelt for å redusere byggtid.

**Steg 3: Generer `valideringsregler.md` og hovud-`index.md`**
- `valideringsregler.md` genereres frå `src/mcp-linkml-validator/policies/README.md` med GitHub-lenkjer
- Hovud-`index.md` genereres frå `README.md` (med filtrering av intern-referansar)

**Steg 4: Generer `mkdocs.yml`**
- Statisk konfigurasjon (theme, plugins, markdown_extensions) frå heredoc-blokk
- Dynamisk nav-meny: `- Rettleiingar:` (statisk) + domene-seksjonar (generert frå `generated/`-struktur)

**Viktige detaljar:**

- **Metadata-tabell** vert generert av Jinja-templaten `src/assets/templates/docgen/index.md.jinja2` og inneheld name, title, description, versjon, lisens, utgiver, status m.m.
- **ER-diagram** brukar PlantUML SVG (ikkje Mermaid) — zoombart i nettleser, med lenke til full versjon som viser importerte klasser
- **Types-lista** viser alle typar som faktisk vert brukt i modellen (frå `slots[*].range`), inkludert importerte typar frå `linkml:types` m.fl., med "Defined in"-kolonne som viser "Local" eller "Imported"
- **Enumerations-lista** viser alle enums som faktisk vert brukt i modellen (frå `slots[*].range`), inkludert importerte enums, med "Defined in"-kolonne
- **Valideringsresultat** vert generert av `mkdocs/lib/scripts/generate-validation-md.py` frå `validation/<versjon>/<policy>.json` med rein Markdown (nummererte lister, ikkje `<details>`-blokkar)
- **Versjonslog** vert kopiert direkte frå `CHANGELOG.md` som rein Markdown (ikkje kollapsa)
- **Lowercase-transformasjon** av klassefiler skjer for å unngå konflikt på case-insensitive filsystem (Windows/macOS)
- **Filtrert PlantUML-diagram** vert prioritert over full versjon i ER-diagram-seksjonen

### `make docs-publish` er ikkje ein trygg verifiseringssteg

`publish.sh` (Steg 1) **slettar og regenererer** `mkdocs/docs/<domain>/` for
kvart domene i `generated/`. Resultatet er aldri betre enn innhaldet i
`generated/`. Manglar `.ttl`-filer, PlantUML-diagram eller
valideringsresultat der, forsvinn dei òg frå portalsidene. Det skjer utan feil,
og bygget går gjennom. Genererte domenekatalogar skal stå i `.gitignore`. Er
ein katalog likevel versjonskontrollert (som `felles/` var fram til
`.gitignore` vart retta), vert slettingane synlege som endringar i `git status`.
Ligg katalogen i `.gitignore`, er dei usynlege, men portalen blir like ufullstendig.

**Aldri** køyr `make docs-publish` berre for å stadfeste ei endring i
`publish.sh`, `sections/*.sh` eller malar, med mindre du veit at `generated/`
er fullstendig generert for alle domene som vert publiserte.

Gjer i staden slik:

1. **Verifiser så smalt som mogleg.** Ei endring i heredoc-blokka for
   `mkdocs.yml` kan stadfestast ved å lese blokka eller køyre berre den delen
   av scriptet. Ei endring i ein seksjon kan stadfestast ved å køyre
   seksjonsfunksjonen mot eitt skjema.
2. **Treng du eit fullt bygg,** så sjekk først `git ls-files mkdocs/docs` for å
   sjå kva som er versjonskontrollert. Sjekk deretter at dei tilsvarande
   `generated/<domain>/<schema>/` inneheld alle artefakter som `build.yaml`
   ber om (`*.ttl`, `diagrams/`, `validation/`).

   **Treng du å vise at portalen er uendra (regresjon), men `generated/` er
   ufullstendig,** så køyr bygget i ein sandkasse-kopi i scratchpad og ikkje i
   repoet:
   1. Kopier `Makefile`, `make/`, `mkdocs/` (utan `site/`, `node_modules/` og
      `.cache/`), `src/`, `generated/`, `README.md` og `CODEOWNERS.md` til
      `<scratchpad>/box-before` **før** du endrar noko. Ein `tar`-straum frå
      `/mnt/c` tek fleire minutt, så vent til kopien er ferdig før første
      redigering. Køyr `make -C <box> docs-publish` og ta vare på `mkdocs/docs`.
   2. Gjer endringane i repoet. Kopier på same måte til `box-after` og køyr på nytt.
   3. `diff -r -I '^_Portalen vart sist bygd: '` på dei to `mkdocs/docs`-trea, og
      `diff` på `mkdocs.yml`. Byggetidspunktet er einaste venta skilnad.
   4. **Mål dekninga.** Byte-likskap seier berre noko om kodevegar som
      referansedataa faktisk køyrer. Sjekk kva endra tekst/logikk som finst i
      utdataa. Legg **identiske fiksturar** inn i begge boksane for kodevegar som
      manglar (t.d. valideringsfil med feil, modellanalyse-rapportar,
      `submodels` i `build.yaml`), og køyr begge på nytt før du samanliknar.

   Heile køyringa tek under eitt minutt i `/tmp`, mot fleire minutt på `/mnt/c`.
   Repoet vert ikkje rørt.
3. **Etter køyring:** køyr `git status --short mkdocs/docs` og rapporter til
   brukaren alle endringar du ikkje var ute etter, før du melder arbeidet som
   ferdig. Rull dei tilbake med `git restore <sti>` innanfor unntaket i
   CLAUDE.md («Aldri commit eller push»), og rapporter kva som vart rulla tilbake.

Konkret tilfelle: under steg 1 i
`specs/backlog/lokalisering-dokumentasjonsportal.md` (`theme.language: nn`)
sletta ein `make docs-publish` mot ufullstendig `generated/` 48
versjonskontrollerte filer under `mkdocs/docs/felles/` og fjerna
ER-diagram-seksjonen frå fem skjemasider. Sjå
`specs/done/rule-docs-publish-ufullstendig-generated.md`. Sandkasse-metoden i
steg 2 vart brukt i steg 4 i same spec: 8555/8555 filer identiske, men
referansedataa køyrde berre 112 av 152 katalognøklar, så fiksturar var
naudsynte for å dekkje resten.

### PlantUML-diagram

`make gen-plantuml` genererer **to versjonar** av PlantUML-diagramma:

- **`<modell>.puml/.svg`** — full versjon med alle klasser (inkl. importerte frå dcat-ap-no, dqv-ap-no osv.)
- **`<modell>-filtered.puml/.svg`** — filtrert versjon med **kun lokale klasser** frå skjemaet

Filtrering:
- Beheld alle klasser definerte i det lokale skjemaet sitt `classes:`-blokk (inkl. abstrakte klasser)
- Filtrer vekk `tree_root`-klassen (containerklassen)
- Filtrer vekk importerte klasser (frå dcat-ap-no, dqv-ap-no osv.)
- Behald relasjonar og arvestruktur mellom dei filtrerte klassane

Dokumentasjonsportalen (`mkdocs/docs/`) viser den **filtrerte versjonen** som standard, med lenke til full versjon merka "(full)".

### Ankerlenkjer til overskrifter (heading-slugs)

`mkdocs.yml` (heredoc-blokka i `publish.sh`) konfigurerer **ikkje** `toc`-utvidinga eksplisitt, så MkDocs/Python-Markdown brukar sin **default** slugify-funksjon (`markdown.extensions.toc.slugify`, `unicode=False`) til å generere `id`-attributtet ei overskrift får — og dermed kva `#anker` ei intern lenkje til overskrifta må bruke. Denne funksjonen er **ikkje** ei transkriberings-funksjon (ø → o, æ → ae) — han er reint ASCII-filtrerande:

1. `unicodedata.normalize('NFKD', tekst)` — dekomponerer teikn som HAR ein eiga diakritisk NFKD-form
2. `.encode('ascii', 'ignore').decode('ascii')` — **fjernar** alle attverande ikkje-ASCII-teikn (inkludert dei diakritiske merka NFKD nett skilde ut)
3. `re.sub(r'[^\w\s-]', '', ...)` — fjernar attverande teiknsetjing (parentes, spørjeteikn, skråstrek, hermeteikn)
4. Mellomrom → bindestrek, alt til små bokstavar

**Konsekvens — to heilt ulike utfall for norske bokstavar:**

| Bokstav | NFKD-dekomponerbar? | Utfall i slug | Eksempel |
|---|---|---|---|
| å, é, ö, ü m.fl. | Ja (bokstav + kombinerande merke) | Merket fjernast, **basisbokstaven står att** | `Skriftspråk` → `skriftsprak`, `éin` → `ein` |
| æ, ø, ß | **Nei** (eiga, ikkje-samansett teikn) | **Heile bokstaven forsvinn** — ingen erstatning | `høstingsendepunkt` → `hstingsendepunkt`, `Æ Ø Å` → `a` (berre Å-en si `a` står att) |

Dette er lett å gå i fella på nettopp fordi å oppfører seg annleis enn æ/ø — ei intuitiv, hand-skriven slug som transkriberer alle tre likt (t.d. `hoysting`/`hosting`) vert **feil**, og MkDocs sin lenkje-validator (`validation.links` i `mkdocs.yml`) fangar det først ved bygg, ikkje ved skriving.

**Regel:** Skriv **aldri** ein `#anker`-verdi for ei overskrift med æ/ø/å/andre diakritiske teikn frå augemål åleine. Verifiser alltid mot faktisk generert `id`:

```bash
make docs-build
grep -o 'id="[^"]*"' mkdocs/site/<sti-til-sida>/index.html
```

Gjeld berre interne lenkjer til overskrifter i **statisk** innhald i `mkdocs/docs/` (rettleiingssider) — genererte skjema-sider sine interne lenkjer (klasser, slots osv.) vert alt bygde frå faktiske `id`-ar av gen-doc-malen, ikkje handskrivne.

### Relative vs. absolutte lenkjer i portalinnhald

Lenkjer i `.md`-filer skal følgje kor målet faktisk bur:

- **Mål som er bygd inn i mkdocs-portalen** (finst under `mkdocs/docs/` etter `publish.sh` — anten statisk rettleiingsinnhald eller generert domene-/skjemainnhald) → bruk **relative lenkjer** (t.d. `../publisering/publisering-modell.md` eller `klasser/status.md`), aldri absolutte URL-ar til `audunautomat.github.io` eller GitHub. Relative lenkjer vert validerte av mkdocs sin eigen `validation.links` ved bygg (fangar broten interne referansar før publisering, jf. § Ankerlenkjer over) og fungerer korrekt både i lokal `mkdocs serve`-førehandsvising og på den publiserte portalen.
- **Mål som ikkje er bygd for portalen** (t.d. `BUGS.md`, `specs/`, kjeldeskjema under `src/linkml/`, andre repo-filer utanfor `mkdocs/docs/`) → bruk **absolutt lenkje** til fila i GitHub-repoet (`https://github.com/AudunAutomat/linkml-datamodellering-no/blob/main/<sti>`). Desse måla har ingen portal-relativ sti i det heile, sidan dei aldri vert kopierte inn i `mkdocs/docs/`.

Sjå `specs/done/lenkjesjekk-3817-feil-evaluering.md` for eit konkret eksempel på brotet denne regelen skal hindre: fleire rettleiingssider i `mkdocs/docs/` lenka til `specs/bugs/README.md` (ein sti som ikkje finst, og som uansett aldri ville vore ei gyldig relativ portallenkje sidan `specs/` ikkje er portalinnhald) i staden for korrekt absolutt lenkje til `BUGS.md`.

### Portal-adresser er identifikatorar og haustingsadresser

Adressene på GitHub Pages-portalen er ikkje berre lenkjer for menneske. Dei vert
brukte maskinelt utanfor repoet:

- **Identifikator:** `generate_mkdocs_url()` i
  `src/assets/scripts/makefile/generate-informasjonsmodell.py` set `heimeside`
  i kvar `src/linkml/<domain>/<modell>/metadata/<modell>-manifest.yaml` til
  `https://audunautomat.github.io/linkml-datamodellering-no/<domain>/<modell>/`.
  `generate-modellkatalog.py` brukar same verdi som
  `informasjonsmodellidentifikator` i modellkatalogen som Felles datakatalog haustar.
- **Haustingsadresse:** Felles datakatalog og Felles begrepskatalog haustar
  katalog-`.ttl`-filer direkte frå portal-stiar (sjå
  `mkdocs/docs/publisering/publisering-begrep.md`, `publisering-modell.md` og
  `publisering-oversikt.md`).

GitHub Pages har ikkje HTTP-vidaresending (301/302), og haustarar følgjer ikkje
vidaresending i HTML eller JavaScript. Ein flytta sti er difor ein broten
identifikator eller ei broten hausting, sjølv om portalen ser rett ut i nettlesaren.

**Aldri** endre stien til ein publisert artefakt, eller stistrukturen
`<domain>/<modell>/` for portalsider (i `publish.sh`, `site_dir`/`docs_dir`,
`generate_mkdocs_url()` eller liknande), utan å gjere dette først:

1. **Kartlegg maskinelle konsumentar:** grep etter
   `audunautomat.github.io/linkml-datamodellering-no` i
   `src/linkml/*/*/metadata/`, `src/assets/scripts/` og
   `mkdocs/docs/publisering/`.
2. **La artefakter (`*.ttl`, `*.json`, `*.yaml` ...) bli liggjande på dagens sti.**
   Dei er språk- og layoutuavhengige. Lenk til dei frå den nye strukturen.
3. **Gje flytta HTML-sider ei vidaresendingsside på den gamle adressa**, med
   `<link rel="canonical">`, `<meta http-equiv="refresh">` og
   `location.replace(... + location.hash)`. Ein identifikator-URI skal svare
   med 200, så ein felles `404.html` med JS-vidaresending er ikkje nok.
4. **Ikkje endre `heimeside`/identifikatorverdiar.** Den gamle adressa held fram
   med å svare via vidaresendingssida.
5. **Legg fram konsekvensane for brukaren** før arbeidet held fram. Endringar i
   eksterne katalogregistreringar ligg utanfor repoet (jf. «Pull, ikkje push» i
   CLAUDE.md).

Konkret tilfelle: ved valet av `/nn/` og `/en/` for fleirspråkleg portal (O6 i
`specs/backlog/lokalisering-dokumentasjonsportal.md`) ville ei naiv flytting av
heile portalen ha broten alle `heimeside`-identifikatorar og haustingsadressene
for katalog-`.ttl`. Sjå `specs/done/rule-portal-adresser-maskinelle-konsumentar.md`.
