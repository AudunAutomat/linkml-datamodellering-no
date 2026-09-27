# Modellanalyse-rapportar på språket til portalen

## Bakgrunn

Dei tre sidene under «Modellanalyse» i den engelske portalen (Liknande
klassenavn/slotnavn/typenavn, alle domene) har nynorske overskrifter og
nynorsk tekst. `publish.sh` kopierer rapportane frå `find-similar-names.py`
ordrett (`generate_cross_domain_modellanalyse_docs`). Same rapporttekst
(tabellhovud, «Totalt: …», «Ingen … funne») vert òg lagd ordrett inn i
`## Modellanalyse`-seksjonen på kvar skjemaside (`generate-modellanalyse-md.py`),
både frå `find-similar-names.py` og `find-unused-local-definitions.py`.

Avklart med brukaren:

- **Omfang:** all rapporttekst, både på dei tre tvers-av-domene-sidene og i
  Modellanalyse-seksjonane på skjemasidene, for begge analysescripta.
- **Løysing:** analysescripta skriv òg funna som JSON ved sida av
  `.md`-rapporten. Portalen byggjer teksten per språk frå JSON og
  strengkatalogen. `.md`-rapportane (CI-logg, terminal,
  `summarise-modell-analyse.py`) er uendra.

Skildringar av klasser/slots i rapportane er modellinnhald og vert ikkje
omsette.

## Steg

1. `find-similar-names.py`: batch-modus skriv `<rapport>.json` ved sida av
   kvar `<rapport>.md`, med dei same funna (kind, scope, terskel, mål/domene,
   tal sjekka, par med likskap og namn/range/slots/skjema).
2. `find-unused-local-definitions.py`: same for dei seks lokale analysane
   (kind, skjemasti, total, element med namn/skildring/grunnkode).
3. Katalognøklar (`modellanalyse.rapport.*`) for all fast rapporttekst.
   Dei nynorske verdiane skal gje same tekst som `.md`-rapportane i dag.
4. Ny modul `mkdocs/lib/scripts/modellanalyse_render.py` som lagar overskrift,
   brødtekst og funntal frå JSON for eit gitt språk.
5. `generate-modellanalyse-md.py`: bruk JSON når fila finst, elles `.md` med
   åtvaring på stderr.
6. `publish.sh`: lag dei tre tvers-av-domene-sidene frå JSON per språk, med
   same fallback.
7. Testar: nynorsk rendering frå JSON er byte-lik med `.md`-rapporten for
   alle rapporttypar, og engelsk rendering har ingen nynorske fasttekstar.
8. Dokumentasjon: `fleirsprak.md` (+ `.en.md`), eventuelle andre sider som
   skildrar rapportformatet.
9. Verifiser i sandkasse: generer rapportane med make-targeta, køyr
   `docs-publish` og bygg `en`.

## Handlingsliste

- [x] 1. JSON frå `find-similar-names.py`
- [x] 2. JSON frå `find-unused-local-definitions.py`
- [x] 3. Katalognøklar
- [x] 4. `modellanalyse_render.py`
- [x] 5. `generate-modellanalyse-md.py`
- [x] 6. `publish.sh`
- [x] 7. Testar
- [x] 8. Dokumentasjon
- [x] 9. Sandkasseverifisering

## Avgjerder

- **`.md`-rapportane er uendra:** scripta byggjer framleis teksten sjølve, og
  JSON vert skrive i tillegg (berre i batch-modus, som CI brukar). Dermed er
  CI-logg, terminal og `summarise-modell-analyse.py` urørte. Testane sikrar at
  nynorsk rendering frå JSON er byte-lik med `.md`, så dei to ikkje kan gli frå
  kvarandre utan at testen feilar.
- **Fallback utan JSON:** rapportar frå før denne endringa (t.d. lokal
  `generated/` eller CI-cache) har ingen JSON. Då vert `.md` brukt som før,
  med åtvaring på stderr, i staden for at bygget feilar.
- **LinkML-termar står urørte:** kolonnenavna Slot, Type, Enum, Subset, Slots
  og `(default)` vert ikkje omsette (jf. terminologien i
  `.claude/rules/i18n-omsetjing.md`). Klasse, Skjema, Grunntype, Likskap, Grunn
  og Skildring vert omsette.
- **Grunnkodar i JSON:** `isolated`/`container_only` i staden for dei nynorske
  grunntekstane, slik at teksten kjem frå katalogen.
- **Indre oppslagsfunksjon heiter `tr`:** nøkkelskanninga i `i18n_strings.py`
  les `t("…")` i `.py`-filer som fullstendige nøklar. Relative nøklar
  (`liknande.tittel`) ville då vorte rapporterte som manglande.
- **Test utan linkml:** `find-unused-local-definitions.py` patchar linkml ved
  import. Testen erstattar patchen med ein tom stubb, sidan
  rapportformateringa ikkje treng linkml, og køyrer i python-pytest-imaget
  saman med dei andre i18n-testane (`make i18n-check`).
- **Stavemåtar frå scripta er behaldne i nynorsk:** «typer» i
  likskapsrapportane og «typar» i dei lokale rapportane, slik at `.md` og
  rendering er byte-like.

## Utført

- `find-similar-names.py`: `build_report_data()` og `write_report_files()`;
  batch-modus skriv `<rapport>.json` ved sida av `.md`.
- `find-unused-local-definitions.py`: `report_data()` med grunnkodar; batch-
  modus skriv `<rapport>.json`.
- `mkdocs/lib/i18n/strings.yaml`: 37 nye `modellanalyse.rapport.*`-nøklar
  (nn + en), stempla.
- `mkdocs/lib/scripts/modellanalyse_render.py`: ny modul og CLI (`page`).
- `generate-modellanalyse-md.py`: brødtekst og funntal frå JSON, fallback til
  `.md` med åtvaring.
- `publish.sh`: dei tre tvers-av-domene-sidene frå JSON per språk, fallback til
  `.md` med åtvaring, feil ved rendering stoppar steget.
- `tests/test_modellanalyse_render.py`: 4 testar (alle kind/scope, tomme
  rapportar, ukjent format), lagde til i `make i18n-check` (26 testar OK).
- Dokumentasjon: `COMMANDS.md`, `fleirsprak.md` (+ `.en.md`, restempla).
- Sandkasse `box-s13`: rapportane genererte med `make
  analyse-similar-alle-domene-batch`, `analyse-similar-domene-batch` og
  `analyse-lokal-modellanalyse-domene` for alle domene. 426/426 nynorske
  renderingar er byte-like med `.md`, og 0 engelske har nynorske fasttekstar.
  `docs-publish` utan feil. Dei engelske sidene har engelske overskrifter,
  tabellhovud og tekstar («Similar class names (all domains, threshold 80%)»),
  og det same gjeld Modellanalyse-seksjonane på skjemasidene. mkdocs-bygg av
  `en` utan nye åtvaringar.
