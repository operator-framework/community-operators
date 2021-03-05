#!/bin/bash
set +o pipefail

echo "OPA_TEST_TYPE=$OPA_TEST_TYPE"
echo "OPA_STREAM=$OPA_STREAM"
echo "OPA_NAME=$OPA_NAME"
echo "OPA_VERSION=$OPA_VERSION"
echo "OPA_REPO=$OPA_REPO"
echo "OPA_BRANCH=$OPA_BRANCH"
echo "OPA_REPO_DIR=$OPA_REPO_DIR"
echo "OPA_OPERATOR_VERSION_PATH=$OPA_OPERATOR_VERSION_PATH"
echo "OPA_PR_LABELS=$OPA_PR_LABELS"

OPA_VALID_TESTS="kiwi lemon orange"
IS_TEST_VALID=0
for t in $OPA_VALID_TESTS;do
  [[ $OPA_TEST_TYPE == $t* ]] && IS_TEST_VALID=1
done
echo "IS_TEST_VALID=$IS_TEST_VALID"
[[ $IS_TEST_VALID -eq 0 ]] && { echo "Error: Test type '$OPA_TEST_TYPE' is not supprted !!! Supported types are '$OPA_VALID_TESTS' ."; exit 1; }

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

[ -n "$OPA_STREAM" ] || { echo "Error: \$OPA_STREAM is empty !!! "; exit 1; }
[ -n "$OPA_NAME" ] || { echo "Error: \$OPA_NAME is empty !!! "; exit 1; }
[ -n "$OPA_VERSION" ] || { echo "Error: \$OPA_VERSION is empty !!! "; exit 1; }

if [ ! -d $MYPWD/$OPA_STREAM ];then
  echo "Cloing repo '$OPA_REPO' with branch '$OPA_BRANCH'"
  git clone $OPA_REPO --branch $OPA_BRANCH
  cd $OPA_REPO_DIR
fi

if [ -n "$OPA_OPERATOR_VERSION_PATH" ];then
  echo "Creating operator directory structure from '$OPA_OPERATOR_VERSION_PATH' to '$OPA_STREAM/$OPA_NAME/$OPA_VERSION'"
  rm -rf $OPA_STREAM/$OPA_NAME/$OPA_VERSION
  mkdir -p $OPA_STREAM/$OPA_NAME/$OPA_VERSION
  cp -a ../$OPA_OPERATOR_VERSION_PATH/* $OPA_STREAM/$OPA_NAME/$OPA_VERSION/
  ls -al $OPA_STREAM/$OPA_NAME/$OPA_VERSION/
  [ -n "$OPA_PACKAGE_PATH" ] && [ -f $OPA_PACKAGE_PATH ] && cp -f $OPA_PACKAGE_PATH $OPA_STREAM/$OPA_NAME/
  [ -n "$OPA_CI_PATH" ] && [ -f $OPA_CI_PATH ] && cp -f $OPA_CI_PATH $OPA_STREAM/$OPA_NAME/
  ls -al $OPA_STREAM/$OPA_NAME
fi

if [ ! -f scripts/ci/op-test ];then
  mkdir -p scripts/ci/
  curl -O scripts/ci/op-test https://raw.githubusercontent.com/operator-framework/community-operators/master/scripts/ci/op-test
  chmod +x scripts/ci/op-test
fi

echo scripts/ci/op-test $OPA_TEST_TYPE "$OPA_STREAM/$OPA_NAME/$OPA_VERSION"
scripts/ci/op-test $OPA_TEST_TYPE "$OPA_STREAM/$OPA_NAME/$OPA_VERSION"
rc=$?
[[ $rc -eq 0 ]] || { echo "Error: rc=$rc"; exit $rc; }
echo "Done"

cd $MYPWD