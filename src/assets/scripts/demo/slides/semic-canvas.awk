# Delte funksjonar for SEMIC-slidane (terminalgrafikk). Brukt saman med eit
# slide-spesifikt program: awk -f semic-canvas.awk -f <slide>.awk
# Krev -v W=<kolonnar> -v H=<rader>. 256-fargar; celleformat 1:2 (x-radius = 2 * y-radius).

function init_canvas(   x, y) {
    srand(7)
    if (NC1 == "") NC1 = 63          # nodefargar (256-farge), kan overstyrast av slida
    if (NC2 == "") NC2 = 62
    BG = 16
    for (y = 0; y < H; y++) for (x = 0; x < W; x++) { ch[y, x] = " "; fg[y, x] = 7; bg[y, x] = BG }
}

function init_fonts() {
    pat["S"] = "01111 10000 01110 00001 11110"
    pat["E"] = "11111 10000 11110 10000 11111"
    pat["M"] = "10001 11011 10101 10001 10001"
    pat["I"] = "11111 00100 00100 00100 11111"
    pat["C"] = "01111 10000 10000 10000 01111"
    pat["2"] = "01110 10001 00110 01000 11111"
    pat["0"] = "01110 10001 10001 10001 01110"
    pat["6"] = "01111 10000 11110 10001 01110"

    # smalare font (4 piksel breie bokstavar) for SIZE=small
    pat4["S"] = "0111 1000 0110 0001 1110"
    pat4["E"] = "1111 1000 1110 1000 1111"
    pat4["M"] = "1001 1111 1111 1001 1001"
    pat4["I"] = "111 010 010 010 111"
    pat4["C"] = "0111 1000 1000 1000 0111"
    pat4["2"] = "0110 1001 0010 0100 1111"
    pat4["0"] = "0110 1001 1001 1001 0110"
    pat4["6"] = "0111 1000 1110 1001 0110"

}

function flush(   y, x, pf, pb, line, f, b) {
    printf "\033[2J\033[H"
    for (y = 0; y < H; y++) {
        pf = ""; pb = ""; line = ""
        for (x = 0; x < W; x++) {
            f = ((y, x) in fgs && fgs[y, x] != "") ? fgs[y, x] : "38;5;" fg[y, x]
            b = ((y, x) in bgs && bgs[y, x] != "") ? bgs[y, x] : "48;5;" bg[y, x]
            if (f != pf) { line = line "\033[" f "m"; pf = f }
            if (b != pb) { line = line "\033[" b "m"; pb = b }
            line = line ch[y, x]
        }
        printf "%s\033[0m\n", line
    }
}

function draw_title(y0, x0, px, gap, lw, side, big,   gx, i, dx, ls, lc, a, r, cx, dy) {
    split("38 79 114 185 214", lc, " ")
    split("S E M I C", ls, " ")
    gx = x0
    for (i = 1; i <= 5; i++) {
        glyph(ls[i], y0, gx, lc[i], px, big)
        gx += ((!big) ? gwid(ls[i]) : GW) * px + gap
    }
    dx = x0 + lw + side
    dy = big ? 6 : 4
    glyph("2", y0, dx, 250, px, big); glyph("0", y0, dx + GW * px + gap, 250, px, big)
    glyph("2", y0 + dy, dx, 250, px, big); glyph("6", y0 + dy, dx + GW * px + gap, 250, px, big)
    if (big && px == 2) {
        a[0] = "              __                         "
        a[1] = " __ ___ _ _  / _|___ _ _ ___ _ _  __ ___ "
        a[2] = "/ _/ _ \\ \x27 \\|  _/ -_) \x27_/ -_) \x27 \\/ _/ -_)"
        a[3] = "\\__\\___/_||_|_| \\___|_| \\___|_||_\\__\\___|"
        cx = x0 + int((lw - 41) / 2)
        for (r = 0; r < 4; r++) text(y0 + 6 + r, cx, a[r], 231)
    } else if (big) {
        text(y0 + 7, x0, "c o n f e r e n c e", 231)
    } else {
        spread(y0 + dy, x0 + int((lw - 19) / 2), "conference", 2, 231)    # 1 mellomrom = 19 kolonnar, sentrert under SEMIC
    }
}
function gwid(g) { return (g == "M") ? 5 : (g == "I") ? 3 : 4 }
function put(y, x, c, f) {
    if (y < 0 || y >= H || x < 0 || x >= W) return
    ch[y, x] = c; fg[y, x] = f; fgs[y, x] = ""
}
function text(y, x, s, f,   i, c) {
    for (i = 1; i <= length(s); i++) { c = substr(s, i, 1); if (c != " ") put(y, x + i - 1, c, f) }
}
# spread(y, x, tekst, stigning, farge): bokstavane med fast stigning (jamn avstand)
function spread(y, x, s, pitch, f,   i) {
    for (i = 0; i < length(s); i++) put(y, x + i * pitch, substr(s, i + 1, 1), f)
}
# clear(y1, x1, y2, x2 [, mode]): tøm ein boks. Utan bilete: tom celle på BG. Med bilete
# (IMG): fyll boksen frå cellene like utanfor, mode "v" (standard) = mellom cella over
# og under midt i boksen (loddrett), mode "h" = mellom cella til venstre og høgre på
# same rad (vassrett). Interpolerer ved 24-bit farge, elles næraste kantcelle.
function clear(y1, x1, y2, x2, mode,   y, x, xm, ya, yb, t, sf, sb, fa, fb, ba, bb) {
    if (mode == "") mode = "v"
    xm = int((x1 + x2) / 2)
    ya = y1 - 1; if (ya < 0) ya = y1
    yb = y2 + 1; if (yb >= H) yb = y2
    for (y = y1; y <= y2; y++) {
        if (y < 0 || y >= H) continue
        if (IMG) {
            if (mode == "h") {
                xa = (x1 - 1 >= 0) ? x1 - 1 : x1; xb = (x2 + 1 < W) ? x2 + 1 : x2
                fa = fgs[y, xa]; ba = bgs[y, xa]; fb = fgs[y, xb]; bb = bgs[y, xb]
            } else {
                t = (y2 > y1) ? (y - y1) / (y2 - y1) : 0
                fa = fgs[ya, xm]; ba = bgs[ya, xm]; fb = fgs[yb, xm]; bb = bgs[yb, xm]
            }
        }
        for (x = x1; x <= x2; x++) {
            if (x < 0 || x >= W) continue
            if (IMG) {
                if (mode == "h") t = (x2 > x1) ? (x - x1) / (x2 - x1) : 0
                ch[y, x] = "\xe2\x96\x80"; fgs[y, x] = lerp_sgr(fa, fb, t); bgs[y, x] = lerp_sgr(ba, bb, t)
            } else { ch[y, x] = " "; bg[y, x] = BG }
        }
    }
}

