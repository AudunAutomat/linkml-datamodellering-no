# Rule: nye portalinndata utanfor dekte katalogar må inn i CI-fillistene

## Bakgrunn

`README.en.md` vart lagd til som kjelde for den engelske framsida
(`write_index_from_readme` i `mkdocs/publish.sh`), men fila vart ikkje lagd
til i CI sine eksplisitte fillister: `artifact-paths` i
`reusable-oppsett.yml`, `on.push.paths` i `generate.yml` og cache-nøklane i
`generate.yml`/`lenkje-og-mermaid-sjekk.yml`. I CI fall `i18n_source` stille
tilbake til `README.md`, og `/en/` viste norsk framside. Lokalt verka det.
Sjå `specs/backlog/readme-en-manglar-i-ci.md`.

Same manglande fil fanst òg i sandkasse-oppskrifta i
`.claude/rules/mkdocs-portal.md` (kopierer berre `README.md`).

## Steg

1. Legg til underseksjon i `.claude/rules/mkdocs-portal.md`: problem,
   forbod, framgangsmåte, konkret tilfelle.
2. Rett sandkasse-oppskrifta i same fil til `README*.md`.
3. Legg til kort peikar i `.claude/rules/i18n-omsetjing.md`.
4. Oppdater `description` i frontmatter til `mkdocs-portal.md`.

## Handlingsliste

- [x] Steg 1
- [x] Steg 2
- [x] Steg 3
- [x] Steg 4

## Avgjerder

- **Utviding av `mkdocs-portal.md`, ikkje ny fil:** feilen oppstår når
  `publish.sh` tek i bruk ei ny inndatafil, og `mkdocs/**` er scopet til
  `mkdocs-portal.md`. `ci-workflows.md` vert berre lasta når ein alt rører
  CI-filene, og det var nett det som ikkje skjedde.
- **Peikar i `i18n-omsetjing.md`:** ein ny `*.en.md` på rotnivå lastar berre
  i18n-rula. Ei linje med kryssreferanse i staden for å gjenta innhaldet (DRY).
- **Rula peikar berre til denne specen i `specs/done/`,** ikkje til
  `specs/backlog/readme-en-manglar-i-ci.md`, som skal flyttast etter
  CI-verifiseringa. Då slepp rula ein sti som vert utdatert. Denne specen
  peikar vidare til fiks-specen.

## Utført

- `.claude/rules/mkdocs-portal.md`: ny underseksjon «Nye inndatafiler til
  `publish.sh` må inn i CI-fillistene», sandkasse-kopien brukar `README*.md`,
  `description` utvida.
- `.claude/rules/i18n-omsetjing.md`: peikar til den nye underseksjonen.
