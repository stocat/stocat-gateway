# Top-level Makefile to build images and deploy services via Helm

## Settings
CHART_DIR ?= ./helm/stocat-gateway
RELEASE_NS ?= stocat-gw
RELEASE_DEMO_NS ?= stocat-demo
KIND_CLUSTER ?= kind-local
VALUES_DIR ?= ./helm/releases

## Optional build tag. Set TAG to a unique value to force rollout,
## e.g., `make TAG=$(shell date +%s) deploy-gateway`.
TAG ?=

## Image repos and tags
GW_REPO ?= gateway
CAT_REPO ?= demo-catalog
ORD_REPO ?= demo-order

GW_TAG ?= $(if $(TAG),$(TAG),0.0.1-SNAPSHOT)
CAT_TAG ?= $(if $(TAG),$(TAG),0.0.1-SNAPSHOT)
ORD_TAG ?= $(if $(TAG),$(TAG),0.0.1-SNAPSHOT)

GW_IMAGE := $(GW_REPO):$(GW_TAG)
CAT_IMAGE := $(CAT_REPO):$(CAT_TAG)
ORD_IMAGE := $(ORD_REPO):$(ORD_TAG)



.PHONY: help ns images images-gw images-catalog images-order \
	kind-prune-all kind-prune-gw kind-prune-catalog kind-prune-order \
	kind-load-all kind-load-gw kind-load-catalog kind-load-order \
	helm-gateway helm-catalog helm-order helm-all \
	deploy deploy-gateway deploy-catalog deploy-order \
	deploy-ts deploy-gateway-ts deploy-catalog-ts deploy-order-ts \
	uninstall-gateway uninstall-catalog uninstall-order uninstall-all status

help:
	@echo "Targets:"
	@echo "  ns                 Create/update namespace '$(RELEASE_NS)'"
	@echo "  images             Build all images (gateway, catalog, order)"
	@echo "  images-gw          Build gateway image only"
	@echo "  images-catalog     Build demo-catalog image only"
	@echo "  images-order       Build demo-order image only"
	@echo "  kind-prune-all     Remove images from kind nodes (all)"
	@echo "  kind-prune-gw      Remove gateway image from kind nodes"
	@echo "  kind-prune-catalog Remove demo-catalog image from kind nodes"
	@echo "  kind-prune-order   Remove demo-order image from kind nodes"
	@echo "  kind-load-all      Load all images into kind cluster ($(KIND_CLUSTER))"
	@echo "  kind-load-gw       Load gateway image only"
	@echo "  kind-load-catalog  Load demo-catalog image only"
	@echo "  kind-load-order    Load demo-order image only"
	@echo "  helm-gateway       Install/upgrade gateway release"
	@echo "  helm-catalog       Install/upgrade demo-catalog release"
	@echo "  helm-order         Install/upgrade demo-order release"
	@echo "  helm-all           Install/upgrade all releases"
	@echo "  deploy             Build -> kind load -> helm-all"
	@echo "  deploy-gateway     Build+load gateway -> helm-gateway"
	@echo "  deploy-catalog     Build+load demo-catalog -> helm-catalog"
	@echo "  deploy-order       Build+load demo-order -> helm-order"
	@echo "  deploy-ts          Same as deploy with TAG=timestamp"
	@echo "  deploy-gateway-ts  Same as deploy-gateway with TAG=timestamp"
	@echo "  deploy-catalog-ts  Same as deploy-catalog with TAG=timestamp"
	@echo "  deploy-order-ts    Same as deploy-order with TAG=timestamp"
	@echo "  uninstall-all      Uninstall all releases"
	@echo "  status             Show pods/services in namespace"
	@echo "Variables: CHART_DIR=$(CHART_DIR) RELEASE_NS=$(RELEASE_NS) KIND_CLUSTER=$(KIND_CLUSTER) TAG=$(TAG)"

ns:
	@kubectl create namespace $(RELEASE_NS) --dry-run=client -o yaml | kubectl apply -f -
	@kubectl create namespace $(RELEASE_DEMO_NS) --dry-run=client -o yaml | kubectl apply -f -

# Build images via submodule Makefiles
images: images-gw images-catalog images-order

images-gw:
	@$(MAKE) -C gateway IMAGE_NAME=$(GW_REPO) IMAGE_TAG=$(GW_TAG) image

images-catalog:
	@$(MAKE) -C services/demo-catalog IMAGE_NAME=$(CAT_REPO) IMAGE_TAG=$(CAT_TAG) image

images-order:
	@$(MAKE) -C services/demo-order IMAGE_NAME=$(ORD_REPO) IMAGE_TAG=$(ORD_TAG) image


kind-prune-all: kind-prune-gw kind-prune-catalog kind-prune-order

