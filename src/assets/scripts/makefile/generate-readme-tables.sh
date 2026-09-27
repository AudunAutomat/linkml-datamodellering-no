#!/usr/bin/env bash
# Genererer skjema-tabell, begrepskatalog-tabell og modellkatalog-tabell for README.md
# Køyr: src/assets/scripts/makefile/generate-readme-tables.sh [README-fil] [språk]
# Output: Oppdatert README-fil med auto-genererte tabellar
#
# Tabelltekst kjem frå strengkatalogen (mkdocs/lib/i18n/strings.yaml, nøklane
# readme_tabell.*). Utan språk vert standardspråket brukt. For andre språk
# (t.d. README.en.md) peikar portal-lenkjene på /<språk>/. Skildringa av
# skjemaa er modellinnhald og vert ikkje omsett. Sjå
# specs/done/engelsk-framside-genererte-tabellar.md.

set -euo pipefail
trap 'echo "ERROR in ${BASH_SOURCE[0]}:${LINENO} — command: ${BASH_COMMAND}" >&2; exit 1' ERR

: "${LOG_FUNCTIONS:?miljøvariabelen LOG_FUNCTIONS må vere sett}"
eval "$LOG_FUNCTIONS"

README="${1:-README.md}"
LANG_ARG="${2:-}"

if [[ ! -f "$README" ]]; then
  log_error "$README finst ikkje"
  exit 1
fi

log_info "Genererer auto-genererte tabellar for $README..."

# Katalog for støttescripts
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# Strengkatalogen for tabellteksten
export REPO_ROOT="${REPO_ROOT:-$(cd "$SCRIPT_DIR/../../../.." && pwd)}"
source "$REPO_ROOT/mkdocs/lib/utils/i18n.sh"
i18n_load "$LANG_ARG"

# Portal-base for lenkjene: standardspråket på rota (vidaresending til
# /<standardspråk>/), andre språk direkte under /<språk>/.
GHPAGES_BASE="https://audunautomat.github.io/linkml-datamodellering-no"
if [[ "$I18N_LANG" == "$I18N_DEFAULT_LANG" ]]; then
  PORTAL_BASE="$GHPAGES_BASE"
else
  PORTAL_BASE="$GHPAGES_BASE/$I18N_LANG"
fi

# Tabelltekst — tilordna til variablar slik at ein manglande nøkkel stoppar
# scriptet (set -e), i staden for å verte svelgd inne i echo.
H_DOMENE=$(t readme_tabell.domene)
H_SKJEMA=$(t readme_tabell.skjema)
H_SKILDRING=$(t readme_tabell.skildring)
H_DOKUMENTASJON=$(t readme_tabell.dokumentasjon)
H_ORGANISASJON=$(t readme_tabell.organisasjon)
H_GENERATOR=$(t readme_tabell.generator)
H_BEGREPSKATALOG=$(t readme_tabell.begrepskatalog)
H_MODELLKATALOG=$(t readme_tabell.modellkatalog)
UKJEND_ORG=$(t readme_tabell.ukjend_org)

# Opprett temp-fil
TEMP_README=$(mktemp)

# --- Funksjon: Uppercase domenenavn for tabellvising ---
domain_short_label() {
  echo "$1" | tr '[:lower:]' '[:upper:]'
}

