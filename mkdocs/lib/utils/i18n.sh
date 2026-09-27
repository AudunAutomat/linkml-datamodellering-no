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
# Sjå specs/done/lokalisering-dokumentasjonsportal.md (steg 3).
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

# i18n_source <sti>
# Skriv stien til språkvarianten av ei kjeldefil for gjeldande språk
# (x.md -> x.<lang>.md) dersom ho finst og språket ikkje er standardspråket,
# elles originalstien. Returnerer 1 når originalen vert brukt for eit anna
# språk enn standardspråket (dvs. innhaldet er ikkje omsett).
i18n_source() {
    local path="$1" variant
    if [[ "$I18N_LANG" == "$I18N_DEFAULT_LANG" ]]; then
        printf '%s' "$path"; return 0
    fi
    variant="${path%.md}.$I18N_LANG.md"
    if [[ -f "$variant" ]]; then
        printf '%s' "$variant"; return 0
    fi
    printf '%s' "$path"; return 1
}

# i18n_note_untranslated <fil>
# Set inn merknaden «ikkje omsett» (katalognøklane i18n.ikkje_omsett.*) rett
# etter første H1 i fila (øvst dersom fila ikkje har H1).
i18n_note_untranslated() {
    local file="$1" tittel tekst tmp
    tittel=$(t i18n.ikkje_omsett.tittel)
    tekst=$(t i18n.ikkje_omsett.tekst)
    tmp="$file.i18n.tmp"
    awk -v tittel="$tittel" -v tekst="$tekst" '
        function note() { print "!!! info \"" tittel "\""; print "    " tekst; print "" }
        !done && /^# / { print; print ""; note(); done = 1; next }
        { lines[++n] = $0; if (!done) next; print }
        END { if (!done) { note(); for (i = 1; i <= n; i++) print lines[i] } }
    ' "$file" > "$tmp" && mv "$tmp" "$file"
}

# i18n_strip_front_matter <fil>
# Skriv fila til stdout utan i18n-front-matter (---/i18n:/---) frå
# omsette sider (x.<lang>.md, jf. mkdocs/lib/scripts/i18n_status.py). Anna
# front-matter vert behalde.
i18n_strip_front_matter() {
    awk '
        NR == 1 && $0 == "---" { fm = 1; buf = $0 "\n"; next }
        fm == 1 { buf = buf $0 "\n"; if ($0 ~ /^i18n:/) has = 1; if ($0 == "---") { fm = 2; if (!has) printf "%s", buf } ; next }
        { print }
        END { if (fm == 1) printf "%s", buf }
    ' "$1"
}

# i18n_fill_auto_blocks <variant> <original> [<portal-url>]
# Skriv variant til stdout med innhaldet i kvar <!-- BEGIN/END AUTO-GENERATED -->-
# blokk henta frå same blokk i originalen (t.d. README-tabellane, som
# generate-readme-tables.sh berre oppdaterer i README.md). Med <portal-url>
# vert lenkjer til portalen i blokkene skrivne om til /<språk>/.
i18n_fill_auto_blocks() {
    local variant="$1" original="$2" portal="${3:-}"
    awk -v portal="$portal" -v lang="$I18N_LANG" '
        FNR == NR {
            if ($0 ~ /^<!-- BEGIN AUTO-GENERATED/) { key = $0; blk[key] = ""; next }
            if ($0 ~ /^<!-- END AUTO-GENERATED/) { key = ""; next }
            if (key != "") blk[key] = blk[key] $0 "\n"
            next
        }
        /^<!-- BEGIN AUTO-GENERATED/ {
            print
            if (!($0 in blk)) { print "i18n_fill_auto_blocks: blokka finst ikkje i originalen: " $0 > "/dev/stderr"; failed = 1; next }
            body = blk[$0]
            if (portal != "") gsub(portal "/", portal "/" lang "/", body)
            printf "%s", body; inblk = 1; next
        }
        /^<!-- END AUTO-GENERATED/ { inblk = 0 }
        !inblk { print }
        END { exit failed }
    ' "$original" "$variant"
}
