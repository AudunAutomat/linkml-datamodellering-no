#!/usr/bin/env bash
# Strengoppslag for portaltekst frå mkdocs/lib/i18n/strings.yaml.
#
#   i18n_load <lang>        # éin gong per språk, før seksjonsjobbane startar
#   heading=$(t <nøkkel>)
#
# Katalogen vert rendra til ein assosiativ tabell (I18N) i python-pytest-
# kontaineren. Tabellen vert arva av bakgrunnsjobbane (`process_schema &`) i
# publish.sh. Tilordn alltid resultatet av t til ein variabel først
# (`x=$(t key)`), slik at `set -e` stoppar skriptet ved ukjend nøkkel — inne i
# `echo "$(t key)"` vert feilstatusen elles svelgd (meldinga kjem likevel på
# stderr). `make i18n-check` fangar ukjende nøklar statisk før bygg.
# Sjå specs/backlog/lokalisering-dokumentasjonsportal.md (steg 3).
set -euo pipefail

source "$REPO_ROOT/mkdocs/lib/utils/python_container.sh"

# i18n_load <lang>
i18n_load() {
    local lang="$1" rendered
    if ! rendered=$(run_python_container /work/mkdocs/lib/scripts/i18n_strings.py render-sh --lang "$lang"); then
        echo "ERROR: i18n_load: kunne ikkje laste strengkatalogen for språk '$lang'" >&2
        return 1
    fi
    # Rendra av i18n_strings.py med shlex-quota verdiar — sjå render_sh()
    eval "$rendered"
}

# t <nøkkel>
t() {
    local key="$1"
    if [[ -z "${I18N_LANG:-}" ]]; then
        echo "ERROR: t '$key': i18n_load er ikkje kalla" >&2
        return 1
    fi
    if [[ -z "${I18N[$key]+x}" ]]; then
        echo "ERROR: t: i18n-nøkkel '$key' manglar i katalogen (språk: $I18N_LANG)" >&2
        return 1
    fi
    printf '%s' "${I18N[$key]}"
}
