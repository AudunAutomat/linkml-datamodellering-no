#!/usr/bin/env bash
# Generer Datamodell-seksjon med lenke til LinkML-schema

set -euo pipefail
trap 'echo "ERROR in ${BASH_SOURCE[0]}:${LINENO} — command: ${BASH_COMMAND}" >&2; exit 1' ERR

generate_datamodell() {
    local domain="$1"
    local schema="$2"
    # Delmodell-skjema (t.d. dqv-core, modelldcat-katalog) ligg fysisk i
    # FORELDRE-skjemaet sin katalog, ikkje i ein katalog oppkalla etter seg
    # sjølv — PARENT_MODEL er eksportert av publish.sh for slike skjema.
    local source_dir="${PARENT_MODEL:-$schema}"

    local tittel forklaring kjelde
    tittel=$(t seksjon.datamodell.tittel)
    forklaring=$(t seksjon.datamodell.forklaring)
    kjelde=$(t seksjon.datamodell.kjelde lenkje="[\`$schema-schema.yaml\`](https://github.com/AudunAutomat/linkml-datamodellering-no/blob/main/src/linkml/$domain/$source_dir/$schema-schema.yaml)")

    cat <<EOF

## $tittel {#datamodell}

> $forklaring

$kjelde

EOF
}
