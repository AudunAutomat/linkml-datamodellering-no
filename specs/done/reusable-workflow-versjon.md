# BUG-22: versjonshandtering for eksterne kallarar av reusable workflows

## Bakgrunn

BUG-22 (`bugs/reusable-workflow-latest-ref-manglar.md`, registrert 2026-09-26
under `specs/done/ci-etter-origin-flytting-audunautomat.md` 9.9): dei public
reusable workflowane `reusable-{generate,lint,validate}.yml` feilar ved checkout
når versjonen er `latest`. Denne specen kartlegg feilen og dei tilgrensande
feila i same versjonskjede (bootstrap → `linkml-datamodellering.yaml` →
reusable workflow → Renovate), og foreslår ein samla fiks.

## Kartlegging (2026-09-26)

### Versjonskjeda i dag

1. `bootstrap.sh` (eksternt repo) skriv `ap-no-version: ${VERSION}` til
   `linkml-datamodellering.yaml`, med standard `VERSION=latest`
   (`bootstrap.sh:13,32`). Viss `VERSION=latest`, set han sjølv
   `WORKFLOW_REF=main` (`:16–19`) og skriv
   `uses: …/reusable-validate.yml@${WORKFLOW_REF}` (`:50`).
2. Kvar reusable workflow les `version` (input) → `ap-no-version` → standard
   `latest`, og godtek berre `latest` eller `vX.Y.Z` (regex i config-steget).
3. Same `VERSION` vert brukt **to stader**:
   - `actions/checkout` av `AudunAutomat/linkml-datamodellering-no` med
     `ref: ${VERSION}` (verktøyskript)
   - `podman pull ghcr.io/audunautomat/<image>:${VERSION}` (container-image)
4. Renovate (`.github/renovate.json`, malen for eksterne) oppdaterer
   `ap-no-version` frå `datasourceTemplate: github-releases`.

### N1: `latest` finst ikkje som git-ref (BUG-22)

- `:latest` finst for image (laga av `release.yml`), men det finst **ingen
  branch eller tag** som heiter `latest` (`git ls-remote origin latest` → 0 treff,
  same i `brreg`). Checkout feilar.
- **Rammar standardoppsettet:** `bootstrap.sh` utan argument skriv
  `ap-no-version: latest`, og ein manglande `linkml-datamodellering.yaml` gir òg
  `latest`. Alle eksterne repo som følgjer standardrettleiinga, feilar difor.
- `bootstrap.sh` har alt «rett» mapping (`latest` → `main`) for
  `uses:`-referansen, men workflowane sjølve manglar ho.

Påverka stader: `reusable-generate.yml:39–65`, `reusable-lint.yml:28–56` og
`reusable-validate.yml:36–55`. Same kodeblokk ligg i tre filer, som er over
CI-DRY-terskelen (2+).

### N2: Dokumentasjon og bootstrap lovar skjema-taggar som `ap-no-version`

- `mkdocs/docs/arkitektur/ekstern-bruk.md` («Versjonsfesta oppsett»): tabellen
  seier at `ap-no-version: dcat-ap-no-v2.13.0` «Brukar nøyaktig denne
  skjema-versjonen». Bootstrap-dømet (`AP_NO_VERSION=dcat-ap-no-v2.13.0`) gjer
  det same.
- Validerings-regexen i workflowane **avviser** dette («Ugyldig versjon …
  Tillatne verdiar er 'latest' eller semver-tag på forma vX.Y.Z.»).
- Bootstrap med ein skjema-tag ville òg skrive `uses: …@dcat-ap-no-v2.13.0`
  (reusable workflow frå ein gammal commit) og ført til `podman pull
  …:dcat-ap-no-v2.13.0` (image-tag som ikkje finst).
- Rotårsak: to omgrep er blanda saman. **Verktøyversjonen** (`ap-no-version`,
  repo-nivå `vX.Y.Z`, styrer workflowar, skript og image) og
  **skjemaversjonen** (`<komponent>-vX.Y.Z`, låst i `imports:`-URL-en, jf.
  «Skjema-URL-ar og versjonering» i same dokument) er to ulike ting.

### N3: Renovate kan aldri foreslå ein ny `ap-no-version`

