#!/usr/bin/env bash
# Slide: «Thank you» i SEMIC 2026-malen (side 10), teikna som terminalgrafikk:
# svake greiner med blå noder frå høgre kant, toppen og botnen, SEMIC-logoen øvst
# til venstre, og «THANK YOU» med ei kontaktlinje midt på.
#
# Bruk: [TITLE="Thank you"] [CONTACTS="contacts"] [QRFILE=<matrise>] [QRFILE2=<matrise>] bash slides/semic-thanks.sh [BREIDD HØGDE]
#   CONTACTS er linja under tittelen (malen har plasshaldaren «contacts»).
#   QRFILE er ei tekstmatrise (0/1) frå make-qr.sh; standard slides/linkedin-qr.txt.
#   QRFILE2 (standard slides/github-qr.txt) står på same rader. Med begge står LinkedIn
#   til venstre og den andre til høgre; med berre éin står han midt på. Tom streng
#   (QRFILE= / QRFILE2=) = utan den koden.
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=slide-lib.sh
source "$here/slide-lib.sh"

TITLE="${TITLE:-Thank you}"
CONTACTS="${CONTACTS-contacts}"
QRFILE="${QRFILE-$here/linkedin-qr.txt}"
QRFILE2="${QRFILE2-$here/github-qr.txt}"
semic_canvas_size "$@"

if [ "$COLS" -lt 70 ] || [ "$ROWS" -lt 22 ]; then
    echo ""
    echo "${CLR_BOLD}${CLR_STEP}${TITLE}${CLR_RST}"
    [ -n "$CONTACTS" ] && echo "$CONTACTS"
    echo ""
    exit 0
fi

awk -v W="$COLS" -v H="$ROWS" -v TITLE="$TITLE" -v CONTACTS="$CONTACTS" -v QRFILE="$QRFILE" -v QRFILE2="$QRFILE2" -f "$here/semic-canvas.awk" -f "$here/semic-thanks.awk" </dev/null
