#!/usr/bin/env bash
CI_OHIO_BRANCH=${CI_OHIO_BRANCH-"master"}
curl -s -X POST \
  --url https://api.github.com/repos/operator-framework/operatorhub.io/actions/workflows/4934257/dispatches \
  --header "Authorization: token $REPO_GHA_PAT" \
  --header 'Content-Type: application/json' \
  --data "{
    'ref': \"$CI_OHIO_BRANCH\"
}"
echo -e "\nCI on operator-framework/operatorhub.io and it's '$CI_OHIO_BRANCH' branch was triggered"