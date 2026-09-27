#!/usr/bin/env python3
"""
Byggjer byggjetre per språk for adressestrukturen L2 (O6 i
specs/done/lokalisering-dokumentasjonsportal.md):

  <out>/<lang>/   sider (*.md) og felles ressursar (stylesheets o.l.) per språk,
                  med relative lenkjer til artefakter omskrivne til rot-stien
  <out>/rot/      artefakter (alle ikkje-.md-filer under domenekatalogane) på
                  dagens sti utan språkprefiks (A0), vidaresendingssider for
                  gamle sideadresser og rot-vidaresending til /<standardspråk>/

Kjeldetrea er ferdig genererte docs-tre per språk (mkdocs/docs for
standardspråket, mkdocs/build/src-<lang> for andre). Språkvariantar
(x.<lang>.md) i kjeldetrea vert ikkje med i byggjetrea — dei er alt valde
ved generering av arbeidstreet for språket.

Lenkjeomskriving: mkdocs brukar use_directory_urls, så sida x/y.md vert
/<lang>/x/y/ og x/index.md vert /<lang>/x/. Lenkjer til filer utanfor
docs_dir vert ikkje justerte av mkdocs, så den relative stien vert rekna ut
frå sideadressa her. Kvar omskriven lenkje vert kontrollert mot rot-treet.

Bruk:
    build_language_trees.py --default nn --source nn=mkdocs/docs \\
        --source en=mkdocs/build/src-en --domains felles ap-no ... --out mkdocs/build

Berre stdlib (køyrer med verts-python3 frå publish.sh).
"""

import argparse
import html
import posixpath
import re
import shutil
import sys
from pathlib import Path, PurePosixPath

sys.path.insert(0, str(Path(__file__).resolve().parents[3] / "src" / "assets" / "scripts"))
from utils.error_handler import log_error  # noqa: E402

# Relative mål i Markdown-lenkjer/-bilete og i HTML src/href
LINK_RE = re.compile(r'(\]\(|\b(?:src|href)=")(?![a-zA-Z][a-zA-Z0-9+.-]*:|#|/)([^)"\s]+)')


class TreeError(Exception):
    pass


def page_dir(md_rel):
    """Adressekatalogen (relativ til språkrota) for ei .md-side."""
    p = PurePosixPath(md_rel)
    return p.parent if p.name == "index.md" else p.parent / p.stem


def is_language_variant(rel, languages):
    return any(rel.endswith(f".{lang}.md") for lang in languages)


def classify(source, domains):
    """Del filene i kjeldetreet i (sider/ressursar, artefakter)."""
    pages, artefacts = [], []
    for path in sorted(p for p in source.rglob("*") if p.is_file()):
        rel = path.relative_to(source).as_posix()
        top = rel.split("/", 1)[0]
        if top in domains and "/" in rel and not rel.endswith(".md"):
            artefacts.append(rel)
        else:
            pages.append(rel)
    return pages, artefacts


def rewrite_links(text, md_rel, artefact_set, rot):
    """Skriv om relative lenkjer frå sida md_rel til artefakter på rot-stien."""
    src_dir = posixpath.dirname(md_rel)
    depth = len(page_dir(md_rel).parts)
    count = 0

    def sub(m):
        nonlocal count
        target = m.group(2)
        path, sep, frag = target.partition("#")
        resolved = posixpath.normpath(posixpath.join(src_dir, html.unescape(path)))
        if resolved not in artefact_set:
            return m.group(0)
        new_target = "../" * (depth + 1) + resolved
        # Kontroll: den nye lenkja frå /<lang>/<sidekatalog>/ må treffe rot-treet
        landed = posixpath.normpath(posixpath.join("_lang", str(page_dir(md_rel)), new_target))
        if not (rot / landed).is_file():
            raise TreeError(f"{md_rel}: omskriven lenkje {new_target} treffer ikkje {landed} i rot-treet")
        count += 1
        return m.group(1) + new_target + (sep + frag if sep else "")

    return LINK_RE.sub(sub, text), count


