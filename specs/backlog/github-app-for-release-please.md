# GitHub App i staden for PAT for release-please

## Bakgrunn

`RELEASE_PLEASE_TOKEN` er i dag ein fine-grained PAT som høyrer til kontoen
`AudunAutomat`. Han vart oppretta under flyttinga frå `brreg` (sjå
`specs/backlog/ci-etter-origin-flytting-audunautomat.md`, F2/F2a). F9 i same
spec vurderte alternativa og tilrådde ein **GitHub App eigd av `AudunAutomat`**
(alternativ B). Då vert ikkje automatiseringa knytt til ein personleg konto,
tokenet går ikkje ut, og handlingane vert logga som ein bot. Denne specen
planlegg migreringa. PAT-en er mellombels løysing til denne specen er
gjennomført.

Tidlegare vurdering i org-konteksten: `specs/done/alternativ-til-pat-release-please.md`
(tilrådde òg App, men stoppa på manglande org-admin-tilgang), og
`specs/done/auto-merge-release-pr.md` (AM1: `github-actions[bot]` kan ikkje
stå på bypass-lista, 422).

## Noverande tokenbruk (kartlagt 2026-09-26)

| # | Stad | Handling | Token i dag |
|---|---|---|---|
| T1 | `release-please.yml:114` | `release-please-action` (lage/oppdatere release-PR, GitHub Release og tag ved merge) | `RELEASE_PLEASE_TOKEN` |
| T2a | `release-please.yml:121` | `gh`-kall i «Oppdater schema-versjonar i release-PR» | `RELEASE_PLEASE_TOKEN` (`GH_TOKEN`) |
| T2b | `release-please.yml:150` | `git push origin "$BRANCH"` (schema-datoar til PR-branch) | **`GITHUB_TOKEN`** (lagra av `actions/checkout` i «Checkout for release-please», utan `token:`) |
| T3 | `release-please.yml:160,174` | `gh pr merge --auto --squash` | `RELEASE_PLEASE_TOKEN` (`GH_TOKEN`) |
| T4 | `release-please.yml:213,227` | `gh release upload` (artefakter) | `RELEASE_PLEASE_TOKEN` (`GH_TOKEN`) |
| T5 | `release-please.yml:240,271` | `git push origin "$tag_name"` (per-schema-taggar) | **`GITHUB_TOKEN`** (checkout «for artefakt-generering», utan `token:`) |
| T6 | `validate.yml:278` | `peter-evans/create-pull-request` (valideringsloggar) | `RELEASE_PLEASE_TOKEN` |
| – | `auto-approve-release-please.yml` | `gh pr review --approve` | `GITHUB_TOKEN` (skal forbli det, sjå under) |

**Rettar F9-tabellen i hovudspecen:** T2b og T5 går i dag med
`GITHUB_TOKEN`, ikkje PAT-en. `GH_TOKEN` i `env:` gjeld berre `gh`-CLI, ikkje
`git`. Konsekvensar i dag:
- Commit-en med schema-datoar på release-PR-en er gjord av
  `github-actions[bot]` og startar ikkje `validate.yml`, fordi `GITHUB_TOKEN`
  har loop-vern. Siste commit på PR-en har difor ingen checks. Det blokkerer
  ikkje, fordi ruleset-en ikkje har påkravde status checks.
- «Siste push må godkjennast av ein annan» (`require_last_push_approval`):
  siste pushar er `github-actions[bot]`, som òg er den som godkjenner i
  auto-approve. Godkjenninga oppfyller difor ikkje regelen. Merge skjer i dag
  berre fordi PAT-eigaren er admin og går forbi reglane.

## Mål

1. Ingen hemmelegheit som høyrer til ein personleg brukar. `RELEASE_PLEASE_TOKEN`
   (PAT) vert sletta og trekt tilbake.
2. Full automatikk som i dag: release-PR → validate køyrer → godkjenning →
   auto-merge → GitHub Release, artefakter og taggar.
3. Ruleset-en `main protection` (F8/F8b) vert **uendra**. Appen skal ikkje stå
   på bypass-lista (O3 = nei).

## Design

### App

- Oppretta av `AudunAutomat` under **konto-innstillingane** (profilbilete →
  *Settings* → nedst i venstremenyen *Developer settings* → *GitHub Apps* →
  *New GitHub App*), direkte: <https://github.com/settings/apps/new>. Dette
  ligg **ikkje** under *Settings* i repoet. Kontroller at nettlesaren er
  innlogga som `AudunAutomat` og ikkje `AudunVindenesEggeBR`, elles vert appen
  eigd av feil konto. Namn: **`linkml-release-bot`** (O1, avgjort).
  Bot-identiteten vert `linkml-release-bot[bot]`.
