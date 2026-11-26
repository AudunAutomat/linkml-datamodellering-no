#!/usr/bin/env bash
# Slide: tittelslide i SEMIC 2026-malen (side 2), teikna som terminalgrafikk:
# same mørke bakgrunn med nettverkskuler og bobler som malen, den lille
# SEMIC-logoen øvst til høgre, og foredragstittelen midt i bildet.
#
# Bruk: [TITLE="Tittel"] [SUBTITLE="..."] [BYLINE="By: ..."] bash slides/semic-title.sh [BREIDD HØGDE]
#   TITLE (standard "The right tool is more than half the job") vert vist med store bokstavar og
#   brote på ordgrense viss han er for brei. SUBTITLE (standard «Modeling once with
#   LinkML», tom streng = ingen) og BYLINE (standard «By: Audun Vindenes Egge», tom
#   streng = ingen) står som vanleg tekst under tittelen, i den rekkjefølgja.
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=slide-lib.sh
source "$here/slide-lib.sh"

TITLE="${TITLE:-The right tool is more than half the job}"
SUBTITLE="${SUBTITLE-Modeling once with LinkML}"
BYLINE="${BYLINE-By: Audun Vindenes Egge}"
semic_canvas_size "$@"

if [ "$COLS" -lt 70 ] || [ "$ROWS" -lt 22 ]; then
    echo ""
    echo "${CLR_BOLD}${CLR_STEP}${TITLE}${CLR_RST}"
    echo ""
    exit 0
fi

IMGFILE="$(semic_background ppt/media/image2.jpg)"
awk -v W="$COLS" -v H="$ROWS" -v TITLE="$TITLE" -v SUBTITLE="$SUBTITLE" -v BYLINE="$BYLINE" -v IMGFILE="$IMGFILE" -f "$here/semic-canvas.awk" -f "$here/semic-title.awk" </dev/null
rc=$?
[ -n "$IMGFILE" ] && rm -f "$IMGFILE"
exit $rc
