# ==============================================================================
# make/50-docs.mk
#
# MkDocs-dokumentasjonsportal:
# - build-docker-mkdocs: bygg docs-image med mkdocs-kroki
# - docs-serve: køyr lokal live-server på :8000 for eitt språk [DOCS_LANG=<lang>]
# - docs-serve-site: server den bygde portalen (alle språk) på :8000
# - docs-build: bygg statisk site for alle språk til mkdocs/site/ (/<lang>/ + rot)
# - docs-publish: generer språktre og mkdocs-konfig per språk i mkdocs/build/
# - i18n-check: valider strengkatalogen for portaltekst og røyktest lastaren
# - i18n-status / i18n-stamp: endringsdeteksjon for omsetjingar (source_hash)
#
# Relaterte script:
# - mkdocs/publish.sh (hovudscript for docs-publish)
# - mkdocs/lib/scripts/i18n_strings.py, mkdocs/lib/utils/i18n.sh (i18n-check)
# - src/assets/scripts/makefile/generate-readme-tables.sh
# ==============================================================================

# ---------------------------------------------------------------------------
# MkDocs Material
# ---------------------------------------------------------------------------

build-docker-mkdocs: ## Bygg MkDocs container-image
	$(call print_header,build-docker-mkdocs)
	@podman build --format docker -f $(DOCS_DOCKERFILE) -t $(DOCS_IMAGE)

# Språk, standardspråk og base-sti kjem frå mkdocs/build/languages.env, skrive av
# mkdocs/publish.sh — sjå specs/backlog/lokalisering-dokumentasjonsportal.md (steg 8).
DOCS_LANGUAGES_ENV := $(CURDIR)/mkdocs/build/languages.env
define docs_load_languages
[ -f "$(DOCS_LANGUAGES_ENV)" ] || { log_error "Manglar $(DOCS_LANGUAGES_ENV) — køyr make docs-publish først"; exit 1; }; \
. "$(DOCS_LANGUAGES_ENV)"
endef

docs-serve: ## Køyr lokal MkDocs-server med live reload på :8000 for eitt språk [DOCS_LANG=<lang>]
	$(call print_header,docs-serve)
	@eval "$$LOG_FUNCTIONS"; $(docs_load_languages); \
	lang="$(DOCS_LANG)"; lang="$${lang:-$$DOCS_DEFAULT_LANGUAGE}"; \
	[ -f "$(CURDIR)/mkdocs/build/mkdocs.$$lang.yml" ] || { log_error "Ukjent språk '$$lang' (tilgjengeleg: $$DOCS_LANGUAGES)"; exit 1; }; \
	mkdir -p "$(CURDIR)/mkdocs/.cache" "$(CURDIR)/mkdocs/site"; \
	log_info "Serverer $$lang på http://localhost:8000/$$DOCS_BASE_PATH/$$lang/ (artefaktlenkjer og språkveljar krev make docs-build + docs-serve-site)"; \
	$(DOCS_RUN) -it -p 8000:8000 $(DOCS_IMAGE) serve -f "mkdocs.$$lang.yml" --dev-addr=0.0.0.0:8000

docs-serve-site: ## Server den bygde portalen (alle språk, artefakter, vidaresendingar) på :8000
	$(call print_header,docs-serve-site)
	@eval "$$LOG_FUNCTIONS"; $(docs_load_languages); \
	[ -f "$(CURDIR)/mkdocs/site/index.html" ] || { log_error "mkdocs/site/ er tom — køyr make docs-build først"; exit 1; }; \
	log_info "Serverer mkdocs/site/ på http://localhost:8000/$$DOCS_BASE_PATH/"; \
	podman run --rm -it -p 8000:8000 -v "$(CURDIR)/mkdocs/site:/srv/$$DOCS_BASE_PATH:ro" $(PYTHON_IMAGE) \
		python3 -m http.server 8000 --directory /srv

docs-build: ## Bygg statisk portal for alle språk til mkdocs/site/ (/<lang>/, artefakter og vidaresendingar på rota)
	$(call print_header,docs-build)
	@eval "$$LOG_FUNCTIONS"; $(docs_load_languages); \
	site="$(CURDIR)/mkdocs/site"; \
	mkdir -p "$(CURDIR)/mkdocs/.cache" "$$site"; \
	find "$$site" -mindepth 1 -delete; \
	pids=(); for lang in $$DOCS_LANGUAGES; do \
		timed_run "Bygg statisk MkDocs-site ($$lang)" $(DOCS_RUN) $(DOCS_IMAGE) build -f "mkdocs.$$lang.yml" & pids+=($$!); \
	done; \
	rc=0; for pid in "$${pids[@]}"; do wait "$$pid" || rc=1; done; \
	[ "$$rc" -eq 0 ] || { log_error "Minst eitt språkbygg feila — sjå over"; exit 1; }; \
	timed_run "Legg artefakter og vidaresendingar på rota" cp -a "$(CURDIR)/mkdocs/build/rot/." "$$site/"; \
	timed_run "Kopier 404-side ($$DOCS_DEFAULT_LANGUAGE) til rota" cp "$$site/$$DOCS_DEFAULT_LANGUAGE/404.html" "$$site/404.html"

docs-publish: ## Generer språktre, byggjetre og mkdocs-konfig per språk i mkdocs/build/ frå generated/
	$(call print_header,docs-publish)
	@eval "$$LOG_FUNCTIONS"; \
	log_info "$(CLR_STEP)Publiserer mkdocs-portal...$(CLR_RST)"; \
	log_debug "Kommando: mkdocs/publish.sh"; \
	bash mkdocs/publish.sh

# ---------------------------------------------------------------------------
# Fleirspråkleg portaltekst (strengkatalog) — sjå
# specs/backlog/lokalisering-dokumentasjonsportal.md
# ---------------------------------------------------------------------------

i18n-check: ## Valider strengkatalogen for portaltekst, køyr testane og røyktest i18n-lastaren
	$(call print_header,i18n-check)
	@$(PYTHON_RUN) python3 mkdocs/lib/scripts/i18n_strings.py check
	@$(PYTHON_RUN) python3 -m pytest -q -p no:cacheprovider tests/test_i18n_strings.py tests/test_i18n_status.py
	@langs=$$($(PYTHON_RUN) python3 mkdocs/lib/scripts/i18n_strings.py languages) && \
	REPO_ROOT="$(CURDIR)" LANGS="$$langs" bash -c 'set -euo pipefail; source mkdocs/lib/utils/i18n.sh; \
		for lang in $$LANGS; do i18n_load "$$lang"; v=$$(t i18n.ikkje_omsett.tittel); \
		echo "i18n_load $$lang: $${#I18N[@]} nøklar, i18n.ikkje_omsett.tittel = $$v"; done'

i18n-status: ## List manglande, ustempla og utdaterte omsetjingar (åtvaringar) [STRICT=1]
	$(call print_header,i18n-status)
	@$(PYTHON_RUN) python3 mkdocs/lib/scripts/i18n_status.py status $(if $(STRICT),--strict)

i18n-stamp: ## Stempla omsetjingar med hash av originalen [FILE=<x.lang.md>|KEYS="k1 k2"] [DOCS_LANG=<lang>]
	$(call print_header,i18n-stamp)
	@$(PYTHON_RUN) python3 mkdocs/lib/scripts/i18n_status.py \
		$(if $(FILE),stamp-page "$(FILE)",stamp-catalog $(if $(DOCS_LANG),--lang $(DOCS_LANG)) $(if $(KEYS),--keys $(KEYS)))
