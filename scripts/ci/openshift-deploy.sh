#!/usr/bin/env bash
set -e #fail in case of non zero return
#This scripts is configured in https://github.com/openshift/release/tree/master/ci-operator/config/operator-framework/community-operators and executed from ci-operator/jobs

export PATH=$PATH:/tmp/operator-test/bin
mkdir -p /tmp/operator-test/bin
curl https://mirror.openshift.com/pub/openshift-v4/clients/oc/4.6/linux/oc.tar.gz | tar xvzf - -C /tmp/operator-test/bin oc
chmod ug+x /tmp/operator-test/bin/oc
oc get pods --all-namespaces|grep -i olm

#temp test
echo "Need to clone test branch, cloning..."
mkdir -p /tmp/oper-for-me-test
cd /tmp/oper-for-me-test
git clone https://github.com/J0zi/community-operators.git
cd community-operators
git checkout oper-for-my-test
ls

#detection start

TARGET_PATH='/go/src/github.com/operator-framework/community-operators/community-operators'
#TODO: uncomment
#cd "$TARGET_PATH"
pwd
#TODO: check
COMMIT=$(git --no-pager log -n1 --format=format:"%H" | tail -n 1)
echo
echo "Target commit $COMMIT"

echo "git log"
git --no-pager log --oneline|head
echo
echo "Source commit details:"
git --no-pager log -m -1 --name-only --first-parent $COMMIT

declare -A CHANGED_FILES
##community only
echo "changed community files:"
CHANGED_FILES=$(git --no-pager log -m -1 --name-only --first-parent $COMMIT|grep -v 'upstream-community-operators/'|grep 'community-operators/')
echo
# shellcheck disable=SC2128
if [ -z "$CHANGED_FILES" ]; then
    echo "No community operator (Openshift) modified, no reason to deploy on Openshift"
    exit 0
fi

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
CSV_FILE="$(find $TARGET_PATH/$OP_NAME/$OP_VER -name "*${OP_VER}.clusterserviceversion.yaml" -type f -exec basename {} \; )"
echo "CSV_FILE=$CSV_FILE"

#detection end

mkdir -p /tmp/playbooks2
cd /tmp/playbooks2
ansible-pull -vv -U https://github.com/J0zi/operator-test-playbooks -C RHO-716-deploy-on-openshift -vv -i localhost, deploy-olm-operator-openshift-upstream.yml -e ansible_connection=local -e package_name=$OP_NAME -e csv_name=$CSV_FILE
echo "Variable summary:"
echo "OP_NAME=$OP_NAME"
echo "OP_VER=$OP_VER"
echo "CSV_FILE=$CSV_FILE"