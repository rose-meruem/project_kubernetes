APP_NAME=url-shortener
IMAGE_NAME=url-shortener
IMAGE_TAG=local
KIND_CLUSTER=sovereign-idp
NAMESPACE=url-shortener
CHART=./charts/url-shortener
VALUES_LOCAL=./charts/url-shortener/values-local.yaml

.PHONY: help dev-up dev-down test build import-image deploy-local smoke-test logs status clean helm-lint helm-template validate-chart argocd-status argocd-check gitops-test

help:
	@echo "Available commands:"
	@echo "  make dev-up        Create local kind cluster"
	@echo "  make dev-down      Delete local kind cluster"
	@echo "  make test          Run app tests"
	@echo "  make build         Build Docker image"
	@echo "  make import-image  Import image into kind"
	@echo "  make deploy-local  Deploy app with Helm"
	@echo "  make smoke-test    Run smoke tests"
	@echo "  make logs          Show app logs"
	@echo "  make status        Show cluster status"
	@echo "  make clean         Delete app namespace"
	@echo "  make helm-lint     Lint Helm chart"
	@echo "  make helm-template Render Helm chart"
	@echo "  make validate-chart Validate Helm chart rendering"
	@echo "  make argocd-status Show Argo CD application status"
	@echo "  make argocd-check  Check Argo CD sync status"
	@echo "  make gitops-test   Validate Argo CD sync and app smoke test"

dev-up:
	kind create cluster --name $(KIND_CLUSTER)
	kubectl wait --for=condition=Ready node/$(KIND_CLUSTER)-control-plane --timeout=120s
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

helm-lint:
	helm lint $(CHART)

helm-template:
	helm template $(APP_NAME) $(CHART) -f $(VALUES_LOCAL) >/tmp/url-shortener-rendered.yaml

validate-chart: helm-lint helm-template

argocd-status:
	kubectl get applications -n argocd
	kubectl describe application $(APP_NAME) -n argocd

argocd-check:
	kubectl wait application/$(APP_NAME) \
		-n argocd \
		--for=jsonpath='{.status.sync.status}'=Synced \
		--timeout=120s
	kubectl get application $(APP_NAME) -n argocd

gitops-test:
	$(MAKE) argocd-check
	kubectl get pods -n $(NAMESPACE)
	kubectl get deploy -n $(NAMESPACE)
	kubectl get statefulset -n $(NAMESPACE)
	$(MAKE) smoke-test
