---
name: jinja2-templates
description: Whitespace-kontroll for Jinja2-malar (docgen) — ingen indentasjon av Jinja-blokker, {%- -%}-mønster for tabellar/variablar/if-blokkar, feilsøkingsliste — og i18n-markørar, faste anker ({: #id }, aldri {#id}) og parsekontraktar mot seksjonsscripta. Lastast automatisk ved arbeid med filer under src/assets/templates/docgen/.
paths:
  - "src/assets/templates/docgen/**"
---

## Jinja2-template whitespace-kontroll

Når du redigerer Jinja2-templatear (t.d. `src/assets/templates/docgen/index.md.jinja2`), følg desse reglane for å unngå ekstra linjeskift og indenteringsproblem i generert output:

**HOVUDREGEL: Ingen indentasjon av Jinja-blokker**
- **ALDRI indenter Jinja-taggar (`{%`, `{{`, `{#`)** — all indentasjon vert inkludert i generert output
- `classes.sh` brukar `awk '/^## Subsets/,0'` som krev at overskrifter startar på kolonne 0
- Med indentasjon matchar ikkje `^##` (start-of-line), og seksjonen vert ikkje ekstrahert

**Hovudregel for whitespace-kontroll:** Bruk `-` i Jinja-taggar (`{%-` og `-%}`) for å strippe kvitteikn før/etter taggen:
- `{%-` strippar kvitteikn (mellomrom, tab, linjeskift) **før** taggen
- `-%}` strippar kvitteikn **etter** taggen

**Kritiske stader å unngå ekstra linjeskift:**

1. **Tabellar:** Ingen indentasjon på tabellrader, og korrekt `-`-plassering:
   ```jinja2
   | Enumeration | Description | Defined in |
   | --- | --- | --- |
   {% for enum_name in enums|sort -%}
   {%- set e = get_enum(enum_name) -%}
   {%- if e -%}
   {%- set origin = e.from_schema -%}
   | {{ e.name }} | {{ e.description }} | {{ origin }} |
   {% endif -%}
   {%- endfor -%}
   ```
   - `{% for ... -%}` (IKKJE `{%- for`) → beheld linjeskift etter header-linje
   - `{% endif -%}` (IKKJE `{%- endif`) → beheld linjeskift før endif (= linjeskift mellom tabellinjer)
   - `{%- endfor -%}` → strippar kvitteikn før og etter (hindrar ekstra linjeskift etter tabellen)
   - **Ingen indentasjon** på linjer inne i loopen — all indentasjon vert inkludert i output

2. **Variable assigningar:** Alltid bruk `{%- ... -%}` for å unngå kvitteikn:
   ```jinja2
   {%- set my_var = some_value -%}
   ```

3. **If-blokkar som IKKJE produserer synleg output:** Bruk `{%- ... -%}`:
   ```jinja2
   {%- if condition -%}
     {%- set variable = value -%}
   {%- endif -%}
   ```

4. **If-blokkar som produserer output:** Juster `-` basert på om du vil ha linjeskift:
   ```jinja2
   {%- if items %}
   ### Overskrift

   {{ items|join(', ') }}
   {% endif -%}
   ```

**Feilsøking:** Dersom generert Markdown har ekstra tomme linjer eller manglande linjeskift:
1. Sjekk om det er **indentasjon** (mellomrom/tab) på Jinja-blokker — **fjern all indentasjon**
2. Sjekk om `-` manglar på starten/slutten av taggar — legg til der kvitteikn skal strippast
3. Sjekk om `-` er **feil stad** (t.d. `{%- for` i staden for `{% for`) — juster basert på ønskt linjeskift

**Viktig:** Markdown-tabellar krev linjeskift mellom kvar rad, så **ALDRI** bruk `{%- endif -%}` direkte etter ei tabellinje — bruk `{% endif -%}` i staden.

**Verifiser alltid mot faktisk generert output** — same prinsipp som
heading-slug-fella i `.claude/rules/mkdocs-portal.md`:

```bash
make docs-build
```

## i18n-markørar og faste anker i docgen-malar

Portaltekst i malane er ikkje skriven direkte, men som markørar
`@@i18n:docgen.<nøkkel>@@` med tekst i `mkdocs/lib/i18n/strings.yaml` (nn + en).
`publish.sh` byter dei ut **til slutt** (`i18n_strings.py render-tree`). Sjå
steg 5 i `specs/backlog/lokalisering-dokumentasjonsportal.md`.

**Aldri skriv `{#anker}` i ein Jinja-mal.** `{#` opnar ein Jinja-kommentar, og
alt fram til neste `#}` forsvinn frå output. Det kan vere resten av malen.
Bruk attr_list-forma `{: #anker }`, t.d.
`## @@i18n:docgen.arv@@ {: #inheritance }`. I bash og Python (seksjonane på
skjemasida) er `{#anker}` trygt.

Ved ny eller endra overskrift/etikett i ein mal:

1. **Ny tekst skal ha markør og nøkkel i katalogen** med alle språk.
   LinkML-termar som svarar til nøklar i skjema-YAML-en (Slot, Enumeration,
   Mixin, range, Induced, eigenskapsetikettar som «Slot URI») står utan markør.
   `make i18n-check` feilar på markørar utan nøkkel.
2. **Omsett overskrift skal ha fast anker lik dagens slug** (`i18n_strings.slugify`
   av den opphavlege teksten, med teljing der overskrifta har teljing:
   `{: #classes-{{ n }} }`). Faste anker vert ikkje gjorde unike av mkdocs. Kan
   same overskrift kome to gonger på ei side, må det andre ankeret få `_1`
   (sjå «Døme» i `class.md.jinja2`).
3. **Overskrifter og radetikettar som seksjonsscripta parsar, er ein kontrakt.**
   `classes.sh` (`### @@i18n:docgen.klasser@@`, teljinga i importerte skjema),
   `metadata.sh` (`## @@i18n:docgen.modellmetadata@@`) og `badges.sh`
   (`| @@i18n:docgen.versjon@@ |`, lisens, endringsdato, utgiver) matchar
   markørane. Endrar du ein slik markør eller nøkkel, må parse-mønstra endrast
   i same endring.
4. **Verifiser anker, ikkje berre tekst.** Samanlikn `id`-attributta på h2-h6 per
   side før og etter i ein sandkasse-kopi (jf. `.claude/rules/mkdocs-portal.md`).
   Gen-doc må køyrast på nytt i begge kopiane (`make gen-schema-docs`).

Konkret tilfelle: under steg 5 vart anker først skrivne som `{#inheritance}` i
malane. Feilen vart fanga før køyring, og alle 53 vart gjorde om til `{: # }`.
