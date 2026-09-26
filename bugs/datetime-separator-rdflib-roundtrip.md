# Bug: `rdflib_loader` mistar leksikalsk form for `xsd:dateTime` på eigendefinert type med `base: str`

**ID:** BUG-19
**Status:** `upstream`
**Komponent:** `linkml-runtime` (`linkml_runtime/loaders/rdflib_loader.py`, `v = o.value`)
**Oppdaga:** 2026-08-14 (rotårsak stadfesta 2026-09-26)

## Symptom

`roundtrip-ttl` feilar for `enhetsregisteret-bvrinnfelles` og
`enhetsregisteret-bvrfriv` (førstnemnde heitte `enhetsregisteret-bvrinn` då
feilen vart oppdaga, sjå `specs/done/enhetsregisteret-bvrinn-bvrinnfelles-duplikat.md`):

```
ROUNDTRIP-AVVIK (yaml→ttl→yaml→json):
Forventa: {..., 'innsendingstidspunkt': '2026-07-04T10:30:00', ...}
Fekk:     {..., 'innsendingstidspunkt': '2026-07-04 10:30:00', ...}
```

TTL-en er korrekt (`"2026-07-04T10:30:00"^^xsd:dateTime`). Feilen oppstår i
TTL→YAML.

## Berørte skjema

Skjema der ein slot har range `DateTime` frå `brreg-felles-typer`:

```yaml
DateTime:
  uri: xsd:dateTime
  base: str
```

Stadfesta: `enhetsregisteret-bvrinnfelles`, `enhetsregisteret-bvrfriv` (skip i
`tests/test_make.sh`).

Innebygd `linkml:types`-`datetime` er **ikkje** råka — verifisert med
minimal reproduksjon, der ein `range: datetime`-verdi roundtrippar uendra.
Tidlegare antaking om at `fint-*` (`range: datetime`) potensielt var råka,
er difor truleg feil.

## Rot-årsak (stadfesta med minimal reproduksjon)

`rdflib_loader.py` (linje 148 på `main @ 5ef7622e`) brukar `v = o.value`.
For ein `xsd:dateTime`-literal gir rdflib eit `datetime.datetime`-objekt.
Sidan typen har `base: str`, vert verdien seinare gjort om med `str()`, som
gir mellomrom i staden for `T`. Den opphavlege leksikalske forma (`str(o)`)
går tapt.

Minimal reproduksjon (eigendefinert type `uri: xsd:dateTime`, `base: str`)
i `specs/backlog/upstream-linkml-bugrapportar.md` § U3. Reprodusert på
`linkml` 1.11.1 og `main @ 5ef7622e`. Ingen eksisterande upstream-issue
funnen (2026-09-26).

## Workaround

Skip-betingelse i `roundtrip_ttl_job()`/`test_roundtrip_ttl()` i
`tests/test_make.sh`.

Mogleg intern workaround (ikkje verifisert): definer `DateTime` med
`typeof: datetime` i staden for `base: str`, slik at den innebygde
datetime-handteringa vert brukt. Krev kontroll av genererte artefakter
(Python, JSON Schema, XSD) for alle skjema som importerer `brreg-felles-typer`.

## Løysing

Upstream-fiks: bruk leksikalsk form (`str(o)`) når måltypen har `base: str`.
Må meldast i [linkml/linkml](https://github.com/linkml/linkml/issues) — sjå U3.

Når fiksen (upstream eller intern) er på plass: fjern skip-betingelsen og
oppdater denne fila til `Status: løyst`.
