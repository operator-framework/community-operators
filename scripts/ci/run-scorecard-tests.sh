#!/bin/bash

eval $(scripts/ci/operators-env)
      
if [ -z "${OP_PATH}" ] ; 
then 
    echo "No operator modification detected. Exiting."
    exit 0 
else
    echo "Detected modified Operator in ${OP_PATH}"
    echo "Detected modified Operator version ${OP_VER}"
fi
      
make operator.test OP_PATH="${OP_PATH}" OP_VER="${OP_VER}"