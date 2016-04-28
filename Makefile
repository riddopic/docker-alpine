# encoding: UTF-8
#
# Load the latest tag, and set a default for TAG. The goal here is to ensure
# TAG is set as early possible, considering it's usually provided as an input
# anyway, but we want running "make" to *just work*.
include latest.mk

ifndef LATEST_TAG
$(error LATEST_TAG *must* be set in latest.mk)
endif

ifeq "$(TAG)" "latest"
override TAG = $(LATEST_TAG)
endif

TAG ?= $(LATEST_TAG)

# Import configuration. config.mk must set the variables REGISTRY and
# REPOSITORY so the Makefile knows what to call your image. You can also set
# PUSH_REGISTRIES and PUSH_TAGS to customize what will be pushed. Finally, you
# can set any variable that'll be used by your build process, but make sure you
# export them so they're visible in build programs!
include config.mk

ifndef REGISTRY
$(error REGISTRY *must* be set in config.mk)
endif

ifndef REPOSITORY
$(error REPOSITORY *must* be set in config.mk)
endif

# Create $(TAG)/config.mk if you need to e.g. set environment variables
# depending on the tag being built. This is typically useful for things
# constants like a point version, a sha1sum, etc. (note that $(TAG)/config.mk
# is entirely optional).
-include $(TAG)/config.mk

# By default, we'll push the tag we're building, and the 'latest' tag if said
# tag is indeed the latest one. Set PUSH_TAGS in config.mk (or $(TAG)/config.mk)
# to override that behavior (note: you can't override the 'latest' tag).
PUSH_TAGS ?= $(TAG)

ifeq "$(TAG)" "$(LATEST_TAG)"
PUSH_TAGS += latest
endif

# By default, we'll push the registry we're naming the image after. You can
# override this in config.mk (or $(TAG)/config.mk)
PUSH_REGISTRIES ?= $(REGISTRY)

# Export what we're building for e.g. test scripts to use. Exporting other
# variables is the responsibility of config.mk and $(TAG)/config.mk.
export REGISTRY
export REPOSITORY
export TAG

step=-=-=-=-=-=-=-=-=-

# define colorecho
# 	@tput setaf 1
# 	@printf "%$(tput cols)s\n"|tr ' ' '='
# 	@echo $1
# 	@printf "%$(tput cols)s\n"|tr ' ' '='
# 	@tput sgr0
# endef

# Define actual usable targets
push: save
	# $(call colorecho,"$(step) Release $(REGISTRY)/$(REPOSITORY):$(TAG) $(step)")
	set -e ; \
	for registry in $(PUSH_REGISTRIES); do \
		for tag in $(PUSH_TAGS); do \
			docker tag -f "$(REGISTRY)/$(REPOSITORY):$(TAG)" "$${registry}/$(REPOSITORY):$${tag}"; \
			docker push "$${registry}/$(REPOSITORY):$${tag}"; \
		done \
	done

save: test
ifdef $(CI)
	# $(call colorecho,"$(step) Generating $(REGISTRY)/$(REPOSITORY):$(TAG) artifact $(step)")
	mkdir -p builds
	docker save -o "builds/image-$(REPOSITORY)-$(TAG).tar" $(REGISTRY)/$(REPOSITORY):$(TAG)
endif

test: build
	$(call colorecho,"$(step) Testing $(REGISTRY)/$(REPOSITORY):$(TAG) $(step)")
	set -e ;\
	if [ -f "test/alpine-${TAG}.bats" ]; then \
		bats test/alpine-$(TAG).bats; \
	fi

.build: . $(TAG) $(DEPS)
	# $(call colorecho,"$(step) Building $(REGISTRY)/$(REPOSITORY):$(TAG) $(step)")
	docker build -t "$(REGISTRY)/$(REPOSITORY):$(TAG)" -f "$(TAG)/Dockerfile" .
	@docker inspect -f '{{.Id}}' $(REGISTRY)/$(REPOSITORY):$(TAG) > $(TAG)/.build
ifeq "$(TAG)" "$(LATEST_TAG)"
	docker tag -f "$(REGISTRY)/$(REPOSITORY):$(TAG)" "$(REGISTRY)/$(REPOSITORY):latest"
endif

build: $(TAG)/Dockerfile .build

clean: stop
	# $(call colorecho,"$(step) Cleaning $(REGISTRY)/$(REPOSITORY):$(TAG) $(step)")
	@$(RM) $(TAG)/.build
	-docker rmi "$(REPOSITORY):${TAG}"
ifeq "$(TAG)" "$(LATEST_TAG)"
	-docker rmi "$(REPOSITORY):latest"
endif

stop:
	# $(call colorecho,"$(step) Stoping $(REGISTRY)/$(REPOSITORY):$(TAG) $(step)")
	-docker stop "$(REPOSITORY):${TAG}"
	-docker rm "$(REPOSITORY):${TAG}"
ifeq "$(TAG)" "$(LATEST_TAG)"
	-docker rm "$(REPOSITORY):latest"
endif

# Per-tag Dockerfile target. Look for Dockerfile or Dockerfile.erb in the root,
# and use it for $(TAG). We prioritize Dockerfile.erb over Dockerfile if both
# are present.
$(TAG)/Dockerfile: Dockerfile.erb Dockerfile | $(TAG)
	# $(call colorecho,"$(step) Rendering $(REGISTRY)/$(REPOSITORY):$(TAG) Dockerfile $(step)")
	set -e ;\
	if [ -f 'Dockerfile.erb' ]; then \
		erb "Dockerfile.erb" > "$(TAG)/Dockerfile"; \
	else \
		cp "Dockerfile" "$(TAG)/Dockerfile"; \
	fi

# Pseudo targets for Dockerfile and Dockerfile.erb. They don't technically
# create anything, but each warn if the other file is missing (meaning both
# files are missing).
Dockerfile.erb:
	@ if [ ! -f 'Dockerfile' ]; then echo "You must create one of Dockerfile.erb or Dockerfile"; exit 1; fi

Dockerfile:
	@ if [ ! -f 'Dockerfile.erb' ]; then echo "You must create one of Dockerfile.erb or Dockerfile"; exit 1; fi

$(TAG):
	mkdir -p "$(TAG)"

# list of dependancies in the build context
DEPS = $(shell find $(TAG) -type f -print)

.PHONY: push save test build clean stop
.DEFAULT_GOAL := build
