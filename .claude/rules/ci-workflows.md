---
name: ci-workflows
description: Actionlint-plikta (inkl. utdatert action-metadata), CI-YAML sin lægre DRY-terskel (2+), cache-nøklar for avleidde artefakter (hash deterministisk output, stadfest cache-miss før CI-verifisering), reusable workflow/composite action-avgrensingar (inkl. ./-stiar ved eksterne kall og røyktest-plikt for public reusable workflows), og GHCR-referansar med små bokstavar. Lastast automatisk ved arbeid med filer under .github/workflows/ eller .github/actions/.
paths:
  - ".github/workflows/**"
  - ".github/actions/**"
---

## Actionlint etter CI-endring

Etter *kvar* endring i `.github/workflows/*.yml` skal `actionlint` køyrast
mot den endra fila før arbeidet vert rekna som ferdig.

GitHub Actions evaluerer `${{ }}`-uttrykk overalt i eit `run:`-steg — også
inni kommentarar — så eit bokstaveleg tomt `${{ }}` eller anna ugyldig
uttrykk får heile workflowen til å feile ved parse-tid, utan at éin einaste
jobb køyrer (synest som ei 0-sekunds "workflow file issue"-feiling i
Actions-historikken).

Køyr via podman, aldri lokal installasjon:

```bash
podman run --rm -v "$(pwd)":/repo:ro -w /repo docker.io/rhysd/actionlint:latest -color .github/workflows/<fil>.yml
```

**Kva blokkerer:** berre feil av typen `[expression]` (og andre reelle
syntaks-/schemafeil) blokkerer arbeidet. `[shellcheck]`-funn er stilråd og
treng ikkje rettast som del av same endring.

**Gjeld berre `.github/workflows/*.yml`.** `actionlint` tolkar ei
`.github/actions/*/action.yml`-fil som ein workflow (krev `jobs:`/`on:`)
og gir falske "unexpected key"/"section is missing"-feil dersom han
køyrast mot ei composite action-fil. Valider action.yml-filer med rein
YAML-syntakssjekk i staden:

```bash
python3 -c "import yaml; yaml.safe_load(open('.github/actions/<namn>/action.yml')); print('OK')"
```

### `[action]`-funn kan kome av utdatert metadata

actionlint validerer `with:`-inputs mot ein innebygd kopi av `action.yml` for
populære actions. Kopien følgjer actionlint-versjonen og kan vere eldre enn
action-versjonen workflowen brukar. Då rapporterer actionlint input som
faktisk finst, som «not defined», eller input som ikkje lenger er påkravde,
som «missing … required».

**Aldri** «fiks» eit slikt funn ved å byte til ein input som actionen sjølv har
merkt som deprecated, berre for å gjere actionlint grøn.

Gjer i staden slik:

1. Les `action.yml` på den taggen workflowen faktisk brukar, og samanlikn
   `inputs:` (`required`, `deprecationMessage`) med funnet:
   ```bash
   gh api "repos/<eigar>/<action>/contents/action.yml?ref=<tag>" --jq .content | base64 -d | sed -n '/^inputs:/,/^outputs:/p'
   ```
2. Viss `action.yml` motseier funnet, er metadataen utdatert. Undertrykk
   **berre dei eksakte meldingane** i `.github/actionlint.yaml`
   (`paths.<glob>.ignore`), med ein kommentar om actionlint-versjonen,
   action-versjonen og når linjene kan fjernast.
3. Viss `action.yml` stadfestar funnet, er det ein reell feil. Rett workflowen.

**Grunngjeving:** actionlint 1.7.12 hadde metadata frå
`actions/create-github-app-token` v3.0.0 og rapporterte `client-id` som
ukjend og `app-id` som påkravd for `@v3`. I v3.1.0+ er `client-id` tilrådd og
`app-id` deprecated. Sjå steg 5 og Avgjerder i
`specs/backlog/github-app-for-release-please.md`.

## DRY-terskel for CI-YAML: 2+, ikkje 3+

