# Forside (slide 1): se semic-cover.sh. Brukar funksjonar frå semic-canvas.awk.
BEGIN {
    init_canvas()
    init_fonts()

    # Bakgrunn: biletet frå malen (IMGFILE, laga av semic-image.py), elles teikna kuler.
    if (IMGFILE != "" && load_image(IMGFILE)) {
        # fjern logo og tagline som ligg i biletet (grovt), vi teiknar skarpe versjonar
        clear(int(0.33 * H), int(0.37 * W), int(0.68 * H), int(0.645 * W))
    } else {
        # --- nettverkskuler ------------------------------------------------------
        # Kulene er sirklar (ei terminalcelle er ca. dobbelt så høg som brei, så
        # x-radius = 2 * y-radius). Plassering målt mot malen: kula øvst til venstre
        # når ca. 51 % ned og 42 % til høgre; kula nede til høgre startar ca. 58 % ned.
        # Midtpunkta er målte med full radius; SCALE (0.8) minkar kulene rundt same midtpunkt.
        SCALE = 0.8
        ry = 0.55 * H; sphere(0.42 * W - 2 * ry, -0.04 * H, 2 * ry * SCALE, ry * SCALE, 1)
        ry = 0.62 * H; sphere(0.84 * W, 1.20 * H, 2 * ry * SCALE, ry * SCALE, 0)
        bubble(0.46 * W, 0.14 * H, 0.035 * W, 0.075 * H)
        bubble(0.77 * W, 0.50 * H, 0.060 * W, 0.140 * H)
        bubble(0.07 * W, 0.58 * H, 0.030 * W, 0.070 * H)
        bubble(0.34 * W, 0.86 * H, 0.055 * W, 0.120 * H)

    }

    if (SIZE == "large") {
        GW = 5
        px = (W >= 110) ? 2 : 1
        gap = px
        lw = 5 * 5 * px + 4 * gap
        dw = 2 * 5 * px + gap
        side = 2 * px + 2
        total = lw + side + dw
        x0 = int((W - total) / 2)
        y0 = int(H / 2 - 8)
        if (y0 < 1) y0 = 1
        clear(y0 - 1, x0 - 3, y0 + 17, x0 + total + 3)
        draw_title(y0, x0, px, gap, lw, side, 1)
        tag_y = y0 + 13
    } else {
        GW = 4
        px = 1; gap = 1
        # S E C = 4 piksel, M = 5 (ellers ser han ut som H), I = 3  ->  20 + 4 * gap = 28
        lw = 20 + 4 * gap
        dw = 2 * GW + gap
        side = 2
        total = lw + side + dw
        x0 = int((W - total) / 2)
        y0 = int(H / 2 - 5.5)
        if (y0 < 1) y0 = 1
        clear(y0 - 1, x0 - 3, y0 + 12, x0 + total + 3)
        draw_title(y0, x0, px, gap, lw, side, 0)
        tag_y = y0 + 9
    }
    x0t = x0

    # --- tagline ---------------------------------------------------------------
    ty = tag_y
    split("38 44 43 79 114 150 185 220 214", gc, " ")
    word = "Interoperability"
    for (i = 1; i <= length(word); i++) {
        k = int((i - 1) * 8 / (length(word) - 1)) + 1
        text(ty, x0t + i - 1, substr(word, i, 1), gc[k])
    }
    text(ty, x0t + length(word), " by design", 231)
    text(ty + 1, x0t, "for a competitive Europe", 231)

    flush()
}
