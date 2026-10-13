# LinkML-konformitet og beste praksis som fjerde, teknisk kjelde i policy-sjekklista

**Dato:** 2026-10-13
**Status:** Utført 2026-10-13.
**Bygger på:** `specs/done/gap-policyar-retningslinjer-apne-data.md` (tre normative
kjelder med `retningslinje`/`digdir_rule`/`fair_principle` i YAML),
`specs/done/gjennomgang-bronze-policy-generisk.md` (bronze som generisk LinkML-baseline).

---

## Bakgrunn

`src/mcp-linkml-validator/policies/README.md` stiller saman tre **normative** kjelder:
Retningslinjer ved tilgjengeliggjøring av offentlige data, Felles modelleringsregler og
FAIR. Bronze er definert som ein «generisk LinkML-baseline». Fleire av sjekkane der har
likevel sitt eigentlege grunnlag i LinkML og ikkje i nokon av dei tre kjeldene:

| Sjekk (bronze) | Kopling i dag | Eigentleg grunnlag |
|---|---|---|
| `schema.id`, `schema.name` påkravd (`required:`) | Digdir 4 / 1 | LinkML-metamodellen: `id` og `name` er påkravde på `SchemaDefinition` |
| `default_prefix_is_absolute_uri` | Digdir 4 | LinkML si prefiksekspansjon: `default_prefix` må ekspandere til ein brukbar URI-base |
| LinkML-linter, `recommended` (inkl. metamodell-validering) | Digdir 8 | LinkML [Schema Linter](https://linkml.io/linkml/schemas/linter.html) |
| `standard_naming` | Digdir 3 | Linter-regelen `standard_naming` (LinkML-konvensjon) — overlappar med Digdir 3 |
| `no_inlined_on_primitive_range` | Digdir 8, FAIR I1 | LinkML-semantikk: `inlined`/`inlined_as_list` har berre verknad når range er ein klasse |
| `local_types_have_standard_uri` | Digdir 15, FAIR I1 | LinkML-typesystemet: `types:` skal ha `uri` — overlappar med Digdir 15 |
| Klasse-/slot-`description` (`recommended:`) | Digdir 1 | LinkML-praksis (linter-regelen `recommended` sjekkar same felt, men er slått av i bronze for å unngå dobbeltsignal) |

Når LinkML ikkje står oppført som kjelde, blir dette uklart på to måtar. For det første
er nokre Digdir-koplingar tynne (særleg regel 8 for linteren). For det andre står det
berre i prosa kvifor bronze skal vere generisk og basis-no norsk.

### Avgrensingar

- **Teknisk, ikkje normativ.** LinkML er verktøyet si eiga konformitet og konvensjon.
  Han skal ikkje likestillast med dei tre normative kjeldene, men stå som
  «éi teknisk kjelde».
- **Ikkje eitt samla dokument for beste praksis.** LinkML har inga samla side for
  beste praksis. Det som kan siterast, er (1) metamodellen, (2) Schema Linter med
  regelnavn og (3) `personinfo`-tutorialen, som alt er regresjonsvern for bronze
  (`tests/fixtures/bronze-generisk-personinfo-fixture.yaml`). Ein generell
  «beste praksis»-referanse skal ikkje brukast.
- **Regelsettet er versjonsavhengig.** `Dockerfile.mcp-linkml` installerer
  `linkml>=1.11.1,<2.0.0`. Kva `extends: recommended` inneheld, avheng av installert
  versjon. README nemner i dag `no_undeclared_slots`, `no_undeclared_ranges`,
  `one_identifier_per_class` og `no_invalid_slot_usage` (frå
  `specs/done/gjennomgang-bronze-policy-generisk.md`, B23). Ei oppsummering av
  linter-sida på linkml.io lista andre regelnavn. Den faktiske lista må hentast
  frå koden i containeren.

---

## Steg

1. **Kartlegg regelsettet `recommended` i containeren.** Les `recommended.yaml` og
   `default.yaml` frå `linkml.linter` i `mcp-linkml-validator`-imaget (installert
   versjon) og noter regelnavn, nivå og LinkML-versjon. Dette er feilsøking, så
   direkte `podman run` er greitt etter unntaket i CLAUDE.md. Vurder om ein
   make-target (t.d. `mcp-linkml-linter-reglar`) er verdt det. Viss ja, må han ha
   eiga grunngjeving.
2. **Kjeldenøkkel i YAML.** Innfør `linkml:` som kjeldemetadata på bronze-sjekkane (og
   på arva/oppgraderte kopiar i gold), med kontrollerte verdiar:
   - `metamodell` — krav som følgjer av LinkML-metamodellen
   - `linter:<regelnavn>` — ein navngjeven linter-regel
   - `semantikk` — LinkML-semantikk (t.d. `inlined` berre for klasse-range)
   - `praksis` — konvensjon dokumentert i tutorial/rettleiing (berre med konkret tilvising)

   `required:`/`recommended:`-felta har ingen `checks:`-oppføring. Kjelda for dei
   blir difor ført manuelt i README, same mønster som for retningslinje-kolonna.
3. **README: kjeldetabell.** Utvid innleiinga til «tre normative kjelder og éi
   teknisk». Den tekniske kjelda er LinkML (metamodell, Schema Linter og
   `personinfo`-tutorial), med versjonsintervallet frå `Dockerfile.mcp-linkml`.
4. **README: ny underseksjon «LinkML-konformitet»** under «Dekningsgrad per kjelde».
   Han skal vise kvar bronze-sjekk med `linkml:`-kopling, og linter-reglane frå
   steg 1 med nivå (aktiv, slått av og kvifor). Sjekktabellane får **ikkje** ei ny
   kolonne, fordi dei alt har sju og LinkML-sjekkane nesten berre ligg i bronze.
5. **README: kryssreferanse.** Legg til kolonna «LinkML» i kryssreferansetabellen, og
   eventuelt ei ny rad «LinkML-strukturell gyldigheit» (metamodell, deklarerte
   slots/range).
6. **Vurder dei tynne Digdir-koplingane.** Til dømes linter → Digdir 8 og
   `default_prefix_is_absolute_uri` → Digdir 4. Behald koplinga der ho er reell, og
   fjern ho der LinkML er det einaste grunnlaget. Kvar endring skal loggast i
   `## Avgjerder`.
7. **Koherenstest.** Utvid `TestPolicyKoherens`: `linkml:`-verdiar skal vere ein av
   dei kontrollerte typane, og `linter:<regel>` skal finnast i linter-konfigen til
   den merga policyen.
8. **Engelsk versjon og andre stader.** `policies/README.en.md`, `make translate-stamp`.
   Sjekk om `standardetterleving{,.en}.md` («Sjå også») og CLAUDE.md § «Policy-hierarki»
   bør nemne den tekniske kjelda.
9. **Testar:** `make mcp-linkml-valider-modell-test`.

---

## Handlingsliste

- [x] Steg 1: regelsettet `recommended` kartlagt (versjon og regelnavn)
- [x] Steg 2: `linkml:`-nøkkel i bronze/gold
- [x] Steg 3: kjeldetabell utvida
- [x] Steg 4: underseksjon «LinkML-konformitet»
- [x] Steg 5: kryssreferanse med LinkML-kolonne
- [x] Steg 6: tynne Digdir-koplingar vurderte
- [x] Steg 7: koherenstest
- [x] Steg 8: README.en, standardetterleving, CLAUDE.md
- [x] Steg 9: testar

---

## Avklaringar før utføring

- **A1 — Navn på nøkkelen (svar: `linkml:`):** `linkml:` eller noko meir eksplisitt, t.d. `linkml_kjelde:`?
- **A2 — Steg 6 (svar: fjern tynne koplingar):** Skal tynne Digdir-koplingar fjernast, eller beheldast i tillegg til
  `linkml:`? Fjerning gir ærlegare sporing, men endrar Digdir-dekningstabellen
  (regel 8 kan få færre sjekkar).
- **A3 — Versjonslåsing (svar: dokumenter versjonsintervallet):** Skal README dokumentere versjonsintervallet, eller bør
  LinkML-versjonen i validator-imaget låsast for å få eit stabilt regelsett? Låsing
  er ei eiga avgjerd, jf. `specs/backlog/lock-github-action-versjonar.md`.

---

## Avgjerder

- **Teknisk kjelde, ikkje fjerde normative kjelde.** LinkML regulerer verktøyet og ikkje
  forvaltninga. Han blir difor skild frå dei tre normative kjeldene, slik at sporinga
  ikkje gir verktøykonvensjonar meir tyngd enn dei har.
- **Underseksjon i staden for kolonne.** LinkML-sjekkane ligg nesten berre i bronze. Ei
  kolonne i alle sjekktabellane ville stort sett vere tom.
- **Regelsettet blir henta frå koden, ikkje frå dokumentasjonen.** Ei oppsummering av
  linter-sida på linkml.io stemte ikkje med regelnavna i README, og versjonsintervallet
  er ope.
- **Regelsettet i LinkML 1.11.1 (steg 1).** `recommended.yaml` har ti reglar:
  `recommended`, `no_xsd_int_type`, `no_invalid_slot_usage`, `no_undeclared_slots`,
  `no_undeclared_ranges`, `one_identifier_per_class`, `one_key_per_class`,
  `root_type_checks`, `standard_naming` og `canonical_prefixes`. README nemnde berre fem.
  Lista vart lesen med `podman run` direkte mot `mcp-linkml-validator`-imaget, som
  feilsøking. Ingen ny make-target, fordi kartlegginga er eit eingongssteg og
  koherenstesten les regelnavna frå installert LinkML.
- **Kva koplingar som er «tynne» (steg 6, A2).** Fjerna:
  - `schema.name` → Digdir 1. Maskinnavnet er ein identifikator, ikkje ein forståeleg tittel.
  - LinkML-linteren → Digdir 8.
  - `no_inlined_on_primitive_range` → Digdir 8. Sjekken fangar daud konfigurasjon og
    seier ingenting om maskinlesbarheit.

  Behaldne, fordi koplinga er reell:
  - `default_prefix_is_absolute_uri` → Digdir 4 (gyldige element-URI-ar er identifiserbarheit)
  - `standard_naming` → Digdir 3
  - `local_types_have_standard_uri` → Digdir 15

  FAIR I1 på `no_inlined_on_primitive_range` er beheldt, sidan A2 berre gjaldt
  Digdir-koplingar. Ho er like tynn og kan vurderast seinare.
- **`schema.id`/`default_prefix`-sjekkane fekk ikkje `linkml:`.** HTTP(S)-kravet på `id`
  og kravet om at `default_prefix` finst er ikkje LinkML-krav (metamodellen krev berre
  `id`/`name`). Metamodell-kravet på `id`/`name` er ført i README for `required:`-felta.
- **Nivåtabellen retta.** Digdir-kolonna for bronze vart `1, 2, 3, 4, 7, 9, 15` (8 fall
  bort, 9 mangla frå før trass i `schema.version`). Basis-no vart `1-9, 13, 15`
  (9 mangla frå før).
- **`linter:<regel>` er ein gyldig verdi, men er ikkje i bruk i `checks:`.** Linter-reglane
  er konfigurasjon og ikkje `checks:`-oppføringar, så dei er dokumenterte i README-tabellen.
  Testen validerer verdien mot `default.yaml` frå installert LinkML, slik at framtidig
  bruk blir kontrollert.

## Utført

- **YAML:** `linkml: semantikk` på `default_prefix_is_absolute_uri`,
  `no_inlined_on_primitive_range` og `local_types_have_standard_uri` (bronze, og gold-kopiane
  der dei finst). `digdir_rule: 8` er fjerna frå `no_inlined_on_primitive_range` (bronze, gold).
- **README/README.en:**
  - Innleiinga seier «tre normative kjelder og éi teknisk», og kjeldetabellen har ei LinkML-rad.
  - Ny seksjon «LinkML-konformitet (teknisk kjelde)» med versjonsintervall, LinkML-sjekkar
    og tabell over linter-reglar (nivå i `recommended`, bronze og gull).
  - Kryssreferansen har ei LinkML-kolonne og ei ny rad for strukturell gyldigheit.
  - Digdir-regel 8-rada og nivåtabellen er oppdaterte, og Digdir-cella er sett til «—» for
    `schema.name`, linteren og `inlined`.
- **Testar:** `linkml` er med i `_KJELDENOKLAR` (samsvar mellom gull og sølv), og den nye
  testen `test_linkml_kjelde_er_kontrollert_verdi` er lagd til.
  `make mcp-linkml-valider-modell-test`: 75 testar OK.
- **Andre stader:** CLAUDE.md § «Policy-hierarki» og «Sjå også» i
  `standardetterleving{,.en}.md` nemner LinkML som teknisk kjelde. `make translate-stamp`
  er køyrd for begge `.en.md`, og `make translate-status` viser 0 utdaterte.
