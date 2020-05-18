#!/usr/bin/env bash

curl -s -X POST \
     -H "Content-Type: application/json" \
     -H "Accept: application/json" \
     -H "Travis-API-Version: 3" \
     -H "Authorization: token $CI_OHIO_TRIGGER_TOKEN"  \
     -d '{"request":{"branch":"master"}}'  \
     https://api.travis-ci.com/repo/operator-framework%2Foperatorhub.io/requests
echo -e "\nCI on operator-framework/operatorhub.io and it's master branch was triggered"
