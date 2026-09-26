# ==============================================================================
# make/40-validation.mk
#
# Validering av skjema, eksempelfiler og datafiler:
# - LinkML-validering (validate, lint, validate-instance)
# - Policy-validering (validate-data, validate-examples)
# - MCP-validering (mcp-linkml-valider-modell, validate-capture)
# - Logging av valideringsresultat (validate-policy-logg, validate-instance-logg)
#
# Relaterte script:
# - src/assets/scripts/makefile/detect-validation-policy.py
# - src/assets/scripts/makefile/save-validation-log.py
# - src/assets/scripts/makefile/run-validation.sh
# ==============================================================================

# ---------------------------------------------------------------------------
# LinkML-validering
# ---------------------------------------------------------------------------

validate: ## Valider alle skjema (merge-imports, fail-fast, ingen fil skriven) [DOMAIN=<domene>|SCHEMA=<sti>]
ifdef SCHEMA
	$(call print_header,validate,SCHEMA=$(SCHEMA))
else ifdef DOMAIN
	$(call print_header,validate,DOMAIN=$(DOMAIN))
else
	$(call print_header,validate)
endif
	$(call run_gen_linkml_parallel,$(call get_target_schemas))
	@$(LINKML_RUN) python3 src/assets/scripts/makefile/check-import-duplicates.py $(call get_target_schemas)

lint: ## Køyr linkml lint [SCHEMA=<sti>]
	$(call print_header,lint,$(if $(SCHEMA),SCHEMA=$(SCHEMA),(alle skjema)))
	@$(LINKML_RUN) python3 src/assets/scripts/makefile/batch-lint.py \
		--config src/assets/containers/.linkmllint.yaml -- $(if $(SCHEMA),$(SCHEMA),$(SCHEMAS))
	@$(LINKML_RUN) python3 src/assets/scripts/makefile/check-import-duplicates.py $(call get_target_schemas)

check-import-duplicates: ## Sjekk at lokale slots/klasser/typar/enum ikkje kolliderer med navn frå importerte skjema [DOMAIN=<domene>|SCHEMA=<sti>]
	$(call print_header,check-import-duplicates,$(if $(SCHEMA),SCHEMA=$(SCHEMA),$(if $(DOMAIN),DOMAIN=$(DOMAIN),(alle skjema))))
	@$(LINKML_RUN) python3 src/assets/scripts/makefile/check-import-duplicates.py $(call get_target_schemas)

validate-instance: ## Valider instansfil mot skjema (SCHEMA=<sti> INSTANCE=<sti>)
	@test -n "$(SCHEMA)" || { eval "$$LOG_FUNCTIONS"; log_error "Bruk: make validate-instance SCHEMA=<sti> INSTANCE=<sti>"; exit 1; }
	@test -n "$(INSTANCE)" || { eval "$$LOG_FUNCTIONS"; log_error "Bruk: make validate-instance SCHEMA=<sti> INSTANCE=<sti>"; exit 1; }
	$(call print_header,validate-instance,SCHEMA=$(SCHEMA)  INSTANCE=$(INSTANCE))
	$(LINKML_RUN) linkml validate --schema "$(SCHEMA)" "$(INSTANCE)"

# ---------------------------------------------------------------------------
# Policy-validering (bronze/silver/gold/felles-*)
# ---------------------------------------------------------------------------

