# Bug (ikkje reproduserbar): LinkML `gen-doc` strippar backticks frå `description`-felt

**ID:** BUG-20
**Status:** `løyst` (ikkje reproduserbar — feildiagnostisert)
**Komponent:** — (opphavleg tilskriven `linkml` docgen)
**Oppdaga:** 2026-08-17 · **Lukka:** 2026-09-26

## Opphavleg symptom

`tema`-sloten i `dcat-ap-no-schema.yaml` har ein backtick-verna
plassholdar-URL (`` `https://psi.norge.no/los/tema/<navn>` ``). Den genererte
sida vart observert utan backticks, og lychee sjekka den trunkerte
`https://psi.norge.no/los/tema/` (404).

## Verifisering 2026-09-26

- Fersk `make gen-schema-docs SCHEMA=src/linkml/ap-no/dcat-ap-no/dcat-ap-no-schema.yaml`
  gir `` (`https://psi.norge.no/los/tema/<navn>`) `` i `tema.md` — backtickane
  er bevarte.
- Vanilla `gen-doc` (`linkml` 1.11.1 og `main @ 5ef7622e`) bevarer òg
  backticks i `description`.
- Backtickane vart lagde til i kjelda i `7e1a2ac7` (2026-08-16). Den
  `generated/`-fila som vart samanlikna, var eldre enn denne endringa, og
  hadde difor heller aldri backticks.

Konklusjon: feilen låg ikkje i LinkML. Samanlikninga var gjort mot forelda
byggartefakter. Sjå `.claude/rules/bug-diagnostisering.md` og
`specs/backlog/upstream-linkml-bugrapportar.md`.

## Opprydding

Lychee-eksklusjonen `"^https://psi\\.norge\\.no/los/tema/$"` i
`.github/lychee.toml` er truleg ikkje lenger naudsynt. Fjern ho og
stadfest med neste lenkjesjekk-køyring i CI.
