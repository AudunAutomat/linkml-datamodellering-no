# SchemaView.namespaces() bufrar prefiks før importar er lasta

## Bakgrunn

Etter lenkjesjekk runde 4 (`specs/done/lenkjesjekk-runde4-88-feil-og-unsupported.md`)
stod det att 646 unsupported-lenkjer i CI-køyring `36248679932`. Den nye
`lenkjesjekk-unsupported.md` viste 52 unike CURIE-ar (`dqv:value`,
`adms:status`, `vcard:hasURL`, `odrs:*` m.fl.) brukte rått som lenkjemål,
t.d. `URI: [dqv:value](dqv:value)`, i slot-/klassesidene til dei 6
oreg-skjemaa med versjonslåst URL-import av `dcat-ap-no`
(`enhetsregisteret-{bvrbekreftelse,bvrettersendingavvedlegg,bvrfriv,bvrstiftelsesdokument,frivilligorganisasjonapi}`,
`javazonetalk`). 12 førekomstar per CURIE = 6 skjema × 2 lenkjer per side
(`URI:` + `Slot URI`-rad) i `slot.md.jinja2`/`class.md.jinja2`
(`gen.uri_link(element)`).

**Rotårsak (stadfesta i `localhost/linkml-local`, linkml/linkml-runtime 1.11.1):**
`SchemaView.namespaces()` er dekorert med `@lru_cache(None)` og byggjer
prefiks-kartet frå `self.schema_map`. `SchemaView.load_import()` kallar
`self.namespaces()` (via `map_import`) for kvart import medan
`imports_closure()` framleis fyller `schema_map` — første kall bufrar difor
eit kart med berre rotskjemaet sine prefiks. Etterfølgjande
`expand_curie()`/`get_uri(expand=True)` brukar det bufra kartet og
returnerer CURIE-en uendra når prefikset berre er deklarert i eit importert
skjema (her `dqv-core`/`dcat-ap-no`).

Reproduksjon:

```python
sv = SchemaView("src/linkml/oreg/enhetsregisteret-bvrfriv/enhetsregisteret-bvrfriv-schema.yaml")
sv.imports_closure()
sv.expand_curie("dqv:value")          # → 'dqv:value'
SchemaView.namespaces.cache_clear()
sv.expand_curie("dqv:value")          # → 'http://www.w3.org/ns/dqv#value'
```

Lokale AP-NO-skjema er ikkje råka fordi dei deklarerer prefiksa sjølve.
Feilen er ikkje URL-spesifikk — eitkvart skjema som brukar eit prefiks som
berre er deklarert i eit importert skjema, vert råka.

## Steg

1. [x] Legg `SchemaView.namespaces.cache_clear()` til på slutten av `patched_imports_closure()` i `src/assets/scripts/utils/linkml_relative_import_patch.py` (patchen er allereie aktiv for alle generatorar, batch-script og MCP-validatoren), og dokumenter det i modulkommentaren
2. [x] Opprett `bugs/schemaview-namespaces-cache-importerte-prefiks.md` (BUG-24) og oppdater `BUGS.md` (PoC-liste + indeks)
3. [x] Verifiser: `make gen-schema-docs SCHEMA=src/linkml/oreg/enhetsregisteret-bvrfriv/...` — `URI:`-lenkjer skal vere fullt ekspanderte
4. [x] Regresjonssjekk: generer eit lokalt AP-NO-skjema (`dqv-ap-no`) og kontroller at utdata er uendra; kontroller at andre generatorar (t.d. SHACL) for eit oreg-skjema framleis køyrer
5. [ ] **Attståande (etter push):** CI-lenkjesjekk skal vise unsupported ≈ 0

## Handlingsliste

- [x] `cache_clear()` i patcha `imports_closure()`
- [x] BUG-24-fil + `BUGS.md`
- [x] Verifiser docgen for oreg-skjema
- [x] Regresjonssjekk lokalt AP-NO-skjema + SHACL
- [ ] CI-verifisering etter push

## Avgjerder
- Fiksen vert lagd i den eksisterande patcha `imports_closure()` (BUG-15-patchen) i staden for ein ny patch eller ein docgen-spesifikk fiks: patchen er allereie aktiv på alle køyrevegane som byggjer `SchemaView`, og `cache_clear()` rett etter at closure-en er ferdig lasta treff rotårsaka for alle generatorar (docgen, OWL, SHACL, …), ikkje berre symptomet i docgen. Ingen ny upstream-intern kode vert kopiert.
- Alternativet om å deklarere dei 13 manglande prefiksa i kvart av dei 6 oreg-skjemaa vart forkasta: det ville skjule rotårsaka, bryte DRY (prefiksa er alt deklarerte i dei importerte skjemaa) og måtte gjentakast for kvart nytt skjema med versjonslåst import.
- BUG-24 har status `upstream` (workaround på plass, permanent fiks krev endring i linkml-runtime).
- Regresjonssjekk: TTL samanlikna semantisk (rdflib-isomorfi, `generation_date` fjerna, CURIE-ar i gammalt utdata ekspanderte). SHACL-skilnaden `-121 +121` for bvrfriv er same storleik som mellom to køyringar av `dqv-ap-no` utan kodeendring — kjend ikkje-deterministisk `rdf:List`-rekkjefølgje, ikkje ein effekt av fiksen.

## Utført

- `src/assets/scripts/utils/linkml_relative_import_patch.py`: `SchemaView.namespaces.cache_clear()` på slutten av `patched_imports_closure()`, modulkommentar oppdatert.
- `bugs/schemaview-namespaces-cache-importerte-prefiks.md`: ny (BUG-24). `BUGS.md`: PoC-liste og indeks.
- Verifisert med `make gen-schema-docs`/`gen-owl`/`gen-shacl` for `enhetsregisteret-bvrfriv` og `dqv-ap-no`:
  - bvrfriv docgen: `URI: [dqv:value](http://www.w3.org/ns/dqv#value)`, `URI: [vcard:Kind](http://www.w3.org/2006/vcard/ns#Kind)` — alle endra docs-linjer er `URI:`/`Slot URI`/`Class URI`-linjer.
  - bvrfriv OWL: ugyldige IRI-ar som `<dqvno:validity>` vert no fullt ekspanderte; elles isomorf.
  - `dqv-ap-no`: docs og OWL uendra.

**Attståande etter push:** nattleg/manuell `lenkje-og-mermaid-sjekk` skal vise unsupported ≈ 0 (frå 646). Eventuelle restar er lista i `lenkjesjekk-unsupported.md`.