- Homepage URL: `https://github.com/AudunAutomat/linkml-datamodellering-no`.
  Webhook: **av**. «Where can this GitHub App be installed?»: **Only on this
  account**.
- Repository permissions: **Contents: Read and write**, **Pull requests: Read
  and write**, **Issues: Read and write** (etikettar). Metadata: Read-only
  vert sett automatisk. *Workflows* trengst ikkje, fordi ingen steg skriv til
  `.github/workflows/`.
- Installert berre på `linkml-datamodellering-no` (*Only select repositories*).

### Lagring

Undersøkt 2026-09-26 mot `action.yml` og `README.md` i
`actions/create-github-app-token@v3.2.0`. `v3` peikar på same commit
(`bcd2ba49`). Siste release er frå 2026-05-12, og v3.0.0 kom 2026-03-14:

| Input | Status i v3.2.0 | Merknad |
|---|---|---|
| `client-id` | **tilrådd**, dokumentert i alle døme (`vars.APP_CLIENT_ID`) | README: «Store the App's Client ID in your repository variables» |
| `app-id` | `deprecationMessage: "Use 'client-id' instead."` | Fungerer framleis, men gir ei åtvaring i køyringa og kan forsvinne i ein seinare major |
| `private-key` | påkravd | PEM-innhaldet som det er. `\\n` vert omgjort til linjeskift automatisk |

Lagring i repoet:
- Repo-**variabel** `RELEASE_APP_CLIENT_ID`: appen sin *Client ID* (strengen
  øvst på innstillingssida til appen, t.d. `Iv23li…`). Han er ikkje hemmeleg og
  skal vere variabel, ikkje secret. Då er han lesbar i loggar og for
  feilsøking.
- Repo-**secret** `RELEASE_APP_PRIVATE_KEY`: innhaldet i `.pem`-fila.
- **App-ID** (numerisk) trengst **ikkje** i workflowane, men han er
  `actor_id` for ein `Integration` i ruleset-ens `bypass_actors` (steg 3, veg
  1). Noter han i specen ved steg 2, men lagre han ikkje som variabel før
  veg 1 faktisk vert teken i bruk.

Andre forhold frå v3 som påverkar designet:
- **Tokenet vert trekt tilbake i `post`-steget** (med mindre
  `skip-token-revoke: true`). Det kan difor ikkje sendast mellom jobbar, og
  kvar jobb må hente sitt eige. Det stemmer med «Token per jobb» under.
- **`permission-<namn>`-inputs** avgrensar tokenet per jobb. Utan dei arvar
  tokenet alle løyva til installasjonen. README tilrår å liste dei
  eksplisitt.
- **Outputs:** `token`, `installation-id`, `app-slug`. `app-slug` vert brukt
  til å setje git-identiteten (sjå «Konsekvens for steg 5»).
- `runs.using: node24` krev Actions Runner ≥ v2.327.1. Det gjeld berre
  self-hosted runnarar, og repoet brukar GitHub-hosta `ubuntu-22.04`.
- Proxy-endringa i v3.0.0 (`NODE_USE_ENV_PROXY`) er ikkje relevant, fordi
  ingen proxy er i bruk.

### Token per jobb

Éitt token-steg først i kvar jobb som treng det. Tokenet lever i 1 time,
og det er nok for jobbane:

```yaml
- name: Hent token for release-bot
  id: app-token
  uses: actions/create-github-app-token@v3
  with:
    client-id: ${{ vars.RELEASE_APP_CLIENT_ID }}
    private-key: ${{ secrets.RELEASE_APP_PRIVATE_KEY }}
    permission-contents: write
    permission-pull-requests: write
    permission-issues: write
```

Løyve per jobb, frå tokenbruken over:

| Jobb | `contents` | `pull-requests` | `issues` | Grunn |
|---|---|---|---|---|
| `release-please` (`release-please.yml`) | write | write | write | T1–T5: PR, push, merge, release, taggar, `autorelease:*`-etikettar |
| `create-pr-with-validation-logs` (`validate.yml`) | write | write | write | T6: branch, commit og PR. `issues: write` for etikettane `automated`/`validation` |

Dei to jobbane treng same løyve, så eit felles token-steg (composite action)
kan ha dei faste.

