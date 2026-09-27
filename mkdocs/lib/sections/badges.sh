#!/usr/bin/env bash
# Generer badge-rad (seksjon 2 i index.md)
set -euo pipefail
trap 'echo "ERROR in ${BASH_SOURCE[0]}:${LINENO} — command: ${BASH_COMMAND}" >&2; exit 1' ERR

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../utils/metadata_parsers.sh"

generate_badges() {
    local domain="$1"
    local schema="$2"
    local gendoc_index="$3"

    [ ! -f "$gendoc_index" ] && return 0

    # Parse metadata frå gen-doc
    local version=$(grep "^| Versjon" "$gendoc_index" | sed 's/.*| \([^ ]*\) |/\1/' | head -1)
    local status=$(grep "^| Status" "$gendoc_index" | sed 's|.*status/\([^)]*\).*|\1|' | head -1)
    local license=$(grep "^| Lisens" "$gendoc_index" | sed 's|.*/nlod/no/\([0-9.]*\).*|\1|' | head -1)
    local endringsdato=$(grep "^| Endringsdato" "$gendoc_index" | sed 's/^| Endringsdato | \(.*\) |$/\1/' | head -1)
    local utgiver_uri=$(grep "^| Utgiver" "$gendoc_index" | sed -n 's/^| Utgiver | \[\(https:[^]]*\)\].*/\1/p' | head -1)

    # Slå opp organisasjonsnavn frå det pre-berekna
    # ORG_URI_TO_NAME_SERIALIZED-registeret (CODEOWNERS.md parsa éin gong i
    # publish.sh Steg 1.5) i staden for eit eige `podman run`-kall per
    # skjema — sjå specs/backlog/reduser-podman-kall-docs-publish.md.
    local utgiver_navn=""
    if [ -n "$utgiver_uri" ]; then
        utgiver_navn=$(lookup_org_name "$utgiver_uri") || utgiver_navn=""
    fi

    # Valideringsstatus
    local validation_json=$(get_validation_json_path "$domain" "$schema")
    local manifest="$REPO_ROOT/src/linkml/${domain}/${schema}/build.yaml"
    local policy=$(get_validation_policy "$manifest")
    local val_status; val_status=$(t badge.ukjent)
    local val_color="lightgrey"

    if [ -f "$validation_json" ]; then
        # Støtt både errorCount (ny camelCase) og error_count (gamal snake_case)
        local errors
        if errors=$(python3 -c "import json; d=json.load(open('$validation_json')); r=d.get('result', {}); print(r.get('errorCount', r.get('error_count', 0)))" 2>&1) && [ -n "$errors" ]; then
            if [ "$errors" -eq 0 ]; then
                val_status=$(t badge.validering.godkjent)
                val_color="green"
            else
                val_status=$(t badge.validering.feil antal="$errors")
                val_color="yellow"
            fi
        else
            echo "ÅTVARING: kunne ikkje lese valideringsresultat frå $validation_json — behelt status 'ukjent' ($errors)" >&2
        fi
    fi

    # Normaliser status-navn
    local status_label="$status"
    local status_color="blue"
    case "$status" in
        Completed) status_label=$(t badge.status.ferdigstilt); status_color="green" ;;
        UnderDevelopment) status_label=$(t badge.status.under_utvikling); status_color="orange" ;;
        Deprecated) status_label=$(t badge.status.foreldet); status_color="red" ;;
        Withdrawn) status_label=$(t badge.status.trukket_tilbake); status_color="red" ;;
    esac

    # URL-encode
    local val_status_encoded="${val_status// /_}"
    val_status_encoded="${val_status_encoded//✓/%E2%9C%93}"
    local policy_encoded="${policy//-/_}"

    # Output badges — bilete utan omsluttande lenkje (badgane er ikkje
    # klikkbare, sjå specs/done/lenkjesjekk-3817-feil-evaluering.md)
     if [ -n "$utgiver_navn" ]; then
        local utgiver_encoded="${utgiver_navn// /_}"
        utgiver_encoded="${utgiver_encoded//-/--}"
        echo "![$(t badge.utgiver.alt)](https://img.shields.io/badge/$(t badge.utgiver.etikett)-${utgiver_encoded}-blue)"
    fi
    [ -n "$license" ] && echo "![$(t badge.lisens.alt)](https://img.shields.io/badge/NLOD-${license}-blue)"
    if [ -n "$status" ]; then
        echo "![$(t badge.status.alt)](https://img.shields.io/badge/$(t badge.status.etikett)-${status_label}-${status_color})"
    else
        echo "![$(t badge.status.alt)](https://img.shields.io/badge/$(t badge.status.etikett)-$(t badge.ukjent)-lightgrey)"
    fi
    echo "![$(t badge.versjon.alt)](https://img.shields.io/badge/$(t badge.versjon.etikett)-${version}-blue)"
    echo "![$(t badge.validering.alt)](https://img.shields.io/badge/${policy_encoded}-${val_status_encoded}-${val_color})"
    local endringsdato_encoded="${endringsdato//-/--}"
    [ -n "$endringsdato" ] && echo "![$(t badge.endringsdato.alt)](https://img.shields.io/badge/$(t badge.endringsdato.etikett)-${endringsdato_encoded}-blue)"
    echo ""
    echo ""
}