kind-prune-gw:
	@for n in $(shell kind get nodes --name $(KIND_CLUSTER)); do \
	  echo "[prune] $$n: $(GW_IMAGE)"; \
	  docker exec $$n sh -lc "ctr -n k8s.io images rm $(GW_IMAGE) 2>/dev/null || true; \
	    ctr -n k8s.io images rm docker.io/library/$(GW_IMAGE) 2>/dev/null || true"; \
	done

kind-prune-catalog:
	@for n in $(shell kind get nodes --name $(KIND_CLUSTER)); do \
	  echo "[prune] $$n: $(CAT_IMAGE)"; \
	  docker exec $$n sh -lc "ctr -n k8s.io images rm $(CAT_IMAGE) 2>/dev/null || true; \
	    ctr -n k8s.io images rm docker.io/library/$(CAT_IMAGE) 2>/dev/null || true"; \
	done

kind-prune-order:
	@for n in $(shell kind get nodes --name $(KIND_CLUSTER)); do \
	  echo "[prune] $$n: $(ORD_IMAGE)"; \
	  docker exec $$n sh -lc "ctr -n k8s.io images rm $(ORD_IMAGE) 2>/dev/null || true; \
	    ctr -n k8s.io images rm docker.io/library/$(ORD_IMAGE) 2>/dev/null || true"; \
	done

kind-load-all: kind-prune-all
	@kind load docker-image $(GW_IMAGE) --name $(KIND_CLUSTER)
	@kind load docker-image $(CAT_IMAGE) --name $(KIND_CLUSTER)
	@kind load docker-image $(ORD_IMAGE) --name $(KIND_CLUSTER)

kind-load-gw: kind-prune-gw
	@kind load docker-image $(GW_IMAGE) --name $(KIND_CLUSTER)

kind-load-catalog: kind-prune-catalog
	@kind load docker-image $(CAT_IMAGE) --name $(KIND_CLUSTER)

kind-load-order: kind-prune-order
	@kind load docker-image $(ORD_IMAGE) --name $(KIND_CLUSTER)

## Helm deploys using generic chart and per-service values files
GW_VALUES ?= $(VALUES_DIR)/gateway.values-local.yaml
CAT_VALUES ?= $(VALUES_DIR)/demo-catalog.values-local.yaml
ORD_VALUES ?= $(VALUES_DIR)/demo-order.values-local.yaml

helm-gateway: ns
	@helm upgrade --install gateway $(CHART_DIR) -n $(RELEASE_NS) -f $(GW_VALUES) \
	  --set image.repository=$(GW_REPO) --set image.tag=$(GW_TAG) --set nameOverride=gateway
	@kubectl -n $(RELEASE_NS) rollout restart deployment gateway || true

helm-catalog: ns
	@helm upgrade --install demo-catalog $(CHART_DIR) -n $(RELEASE_DEMO_NS) -f $(CAT_VALUES) \
	  --set image.repository=$(CAT_REPO) --set image.tag=$(CAT_TAG) --set nameOverride=demo-catalog
	@kubectl -n $(RELEASE_DEMO_NS) rollout restart deployment demo-catalog || true

helm-order: ns
	@helm upgrade --install demo-order $(CHART_DIR) -n $(RELEASE_DEMO_NS) -f $(ORD_VALUES) \
	  --set image.repository=$(ORD_REPO) --set image.tag=$(ORD_TAG) --set nameOverride=demo-order
	@kubectl -n $(RELEASE_DEMO_NS) rollout restart deployment demo-order || true

helm-all: helm-gateway helm-catalog helm-order

# Full deploy pipeline
deploy: images kind-load-all helm-all

deploy-gateway: images-gw kind-load-gw helm-gateway

deploy-catalog: images-catalog kind-load-catalog helm-catalog

deploy-order: images-order kind-load-order helm-order

# Timestamp-tagged deploy shortcuts
deploy-ts:
	@$(MAKE) TAG=$(shell date +%s) deploy

deploy-gateway-ts:
	@$(MAKE) TAG=$(shell date +%s) deploy-gateway

deploy-catalog-ts:
	@$(MAKE) TAG=$(shell date +%s) deploy-catalog

deploy-order-ts:
	@$(MAKE) TAG=$(shell date +%s) deploy-order

uninstall-gateway:
	@helm uninstall gateway -n $(RELEASE_NS) || true

uninstall-catalog:
	@helm uninstall demo-catalog -n $(RELEASE_DEMO_NS) || true

uninstall-order:
	@helm uninstall demo-order -n $(RELEASE_DEMO_NS) || true

uninstall-all: uninstall-gateway uninstall-catalog uninstall-order

status:
	@kubectl -n $(RELEASE_NS) get pods,svc


# Convenience
.PHONY: all
all: deploy-gateway-ts deploy-catalog-ts deploy-order-ts

.PHONY: clean
clean: uninstall-all
