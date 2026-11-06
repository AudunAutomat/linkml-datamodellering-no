---
name: testar
description: Artefakt-sjekkar i tests/** skal krevje at fila er generert i same testkøyring og spegle build.yaml-gatinga til generatoren. Lastast automatisk ved arbeid med filer under tests/.
paths:
  - "tests/**"
---

## Ein artefakt-test skal ikkje godta ei fil berre fordi ho finst

`generated/` er gitignorert og vert aldri rydda. Ei fil der kan vere månader gamal og
komme frå ein generator som ikkje lenger køyrer. Ein test som berre sjekkar at fila
finst og ikkje er tom, gir då falsk OK, og feilen syner seg først i ein rein checkout.

Den same fella kjem når testen og produsenten tolkar konfigurasjonen ulikt. Fase A i
`tests/test_make.sh` genererer via `batch-generate.py`, som hoppar over generatorar
som ikkje er `true` i `build.yaml`. Fase B sjekka artefakta utan å lese `build.yaml`.
Resultatet var «Fil manglar» der flagget var av og ingen gamal fil låg att, og falsk
OK der ho låg att.

**Aldri** skriv ei artefakt-assertion som berre sjekkar `[ -f ]`/`[ -s ]`. **Aldri**
la ein test forvente eit artefakt som produsenten ikkje er konfigurert til å lage.

Ved ny eller endra artefakt-test:

1. Krev at fila er nyare enn starten av testkøyringa. I `test_make.sh` gjer
   `assert_file_nonempty()` dette mot `TEST_START_MARKER`. Bruk han i staden for ein
   eigen `[ -s ]`-sjekk.
2. Hopp over testen når produsenten ikkje er konfigurert til å lage artefaktet. Bruk
   same tolking som produsenten. For generatorar er det `skip_disabled_generator
   <skjema> <flagg> <test>`, som les `^  <flagg>: true$` frå `build.yaml` slik
   `read_build_yaml_flag()` i `batch-generate.py` gjer. Flaggnavnet er nøkkelen i
   `build.yaml` (t.d. `json_schema`), ikkje testnavnet.
3. Skip-en skal skrive éi linje med kvifor, slik at han er synleg i testloggen.
4. Verifiser i rein tilstand: flytt `generated/` til ein backup i scratchpad, køyr
   testen, og legg katalogen tilbake etterpå. Ein test som berre er køyrd mot ein
   eksisterande `generated/`, er ikkje verifisert.

Grunngjeving: `specs/done/rett-feil-i-make-test.md`. Flagga for 13 skjema vart slått
av 2026-08-07 (`0987f9cb`), men testane deira passerte i tre månader på artefakter frå
2026-08-04/05. 36 andre feila med «Fil manglar» av same grunn.
