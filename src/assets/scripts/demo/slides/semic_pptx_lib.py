"""Delt kode for scriptene som byggjer éi PowerPoint-slide frå SEMIC 2026-malen.

Berre stdlib; skriv OOXML direkte. Brukt av `semic-mcp-pptx.py`. (`semic-tooling-pptx.py`
og `semic-findings-pptx.py` har framleis eigne kopiar av same kode; flytting dit
krev eksplisitt løyve, jf. DRY-regelen i CLAUDE.md.)

Bruk frå eit script (køyrt med `python3 -I`, som ikkje legg scriptmappa på sys.path):
    sys.path.insert(0, str(Path(__file__).resolve().parent))
    import semic_pptx_lib as L
"""
import re
import shutil
import sys
import zipfile
from pathlib import Path
from xml.sax.saxutils import escape

BLUE, PURPLE, PINK, WHITE, INK, TINT, ICE = "3633D1", "9E2FD5", "C58BD8", "FFFFFF", "0B0C12", "ECF0FB", "CADCFC"

_id = [10]
LINKS = []  # (rId, url)


def nid():
    _id[0] += 1
    return _id[0]


def fill(c, alpha=None):
    a = f'<a:alpha val="{alpha}"/>' if alpha is not None else ""
    return f'<a:solidFill><a:srgbClr val="{c}">{a}</a:srgbClr></a:solidFill>'


def line(c=None, w=12700, alpha=None):
    if c is None:
        return "<a:ln><a:noFill/></a:ln>"
    return f'<a:ln w="{w}">{fill(c, alpha)}</a:ln>'


def run(text, sz, color, bold=False, link=None, font=None):
    h = ""
    if link:
        rid = f"rId{len(LINKS) + 2}"  # rId1 = layout
        LINKS.append((rid, link))
        h = f'<a:hlinkClick r:id="{rid}"/>'
    u = ' u="sng"' if link else ""
    f = f'<a:latin typeface="{font}"/>' if font else ""
    return (
        f'<a:r><a:rPr lang="en-GB" sz="{sz}" b="{int(bold)}"{u} dirty="0">{fill(color)}{f}{h}</a:rPr>'
        f"<a:t>{escape(text)}</a:t></a:r>"
    )


def box(name, x, y, w, h, paras=(), prst="rect", f=None, ln=None, anchor="t", inset=0, rot=0):
    """Form med valfri tekst. paras: liste av (algn, [run-xml, ...]). f=None gir tekstboks utan fyll."""
    body = "".join(f'<a:p><a:pPr algn="{a}"/>{"".join(rs)}</a:p>' for a, rs in paras) or '<a:p><a:endParaRPr lang="en-GB"/></a:p>'
    adj = '<a:gd name="adj" fmla="val 9000"/>' if prst == "roundRect" else ""
    r = f' rot="{int(rot * 60000)}"' if rot else ""
    tx = "1" if (f is None and paras) else "0"
    return (
        f'<p:sp><p:nvSpPr><p:cNvPr id="{nid()}" name="{escape(name)}"/><p:cNvSpPr txBox="{tx}"/><p:nvPr/></p:nvSpPr>'
        f'<p:spPr><a:xfrm{r}><a:off x="{int(x)}" y="{int(y)}"/><a:ext cx="{int(w)}" cy="{int(h)}"/></a:xfrm>'
        f'<a:prstGeom prst="{prst}"><a:avLst>{adj}</a:avLst></a:prstGeom>{f or "<a:noFill/>"}{ln or line()}</p:spPr>'
        f'<p:txBody><a:bodyPr wrap="square" lIns="{inset}" tIns="{inset}" rIns="{inset}" bIns="{inset}" rtlCol="0" anchor="{anchor}"><a:noAutofit/></a:bodyPr>'
        f"<a:lstStyle/>{body}</p:txBody></p:sp>"
    )


def connector(name, x1, y1, x2, y2, c, w=19050, alpha=None):
    flip = (' flipH="1"' if x2 < x1 else "") + (' flipV="1"' if y2 < y1 else "")
    return (
        f'<p:cxnSp><p:nvCxnSpPr><p:cNvPr id="{nid()}" name="{escape(name)}"/><p:cNvCxnSpPr/><p:nvPr/></p:nvCxnSpPr>'
        f'<p:spPr><a:xfrm{flip}><a:off x="{int(min(x1, x2))}" y="{int(min(y1, y2))}"/><a:ext cx="{int(abs(x2 - x1))}" cy="{int(abs(y2 - y1))}"/></a:xfrm>'
        f'<a:prstGeom prst="line"><a:avLst/></a:prstGeom>{line(c, w, alpha)}</p:spPr></p:cxnSp>'
    )


def title_ph(text, sz=2800, x=3500000, y=300000, w=8100000, h=900000):
    return (
        '<p:sp><p:nvSpPr><p:cNvPr id="2" name="Title 1"/><p:cNvSpPr><a:spLocks noGrp="1"/></p:cNvSpPr><p:nvPr><p:ph type="title"/></p:nvPr></p:nvSpPr>'
        f'<p:spPr><a:xfrm><a:off x="{x}" y="{y}"/><a:ext cx="{w}" cy="{h}"/></a:xfrm></p:spPr>'
        '<p:txBody><a:bodyPr anchor="ctr"><a:normAutofit/></a:bodyPr><a:lstStyle/><a:p><a:pPr algn="l"/>'
        f'<a:r><a:rPr lang="en-GB" sz="{sz}" dirty="0">{fill(INK)}</a:rPr><a:t>{escape(text)}</a:t></a:r></a:p></p:txBody></p:sp>'
    )


def slide_xml(title, shapes):
    return (
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n'
        '<p:sld xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" '
        'xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" '
        'xmlns:p="http://schemas.openxmlformats.org/presentationml/2006/main"><p:cSld><p:spTree>'
        '<p:nvGrpSpPr><p:cNvPr id="1" name=""/><p:cNvGrpSpPr/><p:nvPr/></p:nvGrpSpPr>'
        '<p:grpSpPr><a:xfrm><a:off x="0" y="0"/><a:ext cx="0" cy="0"/><a:chOff x="0" y="0"/><a:chExt cx="0" cy="0"/></a:xfrm></p:grpSpPr>'
        f"{title}{shapes}</p:spTree></p:cSld><p:clrMapOvr><a:masterClrMapping/></p:clrMapOvr></p:sld>"
    )


def build_deck(src, out, xml, layout="slideLayout4.xml"):
    """Pakk malen om til ei fil med berre denne slida (layout «Content» som standard)."""
    work = Path(out).with_suffix(".dir")
    if work.exists():
        shutil.rmtree(work)
    with zipfile.ZipFile(src) as z:
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
        f'<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/slideLayout" Target="../slideLayouts/{layout}"/>'
        f"{link_rels}</Relationships>",
        encoding="utf-8",
    )
    files = sorted(p for p in work.rglob("*") if p.is_file())
    rel = lambda p: p.relative_to(work).as_posix()
    names = ["[Content_Types].xml"] + [rel(p) for p in files if rel(p) != "[Content_Types].xml"]
    Path(out).unlink(missing_ok=True)
    with zipfile.ZipFile(out, "w", zipfile.ZIP_DEFLATED) as z:
        for n in names:
            z.write(work / n, n)
    shutil.rmtree(work)
    print("skreiv", out)