Pinning: `actions/*` vert pinna på major-tag i repoet (jf.
`actions/checkout@v7`). Tredjeparts-actions vert pinna på SHA. Følg same
konvensjon.

Erstatningar:
- `release-please.yml`, jobben `release-please`: token-steget kjem før første
  checkout. `secrets.RELEASE_PLEASE_TOKEN` → `steps.app-token.outputs.token` i
  T1, T2a, T3 og T4. **I tillegg** (O2 = ja, O4 = a):
  - «Checkout for release-please» får `token: ${{ steps.app-token.outputs.token
    }}`, slik at T2b (dato-commit) vert pusha som appen.
  - «Checkout for artefakt-generering» får `persist-credentials: false`, og
    T5 (per-schema-taggar) vert laga via API i staden for `git push`, sjå
    «Per-schema-taggar via API (O4 = a)» under.
- `validate.yml`, jobben `create-pr-with-validation-logs`: token-steget før
  `create-pull-request`, T6 → `steps.app-token.outputs.token`.
- CI-DRY-terskelen er 2+. Token-steget vert gjenteke i 2 jobbar med same
  innhald. Vurder ein composite action `./.github/actions/release-bot-token`
  (jf. `.claude/rules/ci-workflows.md`). Composite actions kan ikkje lese
  `secrets`, så nøkkelen må sendast inn som input.

### Godkjenning og merge (T3)

Ruleset-en krev 1 godkjenning og at siste push er godkjend av ein annan.
Appen lagar PR-en, og (etter O2) er det appen som gjer siste push.
**Avgjort (O3 = nei): berre veg 2 vert brukt.** Veg 1 er reserveløysing
og vert berre teken i bruk dersom veg 2 viser seg ikkje å fungere i steg 6.3.

1. **(Reserveløysing, ikkje planlagd) Appen på bypass-lista:** `bypass_actors` += `{ "actor_type":
   "Integration", "actor_id": <App-ID>, "bypass_mode": "always" }`.
   `github-actions[bot]` vart avvist med 422 i AM1, men ein *installert* app på
   eit repo er ein annan type aktør. Det er **ikkje stadfesta** at dette er
   tillate for rulesets på personlege repo. Vert berre testa viss veg 2
   feilar (steg 3).
2. **(Valt) Utan bypass:** `auto-approve-release-please.yml` godkjenner med
   `GITHUB_TOKEN` (`github-actions[bot]`). PR-forfattar og siste pushar er
   `<app-slug>[bot]`, som ikkje er den same, så både «1 godkjenning» og
   «siste push godkjend av ein annan» vert oppfylte utan bypass. Dette krev O2
   (push som appen).

Uansett veg må `if:`-sjekken i `auto-approve-release-please.yml` godta
PR-forfattaren `<app-slug>[bot]` i tillegg til eller i staden for
`github.repository_owner`. Behald sjekken av `head.repo.full_name`.

### O2 i detalj: git-push som appen

#### Kvifor O2 = ja er ein føresetnad for veg 2

Ruleset-en har både `dismiss_stale_reviews_on_push: true` og
`require_last_push_approval: true` (F8b). Hendingsforløpet for ein release-PR
ser slik ut:

| # | Hending | Aktør i dag | Aktør med O2 = nei | Aktør med O2 = ja |
|---|---|---|---|---|
| 1 | `release-please-action` opnar PR-en | `AudunAutomat` (PAT) | `<app>[bot]` | `<app>[bot]` |
| 2 | `auto-approve` (`opened`) godkjenner | `github-actions[bot]` | `github-actions[bot]` | `github-actions[bot]` |
| 3 | «Oppdater schema-versjonar» pushar dato-commit (T2b) | `github-actions[bot]` (`GITHUB_TOKEN`) | `github-actions[bot]` | `<app>[bot]` |
| 4 | Godkjenninga frå 2 vert **avvist** (stale) | ja | ja | ja |
| 5 | `synchronize`-hending → `auto-approve` og `validate` køyrer på nytt | **nei** (loop-vern for `GITHUB_TOKEN`) | **nei** | **ja** |
| 6 | Ny godkjenning etter siste push, frå ein annan enn pusharen | – | – | ja (`github-actions[bot]` ≠ `<app>[bot]`) |
| 7 | Auto-merge (T3) kan fullføre | berre via admin-bypass for PAT-eigaren | berre via bypass (veg 1, ustadfesta) | **ja, utan bypass** |

