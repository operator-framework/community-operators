#!/usr/bin/env bash
#This scripts is configured in https://github.com/openshift/release/tree/master/ci-operator/config/operator-framework/community-operators and executed from ci-operator/jobs

set -e #fail in case of non zero return

OC_DIR_CORE=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 20 | head -n 1)
SUBDIR_ARG="-e work_subdir_name=oc-$OC_DIR_CORE"
echo "SUBDIR_ARG = $SUBDIR_ARG"

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

cd "$TARGET_PATH"
pwd
COMMIT=$(git --no-pager log -n1 --pretty=format:%h | tail -n 1)
echo
echo "Target commit $COMMIT"

echo "git log"
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

ls
cd aqua

podman --version
echo
/tmp/operator-test/bin/opm alpha bundle build --directory 1.0.2 --package aqua -t test/aqua -b podman|true
echo
/tmp/operator-test/bin/opm alpha bundle build --directory 1.0.2 --package aqua -t test/aqua -b buildah|true
echo
podman build -f ../jenkins-operator/0.6.0/Dockerfile community-operators/jenkins-operator/0.6.0|true
echo
buildah bud -f ../jenkins-operator/0.6.0/Dockerfile community-operators/jenkins-operator/0.6.0|true
echo
podman pull centos:8|true

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
ansible-pull -d /tmp/.ansible-pulled -vv -U https://github.com/J0zi/operator-test-playbooks -C RHO-716-deploy-on-openshift -vv -i localhost, deploy-olm-operator-openshift-upstream.yml -e ansible_connection=local -e package_name=$OP_NAME -e operator_dir=$TARGET_PATH/$OP_NAME -e op_version=$OP_VER -e oc_bin_path="/tmp/oc-$OC_DIR_CORE/bin/oc" -e commit_tag=$QUAY_HASH -e dir_suffix_part=$OC_DIR_CORE $SUBDIR_ARG
echo "Variable summary:"
echo "OP_NAME=$OP_NAME"
echo "OP_VER=$OP_VER"
