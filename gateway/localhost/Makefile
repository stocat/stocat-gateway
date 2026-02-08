REGISTRY := stocat
TAG := local
KIND_CLUSTER := stocat-local
OTEL_AGENT_VERSION := 2.8.0
GRADLE := ../../gradlew -p ../..
MODULE := gateway
IMAGE := $(REGISTRY)/$(MODULE):$(TAG)
NAMESPACE := stocat

.PHONY: help boot docker kind-clean kind-load namespace helm-deploy helm-delete clean all
help:
	@echo "Local targets: boot, docker, kind-clean, kind-load, namespace, helm-deploy, helm-delete, all"

boot:
	$(GRADLE) :$(MODULE):bootJar

docker:
	docker build \
		--build-arg OTEL_AGENT_VERSION=$(OTEL_AGENT_VERSION) \
		-t $(IMAGE) \
		-f ../Dockerfile ../..

kind-clean:
	@if kind get clusters | grep -qx "$(KIND_CLUSTER)"; then \
		for node in $$(kind get nodes --name $(KIND_CLUSTER)); do \
			docker exec $$node crictl rmi $(IMAGE) >/dev/null 2>&1 || true; \
		done; \
		echo "Removed $(IMAGE) from kind nodes"; \
	else \
		echo "kind cluster '$(KIND_CLUSTER)' not found; skipping clean"; \
	fi

kind-load: docker kind-clean
	kind load docker-image $(IMAGE) --name $(KIND_CLUSTER)

namespace:
	kubectl get namespace $(NAMESPACE) >/dev/null 2>&1 || kubectl create namespace $(NAMESPACE)

helm-deploy: kind-load namespace
	helm upgrade --install $(MODULE) ../../helm/stocat-service \
		--namespace $(NAMESPACE) --create-namespace \
		-f ../../helm/services/$(MODULE)/values.yaml \
		-f ../../helm/local.values.yaml \
		-f ../../helm/services/$(MODULE)/local.values.yaml

helm-delete:
	helm uninstall $(MODULE) --namespace $(NAMESPACE) || true

all: helm-deploy
clean: helm-delete