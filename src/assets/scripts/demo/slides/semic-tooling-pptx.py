#!/usr/bin/env python3
"""Bygg ei PowerPoint-slide (hub-and-spoke: LinkML-verktøyet) frå SEMIC 2026-malen.

Berre stdlib; skriv OOXML direkte, så ingen avhengigheiter må installerast.
Fjernar malslidene og legg inn éi slide på layouten «Content».

Bruk: python3 -I semic-tooling-pptx.py MAL.pptx UT.pptx
Døme: python3 -I semic-tooling-pptx.py "src/tmp/PPT TEMPLATE SEMIC 2026 .pptx" src/tmp/semic-tooling-slide.pptx
Spec: specs/done/semic-tooling-slide.md
"""
import math
import re
import shutil
import sys
import zipfile
from pathlib import Path
from xml.sax.saxutils import escape

if len(sys.argv) != 3:
    sys.exit(__doc__)
SRC, OUT = sys.argv[1], sys.argv[2]
W, H = 12192000, 6858000

TITLE = "With LinkML at its core, can we make tooling that enables «easy to do the right thing»?"
# (stikkord, ikon), med klokka frå øvre høgre
ITEMS = [
    ("Open source,\nfor anyone", "globe"),
    ("Generate value\nfrom the model", "gear"),
    ("Validate against\nstandards and FAIR", "check"),
    ("Analyze for\nanomalies", "magnifier"),
    ("Bridge to\nsemantic formats", "bridge"),
    ("Publish to\ndata catalogs", "catalog"),
    ("Cooperate across\norganizations", "venn"),
    ("AI in the\nmodelling process", "sparkle"),
]

BLUE, CYAN, PINK, WHITE, INK = "3633D1", "4AB1FE", "9E2FD5", "FFFFFF", "0B0C12"

_id = [10]


def nid():
    _id[0] += 1
    return _id[0]


def fill(c, alpha=None):
    a = f'<a:alpha val="{alpha}"/>' if alpha is not None else ""
    return f'<a:solidFill><a:srgbClr val="{c}">{a}</a:srgbClr></a:solidFill>'


def line(c=None, w=12700, alpha=None, dash=None):
    if c is None:
        return "<a:ln><a:noFill/></a:ln>"
    d = f'<a:prstDash val="{dash}"/>' if dash else ""
    return f'<a:ln w="{w}">{fill(c, alpha)}{d}</a:ln>'


def shape(name, prst, x, y, w, h, f=None, ln=None, rot=0, geom=None, flip=""):
    """Form med presetgeometri (eller custGeom). x,y,w,h i EMU."""
    g = geom or f'<a:prstGeom prst="{prst}"><a:avLst/></a:prstGeom>'
    r = f' rot="{int(rot * 60000)}"' if rot else ""
    return (
        f'<p:sp><p:nvSpPr><p:cNvPr id="{nid()}" name="{escape(name)}"/><p:cNvSpPr/><p:nvPr/></p:nvSpPr>'
        f'<p:spPr><a:xfrm{r}{flip}><a:off x="{int(x)}" y="{int(y)}"/><a:ext cx="{int(w)}" cy="{int(h)}"/></a:xfrm>'
        f'{g}{f or "<a:noFill/>"}{ln or line()}</p:spPr>'
        f'<p:txBody><a:bodyPr rtlCol="0" anchor="ctr"/><a:lstStyle/><a:p><a:endParaRPr lang="en-GB"/></a:p></p:txBody></p:sp>'
    )


def connector(name, x1, y1, x2, y2, c, w=15875, alpha=None):
    x, y = min(x1, x2), min(y1, y2)
    flip = ""
    if x2 < x1:
        flip += ' flipH="1"'
    if y2 < y1:
        flip += ' flipV="1"'
    return (
        f'<p:cxnSp><p:nvCxnSpPr><p:cNvPr id="{nid()}" name="{escape(name)}"/><p:cNvCxnSpPr/><p:nvPr/></p:nvCxnSpPr>'
        f'<p:spPr><a:xfrm{flip}><a:off x="{int(x)}" y="{int(y)}"/><a:ext cx="{int(abs(x2 - x1))}" cy="{int(abs(y2 - y1))}"/></a:xfrm>'
        f'<a:prstGeom prst="line"><a:avLst/></a:prstGeom>{line(c, w, alpha)}</p:spPr></p:cxnSp>'
    )


