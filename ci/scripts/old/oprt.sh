#!/bin/bash
set +o pipefail
OPRT_REPO=${OPRT_REPO-""}
OPRT_SHA=${OPRT_SHA-""}
OPRT_SRC_BRANCH=${OPRT_SRC_BRANCH-"master"}
OPRT_SCRIPT=${OPRT_SCRIPT-"https://raw.githubusercontent.com/operator-framework/community-operators/master/scripts/ci/actions-env"}
export OPRT=1

[ -n "$OPRT_REPO" ] || { echo "Error: '\$OPRT_REPO' is empty !!!"; exit 1; }
[ -n "$OPRT_SHA" ] || { echo "Error: '\$OPRT_SHA' is empty !!!"; exit 1; }

git clone https://github.com/$OPRT_REPO community-operators > /dev/null 2>&1
cd community-operators
BRANCH_NAME=$(git branch -a --contains $OPRT_SHA | grep remotes/ | grep -v HEAD | cut -d '/' -f 2-)
git checkout $BRANCH_NAME > /dev/null 2>&1
git log --oneline | head

git config --global user.email "test@example.com"
git config --global user.name "Test User"

git remote add upstream https://github.com/operator-framework/community-operators -f > /dev/null 2>&1
git pull --rebase -Xours upstream $OPRT_SRC_BRANCH 

export OP_TEST_ADDED_FILES=$(git diff --diff-filter=A upstream/$OPRT_SRC_BRANCH --name-only | tr '\r\n' ' ')
export OP_TEST_MODIFIED_FILES=$(git diff --diff-filter=M upstream/$OPRT_SRC_BRANCH --name-only | tr '\r\n' ' ')
export OP_TEST_REMOVED_FILES=$(git diff --diff-filter=D upstream/$OPRT_SRC_BRANCH --name-only | tr '\r\n' ' ')
export OP_TEST_RENAMED_FILES=$(git diff --diff-filter=R upstream/$OPRT_SRC_BRANCH --name-only | tr '\r\n' ' ')
export OP_TEST_ADDED_MODIFIED_FILES=$(git diff --diff-filter=AM upstream/$OPRT_SRC_BRANCH --name-only | tr '\r\n' ' ')
export OP_TEST_ADDED_MODIFIED_RENAMED_FILES=$(git diff --diff-filter=RAM upstream/$OPRT_SRC_BRANCH --name-only | tr '\r\n' ' ')

BRANCH_NAME=$(echo $BRANCH_NAME | cut -d '/' -f 2-)
echo "BRANCH_NAME=$BRANCH_NAME"
echo "::set-output name=op_test_repo_branch::$OPRT_REPO/${BRANCH_NAME}"

bash <(curl -sL $OPRT_SCRIPT)