- `renovate.json` brukar `github-releases` for
  `AudunAutomat/linkml-datamodellering-no`. Det finst **0** GitHub Releases på
  repo-nivå med `vX.Y.Z`-tag: `v1.1.0` er berre ein git-tag, og `release.yml`
  lagar ingen GitHub Release. Det galdt òg i `brreg` (0 av 330 releases).
- Dei GitHub Releases som finst, gjeld komponentar (`samt-bu-v1.12.2`,
  `ngr-adresse-v2.1.2`, …). Taggane deira er ikkje gyldige `ap-no-version`-verdiar
  (jf. regexen) og ville uansett vere feil omgrep (N2).
- Resultat: Renovate-integrasjonen som `ekstern-bruk.md` tilrår, gjer ingenting.

## Alternativ

### N1: kva tyder `latest` for checkout?

| | Kva | For | Mot |
|---|---|---|---|
| **a** | `latest` → `main` for checkout, `:latest` for image (som `bootstrap.sh` alt gjer for `uses:`) | Minst kode. Same mapping som bootstrap | Skripta frå `main` kan vere nyare enn `:latest`-imaget (som vert bygd berre ved `v*.*.*`-tag). Då kan skript og image vere ute av takt |
| **b** | `latest` → **nyaste `vX.Y.Z`-tag** (`git ls-remote --tags --sort=-v:refname … 'v*.*.*'`), som vert brukt **både** som ref og image-tag | Skript og image kjem alltid frå same release. `latest` tyder «siste release», slik `ekstern-bruk.md` alt seier | Litt meir kode (eitt oppslag). Ny release krev ny tag, og det er slik det skal vere |
| **c** | Fjern `latest`, krev `vX.Y.Z` | Eksplisitt | Brytande for alle eksisterande oppsett. Bootstrap og dokumentasjon må endrast |

### N3: kjelde for Renovate

| | Kva | For | Mot |
|---|---|---|---|
| **a** | `release.yml` lagar ein **GitHub Release** for `v*.*.*`-taggen (`gh release create "$GITHUB_REF_NAME" --generate-notes`) | Renovate-malen fungerer uendra. Synleg release-side for verktøyversjonar | Endring i `release.yml` (treng `contents: write` for jobben som lagar releasen) |
| **b** | Byt Renovate-malen til `datasourceTemplate: github-tags` med `extractVersion: "^v(?<version>\\d+\\.\\d+\\.\\d+)$"` | Inga endring i release-flyten | Eksisterande eksterne `renovate.json` må oppdaterast manuelt. Taggfiltreringa er meir skjør |

## Tilråding

- **N1: b.** `latest` vert slått opp til nyaste `vX.Y.Z` og brukt som både ref og
  image-tag. Logikken ligg i éin composite action (t.d.
  `.github/actions/resolve-linkml-version`) som dei tre workflowane kallar
  (CI-DRY 2+). Han erstattar dei tre like config-blokkene.
- **N2:** `ap-no-version` tek berre `latest` eller `vX.Y.Z`. Rett
  `ekstern-bruk.md` (tabell, bootstrap-døme, ein tydeleg forklaring av skilnaden
  mellom verktøyversjon og skjemaversjon), og la `bootstrap.sh` validere
  `VERSION` med same regex og avvise skjema-taggar med ei forklarande melding.
- **N3: a.** `release.yml` lagar GitHub Release for `v*.*.*`. Etterpå:
  lag release for eksisterande `v1.1.0` (éin gong, brukaren).

## Steg

1. **Composite action `resolve-linkml-version`:** input `version` (tom =
   les `linkml-datamodellering.yaml`, standard `latest`). Validering
   `^(latest|v[0-9]+\.[0-9]+\.[0-9]+)$` med same feilmelding som i dag.
   `latest` → nyaste `v*.*.*` frå `git ls-remote --tags --sort=-v:refname
   https://github.com/AudunAutomat/linkml-datamodellering-no 'v*.*.*'`
   (første treff utan `^{}`). Feil og tydeleg melding viss ingen tag vert
   funnen. Output: `version` (konkret `vX.Y.Z`).
   - Merk: composite actions i *dette* repoet kan ikkje brukast med
     `uses: ./…` frå eit **eksternt** kallande repo. Dei må refererast som
     `AudunAutomat/linkml-datamodellering-no/.github/actions/resolve-linkml-version@<ref>`.
     Alternativt vert logikken lagd som eit felles skript som vert henta med
     sparse-checkout. Vel éin av dei i gjennomføringa, og logg valet.
