#!/usr/bin/env python3
"""
Strengkatalog for portaltekst (mkdocs/lib/i18n/strings.yaml).

Bibliotek:
    from i18n_strings import load_catalog
    catalog = load_catalog()
    catalog.t("section.kom_i_gang", "en")

CLI:
    i18n_strings.py render-sh --lang <lang> [--catalog PATH]
        Skriv bash-kode som definerer den assosiative tabellen I18N og
        I18N_LANG. Brukt av i18n_load i mkdocs/lib/utils/i18n.sh.
    i18n_strings.py check [--catalog PATH] [--scan-root PATH ...]
        Validerer katalogen (gyldige nøklar, alle språk har verdi) og at alle
        nøklar som vert brukte i scan-røtene finst i katalogen.
    i18n_strings.py languages [--catalog PATH]
        Skriv språkkodane i katalogen, mellomromsseparerte.

Sjå specs/backlog/lokalisering-dokumentasjonsportal.md (steg 3).
"""

import argparse
import re
import shlex
import sys
from pathlib import Path

import yaml

REPO_ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(REPO_ROOT / "src" / "assets" / "scripts"))
from utils.error_handler import log_error  # noqa: E402

DEFAULT_CATALOG = REPO_ROOT / "mkdocs" / "lib" / "i18n" / "strings.yaml"
DEFAULT_SCAN_ROOTS = [
    REPO_ROOT / "mkdocs" / "publish.sh",
    REPO_ROOT / "mkdocs" / "lib",
    REPO_ROOT / "src" / "assets" / "templates" / "docgen",
]
SCAN_SUFFIXES = {".sh", ".py", ".jinja2"}

KEY_RE = re.compile(r"^[a-z0-9_]+(\.[a-z0-9_]+)+$")
LANG_RE = re.compile(r"^[a-z]{2,3}$")
# Bruksmønster for nøklar: Jinja-markør, bash "$(t key)" og Python .t("key", ...)
USAGE_RES = [
    re.compile(r"@@i18n:([a-z0-9_.]+)@@"),
    re.compile(r"\$\(\s*t\s+[\"']?([a-z0-9_]+(?:\.[a-z0-9_]+)+)"),
    re.compile(r"\bt\(\s*[\"']([a-z0-9_]+(?:\.[a-z0-9_]+)+)[\"']"),
]


class CatalogError(Exception):
    """Katalogen er ugyldig eller manglar ein nøkkel/eit språk."""


class Catalog:
    def __init__(self, languages, default_language, strings):
        self.languages = languages
        self.default_language = default_language
        self.strings = strings

    def t(self, key, lang):
        if lang not in self.languages:
            raise CatalogError(f"ukjent språk '{lang}' (katalogen har: {', '.join(self.languages)})")
        entry = self.strings.get(key)
        if entry is None:
            raise CatalogError(f"i18n-nøkkel manglar i katalogen: '{key}'")
        if lang not in entry:
            raise CatalogError(f"i18n-nøkkel '{key}' manglar verdi for språk '{lang}'")
        return entry[lang]

    def for_lang(self, lang):
        return {key: self.t(key, lang) for key in sorted(self.strings)}


def validate(data):
    """Returnerer liste med feilmeldingar for rå katalogdata (tom liste = gyldig)."""
    if not isinstance(data, dict):
        return ["katalogen må vere eit YAML-objekt"]
    errors = []
    languages = data.get("languages")
    if not isinstance(languages, list) or not languages or not all(isinstance(l, str) and LANG_RE.match(l) for l in languages):
        errors.append("'languages' må vere ei ikkje-tom liste med språkkodar (t.d. [nn, en])")
        languages = []
    default = data.get("default_language")
    if default not in languages:
        errors.append(f"'default_language' ({default!r}) må vere eitt av språka i 'languages'")
    strings = data.get("strings")
    if not isinstance(strings, dict):
        return errors + ["'strings' må vere eit objekt med nøklar"]
    for key, entry in strings.items():
        if not isinstance(key, str) or not KEY_RE.match(key):
            errors.append(f"ugyldig nøkkel {key!r}: bruk [a-z0-9_] i minst to punktum-separerte ledd")
            continue
        if not isinstance(entry, dict):
            errors.append(f"'{key}': må vere eit objekt med éin verdi per språk")
            continue
        for lang in languages:
            value = entry.get(lang)
            if not isinstance(value, str) or not value.strip():
                errors.append(f"'{key}': manglar ikkje-tom verdi for språk '{lang}'")
        for extra in sorted(set(entry) - set(languages)):
            errors.append(f"'{key}': ukjent språk '{extra}' (ikkje i 'languages')")
    return errors


