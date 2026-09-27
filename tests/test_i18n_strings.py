#!/usr/bin/env python3
"""Automatiske testar for mkdocs/lib/scripts/i18n_strings.py (strengkatalogen).

Køyr frå repo-rot i python-pytest-kontaineren:
  podman run --rm -v "$PWD:/work" -w /work localhost/python-pytest:latest \
      python3 -m pytest tests/test_i18n_strings.py -v

bash-lastaren (mkdocs/lib/utils/i18n.sh) vert røyktesta av `make i18n-check`,
sidan python-pytest-imaget ikkje har bash.
Sjå specs/backlog/lokalisering-dokumentasjonsportal.md (steg 3).
"""

import shlex
import subprocess
import sys
import tempfile
import textwrap
import unittest
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
SCRIPT = REPO_ROOT / "mkdocs" / "lib" / "scripts" / "i18n_strings.py"
sys.path.insert(0, str(SCRIPT.parent))
import i18n_strings  # noqa: E402

VALID = """
languages: [nn, en]
default_language: nn
strings:
  section.kom_i_gang:
    nn: Kom i gang
    en: Getting started
  table.sitat:
    nn: "Han sa 'hei' og $HOME `ls`"
    en: It's "quoted"
"""


def run(*args):
    return subprocess.run([sys.executable, str(SCRIPT), *args], capture_output=True, text=True)


class TmpCase(unittest.TestCase):
    def setUp(self):
        self._tmp = tempfile.TemporaryDirectory()
        self.tmp = Path(self._tmp.name)

    def tearDown(self):
        self._tmp.cleanup()

    def write(self, name, content):
        path = self.tmp / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(textwrap.dedent(content), encoding="utf-8")
        return path


class TestRepoCatalog(unittest.TestCase):
    def test_repo_catalog_passes_check(self):
        """Den faktiske katalogen og all nøkkelbruk i repoet skal vere konsistent."""
        result = run("check")
        self.assertEqual(result.returncode, 0, msg=result.stderr)


class TestValidation(TmpCase):
    def test_valid_catalog_loads(self):
        catalog = i18n_strings.load_catalog(self.write("s.yaml", VALID))
        self.assertEqual(catalog.t("section.kom_i_gang", "en"), "Getting started")

    def test_missing_language_value_fails(self):
        path = self.write("s.yaml", VALID.replace("    en: Getting started\n", ""))
        result = run("check", "--catalog", str(path), "--scan-root", str(self.tmp))
        self.assertEqual(result.returncode, 1)
        self.assertIn("'section.kom_i_gang': manglar ikkje-tom verdi for språk 'en'", result.stderr)

    def test_unknown_language_fails(self):
        path = self.write("s.yaml", VALID.replace("    en: Getting started\n", "    en: Getting started\n    de: Los\n"))
        result = run("check", "--catalog", str(path), "--scan-root", str(self.tmp))
        self.assertEqual(result.returncode, 1)
        self.assertIn("ukjent språk 'de'", result.stderr)

    def test_invalid_key_fails(self):
        path = self.write("s.yaml", VALID.replace("section.kom_i_gang:", "Kom-i-gang:"))
        result = run("check", "--catalog", str(path), "--scan-root", str(self.tmp))
        self.assertEqual(result.returncode, 1)
        self.assertIn("ugyldig nøkkel 'Kom-i-gang'", result.stderr)

    def test_default_language_must_be_listed(self):
        path = self.write("s.yaml", VALID.replace("default_language: nn", "default_language: nb"))
        with self.assertRaises(i18n_strings.CatalogError):
            i18n_strings.load_catalog(path)

    def test_missing_key_raises(self):
        catalog = i18n_strings.load_catalog(self.write("s.yaml", VALID))
        with self.assertRaises(i18n_strings.CatalogError):
            catalog.t("finst.ikkje", "nn")


class TestUsageScan(TmpCase):
    def test_all_usage_forms_are_detected(self):
        catalog = self.write("s.yaml", VALID)
        self.write("src/a.jinja2", "## @@i18n:section.kom_i_gang@@ {#kom-i-gang}\n")
        self.write("src/b.sh", 'heading=$(t section.kom_i_gang)\necho "$(t "table.sitat")"\n')
        self.write("src/c.py", 'catalog.t("table.sitat", lang)\n')
        self.write("src/d.sh", '    felles) t section.kom_i_gang; echo ;;\n')
        result = run("check", "--catalog", str(catalog), "--scan-root", str(self.tmp / "src"))
        self.assertEqual(result.returncode, 0, msg=result.stderr)
        self.assertIn("2 nøklar i bruk, 0 manglar", result.stdout)

    def test_bare_bash_call_with_unknown_key_fails(self):
        catalog = self.write("s.yaml", VALID)
        self.write("src/d.sh", '    felles) t domene.finst_ikkje; echo ;;\n')
        result = run("check", "--catalog", str(catalog), "--scan-root", str(self.tmp / "src"))
        self.assertEqual(result.returncode, 1)
        self.assertIn("'domene.finst_ikkje' manglar i katalogen", result.stderr)

    def test_placeholders_must_match_across_languages(self):
        path = self.write("s.yaml", VALID.replace("en: Getting started", "en: Getting started {x}"))
        result = run("check", "--catalog", str(path), "--scan-root", str(self.tmp))
        self.assertEqual(result.returncode, 1)
        self.assertIn("ulike plasshaldarar", result.stderr)

    def test_placeholder_substitution(self):
        catalog = i18n_strings.load_catalog(self.write("s.yaml", VALID.replace(
            "nn: Kom i gang", "nn: Kom i gang med {x} {#anker}").replace("en: Getting started", "en: Start {x} {#anker}")))
        self.assertEqual(catalog.t("section.kom_i_gang", "nn", x="LinkML"), "Kom i gang med LinkML {#anker}")
        with self.assertRaises(i18n_strings.CatalogError):
            catalog.t("section.kom_i_gang", "nn")

    def test_unknown_key_in_use_fails(self):
        catalog = self.write("s.yaml", VALID)
        self.write("src/a.jinja2", "### @@i18n:table.finst_ikkje@@\n")
        self.write("src/b.sh", "x=$(t section.finst_ikkje)\n")
        result = run("check", "--catalog", str(catalog), "--scan-root", str(self.tmp / "src"))
        self.assertEqual(result.returncode, 1)
        self.assertIn("'table.finst_ikkje' manglar i katalogen", result.stderr)
        self.assertIn("'section.finst_ikkje' manglar i katalogen", result.stderr)
        self.assertIn("a.jinja2:1", result.stderr)


class TestRenderSh(TmpCase):
    def test_render_quotes_special_characters(self):
        catalog = i18n_strings.load_catalog(self.write("s.yaml", VALID))
        out = i18n_strings.render_sh(catalog, "nn")
        self.assertIn("declare -gA I18N=(", out)
        self.assertIn(f"[table.sitat]={shlex.quote(catalog.t('table.sitat', 'nn'))}", out)
        self.assertIn("I18N_LANG=nn", out)

    def test_render_unknown_language_fails(self):
        path = self.write("s.yaml", VALID)
        result = run("render-sh", "--lang", "de", "--catalog", str(path))
        self.assertEqual(result.returncode, 1)
        self.assertIn("ukjent språk 'de'", result.stderr)


if __name__ == "__main__":
    unittest.main()
