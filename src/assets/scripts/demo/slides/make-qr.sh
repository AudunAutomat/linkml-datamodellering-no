#!/usr/bin/env bash
# Lagar QR-kode for ein URL som GIF (til visning) og som tekstmatrise (0/1, til
# terminalslida). Køyrer i ein kortvarig python-pytest-container (pip install
# qrcode[pil] i containeren, krev nett) — ingenting vert installert lokalt, og URL-en
# går ikkje til nokon QR-teneste.
#
# Bruk: bash slides/make-qr.sh <URL> [utfil-utan-etternamn]   (standard: slides/linkedin-qr)
set -euo pipefail

url="${1:?bruk: make-qr.sh <URL> [utfil-utan-etternamn]}"
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
base="${2:-$here/linkedin-qr}"
outdir="$(cd "$(dirname "$base")" && pwd)"
name="$(basename "$base")"

podman run --rm -v "$outdir:/out" -e URL="$url" -e NAME="$name" localhost/python-pytest:latest sh -c '
pip install --quiet --disable-pip-version-check --root-user-action=ignore --target /tmp/qr "qrcode[pil]" >/dev/null
PYTHONPATH=/tmp/qr python3 - <<PY
import os, qrcode
qr = qrcode.QRCode(version=None, error_correction=qrcode.constants.ERROR_CORRECT_M, box_size=10, border=4)
qr.add_data(os.environ["URL"]); qr.make(fit=True)
name = os.environ["NAME"]
qr.make_image(fill_color="black", back_color="white").convert("P").save(f"/out/{name}.gif")
with open(f"/out/{name}.txt", "w") as f:
    for row in qr.get_matrix()[4:-4]:           # utan rammen (border)
        f.write("".join("1" if c else "0" for c in row[4:-4]) + "\n")
print(f"{name}: {qr.modules_count}x{qr.modules_count} moduler")
PY' < /dev/null
