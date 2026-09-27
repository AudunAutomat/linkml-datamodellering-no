#!/usr/bin/env bash
# Generer eksempeldatafil-seksjon (seksjon 6 i index.md)
set -euo pipefail
trap 'echo "ERROR in ${BASH_SOURCE[0]}:${LINENO} — command: ${BASH_COMMAND}" >&2; exit 1' ERR

source "$REPO_ROOT/mkdocs/lib/utils/imported_schemas.sh"

generate_example() {
    local domain="$1"
    local schema="$2"

    # Finn kjeldemappe for skjemaet via det pre-berekna oppslaget frå
    # Steg 1.5 — sjå specs/backlog/batch-docs-publish-generering.md
    local schema_file
    schema_file=$(lookup_schema_path "${schema}-schema") || schema_file=""
    local src_dir=""
    [ -n "$schema_file" ] && src_dir=$(dirname "$schema_file")

    local example_file=""
    [ -n "$src_dir" ] && example_file="$src_dir/examples/${schema}-eksempel.yaml"

    [ ! -f "$example_file" ] && return 0

    # Rekonstruer relative sti frå src/linkml/ for GitHub-lenke
    local relative_path="${src_dir#$REPO_ROOT/src/linkml/}"

    echo "---"
    echo ""
    echo "## $(t seksjon.eksempeldatafil.tittel) {#eksempeldatafil}"
    echo ""
    echo "> $(t seksjon.eksempeldatafil.forklaring)"
    echo ""
    echo "\`\`\`yaml"
    # Ekstraher første 20 liner (eller til første tom linje etter header)
    head -20 "$example_file" | awk '
        NR == 1 && /^#/ { in_header = 1 }
        in_header && /^$/ { in_header = 0; next }
        !in_header { print }
        NR > 20 { exit }
    '
    echo "\`\`\`"
    echo ""
    echo "[📄 $(t seksjon.eksempeldatafil.full_fil)](https://raw.githubusercontent.com/AudunAutomat/linkml-datamodellering-no/main/src/linkml/$relative_path/examples/$schema-eksempel.yaml)"
    echo ""
    echo "*$(t seksjon.eksempeldatafil.per_klasse)*"
    echo ""
    echo ""
}
