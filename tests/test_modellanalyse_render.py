"""Testar for mkdocs/lib/scripts/modellanalyse_render.py: nynorsk rendering frå
JSON-funna skal gje same tekst som .md-rapportane frå find-similar-names.py og
find-unused-local-definitions.py, og engelsk rendering skal ikkje ha att
nynorsk fasttekst. Sjå specs/done/modellanalyse-rapportar-per-sprak.md."""

import importlib.util
import sys
import types
import unittest
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(REPO_ROOT / "mkdocs" / "lib" / "scripts"))
import modellanalyse_render  # noqa: E402
from i18n_strings import load_catalog  # noqa: E402

SCRIPTS = REPO_ROOT / "src" / "assets" / "scripts" / "makefile"


def _load(name, filename):
    spec = importlib.util.spec_from_file_location(name, SCRIPTS / filename)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


# find-unused-local-definitions.py patchar linkml ved import. Rapportformateringa
# treng ikkje linkml, så patchen vert erstatta med ein tom stubb her.
sys.modules.setdefault("linkml_relative_import_patch", types.SimpleNamespace(apply=lambda: None))
similar = _load("find_similar_names", "find-similar-names.py")
unused = _load("find_unused_local_definitions", "find-unused-local-definitions.py")

CATALOG = load_catalog()
NORSKE_FASTTEKSTAR = ["Liknande", "Ingen ", "Totalt", "Likskap", "Skjema", "Klasse", "Grunn",
                      "Skildring", "sjekka", "funne", "Ubrukte", "Isolerte", "(ingen)",
                      "(inga skildring)", "heilt isolert", "kun tilkopla"]


def _page(title, body):
    return f"# {title}\n\n{body}"


class SimilarTest(unittest.TestCase):
    def cases(self):
        a, b, c = Path("src/linkml/d1/s1/s1-schema.yaml"), Path("src/linkml/d1/s2/s2-schema.yaml"), \
            Path("src/linkml/d2/s3/s3-schema.yaml")
        many = [f"slot{i}" for i in range(15)]
        return {
            "class": [("Person", many, a), ("Personar", [], b), ("Persona", ["x"], c)],
            "slot": [("navn", "string", a), ("navnet", None, b), ("namn", "string", c)],
            "types": [("Dato", "str", a), ("Datoen", None, b)],
        }

    def check(self, kind, entries, scope, target=None, domain=None, threshold=0.8):
        target_path = None
        if target:
            target_path = next(e[2] for e in entries if e[2].parent.name == target[1])
        matches = similar.compute_matches(entries, scope, threshold, target_path=target_path)
        target_label = f"modell {target[0]}/{target[1]}, " if target else ""
        domain_label = f", domene {domain}" if domain else ""
        md = similar.build_report(kind, scope, threshold, entries, matches, target_label, domain_label)
        data = similar.build_report_data(kind, scope, threshold, entries, matches, target=target, domain=domain)
        title, body, count = modellanalyse_render.render(data, CATALOG, "nn")
        self.assertEqual(_page(title, body), md)
        self.assertEqual(count, len(matches))
        title_en, body_en, _ = modellanalyse_render.render(data, CATALOG, "en")
        for word in NORSKE_FASTTEKSTAR:
            self.assertNotIn(word, _page(title_en, body_en), f"{kind}/{scope}: '{word}'")

    def test_all_kinds_and_scopes(self):
        for kind, entries in self.cases().items():
            self.check(kind, entries, "all")
            self.check(kind, entries, "domain", target=("d1", "s1"), domain="d1")

    def test_no_matches(self):
        for kind, entries in self.cases().items():
            self.check(kind, entries, "all", threshold=1.01)


class LocalTest(unittest.TestCase):
    def check(self, kind, items, total):
        md = unused.format_report(kind, "src/linkml/d/s/s-schema.yaml", items, total)
        data = unused.report_data(kind, "src/linkml/d/s/s-schema.yaml", items, total)
        title, body, count = modellanalyse_render.render(data, CATALOG, "nn")
        self.assertEqual(_page(title, body), md)
        self.assertEqual(count, len(items))
        title_en, body_en, _ = modellanalyse_render.render(data, CATALOG, "en")
        for word in NORSKE_FASTTEKSTAR:
            self.assertNotIn(word, _page(title_en, body_en), f"{kind}: '{word}'")

    def test_all_kinds(self):
        for kind in ("slot", "enum", "type", "subset"):
            self.check(kind, [("a", "Ei beskriving"), ("b", "")], 5)
            self.check(kind, [], 5)
        self.check("class", [("A", "", unused.REASON_ISOLATED), ("B", "Tekst", unused.REASON_CONTAINER_ONLY)], 4)
        self.check("class", [], 4)
        self.check("unreachable", [("A", ""), ("B", "Tekst")], 3)
        self.check("unreachable", [], 3)

    def test_unknown_format_fails(self):
        with self.assertRaises(ValueError):
            modellanalyse_render.render({"format": 2}, CATALOG, "nn")


if __name__ == "__main__":
    unittest.main()
