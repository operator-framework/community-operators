#!/bin/bash
set +o pipefail

OPP_ANSIBLE_PULL_REPO=${OPP_ANSIBLE_PULL_REPO-"https://github.com/redhat-openshift-ecosystem/operator-test-playbooks"}
OPP_ANSIBLE_PULL_BRANCH=${OPP_ANSIBLE_PULL_BRANCH-"upstream-community"}

OPP_INPUT_REPO=${OPP_INPUT_REPO-"https://github.com/operator-framework/community-operators"}
OPP_INPUT_BRANCH=${OPP_INPUT_BRANCH-"master"}
OPP_CONTAINER_TOOL=${OPP_CONTAINER_TOOL-docker}
OPP_ANSIBLE_ARGS="-i localhost, -e ansible_connection=local upstream/local-pipeline-update.yml"
OPP_ANSIBLE_EXTRA_ARGS=""

[ $1 = "recreate" ] && OPP_ANSIBLE_EXTRA_ARGS="-e empty_index=quay.io/operator_testing/index_empty"

OPP_TMP_DIR="/tmp/opp-update"
[ -d $OPP_TMP_DIR ] && rm -rf $OPP_TMP_DIR
mkdir -p $OPP_TMP_DIR
git clone $OPP_INPUT_REPO --branch $OPP_INPUT_BRANCH $OPP_TMP_DIR/opp-input

ANSIBLE_STDOUT_CALLBACK=yaml ansible-pull -U $OPP_ANSIBLE_PULL_REPO -C $OPP_ANSIBLE_PULL_BRANCH $OPP_ANSIBLE_ARGS \
-e workflow_config_path="$PWD/ci" \
-e workflow_templates_path="$OPP_TMP_DIR/opp-input/scripts/template/workflow" \
-e workflow_output_path="$PWD/.github/workflows" \
-e quay_api_token=$REGISTRY_RELEASE_API_TOKEN \
-e container_tool=$OPP_CONTAINER_TOOL \
$OPP_ANSIBLE_EXTRA_ARGS

######## Gen empty index ###############################
#
#/tmp/operator-test/bin/opm index add --bundles quay.io/operator_testing/aqua:v0.0.1 --tag quay.io/operator_testing/index_empty:latest --mode semver -p none
#podman login quay.io -u mavala
#podman push quay.io/operator_testing/index_empty:latest
#/tmp/operator-test/bin/opm index rm -o aqua --from-index quay.io/operator_testing/index_empty:latest --tag quay.io/operator_testing/index_empty:latest -p none
#podman push quay.io/operator_testing/index_empty:latest
#
########################################################
