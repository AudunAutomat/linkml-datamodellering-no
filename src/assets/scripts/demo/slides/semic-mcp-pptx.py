#!/usr/bin/env python3
"""Bygg slida «What about AI?» (dei tre MCP-serverane) frå SEMIC 2026-malen.

Berre stdlib (delt kode i semic_pptx_lib.py). AI-agent til venstre, tre MCP-serverar
som kort til høgre, koplingar mellom.

Bruk: python3 -I semic-mcp-pptx.py MAL.pptx UT.pptx
Døme: python3 -I semic-mcp-pptx.py "src/tmp/PPT TEMPLATE SEMIC 2026 .pptx" src/tmp/semic-mcp-slide.pptx
Spec: specs/done/semic-mcp-slide.md
"""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import semic_pptx_lib as L  # noqa: E402
from semic_pptx_lib import BLUE, ICE, INK, PINK, TINT, WHITE, box, connector, fill, line, run  # noqa: E402

if len(sys.argv) != 3:
    sys.exit(__doc__)
SRC, OUT = sys.argv[1], sys.argv[2]

TITLE = "What about AI?"
TAGLINE = "AI proposes. The tooling decides what is right."
# (servernamn, kva han gjer, verktøy, ikon)
SERVERS = [
    ("linkml-modell-utkast", "Drafts a LinkML schema from JSON Schema, following the modelling rules", "generate_linkml · list_policies", "doc"),
    ("linkml-begrep-utkast", "Drafts concepts, searches the concept catalog, validates before publishing", "opprett_begrep · sok_begrepskatalog · valider_begrep", "book"),
    ("linkml-validator", "Checks schemas and data against bronze, silver, gold and publishing policies", "validate_linkml_schema · validate_linkml_instance", "check"),
]
MONO = "Courier New"


def icon(kind, cx, cy, r):
    u = r * 0.5
    F = fill(WHITE)
    s = []
    if kind == "doc":  # dokument med tekstlinjer
        s.append(box("Icon doc", cx - u * 0.75, cy - u, u * 1.5, u * 2, f=F))
        for k in range(3):
            s.append(box(f"Icon doc line {k}", cx - u * 0.45, cy - u * 0.55 + k * u * 0.55, u * 0.9, u * 0.16, f=fill(BLUE)))
    elif kind == "book":  # open bok
        s.append(box("Icon book left", cx - u * 1.05, cy - u * 0.75, u * 1.0, u * 1.5, f=F))
        s.append(box("Icon book right", cx + u * 0.05, cy - u * 0.75, u * 1.0, u * 1.5, f=F))
    elif kind == "check":  # hake
        s.append(box("Icon check short", cx - u * 0.95, cy + u * 0.02, u * 0.95, u * 0.34, prst="roundRect", f=F, rot=45))
        s.append(box("Icon check long", cx - u * 0.35, cy - u * 0.12, u * 1.75, u * 0.34, prst="roundRect", f=F, rot=-50))
    return "".join(s)


def build_shapes():
    out = []
    # tagline under tittelen
    out.append(box("Tagline", 3500000, 1180000, 8100000, 380000, [("l", [run(TAGLINE, 1800, BLUE, bold=True)])], anchor="ctr"))

    # AI-agent (venstre)
    ax, ay, ar = 1900000, 4000000, 850000
    cards_x, cw, ch, gap, y0 = 4300000, 7300000, 1300000, 150000, 1900000
    centers = [y0 + i * (ch + gap) + ch / 2 for i in range(3)]
    for i, cy in enumerate(centers):  # koplingar bak sirkelen og korta
        out.append(connector(f"Link {i + 1}", ax, ay, cards_x, cy, PINK, 22225, 60000))
        mx, my = ax + (cards_x - ax) * 0.62, ay + (cy - ay) * 0.62
        out.append(box(f"Link dot {i + 1}", mx - 65000, my - 65000, 130000, 130000, prst="ellipse", f=fill(BLUE), ln=line(ICE, 9525)))
    out.append(box("Agent glow", ax - ar * 1.4, ay - ar * 1.4, 2 * ar * 1.4, 2 * ar * 1.4, prst="ellipse", f=fill(BLUE, 12000)))
    out.append(box("Agent", ax - ar, ay - ar, 2 * ar, 2 * ar, [("ctr", [run("AI agent", 2000, WHITE, bold=True)])], prst="ellipse", f=fill(BLUE), ln=line("4AB1FE", 19050), anchor="ctr"))
    out.append(box("Agent caption", 500000, ay + ar * 1.45, 2800000, 800000,
                   [("ctr", [run("Claude Code or any MCP client", 1200, INK)]),
                    ("ctr", [run("MCP servers run locally, in containers", 1200, INK)])], anchor="t"))

    # tre MCP-kort (høgre)
    pad = 230000
    for i, (name, what, tools, ic) in enumerate(SERVERS):
        y = y0 + i * (ch + gap)
        out.append(box(f"Card {name}", cards_x, y, cw, ch, prst="roundRect", f=fill(TINT)))
        cx, cy, r = cards_x + pad + 330000, y + ch / 2, 330000
        out.append(box(f"Icon circle {name}", cx - r, cy - r, 2 * r, 2 * r, prst="ellipse", f=fill(BLUE)))
        out.append(icon(ic, cx, cy, r))
        tx = cards_x + pad + 2 * r + 220000
        tw = cw - (tx - cards_x) - pad
        out.append(box(f"Name {name}", tx, y + 130000, tw, 300000, [("l", [run(name, 1600, INK, bold=True, font=MONO)])], anchor="ctr"))
        out.append(box(f"What {name}", tx, y + 450000, tw, 460000, [("l", [run(what, 1400, INK)])], anchor="t"))
        out.append(box(f"Tools {name}", tx, y + 930000, tw, 260000, [("l", [run(tools, 1100, BLUE, font=MONO)])], anchor="ctr"))
    return "".join(out)


L.build_deck(SRC, OUT, L.slide_xml(L.title_ph(TITLE, h=800000), build_shapes()))
