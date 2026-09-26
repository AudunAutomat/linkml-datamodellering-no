# CI etter flytting av origin til AudunAutomat/linkml-datamodellering-no

## Bakgrunn

`origin` er endra frå `brreg/linkml-datamodellering-no` til
`https://github.com/AudunAutomat/linkml-datamodellering-no.git`. Etter
flyttinga feilar workflowane. Denne specen kartlegg kvifor, per workflow, og
foreslår fiksar.

**Metode:** Analysen byrja **statisk** (lesing av `.github/workflows/**`,
`.github/actions/**` og skripta dei kallar), fordi repoet var privat og
lokal `gh` (`AudunVindenesEggeBR`) ikkje hadde tilgang. Etter at repoet vart
gjort offentleg, er funna kontrollerte mot faktiske køyringar
(2026-09-23–26). Funn merkte **[stadfesta]** har støtte i loggane.

**Rammer (avklart med brukaren, 2026-09-26):**
- Repoet er **offentleg** (var privat då første versjon av specen vart skriven).
- **`AudunAutomat/linkml-datamodellering-no` er den nye kanoniske upstreamen.**
  Alle tilvisingar til `brreg/linkml-datamodellering-no`,
  `brreg.github.io/linkml-datamodellering-no` og `ghcr.io/brreg/...` skal
  flyttast til ny eigar.

### Observerte køyringar

| Workflow | Status | Feilande steg | Feilmelding |
|---|---|---|---|
| Validate (schedule, 24.–26.09) | ✗ | `oppsett / build-image / *` → «Sikre … i GHCR» | `invalid reference format: repository name must be lowercase` (`ghcr.io/AudunAutomat/python-pytest:…`) |
| Lenkje- og mermaid-sjekk (schedule, 24.–25.09) | ✗ | `oppsett / build-image / *` (alle 5+) | same som over (exit 125) |
| Generate and publish (push, 23.09) | ✗ | `oppsett / build-image / *` (alle 7) | same som over |
| CodeQL (push, 23.09) | ✗ | «Analyser» (actions, python, javascript-typescript) | `Code scanning is not enabled for this repository` |
| Release Please (push, 23.09) | ✓ | – | Hoppa over av commit-type-filteret før token-steget. F2 er difor **ikkje stadfesta enno** |
| Trivy (push, 23.09) | ✓ | – | – |
| Dependabot | ✓ | – | – |

`gh api repos/AudunAutomat/linkml-datamodellering-no/pages` → `404`: Pages er
ikkje sett opp i det nye repoet.