# --- Funksjon: Generer skjema-tabell ---
generate_schema_table() {
  echo "| $H_DOMENE | $H_SKJEMA | $H_SKILDRING | $H_DOKUMENTASJON"
  echo "|---|---|---|---|"

  # Domene-rekkefølgje (same som i domene-tabellen)
  DOMAIN_ORDER=("felles" "fair" "ap-no" "referanse" "ngr" "oreg" "fint" "samt")

  # Bygg assosiativ array: domain -> liste av skjema-filer
  declare -A DOMAIN_SCHEMAS

  while IFS= read -r schema_file; do
    domain=$(echo "$schema_file" | cut -d'/' -f3)

    # Hopp over modellkatalog og begrepskatalog (handterast separat)
    [[ "$domain" == "modellkatalog" ]] && continue
    [[ "$domain" == "begrepskatalog" ]] && continue

    schema_dir=$(dirname "$schema_file")
    schema_name=$(basename "$schema_dir")
    schema_basename=$(basename "$schema_file" "-schema.yaml")

    # Berre inkluder hovudskjema (der filnavn matcher katalognavn)
    # t.d. modelldcat-ap-no/modelldcat-ap-no-schema.yaml (OK)
    # relevant for eit evt. framtidig submodels:-tilfelle (sjå build-config.md)
    [[ "$schema_basename" != "$schema_name" ]] && continue

    # Legg til skjema i domenet sin liste
    if [[ -z "${DOMAIN_SCHEMAS[$domain]:-}" ]]; then
      DOMAIN_SCHEMAS[$domain]="$schema_file"
    else
      DOMAIN_SCHEMAS[$domain]="${DOMAIN_SCHEMAS[$domain]}"$'\n'"$schema_file"
    fi
  done < <(find src/linkml -name "*-schema.yaml" -type f | sort)

  # Iterer gjennom domene i riktig rekkefølgje
  for domain in "${DOMAIN_ORDER[@]}"; do
    # Hopp over domene utan skjema
    [[ -z "${DOMAIN_SCHEMAS[$domain]:-}" ]] && continue

    # Iterer gjennom skjema i dette domenet
    while IFS= read -r schema_file; do
      [[ -z "$schema_file" ]] && continue

      schema_dir=$(dirname "$schema_file")
      schema_name=$(basename "$schema_dir")

      # Hent description frå skjemafil (dynamisk via Python-script)
      description=$(python3 src/assets/scripts/makefile/extract-schema-metadata.py "$schema_file" description)

      # Hent see_also frå skjemafil (første URI via Python-script)
      see_also_uri=$(python3 src/assets/scripts/makefile/extract-schema-metadata.py "$schema_file" see_also)

      # Format dokumentasjonslenkje dersom see_also finst
      if [[ -n "$see_also_uri" ]]; then
        # Ekstraher domenenavn frå URI (t.d. data.norge.no, www.go-fair.org)
        doc_domain=$(echo "$see_also_uri" | sed -E 's|https?://([^/]+).*|\1|')
        doc_link="[$doc_domain]($see_also_uri)"
      else
        doc_link=""
      fi

      # Konverter src/linkml/<domain>/<modell>/ til <domain>/<modell>/ for GitHub Pages.
      # Absolutte URL-ar (ikkje relative) sidan denne tabellen både vert vist
      # i README.md (GitHub-repo-rot) og kopiert ordrett inn i
      # mkdocs/docs/index.md (portal-rot) — dei to har ulik relativ-lenkje-rot,
      # så berre eit kontekst-uavhengig, absolutt mål er korrekt begge stader.
      # Sjå specs/backlog/lenkjesjekk-runde3-fiks-resterande-feil.md kategori E.
      ghpages_schema_link="${schema_dir#src/linkml/}"

      echo "| [$(domain_short_label "$domain")]($PORTAL_BASE/$domain/) | [$schema_name]($PORTAL_BASE/$ghpages_schema_link/) | $description | $doc_link"
    done <<< "${DOMAIN_SCHEMAS[$domain]}"
  done
}

# --- Funksjon: Generer begrepskatalog-tabell ---
generate_begrepskatalog_table() {
  echo "| $H_DOMENE | $H_BEGREPSKATALOG | $H_ORGANISASJON | $H_SKILDRING | $H_GENERATOR |"
  echo "|---|---|---|---|---|"

  local extractor="$SCRIPT_DIR/extract-schema-metadata.py"

  # Finn alle begrepskatalogar
  while IFS= read -r schema_file; do
    schema_dir=$(dirname "$schema_file")
    schema_name=$(basename "$schema_dir")

    # Hent title frå skjema, ekstraher organisasjonsnavn (før " - Begrepskatalog")
    title=$(python3 "$extractor" "$schema_file" title)
    # Fjern " - Begrepskatalog" og alt etter det (inkl. eventuelle parentesar)
    org=$(echo "$title" | sed 's/ - Begrepskatalog.*//')

    # Fallback dersom title manglar eller ikkje følgjer mønsteret
    if [[ -z "$org" || "$org" == "$title" ]]; then
      org="$UKJEND_ORG"
    fi

    # Lenk begrepskatalog-domenet til dokumentasjonsportalen
    domain_link="$PORTAL_BASE/begrepskatalog/"

    # Konverter src/linkml/begrepskatalog/<katalog>/ til begrepskatalog/<katalog>/ for GitHub Pages.
    # Absolutt URL — sjå grunngjeving i generate_schema_table() over.
    ghpages_link="${schema_dir#src/linkml/}"

    skildring=$(t readme_tabell.begrepskatalog_skildring org="$org")

    echo "| [begrepskatalog]($domain_link) | [$schema_name]($PORTAL_BASE/$ghpages_link/) | $org | $skildring | [\`gen-begrepskatalog-instance\`](https://github.com/AudunAutomat/linkml-datamodellering-no/blob/main/COMMANDS.md#gen-begrepskatalog-instance) |"
  done < <(find src/linkml/begrepskatalog -name "*-schema.yaml" -type f | sort)
}