CLAUDE.md sin generelle DRY-terskel (tre eller fleire identiske tilfelle)
gjeld **ikkje** for `.github/workflows/**`/`.github/actions/**`. Her er
terskelen **2 eller fleire** stader med same/liknande kode.

**Grunngjeving:** duplisert YAML her har vist seg å drive frå kvarandre
stille, utan at nokon merkar det før noko faktisk feilar i CI. Sjå P3 i
`specs/done/evaluering-gjentakande-monster-backlog.md`: ein
cache-nøkkel-formel meint å vere byte-for-byte identisk i to workflow-
filer dreiv frå kvarandre etter at berre den eine vart fiksa — braut
cross-workflow-cache-delinga umerkt, ingen feilmelding, berre stille
dårlegare yting. Full kartlegging av kva som faktisk vart trekt ut ved
denne terskelen (composite actions + éin intern reusable workflow) står i
`specs/done/evaluering-dry-github-workflows.md`.

## Cache-nøklar for avleidde artefakter

Ein `actions/cache`-nøkkel for noko som vert *generert* (`generated/`,
`mkdocs/docs`, `mkdocs/site` o.l.) må endre seg når, og berre når, innhaldet
ville blitt annleis. Ein for smal nøkkel gir **stille, utdatert innhald**:
jobben er grøn, og ein fiks ser ut til å ikkje verke. Ein for brei nøkkel gir
unødvendig regenerering. Begge har skjedd her.

**Aldri** avgrens nøkkelen til kjeldedata (`src/linkml/**`) åleine når
resultatet òg avheng av generatorlaget (malar, `src/assets/scripts/**`,
import-patchar, Dockerfiler, `make/*.mk`). **Aldri** bruk breie glob-ar
(`src/assets/scripts/**`, `make/**`) utan å sjekke at filene faktisk er i
kallgrafen til det som vert cacha.

Framgangsmåte:

1. Hash det **deterministiske outputet** når det finst, i staden for ei
   manuell liste over input. Stadfest determinisme med to påfølgjande
   lokale genereringar og `diff -rq`. Døme: docs-cachen i
   `lenkje-og-mermaid-sjekk.yml` hashar `generated/**/*.md`. `.ttl` er
   **ikkje** deterministisk (`linkml:generation_date`, rekkjefølgja i
   `rdf:List`).
2. Når output ikkje er deterministisk, list **eksplisitte** input-filer frå
   kallgrafen (jf. `v4-generated`-nøkkelen i `generate.yml`).
3. Bump versjonsprefikset (`vN-` → `vN+1-`) når nøkkelformelen endrar
   semantikk, slik at gamle innslag ikkje vert treffe.
4. **Før du konkluderer om ein generatorfiks ut frå ei CI-køyring:** sjekk i
   jobbloggen at cachen for det aktuelle artefaktet *missa*
   (`Cache hit for: …` / eit hoppa-over «Hopp over bygg (cache-treff)»-steg).
   Ved treff seier køyringa ingenting om fiksen.

**Grunngjeving:** lenkjesjekk-køyring `36250233352` viste uendra 646
unsupported etter BUG-24-fiksen. `generated-oreg`-artefaktet i same køyring
hadde fiksen, men `v2-docs-…`-nøkkelen hasha berre `src/linkml/**` og
`publish.sh`-kjelder, så ein gammal `mkdocs/docs/` vart gjenbrukt. Sjå
`specs/done/lenkjesjekk-docs-cache-generert-md.md`. Motsett retning (for
brei): `specs/done/scripts-glob-cache-miss-generate-jobb.md` og
`specs/done/docs-only-endring-cache-miss-alle-domene.md`. Drift mellom
dupliserte nøkkelformlar: P3 i
`specs/done/evaluering-gjentakande-monster-backlog.md` (sjå DRY-seksjonen
over).

## Reusable workflows og composite actions — kva som IKKJE kan delast

### Kallejobba til ein reusable workflow treng eksplisitte permissions

