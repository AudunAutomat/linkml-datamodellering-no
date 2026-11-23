# Spørsmålsslide (slide 8): se semic-questions.sh. Brukar funksjonar frå semic-canvas.awk.
# Krev -v TITLE=<tekst>.
BEGIN {
    init_canvas()
    init_fonts()
    init_font3()

    # tekstboksen (i piksel, 1 piksel = 1 kolonne x 1/2 rad) — greinene skal nærme seg han utan å røre
    ttxt = toupper(TITLE)
    tw = px3_width(ttxt)
    ttx = int((W - tw) / 2)
    tty = int((H - 3) / 2)
    TXL = ttx - 16                    # greiner som når hit (og er høgt nok) sluttar
    TYB = 2 * tty + 6 + 14            # ... med minst 14 piksel (7 rader) avstand under teksten

    # Bakgrunn: biletet frå malen (IMGFILE), elles teikna glød, bølgje og greiner.
    if (IMGFILE != "" && load_image(IMGFILE)) {
        clear(int(0.05 * H), int(0.03 * W), int(0.20 * H), int(0.225 * W))    # logoen i biletet
        clear(int(0.42 * H), int(0.35 * W), int(0.55 * H), int(0.65 * W), "h")     # «QUESTIONS?» i biletet
    } else {
        # --- blå glød på høgre side, mørk bølgje nede, målt mot malen ------------------
        # Bølgja (grense mellom glød og mørkt), som (u, v) i brøkdelar av breidd/høgd.
        wu[0] = 0.26; wv[0] = 0.65
        wu[1] = 0.31; wv[1] = 0.79
        wu[2] = 0.39; wv[2] = 0.90
        wu[3] = 0.48; wv[3] = 0.955
        wu[4] = 0.59; wv[4] = 0.90
        wu[5] = 0.70; wv[5] = 0.79
        wu[6] = 0.82; wv[6] = 0.69
        wu[7] = 0.94; wv[7] = 0.64
        wu[8] = 1.00; wv[8] = 0.63
        split("16 16 17 17 18 18 19 19 20", ramp, " ")
        for (y = 0; y < H; y++) for (x = 0; x < W; x++) {
            u = (x + 0.5) / W; v = (y + 0.5) / H
            d = sqrt(((u - 0.68) / 0.62) ^ 2 + ((v - 0.64) / 0.85) ^ 2)
            i = 1 - d; if (i < 0) i = 0
            e = (u - 0.23) / 0.20; if (e < 0) e = 0; if (e > 1) e = 1
            i = i * e * e * (3 - 2 * e)
            # under bølgja: mørkt
            wave = 1
            for (k = 0; k < 8; k++) if (u >= wu[k] && u <= wu[k + 1]) wave = wv[k] + (wv[k + 1] - wv[k]) * (u - wu[k]) / (wu[k + 1] - wu[k])
            if (u > wu[8]) wave = wv[8]
            if (u < wu[0]) wave = wv[0]
            if (v > wave) { bg[y, x] = 16; continue }
            lv = int(i * 8 + (rand() - 0.5) * 0.5 + 0.5) + 1
            if (lv < 1) lv = 1; if (lv > 9) lv = 9
            bg[y, x] = ramp[lv]
        }

        # --- greiner med noder som veks inn frå venstre kant (pikselbuffer) ---------------
        # 8-bit: tynne rosa linjer (teikn) i lange kurver frå venstre og nedre kant,
        # opp og mot høgre, med forgreiningar og blå noder (pikselsirklar) i ulike storleikar.
        # Held seg under logoen (PSTOPY) og i venstre ca. 31 % av breidda (PGX1).
        PSTOPY = 2 * (int(0.07 * H) + 9)       # rett under logoen
        PGX1 = 0.31 * W
        for (k = 0; k < 5; k++)
            pbranch(0, PSTOPY + 14 + (k + rand()) * (2 * H - PSTOPY - 20) / 5, -(0.4 + rand() * 0.8), 0, 80 + int(rand() * 60))
        for (k = 0; k < 3; k++)
            pbranch(rand() * 0.12 * W, 2 * H - 1, -(1.0 + rand() * 0.45), 0, 100 + int(rand() * 60))
        # lange greiner frå nedre venstre mot midten og opp mot «QUESTIONS?» (stoppar under teksten)
        for (k = 0; k < 3; k++)
            pbranch(0.04 * W + rand() * 0.32 * W, 2 * H - 1, -(0.7 + rand() * 0.5), 0, 240 + int(rand() * 60), 0, 0.62 * W)
        pb_flush()
    }

    # --- logo øvst til venstre ---------------------------------------------------
    GW = 4; px = 1; gap = 1
    lw = 20 + 4 * gap; dw = 2 * GW + gap; side = 2; total = lw + side + dw
    lx = int(0.04 * W)
    ly = int(0.07 * H)
    clear(ly - 1, lx - 2, ly + 7, lx + total + 2)
    draw_title(ly, lx, px, gap, lw, side, 0)

    # --- tittel midt i bildet -------------------------------------------------------
    t = toupper(TITLE)
    w = px3_width(t)
    tx = int((W - w) / 2)
    ty = int((H - 3) / 2)           # same rad som tittelen på tittelslida
    px3_text(ty, tx, t, 231)
    flush()
}

