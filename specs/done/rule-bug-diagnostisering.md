# Rule: minimal reproduksjon og fersk regenerering før bug-diagnose

## Bakgrunn

Verifiseringa i `specs/backlog/upstream-linkml-bugrapportar.md` viste at fem
av dei dokumenterte bugsa i `bugs/` hadde feil eller ufullstendig rotårsak:

- BUG-1 og BUG-2 var dokumenterte som LangString- og `inlined_as_list`-feil.
  Den faktiske krasjen skuldast to slots med same `slot_uri`. Dei to er éin feil.
- BUG-3 stod som «hypotese» om manglande `slot_uri`. Den faktiske årsaka er
  eit attributt med same navn som ein global slot.
- BUG-19 vart tilskriven `rdflib_loader` generelt. Feilen gjeld berre ein
  eigendefinert type med `base: str`.
- BUG-20 (gen-doc strippar backticks) var basert på samanlikning av dagens
  kjelde mot `generated/`-output som var eldre enn endringa i kjelda. Feilen
  reproduserer ikkje.

Felles mønster: rotårsaka vart fastsett frå symptom i eit stort domeneskjema,
utan ein isolert reproduksjon, eller mot forelda artefakter. Status `upstream`
vart sett utan at det var stadfesta at feilen ligg i det eksterne biblioteket.

## Steg

1. Avgjer mekanisme og scope (rule, ny fil vs. eksisterande).
2. Skriv rula.
3. Logg avgjerder, avslutt.

## Handlingsliste

- [x] Steg 1 — ny rule-fil, scope `bugs/**` og `BUGS.md` (ingen eksisterande rule dekkjer desse)
- [x] Steg 2 — `.claude/rules/bug-diagnostisering.md`
- [x] Steg 3

## Avgjerder

- **Ny fil i staden for utviding:** ingen eksisterande rule har `bugs/**` eller `BUGS.md` i `paths:`. Innhaldet gjeld heller ikkje eitt enkelt verktøy (LinkML, make, mkdocs), så det passar ikkje inn i `linkml-schema.md` eller `make-conventions.md`.
- **Scope utan `tests/test_make.sh`:** skip-konvensjonen krev alltid ei tilhøyrande bug-fil. Rula lastar difor når bug-fila vert skriven, og vi slepp å laste henne ved alle testendringar.
- **Rule, ikkje CLAUDE.md:** kravet gjeld berre når bugs vert dokumenterte, ikkje ubetinga.

## Utført

- `.claude/rules/bug-diagnostisering.md`: ny rule (scope `bugs/**`, `BUGS.md`) — krav om MRE før stadfesta rotårsak/status `upstream`, fersk regenerering før samanlikning mot artefakter, køyring mot upatcha image, søk i `linkml/linkml`, samanslåing av bugs med same rotårsak.
