#!/usr/bin/env bash
# Steg-for-steg demo-script for semantisk web-konferansen — sjå
# specs/backlog/demo-semantisk-web-konferanse.md for kontekst, talk track og
# verifiserte funn. Same stil som javazone-demo-script.sh: kvart steg viser
# tittel og kommando, ventar på Enter, køyrer så kommandoen.
#
# Køyr FRÅ REPO-ROTA:
#   bash src/assets/scripts/demo/semweb-demo-script.sh [QUICK=<true|false>] [PREPARE=<true|false>]
#
#   QUICK   — default: false. Ved "true" hoppar scriptet over akt 0-1 (hook og
#             visning av kjelda) og startar på akt 2. Til øving av kommandoane.
#   PREPARE — default: false. Ved "true" genererer scriptet FØR demoklokka
#             startar alt portalen treng (artefakter, valideringslogg,
#             modellanalyse) og byggjer portalen (make docs-build, ca. 1 min).
#             Start deretter `make docs-serve-site` i ein eigen terminal, og
#             byt fane i akt 4. Utan PREPARE=true vert akt 4 berre
#             `make gen-schema-docs` og ein pause for å byte til nettlesaren.
#
# Fixturen ligg i src/assets/scripts/demo/semweb-demo/ (utanfor src/linkml/, slik
# at han ikkje kjem med i make test, CI eller den publiserte portalen). Scriptet
# kopierer han til src/linkml/oreg/konferanseprogram/ ved start, og slettar han
# ved slutt (oppryddingsspørsmål).
#
# Akt 3 og 5 set inn ferdigskrivne YAML-blokkar i skjemaet (reint tekstbasert,
# ingen YAML-parsing — innhaldet er scriptet sitt eige) og viser resultatet
# som git diff --no-index.
#
# Ikkje "set -e": eit feila steg skal ikkje krasje demoen midt i ein
# presentasjon. Feilen vert vist, og du vel sjølv om du held fram.
#
# Bash 3.2-kompatibelt (macOS): ingen mapfile, declare -A eller ${v,,}.
set -uo pipefail

DOMAIN="oreg"
NAME="konferanseprogram"
QUICK="false"
PREPARE="false"
for arg in "$@"; do
    case "$arg" in
        QUICK=*)
            QUICK="${arg#QUICK=}"
            case "$QUICK" in true|false) ;; *)
                echo "Feil: QUICK må vere 'true' eller 'false' (fekk '$QUICK')." >&2; exit 1 ;;
            esac
            ;;
        PREPARE=*)
            PREPARE="${arg#PREPARE=}"
            case "$PREPARE" in true|false) ;; *)
                echo "Feil: PREPARE må vere 'true' eller 'false' (fekk '$PREPARE')." >&2; exit 1 ;;
            esac
            ;;
        *)
            echo "Feil: ukjent argument '$arg'." >&2
            echo "Bruk: bash $0 [QUICK=<true|false>] [PREPARE=<true|false>]" >&2
            exit 1
            ;;
    esac
done

SCHEMA="src/linkml/$DOMAIN/$NAME/$NAME-schema.yaml"
MODEL_DIR="src/linkml/$DOMAIN/$NAME"
GEN_DIR="generated/$DOMAIN/$NAME"
FIXTURE_DIR="$(cd "$(dirname "$0")" && pwd)/semweb-demo"

CLR_STEP=$'\033[0;36m'
CLR_OK=$'\033[0;32m'
CLR_WARN=$'\033[0;33m'
CLR_DBG=$'\033[2m'
CLR_ERR=$'\033[0;31m'
CLR_RST=$'\033[0m'

if [ ! -f Makefile ]; then
    echo "Feil: køyr dette scriptet frå repo-rota (der Makefile ligg)." >&2
    exit 1
fi
if [ ! -d "$FIXTURE_DIR" ]; then
    echo "Feil: fann ikkje fixturen $FIXTURE_DIR" >&2
    exit 1
fi

# ---------------------------------------------------------------------------
# Førehandsfasen (før demoklokka): fixture, ryddeføresetnader, eventuell portal
# ---------------------------------------------------------------------------