**Etter fiks (2026-09-26, `a3946dad`):** Alle dei raude workflowane over er
grøne. Detaljar under steg 7. Pages er sett opp
(<https://audunautomat.github.io/linkml-datamodellering-no/>).

## Funn (tverrgåande)

### F1 — Eigarnavnet har store bokstavar → alle GHCR-referansar er ugyldige (kodefeil) [stadfesta]

`github.repository_owner` er no `AudunAutomat`. Referansar til OCI-image
**må** vere berre små bokstavar. `podman pull/push/tag` og `skopeo inspect`
avviser `ghcr.io/AudunAutomat/...` med `repository name must be lowercase`.
Med `brreg` kom dette aldri fram, sidan det navnet berre har små bokstavar.

Staden der `ghcr.io/${{ github.repository_owner }}/...` vert bygd:

| Fil | Linje(r) | Verknad |
|---|---|---|
| `.github/actions/pull-images/action.yml` | 40 | pull feilar, fell stilt tilbake til lokalt bygg (tregt, men ikkje raudt) |
| `.github/workflows/reusable-oppsett.yml` | 133 | `ensure-image`: skopeo seier «finst ikkje» → bygg → `podman tag/push` **feilar** |
| `.github/workflows/modell-analyse.yml` | 42 | same som over, for `python-pytest` |
| `.github/workflows/release.yml` | 24–113 | alle fire image-jobbane feilar på `podman tag/push` |

`ghcr-login` (`podman login ghcr.io -u ${{ github.actor }}`) er uproblematisk:
brukarnavnet ved innlogging skil ikkje mellom store og små bokstavar.

**Fiks:** Rekn ut eit prefiks med berre små bokstavar på **éin** stad og
bruk det overalt (4 filer, over DRY-terskelen for CI-YAML som er 2+, jf.
`.claude/rules/ci-workflows.md`):

- Utvid `.github/actions/compute-image-tags/action.yml` med ein ny output
  `registry`, der verdien er `ghcr.io/${GITHUB_REPOSITORY_OWNER,,}` (bash-lowercase;
  GitHub-uttrykk har ingen `lower()`).
- `reusable-oppsett.yml` (`checkout-source`) sender `registry` vidare som
  job-output ved sida av `image_tags`.
- `ensure-image`-kall: `tag: ${{ needs.checkout-source.outputs.registry }}/<navn>:<hash>`
  (`modell-analyse.yml`: `steps.image-tags.outputs.registry`).
- `pull-images`: ny input `registry`. Alternativt kan du bruke
  `${GITHUB_REPOSITORY_OWNER,,}` direkte i bash, men det gir to kjelder.
- `release.yml`: set `REGISTRY="ghcr.io/${GITHUB_REPOSITORY_OWNER,,}"` i starten
  av kvart `run:`-steg, og bruk `$REGISTRY` i staden for uttrykket.
  `hashFiles()` må framleis stå som uttrykk.

### F2 — Secret `RELEASE_PLEASE_TOKEN` finst ikkje i det nye repoet

Secrets vert ikkje med når origin vert flytta. `RELEASE_PLEASE_TOKEN` er i bruk i:

- `release-please.yml` (linje 114, 121, 160, 213, 240): release-please-action,
  push til PR-branch og `gh pr merge --auto`
- `validate.yml` (linje 278): `peter-evans/create-pull-request` for
  valideringsloggar

Når secreten manglar, vert han ein tom streng, og steget feilar med
`Input required and not supplied: token` eller `Bad credentials`.

**Fiks (manuelt, du må gjere det sjølv):** Lag ein fine-grained PAT og legg han inn
som repo-secret. Framgangsmåten står i F2a under.

#### F2a — Opprett `RELEASE_PLEASE_TOKEN` steg for steg

**Viktig:** Sjølve tokenet kan **ikkje** lagast med `gh` eller REST-API-et.
GitHub har ikkje noko API for å opprette PAT-ar, så det må gjerast i
nettlesaren. `gh` vert brukt til steget etterpå, der tokenet vert lagra som
secret.

**Kven må lage tokenet:** Kontoen `AudunAutomat`. Ein fine-grained PAT kan
berre gje tilgang til repo som tilhøyrer token-eigaren (eller ein organisasjon
han er medlem av). Ein PAT laga av `AudunVindenesEggeBR` kan difor ikkje peike
på `AudunAutomat/linkml-datamodellering-no`.

**1. Lag tokenet i nettlesaren** (innlogga som `AudunAutomat`):

Gå til <https://github.com/settings/personal-access-tokens/new>
(*Settings → Developer settings → Personal access tokens → Fine-grained
tokens → Generate new token*) og fyll ut:

| Felt | Verdi |
|---|---|
| Token name | `release-please linkml-datamodellering-no` |
| Resource owner | `AudunAutomat` |
| Expiration | t.d. 1 år. Set ei påminning i kalenderen, for CI stoppar utan varsel når tokenet går ut |
| Repository access | **Only select repositories** → `linkml-datamodellering-no` |
| Permissions → Repository → **Contents** | Read and write (release-please: CHANGELOG, manifest, taggar, releases; push av schema-datoar til PR-branch) |
| Permissions → Repository → **Pull requests** | Read and write (opprette release-PR-ar, `gh pr merge --auto`, `create-pull-request` i `validate.yml`) |
| Permissions → Repository → **Issues** | Read and write (release-please sine `autorelease: *`-etikettar og `automated`/`validation`-etikettane i `validate.yml` går via issues-API-et) |
| Permissions → Repository → Metadata | Read (vert sett automatisk) |

*Workflows*-løyvet trengst **ikkje**. Ingen av stega som brukar tokenet skriv
til `.github/workflows/`. (Første versjon av specen tilrådde det, men det er
retta av omsyn til minste privilegium.)

Trykk *Generate token* og kopier verdien (`github_pat_…`). Han vert vist
berre éin gong.

**2. Lagre tokenet som secret med `gh`:**

Å setje ein repo-secret krev admin-tilgang til repoet, så `gh` må vere
innlogga som `AudunAutomat`:

```bash
# Legg til AudunAutomat-kontoen i gh (éin gong), eller byt til han:
gh auth login          # vel GitHub.com → HTTPS/SSH → logg inn som AudunAutomat
gh auth switch -u AudunAutomat   # dersom kontoen alt er lagt til

# Set secreten. Kommandoen spør etter verdien interaktivt, så tokenet
# hamnar ikkje i shell-historikken:
gh secret set RELEASE_PLEASE_TOKEN -R AudunAutomat/linkml-datamodellering-no

# Stadfest at han finst (sjølve verdien vert aldri vist):
gh secret list -R AudunAutomat/linkml-datamodellering-no

# Byt tilbake til vanleg konto ved behov:
gh auth switch -u AudunVindenesEggeBR
```

Alternativ utan `gh`: *Repo → Settings → Secrets and variables → Actions →
New repository secret*, med Name `RELEASE_PLEASE_TOKEN` og Secret = tokenet.

**Ikkje bruk `gh auth token | gh secret set …`.** OAuth-tokenet til `gh`
har scope `repo` på **alle** repoa til kontoen, og det vert ugyldig når du
loggar ut av `gh`.

**3. Verifiser:**

```bash
gh workflow run release-please.yml -R AudunAutomat/linkml-datamodellering-no
gh run watch -R AudunAutomat/linkml-datamodellering-no \
  "$(gh run list -R AudunAutomat/linkml-datamodellering-no -w release-please.yml -L 1 --json databaseId -q '.[0].databaseId')"
```

`workflow_dispatch` hoppar over commit-type-filteret, så
`release-please-action` vil faktisk bruke tokenet. Dette steget er òg
verifiseringa av F2 i steg 7.

**Fornying:** Når tokenet går ut, gjer du steg 1–2 på nytt med same
secret-navn. Workflow-filene treng ingen endring.

**Alternativ utan PAT:** Sjå F9. Tilrådinga er å bruke PAT no og
migrere til GitHub App i ein eigen spec etterpå.

**Kvifor PAT og ikkje `GITHUB_TOKEN`:** PR-ar og push gjorde med `GITHUB_TOKEN`
startar ikkje nye workflow-køyringar. Utan PAT vil ikkje `validate.yml` køyre
på release-PR-ane, og auto-merge vil aldri skje.

### F3 — Repo-innstillingar som ikkje vert med ved flytting

| Innstilling | Kvar | Krevd av |
|---|---|---|
| *Workflow permissions* = «Read and write permissions» (eller behald «Read» og stol på eksplisitte `permissions:`-blokker, som alle jobbar har) | Settings → Actions → General | alle |
| **«Allow GitHub Actions to create and approve pull requests»** = på | Settings → Actions → General | `auto-approve-release-please.yml` (`gh pr review --approve` med `GITHUB_TOKEN`) |
| **«Allow auto-merge»** = på | Settings → General → Pull Requests | `release-please.yml` (`gh pr merge --auto`) |
| **GitHub Pages → Source = «GitHub Actions»** [stadfesta: Pages-API gir 404] | Settings → Pages | `generate.yml` / `publish` (`configure-pages` feilar med `Get Pages site failed` utan dette) |
| Miljøet `github-pages` utan branch-avgrensing som stengjer `main` ute | Settings → Environments | `generate.yml` / `publish` |
| **Ruleset `main protection` på `main`** [stadfesta: manglar, `protected: false`], sjå F8 | Settings → Rules → Rulesets | beskyttar `main`; styrer auto-merge av release-PR-ar |
| **Code scanning slått på** [stadfesta: `Code scanning is not enabled`] — gratis for offentlege repo; vel «Advanced setup», sidan repoet har eigen `codeql.yml` | Settings → Code security | `codeql.yml`, `trivy.yml` (`upload-sarif`) |

Repoet er no offentleg (O1). Pages og code scanning/SARIF-opplasting krev
difor verken betalt plan eller GitHub Advanced Security. Dei må berre slåast på.

### F4 — GHCR-pakkar: første push under ny eigar

Første `podman push` til `ghcr.io/audunautomat/<image>` opprettar pakken og
koplar han til repoet, sidan `GITHUB_TOKEN` har `packages: write`. Det krev
ingen ny secret. **Men** dersom ein pakke med same navn alt finst under
`audunautomat` og ikkje er kopla til dette repoet (t.d. frå ein tidlegare
test), får du `403 permission_denied: write_package`. Fiks: Package settings →
*Manage Actions access* → legg til repoet med rolla *Write*.

Pakkane vert **private** som standard, sjølv om repoet er offentleg. Det er
greitt for CI-en i repoet sjølv. Men sidan AudunAutomat no er upstream (O2),
kan eksterne kallarar av `reusable-*.yml` (sjå F6) og lokale brukarar som
hentar `mcp-linkml-*`-image ikkje hente dei før synlegheita er sett til
*Public* (Package settings → Change visibility), per image.

## Funn per workflow

| Workflow | Trigger | Venta feil | Årsak | Fiks | Resultat etter fiks (steg 7) |
|---|---|---|---|---|---|
| `generate.yml` | push/dispatch | `oppsett / build-image / *` raud på `podman tag/push`; `publish` raud på `configure-pages` | F1, F3 (Pages) | F1-kode + slå på Pages (Actions) | ✅ 36230891223: alle `build-image` grøne, portal publisert |
| `validate.yml` | PR/schedule/dispatch | `oppsett / build-image / *` raud (F1); `create-pr-with-validation-logs` raud (token) | F1, F2 | F1-kode + `RELEASE_PLEASE_TOKEN` | ✅ 36231138870. Token ikkje brukt (ingen nye loggar, ingen PR) |
| `modell-analyse.yml` | schedule/dispatch | `ensure-images` raud → alle nedstraums-jobbar vert hoppa over | F1 | F1-kode | ✅ 36231141184 |
| `lenkje-og-mermaid-sjekk.yml` | schedule/dispatch | `oppsett` raud (F1). Mermaid-sjekken testar `https://brreg.github.io/...` og gir falske resultat eller feil dersom brreg-portalen ikkje lenger vert oppdatert | F1, F5 | F1-kode + F5 | ✅ 36231265932 mot ny portal, inkl. `lenkjesjekk` og `mermaid-click-href-sjekk` |
| `release-please.yml` | push/dispatch | release-please-steget raud (manglar token); auto-merge feilar utan «Allow auto-merge» | F2, F3 | secret + innstillingar | ⏸ push-køyring grøn, men hoppa over; manuell køyring utsett til steg 9 (F10). F2 ikkje verifisert |
| `auto-approve-release-please.yml` | pull_request_target | Hoppar over eller feilar: `github.actor` vert `AudunAutomat` (eigaren av PAT-en), ikkje `AudunVindenesEggeBR`; `gh pr review --approve` krev «Allow GitHub Actions to … approve» | F3, hardkoda aktør | byt/utvid aktør (sjå steg 4) + innstilling | ⏸ ikkje utløyst (ingen release-PR enno). Innstillinga `can_approve_pull_request_reviews: true` er stadfesta |
| `release.yml` | push av tag/dispatch | alle fire `podman push` raude | F1 | F1-kode | ⏸ ikkje køyrd (krev tag `v*.*.*`). Same F1-fiks er lint-verifisert (actionlint) |
| `codeql.yml` | push/PR/schedule | `Analyser` raud: code scanning er ikkje slått på **[stadfesta]** | F3 | slå på code scanning | ✅ push-køyring på `a3946dad` |
| `trivy.yml` | push/schedule | `upload-sarif` vil feile av same grunn (grøn 23.09, men `scan-requirements` er ikkje kontrollert i detalj) | F3 | slå på code scanning | ✅ push-køyring på `a3946dad` |
| `reusable-*.yml` | workflow_call | Vert ikkje køyrde direkte, så dei gir ikkje raude køyringar. Men dei hentar kode og image frå `brreg/...` (F6) | F6 | steg 6 | ⏸ ikkje testa frå eksternt repo. Krev taggar (F10), `release.yml`-køyring og offentlege pakkar (2f) |

Merk: `auto-approve` godkjenner ein PR oppretta av same konto som eig
PAT-en. GitHub nektar ein brukar å godkjenne sin eigen PR, men her godkjenner
`github-actions[bot]` via `GITHUB_TOKEN`, og det er tillate når F3-innstillinga
er på.

### F5 — Hardkoda `brreg`-URL-ar i portal- og lenkjesjekk (ikkje-blokkerande)

Desse gir ikkje raude køyringar i seg sjølve (unnateke mermaid-sjekken), men
portalen peikar framleis til brreg:

- `mkdocs/publish.sh:52,67,118,549,552` (`site_url`, GitHub-lenkjer)
- `mkdocs/lib/sections/{datamodell,generated_artifacts,kontakt}.sh`,
  `mkdocs/lib/scripts/generate-modellanalyse-md.py:167`
- `src/assets/scripts/makefile/{generate-readme-tables.sh,update-modellkatalog.py,generate-informasjonsmodell.py}`
  (fallback-URL-ar; `generate-informasjonsmodell.py` brukar alt
  `GITHUB_REPOSITORY` i CI)
- `.github/workflows/lenkje-og-mermaid-sjekk.yml:245`, `.github/lychee.toml:77`
- `.github/renovate.json:9,15`, `.github/CODEOWNERS` (`@AudunVindenesEggeBR`
  må ha tilgang til nytt repo, elles vert regelen ignorert)

Sidan AudunAutomat er kanonisk (O2), skal `site_url` vere
`https://audunautomat.github.io/linkml-datamodellering-no`. Pages-URL-en er
alltid med små bokstavar. GitHub-URL-ar
(`github.com/AudunAutomat/...`) kan behalde store bokstavar.

Mermaid-sjekken i `lenkje-og-mermaid-sjekk.yml:245` testar i dag brreg-portalen,
som ikkje lenger vert oppdatert frå dette repoet. Sjekken er grøn, men
resultatet er meiningslaust til URL-en er bytt **og** første publisering til
den nye Pages-sida har gått gjennom.

Obs: `CHANGELOG.md`-filer og `specs/done/` inneheld historiske
`brreg`-lenkjer. Dei skal **ikkje** skrivast om (arkiv / genererte av
release-please).

### F6 — Reusable workflows hentar frå `brreg/...`

`reusable-generate.yml:64,94`, `reusable-lint.yml:55,81` og
`reusable-validate.yml:54,68` hentar kjeldekode og
`ghcr.io/brreg/<image>` på ein fast måte. Sidan `AudunAutomat` no er upstream (O2),
er dette feil: eksterne kallarar vil få kode og image frå den gamle
upstreamen. `repository:` skal vere `AudunAutomat/linkml-datamodellering-no`,
og image-referansane skal vere `ghcr.io/audunautomat/...` (små bokstavar, jf.
F1). Her kan ein **ikkje** bruke `github.repository_owner`: i ein reusable
workflow er det eigaren av det *kallande* repoet. Verdien må difor vere
hardkoda, eller komme frå éin felles `env`-verdi per fil.

Merk: eksterne kallarar vil truleg peike på
`brreg/linkml-datamodellering-no/.github/workflows/reusable-*.yml@<ref>` i
sine eigne workflowar. Dei må sjølve byte til den nye stien. Dokumentasjonen i
`mkdocs/docs/arkitektur/ekstern-bruk.md` må oppdaterast.

### F7 — Evaluering: bør GitHub-brukarnavnet endrast til berre små bokstavar?

**Spørsmål (brukaren, 2026-09-26):** Bør kontoen `AudunAutomat` få nytt
brukarnavn med berre små bokstavar (t.d. `audunautomat`), slik at F1
forsvinn?

**Avgrensing:** Det gjeld *GitHub-login-en* (kontoen `AudunAutomat`, type
`User`, oppretta 2021, 3 offentlege repo). Den lokale `git config user.name`
(«Audun Vindenes Egge») har ingenting å seie for CI og treng ikkje endrast.

**Kva ei endring til små bokstavar ville løyse:**
- `github.repository_owner` og `github.actor` ville returnere
  `audunautomat`. Då vert `ghcr.io/${{ github.repository_owner }}/...` gyldig
  utan kodeendring, og CI vert grøn raskt (F1 forsvinn i praksis).
- Brukarnavnet vert likt på alle stader (GHCR og Pages brukar alltid små
  bokstavar).

**Kostnad og risiko:**
- Det er ei omdøyping av kontoen. GitHub vidaresender repo-URL-ar og
  git-remote for dei 3 offentlege repoa, men profil-URL-en vert ikkje vidaresend.
  Sidan navnet berre skil seg i store og små bokstavar, er
  `github.com/AudunAutomat/...` og `github.com/audunautomat/...` likeverdige
  (GitHub skil ikkje mellom store og små bokstavar i URL-ar). Risikoen for brot er difor
  låg. Det finst heller ingen risiko for at andre tek det gamle navnet.
- Det vil påverke andre repo og integrasjonar på same konto som
  eventuelt skil mellom store og små bokstavar (t.d. hardkoda `AudunAutomat`
  i andre workflowar). Det er ikkje undersøkt, sidan det ligg utanfor dette repoet.
- **Det løyser ikkje feilen i koden.** Koden føreset framleis at eigaren
  berre har små bokstavar. Den same feilen kjem att for:
  - kvar fork eller mirror under ein konto eller organisasjon med store bokstavar
    (`pull-images`, `ensure-image`, `release.yml` køyrer i forken sin kontekst)
  - ei framtidig flytting til ein organisasjon med store bokstavar
  Det er ein stille føresetnad av same type som gjorde at F1 ikkje vart oppdaga
  medan eigaren var `brreg`.

**Tilråding:** **Ikkje** endre brukarnavnet som løysing på F1. Gjennomfør
kodefiksen i steg 3 (lowercase-prefiks frå `compute-image-tags`), som
gjer CI robust uavhengig av korleis eigarnavnet er skrive. Å endre
brukarnavnet til små bokstavar er eit reint kosmetisk val som brukaren kan
gjere uavhengig av denne specen. Det er ufarleg etter at steg 3 er gjort,
men skal ikkje nyttast som erstatning for steg 3.

**Eventuell mellombels bruk:** Dersom CI må bli grøn *før* steg 3 er
gjort, kan ei endring til små bokstavar fungere som mellombels løysing. Steg 3 skal
likevel gjennomførast, og det skal testast (t.d. med ein fork under ein
konto med store bokstavar, eller ved å setje `GITHUB_REPOSITORY_OWNER`
manuelt i ein test-dispatch) at prefikset vert gjort om til små bokstavar.

### F8 — Branch protection på `main` forsvann ved flyttinga [stadfesta]

**Observasjon (2026-09-26):**

| Repo | `branches/main.protected` | Rulesets |
|---|---|---|
| `brreg/linkml-datamodellering-no` | `true` | `main protection` (id 16642329, **active**), `Code Quality Copilot review for default branch` (id 19469602, **disabled**) |
| `AudunAutomat/linkml-datamodellering-no` | `false` | ingen |

Rulesets og klassisk branch protection høyrer til repoet på GitHub, ikkje til
git-historikken, så dei vert ikkje med når origin vert bytt eller innhaldet
vert pusha til eit nytt repo. Det gamle repoet brukte **berre rulesets** (ingen
klassisk branch protection: `required_status_checks.enforcement_level: off`).

**Oppsett i `brreg` (sist endra 2026-07-02), som skal gjenskapast:**

| Regel | Verdi | Tyding |
|---|---|---|
| Mål | `~DEFAULT_BRANCH` | gjeld `main` (default branch) |
| `deletion` | på | `main` kan ikkje slettast |
| `non_fast_forward` | på | ingen force-push til `main` |
| `pull_request.required_approving_review_count` | 1 | endringar må gå via PR med 1 godkjenning |
| `dismiss_stale_reviews_on_push` | true | ny push fjernar tidlegare godkjenning |
| `require_last_push_approval` | true | den siste pushen må godkjennast av ein annan enn den som pusha |
| `require_extra_approval_for_unattributed_changes` | true | commit-ar utan kjend forfattar krev ekstra godkjenning |
| `require_code_owner_review` | false | CODEOWNERS er rettleiande, ikkje påkravd |
| `required_review_thread_resolution` | false | – |
| `allowed_merge_methods` | merge, squash, rebase | – |
| **Påkravde status checks** | **ingen** | sjå merknad under |
| `bypass_actors` | `RepositoryRole` id 5 (= **Admin**), `bypass_mode: always` | admin kan merge eller pushe utan godkjenning |

**Merknad om status checks:** `specs/done/auto-merge-release-pr.md` (AM0)
skildrar at ruleset-en tidlegare hadde status-sjekken `validate` som påkravd.
Den sjekken er ikkje med i ruleset-en slik han ser ut no (fjerna på eit
tidspunkt fram til 2026-07-02). «Tilsvarande som før» vert her tolka som
**slik han var sist**, altså utan påkravd status check. Sjå
Avgjerder.

**Samspel med release-please og auto-merge:** Admin-bypass er det som gjer
at release-PR-ane kan auto-mergast utan menneskeleg godkjenning. `gh pr merge
--auto` køyrer med `RELEASE_PLEASE_TOKEN`, og eigaren av tokenet er admin (jf.
AM1 i `specs/done/auto-merge-release-pr.md`). I det nye repoet er
`AudunAutomat` både eigar av tokenet (F2a) og eigar av repoet, altså admin.
Same mekanisme fungerer difor utan endring, så lenge tokenet er laga av
`AudunAutomat`.

**Merk: reviewarar.** `AudunVindenesEggeBR` har ikkje push-tilgang til det
nye repoet (`collaborators`-API-et gir 403). Med «1 godkjenning» og «siste
push må godkjennast av ein annan» kan PR-ar i praksis berre mergast via
admin-bypass (`AudunAutomat`), med mindre ein annan konto vert lagd til som
collaborator med *Write*. Dersom `AudunVindenesEggeBR` skal vere reviewar
(slik `.github/CODEOWNERS` legg opp til), må kontoen inviterast:
*Settings → Collaborators → Add people* (eller
`gh api -X PUT repos/AudunAutomat/linkml-datamodellering-no/collaborators/AudunVindenesEggeBR -f permission=push`).

#### F8a — Gjenskap ruleset-en

Rulesets er gratis på offentlege repo under personlege kontoar (O1).

**Alternativ A: import av JSON (tilrådd, gir eksakt kopi).**

1. Lagre denne JSON-en som `main-protection.json` (eksportert frå
   `brreg`-ruleset-en 2026-09-26, med `id`, `_links` og tidsstempel fjerna):

   ```json
   {
     "name": "main protection",
     "target": "branch",
     "enforcement": "active",
     "conditions": {
       "ref_name": { "include": ["~DEFAULT_BRANCH"], "exclude": [] }
     },
     "rules": [
       { "type": "deletion" },
       { "type": "non_fast_forward" },
       {
         "type": "pull_request",
         "parameters": {
           "required_approving_review_count": 1,
           "dismiss_stale_reviews_on_push": true,
           "require_code_owner_review": false,
           "require_last_push_approval": true,
           "required_review_thread_resolution": false,
           "require_extra_approval_for_unattributed_changes": true,
           "dismissal_restriction": { "enabled": false, "allowed_actors": [] },
           "required_reviewers": [],
           "allowed_merge_methods": ["merge", "squash", "rebase"]
         }
       }
     ],
     "bypass_actors": [
       { "actor_id": 5, "actor_type": "RepositoryRole", "bypass_mode": "always" }
     ]
   }
   ```

   Du kan òg eksportere direkte frå det gamle repoet. Det krev admin på `brreg`,
   som `AudunVindenesEggeBR` har:
   ```bash
   gh auth switch -u AudunVindenesEggeBR
   gh api repos/brreg/linkml-datamodellering-no/rulesets/16642329 \
     --jq '{name, target, enforcement, conditions, rules, bypass_actors}' > main-protection.json
   ```

2. Importer, innlogga som `AudunAutomat` (krev admin på det nye repoet):
   ```bash
   gh auth switch -u AudunAutomat
   gh api -X POST repos/AudunAutomat/linkml-datamodellering-no/rulesets \
     --input main-protection.json
   ```
   I nettlesaren: *Settings → Rules → Rulesets → New ruleset → Import a
   ruleset* → vel `main-protection.json` → *Create*.

   Dersom API-et avviser eitt av dei nyare parameterfelta (t.d.
   `require_extra_approval_for_unattributed_changes` eller
   `dismissal_restriction`), fjern berre det feltet, prøv på nytt, og logg
   avviket under Avgjerder.

**Alternativ B: manuelt i nettlesaren.** *Settings → Rules → Rulesets → New
ruleset → New branch ruleset*:
- Ruleset name: `main protection`, Enforcement status: **Active**
- Bypass list: *Add bypass* → **Repository admin** → *Always allow*
- Target branches: *Add target* → **Include default branch**
- Kryss av: **Restrict deletions**, **Block force pushes**, **Require a pull
  request before merging** med:
  - Required approvals: **1**
  - **Dismiss stale pull request approvals when new commits are pushed**
  - **Require approval of the most recent reviewable push**
  - Allowed merge methods: Merge, Squash, Rebase
- *Ikkje* kryss av Require status checks, Require code owner review eller
  Require conversation resolution (jf. tabellen over)
- *Create*

**Valfritt: Copilot-ruleset-en.** `Code Quality Copilot review for default
branch` var **disabled** i `brreg`. Han trengst ikkje for å få same
beskyttelse. Viss du vil ha han med for fullstendigheita (framleis disabled):
```bash
gh api repos/brreg/linkml-datamodellering-no/rulesets/19469602 \
  --jq '{name, target, enforcement, conditions, rules}' > copilot-review.json   # som AudunVindenesEggeBR
gh api -X POST repos/AudunAutomat/linkml-datamodellering-no/rulesets --input copilot-review.json   # som AudunAutomat
```
Copilot code review krev at kontoen har Copilot-abonnement dersom han vert
aktivert.

**Verifiser:**
```bash
gh api repos/AudunAutomat/linkml-datamodellering-no/branches/main --jq .protected   # → true
gh api repos/AudunAutomat/linkml-datamodellering-no/rules/branches/main \
  --jq '.[].type'                                                                   # → deletion, non_fast_forward, pull_request
```
Prøv i tillegg `git push --force-with-lease` til `main` frå ein konto som ikkje
er admin (dersom du har lagt til ein). Den skal verte avvist.

**Rekkjefølgje:** Ruleset-en kan setjast opp med ein gong. Han har ingen
påkravde status checks, så han er ikkje avhengig av F1-fiksen. Men
auto-merge av release-PR-ar (steg 7) føreset at `RELEASE_PLEASE_TOKEN` er
laga av `AudunAutomat` (F2a), slik at admin-bypass slår inn.

#### F8b — Verifisering av gjenskapt ruleset (2026-09-26)

Ruleset `main protection` (id 24036454) i `AudunAutomat/linkml-datamodellering-no`
er samanlikna felt for felt med `brreg`-ruleset 16642329 (`name`, `target`,
`enforcement`, `conditions`, `rules`, `bypass_actors`, sorterte JSON-ar
via `diff`):

- Identisk: `enforcement: active`, mål `~DEFAULT_BRANCH`, `deletion`,
  `non_fast_forward`, `pull_request` med `required_approving_review_count: 1`,
  `dismiss_stale_reviews_on_push: true`, `require_last_push_approval: true`,
  `require_extra_approval_for_unattributed_changes: true`,
  `require_code_owner_review: false`, `required_review_thread_resolution: false`,
  `allowed_merge_methods: [merge, squash, rebase]`, og bypass for
  Repository admin (`always`).
- Einaste skilnad: `dismissal_restriction: {enabled: false, allowed_actors: []}`
  manglar i det nye. Det er standardverdien (avslått), så åtferda er den same.
  Feltet vert truleg ikkje sett på personlege repo, der det ikkje finst team
  eller brukarar å avgrense til.
- Effektive reglar på `main` (`rules/branches/main`): `deletion`,
  `non_fast_forward`, `pull_request`, alle frå ruleset 24036454.

### F9 — Evaluering: kan vi slutte å bruke ein PAT som er knytt til brukaren?

**Spørsmål (brukaren, 2026-09-26):** No som repoet ligg under brukaren sin
eigen konto, er det mogleg å sleppe `RELEASE_PLEASE_TOKEN` som personleg
tilgangstoken (PAT)? Kva alternativ finst?

**Tidlegare vurdering:** `specs/done/alternativ-til-pat-release-please.md`
tilrådde ein GitHub App (alternativ A), men han vart ikkje gjennomført, fordi
han kravde tilgang til organisasjonsinnstillingane i `brreg`. I staden vart
manuell release (alternativ C) innført, og seinare erstatta av PAT med
auto-merge (`specs/done/auto-merge-release-pr.md`). Forsøket på å leggje
`github-actions[bot]` på bypass-lista vart avvist med 422.

#### Kva tokenet må kunne

| # | Handling | Stad | Kvifor ikkje `GITHUB_TOKEN`? |
|---|---|---|---|
| T1 | Opprette release-PR-ar | `release-please.yml:114` | PR-ar frå `GITHUB_TOKEN` startar ikkje `validate.yml` (loop-vern) |
| T2 | Pushe schema-datoar til PR-branch | `release-please.yml:121,150` | same: push startar ikkje nye køyringar |
| T3 | `gh pr merge --auto` forbi krav om 1 godkjenning | `release-please.yml:160,174` | `github-actions[bot]` kan ikkje stå på bypass-lista (422, jf. AM1) |
| T4 | Opprette GitHub-release/tag (release-please ved merge) og laste opp artefakter | `release-please.yml:114,213` | tag-push frå `GITHUB_TOKEN` startar ikkje `release.yml` (`on: push: tags`) |
| T5 | Pushe per-schema-taggar | `release-please.yml:240,271` | same som T4 |
| T6 | PR med valideringsloggar | `validate.yml:278` | same som T1 |

#### Kva flyttinga har endra

1. **Hindringa for GitHub App er borte.** Ein personleg konto kan sjølv lage
   ein GitHub App og installere han på eigne repo, utan
   organisasjonsadministrator.
2. **Personrisikoen med PAT er mindre.** Repoeigar og token-eigar er no same
   person, så det at nokon sluttar i organisasjonen knekkjer ikkje lenger CI. Desse
   ulempene står att:
   - tokenet går ut (maks 1 år)
   - handlingar vert logga som brukaren, ikkje som ein bot
   - release-PR-ar har brukaren som forfattar
   - ein lekk gir tilgang *som brukaren* innanfor repoet
3. **Kravet om 1 godkjenning kan i praksis berre oppfyllast via bypass.**
   `AudunAutomat` er einaste konto med skrivetilgang (F8). Andre enn admin kan
   ikkje godkjenne, og admin treng ikkje godkjenning. Det opnar for alternativ C
   under.

#### Alternativ

**A. Behald fine-grained PAT (F2a) — status quo.**
- ✅ Ingen kodeendring, fungerer i dag med admin-bypass.
- ❌ Knytt til brukaren; må fornyast manuelt; handlingar vert logga som
  brukaren; auto-approve-workflowen må kjenne att brukaren som aktør (steg 4).

**B. GitHub App eigd av `AudunAutomat` (tilrådd).**
- Brukaren lagar ein privat app (t.d. `linkml-release-bot`) under
  *Settings → Developer settings → GitHub Apps → New GitHub App*:
  - webhook av
  - Repository permissions: Contents RW, Pull requests RW, Issues RW
    (Metadata R vert sett automatisk)
  - «Only on this account»
- Installer appen på berre `linkml-datamodellering-no`.
- Lagre App-ID som repo-*variabel* `RELEASE_APP_ID` (ikkje hemmeleg) og den
  private nøkkelen som secret `RELEASE_APP_PRIVATE_KEY`.
- Workflowane hentar eit installasjonstoken ved kvar køyring:
  ```yaml
  - uses: actions/create-github-app-token@v2
    id: app-token
    with:
      app-id: ${{ vars.RELEASE_APP_ID }}
      private-key: ${{ secrets.RELEASE_APP_PRIVATE_KEY }}
  # … token: ${{ steps.app-token.outputs.token }}
  ```
  Dette erstattar dei 6 stadene i T1–T6. I `release-please.yml` bør det skje
  éin gong per jobb, og alle stega brukar same `steps.app-token.outputs.token`.
- **T3 (godkjenning):** To moglege vegar, som må verifiserast i denne
  rekkjefølgja:
  1. Legg appen til `bypass_actors` i `main protection` (`actor_type:
     Integration`, `actor_id: <App-ID>`). I motsetnad til
     `github-actions[bot]` er dette ein installert app på repoet, så 422-feilen
     frå AM1 skal ikkje gjelde. Det er **ikkje verifisert** for rulesets på
     personlege repo. Test med `gh api -X PUT …/rulesets/<id>` før
     kodeendringa.
  2. Fallback utan bypass: `auto-approve-release-please.yml` godkjenner
     PR-en med `GITHUB_TOKEN` (`github-actions[bot]`). Sidan PR-en og siste
     push kjem frå `<app-slug>[bot]` og ikkje frå `github-actions[bot]`, vert
     både «1 godkjenning» og «siste push må godkjennast av ein annan» oppfylte.
     Krev at `if:`-sjekken i auto-approve-workflowen vert utvida til
     `<app-slug>[bot]`, og at F3-innstillinga «Allow GitHub Actions to …
     approve pull requests» er på.
- ✅ Ikkje knytt til brukaren som aktør: handlingar vert logga som
  `<app-slug>[bot]`.
- ✅ Token lever 1 time og vert laga automatisk. Ingen utløpsdato å fornye.
- ✅ Hendingar frå app-token startar workflowar (T1, T2, T4–T6 fungerer som med PAT).
- ✅ Appen kan flyttast til ein organisasjon seinare (*Transfer ownership*).
- ❌ Kodeendring i `release-please.yml`, `validate.yml` og
  `auto-approve-release-please.yml`, og `actionlint` må køyrast etterpå.
- ❌ Den private nøkkelen er ein langlevd hemmelegheit. Han utløper ikkje, men
  må roterast ved mistanke om lekkasje.

**C. Berre `GITHUB_TOKEN` + mjukare ruleset.**
- Set `required_approving_review_count` til 0 (PR er framleis påkravd,
  og force-push og sletting er framleis blokkert). Med éin maintainer vert ingen
  reell kontroll borte, sjå punkt 3 over.
- ❌ T1/T2/T6: `validate.yml` køyrer ikkje på release- og logg-PR-ar.
  Det kan omgåast med `gh workflow run validate.yml --ref <branch>`
  (`workflow_dispatch` frå `GITHUB_TOKEN` *startar* workflowar), men då vert
  resultatet ikkje kopla til PR-en som status check.
- ❌ T4/T5: Tag-push startar ikkje `release.yml`, og merge av release-PR
  startar ikkje `release-please.yml` på `main`. Det krev eksplisitt kjeding
  (`gh workflow run release.yml -f …`), som gjer kjeda meir samankopla og
  skjør.
- ❌ Svekkjer F8 («tilsvarande som før») og må løysast på nytt dersom fleire
  maintainerar kjem til.
- ✅ Ingen hemmelegheiter i det heile.

**D. Manuell release (historisk alternativ C).**
- `release-please.yml` berre med `workflow_dispatch` og `GITHUB_TOKEN`. Admin
  mergar release-PR-en sjølv.
- ✅ Ingen hemmelegheiter. ❌ Ikkje automatisk. Har dei same
  trigger-problema som C for `validate.yml` og `release.yml`. Vart forlate
  før av den grunnen.

**E. Deploy key (SSH).**
- Kan stå på bypass-lista, og push via deploy key startar workflowar.
- ❌ Gir berre git-tilgang, ikkje API. Løyser T2 og T5, men ikkje T1, T3, T4
  eller T6. Er difor ikkje nok åleine, og ein kombinasjon med `GITHUB_TOKEN`
  gir to mekanismar å halde ved like.

#### Samanlikning

| | A PAT | **B App** | C GITHUB_TOKEN | D Manuell | E Deploy key |
|---|---|---|---|---|---|
| Knytt til brukaren | ja | **nei** | nei | nei | nei |
| Hemmelegheit som går ut | ja (≤1 år) | **nei** | – | – | nei |
| Full automatikk (T1–T6) | ja | **ja** | delvis, med kjeding | nei | nei |
| Behald ruleset frå F8 | ja | **ja** | nei | ja | ja |
| Kodeendring | nei | **moderat** | stor | moderat | stor |

#### Tilråding

**B (GitHub App)**, i to fasar:

1. **No:** Bruk PAT etter F2a for å få CI grøn att raskt. Det er éin secret
   og ingen kodeendring.
2. **Deretter:** Migrer til GitHub App som ein **eigen spec**
   (`specs/backlog/github-app-for-release-please.md`). Det er ei
   kodeendring i tre workflowar med eigen verifisering, og ho høyrer ikkje til i
   feilrettinga etter flyttinga. Start med å verifisere bypass-støtta (B, punkt
   T3.1) før workflowane vert endra. Når appen fungerer: slett
   `RELEASE_PLEASE_TOKEN` og trekk tilbake PAT-en.

Dersom du heller vil hoppe over PAT-steget, kan B gjerast direkte. CI for
release vil då vere raud til B er ferdig. Resten av CI (F1, F3) er
uavhengig av valet.

### F10 — Taggane manglar i det nye repoet [stadfesta]

`git ls-remote --tags origin` gir **0 taggar** (2026-09-26). Git-taggar
vert ikkje med når berre branchar vert overførte, og GitHub Releases (med
opplasta artefakter) høyrer til repoet på GitHub og vert heller ikkje med.
Konsekvensar:

- **release-please** finn ikkje førre release per komponent (tag
  `<komponent>-vX.Y.Z`). Då kan han rekne alle commit-ar sidan byrjinga som
  nye, og det kan gi store eller feil CHANGELOG-ar og versjonshopp i neste
  release-PR.
- **Versjonslåste skjema-importar** (`raw.githubusercontent.com/<eigar>/…/<komponent>-vX.Y.Z/…`)
  og `bootstrap.sh`/`kom_i_gang.sh`/`new-modell.sh` (versjons-ref) kan
  **ikkje** flyttast til `AudunAutomat` før taggane finst der. Difor er desse
  haldne utanfor steg 5 (sjå Avgjerder). Dei peikar framleis på `brreg`.
- **Reusable workflows** (steg 6) sjekkar ut `AudunAutomat/…@vX.Y.Z` og hentar
  `ghcr.io/audunautomat/<image>:vX.Y.Z|latest`. Eksterne kallarar vil feile
  til (a) taggane finst i det nye repoet, (b) `release.yml` har køyrt i
  det nye repoet, og (c) pakkane er sette til *Public* (F4).

**Tiltak:** Taggane frå `brreg` må overførast til det nye repoet **før
neste release-please-køyring som lagar ein release-PR**. Sjå steg 9.

## Steg

1. **Verifiser hypotesane mot loggar.** ~~Hent køyringsloggar~~ — gjort
   2026-09-26 etter at repoet vart offentleg. F1 og code scanning (F3) er
   stadfesta, og Pages manglar. F2 (`RELEASE_PLEASE_TOKEN`) er framleis
   ustadfesta, sidan release-please-steget vart hoppa over. Kontroller det i steg 7.
2. **Repo-innstillingar og secret (manuelt, du må gjere det sjølv)**, jf. F2, F3 og F4:
   `RELEASE_PLEASE_TOKEN`, Actions-løyve, auto-merge, Pages-kjelde,
   `github-pages`-miljø, code scanning (Advanced setup), og GHCR-pakkane sett
   til *Public* etter første vellukka push.
3. ✅ **F1 — lowercase GHCR-prefiks** (kode, utført 2026-09-26, sjå Avgjerder for avvik frå skissa): `compute-image-tags` får
   `registry`-output; `reusable-oppsett.yml`, `modell-analyse.yml`,
   `pull-images`, `release.yml` vert oppdaterte. Køyr `actionlint` på alle endra
   workflow-filer.
4. ✅ **Auto-approve-aktør** (utført 2026-09-26): erstatt `'AudunVindenesEggeBR'` i
   `auto-approve-release-please.yml:14` med eigaren av PAT-en (`AudunAutomat`)
   eller, betre, sjekk
   `github.event.pull_request.user.login == github.repository_owner`, slik at
   det ikkje er hardkoda. Køyr `actionlint`.
5. ✅ **F5 — portal-URL-ar** (utført 2026-09-26 for kategoriane
   «portal/skript/CI» og «dokumentasjonsprosa», som brukaren valde. 47 filer, 369
   utskiftingar + prosa-/mermaid-etikettar): byt
   `brreg` → `AudunAutomat`/`audunautomat` i lista i F5, helst via éi kjelde
   (t.d. `GITHUB_REPOSITORY` med fallback frå `.git/config`, slik
   `generate-informasjonsmodell.py` alt gjer), for å unngå ny hardkoding.
6. ✅ **F6 — reusable workflows** (utført 2026-09-26): byt `repository:` til
   `AudunAutomat/linkml-datamodellering-no` og `ghcr.io/brreg` til
   `ghcr.io/audunautomat` i `reusable-{generate,lint,validate}.yml`, inkludert
   `::error::`-meldingane og steg-navna som nemner brreg. Oppdater
   `mkdocs/docs/arkitektur/ekstern-bruk.md`. Køyr `actionlint`.
7. **Verifiser:** `workflow_dispatch` på `generate.yml`, `validate.yml`,
   `modell-analyse.yml`, `release-please.yml` (dispatch hoppar over
   commit-type-filteret, så F2 vert testa), `codeql.yml`. Sjekk at image har
   kome i `ghcr.io/audunautomat/*`, og at portalen er publisert på
   `https://audunautomat.github.io/linkml-datamodellering-no/`. Køyr deretter
   `lenkje-og-mermaid-sjekk.yml` mot den nye portalen.
   **Status 2026-09-26 (delvis, blokkert):**
   - **Blokkering 1:** Endringane frå steg 3–6 finst berre lokalt.
     `origin/main` = `d0c54109`, og `workflow_dispatch` køyrer koden i
     origin. Verifisering av F1/F5/F6 i CI må difor vente til endringane
     ligg i `origin/main`.
   - **Blokkering 2:** `gh` er innlogga som `AudunVindenesEggeBR`, som ikkje
     har skrivetilgang. `gh workflow run` krev `gh auth switch -u
     AudunAutomat` (eller at kontoen vert invitert, steg 2h).
   - **Kontroll av steg 2 via offentleg API:**
     | Innstilling | Resultat |
     |---|---|
     | `branches/main.protected` | ✅ `true` |
     | Ruleset `main protection` (id 24036454) | ⚠️ aktiv, men har **berre** `deletion` + `non_fast_forward`. **`pull_request`-regelen (1 godkjenning, dismiss stale, last-push-approval) manglar**, jamfør F8. Moglege årsaker: importen droppa regelen, eller han vart ikkje kryssa av ved manuelt oppsett |
     | Pages | ✅ `build_type: workflow`, `https://audunautomat.github.io/linkml-datamodellering-no/` |
     | Synlegheit | ✅ `public` |
     | `allow_auto_merge`, bypass-liste, code scanning, secret | ❓ krev admin-tilgang, kan ikkje lesast som `AudunVindenesEggeBR` |
   - Siste køyringar (schedule 26.09) er framleis raude med F1-feilen, som
     venta: dei køyrer koden i origin.
   **Status 2026-09-26 (etter push av `a3946dad`, `gh` som `AudunAutomat`):**
   | Workflow | Køyring | Resultat |
   |---|---|---|
   | Generate and publish (push) | 36230891223 | ✅ alle 7 `build-image` grøne (F1 løyst); image pusha til `ghcr.io/audunautomat/*` (t.d. `linkml-local:5c74…`); portal publisert |
   | Validate (dispatch) | 36231138870 | ✅; `create-pr-with-validation-logs` grøn, men **laga ingen PR** («Ingen endringar å committe»), så tokenet vart ikkje brukt |
   | Modell-analyse (dispatch) | 36231141184 | ✅ |
   | CodeQL (push) | – | ✅ (code scanning slått på, advanced setup) |
   | Trivy (push) | – | ✅ |
   | Lenkje- og mermaid-sjekk (dispatch, mot ny portal) | 36231265932 | ✅ inkl. `lenkjesjekk` og `mermaid-click-href-sjekk` |
   | Release Please (push) | 36230891008 | ✅, men hoppa over av commit-type-filteret. **Ikkje starta manuelt**, sidan taggane framleis manglar (F10) og ei køyring då kunne laga release-PR-ar med feil versjonar/CHANGELOG |

   Portal: <https://audunautomat.github.io/linkml-datamodellering-no/> (HTTP 200).

   Innstillingar (lesne som admin): secret `RELEASE_PLEASE_TOKEN` finst;
   `allow_auto_merge: true`; workflow-permissions `write` +
   `can_approve_pull_request_reviews: true`; miljøet `github-pages` tillèt
   `main`; ruleset-bypass = Repository admin (always).

   **Står att frå steg 7:**
   - **F2 (`RELEASE_PLEASE_TOKEN`) er framleis ikkje verifisert.** Tokenet vert først
     brukt ved ein manuell køyring av `release-please.yml`, som skal vente
     til steg 9.1 (taggar) er gjort, eller når `validate.yml` finn nye
     valideringsloggar.
   - ~~Ruleset `main protection` manglar `pull_request`-regelen.~~ Retta av
     brukaren og verifisert 2026-09-26, sjå F8b.
   - ~~2f: GHCR-pakkane er private.~~ Retta av brukaren. Anonym
     `GET ghcr.io/v2/audunautomat/<image>/tags/list` gir HTTP 200 for alle 7
     image i `images.json` (2026-09-26). Dei har berre hash-taggar.
   - `latest`/`vX.Y.Z`-taggar på image og dei to `mcp-linkml-*-utkast`-imaga
     manglar, fordi `release.yml` ikkje har køyrt (krev `v*.*.*`-tag, jf. F10).
     Til det har skjedd, vil eksterne kallarar av `reusable-*.yml` (som hentar
     `:${VERSION}`, standard `latest`) feile.
8. (Etter F9) Opprett spec for GitHub App, sjå handlingslista.
9. **F10 — taggar, versjonslåste referansar og første release i nytt repo**
   (ikkje utført). Del-stega har denne rekkjefølgja: 9.1 → 9.2 → 9.3 → 9.4 → 9.5.
   9.6 og 9.7 krev at 9.1 er gjort, men er elles uavhengige. 9.8 og 9.9 er
   avgjerder.

   **Kartlegging (2026-09-26):**

   | Kva | Resultat |
   |---|---|
   | Taggar i `brreg` | 367 (40 annoterte, 327 lette) |
   | Taggar i lokal klone | 367, **identisk sett** med `brreg` (`diff` av sorterte lister er tom). Ingen henting frå `brreg` trengst |
   | Taggar i `origin` (AudunAutomat) | 0 |
   | Namnemønster | `<komponent>-vX.Y.Z` (release-please, `include-component-in-tag: true`) for 39 komponentar; éin repo-nivå-tag `v1.0.0` |
   | Forventa taggar (komponent + versjon i `.github/release-please-manifest.json`) | alle finst, **unntatt `modelldcat-modell-v1.14.0`** (sjå 9.2) |
   | GitHub Releases | 330 i `brreg`, 0 i nytt repo. Releases (med opplasta artefakter) er GitHub-objekt og vert ikkje med i git (sjå 9.8) |

   #### 9.1 Overfør taggane til nytt origin (du må gjere det sjølv) ✅

   **Utført av brukaren, verifisert 2026-09-26:** `git ls-remote --tags origin`
   gir 367 taggar (40 annoterte). Settet er identisk med lokal klone og
   `brreg` (`diff` av sorterte lister er tom). Ingen workflow-køyringar vart
   utløyste av pushen. `modelldcat-modell-v1.14.0` manglar framleis, som
   venta (9.2).


   Stadfest først at den lokale klonen har alle taggane:
   ```bash
   git tag | wc -l                                                     # → 367
   git ls-remote --tags https://github.com/brreg/linkml-datamodellering-no \
     | grep -v '\^{}' | wc -l                                          # → 367
   ```
   Overfør alle taggane til `origin`, og stadfest resultatet:
   ```bash
   git push origin --tags
   git ls-remote --tags origin | grep -v '\^{}' | wc -l                # → 367
   ```
   Merknader:
   - GitHub lagar **ingen** `push`-hendingar når meir enn tre taggar vert
     pusha samstundes. Det er ønskt her: `release.yml` (`on: push: tags:
     ['v*.*.*']`) vert ikkje utløyst av den gamle `v1.0.0`, og ingen andre
     workflowar startar.
   - Ruleset-en `main protection` gjeld berre branchar (`target: branch`), så
     tag-pushen vert ikkje blokkert.

   #### 9.2 Rett manglande `modelldcat-modell-v1.14.0` (feil som fanst alt i `brreg`) ✅

   **Utført av brukaren, verifisert 2026-09-26:** annotert tag
   `modelldcat-modell-v1.14.0` (objekt `5c5e4f2d`) peikar på `46792cdc`.
   Origin har no 368 taggar.


   Komponenten `modelldcat-modell` vart flytta til ny sti i `46792cdc`
   (`refactor(ap-no): flytt dqv-core, modelld…`, 2026-08-17) og fekk `1.14.0`
   direkte i manifestet utan at ein tag vart laga. Nyaste tag er
   `modelldcat-modell-v1.11.0`, og det finst heller ingen GitHub Release for
   1.12–1.14 i `brreg`. Utan tag finn ikkje release-please førre release for
   komponenten. Han vil då ta med alle commit-ar bakover (opp til
   søkjedjupna) i CHANGELOG for neste versjon.

   Tilrådd fiks (du må gjere det sjølv): lag den manglande taggen på commit-en
   som sette 1.14.0 i manifestet. Kommandoane er skrivne slik at dei stoppar
   dersom føresetnadene ikkje held:
   ```bash
   # 1. Kontroller at taggen framleis manglar (lokalt og i origin) — forventa: ingen output
   git tag -l modelldcat-modell-v1.14.0
   git ls-remote --tags origin modelldcat-modell-v1.14.0

   # 2. Kontroller at 46792cdc er commit-en som sette 1.14.0 og ligg på main
   git show 46792cdc:.github/release-please-manifest.json | grep '"src/linkml/ap-no/modelldcat-modell": "1.14.0"'
   git merge-base --is-ancestor 46792cdc origin/main && echo "46792cdc er på main"

   # 3. Lag annotert tag (same form som per-schema-taggane i release-please.yml)
   git tag -a modelldcat-modell-v1.14.0 46792cdc -m "Release modelldcat-modell version 1.14.0 (etterregistrert etter flytting, jf. specs/backlog/ci-etter-origin-flytting-audunautomat.md 9.2)"

   # 4. Push berre denne éine taggen
   git push origin modelldcat-modell-v1.14.0

   # 5. Verifiser — forventa: éi linje med …refs/tags/modelldcat-modell-v1.14.0 og éi med ^{}
   git ls-remote --tags origin 'modelldcat-modell-v1.14.0*'
   ```
   Merk: ein push av éin enkelt tag lagar ei `push`-hending, men ingen
   workflowar lyttar på `modelldcat-modell-v*`. `release.yml` reagerer berre
   på `v*.*.*`.
   Alternativ utan tag: set `"last-release-sha": "46792cdc…"` på pakken i
   `.github/release-please-config.json`. Det krev ei kodeendring og må
   fjernast att etter neste release, så taggen er enklare.

   #### 9.3 Tørrkøyr release-please før første ekte køyring ✅

   **Utført 2026-09-26** med `release-please@17` (same major som
   `release-please-action@v5` / `45996ed`, som krev `^17.6.0`) i
   `node:22`-container, `--dry-run`:
   - `Expected 37 releases, only found 0` → `Missing 37 paths`, deretter
     **37 av 37** funne via taggar (`looking for tagName` → `found`), t.d.
     `modelldcat-modell-v1.14.0 → 46792cdc` (9.2 verka).
   - Utfall: 20 × «No user facing commits found since <tag-SHA>», 17 × «No
     commits for path», **`Would open 0 pull requests`**. Ingen komponent får
     historikken sin på nytt.
   - Harmlause åtvaringar: `Release SHA … did not have an associated pull
     request` (releases frå `brreg` er ikkje kopla til PR-ar i nytt repo), og
     `commit could not be parsed: … Merge branch 'main' of github.com:brreg/…`
     (merge-commit utan conventional-format vert ignorert).


   release-please finn førre release per komponent først via GitHub Releases.
   Når dei manglar (0 i nytt repo), er det forventa at han fell tilbake til å
   leite etter taggar med forventa namn (`<komponent>-v<manifest-versjon>`).
   Dette skal stadfestast før release-please får skrive noko. Tørrkøyringa
   er eit eingongs diagnoseverktøy, ikkje eit make-target:
   ```bash
   podman run --rm -e GH_TOKEN="$(gh auth token)" docker.io/library/node:22 \
     sh -c 'npx -y release-please release-pr --dry-run \
       --repo-url=AudunAutomat/linkml-datamodellering-no --target-branch=main \
       --token="$GH_TOKEN" \
       --config-file=.github/release-please-config.json \
       --manifest-file=.github/release-please-manifest.json'
   ```
   Sjå etter følgjande i loggen:
   - ✅ Ingen `Expected N releases, only found M`-åtvaring, eller at
     åtvaringa vert følgd av at alle manglande stiar vert funne via taggar.
   - ✅ Kvar planlagde release-PR/CHANGELOG inneheld berre commit-ar etter
     taggen til komponenten, og ikkje heile historikken.
   - ❌ Viss ein komponent får ein CHANGELOG med hundrevis av commit-ar eller
     eit uventa versjonshopp, manglar taggen hans. Løys det som i 9.2 før du
     går vidare.

   #### 9.4 Første ekte køyring av release-please (verifiserer F2) ✅ (delvis)

   **Utført 2026-09-26:** `workflow_dispatch`, køyring `36233290337` → ✅
   `success`. `release-please-action` køyrde med `token: ***`
   (`RELEASE_PLEASE_TOKEN`), gjorde same 37 tag-oppslag som tørrkøyringa, og
   laga ingen PR (ingen `feat`/`fix` sidan taggane).
   - **F2 verifisert for lesetilgang:** tokenet er gyldig og har tilgang til
     repoet, elles hadde API-kalla feila med `401 Bad credentials`.
   - **Ikkje verifisert enno:** skrivetilgangane (lage PR, pushe til
     PR-branch, `gh pr merge --auto`, lage GitHub Release/tag) og kjeda
     auto-approve → validate → auto-merge. Dette vert først testa ved første
     `feat`/`fix` som endrar ein `*-schema.yaml` i ein release-please-komponent.
     Kontrollpunkta under gjeld då.


   ```bash
   gh workflow run release-please.yml -R AudunAutomat/linkml-datamodellering-no
   gh run watch -R AudunAutomat/linkml-datamodellering-no \
     "$(gh run list -R AudunAutomat/linkml-datamodellering-no -w release-please.yml -L 1 --json databaseId -q '.[0].databaseId')"
   ```
   `workflow_dispatch` hoppar over commit-type-filteret, så
   `release-please-action` køyrer alltid med `RELEASE_PLEASE_TOKEN`.
   - **Grøn køyring = F2 verifisert** (API-kall med ugyldig token gir `401 Bad
     credentials`), sjølv om ingen PR vert laga.
   - Viss det finst `feat`/`fix` sidan førre tag, vert det laga ein release-PR.
     Kontroller då kjeda:
     1. PR-forfattar er `AudunAutomat`, og `auto-approve-release-please.yml`
        køyrer og godkjenner (verifiserer steg 4).
     2. `validate.yml` køyrer på PR-en. Det viser at PAT-en startar
        workflowar, noko `GITHUB_TOKEN` ikkje ville gjort.
     3. «Oppdater schema-versjonar i release-PR» pushar til PR-branchen.
     4. Auto-merge er aktivert. PR-en vert merga via admin-bypass (F8).
     5. Push-køyringa etter merge lagar GitHub Release(s), lastar opp
        artefakter og lagar per-schema-taggar.

   #### 9.5 Image-taggar `latest`/`vX.Y.Z` og `mcp-linkml-*-utkast`-image ✅

   **Utført 2026-09-26:** Brukaren pusha annotert tag `v1.1.0` (objekt
   `6384c2ae`) → `f281324f` (`fix(imports): …`, inneheld 9.6 — kontrollert
   med `git grep` mot `origin/main`). `release.yml`-køyring `36234113027` →
   ✅ alle 4 jobbar (`linkml-local`, `mcp-linkml-validator`,
   `mcp-linkml-modell-utkast`, `mcp-linkml-begrep-utkast`). Anonym
   `tags/list` på `ghcr.io/audunautomat/<image>` → HTTP 200 og taggane
   `v1.1.0` og `latest` for alle fire. Dei to `mcp-linkml-*-utkast`-imaga var
   allereie offentlege etter første push, så 2f-2 kravde ingen manuell handling.
   Eksterne kallarar med `ap-no-version: v1.1.0` har no både git-ref og
   image-taggar å hente. `VERSION=latest` feilar framleis ved checkout (9.9).

   Opphavleg plan: Taggen må lagast av
   brukaren, fordi LLM ikkje køyrer git-kommandoar som endrar
   versjonskontroll-tilstand. Å lage taggen via GitHub-API-et har same verknad
   og vert difor heller ikkje gjort. Føresetnad: `v1.1.0` skal peike på ein
   commit i `origin/main` som inneheld endringane frå 9.6. Då får eksterne som
   låser `ap-no-version: v1.1.0` oppdaterte `bootstrap.sh` og import-URL-ar.
   ```bash
   # 1. Kontroller at 9.6-endringane er med i origin/main — forventa: ingen output
   git fetch origin
   git grep -l 'raw.githubusercontent.com/brreg/linkml-datamodellering-no' origin/main -- bootstrap.sh mkdocs/lib/sections/kom_i_gang.sh src/assets/scripts/scaffolding/new-modell.sh

   # 2. Kontroller at taggen ikkje finst frå før — forventa: ingen output
   git ls-remote --tags origin v1.1.0

   # 3. Lag og push taggen (éin tag → push-hending → release.yml startar)
   git tag -a v1.1.0 origin/main -m "v1.1.0: første release etter flytting til AudunAutomat"
   git push origin v1.1.0
   ```
   Etterpå (LLM): følg `release.yml`-køyringa, og kontroller at alle 4 jobbane er
   grøne og at `:v1.1.0` og `:latest` finst. Deretter set brukaren
   `mcp-linkml-modell-utkast` og `mcp-linkml-begrep-utkast` til *Public*
   (2f-2), og LLM verifiserer anonymt (kommando under).


   `release.yml` (utløyst av `v*.*.*`-tag eller `workflow_dispatch`) er det
   einaste som lagar `:latest`/`:<ref_name>` for image og byggjer
   `mcp-linkml-modell-utkast`/`mcp-linkml-begrep-utkast`. Reusable workflows
   hentar `:${VERSION}` (standard `latest`), så eksterne kallarar feilar til
   dette har skjedd.

   **Ikkje** køyr `release.yml` med `--ref v1.0.0`. Workflowen vert då henta
   frå den gamle commit-en, som manglar F1-fiksen, og feilar med same
   feil som før.

   **Avgjort (O5, 2026-09-26): alternativ a) med `v1.1.0`.** Alternativa
   som vart vurderte:
   - **a) Ny repo-nivå-tag på dagens `main`** (t.d. `v1.1.0`, jf.
     versjonspolitikken i `GOVERNANCE.md`). Éin tag-push utløyser
     `release.yml` og gir image-taggane `:v1.1.0` og `:latest`. Eksterne kan
     då låse `ap-no-version: v1.1.0`.
   - **b) Berre `latest` no:** `gh workflow run release.yml -R
     AudunAutomat/linkml-datamodellering-no` (på `main`). Då vert
     `ref_name` = `main`, og image får taggane `:main` og `:latest`.

   Etterpå: set `mcp-linkml-modell-utkast` og `mcp-linkml-begrep-utkast` til
   *Public* (2f-2). Verifiser anonymt:
   ```bash
   for img in linkml-local mcp-linkml-validator mcp-linkml-modell-utkast mcp-linkml-begrep-utkast; do
     tok=$(curl -s "https://ghcr.io/token?scope=repository:audunautomat/$img:pull" | jq -r .token)
     curl -s -H "Authorization: Bearer $tok" "https://ghcr.io/v2/audunautomat/$img/tags/list" | jq -c '{name, tags}'
   done
   ```

   #### 9.6 Byt versjonslåste `raw.githubusercontent.com/brreg/…` til `AudunAutomat` (etter 9.1) ✅

   **Utført 2026-09-26:**
   - Tekstutskifting i 15 filer: dei 6 `oreg`-skjemaa, `README.md`,
     `SCOPE.md`, `CONVENTIONS.md`, `ekstern-bruk.md` (8),
     `importhierarki.md`, `ny-domenemodell.md`, `bootstrap.sh` (2),
     `kom_i_gang.sh` og `new-modell.sh`. Nye URL-ar er kontrollerte (HTTP 200
     for `dcat-ap-no-v2.14.1`, `-v2.13.0` og `common-ap-no-v1.0.0`).
   - Validering av dei 6 skjemaa: `make lint` → alle exit 0. `make roundtrip` →
     5 ✅, **`enhetsregisteret-bvrfriv` ✗ `roundtrip-ttl`**. Feilen fanst
     **før endringa**: same feil med opphavleg `brreg`-import (kontrollert ved å
     setje importen mellombels tilbake). Sjå 9.9.
   - `make gen-informasjonsmodell-instance` (alle skjema) → 47 manifest
     regenererte, ingen nye filer. I **33** av dei retta regenereringa òg
     utdaterte felt (t.d. `ngr-adresse` `versjonsnummer` 1.4.0 → 2.1.1,
     `beskrivelse`, `endringsdato`, `inneholder_modellelement`). Brukaren valde å
     behalde full regenerering (sjå Avgjerder).
   - `mkdocs/docs/felles/*/*-manifest.yaml` (5): kopierte frå kjelda med `cp`,
     slik `mkdocs/lib/copy_artifacts.sh` gjer. Dei var byte-like med kjelda i
     HEAD. `mkdocs/docs/felles/*/index.md` (5): import-linja er bytt slik den
     endra `kom_i_gang.sh` ville generert henne. `make docs-publish` er ikkje
     køyrd, fordi han skriv om alle 512 tracka filer under `mkdocs/docs/felles/`.
   - Att med `raw.githubusercontent.com/brreg`: berre
     `src/linkml/ap-no/dqv-ap-no/metadata/modelldcat.yaml`. Det er ei utdatert
     fil med gammal sti, dekt av BUG-11
     (`bugs/informasjonsmodell-instance-stale-metadata-sti.md`), og vert ikkje
     rørt her.


   Utskiftinga er
   `raw.githubusercontent.com/brreg/linkml-datamodellering-no/` →
   `raw.githubusercontent.com/AudunAutomat/linkml-datamodellering-no/`. Tag-delen
   er uendra. Filene som skal endrast:

   | Fil(er) | Kva | Merknad |
   |---|---|---|
   | 6 skjema i `src/linkml/oreg/`: `enhetsregisteret-bvrbekreftelse`, `-bvrettersendingavvedlegg`, `-bvrfriv`, `-bvrstiftelsesdokument`, `-frivilligorganisasjonapi`, `javazonetalk` | `imports:` av `dcat-ap-no-v2.14.1` | Ingen av dei er release-please-komponentar, så endringa utløyser **ingen** release. Køyr `make lint SCHEMA=…` og `make roundtrip SCHEMA=…` per skjema etterpå |
   | `README.md`, `SCOPE.md`, `CONVENTIONS.md` | døme-importar (`dcat-ap-no-v2.8.0`, `-v2.0.0`, `common-ap-no-v1.0.0`) | dokumentasjon |
   | `mkdocs/docs/arkitektur/ekstern-bruk.md` | profiltabell, døme og `{versjon}`-mønster | dokumentasjon |
   | `mkdocs/docs/arkitektur/importhierarki.md`, `mkdocs/docs/kom-i-gang/ny-domenemodell.md` | døme-importar | dokumentasjon |
   | `bootstrap.sh` (2 linjer, `${WORKFLOW_REF}`) | import-døme og `renovate.json`-nedlasting | verktøy for eksterne |
   | `mkdocs/lib/sections/kom_i_gang.sh` | **generator** for «Importer i egne LinkML-skjema» på modellsidene | etter endring: køyr `make docs-publish`, så vert `mkdocs/docs/**/index.md` (t.d. `felles/*/index.md`) regenererte |
   | `src/assets/scripts/scaffolding/new-modell.sh` | **generator** for import i nye skjema | påverkar berre nye modellar |

   Genererte filer skal **ikkje** handredigerast. Regenerer dei i staden:
   - `src/linkml/**/metadata/*-manifest.yaml` (47) og
     `metadata/modelldcat.yaml` inneheld `raw.githubusercontent.com/brreg/…/main/…`
     og `heimeside: https://brreg.github.io/…`. Generatoren
     (`generate-informasjonsmodell.py`) brukar no `AudunAutomat` (steg 5).
     Lokalt les han `.git/config` (origin = AudunAutomat), og i CI les han
     `GITHUB_REPOSITORY`. Regenerer med `make gen-informasjonsmodell-instance
     DOMAIN=<domene>` for kvart domene. Dette er uavhengig av taggane og kan
     gjerast når som helst.
   - `mkdocs/docs/felles/*/*-manifest.yaml` er kopiar av manifesta og vert
     oppdaterte av `make docs-publish`.

   Feil som fanst alt i `brreg` og som ikkje vert retta av 9.6: `felles/*/index.md`
   refererer `brreg-felles-{aktoer,digital-adresse,geografisk-adresse,tid,typer}-v0.1.0`.
   Desse taggane finst verken i `brreg` eller lokalt, og `felles`-modellane
   er ikkje release-please-komponentar. Lenkjene er brotne uansett eigar.
   Bør få eigen `bugs/`-fil.

   Tilsvarande feil som fanst før flyttinga, funnen i 9.6:
   `make roundtrip SCHEMA=src/linkml/oreg/enhetsregisteret-bvrfriv/…` feilar i
   `roundtrip-ttl`, uavhengig av import-eigar. Bør òg få eigen `bugs/`-fil (9.9).

   #### 9.7 `informasjonsmodellidentifikator` (eigen spec)

   34 identifikatorar i 6 filer under `src/linkml/modellkatalog/**/data/**`
   brukar `https://brreg.github.io/linkml-datamodellering-no/<domene>/<modell>/`.
   Dei identifiserer publiserte informasjonsmodellar i eksterne katalogar,
   så ei endring er ei identitetsendring (ny URI = ny modell for
   konsumentane). Dette skal ikkje gjerast som del av denne specen. Opprett
   eigen spec som vurderer (a) behalde gamle URI-ar som stabile
   identifikatorar, (b) byte med `owl:sameAs`/`dct:replaces` til gammal URI,
   eller (c) byte utan kopling.

   #### 9.8 Historiske GitHub Releases (avgjerd O3)

   De 330 releasane i `brreg` (med artefakter som `*-schema.json`,
   `*-shapes.ttl`, `*-ontology.ttl`) vert ikkje med. `ekstern-bruk.md`
   peikar no på `github.com/AudunAutomat/…/releases` som «kanonisk adresse
   for eldre versjonar», men den sida er tom. Alternativ:
   **Avgjort (O3, 2026-09-26): alternativ a).** `ekstern-bruk.md` har fått ein
   `!!! note`-boks under lista over versjonerte adresser. Han seier at
   releases frå før flyttinga ligg i `brreg`, og at nye releases vert
   publiserte i det nye repoet.

   - **a) (tilrådd, valt)** Behald historikken i `brreg`. Presiser i
     `ekstern-bruk.md` at releases før flyttinga (2026-09) ligg i
     `github.com/brreg/linkml-datamodellering-no/releases`, og at nye releases
     ligg i det nye repoet. Krev ingen kopiering, men føreset at `brreg`-repoet
     vert ståande.
   - **b)** Kopier releasane med skript (`gh release view` i `brreg` →
     `gh release download` → `gh release create --notes … <tag> <assets>` i
     nytt repo). Det er 330 releases, krev 9.1 først, og gir nye
     publiseringsdatoar.
   - **c)** Ikkje gjer noko, og aksepter at lenkja er tom for gamle versjonar.

   #### 9.9 Observasjon: `VERSION=latest` i reusable workflows (feil som fanst alt i `brreg`) ✅

   **Utført 2026-09-26.** Dei tre kandidatane er no registrerte i `bugs/`:
   | Kandidat | Resultat |
   |---|---|
   | `VERSION=latest`-checkout | ny **BUG-22** (`bugs/reusable-workflow-latest-ref-manglar.md`), `open` |
   | `brreg-felles-*-v0.1.0`-lenkjer | ny **BUG-23** (`bugs/kom-i-gang-import-tag-for-ikkje-releasa-skjema.md`), `open`. Rotårsaka ligg i `kom_i_gang.sh`, som utleier tag frå `version:` utan å sjekke om skjemaet er release-please-komponent. Kartlegginga fann **11** ramma skjema, ikkje berre dei 5 i `felles`: òg dei 6 `oreg`-skjemaa frå 9.6 |
   | `enhetsregisteret-bvrfriv` `roundtrip-ttl` | **ikkje ny bug.** Isolert ved å ta vare på `a.json`/`d.json` under `make roundtrip`. Einaste avvik er `innsendingstidspunkt` `'2024-01-01T00:00:00'` → `'2024-01-01 00:00:00'`, altså **BUG-19**. BUG-19 er utvida med skjemaet, og skip er lagt til i `tests/test_make.sh` (begge stadene, same mønster som `bvrinnfelles`). `make roundtrip SCHEMA=…bvrfriv…` gir no `2 OK, 0 feil`, og loggen viser «Hoppar over roundtrip-ttl … (BUG-19 …)» |

   `BUGS.md`: indeksrader for BUG-22/23, BUG-19-rada er utvida, og det er lagt til punkt under
   «Publisering» (BUG-23) og «Samhandling og CI/CD» (BUG-22).

   Opphavleg observasjon:

   `reusable-{generate,lint,validate}.yml` sjekkar ut
   `AudunAutomat/linkml-datamodellering-no` med `ref: ${VERSION}`, der
   standardverdien er `latest`. Det finst ingen branch eller tag som heiter
   `latest`, verken i `brreg` eller i nytt repo, så checkout feilar for
   eksterne kallarar som ikkje set `ap-no-version: vX.Y.Z`. Dette kjem ikkje av
   flyttinga, men vert synleg når eksterne tek i bruk det nye repoet. Bør få
   eigen `bugs/`-fil og fiks (t.d. mappe `latest` → `main` for checkout,
   men behalde `:latest` for image).

