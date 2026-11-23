# Avslutningsslide (slide 10): se semic-thanks.sh. Brukar funksjonar frå semic-canvas.awk.
# Krev -v TITLE=<tekst> og -v CONTACTS=<tekst>.
BEGIN {
    init_canvas()
    init_fonts()
    init_font3()
    NC1 = 18; NC2 = 17; NODEBIG = 0.08          # svake blå noder, som i malen
    BG = 16

    # tekstboksane, i piksel (1 piksel = 1 kolonne x 1/2 rad), så greinene held seg unna
    ttxt = toupper(TITLE)
    tw = px3_width(ttxt)
    ttx = int((W - tw) / 2)
    tty = int(0.35 * H - 1.5)                   # tittelrad
    cty = int(0.47 * H)                         # kontaktrad
    cw = length(CONTACTS)
    cx = int((W - cw) / 2)
    BX1 = (ttx < cx ? ttx : cx) - 6             # forbode boks (x1,y1)-(x2,y2) i piksel
    BX2 = ((ttx + tw) > (cx + cw) ? (ttx + tw) : (cx + cw)) + 6
    BY1 = 2 * tty - 6
    BY2 = 2 * cty + 8

    # QR-kode (matrise frå QRFILE: ein rad per linje, 0/1). Under kontaktlinja midt på viss det
    # er plass, elles nede til venstre. Teikna med halvblokk: 1 modul = 1 piksel, kvit ramme.
    qn = (QRFILE != "") ? load_qr(QRFILE, qm) : 0
    if (qn > 0) {
        qz = 2; qp = qn + 2 * qz; qrows = int((qp + 1) / 2)
        qy = cty + 3
        twoq = (QRFILE2 != "")                                       # med GitHub-kode: LinkedIn til venstre, GitHub til høgre
        if (qy + qrows + 1 > H) qy = H - qrows - 1                  # for lågt: nedst i bildet
        qx = twoq ? int(0.04 * W) : int((W - qp) / 2)               # ei kode: midtstilt
        if (!twoq && qx == int((W - qp) / 2) && qy == cty + 3) {
            if (qx - 4 < BX1) BX1 = qx - 4
            if (qx + qp + 4 > BX2) BX2 = qx + qp + 4
            BY2 = 2 * (qy + qrows) + 4
        }
        # GitHub-kode på same rader, heilt til høgre i bildet (viss det er plass til han)
        qn2 = (QRFILE2 != "") ? load_qr(QRFILE2, qm2) : 0
        gx = 0
        if (qn2 > 0) {
            gx = W - int(0.04 * W) - (qn2 + 2 * qz)
            if (gx < qx + qp + 4) gx = 0                                  # ikkje plass: hopp over
            else { FX1 = 2 * 0 + gx - 3; FX2 = gx + qn2 + 2 * qz + 3; FY1 = 2 * qy - 4; FY2 = 2 * (qy + qrows) + 4 }
            if (gx > 0) {                                                 # tekst mellom kodane: plass og forbode boks for greinene
                l1 = "<- LinkedIn"; l2 = "git repo ->"
                mid = int((qx + qp + gx) / 2)                             # midten mellom kodane
                mx1 = mid - int(length(l1) / 2); mx2 = mid - int(length(l2) / 2)
                my1 = qy + int(qrows / 2) - 2; my2 = my1 + 3
                TX1 = mid - 9; TX2 = mid + 9; TY1 = 2 * my1 - 4; TY2 = 2 * my2 + 6
            }
        }
    }

    # --- svake greiner frå høgre kant, toppen og botnen (pikselbuffer + tynne teikn) ---
    XMIN = 0.40 * W                             # held seg til høgre for midten
    for (k = 0; k < 3; k++)                     # ovanfrå, ned og mot venstre
        dbranch(0.62 * W + rand() * 0.34 * W, 0, 1.15 + rand() * 0.6, 0, 110 + int(rand() * 60), 1.9)
    for (k = 0; k < 2; k++)                     # frå høgre kant, ned og mot venstre
        dbranch(W - 1, rand() * 0.35 * 2 * H, 2.3 + rand() * 0.7, 0, 120 + int(rand() * 60), 2.5)
    for (k = 0; k < 3; k++)                     # frå botnen, opp og mot høgre
        dbranch(0.45 * W + rand() * 0.5 * W, 2 * H - 1, -(0.6 + rand() * 0.9), 0, 110 + int(rand() * 60), -1.2)
    pb_flush()

    # --- logo øvst til venstre ---------------------------------------------------
    GW = 4; px = 1; gap = 1
    lw = 20 + 4 * gap; dw = 2 * GW + gap; side = 2; total = lw + side + dw
    lx = int(0.04 * W)
    ly = int(0.07 * H)
    clear(ly - 1, lx - 2, ly + 7, lx + total + 2)
    draw_title(ly, lx, px, gap, lw, side, 0)

    # --- tekst midt på ------------------------------------------------------------
    px3_text(tty, ttx, ttxt, 231)
    text(cty, cx, CONTACTS, 231)
    if (qn > 0) qr_draw(qy, qx, qz, qm, qn)
    if (gx > 0) {
        qr_draw(qy, gx, qz, qm2, qn2)
        text(my1, mx1, l1, 231)                        # peikar mot kvar sin kode
        text(my2, mx2, l2, 231)
    }
    flush()
}