# Filer docs-publish/docs-build kan endre (README-rad for modellen, sletting av
# mkdocs/docs/felles/ når generated/ ikkje har domenet). Berre rydda med git
# restore dersom dei var uendra då scriptet starta, slik at ingen eigne endringar
# går tapt. Sjå specs/backlog/demo-semantisk-web-konferanse.md § Portalmåling.
PORTAL_PATHS="README.md README.en.md mkdocs/docs/felles"
# shellcheck disable=SC2086
if git diff --quiet -- $PORTAL_PATHS 2>/dev/null; then
    PORTAL_PATHS_CLEAN="true"
else
    PORTAL_PATHS_CLEAN="false"
fi

if [ -d "$MODEL_DIR" ]; then
    echo "${CLR_WARN}${MODEL_DIR} finst frå ei tidlegare køyring.${CLR_RST}"
    read -rp "Fjerne eksisterande modell og kopiere ferskt fixture? (J/n) " svar
    if [[ ! "$svar" =~ ^[nN]$ ]]; then
        rm -rf "$MODEL_DIR" "$GEN_DIR"
        echo "Rydda opp."
    else
        echo "${CLR_WARN}Held fram med eksisterande modell (akt 3 og 5 kan feile viss han alt er endra).${CLR_RST}"
    fi
fi
if [ ! -d "$MODEL_DIR" ]; then
    mkdir -p "$MODEL_DIR" && cp -R "$FIXTURE_DIR/." "$MODEL_DIR/" \
        || { echo "${CLR_ERR}Klarte ikkje kopiere fixturen til ${MODEL_DIR}${CLR_RST}" >&2; exit 1; }
fi

if [ "$PREPARE" = "true" ]; then
    echo "${CLR_DBG}PREPARE=true: genererer artefakter, valideringslogg og modellanalyse, og byggjer portalen …${CLR_RST}"
    for t in gen-shacl gen-owl gen-jsonld-context gen-rdf gen-jsonschema gen-python \
             gen-erdiagram-mermaid gen-plantuml gen-schema-docs; do
        make "$t" SCHEMA="$SCHEMA" > /dev/null || echo "${CLR_ERR}FEIL: make $t${CLR_RST}" >&2
    done
    make convert-instance-rdf DOMAIN="$DOMAIN" > /dev/null || echo "${CLR_ERR}FEIL: convert-instance-rdf${CLR_RST}" >&2
    make mcp-linkml-valider-modell SCHEMA="$SCHEMA" POLICY=basis-no > /dev/null \
        || echo "${CLR_DBG}(validering gav funn, som venta for utgangsmodellen)${CLR_RST}"
    make analyse-lokal-modellanalyse-domene DOMAIN="$DOMAIN" > /dev/null || echo "${CLR_ERR}FEIL: modellanalyse${CLR_RST}" >&2
    make docs-build > /dev/null || echo "${CLR_ERR}FEIL: docs-build${CLR_RST}" >&2
    echo "${CLR_OK}Portalen er bygd.${CLR_RST} Start ${CLR_STEP}make docs-serve-site${CLR_RST} i ein eigen terminal og opne"
    echo "  http://localhost:8000/linkml-datamodellering-no/en/${DOMAIN}/${NAME}/"
    read -rp "Trykk Enter når portalen køyrer … "
fi

# Terminalpynt (figlet/glow) frå JavaZone-biletet — valfritt. Utan biletet vert
# overskrifter vist som farga tekst og tabellar som rå markdown.
FUN_IMAGE="localhost/demo-fun-tools"
fun() { podman run --rm -i "$FUN_IMAGE" "$@" 2>/dev/null; }
have_fun() { podman image exists "$FUN_IMAGE" 2>/dev/null; }

fun_width() {
    local floor="$1" cols
    cols="$(tput cols 2>/dev/null || echo "$floor")"
    if [ "$cols" -lt "$floor" ]; then echo "$floor"; else echo "$cols"; fi
}