## Handlingsliste

- [x] 1. Hent faktiske feilloggar og stadfest/juster funna (F2 står att, sjå steg 7)
- [x] 2a. Opprett `RELEASE_PLEASE_TOKEN` (fine-grained PAT, AudunAutomat), sjå F2a
- [x] 2b. Slå på «Allow GitHub Actions to create and approve pull requests»
- [x] 2c. Slå på «Allow auto-merge»
- [x] 2d. Pages-kjelde = GitHub Actions; sjekk `github-pages`-miljøet
- [x] 2e. Slå på code scanning (Advanced setup)
- [x] 2f. Set GHCR-pakkane under `audunautomat` til *Public* — verifisert 2026-09-26 med anonym `tags/list` (HTTP 200) for alle 7 image i `images.json`
- [x] 2f-2. `mcp-linkml-modell-utkast` og `mcp-linkml-begrep-utkast` offentlege — verifisert anonymt 2026-09-26 etter `release.yml` (v1.1.0)
- [x] 2g. Gjenskap ruleset `main protection` på `main` (F8a), og verifiser `protected: true` — verifisert 2026-09-26, funksjonelt identisk med `brreg` (sjå F8b)
- [ ] 2h. (Valfritt) Inviter `AudunVindenesEggeBR` som collaborator med *Write*, dersom kontoen skal vere reviewar
- [x] 3. F1: lowercase GHCR-prefiks via `compute-image-tags` + actionlint
- [x] 4. Auto-approve-aktør utan hardkoding + actionlint
- [x] 5. F5: portal-URL-ar → `audunautomat.github.io` / `github.com/AudunAutomat` (utan versjonslåste importar/identifikatorar)
- [x] 6. F6: reusable workflows → `AudunAutomat` / `ghcr.io/audunautomat` + `ekstern-bruk.md`
- [x] 7. Manuell verifisering via `workflow_dispatch` (alle grøne; F2 og `release-please.yml` utsette til steg 9, sjå status)
- [x] 9.1 Overfør 367 taggar til `origin` (stadfest 367 i `git ls-remote --tags origin`)
- [x] 9.2 Lag manglande tag `modelldcat-modell-v1.14.0` på `46792cdc`
- [x] 9.3 Tørrkøyr release-please (`--dry-run`) og kontroller CHANGELOG-omfang
- [x] 9.4 `gh workflow run release-please.yml` → grøn (36233290337), F2 verifisert for lesetilgang
- [ ] 9.4b Ved første ekte release-PR: kontroller skrivetilgang og auto-approve/validate/auto-merge-kjeda (kontrollpunkt i 9.4)
- [x] 9.5 Køyr `release.yml` via ny tag `v1.1.0` på `main` (O5) — køyring 36234113027 grøn, `:v1.1.0`/`:latest` på alle 4 image, og set `mcp-linkml-*-utkast` til *Public* (2f-2)
- [x] 9.6 Byt versjonslåste raw-URL-ar (tabell i 9.6), regenerer manifest (`make gen-informasjonsmodell-instance`) og portal (`make docs-publish`)
- [ ] 9.7 Opprett eigen spec for `informasjonsmodellidentifikator`
- [x] 9.8 Avgjer O3 (historiske GitHub Releases) og oppdater `ekstern-bruk.md` — alternativ a), note-boks lagt til
- [x] 9.9 `bugs/`-filer: BUG-22 (`latest`-checkout), BUG-23 (tag-URL for ikkje-releasa skjema, 11 skjema); `bvrfriv` = BUG-19 (utvida + test-skip)
- [ ] 8. (Etter F9) Opprett spec `specs/backlog/github-app-for-release-please.md` for migrering frå PAT til GitHub App

