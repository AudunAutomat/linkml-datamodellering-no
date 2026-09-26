# CodeQL: 7 opne varsel i dei public reusable workflowane

## Bakgrunn

Code scanning (CodeQL, `actions`-språket) har 7 opne varsel, alle
`medium` og alle i dei public reusable workflowane
(`reusable-{generate,lint}.yml` og, for éin kategori, `reusable-validate.yml`).
Henta med `gh api repos/AudunAutomat/linkml-datamodellering-no/code-scanning/alerts?state=open`
(2026-09-26, analyse på `main` @ `5eb27ea6`).

| # | Regel | Fil:linje | Kategori |
|---|---|---|---|
| 5 | `actions/code-injection/medium` | `reusable-generate.yml:85` | A |
| 7 | `actions/code-injection/medium` | `reusable-lint.yml:72` | A |
| 9 | `actions/unpinned-tag` | `reusable-generate.yml:42` | B |
| 10 | `actions/unpinned-tag` | `reusable-lint.yml:31` | B |
| 11 | `actions/unpinned-tag` | `reusable-validate.yml:39` | B |
| 2 | `actions/untrusted-checkout/medium` | `reusable-generate.yml:53` | C |
| 1 | `actions/untrusted-checkout/medium` | `reusable-lint.yml:44` | C |

Historikk (lukka varsel): #4, #6, #8 (`code-injection` på `${{ inputs.version }}`
inline i `run:`) og #3 (`untrusted-checkout` i `reusable-validate.yml`) vart
alle registrerte som *fixed* 2026-09-26 13:32, ved analysen av commit
`10ae299a` (BUG-22, `resolve-linkml-version`-actionen). Same commit
introduserte #9-#11.

Relevante rules: `.claude/rules/ci-workflows.md` (actionlint etter endring,
DRY-terskel 2+, `./` peikar på kallande repo, røyktest-plikt for public
reusable workflows).

## Kategori A — code injection (#5, #7)

**Funn:** Steget «Trekk inn linkml-local image» interpolerer
`${{ steps.config.outputs.version }}` direkte i `run:`-skriptet:

```yaml
run: |
  VERSION="${{ steps.config.outputs.version }}"
```

GitHub substituerer uttrykket inn i skriptteksten før bash køyrer, så ein
verdi med `"`/`$(...)` ville bli køyrd som kode.

**Reell risiko:** låg. `resolve-linkml-version` avviser alt som ikkje
matchar `^(latest|v[0-9]+\.[0-9]+\.[0-9]+)$` og skriv berre ein upstream
`vX.Y.Z`-tag til outputen. CodeQL ser ikkje shell-valideringa i den
samansette actionen, men mønsteret er framleis feil (forsvar i djupna, og
valideringa kan endre seg).

**Fiks:** send verdien via `env:`, same mønster som `reusable-validate.yml`
alt brukar (difor er han ikkje flagga):

```yaml
- name: Trekk inn linkml-local image
  env:
    VERSION: ${{ steps.config.outputs.version }}
  run: |
    podman pull "ghcr.io/audunautomat/linkml-local:${VERSION}"
    podman tag  "ghcr.io/audunautomat/linkml-local:${VERSION}" localhost/linkml-local:latest
```

To stader (`reusable-lint.yml`, `reusable-generate.yml`). Ingen
åtferdsendring.

## Kategori B — unpinned action (#9, #10, #11)

**Funn:** alle tre reusable workflowane brukar
`AudunAutomat/linkml-datamodellering-no/.github/actions/resolve-linkml-version@main`.
Full sti (ikkje `./`) er nødvendig fordi `./` peikar på kallande repo når
workflowen vert kalla eksternt (jf. rule-seksjonen «`./` i ein reusable
workflow peikar på kallande repo»). CodeQL krev at tredjeparts-actions er
låste til commit-SHA.

**Reell risiko:**
- *Tillit:* låg. Actionen ligg i same repo og har same eigar som workflowen
  som brukar han. Den som kan endre `main`, kan òg endre sjølve workflowen.
- *Reproduserbarheit:* **reell**. Ein ekstern kallar som har låst
  `reusable-validate.yml@v1.2.0`, får likevel actionen frå `main` slik han
  er i dag. Ei inkompatibel endring i actionen slår difor inn hos alle
  kallarar, uavhengig av kva versjon dei har låst. Det bryt med
  versjonslåsinga som BUG-22-arbeidet innførte.

**Alternativ:**