# Markdown-tabellar frå analysejobbane gjennom glow når biletet finst.
pretty_md() {
    if have_fun; then fun glow -w "$(fun_width 140)" -; else cat; fi
}

# ---------------------------------------------------------------------------
# Hjelparar (klokke, prompt, steg)
# ---------------------------------------------------------------------------

DEMO_START=$(date +%s)
elapsed() {
    local diff=$(( $(date +%s) - DEMO_START ))
    printf '%02d:%02d' "$(( diff / 60 ))" "$(( diff % 60 ))"
}
prompt_enter() {
    read -rp "${CLR_DBG}[$(elapsed)]${CLR_RST} ${1:-Press Enter to continue … }"
}

print_heading() {
    local title="$1"
    echo ""
    if have_fun; then
        echo "$title" | fun boxes -d stone
    else
        echo "${CLR_STEP}=== ${title} ===${CLR_RST}"
    fi
}

# act TITTEL — større overskrift for ein akt (ingen pause).
act() {
    echo ""
    echo ""
    if have_fun; then
        fun figlet -w "$(tput cols 2>/dev/null || echo 100)" "$1" | fun lolcat -f
    else
        echo "${CLR_STEP}##### ${1} #####${CLR_RST}"
    fi
}

# step TITTEL FARGA-KOMMANDOLINJE [KOMMANDO ...]
step() {
    local title="$1" display="$2"
    shift 2
    print_heading "$title"
    if [ -n "$display" ]; then
        echo ""
        echo "\$ ${display}"
    fi
    prompt_enter
    if [ "$#" -gt 0 ]; then
        "$@" || echo "${CLR_ERR}(step failed — see output above; decide whether to continue)${CLR_RST}"
    fi
}

LESS_HINT="${CLR_DBG}(press 'q' to close less and continue)${CLR_RST}"
to_less() { echo "$LESS_HINT"; less -R -F -X; }

# Farga kommandolinje: cmd "make gen-shacl" "SCHEMA=<S>" (valfritt arg i gult)
disp() { echo "${CLR_STEP}$1${CLR_RST} ${CLR_WARN}$2${CLR_RST}"; }

# show_diff FØR ETTER — viser berre hunkane (frå fyrste "@@"), med ei rein
# overskrift. git diff --no-index viser elles den midlertidige stien til
# før-fila (/var/folders/...), som er uleseleg på ein storskjerm.
show_diff() {
    local before="$1" after="$2"
    {
        echo "${CLR_STEP}$(basename "$after")${CLR_RST}"
        git diff --no-index --color=always -- "$before" "$after" | sed -n '/@@/,$p'
    } | to_less
}

# --- tekstbasert innsetjing i skjemaet ---------------------------------------
# Innhaldet vert sendt via ENVIRON, ikkje awk -v: BSD-awk (macOS) tek ikkje
# newline i -v-verdiar. Resultatet vert skrive TILBAKE I SAMA FIL (cat >), ikkje
# mv: eit mv byter inode, og podman-monteringa på macOS såg då stundom ikkje fila
# i containeren ("File ... does not exist") i dei neste make-stega.

# insert_after_line SCHEMA ANKER INNHALD — rett etter fyrste linje eksakt lik ANKER
insert_after_line() {
    local schema="$1" anchor="$2" content="$3" line
    line=$(grep -n -F -x -m1 "$anchor" "$schema" | cut -d: -f1)
    if [ -z "$line" ]; then
        echo "${CLR_ERR}Anchor line not found: '${anchor}' in ${schema}${CLR_RST}" >&2
        return 1
    fi
    CONTENT="$content" awk -v line="$line" '{ print } NR == line { print ENVIRON["CONTENT"] }' \
        "$schema" > "${schema}.tmp" && cat "${schema}.tmp" > "$schema" && rm -f "${schema}.tmp"
}

