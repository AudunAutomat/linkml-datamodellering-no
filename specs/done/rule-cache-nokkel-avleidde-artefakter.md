# Rule: cache-nøklar for avleidde artefakter i CI

## Bakgrunn

Lenkjesjekk-køyring `36250233352` (commit `fe5526af`, BUG-24-fiksen) viste
framleis 646 unsupported sjølv om fiksen var verifisert lokalt og til og med
var med i `generated-oreg`-artefaktet frå same køyring. Årsaka var at
docs-cache-nøkkelen i `lenkje-og-mermaid-sjekk.yml` ikkje hasha
generatorlaget, så ein utdatert `mkdocs/docs/` vart gjenbrukt og
portalbygget hoppa over — sjå
`specs/done/lenkjesjekk-docs-cache-generert-md.md`. Første tolking av
CI-resultatet («fiksen verkar ikkje») var feil; det var cachen som ikkje
missa.

Dette er fjerde observerte cache-nøkkelfeil i repoet:

| Spec | Feilretning |
|---|---|
| `specs/done/lenkjesjekk-docs-cache-generert-md.md` | For smal — stale innhald, falsk negativ CI-verifisering |
| `specs/done/scripts-glob-cache-miss-generate-jobb.md` | For brei (`src/assets/scripts/**`) — unødvendig regenerering |
| `specs/done/docs-only-endring-cache-miss-alle-domene.md` | For brei (`make/**`) — alle domene regenererte ved docs-endring |
| `specs/done/evaluering-gjentakande-monster-backlog.md` (P3) | Duplisert nøkkelformel drifta mellom to filer |

Brukaren godkjende å leggje til rula (jf. avslutningssteget i
lenkjesjekk-docs-cache-specen).

## Steg

1. [x] Avgjer mekanisme og plassering (ny fil eller underseksjon)
2. [x] Skriv underseksjonen: problem, forbod, framgangsmåte, referansar
3. [x] Oppdater `description:` i frontmatter

## Handlingsliste

- [x] Ny underseksjon i `.claude/rules/ci-workflows.md`
- [x] Frontmatter `description` oppdatert

## Avgjerder
- Rule, ikkje CLAUDE.md: gjeld berre ved arbeid med `.github/workflows/**`/`.github/actions/**` (cache-steg finst berre der).
- Underseksjon i eksisterande `.claude/rules/ci-workflows.md`, ikkje ny fil: same `paths:`-scope, og emnet heng tett saman med DRY-seksjonen (P3 er òg ein cache-nøkkelfeil) — plassert rett etter han, med kryssreferanse i staden for å gjenta P3.
- Dekkjer både for smal og for brei nøkkel, sidan repoet har konkrete tilfelle av begge; hovudvekta ligg på for smal (stille feil og falsk negativ CI-verifisering), som er den farlegaste.
- Punkt 4 (stadfest cache-miss før konklusjon) er teke med fordi feilen i denne økta først vart tolka som «fiksen verkar ikkje».

## Utført

- `.claude/rules/ci-workflows.md`: ny seksjon «Cache-nøklar for avleidde artefakter» (problem, to forbod, 4-punkts framgangsmåte, grunngjeving med køyring `36250233352` og tre tidlegare specar); `description` i frontmatter utvida.
