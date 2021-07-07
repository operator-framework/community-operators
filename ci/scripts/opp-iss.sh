#!/bin/bash
set +o pipefail

# iss.sh  (Index Sync Sha)

OP_TEST_INDEX_IMAGE_TAG=${2-"latest"}

OP_TEST_IMAGE=${OP_TEST_IMAGE-"quay.io/operator_testing/operator-test-playbooks:latest"}
OP_TEST_CONTAINER_TOOL=${OP_TEST_CONTAINER_TOOL-"docker"}
OP_TEST_CONTAINER_OPT=${OP_TEST_CONTAINER_OPT-"-it"}
OP_TEST_NAME=${OPT_TEST_NAME-"op-sync-sha"}
OP_TEST_CONAINER_RUN_DEFAULT_ARGS=${OP_TEST_CONAINER_RUN_DEFAULT_ARGS-"--privileged --net host -e STORAGE_DRIVER=vfs -e BUILDAH_FORMAT=docker -e GODEBUG=x509ignoreCN=0"}
OP_TEST_CONTAINER_RUN_EXTRA_ARGS=${OP_TEST_CONTAINER_RUN_EXTRA_ARGS-""}
OP_TEST_EXEC_USER=${OP_TEST_EXEC_USER-""}
OP_TEST_EXEC_USER_SECRETS=${OP_TEST_EXEC_USER_SECRETS-""}
OP_TEST_EXEC_BASE=${OP_TEST_EXEC_BASE-"ansible-playbook -i localhost, -e ansible_connection=local upstream/local.yml -e run_upstream=true -e image_protocol='docker://'"}
OP_TEST_EXEC_EXTRA=${OP_TEST_EXEC_EXTRA-"-e container_tool=podman --tags sync_index_sha"}
OP_TEST_INDEX_POSTFIX=${OP_TEST_INDEX_POSTFIX-"s"}
OP_TEST_ANSIBLE_PULL_REPO=${OP_TEST_ANSIBLE_PULL_REPO-"https://github.com/operator-framework/operator-test-playbooks"}
OP_TEST_ANSIBLE_PULL_BRANCH=${OP_TEST_ANSIBLE_PULL_BRANCH-"master"}
OP_TEST_ANSIBLE_DEFAULT_ARGS=${OP_TEST_ANSIBLE_DEFAULT_ARGS-"-i localhost, -e ansible_connection=local -e run_upstream=true -e run_remove_catalog_repo=false upstream/local.yml"}
IIB_INPUT_REGISTRY_USER=${IIB_INPUT_REGISTRY_USER-"mavala"}
IIB_OUTPUT_REGISTRY_USER=${IIB_OUTPUT_REGISTRY_USER-"redhat+iib_community"}
#$OP_TEST_CONTAINER_TOOL rm -f $OP_TEST_NAME > /dev/null 2>&1
OP_TEST_MIRROR_LATEST_TAG=${OP_TEST_MIRROR_LATEST_TAG-"v4.6"}

