# Utkast til datamodell for enkel bookingteneste

## Bakgrunn

Brukaren ba om eit utkast til ein datamodell for ei enkel bookingteneste. Utkastet vert generert med MCP-verktøyet `linkml-modell-utkast` (`generate_linkml`), som berre tek `json-schema` eller `empty` som input. Utkastet vert vist i svaret og ikkje skrive til `src/linkml/`.

## Avklarte val (frå brukaren)

- Omfang: minimal (Booking, Ressurs, Kunde, Tidsrom + containerklasse)
- Plassering: nytt frittståande domene, berre `linkml:types`, ingen AP-NO-import
- Oppfølging: berre utkast (ingen lint, ingen scaffolding i repoet)

## Steg

1. Skriv JSON Schema for dei fire klassane og containeren (modellspråk: bokmål)
2. Køyr `generate_linkml` med `policy=bronze`
3. Vis det genererte LinkML-utkastet og eventuelle lint-/valideringsfunn
4. Oppsummer avvik frå ønska modell og forslag til neste steg

## Handlingsliste

- [x] Steg 1: JSON Schema
- [x] Steg 2: generate_linkml
- [x] Steg 3: vis utkast og funn
- [x] Steg 4: oppsummering

## Avgjerder

- JSON Schema som inndata fordi verktøyet berre støttar `json-schema` og `empty`.
- `ressurs` og `kunde` på Booking vart skrivne som `string` (identifikator) i JSON Schema, ikkje som nøsta objekt, for å halde lenking fremfor inlining. Verktøyet gjer dei til `range: string`, ikkje klasseref.
- `Tidsrom` vart modellert som eiga klasse (nøsta objekt i JSON Schema) for å halde start/slutt samla.
- Policy `bronze` (einaste andre val er `silver`; bronze er generisk baseline).
- Utkastet vart ikkje skrive til `src/linkml/` og `make lint` vart ikkje køyrd (brukaren valde berre utkast; validator-MCP var ikkje tilkopla).

## Utført

- Generert LinkML-utkast for `bookingtjeneste-schema` (Booking, Ressurs, Kunde, Tidsrom + container) via `generate_linkml`, bronze.
- Verktøyet: lint utan funn, dummy-validering OK, éi åtvaring (subsetta `Obligatorisk`/`Anbefalt` er ikkje definerte utan AP-NO-import).
- Kjende manglar i utkastet (til manuell oppretting): `status` er `string` i staden for enum, `ressurs`/`kunde` er `string` i staden for klasseref, containerattributt-namn er feilbøygde (`kundeer`, `tidsromer`), `Tidsrom` har unødvendig `id` og ligg i containeren, ubrukt slot `bookingtjeneste_schema_kontaktinformasjon`, `TODO`-skildringar og `begrepsidentifikator`, placeholder-prefiks.
