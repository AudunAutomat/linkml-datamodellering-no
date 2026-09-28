# README.en.md manglar i CI — engelsk framside vert vist på norsk

## Bakgrunn

Den engelske framsida (`/en/`, nav-gruppa «Guides») i den publiserte portalen
viser norsk tekst, sjølv om `README.en.md` finst og `write_index_from_readme`
i `mkdocs/publish.sh` brukar språkvarianten via `i18n_source`. Lokalt verkar
det.

**Årsak:** CI sender kjeldekoden mellom jobbar som ein artifact med eksplisitt
filliste (`artifact-paths` i `.github/workflows/reusable-oppsett.yml:50`).
Lista har `README.md`, men ikkje `README.en.md`. I publiseringsjobben finst
difor ikkje språkvarianten, og `i18n_source` fell tilbake til `README.md` (med
«ikkje omsett»-merknaden).

Same fil manglar òg i:

- `on.push.paths` i `generate.yml:35`: ei endring berre i `README.en.md`
  startar ikkje nytt bygg.
- site-cache-nøkkelen i `generate.yml:536` (`v1-site-…`): endringar i
  `README.en.md` gir ikkje ny nøkkel, så ein utdatert, norsk portal kan bli
  gjenbrukt.
- docs-cache-nøkkelen i `lenkje-og-mermaid-sjekk.yml:331` (`v3-docs-…`):
  same problem for lenkjesjekken.

Dette er same feilmønster som `.claude/rules/ci-workflows.md` § «Cache-nøklar
for avleidde artefakter» skildrar: ein for smal nøkkel gir stille, utdatert
innhald.

## Steg

1. `reusable-oppsett.yml`: byt `README.md` med `README*.md` i
   `artifact-paths`-standardlista, og oppdater `description` tilsvarande.
2. `generate.yml`: byt `'README.md'` med `'README*.md'` i `on.push.paths`.
3. `generate.yml`: byt `'README.md'` med `'README*.md'` i site-cache-nøkkelen
   og bump `v1-site` → `v2-site` (oppdater kommentaren over).
4. `lenkje-og-mermaid-sjekk.yml`: byt `'README.md'` med `'README*.md'` i
   docs-cache-nøkkelen og bump `v3-docs` → `v4-docs` (oppdater kommentaren
   over).
5. Køyr `actionlint` mot dei tre endra filene.
6. Etter push: sjekk i jobbloggen til `generate.yml` at site-cachen *missa*,
   og at `/en/` i den publiserte portalen viser engelsk framside utan
   «ikkje omsett»-merknad.

## Handlingsliste

- [x] Steg 1: `artifact-paths` i `reusable-oppsett.yml`
- [x] Steg 2: `paths`-filter i `generate.yml`
- [x] Steg 3: site-cache-nøkkel i `generate.yml`
- [x] Steg 4: docs-cache-nøkkel i `lenkje-og-mermaid-sjekk.yml`
- [x] Steg 5: actionlint (berre `[shellcheck]`-stilråd, ingen blokkerande funn)
- [ ] Steg 6: verifiser publisert `/en/` (ventar på push frå brukaren)

## Avgjerder

- **`README*.md` i staden for `README.en.md`:** glob-mønsteret tek med
  framtidige språkvariantar utan ny CI-endring. `actions/upload-artifact`,
  `on.push.paths` og `hashFiles` støttar alle glob. Mønsteret treffer berre
  `README.md` og `README.en.md` på rotnivå i dag.
- **Bump av versjonsprefiks** (`v1-site` → `v2-site`, `v3-docs` → `v4-docs`):
  nøkkelformelen endrar semantikk, jf. `.claude/rules/ci-workflows.md`
  steg 3. Ingen andre workflowar deler desse nøklane (grep stadfesta).
- **Specen vert verande i `specs/backlog/`** til steg 6 er verifisert etter
  push.
