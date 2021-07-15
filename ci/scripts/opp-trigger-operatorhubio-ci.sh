#!/usr/bin/env bash
set -e #fail in case of non zero return
CI_OHIO_BRANCH=${CI_OHIO_BRANCH-"master"}

payload()
{
  cat <<EOF
{
"ref": "$CI_OHIO_BRANCH"
}
EOF
}

curl -f -s -X POST \
  --url https://api.github.com/repos/operator-framework/operatorhub.io/actions/workflows/4934257/dispatches \
  --header "Authorization: token $CI_OHIO_TRIGGER_TOKEN" \
  --header 'Content-Type: application/json' \
  --data "$(payload)"

echo -e "\nCI on operator-framework/operatorhub.io and it's '$CI_OHIO_BRANCH' branch was triggered"