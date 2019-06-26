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

operator.olm.install: ## Install OLM to your cluster
	@docker run command operator.olm.install  -v ~/.kube:/root/.kube -v ./community-operators:/community-operators -v ./upstream-community-operators:/upstream-community-operators

operator.registry.build: check_path ## Build registry image
	@docker run command operator.registry.build -e OP_PATH=${OP_PATH} -e VERBOSE=${VERBOSE} -e REG_IMAGE=${REG_IMAGE} -e OP_VER=${OP_VER} -v ./community-operators:/community-operators -v ./upstream-community-operators:/upstream-community-operators

operator.test: check_path ## Operator test which run courier and scoreboard
	@docker run -v ~/.kube:/root/.kube -v ~/.minikube:${HOME}/.minikube -v ${PWD}/community-operators:/community-operators -v ${PWD}/upstream-community-operators:/upstream-community-operators -ti command operator.test -e OP_PATH=${OP_PATH} -e VERBOSE=${VERBOSE} -e REG_IMAGE=${REG_IMAGE} -e OP_VER=${OP_VER}

operator.verify: check_path ## Run only courier
	@docker run -ti command operator.verify -e OP_PATH=${OP_PATH} -e VERBOSE=${VERBOSE} -v ./community-operators:/community-operators -v ./upstream-community-operators:/upstream-community-operators
