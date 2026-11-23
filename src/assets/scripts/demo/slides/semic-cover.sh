#!/usr/bin/env bash
# Slide: forside i SEMIC 2026-malen (side 1), teikna som terminalgrafikk:
# mørk bakgrunn, to lysande nettverkskuler (blå prikkar, rosa linjer), midt på
# «SEMIC 20/26 conference» i blokkbokstavar med fargegradient og tagline.
# 256-fargar (ikkje 24-bit), så det fungerer òg i Terminal.app.
#
# Bruk: [SIZE=small|large] bash slides/semic-cover.sh [BREIDD HØGDE]
#   SIZE=small (standard): halvblokk-piksel, ca. 19 % av breidda (som i malen)
#   SIZE=large: heilblokk, dobbel breidd og 5 rader høge bokstavar
# (standard terminalstorleik)
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=slide-lib.sh
source "$here/slide-lib.sh"

semic_canvas_size "$@"

if [ "$COLS" -lt 70 ] || [ "$ROWS" -lt 22 ]; then
    # For lita terminal: enkel tekstversjon.
    echo ""
    echo "${CLR_BOLD}${CLR_STEP}SEMIC 2026 conference${CLR_RST}"
    echo "Interoperability by design for a competitive Europe"
    echo ""
    exit 0
fi

IMGFILE="$(semic_background ppt/media/image1.jpg)"
awk -v W="$COLS" -v H="$ROWS" -v SIZE="${SIZE:-small}" -v IMGFILE="$IMGFILE" -f "$here/semic-canvas.awk" -f "$here/semic-cover.awk" </dev/null
rc=$?
[ -n "$IMGFILE" ] && rm -f "$IMGFILE"
exit $rc