GITHUB_TOKEN sine faktiske permissions i ein kalla reusable workflow
(`uses: ./.github/workflows/X.yml`) er det **mest restriktive** av kva
kallejobben deklarerer OG kva den kalla workflowen sine eigne jobbar
deklarerer. Ei kallejobb utan eksplisitt `permissions:`-block kan difor
stille nedskalere det den kalla workflowen faktisk treng (t.d.
`packages: write` for GHCR-push) — ein feil som verken `actionlint` eller
YAML-syntakssjekk fangar, og som først syner seg ved faktisk CI-køyring.

**Regel:** ei kallejobb til ein intern reusable workflow skal alltid ha
eit eksplisitt `permissions:`-block som minst dekker det den kalla
workflowen sine jobbar treng.

### Reusable workflow-jobbar har fast steg-sekvens

Ein jobb definert inni ein reusable workflow (`on.workflow_call`) kan
**ikkje** ta imot ekstra steg injisert frå kallaren. Før du trekk ut ein
jobb til ein reusable workflow: sjekk om ALLE kallarar faktisk har
identisk steg-sekvens. Kallar-spesifikke ekstra steg må anten
parametriserast (input-styrt `if:` på eit steg INNI den delte jobben,
jf. `prepare-podman` sitt `images != ''`-mønster) eller flyttast til ein
separat jobb hos kvar kallar — dei kan ikkje "setjast inn" i den delte
jobben frå kallaren.

### Composite actions kan ikkje lese kallaren sin steps.*-kontekst

Ein composite action kan gate sine EIGNE interne steg via input-verdiar
(`if: inputs.X != ''`), men kan ikkje lese kallaren sin
`steps.<id>.outputs.*`. Ei cache-hit-vakt må difor liggje på
**kallesteget** (`if: steps.cache-id.outputs.cache-hit != 'true'` på
sjølve `uses: ./.github/actions/X`-linja), ikkje inni actionen.

### `./` i ein reusable workflow peikar på kallande repo

Når ein reusable workflow (`on.workflow_call`) vert kalla frå eit **eksternt**
repo, er arbeidskatalogen og alle `uses: ./…`-stiar kallarens repo, ikkje
dette. `uses: ./.github/actions/<x>` finn difor ikkje actionen vår hos
eksterne kallarar. Han verkar berre når workflowen vert kalla frå dette repoet,
så feilen syner seg ikkje i eigen CI.

**Regel:** Ein composite action som ein **public** reusable workflow brukar,
skal refererast med full sti, låst til commit-SHA:
`uses: AudunAutomat/linkml-datamodellering-no/.github/actions/<x>@<40-teikns-sha> # main`.
Aldri `@main`: det gir CodeQL-varselet `actions/unpinned-tag`, og ein kallar
som har låst workflowen til `@vX.Y.Z`, får likevel actionen frå `main`.
Endrar du actionen, bump SHA-en til den nye commiten i same push.
Jobben `pinned-action-drift` i `royktest-reusable.yml` feilar elles. Sjå
`specs/done/codeql-reusable-workflows-7-varsel.md`. Actionen er
sjølv public API og må vere **bakoverkompatibel**. Skriv det i
`description` i `action.yml`. Ein lokal `uses: ./…` er berre tillaten i interne
workflowar (t.d. `reusable-oppsett.yml`) og i røyktesten, som medvite testar den
lokale kopien.

**Grunngjeving:** Versjonsløysinga for BUG-22 (`resolve-linkml-version`) måtte
delast mellom tre public reusable workflows. Ho kunne ikkje brukast via `./`
eller via eit skript henta med sparse-checkout, fordi versjonen må vere
kjend før vår kode vert sjekka ut. Sjå O4 i
`specs/done/reusable-workflow-versjon.md`.

### To kategoriar reusable workflows — ikkje forveksle

- `reusable-generate.yml`/`reusable-lint.yml`/`reusable-validate.yml` er
  **public API for eksterne repo** (workflow_call med `schema:`-input for
  validering/lint/generering av eitt enkelt skjema) — ikkje interne
  DRY-verktøy. Endringar her er ei API-endring for andre repo.