## Opne spørsmål

- ~~**O1:** Er repoet privat?~~ **Løyst 2026-09-26:** Repoet var privat då
  specen vart skriven, og er no gjort **offentleg**. Pages og code
  scanning/SARIF krev difor ingen betalt plan. Dei må berre slåast på (steg
  2d/2e).
- ~~**O2:** Er AudunAutomat kanonisk upstream?~~ **Løyst 2026-09-26:** Ja,
  `AudunAutomat/linkml-datamodellering-no` er den nye kanoniske upstreamen.
  Steg 5 og 6 skal gjerast utan vilkår.
- ~~**O3:** Historiske GitHub Releases (330 i `brreg`)?~~ **Løyst
  2026-09-26:** Dei vert liggjande i `brreg`, og `ekstern-bruk.md` peikar dit
  for releases før flyttinga (9.8, alternativ a).
- ~~**O5:** Korleis skal første `release.yml`-køyring skje?~~ **Løyst
  2026-09-26:** Ny repo-nivå-tag `v1.1.0` på `main` (9.5, alternativ a).
  Det er ein minor-bump: tooling-API-et er uendra, men eigar og URL-ar er nye.

## Avgjerder

- 9.9: `bvrfriv`-roundtripfeilen fekk ikkje eiga bug-fil, fordi avviket er
  identisk med BUG-19 (datetime-separator). BUG-19 er utvida og test-skip lagt
  til i tråd med CLAUDE.md-konvensjonen (skip ↔ `bugs/`-fil med BUG-ID).
