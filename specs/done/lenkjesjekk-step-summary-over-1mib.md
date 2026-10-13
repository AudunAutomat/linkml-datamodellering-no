# Lenkjesjekk: Step Summary over 1 MiB

## Bakgrunn

Jobben `lenkjesjekk` i `.github/workflows/lenkje-og-mermaid-sjekk.yml` gav
annotasjonen «`$GITHUB_STEP_SUMMARY upload aborted, supports content up to a
size of 1024k, got 1075k`» i køyring 38262481311 (2026-10-12). Steget
«Sjekk lenkjer i dokumentasjon» skriv heile lychee-rapporten
(`lenkjesjekk-report.md`) til Step Summary. GitHub tillèt maks 1 MiB
(1 048 576 byte) per steg.

| Køyring | Rapportstorleik | Feil |
|---|---|---|
| 38049966383 | 1 048 788 byte | 5996 |
| 38137891411 | 1 016 335 byte | 5724 |
| 38262481311 | 1 101 197 byte | 6850 |

Rapporten er stor fordi han inneheld mange feil:

- **5706 × 404** på `github.com/brreg/linkml-datamodellering-no/commit/<sha>`.
  Lenkjene står i 34 `src/linkml/**/CHANGELOG.md` (1146 førekomstar), som
  òg vert kopierte inn i `mkdocs/docs/**` og `mkdocs/build/src-en/**`.
  `brreg`-repoet gir no 404. Dei same commitane finst i
  `AudunAutomat/linkml-datamodellering-no` (stikkprøve gav 200).
- **~1140 × 503** frå github.com (`linkml/linkml-model` og
  `AudunAutomat/…`), truleg rate-limit. Desse er utanfor scope.

Note-boksen i `mkdocs/docs/arkitektur/ekstern-bruk.md` (og `.en.md`)
viser til `github.com/brreg/linkml-datamodellering-no/releases` for releases
frå før flyttinga. Den lenkja er òg død. Avgjerda O3 i
`specs/done/ci-etter-origin-flytting-audunautomat.md` føresette at
`brreg`-repoet vart ståande.

## Steg

1. Avgrens det som vert skrive til `$GITHUB_STEP_SUMMARY` i steget «Sjekk
   lenkjer i dokumentasjon» med eit byte-tak. Skriv Summary-tabellen og så
   mange heile linjer som får plass. Etterpå kjem ei linje om at rapporten er
   avkorta, og at full rapport ligg i artefakten `lenkjesjekk-report`.
2. Skriv om `github.com/brreg/linkml-datamodellering-no/commit/` →
   `github.com/AudunAutomat/linkml-datamodellering-no/commit/` i
   `src/linkml/**/CHANGELOG.md`.
3. Skriv om note-boksen i `ekstern-bruk.md` og `ekstern-bruk.en.md`, slik at
   han ikkje lenkjer til `brreg`. Restempl `.en.md`.
4. Køyr actionlint mot workflowen og `make i18n-check`.

## Handlingsliste

- [x] Steg 1: byte-tak i Step Summary (900 000 byte; testa mot rapporten
  frå 38262481311 → 899 885 byte)
- [x] Steg 2: CHANGELOG commit-lenkjer (34 filer, 1146 førekomstar, 163
  unike SHA-ar — alle stadfesta 200 via `gh api` mot `AudunAutomat/`)
- [x] Steg 3: note-boks i ekstern-bruk — tekst endra i begge språk,
  `.en.md` restempla med `make i18n-stamp`
- [x] Steg 4: verifisering — YAML-parse OK; `make i18n-check` OK (26
  passed); `ekstern-bruk.en.md` ikkje utdatert i `i18n-status`; `actionlint`
  gir berre SC2034 (`blockfile` unused, linje 170) som finst uendra i HEAD
  (første forsøk feila på podman, OK etter WSL-restart)

## Avgjerder

- **Byte-tak 900 000, ikkje 1 048 576:** margin for overskrifta og
  avkortingslinja, og for at `wc -c`/awk-teljinga og GitHub si grense kan
  rekne litt ulikt. Avkortinga skjer ved heile linjer (`LC_ALL=C awk`, tel
  byte). Ei logglinje i jobben seier frå når rapporten vert avkorta, slik at
  avkortinga ikkje er stille.
- **Berre `commit/`-lenkjer er skrivne om, ikkje `compare/`:** brukaren valde
  omskriving av commit-lenkjene. `compare/`-lenkjene (343) er alt
  ekskluderte i `lychee.toml`, og fleire av taggane dei viser til manglar
  (jf. `specs/done/lenkjesjekk-runde4-88-feil-og-unsupported.md` kategori A),
  så dei vert ikkje rapporterte.
- **Note-boksen viser til `raw.githubusercontent.com` med tag** for eldre
  versjonar i staden for brreg-releases, sidan alle versjon-taggar vart flytta
  med (jf. same note-boks).
- **SC2034 i mermaid-steget er retta etter ønske frå brukaren:** åtvaringa
  var eldre enn denne endringa. Ubrukt `blockfile` i «Rendra kvar
  mermaid-blokk» er fjerna (containeren les `/data/block-<id>.mmd`);
  actionlint er no utan funn.

## Utført

Step Summary i `lenkjesjekk` vert avkorta ved 900 000 byte med synleg
melding; commit-lenkjer i 34 CHANGELOG-filer peikar til `AudunAutomat/`;
note-boksen i `ekstern-bruk(.en).md` lenkjer ikkje lenger til `brreg`.
