#!/usr/bin/env bash
# Kopier genererte artefakter til mkdocs/docs/, generer index-sider per språk og
# byggjetre + mkdocs-konfig per språk i mkdocs/build/ (sjå Steg 2b, 2c og 3).
# Køyr etter make <domain> eller make validate.
set -euo pipefail
trap 'echo "ERROR in ${BASH_SOURCE[0]}:${LINENO} — command: ${BASH_COMMAND}" >&2; exit 1' ERR

: "${LOG_FUNCTIONS:?miljøvariabelen LOG_FUNCTIONS må vere sett (eksportert frå make/00-settings.mk)}"
eval "$LOG_FUNCTIONS"

export REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GEN="$REPO_ROOT/generated"
DOCS="$REPO_ROOT/mkdocs/docs"
# Publisert portal-adresse (GitHub Pages) — base for site_url, språkveljar og
# portal-lenkjer i omsette sider.
PORTAL_URL="https://audunautomat.github.io/linkml-datamodellering-no"

# log_step — banner/deloverskrift, alltid synleg (uavhengig av LOGLVL),
# same kontrakt som print_header i make/03-output.mk. SEP/CLR_*-variablane
# er arva frå miljøet (eksportert av make/00-settings.mk), ikkje
# redeklarerte lokalt.
log_step() {
    echo "${CLR_SEP}${SEP}${CLR_RST}"
    echo "${CLR_HDR}$*${CLR_RST}"
    echo "${CLR_SEP}${SEP}${CLR_RST}"
}

# ---------------------------------------------------------------------------
# Source lib-filer (refactored modulær struktur)
# ---------------------------------------------------------------------------
LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/lib" && pwd)"
source "$LIB_DIR/utils/python_container.sh"
source "$LIB_DIR/utils/imported_schemas.sh"
source "$LIB_DIR/copy_artifacts.sh"
source "$LIB_DIR/generate_index.sh"
source "$LIB_DIR/utils/formatters.sh"
source "$LIB_DIR/utils/metadata_parsers.sh"
source "$LIB_DIR/utils/i18n.sh"

# Strengkatalog for portaltekst (mkdocs/lib/i18n/strings.yaml): sjekk at alle
# nøklar som vert brukte finst (t-kall inne i echo svelgjer feilstatus, sjå
# mkdocs/lib/utils/i18n.sh), og last standardspråket éin gong — tabellen vert
# arva av dei parallelle skjemajobbane. Fleire språktre: steg 6 i
# specs/done/lokalisering-dokumentasjonsportal.md.
run_python_container /work/mkdocs/lib/scripts/i18n_strings.py check
i18n_load

# Rekkjefølgje på artefakter i tabellen (brukt både i artifacts.sh og domain/index.md-generering)
ARTIFACT_ORDER="shapes.ttl context.jsonld schema.json schema.xsd openapi.yaml asyncapi.yaml ontology.ttl schema.ttl model.py schema.proto schema.graphql erdiagram.md eksempel.ttl"

# ---------------------------------------------------------------------------
# Hjelpefunksjonar (legacy — flytta til lib/)
# ---------------------------------------------------------------------------

# DEPRECATED: domain_label() og artifact_label() er flytta til lib/utils/formatters.sh
# DEPRECATED: ARTIFACT_ORDER er flytta til lib/sections/artifacts.sh

# ---------------------------------------------------------------------------
# Generer valideringsregler.md frå policies/README.md
# ---------------------------------------------------------------------------
generate_validation_docs() {
    local policies_readme omsett=true
    policies_readme=$(i18n_source "$REPO_ROOT/src/mcp-linkml-validator/policies/README.md") || omsett=false
    local output="$DOCS/arkitektur/valideringsregler.md"
    local github_base="https://github.com/AudunAutomat/linkml-datamodellering-no/blob/main"

    # Ingen eigen før/etter-logging her — kalt via timed_run(), som alt
    # loggar navn+tid ved suksess og navn+tid+kommando ved feil. Sjå
    # specs/backlog/flytt-steg3-til-steg1-med-timing.md.
    log_debug "→ Genererer $output frå $policies_readme"

    {
        printf '%s\n' "# $(t valideringsreglar.tittel)" "" \
            "!!! note \"$(t valideringsreglar.merknad_tittel)\"" "" \
            "     $(t valideringsreglar.merknad_1)" "     " \
            "     $(t valideringsreglar.merknad_2 lenkje="https://github.com/AudunAutomat/linkml-datamodellering-no/tree/main/src/mcp-linkml-validator")" \
            "" "---" ""
        i18n_strip_front_matter "$policies_readme" | \
            sed -E "s|\]\(([^)]+\.yaml)\)|]($github_base/src/mcp-linkml-validator/policies/\1)|g" | \
            sed -E "s|specs/done/([^)]+)|$github_base/specs/done/\1|g" | \
            sed -E "s|\.\./\.\./\.\./([A-Z][A-Za-z-]*\.md)|$github_base/\1|g"
    } > "$output"
    $omsett || i18n_note_untranslated "$output"
}

