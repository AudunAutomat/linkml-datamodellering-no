# Omset resten av dei statiske sidene til engelsk

## Bakgrunn

Etter `specs/done/lokalisering-dokumentasjonsportal.md` har portalen ei engelsk
versjon under `/en/`. Strengkatalogen, framsida (`README.en.md`) og
`om.en.md` er omsette. 34 kjeldesider manglar framleis engelsk omsetjing og
vert viste på nynorsk med merknaden «Not yet translated»
(`make i18n-status`). Brukaren bad om at resten av dei statiske sidene vert
omsette til engelsk.

Omfang (34 sider, om lag 5700 linjer):

- 24 rettleiingssider i `mkdocs/docs/` (`kom-i-gang/`, `arkitektur/`,
  `publisering/`, `automasjon/`, inkludert indekssidene)
- `src/mcp-linkml-validator/policies/README.md` (vert til valideringsreglar-sida)
- 10 domeneskildringar `src/linkml/<domene>/description.md`

Framgangsmåte og terminologi: `.claude/rules/i18n-omsetjing.md`.

## Steg

1. Lag eit hjelpescript som set faste anker på engelske overskrifter frå den
   nynorske originalen. Scriptet skal òg kontrollere at overskriftsstrukturen
   er lik i original og omsetjing.
2. Omset domeneskildringane (10).
3. Omset indekssidene og dei korte sidene.
4. Omset `kom-i-gang/`.
5. Omset `arkitektur/`.
6. Omset `publisering/`.
7. Omset `automasjon/`.
8. Omset `policies/README.md`.
9. Stempla alle sidene og køyr `make i18n-status` / `make i18n-check`.
10. Bygg den engelske portalen i sandkasse og sjekk lenkjer og anker.
11. Oppdater `.claude/rules/i18n-omsetjing.md` med ankerprinsippet.

## Handlingsliste

- [x] 1. Hjelpescript for anker
- [x] 2. Domeneskildringar
- [x] 3. Indekssider og korte sider
- [x] 4. `kom-i-gang/`
- [x] 5. `arkitektur/`
- [x] 6. `publisering/`
- [x] 7. `automasjon/`
- [x] 8. `policies/README.md`
- [x] 9. Stempling og status
- [x] 10. Sandkassebygg
- [x] 11. Rule

## Avgjerder

- **Omfang:** alle 34 sider som `make i18n-status` listar som manglande, også
  domeneskildringar og `policies/README.md`. Alle vert viste som ikkje omsette i
  den engelske portalen.
- **Anker på portalsider:** engelske overskrifter i `mkdocs/docs/*.en.md` får
  fast anker lik slug-en av den nynorske overskrifta (`## Prerequisites {#foresetnader}`),
  i tråd med O2-a. Då held eksisterande `#anker`-lenkjer, både innanfor sida og
  mellom sider, i begge språk, og språkveljaren tek med ankeret. Dette
  erstattar punktet i `.claude/rules/i18n-omsetjing.md` om at anker skal peike
  på den engelske slug-en.
- **Unntak utan faste anker:** `README.en.md`, `policies/README.en.md` og
  `description.en.md` vert òg viste på GitHub, der attr_list-syntaksen `{#…}`
  ville synt som tekst. `policies/README.md` sine policy-overskrifter
  (`bronze`, `silver` …), som valideringsresultata lenkjer til, er like i begge
  språk.
- **Hjelpescript vart ein del av `stamp-page`:** i staden for eit eige script
  set `i18n_status.py stamp-page` faste anker når sida ligg under
  `mkdocs/docs/`, og feilar ved ulik overskriftsstruktur. Då kan ankera ikkje
  gå ut av synk med originalen ved seinare omstempling. Sluggen følgjer
  mkdocs sin `slugify` med dedup (`_1`, `_2`), så ø/æ fell bort (`fresetnader`).
- **Digdir-regelnavn i `policies/README.en.md`:** brukar dei offisielle
  bokmålsnavna frå Digdir (Meningsfullhet, Identifiserbarhet …) med engelsk
  forklaring i parentes i dekningstabellen, i staden for dei nynorske
  skrivemåtane i originalen. Lenkjene går til Digdir si bokmålsside.
- **Norske verdiar vert ståande:** feltnavn i registreringsskjemaet på
  data.norge.no (Utgjevar, Katalogtype …), knappetekst («Høst»), kodeeksempel,
  genererte norske kommentarar og commit-meldingar i døme står på norsk, med
  engelsk forklaring der det trengst.
- **Portal-URL-ar:** hovudportalen i `monitorering.en.md` peikar på `/en/`.
  Adressa UptimeRobot overvakar, og alle artefakt-/haustingsadresser, står utan
  språkprefiks.
- **`fleirsprak.md` (original) utvida:** eit avsnitt om at `i18n-stamp` set faste
  anker, sidan sida er normativ kjelde for mekanismen. Omsetjinga er stempla mot
  den nye versjonen.
- **Sandkassebygg:** `generated/` i repoet har gen-doc-output utan
  i18n-markørar, og `docs-publish` feila då for alle skjema. Sandkassa brukte
  difor `generated/` frå `box-s5-after`, som har ny gen-doc-output. Berre `en`
  vart bygd (`nn` er uendra av denne specen, utanom `fleirsprak.md`).
- **Valideringsreglar-sida på engelsk** har engelske anker for alle overskrifter
  utanom policy-overskriftene. Språkveljaren tek med ankeret berre for desse.

## Utført

- 36 engelske sider er omsette og stempla: 24 rettleiingssider, 10
  domeneskildringar, `policies/README.en.md` og omstempla `om.en.md`.
  `make i18n-status`: 0 manglar, 0 utdaterte, 0 ustempla. `make i18n-check`:
  310 nøklar, 0 manglar, 22 testar OK.
- `stamp-page` set faste anker frå den nynorske originalen og kontrollerer
  overskriftsstrukturen (to nye testar i `tests/test_i18n_status.py`).
- Sandkassebygg av `en` (`box-s11`): `docs-publish` utan feil, mkdocs-bygg utan
  lenkje- eller ankeråtvaringar for statiske sider. Dei einaste åtvaringane er dei
  kjende artefaktlenkjene ut av språktreet (A0). Etter at `rot/` vart lagd på rota:
  513/513 artefaktlenkjer OK. Kryss-side-anker (`#registrering-av-hstingsendepunkt-ein-gong`,
  `#verifisere-at-hstingsendepunkt-er-tilgjengelege-eksternt`, `#getting-started`)
  finst i dei bygde sidene.
- `.claude/rules/i18n-omsetjing.md`: ankerprinsippet er oppdatert.
