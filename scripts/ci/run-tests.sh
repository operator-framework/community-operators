#!/bin/bash
set -ev

eval $(scripts/ci/operators-env)
      
if [ -z "${OP_PATH}" ] ; 
then 
    echo "No operator modification detected. Exiting."
    exit 0 
else
    echo "Detected modified Operator in ${OP_PATH}"
    echo "Detected modified Operator version ${OP_VER}"
fi
      
make operator.verify OP_PATH="${OP_PATH}" OP_VER="${OP_VER}"
sudo make minikube.start VM_DRIVER=none 
sudo chown -R $USER ${HOME}/.{mini,}kube
kubectl config use-context minikube
make operator.test OP_PATH="${OP_PATH}" OP_VER="${OP_VER}" CLEAN_MODE=NORMAL INSTALL_MODE='' VERBOSE=1