# lerp_sgr(a, b, t): blandar to SGR-fargar ("38;2;r;g;b"), elles næraste (t < 0,5 gir a).
function lerp_sgr(a, b, t,   pa, pb, na, nb) {
    na = split(a, pa, ";"); nb = split(b, pb, ";")
    if (na == 5 && nb == 5 && pa[2] == "2" && pb[2] == "2")
        return pa[1] ";2;" int(pa[3] + (pb[3] - pa[3]) * t + 0.5) ";" int(pa[4] + (pb[4] - pa[4]) * t + 0.5) ";" int(pa[5] + (pb[5] - pa[5]) * t + 0.5)
    return (t < 0.5) ? a : b
}

# load_image(fil): les ei cellefil frå semic-image.py (ein rad per terminalrad, celler
# "<fg-SGR>/<bg-SGR>" skilde av mellomrom). Set IMG = 1 viss fila vart lesen.
function load_image(file,   y, x, n, cells, parts, line) {
    y = 0
    while ((getline line < file) > 0 && y < H) {
        n = split(line, cells, " ")
        for (x = 1; x <= n && x <= W; x++) {
            split(cells[x], parts, "/")
            ch[y, x - 1] = "\xe2\x96\x80"; fgs[y, x - 1] = parts[1]; bgs[y, x - 1] = parts[2]
        }
        y++
    }
    close(file)
    IMG = (y >= H) ? 1 : 0
    return IMG
}
function glyph(g, y, x, f, p, big,   wd, rows, r, c, k, t, b, ch2) {
    split(pat[g], rows, " ")
    if (big) {
        for (r = 1; r <= 5; r++) for (c = 1; c <= 5; c++)
            if (substr(rows[r], c, 1) == "1") for (k = 0; k < p; k++) put(y + r - 1, x + (c - 1) * p + k, "\xe2\x96\x88", f)
        return
    }
    # halvblokk: to pikselrader per terminalrad (▀ ▄ █), kvar piksel 1 kolonne
    if (g == "M") split(pat[g], rows, " "); else split(pat4[g], rows, " ")
    wd = length(rows[1])
    for (r = 1; r <= 5; r += 2) for (c = 1; c <= wd; c++) {
        t = (substr(rows[r], c, 1) == "1")
        b = (r + 1 <= 5) ? (substr(rows[r + 1], c, 1) == "1") : 0
        if (t && b) ch2 = "\xe2\x96\x88"; else if (t) ch2 = "\xe2\x96\x80"; else if (b) ch2 = "\xe2\x96\x84"; else ch2 = ""
        if (ch2 != "") put(y + int((r - 1) / 2), x + c - 1, ch2, f)
    }
}
function bg_at(y, x, v) { if (y >= 0 && y < H && x >= 0 && x < W && bg[y, x] < v) bg[y, x] = v }
# sphere(cx, cy, rx, ry, pinkBottom): fylt kule med glød i kanten
function sphere(cx, cy, rx, ry, topleft,   y, x, u, v, d, r, lean) {
    for (y = 0; y < H; y++) for (x = 0; x < W; x++) {
        u = (x - cx) / rx; v = (y - cy) / ry; d = u * u + v * v
        if (d > 1.18) continue
        if (d > 1.0) { bg[y, x] = 17; continue }
        if (d > 0.90) bg[y, x] = 19; else if (d > 0.78) bg[y, x] = 18; else bg[y, x] = 17 - 1
        r = rand()
        lean = (topleft ? v : -v)          # linjer tettast mot kanten av kula
        if (r < 0.10) { ch[y, x] = "\xe2\x80\xa2"; fg[y, x] = (rand() < 0.5) ? 63 : 69 }
        else if (r < 0.10 + 0.18 * (0.4 + d)) {
            if (rand() < 0.5) ch[y, x] = "|"; else ch[y, x] = (rand() < 0.5) ? "/" : "\\"
            fg[y, x] = (rand() < 0.6) ? 175 : 139
        }
        else if (r < 0.40) { ch[y, x] = "."; fg[y, x] = 61 }
    }
}
function bubble(cx, cy, rx, ry,   y, x, u, v, d, r) {
    for (y = 0; y < H; y++) for (x = 0; x < W; x++) {
        u = (x - cx) / rx; v = (y - cy) / ry; d = u * u + v * v
        if (d > 1.0) continue
        bg[y, x] = (d > 0.7) ? 17 : 16
        r = rand()
        if (d <= 0.7 && r < 0.12) { ch[y, x] = "\xe2\x80\xa2"; fg[y, x] = 60 }
    }
}

