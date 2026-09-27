#!/usr/bin/env python3
"""
Endringsdeteksjon for omsetjingar av portaltekst (steg 9 i
specs/backlog/lokalisering-dokumentasjonsportal.md).

Kvar omsetjing hugsar sha256 av den nynorske originalen ho vart laga frå:

  - Sider (x.<lang>.md ved sida av x.md): front-matter
        ---
        i18n:
          source: x.md
          source_hash: sha256:<hex>
        ---
  - Strengkatalogen: mkdocs/lib/i18n/strings.lock.yaml, per språk og nøkkel
    (hash av den nynorske verdien). Held separat frå strings.yaml, slik at
    stempling ikkje skriv om den handskrivne katalogen (kommentarar/rekkjefølgje).

CLI:
    i18n_status.py status [--strict] [--repo-root DIR]
        List manglande, ustempla og utdaterte omsetjingar. Åtvaringar, exit 0
        (--strict: exit 1 ved utdaterte/ustempla, ikkje ved manglande sider).
    i18n_status.py stamp-page FIL.<lang>.md [--repo-root DIR]
        Set/oppdater front-matter med hash av originalen.
    i18n_status.py stamp-catalog [--lang L] [--keys K ...] [--repo-root DIR]
        Oppdater låsefila: utan --keys berre nøklar utan hash, med --keys dei
        gitte nøklane (etter at omsetjinga er oppdatert).
"""

import argparse
import hashlib
import os
import sys
from pathlib import Path

import yaml

from i18n_strings import CatalogError, load_catalog

sys.path.insert(0, str(Path(__file__).resolve().parents[3] / "src" / "assets" / "scripts"))
from utils.error_handler import log_error  # noqa: E402

DEFAULT_ROOT = Path(__file__).resolve().parents[3]
CATALOG_REL = Path("mkdocs/lib/i18n/strings.yaml")
LOCK_REL = Path("mkdocs/lib/i18n/strings.lock.yaml")
LOCK_HEADER = ("# Generert av mkdocs/lib/scripts/i18n_status.py stamp-catalog — ikkje rediger manuelt.\n"
               "# sha256 av den nynorske verdien då omsetjinga (per språk og nøkkel) sist vart stadfesta.\n")
# Sider i mkdocs/docs som publish.sh genererer (jf. GENERATED_DOCS_PATHS i
# mkdocs/publish.sh) — ikkje omsetjingskjelder.
GENERATED_DOCS_PATHS = ("index.md", "arkitektur/valideringsregler.md", "modellanalyse")


def sha(data):
    if isinstance(data, str):
        data = data.encode("utf-8")
    return "sha256:" + hashlib.sha256(data).hexdigest()


def split_front_matter(text):
    """(front-matter-dict eller None, resten av teksten)."""
    if not text.startswith("---\n"):
        return None, text
    end = text.find("\n---\n", 4)
    if end == -1:
        return None, text
    meta = yaml.safe_load(text[4:end]) or {}
    if not isinstance(meta, dict):
        return None, text
    return meta, text[end + 5:]


def translation_sources(root, languages):
    """Alle handskrivne kjeldesider (standardspråket) som kan ha x.<lang>.md."""
    root = Path(root)
    domains = {p.name for p in (root / "src/linkml").iterdir() if p.is_dir()} if (root / "src/linkml").is_dir() else set()
    sources = [root / "README.md", root / "src/mcp-linkml-validator/policies/README.md"]
    sources += sorted((root / "src/linkml").glob("*/description.md"))
    docs = root / "mkdocs/docs"
    for p in sorted(docs.rglob("*.md")) if docs.is_dir() else []:
        rel = p.relative_to(docs).as_posix()
        top = rel.split("/", 1)[0]
        if top in domains or any(rel == g or rel.startswith(g + "/") for g in GENERATED_DOCS_PATHS):
            continue
        if any(rel.endswith(f".{l}.md") for l in languages):
            continue
        sources.append(p)
    return [s for s in sources if s.is_file()]


def variant_path(source, lang):
    return source.with_name(source.name[:-3] + f".{lang}.md")


def load_lock(root):
    path = Path(root) / LOCK_REL
    if not path.is_file():
        return {}
    data = yaml.safe_load(path.read_text(encoding="utf-8")) or {}
    if not isinstance(data, dict):
        raise CatalogError(f"{path}: må vere eit objekt per språk")
    return data


def write_lock(root, lock):
    body = yaml.safe_dump({l: dict(sorted(v.items())) for l, v in sorted(lock.items())},
                          allow_unicode=True, sort_keys=False, default_flow_style=False)
    (Path(root) / LOCK_REL).write_text(LOCK_HEADER + body, encoding="utf-8")


