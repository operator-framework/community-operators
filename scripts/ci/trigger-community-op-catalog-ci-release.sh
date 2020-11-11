#!/usr/bin/env bash
set -e

NO_OPERATOR=0 #related to ansible-env
scripts/ci/ansible-env release

if [ -f /tmp/vars-op-path ]; then
     source /tmp/vars-op-path
     if [ "$NO_OPERATOR" -gt "0"  ]; then
       exit 0 # no need to test/release, no operator modified
     fi

     echo "STREAM_NAME=$STREAM_NAME OP_NAME=$OP_NAME OP_VER=$OP_VER"
     echo "PR_NUMBER=$PR_NUMBER OP_VER_UPDATE=$OP_VER_UPDATE OP_RECREATE=$OP_RECREATE"

     curl -s -X POST \
     -H "Content-Type: application/json" \
     -H "Accept: application/json" \
     -H "Travis-API-Version: 3" \
     -H "Authorization: token $FRAMEWORK_AUTOMATION_ON_TRAVIS"  \
     -d "{\"request\":{\"branch\":\"$STREAM_NAME\",\"message\":\"$OP_NAME ($OP_VER)\"}}"  \
     https://api.travis-ci.com/repo/operator-framework%2Fcommunity-operator-catalog/requests
     echo -e "\nRelease pipeline has been triggered on operator-framework/community-operator-catalog"

else
     echo "The file /tmp/vars-op-path does not exist."
     exit 1
fi



# This will execute version overwrite
# curl -s -X POST \
#      -H "Content-Type: application/json" \
#      -H "Accept: application/json" \
#      -H "Travis-API-Version: 3" \
#      -H "Authorization: token $FRAMEWORK_AUTOMATION_ON_TRAVIS"  \
#      -d "{\"request\":{\"branch\":\"job/$STREAM_NAME-update\",\"message\":\"$OP_NAME ($OP_VER)\",\"config\":{\"env\":{\"jobs\":[\"OP_STREAM_NAME_VER=$STREAM_NAME/$OP_NAME/$OP_VER\"]}}}}"  \
#      https://api.travis-ci.com/repo/operator-framework%2Fcommunity-operator-catalog/requests
#      echo -e "\nRelease pipeline has been triggered on operator-framework/community-operator-catalog"

# This will execute operator delet
# curl -s -X POST \
#      -H "Content-Type: application/json" \
#      -H "Accept: application/json" \
#      -H "Travis-API-Version: 3" \
#      -H "Authorization: token $FRAMEWORK_AUTOMATION_ON_TRAVIS"  \
#      -d "{\"request\":{\"branch\":\"job/$STREAM_NAME-update\",\"message\":\"$OP_NAME ($OP_VER)\",\"config\":{\"env\":{\"jobs\":[\"OP_STREAM_NAME_VER=$STREAM_NAME/$OP_NAME\",\"OP_DELETE=1\"]}}}}"  \
#      https://api.travis-ci.com/repo/operator-framework%2Fcommunity-operator-catalog/requests
#      echo -e "\nRelease pipeline has been triggered on operator-framework/community-operator-catalog"