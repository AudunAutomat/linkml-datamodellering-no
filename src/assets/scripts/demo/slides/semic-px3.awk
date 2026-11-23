# Skriv ut tekst (-v TEXT=...) i 3x5-pikselfonten som tre tekstrader (utan farge), til slides
# som ikkje er rutenett-grafikk (t.d. hook.sh). Krev -v W=<breidd> -v H=3. Brukar semic-canvas.awk.
BEGIN {
    init_canvas()
    init_font3()
    if (MODE == "width") { print px3_width(toupper(TEXT)); exit }     # berre breidda i kolonnar
    px3_text(0, 0, toupper(TEXT), 231)
    for (y = 0; y < 3; y++) {
        line = ""
        for (x = 0; x < W; x++) line = line ch[y, x]
        sub(/ +$/, "", line)
        print line
    }
}
