.PHONY: build push test build-multiarch

IMAGE_NAME = ghcr.io/the-mines/sbi/git-init-compat
VERSION = v3.0.1
PLATFORMS = linux/amd64,linux/arm64

build:
	docker build -t $(IMAGE_NAME):$(VERSION) -t $(IMAGE_NAME):latest .

build-multiarch:
	docker buildx build --platform $(PLATFORMS) \
		-t $(IMAGE_NAME):$(VERSION) \
		-t $(IMAGE_NAME):latest \
		--push .

push: build
	docker push $(IMAGE_NAME):$(VERSION)
	docker push $(IMAGE_NAME):latest

test: build
	@echo "Testing git-init compatibility image..."
	docker run --rm $(IMAGE_NAME):latest -url=https://github.com/octocat/Hello-World -path=/tmp/test -revision=master

test-tekton:
	@echo "Testing with Tekton task..."
	kubectl delete taskrun git-clone-compat-test --ignore-not-found
	kubectl apply -f ../tekton-git-clone-example.yaml
	kubectl wait --for=condition=Succeeded taskrun/git-clone-compat-test --timeout=60s
	kubectl logs -l tekton.dev/taskRun=git-clone-compat-test