Med O2 = nei endar PR-en med 0 gyldige godkjenningar etter steg 4, og
ingen workflow vert utløyst som kan gi ny godkjenning. Då står berre veg 1
(appen på bypass-lista) att. Veg 1 er ikkje stadfesta for personlege repo, og
O3 tilrår å unngå han. Det same held i dag: flyten verkar berre fordi
PAT-eigaren er admin. O2 = ja gjer at release-flyten ikkje lenger treng
bypass i det heile.

#### Kva som vert utløyst av push som appen (kartlagt 2026-09-26)

Hendingar frå eit app-token startar workflowar (i motsetnad til
`GITHUB_TOKEN`). Kartlegginga av `on:` i alle workflowar:

| Push | Workflow | Utløyst? | Merknad |
|---|---|---|---|
| T2b dato-commit til `release-please--branches--main` (endrar `*-schema.yaml`) | `validate.yml` (`pull_request`, `paths: src/linkml/**`) | **nei**, jf. retting under | Commit-meldinga inneheld `[skip ci]`, og det hindrar `push`/`pull_request`-workflowar. `validate` køyrer framleis på `opened` (release-please sin eigen commit) |
| | `auto-approve-release-please.yml` (`pull_request_target: synchronize`) | **ja**, ønskt | Gir ny godkjenning etter at den første er avvist (steg 6 over) |
| | `codeql.yml` (`pull_request: branches: [main]`) | nei (`[skip ci]`) | – |
| | `generate.yml`, `release-please.yml`, `trivy.yml` (`push: branches: [main]`) | nei | Push til ein annan branch enn `main` |
| T5 per-schema-tag `<skjema>-vX.Y.Z` | `release.yml` (`push: tags: ['v*.*.*']`) | **nei** | Mønsteret krev at tag-namnet byrjar på `v`. `dcat-ap-no-v2.14.2` matchar ikkje |
| | alle andre med `push: branches: [main]` | nei | Ein workflow med berre `branches`-filter vert ikkje utløyst av tag-push |

**Retting 2026-09-26 (steg 5):** Dato-commiten har `[skip ci]` i meldinga
(`release-please.yml`). Ifølgje GitHub-dokumentasjonen («Skipping workflow
runs») gjeld dette `on: push` og `on: pull_request`, men **ikkje**
`pull_request_target`. `auto-approve` køyrer difor framleis på
`synchronize`, og det er det veg 2 treng. `validate`/`codeql` køyrer ikkje på
dato-commiten, berre på `opened`. `[skip ci]` er behalde, og **steg 6.3 må
stadfeste at `auto-approve` faktisk køyrer på dato-commiten.** Viss han ikkje
gjer det, er fiksen å fjerne `[skip ci]` frå commit-meldinga.

**Ingen løkker:** Ingen av workflowane som vert utløyste (validate, auto-approve,
codeql), pushar til release-branchen. `create-pr-with-validation-logs` køyrer
berre ved `schedule`/`workflow_dispatch`. `release-please.yml` er avgrensa med
`concurrency: release-please`.

**Uendra:** Merge av release-PR-en (T3, auto-merge) vert utført som den som
aktiverte auto-merge, altså appen. Pushen til `main` utløyser
`release-please.yml` og `generate.yml` akkurat som i dag med PAT.

#### Risiko: token lagra i `.git/config`

`actions/checkout` med `token:` lagrar tokenet i `.git/config`
(`persist-credentials: true` er standard). Alle seinare steg i jobben kan då
lese det. I «Checkout for artefakt-generering» køyrer seinare steg
`make build-docker-*` og `make gen-*`, altså kode frå repoet. Det gjeld i dag
òg for `GITHUB_TOKEN` (`contents: write`), og app-tokenet har tilsvarande
omfang (Contents/PR/Issues på eitt repo, levetid 1 time). Risikoen er difor om
lag den same som i dag, men han kan reduserast:

- **a) (tilrådd for T5)** `persist-credentials: false` på «Checkout for
  artefakt-generering». Lag per-schema-taggane via API i staden for `git push`:
  `gh api repos/$R/git/tags` (annotert tag-objekt) + `gh api repos/$R/git/refs
  -f ref=refs/tags/$tag_name -f sha=<tag-objekt>`, med `GH_TOKEN` berre i det
  steget. Byggestega får då ikkje tokenet.
- **b) (tilrådd for T2b)** Behald `token:` på «Checkout for release-please».
  Steget etter køyrer berre `update-schema-dates.py` og git-kommandoar, ikkje
  bygg.
