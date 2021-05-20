#!/usr/bin/env bash
#This scripts is configured in https://github.com/openshift/release/tree/master/ci-operator/config/operator-framework/community-operators and executed from ci-operator/jobs
cd -P -- "$(dirname -- "$0")"
./openshift-deploy-core.sh || curl -f -u framework-automation:$(cat /var/run/cred/framautom) \
-X POST \
-H "Accept: application/vnd.github.v3+json" \
https://api.github.com/repos/operator-framework/community-operators/dispatches --data "{\"event_type\": \"openshift-test-status\", \"client_payload\": {\"source_pr\": \"$PULL_NUMBER\", \"remove_labels\": [\"openshift-started\", \"installation-validated\"], \"add_labels\": [\"installation-failed\"]}}"


