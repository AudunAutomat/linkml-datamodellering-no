#!/usr/bin/env python3
"""
Lagar modellanalyse-rapportar på eit gitt språk frå JSON-funna som
find-similar-names.py og find-unused-local-definitions.py skriv ved sida av
.md-rapportane (<rapport>.json). Teksten kjem frå strengkatalogen
(modellanalyse.rapport.*). Nynorsk gjev same tekst som .md-rapportane
(tests/test_modellanalyse_render.py), slik at .md-rapportane i CI og terminal
er uendra. Sjå specs/done/modellanalyse-rapportar-per-sprak.md.

Bruk som modul: render(data, catalog, lang) -> (tittel, brødtekst, funntal).

Bruk frå kommandolinja (publish.sh, tvers-av-domene-sidene):
    python3 modellanalyse_render.py page <rapport.json> [lang]
skriv heile sida (# tittel + brødtekst) til stdout.
"""

import json
import sys
from pathlib import Path

from i18n_strings import CatalogError, load_catalog

PREFIX = "modellanalyse.rapport"


def _similar(data, tr):
    kind = data["kind"]
    navnetype = tr(f"liknande.navnetype_{kind}")
    etikett = tr(f"liknande.etikett_{kind}")
    detaljar = []
    if data.get("target"):
        detaljar.append(tr("liknande.mal", domene=data["target"]["domain"], skjema=data["target"]["schema"]))
    detaljar.append(tr(f"liknande.omfang_{data['scope']}"))
    if data.get("domain"):
        detaljar.append(tr("liknande.domene", domene=data["domain"]))
    tittel = tr("liknande.tittel", navnetype=navnetype, detaljar=", ".join(detaljar), terskel=f"{data['threshold']:.0%}")

    matches = data["matches"]
    if not matches:
        return tittel, tr("liknande.ingen", navnetype=navnetype, tal=str(data["checked"]), etikett=etikett), 0

    def fmt_extra(extra):
        if kind == "class":
            if not extra:
                return tr("liknande.ingen_slots")
            shown = extra[:12]
            text = ", ".join(f"`{n}`" for n in shown)
            rest = len(extra) - len(shown)
            return f"{text}, … {tr('liknande.fleire_slots', tal=str(rest))}" if rest > 0 else text
        return f"`{extra}`" if extra else "(default)"

    likskap = tr("liknande.likskap")
    skjema = tr("kolonne.skjema")
    if kind == "class":
        col_a, col_b = tr("kolonne.klasse"), "Slots"
    elif kind == "slot":
        col_a, col_b = "Slot", "Type"
    else:
        col_a, col_b = "Type", tr("liknande.grunntype")
    lines = [
        f"| {likskap} | {col_a} A | {col_b} A | {skjema} A | {col_a} B | {col_b} B | {skjema} B |",
        "|---|---|---|---|---|---|---|",
    ]
    for m in matches:
        a, b = m["a"], m["b"]
        lines.append(
            f"| {m['ratio']:.0%} | `{a['name']}` | {fmt_extra(a['extra'])} | {a['schema']} "
            f"| `{b['name']}` | {fmt_extra(b['extra'])} | {b['schema']} |"
        )
    lines.append("\n" + tr("liknande.totalt", tal=str(len(matches)), sjekka=str(data["checked"]), etikett=etikett))
    return tittel, "\n".join(lines), len(matches)


def _local(data, tr):
    kind, sti, total, items = data["kind"], data["schema_path"], str(data["total"]), data["items"]
    inga = tr("lokal.inga_skildring")
    if kind == "class":
        tittel = tr("lokal.isolerte_tittel", sti=sti)
        tom = tr("lokal.isolerte_ingen", total=total)
    elif kind == "unreachable":
        tittel = tr("lokal.ikkje_tilkopla_tittel", sti=sti)
        tom = tr("lokal.ikkje_tilkopla_ingen", total=total)
    else:
        etikett = tr(f"lokal.etikett_{kind}")
        tittel = tr("lokal.ubrukte_tittel", etikett=etikett, sti=sti)
        tom = tr("lokal.ubrukte_ingen", etikett=etikett, total=total)
    if not items:
        return tittel, tom, 0

    col_a = tr("kolonne.klasse") if kind in ("class", "unreachable") else {
        "slot": "Slot", "enum": "Enum", "type": "Type", "subset": "Subset"}[kind]
    skildring = tr("kolonne.skildring")
    lines = []
    if kind == "class":
        lines += [f"| {col_a} | {tr('kolonne.grunn')} | {skildring} |", "|---|---|---|"]
        for it in items:
            lines.append(f"| `{it['name']}` | {tr('lokal.grunn_' + it['reason'])} | {it['description'] or inga} |")
        n_container = sum(1 for it in items if it["reason"] == "container_only")
        lines.append("\n" + tr("lokal.isolerte_totalt", tal=str(len(items)), total=total,
                              isolerte=str(len(items) - n_container), container=str(n_container)))
    else:
        lines += [f"| {col_a} | {skildring} |", "|---|---|"]
        for it in items:
            lines.append(f"| `{it['name']}` | {it['description'] or inga} |")
        if kind == "unreachable":
            lines.append("\n" + tr("lokal.ikkje_tilkopla_totalt", tal=str(len(items)), total=total))
        else:
            lines.append("\n" + tr("lokal.ubrukte_totalt", tal=str(len(items)), etikett=etikett, total=total))
    return tittel, "\n".join(lines), len(items)


def render(data, catalog, lang):
    """(tittel, brødtekst, funntal) for rapporten i data, på språket lang."""
    def tr(key, **values):
        return catalog.t(f"{PREFIX}.{key}", lang, **values)

    if data.get("format") != 1:
        raise ValueError(f"ukjent rapportformat: {data.get('format')!r}")
    if data.get("analyse") == "liknande":
        return _similar(data, tr)
    if data.get("analyse") == "lokal":
        return _local(data, tr)
    raise ValueError(f"ukjend analyse: {data.get('analyse')!r}")


def load_report(path):
    return json.loads(Path(path).read_text(encoding="utf-8"))


def main(argv):
    if len(argv) < 3 or argv[1] != "page":
        print("Bruk: modellanalyse_render.py page <rapport.json> [lang]", file=sys.stderr)
        return 2
    catalog = load_catalog()
    lang = argv[3] if len(argv) > 3 else catalog.default_language
    try:
        tittel, body, _ = render(load_report(argv[2]), catalog, lang)
    except (OSError, ValueError, KeyError, CatalogError) as exc:
        print(f"[ERROR] modellanalyse_render: {argv[2]}: {exc}", file=sys.stderr)
        return 1
    print(f"# {tittel}\n\n{body}")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