validate-data: ## Valider datafiler (data/*/*.yaml) med MCP-validator (DOMAIN=<domene>)
ifdef DOMAIN
	@eval "$$LOG_FUNCTIONS"; \
	set +e; \
	FAILED=0; \
	DATADIRS=$$(find $(SCHEMA_DIR)/$(DOMAIN) -mindepth 3 -maxdepth 3 -type d -path '*/data/*' 2>/dev/null | sort); \
	if [ -z "$$DATADIRS" ]; then \
		log_info "Ingen datafiler funne for DOMAIN=$(DOMAIN)"; \
		exit 0; \
	fi; \
	BATCH_DIR=$$(mktemp -d); \
	trap 'rm -rf "$$BATCH_DIR"' EXIT; \
	JOBS_TSV="$$BATCH_DIR/jobs.tsv"; \
	: > "$$JOBS_TSV"; \
	for datadir in $$DATADIRS; do \
		model=$$(echo "$$datadir" | awk -F/ '{print $$4}'); \
		catalog=$$(basename "$$datadir"); \
		datafile="$$datadir/$$catalog.yaml"; \
		[ -f "$$datafile" ] || continue; \
		schema=$(SCHEMA_DIR)/$(DOMAIN)/$$model/$$model-schema.yaml; \
		manifest="$$datadir/build.yaml"; \
		if [ -f "$$manifest" ]; then \
			policy=$$(grep '^validation_policy:' "$$manifest" | awk '{print $$2}'); \
		else \
			policy=bronze; \
		fi; \
		[ -n "$$policy" ] || policy=bronze; \
		printf '%s\t%s\t%s\n' "$$schema" "$$policy" "$$datafile" >> "$$JOBS_TSV"; \
	done; \
	COUNT=$$(wc -l < "$$JOBS_TSV"); \
	log_debug "Kommando: batch-flatten-and-validate.py --jobs-tsv ($$COUNT datafiler, domain $(DOMAIN))"; \
	t0=$$(now_ms); \
	run_logged "batch-flatten-and-validate/data $(DOMAIN)" python3 src/mcp-linkml-validator/batch-flatten-and-validate.py --jobs-tsv "$$JOBS_TSV" \
		--output-dir "$$BATCH_DIR"; \
	t1=$$(now_ms); \
	ms=$$(( t1 - t0 )); \
	log_info "$$(printf '$(CLR_STEP)→ validate-data  %s  (%d datafiler, batcha)$(CLR_RST) (%s)' "$(DOMAIN)" "$$COUNT" "$$(fmt_elapsed_ms $$ms)")"; \
	i=0; \
	while IFS=$$'\t' read -r schema policy datafile; do \
		catalog=$$(basename "$$datafile" .yaml); \
		result=$$(cat "$$BATCH_DIR/$$i.json" 2>/dev/null || echo '{"valid":false,"errorCount":1,"warningCount":0,"issues":[{"severity":"error","code":"missing_batch_result","target":"schema","message":"Batch-resultat manglar"}]}'); \
		log_debug "$$result"; \
		if echo "$$result" | grep -Eq '"valid"[[:space:]]*:[[:space:]]*false'; then \
			FAILED=$$((FAILED + 1)); \
			log_error "::error file=$$datafile::Validering feila ($$catalog): $$result"; \
		fi; \
		run_logged "save-validation-log/data $$catalog" $(PYTHON_RUN) python3 /work/src/assets/scripts/makefile/save-validation-log.py \
			--schema "$$schema" --type "data-$$catalog" --result "$$result" < /dev/null; \
		i=$$((i + 1)); \
	done < "$$JOBS_TSV"; \
	exit $$FAILED
else
	@log_error "FEIL: DOMAIN er påkravd. Bruk: make validate-data DOMAIN=<domene>"
	@exit 1
endif

