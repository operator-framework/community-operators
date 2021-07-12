#!/bin/bash
# Operator Pipeline (OPP) env script (opp-env.sh)

set +o pipefail
OPP_OPRT_REPO=${OPP_OPRT_REPO-""}
OPP_OPRT_SHA=${OPP_OPRT_SHA-""}
OPP_OPRT_SRC_REPO=${OPP_OPRT_SRC_REPO-"operator-framework/community-operators"}
OPP_OPRT_SRC_BRANCH=${OPP_OPRT_SRC_BRANCH-"master"}
OPP_SCRIPT_ENV_URL=${OPP_SCRIPT_ENV_URL-"https://raw.githubusercontent.com/operator-framework/community-operators/master/scripts/ci/actions-env"}
export OPRT=1
echo "OPP_SCRIPT_ENV_URL=$OPP_SCRIPT_ENV_URL"

[ -n "$OPP_OPRT_REPO" ] || { echo "Error: '\$OPP_OPRT_REPO' is empty !!!"; exit 1; }
[ -n "$OPP_OPRT_SHA" ] || { echo "Error: '\$OPP_OPRT_SHA' is empty !!!"; exit 1; }

git clone https://github.com/$OPP_OPRT_REPO operators #> /dev/null 2>&1
echo "cloned https://github.com/$OPP_OPRT_REPO"
cd operators
BRANCH_NAME=$(git branch -a --contains $OPP_OPRT_SHA | grep remotes/ | grep -v HEAD | cut -d '/' -f 2-)
echo "BRANCH_NAME=$BRANCH_NAME"
git checkout $BRANCH_NAME #> /dev/null 2>&1
git log --oneline | head

git config --global user.email "test@example.com"
git config --global user.name "Test User"

git remote add upstream https://github.com/$OPP_OPRT_SRC_REPO -f #> /dev/null 2>&1
echo "added remote https://github.com/$OPP_OPRT_SRC_REPO"
git pull --rebase -Xours upstream $OPP_OPRT_SRC_BRANCH 
echo "Repo rebased over branch OPP_OPRT_SRC_BRANCH - $OPP_OPRT_SRC_BRANCH"

export OPP_ADDED_FILES=$(git diff --diff-filter=A upstream/$OPP_OPRT_SRC_BRANCH --name-only | tr '\r\n' ' ')
export OPP_MODIFIED_FILES=$(git diff --diff-filter=M upstream/$OPP_OPRT_SRC_BRANCH HEAD --name-only | tr '\r\n' ' ')
export OPP_REMOVED_FILES=$(git diff --diff-filter=D upstream/$OPP_OPRT_SRC_BRANCH --name-only | tr '\r\n' ' ')
export OPP_RENAMED_FILES=$(git diff --diff-filter=R upstream/$OPP_OPRT_SRC_BRANCH --name-only | tr '\r\n' ' ')
export OPP_ADDED_MODIFIED_FILES=$(git diff --diff-filter=AM upstream/$OPP_OPRT_SRC_BRANCH --name-only | tr '\r\n' ' ')
export OPP_ADDED_MODIFIED_RENAMED_FILES=$(git diff --diff-filter=RAM upstream/$OPP_OPRT_SRC_BRANCH --name-only | tr '\r\n' ' ')
export OPP_CURRENT_PROJECT_REPO="$OPP_OPRT_SRC_REPO"
export OPP_CURRENT_PROJECT_BRANCH="$OPP_OPRT_SRC_BRANCH"

BRANCH_NAME=$(echo $BRANCH_NAME | cut -d '/' -f 2-)
echo "BRANCH_NAME=$BRANCH_NAME"
# echo "::set-output name=op_test_repo_branch::$OPP_OPRT_REPO/${BRANCH_NAME}"

bash <(curl -sL $OPP_SCRIPT_ENV_URL)