- 9.9: BUG-23 er formulert rundt rotårsaka i `kom_i_gang.sh` (11 skjema), ikkje
  berre dei 5 `felles`-lenkjene som var utgangspunktet. BUG-22 og BUG-23 er
  berre dokumenterte. Fiksane er ikkje gjorde i denne specen.
- 9.6 (brukarval 2026-09-26): full regenerering av manifest er behalden, sjølv om
  33 av 47 fekk endringar i tillegg til eigarbytet (utdaterte versjonsnummer,
  beskrivelsar, datoar og modellelement). Manifesta skal vere ein funksjon av
  dagens skjema. Alternativet var å setje filene tilbake til HEAD og berre byte
  URL-ar.
- 9.6: `mkdocs/docs/felles/**` er oppdatert målretta (`cp` + import-linje) i
  staden for med `make docs-publish`, som ville skrive om alle 512 tracka filer
  der.
- 9.5 før 9.6 vart snudd til 9.6 før 9.5, slik at `v1.1.0` inneheld dei
  oppdaterte `bootstrap.sh`- og import-URL-ane.
- 9.3: Tørrkøyringa brukte `release-please@17` fordi
  `release-please-action@45996ed` (v5.0.0) krev `release-please ^17.6.0`. Då
  er backfill-åtferda den same som i CI.
