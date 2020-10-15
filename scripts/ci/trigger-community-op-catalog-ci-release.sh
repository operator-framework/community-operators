#!/usr/bin/env bash

eval $(scripts/ci/ansible-env)

curl -s -X POST \
     -H "Content-Type: application/json" \
     -H "Accept: application/json" \
     -H "Travis-API-Version: 3" \
     -H "Authorization: token $FRAMEWORK_AUTOMATION_ON_TRAVIS"  \
     -d "{\"request\":{\"branch\":\"$STREAM_NAME\",\"message\":\"$OP_PATH ($OP_VER)\"}}"  \
     https://api.travis-ci.com/repo/operator-framework%2Fcommunity-operator-catalog/requests
echo -e "\nRelease pipeline has been triggered on operator-framework/community-operator-catalog"