# insert_before_line SCHEMA ANKER INNHALD — rett før fyrste linje eksakt lik ANKER
insert_before_line() {
    local schema="$1" anchor="$2" content="$3" line
    line=$(grep -n -F -x -m1 "$anchor" "$schema" | cut -d: -f1)
    if [ -z "$line" ]; then
        echo "${CLR_ERR}Anchor line not found: '${anchor}' in ${schema}${CLR_RST}" >&2
        return 1
    fi
    CONTENT="$content" awk -v line="$line" 'NR == line { print ENVIRON["CONTENT"] } { print }' \
        "$schema" > "${schema}.tmp" && cat "${schema}.tmp" > "$schema" && rm -f "${schema}.tmp"
}

# insert_after_in_block SCHEMA NOKKELLINJE ANKER INNHALD — set INNHALD etter
# fyrste linje eksakt lik ANKER som kjem etter NOKKELLINJE (t.d. "  Foredrag:").
insert_after_in_block() {
    local schema="$1" key="$2" anchor="$3" content="$4" start
    start=$(grep -n -F -x -m1 "$key" "$schema" | cut -d: -f1)
    if [ -z "$start" ]; then
        echo "${CLR_ERR}Block not found: '${key}' in ${schema}${CLR_RST}" >&2
        return 1
    fi
    CONTENT="$content" awk -v start="$start" -v anchor="$anchor" '
        { print }
        NR > start && !done && $0 == anchor { print ENVIRON["CONTENT"]; done = 1 }
        END { if (!done) exit 1 }
    ' "$schema" > "${schema}.tmp" && cat "${schema}.tmp" > "$schema" && rm -f "${schema}.tmp" \
        || { rm -f "${schema}.tmp"; echo "${CLR_ERR}Anchor '${anchor}' not found after '${key}'${CLR_RST}" >&2; return 1; }
}

# edit_and_diff FUNKSJON — ventar på Enter, køyrer FUNKSJON (som endrar $SCHEMA)
# og viser resultatet som diff.
edit_and_diff() {
    local fn="$1" before
    prompt_enter
    before="$(mktemp "${TMPDIR:-/tmp}/semweb-before.XXXXXX")"
    cp "$SCHEMA" "$before"
    if "$fn"; then
        show_diff "$before" "$SCHEMA"
    else
        echo "${CLR_ERR}(edit failed — see output above; decide whether to continue)${CLR_RST}"
    fi
    rm -f "$before"
}

# make_quiet_deprecations MÅL... — køyrer make, og fjernar linkml sine
# deprecation-åtvaringar (gen-owl skriv ca. 20 linjer av dei på skjermen) frå
# utskrifta. Feilar make, vert HEILE utskrifta vist (ingen stille feil).
make_quiet_deprecations() {
    local out rc
    out=$(make "$@" 2>&1); rc=$?
    if [ "$rc" -ne 0 ]; then
        printf '%s\n' "$out"
        return "$rc"
    fi
    printf '%s\n' "$out" | grep -v -E 'DeprecationWarning|deprecation_warning|^Deprecated In:|^Recommendation:|^The default for|^See: https://github.com/linkml'
    return 0
}

# --- visning av kjelda --------------------------------------------------------

# show_excerpt NOKKELLINJE ANTAL — viser ANTAL linjer frå fyrste linje eksakt lik
# NOKKELLINJE i $SCHEMA, med linjenummer, gjennom less.
show_excerpt() {
    local key="$1" count="$2" start
    start=$(grep -n -F -x -m1 "$key" "$SCHEMA" | cut -d: -f1)
    if [ -z "$start" ]; then
        echo "${CLR_ERR}Fann ikkje '${key}' i ${SCHEMA}${CLR_RST}" >&2
        return 1
    fi
    sed -n "${start},$(( start + count - 1 ))p" "$SCHEMA" | cat -n | to_less
}

# --- «éin slot, seks artefakter» ----------------------------------------------

# show_hit ETIKETT FIL MØNSTER [LINJER-ETTER] — fyrste treff (fast streng).
show_hit() {
    local label="$1" file="$2" pattern="$3" after="${4:-0}"
    echo "${CLR_OK}${label}${CLR_RST} ${CLR_DBG}${file}${CLR_RST}"
    grep -n -F -m1 -A "$after" -- "$pattern" "$file" | sed 's/^/    /' \
        || echo "${CLR_ERR}    (no match for: ${pattern})${CLR_RST}"
}

