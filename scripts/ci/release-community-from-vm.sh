#!/usr/bin/env bash

#add to cron
#0 1,3,5,7,9,11,13,15,17,19,21,23 * * * /home/ubuntu/release-community.sh>>/tmp/community.log 2>&1
#0 0,2,4,6,8,10,12,14,16,18,20,22 * * * /home/ubuntu/release-upstream.sh>>/tmp/upstream.log 2>&1

export PATH="/usr/local/bin:$PATH"
export KIND_VER=v0.8.1
export KUBE_VER=v1.18.2
export OLM_VER=0.15.1
export SDK_VER=v0.16.0
export DISTRO_TYPE=upstream
export PLAYBOOK_VARS="-i localhost, local.yml -e kind_version=v0.8.1 -e kind_kube_ver=v1.18.2 -e olm_ver=0.15.1 -e operator_sdk_version=v0.16.0 -e ansible_connection=local -e run_remove_catalog_repo=false"
export PLAYBOOK_REPO=https://github.com/J0zi/operator-test-playbooks
export PLAYBOOK_BRANCH='sprint-8' #check if correct
export ANSIBLE_STDOUT_CALLBACK=yaml
export AUTOMATION_TOKEN_RELEASE_COMMUNITY='please-fill'
echo '************************ community starting *******************************'
date
#/etc/sudo pip install ansible jmespath
#mkdir -p /tmp/oper


rm -rf /tmp/oper-c/*
cd /tmp/oper-c
git clone https://github.com/operator-framework/community-operators.git
pwd
cd community-operators
ls
scripts/ci/run-release -c
echo '********* finished *******'
