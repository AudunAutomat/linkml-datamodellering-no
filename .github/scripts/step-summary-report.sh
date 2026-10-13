#!/usr/bin/env bash
# Skriv ein rapport til $GITHUB_STEP_SUMMARY med byte-tak.
#
# GitHub avviser heile Step Summary-en for steget når ho er over 1 MiB
# ("upload aborted"). Rapportar over taket vert avkorta ved heile linjer
# (LC_ALL=C: awk tel byte, ikkje teikn). Ei linje i Step Summary og i
# jobbloggen viser då til artefakten med fullstendig rapport.
# Sjå .claude/rules/ci-workflows.md § «Step Summary: byte-tak på rapportar».
#
# Bruk:
#   step-summary-report.sh <tittel> <rapport> <artefakt>
#
# Miljø:
#   SUMMARY_MAX_BYTES  byte-tak (standard 900000)

set -euo pipefail

if [ "$#" -ne 3 ]; then
  echo "Bruk: $0 <tittel> <rapport> <artefakt>" >&2
  exit 2
fi

title=$1
report=$2
artifact=$3
max_bytes=${SUMMARY_MAX_BYTES:-900000}

if [ ! -f "$report" ]; then
  echo "::error::step-summary-report: fann ikkje rapporten '$report'" >&2
  exit 1
fi

report_bytes=$(wc -c < "$report")
{
  echo "## $title"
  if [ "$report_bytes" -le "$max_bytes" ]; then
    cat "$report"
  else
    LC_ALL=C awk -v max="$max_bytes" \
      '{ n += length($0) + 1; if (n > max) exit; print }' "$report"
    echo ""
    echo "**Avkorta:** rapporten er ${report_bytes} byte, over grensa for Step Summary. Fullstendig rapport: opplasta artefakt \`${artifact}\`."
  fi
} >> "$GITHUB_STEP_SUMMARY"

if [ "$report_bytes" -gt "$max_bytes" ]; then
  echo "Step Summary avkorta til ${max_bytes} av ${report_bytes} byte — sjå artefakten '${artifact}'."
fi
