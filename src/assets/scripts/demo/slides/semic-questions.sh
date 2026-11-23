#!/usr/bin/env bash
# Slide: «Questions?» i SEMIC 2026-malen (side 8), teikna som terminalgrafikk:
# mørk bakgrunn med blå glød og bølgje, rosa tre med blå prikkar til venstre,
# SEMIC-logoen øvst til venstre og teksten midt i bildet.
#
# Bruk: [TITLE="Questions?"] bash slides/semic-questions.sh [BREIDD HØGDE]
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=slide-lib.sh
source "$here/slide-lib.sh"

TITLE="${TITLE:-Questions?}"
semic_canvas_size "$@"

if [ "$COLS" -lt 70 ] || [ "$ROWS" -lt 22 ]; then
    echo ""
    echo "${CLR_BOLD}${CLR_STEP}${TITLE}${CLR_RST}"
    echo ""
    exit 0
fi

IMGFILE="$(semic_background ppt/media/image4.jpg)"
awk -v W="$COLS" -v H="$ROWS" -v TITLE="$TITLE" -v IMGFILE="$IMGFILE" -f "$here/semic-canvas.awk" -f "$here/semic-questions.awk" </dev/null
rc=$?
[ -n "$IMGFILE" ] && rm -f "$IMGFILE"
exit $rc
