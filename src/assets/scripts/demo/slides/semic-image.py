#!/usr/bin/env python3
"""Gjer eit bilete frå SEMIC-malen (.pptx) om til ei terminal-cellefil (halvblokk).

Bruk: semic-image.py <pptx> <ppt/media/imageN.jpg> <breidd> <høgd> <utfil>

Fila har ein rad per terminalrad, med BREIDD celler skilde av mellomrom. Kvar celle
er "<fg>/<bg>" som SGR-parametrar (t.d. "38;5;17/48;5;16"): øvre piksel = fg,
nedre piksel = bg, teikna som ▀. 24-bit farge når COLORTERM er truecolor/24bit,
elles næraste 256-farge. Berre stdlib; biletet vert skalert og avkoda med macOS
`sips` (JPEG -> BMP). Avsluttar med exit-kode != 0 og melding på stderr viss noko
manglar, slik at kallaren kan falle tilbake til teikna artwork.
"""
import os
import shutil
import struct
import subprocess
import sys
import tempfile
import zipfile


def fail(msg):
    print(f"semic-image: {msg}", file=sys.stderr)
    sys.exit(1)


def _dist(a, b):
    """Redmean-vekta fargeavstand (nærare det auget ser enn rein euklidsk)."""
    rm = (a[0] + b[0]) / 2
    dr, dg, db = a[0] - b[0], a[1] - b[1], a[2] - b[2]
    return (2 + rm / 256) * dr * dr + 4 * dg * dg + (2 + (255 - rm) / 256) * db * db


_PAL = None


def nearest256(r, g, b):
    global _PAL
    if _PAL is None:
        levels = [0, 95, 135, 175, 215, 255]
        _PAL = [(16 + 36 * i + 6 * j + k, (levels[i], levels[j], levels[k]))
                for i in range(6) for j in range(6) for k in range(6)]
        _PAL += [(232 + g_, (8 + 10 * g_,) * 3) for g_ in range(24)]
    c = (r, g, b)

    def cost(e):
        q = e[1]
        # redmean-avstand + straff for å halde forholdet mellom kanalane (nyansen):
        # utan dette vert mørke blåtonar til grøn-blå (t.d. (50,60,200) -> (0,95,215)).
        hue = ((q[0] - q[1]) - (r - g)) ** 2 + ((q[2] - q[1]) - (b - g)) ** 2 + ((q[2] - q[0]) - (b - r)) ** 2
        return _dist(c, q) + 1.5 * hue

    return min(_PAL, key=cost)[0]


def palette_rgb(n):
    if n >= 232:
        v = 8 + 10 * (n - 232)
        return (v, v, v)
    n -= 16
    levels = [0, 95, 135, 175, 215, 255]
    return (levels[n // 36], levels[(n // 6) % 6], levels[n % 6])


def dither256(px, w, h):
    """Floyd-Steinberg (serpentin) mot 256-fargepaletten. Gir indeksar per piksel.
    Utan dette vert jamne blå overgangar til grove flater med feil nyanse."""
    cur = [[list(map(float, p)) for p in row] for row in px]
    out = [[0] * w for _ in range(h)]
    for y in range(h):
        xs = range(w) if y % 2 == 0 else range(w - 1, -1, -1)
        dirn = 1 if y % 2 == 0 else -1
        for x in xs:
            c = [max(0, min(255, v)) for v in cur[y][x]]
            idx = nearest256(*[int(round(v)) for v in c])
            out[y][x] = idx
            q = palette_rgb(idx)
            err = [c[i] - q[i] for i in range(3)]
            for dx, dy, wt in ((dirn, 0, 7 / 16), (-dirn, 1, 3 / 16), (0, 1, 5 / 16), (dirn, 1, 1 / 16)):
                nx, ny = x + dx, y + dy
                if 0 <= nx < w and 0 <= ny < h:
                    for i in range(3):
                        cur[ny][nx][i] += err[i] * wt
    return out


def read_bmp(path):
    with open(path, "rb") as f:
        d = f.read()
    if d[:2] != b"BM":
        fail("sips ga ikkje BMP")
    off = struct.unpack_from("<I", d, 10)[0]
    w, h = struct.unpack_from("<ii", d, 18)
    bpp = struct.unpack_from("<H", d, 28)[0]
    if bpp not in (24, 32):
        fail(f"uventa BMP-djupn {bpp}")
    bytespp = bpp // 8
    stride = (w * bytespp + 3) & ~3
    top_down = h < 0
    h = abs(h)
    px = []
    for row in range(h):
        src = row if top_down else h - 1 - row
        base = off + src * stride
        line = []
        for x in range(w):
            b, g, r = d[base + x * bytespp], d[base + x * bytespp + 1], d[base + x * bytespp + 2]
            line.append((r, g, b))
        px.append(line)
    return w, h, px


def main():
    if len(sys.argv) != 6:
        fail("bruk: semic-image.py <pptx> <media> <breidd> <høgd> <utfil>")
    pptx, member, width, height, out = sys.argv[1:]
    width, height = int(width), int(height)
    if not os.path.isfile(pptx):
        fail(f"fann ikkje malen: {pptx}")
    if not shutil.which("sips"):
        fail("sips (macOS) manglar")
    truecolor = os.environ.get("COLORTERM", "") in ("truecolor", "24bit")
    with tempfile.TemporaryDirectory() as tmp:
        jpg = os.path.join(tmp, "in.jpg")
        bmp = os.path.join(tmp, "out.bmp")
        try:
            with zipfile.ZipFile(pptx) as z, open(jpg, "wb") as f:
                f.write(z.read(member))
        except (KeyError, zipfile.BadZipFile) as e:
            fail(f"kunne ikkje lese {member} frå {pptx}: {e}")
        r = subprocess.run(
            ["sips", "-z", str(height * 2), str(width), "-s", "format", "bmp", jpg, "--out", bmp],
            capture_output=True, text=True)
        if r.returncode != 0 or not os.path.isfile(bmp):
            fail(f"sips feila: {r.stderr.strip()}")
        w, h, px = read_bmp(bmp)
    if w != width or h != height * 2:
        fail(f"uventa storleik {w}x{h}")

    idx = None if truecolor else [[nearest256(*p) for p in row] for row in px]

    def sgr(kind, c, x, y):
        if truecolor:
            return f"{kind};2;{c[0]};{c[1]};{c[2]}"
        return f"{kind};5;{idx[y][x]}"

    with open(out, "w") as f:
        for y in range(height):
            f.write(" ".join(sgr("38", px[2 * y][x], x, 2 * y) + "/" + sgr("48", px[2 * y + 1][x], x, 2 * y + 1) for x in range(width)) + "\n")


if __name__ == "__main__":
    main()
