# Bug: `SchemaView.namespaces()` bufrar prefiks-kartet før importane er lasta

**ID:** BUG-24
**Status:** `upstream`
**Komponent:** `linkml-runtime` (`linkml_runtime/utils/schemaview.py::SchemaView.namespaces` / `load_import`)
**Oppdaga:** 2026-09-26

## Symptom

`gen-doc` renderer URI-lenkjer på slot-/klassesider som rå CURIE-ar, t.d.
`URI: [dqv:value](dqv:value)`, i staden for
`URI: [dqv:value](http://www.w3.org/ns/dqv#value)`. Lychee rapporterer desse
som *unsupported* (`URL is missing a hostname`). Lenkjene er døde i den
publiserte portalen. OWL-generatoren skriv på same måte ugyldige IRI-ar som
`<dqvno:validity>`.

Stadfesta for dei 6 oreg-skjemaa med versjonslåst URL-import av
`dcat-ap-no` (52 unike CURIE-ar, 624+ førekomstar i CI-køyring
`36248679932`) — prefiksa (`dqv`, `dqvno`, `oa`, `adms`, `vcard`, `odrs`,
`cv`, `spdx`, `prov`, `time`, `eli`, `dcatap`, `odrl`) er berre deklarerte i
dei importerte `dqv-core`/`dcat-ap-no`/`common-ap-no`-skjemaa.

## Rot-årsak

`SchemaView.namespaces()` er dekorert med `@lru_cache(None)` og byggjer
kartet frå `self.schema_map`. `SchemaView.load_import()` kallar
`self.namespaces()` (via `map_import`) for kvart import **medan**
`imports_closure()` framleis fyller `schema_map`. Første kall bufrar difor
eit kart med berre rotskjemaet sine prefiks, og alle seinare
`expand_curie()`/`get_uri(expand=True)`-kall brukar det ufullstendige kartet.
Docstringen til `namespaces()` nemner at resultatet «will differ, depending
on whether any functions that process imports have been run», men cachen
vert aldri invalidert når importane er lasta.

Ikkje URL-spesifikk: eitkvart skjema som brukar eit prefiks som berre er
deklarert i eit importert skjema, vert råka. Lokale AP-NO-skjema slepp fordi
dei deklarerer prefiksa sjølve.

Reproduksjon (i `localhost/linkml-local`, linkml/linkml-runtime 1.11.1):

```python
sv = SchemaView("src/linkml/oreg/enhetsregisteret-bvrfriv/enhetsregisteret-bvrfriv-schema.yaml")
sv.imports_closure()
sv.expand_curie("dqv:value")          # → 'dqv:value'
SchemaView.namespaces.cache_clear()
sv.expand_curie("dqv:value")          # → 'http://www.w3.org/ns/dqv#value'
```

## Workaround

Den patcha `imports_closure()` i
`src/assets/scripts/utils/linkml_relative_import_patch.py` (BUG-15) kallar
`SchemaView.namespaces.cache_clear()` etter at closure-en er lasta. Patchen
er allereie aktiv på alle køyrevegane som byggjer `SchemaView` (sjå liste i
`bugs/relativ-import-via-versjonslast-url.md`), inkludert `batch-generate.py`
(`gen-schema-docs`/`gen-owl`/`gen-shacl` m.fl.).

Verifisert: docgen-lenkjer vert fullt ekspanderte; OWL for
`enhetsregisteret-bvrfriv` er isomorf med før når CURIE-ane i gammalt
utdata vert ekspanderte; SHACL skil seg berre i den kjende, ikkje-deterministiske
`rdf:List`-rekkjefølgja; `dqv-ap-no` (lokale prefiks) er uendra.

Same avgrensing som BUG-15: `make validate-instance` kallar `linkml validate`
direkte og har ikkje patchen.

## Løysing

Bør meldast til [linkml/linkml-runtime](https://github.com/linkml/linkml-runtime):
`namespaces()`-cachen bør invaliderast når `schema_map` endrar seg (eller
`load_import()` bør ikkje bruke den cacha metoden). Når upstream er fiksa,
kan `cache_clear()`-linja fjernast frå patchen.

Sjå `specs/done/schemaview-namespaces-cache-importerte-prefiks.md`.
