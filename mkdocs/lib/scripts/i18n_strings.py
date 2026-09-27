#!/usr/bin/env python3
"""
Strengkatalog for portaltekst (mkdocs/lib/i18n/strings.yaml).

Bibliotek:
    from i18n_strings import load_catalog
    catalog = load_catalog()
    catalog.t("section.kom_i_gang", "en")

CLI:
    i18n_strings.py render-sh [--lang <lang>] [--catalog PATH]
        Skriv bash-kode som definerer den assosiative tabellen I18N og
        I18N_LANG (standard: default_language i katalogen). Brukt av
        i18n_load i mkdocs/lib/utils/i18n.sh.
    i18n_strings.py check [--catalog PATH] [--scan-root PATH ...]
        Validerer katalogen (gyldige nøklar, alle språk har verdi) og at alle
        nøklar som vert brukte i scan-røtene finst i katalogen.
    i18n_strings.py languages [--catalog PATH]
        Skriv språkkodane i katalogen, mellomromsseparerte.
    i18n_strings.py render-tree [--lang <lang>] [--catalog PATH] KATALOG ...
        Byt ut @@i18n:<nøkkel>@@-markørar i alle *.md under katalogane (på
        staden). Feilar ved ukjend nøkkel. Brukt av publish.sh for gen-doc-sider.

Sjå specs/backlog/lokalisering-dokumentasjonsportal.md (steg 3).
"""

import argparse
import re
import shlex
import sys
import unicodedata
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
SCAN_SUFFIXES = {".sh", ".py", ".jinja2", ".html"}

KEY_RE = re.compile(r"^[a-z0-9_]+(\.[a-z0-9_]+)+$")
LANG_RE = re.compile(r"^[a-z]{2,3}$")
PLACEHOLDER_RE = re.compile(r"\{[a-z_]+\}")
# Bruksmønster for nøklar per filtype: Jinja-/tekstmarkør overalt, bash-kallet
# `t key` (også inni "$(t key)") i .sh og Python-kallet t("key", ...) i .py.
_KEY = r"([a-z0-9_]+(?:\.[a-z0-9_]+)+)"
_MARKER_RE = re.compile(r"@@i18n:([a-z0-9_.]+)@@")
USAGE_RES = {
    ".sh": [_MARKER_RE, re.compile(r"(?:^|[\s;|&(])t\s+[\"']?" + _KEY)],
    ".py": [_MARKER_RE, re.compile(r"\bt\(\s*[\"']" + _KEY + r"[\"']")],
    ".jinja2": [_MARKER_RE],
    ".html": [_MARKER_RE],
}


class CatalogError(Exception):
    """Katalogen er ugyldig eller manglar ein nøkkel/eit språk."""


class Catalog:
    def __init__(self, languages, default_language, strings, language_names=None):
        self.languages = languages
        self.default_language = default_language
        self.strings = strings
        self.language_names = language_names or {}

    def raw(self, key, lang):
        if lang not in self.languages:
            raise CatalogError(f"ukjent språk '{lang}' (katalogen har: {', '.join(self.languages)})")
        entry = self.strings.get(key)
        if entry is None:
            raise CatalogError(f"i18n-nøkkel manglar i katalogen: '{key}'")
        if lang not in entry:
            raise CatalogError(f"i18n-nøkkel '{key}' manglar verdi for språk '{lang}'")
        return entry[lang]

    def t(self, key, lang, **values):
        """Slå opp og byt ut {navn}-plasshaldarar (ikkje str.format: verdiar
        kan innehalde Markdown-anker som {#classes})."""
        text = self.raw(key, lang)
        # Sjekk malen (ikkje resultatet): innsette verdiar kan sjølve innehalde {...}
        missing = [p for p in PLACEHOLDER_RE.findall(text) if p[1:-1] not in values]
        if missing:
            raise CatalogError(f"i18n-nøkkel '{key}' har plasshaldar utan verdi: {missing[0]} (språk: {lang})")
        for name, value in values.items():
            text = text.replace("{" + name + "}", str(value))
        return text

    def for_lang(self, lang):
        return {key: self.raw(key, lang) for key in sorted(self.strings)}


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
    names = data.get("language_names")
    if not isinstance(names, dict) or any(not isinstance(names.get(l), str) or not names.get(l).strip() for l in languages):
        errors.append("'language_names' må ha eit ikkje-tomt navn for kvart språk i 'languages'")
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
        placeholder_sets = {}
        for lang in languages:
            value = entry.get(lang)
            if not isinstance(value, str) or not value.strip():
                errors.append(f"'{key}': manglar ikkje-tom verdi for språk '{lang}'")
            else:
                placeholder_sets[lang] = set(PLACEHOLDER_RE.findall(value))
        if len({frozenset(s) for s in placeholder_sets.values()}) > 1:
            detail = "; ".join(f"{l}: {' '.join(sorted(s)) or '-'}" for l, s in placeholder_sets.items())
            errors.append(f"'{key}': ulike plasshaldarar mellom språka ({detail})")
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
    return Catalog(data["languages"], data["default_language"], data["strings"], data["language_names"])


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
            for pattern in USAGE_RES.get(path.suffix, [_MARKER_RE]):
                for key in pattern.findall(line):
                    usages.setdefault(key, []).append(f"{path}:{lineno}")
    return usages


