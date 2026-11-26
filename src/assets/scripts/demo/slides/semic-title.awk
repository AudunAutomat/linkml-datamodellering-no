# Tittelslide (slide 2): se semic-title.sh. Brukar funksjonar frå semic-canvas.awk.
# Krev -v TITLE=<tekst> (vert gjort om til store bokstavar). Valfri -v BYLINE=<tekst>
# vert vist som vanleg tekst rett under tittelen. Valfri -v SUBTITLE=<tekst> står
# i same skriftstorleik mellom tittel og BYLINE.
BEGIN {
    init_canvas()
    init_fonts()
    init_font3()

    # Bakgrunn: biletet frå malen (IMGFILE), elles teikna kuler og bobler.
    if (IMGFILE != "" && load_image(IMGFILE)) {
        clear(int(0.05 * H), int(0.71 * W), int(0.24 * H), int(0.97 * W))    # logoen i biletet
    } else {
        # --- nettverkskuler og bobler, målte mot malen (side 2) -----------------------
        # Kuler er sirklar med x-radius = 2 * y-radius.
        ry = 0.46 * H; sphere(0.90 * W, 1.11 * H, 2 * ry, ry, 0)    # nede til høgre
        ry = 0.34 * H; sphere(0.0 * W, -0.01 * H, 2 * ry, ry, 1)    # øvst til venstre
        ry = 0.056 * H; bubble(0.176 * W, 0.336 * H, 2 * ry, ry)
        ry = 0.053 * H; bubble(0.610 * W, 0.060 * H, 2 * ry, ry)
        ry = 0.104 * H; bubble(0.100 * W, 0.830 * H, 2 * ry, ry)
        ry = 0.146 * H; bubble(0.580 * W, 0.920 * H, 2 * ry, ry)

    }

    # --- logo øvst til høgre (same lille SEMIC 20/26 conference som på forsida) -----
    GW = 4; px = 1; gap = 1
    lw = 20 + 4 * gap; dw = 2 * GW + gap; side = 2; total = lw + side + dw
    lx = int(0.96 * W) - total
    ly = int(0.07 * H)
    clear(ly - 1, lx - 2, ly + 7, lx + total + 2)
    draw_title(ly, lx, px, gap, lw, side, 0)

    # --- tittel: midt i bildet, brote på ordgrense viss han er for brei -----------
    t = toupper(TITLE)
    maxw = int(0.8 * W)
    nw = split(t, words, " ")
    nl = 0; cur = ""
    for (i = 1; i <= nw; i++) {
        trial = (cur == "") ? words[i] : cur " " words[i]
        if (cur != "" && px3_width(trial) > maxw) { lines[++nl] = cur; cur = words[i] }
        else cur = trial
    }
    lines[++nl] = cur
    totalh = nl * 3 + (nl - 1)
    ty = int((H - totalh) / 2)
    maxlw = 0
    for (i = 1; i <= nl; i++) { w = px3_width(lines[i]); if (w > maxlw) maxlw = w }
    clear(ty - 2, int((W - maxlw) / 2) - 4, ty + totalh + 3, int((W + maxlw) / 2) + 4)
    for (i = 1; i <= nl; i++) {
        w = px3_width(lines[i])
        px3_text(ty + (i - 1) * 4, int((W - w) / 2), lines[i], 231)
    }
    by = ty + totalh + 2
    if (SUBTITLE != "") {
        text(by, int((W - length(SUBTITLE)) / 2), SUBTITLE, 250)
        by += 2
    }
    if (BYLINE != "") {
        text(by, int((W - length(BYLINE)) / 2), BYLINE, 250)
    }
    flush()
}
