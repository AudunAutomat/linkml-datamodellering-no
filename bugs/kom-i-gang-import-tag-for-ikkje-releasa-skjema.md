# Bug: «Kom i gang»-seksjonen viser import-URL til ein tag som aldri vert laga

**ID:** BUG-23
**Status:** `open`
**Komponent:** `mkdocs/lib/sections/kom_i_gang.sh`
**Oppdaga:** 2026-09-26

## Symptom

Modellsida i portalen (seksjonen «Importer i egne LinkML-skjema») viser
ein import-URL på forma

```
https://raw.githubusercontent.com/AudunAutomat/linkml-datamodellering-no/<skjema>-v<versjon>/src/linkml/<domene>/<skjema>/<skjema>-schema
```

for skjema der taggen `<skjema>-v<versjon>` ikkje finst. URL-en gir 404, og
ein brukar som kopierer importen får eit skjema som ikkje kan lastast.

## Rot-årsak

`kom_i_gang.sh` utleier tag-namnet berre frå `version:`-feltet i skjemaet:

```bash
local version_tag="${version:+${schema}-v$version}"
local version_path="${version_tag:-main}"
```

Taggar vert berre laga av release-please (og per-schema-tag-steget i
`release-please.yml`) for skjema som er **komponentar** i
`.github/release-please-config.json`. Skjema som har `version:` men ikkje er
komponentar, får difor ein tag-URL som aldri vil eksistere.

## Berørte skjema

Stadfesta 2026-09-26 (skjema med `version:` der `<skjema>-v<versjon>` ikkje
finst som tag; ingen av dei er release-please-komponentar):

- `felles`: `brreg-felles-aktoer`, `brreg-felles-digital-adresse`,
  `brreg-felles-geografisk-adresse`, `brreg-felles-tid`, `brreg-felles-typer`
  (alle `v0.1.0`; synleg i tracka `mkdocs/docs/felles/*/index.md`)
- `oreg`: `enhetsregisteret-bvrbekreftelse`,
  `enhetsregisteret-bvrettersendingavvedlegg`, `enhetsregisteret-bvrfriv`,
  `enhetsregisteret-bvrstiftelsesdokument`,
  `enhetsregisteret-frivilligorganisasjonapi`, `javazonetalk` (alle `v0.1.0`)

Feilen er eldre enn flyttinga frå `brreg` (taggane fanst heller ikkje der),
oppdaga under steg 9.6 i `specs/backlog/ci-etter-origin-flytting-audunautomat.md`.

## Workaround

Ingen. Brukarar kan byte tag-delen i URL-en med `main` manuelt.

## Forslag til løysing

La `kom_i_gang.sh` berre bruke `<skjema>-v<versjon>` når skjemastien er ein
nøkkel i `.github/release-please-manifest.json` (same sannkjelde som
release-please), og elles falle tilbake til `main` — eventuelt med ein
merknad om at modellen enno ikkje er versjonert/releasa. Alternativt: gjer
skjemaa til release-please-komponentar dersom dei skal vere importerbare med
låst versjon.