# --- Funksjon: Generer modellkatalog-tabell ---
generate_modellkatalog_table() {
  echo "| $H_DOMENE | $H_MODELLKATALOG | $H_ORGANISASJON | $H_SKILDRING | $H_GENERATOR |"
  echo "|---|---|---|---|---|"

  local extractor="$SCRIPT_DIR/extract-schema-metadata.py"

  # Finn alle modellkatalogar
  while IFS= read -r schema_file; do
    schema_dir=$(dirname "$schema_file")
    schema_name=$(basename "$schema_dir")

    # Hent title frå skjema, ekstraher organisasjonsnavn (før " - Modellkatalog")
    title=$(python3 "$extractor" "$schema_file" title)
    # Fjern " - Modellkatalog" og alt etter det (inkl. eventuelle parentesar)
    org=$(echo "$title" | sed 's/ - Modellkatalog.*//')

    # Fallback dersom title manglar eller ikkje følgjer mønsteret
    if [[ -z "$org" || "$org" == "$title" ]]; then
      org="$UKJEND_ORG"
    fi

    # Lenk modellkatalog-domenet til dokumentasjonsportalen
    domain_link="$PORTAL_BASE/modellkatalog/"

    # Konverter src/linkml/modellkatalog/<katalog>/ til modellkatalog/<katalog>/ for GitHub Pages.
    # Absolutt URL — sjå grunngjeving i generate_schema_table() over.
    ghpages_link="${schema_dir#src/linkml/}"

    skildring=$(t readme_tabell.modellkatalog_skildring org="$org")

    echo "| [modellkatalog]($domain_link) | [$schema_name]($PORTAL_BASE/$ghpages_link/) | $org | $skildring | [\`gen-modellkatalog-instance\`](https://github.com/AudunAutomat/linkml-datamodellering-no/blob/main/COMMANDS.md#gen-modellkatalog-instance) |"
  done < <(find src/linkml/modellkatalog -name "*-schema.yaml" -type f | sort)
}

# --- Hovudlogikk: Bygg ny README med auto-genererte seksjoner ---

IN_SCHEMA_TABLE=false
IN_BEGREPSKATALOG_TABLE=false
IN_MODELLKATALOG_TABLE=false

while IFS= read -r line; do
  # Skjema-tabell
  if [[ "$line" =~ ^\<\!--\ BEGIN\ AUTO-GENERATED:.*generate_schema_table ]]; then
    IN_SCHEMA_TABLE=true
    echo "<!-- BEGIN AUTO-GENERATED: src/assets/scripts/makefile/generate-readme-tables.sh generate_schema_table -->" >> "$TEMP_README"
    generate_schema_table >> "$TEMP_README"
    continue
  elif [[ "$line" =~ ^\<\!--\ END\ AUTO-GENERATED:.*generate_schema_table ]]; then
    IN_SCHEMA_TABLE=false
    echo "<!-- END AUTO-GENERATED: src/assets/scripts/makefile/generate-readme-tables.sh generate_schema_table -->" >> "$TEMP_README"
    continue
  elif $IN_SCHEMA_TABLE; then
    continue  # Hopp over eksisterande innhald
  fi

  # Begrepskatalog-tabell
  if [[ "$line" =~ ^\<\!--\ BEGIN\ AUTO-GENERATED:.*generate_begrepskatalog_table ]]; then
    IN_BEGREPSKATALOG_TABLE=true
    echo "<!-- BEGIN AUTO-GENERATED: src/assets/scripts/makefile/generate-readme-tables.sh generate_begrepskatalog_table -->" >> "$TEMP_README"
    generate_begrepskatalog_table >> "$TEMP_README"
    continue
  elif [[ "$line" =~ ^\<\!--\ END\ AUTO-GENERATED:.*generate_begrepskatalog_table ]]; then
    IN_BEGREPSKATALOG_TABLE=false
    echo "<!-- END AUTO-GENERATED: src/assets/scripts/makefile/generate-readme-tables.sh generate_begrepskatalog_table -->" >> "$TEMP_README"
    continue
  elif $IN_BEGREPSKATALOG_TABLE; then
    continue  # Hopp over eksisterande innhald
  fi

  # Modellkatalog-tabell
  if [[ "$line" =~ ^\<\!--\ BEGIN\ AUTO-GENERATED:.*generate_modellkatalog_table ]]; then
    IN_MODELLKATALOG_TABLE=true
    echo "<!-- BEGIN AUTO-GENERATED: src/assets/scripts/makefile/generate-readme-tables.sh generate_modellkatalog_table -->" >> "$TEMP_README"
    generate_modellkatalog_table >> "$TEMP_README"
    continue
  elif [[ "$line" =~ ^\<\!--\ END\ AUTO-GENERATED:.*generate_modellkatalog_table ]]; then
    IN_MODELLKATALOG_TABLE=false
    echo "<!-- END AUTO-GENERATED: src/assets/scripts/makefile/generate-readme-tables.sh generate_modellkatalog_table -->" >> "$TEMP_README"
    continue
  elif $IN_MODELLKATALOG_TABLE; then
    continue  # Hopp over eksisterande innhald
  fi

  # Behald alle andre linjer
  echo "$line" >> "$TEMP_README"
done < "$README"

# Erstatt original med oppdatert versjon
mv "$TEMP_README" "$README"

log_info "$README er oppdatert med auto-genererte tabellar"
