# Bug: `JavaGenerator` kan ikkje mappe eigendefinerte typar utan `typeof` når URI-en manglar i `TYPEMAP`

**ID:** BUG-25
**Status:** `workaround`
**Komponent:** `linkml` (`linkml/generators/javagen.py::JavaGenerator.map_type`)
**Oppdaga:** 2026-11-06

## Symptom

Etter oppgradering til `linkml` 1.12.1 feila `make domain-samt` og `make domain-referanse` i `gen-java`:

```
TypeDefinition({
  'name': 'LangString',
  'description': 'Språktagget streng (rdf:langString).',
  'from_schema': 'https://data.norge.no/ap-no/common-ap-no',
  'base': 'str',
  'uri': 'rdf:langString'
}) cannot be mapped to a type
```

Råka er `samt-bu` og `referansemodell`, som har `java: true` og transitivt importerer `common-ap-no`.

## Rot-årsak

`common-ap-no-schema.yaml` definerer fire eigne typar med `uri` og `base`, men utan `typeof`:

| Type | `uri` | `base` |
|---|---|---|
| `LangString` | `rdf:langString` | `str` |
| `GYear` | `xsd:gYear` | `str` |
| `Duration` | `xsd:duration` | `str` |
| `NonNegativeInteger` | `xsd:nonNegativeInteger` | `int` |

`JavaGenerator.map_type()` i 1.12.1 slår opp i ein eigen type-map og deretter i den statiske `TYPEMAP`
(berre `xsd:string`, `xsd:integer` o.l.). Etterpå fell han tilbake på `typeof`. Han ser aldri på `base`.
Ingen av dei fire URI-ane står i `TYPEMAP`, og ingen av typane har `typeof`, så generatoren kastar
`ValueError`.

Dette er ein regresjon i 1.12. I 1.11.1 returnerte `map_type()` `None` for ukjende URI-ar, og
`OOCodeGenerator.create_documents()` fall då stille tilbake til typen `string` (`if range is None: range =
self.map_type(sv.all_types().get("string"))`). I 1.12.1 kastar `map_type()` før denne fallbacken vert nådd.
Feilen syner seg i tillegg oftare i 1.12.1, fordi han genererer klassar òg for importerte klassar (47 mot 18
filer for `samt-bu`).

### Minimal reproduksjon

```yaml
id: https://example.org/mre
name: mre
prefixes:
  linkml: https://w3id.org/linkml/
  rdf: http://www.w3.org/1999/02/22-rdf-syntax-ns#
default_prefix: https://example.org/mre/
imports:
- linkml:types
types:
  LangString:
    uri: rdf:langString
    base: str
classes:
  Ting:
    attributes:
      tittel:
        range: LangString
```

`JavaGenerator("mre.yaml").serialize(directory=...)`, køyrt med `--network none` (2026-11-06):

| Image | Resultat |
|---|---|
| `linkml` 1.11.1, utan lokale patchar | OK: `private String tittel;` |
| `linkml` 1.12.1, utan lokale patchar (`mcp-linkml-validator`) | `ValueError: ... cannot be mapped to a type` |
| `linkml` 1.12.1 med `javagen-custom-typemap.patch` (`linkml-local`) | OK: `private String tittel;` |

## Workaround

`src/assets/containers/patches/javagen-custom-typemap.patch` (brukt i `Dockerfile.linkml`, same mekanisme
som `docgen-max-chars.patch`) legg dei fire URI-ane til i `TYPEMAP`:

- `rdf:langString`, `xsd:gYear` og `xsd:duration` vert `String`
- `xsd:nonNegativeInteger` vert `Integer`. Merk: 1.11.1 sin fallback ville gitt `String` her. `Integer` er meir presis og påverkar berre klassar som 1.11.1 ikkje genererte.

Verifisert 2026-11-06:
- `make domain-samt`, `make domain-referanse` og `make domain-ngr` går gjennom.
- Java-felta får gyldige typar (t.d. `List<String> tittel`), og ingen felt har typen `None`.
- Java-filene som fanst i 1.11.1, er uendra bortsett frå `metamodel_version`.

## Løysing

Ikkje meld upstream (per 2026-11-06). Framlegg til upstream-fiks: `map_type()` bør returnere `None` (eller falle tilbake på `base`) i
staden for å kaste, slik at fallbacken til `string` i `OOCodeGenerator` frå 1.11.1 verkar igjen. Ein alternativ lokal fiks er `typeof: string` /
`typeof: integer` på dei fire typane i `common-ap-no`, men det endrar ein publisert AP-NO-profil.
Patchen må verifiserast på nytt ved kvar `linkml`-oppgradering, sidan han bind seg til `TYPEMAP` i
`javagen.py`.

Sjå `specs/done/oppgrader-linkml-1-12-1.md`.
