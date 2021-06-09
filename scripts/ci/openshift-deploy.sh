#!/usr/bin/env bash
#This scripts is configured in https://github.com/openshift/release/tree/master/ci-operator/config/operator-framework/community-operators and executed from ci-operator/jobs
if [ $1 = "test-only" ]; then
  echo "Running in test mode"
  export TEST_MODE=1
  if [ -z "${2+xxx}" ]; then echo "Please provide test repo and branch for community operators 'test-only https://github.com/operator-framework/community-operators.git community_branch_name https://github.com/operator-framework/operator-test-playbooks.git playbook_branch_name 3966'"
  else
    export TEST_COMMUNITY_REPO=$2
    export TEST_COMMUNITY_BRANCH=$3
    export TEST_PB_REPO=$4
    export TEST_PB_BRANCH=$5
    export PULL_NUMBER=$6
  fi
fi
[[ $TEST_MODE -eq 1 ]] && export OCP_CLUSTER_VERSION=4.7

echo "OCP_CLUSTER_VERSION=$OCP_CLUSTER_VERSION"
OCP_CLUSTER_VERSION=${OCP_CLUSTER_VERSION-""}
if [ -n "$OCP_CLUSTER_VERSION" ]; then
  if [[ "$OCP_CLUSTER_VERSION" = "4.6" ]]; then
    export OCP_CLUSTER_VERSION_SUFFIX=""
  else export OCP_CLUSTER_VERSION_SUFFIX="-$OCP_CLUSTER_VERSION"
  fi
else export OCP_CLUSTER_VERSION_SUFFIX=""
fi

cd -P -- "$(dirname -- "$0")"
./openshift-deploy-core.sh || curl -f -u framework-automation:$(cat /var/run/cred/framautom) \
-X POST \
-H "Accept: application/vnd.github.v3+json" \
https://api.github.com/repos/operator-framework/community-operators/dispatches --data "{\"event_type\": \"openshift-test-status\", \"client_payload\": {\"source_pr\": \"$PULL_NUMBER\", \"remove_labels\": [\"openshift-started$OCP_CLUSTER_VERSION_SUFFIX\", \"installation-validated$OCP_CLUSTER_VERSION_SUFFIX\"], \"add_labels\": [\"installation-failed$OCP_CLUSTER_VERSION_SUFFIX\"]}}";
exit 1;
