# ==============================================================================
# make/50-docs.mk
#
# MkDocs-dokumentasjonsportal:
# - build-docker-mkdocs: bygg docs-image med mkdocs-kroki
# - docs-serve: køyr lokal server på :8000
# - docs-build: bygg statisk site til mkdocs/site/
# - docs-publish: kopier generated/ til mkdocs/docs/ og generer mkdocs.yml
# - i18n-check: valider strengkatalogen for portaltekst og røyktest lastaren
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

docs-serve: ## Køyr lokal MkDocs-server på :8000
	$(call print_header,docs-serve)
	@mkdir -p "$(CURDIR)/mkdocs/.cache" "$(CURDIR)/mkdocs/site"
	@$(DOCS_RUN) -it -p 8000:8000 $(DOCS_IMAGE) serve --dev-addr=0.0.0.0:8000

docs-build: ## Bygg statisk MkDocs-site til mkdocs/site/
	$(call print_header,docs-build)
	@eval "$$LOG_FUNCTIONS"; \
	mkdir -p "$(CURDIR)/mkdocs/.cache" "$(CURDIR)/mkdocs/site"; \
	timed_run "Bygg statisk MkDocs-site" $(DOCS_RUN) $(DOCS_IMAGE) build

docs-publish: ## Publiser generated/ til mkdocs/docs/ og oppdater mkdocs.yml
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
	@$(PYTHON_RUN) python3 -m pytest -q -p no:cacheprovider tests/test_i18n_strings.py
	@langs=$$($(PYTHON_RUN) python3 mkdocs/lib/scripts/i18n_strings.py languages) && \
	REPO_ROOT="$(CURDIR)" LANGS="$$langs" bash -c 'set -euo pipefail; source mkdocs/lib/utils/i18n.sh; \
		for lang in $$LANGS; do i18n_load "$$lang"; v=$$(t i18n.ikkje_omsett.tittel); \
		echo "i18n_load $$lang: $${#I18N[@]} nøklar, i18n.ikkje_omsett.tittel = $$v"; done'
