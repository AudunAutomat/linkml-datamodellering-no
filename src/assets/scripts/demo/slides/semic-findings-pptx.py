#!/usr/bin/env python3
"""Bygg ei PowerPoint-slide med upstream-funn (findings) frå SEMIC 2026-malen.

Berre stdlib; skriv OOXML direkte, så ingen avhengigheiter må installerast.
Fjernar malslidene og legg inn éi slide på layouten «Content». Kvar bug er eit
kort med kategori, overskrift og hyperlenkje til GitHub-issuen.

Bruk: python3 -I semic-findings-pptx.py MAL.pptx UT.pptx
Døme: python3 -I semic-findings-pptx.py "src/tmp/PPT TEMPLATE SEMIC 2026 .pptx" src/tmp/semic-findings-slide.pptx
Spec: specs/backlog/semic-findings-slide.md (sjå òg semic-tooling-pptx.py, same metode)
"""
import re
import shutil
import sys
import zipfile
from pathlib import Path
from xml.sax.saxutils import escape

if len(sys.argv) != 3:
    sys.exit(__doc__)
SRC, OUT = sys.argv[1], sys.argv[2]

TITLE = "Findings: 7 issues reported upstream to LinkML"
REPO = "https://github.com/linkml/linkml/issues/"
# (issue, kategori, overskrift)
FINDINGS = [
    (4285, "RDF loader", "Duplicate slot_uri breaks RDF loading"),
    (4286, "RDF loader", "Attribute shadows a global slot on RDF load"),
    (4287, "RDF loader", "Custom dateTime type loses the T on load"),
    (4288, "RDF dumper and loader", "rdf:langString written as invalid RDF, silently lost"),
    (4289, "Generators", "Re-declared imported class: crash or silent slot loss"),
    (4290, "gen-doc", "Broken Mermaid links for built-in types"),
    (4291, "gen-rdf", "gen-rdf fetches a missing context.jsonld (404)"),
]
LOADER = {"RDF loader", "RDF dumper and loader"}

BLUE, PURPLE, WHITE, INK, TINT = "3633D1", "9E2FD5", "FFFFFF", "0B0C12", "ECF0FB"

_id = [10]
LINKS = []  # (rId, url)


def nid():
    _id[0] += 1
    return _id[0]


def fill(c):
    return f'<a:solidFill><a:srgbClr val="{c}"/></a:solidFill>'


def run(text, sz, color, bold=False, link=None):
    h = ""
    if link:
        rid = f"rId{len(LINKS) + 2}"  # rId1 = layout
        LINKS.append((rid, link))
        h = f'<a:hlinkClick r:id="{rid}"/>'
    u = ' u="sng"' if link else ""
    return (
        f'<a:r><a:rPr lang="en-GB" sz="{sz}" b="{int(bold)}"{u} dirty="0">{fill(color)}{h}</a:rPr>'
        f"<a:t>{escape(text)}</a:t></a:r>"
    )


def box(name, x, y, w, h, paras, prst="rect", f=None, anchor="t", inset=0):
    """Form med tekst. paras: liste av (algn, [run-xml, ...])."""
    body = "".join(f'<a:p><a:pPr algn="{a}"/>{"".join(rs)}</a:p>' for a, rs in paras) or '<a:p><a:endParaRPr lang="en-GB"/></a:p>'
    geom = f'<a:prstGeom prst="{prst}"><a:avLst>{"<a:gd name=\"adj\" fmla=\"val 9000\"/>" if prst == "roundRect" else ""}</a:avLst></a:prstGeom>'
    tx = "1" if f is None else "0"
    return (
        f'<p:sp><p:nvSpPr><p:cNvPr id="{nid()}" name="{escape(name)}"/><p:cNvSpPr txBox="{tx}"/><p:nvPr/></p:nvSpPr>'
        f'<p:spPr><a:xfrm><a:off x="{int(x)}" y="{int(y)}"/><a:ext cx="{int(w)}" cy="{int(h)}"/></a:xfrm>{geom}'
        f'{f or "<a:noFill/>"}<a:ln><a:noFill/></a:ln></p:spPr>'
        f'<p:txBody><a:bodyPr wrap="square" lIns="{inset}" tIns="{inset}" rIns="{inset}" bIns="{inset}" rtlCol="0" anchor="{anchor}"><a:noAutofit/></a:bodyPr>'
        f"<a:lstStyle/>{body}</p:txBody></p:sp>"
    )


