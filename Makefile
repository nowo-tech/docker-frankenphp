# FrankenPHP image: upstream Dockerfile, newer PHP base.
include versions.env
export

UPSTREAM_DIR := .upstream/frankenphp
IMAGE        := $(DOCKERHUB_USER)/$(IMAGE_NAME)
PLATFORMS    ?= linux/amd64,linux/arm64

# Same tag scheme as upstream docker-bake.hcl: the OS suffix is always there,
# the plain tag (no suffix) only for trixie, the default Debian.
TAG          := $(FRANKENPHP_VERSION)-php$(PHP_VERSION)-$(OS)
BASE_TAGS    := -t $(IMAGE):$(TAG)
ifeq ($(OS),trixie)
BASE_TAGS    += -t $(IMAGE):$(FRANKENPHP_VERSION)-php$(PHP_VERSION)
endif
SYMFONY_TAG  := $(TAG)-symfony
SYMFONY_TAGS := -t $(IMAGE):$(SYMFONY_TAG)

ifeq ($(OS),alpine)
DOCKERFILE   := $(UPSTREAM_DIR)/alpine.Dockerfile
else
DOCKERFILE   := $(UPSTREAM_DIR)/Dockerfile
endif

# Same OCI labels upstream docker-bake.hcl sets on its images
OCI_LABELS := \
	--label org.opencontainers.image.version=v$(FRANKENPHP_VERSION) \
	--label org.opencontainers.image.revision=$(FRANKENPHP_COMMIT)

BASE_CONTEXTS := \
	--build-context php-base=docker-image://php:$(PHP_VERSION)-zts-$(OS) \
	--build-context golang-base=docker-image://golang:$(GO_VERSION)-$(OS)

.PHONY: help fetch build build-base build-symfony test push push-multiarch clean

help: ## List targets
	@grep -E '^[a-z-]+:.*##' $(MAKEFILE_LIST) | awk -F':.*## ' '{printf "  %-16s %s\n", $$1, $$2}'

fetch: ## Clone upstream FrankenPHP at the pinned tag and check the commit
	@if [ ! -d $(UPSTREAM_DIR) ]; then \
		git clone -q --depth 1 --branch v$(FRANKENPHP_VERSION) https://github.com/php/frankenphp.git $(UPSTREAM_DIR); \
	fi
	@test "$$(git -C $(UPSTREAM_DIR) rev-parse HEAD)" = "$(FRANKENPHP_COMMIT)" \
		|| { echo "Upstream commit mismatch (expected $(FRANKENPHP_COMMIT))"; exit 1; }
	@echo "Upstream v$(FRANKENPHP_VERSION) OK ($(FRANKENPHP_COMMIT))"

build: build-base build-symfony ## Build both images for the local platform

build-base: fetch ## Build the base image (same as dunglas/frankenphp, newer PHP)
	docker buildx build $(UPSTREAM_DIR) -f $(DOCKERFILE) --target runner \
		$(BASE_CONTEXTS) $(OCI_LABELS) --build-arg FRANKENPHP_VERSION=$(FRANKENPHP_VERSION) \
		$(BASE_TAGS) --load

build-symfony: ## Build the Symfony variant on top of the base image
	docker buildx build symfony --build-arg BASE_IMAGE=$(IMAGE):$(TAG) $(SYMFONY_TAGS) --load

test: ## Smoke test: versions, extensions and an HTTP request
	docker run --rm $(IMAGE):$(TAG) frankenphp version
	docker run --rm $(IMAGE):$(TAG) php -v | grep "PHP $(PHP_VERSION)"
	docker run --rm $(IMAGE):$(SYMFONY_TAG) sh -c 'php -m | grep -E "^(intl|pdo_pgsql|redis|apcu|zip)$$" && composer --version'
	@cid=$$(docker run -d -p 18080:80 -e SERVER_NAME=:80 $(IMAGE):$(TAG)); \
		sleep 3; curl -fsS -o /dev/null -w "HTTP %{http_code}\n" http://localhost:18080/; rc=$$?; \
		docker stop $$cid >/dev/null; docker container rm $$cid >/dev/null; exit $$rc

push: ## Push every local tag of IMAGE (local platform only)
	docker push --all-tags $(IMAGE)

push-multiarch: fetch ## Build and push for PLATFORMS (slow on emulated arches)
	docker buildx build $(UPSTREAM_DIR) -f $(DOCKERFILE) --target runner \
		$(BASE_CONTEXTS) $(OCI_LABELS) --build-arg FRANKENPHP_VERSION=$(FRANKENPHP_VERSION) \
		--platform $(PLATFORMS) $(BASE_TAGS) --push
	docker buildx build symfony --build-arg BASE_IMAGE=$(IMAGE):$(TAG) \
		--platform $(PLATFORMS) $(SYMFONY_TAGS) --push

clean: ## Remove the upstream clone and local images
	rm -rf .upstream
	-docker image rm $(IMAGE):$(TAG) $(IMAGE):$(SYMFONY_TAG)
