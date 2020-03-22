MAKEFLAGS += --no-print-directory
export OP_PATH=''
export CLEAN_MODE=NORMAL
export KUBECONFIG := ${HOME}/.kube/config
export KUBE_VER ?= v1.17.0
export OLM_VER ?= 0.14.1
export SDK_VER ?= v0.16.0
export VERBOSE ?= 0
export NO_KIND ?= 0
export KIND_VER ?= v0.7.0

help:
	@grep -E '^[a-zA-Z0-9/._-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

check_path:
	@if [ ! -d ${OP_PATH} ]; then echo "Operator path not found you need set it with OP_PATH=upstream-community-operators/your-operator"; exit 1; fi

check_kind :
	@if [ ${NO_KIND} == true ] && [ -z ${CATALOG_IMAGE+x} ] ; then echo "You specified NO_KIND but did not specify CATALOG_IMAGE"; exit 1; fi

minikube.install: ## Install the local minikube
	@./scripts/ci/install-minikube
	@echo "Installed"

kind.install:
	@scripts/ci/run-script "scripts/ci/install-kind" "Install KIND"

kind.start:
	@scripts/ci/run-script "scripts/ci/start-kind" "Start KIND"

minikube.start: ## Start local minikube
	@scripts/ci/run-script "scripts/ci/start-minikube" "Start minikube"

olm.install: ## Install OLM to your cluster
	@scripts/ci/run-script "docker pull quay.io/operator-framework/operator-testing" "Pulling docker image"
	@python3 scripts/utils/check-kube-config.py
	@docker run -v ${KUBECONFIG}:/root/.kube/config:Z -v ${PWD}/community-operators:/community-operators:Z -v ${PWD}/upstream-community-operators:/upstream-community-operators:Z -it quay.io/operator-framework/operator-testing olm.install --no-print-directory VERBOSE=${VERBOSE}

operator.install:
	@scripts/ci/run-script "docker pull quay.io/operator-framework/operator-testing" "Pulling docker image"
	@python3 scripts/utils/check-kube-config.py
	@docker run -v ${KUBECONFIG}:/root/.kube/config:Z -v ${PWD}/community-operators:/community-operators:Z -v ${PWD}/upstream-community-operators:/upstream-community-operators:Z -ti quay.io/operator-framework/operator-testing operator.install --no-print-directory OP_PATH=${OP_PATH} VERBOSE=${VERBOSE} OP_VER=${OP_VER} OP_CHANNEL=${OP_CHANNEL} INSTALL_MODE=${INSTALL_MODE} CLEAN_MODE=${CLEAN_MODE}

operator.cleanup:
	@scripts/ci/run-script "scripts/ci/cleanup" "Cleaning"

operator.test: check_path check_kind ## Operator test which run courier and scorecard
	@scripts/ci/run-script "docker pull quay.io/operator-framework/operator-testing" "Pulling docker image"
	@python3 scripts/utils/check-kube-config.py
	@scripts/ci/run-script "scripts/ci/build-catalog-image" "Building catalog image"
	@docker run --network=host -v ${KUBECONFIG}:/root/.kube/config:Z -v ${PWD}/community-operators:/community-operators:Z -v ${PWD}/upstream-community-operators:/upstream-community-operators:Z -ti quay.io/dmesser/operator-testing operator.test --no-print-directory OP_PATH=${OP_PATH} VERBOSE=${VERBOSE} OP_VER=${OP_VER} OP_CHANNEL=${OP_CHANNEL} INSTALL_MODE=${INSTALL_MODE} CLEAN_MODE=${CLEAN_MODE} OLM_VER=${OLM_VER} KUBE_VER=${KUBE_VER} NO_KIND=${NO_KIND} CATALOG_IMAGE=${CATALOG_IMAGE}

operator.verify: check_path ## Run only courier
	@scripts/ci/run-script "docker pull quay.io/operator-framework/operator-testing" "Pulling docker image"
	@docker run -v ${PWD}/community-operators:/community-operators:Z -v ${PWD}/upstream-community-operators:/upstream-community-operators:Z -ti quay.io/operator-framework/operator-testing operator.verify --no-print-directory OP_PATH=${OP_PATH} VERBOSE=${VERBOSE}