def build_shapes():
    out = []
    x0, y0 = 600000, 1650000
    cw, ch, gx, gy = 5350000, 1000000, 300000, 130000
    pad = 220000
    cells = [(i % 2, i // 2) for i in range(8)]
    for i, (issue, cat, head) in enumerate(FINDINGS):
        cx, cy = cells[i]
        x, y = x0 + cx * (cw + gx), y0 + cy * (ch + gy)
        col = BLUE if cat in LOADER else PURPLE
        out.append(box(f"Card {issue}", x, y, cw, ch, [], prst="roundRect", f=fill(TINT)))
        # kategori-etikett (fargeprikk + tekst), overskrift, lenkje
        out.append(box(f"Dot {issue}", x + pad, y + 160000, 110000, 110000, [], prst="ellipse", f=fill(col)))
        out.append(box(f"Category {issue}", x + pad + 190000, y + 110000, 2800000, 210000, [("l", [run(cat.upper(), 1100, col, bold=True)])], anchor="ctr"))
        out.append(box(f"Headline {issue}", x + pad, y + 360000, cw - 2 * pad - 1250000, 560000, [("l", [run(head, 1500, INK, bold=True)])], anchor="t"))
        out.append(box(f"Link {issue}", x + cw - pad - 1250000, y + 110000, 1250000, 210000, [("r", [run(f"linkml#{issue}", 1200, BLUE, link=f"{REPO}{issue}")])], anchor="ctr"))
    # åttande felt: oppsummering
    cx, cy = cells[7]
    x, y = x0 + cx * (cw + gx), y0 + cy * (ch + gy)
    out.append(box("Summary card", x, y, cw, ch, [], prst="roundRect", f=fill(INK)))
    out.append(box("Summary number", x + pad, y + 120000, 800000, 760000, [("l", [run("7", 5400, WHITE, bold=True)])], anchor="ctr"))
    out.append(box(
        "Summary text", x + pad + 850000, y + 120000, cw - 2 * pad - 850000, 760000,
        [("l", [run("issues reported to linkml/linkml", 1500, WHITE, bold=True)]),
         ("l", [run("all reproduced on 1.12.1 and main", 1200, "CADCFC")])],
        anchor="ctr",
    ))
    return "".join(out)


def slide_xml():
    shapes = build_shapes()
    title = (
        '<p:sp><p:nvSpPr><p:cNvPr id="2" name="Title 1"/><p:cNvSpPr><a:spLocks noGrp="1"/></p:cNvSpPr><p:nvPr><p:ph type="title"/></p:nvPr></p:nvSpPr>'
        '<p:spPr><a:xfrm><a:off x="3500000" y="300000"/><a:ext cx="8100000" cy="1000000"/></a:xfrm></p:spPr>'
        '<p:txBody><a:bodyPr anchor="ctr"><a:normAutofit/></a:bodyPr><a:lstStyle/><a:p><a:pPr algn="l"/>'
        f'<a:r><a:rPr lang="en-GB" sz="2800" dirty="0">{fill(INK)}</a:rPr><a:t>{escape(TITLE)}</a:t></a:r></a:p></p:txBody></p:sp>'
    )
    return (
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n'
        '<p:sld xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" '
        'xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" '
        'xmlns:p="http://schemas.openxmlformats.org/presentationml/2006/main"><p:cSld><p:spTree>'
        '<p:nvGrpSpPr><p:cNvPr id="1" name=""/><p:cNvGrpSpPr/><p:nvPr/></p:nvGrpSpPr>'
        '<p:grpSpPr><a:xfrm><a:off x="0" y="0"/><a:ext cx="0" cy="0"/><a:chOff x="0" y="0"/><a:chExt cx="0" cy="0"/></a:xfrm></p:grpSpPr>'
        f"{title}{shapes}</p:spTree></p:cSld><p:clrMapOvr><a:masterClrMapping/></p:clrMapOvr></p:sld>"
    )


def main():
    work = Path(OUT).with_suffix(".dir")
    if work.exists():
        shutil.rmtree(work)
    with zipfile.ZipFile(SRC) as z:
        z.extractall(work)

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

    xml = slide_xml()  # fyller LINKS
    (work / "ppt/slides").mkdir(exist_ok=True)
    (work / "ppt/slides/_rels").mkdir(exist_ok=True)
    (work / "ppt/slides/slide1.xml").write_text(xml, encoding="utf-8")
    link_rels = "".join(
        f'<Relationship Id="{rid}" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/hyperlink" Target="{escape(url)}" TargetMode="External"/>'
        for rid, url in LINKS
    )
    (work / "ppt/slides/_rels/slide1.xml.rels").write_text(
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n'
        '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
        '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/slideLayout" Target="../slideLayouts/slideLayout4.xml"/>'
        f"{link_rels}</Relationships>",
        encoding="utf-8",
    )

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