function iib_install() {
    echo "Installing iib ..."
    set -o pipefail
    ansible-pull -U $OP_TEST_ANSIBLE_PULL_REPO -C $OP_TEST_ANSIBLE_PULL_BRANCH $OP_TEST_ANSIBLE_DEFAULT_ARGS -e run_prepare_catalog_repo_upstream=false --tags iib
    # -e iib_push_image="$IIB_PUSH_IMAGE" -e iib_push_registry="$(echo $IIB_PUSH_IMAGE | cut -d '/' -f 1)"
    if [[ $? -eq 0 ]];then
        echo "Loging to registry.redhat.io ..."
        if [ -n "$IIB_INPUT_REGISTRY_TOKEN" ];then
          echo "$IIB_INPUT_REGISTRY_TOKEN" | $OP_TEST_CONTAINER_TOOL login registry.redhat.io -u $IIB_INPUT_REGISTRY_USER --password-stdin || { echo "Problem to login to 'registry.redhat.io' !!!"; exit 1; }
          if [ -n "$IIB_OUTPUT_REGISTRY_TOKEN" ];then
            echo "$IIB_OUTPUT_REGISTRY_TOKEN" | $OP_TEST_CONTAINER_TOOL login quay.io -u $IIB_OUTPUT_REGISTRY_USER --password-stdin || { echo "Problem to login to 'quay.io' !!!"; exit 1; }
          fi
          $OP_TEST_CONTAINER_TOOL cp $HOME/.docker/config.json iib_iib-worker_1:/root/.docker/config.json.template || exit 1
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



if [ "$1" == "kubernetes" ];then
  OP_TEST_EXEC_USER="-e sis_index_image_input=quay.io/operatorhubio/catalog:$OP_TEST_INDEX_IMAGE_TAG -e sis_index_image_output=quay.io/operatorhubio/catalog:${OP_TEST_INDEX_IMAGE_TAG}${OP_TEST_INDEX_POSTFIX} -e op_base_name=upstream-community-operators"
  OP_TEST_EXEC_USER_SECRETS="-e quay_api_token=$QUAY_API_TOKEN_OPERATORHUBIO"
elif [ "$1" == "openshift" ];then
  OP_TEST_EXEC_USER="-e sis_index_image_input=quay.io/openshift-community-operators/catalog:$OP_TEST_INDEX_IMAGE_TAG -e sis_index_image_output=quay.io/openshift-community-operators/catalog:${OP_TEST_INDEX_IMAGE_TAG}${OP_TEST_INDEX_POSTFIX} -e op_base_name=community-operators"
  OP_TEST_EXEC_USER="$OP_TEST_EXEC_USER -e mirror_multiarch_image=registry.redhat.io/openshift4/ose-operator-registry:v4.5 -e mirror_apply=true -e bundle_index_image=quay.io/openshift-community-operators/catalog:${OP_TEST_INDEX_IMAGE_TAG}${OP_TEST_INDEX_POSTFIX}"
  OP_TEST_EXEC_USER_SECRETS="-e quay_api_token=$QUAY_API_TOKEN_OPENSHIFT_COMMUNITY_OP"
  [ "$OP_TEST_MIRROR_LATEST_TAG" == "${OP_TEST_INDEX_IMAGE_TAG}" ] && OP_TEST_EXEC_USER_SECRETS="$OP_TEST_EXEC_USER_SECRETS -e mirror_index_images=\"quay.io/redhat/redhat----community-operator-index:${OP_TEST_INDEX_IMAGE_TAG}|redhat+iib_community|$QUAY_RH_INDEX_PW|$OP_TEST_MIRROR_IMAGE_POSTFIX|quay.io/redhat/redhat----community-operator-index:latest\""
  [ "$OP_TEST_MIRROR_LATEST_TAG" != "${OP_TEST_INDEX_IMAGE_TAG}" ] && OP_TEST_EXEC_USER_SECRETS="$OP_TEST_EXEC_USER_SECRETS -e mirror_index_images=\"quay.io/redhat/redhat----community-operator-index:${OP_TEST_INDEX_IMAGE_TAG}|redhat+iib_community|$QUAY_RH_INDEX_PW|$OP_TEST_MIRROR_IMAGE_POSTFIX\""
  OP_TEST_EXEC_EXTRA="$OP_TEST_EXEC_EXTRA,mirror_index"
else
  echo "Only supported input is 'kubernetes' or 'openshift'"
  exit 1
fi


$OP_TEST_CONTAINER_TOOL run -d --rm $OP_TEST_CONTAINER_OPT --name $OP_TEST_NAME $OP_TEST_CONAINER_RUN_DEFAULT_ARGS $OP_TEST_CONTAINER_RUN_EXTRA_ARGS $OP_TEST_IMAGE
[ "$1" == "openshift" ] && iib_install

echo "$OP_TEST_EXEC_BASE $OP_TEST_EXEC_EXTRA $OP_TEST_EXEC_USER"
$OP_TEST_CONTAINER_TOOL exec $OP_TEST_CONTAINER_OPT $OP_TEST_NAME /bin/bash -c "$OP_TEST_EXEC_BASE $OP_TEST_EXEC_EXTRA $OP_TEST_EXEC_USER $OP_TEST_EXEC_USER_SECRETS"
