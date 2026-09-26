# Bug: `rdflib_loader` kastar `MappingError` når eit attributt har same navn som ein global slot

**ID:** BUG-3
**Status:** `upstream`
**Komponent:** `linkml-runtime` (`linkml_runtime/loaders/rdflib_loader.py`, `uri_to_slot`)
**Oppdaga:** 2026-06-09 (rotårsak stadfesta 2026-09-26)

## Symptom

`ttl→yaml`-steget i TTL-roundtrip feilar med:

```
linkml_runtime.MappingError: No pred for https://data.norge.no/fint/fint-administrasjon/arbeidsforhold <class 'rdflib.term.URIRef'>
linkml_runtime.MappingError: No pred for https://data.norge.no/samt/samt-bu/id <class 'rdflib.term.URIRef'>
```

## Berørte skjema / testar

| Skjema | Attributt i containeren | Global slot med same navn | Test |
|---|---|---|---|
| `fint-administrasjon` | `AdministrasjonContainer.arbeidsforhold` | `arbeidsforhold` (`slot_uri: adm:arbeidsforhold`) | `test_roundtrip_ttl` (FEIL) |
| `fint-okonomi`, `fint-personvern`, `fint-utdanning` | same mønster | | `test_roundtrip_ttl` (FEIL) |
| `samt-bu` | `SamtBuContainer.id` | `id` (frå `common-ap-no`) | `test_roundtrip_ttl` (FEIL) |

Desse skjemaa er ikkje i skip-lista — dei køyrer og feilar.

## Rot-årsak (stadfesta med minimal reproduksjon)

Dumparen og lastaren løyser slot-URI ulikt:

- `RDFLibDumper` brukar `induced_slot(navn, klasse)`, altså **attributtet**
  sin URI. Utan `slot_uri` vert det `default_prefix` + navn (t.d.
  `fint-administrasjon:arbeidsforhold`).
- `RDFLibLoader` byggjer predikattabellen frå `schemaview.all_slots()`
  (`rdflib_loader.py` linje 99 på `main @ 5ef7622e`). Den er nøkla på
  **navn**, og den globale sloten vinn. Attributtet sin URI finst difor ikkje
  i tabellen.

```python
sv.get_uri(sv.all_slots()['items'], expand=True)                # https://example.org/other/items
sv.get_uri(sv.induced_slot('items', 'Container'), expand=True)  # https://example.org/b03/items
```

Minimal reproduksjon i `specs/backlog/upstream-linkml-bugrapportar.md` § U2.
Reprodusert på `linkml` 1.11.1 og `main @ 5ef7622e`. Ingen eksisterande
upstream-issue funnen (2026-09-26).

Den tidlegare hypotesen (manglande `slot_uri` på vanlege slots) var feil.
`fint-arkiv` og `fint-ressurs` passerer fordi containerattributta deira ikkje
kolliderer med globale slotnavn.

## Workaround

Ingen aktiv workaround. Moglege interne tiltak (ikkje gjennomførte):

- Gi containerattributtet eit navn som ikkje kolliderer med ein global slot
  (t.d. `arbeidsforholdliste`). Endrar serialiseringsformatet.
- Gi containerattributtet eksplisitt `slot_uri` lik den globale sloten sin.
  Bryt regelen om at containerattributt ikkje har `slot_uri`
  (`.claude/rules/linkml-schema.md` § Containerklasse).

## Løysing

Upstream-fiks i `rdflib_loader`: slå opp predikat via `induced_slot` per
subjektklasse, same som dumparen. Truleg same fiks som BUG-2 (U1). Må
meldast i [linkml/linkml](https://github.com/linkml/linkml/issues) — sjå U2.

Når upstream-fix er på plass: verifiser `make roundtrip` for skjemaa over og
oppdater denne fila til `Status: løyst`.
