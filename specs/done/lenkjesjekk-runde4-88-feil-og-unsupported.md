# Lenkjesjekk runde 4 — 88 feil og 666 unsupported

## Bakgrunn

`lenkjesjekk`-jobben i `.github/workflows/lenkje-og-mermaid-sjekk.yml`
(køyring `36238240378`, 2026-09-26) rapporterte:

| Status | Tal |
|---|---|
| Total | 119 555 |
| Unique | 12 199 |
| Errors | **88** |
| Unsupported | **666** |

Mermaid-render (53 diagram, 0 feil) og mermaid click-href-sjekken (7591
sider, 0 feil) er grøne — alle funn gjeld lychee-jobben.

Brukaren bad om (1) gjennomgang av alle 88 feila med forslag til løysing og
(2) vurdering av om dei 666 unsupported-lenkjene kan rapporterast/loggast.
Specen vart først skriven som kartlegging; tiltaka vart deretter utførte etter brukaravgjerd på O1/O2 (sjå `## Utført`).

Metode: lychee-rapporten vart lasta ned som artefakt (`lenkjesjekk-report`),
kvar feil vart kategorisert og verifisert manuelt (curl, `gh api` mot
taggar/repo), og lychee 0.24.2 vart køyrd lokalt (feilsøking, direkte
`podman run` — jf. unntaket i CLAUDE.md) for å finne ut korleis unsupported
vert handsama.

## Kategori A — 78 feil: CHANGELOG compare-lenkjer til `brreg/`-repoet

**Førekomstar:** 26 unike URL-ar × 3 kopiar (`src/linkml/**/CHANGELOG.md`,
`mkdocs/docs/**/CHANGELOG.md`, `mkdocs/docs/**/index.md`) — dcat-ap-no,
dqv-ap-no, modelldcat-ap-no, skos-ap-no, enhetsregisteret-bvrinnfelles,
referansemodell{,-bronze,-silver,-gold}.

**Rotårsak (to lag):**

1. **Eksklusjonen dekkjer berre éin eigar.** `.github/lychee.toml` ekskluderer
   `^https://github\.com/AudunAutomat/linkml-datamodellering-no/compare/`
   (kategori G i `specs/done/lenkjesjekk-runde2-verifisering.md`). Alle
   CHANGELOG-oppføringar før 2026-09-26 peikar derimot til
   `github.com/brreg/linkml-datamodellering-no/compare/...` (repoet vart
   flytta; nyaste oppføring, t.d. dcat-ap-no 2.14.3, brukar `AudunAutomat/`).
   `brreg/linkml-datamodellering-no` er eit **separat** repo (id 1222198005,
   ikkje fork, ikkje redirect) som framleis eksisterer — difor passerer dei
   fleste brreg-compare-lenkjene, og berre dei med manglande taggar feilar.
2. **19 release-taggar manglar i begge repoa** (verifisert via `gh api
   .../tags` mot både `brreg/` og `AudunAutomat/` — identisk resultat):

   ```
   dcat-ap-no-v2.7.0            dcat-ap-no-v2.9.0
   dqv-ap-no-v1.8.0             dqv-ap-no-v1.9.0         dqv-ap-no-v1.11.0
   enhetsregisteret-bvrinnfelles-v1.1.2
   modelldcat-ap-no-v1.7.0      modelldcat-ap-no-v1.8.0  modelldcat-ap-no-v1.9.0
   referansemodell-v1.3.0       referansemodell-bronze-v1.0.0
   referansemodell-silver-v1.0.0 referansemodell-gold-v1.0.0
   skos-ap-no-v2.7.0  skos-ap-no-v2.8.0  skos-ap-no-v2.9.0
   skos-ap-no-v2.10.0 skos-ap-no-v2.11.0 skos-ap-no-v2.13.0
   ```

   Dette er den same tag-gap-feilen som runde 2 kategori G noterte som
   «ope for seinare» (release-please laga CHANGELOG-oppføring utan tag,
   typisk ved fleire releasar same dag, t.d. dcat-ap-no 2.6.0/2.7.0/2.8.0
   alle 2026-07-09).

