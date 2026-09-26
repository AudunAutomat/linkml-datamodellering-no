"""
Delt org-/skjemaoppslagslogikk for modellkatalog-skript.

Flytta frå src/assets/scripts/makefile/update-modellkatalog.py (sletta —
erstatta av generate-modellkatalog.py / `make gen-modellkatalog-instance`),
sjå specs/done/fjern-update-modellkatalog.md. Brukt av
gen-modelldcat-elements.py og generate-modellkatalog.py.

Import (med src/assets/scripts på sys.path):
    from utils.modellkatalog import load_org_registry, ...
"""
import glob
import json
import os
import sys
from pathlib import Path

import yaml

from utils.codeowners import load_codeowners as _load_codeowners

CODEOWNERS_PATH = "CODEOWNERS.md"
CATALOG_DATA_TEMPLATE = "src/linkml/modellkatalog/{slug}/data/{slug}/{slug}.yaml"
RELEASE_MANIFEST_PATH = ".github/release-please-manifest.json"
# modellkatalog er outputdomenet (sjølvreferanse), begrepskatalog er SKOS-AP-NO
# (ein annan artefakttype enn Informasjonsmodell), referanse er ikkje-produksjon.
EXCLUDED_DOMAINS = {"referanse", "modellkatalog", "begrepskatalog"}


def load_org_registry(codeowners_path=CODEOWNERS_PATH):
    """Les organisasjonsregisteret frå CODEOWNERS.md. Returnerer dict nøkla på org_uri.

    Delegerer til den delte parsaren i utils/codeowners.py (som forstår det
    faktiske ```yaml ...```-fenceformatet CODEOWNERS.md brukar) i staden for
    å parse `---`-frontmatter sjølv — sjå bugs/codeowners-frontmatter-format-mismatch.md.
    """
    orgs = _load_codeowners(Path(codeowners_path).resolve().parent)
    return {org["org_uri"]: org for org in orgs if org.get("org_uri")}


def load_release_manifest(path=RELEASE_MANIFEST_PATH):
    """Les .github/release-please-manifest.json. Returnerer dict nøkla på pakkesti.

    Manglar fila, vert det skrive éi linje til stderr (ingen stille feil) og
    returnert tom dict — load_annotated_schemas() fell då tilbake til
    schema.version.
    """
    if not os.path.isfile(path):
        print(
            f"ÅTVARING: {path} finst ikkje — brukar schema.version som versjonsnummer",
            file=sys.stderr,
        )
        return {}
    with open(path, encoding="utf-8") as fh:
        return json.load(fh)


def load_annotated_schemas(root="src/linkml", release_manifest=None):
    """Load all schemas with annotations.utgiver.

    versjonsnummer kjem frå .github/release-please-manifest.json (nøkkel:
    skjemaet sin katalogsti), sidan schema.version vist seg å vere upålitelig —
    release-please sin extra-files-mekanisme oppdaterer ikkje alltid
    version-feltet i YAML-fila direkte. Fallback til schema.version berre for
    skjema som ikkje er release-please-pakkar (t.d. common-ap-no, xkos-ap-no).
    """
    release_manifest = release_manifest or {}
    schemas = []
    for path in sorted(glob.glob(f"{root}/*/*/*.yaml")):
        if not path.endswith("-schema.yaml"):
            continue
        with open(path, encoding="utf-8") as fh:
            data = yaml.safe_load(fh)
        if not data:
            continue
        parts = path.split("/")
        domain = parts[2] if len(parts) >= 3 else "unknown"
        if domain in EXCLUDED_DOMAINS:
            continue
        anns = data.get("annotations") or {}
        if not anns.get("utgiver"):
            continue
        package_path = os.path.dirname(path)
        version = release_manifest.get(package_path, data.get("version"))
        schemas.append({
            "path": path,
            "name": data.get("name"),
            "title": data.get("title"),
            "description": data.get("description"),
            "schema_id": data.get("id"),
            "domain": domain,
            "annotations": anns,
            "version": version,
        })
    return schemas


def group_schemas_by_org(schemas, org_registry):
    """Group schemas by annotations.utgiver. Returns (grouped_dict, unknown_list)."""
    grouped = {org_uri: [] for org_uri in org_registry}
    unknown = []
    for schema in schemas:
        org_uri = schema["annotations"].get("utgiver")
        if org_uri in org_registry:
            grouped[org_uri].append(schema)
        else:
            unknown.append(schema)
    return grouped, unknown


def find_catalog_data(org):
    """Resolve catalog data file path for org. Returns (path, exists)."""
    slug = org["catalog_slug"]
    path = CATALOG_DATA_TEMPLATE.format(slug=slug)
    return path, os.path.isfile(path)


def entry_name(entry):
    """Derive schema name (LinkML 'name:' field / katalogmappenamn) frå
    'informasjonsmodellidentifikator' (mkdocs-URL, .../<domain>/<modell>/),
    som alltid samsvarar med katalogmappa. Fell tilbake til entry sin eigen
    id (siste path-segment) når feltet manglar — det samsvarar oftast, men
    ikkje alltid, med schema-namnet: nokre schema (t.d. modelldcat-katalog,
    modelldcat-modell) har eit kortare alias som siste segment i sjølve
    id-en ('katalog'/'modell'), noko som elles gjer join mot schema["name"]
    stille feil (sjå specs/done/fiks-digdir-katalog-referanse.md)."""
    identifikator = entry.get("informasjonsmodellidentifikator")
    if identifikator:
        return identifikator.rstrip("/").split("/")[-1]
    return (entry.get("id") or "").rstrip("/").split("/")[-1]
