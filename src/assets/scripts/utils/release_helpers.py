#!/usr/bin/env python3
"""Delte hjelpefunksjonar for release-please-relaterte script."""

import json
import subprocess
import sys
from pathlib import Path

# Flytta frå rota til .github/ i 1f76478d (2026-07-28), sjå
# specs/done/fjern-update-modellkatalog.md (K2).
RELEASE_MANIFEST_PATH = ".github/release-please-manifest.json"


def find_released_packages(config: dict) -> list[str]:
    """Finn pakkar som endra versjon mellom HEAD~1 og HEAD ved å samanlikne manifest."""
    try:
        old_json = subprocess.check_output(
            ["git", "show", f"HEAD~1:{RELEASE_MANIFEST_PATH}"],
            stderr=subprocess.DEVNULL,
        ).decode()
        old = json.loads(old_json)
    except Exception as e:
        print(f"INFO: fann ikkje HEAD~1:{RELEASE_MANIFEST_PATH} ({e}) — behandlar alle pakkar som nye", file=sys.stderr)
        old = {}

    try:
        new = json.loads(Path(RELEASE_MANIFEST_PATH).read_text())
    except Exception as e:
        print(f"FEIL: kunne ikkje lese {RELEASE_MANIFEST_PATH}: {e}", file=sys.stderr)
        return []

    return [p for p in new if old.get(p) != new[p] and p in config.get("packages", {})]
