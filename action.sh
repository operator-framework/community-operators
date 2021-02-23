#!/bin/bash
set +o pipefail

echo "OPA_TEST_TYPE=$OPA_TEST_TYPE"
echo "OPA_STREAM=$OPA_STREAM"
echo "OPA_NAME=$OPA_NAME"
echo "OPA_VERSION=$OPA_VERSION"
echo "OPA_REPO=$OPA_REPO"
echo "OPA_BRANCH=$OPA_BRANCH"
echo "OPA_REPO_DIR=$OPA_REPO_DIR"
echo "OPA_OPERATOR_DIR=$OPA_OPERATOR_DIR"
echo "OPA_PR_LABELS=$OPA_PR_LABELS"

OPA_VALID_TESTS="kiwi lemon orange"
IS_TEST_VALID=0
for t in $OPA_VALID_TESTS;do
  [[ $OPA_TEST_TYPE == $t* ]] && IS_TEST_VALID=1
done

echo "IS_TEST_VALID=$IS_TEST_VALID"

export OP_TEST_DEBUG=${OP_TEST_DEBUG-1}
export OP_TEST_CONTAINER_OPT=${OP_TEST_CONTAINER_OPT-"-t"}
export OP_TEST_SCRIPT_URL=${OP_TEST_SCRIPT_URL-"https://raw.githubusercontent.com/operator-framework/operator-test-playbooks/master/upstream/test/test.sh"}
export OP_TEST_IMAGE=${OP_TEST_IMAGE-"quay.io/operator_testing/operator-test-playbooks:latest"}
export OP_TEST_PROD=0
export OP_TEST_DRY_RUN=0
export GODEBUG=x509ignoreCN=0
export OP_TEST_LABELS=${OP_TEST_LABELS-"$OPA_PR_LABELS"}

MYPWD=$(pwd)
echo "MYPWD=$MYPWD"
MY_BASENAME=$(basename $MYPWD)
echo "$MY_BASENAME != $OPA_REPO_DIR"
if [ "$MY_BASENAME" != "$OPA_REPO_DIR" ];then
    echo "$OPA_REPO $OPA_BRANCH"
    [ -d $OPA_REPO_DIR ] || git clone $OPA_REPO --branch $OPA_BRANCH
    cd $OPA_REPO_DIR
fi

ls -al 
export

echo scripts/ci/op-test $OPA_TEST_TYPE "$OPA_STREAM/$OPA_NAME/$OPA_VERSION"
scripts/ci/op-test $OPA_TEST_TYPE "$OPA_STREAM/$OPA_NAME/$OPA_VERSION"
rc=$?
[[ $rc -eq 0 ]] || { echo "Error: rc=$rc"; exit $rc; }
echo "Done"

cd $MYPWD