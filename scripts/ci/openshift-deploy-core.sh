#!/usr/bin/env bash
#./openshift-deploy.sh test-only https://github.com/J0zi/community-operators.git bundle2 https://github.com/J0zi/operator-test-playbooks.git CVP-1793-exit-non-relevant-ocp-test

set -e #fail in case of non zero return
echo "OCP_CLUSTER_VERSION_SUFFIX=$OCP_CLUSTER_VERSION_SUFFIX"

JQ_VERSION='1.6'
MAX_LIMIT_FOR_INDEX_WAIT=20
EXTRA_ARGS=''
CURRENT_OPENSHIFT_RUN=${OCP_CLUSTER_VERSION-""}

OC_DIR_CORE=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 20 | head -n 1)
SUBDIR_ARG="-e work_subdir_name=oc-$OC_DIR_CORE"
echo "SUBDIR_ARG = $SUBDIR_ARG"

if [[ $TEST_MODE -ne 1  ]]; then
    #CURRENT_PATH=/go/src/github.com/redhat-openshift-ecosystem/community-operators-pipeline/scripts/ci
    CURRENT_PATH=$(pwd)
    if [ $(echo $CURRENT_PATH|grep operator-framework)  ]; then
         	TARGET_PATH=$(echo $CURRENT_PATH|sed -e 's/scripts\/ci/community-operators/g')
    else
                TARGET_PATH=$(echo $CURRENT_PATH|sed -e 's/scripts\/ci/operators/g')
    fi
fi
echo "TARGET_PATH=$TARGET_PATH"
export PR_TARGET_REPO=$(echo $TARGET_PATH|cut -d"/" -f 5-6)
echo "PR_TARGET_REPO=$PR_TARGET_REPO"

#label start
[[ $TEST_MODE -ne 1 ]] && curl -f -u framework-automation:$(cat /var/run/cred/framautom) \
-X POST \
-H "Accept: application/vnd.github.v3+json" \
"https://api.github.com/repos/$PR_TARGET_REPO/dispatches" --data "{\"event_type\": \"openshift-test-status\", \"client_payload\": {\"source_pr\": \"$PULL_NUMBER\", \"remove_labels\": [\"installation-validated$OCP_CLUSTER_VERSION_SUFFIX\", \"openshift-started$OCP_CLUSTER_VERSION_SUFFIX\", \"installation-failed$OCP_CLUSTER_VERSION_SUFFIX\", \"installation-validated\"], \"add_labels\": [\"openshift-started$OCP_CLUSTER_VERSION_SUFFIX\"]}}"

echo "OS"
cat /etc/os-release

pwd

#[[ $TEST_MODE -ne 1 ]] && TARGET_PATH='/go/src/github.com/operator-framework/community-operators/community-operators'


[[ $TEST_MODE -eq 1 ]] && TARGET_PATH='/tmp/oper-for-me-test/community-operators/community-operators'

#temp test for development to test on a stable commit
if [[ $TEST_MODE -eq 1 ]]; then
  echo "Need to clone test branch, cloning..."
  if [ -d /tmp/oper-for-me-test ]; then rm -Rf /tmp/oper-for-me-test; fi
  mkdir -p /tmp/oper-for-me-test
  cd /tmp/oper-for-me-test
  git clone $TEST_COMMUNITY_REPO
  cd community-operators
  git checkout $TEST_COMMUNITY_BRANCH
  ls
fi

##clone again to suppress caching during pr on ci-operator repo
#echo "Need to clone actual branch, cloning..."
#mkdir -p /tmp/oper-for-me-test
#cd /tmp/oper-for-me-test
#git clone https://github.com/$PR_TARGET_REPO.git
#cd community-operators
#ls
#TARGET_PATH='/tmp/oper-for-me-test/community-operators/community-operators'

#detection start
mkdir -p /tmp/jq-$OC_DIR_CORE/bin/
curl -L "https://github.com/stedolan/jq/releases/download/jq-$JQ_VERSION/jq-linux64" --output "/tmp/jq-$OC_DIR_CORE/bin/jq" #&& echo "jq $JQ_VERSION downloaded"
chmod +x "/tmp/jq-$OC_DIR_CORE/bin/jq" && echo "Rights adjusted"