validate-examples: ## Valider eksempelfiler mot skjema (DOMAIN=<domene>)
ifdef DOMAIN
	@eval "$$LOG_FUNCTIONS"; \
	set +e; \
	JOBS_TSV=$$(mktemp "$(GEN_DIR)/.validate-examples-jobs.XXXXXX"); \
	trap 'rm -f "$$JOBS_TSV"' EXIT; \
	SCHEMA_LIST=$$(find src/linkml/$(DOMAIN) -mindepth 2 -maxdepth 2 -name '*-schema.yaml' | grep -v common | sort); \
	if [ -z "$$SCHEMA_LIST" ]; then \
		log_info "Ingen skjema funne for DOMAIN=$(DOMAIN)"; \
		exit 0; \
	fi; \
	while IFS= read -r schema; do \
		name=$$(basename "$$schema" -schema.yaml); \
		example="$(SCHEMA_DIR)/$(DOMAIN)/$$name/examples/$$name-eksempel.yaml"; \
		if [ ! -f "$$example" ]; then \
			log_info "$(CLR_WARN)::warning file=$$schema::Ingen eksempelfil funne: $$example$(CLR_RST)"; \
			continue; \
		fi; \
		validate_schema="$$schema"; \
		if ! grep -q "tree_root: true" "$$schema"; then \
			fixture="tests/fixtures/$$name-fixture.yaml"; \
			if [ -f "$$fixture" ]; then \
				validate_schema="$$fixture"; \
			else \
				log_info "$(CLR_WARN)::warning file=$$schema::Ingen tree_root og ingen fixture funne ($$fixture) — hoppar over$(CLR_RST)"; \
				continue; \
			fi; \
		fi; \
		printf '%s\t%s\t%s\n' "$$schema" "$$validate_schema" "$$example" >> "$$JOBS_TSV"; \
	done <<< "$$SCHEMA_LIST"; \
	if [ ! -s "$$JOBS_TSV" ]; then \
		log_info "Ingen eksempelfiler å validere for DOMAIN=$(DOMAIN)"; \
		exit 0; \
	fi; \
	COUNT=$$(wc -l < "$$JOBS_TSV"); \
	log_debug "Kommando: batch-linkml-validate.py --jobs-tsv ($$COUNT eksempelfiler, domain $(DOMAIN))"; \
	t0=$$(now_ms); \
	if ! $(LINKML_RUN) python3 src/assets/scripts/makefile/batch-linkml-validate.py --jobs-tsv "$$JOBS_TSV"; then \
		FAILED=1; \
	else \
		FAILED=0; \
	fi; \
	t1=$$(now_ms); \
	ms=$$(( t1 - t0 )); \
	log_info "$$(printf '$(CLR_STEP)→ validate-examples  %s  (%d eksempelfiler, batcha)$(CLR_RST) (%s)' "$(DOMAIN)" "$$COUNT" "$$(fmt_elapsed_ms $$ms)")"; \
	i=0; \
	while IFS=$$'\t' read -r schema validate_schema example; do \
		name=$$(basename "$$schema" -schema.yaml); \
		if [ $$FAILED -eq 0 ]; then \
			result_json='{"valid":true,"error_count":0,"warning_count":0,"issues":[]}'; \
		else \
			result_json='{"valid":false,"error_count":1,"warning_count":0,"issues":[{"severity":"error","target":"examples","message":"Validation failed"}]}'; \
		fi; \
		run_logged "save-validation-log/examples $(DOMAIN)/$$name" $(PYTHON_RUN) python3 /work/src/assets/scripts/makefile/save-validation-log.py \
			--schema "$$schema" --type examples --result "$$result_json" < /dev/null; \
		i=$$((i + 1)); \
	done < "$$JOBS_TSV"; \
	exit $$FAILED
else
	@log_error "FEIL: DOMAIN er påkravd. Bruk: make validate-examples DOMAIN=<domene>"
	@exit 1
endif

# ---------------------------------------------------------------------------
# MCP-validering
# ---------------------------------------------------------------------------

mcp-linkml-valider-modell: ## MCP-validator for skjema (SCHEMA=<sti> [POLICY=<policy>])
	@test -n "$(SCHEMA)" || { eval "$$LOG_FUNCTIONS"; log_error "Bruk: make mcp-linkml-valider-modell SCHEMA=<sti> [POLICY=gold]"; exit 1; }
	@DETECTED_POLICY=$$($(PYTHON_RUN) python3 /work/src/assets/scripts/makefile/detect-validation-policy.py "$(SCHEMA)" || echo "bronze"); \
	POLICY_TO_USE="$${POLICY:-$$DETECTED_POLICY}"; \
	$(MAKE) --no-print-directory _mcp-valider-modell-with-header SCHEMA=$(SCHEMA) POLICY=$$POLICY_TO_USE