- **c)** Enklast: `token:` på begge checkout-stega. Same risikoprofil som i dag.

#### Konsekvens for steg 5 (kodeendring)

- «Checkout for release-please»: `token: ${{ steps.app-token.outputs.token }}`.
- «Checkout for artefakt-generering»: `persist-credentials: false` (O4 = a).
  Byggestega (`make build-docker-*`, `make gen-*`) ser då ikkje noko token.
- «Opprett per-schema git-tags»: skriv om frå `git tag -a` + `git push` til
  API-kall, sjå under.

#### Per-schema-taggar via API (O4 = a)

Tilsvarer dagens `git tag -a "$tag_name" -m "Release $schema version
$version"` + `git push origin "$tag_name"` (`release-please.yml:240–275`),
men utan git-credentials:

```bash
# GH_TOKEN: ${{ steps.app-token.outputs.token }} berre i dette steget
sha=$(git rev-parse HEAD)          # lokal operasjon, krev ikkje credentials
if gh api "repos/$GITHUB_REPOSITORY/git/ref/tags/$tag_name" >/dev/null 2>&1; then
  echo "✅ Tag $tag_name finst allereie"; continue
fi
tag_obj=$(gh api -X POST "repos/$GITHUB_REPOSITORY/git/tags" \
  -f tag="$tag_name" -f message="Release $schema version $version" \
  -f object="$sha" -f type=commit --jq .sha)
gh api -X POST "repos/$GITHUB_REPOSITORY/git/refs" \
  -f ref="refs/tags/$tag_name" -f sha="$tag_obj" >/dev/null
echo "::notice::Oppretta git-tag: $tag_name"
```

- Resultatet er ein **annotert** tag, same type som i dag. Tagger er
  appen.
- **Eksistenssjekken skal gå mot API-et, ikkje `git tag -l`.** Dagens sjekk
  (`git tag -l | grep -q "^${tag_name}$"`) køyrer mot ein grunn checkout
  (`fetch-depth: 1`, ingen taggar henta), og finn difor aldri taggar som alt
  finst i origin. Då ville ein push av ein eksisterande tag feile. API-sjekken
  rettar denne latente feilen, som fanst frå før.
- Ein feil i `gh api` skal ikkje svelgjast. `2>&1 >/dev/null` gjeld berre
  eksistenssjekken, der «finst ikkje» (404) er venta. Dei to POST-kalla skal
  feile steget ved feil (ingen stille feil, jf. CLAUDE.md).
- Steget treng ingen eigen `|| exit 1`. Utan `shell:` køyrer GitHub Actions
  `run:` med `bash --noprofile --norc -eo pipefail {0}`. Ein feil i eit
  POST-kall avsluttar difor subshellen til `while`-løkka, og `pipefail` gjer
  heile steget raudt. Legg likevel til ei `::error::`-linje med tag-namnet,
  slik at feilen vert synleg i annotasjonane.