# --- 3x5 piksel-font (store bokstavar, tal, litt teiknsetjing) -----------------
# Teikna med halvblokk (3 terminalrader høge). M og W er 5 brei, N 4 brei,
# punktum/kolon/utropsteikn 1 brei.
function init_font3() {
    p3["A"] = "010 101 111 101 101"; p3["B"] = "110 101 110 101 110"
    p3["C"] = "011 100 100 100 011"; p3["D"] = "110 101 101 101 110"
    p3["E"] = "111 100 110 100 111"; p3["F"] = "111 100 110 100 100"
    p3["G"] = "011 100 101 101 011"; p3["H"] = "101 101 111 101 101"
    p3["I"] = "111 010 010 010 111"; p3["J"] = "001 001 001 101 010"
    p3["K"] = "101 101 110 101 101"; p3["L"] = "100 100 100 100 111"
    p3["M"] = "10001 11011 10101 10001 10001"
    p3["N"] = "1001 1101 1011 1001 1001"
    p3["O"] = "010 101 101 101 010"; p3["P"] = "110 101 110 100 100"
    p3["Q"] = "010 101 101 111 011"; p3["R"] = "110 101 110 101 101"
    p3["S"] = "011 100 010 001 110"; p3["T"] = "111 010 010 010 010"
    p3["U"] = "101 101 101 101 111"; p3["V"] = "101 101 101 101 010"
    p3["W"] = "10001 10001 10101 11011 10001"
    p3["X"] = "101 101 010 101 101"; p3["Y"] = "101 101 010 010 010"
    p3["Z"] = "111 001 010 100 111"
    p3["0"] = "111 101 101 101 111"; p3["1"] = "010 110 010 010 111"
    p3["2"] = "110 001 010 100 111"; p3["3"] = "110 001 010 001 110"
    p3["4"] = "101 101 111 001 001"; p3["5"] = "111 100 110 001 110"
    p3["6"] = "011 100 111 101 111"; p3["7"] = "111 001 010 010 010"
    p3["8"] = "111 101 111 101 111"; p3["9"] = "111 101 111 001 110"
    p3["."] = "0 0 0 0 1"; p3[":"] = "0 1 0 1 0"; p3["!"] = "1 1 1 0 1"
    p3["-"] = "000 000 111 000 000"; p3["?"] = "110 001 010 000 010"
    p3["\x27"] = "1 1 0 0 0"; p3[","] = "0 0 0 1 1"
}

# Breidd i kolonnar for tekst S i 3x5-fonten (1 kolonne mellom bokstavane, mellomrom = 2).
function px3_width(s,   i, c, w, rows) {
    w = 0
    for (i = 1; i <= length(s); i++) {
        c = substr(s, i, 1)
        if (c == " ") w += 2
        else if (c in p3) { split(p3[c], rows, " "); w += length(rows[1]) + 1 }
        else w += 4
    }
    return (w > 0) ? w - 1 : 0
}