# ---------------------------------------------------------------------------
# Generer modellanalyse/-sider frå dei tre --scope all-rapportane
# (similar-classes/-slots/-types-all), køyrde éin gong per generate.yml-
# køyring (sjå .github/workflows/generate.yml, steget "Køyr modellanalyse
# på tvers av domene"). Gjer at kvart skjema sin per-objekttype-fotnote
# under ## Modellanalyse (generate-modellanalyse-md.py) kan lenke til ei
# ekte, stabil side i staden for GitHub Actions-workflowen — sjå
# specs/backlog/modellanalyse-ubrukte-lokale-definisjonar.md.
# ---------------------------------------------------------------------------
generate_cross_domain_modellanalyse_docs() {
    local src_dir="$GEN/modell-analyse-tvers-domene"
    local out_dir="$DOCS/modellanalyse"
    mkdir -p "$out_dir"

    local -A files=(
        [similar-classes-all-report.md]="liknande-klassenavn-alle-domene.md"
        [similar-slots-all-report.md]="liknande-slotnavn-alle-domene.md"
        [similar-types-all-report.md]="liknande-typenavn-alle-domene.md"
    )

    local src_name dest
    for src_name in "${!files[@]}"; do
        dest="$out_dir/${files[$src_name]}"
        if [ -f "$src_dir/$src_name" ]; then
            cp "$src_dir/$src_name" "$dest"
        else
            log_info "${CLR_WARN}ÅTVARING: $src_dir/$src_name finst ikkje — hoppar over${CLR_RST}"
            printf '%s\n' "# $(t modellanalyse.alle.ikkje_tilgjengeleg_tittel)" "" \
                "$(t modellanalyse.alle.ikkje_generert)" > "$dest"
        fi
    done

    {
        echo "# $(t modellanalyse.alle.tittel)"
        echo ""
        echo "$(t modellanalyse.alle.innleiing lenkje="https://github.com/AudunAutomat/linkml-datamodellering-no/actions/workflows/modell-analyse.yml")"
        echo ""
        echo "- [$(t modellanalyse.liknande_klassenavn.tittel)](liknande-klassenavn-alle-domene.md)"
        echo "- [$(t modellanalyse.liknande_slotnavn.tittel)](liknande-slotnavn-alle-domene.md)"
        echo "- [$(t modellanalyse.liknande_typenavn.tittel)](liknande-typenavn-alle-domene.md)"
    } > "$out_dir/index.md"
}

# ---------------------------------------------------------------------------
# Generer index.md frå README.md (+ footer med byggetidspunkt)
# ---------------------------------------------------------------------------
write_index_from_readme() {
    local readme
    if readme=$(i18n_source "$REPO_ROOT/README.md"); then
        # README-tabellane er alt fylte på språket til fila (update_readme_tables)
        i18n_strip_front_matter "$readme" > "$DOCS/index.md"
    else
        cp "$readme" "$DOCS/index.md"
        i18n_note_untranslated "$DOCS/index.md"
    fi

    local sist_bygd
    sist_bygd=$(t portal.sist_bygd tid="$BUILD_TIMESTAMP")
    cat >> "$DOCS/index.md" <<EOF

---

_${sist_bygd}_
EOF
}

# DEPRECATED: build_dependency_graph() er flytta til lib/sections/dependencies.sh

# ---------------------------------------------------------------------------
# Per-skjema prosessering (køyrer parallelt) — REFACTORED
# ---------------------------------------------------------------------------
process_schema() {
    local domain="$1"
    local schema="$2"
    local schema_dir="$GEN/$domain/$schema"
    local out="$DOCS/$domain/$schema"
    local t0
    t0=$(now_ms)

    # Steg 2a: Kopier artefakter
    copy_schema_artifacts "$domain" "$schema" "$schema_dir" "$out"

    # Steg 2b: Deserialisér delmodell-map frå miljøvariablar og generer index.md
    local parent_model=""
    local submodels=""

    for entry in $SCHEMA_PARENT_MODEL_SERIALIZED; do
        key="${entry%%=*}"
        val="${entry#*=}"
        [ "$key" = "$schema" ] && parent_model="$val" && break
    done

    for entry in $SCHEMA_SUBMODELS_SERIALIZED; do
        key="${entry%%=*}"
        val="${entry#*=}"
        if [ "$key" = "$schema" ]; then
            # val er komma-separert — konverter til mellomrom-separert for SUBMODELS
            submodels="${val//,/ }"
            break
        fi
    done

    export PARENT_MODEL="$parent_model"
    export SUBMODELS="$submodels"
    generate_schema_index "$domain" "$schema" "$schema_dir" "$out"
    unset PARENT_MODEL SUBMODELS

    local elapsed_ms=$(( $(now_ms) - t0 ))
    log_info "$(printf "${CLR_STEP}  → %s/%s${CLR_RST} (%s)" \
        "$domain" "$schema" \
        "$(fmt_elapsed_ms "$elapsed_ms")")"
}

# ---------------------------------------------------------------------------
# Steg 1: Rens tidlegare genererte domene-katalogar frå docs/
# ---------------------------------------------------------------------------
log_step "Steg 1: Rens tidlegare genererte domene-katalogar frå docs/"
t1=$(now_ms)

if [ ! -d "$GEN" ] || [ -z "$(ls -A "$GEN" 2>/dev/null)" ]; then
    log_error "Ingen genererte artefakter funne i $GEN. Køyr make <domain> fyrst."
    exit 1
fi

clean_previous_docs() {
    for domain_dir in "$GEN"/*/; do
        [ -d "$domain_dir" ] || continue
        # Hopp over tomme domene-katalogar (ingen skjema-underkatalogar)
        schema_count=$(find "$domain_dir" -mindepth 1 -maxdepth 1 -type d | wc -l)
        [ "$schema_count" -eq 0 ] && continue
        domain=$(basename "$domain_dir")
        # Åtvar om domenet finst i generated/ men ikkje i src/linkml/ (stale artefakter)
        if [ ! -d "$REPO_ROOT/src/linkml/$domain" ]; then
            log_info "${CLR_WARN}ÅTVARING: $domain finst i generated/ men ikkje i src/linkml/ — stale artefakter frå omdøypt domene?${CLR_RST}"
        fi
        log_debug "→ Slettar $DOCS/$domain"
        find "${DOCS}/${domain}" -mindepth 1 -depth -delete 2>/dev/null || true
        rmdir "${DOCS}/${domain}" 2>/dev/null || true
    done

    # Slett mkdocs/docs/$domain/ for domene som ikkje lenger finst i generated/
    for docs_domain_dir in "$DOCS"/*/; do
        [ -d "$docs_domain_dir" ] || continue
        domain=$(basename "$docs_domain_dir")
        case "$domain" in
            stylesheets|javascripts|kom-i-gang|arkitektur|publisering|automasjon|modellanalyse) continue ;;
        esac
        if [ ! -d "$GEN/$domain" ]; then
            log_info "Ryddar forsvunne domene: $domain"
            rm -rf "$docs_domain_dir"
        fi
    done
}