def load_catalog(path=DEFAULT_CATALOG):
    path = Path(path)
    try:
        data = yaml.safe_load(path.read_text(encoding="utf-8"))
    except (OSError, yaml.YAMLError) as exc:
        raise CatalogError(f"kan ikkje lese katalogen {path}: {exc}") from exc
    errors = validate(data)
    if errors:
        raise CatalogError(f"ugyldig katalog {path}:\n  - " + "\n  - ".join(errors))
    return Catalog(data["languages"], data["default_language"], data["strings"])


def find_usages(roots):
    """Returnerer {nøkkel: [fil:linje, ...]} for alle nøklar brukte i røtene."""
    usages = {}
    files = []
    for root in roots:
        root = Path(root)
        if root.is_file():
            files.append(root)
        elif root.is_dir():
            files.extend(p for p in sorted(root.rglob("*")) if p.is_file() and p.suffix in SCAN_SUFFIXES)
    for path in files:
        if path.resolve() == Path(__file__).resolve():
            continue  # docstring-døma her er ikkje reell bruk
        for lineno, line in enumerate(path.read_text(encoding="utf-8", errors="replace").splitlines(), 1):
            for pattern in USAGE_RES:
                for key in pattern.findall(line):
                    usages.setdefault(key, []).append(f"{path}:{lineno}")
    return usages


def render_sh(catalog, lang):
    lines = ["# Generert av mkdocs/lib/scripts/i18n_strings.py render-sh — ikkje rediger", "declare -gA I18N=("]
    for key, value in catalog.for_lang(lang).items():
        lines.append(f"  [{key}]={shlex.quote(value)}")
    lines += [")", f"I18N_LANG={shlex.quote(lang)}"]
    return "\n".join(lines) + "\n"


def cmd_render_sh(args):
    catalog = load_catalog(args.catalog)
    if args.lang not in catalog.languages:
        raise CatalogError(f"ukjent språk '{args.lang}' (katalogen har: {', '.join(catalog.languages)})")
    sys.stdout.write(render_sh(catalog, args.lang))
    return 0


def cmd_check(args):
    catalog = load_catalog(args.catalog)
    usages = find_usages(args.scan_root or DEFAULT_SCAN_ROOTS)
    missing = {k: locs for k, locs in usages.items() if k not in catalog.strings}
    for key, locs in sorted(missing.items()):
        print(f"[ERROR] i18n-nøkkel '{key}' manglar i katalogen, brukt i: {', '.join(locs)}", file=sys.stderr)
    print(f"i18n-katalog: {len(catalog.strings)} nøklar, språk {', '.join(catalog.languages)}; "
          f"{len(usages)} nøklar i bruk, {len(missing)} manglar")
    return 1 if missing else 0


def cmd_languages(args):
    print(" ".join(load_catalog(args.catalog).languages))
    return 0


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = parser.add_subparsers(dest="command", required=True)
    p_langs = sub.add_parser("languages", help="skriv språkkodane i katalogen, mellomromsseparerte")
    p_langs.add_argument("--catalog", default=DEFAULT_CATALOG)
    p_render = sub.add_parser("render-sh", help="skriv bash-definisjon av I18N for eitt språk")
    p_render.add_argument("--lang", required=True)
    p_render.add_argument("--catalog", default=DEFAULT_CATALOG)
    p_check = sub.add_parser("check", help="valider katalogen og nøkkelbruk")
    p_check.add_argument("--catalog", default=DEFAULT_CATALOG)
    p_check.add_argument("--scan-root", action="append", help="fil/katalog å skanne (kan gjentakast)")
    args = parser.parse_args(argv)
    try:
        return {"render-sh": cmd_render_sh, "check": cmd_check, "languages": cmd_languages}[args.command](args)
    except CatalogError as exc:
        print(f"[ERROR] {exc}", file=sys.stderr)
        return 1
    except (OSError, UnicodeDecodeError):
        log_error({"step": f"i18n_strings {args.command}"})
        return 1


if __name__ == "__main__":
    sys.exit(main())
