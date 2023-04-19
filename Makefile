PROJECT_NAME := keepalived-exporter
PKG := "github.com/mehdy/$(PROJECT_NAME)"
LINTER = golangci-lint
LINTER_VERSION = 1.52.2
CURRENT_LINTER_VERSION := $(shell golangci-lint version 2>/dev/null | awk '{ print $$4 }')

BUILD_TIME := $(shell LANG=en_US date +"%F_%T_%z")
COMMIT := $(shell git rev-parse --short HEAD)
BRANCH := $(shell git rev-parse --abbrev-ref HEAD)
VERSION ?= $(shell git describe --tags ${COMMIT} 2>/dev/null | cut -c2-)
VERSION := $(or $(VERSION),$(COMMIT))
LD_FLAGS ?=
LD_FLAGS += -X github.com/prometheus/common/version.Version=$(VERSION)
LD_FLAGS += -X github.com/prometheus/common/version.Revision=$(COMMIT)
LD_FLAGS += -X github.com/prometheus/common/version.Branch=$(BRANCH)
LD_FLAGS += -X github.com/prometheus/common/version.BuildDate=$(BUILD_TIME)

.PHONY: all dep lint build clean

all: dep build

dep: ## Get the dependencies
	@go mod tidy

lintdeps: ## golangci-lint dependencies
ifneq ($(CURRENT_LINTER_VERSION), $(LINTER_VERSION))
	@curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | sh -s -- -b $(GOPATH)/bin v$(LINTER_VERSION)
endif

lint: lintdeps ## to lint the files
	$(LINTER) run --config=.golangci-lint.yml ./...

build: ## Build the binary file
	@go build -v -ldflags="$(LD_FLAGS)" $(PKG)/cmd/$(PROJECT_NAME)

test:
	@go test -v -cover -race ./...

clean: ## Remove previous build and release files
	@rm -f $(PROJECT_NAME)
	@rm -f $(RELEASE_FILENAME).zip
	@rm -f $(RELEASE_FILENAME).tar.gz