#detect allow/longer-deployment label
[[ $TEST_MODE -ne 1 ]] && curl -f -u framework-automation:$(cat /var/run/cred/framautom) \
-X GET \
-H "Accept: application/vnd.github.v3+json" \
"https://api.github.com/repos/$PR_TARGET_REPO/issues/$PULL_NUMBER"|"/tmp/jq-$OC_DIR_CORE/bin/jq" '.labels[].name'|grep 'allow/longer-deployment' \
&& echo "Longer deployment detected" && EXTRA_ARGS='-e pod_start_retries=300'
cd "$TARGET_PATH"
tmpfile=$(mktemp /tmp/pr-details-XXXXXXX.json)
curl -s https://api.github.com/repos/$PR_TARGET_REPO/pulls/$PULL_NUMBER -o $tmpfile
cat $tmpfile
REPO_FULL=$(cat $tmpfile | /tmp/jq-$OC_DIR_CORE/bin/jq -r '.head.repo.clone_url')
echo "REPO_FULL=$REPO_FULL"
BRANCH=$(cat $tmpfile | /tmp/jq-$OC_DIR_CORE/bin/jq -r '.head.ref')
echo "BRANCH=$BRANCH"
COMMIT=$(cat $tmpfile | /tmp/jq-$OC_DIR_CORE/bin/jq -r '.head.sha')
echo "COMMIT=$COMMIT"
REPO=$(echo "$REPO_FULL"| awk -F'https://github.com/' '{print $2}')
echo "REPO=$REPO"
QUAY_HASH=$(echo ${COMMIT::8})
echo "QUAY_HASH=$QUAY_HASH"
rm -f $tmpfile > /dev/null 2>&1

OPRT_REPO=${REPO_FULL-""}
OPRT_SHA=${COMMIT-""}
echo "OPRT_SHA=$OPRT_SHA"
OPRT_SRC_BRANCH=${OPRT_SRC_BRANCH-"main"}
export OPRT=1
echo "OPRT values set [OK]"
[ -n "$OPRT_REPO" ] || { echo "Error: '\$OPRT_REPO' is empty !!!"; exit 1; }
[ -n "$OPRT_SHA" ] || { echo "Error: '\$OPRT_SHA' is empty !!!"; exit 1; }
echo "Going to clone"
git clone $REPO_FULL community-operators #> /dev/null 2>&1
echo "Cloned  [OK]"
cd community-operators
echo "Dir entered  [OK]"
BRANCH_NAME=$(git branch -a --contains $OPRT_SHA | grep remotes/ | grep -v HEAD | cut -d '/' -f 2-)
echo "BRANCH_NAME=$BRANCH_NAME"
git checkout $BRANCH_NAME > /dev/null #2>&1
echo "Checkout  [OK]"
git log --oneline | head

git config --global user.email "test@example.com"
git config --global user.name "Test User"
echo "Git user configured  [OK]"

git remote add upstream https://github.com/$PR_TARGET_REPO -f > /dev/null 2>&1
echo "Remote added [OK]"

git pull --rebase -Xours upstream $OPRT_SRC_BRANCH
echo "Rebased  [OK]"

export OP_TEST_ADDED_FILES=$(git diff --diff-filter=A upstream/$OPRT_SRC_BRANCH --name-only | tr '\r\n' ' ')
echo "OP_TEST_ADDED_FILES exported  [OK]"
export OP_TEST_MODIFIED_FILES=$(git diff --diff-filter=M upstream/$OPRT_SRC_BRANCH --name-only | tr '\r\n' ' ')
echo "OP_TEST_MODIFIED_FILES exported  [OK]"
export OP_TEST_REMOVED_FILES=$(git diff --diff-filter=D upstream/$OPRT_SRC_BRANCH --name-only | tr '\r\n' ' ')
echo "OP_TEST_REMOVED_FILES exported  [OK]"
export OP_TEST_RENAMED_FILES=$(git diff --diff-filter=R upstream/$OPRT_SRC_BRANCH --name-only | tr '\r\n' ' ')
export OP_TEST_RENAMED_ADDED_MODIFIED_FILES=$(git diff --diff-filter=RAM upstream/$OPRT_SRC_BRANCH --name-only | tr '\r\n' ' ')
echo "OP_TEST_RENAMED_ADDED_MODIFIED_FILES: $OP_TEST_RENAMED_ADDED_MODIFIED_FILES"
echo "All exported [OK]"
BRANCH_NAME=$(echo $BRANCH_NAME | cut -d '/' -f 2-)
echo "BRANCH_NAME=$BRANCH_NAME"

