#!/usr/bin/env bash
#This scripts is configured in https://github.com/openshift/release/tree/master/ci-operator/config/operator-framework/community-operators and executed from ci-operator/jobs

set -e #fail in case of non zero return

JQ_VERSION='1.6'
MAX_LIMIT_FOR_INDEX_WAIT=20
EXTRA_ARGS=''

OC_DIR_CORE=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 20 | head -n 1)
SUBDIR_ARG="-e work_subdir_name=oc-$OC_DIR_CORE"
echo "SUBDIR_ARG = $SUBDIR_ARG"

#label start
curl -f -u framework-automation:$(cat /var/run/cred/framautom) \
-X POST \
-H "Accept: application/vnd.github.v3+json" \
https://api.github.com/repos/operator-framework/community-operators/dispatches --data "{\"event_type\": \"openshift-test-status\", \"client_payload\": {\"source_pr\": \"$PULL_NUMBER\", \"remove_labels\": [\"deployment-ok\", \"openshift-started\"], \"add_labels\": [\"openshift-started\"]}}"

pwd
TARGET_PATH='/go/src/github.com/operator-framework/community-operators/community-operators'

##temp test for development to test on a stable commit
#echo "Need to clone test branch, cloning..."
#mkdir -p /tmp/oper-for-me-test
#cd /tmp/oper-for-me-test
#git clone https://github.com/J0zi/community-operators.git
#cd community-operators
#git checkout oper-for-my-test
#ls
#TARGET_PATH='/tmp/oper-for-me-test/community-operators/community-operators'

##clone again to suppress caching during pr on ci-operator repo
#echo "Need to clone actual branch, cloning..."
#mkdir -p /tmp/oper-for-me-test
#cd /tmp/oper-for-me-test
#git clone https://github.com/operator-framework/community-operators.git
#cd community-operators
#ls
#TARGET_PATH='/tmp/oper-for-me-test/community-operators/community-operators'

#detection start
mkdir -p /tmp/jq-$OC_DIR_CORE/bin/
curl -L "https://github.com/stedolan/jq/releases/download/jq-$JQ_VERSION/jq-linux64" --output "/tmp/jq-$OC_DIR_CORE/bin/jq" #&& echo "jq $JQ_VERSION downloaded"
chmod +x "/tmp/jq-$OC_DIR_CORE/bin/jq" && echo "rights adjusted"

#detect allow/longer-deployment label
curl -f -u framework-automation:$(cat /var/run/cred/framautom) \
-X GET \
-H "Accept: application/vnd.github.v3+json" \
"https://api.github.com/repos/operator-framework/community-operators/issues/$PULL_NUMBER"|"/tmp/jq-$OC_DIR_CORE/bin/jq" '.labels[].name'|grep 'allow/longer-deployment' \
&& echo "Longer deployment detected" && EXTRA_ARGS='-e pod_start_retries=300'

cd "$TARGET_PATH"

tmpfile=$(mktemp /tmp/pr-details-XXXXXXX.json)
curl -s https://api.github.com/repos/operator-framework/community-operators/pulls/$PULL_NUMBER -o $tmpfile
REPO_FULL=$(cat $tmpfile | /tmp/jq-$OC_DIR_CORE/bin/jq -r '.head.repo.clone_url')
BRANCH=$(cat $tmpfile | /tmp/jq-$OC_DIR_CORE/bin/jq -r '.head.ref')
COMMIT=$(cat $tmpfile | /tmp/jq-$OC_DIR_CORE/bin/jq -r '.head.sha')
REPO=$(echo "$REPO_FULL"| awk -F'https://github.com/' '{print $2}')
QUAY_HASH=$(echo ${COMMIT::8})

rm -f $tmpfile > /dev/null 2>&1

OPRT_REPO=${REPO_FULL-""}
OPRT_SHA=${COMMIT-""}
OPRT_SRC_BRANCH=${OPRT_SRC_BRANCH-"master"}
export OPRT=1

[ -n "$OPRT_REPO" ] || { echo "Error: '\$OPRT_REPO' is empty !!!"; exit 1; }
[ -n "$OPRT_SHA" ] || { echo "Error: '\$OPRT_SHA' is empty !!!"; exit 1; }

git clone $REPO_FULL community-operators > /dev/null 2>&1
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
export OP_TEST_RENAMED_ADDED_MODIFIED_FILES=$(git diff --diff-filter=RAM upstream/$OPRT_SRC_BRANCH --name-only | tr '\r\n' ' ')

BRANCH_NAME=$(echo $BRANCH_NAME | cut -d '/' -f 2-)
echo "BRANCH_NAME=$BRANCH_NAME"

