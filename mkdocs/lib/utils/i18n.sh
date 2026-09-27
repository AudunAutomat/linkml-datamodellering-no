#!/usr/bin/env bash
# Strengoppslag for portaltekst frå mkdocs/lib/i18n/strings.yaml.
#
#   i18n_load [lang]        # éin gong per språk, før seksjonsjobbane startar
#                           # (utan argument: default_language i katalogen)
#   heading=$(t <nøkkel>)
#
# Katalogen vert rendra til ein assosiativ tabell (I18N) i python-pytest-
# kontaineren. Tabellen vert arva av bakgrunnsjobbane (`process_schema &`) i
# publish.sh. Inne i `echo "$(t key)"` vert feilstatusen til t svelgd
# (meldinga kjem likevel på stderr). Difor køyrer publish.sh
# `i18n_strings.py check` før bygget, som fangar ukjende nøklar statisk
# (same sjekk som `make i18n-check`). Der kontrollflyten avheng av resultatet,
# tilordn til ein variabel (`x=$(t key)`) slik at `set -e` slår inn.
# Sjå specs/backlog/lokalisering-dokumentasjonsportal.md (steg 3).
set -euo pipefail

source "$REPO_ROOT/mkdocs/lib/utils/python_container.sh"

# i18n_load [lang]
i18n_load() {
    local lang="${1:-}" rendered
    if ! rendered=$(run_python_container /work/mkdocs/lib/scripts/i18n_strings.py render-sh ${lang:+--lang "$lang"}); then
        echo "ERROR: i18n_load: kunne ikkje laste strengkatalogen for språk '${lang:-<standard>}'" >&2
        return 1
    fi
    # Rendra av i18n_strings.py med shlex-quota verdiar — sjå render_sh()
    eval "$rendered"
}

# t <nøkkel> [navn=verdi ...]
# Plasshaldarar i katalogverdien på forma {navn} vert bytte ut med verdi.
# Ein plasshaldar som står att etter utbytinga, er ein feil.
t() {
    local key="$1"; shift
    if [[ -z "${I18N_LANG:-}" ]]; then
        echo "ERROR: t '$key': i18n_load er ikkje kalla" >&2
        return 1
    fi
    if [[ -z "${I18N[$key]+x}" ]]; then
        echo "ERROR: t: i18n-nøkkel '$key' manglar i katalogen (språk: $I18N_LANG)" >&2
        return 1
    fi
    local value="${I18N[$key]}" rest arg name
    # Sjekk malen (ikkje resultatet): innsette verdiar kan sjølve innehalde {...}
    rest="$value"
    while [[ "$rest" =~ \{([a-z_]+)\} ]]; do
        name="${BASH_REMATCH[1]}"
        rest="${rest#*"${BASH_REMATCH[0]}"}"
        for arg in "$@"; do [[ "${arg%%=*}" == "$name" ]] && continue 2; done
        echo "ERROR: t: i18n-nøkkel '$key' har plasshaldar utan verdi: {$name} (språk: $I18N_LANG)" >&2
        return 1
    done
    for arg in "$@"; do
        value="${value//"{${arg%%=*}}"/"${arg#*=}"}"
    done
    printf '%s' "$value"
}

# i18n_render <kjelde> <mål>
# Kopier ei fil og byt ut alle @@i18n:<nøkkel>@@-markørar med tekst frå
# katalogen (brukt for Material-overrides og, frå steg 5, gen-doc-malar).
i18n_render() {
    local src="$1" dst="$2" content key value
    content=$(<"$src") || { echo "ERROR: i18n_render: kan ikkje lese $src" >&2; return 1; }
    while [[ "$content" =~ @@i18n:([a-z0-9_.]+)@@ ]]; do
        key="${BASH_REMATCH[1]}"
        value=$(t "$key") || return 1
        content="${content//"@@i18n:$key@@"/"$value"}"
    done
    printf '%s\n' "$content" > "$dst"
}