timed_run "Rens tidlegare genererte domene-katalogar" clean_previous_docs

# Generer byggetidspunkt (ISO 8601 UTC), nødvendig for footer-en
# write_index_from_readme() skriv rett under
BUILD_TIMESTAMP=$(TZ="Europe/Oslo" date +"%Y-%m-%d %H:%M %Z")

# README-tabellgenerering, README→index.md og valideringsregler.md avheng
# ikkje av noko frå Steg 2 (statiske kjeldefiler, arkitektur/ er kvitelista
# i Steg 1 sin opprydding) — flytta hit for å unngå unødig venting etter
# det tunge parallelle skjema-arbeidet. Kvart kall tidtakast og loggast
# individuelt via timed_run() (frå LOG_FUNCTIONS, make/00-settings.mk) i
# staden for eit samla steg-tal. Inngår i Steg 1 sin samla tidtaking —
# "✓ Steg 1 ferdig" loggast fyrst etter Steg 1.4/1.5 lenger ned, slik at
# ho står som siste linje av Steg 1 rett før Steg 2-banneret. Sjå
# specs/done/flytt-steg3-til-steg1-med-timing.md og
# specs/done/flytt-readme-tabellar-inn-i-publish-sh.md.
#
# README-tabellgenereringa må køyrast FØR write_index_from_readme, sidan
# index.md vert kopiert direkte frå README.md — elles kopierer
# write_index_from_readme ein utdatert versjon av tabellane.
# Tabellane vert genererte på språket til kvar README (README.md og
# README.<lang>.md) — sjå specs/done/engelsk-framside-genererte-tabellar.md.
update_readme_tables() {
    local lang readme
    for lang in $I18N_LANGUAGES; do
        if [ "$lang" = "$I18N_DEFAULT_LANG" ]; then
            readme="$REPO_ROOT/README.md"
        else
            readme="$REPO_ROOT/README.$lang.md"
            [ -f "$readme" ] || continue
        fi
        bash "$REPO_ROOT/src/assets/scripts/makefile/generate-readme-tables.sh" "$readme" "$lang"
    done
}
timed_run "Oppdater README-tabellar" update_readme_tables
timed_run "Generer index.md frå README.md" write_index_from_readme
timed_run "Generer valideringsregler.md" generate_validation_docs
timed_run "Generer modellanalyse-tvers-domene-sider" generate_cross_domain_modellanalyse_docs

# ---------------------------------------------------------------------------
# Steg 1.4: Finn domene/skjema-struktur frå generated/
# ---------------------------------------------------------------------------
# Flytta hit frå (tidlegare) Steg 2 — denne enumereringa avheng berre av
# $GEN, ikkje av noko bygd i Steg 1.5, og Steg 1.5 treng no
# ALL_DOMAINS/DOMAIN_SCHEMA_LIST for å byggje input til det samla
# metadata-kallet. Sjå specs/backlog/reduser-podman-kall-docs-publish.md.
#
# Tidteke som eige delsteg (manuell t/elapsed, ikkje timed_run) sidan
# ALL_DOMAINS/DOMAIN_SCHEMA_LIST/DOMAIN_EXISTS må vere synlege i
# hovudshell-scope etter blokka — ei `declare -a`/`declare -A` inni ein
# bash-funksjon utan `-g` ville gjort desse lokale og usynlege for Steg
# 1.5/2/3. Sjå specs/done/tidtaking-steg1-4-1-5-docs-publish.md.
t1_4=$(now_ms)
declare -a ALL_DOMAINS=()
declare -A DOMAIN_SCHEMA_LIST=()

# Hardkoda rekkefølgje på domene i nav-menyen
DOMAIN_ORDER=("felles" "referanse" "ap-no" "fair" "ngr" "oreg" "fint" "samt" "begrepskatalog" "modellkatalog")

# Samle domene/skjema-struktur frå generated/ — bygg opp DOMAIN_SCHEMA_LIST for alle domene
declare -A DOMAIN_EXISTS=()
for domain_dir in $(find "$GEN" -mindepth 1 -maxdepth 1 -type d); do
    domain=$(basename "$domain_dir")
    schemas=()
    for schema_dir in $(find "$domain_dir" -mindepth 1 -maxdepth 1 -type d | sort); do
        schema=$(basename "$schema_dir")

        # Hopp over *-schema-katalogar dersom tilsvarande katalog utan -schema finst
        # (indikerer dublett: både data og schema generert frå same kjeldekatalog)
        if [[ "$schema" == *-schema ]]; then
            base_schema="${schema%-schema}"
            if [ -d "$domain_dir/$base_schema" ]; then
                continue
            fi
        fi

        schemas+=("$schema")
    done
    [ "${#schemas[@]}" -eq 0 ] && continue
    DOMAIN_EXISTS[$domain]=1
    DOMAIN_SCHEMA_LIST[$domain]="${schemas[*]:-}"
done

