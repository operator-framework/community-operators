#!/usr/bin/env bash
#This scripts is configured in https://github.com/openshift/release/tree/master/ci-operator/config/operator-framework/community-operators and executed from ci-operator/jobs

set -e #fail in case of non zero return

JQ_VERSION='1.6'
MAX_LIMIT_FOR_INDEX_WAIT=20
EXTRA_ARGS=''

OC_DIR_CORE=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 20 | head -n 1)
SUBDIR_ARG="-e work_subdir_name=oc-$OC_DIR_CORE"
echo "SUBDIR_ARG = $SUBDIR_ARG"

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
pwd
COMMIT=$(git --no-pager log -n1 --pretty=format:%h | tail -n 1)
echo
echo "Target commit $COMMIT"

echo "git log:"
git --no-pager log --oneline|head
echo
echo "Source commit details:"
git --no-pager log -m -1 --name-only --first-parent $COMMIT
QUAY_HASH=$(git --no-pager log -m -1 --name-only --first-parent $COMMIT|head -n 2|grep 'Merge: '|awk '{print $3}')

declare -A CHANGED_FILES
##community only
echo "changed community files:"
CHANGED_FILES=$(git --no-pager log -m -1 --name-only --first-parent $COMMIT|grep -v 'upstream-community-operators/'|grep 'community-operators/') || { echo '******* No community operator (Openshift) modified, no reason to deploy on Openshift *******'; exit 0; }
echo

for sf in ${CHANGED_FILES[@]}; do
  echo $sf
  if [ $(echo $sf| awk -F'/' '{print NF}') -ge 4 ]; then
      OP_NAME="$(echo "$sf" | awk -F'/' '{ print $2 }')"
      OP_VER="$(echo "$sf" | awk -F'/' '{ print $3 }')"
  fi
done
echo
echo "OP_NAME=$OP_NAME"
echo "OP_VER=$OP_VER"

#detection end

#test
#OP_NAME=aqua
#OP_VER=1.0.2
#COMMIT=1234
#echo "Forced specific operator - $OP_NAME $OP_VER $COMMIT"

cd aqua

OP_TOKEN=$(cat /var/run/cred/op_token_quay_test)
echo
curl -f -u framework-automation:$(cat /var/run/cred/framautom) \
-X POST \
-H "Accept: application/vnd.github.v3+json" \
https://api.github.com/repos/operator-framework/community-operators/dispatches --data "{\"event_type\": \"index-for-openshift-test\", \"client_payload\": {\"op_token\": \"$OP_TOKEN\", \"source_pr\": \"$PULL_NUMBER\"}}"

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


#export OP_STREAM=community-operators
#export OP_VERSION=$OP_VER
#export OP_NAME=$OP_NAME
#export OP_OSR_HAH= #"quay.io/operator_testing|$OP_TOKEN|$COMMIT"
#export STORAGE_DRIVER=vfs
#bash <(curl -sL https://raw.githubusercontent.com/J0zi/operator-test-playbooks/upstream-community/test/osr_test.sh)
##solve secret or local registry (empty token)

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
fi

echo "Variable summary:"
echo "OP_NAME=$OP_NAME"
echo "OP_VER=$OP_VER"