def textbox(name, x, y, w, h, lines, sz, algn, color=WHITE, bold=False, anchor="ctr"):
    paras = "".join(
        f'<a:p><a:pPr algn="{algn}"/><a:r><a:rPr lang="en-GB" sz="{sz}" b="{int(bold)}" dirty="0">{fill(color)}</a:rPr>'
        f"<a:t>{escape(t)}</a:t></a:r></a:p>"
        for t in lines
    )
    return (
        f'<p:sp><p:nvSpPr><p:cNvPr id="{nid()}" name="{escape(name)}"/><p:cNvSpPr txBox="1"/><p:nvPr/></p:nvSpPr>'
        f'<p:spPr><a:xfrm><a:off x="{int(x)}" y="{int(y)}"/><a:ext cx="{int(w)}" cy="{int(h)}"/></a:xfrm>'
        f'<a:prstGeom prst="rect"><a:avLst/></a:prstGeom><a:noFill/></p:spPr>'
        f'<p:txBody><a:bodyPr wrap="square" lIns="0" tIns="0" rIns="0" bIns="0" rtlCol="0" anchor="{anchor}"><a:noAutofit/></a:bodyPr>'
        f"<a:lstStyle/>{paras}</p:txBody></p:sp>"
    )


def cust(path_w, path_h, cmds):
    return (
        f'<a:custGeom><a:avLst/><a:gdLst/><a:ahLst/><a:cxnLst/><a:rect l="0" t="0" r="r" b="b"/>'
        f'<a:pathLst><a:path w="{path_w}" h="{path_h}">{cmds}</a:path></a:pathLst></a:custGeom>'
    )


def pts(points):
    out = []
    for i, (px, py) in enumerate(points):
        tag = "moveTo" if i == 0 else "lnTo"
        out.append(f'<a:{tag}><a:pt x="{px}" y="{py}"/></a:{tag}>')
    out.append("<a:close/>")
    return "".join(out)


def icon(kind, cx, cy, r):
    """Ikon i kvit/cyan inni i ein sirkel med radius r, midt i (cx, cy). Berre enkle former."""
    s = []
    u = r * 0.52  # halv breidd på ikonet
    F = fill(WHITE)
    thick = line(WHITE, 38100)
    if kind == "globe":      # open for alle
        s.append(shape("Icon globe", "ellipse", cx - u, cy - u, 2 * u, 2 * u, None, thick))
        s.append(shape("Icon meridian", "ellipse", cx - u * 0.42, cy - u, u * 0.84, 2 * u, None, line(WHITE, 19050)))
        s.append(connector("Icon equator", cx - u, cy, cx + u, cy, WHITE, 19050))
    elif kind == "gear":     # generering
        for k, ang in enumerate((0, 45, 90, 135)):
            s.append(shape(f"Icon tooth {k}", "roundRect", cx - u * 1.05, cy - u * 0.2, u * 2.1, u * 0.4, F, rot=ang))
        s.append(shape("Icon gear", "ellipse", cx - u * 0.72, cy - u * 0.72, u * 1.44, u * 1.44, F))
        s.append(shape("Icon gear hole", "ellipse", cx - u * 0.3, cy - u * 0.3, u * 0.6, u * 0.6, fill(BLUE)))
    elif kind == "check":    # validering
        s.append(shape("Icon check short", "roundRect", cx - u * 0.95, cy + u * 0.02, u * 0.95, u * 0.34, F, rot=45))
        s.append(shape("Icon check long", "roundRect", cx - u * 0.35, cy - u * 0.12, u * 1.75, u * 0.34, F, rot=-50))
    elif kind == "magnifier":  # analyse
        d = u * 1.45
        s.append(shape("Icon lens", "ellipse", cx - u * 0.95, cy - u * 0.95, d, d, None, thick))
        s.append(shape("Icon handle", "roundRect", cx + u * 0.15, cy + u * 0.45, u * 1.15, u * 0.34, F, rot=45))
    elif kind == "bridge":   # tradisjonell <-> semantisk
        s.append(shape("Icon bridge", "leftRightArrow", cx - u * 1.15, cy - u * 0.6, u * 2.3, u * 1.2, F))
    elif kind == "catalog":  # katalog / database
        s.append(shape("Icon catalog", "can", cx - u * 0.8, cy - u, u * 1.6, u * 2.0, F))
    elif kind == "venn":     # samarbeid
        d = u * 1.4
        s.append(shape("Icon venn left", "ellipse", cx - u * 1.05, cy - d / 2, d, d, fill(WHITE, 70000), line(WHITE, 12700)))
        s.append(shape("Icon venn right", "ellipse", cx + u * 1.05 - d, cy - d / 2, d, d, fill(CYAN, 70000), line(WHITE, 12700)))
    elif kind == "sparkle":  # AI
        s.append(shape("Icon sparkle large", "star4", cx - u * 0.95, cy - u * 0.8, u * 1.5, u * 1.5, F))
        s.append(shape("Icon sparkle small", "star4", cx + u * 0.3, cy - u * 0.95, u * 0.8, u * 0.8, fill(CYAN)))
        s.append(shape("Icon sparkle tiny", "star4", cx + u * 0.35, cy + u * 0.3, u * 0.6, u * 0.6, fill(WHITE)))
    return "".join(s)