# Bygg ALL_DOMAINS i hardkoda rekkefølgje, deretter alfabetisk for resten
for domain in "${DOMAIN_ORDER[@]}"; do
    if [ "${DOMAIN_EXISTS[$domain]:-0}" = "1" ]; then
        ALL_DOMAINS+=("$domain")
        unset DOMAIN_EXISTS[$domain]
    fi
done

# Legg til resterande domene (ikkje i DOMAIN_ORDER) i alfabetisk rekkefølgje
for domain in $(printf '%s\n' "${!DOMAIN_EXISTS[@]}" | sort); do
    ALL_DOMAINS+=("$domain")
done

elapsed1_4_ms=$(( $(now_ms) - t1_4 ))
log_info "$(printf "${CLR_STEP}→ Steg 1.4: Finn domene/skjema-struktur${CLR_RST} (%s)" \
    "$(fmt_elapsed_ms "$elapsed1_4_ms")")"

# ---------------------------------------------------------------------------
# Steg 1.5: Bygg delmodell-/metadata-oppslag
# ---------------------------------------------------------------------------
# Same grunngjeving som Steg 1.4 for manuell t/elapsed i staden for
# timed_run: SCHEMA_PARENT_MODEL/SCHEMA_SUBMODELS m.fl. må vere synlege i
# hovudshell-scope for Steg 2/3.
t1_5=$(now_ms)

# Bruk assosiative arrays som må eksporterast manuelt til subshells
declare -A SCHEMA_PARENT_MODEL_TMP=()
declare -A SCHEMA_SUBMODELS_TMP=()

# Globalt oppslag skjemanavn → domene og → filsti, bygd éin gong for heile
# repoet. Erstattar gjentekne whole-tree `find "$REPO_ROOT/src/linkml" -name
# "<navn>-schema.yaml"`-kall i classes.sh/avhengigheiter.sh (kvart slikt
# find-kall er dyrt på NTFS-monterte /mnt/c-filsystem under WSL2 — sjå
# specs/backlog/batch-docs-publish-generering.md for profilering).
# Filstien vert lagra direkte (ikkje rekonstruert frå katalogkonvensjonen)
# fordi delmodell-skjema (t.d. dqv-core-schema.yaml) ligg i FORELDREskjemaet
# sin katalog (dqv-ap-no/), ikkje i ein katalog oppkalla etter seg sjølv.
declare -A SCHEMA_NAME_TO_DOMAIN_TMP=()
declare -A SCHEMA_NAME_TO_PATH_TMP=()
for schema_yaml in $(find "$REPO_ROOT/src/linkml" -name '*-schema.yaml'); do
    schema_name=$(basename "$schema_yaml" .yaml)
    domain=$(basename "$(dirname "$(dirname "$schema_yaml")")")
    SCHEMA_NAME_TO_DOMAIN_TMP["$schema_name"]="$domain"
    SCHEMA_NAME_TO_PATH_TMP["$schema_name"]="$schema_yaml"
done

export SCHEMA_NAME_TO_DOMAIN_SERIALIZED=""
for key in "${!SCHEMA_NAME_TO_DOMAIN_TMP[@]}"; do
    SCHEMA_NAME_TO_DOMAIN_SERIALIZED+="$key=${SCHEMA_NAME_TO_DOMAIN_TMP[$key]} "
done

export SCHEMA_NAME_TO_PATH_SERIALIZED=""
for key in "${!SCHEMA_NAME_TO_PATH_TMP[@]}"; do
    SCHEMA_NAME_TO_PATH_SERIALIZED+="$key=${SCHEMA_NAME_TO_PATH_TMP[$key]} "
done

# Samla metadata-innhenting: EIN containerprosess (collect-schema-metadata.py)
# for ALLE skjema, i staden for opptil ~211 separate `podman run`-kall (éin
# per submodels-oppslag/skjema-felt) — kvart `podman run`-kall har ~2,7s
# eigen container-oppstartskostnad, målt direkte. Sjå
# specs/backlog/reduser-podman-kall-docs-publish.md for profilering og
# grunngjeving.
#
# Input (stdin, éi linje per skjema i DOMAIN_SCHEMA_LIST): felt skilde med
# \x1f — domain, schema, schema_file (container-sti, tom viss ikkje funnen),
# manifest_path (container-sti, tom viss build.yaml ikkje finst).
SCHEMA_METADATA_INPUT=""
for domain in "${ALL_DOMAINS[@]}"; do
    for schema in ${DOMAIN_SCHEMA_LIST[$domain]:-}; do
        schema_file_path=$(lookup_schema_path "${schema}-schema") || schema_file_path=""
        schema_file_container=""
        [ -n "$schema_file_path" ] && schema_file_container=$(to_container_path "$schema_file_path")

        manifest_path="$REPO_ROOT/src/linkml/${domain}/${schema}/build.yaml"
        manifest_container=""
        [ -f "$manifest_path" ] && manifest_container=$(to_container_path "$manifest_path")

        SCHEMA_METADATA_INPUT+="${domain}$(printf '\x1f')${schema}$(printf '\x1f')${schema_file_container}$(printf '\x1f')${manifest_container}"$'\n'
    done
done

COLLECT_OUTPUT=$(printf '%s' "$SCHEMA_METADATA_INPUT" | run_python_container /work/mkdocs/lib/scripts/collect-schema-metadata.py)

# Splitt output i dei tre seksjonane scriptet skriv (### SUBMODELS /
# ### SCHEMAS / ### ORGS), kvar linje felt-skilt med \x1f.
SUBMODELS_SECTION=""
SCHEMAS_SECTION=""
ORGS_SECTION=""
collect_mode=""
while IFS= read -r collect_line; do
    case "$collect_line" in
        "### SUBMODELS") collect_mode="submodels"; continue ;;
        "### SCHEMAS") collect_mode="schemas"; continue ;;
        "### ORGS") collect_mode="orgs"; continue ;;
    esac
    case "$collect_mode" in
        submodels) SUBMODELS_SECTION+="$collect_line"$'\n' ;;
        schemas) SCHEMAS_SECTION+="$collect_line"$'\n' ;;
        orgs) ORGS_SECTION+="$collect_line"$'\n' ;;
    esac