#deleted only
[ -n "$OP_TEST_REMOVED_FILES" ] && [ -z "$OP_TEST_RENAMED_ADDED_MODIFIED_FILES" ] && echo "Nothing to test - [OK]" && echo "only deleted files detected:" && echo ${OP_TEST_REMOVED_FILES[@]} && curl -f -u framework-automation:$(cat /var/run/cred/framautom) -X POST -H "Accept: application/vnd.github.v3+json" https://api.github.com/repos/$PR_TARGET_REPO/dispatches --data "{\"event_type\": \"openshift-test-status\", \"client_payload\": {\"source_pr\": \"$PULL_NUMBER\", \"remove_labels\": [\"openshift-started$OCP_CLUSTER_VERSION_SUFFIX\", \"installation-validated$OCP_CLUSTER_VERSION_SUFFIX\"], \"add_labels\": [\"installation-validated$OCP_CLUSTER_VERSION_SUFFIX\"]}}" && exit 0;
echo "Looping"
for sf in ${OP_TEST_RENAMED_ADDED_MODIFIED_FILES[@]}; do
  echo $sf
  OP_STREAM_DIR="$(echo "$sf" | awk -F'/' '{ print $1 }')"
  # make green when PR from maintainers targeting CI
  if [[ "$OP_STREAM_DIR" != "operators" ]]; then
    curl -f -u framework-automation:$(cat /var/run/cred/framautom) \
    -X POST \
    -H "Accept: application/vnd.github.v3+json" \
    "https://api.github.com/repos/$PR_TARGET_REPO/dispatches" --data "{\"event_type\": \"openshift-test-status\", \"client_payload\": {\"source_pr\": \"$PULL_NUMBER\", \"remove_labels\": [\"openshift-started$OCP_CLUSTER_VERSION_SUFFIX\", \"installation-validated$OCP_CLUSTER_VERSION_SUFFIX\"]}}"
    echo "Running operator deployment on an Openshift is not relevant for the affected commit. Found changes outside Openshift operators, exiting."
    exit 0;
  fi

  if [ $(echo $sf| awk -F'/' '{print NF}') -ge 4 ]; then
      OP_NAME="$(echo "$sf" | awk -F'/' '{ print $2 }')"
      OP_VER="$(echo "$sf" | awk -F'/' '{ print $3 }')"
  fi
done
echo "Loop ended  [OK]"
echo
echo "OP_NAME=$OP_NAME"
echo "OP_VER=$OP_VER"

#[ -n "$OP_NAME" ] || { echo "Error: '\$OP_NAME' is empty !!!"; exit 1; }
[ -n "$OP_NAME" ] || { echo "Nothing to test, no community operator modified - [OK]"  && curl -f -u framework-automation:$(cat /var/run/cred/framautom) -X POST -H "Accept: application/vnd.github.v3+json" "https://api.github.com/repos/$PR_TARGET_REPO/dispatches" --data "{\"event_type\": \"openshift-test-status\", \"client_payload\": {\"source_pr\": \"$PULL_NUMBER\", \"remove_labels\": [\"openshift-started$OCP_CLUSTER_VERSION_SUFFIX\", \"installation-validated$OCP_CLUSTER_VERSION_SUFFIX\", \"installation-failed$OCP_CLUSTER_VERSION_SUFFIX\"], \"add_labels\": [\"installation-validated$OCP_CLUSTER_VERSION_SUFFIX\"]}}" && exit 0; }
[ -n "$OP_VER" ] || { echo "Error: '\$OP_VER' is empty !!!"; exit 1; }

#detection end

#test
#OP_NAME=aqua
#OP_VER=1.0.2
#COMMIT=1234
#echo "Forced specific operator - $OP_NAME $OP_VER $COMMIT"

