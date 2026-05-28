APP_NAME=url-shortener
IMAGE_NAME=url-shortener
IMAGE_TAG=local
KIND_CLUSTER=sovereign-idp
NAMESPACE=url-shortener
CHART=./charts/url-shortener
VALUES_LOCAL=./charts/url-shortener/values-local.yaml

.PHONY: help dev-up dev-down test build import-image deploy-local smoke-test logs status clean

help:
	@echo "Available commands:"
	@echo "  make dev-up        Create local k3d cluster"
	@echo "  make dev-down      Delete local k3d cluster"
	@echo "  make test          Run app tests"
	@echo "  make build         Build Docker image"
	@echo "  make import-image  Import image into k3d"
	@echo "  make deploy-local  Deploy app with Helm"
	@echo "  make smoke-test    Run smoke tests"
	@echo "  make logs          Show app logs"
	@echo "  make status        Show cluster status"
	@echo "  make clean         Delete app namespace"

dev-up:
	kind create cluster --name $(KIND_CLUSTER)
	kubectl get nodes

dev-down:
	kind delete cluster --name $(KIND_CLUSTER)

test:
	cd app && python -m pytest -q

build:
	docker build -t $(IMAGE_NAME):$(IMAGE_TAG) ./app

import-image:
	kind load docker-image $(IMAGE_NAME):$(IMAGE_TAG) --name $(KIND_CLUSTER)

deploy-local: import-image
	kubectl create namespace $(NAMESPACE) --dry-run=client -o yaml | kubectl apply -f -
	helm upgrade --install $(APP_NAME) $(CHART) \
		--namespace $(NAMESPACE) \
		-f $(VALUES_LOCAL)
	kubectl rollout status deployment/$(APP_NAME) -n $(NAMESPACE) --timeout=120s

smoke-test:
	./scripts/smoke-test.sh

logs:
	kubectl logs -n $(NAMESPACE) deployment/$(APP_NAME) --tail=100 -f

status:
	kubectl get nodes -o wide
	kubectl get pods -A
	kubectl get svc -A
	kubectl get ingress -A

clean:
	kubectl delete namespace $(NAMESPACE) --ignore-not-found=true