one_slot_six_artifacts() {
    show_hit "YAML           " "$SCHEMA" "slot_uri: dct:title"
    show_hit "OWL            " "$GEN_DIR/$NAME-ontology.ttl" "dct:title a owl:DatatypeProperty"
    show_hit "SHACL          " "$GEN_DIR/$NAME-shapes.ttl" "sh:path dct:title"
    show_hit "JSON-LD context" "$GEN_DIR/$NAME-context.jsonld" '"tittel": {' 1
    show_hit "RDF (schema)   " "$GEN_DIR/$NAME-schema.ttl" 'linkml:slot_uri "http://purl.org/dc/terms/title"'
    show_hit "JSON Schema    " "$GEN_DIR/$NAME-schema.json" '"tittel": {'
}

# --- akt 3: ny slot, generer på nytt, diff over artefakta ---------------------

ARTIFACT_FILES="$NAME-shapes.ttl $NAME-context.jsonld $NAME-schema.json"
SNAP_DIR=""

snapshot_artifacts() {
    SNAP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/semweb-snap.XXXXXX")"
    local f
    for f in $ARTIFACT_FILES; do cp "$GEN_DIR/$f" "$SNAP_DIR/$f"; done
}

insert_landingsside() {
    insert_after_line "$SCHEMA" "  foaf: http://xmlns.com/foaf/0.1/" \
        "  dcat: http://www.w3.org/ns/dcat#" || return 1
    insert_after_in_block "$SCHEMA" "  Konferanse:" "      - tittel" \
        "      - landingsside" || return 1
    insert_before_line "$SCHEMA" "  har_foredragsholder:" "$(cat <<'EOF'
  landingsside:
    description: Konferansens landingsside på nettet.
    slot_uri: dcat:landingPage
    range: uriorcurie
    structured_aliases:
      - literal_form: landing page
        in_language: en

EOF
)"
}

regenerate_four() {
    local t
    snapshot_artifacts
    for t in gen-shacl gen-owl gen-jsonld-context gen-jsonschema; do
        make_quiet_deprecations "$t" SCHEMA="$SCHEMA" || return 1
    done
}

show_artifact_diffs() {
    local f out=""
    [ -n "$SNAP_DIR" ] || { echo "${CLR_ERR}Ingen snapshot — køyr regenereringa fyrst.${CLR_RST}" >&2; return 1; }
    for f in $ARTIFACT_FILES; do
        out="${out}${CLR_STEP}${f}${CLR_RST}"$'\n'
        out="${out}$(git diff --no-index --color=always -U1 -- "$SNAP_DIR/$f" "$GEN_DIR/$f" | sed -n '/@@/,$p')"$'\n\n'
    done
    echo "$LESS_HINT"
    printf '%s' "$out" | less -R -F -X
}

# --- akt 5: valideringsretting ------------------------------------------------

fix_findings() {
    insert_after_in_block "$SCHEMA" "  Foredrag:" "        in_language: en" "$(cat <<'EOF'
    annotations:
      begrepsidentifikator: https://concept-catalog.fellesdatakatalog.digdir.no/collections/TODO/concepts/TODO
EOF
)" || return 1
    insert_after_in_block "$SCHEMA" "  varighet:" \
        "    description: Varigheita på foredraget, i minutt." \
        "    slot_uri: ${NAME}:varighet"
}

# Layer 3b skal gi exit != 0 (det er poenget). Vis rapporten, og forklar at
# brotet er forventa, i staden for den generelle "step failed"-meldinga.
run_shacl_expect_violation() {
    if make validate-shacl SCHEMA="$SCHEMA" DATA="$MODEL_DIR/examples/$NAME-ugyldig.ttl"; then
        echo "${CLR_ERR}Uventa: SHACL godtok den ugyldige fila.${CLR_RST}" >&2
        return 1
    fi
    echo "${CLR_OK}(violation reported, as expected — a non-zero exit code is what makes this usable in CI)${CLR_RST}"
}

