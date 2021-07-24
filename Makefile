PROJECT-ID    := minectl-fn
FILES         := $(shell find * -type f ! -path 'vendor/*' -name '*.go')
.DEFAULT_GOAL := help
Version       := $(shell git describe --tags --dirty)
GitCommit     := $(shell git rev-parse HEAD)


.PHONY: lint
lint: golangci-lint

.PHONY: golangci-lint
golangci-lint:
	@hash golangci-lint > /dev/null 2>&1; if [ $$? -ne 0 ]; then \
		export BINARY="golangci-lint"; \
		curl -sfL https://install.goreleaser.com/github.com/golangci/golangci-lint.sh | sh -s -- -b $(GOPATH)/bin v1.41.1; \
	fi
	golangci-lint run --timeout 10m -E goimports --fix

.PHONY: test
test: ## Run the tests against the codebase
	go test -v ./...

.PHONY: docker-build-java-version
docker-build-java-version:
	docker build -f Dockerfile.java-version . -t gcr.io/$(PROJECT-ID)/java-version

.PHONY: build-java-version
build-java-version: clean test lint ## Build the binaries
	mkdir -p bin/
	CGO_ENABLED=0 GOOS=linux go build -ldflags "-s -w -X main.version=$(Version) -X main.commit=$(GitCommit)" -a -installsuffix cgo -o bin/$(NAME) ./cmd/java-version

.PHONY: docker-build-bedrock-version
docker-build-bedrock-version:
	docker build -f Dockerfile.bedrock-version . -t gcr.io/$(PROJECT-ID)/bedrock-version

.PHONY: build-bedrock-version
build-bedrock-version: clean test lint ## Build the binaries
	mkdir -p bin/
	CGO_ENABLED=0 GOOS=linux go build -ldflags "-s -w -X main.version=$(Version) -X main.commit=$(GitCommit)" -a -installsuffix cgo -o bin/$(NAME) ./cmd/bedrock-version


.PHONY: clean
clean: ## Remove binary if it exists
	rm -rf bin/

.PHONY: coverage
coverage: ## Generates coverage report
	rm -rf *.out
	go test -v ./... -coverpkg=./... -coverprofile=coverage.out

.PHONY: help
help: ## Displays this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