**Løysingsalternativ:**

| # | Tiltak | Effekt | Merknad |
|---|---|---|---|
| A1 | Utvid eksklusjonen i `lychee.toml` til `^https://github\.com/(AudunAutomat\|brreg)/linkml-datamodellering-no/compare/` | Fjernar alle 78 | Minimalt, konsistent med runde 2-avgjerda. Lenkjene er framleis brotne for lesaren. |
| A2 | Opprett dei 19 manglande taggane i ettertid (på release-commiten som sette versjonen) | Lenkjene vert gyldige i `AudunAutomat/` | Git-operasjon — **brukaren** må gjere det. Krev at rett commit per versjon vert identifisert (t.d. `git log -S'"<versjon>"' -- .github/release-please-manifest.json`). Treff berre dersom lenkjene òg peikar til `AudunAutomat/` (sjå A3). |
| A3 | Skriv om `github.com/brreg/linkml-datamodellering-no/compare/` → `AudunAutomat/` i alle `src/linkml/**/CHANGELOG.md` | Éin eigar for alle compare-lenkjer | Røyrer historiske CHANGELOG-oppføringar (release-please les berre toppen, så ufarleg teknisk). Gir ingen effekt åleine — taggane manglar i begge repoa. |

**Avgjort (O1):** berre A1. A2+A3 vert ikkje utførte.

## Kategori B — 5 feil: GitHub Discussions er ikkje slått på

**Førekomstar:** `CONTRIBUTING.md` linje 218, 245, 272; `README.md` linje 55
(→ `mkdocs/docs/index.md` linje 55 via `publish.sh`).

**Rotårsak:** `gh repo view` gir `hasDiscussionsEnabled: false` —
`https://github.com/AudunAutomat/linkml-datamodellering-no/discussions`
er 404. Reell feil (også for lesarar).

**Løysingsalternativ:**

| # | Tiltak | Merknad |
|---|---|---|
| B1 | Slå på Discussions i repo-innstillingane (Settings → General → Features) | Brukaren si avgjerd/handling; ingen kodeendring. Lenkjene vert gyldige. |
| B2 | Erstatt Discussions-lenkjene med Issues (`.../issues`) og juster teksten | 4 kjeldestadar (`CONTRIBUTING.md` ×3, `README.md` ×1). README-teksten skil i dag eksplisitt mellom Discussions og Issues — må omformulerast. |

**Avgjort (O2):** B1 — brukaren har slått på Discussions. Dei 5 feila
forsvinn ved neste køyring utan kodeendring.

## Kategori C — 5 feil: utdaterte digdir.no-lenkjer

**Førekomst:** `mkdocs/docs/arkitektur/standardetterleving.md` (statisk,
git-sporta side — rett direkte der). Ingen andre kjeldefiler (utanom
`specs/done/`) har desse URL-ane.

**Rotårsak:** Ikkje bot-blokkering. Digdir har flytta innhaldet; dei gamle
node-ID-ane redirectar no (302) til **urelaterte** sider som sjølve gir 403
(t.d. `.../beskrivelse-av-kvalitet-pa-datasett/2570` →
`/klart-sprak/dialogmote-klart-sprak-i-digitale-tjenester/2570`), eller
404 direkte.

**Tiltak (alle erstatningar verifiserte 200 + rett `<title>`):**