- 9.4: F2 er berre rekna som verifisert for lesetilgang. Ei grøn køyring utan
  PR prøver ikkje skriveløyva, så dei er skilde ut i 9.4b i staden for å
  kryssast av.
- O5: Brukaren godkjende «tilrådinga» for O5, men specen hadde ikkje merkt noko
  alternativ som tilrådd. Valet vart difor stadfesta eksplisitt med brukaren
  (`v1.1.0`, minor), ikkje tolka.
- 9.8: Merknaden om releases frå før flyttinga er lagd til som `!!! note`
  rett etter lista over versjonerte adresser i `ekstern-bruk.md`. Lenkja til
  nye releases er ikkje endra.
- Steg 9 (dokumentert 2026-09-26 etter ønske frå brukaren): git-kommandoane for
  tag-overføring (9.1/9.2) er skrivne inn som framgangsmåte som brukaren sjølv
  køyrer. LLM køyrer ikkje git-kommandoar som endrar versjonskontroll-tilstand.
- 9.2: Den manglande `modelldcat-modell-v1.14.0` er tilrådd løyst med ein tag
  på `46792cdc` i staden for `last-release-sha` i config, fordi ein tag ikkje
  krev kodeendring og ikkje må fjernast att.
- 9.3: Tørrkøyringa brukar `podman run` direkte (node-container), ikkje eit
  make-target. Det er ein eingongs diagnose, jf. unntaket for feilsøking i
  CLAUDE.md.
