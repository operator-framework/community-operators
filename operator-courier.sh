#!/bin/bash

export OPERATOR_DIR=tidb-operator/
export QUAY_NAMESPACE=cofyc
export PACKAGE_NAME=tidb-operator
export PACKAGE_VERSION=1.1.2
# https://github.com/operator-framework/operator-courier#authentication
export TOKEN="basic Y29meWM6Y2xPYWI2aGVrMA=="

for d in community-operators  upstream-community-operators ; do
    echo docker run -v `pwd`:`pwd` -w `pwd` tufin/operator-courier operator-courier verify $d/tidb-operator
done
# docker run -v `pwd`:`pwd` -w `pwd` tufin/operator-courier operator-courier push "$OPERATOR_DIR" "$QUAY_NAMESPACE" "$PACKAGE_NAME" "$PACKAGE_VERSION" "$TOKEN"
