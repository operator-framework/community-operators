#!/bin/bash
set +o pipefail

ACTION=${1-""}
TESTS=$1

[[ $TESTS == all* ]] && TESTS="kiwi,lemon,orange"
TESTS=${TESTS//,/ }

OPP_INPUT_REPO=${OPP_INPUT_REPO-"operator-framework/community-operators"}
OPP_INPUT_BRANCH=${OPP_INPUT_BRANCH-"master"}
OPP_THIS_SCRIPT_URL="https://raw.githubusercontent.com/$OPP_INPUT_REPO/$OPP_INPUT_BRANCH/ci/scripts/opp.sh"
OPP_THIS_REPO=${OPP_INPUT_REPO-"redhat-openshift-ecosystem/community-operators-pipeline"}
OPP_THIS_BRANCH=${OPP_INPUT_BRANCH-"main"}


OPP_BASE_DEP="ansible curl openssl git"
KIND_KUBE_VERSION=${KIND_KUBE_VERSION-"v1.19.11"}
OPP_PRODUCTION_TYPE=${OPP_PRODUCTION_TYPE-"ocp"}
OPP_CLUSTER_TYPE="k8s"
OPP_OPERATORS_DIR=${OPP_OPERATORS_DIR-"operators"}

OPP_INDEX_SAFETY="-e enable_production=true"
OPP_POD_START_RETRIES_LONG_DEPLOYMENT_WAIT_RETRIES=300
OPP_ANSIBLE_PULL_REPO=${OPP_ANSIBLE_PULL_REPO-"https://github.com/redhat-openshift-ecosystem/operator-test-playbooks"}
OPP_ANSIBLE_PULL_BRANCH=${OPP_ANSIBLE_PULL_BRANCH-"upstream-community"}
OPP_IMAGE=${OPP_IMAGE-"quay.io/operator_testing/operator-test-playbooks:latest"}
OPP_CONTAINER_TOOL=${OPP_CONTAINER_TOOL-"docker"}
OPP_CONTAINER_OPT=${OPP_CONTAINER_OPT-"-it"}
OPP_CERT_DIR=${OPP_CERT_DIR-"$HOME/.optest/certs"}
OPP_NAME=${OPT_TEST_NAME-"op-test"}
OPP_ANSIBLE_DEFAULT_ARGS=${OPP_ANSIBLE_DEFAULT_ARGS-"-i localhost, -e ansible_connection=local -e run_upstream=true -e run_remove_catalog_repo=false upstream/local.yml"}
OPP_ANSIBLE_EXTRA_ARGS=${OPP_ANSIBLE_EXTRA_ARGS-"--tags kubectl,install_kind"}
OPP_CONAINER_RUN_DEFAULT_ARGS=${OPP_CONAINER_RUN_DEFAULT_ARGS-"--net host --cap-add SYS_ADMIN --cap-add SYS_RESOURCE --security-opt seccomp=unconfined --security-opt label=disable -v $OPP_CERT_DIR/domain.crt:/usr/share/pki/ca-trust-source/anchors/ca.crt -e STORAGE_DRIVER=vfs -e BUILDAH_FORMAT=docker"}
OPP_CONTAINER_RUN_EXTRA_ARGS=${OPP_CONTAINER_RUN_EXTRA_ARGS-""}
OPP_CONTAINER_EXEC_DEFAULT_ARGS=${OPP_CONTAINER_EXEC_DEFAULT_ARGS-""}
OPP_CONTAINER_EXEC_EXTRA_ARGS=${OPP_CONTAINER_EXEC_EXTRA_ARGS-""}
OPP_EXEC_BASE=${OPP_EXEC_BASE-"ansible-playbook -i localhost, -e ansible_connection=local upstream/local.yml -e run_upstream=true -e image_protocol='docker://'"}
OPP_EXEC_EXTRA=${OPP_EXEC_EXTRA-"-e container_tool=podman"}
OPP_RUN_MODE=${OPP_RUN_MODE-"privileged"}
OPP_LABELS=${OPP_LABELS-""}
OPP_PROD=${OPP_PROD-0}
OPP_PRETEST_CUSTOM_SCRIPT=${OPP_PRETEST_CUSTOM_SCRIPT-""}
OPP_DEBUG=${OPP_DEBUG-0}
OPP_DRY_RUN=${OPP_DRY_RUN-0}
OPP_FORCE_INSTALL=${OPP_FORCE_INSTALL-0}
OPP_RESET=${OPP_RESET-1}
OPP_IIB_INSTALL=${OPP_IIB_INSTALL-0}
OPP_LOG_DIR=${OPP_LOG_DIR-"/tmp/op-test"}
OPP_NOCOLOR=${OPP_NOCOLOR-0}

OHIO_INPUT_CATALOG_IMAGE=${OHIO_INPUT_CATALOG_IMAGE-"quay.io/operatorhubio/catalog:latest"}
OHIO_REGISTRY_IMAGE=${OHIO_REGISTRY_IMAGE-"quay.io/operator-framework/upstream-community-operators:latest"}

IIB_PUSH_IMAGE=${IIB_PUSH_IMAGE-"quay.io/operator_testing/catalog:latest"}
IIB_INPUT_REGISTRY_USER=${IIB_INPUT_REGISTRY_USER-"mvalahtv"}
IIB_INPUT_REGISTRY_TOKEN=${IIB_INPUT_REGISTRY_TOKEN-""}
IIB_OUTPUT_REGISTRY_USER=${IIB_OUTPUT_REGISTRY_USER-"redhat+iib_community"}
IIB_OUTPUT_REGISTRY_TOKEN=${IIB_OUTPUT_REGISTRY_TOKEN-""}
OPP_MIRROR_IMAGE_POSTFIX=${OPP_MIRROR_IMAGE_POSTFIX-""}
OPP_INDEX_MIRROR=${OPP_INDEX_MIRROR-1}
OPP_MIRROR_LATEST_TAG=${OPP_MIRROR_LATEST_TAG-"v4.6"}

OPP_VER_OVERWRITE=${OPP_VER_OVERWRITE-0}
OPP_RECREATE=${OPP_RECREATE-0}
OPP_FORCE_DEPLOY_ON_K8S=${OPP_FORCE_DEPLOY_ON_K8S-0}
OPP_CI_YAML_ONLY=${OPP_CI_YAML_ONLY-0}
OPP_UNCOMPLETE="/tmp/operators_uncomplete-localhost.yaml"
DELETE_APPREG=${DELETE_APPREG-0}
OPP_DEPLOY_LONGER=${OPP_DEPLOY_LONGER-0}

export GODEBUG=${GODEBUG-x509ignoreCN=0}

[[ $OPP_NOCOLOR -eq 1 ]] && ANSIBLE_NOCOLOR=1

# Handle if cluster is k8s (pure kubernetes) or openshift
[[ OPP_PRODUCTION_TYPE == "ocp" || OPP_PRODUCTION_TYPE == "okd" ]] && OPP_CLUSTER_TYPE="openshift"

function help() {
    echo ""
    echo "op-test <test1,test2,...,testN> [<rebo>] [<branch>]"
    echo ""
    echo "Note: 'op-test' can be substituted by 'bash <(curl -sL $OPP_THIS_SCRIPT_URL)'"
    echo ""
    echo -e "Examples:\n"
    echo -e "\top-test all operators/aqua/1.0.2\n"
    echo -e "\top-test all operators/aqua/1.0.2 https://github.com/$OPP_THIS_REPO $OPP_THIS_BRANCH\n"
    echo -e "\top-test kiwi operators/aqua/1.0.2 https://github.com/$OPP_THIS_REPO $OPP_THIS_BRANCH\n"
    echo -e "\top-test lemon,orange operators/aqua/1.0.2 https://github.com/$OPP_THIS_REPO $OPP_THIS_BRANCH\n"
    exit 1
}

function checkExecutable() {
    local pm=""
    for p in $*;do
        ! command -v $p > /dev/null 2>&1 && pm="$p $pm"
    done
    if [[ "$pm" != "" ]]; then
        echo "Error: Following packages needs to be installed !!!"
        for p in $pm;do
            echo -e "\t$p\n"
        done
        echo ""
        exit 1
    fi
}

function clean() {
    echo "Removing testing container '$OPP_NAME' ..."
    $OPP_CONTAINER_TOOL rm -f $OPP_NAME > /dev/null 2>&1
    echo "Removing kind registry 'kind-registry' ..."
    $OPP_CONTAINER_TOOL rm -f kind-registry > /dev/null 2>&1
    command -v kind > /dev/null 2>&1 && kind delete cluster --name operator-test
    echo "Removing cert dir '$OPP_CERT_DIR' ..."
    rm -rf $OPP_CERT_DIR > /dev/null 2>&1
    echo "Done"
    exit 0
}

function iib_install() {
    echo "Installing iib ..."
    set -o pipefail
    $DRY_RUN_CMD ansible-pull -U $OPP_ANSIBLE_PULL_REPO -C $OPP_ANSIBLE_PULL_BRANCH $OPP_ANSIBLE_DEFAULT_ARGS -e run_prepare_catalog_repo_upstream=false --tags iib
    # -e iib_push_image="$IIB_PUSH_IMAGE" -e iib_push_registry="$(echo $IIB_PUSH_IMAGE | cut -d '/' -f 1)"
    if [[ $? -eq 0 ]];then
        echo "Loging to registry.redhat.io ..."
        if [ -n "$IIB_INPUT_REGISTRY_TOKEN" ];then
          echo "$IIB_INPUT_REGISTRY_TOKEN" | $OPP_CONTAINER_TOOL login registry.redhat.io -u $IIB_INPUT_REGISTRY_USER --password-stdin || { echo "Problem to login to 'registry.redhat.io' !!!"; exit 1; }
          if [ -n "$IIB_OUTPUT_REGISTRY_TOKEN" ];then
            echo "$IIB_OUTPUT_REGISTRY_TOKEN" | $OPP_CONTAINER_TOOL login quay.io -u $IIB_OUTPUT_REGISTRY_USER --password-stdin || { echo "Problem to login to 'quay.io' !!!"; exit 1; }
          fi
          $OPP_CONTAINER_TOOL cp $HOME/.docker/config.json iib_iib-worker_1:/root/.docker/config.json.template || exit 1
        else
            echo "Variable \$IIB_INPUT_REGISTRY_TOKEN is not set or is empty !!!"
            exit 1
        fi
        echo -e "\n=================================================================================="
        echo -e "IIB was installed successfully !!!"
        echo -e "==================================================================================\n"
    else
        echo "Problem installing iib !!!"
        exit 1
    fi
    set +o pipefail
}

function run() {
        if [[ $OPP_DEBUG -ge 4 ]] ; then
                v=$(exec 2>&1 && set -x && set -- "$@")
                echo "#${v#*--}"
                set -o pipefail
                "$@" | tee -a $OPP_LOG_DIR/log.out
                [[ $? -eq 0 ]] || { echo -e "\nFailed with rc=$? !!!\nLogs are in '$OPP_LOG_DIR/log.out'."; exit $?; }
                set +o pipefail
        elif [[ $OPP_DEBUG -ge 1 ]] ; then
                set -o pipefail
                "$@" | tee -a $OPP_LOG_DIR/log.out
                [[ $? -eq 0 ]] || { echo -e "\nFailed with rc=$? !!!\nLogs are in '$OPP_LOG_DIR/log.out'."; exit $?; }
                set +o pipefail
        else
                set -o pipefail
                "$@" | tee -a $OPP_LOG_DIR/log.out >/dev/null 2>&1
                [[ $? -eq 0 ]] || { echo -e "\nFailed with rc=$? !!!\nLogs are in '$OPP_LOG_DIR/log.out'."; exit $?; }
                set +o pipefail
        fi
}


[ "$OPP_RUN_MODE" = "privileged" ] && OPP_CONAINER_RUN_DEFAULT_ARGS="--privileged --net host -v $OPP_CERT_DIR:/usr/share/pki/ca-trust-source/anchors -e STORAGE_DRIVER=vfs -e BUILDAH_FORMAT=docker"
[ "$OPP_RUN_MODE" = "user" ] && OPP_CONAINER_RUN_DEFAULT_ARGS="--net host -v $OPP_CERT_DIR:/usr/share/pki/ca-trust-source/anchors -e STORAGE_DRIVER=vfs -e BUILDAH_FORMAT=docker"

checkExecutable $OPP_BASE_DEP

if ! command -v ansible > /dev/null 2>&1; then
    echo "Error: Ansible is not installed. Please install it first !!!"
    echo "    e.g.  : pip install ansible jmespath"
    echo "    or    : apt install ansible"
    echo "    or    : yum install ansible"
    echo -e "\nRun 'ansible --version' to make sure it is installed\n"

    exit 1
fi

if [ "$OPP_CONTAINER_TOOL" = "podman" ];then
    OPP_ANSIBLE_EXTRA_ARGS="$OPP_ANSIBLE_EXTRA_ARGS -e opm_container_tool=podman -e container_tool=podman -e opm_container_tool_index=none"
    # OPP_EXEC_EXTRA="$OPP_EXEC_EXTRA -e opm_container_tool=podman -e container_tool=podman -e opm_container_tool_index="
fi

[ -d $OPP_LOG_DIR ] || mkdir -p $OPP_LOG_DIR
[ -f $OPP_LOG_DIR/log.out ] && rm -f $OPP_LOG_DIR/log.out

# Handle labels
if [ -n "$OPP_LABELS" ];then
    for l in $(echo $OPP_LABELS);do
    echo "Handling label '$l' ..."
    [[ "$l" = "allow/operator-version-overwrite" ]] && export OPP_VER_OVERWRITE=1
    [[ "$l" = "allow/operator-recreate" ]] && export OPP_RECREATE=1
    [[ "$l" = "allow/serious-changes-to-existing" ]] && export OP_ALLOW_BIG_CHANGES_TO_EXISTING=1
    [[ "$l" = "test/force-deploy-on-kubernetes" ]] && export OPP_FORCE_DEPLOY_ON_K8S=1
    [[ "$l" = "verbosity/high" ]] && export OPP_DEBUG=2
    [[ "$l" = "verbosity/debug" ]] && export OPP_DEBUG=3
    [[ "$l" = "allow/longer-deployment" ]] && export OPP_DEPLOY_LONGER=1
    done
else
    echo "Info: No labels defined"
fi
[[ $OPP_DEBUG -eq 0 ]] && OPP_EXEC_EXTRA="-vv $OPP_EXEC_EXTRA"
# [[ $OPP_DEBUG -eq 1 ]] && OPP_EXEC_EXTRA="$OPP_EXEC_EXTRA"
[[ $OPP_DEBUG -eq 2 ]] && OPP_EXEC_EXTRA="-v $OPP_EXEC_EXTRA"
[[ $OPP_DEBUG -eq 3 ]] && OPP_EXEC_EXTRA="-vv $OPP_EXEC_EXTRA"
[[ $OPP_DRY_RUN -eq 1 ]] && DRY_RUN_CMD="echo"


# Hide secrets in dry run
if [[ $OPP_DRY_RUN -eq 1 ]];then
    QUAY_API_TOKEN_OPENSHIFT_COMMUNITY_OP=""
    QUAY_API_TOKEN_OPERATORHUBIO=""
    QUAY_API_TOKEN_OPERATOR_TESTING=""
    OHIO_REGISTRY_TOKEN=""
    QUAY_APPREG_TOKEN=""
    QUAY_COURIER_TOKEN=""
fi

echo "debug=$OPP_DEBUG"

# Handle test types
[ -z $1 ] && help

[ "$ACTION" = "clean" ] && clean
if [ "$ACTION" = "docker" ];then
    echo "Installing docker ..."
    $DRY_RUN_CMD ansible-pull -U $OPP_ANSIBLE_PULL_REPO -C $OPP_ANSIBLE_PULL_BRANCH $OPP_ANSIBLE_DEFAULT_ARGS -e run_prepare_catalog_repo_upstream=false --tags docker
    if [[ $? -eq 0 ]];then
        echo -e "\n=================================================================================="
        echo -e "Make sure that you logout and login after docker installation to apply changes !!!"
        echo -e "==================================================================================\n"
    else
        echo "Problem installing docker !!!"
        exit 1
    fi
    exit 0
fi

[ "$ACTION" = "iib" ] && { iib_install; exit 0; }

if ! command -v $OPP_CONTAINER_TOOL > /dev/null 2>&1; then
    echo -e "\nError: '$OPP_CONTAINER_TOOL' is missing !!! Install it via:"
    [ "$OPP_CONTAINER_TOOL" = "docker" ] && echo -e "\n\tbash <(curl -sL $OPP_THIS_SCRIPT_URL) $OPP_CONTAINER_TOOL"
    [ "$OPP_CONTAINER_TOOL" = "podman" ] && echo -e "\n\tContainer tool '$OPP_CONTAINER_TOOL' is not supported yet"
    echo
    exit 1
fi


# Handle operator info
OPP_BASE_DIR=${OPP_BASE_DIR-"/tmp/community-operators-for-catalog"}
OPP_STREAM=${OPP_STREAM-"operators"}
OPP_OPERATOR=${OPP_OPERATOR-"aqua"}
OPP_VERSION=${OPP_VERSION-"1.0.2"}

if [ -n "$2" ];then
    if [ -n "$3" ];then
        p=$2
        OPP_VERSION=$(echo $p | rev | cut -d'/' -f 1 | rev);p=$(dirname $p)
        OPP_OPERATOR=$(echo $p | rev | cut -d'/' -f 1 | rev);p=$(dirname $p)
        OPP_STREAM=$(echo $p | rev | cut -d'/' -f 1 | rev);p=$(dirname $p)
        OPP_REPO="$3"
        OPP_BRANCH="master"
        [ -n "$4" ] && OPP_BRANCH=$4
    elif [ -d $2 ];then
        p=$(readlink -f $2)
        OPP_VERSION=$(echo $p | rev | cut -d'/' -f 1 | rev);p=$(dirname $p)
        OPP_OPERATOR=$(echo $p | rev | cut -d'/' -f 1 | rev);p=$(dirname $p)
        OPP_STREAM=$(echo $p | rev | cut -d'/' -f 1 | rev);p=$(dirname $p)
        OPP_CONTAINER_RUN_EXTRA_ARGS="$OPP_CONTAINER_RUN_EXTRA_ARGS -v $p:$OPP_BASE_DIR"
    else
        echo -e "\nError: Full path to operator/version '$PWD/$2' was not found !!!\n"
        exit 1
    fi

else
    p=${PWD}
    echo "Running locally from '$p' ..."
    OPP_VERSION=$(echo $p | rev | cut -d'/' -f 1 | rev);p=$(dirname $p)
    OPP_OPERATOR=$(echo $p | rev | cut -d'/' -f 1 | rev);p=$(dirname $p)
    OPP_STREAM=$(echo $p | rev | cut -d'/' -f 1 | rev);p=$(dirname $p)
    OPP_CONTAINER_RUN_EXTRA_ARGS="$OPP_CONTAINER_RUN_EXTRA_ARGS -v $p:$OPP_BASE_DIR"
fi

OPP_CHECK_STEAM_OK=0
[ "$OPP_STREAM" = "." ] && [ "$OPP_VERSION" = "sync" ] && OPP_STREAM=$OPP_OPERATOR && OPP_OPERATOR=$OPP_VERSION
[ "$OPP_STREAM" = "." ] && [ "$OPP_VERSION" = "update" ] && OPP_STREAM=$OPP_OPERATOR && OPP_OPERATOR=$OPP_VERSION
[ "$OPP_STREAM" = "operators" ] && OPP_CHECK_STEAM_OK=1
# [ "$OPP_STREAM" = "community-operators" ] && OPP_CHECK_STEAM_OK=1
# [ "$OPP_STREAM" = "upstream-community-operators" ] && OPP_CHECK_STEAM_OK=1

[[ $OPP_CHECK_STEAM_OK -eq 0 ]] && { echo "Error : Unknwn value for 'OPP_STREAM=$OPP_STREAM' !!!"; exit 1; }

function ExecParameters() {
    OPP_EXEC_USER=
    OPP_EXEC_USER_SECRETS=
    OPP_EXEC_USER_INDEX_CHECK=
    OPP_SKIP=0
    [[ $1 == kiwi* ]] && OPP_EXEC_USER="-e operator_dir=$OPP_BASE_DIR/$OPP_OPERATORS_DIR/$OPP_OPERATOR -e operator_version=$OPP_VERSION --tags pure_test -e operator_channel_force=optest"
    [[ $1 == kiwi* ]] && [ "$OPP_CLUSTER_TYPE" = "openshift" ] && [[ $OPP_FORCE_DEPLOY_ON_K8S -eq 0 ]] && OPP_EXEC_USER="$OPP_EXEC_USER -e test_skip_deploy=true"
    [[ $1 == kiwi* ]] && [[ $OPP_DEPLOY_LONGER -eq 1 ]] && OPP_EXEC_USER="$OPP_EXEC_USER -e pod_start_retries=$OPP_POD_START_RETRIES_LONG_DEPLOYMENT_WAIT_RETRIES"
    [[ $1 == lemon* ]] && OPP_EXEC_USER="-e operator_dir=$OPP_BASE_DIR/$OPP_OPERATORS_DIR/$OPP_OPERATOR --tags deploy_bundles"
    [[ $1 == orange* ]] && [ "$OPP_VERSION" != "sync" ] && OPP_EXEC_USER="-e operator_dir=$OPP_BASE_DIR/$OPP_OPERATORS_DIR/$OPP_OPERATOR --tags deploy_bundles"
    [[ $1 == orange* ]] &&  [ "$OPP_VERSION" = "sync" ] && OPP_EXEC_USER="--tags deploy_bundles"




    # [[ $1 == orange* ]] && [ "$OPP_STREAM" = "community-operators" ] && [ "$OPP_VERSION" != "sync" ] && [[ $OPP_PROD -lt 2 ]] && OPP_EXEC_USER="$OPP_EXEC_USER -e production_registry_namespace=quay.io/openshift-community-operators"
    # [[ $1 == orange* ]] && [ "$OPP_STREAM" = "upstream-community-operators" ] && [ "$OPP_VERSION" != "sync" ] && [[ $OPP_PROD -lt 2 ]] && OPP_EXEC_USER="$OPP_EXEC_USER -e production_registry_namespace=quay.io/operatorhubio"
    [[ $1 == orange* ]] && [ "$OPP_VERSION" != "sync" ] && [[ $OPP_PROD -lt 2 ]] && OPP_EXEC_USER="$OPP_EXEC_USER -e production_registry_namespace=$OPP_PRODUCTION_REGISTRY_NAMESPACE"

    # Handle index_check
    # [[ $1 == orange* ]] &&[ "$OPP_STREAM" = "community-operators" ] && OPP_EXEC_USER_INDEX_CHECK="-e run_prepare_catalog_repo_upstream=true -e bundle_index_image=quay.io/openshift-community-operators/catalog:latest -e operator_base_dir=$OPP_BASE_DIR/$OPP_OPERATORS_DIR"
    # [[ $1 == orange* ]] &&[ "$OPP_STREAM" = "community-operators" ] && [[ $OPP_PROD -ge 2 ]] && OPP_EXEC_USER_INDEX_CHECK="-e run_prepare_catalog_repo_upstream=true -e bundle_index_image=quay.io/operator_testing/catalog:latest -e operator_base_dir=$OPP_BASE_DIR/$OPP_OPERATORS_DIR"
    
    # [[ $1 == orange_* ]] && [ "$OPP_STREAM" = "community-operators" ] && OPP_EXEC_USER_INDEX_CHECK="-e run_prepare_catalog_repo_upstream=true -e bundle_index_image=quay.io/openshift-community-operators/catalog:${1/orange_/} -e operator_base_dir=$OPP_BASE_DIR/$OPP_OPERATORS_DIR"
    # [[ $1 == orange_* ]] && [ "$OPP_STREAM" = "community-operators" ] && [[ $OPP_PROD -ge 2 ]] && OPP_EXEC_USER_INDEX_CHECK="-e run_prepare_catalog_repo_upstream=true -e bundle_index_image=quay.io/operator_testing/catalog:${1/orange_/} -e operator_base_dir=$OPP_BASE_DIR/$OPP_OPERATORS_DIR"
    # [[ $1 == orange* ]] && [ "$OPP_STREAM" = "upstream-community-operators" ] && OPP_EXEC_USER_INDEX_CHECK="-e run_prepare_catalog_repo_upstream=true -e bundle_index_image=quay.io/operatorhubio/catalog:latest -e operator_base_dir=$OPP_BASE_DIR/$OPP_OPERATORS_DIR"
    # [[ $1 == orange* ]] && [ "$OPP_STREAM" = "upstream-community-operators" ] && [[ $OPP_PROD -ge 2 ]] && OPP_EXEC_USER_INDEX_CHECK="-e run_prepare_catalog_repo_upstream=true -e bundle_index_image=quay.io/operator_testing/catalog:latest -e operator_base_dir=$OPP_BASE_DIR/$OPP_OPERATORS_DIR"
    # [[ $1 == orange_* ]] && [ "$OPP_STREAM" = "upstream-community-operators" ] && { echo "Error: orange_xxx is not supported for 'upstream-community-operators' !!! Exiting ..."; exit 1; }

    # Handle index_check
    OPP_PRODUCTION_INDEX_IMAGE_TAG="latest"
    [[ $1 == orange_* ]] && OPP_PRODUCTION_INDEX_IMAGE_TAG="${1/orange_/}"
    [[ $1 == orange* ]] && OPP_EXEC_USER_INDEX_CHECK="-e run_prepare_catalog_repo_upstream=true -e bundle_index_image=$OPP_PRODUCTION_INDEX_IMAGE:$OPP_PRODUCTION_INDEX_IMAGE_TAG -e operator_base_dir=$OPP_BASE_DIR/$OPP_OPERATORS_DIR"
    [[ $1 == orange_* ]] && [ "$OPP_CLUSTER_TYPE" = "k8s" ] && { echo "Error: orange_xxx is not supported for 'kubernetes' cluster !!! Exiting ..."; exit 1; }
    
    
    
    


















    
    [[ $1 == orange* ]] && [[ $OPP_PROD -eq 1 ]] && [ "$OPP_STREAM" = "community-operators" ] && OPP_EXEC_USER="$OPP_EXEC_USER -e bundle_registry=quay.io -e bundle_image_namespace=openshift-community-operators -e bundle_index_image_namespace=openshift-community-operators -e bundle_index_image_name=catalog"
    
    # Using default "-e use_cluster_filter=false -e supported_cluster_versions=latest" for k8s
    [[ $1 == orange* ]] && [[ $OPP_PROD -eq 1 ]] && [ "$OPP_STREAM" = "upstream-community-operators" ] && OPP_EXEC_USER="$OPP_EXEC_USER -e bundle_registry=quay.io -e bundle_image_namespace=operatorhubio -e bundle_index_image_namespace=operatorhubio -e bundle_index_image_name=catalog"
    
    [[ $1 == orange* ]] && [[ $OPP_PROD -ge 2 ]] && OPP_EXEC_USER="$OPP_EXEC_USER -e bundle_registry=quay.io -e bundle_image_namespace=operator_testing -e bundle_index_image_namespace=operator_testing -e bundle_index_image_name=catalog"

    [[ $1 == orange* ]] && [[ $OPP_PROD -eq 1 ]] && [ "$OPP_STREAM" = "community-operators" ] && OPP_EXEC_USER_SECRETS="$OPP_EXEC_USER_SECRETS -e quay_api_token=$QUAY_API_TOKEN_OPENSHIFT_COMMUNITY_OP"
    [[ $1 == orange* ]] && [[ $OPP_PROD -eq 1 ]] && [ "$OPP_STREAM" = "upstream-community-operators" ] && OPP_EXEC_USER_SECRETS="$OPP_EXEC_USER_SECRETS -e quay_api_token=$QUAY_API_TOKEN_OPERATORHUBIO"
    [[ $1 == orange* ]] && [[ $OPP_PROD -ge 2 ]] && OPP_EXEC_USER_SECRETS="$OPP_EXEC_USER_SECRETS -e quay_api_token=$QUAY_API_TOKEN_OPERATOR_TESTING"

    [[ $1 == orange* ]] && [[ $OPP_PROD -eq 1 ]] && [ "$OPP_STREAM" = "community-operators" ] && OPP_MIRROR_IMAGE_POSTFIX="s" 
    # If community and doing orange_<version>
    [[ $1 == orange* ]] && [[ $1 != orange_* ]] && [ "$OPP_STREAM" = "community-operators" ] && OPP_EXEC_USER="$OPP_EXEC_USER -e stream_kind=openshift_upstream"
    [[ $1 == orange_* ]] && [ "$OPP_STREAM" = "community-operators" ] && OPP_EXEC_USER="$OPP_EXEC_USER -e stream_kind=openshift_upstream -e supported_cluster_versions=${1/orange_/} -e bundle_index_image_version=${1/orange_/}"
    [[ $1 == lemon_* ]] && [ "$OPP_STREAM" = "community-operators" ] && OPP_EXEC_USER="$OPP_EXEC_USER -e stream_kind=openshift_upstream -e supported_cluster_versions=${1/lemon_/} -e bundle_index_image_version=${1/lemon_/}"

    if [[ $OPP_INDEX_MIRROR -eq 1 ]];then
        [[ $1 == orange_* ]] && [ "$OPP_STREAM" = "community-operators" ] && [[ $OPP_PROD -eq 1 ]] && OPP_EXEC_USER="$OPP_EXEC_USER -e mirror_multiarch_image=registry.redhat.io/openshift4/ose-operator-registry:v4.5 -e mirror_apply=true"
        [[ $1 == orange_* ]] && [ "$OPP_STREAM" = "community-operators" ] && [[ $OPP_PROD -eq 1 ]] && [ "$OPP_MIRROR_LATEST_TAG" != "${1/orange_/}" ]&& OPP_EXEC_USER_SECRETS="$OPP_EXEC_USER_SECRETS -e mirror_index_images=\"quay.io/redhat/redhat----community-operator-index:${1/orange_/}|redhat+iib_community|$QUAY_RH_INDEX_PW|$OPP_MIRROR_IMAGE_POSTFIX\""
        [[ $1 == orange_* ]] && [ "$OPP_STREAM" = "community-operators" ] && [[ $OPP_PROD -eq 1 ]] && [ "$OPP_MIRROR_LATEST_TAG" = "${1/orange_/}" ] && OPP_EXEC_USER_SECRETS="$OPP_EXEC_USER_SECRETS -e mirror_index_images=\"quay.io/redhat/redhat----community-operator-index:${1/orange_/}|redhat+iib_community|$QUAY_RH_INDEX_PW|$OPP_MIRROR_IMAGE_POSTFIX|quay.io/redhat/redhat----community-operator-index:latest\""
    else
        [[ $1 == orange_* ]] && [ "$OPP_STREAM" = "community-operators" ] && [[ $OPP_PROD -eq 1 ]] && OPP_EXEC_USER="$OPP_EXEC_USER -e sis_index_add_skip=true"    
    fi

    [[ OP_ALLOW_BIG_CHANGES_TO_EXISTING -eq 1 ]] && OPP_EXEC_USER="$OPP_EXEC_USER -e allow_big_changes_to_existing=true"

    # Failing test when upstream and orgage_<version> (not supported yet)
    [[ $1 == orange_* ]] && [ "$OPP_STREAM" = "upstream-community-operators" ] && OPP_EXEC_USER="" && { echo "Warning: Index versions are not supported for 'upstream-community-operators' !!! Skipping ..."; OPP_SKIP=1; }

    # Building index from bundle shas in production
    [[ $1 == orange* ]] && [[ $OPP_PROD -eq 1 ]] && OPP_EXEC_USER="$OPP_EXEC_USER -e bundle_index_sha_posfix=s"

    # Don't reset kind when production (It should speedup deploy when kind and registry is not needed)
    [[ $1 == orange* ]] && [[ $OPP_PROD -ge 1 ]] && OPP_RESET=0

    [[ $1 == orange* ]] && [[ $OPP_VER_OVERWRITE -eq 0 ]] && [ "$OPP_VERSION" != "update" ] && OPP_EXEC_USER="$OPP_EXEC_USER -e fail_on_no_index_change=false"
    
    [[ $1 == orange* ]] && [[ $OPP_PROD -ge 1 ]] && [[ $OPP_VER_OVERWRITE -eq 0 ]] && [ "$OPP_VERSION" == "sync" ] && OPP_EXEC_USER="$OPP_EXEC_USER -e index_force_update=true"
    [[ $1 == orange* ]] && [[ $OPP_PROD -ge 1 ]] && [[ $OPP_CI_YAML_ONLY -eq 1 ]] && [ "$OPP_VERSION" == "sync" ] && OPP_EXEC_USER="$OPP_EXEC_USER -e operator_dir=$OPP_BASE_DIR/$OPP_OPERATORS_DIR/$OPP_OPERATOR"
    [[ $1 == orange* ]] && [[ $OPP_VER_OVERWRITE -eq 0 ]] && [ "$OPP_VERSION" = "update" ] && OPP_EXEC_USER="$OPP_EXEC_USER -e fail_on_no_index_change=false -e strict_mode=true -e index_force_update=true"

    # Handle OPP_VER_OVERWRITE
    [[ $1 == orange* ]] && [[ $OPP_VER_OVERWRITE -eq 1 ]] && [ "$OPP_VERSION" != "sync" ] && [ "$OPP_VERSION" != "update" ] && OPP_EXEC_USER="$OPP_EXEC_USER -e operator_version=$OPP_VERSION -e bundle_force_rebuild=true -e fail_on_no_index_change=false"
    # Handle OPP_RECREATE
    [[ $1 == orange* ]] && [[ $OPP_RECREATE -eq 1 ]] && [[ $OPP_PROD -eq 0 ]] && OPP_SKIP=1

    # Skipping when version is not defined in case OPP_VER_OVERWRITE=1
    [[ $OPP_VER_OVERWRITE -eq 1 ]] && [ -z $OPP_VERSION ] && { echo "Warning: OPP_VER_OVERWRITE=1 and no version specified 'OPP_VERSION=$OPP_VERSION' !!! Skipping ..."; OPP_SKIP=1; }

    # Skipping case when sync in non prod mode
    [[ $OPP_PROD -eq 0 ]] && [ "$OPP_VERSION" = "sync" ] && { echo "Warning: No support for 'sync' (try 'update') when 'OPP_PROD=$OPP_PROD' !!! Skipping ..."; OPP_SKIP=1; }

    [[ $OPP_PROD -eq 0 ]] && [ "$OPP_OPERATOR" = "update" ] && { echo "Warning: No support for 'update' when 'OPP_PROD=$OPP_PROD' when operator name is not defined !!! Skipping ..."; OPP_SKIP=1; }

    # Handling when kiwi and lemon case for production mode
    [[ $OPP_PROD -ge 1 ]] && [[ $1 == kiwi* ]] && { echo "Warning: No support for 'kiwi' test when 'OPP_PROD=$OPP_PROD' !!! Skipping ..."; OPP_SKIP=1; }
    [[ $OPP_PROD -ge 1 ]] && [[ $1 == lemon* ]] && { echo "Warning: No support for 'lemon' test when 'OPP_PROD=$OPP_PROD' !!! Skipping ..."; OPP_SKIP=1; }
    [[ $OPP_PROD -eq 1 ]] && OPP_EXEC_USER="$OPP_EXEC_USER -e enable_bundle_validate_community=false"

    [[ $1 == push_to_quay* ]] && [ "$OPP_STREAM" = "community-operators" ] && OPP_RESET=1 && OPP_EXEC_USER="$OPP_EXEC_USER --tags deploy_bundles -e operator_dir=$OPP_BASE_DIR/$OPP_OPERATORS_DIR/$OPP_OPERATOR -e quay_appregistry_api_token=$QUAY_APPREG_TOKEN -e quay_appregistry_courier_token=$QUAY_COURIER_TOKEN -e production_registry_namespace=quay.io/openshift-community-operators -e index_force_update=true -e bundle_index_image_name=catalog -e op_test_operator_version=$OPP_VERSION"
    [[ $1 == push_to_quay* ]] && [ "$OPP_STREAM" = "community-operators" ] && OPP_RESET=1 && [[ DELETE_APPREG -eq 1 ]] && OPP_EXEC_USER="$OPP_EXEC_USER -e delete_appreg='true'"
    [[ $1 == push_to_quay* ]] && [ "$OPP_STREAM" = "upstream-community-operators" ] && OPP_RESET=0 && OPP_EXEC_USER="" && { echo "Warning: Push to quay is not supported for 'upstream-community-operators' !!! Skipping ..."; OPP_SKIP=1; }

    [[ $1 == ohio_image* ]] && OPP_RESET=0 && OPP_EXEC_USER="$OPP_EXEC_USER --tags app_registry -e bundle_index_image=$OHIO_INPUT_CATALOG_IMAGE -e index_export_parallel=true -e app_registry_image=$OHIO_REGISTRY_IMAGE -e quay_api_token=$OHIO_REGISTRY_TOKEN"

    [[ $1 == op_delete* ]] && OPP_RESET=0 && OPP_EXEC_USER="$OPP_EXEC_USER --tags remove_operator -e operator_dir=$OPP_BASE_DIR/$OPP_OPERATORS_DIR/$OPP_OPERATOR"
    [[ $1 == op_delete* ]] && [[ $OPP_PROD -eq 1 ]] && [ "$OPP_STREAM" = "community-operators" ] && OPP_EXEC_USER="$OPP_EXEC_USER -e bundle_registry=quay.io -e bundle_image_namespace=openshift-community-operators -e bundle_index_image_namespace=openshift-community-operators -e bundle_index_image_name=catalog"
    [[ $1 == op_delete* ]] && [[ $OPP_PROD -eq 1 ]] && [ "$OPP_STREAM" = "upstream-community-operators" ] && OPP_EXEC_USER="$OPP_EXEC_USER -e bundle_registry=quay.io -e bundle_image_namespace=operatorhubio -e bundle_index_image_namespace=operatorhubio -e bundle_index_image_name=catalog"
    [[ $1 == op_delete* ]] && [[ $OPP_PROD -eq 1 ]] && [ "$OPP_STREAM" = "community-operators" ] && OPP_EXEC_USER_SECRETS="$OPP_EXEC_USER_SECRETS -e quay_api_token=$QUAY_API_TOKEN_OPENSHIFT_COMMUNITY_OP"
    [[ $1 == op_delete* ]] && [[ $OPP_PROD -eq 1 ]] && [ "$OPP_STREAM" = "upstream-community-operators" ] && OPP_EXEC_USER_SECRETS="$OPP_EXEC_USER_SECRETS -e quay_api_token=$QUAY_API_TOKEN_OPERATORHUBIO"
    [[ $1 == op_delete* ]] && [[ $OPP_PROD -ge 2 ]] && OPP_EXEC_USER_SECRETS="$OPP_EXEC_USER_SECRETS -e quay_api_token=$QUAY_API_TOKEN_OPERATOR_TESTING"
    [[ $1 == op_delete_* ]] && [ "$OPP_STREAM" = "community-operators" ] && OPP_EXEC_USER="$OPP_EXEC_USER -e bundle_index_image_version=${1/op_delete_/}"

    # index safety - avoid accidental index destroy
    [[ $1 == orange* ]] && [[ $OPP_PROD -eq 1 ]] && OPP_EXEC_USER="$OPP_EXEC_USER $OPP_INDEX_SAFETY" && OPP_EXEC_USER_INDEX_CHECK="$OPP_EXEC_USER_INDEX_CHECK $OPP_INDEX_SAFETY"

    # Force strict mode (force to fail on 'bundle add' and 'index add')
    [[ $OPP_PROD -eq 0 ]] && OPP_EXEC_USER="$OPP_EXEC_USER -e strict_mode=true"

}

echo "Using $(ansible --version | head -n 1) on host ..."
if [[ $OPP_DEBUG -ge 2 ]];then
    run echo "OPP_DEBUG='$OPP_DEBUG'"
    run echo "OPP_DRY_RUN='$OPP_DRY_RUN'"
    run echo "OPP_EXEC_USER='$OPP_EXEC_USER'"
    run echo "OPP_IMAGE='$OPP_IMAGE'"
    run echo "OPP_CONTAINER_EXEC_EXTRA_ARGS='$OPP_CONTAINER_EXEC_EXTRA_ARGS'"
    run echo "OPP_CERT_DIR='$OPP_CERT_DIR'"
    run echo "OPP_CONTAINER_TOOL='$OPP_CONTAINER_TOOL'"
    run echo "OPP_NAME='$OPP_NAME'"
    run echo "OPP_ANSIBLE_PULL_REPO='$OPP_ANSIBLE_PULL_REPO'"
    run echo "OPP_ANSIBLE_PULL_BRANCH='$OPP_ANSIBLE_PULL_BRANCH'"
    run echo "OPP_ANSIBLE_DEFAULT_ARGS='$OPP_ANSIBLE_DEFAULT_ARGS'"
    run echo "OPP_ANSIBLE_EXTRA_ARGS='$OPP_ANSIBLE_EXTRA_ARGS'"
    run echo "OPP_CONAINER_RUN_DEFAULT_ARGS='$OPP_CONAINER_RUN_DEFAULT_ARGS'"
    run echo "OPP_CONTAINER_RUN_EXTRA_ARGS='$OPP_CONTAINER_RUN_EXTRA_ARGS'"
    run echo "OPP_CONTAINER_EXEC_DEFAULT_ARGS='$OPP_CONTAINER_EXEC_EXTRA_ARGS'"
    run echo "OPP_CONTAINER_EXEC_EXTRA_ARGS='$OPP_CONTAINER_EXEC_EXTRA_ARGS'"
    run echo "OPP_RUN_MODE='$OPP_RUN_MODE'"
    run echo "OPP_FORCE_INSTALL='$OPP_FORCE_INSTALL'"
    run echo "OPP_LOG_DIR='$OPP_LOG_DIR'"
fi

echo -e "\nOne can do 'tail -f $OPP_LOG_DIR/log.out' from second console to see full logs\n"


# Check if kind is installed
echo -e "Checking for kind binary ..."
if ! $DRY_RUN_CMD command -v kind > /dev/null 2>&1; then
    OPP_FORCE_INSTALL=1
fi

# Install prerequisites (kind cluster)
[[ $OPP_FORCE_INSTALL -eq 1 ]] && run echo -e " [ Installing prerequisites ] "
[[ $OPP_FORCE_INSTALL -eq 1 ]] && run $DRY_RUN_CMD ansible-pull -U $OPP_ANSIBLE_PULL_REPO -C $OPP_ANSIBLE_PULL_BRANCH $OPP_ANSIBLE_DEFAULT_ARGS $OPP_ANSIBLE_EXTRA_ARGS -e run_prepare_catalog_repo_upstream=false

# [[ $OPP_IIB_INSTALL -eq 1 ]] && iib_install 

if [ -n "$OPP_REPO" ];then
    OPP_EXEC_EXTRA="$OPP_EXEC_EXTRA -e catalog_repo=$OPP_REPO -e catalog_repo_branch=$OPP_BRANCH"
else
    OPP_EXEC_EXTRA="$OPP_EXEC_EXTRA -e run_prepare_catalog_repo_upstream=false"
fi
# Start container
echo -e " [ Preparing testing container '$OPP_NAME' from '$OPP_IMAGE' ] "
$DRY_RUN_CMD $OPP_CONTAINER_TOOL pull $OPP_IMAGE > /dev/null 2>&1 || { echo "Error: Problem pulling image '$OPP_IMAGE' !!!"; exit 1; }

OPP_CONTAINER_OPT="$OPP_CONTAINER_OPT -e ANSIBLE_CONFIG=/playbooks/upstream/ansible.cfg"
OPP_CONTAINER_OPT="$OPP_CONTAINER_OPT -e GODEBUG=$GODEBUG"

OPP_SKIP=0
IIB_INSTALLED=0
for t in $TESTS;do

    ExecParameters $t
    [[ $OPP_SKIP -eq 1 ]] && echo "Skipping test '$t' for '$OPP_OPERATORS_DIR $OPP_OPERATOR $OPP_VERSION' ..." && continue

    [ -z "$OPP_EXEC_USER" ] && { echo "Error: Unknown test '$t' for '$OPP_OPERATORS_DIR $OPP_OPERATOR $OPP_VERSION' !!! Exiting ..."; help; }
    echo -e "Test '$t' for '$OPP_OPERATORS_DIR $OPP_OPERATOR $OPP_VERSION' ..."
    if [[ $OPP_RESET -eq 1 ]];then
        echo -e "[$t] Reseting kind cluster ..."
        run $DRY_RUN_CMD ansible-pull -U $OPP_ANSIBLE_PULL_REPO -C $OPP_ANSIBLE_PULL_BRANCH $OPP_ANSIBLE_DEFAULT_ARGS -e run_prepare_catalog_repo_upstream=false -e kind_kube_version=$KIND_KUBE_VERSION --tags reset
    fi
    if [ -n "$OPP_PRETEST_CUSTOM_SCRIPT" ];then
        echo "Running custom script '$OPP_PRETEST_CUSTOM_SCRIPT' ..."
        [ -f $OPP_PRETEST_CUSTOM_SCRIPT ] || { echo "Custom script '$OPP_PRETEST_CUSTOM_SCRIPT' was not found. Exiting ..."; exit 1; }
        [[ -x "$OPP_PRETEST_CUSTOM_SCRIPT" ]] || { echo "Custom script '$OPP_PRETEST_CUSTOM_SCRIPT' is not executable. Do 'chmod +x $OPP_PRETEST_CUSTOM_SCRIPT' first !!! Exiting ..."; exit 1; }
        run $OPP_PRETEST_CUSTOM_SCRIPT
        echo "Custom script '$OPP_PRETEST_CUSTOM_SCRIPT' done ..."
    fi
    echo -e "[$t] Running test ..."
    [[ $OPP_DEBUG -ge 3 ]] && echo "OPP_EXEC_EXTRA=$OPP_EXEC_EXTRA"
    $DRY_RUN_CMD $OPP_CONTAINER_TOOL rm -f $OPP_NAME > /dev/null 2>&1
    run $DRY_RUN_CMD $OPP_CONTAINER_TOOL run -d --rm $OPP_CONTAINER_OPT --name $OPP_NAME $OPP_CONAINER_RUN_DEFAULT_ARGS $OPP_CONTAINER_RUN_EXTRA_ARGS $OPP_IMAGE
    [[ $OPP_RESET -eq 1 ]] && run $DRY_RUN_CMD $OPP_CONTAINER_TOOL cp $HOME/.kube $OPP_NAME:/root/
    set -e
    if [[ $1 == orange* ]] && [[ $OPP_PROD -ge 1 ]] && [[ $OPP_CI_YAML_ONLY -eq 0 ]] && [ "$OPP_VERSION" = "sync" ];then
        echo "$OPP_EXEC_BASE $OPP_EXEC_EXTRA --tags index_check $OPP_EXEC_USER_INDEX_CHECK"
        run $DRY_RUN_CMD $OPP_CONTAINER_TOOL exec $OPP_CONTAINER_OPT $OPP_NAME /bin/bash -c "update-ca-trust && $OPP_EXEC_BASE $OPP_EXEC_EXTRA --tags index_check $OPP_EXEC_USER_INDEX_CHECK"
        $DRY_RUN_CMD $OPP_CONTAINER_TOOL exec $OPP_CONTAINER_OPT $OPP_NAME /bin/bash -c "ls $OPP_UNCOMPLETE" > /dev/null 2>&1 || continue
        OPP_EXEC_USER="$OPP_EXEC_USER -e operators_config=$OPP_UNCOMPLETE" 
    fi
    
    [[ $OPP_IIB_INSTALL -eq 1 ]] && [[ $IIB_INSTALLED -eq 0 ]] && iib_install && IIB_INSTALLED=1
 
    echo "$OPP_EXEC_BASE $OPP_EXEC_EXTRA $OPP_EXEC_USER"
    run $DRY_RUN_CMD $OPP_CONTAINER_TOOL exec $OPP_CONTAINER_OPT $OPP_NAME /bin/bash -c "update-ca-trust && $OPP_EXEC_BASE $OPP_EXEC_EXTRA $OPP_EXEC_USER $OPP_EXEC_USER_SECRETS"
    set +e
    echo -e "Test '$t' : [ OK ]\n"
done

echo "Done"

# For playbook developers
# OPP_DEBUG=2 bash <(curl -sL https://raw.githubusercontent.com/operator-framework/operator-test-playbooks/master/upstream/test/test.sh) orange community-operators/aqua/5.3.0 https://github.com/operator-framework/community-operators master
# export CURLOPT_FRESH_CONNECT=true