- Commit-identiteten i «Oppdater schema-versjonar» og «Opprett per-schema
  git-tags» (i dag `git config user.name "github-actions[bot]"`) bør bytast til
  appen, etter mønsteret i README («Configure Git CLI for an app's bot user»):
  ```yaml
  - name: Hent bot-brukar-id
    id: bot-user
    env:
      GH_TOKEN: ${{ steps.app-token.outputs.token }}
    run: echo "id=$(gh api "/users/${{ steps.app-token.outputs.app-slug }}[bot]" --jq .id)" >> "$GITHUB_OUTPUT"
  # … i run-steget:
  git config user.name  "${{ steps.app-token.outputs.app-slug }}[bot]"
  git config user.email "${{ steps.bot-user.outputs.id }}+${{ steps.app-token.outputs.app-slug }}[bot]@users.noreply.github.com"
  ```
  Utan dette viser commit-historikken feil forfattar, sjølv om pushen går som
  appen. Brukar-id-en er stabil, så ho kan alternativt slåast opp éin gong
  og lagrast som variabel for å spare eit API-kall per køyring.
- Verifiser i steg 6.3 at `validate` og `auto-approve` faktisk køyrer på
  `synchronize` etter dato-commiten, og at PR-en har éi godkjenning *etter*
  siste push.

## Steg

1. ✅ **Opne spørsmål avklarte** (2026-09-26): O1 = `linkml-release-bot`,
   O2 = ja, O3 = nei, O4 = a.
2. **Opprett og installer appen** (brukaren, i nettlesaren som
   `AudunAutomat`), jf. Design → App. Generer privat nøkkel og last ned
   `.pem`. Noter **Client ID** (til variabelen) frå innstillingssida til
   appen. App ID trengst berre dersom reserveløysinga i steg 3 vert aktuell.
3. **(Berre viss veg 2 feilar i steg 6.3, O3 = nei.) Test bypass-støtte**
   (LLM, les- og skriv-API som admin):
   ```bash
   R=AudunAutomat/linkml-datamodellering-no
   gh api repos/$R/rulesets/24036454 > ruleset-backup.json
   jq --argjson id <App-ID> '{bypass_actors: (.bypass_actors + [{actor_type:"Integration", actor_id:$id, bypass_mode:"always"}])}' \
     ruleset-backup.json | gh api -X PUT repos/$R/rulesets/24036454 --input -
   gh api repos/$R/rulesets/24036454 --jq .bypass_actors
   ```
   422 betyr at vegen ikkje er tillaten. Då går ein vidare med veg 2, og
   ruleset-en er uendra. Viss kallet går gjennom, stadfest at dei andre reglane
   er urørte ved å samanlikne mot `ruleset-backup.json`, jf. F8b.
4. **Lagre variabel og secret** (brukaren):
   ```bash
   gh variable set RELEASE_APP_CLIENT_ID -R AudunAutomat/linkml-datamodellering-no --body <Client-ID>
   gh secret set RELEASE_APP_PRIVATE_KEY -R AudunAutomat/linkml-datamodellering-no < <sti>/<app>.private-key.pem
   ```
   Slett `.pem`-fila lokalt etterpå, eller lagre ho i ein passordhandsamar.
5. ✅ **Kodeendring** (LLM, utført 2026-09-26, sjå «Utført steg 5» under), jf. Design → Token per jobb og Godkjenning:
   `release-please.yml`, `validate.yml`, `auto-approve-release-please.yml`,
   eventuelt ny composite action. Køyr `actionlint` på alle endra workflow-filer.
   Oppdater kommentarar som nemner PAT. Oppdater F2a/F9 i hovudspecen og
   `specs/done/auto-merge-release-pr.md`-referansar i kommentarar ved behov.
6. **Verifiser** (etter at endringane ligg i `origin/main`):
   1. `gh workflow run release-please.yml` → grøn. Loggen viser at
      token-steget køyrde, og ingen `RELEASE_PLEASE_TOKEN`.
   2. `gh workflow run validate.yml`. Viss det er nye loggar, er
      `validation-logs-update`-PR-en laga av `<app-slug>[bot]`.
   3. Ved første ekte release-PR (dekkjer òg 9.4b i hovudspecen): forfattar
      `<app-slug>[bot]` → auto-approve godkjenner → `validate.yml` køyrer
      både på PR-en og på dato-commiten → auto-merge → GitHub Release,
      artefakter og per-schema-taggar vert laga, med `<app-slug>[bot]` som
      aktør.
   4. Kontroller spesielt (O2/O3): PR-en har éi godkjenning frå
      `github-actions[bot]` som er gitt **etter** siste push frå
      `<app-slug>[bot]`, og merge skjedde **utan** bypass (appen står ikkje i
      `bypass_actors`). Per-schema-taggane er annoterte, med `<app-slug>[bot]`
      som tagger (O4).
7. **Fjern PAT** (brukaren): `gh secret delete RELEASE_PLEASE_TOKEN -R
   AudunAutomat/linkml-datamodellering-no`, og trekk tilbake PAT-en under
   *Settings → Developer settings → Fine-grained tokens*. Stadfest med
   `grep -rn RELEASE_PLEASE_TOKEN .github` (0 treff).

### Utført steg 5 (2026-09-26)

**Førehandskontroll:** `RELEASE_APP_CLIENT_ID` (variabel) og
`RELEASE_APP_PRIVATE_KEY` (secret) finst. Appen finst som
`linkml-release-bot[bot]` (id 334154478). Installasjonen kan ikkje lesast med
brukar-token (endepunktet krev app-JWT), men han vert stadfesta ved første
køyring: `create-github-app-token` feilar dersom appen ikkje er installert på
repoet.

**Faktiske data frå release-PR #1** (oppretta og merga same dag, før migreringa):

| Tid | Hending | Aktør |
|---|---|---|
| 09:53:51 | PR oppretta | `AudunAutomat` (PAT) |
| 09:53:54 | dato-commit `[skip ci]` | `github-actions[bot]` (`GITHUB_TOKEN`) |
| 09:53:58 | godkjenning (etter siste push, men frå **same** aktør som pusha) | `github-actions` |
| 10:29:44 | auto-merge **slått av** | `AudunAutomat` |
| 10:29:51 | merga manuelt (merge-commit `700e2918`) via admin-bypass | `AudunAutomat` |
| 10:30 | release-please etter merge: 10 GitHub Releases, artefakter og per-schema-taggar | PAT / `GITHUB_TOKEN` |

Dette stadfestar analysen i «O2 i detalj»: med `GITHUB_TOKEN`-push fullfører
ikkje auto-merge (`require_last_push_approval`), og PR-en vert merga manuelt.

**Endringar:**

- `release-please.yml`:
  - Nye steg «Hent token for linkml-release-bot» (`create-github-app-token@v3`,
    `client-id`, `permission-contents/pull-requests/issues: write`) og «Hent
    git-identitet for linkml-release-bot» (`app-slug` + `gh api /users/…[bot]`).
    Begge ligg før «Checkout for release-please», med same vilkår.
  - Alle `secrets.RELEASE_PLEASE_TOKEN` → `steps.app-token.outputs.token`
    (T1, T2a, T3, T4, T5).
  - «Checkout for release-please»: `token:` = app-token (T2b pushar som appen, O2).
  - Dato-commit: `git config` = app-identitet i staden for `github-actions[bot]`.
  - **`gh pr merge --auto --squash` → `--merge`** (sjå Avgjerder).
  - «Checkout for artefakt-generering»: `persist-credentials: false` (O4).
  - «Opprett per-schema git-tags»: `git tag -a` + `git push` er erstatta av
    `git/tags` + `git/refs`-API. Eksistenssjekken går no mot origin via API.
    `::error::` og `exit 1` ved feil.
  - Jobb-`permissions`: `contents: write` + `pull-requests: write` →
    **`contents: read`**. `GITHUB_TOKEN` gjer ikkje lenger noko skrivande i jobben.
- `validate.yml` (`create-pr-with-validation-logs`): token-steg før
  `create-pull-request`, `token:` = app-token (T6).
- `auto-approve-release-please.yml`: `github.repository_owner` →
  `'linkml-release-bot[bot]'` i forfattar-sjekken. `head.repo`-sjekken er
  behalden.
- `.github/actionlint.yaml` (ny): ignorerer to falske `[action]`-funn for
  `create-github-app-token@v3` (sjå Avgjerder).

**actionlint:** Ingen funn utanom `[shellcheck]` i dei tre filene.
`release-please.yml` har 8 shellcheck-funn, same tal som i HEAD (ingen nye).
Funna i `validate.yml` ligg på linjer som ikkje er endra.

**Står att:** Steg 6 (verifisering etter push til `origin/main`) og steg 7
(fjerne PAT). `RELEASE_PLEASE_TOKEN` er framleis lagra som secret, men vert
ikkje lenger referert i `.github/` (`grep` gir 0 treff).

## Handlingsliste

- [x] 1. Avklar O1–O4 (O1 `linkml-release-bot`, O2 ja, O3 nei, O4 a)
- [x] 2. Opprett og installer appen, generer nøkkel (brukaren) — `linkml-release-bot[bot]` id 334154478
- [ ] 3. (Berre viss veg 2 feilar) Test `Integration`-bypass på ruleset 24036454 (backup først)
- [x] 4. `RELEASE_APP_CLIENT_ID` (variabel) + `RELEASE_APP_PRIVATE_KEY` (secret) (brukaren) — verifisert med `gh variable/secret list`
- [x] 5. Kodeendring i 3 workflowar, actionlint (+ `.github/actionlint.yaml`)
- [ ] 6. Verifiser dispatch og første ekte release-PR
- [ ] 7. Slett secret og trekk tilbake PAT (brukaren)

## Opne spørsmål

- ~~**O1:** Namn på appen?~~ **Avgjort 2026-09-26: `linkml-release-bot`**
  (`linkml-release-bot[bot]`). Ledig per same dato: `github.com/apps/linkml-release-bot`
  og `api.github.com/users/linkml-release-bot[bot]` gir 404.
- ~~**O2:** Skal git-pushane gå som appen?~~ **Avgjort 2026-09-26: ja.**
- ~~**O3:** Skal bypass (veg 1) brukast sjølv om veg 2 fungerer?~~ **Avgjort
  2026-09-26: nei.** Appen skal ikkje stå på bypass-lista. Veg 1 er
  reserveløysing viss veg 2 feilar.
- ~~**O4:** Korleis skal T5 pushast?~~ **Avgjort 2026-09-26: a)**, via API med
  `persist-credentials: false` på checkout for artefakt-generering.