# Teiknar S med øvre venstre hjørne i (y, x). Ukjende teikn vert hoppa over.
function px3_text(y, x, s, f,   i, c, rows, wd, r, c2, t, b, ch2) {
    for (i = 1; i <= length(s); i++) {
        c = substr(s, i, 1)
        if (c == " ") { x += 2; continue }
        if (!(c in p3)) { x += 4; continue }
        split(p3[c], rows, " ")
        wd = length(rows[1])
        for (r = 1; r <= 5; r += 2) for (c2 = 1; c2 <= wd; c2++) {
            t = (substr(rows[r], c2, 1) == "1")
            b = (r + 1 <= 5) ? (substr(rows[r + 1], c2, 1) == "1") : 0
            if (t && b) ch2 = "\xe2\x96\x88"; else if (t) ch2 = "\xe2\x96\x80"; else if (b) ch2 = "\xe2\x96\x84"; else ch2 = ""
            if (ch2 != "") put(y + int((r - 1) / 2), x + c2 - 1, ch2, f)
        }
        x += wd + 1
    }
}

# --- pikselbuffer (halv celle-oppløysing): 8-bit teikning av greiner og noder ---------
# Kvar piksel er 8x8 skjermpikslar (ein halv terminalcelle i høgda). pb[x, y] held
# fargeindeksen (256-farge) for piksel (x, y), x i 0..W-1, y i 0..2H-1.
function pb_set(x, y, c) {
    x = int(x); y = int(y)
    if (x < 0 || x >= W || y < 0 || y >= 2 * H) return
    pb[x, y] = c
}
# Fylt "sirkel" med radius r (piksel), 8-bit-form (r=1: pluss, r=2: 13 piksel, r=3: 29 piksel).
function pb_disc(cx, cy, r, c,   dx, dy) {
    for (dy = -r; dy <= r; dy++) for (dx = -r; dx <= r; dx++)
        if (dx * dx + dy * dy <= r * r + 0.5) pb_set(cx + dx, cy + dy, c)
}
# Legg pikselbufferet inn i cellene: to piksel per celle (▀ ▄ █). Ubrukte piksel let
# bakgrunnen (bg) skine gjennom.
function pb_flush(   x, y, t, b) {
    for (y = 0; y < H; y++) for (x = 0; x < W; x++) {
        t = ((x, 2 * y) in pb) ? pb[x, 2 * y] : ""
        b = ((x, 2 * y + 1) in pb) ? pb[x, 2 * y + 1] : ""
        if (t == "" && b == "") continue
        fgs[y, x] = ""
        if (t != "" && b != "") {
            if (t == b) { ch[y, x] = "\xe2\x96\x88"; fg[y, x] = t }
            else { ch[y, x] = "\xe2\x96\x80"; fg[y, x] = t; bg[y, x] = b }
        } else if (t != "") { ch[y, x] = "\xe2\x96\x80"; fg[y, x] = t }
        else { ch[y, x] = "\xe2\x96\x84"; fg[y, x] = b }
    }
}

# Node: pikselsirkel i varierande storleik (NODEMAX = største radius, standard 2). Hoppar
# over viss han ville overlappe ein eksisterande node (minst to piksel luft).
function pnode(x, y,   r, i, col) {
    r = (rand() < 0.10) ? 0 : (rand() < 0.65) ? 1 : 2      # små noder: radius 0 (1 piksel), 1 (pluss) eller 2
    if (NODEBIG != "" && rand() < NODEBIG) r = 3
    for (i = 1; i <= nn; i++)
        if ((x - nx[i]) ^ 2 + (y - ny[i]) ^ 2 < (r + nr[i] + 2) ^ 2) return
    nn++; nx[nn] = x; ny[nn] = y; nr[nn] = r
    col = (rand() < 0.5) ? NC1 : NC2
    pb_disc(x, y, r, col)
}

# edge_char(x, y, vinkel, farge): tynn linje som teikn (| - / \\) i cella som pikselet ligg i.
# Pikselkoordinatane er kvadratiske (ein piksel = halv celle i høgda), så retninga
# (cos, sin) kan brukast direkte; fungerer for alle vinklar.
function edge_char(x, y, a, c,   cx, cy, dx, dy, r, k) {
    cx = int(x); cy = int(y / 2)
    if (cx < 0 || cx >= W || cy < 0 || cy >= H) return
    dx = cos(a); dy = sin(a)
    if (dx < 0) dx = -dx * ((dy < 0) ? 1 : 1)
    r = (dx == 0) ? 99 : ((dy < 0) ? -dy : dy) / dx
    if (r < 0.5) k = "-"
    else if (r > 2.2) k = "|"
    else k = ((cos(a) * dy) < 0) ? "/" : "\\"
    ch[cy, cx] = k; fg[cy, cx] = c; fgs[cy, cx] = ""
}
