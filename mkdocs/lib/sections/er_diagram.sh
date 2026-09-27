#!/usr/bin/env bash
# Generer ER-diagram-seksjon (seksjon 10 i index.md)
set -euo pipefail
trap 'echo "ERROR in ${BASH_SOURCE[0]}:${LINENO} — command: ${BASH_COMMAND}" >&2; exit 1' ERR

generate_er_diagram() {
    local schema="$1"
    local out="$2"

    # Embed PlantUML-diagram (filtrert versjon — kun lokale klasser)
    local plantuml_svg="diagrams/${schema}-filtered.svg"
    local plantuml_full="diagrams/${schema}.svg"

    # Prioriter filtrert versjon
    if [ -f "$out/$plantuml_svg" ]; then
        # Sjekk om filtrert diagram er tomt (< 1000 bytes = ingen lokale klasser)
        local filesize
        filesize=$(stat -c%s "$out/$plantuml_svg" 2>/dev/null || stat -f%z "$out/$plantuml_svg" 2>/dev/null || echo "0")

        echo "---"
        echo ""
        echo "## $(t seksjon.er_diagram.tittel)"
        echo ""
        echo "> $(t seksjon.er_diagram.forklaring)"
        echo ""

        if [ "$filesize" -lt 1000 ]; then
            # Tomt diagram — vis berre full versjon med forklaring
            echo "[![$(t seksjon.er_diagram.alt)]($plantuml_full)]($plantuml_full)"
            echo ""
            echo "*$(t seksjon.er_diagram.ingen_lokale full="$plantuml_full")*"
        else
            # Normalt filtrert diagram
            echo "[![$(t seksjon.er_diagram.alt)]($plantuml_svg)]($plantuml_svg)"
            echo ""
            echo "*$(t seksjon.er_diagram.kun_lokale full="$plantuml_full")*"
        fi
        echo ""
        echo "---"
    elif [ -f "$out/$plantuml_full" ]; then
        echo "---"
        echo ""
        echo "## $(t seksjon.er_diagram.tittel)"
        echo ""
        echo "> $(t seksjon.er_diagram.forklaring)"
        echo ""
        echo "[![$(t seksjon.er_diagram.alt)]($plantuml_full)]($plantuml_full)"
        echo ""
        echo "*$(t seksjon.er_diagram.klikk_zoom)*"
        echo ""
        echo "---"
    fi
}