def build_shapes():
    cx, cy = 6096000, 4000000
    rx, ry = 3050000, 1950000
    hub_r = 760000
    node_r = 340000
    out = []

    # bane (orbit) og spokar bak nodane
    out.append(shape("Orbit", "ellipse", cx - rx, cy - ry, 2 * rx, 2 * ry, None, line(BLUE, 9525, 45000, "sysDash")))
    out.append(shape("Orbit outer", "ellipse", cx - rx * 1.22, cy - ry * 1.22, 2.44 * rx, 2.44 * ry, None, line(PINK, 6350, 30000)))

    nodes = []
    for i, (label, kind) in enumerate(ITEMS):
        th = math.radians(-67.5 + 45 * i)
        nodes.append((cx + rx * math.cos(th), cy + ry * math.sin(th), label, kind))

    for i, (nx, ny, label, kind) in enumerate(nodes):
        out.append(connector(f"Spoke {i + 1}", cx, cy, nx, ny, PINK, 19050, 60000))
        # liten node midt på spoken, som nettverksgrafikken i malen
        mx, my = cx + (nx - cx) * 0.52, cy + (ny - cy) * 0.52
        out.append(shape(f"Spoke node {i + 1}", "ellipse", mx - 60000, my - 60000, 120000, 120000, fill(BLUE), line(CYAN, 9525, 60000)))

    # nav
    for k, a in ((1.55, 10000), (1.28, 20000)):
        rr = hub_r * k
        out.append(shape("Hub glow", "ellipse", cx - rr, cy - rr, 2 * rr, 2 * rr, fill(BLUE, a)))
    out.append(shape("Hub", "ellipse", cx - hub_r, cy - hub_r, 2 * hub_r, 2 * hub_r, fill(BLUE), line(CYAN, 19050)))
    out.append(textbox("Hub label", cx - hub_r, cy - 200000, 2 * hub_r, 400000, ["LinkML"], 2400, "ctr", bold=True))

    # noder med ikon og tekst
    for i, (nx, ny, label, kind) in enumerate(nodes):
        out.append(shape(f"Node {i + 1}", "ellipse", nx - node_r, ny - node_r, 2 * node_r, 2 * node_r, fill(BLUE), line(CYAN, 19050)))
        out.append(icon(kind, nx, ny, node_r))
        lw, lh, gap = 2450000, 560000, 130000
        lines = label.split("\n")
        if nx > cx:
            out.append(textbox(f"Label {i + 1}", nx + node_r + gap, ny - lh / 2, lw, lh, lines, 1400, "l", color=INK, bold=True))
        else:
            out.append(textbox(f"Label {i + 1}", nx - node_r - gap - lw, ny - lh / 2, lw, lh, lines, 1400, "r", color=INK, bold=True))
    return "".join(out)


