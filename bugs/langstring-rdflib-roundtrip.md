# Bug: `LangString`-verdiar vert skrivne som ugyldig RDF og forsvinn stilt ved TTL→YAML

**ID:** BUG-1
**Status:** `upstream`
**Komponent:** `linkml-runtime` (`rdflib_dumper` / `rdflib_loader`)
**Oppdaga:** 2026-06-09 (rotårsak retta 2026-09-26)

## Symptom

Typen `LangString` (`common-ap-no`: `uri: rdf:langString`, `base: str`) vert
skriven til TTL som ein literal med datatype `rdf:langString` **utan**
språktagg:

```turtle
dct:title "My catalog"^^rdf:langString .
```

Dette er ugyldig RDF 1.1 (ein `rdf:langString`-literal krev språktagg). Når
TTL-en vert lesen tilbake, **forsvinn verdien stilt** — ingen feil, ingen
åtvaring. Er sloten `required: true`, kastar Python-klassen
`ValueError: <slot> must be supplied`.

> **Retting 2026-09-26:** Krasjane (`unexpected keyword argument
> 'tittel_literal'` / `'har_anbefalt_term'`) som tidlegare vart tilskrivne
> denne bugen, skuldast delt `slot_uri` — sjå BUG-2
> (`bugs/inlined-as-list-rdflib-roundtrip.md`). Skip-betingelsane for
> `brreg-begrepskatalog` og dei seks modellkatalogskjemaa er flytta dit.

## Berørte skjema

Alle skjema med `LangString`-slots (via `common-ap-no`, `skos-ap-no`,
`dcat-ap-no`, `modelldcat-ap-no` m.fl.) som roundtrippar TTL. Ingen
test-skip refererer i dag til BUG-1: skjemaa som ville vist LangString-tapet,
krasjar først på BUG-2.

LangString-verdiar i YAML ber heller ikkje språktagg per verdi — LinkML har
ingen mekanisme for dette ([linkml/linkml#3548](https://github.com/linkml/linkml/issues/3548)).

## Rot-årsak (stadfesta med minimal reproduksjon)

- `rdflib_dumper.py` lagar `Literal(value, datatype=<type-uri>)` for alle
  typar, også `rdf:langString`, utan språktagg.
- `rdflib_loader.py` (linje 148 på `main @ 5ef7622e`) brukar `v = o.value`,
  som er `None` for den ugyldige literalen. `None`-verdiar vert filtrerte bort.

Minimal reproduksjon (éin klasse, éin `LangString`-slot) i
`specs/backlog/upstream-linkml-bugrapportar.md` § U5. Reprodusert på
`linkml` 1.11.1 og `main @ 5ef7622e`.

## Workaround

**Fjerna `required: true` frå alle LangString-slots** i `skos-ap-no` og
`modelldcat-ap-no` (og deira avhengige domeneskjema). `in_subset: Obligatorisk`
bevarer den semantiske annoteringa som MCP-validatoren brukar til å
handheve kravet.

| Skjema | Klasse | Slot |
|---|---|---|
| `skos-ap-no` | `Begrep` | `anbefalt_term` |
| `skos-ap-no` | `Definisjon` | `tekst` |
| `skos-ap-no` | `Samling` | `tittel` |
| `modelldcat-ap-no` | `Aktoer` | `navn_aktoer` |
| `modelldcat-ap-no` | `Standard` | `tittel` |
| `modelldcat-ap-no` | `Modellkatalog` | `tittel`, `beskrivelse` |
| `modelldcat-ap-no` | `Informasjonsmodell` | `tittel` |
| `modelldcat-ap-no` | `Modellelement` | `tittel` |

## Løysing

Upstream: lastaren skal ikkje droppe verdiar stilt, og dumparen skal ikkje
skrive `^^rdf:langString` utan språktagg. Må meldast i
[linkml/linkml](https://github.com/linkml/linkml/issues) (U5), med
referanse til #3548.

Når upstream-fix er på plass:
1. Verifiser at LangString-verdiar overlever `make roundtrip` for eit
   skjema utan BUG-2-mønsteret.
2. Vurder å leggje `required: true` tilbake på slotane i tabellen over.
3. Oppdater denne fila til `Status: løyst`.
