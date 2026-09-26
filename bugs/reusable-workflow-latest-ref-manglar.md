# Bug: reusable workflows sjekkar ut `ref: latest`, som ikkje finst

**ID:** BUG-22
**Status:** `open`
**Komponent:** `.github/workflows/reusable-generate.yml`, `reusable-lint.yml`, `reusable-validate.yml`
**Oppdaga:** 2026-09-26

## Symptom

Ein ekstern kallar som brukar ein av dei public reusable workflowane
**utan** `ap-no-version` i `linkml-datamodellering.yaml` (eller med
`ap-no-version: latest`, som `mkdocs/docs/arkitektur/ekstern-bruk.md`
tilrår som «flytande — anbefalt»), vil feile i steget som hentar
verktøya frå dette repoet: `actions/checkout` finn ingen ref som heiter
`latest`.

## Rot-årsak

Alle tre workflowane les versjonen slik:

```bash
VERSION="${{ inputs.version }}"
[ -z "$VERSION" ] && VERSION=$(grep '^ap-no-version:' linkml-datamodellering.yaml | awk '{print $2}')
VERSION="${VERSION:-latest}"
```

og brukar `VERSION` til to ulike ting:

1. **Container-image-tag:** `ghcr.io/audunautomat/<image>:${VERSION}` —
   `:latest` finst (vert laga av `release.yml`), så dette fungerer.
2. **Git-ref for `actions/checkout`** (`repository:
   AudunAutomat/linkml-datamodellering-no`, `ref: ${VERSION}`) — det finst
   ingen branch eller tag som heiter `latest` (`git ls-remote origin latest`
   gir 0 treff, og det same galdt i `brreg/linkml-datamodellering-no` før
   flyttinga). Checkout feilar.

`latest` er altså meiningsfull for image, men ikkje for git.

## Berørte

Alle eksterne repo som kallar `reusable-{generate,lint,validate}.yml` utan
å låse `ap-no-version` til ein `vX.Y.Z`-tag. Kallarar med
`ap-no-version: v1.1.0` (eller ein annan eksisterande `vX.Y.Z`) er ikkje
berørte. Ikkje berørt: dette repoet sine eigne workflowar (brukar ikkje dei
public reusable workflowane).

Oppdaga under steg 9.5/9.9 i
`specs/backlog/ci-etter-origin-flytting-audunautomat.md` — feilen er eldre enn
flyttinga, men vert synleg når eksterne tek i bruk det nye repoet.

## Workaround

Set `ap-no-version: v1.1.0` (eller nyare `vX.Y.Z`) i
`linkml-datamodellering.yaml`, eller send `version: v1.1.0` som input.

## Forslag til løysing

Skil mellom image-tag og git-ref i config-steget, t.d. ein ekstra output
`ref` der `latest` vert mappa til `main` (eller til nyaste `v*.*.*`-tag via
`git ls-remote --tags --sort=-v:refname`), medan `version` framleis vert
brukt som image-tag. Må gjerast likt i alle tre filene (CI-DRY-terskel 2+,
jf. `.claude/rules/ci-workflows.md`), og `ekstern-bruk.md` må oppdaterast
til å skildre kva `latest` faktisk tyder.
