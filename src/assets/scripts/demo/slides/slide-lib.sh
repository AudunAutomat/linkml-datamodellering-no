#!/usr/bin/env bash
# Delt hjelpebibliotek for demo-slides (terminal-slides som vert kalla frå
# SEMIC-demo.sh, eller åleine: bash slides/<slide>.sh). Kjelde: source slide-lib.sh.
#
# Fargane kan overstyrast frå kallaren (SEMIC-demo.sh eksporterer CLR_*); utan
# dei brukar slidane eigne standardverdiar, så kvar slide kan køyrast åleine.
set -uo pipefail     # ikkje -e: stty size feilar utan tty (røyr, CI), og det skal ikkje krasje slida

: "${CLR_STEP:=$'\033[0;36m'}"    # cyan: overskrifter
: "${CLR_OK:=$'\033[0;32m'}"      # grøn
: "${CLR_WARN:=$'\033[0;33m'}"    # gul
: "${CLR_ERR:=$'\033[0;31m'}"     # raud: drift/feil
: "${CLR_DBG:=$'\033[0;90m'}"     # grå: dempa tekst
: "${CLR_RST:=$'\033[0m'}"
CLR_BOLD=$'\033[1m'

# Faktisk terminalbreidd (tput cols gir 80 utan tty på stdout).
slide_cols() {
    local c
    c="$({ stty size < /dev/tty; } 2>/dev/null | awk '{ print $2 }')"
    case "$c" in ''|*[!0-9]*|0) c="${COLUMNS:-}" ;; esac
    case "$c" in ''|*[!0-9]*|0) c="$(tput cols 2>/dev/null || echo 100)" ;; esac
    echo "$c"
}

# slide_begin BREIDD — nullstiller og set venstremarg slik at eit innhaldsfelt
# på BREIDD teikn står sentrert. Skriv ut ein tom linje øvst.
slide_begin() {
    local width="$1" cols
    cols="$(slide_cols)"
    PAD=$(( (cols - width) / 2 ))
    [ "$PAD" -lt 2 ] && PAD=2
    PADSTR="$(printf '%*s' "$PAD" '')"
    echo ""
}

# sl TEKST — éi linje med venstremarg (TEKST kan innehalde ANSI-fargar).
sl() { printf '%s%s\n' "$PADSTR" "${1:-}"; }

# semic_canvas_size [BREIDD HØGDE] — set COLS/ROWS for grafikkslides: eksplisitte
# argument, elles terminalstorleik (minus 3 rader til demo-prompten), avgrensa
# til maks 220x60.
semic_canvas_size() {
    if [ "$#" -ge 2 ]; then
        COLS="$1"; ROWS="$2"
    else
        COLS="$(slide_cols)"
        ROWS="$({ stty size < /dev/tty; } 2>/dev/null | awk '{ print $1 }')"
        case "$ROWS" in ''|*[!0-9]*|0) ROWS="$(tput lines 2>/dev/null || echo 40)" ;; esac
        ROWS=$(( ROWS - 3 ))
    fi
    [ "$COLS" -gt 220 ] && COLS=220
    [ "$ROWS" -gt 60 ] && ROWS=60
    return 0
}

# semic_background MEDIA — skriv ut stien til ei temp-cellefil med bakgrunnsbiletet
# MEDIA (t.d. ppt/media/image1.jpg) frå SEMIC-malen, skalert til COLS x ROWS.
# Standard er teikna 8-bit-artwork (tom utskrift). Berre med SEMIC_BACKGROUND=template
# vert biletet frå malen brukt; manglar malen, sips eller python3, er utskrifta
# tom (og ei dempa melding går til stderr), slik at slida brukar teikna artwork.
# Malen: $SEMIC_TEMPLATE, standard src/tmp/PPT TEMPLATE SEMIC 2026 .pptx (repo-rota).
semic_background() {
    local media="$1" tpl out here
    here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    [ "${SEMIC_BACKGROUND:-}" = "template" ] || return 0
    tpl="${SEMIC_TEMPLATE:-$here/../../../../../src/tmp/PPT TEMPLATE SEMIC 2026 .pptx}"
    out="$(mktemp "${TMPDIR:-/tmp}/semic-cells.XXXXXX")" || return 0
    if python3 "$here/semic-image.py" "$tpl" "$media" "$COLS" "$ROWS" "$out" 2> "$out.err"; then
        rm -f "$out.err"
        printf '%s' "$out"
    else
        printf '%s(bakgrunn frå malen utilgjengeleg, brukar teikna: %s)%s\n' "$CLR_DBG" "$(tr '\n' ' ' < "$out.err")" "$CLR_RST" >&2
        rm -f "$out" "$out.err"
    fi
    return 0
}

# px3_lines TEKST — skriv ut TEKST i same 3x5-pikselfont som tittelslida (3 rader høg,
# store bokstavar), éi linje per rad, utan farge. For slides som ikkje er rutenettgrafikk.
px3_lines() {
    local here
    here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    awk -v W=120 -v H=3 -v TEXT="$1" -f "$here/semic-canvas.awk" -f "$here/semic-px3.awk" </dev/null
}

# px3_cols TEKST — breidda (kolonnar) TEKST får i 3x5-fonten, til å sjekke at han passar.
px3_cols() {
    local here
    here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    awk -v W=120 -v H=3 -v MODE=width -v TEXT="$1" -f "$here/semic-canvas.awk" -f "$here/semic-px3.awk" </dev/null
}