_mcp-valider-modell-with-header:
	$(call print_header,mcp-linkml-valider-modell,SCHEMA=$(SCHEMA)  POLICY=$(POLICY))
	@podman image exists $(MCP_IMAGE) 2>/dev/null || $(MAKE) --no-print-directory build-docker-mcp-validator
	@eval "$$LOG_FUNCTIONS"; \
	LOG_PATH=$$(bash src/assets/scripts/makefile/run-validation.sh \
	    --schema "$(SCHEMA)" --policy "$(POLICY)" \
	    $(if $(INSTANCE),--instance "$(INSTANCE)") --quiet); \
	EXIT_CODE=$$?; \
	cat "$$LOG_PATH"; \
	GEN_PATH=$$(echo "$$LOG_PATH" | sed 's#^src/linkml/#generated/#'); \
	mkdir -p "$$(dirname "$$GEN_PATH")"; \
	cp "$$LOG_PATH" "$$GEN_PATH"; \
	log_info "Skrive til: $$LOG_PATH (og kopiert til $$GEN_PATH for lokal portalvising)"; \
	exit $$EXIT_CODE

# Merk navnekonsistens/overlapp med validate-policy-logg/validate-instance-logg
# under: begge skriv til same output-format (validation/<versjon>/<policy>.json),
# men er ikkje duplikat i praksis. validate-capture er eit manuelt batch-verktøy
# for alle skjema (eller DOMAIN/SCHEMA) — ikkje brukt frå CI. validate-policy-
# logg/validate-instance-logg (run-validation.sh) er derimot kalla direkte frå
# .github/workflows/{generate,validate}.yml for kvart einskild skjema/manifest
# — CI-kritisk infrastruktur. Konsolidering vart difor vurdert (jf.
# specs/backlog/make-kommando-inkonsistens-audit.md, navnekonsistens 4) og
# medvite utsett: å skrive om eit CI-kritisk script utan eksplisitt brukar-
# godkjenning bryt CLAUDE.md sitt DRY-unntak for risikofylte omskrivingar.
# (Navna sjølve vart omdøypte 2026-08-20, jf.
# specs/done/make-target-navn-vs-funksjon.md, Funn 7 — funksjonen og
# CI-kritikaliteten er uendra.)
#
# Same mønster som validate-data: batch-flatten-and-validate.py køyrer på
# verten (stdlib, startar sjølv podman) — IKKJE i $(PYTHON_RUN), som manglar
# bash/podman — og kvart resultat vert lagra med save-validation-log.py i
# container. Sjå specs/done/validate-capture-utan-schema.md (F3).
# Capture-verktøy, ikkje port: ugyldige skjema vert logga og talde, men gir
# ikkje exit ≠ 0. Infrastrukturfeil (manglande skjema/resultat, lagringsfeil) gjer.
validate-capture: ## MCP-validering med logging til validation/ [DOMAIN=<domene>|SCHEMA=<sti>]
	$(call print_header,validate-capture,$(if $(SCHEMA),SCHEMA=$(SCHEMA),$(if $(DOMAIN),DOMAIN=$(DOMAIN),(alle skjema$(COMMA) batcha))))
	@podman image exists $(MCP_IMAGE) 2>/dev/null || $(MAKE) --no-print-directory build-docker-mcp-validator
	@eval "$$LOG_FUNCTIONS"; \
	set +e; \
	TARGET_SCHEMAS="$(call get_target_schemas)"; \
	if [ -z "$$TARGET_SCHEMAS" ]; then \
		log_error "FEIL: ingen skjema funne (DOMAIN=$(DOMAIN) SCHEMA=$(SCHEMA))"; \
		exit 1; \
	fi; \
	BATCH_DIR=$$(mktemp -d); \
	trap 'rm -rf "$$BATCH_DIR"' EXIT; \
	JOBS_TSV="$$BATCH_DIR/jobs.tsv"; \
	: > "$$JOBS_TSV"; \
	for schema in $$TARGET_SCHEMAS; do \
		if [ ! -f "$$schema" ]; then \
			log_error "FEIL: $$schema finst ikkje"; \
			exit 1; \
		fi; \
		manifest="$$(dirname "$$schema")/build.yaml"; \
		if [ -f "$$manifest" ]; then \
			policy=$$(grep '^validation_policy:' "$$manifest" | awk '{print $$2}'); \
		else \
			policy=bronze; \
		fi; \
		[ -n "$$policy" ] || policy=bronze; \
		printf '%s\t%s\t\n' "$$schema" "$$policy" >> "$$JOBS_TSV"; \
	done; \
	COUNT=$$(wc -l < "$$JOBS_TSV"); \
	t0=$$(now_ms); \
	run_logged "batch-flatten-and-validate/capture" python3 src/mcp-linkml-validator/batch-flatten-and-validate.py --jobs-tsv "$$JOBS_TSV" \
		--output-dir "$$BATCH_DIR"; \
	t1=$$(now_ms); \
	log_info "$$(printf '$(CLR_STEP)→ validate-capture  %d skjema, batcha$(CLR_RST) (%s)' "$$COUNT" "$$(fmt_elapsed_ms $$(( t1 - t0 )))")"; \
	i=0; INVALID=0; INFRA=0; \
	while IFS=$$'\t' read -r schema policy _; do \
		if [ -f "$$BATCH_DIR/$$i.json" ]; then \
			result=$$(cat "$$BATCH_DIR/$$i.json"); \
		else \
			log_error "FEIL: manglar batch-resultat for $$schema"; \
			INFRA=$$((INFRA + 1)); \
			result='{"valid":false,"errorCount":1,"warningCount":0,"issues":[{"severity":"error","code":"missing_batch_result","target":"schema","message":"Batch-resultat manglar"}]}'; \
		fi; \
		if echo "$$result" | grep -Eq '"valid"[[:space:]]*:[[:space:]]*false'; then \
			INVALID=$$((INVALID + 1)); \
			log_info "⚠ Ugyldig ($$policy): $$schema"; \
		fi; \
		run_logged "save-validation-log/$$policy $$(basename "$$schema" -schema.yaml)" $(PYTHON_RUN) python3 /work/src/assets/scripts/makefile/save-validation-log.py \
			--schema "$$schema" --type "$$policy" --result "$$result" < /dev/null || INFRA=$$((INFRA + 1)); \
		i=$$((i + 1)); \
	done < "$$JOBS_TSV"; \
	log_info "validate-capture: $$COUNT skjema, $$((COUNT - INVALID)) gyldige, $$INVALID ugyldige"; \
	exit $$INFRA