| Linje | Gammal URL | Ny URL |
|---|---|---|
| 27 | `https://www.digdir.no/informasjonsforvaltning/tilgjengeliggjore-apne-data/2721` (404) | `https://fellesdatakatalog.digdir.no/guide/veileder-apne-data` |
| 28 | `https://www.digdir.no/informasjonsforvaltning/beskrivelse-av-kvalitet-pa-datasett/2570` (403) | `https://fellesdatakatalog.digdir.no/specification/spesifikasjon-for-beskrivelse-av-kvalitet-pa-datasett` |
| 30 | `https://www.digdir.no/informasjonsforvaltning/veileder-informasjonsmodeller/2571` (403) | `https://fellesdatakatalog.digdir.no/guide/veileder-modelldcat-ap-no` |
| 39 | `https://www.digdir.no/informasjonsforvaltning/termlosen/2020` (403) | `https://www.digdir.no/standarder/termlosen/1733` |
| 45 | `https://www.digdir.no/informasjonsforvaltning/los/2136` (403) | `https://www.digdir.no/informasjonsforvaltning/los-felles-vokabular-klassifisering-av-offentlige-tjenester-og-ressurser/2434` |

Merk: linje 28 var ein «veileder» (Pilar 1), men Digdir publiserer no
kvalitetsbeskrivinga som *spesifikasjon* på fellesdatakatalog — lenkjeteksten
kan stå, sidan det er same ressurs. Termlosen finst òg på
`fellesdatakatalog.digdir.no/specification/termlosen` (200); digdir.no-varianten
er vald for å halde same vert som resten av tabellen.

## Kategori D — 666 unsupported

### Kva «unsupported» er i lychee 0.24.2

Frå kjeldekoden (`lychee-lib/src/types/status.rs`, tag `lychee-v0.24.2`):
`Status::Unsupported` vert sett ved `ErrorKind::InvalidUrlHost` (URL utan
vertsnavn, t.d. ein CURIE som `rdf:type`), reqwest *builder*-feil og
*body/decode*-feil. Dei vert **talde**, men 0.24.2 har ingen
`unsupported_map` — difor står dei berre som eit tal i Summary, aldri
lista per fil. (`unsupported_map` + listing i summary finst på `master`/
`nightly`, ikkje i nokon release enno.) Lychee-cachen lagrar ikkje
unsupported (`cache.rs`), så cachen påverkar ikkje talet.

### Kva dei er (hypotese, delvis verifisert)

Lokal fullkøyring (lokal `mkdocs/docs/` frå 2026-08-11 — ikkje identisk
med CI) gav **16** unsupported, alle same URL:

```
[IGNORED] rdf:langString (at 210:16) | Unsupported: URL is missing a hostname
```

Kjelde: Types-tabellen i `src/assets/templates/docgen/index.md.jinja2`
(linje 289-303). For typar med `uri` som ikkje startar med `xsd:` vert
CURIE-en brukt rått som lenkjemål:

```jinja
{%- elif t.uri -%}
{%- set uri_text = t.uri -%}
{%- set uri_link = t.uri -%}   {# → [rdf:langString](rdf:langString) #}
```

`LangString` (`uri: rdf:langString`, `common-ap-no-schema.yaml`) vert
arva av alle skjema som importerer AP-NO-profilane, så i ein fersk CI-bygg
dukkar raden opp i mange fleire `index.md`/`klasser/index.md` enn lokalt.
At **alle** 666 kjem herifrå er **ikkje verifisert** — det krev lista frå
CI (sjå D1).

### Tiltak

| # | Tiltak | Merknad |
|---|---|---|
| D1 | **Logg unsupported i CI:** køyr lychee med `-v` og send stderr til fil (ikkje jobbloggen — ~120k liner), grep `^\[IGNORED\]` til `lenkjesjekk-unsupported.md`, legg ei gruppert oppsummering (`sort \| uniq -c` etter URL, utan `(at …)`) i Step Summary og last opp fila i `lenkjesjekk-report`-artefakten. | Verifisert lokalt at `-v` skriv `[IGNORED] <url> (at L:C) \| Unsupported: <grunn>` per førekomst. Ingen versjonsbyte. Oppfyller «Ingen stille feil». Actionlint etter endring. |
| D2 | Rett kjelda: ekspander CURIE til full URI i Types-tabellen, t.d. `{%- set uri_link = schemaview.expand_curie(t.uri) -%}` | Gir `http://www.w3.org/1999/02/22-rdf-syntax-ns#langString` (same URI som `klasser/langstring.md` allereie brukar). Rett for lesaren òg — lenkja er i dag død i portalen. Regenerer docs og kontroller. |
| D3 | (Alternativ til D1) bytt til `lycheeverse/lychee:nightly` for innebygd `unsupported_map` | **Ikkje tilrådd** — nightly er ustabil og bryt versjonslåsing; vent heller på neste release og fjern D1-grep-en då. |

