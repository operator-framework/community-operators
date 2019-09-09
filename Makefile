MAKEFLAGS += --no-print-directory
OP_PATH=''
CLEAN_MODE='NORMAL'
VM_DRIVER=none

help:
	@grep -E '^[a-zA-Z0-9/._-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

check_path:
	@if [ ! -d ${OP_PATH} ]; then echo "Operator path not found you need set it with OP_PATH=upstream-community-operators/your-operator"; exit 1; fi

minikube.install: ## Install the local minikube
	@./scripts/ci/install-minikube
	@echo "Installed"

minikube.start: ## Start local minikube
	@scripts/ci/run-script "minikube start --vm-driver=${VM_DRIVER} --kubernetes-version="v1.12.0" --extra-config=apiserver.v=4 -p operators" "Start minikube"

olm.install: ## Install OLM to your cluster
	@docker run --network host -v ~/.kube:/root/.kube -v ~/.minikube:${HOME}/.minikube -v ${PWD}/community-operators:/community-operators -v ${PWD}/upstream-community-operators:/upstream-community-operators -it quay.io/operator-framework/operator-testing olm.install --no-print-directory

operator.test: check_path ## Operator test which run courier and scorecard
	@docker pull quay.io/operator-framework/operator-testing -q
	@scripts/ci/check-kubeconfig
	@docker run --network host -v ~/.kube:/root/.kube -v ~/.minikube:${HOME}/.minikube -v ${PWD}/community-operators:/community-operators -v ${PWD}/upstream-community-operators:/upstream-community-operators -ti quay.io/operator-framework/operator-testing operator.test --no-print-directory OP_PATH=${OP_PATH} VERBOSE=${VERBOSE} OP_VER=${OP_VER} OP_CHANNEL=${OP_CHANNEL} INSTALL_MODE=${INSTALL_MODE} CLEAN_MODE=${CLEAN_MODE}

operator.verify: check_path ## Run only courier
	@docker pull quay.io/operator-framework/operator-testing -q
	@docker run -v ${PWD}/community-operators:/community-operators -v ${PWD}/upstream-community-operators:/upstream-community-operators -ti quay.io/operator-framework/operator-testing operator.verify --no-print-directory OP_PATH=${OP_PATH} VERBOSE=${VERBOSE}
