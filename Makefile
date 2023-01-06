mkfile_path := $(abspath $(lastword $(MAKEFILE_LIST)))
base_dir := $(notdir $(patsubst %/,%,$(dir $(mkfile_path))))

SERVICE?= $(base_dir)
DOCKER_REGISTRY=registry.uw.systems
DOCKER_REPOSITORY_NAMESPACE=onboarding
DOCKER_ID :=$(DOCKER_REPOSITORY_NAMESPACE)
DOCKER_REPOSITORY_IMAGE=$(SERVICE)
DOCKER_REPOSITORY=$(DOCKER_REGISTRY)/$(DOCKER_REPOSITORY_NAMESPACE)/$(DOCKER_REPOSITORY_IMAGE)


# K8s Settings
K8S_NAMESPACE=$(DOCKER_REPOSITORY_NAMESPACE)
K8S_DEPLOYMENT_NAME=onboarding-lfell
K8S_CONTAINER_NAME=$(K8S_DEPLOYMENT_NAME)

K8S_URL=https://elb.master.k8s.dev.uw.systems/apis/apps/v1/namespaces/$(K8S_NAMESPACE)/deployments/$(K8S_DEPLOYMENT_NAME)
K8S_PAYLOAD={"spec":{"template":{"spec":{"containers":[{"name":"$(K8S_CONTAINER_NAME)","image":"$(DOCKER_REPOSITORY):$(CIRCLE_SHA1)$(CIRCLE_BUILD_NUM)"}]}}}}

# Building settings
BUILDENV :=
BUILDENV += CGO_ENABLED=0
BUILDENV += GO111MODULE=on
BUILDENV += GOPRIVATE="github.com/utilitywarehouse/*"

# Linter
LINTER_EXE := golangci-lint
LINTER := $(shell which $(LINTER_EXE))
LINT_FLAGS :=


LINKFLAGS :=-s -X main.gitHash=$(GIT_HASH) -extldflags "-static"
TESTFLAGS := -v -cover


.PHONY: lint
lint: $(LINTER)
		$(LINTER) run $(LINTER_FLAGS) ./...

.PHONY: install
install:
	GO111MODULE=on GOPRIVATE="github.com/utilitywarehouse/*" go mod download

.PHONY: clean
clean:
	rm -f $(SERVICE)

#$(SERVICE): clean
	#GO111MODULE=on $(BUILDENV) go build -o $(SERVICE) -a -ldflags '$(LINKFLAGS)' ./cmd/$(SERVICE)/*.go

#build: $(SERVICE)

.PHONY: test
test:
	GO111MODULE=on $(BUILDENV) go test $(TESTFLAGS) ./...

.PHONY: all
all: clean install test build


docker-image:
	docker build -t $(DOCKER_REPOSITORY):local . --build-arg SERVICE=$(SERVICE) --build-arg GITHUB_TOKEN=$(GITHUB_TOKEN)

ci-docker-auth:
	@echo "Logging in to $(DOCKER_REGISTRY) as $(DOCKER_ID)"
	@echo $(UW_DOCKER_PASS) | docker login -u $(DOCKER_ID) --password-stdin $(DOCKER_REGISTRY)

ci-docker-build: ci-docker-auth
	docker build -t $(DOCKER_REPOSITORY):$(CIRCLE_SHA1) . --build-arg SERVICE=$(SERVICE) --build-arg GITHUB_TOKEN=$(GITHUB_TOKEN)
	docker tag $(DOCKER_REPOSITORY):$(CIRCLE_SHA1) $(DOCKER_REPOSITORY):latest
	docker push $(DOCKER_REPOSITORY)

ci-kubernetes-push:
	@echo "Executing curl -o /dev/null -w '%{http_code}' -s -X PATCH -k -d '$(K8S_PAYLOAD)' -H 'Content-Type: application/strategic-merge-patch+json' -H 'Authorization: Bearer <K8S_DEV_TOKEN>' '$(K8S_URL)')"
	test "$(shell curl -o /dev/null -w '%{http_code}' -s -X PATCH -k -d '$(K8S_PAYLOAD)' -H 'Content-Type: application/strategic-merge-patch+json' -H 'Authorization: Bearer $(K8S_DEV_TOKEN)' '$(K8S_URL)')" -eq "200"