done <<< "$COLLECT_OUTPUT"

# Bygg SCHEMA_SUBMODELS_TMP/SCHEMA_PARENT_MODEL_TMP frå SUBMODELS-seksjonen
# (same semantikk som den tidlegare 41-kalls-sekvensielle løkka)
while IFS=$'\x1f' read -r schema_key submodels_csv; do
    [ -z "$schema_key" ] && continue
    SCHEMA_SUBMODELS_TMP["$schema_key"]="$submodels_csv"
    IFS=',' read -ra sub_array <<< "$submodels_csv"
    for sub in "${sub_array[@]}"; do
        SCHEMA_PARENT_MODEL_TMP["$sub"]="$schema_key"
    done
done <<< "$SUBMODELS_SECTION"

# Eksporter per-skjema metadata og CODEOWNERS-org-registeret til subshells
# — konsumert via lookup_schema_metadata_line()/lookup_org_name() i
# mkdocs/lib/utils/imported_schemas.sh
export SCHEMA_METADATA_SERIALIZED="$SCHEMAS_SECTION"
export ORG_URI_TO_NAME_SERIALIZED="$ORGS_SECTION"

# Serialiser delmodell-map til miljøvariablar for eksport til subshells
export SCHEMA_PARENT_MODEL_SERIALIZED=""
for key in "${!SCHEMA_PARENT_MODEL_TMP[@]}"; do
    SCHEMA_PARENT_MODEL_SERIALIZED+="$key=${SCHEMA_PARENT_MODEL_TMP[$key]} "
done

export SCHEMA_SUBMODELS_SERIALIZED=""
for key in "${!SCHEMA_SUBMODELS_TMP[@]}"; do
    SCHEMA_SUBMODELS_SERIALIZED+="$key=${SCHEMA_SUBMODELS_TMP[$key]} "
done

# Bygg lokale map for bruk i hovudshell (nav-generering)
declare -A SCHEMA_PARENT_MODEL=()
declare -A SCHEMA_SUBMODELS=()
for entry in $SCHEMA_PARENT_MODEL_SERIALIZED; do
    key="${entry%%=*}"
    val="${entry#*=}"
    SCHEMA_PARENT_MODEL["$key"]="$val"
done
for entry in $SCHEMA_SUBMODELS_SERIALIZED; do
    key="${entry%%=*}"
    val="${entry#*=}"
    # Behald komma-separering i SCHEMA_SUBMODELS-map
    SCHEMA_SUBMODELS["$key"]="$val"
done

elapsed1_5_ms=$(( $(now_ms) - t1_5 ))
log_info "$(printf "${CLR_STEP}→ Steg 1.5: Bygg delmodell-/metadata-oppslag${CLR_RST} (%s)" \
    "$(fmt_elapsed_ms "$elapsed1_5_ms")")"

elapsed1_ms=$(( $(now_ms) - t1 ))
log_info "$(printf "${CLR_OK}✓ Steg 1 ferdig${CLR_RST} (%s)" \
    "$(fmt_elapsed_ms "$elapsed1_ms")")"