- 9.5: Frårår `release.yml --ref v1.0.0`, fordi workflow-fila då vert henta frå
  den gamle commit-en utan F1-fiksen.
- 9.9 og `brreg-felles-*-v0.1.0` er registrerte som feil som fanst alt før
  flyttinga, og vert ikkje retta i denne specen.
- Steg 3: I staden for ein ny `registry`-output som skulle sendast gjennom
  `reusable-oppsett.yml` og vidare til alle `pull-images`-kallarane (skissa i F1), lagar
  `compute-image-tags` no **fullstendige referansar**
  (`ghcr.io/<eigar i små bokstavar>/<navn>:<hash>`) i `image_tags`. Verdiane
  vert berre lesne på tre stader (`pull-images`, `reusable-oppsett.yml`,
  `modell-analyse.yml`). Det gir éi kjelde for både eigar og små bokstavar, og ingen
  ny plumbing gjennom 10+ kallarar. `release.yml` brukar ikkje
  `compute-image-tags` (to av imaga står ikkje i `images.json`) og får difor
  `REGISTRY="ghcr.io/${GITHUB_REPOSITORY_OWNER,,}"` i bash i kvart av dei 4
  stega.
- Steg 4: Sjekkar `pull_request.user.login` (PR-forfattar) i staden for
  `github.actor`, som kan vere den som opna PR-en på nytt eller pusha. Har òg lagt til
  `head.repo.full_name == github.repository`, fordi repoet no er offentleg og
  `pull_request_target` elles kunne godkjenne ein fork-PR med same
  branch-prefiks. GitHub-uttrykk samanliknar strengar utan å skilje mellom store
  og små bokstavar, så `github.repository_owner` (`AudunAutomat`) matchar login.