2. **`reusable-{generate,lint,validate}.yml`:** erstatt config-steget med kall
   til 1. Bruk `version`-outputen for både `ref:` og `podman pull`.
   Køyr `actionlint` på alle tre.
3. **`bootstrap.sh`:** valider `VERSION` (same regex). Ved skjema-tag:
   feilmelding som forklarar at skjemaversjonen skal låsast i `imports:`. Vurder å
   la `latest` slå opp konkret `vX.Y.Z` for `uses:` (i dag `main`), slik at
   workflow-fila, skripta og imaget alle kjem frå same release (sjå O2).
4. **`mkdocs/docs/arkitektur/ekstern-bruk.md`:** rett «Versjonsfesta oppsett»
   (berre `latest`/`vX.Y.Z`, og kva `latest` tyder), bootstrap-dømet
   (`AP_NO_VERSION=v1.1.0`), og legg til ein kort boks om verktøyversjon mot
   skjemaversjon.
5. **`release.yml`:** ny jobb (eller nytt steg) som lagar GitHub Release for
   `v*.*.*`-taggen etter at image er pusha. `permissions: contents: write`
   berre for den jobben. `actionlint`.
6. **Éin gong (brukaren):** `gh release create v1.1.0 -R
   AudunAutomat/linkml-datamodellering-no --generate-notes --verify-tag`.
7. **BUG-22:** status `løyst` i `bugs/reusable-workflow-latest-ref-manglar.md`
   og `BUGS.md`, med tilvising hit. Fjern punktet under «Samhandling og CI/CD»
   i `BUGS.md`.
8. **Verifiser (O3):** køyr dei tre reusable workflowane frå ein kallar med
   (a) `version: latest`, (b) `version: v1.1.0`, (c) utan
   `linkml-datamodellering.yaml`, og (d) `version: dcat-ap-no-v2.13.0` (skal
   feile med forklarande melding). Kontroller at `latest` vert løyst til `v1.1.0`
   (eller nyare), og at checkout og `podman pull` brukar same verdi.

## Handlingsliste

- [x] 1. Avgjer O1–O4 (alle etter tilrådinga)
- [x] 2. `resolve-linkml-version` (composite action, O4-val: `@main`-referanse)
- [x] 3. Tre reusable workflows brukar han (+ actionlint)
- [x] 4. `bootstrap.sh`: versjonsvalidering, `uses: …@<nyaste vX.Y.Z>` (O2), skjema-tag i import-døme
- [x] 5. `ekstern-bruk.md`: versjonsomgrep og døme retta. Renovate-malen dekkjer òg `uses:`
- [x] 6. `release.yml`: jobb `github-release` for `v*.*.*` (+ actionlint)
- [x] 6b. Røyktest-workflow `royktest-reusable.yml` (O3) (+ actionlint)
- [x] 7. **Etter push (brukaren):** ny tag `v1.2.0` på `main` → `release.yml` byggjer image og lagar GitHub Release automatisk. **Påkravd**, sjå «Rekkjefølgje etter push»
- [-] 7b. (valfritt, brukaren) GitHub Release for eldre `v1.1.0`: **ikkje utført**, ikkje naudsynt sidan `v1.2.0` er nyaste release
- [x] 8. Røyktest grøn → BUG-22 → `løyst`
- [x] 9. Verifiser (a)–(d) via røyktesten

## Opne spørsmål

- ~~**O1:**~~ **Avgjort 2026-09-26: N1 b, N3 a** (tilrådinga).
- ~~**O2:**~~ **Avgjort 2026-09-26: `@<nyaste vX.Y.Z>`** (tilrådinga). Skal `bootstrap.sh` med `latest` skrive `uses: …@main` (som i dag) eller
  `uses: …@<nyaste vX.Y.Z>`? Tilråding: **`@<nyaste vX.Y.Z>`**. `@main` gjer at
  workflow-fila kan vere nyare enn skripta og imaget som ho sjølv hentar. Ekstern
  oppgradering skjer då via Renovate (N3), som elles ikkje kan oppdatere
  `uses:`-referansen. Viss Renovate òg skal oppdatere `uses:`, trengst ein ekstra
  `matchStrings` i malen (inngår i steg 5/N3).
