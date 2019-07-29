MAKEFLAGS += --no-print-directory
OP_PATH=''
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
	@docker run -v ~/.kube:/root/.kube -v ./community-operators:/community-operators -v ./upstream-community-operators:/upstream-community-operators sebastiansimko/operator-command operator.olm.install

operator.test: check_path ## Operator test which run courier and scorecard
	@scripts/ci/check-kubeconfig
	@docker run --network host -v ~/.kube:/root/.kube -v ~/.minikube:${HOME}/.minikube -v ${PWD}/community-operators:/community-operators -v ${PWD}/upstream-community-operators:/upstream-community-operators -ti sebastiansimko/operator-command operator.test --no-print-directory OP_PATH=${OP_PATH} VERBOSE=${VERBOSE} OP_VER=${OP_VER}

operator.verify: check_path ## Run only courier
	@docker run -v ${PWD}/community-operators:/community-operators -v ${PWD}/upstream-community-operators:/upstream-community-operators -ti sebastiansimko/operator-command operator.verify --no-print-directory OP_PATH=${OP_PATH} VERBOSE=${VERBOSE}
