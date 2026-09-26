# Lenkjesjekk: docs-cachen fangar ikkje endringar i generert dokumentasjon

## Bakgrunn

Etter BUG-24-fiksen (`specs/done/schemaview-namespaces-cache-importerte-prefiks.md`,
commit `fe5526af`) viste lenkjesjekk-køyring `36250233352` framleis 646
unsupported, sjølv om fiksen var verifisert lokalt.

Gransking av køyringa:

| Steg | Resultat |
|---|---|
| `generate / oreg` (cache frå `generate.yml` `36250221546` på `fe5526af`) | Fiksen er med: `URI: [dqv:value](http://www.w3.org/ns/dqv#value)` i `generated-oreg`-artefaktet |
| `lenkjesjekk` → «Cache publisert dokumentasjonsportal» | Cache-treff på `v2-docs-…` frå før fiksen → «Publiser og bygg dokumentasjonsportal» hoppa over, lychee sjekka gammal `mkdocs/docs/` |

**Rotårsak:** nøkkelen for `mkdocs/docs`+`mkdocs/site`-cachen i
`.github/workflows/lenkje-og-mermaid-sjekk.yml` hashar `src/linkml/**` og
`publish.sh`-kjeldene, men ikkje noko som skildrar *korleis* dokumentasjonen
vert generert (`src/assets/scripts/**`, `src/assets/templates/**`,
Dockerfiler, `make/*.mk`). Endringar i generatorlaget gir difor ikkje ny
nøkkel. Førre køyring (`36248679932`) fekk med seg malfiksen for
`rdf:langString` berre fordi same commit tilfeldigvis endra
`mkdocs/docs/arkitektur/**`.

`generate.yml` (publisert portal) er ikkje råka — `v1-site-…`-nøkkelen
hashar `generated/**`.

Opphavleg vart `generated/**` medvite halde utanfor nøkkelen fordi TTL-filene
har ferskt `linkml:generation_date` og ikkje-deterministisk
blankenode-rekkjefølgje (jf. kommentaren i workflowen og
`specs/done/lenkjesjekk-reduser-clock-time.md`).

## Tiltak (alternativ 1, vald av brukaren)

Legg `generated/**/*.md` til i docs-cache-nøkkelen og bump prefikset
`v2` → `v3`:

- `.md`-filene er det som faktisk vert til portalsider, så nøkkelen fangar
  alle generatorendringar som påverkar sideinnhaldet utan ei manuell
  infra-filliste (alternativ 2 — kopi av `v4-generated`-lista — vart forkasta:
  tredje kopi av same lange liste, bryt CI-DRY-terskelen 2+).
- Ikkje-`.md`-filer (TTL, SVG, puml, yaml, json, …) vert berre kopierte som
  nedlastingar; om dei finst, er styrt av manifestet (`src/linkml/**`, allereie i
  nøkkelen).

## Steg

1. [x] Stadfest at generert `.md` er deterministisk (to lokale genereringar)
2. [x] Oppdater nøkkel og kommentar i `lenkje-og-mermaid-sjekk.yml`; køyr `actionlint`
3. [ ] **Attståande (etter push):** køyr `lenkje-og-mermaid-sjekk` og kontroller at docs-cachen missar (`v3-docs-…`), at portalen vert bygd, og at unsupported ≈ 0

## Handlingsliste

- [x] Determinisme-sjekk av generert `.md`
- [x] Ny docs-cache-nøkkel (`v3`, `generated/**/*.md`)
- [x] actionlint
- [ ] CI-verifisering etter push

## Avgjerder
- Berre `generated/**/*.md`, ikkje `generated/**`: TTL er framleis ikkje-deterministisk (bekrefta på nytt 2026-09-26: `dqv-ap-no-shapes.ttl` skil seg mellom to køyringar utan kodeendring), og ikkje-`.md`-filer påverkar ikkje sideinnhaldet lychee sjekkar.
- Determinisme stadfesta med to påfølgjande `make gen-schema-docs` for `enhetsregisteret-bvrfriv` (279 `.md`) og `dqv-ap-no`: 0 ulike `.md`-filer. Skulle ein seinare generator gi ikkje-deterministisk `.md`, er konsekvensen berre cache-miss (tryggt, men tregare) — ikkje utdatert innhald.
- Eksisterande `src/linkml/**`- og `infra`-delar av nøkkelen er behaldne: dei fangar framleis endringar i manifest og `publish.sh`-kjelder som ikkje nødvendigvis endrar generert `.md`.
- Prefiks `v2` → `v3` for å tvinge fram ein rebuild ved første køyring.

## Utført

- `.github/workflows/lenkje-og-mermaid-sjekk.yml`: docs-cache-nøkkel `v3-docs-<src>-gen-<generated/**/*.md>-infra-<…>`, kommentar utvida. `actionlint`: ingen nye funn (berre eksisterande SC2034 på linje 170).

**Attståande etter push:** køyr `lenkje-og-mermaid-sjekk`. Forventa: «Publiser og bygg dokumentasjonsportal» køyrer (cache-miss på `v3-docs-…`), Errors 0, unsupported 646 → ~0 (BUG-24-fiksen når portalen).