- ~~**O3:**~~ **Avgjort 2026-09-26: (a) permanent røyktest** (tilrådinga). Korleis skal steg 9 verifiserast? (a) ein permanent
  røyktest-workflow i dette repoet (`workflow_dispatch`, kallar dei tre reusable
  workflowane med eit referanseskjema, med matrise over versjonsvariantane), eller
  (b) eit eingongs testrepo hos brukaren. Tilråding: **(a)**. Då vert N1 fanga
  før eksterne merkar det, og det er same klasse feil som BUG-22 sjølv (12+
  veker uoppdaga).
- ~~**O4:**~~ **Avgjort 2026-09-26: ja** (tilrådinga). Val i steg 1 (composite action refererert som
  `AudunAutomat/…/.github/actions/…@<ref>` eller skript via sparse-checkout)
  vert gjort under gjennomføringa. Er det greitt at det vert logga i Avgjerder
  utan eige spørsmål? Tilråding: **ja**.

## Avgjerder

- Rules (brukar stadfesta 2026-09-26): to lærdommar er lagde til i
  `.claude/rules/ci-workflows.md` under «Reusable workflows og composite actions»:
  «`./` i ein reusable workflow peikar på kallande repo» (frå O4) og «Public
  reusable workflows skal vere dekte av røyktesten» (frå O3/BUG-22). Same fil
  fordi scopet (`.github/workflows/**`, `.github/actions/**`) er identisk. I same
  endring er «To kategoriar» retta: `reusable-lint.yml` er òg public API, men
  mangla i lista.
- **O4, composite action med `@main`-referanse:** Dei tre reusable workflowane
  kallar `AudunAutomat/linkml-datamodellering-no/.github/actions/resolve-linkml-version@main`.
  `./` peikar på kallande repo når workflowen er kalla eksternt, og versjonen må
  vere kjend *før* vår eigen kode vert sjekka ut, så eit delt skript via
  sparse-checkout ville gitt høna-og-egget-problem. `uses:` krev ein statisk
  ref, og difor `@main`. Konsekvens: actionen er public API og må vere
  bakoverkompatibel (skrive i `description`).
- **O2 og `ap-no-version`:** `bootstrap.sh` låser `uses: …@<nyaste vX.Y.Z>`, men
  skriv `ap-no-version` som oppgitt (`latest` vert ståande som `latest`).
  Brukaren sitt val av flytande eller fast versjon vert respektert for
  skript og image. Workflow-fila er låst og vert oppdatert av Renovate via det
  nye `uses:`-mønsteret i malen.
- **Import-dømet i `bootstrap.sh`** brukar no nyaste `dcat-ap-no-v*`-skjematag i
  staden for verktøytaggen (N2). Oppslaget har ei synleg `ÅTVARING` og ein
  plasshaldar viss det feilar, så det er ingen stille fallback.
- **Utdaterte stiar i `bootstrap.sh`** (funne under steg 4, jf. regelen om
  flytting i CLAUDE.md): `…/${WORKFLOW_REF}/renovate.json` → `.github/renovate.json`
  (gav 404), og `https://linkml.datamodellering.no/ekstern-bruk/` (resolvar
  ikkje) → portalsida på `audunautomat.github.io`.
- **Røyktest-avgrensing:** `reusable-lint.yml` og `reusable-generate.yml` kan ikkje
  køyrast frå dette repoet (dei stoppar når kallaren har `src/assets/` eller
  `Makefile`). Røyktesten dekkjer difor actionen (5 versjonstilfelle, lokal kopi)
  og `reusable-validate.yml` (`latest`, `v1.1.0`). Dei tre workflowane deler same
  versjonsløysing.
- **Rekkjefølgje etter push:** Bootstrap låser `uses:` til nyaste `vX.Y.Z`. Ved
  push er det `v1.1.0`, og den versjonen av `reusable-*.yml` har den gamle
  logikken (`ref: latest`). Ein ny tag `v1.2.0` med fiksen er difor
  **påkravd**. Før han finst, gir nye bootstrap-oppsett med `latest` framleis
  BUG-22. Kallarar som alt har `@main`, får fiksen straks.

- Specen er ei kartlegging med tilråding. Ingen kode er endra, og specen står i
  `specs/backlog/`.
- N2 og N3 er tekne med i same spec som BUG-22 (N1), fordi dei tre ligg i same
  versjonskjede. Ein fiks av N1 åleine ville framleis gi eksterne brukarar ei
  rettleiing (skjema-taggar som `ap-no-version`) og ei auto-oppgradering
  (Renovate) som ikkje fungerer.

