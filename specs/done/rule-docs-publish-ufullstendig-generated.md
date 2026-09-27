# Rule: ikkje køyr `make docs-publish` som verifisering mot ufullstendig `generated/`

## Bakgrunn

Under steg 1 i `specs/backlog/lokalisering-dokumentasjonsportal.md` (endringa
`theme.language: nb` → `nn` i `mkdocs/publish.sh`) køyrde LLM
`make docs-publish && make docs-build` for å stadfeste endringa. Den lokale
`generated/`-katalogen var ufullstendig. For `felles`-skjemaa låg berre
gen-doc-output og ER-diagram der, og `.ttl`, PlantUML-diagram og
valideringsresultat mangla.

`publish.sh` slettar og regenererer `mkdocs/docs/<domain>/` for kvart domene i
`generated/`. `mkdocs/docs/felles/` er versjonskontrollert (512 filer), i
motsetnad til dei andre domenekatalogane, som står i `.gitignore`. Resultatet
vart 48 sletta filer (`*.ttl`, `diagrams/*`, `validation/*`) og 11 endra
`index.md`-filer, der ER-diagram-seksjonen forsvann og artefaktabellen gjekk
frå 6 til 2 rader. Endringa som skulle verifiserast, låg i heredoc-blokka for
`mkdocs.yml` og kunne ha vore stadfesta utan eit fullt bygg.

Brukaren oppdaga slettingane og bad om at mønsteret vert fanga som rule.

## Steg

1. Utvid `.claude/rules/mkdocs-portal.md` med ein subseksjon om at
   `make docs-publish` skriv til versjonskontrollerte filer, og om korleis ein
   verifiserer trygt.
2. Rapporter funnet om at `mkdocs/docs/felles/` manglar i `.gitignore` til
   brukaren, men endre det ikkje i denne specen.

## Handlingsliste

- [x] 1. Ny subseksjon i `.claude/rules/mkdocs-portal.md`
- [x] 2. Rapporter `.gitignore`-funnet

## Avgjerder

- **Utvida eksisterande rule, ikkje ny fil:** emnet (`publish.sh`/`docs-publish`)
  deler scope (`mkdocs/**`) med resten av `mkdocs-portal.md`.
- **`.gitignore` er ikkje endra:** det er uklart om `mkdocs/docs/felles/` er
  versjonskontrollert med vilje. Rula er difor generell («sjekk kva som er
  versjonskontrollert») og ikkje knytt til `felles`.

## Utført

- `.claude/rules/mkdocs-portal.md`: ny subseksjon «`make docs-publish` er ikkje ein trygg verifiseringssteg» med forbod, framgangsmåte i tre steg og referanse til tilfellet.
- `.gitignore`-funnet (`mkdocs/docs/felles/` manglar i lista over genererte portalkatalogar) er rapportert til brukaren. Ingen endring.
- Dei 48 sletta og 11 endra filene under `mkdocs/docs/felles/` står framleis som lokale endringar. Brukaren rettar dei med `git restore mkdocs/docs`.
