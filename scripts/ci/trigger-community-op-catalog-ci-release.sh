#!/usr/bin/env bash
set -e

NO_OPERATOR=0 #related to ansible-env
INPUT_ENV_SCRIPT=${INPUT_ENV_SCRIPT-"/tmp/vars-op-path"}
scripts/ci/ansible-env release || { echo "Error in preparing operator environment !!! Contact admins."; exit 1; }
source $INPUT_ENV_SCRIPT

if [ "$NO_OPERATOR" -gt "0"  ]; then
  exit 0 # no need to test/release, no operator modified
fi

[[ $OP_VER_OVERWRITE -eq 1 ]] && [[ $OP_RECREATE -eq 1 ]] && { echo "Labels 'allow/operator-version-overwrite' and 'allow/operator-recreate' cannot be set simultaneously !!!"; exit 1; }

echo "STREAM_NAME=$STREAM_NAME OP_NAME=$OP_NAME OP_VER=$OP_VER"
echo "OP_PR_NUMBER=$OP_PR_NUMBER OP_VER_OVERWRITE=$OP_VER_OVERWRITE OP_RECREATE=$OP_RECREATE"

if [[ $OP_VER_OVERWRITE -eq 1 ]];then
  # This will execute version overwrite
  curl -s -X POST \
      -H "Content-Type: application/json" \
      -H "Accept: application/json" \
      -H "Travis-API-Version: 3" \
      -H "Authorization: token $FRAMEWORK_AUTOMATION_ON_TRAVIS"  \
      -d "{\"request\":{\"branch\":\"job/$STREAM_NAME-update\",\"message\":\"[OVERWRITE] $OP_NAME ($OP_VER)\",\"config\":{\"env\":{\"jobs\":[\"OP_STREAM_NAME_VER=$STREAM_NAME/$OP_NAME/$OP_VER\"]}}}}"  \
      https://api.travis-ci.com/repo/operator-framework%2Fcommunity-operator-catalog/requests
      echo -e "\nRelease pipeline has been triggered on operator-framework/community-operator-catalog"
  exit 0
fi


if [[ $OP_RECREATE -eq 1 ]];then
  # This will execute operator delete
  curl -s -X POST \
       -H "Content-Type: application/json" \
       -H "Accept: application/json" \
       -H "Travis-API-Version: 3" \
       -H "Authorization: token $FRAMEWORK_AUTOMATION_ON_TRAVIS"  \
       -d "{\"request\":{\"branch\":\"job/$STREAM_NAME-update\",\"message\":\"[DELETE] $OP_NAME\",\"config\":{\"env\":{\"jobs\":[\"OP_STREAM_NAME_VER=$STREAM_NAME/$OP_NAME OP_DELETE=1\"]}}}}"  \
       https://api.travis-ci.com/repo/operator-framework%2Fcommunity-operator-catalog/requests
       echo -e "\nRelease pipeline has been triggered on operator-framework/community-operator-catalog"
  sleep 10
fi

curl -s -X POST \
-H "Content-Type: application/json" \
-H "Accept: application/json" \
-H "Travis-API-Version: 3" \
-H "Authorization: token $FRAMEWORK_AUTOMATION_ON_TRAVIS"  \
-d "{\"request\":{\"branch\":\"$STREAM_NAME\",\"message\":\"[RELEASE] $OP_NAME ($OP_VER)\"}}"  \
https://api.travis-ci.com/repo/operator-framework%2Fcommunity-operator-catalog/requests
echo -e "\nRelease pipeline has been triggered on operator-framework/community-operator-catalog"