**Tilråding:** D1 først (gir faktisk liste frå CI), deretter D2. Etter D2
skal neste nattlege køyring vise om talet går mot 0; restar vert
kategoriserte frå D1-rapporten.

## Steg

1. [x] Avklar O1 (kategori A) og O2 (kategori B) med brukaren
2. [x] Kategori A: utvid compare-eksklusjonen i `.github/lychee.toml` (A1), oppdater kommentaren med referanse til denne specen
3. [x] Kategori B: B1 utført av brukaren — Discussions slått på (`hasDiscussionsEnabled: true`, `/discussions` gir 200, verifisert 2026-09-26). Ingen kodeendring.
4. [x] Kategori C: byt ut dei 5 digdir-URL-ane i `mkdocs/docs/arkitektur/standardetterleving.md`
5. [x] Kategori D1: `-v` + unsupported-rapport i `lenkjesjekk`-steget i `lenkje-og-mermaid-sjekk.yml`; køyr `actionlint`
6. [x] Kategori D2: `expand_curie` i `src/assets/templates/docgen/index.md.jinja2`; `make gen-doc` for eitt AP-NO-skjema og kontroller Types-tabellen
7. [x] Køyr `lenkje-og-mermaid-sjekk` (workflow_dispatch) etter push og kontroller: Errors ≈ 0, unsupported-lista er tilgjengeleg, talet redusert
8. [x] ~~Vurder eiga oppfølgingsspec for A2+A3~~ — forkasta (O1: berre A1)

## Handlingsliste

- [x] A1 — lychee-eksklusjon for `brreg/`-compare-lenkjer
- [x] B — Discussions aktivert av brukaren (B1)
- [x] C — 5 digdir-URL-ar i `standardetterleving.md`
- [x] D1 — logg unsupported-lenkjer i CI (Step Summary + artefakt)
- [x] D2 — ekspander CURIE i Types-tabellen i `index.md.jinja2`
- [x] Verifiser i CI (køyring `36248679932`)

## Opne spørsmål

- ~~**O1:** Kategori A — berre A1, eller òg A2+A3?~~ → **Berre A1** (brukaravgjerd 2026-09-26).
- ~~**O2:** Kategori B — B1 eller B2?~~ → **B1**: brukaren har slått på GitHub Discussions.

## Avgjerder