[ -n "$OP_TEST_REMOVED_FILES" ] && [ -z "$OP_TEST_RENAMED_ADDED_MODIFIED_FILES" ] && echo "Nothing to test - [OK]" && echo "only deleted files detected:" && echo ${OP_TEST_REMOVED_FILES[@]} && exit 0;

for sf in ${OP_TEST_RENAMED_ADDED_MODIFIED_FILES[@]}; do
  echo $sf
  if [ $(echo $sf| awk -F'/' '{print NF}') -ge 4 ]; then
      OP_NAME="$(echo "$sf" | awk -F'/' '{ print $2 }')"
      OP_VER="$(echo "$sf" | awk -F'/' '{ print $3 }')"
  fi
done
echo
echo "OP_NAME=$OP_NAME"
echo "OP_VER=$OP_VER"

[ -n "$OP_NAME" ] || { echo "Error: '\$OP_NAME' is empty !!!"; exit 1; }
[ -n "$OP_VER" ] || { echo "Error: '\$OP_VER' is empty !!!"; exit 1; }

#detection end

#test
#OP_NAME=aqua
#OP_VER=1.0.2
#COMMIT=1234
#echo "Forced specific operator - $OP_NAME $OP_VER $COMMIT"

#prepare temp index
OP_TOKEN=$(cat /var/run/cred/op_token_quay_test)
echo
curl -f -u framework-automation:$(cat /var/run/cred/framautom) \
-X POST \
-H "Accept: application/vnd.github.v3+json" \
https://api.github.com/repos/operator-framework/community-operators/dispatches --data "{\"event_type\": \"index-for-openshift-test\", \"client_payload\": {\"source_pr\": \"$PULL_NUMBER\"}}"  && echo "Temp index initiated ..."

CHECK_TEMP_INDEX=1
while [ "$CHECK_TEMP_INDEX" -le "$MAX_LIMIT_FOR_INDEX_WAIT" ]; do
  echo "Checking index $QUAY_HASH presence ... $CHECK_TEMP_INDEX minutes."
  if [ $(curl -s 'https://quay.io/v2/operator_testing/catalog/tags/list'|grep $QUAY_HASH) ]; then
   echo "Temp index $QUAY_HASH found."
   break
  elif [ "$CHECK_TEMP_INDEX" -eq "$MAX_LIMIT_FOR_INDEX_WAIT" ]; then
    echo
    echo
    echo 'Temp index not found. Are your commits squashed? If so, please check logs https://github.com/operator-framework/community-operators/actions?query=workflow%3Aprepare-test-index'
    echo
    echo
    exit 1
  fi
  sleep 60s
  CHECK_TEMP_INDEX=$(($CHECK_TEMP_INDEX + 1))
done

#deploy start
mkdir -p /tmp/playbooks2
cd /tmp/playbooks2
git clone https://github.com/operator-framework/operator-test-playbooks.git
cd operator-test-playbooks/upstream
export ANSIBLE_CONFIG=/tmp/playbooks2/operator-test-playbooks/upstream/ansible.cfg
ANSIBLE_STDOUT_CALLBACK=yaml ansible-playbook -i localhost, deploy-olm-operator-openshift-upstream.yml -e ansible_connection=local -e package_name=$OP_NAME -e operator_dir=$TARGET_PATH/$OP_NAME -e op_version=$OP_VER -e oc_bin_path="/tmp/oc-$OC_DIR_CORE/bin/oc" -e commit_tag=$QUAY_HASH -e dir_suffix_part=$OC_DIR_CORE $SUBDIR_ARG $EXTRA_ARGS -vv
if [ $? -eq 0 ]; then
  curl -f -u framework-automation:$(cat /var/run/cred/framautom) \
  -X POST \
  -H "Accept: application/vnd.github.v3+json" \
  https://api.github.com/repos/operator-framework/community-operators/dispatches --data "{\"event_type\": \"openshift-test-status\", \"client_payload\": {\"source_pr\": \"$PULL_NUMBER\", \"remove_labels\": [\"openshift-started\", \"deployment-ok\"], \"add_labels\": [\"deployment-ok\"]}}"
else
  curl -f -u framework-automation:$(cat /var/run/cred/framautom) \
  -X POST \
  -H "Accept: application/vnd.github.v3+json" \
  https://api.github.com/repos/operator-framework/community-operators/dispatches --data "{\"event_type\": \"openshift-test-status\", \"client_payload\": {\"source_pr\": \"$PULL_NUMBER\", \"remove_labels\": [\"openshift-started\", \"deployment-ok\"], \"add_labels\": [\"openshift-failed\"]}}"
fi

echo "Variable summary:"
echo "OP_NAME=$OP_NAME"
echo "OP_VER=$OP_VER"