def slide_xml():
    title = (
        f'<p:sp><p:nvSpPr><p:cNvPr id="2" name="Title 1"/><p:cNvSpPr><a:spLocks noGrp="1"/></p:cNvSpPr><p:nvPr><p:ph type="title"/></p:nvPr></p:nvSpPr>'
        f'<p:spPr><a:xfrm><a:off x="3500000" y="300000"/><a:ext cx="8100000" cy="1100000"/></a:xfrm></p:spPr>'
        f'<p:txBody><a:bodyPr anchor="ctr"><a:normAutofit/></a:bodyPr><a:lstStyle/><a:p><a:pPr algn="l"/>'
        f'<a:r><a:rPr lang="en-GB" sz="2400" dirty="0">{fill(INK)}</a:rPr><a:t>{escape(TITLE)}</a:t></a:r></a:p></p:txBody></p:sp>'
    )
    return (
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n'
        '<p:sld xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" '
        'xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" '
        'xmlns:p="http://schemas.openxmlformats.org/presentationml/2006/main"><p:cSld><p:spTree>'
        '<p:nvGrpSpPr><p:cNvPr id="1" name=""/><p:cNvGrpSpPr/><p:nvPr/></p:nvGrpSpPr>'
        '<p:grpSpPr><a:xfrm><a:off x="0" y="0"/><a:ext cx="0" cy="0"/><a:chOff x="0" y="0"/><a:chExt cx="0" cy="0"/></a:xfrm></p:grpSpPr>'
        f"{title}{build_shapes()}</p:spTree></p:cSld><p:clrMapOvr><a:masterClrMapping/></p:clrMapOvr></p:sld>"
    )


def main():
    work = Path(OUT).with_suffix(".dir")
    if work.exists():
        shutil.rmtree(work)
    with zipfile.ZipFile(SRC) as z:
        z.extractall(work)
        order = z.namelist()

    # fjern dei ti malslidene (fil, rels, content-type, presentation-rels, sldIdLst)
    for n in range(1, 11):
        (work / f"ppt/slides/slide{n}.xml").unlink()
        (work / f"ppt/slides/_rels/slide{n}.xml.rels").unlink()
    ct = (work / "[Content_Types].xml").read_text(encoding="utf-8")
    ct = re.sub(r'<Override PartName="/ppt/slides/slide\d+\.xml"[^>]*/>', "", ct)
    ct = ct.replace("</Types>", '<Override PartName="/ppt/slides/slide1.xml" ContentType="application/vnd.openxmlformats-officedocument.presentationml.slide+xml"/></Types>')
    (work / "[Content_Types].xml").write_text(ct, encoding="utf-8")

    rels = (work / "ppt/_rels/presentation.xml.rels").read_text(encoding="utf-8")
    rels = re.sub(r'<Relationship Id="rId\d+" Type="[^"]*/slide" Target="slides/slide\d+\.xml"/>', "", rels)
    rels = rels.replace("</Relationships>", '<Relationship Id="rId5" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/slide" Target="slides/slide1.xml"/></Relationships>')
    (work / "ppt/_rels/presentation.xml.rels").write_text(rels, encoding="utf-8")

    pres = (work / "ppt/presentation.xml").read_text(encoding="utf-8")
    pres = re.sub(r"<p:sldIdLst>.*?</p:sldIdLst>", '<p:sldIdLst><p:sldId id="258" r:id="rId5"/></p:sldIdLst>', pres, flags=re.S)
    (work / "ppt/presentation.xml").write_text(pres, encoding="utf-8")

    (work / "ppt/slides").mkdir(exist_ok=True)
    (work / "ppt/slides/_rels").mkdir(exist_ok=True)
    (work / "ppt/slides/slide1.xml").write_text(slide_xml(), encoding="utf-8")
    (work / "ppt/slides/_rels/slide1.xml.rels").write_text(
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n'
        '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
        '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/slideLayout" Target="../slideLayouts/slideLayout4.xml"/>'
        "</Relationships>",
        encoding="utf-8",
    )

    # zip: [Content_Types].xml først
    files = sorted(p for p in work.rglob("*") if p.is_file())
    rel = lambda p: p.relative_to(work).as_posix()
    names = ["[Content_Types].xml"] + [rel(p) for p in files if rel(p) != "[Content_Types].xml"]
    Path(OUT).unlink(missing_ok=True)
    with zipfile.ZipFile(OUT, "w", zipfile.ZIP_DEFLATED) as z:
        for n in names:
            z.write(work / n, n)
    shutil.rmtree(work)
    print("skreiv", OUT)


main()