# dbranch(x, y, a, depth, steps, trend): svak greine (som i malen), vinkel a i radianar,
# trekk mot vinkelen `trend`, sidegreiner vekselvis, held seg utanfor tekstboksen og til
# høgre for XMIN. Fargane er dempa (dei er svake i malen).
function dbranch(x, y, a, depth, steps, trend,   n, since, turn, side, nextfork) {
    since = 0; turn = 0
    side = (rand() < 0.5) ? -1 : 1
    nextfork = 12 + int(rand() * 10)
    for (n = 0; n < steps; n++) {
        turn += (rand() - 0.5) * 0.025
        turn *= 0.96
        a += turn + (trend - a) * 0.02
        x += cos(a); y += sin(a)
        if (y < 0 || y >= 2 * H || x < XMIN || x >= W) return
        if (x > BX1 && x < BX2 && y > BY1 && y < BY2) return
        if (gx > 0 && x > FX1 && x < FX2 && y > FY1 && y < FY2) return      # GitHub-koden
        if (gx > 0 && x > TX1 && x < TX2 && y > TY1 && y < TY2) return      # teksten mellom kodane
        edge_char(x, y, a, (depth >= 1) ? 237 : 59)
        since++
        if (since > 14 && rand() < 0.05) { pnode(x, y); since = 0 }
        if (depth < 2 && n >= nextfork && (steps - n) > 16) {
            dbranch(x, y, a + side * (0.45 + rand() * 0.55), depth + 1, int((steps - n) * (0.35 + rand() * 0.25)), trend)
            a -= side * 0.10
            side = -side
            nextfork = n + 18 + int(rand() * 14)
        }
    }
    pnode(x, y)
}

# load_qr(fil, m): les ei 0/1-matrise (ein rad per linje) til m[rad, kol], returnerer storleiken.
function load_qr(file, m,   n, line, j) {
    n = 0
    while ((getline line < file) > 0) { for (j = 1; j <= length(line); j++) m[n, j - 1] = (substr(line, j, 1) == "1"); n++ }
    close(file)
    return n
}
# qr_draw(y0, x0, qz, m, n): matrisen m (n x n) med kvit ramme (qz moduler), to piksel per
# celle (▀ med fg = øvre, bg = nedre). Svart = 16, kvit = 231.
function qr_draw(y0, x0, qz, m, n,   p, r, c, t, b) {
    p = n + 2 * qz
    for (r = 0; r < int((p + 1) / 2); r++) for (c = 0; c < p; c++) {
        t = qr_px(2 * r, c, qz, m, n)
        b = qr_px(2 * r + 1, c, qz, m, n)
        if (y0 + r >= H || x0 + c >= W) continue
        ch[y0 + r, x0 + c] = "\xe2\x96\x80"; fg[y0 + r, x0 + c] = t; bg[y0 + r, x0 + c] = b; fgs[y0 + r, x0 + c] = ""; bgs[y0 + r, x0 + c] = ""
    }
}
# Fargeindeks (16 = svart modul, 231 = kvit) for piksel (rad, kol) i QR-området inkl. ramme.
function qr_px(pr, pc, qz, m, n,   r, c) {
    r = pr - qz; c = pc - qz
    if (r < 0 || c < 0 || r >= n || c >= n) return 231
    return m[r, c] ? 16 : 231
}
