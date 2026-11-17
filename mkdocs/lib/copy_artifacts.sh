#!/usr/bin/env bash
# Kopier genererte artefakter til mkdocs/docs/
set -euo pipefail
trap 'echo "ERROR in ${BASH_SOURCE[0]}:${LINENO} — command: ${BASH_COMMAND}" >&2; exit 1' ERR

source "$REPO_ROOT/mkdocs/lib/utils/imported_schemas.sh"

# find_cp_into <målkatalog> <find-argument...> — kopierer treff frå find inn i
# målkatalogen. Portabel erstatning for `find ... -exec cp -t <mål> {} +`:
# `cp -t` finst berre i GNU cp, ikkje i BSD cp (macOS). Batchar framleis alle
# filer inn i færre cp-prosessar.
find_cp_into() {
    local dest="$1"; shift
    find "$@" -exec sh -c 'dest="$1"; shift; cp "$@" "$dest"' _ "$dest" {} +
}

copy_schema_artifacts() {
    local domain="$1"
    local schema="$2"
    local schema_dir="$3"
    local out="$4"

    mkdir -p "$out/klasser"

    # Kopier artefaktfiler (berre filer, ikkje docs/-underkatalog)
    # -exec ... + batchar alle filer inn i færre cp-prosessar (i staden for
    # éin cp-prosess per fil) — sjå specs/backlog/batch-docs-publish-generering.md
    find_cp_into "$out" "$schema_dir" -maxdepth 1 -type f

    # Finn kjeldemappe for skjemaet (kan vere ulik $schema-navnet) via det
    # pre-berekna oppslaget frå Steg 1.5 i staden for eit eige find-kall —
    # sjå specs/backlog/batch-docs-publish-generering.md
    local schema_file
    schema_file=$(lookup_schema_path "${schema}-schema") || schema_file=""
    local src_dir=""
    [ -n "$schema_file" ] && src_dir=$(dirname "$schema_file")

    # Kopier CHANGELOG.md dersom den finst
    if [ -n "$src_dir" ] && [ -f "$src_dir/CHANGELOG.md" ]; then
        cp "$src_dir/CHANGELOG.md" "$out/CHANGELOG.md"
    fi

    # Kopier metadata/<schema>-manifest.yaml dersom den finst
    if [ -n "$src_dir" ] && [ -f "$src_dir/metadata/${schema}-manifest.yaml" ]; then
        cp "$src_dir/metadata/${schema}-manifest.yaml" "$out/${schema}-manifest.yaml"
    fi

    # Kopier validation/-katalog dersom den finst i generated/ (populert frå CI eller lokal validering)
    # Merk: generated/ er autorativ kjelde her — publish.sh les frå generated/, ikkje src/
    if [ -d "$schema_dir/validation" ]; then
        mkdir -p "$out/validation"
        cp -r "$schema_dir/validation"/* "$out/validation/" 2>/dev/null || true
    fi

    # Kopier PlantUML-diagramfiler til diagrams/-underkatalog
    if [ -d "$schema_dir/diagrams" ]; then
        mkdir -p "$out/diagrams"
        find_cp_into "$out/diagrams" "$schema_dir/diagrams" -type f
    fi

    # Kopier genererte Java-klasser til java/-underkatalog
    if [ -d "$schema_dir/java" ]; then
        mkdir -p "$out/java"
        find_cp_into "$out/java" "$schema_dir/java" -type f
    fi

    # Kopier gen-doc markdown-filer til klasser/-underkatalog
    if [ -d "$schema_dir/docs" ]; then
        find_cp_into "$out/klasser" "$schema_dir/docs" -name "*.md"
        # Rename alle .md-filer til lowercase (via .tmp for case-insensitive filsystem)
        for f in "$out/klasser/"*.md; do
            [ -f "$f" ] || continue
            local base=$(basename "$f")
            local lower=$(echo "$base" | tr '[:upper:]' '[:lower:]')
            if [ "$base" != "$lower" ]; then
                mv "$f" "$out/klasser/${lower}.tmp"
                mv "$out/klasser/${lower}.tmp" "$out/klasser/$lower"
            fi
        done
        # Oppdater alle interne .md-lenkjer til lowercase.
        # perl -pi i staden for `sed -i ... \L`: BSD sed (macOS) støttar korkje
        # `sed -i` utan suffiks eller \L (GNU-utviding).
        find "$out/klasser" -maxdepth 1 -name "*.md" \
            -exec perl -pi -e 's/\]\(([^)]*\.md)\)/"](" . lc($1) . ")"/ge' {} +
        # Oppdater mermaid click-hrefs i to steg (BUG-13, sjå
        # specs/backlog/mermaid-diagram-elementaere-typar-og-attributtklikk.md):
        #
        # Steg 1: for eksterne linkml:types-typar (t.d. Uriorcurie, String)
        # limer LinkML sin eigen gen-doc (docgen.py:link_mermaid()) eit
        # feilaktig "../"-prefiks og ein avsluttande "/" framanfor/etter ein
        # elles gyldig, absolutt XSD-URI (t.d.
        # "../http://www.w3.org/2001/XMLSchema#anyURI/"). Denne URI-en er
        # det tilsikta, korrekte lenkjemålet — han skal bevarast uendra,
        # berre med "../"-prefikset og den påklistra avsluttande "/" fjerna.
        find "$out/klasser" -maxdepth 1 -name "*.md" \
            -exec perl -pi -e 's|click ([A-Za-z0-9_]+) href "\.\./(https?://[^"]+)/"|click $1 href "$2"|g' {} +
        # Steg 2: for genuint lokale klasse-/enum-/slot-/type-referansar
        # (href framleis prefiksa med "../" etter steg 1 — eksterne URL-ar
        # er det ikkje lenger) vert href bygd på nytt frå navnet i
        # click-statementet, ikkje frå den eksisterande href-verdien (som
        # kan vere feilkasa, sjå specs/done/mermaid-klikkbare-lenker-404.md)
        find "$out/klasser" -maxdepth 1 -name "*.md" \
            -exec perl -pi -e 's|click ([A-Za-z0-9_]+) href "\.\./[^"]*"|click $1 href "../\L$1\E/"|g' {} +
    fi
}
