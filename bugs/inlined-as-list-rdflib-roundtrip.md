# Bug: `rdflib_loader` vel feil slot når fleire slots deler same `slot_uri`

**ID:** BUG-2
**Status:** `upstream`
**Komponent:** `linkml-runtime` (`linkml_runtime/loaders/rdflib_loader.py`, `uri_to_slot`)
**Oppdaga:** 2026-06-09 (rotårsak retta 2026-09-26)

> **Merk om filnavnet:** Fila heitte opphavleg «inlined_as_list + identifier»
> fordi rotårsaka først vart feilaktig tilskriven den kombinasjonen. Filnavnet
> er behalde for å ikkje bryte eksisterande lenkjer. Sjå
> `specs/backlog/upstream-linkml-bugrapportar.md` (U1).

## Symptom

TTL→YAML i `rdflib_loader` krasjar med `TypeError` fordi ein slot som ikkje
finst på klassa vert sendt til konstruktøren:

```
TypeError: OffisiellAdresse.__init__() got an unexpected keyword argument 'har_adressekode'
TypeError: Begrep.__init__() got an unexpected keyword argument 'har_anbefalt_term'
TypeError: Modellkatalog.__init__() got an unexpected keyword argument 'tittel_literal'
```

## Berørte skjema / testar

| Skjema | Slots som deler `slot_uri` | Skip i |
|---|---|---|
| `ngr-adresse` | `adressekode_ref` / `har_adressekode` → `ngr:harAdressekode` | `test_roundtrip_ttl` |
| `ngr-eiendom`, `ngr-virksomhet` | same mønster | `test_roundtrip_ttl` |
| `brreg-begrepskatalog` | `anbefalt_term` / `har_anbefalt_term` → `skos:prefLabel` | `test_roundtrip_ttl` |
| `brreg-modellkatalog`, `digdir-modellkatalog`, `novari-modellkatalog`, `ksdigital-modellkatalog`, `skatteetaten-modellkatalog`, `kartverket-modellkatalog` | `tittel` / `tittel_literal` → `dct:title` | `test_roundtrip_ttl` |

Dei sju katalogskjemaa var tidlegare tilskrivne BUG-1 (LangString). Den
faktiske krasjen er denne bugen; LangString-problemet (BUG-1) finst i
tillegg, men krasjar ikkje.

`ngr-*` er òg skippa i `test_convert_rdf` (YAML→TTL) med grunngjeving BUG-2.
Det steget fungerer no for alle tre NGR-skjema (verifisert 2026-09-26 med
`linkml-convert`), så den skippen er truleg forelda og kan fjernast.

## Rot-årsak (stadfesta med minimal reproduksjon)

`rdflib_loader.py` (linje 99 på `main @ 5ef7622e`):

```python
uri_to_slot = {URIRef(schemaview.get_uri(s, expand=True)): s for s in schemaview.all_slots().values()}
```

Oppslagstabellen er nøkla berre på URI, så den **siste** sloten med ein gitt
`slot_uri` vinn globalt. Deretter kallar lastaren
`schemaview.induced_slot(uri_to_slot[p].name, subject_class)` utan å sjekke at
sloten høyrer til subjektklassa. Er det feil slot, får konstruktøren eit ukjent
keyword-argument.

Minimal reproduksjon: to globale slots `title` og `title_literal`, begge
`slot_uri: dct:title`; `Catalog` brukar `title`, `Dataset` brukar
`title_literal` → `Catalog.__init__() got an unexpected keyword argument
'title_literal'`. Full rapport (skjema, data, kommando, framlegg til fiks) i
`specs/backlog/upstream-linkml-bugrapportar.md` § U1.

Kombinasjonen `inlined_as_list` + `identifier: true` er **ikkje** årsaka.

Reprodusert på `linkml` 1.11.1 og `linkml/linkml` `main @ 5ef7622e`
(2026-09-25). Ingen eksisterande upstream-issue funnen (2026-09-26).

## Workaround

Skip i `roundtrip_ttl_job()`/`test_roundtrip_ttl()` i `tests/test_make.sh`
for skjemaa over.

Mogleg intern workaround (ikkje gjennomført): unngå at to slots i same
importgraf deler `slot_uri`. Det krev modelleringsval (t.d. slå saman
`tittel`/`tittel_literal`), og er ikkje alltid ønskjeleg når ein
vokabularterm vert brukt med ulik range i ulike klasser.

## Løysing

Upstream-fiks i `rdflib_loader`: slå opp predikatet blant slotane til
subjektklassa (`class_induced_slots`) i staden for i ein global URI-tabell.
Må meldast i [linkml/linkml](https://github.com/linkml/linkml/issues)
(`linkml-runtime`-repoet er arkivert) — sjå U1.

Når upstream-fix er på plass:
1. Fjern skip-betingelsane frå `tests/test_make.sh`.
2. Verifiser at `make roundtrip` passerer for alle skjemaa over.
3. Oppdater denne fila til `Status: løyst`.