def status(root, strict=False, out=sys.stdout):
    root = Path(root)
    catalog = load_catalog(root / CATALOG_REL)
    lock = load_lock(root)
    others = [l for l in catalog.languages if l != catalog.default_language]
    problems = 0
    for lang in others:
        # Katalogen
        stale, unstamped = [], []
        for key in sorted(catalog.strings):
            current = sha(catalog.raw(key, catalog.default_language))
            stamped = (lock.get(lang) or {}).get(key)
            if stamped is None:
                unstamped.append(key)
            elif stamped != current:
                stale.append(key)
        orphan = sorted(set(lock.get(lang) or {}) - set(catalog.strings))
        # Sidene
        missing, page_stale, page_unstamped, ok = [], [], [], 0
        for src in translation_sources(root, catalog.languages):
            var = variant_path(src, lang)
            rel = var.relative_to(root).as_posix()
            if not var.is_file():
                missing.append(src.relative_to(root).as_posix())
                continue
            meta, _ = split_front_matter(var.read_text(encoding="utf-8"))
            stamped = ((meta or {}).get("i18n") or {}).get("source_hash")
            if not stamped:
                page_unstamped.append(rel)
            elif stamped != sha(src.read_bytes()):
                page_stale.append(rel)
            else:
                ok += 1
        print(f"i18n-status ({lang}):", file=out)
        print(f"  katalog: {len(catalog.strings)} nøklar, {len(stale)} utdaterte, {len(unstamped)} ustempla"
              + (f", {len(orphan)} foreldrelause i låsefila" if orphan else ""), file=out)
        print(f"  sider: {ok} omsette og oppdaterte, {len(page_stale)} utdaterte, {len(page_unstamped)} ustempla, "
              f"{len(missing)} manglar", file=out)
        for label, items in (("utdatert nøkkel", stale), ("ustempla nøkkel", unstamped),
                             ("foreldrelaus nøkkel i låsefila", orphan), ("utdatert side", page_stale),
                             ("ustempla side", page_unstamped)):
            for item in items:
                print(f"  [ÅTVARING] {label}: {item}", file=out)
        for item in missing:
            print(f"  manglar: {item}", file=out)
        problems += len(stale) + len(unstamped) + len(page_stale) + len(page_unstamped)
    return 1 if strict and problems else 0


def stamp_page(root, variant):
    root = Path(root)
    variant = Path(variant)
    if not variant.is_absolute():
        variant = root / variant
    name = variant.name
    parts = name.split(".")
    if len(parts) < 3 or parts[-1] != "md":
        raise CatalogError(f"{variant}: forventa x.<lang>.md")
    text = variant.read_text(encoding="utf-8")
    meta, body = split_front_matter(text)
    meta = meta or {}
    i18n = meta.get("i18n") or {}
    source = variant.with_name(".".join(parts[:-2]) + ".md")
    if i18n.get("source"):
        source = variant.parent / i18n["source"]
    if not source.is_file():
        raise CatalogError(f"{variant}: originalen {source} finst ikkje")
    i18n["source"] = Path(os.path.relpath(source, variant.parent)).as_posix()
    i18n["source_hash"] = sha(source.read_bytes())
    meta["i18n"] = i18n
    fm = yaml.safe_dump(meta, allow_unicode=True, sort_keys=False, default_flow_style=False)
    variant.write_text(f"---\n{fm}---\n{body}", encoding="utf-8")
    print(f"stempla {variant.relative_to(root)} mot {source.relative_to(root)}")


def stamp_catalog(root, lang=None, keys=None):
    root = Path(root)
    catalog = load_catalog(root / CATALOG_REL)
    langs = [lang] if lang else [l for l in catalog.languages if l != catalog.default_language]
    lock = load_lock(root)
    for l in langs:
        if l not in catalog.languages or l == catalog.default_language:
            raise CatalogError(f"ugyldig språk for stempling: {l!r}")
        entries = lock.setdefault(l, {})
        targets = keys if keys else [k for k in catalog.strings if k not in entries]
        for key in targets:
            if key not in catalog.strings:
                raise CatalogError(f"ukjend nøkkel: {key}")
            entries[key] = sha(catalog.raw(key, catalog.default_language))
        print(f"stempla {len(targets)} nøklar for {l}")
    write_lock(root, lock)


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--repo-root", default=DEFAULT_ROOT, type=Path)
    sub = ap.add_subparsers(dest="command", required=True)
    p = sub.add_parser("status", help="list manglande/utdaterte omsetjingar")
    p.add_argument("--strict", action="store_true")
    p = sub.add_parser("stamp-page", help="stempla ei omsett side")
    p.add_argument("file")
    p = sub.add_parser("stamp-catalog", help="stempla katalognøklar i låsefila")
    p.add_argument("--lang")
    p.add_argument("--keys", nargs="+")
    args = ap.parse_args(argv)
    try:
        if args.command == "status":
            return status(args.repo_root, args.strict)
        if args.command == "stamp-page":
            stamp_page(args.repo_root, args.file)
        else:
            stamp_catalog(args.repo_root, args.lang, args.keys)
        return 0
    except CatalogError as exc:
        print(f"[ERROR] {exc}", file=sys.stderr)
        return 1
    except (OSError, yaml.YAMLError):
        log_error({"step": f"i18n_status {args.command}"})
        return 1


if __name__ == "__main__":
    sys.exit(main())