def slugify(text):
    """Same slug som mkdocs/Python-Markdown sin toc-standard
    (markdown.extensions.toc.slugify, unicode=False): brukt til faste anker
    lik dagens automatiske anker (O2-a)."""
    text = unicodedata.normalize("NFKD", text).encode("ascii", "ignore").decode("ascii")
    text = re.sub(r"[^\w\s-]", "", text).strip().lower()
    return re.sub(r"[-\s]+", "-", text)


def render_text(catalog, lang, text):
    """Byt ut alle @@i18n:<nøkkel>@@-markørar i text. Ukjend nøkkel gjev CatalogError."""
    return _MARKER_RE.sub(lambda m: catalog.t(m.group(1), lang), text)


def render_sh(catalog, lang):
    lines = ["# Generert av mkdocs/lib/scripts/i18n_strings.py render-sh — ikkje rediger", "declare -gA I18N=("]
    for key, value in catalog.for_lang(lang).items():
        lines.append(f"  [{key}]={shlex.quote(value)}")
    lines += [")", f"I18N_LANG={shlex.quote(lang)}", f"I18N_DEFAULT_LANG={shlex.quote(catalog.default_language)}",
              f"I18N_LANGUAGES={shlex.quote(' '.join(catalog.languages))}",
              "declare -gA I18N_LANGUAGE_NAMES=(" + " ".join(
                  f"[{l}]={shlex.quote(catalog.language_names[l])}" for l in catalog.languages) + ")"]
    return "\n".join(lines) + "\n"


def cmd_render_sh(args):
    catalog = load_catalog(args.catalog)
    lang = args.lang or catalog.default_language
    if lang not in catalog.languages:
        raise CatalogError(f"ukjent språk '{lang}' (katalogen har: {', '.join(catalog.languages)})")
    sys.stdout.write(render_sh(catalog, lang))
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


def cmd_render_tree(args):
    catalog = load_catalog(args.catalog)
    lang = args.lang or catalog.default_language
    changed = 0
    for root in args.paths:
        for path in sorted(Path(root).rglob("*.md")):
            text = path.read_text(encoding="utf-8")
            if "@@i18n:" not in text:
                continue
            try:
                new = render_text(catalog, lang, text)
            except CatalogError as exc:
                raise CatalogError(f"{path}: {exc}") from exc
            if "@@i18n:" in new:
                raise CatalogError(f"{path}: misdanna i18n-markør står att etter utbyting")
            path.write_text(new, encoding="utf-8")
            changed += 1
    print(f"i18n render-tree ({lang}): {changed} filer med markørar bytte ut")
    return 0


def cmd_languages(args):
    print(" ".join(load_catalog(args.catalog).languages))
    return 0


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = parser.add_subparsers(dest="command", required=True)
    p_langs = sub.add_parser("languages", help="skriv språkkodane i katalogen, mellomromsseparerte")
    p_langs.add_argument("--catalog", default=DEFAULT_CATALOG)
    p_render = sub.add_parser("render-sh", help="skriv bash-definisjon av I18N for eitt språk")
    p_render.add_argument("--lang", help="språkkode (standard: default_language i katalogen)")
    p_render.add_argument("--catalog", default=DEFAULT_CATALOG)
    p_tree = sub.add_parser("render-tree", help="byt ut i18n-markørar i *.md under katalogar")
    p_tree.add_argument("--lang", help="språkkode (standard: default_language i katalogen)")
    p_tree.add_argument("--catalog", default=DEFAULT_CATALOG)
    p_tree.add_argument("paths", nargs="+")
    p_check = sub.add_parser("check", help="valider katalogen og nøkkelbruk")
    p_check.add_argument("--catalog", default=DEFAULT_CATALOG)
    p_check.add_argument("--scan-root", action="append", help="fil/katalog å skanne (kan gjentakast)")
    args = parser.parse_args(argv)
    try:
        return {"render-sh": cmd_render_sh, "check": cmd_check, "languages": cmd_languages,
                "render-tree": cmd_render_tree}[args.command](args)
    except CatalogError as exc:
        print(f"[ERROR] {exc}", file=sys.stderr)
        return 1
    except (OSError, UnicodeDecodeError):
        log_error({"step": f"i18n_strings {args.command}"})
        return 1


if __name__ == "__main__":
    sys.exit(main())
