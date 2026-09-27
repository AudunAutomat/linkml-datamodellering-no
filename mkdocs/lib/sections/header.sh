#!/usr/bin/env bash
# Generer hovudoverskrift (seksjon 1 i index.md)
set -euo pipefail
trap 'echo "ERROR in ${BASH_SOURCE[0]}:${LINENO} — command: ${BASH_COMMAND}" >&2; exit 1' ERR

generate_header() {
    local schema="$1"
    echo "# $schema"
    echo ""
    # Modellinnhaldet (navn og skildringar frå skjemaet) vert ikkje omsett —
    # sjå specs/done/lokalisering-dokumentasjonsportal.md (avgrensing).
    if [ "$I18N_LANG" != "$I18N_DEFAULT_LANG" ]; then
        echo "!!! note \"$(t i18n.modellinnhald_norsk_tittel)\""
        echo "    $(t i18n.modellinnhald_norsk)"
        echo ""
    fi
}
