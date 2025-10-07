# Simple Makefile to build the demo-order image and load into kind

# Config
IMAGE_NAME ?= demo-order
IMAGE_TAG ?= 0.0.1-SNAPSHOT
KIND_CLUSTER ?= stocat

GRADLE ?= ../../gradlew

IMAGE := $(IMAGE_NAME):$(IMAGE_TAG)

.PHONY: help all image kind-load print-image

help:
	@echo "Targets:"
	@echo "  image       Build container image via Spring Boot buildpacks"
	@echo "  kind-load   Load built image into kind cluster ($(KIND_CLUSTER))"
	@echo "  all         Build image and load into kind"
	@echo "Variables (override with make VAR=value):"
	@echo "  IMAGE_NAME=$(IMAGE_NAME)  IMAGE_TAG=$(IMAGE_TAG)  KIND_CLUSTER=$(KIND_CLUSTER)"

all: image kind-load

# Build the image using Boot Build Image
image: print-image
	$(GRADLE) :services:demo-order:bootBuildImage --imageName=$(IMAGE)

# Load the image into the specified kind cluster
kind-load: print-image
	kind load docker-image $(IMAGE) --name $(KIND_CLUSTER)

print-image:
	@echo "Using image: $(IMAGE)"

