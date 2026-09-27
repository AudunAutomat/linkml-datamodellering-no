#!/usr/bin/env bash
# Generer modellmetadata-tabell (seksjon 7 i index.md)
set -euo pipefail
trap 'echo "ERROR in ${BASH_SOURCE[0]}:${LINENO} — command: ${BASH_COMMAND}" >&2; exit 1' ERR

generate_metadata() {
    local gendoc_index="$1"

    [ ! -f "$gendoc_index" ] && return 0

    echo "---"
    echo ""
    # Ekstraher frå "## <modellmetadata-markør>" til neste "##" eller "###"-seksjon
    # (ikkje inkludert). Gen-doc skriv i18n-markør og ankeret {: #modellmetadata }
    # (steg 5); skjemasida brukar det stabile {#metadata}. Markøren vert bytt ut
    # av publish.sh til slutt.
    awk '/^## @@i18n:docgen\.modellmetadata@@( \{: #modellmetadata \})?$/{ p=1; print "## @@i18n:docgen.modellmetadata@@ {#metadata}"; next } p{ if(/^###? /){ exit } print }' "$gendoc_index"
}