run_validate() {
    make mcp-linkml-valider-modell SCHEMA="$SCHEMA" POLICY="$1" | to_less
}
run_validate_bronze()  { run_validate bronze; }
run_validate_basis_no() { run_validate basis-no; }

# --- akt 6: analysejobbar -----------------------------------------------------

run_unused_slots()   { make analyse-unused-slots SCHEMA="$SCHEMA" | pretty_md; }
run_isolated()       { make analyse-isolated-classes SCHEMA="$SCHEMA" | pretty_md; }
run_unreachable()    { make analyse-unreachable-classes SCHEMA="$SCHEMA" | pretty_md; }
run_similar_all()    { make analyse-similar-classes-all NAME="$NAME" | pretty_md; }

# ===========================================================================
# Demoen
# ===========================================================================

if have_fun; then
    fun figlet -w "$(tput cols 2>/dev/null || echo 100)" "One source of truth" | fun lolcat -f
fi
echo "${CLR_DBG}SCHEMA=${SCHEMA}  QUICK=${QUICK}  PREPARE=${PREPARE}${CLR_RST}"

if [ "$QUICK" != "true" ]; then
    # ---- Akt 0: hook (ingen kommando) ----
    act "0. Hook"
    echo "${CLR_DBG}(slide: same model in many places that drift apart — nothing to run)${CLR_RST}"
    prompt_enter

    # ---- Akt 1: kjelda ----
    act "1. The source"
    step "The one file everything is generated from" \
        "$(disp "less" "$SCHEMA")" \
        show_excerpt "  Foredrag:" 28
    step "One slot, one line of mapping" \
        "$(disp "less" "$SCHEMA")" \
        show_excerpt "  tittel:" 9
fi

# ---- Akt 2: generer ----
act "2. Generate"
step "RDF artifacts: SHACL shapes" "$(disp "make gen-shacl" "SCHEMA=<S>")" make gen-shacl SCHEMA="$SCHEMA"
step "RDF artifacts: OWL ontology" "$(disp "make gen-owl" "SCHEMA=<S>")" make_quiet_deprecations gen-owl SCHEMA="$SCHEMA"
step "RDF artifacts: JSON-LD context" "$(disp "make gen-jsonld-context" "SCHEMA=<S>")" make gen-jsonld-context SCHEMA="$SCHEMA"
step "RDF artifacts: the schema itself as Turtle" "$(disp "make gen-rdf" "SCHEMA=<S>")" make gen-rdf SCHEMA="$SCHEMA"
step "For the developers: JSON Schema" "$(disp "make gen-jsonschema" "SCHEMA=<S>")" make gen-jsonschema SCHEMA="$SCHEMA"
step "For the developers: Python classes" "$(disp "make gen-python" "SCHEMA=<S>")" make gen-python SCHEMA="$SCHEMA"
step "One slot, six artifacts" \
    "${CLR_STEP}grep${CLR_RST} dct:title ${CLR_WARN}<each generated file>${CLR_RST}" \
    one_slot_six_artifacts

# ---- Akt 3: live-endring ----
act "3. One edit"
echo ""
echo "${CLR_DBG}Add one slot (landingsside = dcat:landingPage) to the source file:${CLR_RST}"
edit_and_diff insert_landingsside
step "Regenerate four artifacts" \
    "$(disp "make gen-shacl gen-owl gen-jsonld-context gen-jsonschema" "SCHEMA=<S>")" \
    regenerate_four
step "What changed in the generated files" \
    "${CLR_STEP}git diff${CLR_RST} ${CLR_WARN}<before> <after>${CLR_RST}" \
    show_artifact_diffs

# ---- Akt 4: portalen ----
act "4. The portal"
step "Overview without handwritten documentation" \
    "$(disp "make gen-schema-docs" "SCHEMA=<S>")" \
    make gen-schema-docs SCHEMA="$SCHEMA"
