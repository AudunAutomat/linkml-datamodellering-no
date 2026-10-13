# Standardetterleving: oppdater etter samanstilling av tre kjelder i policy-sjekklista

## Bakgrunn

`src/mcp-linkml-validator/policies/README.md` stiller no saman tre autoritative kjelder:
Retningslinjer ved tilgjengeliggjøring av offentlige data, Felles modelleringsregler og
FAIR. Sjå `specs/done/gap-policyar-retningslinjer-apne-data.md` og
`specs/done/nye-policy-sjekkar-retningslinjer-g3-g7.md`. Ein kryssjekk av
`mkdocs/docs/arkitektur/standardetterleving{,.en}.md` fann tre stader som ikkje lenger
stemmer med README.

## Steg

1. Rada for retningslinjene (pilar 2): retta tittel («offentlige data») og lagt til
   policy-dekninga (10 av 15 handheva, 2 delvis og 3 prosesskrav) med lenkjer.
2. Rada for Felles modelleringsregler (pilar 3): 14 med automatisk policy-sjekk,
   regel 12 og delar av 14 via informative modellanalysar. Det tidlegare talet
   «11 + 4» var feil.
3. «Sjå også»: Valideringsreglar dekkjer no tre kjelder.
4. Engelsk side tilsvarande, `make translate-stamp`.

## Handlingsliste

- [x] Steg 1
- [x] Steg 2
- [x] Steg 3
- [x] Steg 4

## Avgjerder

- **Rada for Felles modelleringsregler: berre tala er retta.** Tittelen «Felles
  modelleringsregler for offentleg forvaltning» har same nynorsk-tilpassing av eit
  eigennavn (offisielt: «offentlig») som retningslinje-rada hadde. Han er likevel ikkje
  endra, fordi brukaren bad om dei tre punkta frå kryssjekken.
- **Kjeldelenkje til skjemakartlegginga.** Retningslinje-rada lenkjer no òg til
  `specs/done/avvik-retningslinjer-apne-data.md` (RÅ1-RÅ4). Utan lenkja er det uklart
  kva «Skjema: alle 4 tiltak» viser til.

## Utført

- `standardetterleving.md` og `.en.md`: retningslinje-rada (tittel, policy-dekning,
  lenkjer til Valideringsreglar og dei tre specane), talet for Felles modelleringsregler
  (14 automatiske og 1 informativ) og «Sjå også» (tre kjelder).
- `make translate-stamp` for `.en.md`. `make translate-status` viser 0 utdaterte.
