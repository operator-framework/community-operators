#!/bin/bash
set +o pipefail

OPP_ANSIBLE_PULL_REPO=${OPP_ANSIBLE_PULL_REPO-"https://github.com/redhat-openshift-ecosystem/operator-test-playbooks"}
OPP_ANSIBLE_PULL_BRANCH=${OPP_ANSIBLE_PULL_BRANCH-"upstream-community"}

OPP_INPUT_REPO=${OPP_INPUT_REPO-"https://github.com/operator-framework/community-operators"}
OPP_INPUT_BRANCH=${OPP_INPUT_BRANCH-"master"}

OPP_ANSIBLE_ARGS="-i localhost, -e ansible_connection=local upstream/set-pipeline-workflow.yml"
OPP_TMP_DIR="/tmp/opp-update"
[ -d $OPP_TMP_DIR ] && rm -rf $OPP_TMP_DIR
mkdir -p $OPP_TMP_DIR
git clone $OPP_INPUT_REPO --branch $OPP_INPUT_BRANCH $OPP_TMP_DIR/opp-input

ANSIBLE_STDOUT_CALLBACK=yaml ansible-pull -U $OPP_ANSIBLE_PULL_REPO -C $OPP_ANSIBLE_PULL_BRANCH $OPP_ANSIBLE_ARGS  -e workflow_templates_path=$OPP_TMP_DIR/opp-input/scripts/template/workflow/ -e workflow_config_path=$PWD/ci