# ---------------------------------------------------------------------------
# Steg 2: Generer innhald per domene og skjema (parallelt)
# ---------------------------------------------------------------------------
# generate_domain_content — skjemasider, domeneoversikter og utbyting av
# i18n-markørar for gjeldande språk ($I18N_LANG) inn i $DOCS. Køyrd éin gong
# per språk (Steg 2 og 2b).
generate_domain_content() {
    # Start alle skjemajobbar parallelt
    local -a PIDS=() KEYS=() failed_jobs=() DOMAIN_DOCS_DIRS=()
    for domain in "${ALL_DOMAINS[@]}"; do
        for schema in ${DOMAIN_SCHEMA_LIST[$domain]:-}; do
            process_schema "$domain" "$schema" &
            PIDS+=($!)
            KEYS+=("$domain/$schema")
        done
    done

    # Vent på alle jobbar og rapporter feil
    for i in "${!PIDS[@]}"; do
        if ! wait "${PIDS[$i]}"; then
            domain_schema="${KEYS[$i]}"
            domain="${domain_schema%/*}"
            schema="${domain_schema#*/}"

            log_error "$domain/$schema (Domain: $domain, Schema: $schema, Output: $DOCS/$domain/$schema/)"

            failed_jobs+=("$domain/$schema")
        fi
    done

    if [ ${#failed_jobs[@]} -gt 0 ]; then
        failed_list=$(printf '  - %s\n' "${failed_jobs[@]}")
        log_error "OPPSUMMERING: ${#failed_jobs[@]} skjema feila:
    ${failed_list}"
        exit 1
    fi

    # Generer domain/index.md sekvensielt (avheng av at alle skjema er ferdige)
    for domain in "${ALL_DOMAINS[@]}"; do
        # Sjekk om noko skjema i domenet har eit publisert URI-register
        domain_has_published=false
        for schema in ${DOMAIN_SCHEMA_LIST[$domain]:-}; do
            [ -f "$REPO_ROOT/src/linkml/$domain/$schema/published-uris.lock" ] && domain_has_published=true && break
        done

        {
            echo "# $(domain_label "$domain")"
            echo ""
            generate_domain_description "$domain"
            if $domain_has_published; then
                echo "| $(t domeneoversikt.modell) | $(t domeneoversikt.artefakter) | $(t domeneoversikt.publisert_til) |"
                echo "|--------|--------------------------|---------------|"
            else
                echo "| $(t domeneoversikt.modell) | $(t domeneoversikt.artefakter) |"
                echo "|--------|--------------------------|"
            fi

            for schema in ${DOMAIN_SCHEMA_LIST[$domain]:-}; do
                artifacts=""
                for suffix in $ARTIFACT_ORDER; do
                    if [ -f "$GEN/$domain/$schema/${schema}-${suffix}" ]; then
                        [ -n "$artifacts" ] && artifacts+=" · "
                        artifacts+="$(artifact_label "$suffix")"
                    fi
                done
                if [ -f "$GEN/$domain/$schema/diagrams/${schema}-filtered.svg" ] || [ -f "$GEN/$domain/$schema/diagrams/${schema}-filtered.puml" ] || \
                   [ -f "$GEN/$domain/$schema/diagrams/${schema}.svg" ] || [ -f "$GEN/$domain/$schema/diagrams/${schema}.puml" ]; then
                    [ -n "$artifacts" ] && artifacts+=" · "
                    artifacts+="$(t artefakt.plantuml)"
                fi
                if $domain_has_published; then
                    published_col=""
                    [ -f "$REPO_ROOT/src/linkml/$domain/$schema/published-uris.lock" ] && \
                        published_col="[Felles Begrepskatalog](https://data.norge.no/concepts)"
                    echo "| [${schema}](${schema}/index.md) | ${artifacts:--} | ${published_col} |"
                else
                    echo "| [${schema}](${schema}/index.md) | ${artifacts:--} |"
                fi
            done
        } > "$DOCS/$domain/index.md"
    done

    # Byt ut i18n-markørar (@@i18n:<nøkkel>@@) frå gen-doc-malane og seksjonane
    # som siste transformasjon — classes.sh/metadata.sh/badges.sh parsar
    # gen-doc-outputen på markørane, ikkje på omsett tekst. Sjå steg 5 i
    # specs/done/lokalisering-dokumentasjonsportal.md.
    for domain in "${ALL_DOMAINS[@]}"; do DOMAIN_DOCS_DIRS+=("$DOCS/$domain"); done
    timed_run "Byt ut i18n-markørar" python3 "$LIB_DIR/scripts/i18n_strings.py" render-tree --lang "$I18N_LANG" "${DOMAIN_DOCS_DIRS[@]}"
}

log_step "Steg 2: Generer innhald per domene og skjema (parallelt)"
t2=$(now_ms)
generate_domain_content
log_info "${CLR_OK}Publisert ${#ALL_DOMAINS[@]} domene(r) til mkdocs/docs/${CLR_RST}"

elapsed2_ms=$(( $(now_ms) - t2 ))
log_info "$(printf "${CLR_OK}✓ Steg 2 ferdig${CLR_RST} (%s)" \
    "$(fmt_elapsed_ms "$elapsed2_ms")")"

# ---------------------------------------------------------------------------
# Steg 2b: Arbeidstre for andre språk (mkdocs/build/src-<lang>)
# ---------------------------------------------------------------------------
# Same språkavhengige generering som for standardspråket (mkdocs/docs), med
# tekst frå strengkatalogen for <lang>. Statiske sider: x.<lang>.md dersom ho
# finst, elles den nynorske sida med merknaden «ikkje omsett». Sjå steg 6 i
# specs/done/lokalisering-dokumentasjonsportal.md.
BUILD_DIR="$REPO_ROOT/mkdocs/build"
DEFAULT_DOCS="$DOCS"
# Sider publish.sh genererer i docs-treet (ikkje omsetjingskjelder) — same
# liste som GENERATED_DOCS_PATHS i mkdocs/lib/scripts/i18n_status.py.
GENERATED_DOCS_PATHS=("index.md" "arkitektur/valideringsregler.md" "modellanalyse")

# copy_static_docs_for_language <kjelde-docs> <mål-docs> — kopier statisk
# innhald (ikkje genererte domene/sider) for $I18N_LANG.
copy_static_docs_for_language() {
    local src="$1" dst="$2" rel file variant skip l
    local -a exclude=("${ALL_DOMAINS[@]}" "${GENERATED_DOCS_PATHS[@]}")
    while IFS= read -r -d '' file; do
        rel="${file#"$src"/}"
        skip=false
        for l in "${exclude[@]}"; do
            [[ "$rel" == "$l" || "$rel" == "$l/"* ]] && skip=true && break
        done
        $skip && continue
        # Språkvariantar (x.<lang>.md) vert berre brukte i staden for x.md
        for l in $I18N_LANGUAGES; do
            [[ "$rel" == *".$l.md" ]] && skip=true && break
        done
        $skip && continue
        mkdir -p "$dst/$(dirname "$rel")"
        if [[ "$rel" == *.md ]]; then
            variant="${file%.md}.$I18N_LANG.md"
            if [[ -f "$variant" ]]; then
                i18n_strip_front_matter "$variant" > "$dst/$rel"
            else
                cp "$file" "$dst/$rel"
                i18n_note_untranslated "$dst/$rel"
            fi
        else
            cp "$file" "$dst/$rel"
        fi
    done < <(find "$src" -type f -print0)
}

for lang in $I18N_LANGUAGES; do
    [ "$lang" = "$I18N_DEFAULT_LANG" ] && continue
    log_step "Steg 2b: Arbeidstre for språk: $lang"
    t2b=$(now_ms)
    DOCS="$BUILD_DIR/src-$lang"
    rm -rf "$DOCS"
    mkdir -p "$DOCS"
    i18n_load "$lang"
    timed_run "[$lang] Kopier statiske sider" copy_static_docs_for_language "$DEFAULT_DOCS" "$DOCS"
    timed_run "[$lang] Generer index.md frå README.md" write_index_from_readme
    timed_run "[$lang] Generer valideringsregler.md" generate_validation_docs
    timed_run "[$lang] Generer modellanalyse-tvers-domene-sider" generate_cross_domain_modellanalyse_docs
    generate_domain_content
    log_info "$(printf "${CLR_OK}✓ Steg 2b ferdig for %s${CLR_RST} (%s)" "$lang" \
        "$(fmt_elapsed_ms "$(( $(now_ms) - t2b ))")")"
done
DOCS="$DEFAULT_DOCS"

# ---------------------------------------------------------------------------
# Steg 2c: Byggjetre per språk (mkdocs/build/<lang>, mkdocs/build/rot)
# ---------------------------------------------------------------------------
# Adressestruktur L2 (O6): sider under /<lang>/, artefakter på dagens sti
# utan språkprefiks (A0), vidaresendingssider for gamle adresser. 404-sida
# vert rendra per språk til mkdocs/build/overrides-<lang>/.
log_step "Steg 2c: Byggjetre per språk (L2)"
t2c=$(now_ms)
TREE_SOURCES=()
for lang in $I18N_LANGUAGES; do
    i18n_load "$lang"
    mkdir -p "$BUILD_DIR/overrides-$lang"
    timed_run "[$lang] Generer 404-side" i18n_render "$LIB_DIR/templates/404.html" "$BUILD_DIR/overrides-$lang/404.html"
    if [ "$lang" = "$I18N_DEFAULT_LANG" ]; then
        TREE_SOURCES+=(--source "$lang=$DEFAULT_DOCS")
    else
        TREE_SOURCES+=(--source "$lang=$BUILD_DIR/src-$lang")
    fi
done
i18n_load
timed_run "Byggjetre (språk, artefakter, vidaresendingar)" python3 "$LIB_DIR/scripts/build_language_trees.py" \
    --default "$I18N_DEFAULT_LANG" "${TREE_SOURCES[@]}" --domains "${ALL_DOMAINS[@]}" --out "$BUILD_DIR"
log_info "$(printf "${CLR_OK}✓ Steg 2c ferdig${CLR_RST} (%s)" "$(fmt_elapsed_ms "$(( $(now_ms) - t2c ))")")"

# ---------------------------------------------------------------------------
# Steg 3: Generer mkdocs.yml
# ---------------------------------------------------------------------------
# write_mkdocs_config <fil> <docs_dir> <site_url> <custom_dir> <site_dir|-> <alternate:true|false>
# Skriv ein mkdocs-konfig for gjeldande språk ($I18N_LANG): tittel, copyright
# og nav-etikettar frå strengkatalogen, og språkveljar (extra.alternate) når
# <alternate> er true. Sjå steg 7-8 i specs/done/lokalisering-dokumentasjonsportal.md.
write_mkdocs_config() {
    local out="$1" docs_dir="$2" site_url="$3" custom_dir="$4" site_dir="$5" alternate="$6"
    local base_path="${PORTAL_URL#https://*/}"
    local alle_domene
    alle_domene=$(t nav.alle_domene)
    {
        echo "site_name:  $(t portal.site_name)"
        echo "site_description: $(t portal.site_description)"
        echo "site_url: ${site_url}"
        echo "docs_dir: ${docs_dir}"
        [ "$site_dir" != "-" ] && echo "site_dir: ${site_dir}"
        echo "copyright: >"
        echo "  $(t portal.copyright_1 lenkje="https://github.com/AudunAutomat/linkml-datamodellering-no/blob/main/LICENSE")"
        echo "  $(t portal.copyright_2)"
        echo ""
        cat << STATIC
theme:
  name: material
  custom_dir: ${custom_dir}
  language: ${I18N_LANG}
  features:
    - navigation.indexes
    - navigation.top
    - content.code.copy
    # - navigation.instant  # mellombels av: test om dette er årsaka til at
    #   TOC-aktiv-klasse-fiksen (toc-active-click-fix.js) ikkje verkar —
    #   sjå specs/backlog/toc-aktivt-element-ved-klikk.md
    - toc.follow
  palette:
    - scheme: default
      primary: indigo
      accent: indigo

plugins:
  - search

extra_css:
  - stylesheets/brreg-theme.css              # Brønnøysund designsystem-tema (NPM-pakke, kombinert)
  - stylesheets/brreg-material-overrides.css # Material-overrides
  - stylesheets/responsivt-design.css

extra_javascript:
  - javascripts/toc-active-click-fix.js # Umiddelbar aktiv-markering av TOC-lenkje ved klikk

markdown_extensions:
  - admonition
  - tables
  - attr_list
  - pymdownx.details
  - pymdownx.highlight:
      anchor_linenums: true
  - pymdownx.inlinehilite
  - pymdownx.snippets
  - pymdownx.superfences:
      custom_fences:
        - name: mermaid
          class: mermaid
          format: !!python/name:pymdownx.superfences.fence_code_format

# gen-doc genererer systematiske fragment-lenkjer utan filnavn (t.d.
# ../../ap-no/dcat-ap-no/#classes i staden for .../index.md#classes) som
# mkdocs ikkje kjenner att som interne lenkjer. Denne åtvaringa er ikkje
# kritisk og vert undertrykka her. Merk: dette dekkjer ikkje mermaid
# click-hrefs (klikkbare lenkjer i klassediagram) — mkdocs sin
# lenkje-validator ser berre rendra <a href>-element, ikkje rå tekst inni
# fenced code-blokker, sjå specs/backlog/mermaid-klikkbare-lenker-404.md.
validation:
  links:
    not_found: warn
    unrecognized_links: ignore
  nav:
    omitted_files: ignore

STATIC
        if [ "$alternate" = true ]; then
            echo "extra:"
            echo "  alternate:"
            local l
            for l in $I18N_LANGUAGES; do
                echo "    - name: ${I18N_LANGUAGE_NAMES[$l]}"
                echo "      link: /${base_path}/${l}/"
                echo "      lang: ${l}"
            done
            echo ""
        fi
        echo "nav:"
        echo "  - $(t nav.rettleiingar):"
        echo "      - index.md"
        echo "      - $(t nav.kom_i_gang):"
        echo "          - kom-i-gang/index.md"
        echo "          - $(t nav.bli_modelleigar): kom-i-gang/ny-org.md"
        echo "          - $(t nav.ny_domenemodell): kom-i-gang/ny-domenemodell.md"
        echo "          - $(t nav.ny_begrepskatalog): kom-i-gang/ny-begrepsmodell.md"
        echo "          - $(t nav.byggmanifest): kom-i-gang/build-config.md"
        echo "          - $(t nav.kommandooversikt): kom-i-gang/kommandoar.md"
        echo "      - $(t nav.arkitektur):"
        echo "          - arkitektur/index.md"
        echo "          - $(t nav.arkitekturoversikt): arkitektur/arkitektur-oversikt.md"
        echo "          - $(t nav.importhierarki): arkitektur/importhierarki.md"
        echo "          - $(t valideringsreglar.tittel): arkitektur/valideringsregler.md"
        echo "          - $(t nav.ap_no_arkitektur): arkitektur/ap-no-arkitektur.md"
        echo "          - $(t nav.standardetterleving): arkitektur/standardetterleving.md"
        echo "          - $(t nav.ekstern_bruk): arkitektur/ekstern-bruk.md"
        echo "      - $(t nav.publisering):"
        echo "          - publisering/index.md"
        echo "          - $(t nav.publiseringsflyt): publisering/publisering-oversikt.md"
        echo "          - $(t nav.publiser_begrep): publisering/publisering-begrep.md"
        echo "          - $(t nav.publiser_modell): publisering/publisering-modell.md"
        echo "      - $(t nav.automasjon):"
        echo "          - automasjon/index.md"
        echo "          - $(t nav.artefaktgenerering): automasjon/artefakt-generering.md"
        echo "          - $(t nav.modelldokumentasjon): automasjon/index-md-struktur.md"
        echo "          - $(t nav.modellmanifest): automasjon/modellmanifest-generering.md"
        echo "          - $(t nav.readme_tabellar): automasjon/readme-tabellgenerering.md"
        echo "          - $(t nav.monitorering): automasjon/monitorering.md"
        echo "          - $(t nav.fleirsprak): automasjon/fleirsprak.md"
        echo "      - $(t seksjon.modellanalyse.tittel):"
        echo "          - modellanalyse/index.md"
        echo "          - $(t modellanalyse.liknande_klassenavn.tittel) (${alle_domene}): modellanalyse/liknande-klassenavn-alle-domene.md"
        echo "          - $(t modellanalyse.liknande_slotnavn.tittel) (${alle_domene}): modellanalyse/liknande-slotnavn-alle-domene.md"
        echo "          - $(t modellanalyse.liknande_typenavn.tittel) (${alle_domene}): modellanalyse/liknande-typenavn-alle-domene.md"
        echo "      - $(t nav.om): om.md"

        for domain in "${ALL_DOMAINS[@]}"; do
            label=$(domain_label "$domain")
            echo "  - '${label}':"
            echo "      - ${domain}/index.md"

            schemas_str="${DOMAIN_SCHEMA_LIST[$domain]:-}"
            for schema in $schemas_str; do
                # Hopp over delmodellar — dei vert lagt til under hovudmodellen
                [ -n "${SCHEMA_PARENT_MODEL[$schema]:-}" ] && continue

                echo "      - '${schema}': ${domain}/${schema}/index.md"

                # Legg til delmodellar innrykka under hovudmodell (submodels er komma-separert)
                submodels="${SCHEMA_SUBMODELS[$schema]:-}"
                if [ -n "$submodels" ]; then
                    IFS=',' read -ra sub_array <<< "$submodels"
                    for sub in "${sub_array[@]}"; do
                        echo "      - '${sub}': ${domain}/${sub}/index.md"
                    done
                fi
            done
        done
    } > "$out"
}

log_step "Steg 3: Generer mkdocs.yml"
t4=$(now_ms)

# mkdocs/build/mkdocs.<lang>.yml (L2: /<lang>/, språkveljar) — stiane er
# relative til mkdocs/build/, som `make docs-build`/`docs-serve` monterer.
for lang in $I18N_LANGUAGES; do
    i18n_load "$lang"
    write_mkdocs_config "$BUILD_DIR/mkdocs.$lang.yml" "$lang" "$PORTAL_URL/$lang/" "overrides-$lang" "site/$lang" true
    log_info "${CLR_OK}Oppdatert mkdocs/build/mkdocs.$lang.yml${CLR_RST}"
done
i18n_load

# Språkliste for make docs-build/docs-serve (sourcast av make/50-docs.mk)
printf 'DOCS_LANGUAGES=%q\nDOCS_DEFAULT_LANGUAGE=%q\nDOCS_BASE_PATH=%q\n' \
    "$I18N_LANGUAGES" "$I18N_DEFAULT_LANG" "${PORTAL_URL#https://*/}" > "$BUILD_DIR/languages.env"
log_info "${CLR_OK}Oppdatert mkdocs/build/languages.env${CLR_RST}"

elapsed4_ms=$(( $(now_ms) - t4 ))
log_info "$(printf "${CLR_OK}✓ Steg 3 ferdig${CLR_RST} (%s)" \
    "$(fmt_elapsed_ms "$elapsed4_ms")")"
