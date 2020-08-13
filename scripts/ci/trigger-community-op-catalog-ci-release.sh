#!/usr/bin/env bash

curl -s -X POST \
     -H "Content-Type: application/json" \
     -H "Accept: application/json" \
     -H "Travis-API-Version: 3" \
     -H "Authorization: token $FRAMEWORK_AUTOMATION_ON_TRAVIS"  \
     -d '{"request":{"branch":"master"}}'  \
     https://api.travis-ci.com/repo/operator-framework%2Fcommunity-operator-catalog/requests
echo -e "\nRelease pipeline has been triggered on operator-framework/community-operator-catalog"
