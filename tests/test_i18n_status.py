#!/usr/bin/env python3
"""Automatiske testar for mkdocs/lib/scripts/i18n_status.py (endringsdeteksjon
for omsetjingar). Køyrd av `make i18n-check` i python-pytest-kontaineren.
Sjå specs/done/lokalisering-dokumentasjonsportal.md (steg 9).
"""

import io
import sys
import tempfile
import unittest
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(REPO_ROOT / "mkdocs" / "lib" / "scripts"))
import i18n_status  # noqa: E402

CATALOG = """
languages: [nn, en]
default_language: nn
language_names: {nn: Nynorsk, en: English}
strings:
  a.tittel:
    nn: Tittel
    en: Title
"""


class StatusCase(unittest.TestCase):
    def setUp(self):
        self._tmp = tempfile.TemporaryDirectory()
        self.root = Path(self._tmp.name)
        (self.root / "mkdocs/lib/i18n").mkdir(parents=True)
        (self.root / "mkdocs/lib/i18n/strings.yaml").write_text(CATALOG, encoding="utf-8")
        (self.root / "mkdocs/docs/kom-i-gang").mkdir(parents=True)
        (self.root / "mkdocs/docs/kom-i-gang/side.md").write_text("# Side\n\nTekst\n", encoding="utf-8")
        (self.root / "mkdocs/docs/index.md").write_text("# Generert\n", encoding="utf-8")  # generert, ikkje kjelde
        (self.root / "src/linkml/felles").mkdir(parents=True)
        (self.root / "mkdocs/docs/felles").mkdir()
        (self.root / "mkdocs/docs/felles/x.md").write_text("# Domeneside\n", encoding="utf-8")  # generert domene
        (self.root / "README.md").write_text("# Readme\n", encoding="utf-8")

    def tearDown(self):
        self._tmp.cleanup()

    def status(self, strict=False):
        buf = io.StringIO()
        rc = i18n_status.status(self.root, strict, out=buf)
        return rc, buf.getvalue()

    def test_sources_exclude_generated_pages(self):
        srcs = {p.relative_to(self.root).as_posix() for p in i18n_status.translation_sources(self.root, ["nn", "en"])}
        self.assertEqual(srcs, {"README.md", "mkdocs/docs/kom-i-gang/side.md"})

    def test_missing_and_unstamped(self):
        rc, out = self.status(strict=True)
        self.assertEqual(rc, 1)  # katalognøkkelen er ustempla
        self.assertIn("1 ustempla", out)
        self.assertIn("manglar: mkdocs/docs/kom-i-gang/side.md", out)

    def test_stamp_catalog_then_stale_on_change(self):
        i18n_status.stamp_catalog(self.root)
        rc, out = self.status(strict=True)
        self.assertEqual(rc, 0, out)
        cat = self.root / "mkdocs/lib/i18n/strings.yaml"
        cat.write_text(CATALOG.replace("nn: Tittel", "nn: Ny tittel"), encoding="utf-8")
        rc, out = self.status(strict=True)
        self.assertEqual(rc, 1)
        self.assertIn("utdatert nøkkel: a.tittel", out)
        i18n_status.stamp_catalog(self.root, keys=["a.tittel"])
        self.assertEqual(self.status(strict=True)[0], 0)

    def test_stamp_page_then_stale_on_change(self):
        i18n_status.stamp_catalog(self.root)
        var = self.root / "mkdocs/docs/kom-i-gang/side.en.md"
        var.write_text("# Page\n\nText\n", encoding="utf-8")
        rc, out = self.status(strict=True)
        self.assertIn("ustempla side: mkdocs/docs/kom-i-gang/side.en.md", out)
        i18n_status.stamp_page(self.root, var)
        meta, body = i18n_status.split_front_matter(var.read_text(encoding="utf-8"))
        self.assertEqual(meta["i18n"]["source"], "side.md")
        self.assertEqual(body, "# Page\n\nText\n")
        rc, out = self.status(strict=True)
        self.assertEqual(rc, 0, out)
        self.assertIn("1 omsette og oppdaterte", out)
        (self.root / "mkdocs/docs/kom-i-gang/side.md").write_text("# Side\n\nEndra tekst\n", encoding="utf-8")
        rc, out = self.status(strict=True)
        self.assertEqual(rc, 1)
        self.assertIn("utdatert side: mkdocs/docs/kom-i-gang/side.en.md", out)

    def test_non_strict_always_zero(self):
        self.assertEqual(self.status(strict=False)[0], 0)


if __name__ == "__main__":
    unittest.main()