- Steg 5 (omfang valt av brukaren): berre «portal/skript/CI» og
  «dokumentasjonsprosa». **Ikkje** endra: alt under `src/linkml/**` (skjema,
  versjonslåste importar, `informasjonsmodellidentifikator`, manifest),
  genererte `*-manifest.yaml` (vert regenererte av CI via
  `generate-informasjonsmodell.py`, som no brukar ny eigar), `CHANGELOG.md`,
  `specs/` og `bugs/`. Versjonslåste `raw.githubusercontent.com/brreg/…/<tag>/…`
  er haldne att overalt, fordi taggane ikkje finst i nytt origin (F10).
- Steg 5: Hardkoda URL-ar er bytte der dei står, og ikkje samla i éi felles
  kjelde (som F5 foreslo med «helst»). Ei slik samling ville vore ei
  DRY-omskriving av mange filer, og det krev eige løyve etter CLAUDE.md.
- Steg 6: `.github/CODEOWNERS` (`@AudunVindenesEggeBR`) er ikkje endra.
  Kontoen har ikkje tilgang til det nye repoet (F8), så oppføringane vert
  ignorerte av GitHub til kontoen er invitert (steg 2h) eller fila er
  endra.
- Rule (brukar stadfesta 2026-09-26): F1-lærdommen er lagd til som ny seksjon
  «GHCR-referansar: aldri direkte frå `github.repository_owner`» i
  `.claude/rules/ci-workflows.md`, og ikkje som ei ny rule-fil, fordi scopet
  (`.github/workflows/**`, `.github/actions/**`) er identisk med den
  eksisterande rula. Ingen eigen spec, sidan arbeidet utgår frå denne specen.
- actionlint: éin `[shellcheck]` SC2034 i `lenkje-og-mermaid-sjekk.yml:170`
  fanst frå før og blokkerer ikkje (jf. `.claude/rules/ci-workflows.md`).
- Analysen er statisk fordi `gh` manglar tilgang til det nye repoet. Steg 1
  er lagt til for å verifisere mot faktiske loggar før fiksane vert tekne i bruk.
- F1 er løyst med éin `registry`-output i `compute-image-tags` (som alt er
  einaste kjelda for image-taggar) i staden for `${GITHUB_REPOSITORY_OWNER,,}`
  spreidd over fire filer, jf. DRY-terskelen 2+ for CI-YAML.
- Hardkoda `brreg`-referansar (F5/F6) er skilde ut som eigne steg. Dei var
  først vilkårsbundne. Etter O2 (2026-09-26) er dei vanlege steg.
- F6 brukar ein hardkoda ny eigar, ikkje `github.repository_owner`, fordi
  uttrykket i ein reusable workflow vert evaluert i konteksten til det
  kallande repoet.
- F2a: Workflows-løyvet er fjerna frå PAT-tilrådinga (minste privilegium,
  ingen token-brukarar skriv til `.github/workflows/`). Issues: RW er lagt til
  for etikettar. `gh auth token` er frårådd som secret-verdi, fordi scopet er for breitt.
- F9: GitHub App (B) er tilrådd framfor å fortsetje med PAT (A), berre `GITHUB_TOKEN` (C),
  manuell release (D) eller deploy key (E). Det er det einaste alternativet som
  både fjernar koplinga til brukaren, held full automatikk og held på
  ruleset-en frå F8. Migreringa er skild ut som eigen spec for ikkje å blande ei
  frivillig arkitekturendring med feilrettinga etter flyttinga. PAT (F2a) står
  som mellombels løysing.
- F8: «Tilsvarande som før» er tolka som ruleset-en slik han står i `brreg` i dag
  (utan påkravd status check), ikkje slik AM0 i
  `specs/done/auto-merge-release-pr.md` skildra han (med `validate` påkravd).
  Grunnen er at det gjeldande oppsettet er det siste bevisste valet, og ein påkravd
  `validate`-check ville blokkere alle PR-ar til F1 er fiksa. Vil du ha
  `validate` påkravd att, legg til ein `required_status_checks`-regel etter
  steg 3.
- F8: Import av JSON er tilrådd framfor manuell oppsett, fordi det gir ein eksakt kopi
  av parameterar som er lette å gløyme i nettlesaren (t.d.
  `require_last_push_approval`).
- F7: Tilrådinga er å behalde brukarnavnet `AudunAutomat` og fikse koden (steg 3). Ei
  endring til små bokstavar fjernar symptomet for denne kontoen, men ikkje
  føresetnaden i koden om at eigaren berre har små bokstavar, og den ville slå til att for forkar og
  framtidige eigarar.
- `CHANGELOG.md` og `specs/done/` er haldne utanfor F5-utskiftinga, fordi dei
  er historikk eller genererte av release-please.
