#!/usr/bin/env bash
#This scripts is configured in https://github.com/openshift/release/tree/master/ci-operator/config/operator-framework/community-operators and executed from ci-operator/jobs
echo "OCP_CLUSTER_VERSION=$OCP_CLUSTER_VERSION"
OCP_CLUSTER_VERSION=${OCP_CLUSTER_VERSION-""}
if [ -n "$OCP_CLUSTER_VERSION" ]; then
  if [[ "$OCP_CLUSTER_VERSION" = "4.6" ]]; then
    export OCP_CLUSTER_VERSION_SUFFIX=""
  else OCP_CLUSTER_VERSION_SUFFIX="-$OCP_CLUSTER_VERSION"
  fi
else OCP_CLUSTER_VERSION_SUFFIX=""
fi

cd -P -- "$(dirname -- "$0")"
./openshift-deploy-core.sh || { curl -f -u framework-automation:$(cat /var/run/cred/framautom) \
-X POST \
-H "Accept: application/vnd.github.v3+json" \
https://api.github.com/repos/operator-framework/community-operators/dispatches --data "{\"event_type\": \"openshift-test-status\", \"client_payload\": {\"source_pr\": \"$PULL_NUMBER\", \"remove_labels\": [\"openshift-started$OCP_CLUSTER_VERSION_SUFFIX\", \"installation-validated$OCP_CLUSTER_VERSION_SUFFIX\"], \"add_labels\": [\"installation-failed$OCP_CLUSTER_VERSION_SUFFIX\"]}}";
exit 1; }