#prepare temp index
echo "Preparing temp index ..."
[[ $TEST_MODE -ne 1 ]] && OP_TOKEN=$(cat /var/run/cred/op_token_quay_test)
echo
[[ $TEST_MODE -ne 1 ]] && curl -f -u framework-automation:$(cat /var/run/cred/framautom) \
-X POST \
-H "Accept: application/vnd.github.v3+json" \
"https://api.github.com/repos/$PR_TARGET_REPO/dispatches" --data "{\"event_type\": \"index-for-openshift-test\", \"client_payload\": {\"source_pr\": \"$PULL_NUMBER\"}}"  && echo "Temp index initiated ..."
echo "Temp index triggered [OK]"
CHECK_TEMP_INDEX=1
while [ "$CHECK_TEMP_INDEX" -le "$MAX_LIMIT_FOR_INDEX_WAIT" ]; do
  echo "Checking index $QUAY_HASH presence ... $CHECK_TEMP_INDEX minutes."
  if [ $(curl -s 'https://quay.io/v2/operator_testing/catalog/tags/list'|grep $QUAY_HASH) ]; then
   echo "Temp index $QUAY_HASH found."
   break
  elif [ "$CHECK_TEMP_INDEX" -eq "$MAX_LIMIT_FOR_INDEX_WAIT" ]; then
    echo
    echo
    echo "Temp index not found. Are your commits squashed? If so, please check logs https://github.com/$PR_TARGET_REPO/actions?query=workflow%3Aprepare-test-index"
    echo
    echo
    exit 1
  fi
  sleep 60s
  CHECK_TEMP_INDEX=$(($CHECK_TEMP_INDEX + 1))
done

#deploy start
echo "Starting deployment ..."
if [ -d /tmp/playbooks2 ]; then rm -Rf /tmp/playbooks2; fi
mkdir -p /tmp/playbooks2
cd /tmp/playbooks2
echo "We are in dir"
[[ $TEST_MODE -ne 1 ]] && git clone https://github.com/operator-framework/operator-test-playbooks.git
[[ $TEST_MODE -eq 1 ]] && git clone $TEST_PB_REPO
cd operator-test-playbooks
[[ $TEST_MODE -eq 1 ]] && git checkout $TEST_PB_BRANCH
cd upstream
echo "Config ..."
export ANSIBLE_CONFIG=/tmp/playbooks2/operator-test-playbooks/upstream/ansible.cfg
set +e
echo "Ansible initiated"
ANSIBLE_STDOUT_CALLBACK=yaml ansible-playbook -i localhost, deploy-olm-operator-openshift-upstream.yml -e ansible_connection=local -e package_name=$OP_NAME -e operator_dir=$TARGET_PATH/$OP_NAME -e op_version=$OP_VER -e oc_bin_path="/tmp/oc-$OC_DIR_CORE/bin/oc" -e commit_tag=$QUAY_HASH -e dir_suffix_part=$OC_DIR_CORE -e current_openshift_run=$CURRENT_OPENSHIFT_RUN $SUBDIR_ARG $EXTRA_ARGS -vv
ANSIBLE_STATUS=$?
echo "Reporting ..."
[[ $TEST_MODE -ne 1 ]] && if [ $ANSIBLE_STATUS -eq 0 ]; then
  curl -f -u framework-automation:$(cat /var/run/cred/framautom) \
  -X POST \
  -H "Accept: application/vnd.github.v3+json" \
  "https://api.github.com/repos/$PR_TARGET_REPO/dispatches" --data "{\"event_type\": \"openshift-test-status\", \"client_payload\": {\"source_pr\": \"$PULL_NUMBER\", \"remove_labels\": [\"openshift-started$OCP_CLUSTER_VERSION_SUFFIX\", \"installation-failed$OCP_CLUSTER_VERSION_SUFFIX\", \"installation-validated\"], \"add_labels\": [\"installation-validated$OCP_CLUSTER_VERSION_SUFFIX\"]}}"
else
  curl -f -u framework-automation:$(cat /var/run/cred/framautom) \
  -X POST \
  -H "Accept: application/vnd.github.v3+json" \
  "https://api.github.com/repos/$PR_TARGET_REPO/dispatches" --data "{\"event_type\": \"openshift-test-status\", \"client_payload\": {\"source_pr\": \"$PULL_NUMBER\", \"remove_labels\": [\"openshift-started$OCP_CLUSTER_VERSION_SUFFIX\", \"installation-validated$OCP_CLUSTER_VERSION_SUFFIX\", \"installation-validated\"], \"add_labels\": [\"installation-failed$OCP_CLUSTER_VERSION_SUFFIX\"]}}"
fi

echo "Variable summary:"
echo "OP_NAME=$OP_NAME"
echo "OP_VER=$OP_VER"

if [ $ANSIBLE_STATUS -gt 0 ]; then echo "Ansible failed, see output above"; exit 1; fi
