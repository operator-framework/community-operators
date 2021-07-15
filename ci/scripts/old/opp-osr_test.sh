#!/bin/bash
set -e #fail in case of non zero return
OP_DEBUG=${OP_DEBUG-0}
[[ $OP_DEBUG -ge 2 ]] && set -x
OP_STREAM=${OP_STREAM-"upstream-community-operators"}
OP_NAME=${OP_NAME-"aqua"}
OP_VERSION=${OP_VERSION-"1.0.2"}
OP_REPO=${OP_REPO-""}
OP_BRANCH=${OP_BRANCH-"master"}
OP_OSR_HASH=${OP_OSR_HASH-""}
OP_ANSIBLE_EXTRA=${OP_ANSIBLE_EXTRA-"-e opm_container_tool=podman -e container_tool=podman -e opm_container_tool_index="}

[ -n "$OP_REPO" ] && OP_ANSIBLE_EXTRA="$OP_ANSIBLE_EXTRA -e catalog_repo=$OP_REPO -e catalog_repo_branch=$OP_BRANCH"
[ -n "$OP_OSR_HASH" ] || { echo "Variable \$OP_OSR_HASH is empty !!!"; exit 1; }

[[ $OP_DEBUG -ge 1 ]] && OP_ANSIBLE_EXTRA="$OP_ANSIBLE_EXTRA -vv"

ansible-playbook -i localhost, -e ansible_connection=local upstream/local.yml \
--tags deploy_bundles \
-e run_upstream=true \
-e operator_dir=/tmp/community-operators-for-catalog/$OP_STREAM/$OP_NAME \
-e operator_version=$OP_VERSION \
-e remove_replaces=true \
-e openshift_robot_hash="$OP_OSR_HASH" \
-e strict_mode=true \
-e operator_channel_force=optest \
-e image_protocol="docker://" \
$OP_ANSIBLE_EXTRA