# ---------------------------------------------------------------------------
# Logging av valideringsresultat
# ---------------------------------------------------------------------------

# Validerer og skriv logg til src/linkml/<domain>/<modell>/validation/<version>/<policy>.json
validate-policy-logg: ## Policy-validering med full JSON-logg (BUILDYAML=<sti>|SCHEMA=<sti> POLICY=<policy>)
	@eval "$$LOG_FUNCTIONS"; \
	if [ -n "$(BUILDYAML)" ]; then \
		bash src/assets/scripts/makefile/run-validation.sh --manifest $(BUILDYAML); \
	elif [ -n "$(SCHEMA)" ] && [ -n "$(POLICY)" ]; then \
		bash src/assets/scripts/makefile/run-validation.sh --schema $(SCHEMA) --policy $(POLICY); \
	else \
		log_error "Oppgi anten BUILDYAML=<sti> eller både SCHEMA=<sti> og POLICY=<policy>"; \
		exit 1; \
	fi

# Validerer instans og skriv logg til src/linkml/<domain>/<modell>/validation/<version>/instance-<navn>.json
validate-instance-logg: ## Instansvalidering med full JSON-logg (SCHEMA=<sti> INSTANCE=<sti>)
	@test -n "$(SCHEMA)" || { eval "$$LOG_FUNCTIONS"; log_error "Bruk: make validate-instance-logg SCHEMA=<sti> INSTANCE=<sti>"; exit 1; }
	@test -n "$(INSTANCE)" || { eval "$$LOG_FUNCTIONS"; log_error "Bruk: make validate-instance-logg SCHEMA=<sti> INSTANCE=<sti>"; exit 1; }
	@bash src/assets/scripts/makefile/run-validation.sh --schema $(SCHEMA) --instance $(INSTANCE)
