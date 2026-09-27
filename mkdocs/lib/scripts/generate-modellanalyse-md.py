#!/usr/bin/env python3
"""
Genererer ein ## Modellanalyse-seksjon frå dei per-skjema
modellanalyse-rapportane (similar-classes/-slots/-types-domain-report.md,
ubrukte-slots/-enums/-types/-subsets-report.md,
isolerte-klasser-report.md, ikkje-tilkopla-container-report.md) til stdout.

Rapportfilene vert skrivne av generate.yml sitt «Køyr modellanalyse per
skjema»-steg (make analyse-similar-classes-domain/-slots-domain/-types-domain
og make analyse-ubrukte-slots/-enums/-types/-subsets/analyse-isolerte-klasser/
analyse-ikkje-tilkopla-container NAME=<skjema>/SCHEMA=<sti>) til
generated/<domain>/<schema>/model-analyse/ —
sjå specs/done/modellanalyse-per-skjema-index-md.md,
specs/backlog/modellanalyse-liknande-typenamn.md og
specs/backlog/modellanalyse-ubrukte-lokale-definisjonar.md. Dei er
domene-scopa/per-skjema-scopa (ikkje cross-domain) og reint offline
(ingen IRI-/nettverkssjekkar) — sjå den fyrste spec-en for grunngjeving.

Kvar rapportfil startar med si eiga "# ..."-overskrift (frå
find-similar-names.py/find-unused-local-definitions.py) — denne vert
stroken og erstatta med ei eiga ###-underoverskrift her, sidan rapporten
vert nesta inn i denne sida sin eigen ## Modellanalyse-seksjon.

Cross-domain-fotnote: fram til no enda kvar underseksjon med ei fast
fotnote som peika til modell-analyse.yml-workflowen i GitHub Actions —
ikkje til noka konkret fil. Dei tre similar-*-domain-analysane har no ein
faktisk publisert cross-domain-motpart (--scope all, køyrd éin gong i
generate.yml sin publish-jobb og publisert som statiske sider under
mkdocs/docs/modellanalyse/ av mkdocs/publish.sh), så fotnota for desse
lenkar no direkte til den sida i staden. Dei seks ubrukt-lokalt/isolert-
analysane har inga meiningsfull cross-domain-form (dei er per definisjon
per-skjema) og får difor ingen fotnote i det heile — sjå
cross_domain_report_relpath=None per oppføring under.

Funntal i overskrifta: kvar underoverskrift viser talet på funn i
parentes ("### Liknande klassenavn (same domene) (3)"), etter same
mønster som ### Slots (13) lenger oppe på sida. Talet vert utleidd
generisk frå rapportkroppen (talet på `|`-tabellrader minus header-/
skiljerad) i staden for parsa frå kvar rapport sin eigen menneskelesbare
"Totalt: ..."-linje — sjå count_table_rows(). Manglande/uleseleg
rapportfil får ingen parentes (ikkje "(0)", som ville sett ut som eit
stadfesta nullfunn).

Blockquote per underoverskrift: kvar underoverskrift får òg si eiga
statiske `>`-blockquote (same tekst i alle modellar, uavhengig av faktiske
funn i denne bygginga) som forklarar kva analysen ser etter og kva
konsekvens eit funn kan ha — sjå
specs/done/modellanalyse-blockquote-per-underoverskrift.md. Blockquoten
for dei tre similar-*-analysane nemner ikkje cross-domain-motparten — det
tek den eksisterande fotnota (cross_domain_relpath/-label) seg av.

Rapporttekst per språk: når <rapport>.json finst ved sida av <rapport>.md,
vert brødteksten laga frå JSON-funna og strengkatalogen
(modellanalyse_render.py). Utan JSON (rapportar frå før JSON-utskrifta)
vert .md-rapporten brukt som før, med ei åtvaring på stderr — sjå
specs/done/modellanalyse-rapportar-per-sprak.md.

Bruk: python3 generate-modellanalyse-md.py <model-analyse-dir> <domain> <schema> [lang]

Tekstane kjem frå strengkatalogen (mkdocs/lib/i18n/strings.yaml); lang er
standard default_language i katalogen.
"""

import sys
from pathlib import Path

from i18n_strings import CatalogError, load_catalog, slugify
from modellanalyse_render import load_report, render

# (rapportfil, nøkkelprefiks i strengkatalogen, relativ sti til cross-domain-
#  sida frå mkdocs/docs/<domain>/<schema>/index.md (None = ingen
#  cross-domain-ekvivalent, ingen fotnote)).
# Tekstane ligg i mkdocs/lib/i18n/strings.yaml under <prefiks>.tittel
# (###-overskrift) og .forklaring (blockquote: kva analysen ser etter og kva
# konsekvens eit funn kan ha, statisk, same i alle modellar). Berre når
# relativ sti er sett: .objekttype (brukt i fotnoteteksten) og .kryssdomene
# (fotnote-lenkjetekst).
REPORTS = [
    ("isolerte-klasser-report.md", "modellanalyse.isolerte_klasser", None),
    ("ikkje-tilkopla-container-report.md", "modellanalyse.ikkje_tilkopla_container", None),
    ("ubrukte-slots-report.md", "modellanalyse.ubrukte_slots", None),
    ("ubrukte-types-report.md", "modellanalyse.ubrukte_types", None),
    ("ubrukte-enums-report.md", "modellanalyse.ubrukte_enums", None),
    ("ubrukte-subsets-report.md", "modellanalyse.ubrukte_subsets", None),
    (
        "similar-classes-domain-report.md",
        "modellanalyse.liknande_klassenavn",
        "../../modellanalyse/liknande-klassenavn-alle-domene.md",
    ),
    (
        "similar-slots-domain-report.md",
        "modellanalyse.liknande_slotnavn",
        "../../modellanalyse/liknande-slotnavn-alle-domene.md",
    ),
    (
        "similar-types-domain-report.md",
        "modellanalyse.liknande_typenavn",
        "../../modellanalyse/liknande-typenavn-alle-domene.md",
    ),
]