def redirect_html(target):
    t = html.escape(target, quote=True)
    return (f'<!doctype html><html><head><meta charset="utf-8"><title>{t}</title>'
            f'<link rel="canonical" href="{t}"><meta http-equiv="refresh" content="0; url={t}">'
            f'<script>location.replace("{t}" + location.hash)</script></head>'
            f'<body><a href="{t}">{t}</a></body></html>\n')


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--default", required=True, help="standardspråket (får vidaresendingar frå gamle adresser)")
    ap.add_argument("--source", action="append", required=True, metavar="LANG=DIR")
    ap.add_argument("--domains", nargs="+", required=True)
    ap.add_argument("--out", required=True)
    args = ap.parse_args(argv)

    sources = {}
    for spec in args.source:
        lang, _, d = spec.partition("=")
        if not d or not Path(d).is_dir():
            print(f"[ERROR] ugyldig --source {spec!r} (katalogen finst ikkje)", file=sys.stderr)
            return 1
        sources[lang] = Path(d)
    if args.default not in sources:
        print(f"[ERROR] standardspråket {args.default!r} manglar i --source", file=sys.stderr)
        return 1
    languages = list(sources)
    domains = set(args.domains)
    out = Path(args.out)
    rot = out / "rot"

    try:
        # 1) rot/: artefakter frå standardspråket sitt kjeldetre
        if rot.exists():
            shutil.rmtree(rot)
        _, artefacts = classify(sources[args.default], domains)
        for rel in artefacts:
            dst = rot / rel
            dst.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(sources[args.default] / rel, dst)
        artefact_set = set(artefacts)
        # Kontroll-lenkjene vert rekna frå ein tenkt språkkatalog "_lang" under rot
        (rot / "_lang").mkdir(parents=True, exist_ok=True)

        # 2) <lang>/: sider og ressursar, lenkjer til artefakter omskrivne
        stats = {}
        default_pages = []
        for lang, src in sources.items():
            dst_root = out / lang
            if dst_root.exists():
                shutil.rmtree(dst_root)
            pages, lang_artefacts = classify(src, domains)
            missing = sorted(set(lang_artefacts) - artefact_set)
            if missing:
                raise TreeError(f"{lang}: artefakter som ikkje finst i standardspråket: {missing[:5]}")
            n_pages = n_links = 0
            for rel in pages:
                if is_language_variant(rel, languages):
                    continue
                dst = dst_root / rel
                dst.parent.mkdir(parents=True, exist_ok=True)
                if rel.endswith(".md"):
                    text = (src / rel).read_text(encoding="utf-8")
                    text, c = rewrite_links(text, rel, artefact_set, rot)
                    dst.write_text(text, encoding="utf-8")
                    n_pages += 1
                    n_links += c
                    if lang == args.default:
                        default_pages.append(rel)
                else:
                    shutil.copy2(src / rel, dst)
            stats[lang] = (n_pages, n_links)
        shutil.rmtree(rot / "_lang")

        # 3) rot/: vidaresendingssider for gamle adresser + rot-vidaresending
        n_redirects = 0
        seen = set()
        for rel in default_pages:
            pdir = page_dir(rel)
            if pdir in seen:
                continue  # x.md og x/index.md gjev same adresse
            seen.add(pdir)
            stub = rot / pdir / "index.html"
            if stub.exists():
                raise TreeError(f"vidaresendingsside kolliderer med artefakt: {stub.relative_to(out)}")
            target = "../" * len(pdir.parts) + f"{args.default}/" + (f"{pdir.as_posix()}/" if pdir.parts else "")
            stub.parent.mkdir(parents=True, exist_ok=True)
            stub.write_text(redirect_html(target), encoding="utf-8")
            n_redirects += 1
    except TreeError as exc:
        print(f"[ERROR] build_language_trees: {exc}", file=sys.stderr)
        return 1
    except OSError:
        log_error({"step": "build_language_trees", "out": str(out)})
        return 1

    for lang, (n_pages, n_links) in stats.items():
        print(f"{lang}: {n_pages} sider, {n_links} artefaktlenkjer omskrivne")
    print(f"rot: {len(artefacts)} artefakter, {n_redirects} vidaresendingssider")
    return 0


if __name__ == "__main__":
    sys.exit(main())
