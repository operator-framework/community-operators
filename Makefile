SDK_VER="v0.6.0"
KUBE_VER="v1.13.0"

check_path:
	@if [ ! -d ${OP_PATH} ]; then echo "Operator path not found"; exit 1; fi

help:
    @grep -E '^[a-zA-Z0-9/._-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

dependencies.check: check_path
	@scripts/utils/check-deps

dependencies.install.yq:
	@curl -Lo yq https://github.com/mikefarah/yq/releases/download/2.2.1/yq_linux_amd64
	@chmod +x yq
	@sudo mv yq /usr/local/bin/
	@echo "Installed"

dependencies.install.jq:
	@curl -Lo jq https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64
	@chmod +x jq
	@sudo mv jq /usr/local/bin/
	@echo "Installed"

dependencies.install.operator-courier:
	@python3 -m pip install operator-courier
	@echo "Installed"

dependencies.install.operator-sdk:
	@curl -Lo operator-sdk "https://github.com/operator-framework/operator-sdk/releases/download/${SDK_VER}/operator-sdk-${SDK_VER}-x86_64-linux-gnu"
	@chmod +x operator-sdk
	@sudo mv operator-sdk /usr/local/bin/
	@echo "Installed"

dependencies.install.kubectl:
	@curl -Lo kubectl "https://storage.googleapis.com/kubernetes-release/release/${KUBE_VER}/bin/linux/amd64/kubectl"
	@chmod +x kubectl
	@sudo mv kubectl /usr/local/bin/
	@echo "Installed"

dependencies.install.crictl:
	@curl -Lo crictl.tar.gz "https://github.com/kubernetes-sigs/cri-tools/releases/download/${KUBE_VER}/crictl-${KUBE_VER}-linux-amd64.tar.gz"
	@tar -zxvf crictl.tar.gz
	@chmod +x crictl
	@sudo mv crictl /usr/local/bin/
	@rm crictl.tar.gz
	@echo "Installed"

dependencies.install.minikube:
	@curl -Lo minikube https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
	@chmod +x minikube
	@sudo mv minikube /usr/local/bin/
	@echo "Installed"

minikube.start:
	@sudo minikube start --vm-driver=none --kubernetes-version="v1.12.0" --extra-config=apiserver.v=4 -p operator
	@sudo kubectl apply -f https://github.com/operator-framework/operator-lifecycle-manager/releases/download/0.8.1/olm.yaml
	@sudo kubectl delete catalogsource operatorhubio-catalog -n olm

operator.community.verify: check_path
	@operator-courier verify ${OP_PATH}

operator.test: check_path
	@scripts/ci/test-operator

operator.upstream.verify: check_path
	@operator-courier verify --ui_validate_io ${OP_PATH}