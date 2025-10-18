# Simple Makefile to build the gateway image and load into kind

# Config
IMAGE_NAME 		?= stocat-gateway
IMAGE_TAG  		?= 0.0.1-SNAPSHOT
KIND_CLUSTER 	?= kind-local

GRADLE ?= ../gradlew

IMAGE := $(IMAGE_NAME):$(IMAGE_TAG)

.PHONY: help all image kind-load print-image build-jar

help:
	@echo "Targets:"
	@echo "  image       Build container image via Spring Boot buildpacks"
	@echo "  kind-load   Load built image into kind cluster ($(KIND_CLUSTER))"
	@echo "  all         Build image and load into kind"
	@echo "Variables (override with make VAR=value):"
	@echo "  IMAGE_NAME=$(IMAGE_NAME)  IMAGE_TAG=$(IMAGE_TAG)  KIND_CLUSTER=$(KIND_CLUSTER)"

all: image kind-load

# Build the application JAR first, then docker build using the Dockerfile
build-jar:
	$(GRADLE) :gateway:bootJar

image: print-image build-jar
	docker build -t $(IMAGE) .

# Load the image into the specified kind cluster
kind-load: print-image
	kind load docker-image $(IMAGE) --name $(KIND_CLUSTER)

print-image:
	@echo "Using image: $(IMAGE)"