- `reusable-oppsett.yml` er eit **internt DRY-verktøy** (deler
  `checkout-source`+`ensure-images`), kalla berre av
  `generate.yml`/`lenkje-og-mermaid-sjekk.yml`/`validate.yml` i dette same
  repoet.

### Public reusable workflows skal vere dekte av røyktesten

Dei public reusable workflowane vert ikkje køyrde av nokon annan CI i dette
repoet. Ein feil i dei (eller i actions dei brukar) syner seg difor først hos
eksterne kallarar.

**Regel:** Ved endring i `reusable-{generate,lint,validate}.yml` eller i ein
action dei brukar (t.d. `.github/actions/resolve-linkml-version/**`):

1. Utvid `.github/workflows/royktest-reusable.yml` viss endringa innfører ny
   åtferd som ikkje alt er dekt (ny input, ny versjonsvariant, ny feilveg).
2. Etter push: kontroller at røyktesten køyrde (push-trigger på desse stiane)
   og er grøn før arbeidet vert rekna som ferdig. Ta med køyrings-ID i specen.
3. `reusable-lint.yml`/`reusable-generate.yml` kan ikkje køyrast frå dette
   repoet (dei stoppar når kallaren har `src/assets/`/`Makefile`). For dei skal
   det delte (actions, versjonsløysing) testast i røyktesten, og avgrensinga
   skal nemnast i specen.

**Grunngjeving:** BUG-22 (`ref: latest` finst ikkje) rakk alle eksterne
standardoppsett og var uoppdaga i 12+ veker, fordi ingenting køyrde dei public
reusable workflowane. Sjå `specs/done/reusable-workflow-versjon.md` og
`bugs/reusable-workflow-latest-ref-manglar.md`.

## GHCR-referansar: aldri direkte frå `github.repository_owner`

OCI-image-referansar må vere berre små bokstavar, men
`github.repository_owner` (og `$GITHUB_REPOSITORY_OWNER`) gir eigarnavnet
slik det er skrive på GitHub, som kan ha store bokstavar. `skopeo`/`podman`
avviser då referansen (`invalid reference format: repository name must be
lowercase`). Feilen er usynleg så lenge eigaren tilfeldigvis berre har små
bokstavar. Han dukkar først opp ved flytting, i ein fork eller ved ein ny
eigar. GitHub-uttrykk har ingen `lower()`, så feilen kan ikkje rettast
inni `${{ }}`.

**Aldri** skriv `ghcr.io/${{ github.repository_owner }}/...` (eller
`ghcr.io/$GITHUB_REPOSITORY_OWNER/...`) i ein workflow eller composite action.

Gjer i staden slik:

1. For image i `src/assets/containers/images.json`: bruk verdien frå
   `image_tags` (output frå `./.github/actions/compute-image-tags`). Han er
   alt ein full referanse (`ghcr.io/<eigar i små bokstavar>/<navn>:<hash>`), så du
   treng ikkje setje saman noko sjølv.
2. For image som ikkje står i `images.json` (t.d. `mcp-linkml-*-utkast` i
   `release.yml`): rekn ut prefikset i bash,
   `REGISTRY="ghcr.io/${GITHUB_REPOSITORY_OWNER,,}"`, og bruk `$REGISTRY`.
3. I **public** reusable workflows (`reusable-generate.yml`,
   `reusable-lint.yml`, `reusable-validate.yml`) skal image-eigaren vere
   hardkoda med små bokstavar (`ghcr.io/audunautomat/...`).
   `github.repository_owner` er der eigaren av det *kallande* repoet, ikkje
   dette.

**Grunngjeving:** Etter at origin vart flytta frå `brreg` til `AudunAutomat`
feila alle `oppsett / build-image / *`-jobbar i `generate.yml`,
`validate.yml` og `lenkje-og-mermaid-sjekk.yml` (og `ensure-images` i
`modell-analyse.yml`) med feilmeldinga over. Sjå F1 i
`specs/done/ci-etter-origin-flytting-audunautomat.md`.