# pbranch(x, y, vinkel, djupn, steg): greine, eitt steg = 1 piksel. Negativ vinkel =
# oppover; krummar seg sakte mot høgre, og bøyer av mot høgre like under logoen.
function pbranch(x, y, a, depth, steps, ytop, xl,   n, since, lc, reach, tgx, tgy, des, turn, side, forkgap, nextfork, ax) {
    if (xl == "") xl = PGX1
    reach = (xl > PGX1)
    if (reach) { tgx = ttx + rand() * tw * 0.75; tgy = TYB + rand() * 10 }    # mål: under teksten, med god avstand
    if (ytop == "") ytop = PSTOPY + 4 + rand() * 0.6 * (2 * H - PSTOPY)    # kvar greine sluttar på eiga høgd
    lc = (depth >= 2) ? 139 : 175
    since = 0; turn = 0
    side = (rand() < 0.5) ? -1 : 1                       # sidegreiner kjem vekselvis frå kvar side, som på eit tre
    nextfork = 10 + int(rand() * 8)
    for (n = 0; n < steps; n++) {
        # glatt krumming: sakte "sving" som vandrar tilfeldig og vert dempa, + svak trekk mot opp/høgre
        turn += (rand() - 0.5) * 0.025
        turn *= 0.96
        a += turn
        if (reach) {                          # styr sakte mot målpunktet
            des = atan2(tgy - y, tgx - x)
            a += (des - a) * 0.05
            if (y <= tgy || (x >= tgx && y <= tgy + 12)) { pnode(x, y); return }      # framme ved målet
        } else a += ((-1.0) - a) * 0.022           # lett trekk mot opp-og-til-høgre (som mot lyset)
        if (y < ytop) { pnode(x, y); return }      # slutt med ein node i staden for å flate ut langs toppen
        if (a > 0.5) a = 0.5; if (a < -1.55) a = -1.55
        x += cos(a); y += sin(a)
        if (y < PSTOPY || y >= 2 * H || x < 0 || x >= xl) return
        if (x > TXL && y < TYB) { pnode(x, y); return }          # nær nok «QUESTIONS?»
        edge_char(x, y, a, lc)
        # stammen er tjukkare nær basen (tapering): to tilstøytande teikn dei første 40 % av lengda
        if (depth == 0 && n < steps * 0.4) {
            ax = (a < 0) ? -a : a
            if (ax > 1.15) edge_char(x + 1, y, a, lc)
        }
        since++
        if (since > 12 && rand() < 0.05) { pnode(x, y); since = 0 }
        # sidegreiner med jamn avstand, vekselvis til kvar side, 25-55 grader frå hovudgreina
        if (depth < 3 && n >= nextfork && (steps - n) > 16) {
            pbranch(x, y, a + side * (0.45 + rand() * 0.55), depth + 1, int((steps - n) * (0.35 + rand() * 0.25)), ytop - rand() * 10, xl)
            a -= side * 0.10                                  # hovudgreina bøyer litt bort frå sidegreina
            side = -side
            nextfork = n + 14 + int(rand() * 12)
        }
    }
    pnode(x, y)
}