## Avgjerder

- Steg 5: `gh pr merge --auto` brukar `--merge` i staden for `--squash`.
  Commit-filteret i `release-please.yml` slepp berre gjennom `Merge pull request
  #N from …/release-please--branches--main` etter merge. Ein squash-commit
  (`chore: release main (#N)`) vert hoppa over som `chore`, og då vert ingen
  release laga. Feilen fanst frå før, men har aldri slått inn, fordi auto-merge
  aldri har fullført (alle release-PR-ar, både i `brreg` og #1 her, er merga
  manuelt med merge-commit). Han ville slått inn så snart appen gjer at
  auto-merge fungerer. `merge` er tillate i ruleset-en.
- Steg 5: Jobb-løyva for `GITHUB_TOKEN` i `release-please.yml` er reduserte til
  `contents: read` (minste privilegium). Viss noko steg likevel prøver å
  skrive med `GITHUB_TOKEN`, feilar det synleg.
- Steg 5: Token-steget er duplisert i to jobbar, sjølv om CI-DRY-terskelen er
  2+. Ein lokal composite action krev at repoet er sjekka ut, men i
  `release-please.yml` må tokenet hentast *før* første checkout, fordi checkout
  brukar det (`token:`). Grunnen er skriven i ein kommentar i `validate.yml`.