- Lokal lychee-køyring vart gjort med direkte `podman run` (ikkje make-target) — det finst ikkje noko make-target for lychee, og dette var feilsøking (unntaket i CLAUDE.md). Cache slått av i ein kopi av `lychee.toml` for å få ferske statusar.
- Lokale feil som ikkje finst i CI-rapporten (t.d. `Empty URL`, regex-mønster som `.../file-type/[A-Z_]+$`) er ikkje tekne med — lokal `mkdocs/docs/` er frå 2026-08-11 og ikkje representativ. Specen byggjer berre på CI-rapporten for dei 88 feila.
- Kategori C vert retta direkte i `mkdocs/docs/arkitektur/standardetterleving.md`, sidan fila er statisk og git-sporta (ikkje generert av `publish.sh`).
- O1 (brukar): kategori A løysast berre med A1 (utvida lychee-eksklusjon). Dei 19 manglande taggane vert ikkje oppretta, og CHANGELOG-lenkjene vert ikkje skrivne om.
- O2 (brukar): GitHub Discussions er slått på (B1), verifisert med `gh repo view` og HTTP 200. Kategori B krev ingen kodeendring.
- D1: lychee-linjene har berre `(at L:C)`, ikkje filnavn. Rapporten grupperer difor per URL og finn inntil 3 eksempelfiler med `grep -rlF "](<url>)"` (lenkjemål, ikkje prosa — første versjon trefte prosa-omtalar i `.claude/rules/` og `bugs/`). Avgrensa til 50 unike URL-ar for å halde Step Summary liten. Eige steg med `if: always()`, så rapporten kjem òg om lychee-steget feilar; manglande verbose-logg gir `::warning::` (ingen stille feil).
- D1: verbose-loggen (`lenkjesjekk-verbose.log`) vert ikkje lasta opp som artefakt — berre den grupperte `lenkjesjekk-unsupported.md` (lagt til i `lenkjesjekk-report`-artefakten). Dei andre verbose-linjene (EXCLUDED/ERROR) finst allereie i rapporten eller er uinteressante.
- D2: `schemaview.expand_curie()` i staden for eigen prefiks-logikk — same SchemaView-objekt som malen allereie brukar (`schemaview.get_type`). CURIE-ar med ukjent prefiks vert returnerte uendra (same åtferd som før).

## Utført

- **A1:** `.github/lychee.toml` — compare-eksklusjonen dekkjer no `(AudunAutomat|brreg)`, kommentar utvida med referanse hit.
- **B1:** utført av brukaren (Discussions aktivert, verifisert 200).
- **C:** `mkdocs/docs/arkitektur/standardetterleving.md` — 5 digdir-URL-ar bytte; `git grep` stadfestar ingen attverande førekomstar utanom `specs/`.
- **D1:** `.github/workflows/lenkje-og-mermaid-sjekk.yml` — lychee med `--verbose` (stderr → `lenkjesjekk-verbose.log`), nytt steg «Rapporter unsupported-lenkjer» skriv `lenkjesjekk-unsupported.md` til Step Summary og artefakt. Steg-skriptet er testa lokalt mot verbose-logg frå lokal fullkøyring (16 × `rdf:langString` med rette eksempelfiler). `actionlint`: ingen nye funn (berre eksisterande SC2034 på linje 170, mermaid-steget).
- **D2:** `src/assets/templates/docgen/index.md.jinja2` — Types-tabellen ekspanderer CURIE. Verifisert med `make gen-schema-docs SCHEMA=src/linkml/ap-no/common-ap-no/common-ap-no-schema.yaml`: `[rdf:langString](http://www.w3.org/1999/02/22-rdf-syntax-ns#langString)`.

**Attståande etter push:** køyr `lenkje-og-mermaid-sjekk` (workflow_dispatch). Forventa: Errors 88 → ~0 (A1 fjernar 78, B1 5, C 5), unsupported-talet redusert frå 666, og `lenkjesjekk-unsupported.md` viser kva som eventuelt står att. Dersom unsupported ikkje går mot 0, kategoriser restane frå den nye rapporten i ein ny spec.

**CI-verifisering (køyring `36248679932`, commit `87f3b807`):** Errors 88 → **0**.
Unsupported 666 → **646** (alle `rdf:langString` borte). Den nye
`lenkjesjekk-unsupported.md` viser at restane er 52 unike CURIE-ar
(`dqv:`, `adms:`, `vcard:`, `odrs:` m.fl.) som `gen.uri_link()` i slot- og
klassesidene til dei 6 oreg-skjemaa med versjonslåst URL-import av
`dcat-ap-no` ikkje ekspanderer. Rotårsak (stadfesta i `linkml-local`,
linkml-runtime 1.11.1): `SchemaView.namespaces()` er `@lru_cache`-a og vert
kalla av `load_import()` før importane er lasta, så berre prefiksa i
rotskjemaet vert bufra. `SchemaView.namespaces.cache_clear()` etter
`imports_closure()` gir rett ekspansjon. Dette vert følgt opp i ein eigen spec.
