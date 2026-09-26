---
name: bug-diagnostisering
description: Krav til rotårsak og status i bug-filer — minimal reproduksjon før status upstream, fersk regenerering før samanlikning kjelde mot generert output. Lastast automatisk ved arbeid med bugs/ og BUGS.md.
paths:
  - "bugs/**"
  - "BUGS.md"
---

## Kvifor

Eit symptom i eit stort domeneskjema peikar sjeldan eintydig på rotårsaka.
Ein rotårsak utleidd frå feilmeldinga åleine, eller frå samanlikning mot
gamle artefakter, gir feil workaround, feil skip-grunngjeving og ein
upstream-rapport som ikkje kan reproduserast. Verifiseringa i
`specs/backlog/upstream-linkml-bugrapportar.md` fann dette for fem bugs:

- BUG-1/BUG-2 var dokumenterte som LangString- og
  `inlined_as_list`-feil. Årsaka var to slots med same `slot_uri`.
- BUG-3 var ein ustadfesta hypotese. Årsaka var eit attributt som skuggar
  ein global slot.
- BUG-19 gjald berre ein eigendefinert type med `base: str`, ikkje
  `datetime` generelt.
- BUG-20 samanlikna kjelde mot `generated/`-output som var eldre enn
  endringa i kjelda, og reproduserer ikkje.

## Aldri

- **Aldri** set `Rot-årsak` som stadfesta (eller status `upstream`) berre
  ut frå feilmeldinga i eit domeneskjema. Skriv «hypotese» til punkt 1-3
  under er gjort.
- **Aldri** samanlikn kjelde mot `generated/`, `mkdocs/docs/` eller andre
  byggartefakter utan å regenerere dei først. Artefaktane er gitignorerte og
  kan vere vekevis gamle (sjekk `ls -la --time-style=long-iso` mot
  `git log -1` for kjeldefila).

## Framgangsmåte

1. **Regenerer** artefaktane med Makefile-targeten (t.d.
   `make gen-schema-docs SCHEMA=...`) før du samanliknar mot kjelda.
2. **Lag ein minimal reproduksjon** (MRE): eit sjølvstendig skjema med
   berre dei elementa som trengst, og køyr det i containeren. Reproduserer
   ikkje MRE-en, er hypotesen feil eller ufullstendig. Grav vidare, t.d.
   ved å lese kjeldekoden i containeren, og kom tilbake til eit nytt MRE.
3. **Før status `upstream`:** køyr MRE-en mot eit image **utan** lokale
   patchar (t.d. `docgen-max-chars.patch`). Stadfest at feilen ikkje ligg i
   eigne malar, script eller skjema.
4. **Sjekk om feilen er kjend/fiksa:** søk i
   [linkml/linkml](https://github.com/linkml/linkml/issues) (monorepo —
   `linkml/linkml-runtime` er arkivert) og sjekk `main` for fiksar etter
   gjeldande release.
5. **Dokumenter** MRE-en (skjema, data, kommando, forventa/faktisk) i
   bug-fila, slik at han kan brukast direkte i ein upstream-rapport.
6. **Slå saman bugs med same rotårsak:** har to bugs same rotårsak, skal
   dei vere éin bug. Skip-grunngjevingane i `tests/test_make.sh` skal då
   peike på den samanslåtte bugen.

Sjå `specs/backlog/upstream-linkml-bugrapportar.md` (§ Verifiseringsmatrise
og § Testoppsett) for døme på MRE-ar og køyring mot vanilla-/`main`-image.
