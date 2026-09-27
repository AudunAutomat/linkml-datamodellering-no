# Engelsk framside med genererte README-tabellar på engelsk

## Bakgrunn

Framsida i portalen («Guides», `index.md`) vert laga frå `README.md`, og
på engelsk frå `README.en.md`. Prosaen i `README.en.md` er omsett, men dei tre
auto-genererte tabellane (skjema, begrepskatalogar, modellkatalogar) vert i dag
henta ordrett frå `README.md` ved bygging (`i18n_fill_auto_blocks`). Dermed er
tabellhovud og faste tekstar som «Modellkatalog for X sine informasjonsmodellar»
på nynorsk også på den engelske framsida. I `README.en.md` på GitHub står
blokkene tomme. Brukaren vil at dei genererte delane av framsida skal vere på
engelsk i den engelske versjonen.

Avklart med brukaren:

- **Skildring-kolonna** er `description` frå skjemaet (modellinnhald) og vert
  ikkje omsett, i tråd med at modellinnhald vert vist på originalspråket.
  Berre teksten scriptet sjølv lagar, vert omsett.
- **`README.en.md` i repoet** skal få tabellane fylte av
  `generate-readme-tables.sh` på same måte som `README.md`, slik at GitHub òg
  viser dei.

## Steg

1. Legg inn katalognøklar (`readme_tabell.*`) for tabellhovud, faste tekstar og
   fallback-verdien («Ukjend»).
2. `generate-readme-tables.sh`: ta imot språk som argument, hent tekst med `t`,
   og la portal-lenkjene peike på `/<språk>/` for andre språk enn standardspråket.
   `README.md` skal bli byte-lik med i dag.
3. `i18n_strings.py`: ta med `generate-readme-tables.sh` i skanninga for
   nøkkelbruk, slik at `make i18n-check` fangar manglande nøklar.
4. `publish.sh`: køyr generatoren for kvar `README.<lang>.md` som finst, og bruk
   blokkene i språkvarianten direkte i `index.md`. Fjern `i18n_fill_auto_blocks`
   dersom han ikkje lenger er i bruk.
5. Oppdater dokumentasjonen (`fleirsprak.md`, `readme-tabellgenerering.md` med
   omsetjingar, `.claude/rules/i18n-omsetjing.md`, kommentaren i
   `i18n_status.py`) og stempla dei omsette sidene på nytt.
6. Verifiser: `README.md` uendra, `README.en.md` fylt med engelske tabellar,
   `make i18n-check`, `make i18n-status`, og sandkassebygg av den engelske
   framsida.

## Handlingsliste

- [x] 1. Katalognøklar
- [x] 2. `generate-readme-tables.sh` per språk
- [x] 3. Nøkkelskanning
- [x] 4. `publish.sh`
- [x] 5. Dokumentasjon og stempling
- [x] 6. Verifisering

## Avgjerder

- **Språk som argument, standardspråk på rota:** `generate-readme-tables.sh
  [README-fil] [språk]`. For standardspråket peikar lenkjene framleis på rota
  (vidaresending til `/nn/`), slik at `README.md` vert byte-lik med i dag. For
  andre språk peikar lenkjene direkte på `/<språk>/`.
- **Tekst tilordna til variablar:** alle `t`-kall er tilordningar
  (`H_DOMENE=$(t …)`, `skildring=$(t …)`), slik at ein manglande nøkkel stoppar
  scriptet (`set -e`) i staden for å verte svelgd inne i `echo`.
- **`i18n_fill_auto_blocks` er fjerna:** `write_index_from_readme` brukar no
  blokkene i språkvarianten direkte, og funksjonen hadde ingen andre kallarar.
- **Organisasjonsnavn og domeneetikettar vert ikkje omsette:** «Registerenheten
  i Brønnøysund», «Digitaliseringsdirektoratet» og lenketekstane
  `begrepskatalog`/`modellkatalog` er navn.
- **Byggjetid:** steget «Oppdater README-tabellar» tek no om lag 17 s i
  sandkassa, fordi kvar køyring lastar katalogen (éin podman-start per språk)
  og hentar metadata per skjema to gonger (éin gong per README).

## Utført

- `mkdocs/lib/i18n/strings.yaml`: 11 nye `readme_tabell.*`-nøklar (nn + en),
  stempla.
- `generate-readme-tables.sh`: tek språk som argument, tabelltekst frå
  katalogen, portal-lenkjer til `/<språk>/` for andre språk.
- `publish.sh`: `update_readme_tables` køyrer generatoren for `README.md` og
  kvar `README.<lang>.md`. `write_index_from_readme` brukar språkvarianten
  direkte. `i18n_fill_auto_blocks` er fjerna frå `i18n.sh`.
- `i18n_strings.py`: generatoren er med i nøkkelskanninga (299 nøklar i bruk,
  var 288).
- `README.en.md`: tabellane er fylte på engelsk (53 linjer). Prosaen er
  uendra, og sida er framleis oppdatert i `make i18n-status`.
- Dokumentasjon: `fleirsprak.md`, `readme-tabellgenerering.md` (+ `.en.md`,
  restempla), `.claude/rules/i18n-omsetjing.md`, docstring i `i18n_status.py`.
- Verifisert: generatoren gjev byte-lik `README.md`. Sandkasse `box-s12`:
  `docs-publish` utan feil, `README.md`/`README.en.md` uendra etter publisering
  (idempotent). Den engelske framsida har engelske tabellhovud og tekstar og
  ingen nynorske restar utanom skjemaskildringane. Den nynorske framsida er
  uendra. mkdocs-bygg av `en` utan nye åtvaringar. `make i18n-check`: 321
  nøklar, 0 manglar, 22 testar OK. `make i18n-status`: 0 manglar/utdaterte/ustempla.
