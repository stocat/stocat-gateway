SERVICES := auth-api trade-api trade-websocket-api asset-scraper exchange-rate-crawler
ENV := prod
SERVICE :=
RELEASE := $(SERVICE)
NAMESPACE := stocat-$(ENV)
CHART := ./stocat-service

.PHONY: help
help:
	@echo "Targets in helm/:"
	@echo "  make deploy SERVICE=<service> [ENV=env] [RELEASE=name]"
	@echo "  make delete SERVICE=<service> [ENV=env] [RELEASE=name]"

.PHONY: deploy
deploy:
	@[ -n "$(SERVICE)" ] || (echo "SERVICE is required. Available: $(SERVICES)"; exit 1)
	@if ! printf "%s" "$(SERVICES)" | grep -qw "$(SERVICE)"; then \
		echo "Unknown service '$(SERVICE)'. Allowed: $(SERVICES)"; exit 1; \
	fi
	@VALUES="-f services/$(SERVICE)/values.yaml"; \
	if [ -f services/$(SERVICE)/$(ENV).values.yaml ]; then \
		VALUES="$$VALUES -f services/$(SERVICE)/$(ENV).values.yaml"; \
	fi; \
	if [ -f $(ENV).values.yaml ]; then \
		VALUES="$$VALUES -f $(ENV).values.yaml"; \
	fi; \
	cmd="helm upgrade --install $(RELEASE) $(CHART) --namespace $(NAMESPACE) --create-namespace $$VALUES"; \
	echo $$cmd; \
	$$cmd

.PHONY: delete
delete:
	@[ -n "$(RELEASE)" ] || (echo "RELEASE is required"; exit 1)
	helm uninstall $(RELEASE) --namespace $(NAMESPACE)