| # | Tiltak | Merknad |
|---|---|---|
| B1 | Lås til SHA med kommentar: `resolve-linkml-version@<40-teikn-sha> # main` (tre stader), og legg til ein drift-sjekk i `royktest-reusable.yml`: for kvar `reusable-*.yml`, `git diff --quiet <sha> HEAD -- .github/actions/resolve-linkml-version/` må vere tom, elles `::error::` med «oppdater SHA-pin». | Løyser både CodeQL-varselet og versjonsskeivleiken: ein release-tag av workflowen inneheld ein fast actionversjon. Same mønster som tredjeparts-actions i repoet alt brukar (`trivy-action@<sha> # v0.36.0`, `release-please-action@<sha> # v5`). Endring i actionen krev to commitar (action, deretter SHA-bump) i same push; drift-sjekken fangar det om ein gløymer. Røyktesten triggar alt på begge stiane. |
| B2 | Lås til release-tag (`@vX.Y.Z`) | Høna og egget: workflowfila i tag vX.Y.Z kan ikkje referere til seg sjølv, berre til ein tidlegare tag. Ein endring i actionen kjem difor først med i releasen etter. Tilrådast ikkje. |
| B3 | Avvis varsla (*won't fix*) med grunngjeving om at eigar og tillitsdomene er det same | Held versjonsskeivleiken. Tilrådast ikkje. |

**Avgjort (O1):** B1.

## Kategori C — untrusted checkout (#1, #2)

**Funn:** steget «Hent … frå AudunAutomat/linkml-datamodellering-no»
sjekkar ut med `ref: ${{ steps.config.outputs.version }}`. CodeQL reknar
outputen som potensielt kontrollert av kallaren (han kan kome frå
`linkml-datamodellering.yaml` i det utsjekka kallande repoet). Når
workflowen ikkje har nokon kjend kallar, går CodeQL ut frå det verste: at
han kan kallast frå ein privilegert trigger som `pull_request_target`.

**Kvifor #3 (`reusable-validate.yml`) er løyst, men ikkje #1/#2:**
`10ae299a` gjorde identiske endringar i alle tre filene. Einaste skilnaden
er at same commit la til `royktest-reusable.yml`, som kallar
`reusable-validate.yml` med kjende, ikkje-privilegerte triggarar
(`push`/`schedule`/`workflow_dispatch`). Då kan CodeQL løyse kallekonteksten.
`reusable-lint.yml` og `reusable-generate.yml` har ingen intern kallar
(røyktesten kan ikkje kalle dei, jf. avgrensinga i røyktest-fila og punkt 3
i rule-seksjonen om røyktest-plikt).

**Reell risiko:** i praksis ingen. Checkouten hentar alltid frå det faste
repoet `AudunAutomat/linkml-datamodellering-no`, aldri PR-koden til
kallaren. Ref-en er regex-validert til `vX.Y.Z` (eller løyst frå `latest`
til nyaste slike tag), `persist-credentials: false` og
`permissions: contents: read`. Ein angripar som styrer
`linkml-datamodellering.yaml` i ein PR, kan berre velje mellom publiserte
release-taggar i upstream-repoet.

**Alternativ:**

| # | Tiltak | Merknad |
|---|---|---|
| C1 | Avvis #1 og #2 som *false positive* i GitHub, med grunngjevinga over (sjå forslag til tekst under). | Rask. Må gjerast av brukaren i GitHub (Security → Code scanning), eller med `gh api -X PATCH …/code-scanning/alerts/<n> -f state=dismissed -f dismissed_reason="false positive" -f dismissed_comment=…` etter godkjenning. Varselet kjem att dersom linja endrar seg vesentleg. |
| C2 | Gjer `reusable-lint.yml`/`reusable-generate.yml` røyktestbare: ny valfri input (t.d. `caller-path`) som sjekkar ut kallande repo i ein underkatalog og køyrer der, og kall dei frå `royktest-reusable.yml` med eit minimalt testrepo-oppsett. | Lukkar i tillegg hòlet i røyktestdekninga (BUG-22-lærdomen). Men det utvidar det offentlege API-et, krev endring i stiane for kopiering/montering i begge workflowane og røyktesten, og må vere bakoverkompatibelt. Større jobb, eiga spec. |

**Avgjort (O2):** C1, avvist via `gh api`. C2 kan framleis vurderast som eiga spec dersom
røyktestdekning for lint/generate er ønskt uavhengig av CodeQL.

Forslag til avvisingstekst (C1):

> Checkout is always of the fixed upstream repository
> AudunAutomat/linkml-datamodellering-no, never of PR code. The ref is
> validated by resolve-linkml-version to ^v\d+\.\d+\.\d+$ (latest is
> resolved to the newest such tag); persist-credentials: false and
> permissions: contents: read. A caller-controlled
> linkml-datamodellering.yaml can only select an existing upstream release
> tag. The identical pattern in reusable-validate.yml (#3) was resolved once
> royktest-reusable.yml gave CodeQL a known, unprivileged caller context.

## Steg

1. [x] Avklar O1 (kategori B) og O2 (kategori C) med brukaren
2. [x] Kategori A: flytt `steps.config.outputs.version` til `env:` i `reusable-lint.yml` og `reusable-generate.yml`
3. [x] Kategori B (B1): SHA-lås `resolve-linkml-version` i dei tre `reusable-*.yml` + drift-sjekk-jobb i `royktest-reusable.yml`
4. [x] Oppdater «Avgrensing»-kommentaren i `royktest-reusable.yml` og rule-seksjonen «`./` i ein reusable workflow …», med SHA-pin-mønsteret (endring i actionen → bump SHA i same push)
5. [x] `actionlint` på alle endra workflow-filer
6. [x] Kategori C (C1): brukaren avviser #1 og #2 (eller eg, via `gh api`, etter eksplisitt godkjenning)
7. [ ] **Attståande (etter push):** røyktesten er grøn (inkl. drift-sjekken), og ny CodeQL-analyse viser #5, #7, #9, #10 og #11 som *fixed*

## Handlingsliste

- [x] A — `env:` for versjon i image-pull-steget (2 filer)
- [x] B — SHA-lås actionen (3 filer) + drift-sjekk i røyktesten
- [x] C — avvis #1/#2 som false positive
- [x] actionlint
- [ ] Verifiser røyktest og CodeQL etter push

## Opne spørsmål

- ~~**O1 (B):** B1 eller B3?~~ → **B1** (brukaravgjerd 2026-09-26).
- ~~**O2 (C):** C1 eller C2?~~ → **C1**, avvis via `gh api` (brukaravgjerd 2026-09-26).

## Avgjerder

- Kartlegginga byggjer på dei opne og lukka varsla frå code scanning-API-et og på diffen i `10ae299a`. Årsaka til at #3 vart løyst er utleidd frå at det var den einaste skilnaden mellom filene, ikkje stadfesta mot CodeQL-kjeldekoden.
- B1: låst til `bf95adf2ece22b6dd16fda9a8db39083f7aae0ef`, siste commit på `origin/main` som endra `.github/actions/resolve-linkml-version/` (innhaldet er identisk med HEAD). Kommentaren `# main` følgjer repo-mønsteret `@<sha> # <ref>`.
- B1, drift-sjekk: eigen jobb `pinned-action-drift` i `royktest-reusable.yml` (triggar alt på endringar i både actionen og `reusable-*.yml`). Han krev 40-teikns SHA, at SHA-en finst i historikken og at `git diff <sha> HEAD -- <action>` er tom. Testa lokalt: grøn på noverande tilstand. I ein worktree med ein gammal SHA (`10ae299a`) i éi fil og `@main` i to feila han med rett melding for alle tre.
- `resolve-linkml-version/action.yml` sin `description` nemner framleis `@main`. Han vart **ikkje** retta no: kvar endring i actionfila endrar innhaldet, så drift-sjekken ville feile til SHA-en vart bumpa i ein ny commit. Teksten vert oppdatert neste gong actionen faktisk vert endra, i same push som SHA-bumpen.
- Rule-seksjonen «`./` i ein reusable workflow peikar på kallande repo» i `.claude/rules/ci-workflows.md` føreskreiv `@main`. Han er oppdatert til SHA-lås og bump i same push, sidan rula elles ville føre framtidig arbeid attende til feilen.
- C1: avvisingskommentaren er korta til 247 teikn (GitHub-grensa er 280).
- `mkdocs/docs/arkitektur/ekstern-bruk.md` har døme med `reusable-*.yml@main` for *kallarar*. Det er eit anna spørsmål (korleis eksterne låser workflowen) og ligg utanfor denne specen.

## Utført (før push)

- `reusable-lint.yml`, `reusable-generate.yml`: `VERSION` via `env:` i «Trekk inn linkml-local image» (A, #5/#7).
- `reusable-{generate,lint,validate}.yml`: `resolve-linkml-version@bf95adf2… # main`, kommentar oppdatert (B, #9-#11).
- `royktest-reusable.yml`: ny jobb `pinned-action-drift` og utvida toppkommentar.
- `.claude/rules/ci-workflows.md`: SHA-lås i staden for `@main`.
- `actionlint`: rein for alle fire endra workflow-filer.
- `gh api`: #1 og #2 avviste som *false positive* (C).

**Attståande etter push** (jf. røyktest-plikta i rula): røyktesten må vere grøn (inkl. `pinned-action-drift`, køyrings-ID skal førast inn her), og neste CodeQL-analyse må vise #5, #7, #9, #10 og #11 som *fixed*. Deretter flyttar eg specen til `specs/done/`.