- Steg 5: `.github/actionlint.yaml` er oppretta for å ignorere to `[action]`-funn.
  actionlint 1.7.12 har metadata frå `create-github-app-token` v3.0.0. `client-id`
  kom i v3.1.0 (kontrollert i `action.yml` for v3.0.0/v3.1.0/v3.2.0).
  Ignoreringa er avgrensa til dei to eksakte meldingane for denne actionen.
- Steg 5: `[skip ci]` på dato-commiten er behalde. Han hindrar ikkje
  `pull_request_target`, så veg 2 skal fungere. Verifiserast i 6.3.
- Steg 5: `create-pull-request` i `validate.yml` har framleis standard
  forfattar/committer (ikkje app-identitet). Det er utanfor scopet og påverkar ikkje
  godkjenningsflyten, sidan PR-en ikkje er ein release-PR.
- O1 = `linkml-release-bot` (brukaren, 2026-09-26). Kontrollert at namnet var
  ledig same dag. Viss GitHub likevel avviser namnet ved oppretting, vel eit
  nytt og oppdater `<app-slug>` i `auto-approve`-sjekken tilsvarande.
- O2 = ja, O3 = nei, O4 = a (brukaren, 2026-09-26). Konsekvensar i designet:
  berre «Checkout for release-please» får app-token. Checkout for
  artefakt-generering får `persist-credentials: false`. Per-schema-taggar vert
  laga via `git/tags` + `git/refs`-API, og ruleset-en vert uendra. Steg 3
  (bypass-test) er gjort vilkårsbunde.
- Under utforminga av O4 vart ein latent feil funnen: eksistenssjekken for
  per-schema-taggar går mot ein grunn checkout utan taggar. Han vert retta som
  del av API-omskrivinga, ikkje som eigen bug.
- Lagring (undersøkt 2026-09-26 i `create-github-app-token@v3.2.0`):
  `client-id` vert brukt, ikkje `app-id`, fordi `app-id` er merkt deprecated i
  `action.yml`. Variabelen heiter `RELEASE_APP_CLIENT_ID`. App-ID trengst berre
  som `actor_id` ved eventuell bypass og vert ikkje lagra førebels. Tokenet vert
  avgrensa eksplisitt med `permission-*` i staden for å arve alle
  installasjonsløyva, slik README tilrår.
- O2 utdjupa 2026-09-26: `dismiss_stale_reviews_on_push` gjer at godkjenninga
  frå `opened` vert avvist av dato-commiten. Ny godkjenning krev at pushen
  utløyser `synchronize`, og det gjer han berre som appen. O2 = ja er difor ein
  føresetnad for veg 2, ikkje berre ein fordel.
- Specen er sjølve leveransen for steg 8 i hovudspecen. Han står i
  `specs/backlog/`, fordi ingen tiltak er gjennomførte.
- T2b/T5 (git-push med `GITHUB_TOKEN`) vart oppdaga under kartlegginga og rettar
  ei unøyaktigheit i F9-tabellen i hovudspecen.