## Utført

### Før push (2026-09-26)

**Utført lokalt:**
- `.github/actions/resolve-linkml-version/action.yml` (ny): input → config →
  `latest` → nyaste `vX.Y.Z` via `git ls-remote --tags --sort=-v:refname`.
  Skjema-tag gir eiga forklarande feilmelding. Testa lokalt (same skript):
  `latest` → `v1.1.0`, `v1.1.0` → `v1.1.0`, tom → `v1.1.0`, frå config
  (`v1.0.0`) → `v1.0.0`, `dcat-ap-no-v2.13.0` → feil (skjema-tag), `main` → feil.
- `reusable-{generate,lint,validate}.yml`: config-steget er erstatta av actionen
  (step-id `config` er behalden). actionlint: ingen funn utanom shellcheck.
- `bootstrap.sh`: sjå Avgjerder. Testa i scratch-katalog: utan argument →
  `ap-no-version: latest` + `uses: …@v1.1.0`, import-døme `dcat-ap-no-v2.14.3`,
  renovate-URL `…/v1.1.0/.github/renovate.json` (200). `v1.0.0` → låst til
  `v1.0.0`. `dcat-ap-no-v2.13.0` / `main` → `FEIL`, exit 1.
- `.github/renovate.json`: ny `customManager` for
  `uses: AudunAutomat/linkml-datamodellering-no/.github/workflows/…@vX.Y.Z`
  (regex testa mot ei bootstrap-generert linje → `v1.1.0`).
- `mkdocs/docs/arkitektur/ekstern-bruk.md`: bootstrap-døme `AP_NO_VERSION=v1.1.0`,
  tabellen retta, `!!! warning "Verktøyversjon ≠ skjemaversjon"`, og
  Renovate-dømet med `uses:`-mønsteret.
- `release.yml`: jobb `github-release` (`needs` alle 4 image-jobbar, berre
  `refs/tags/v*`, `contents: write`, idempotent). actionlint: ingen funn.
- `.github/workflows/royktest-reusable.yml` (ny): `workflow_dispatch`, veke-cron
  og push til `main` på relevante stiar. actionlint: ingen funn.

**Står att:** steg 7 (tag `v1.2.0`, brukaren), 7b (valfritt), 8 (BUG-22 →
`løyst` etter grøn røyktest) og 9 (verifisering via røyktesten).

### Etter push og release (2026-09-26)

| Kontroll | Resultat |
|---|---|
| Push `10ae299a` → `royktest-reusable.yml` (`36245471889`, automatisk) | 7/7 grøne. `reusable-validate / latest`: `latest → v1.1.0`, `"valid": true` |
| Tag `v1.2.0` (brukaren) → `release.yml` (`36245671873`) | 5/5 grøne: 4 image-jobbar + ny `github-release` |
| GitHub Release `v1.2.0` | oppretta av `github-actions[bot]` 13:36:44, er repoets `releases/latest` (Renovate-kjelde, N3) |
| GHCR (anonym `tags/list`) | `linkml-local`, `mcp-linkml-validator`, `mcp-linkml-modell-utkast`, `mcp-linkml-begrep-utkast`: alle `v1.1.0`, `v1.2.0`, `latest` |
| Røyktest på nytt (`36245764491`, dispatch) | 7/7 grøne. `latest → v1.2.0` |

Verifisering (a)–(d) frå steg 9 er dekt av røyktesten: (a) `latest` og
(b) `v1.1.0` i både action- og `reusable-validate`-jobbar, (c) tom input utan
config, (d) skjema-tag `dcat-ap-no-v2.13.0` og `main` avviste med forventa
`failure`.

BUG-22: status `løyst` i `bugs/reusable-workflow-latest-ref-manglar.md` (med
`## Løysing`) og i `BUGS.md`. PoC-punktet under «Samhandling og CI/CD» er fjerna.

**Ikkje utført:** 7b (GitHub Release for `v1.1.0`). Det er valfritt og ikkje
naudsynt, sidan Renovate berre treng nyaste release.

**Kjende avgrensingar som står att:** `reusable-lint.yml` og
`reusable-generate.yml` er ikkje dekte av røyktesten (sjå Avgjerder). Dei deler
den testa versjonsløysinga, men ein full ende-til-ende-test krev eit eige
testrepo utan `src/assets/`/`Makefile`.