echo ""
echo "${CLR_OK}Switch to the browser tab:${CLR_RST} http://localhost:8000/linkml-datamodellering-no/en/${DOMAIN}/${NAME}/"
prompt_enter "Press Enter when back from the portal … "

# ---- Akt 5: validering ----
act "5. Validation"
step "Layer 1a: structural lint" "$(disp "make lint" "SCHEMA=<S>")" make lint SCHEMA="$SCHEMA"
step "Layer 1b: policy bronze (generic LinkML baseline)" \
    "$(disp "make mcp-linkml-valider-modell" "SCHEMA=<S> POLICY=bronze")" run_validate_bronze
step "Layer 1c: policy basis-no (Norwegian public-sector requirements)" \
    "$(disp "make mcp-linkml-valider-modell" "SCHEMA=<S> POLICY=basis-no")" run_validate_basis_no
echo ""
echo "${CLR_DBG}Fix the two findings in the source file:${CLR_RST}"
edit_and_diff fix_findings
step "basis-no again: findings gone" \
    "$(disp "make mcp-linkml-valider-modell" "SCHEMA=<S> POLICY=basis-no")" run_validate_basis_no
step "Layer 2: instance data against the model" \
    "$(disp "make validate-instance" "SCHEMA=<S> INSTANCE=<example.yaml>")" \
    make validate-instance SCHEMA="$SCHEMA" INSTANCE="$MODEL_DIR/examples/$NAME-eksempel.yaml"
step "Layer 3 (setup): example data as RDF" \
    "$(disp "make convert-instance-rdf" "DOMAIN=${DOMAIN}")" \
    make convert-instance-rdf DOMAIN="$DOMAIN"
step "Layer 3a: the generated SHACL accepts the good data" \
    "$(disp "make validate-shacl" "SCHEMA=<S>")" \
    make validate-shacl SCHEMA="$SCHEMA"
step "Layer 3b: and reports the violation in the bad data" \
    "$(disp "make validate-shacl" "SCHEMA=<S> DATA=<invalid.ttl>")" \
    run_shacl_expect_violation

# ---- Akt 6: analysejobbane ----
act "6. Analysis"
step "Unused slots" "$(disp "make analyse-unused-slots" "SCHEMA=<S>")" run_unused_slots
step "Isolated classes" "$(disp "make analyse-isolated-classes" "SCHEMA=<S>")" run_isolated
step "Classes unreachable from the root" "$(disp "make analyse-unreachable-classes" "SCHEMA=<S>")" run_unreachable
step "Has somebody already defined this? (whole repository)" \
    "$(disp "make analyse-similar-classes-all" "NAME=${NAME}")" run_similar_all

# ---- Akt 7: avslutning ----
act "7. Take-aways"
echo ""
echo "  1. One source, N artifacts. Generated, never hand-edited."
echo "  2. Validators check the model, the data and the generated SHACL."
echo "  3. Analysis and the portal give you the overview before it ships."
echo ""
if have_fun; then
    printf 'https://audunautomat.github.io/linkml-datamodellering-no/' | fun cowsay -n
fi
echo ""

# ---------------------------------------------------------------------------
# Opprydding
# ---------------------------------------------------------------------------
[ -n "$SNAP_DIR" ] && rm -rf "$SNAP_DIR"
read -rp "Clean up the demo files? (y/N) " svar
if [[ "$svar" =~ ^[yYjJ]$ ]]; then
    rm -rf "$MODEL_DIR" "$GEN_DIR"
    if [ "$PORTAL_PATHS_CLEAN" = "true" ]; then
        # shellcheck disable=SC2086
        git restore $PORTAL_PATHS 2>/dev/null \
            || echo "${CLR_WARN}Kunne ikkje køyre git restore for ${PORTAL_PATHS}; sjekk git status.${CLR_RST}" >&2
    else
        echo "${CLR_WARN}${PORTAL_PATHS} hadde endringar før demoen — ikkje rydda; sjekk git status.${CLR_RST}"
    fi
    echo "Cleaned up. ${CLR_DBG}(sjekk git status)${CLR_RST}"
fi