MODELL_ANALYSE_WORKFLOW_URL = (
    "https://github.com/AudunAutomat/linkml-datamodellering-no/actions/workflows/modell-analyse.yml"
)


def strip_own_heading(text: str) -> str:
    """Fjernar rapporten si eiga '# ...'-toppoverskrift (+ tom linje etter)."""
    lines = text.splitlines()
    if lines and lines[0].startswith("# "):
        lines = lines[1:]
        if lines and lines[0].strip() == "":
            lines = lines[1:]
    return "\n".join(lines).rstrip("\n")


def count_table_rows(body: str) -> int:
    """Talet på funn i rapporten: talet på `|`-tabellrader i body, minus
    header- og skiljerad. 0 når rapporten ikkje har nokon tabell (ingen
    funn) — sjå moduldocstring § "Funntal i overskrifta"."""
    pipe_lines = [line for line in body.splitlines() if line.strip().startswith("|")]
    if len(pipe_lines) < 2:
        return 0
    return len(pipe_lines) - 2


def main() -> None:
    if len(sys.argv) < 4:
        print(
            "Bruk: generate-modellanalyse-md.py <model-analyse-dir> <domain> <schema> [lang]",
            file=sys.stderr,
        )
        sys.exit(1)

    analyse_dir = Path(sys.argv[1])
    # sys.argv[2] (domain) og sys.argv[3] (schema) er ikkje i bruk sjølve
    # formateringa i dag (cross-domain-relativstiane er faste — alle
    # skjema-index.md ligg to nivå under mkdocs/docs/), men tekne imot for
    # symmetri med generate-validation-md.py sitt grensesnitt og for
    # framtidig bruk.

    catalog = load_catalog()
    lang = sys.argv[4] if len(sys.argv) > 4 else catalog.default_language

    def t(key, **values):
        return catalog.t(key, lang, **values)

    lines = [
        "",
        f"## {t('seksjon.modellanalyse.tittel')} {{#modellanalyse}}",
        "",
        f"> {t('seksjon.modellanalyse.forklaring')}",
        "",
        f"*{t('seksjon.modellanalyse.workflow', lenkje=MODELL_ANALYSE_WORKFLOW_URL)}*",
    ]

    any_report_found = False
    for filename, prefix, cross_domain_relpath in REPORTS:
        heading = t(f"{prefix}.tittel")
        # Fast anker lik slug-en av den nynorske overskrifta (O2-a), slik at
        # ankeret er likt i alle språk.
        anchor = slugify(catalog.t(f"{prefix}.tittel", catalog.default_language))
        blockquote_text = t(f"{prefix}.forklaring")
        report_path = analyse_dir / filename
        json_path = report_path.with_suffix(".json")
        body = count = None
        if json_path.is_file():
            any_report_found = True
            try:
                _, body, count = render(load_report(json_path), catalog, lang)
            except (OSError, ValueError, KeyError, CatalogError) as e:
                print(f"ÅTVARING: klarte ikkje lage rapport frå {json_path}: {e} — brukar {report_path}",
                      file=sys.stderr)
        if body is None and not report_path.is_file():
            print(f"ÅTVARING: fann ikkje {report_path}", file=sys.stderr)
        elif body is None:
            any_report_found = True
            if not json_path.is_file():
                print(f"ÅTVARING: fann ikkje {json_path} — rapportteksten vert ikkje omsett", file=sys.stderr)
            try:
                body = strip_own_heading(report_path.read_text(encoding="utf-8"))
                count = count_table_rows(body)
            except Exception as e:
                print(f"ÅTVARING: klarte ikkje lese {report_path}: {e}", file=sys.stderr)

        if body is None:
            lines += ["", f"### {heading} {{#{anchor}}}", "", f"> {blockquote_text}", ""]
            lines.append(f"*{t('seksjon.modellanalyse.rapport_manglar')}*")
        else:
            lines += ["", f"### {heading} ({count}) {{#{anchor}-{count}}}", "", f"> {blockquote_text}", ""]
            lines.append(body)

        if cross_domain_relpath:
            kryssdomene = t(
                "seksjon.modellanalyse.kryssdomene",
                objekttype=t(f"{prefix}.objekttype"),
                etikett=t(f"{prefix}.kryssdomene"),
                lenkje=cross_domain_relpath,
            )
            lines += ["", f"*{kryssdomene}*"]

    if not any_report_found:
        print(f"ÅTVARING: ingen modellanalyse-rapportar funne i {analyse_dir}", file=sys.stderr)

    print("\n".join(lines))


if __name__ == "__main__":
    main()
