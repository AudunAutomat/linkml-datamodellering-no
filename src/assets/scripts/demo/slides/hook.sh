#!/usr/bin/env bash
# Slide: «Same model, many places» (akt 0, hook). Ingen kommando — berre ei
# slide. Tekst og layout: specs/backlog/demo-SEMIC.md § Akt 0.
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=slide-lib.sh
source "$here/slide-lib.sh"

slide_begin 66

sl "${CLR_BOLD}${CLR_STEP}Same model, many artefacts${CLR_RST}"
sl "${CLR_DBG}...that drift apart${CLR_RST}"
sl ""
sl "${CLR_BOLD}Model${CLR_RST} ${CLR_DBG}──┬─${CLR_RST} OWL ontology       ${CLR_DBG}ex:title${CLR_RST}"
sl "        ${CLR_DBG}├─${CLR_RST} SHACL shapes       ${CLR_DBG}sh:path dct:title${CLR_RST}"
sl "        ${CLR_DBG}├─${CLR_RST} JSON Schema        ${CLR_DBG}\"title\": string${CLR_RST}"
sl "        ${CLR_DBG}├─${CLR_RST} Python class       ${CLR_ERR}name: str${CLR_RST}   ${CLR_ERR}<- someone renamed it${CLR_RST}"
sl "        ${CLR_DBG}├─${CLR_RST} Docs / wiki        ${CLR_DBG}\"Title (required)\"${CLR_RST}"
sl "        ${CLR_DBG}└─${CLR_RST} JSON-LD context    ${CLR_DBG}\"title\": \"dct:title\"${CLR_RST}"
sl ""
sl "Six hand-written copies."
sl "Someone renames a field. ${CLR_ERR}Five copies don't know about it.${CLR_RST}"
sl ""
sl ""
sl "${CLR_BOLD}${CLR_OK}-> Model once, use many times.${CLR_RST}"
echo ""
