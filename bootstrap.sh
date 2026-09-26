#!/usr/bin/env bash
# Bootstrap: Legg til LinkML-støtte i eit eksisterande repo.
#
# Bruk:
#   bash bootstrap.sh
#   curl -sSL https://raw.githubusercontent.com/AudunAutomat/linkml-datamodellering-no/main/bootstrap.sh | bash
#
# Standardversjon er "latest" (siste release, vX.Y.Z).
# For å feste til ein konkret release, send versjonen (vX.Y.Z) som argument eller
# set AP_NO_VERSION. Dette er VERKTØYVERSJONEN (workflowar, skript, image) — ikkje
# ein skjemaversjon: skjemaversjonen (t.d. dcat-ap-no-v2.14.3) vert låst i
# imports:-URL-en i skjemaet ditt. Sjå specs/backlog/reusable-workflow-versjon.md.

set -euo pipefail

UPSTREAM="https://github.com/AudunAutomat/linkml-datamodellering-no"
RAW="https://raw.githubusercontent.com/AudunAutomat/linkml-datamodellering-no"

VERSION="${1:-${AP_NO_VERSION:-latest}}"

if ! echo "$VERSION" | grep -Eq '^(latest|v[0-9]+\.[0-9]+\.[0-9]+)$'; then
    if echo "$VERSION" | grep -Eq -- '-v[0-9]+\.[0-9]+\.[0-9]+$'; then
        echo "FEIL: '$VERSION' er ein skjema-tag, ikkje ein verktøyversjon." >&2
        echo "      Bruk 'latest' eller vX.Y.Z her, og lås skjemaversjonen i imports:-URL-en." >&2
    else
        echo "FEIL: ugyldig versjon '$VERSION'. Tillatne verdiar er 'latest' eller vX.Y.Z." >&2
    fi
    exit 1
fi

# newest_tag <mønster> — nyaste tag som matchar mønsteret i upstream (tom viss ingen).
newest_tag() {
    git ls-remote --tags --sort=-v:refname "$UPSTREAM" "$1" \
        | grep -v '\^{}' | sed -E 's#.*refs/tags/##' | head -n 1
}

# Reusable workflow-ref: låst til ein konkret vX.Y.Z (ikkje @main), slik at
# workflow-fila, verktøyskripta og imaget kjem frå same release.
if [ "$VERSION" = "latest" ]; then
    if ! command -v git > /dev/null; then
        echo "FEIL: git er påkravd for å løyse 'latest' — installer git eller oppgi vX.Y.Z." >&2
        exit 1
    fi
    WORKFLOW_REF="$(newest_tag 'v*.*.*' | grep -E '^v[0-9]+\.[0-9]+\.[0-9]+$' | head -n 1 || true)"
    if [ -z "$WORKFLOW_REF" ]; then
        echo "FEIL: fann ingen vX.Y.Z-tag i $UPSTREAM — oppgi versjonen eksplisitt." >&2
        exit 1
    fi
else
    WORKFLOW_REF="$VERSION"
fi

# Import-dømet brukar ein SKJEMA-tag (dcat-ap-no-vX.Y.Z), ikkje verktøyversjonen.
DCAT_REF="$(newest_tag 'dcat-ap-no-v*' || true)"
if [ -z "$DCAT_REF" ]; then
    echo "ÅTVARING: fann ingen dcat-ap-no-tag — import-dømet brukar plasshaldaren dcat-ap-no-vX.Y.Z." >&2
    DCAT_REF="dcat-ap-no-vX.Y.Z"
fi

echo "→ Bootstrap LinkML (versjon: ${VERSION}, workflow-ref: ${WORKFLOW_REF})"
echo ""

# --- linkml-datamodellering.yaml ---
if [ -f linkml-datamodellering.yaml ]; then
    echo "  linkml-datamodellering.yaml finst allereie — hoppar over."
else
    cat > linkml-datamodellering.yaml << EOF
# Verktøyversjon av AudunAutomat/linkml-datamodellering-no (latest eller vX.Y.Z).
# latest = nyaste vX.Y.Z. Skjemaversjonar vert låste i imports:-URL-ane.
ap-no-version: ${VERSION}
EOF
    echo "  Oppretta linkml-datamodellering.yaml"
fi

# --- .github/workflows/linkml.yml ---
mkdir -p .github/workflows

if [ -f .github/workflows/linkml.yml ]; then
    echo "  .github/workflows/linkml.yml finst allereie — hoppar over."
else
    cat > .github/workflows/linkml.yml << EOF
name: LinkML

on: [push, pull_request]

jobs:
  validate:
    uses: AudunAutomat/linkml-datamodellering-no/.github/workflows/reusable-validate.yml@${WORKFLOW_REF}
    with:
      schema: src/linkml/DOMENE/MODELL/MODELL-schema.yaml
      policy: bronze
      # instance: src/linkml/DOMENE/MODELL/examples/MODELL-eksempel.yaml
EOF
    echo "  Oppretta .github/workflows/linkml.yml"
fi

echo ""
echo "Neste steg:"
echo ""
echo "  1. Rediger .github/workflows/linkml.yml:"
echo "     Erstatt 'DOMENE/MODELL/MODELL-schema.yaml' med stien til ditt LinkML-skjema."
echo "     Set policy til bronze/silver/gold etter ønska valideringsnivå."
echo ""
echo "  2. Importer AP-NO-profilene i skjemaet ditt (lås skjemaversjonen i URL-en):"
echo "       imports:"
echo "         - linkml:types"
echo "         - ${RAW}/${DCAT_REF}/src/linkml/ap-no/dcat-ap-no/dcat-ap-no-schema"
echo ""
echo "  3. Commit og push — GitHub Actions køyrer valideringa automatisk."
echo ""
echo "  4. (valfritt) Legg til automatisk oppgradering med Renovate:"
echo "     curl -sSL ${RAW}/${WORKFLOW_REF}/.github/renovate.json -o renovate.json"
echo ""
echo "Dokumentasjon: https://audunautomat.github.io/linkml-datamodellering-no/arkitektur/ekstern-bruk/"
