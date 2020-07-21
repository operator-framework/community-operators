#!/bin/bash

# deploys operator in operator hub using quay.io
if [ -z "${QUAY_USERNAME}" ] || [ -z ${QUAY_PASSWORD} ]; then
  echo "QUAY_USERNAME and QUAY_PASSWORD environment variables must be set"
  exit 1
fi

if [ "$#" -lt 2 ]; then
  echo "Usage: $0 operator_name quay_namespace <package version>" >&2
  exit 2
fi

OPERATOR_NAME=$1
QUAY_NAMESPACE=$2
PACKAGE_VERSION=$3

OPERATOR_DIR=$PWD/$OPERATOR_NAME
PACKAGE_NAME=$( grep packageName $OPERATOR_DIR/$OPERATOR_NAME.package.yaml | cut -f2 -d:)
CURRENT_VERSION=$(grep currentCSV  $OPERATOR_DIR/$OPERATOR_NAME.package.yaml | cut -f2 -d: | cut -d. -f2-4 | tr -d v)

if [[ -z "${PACKAGE_VERSION}" ]]; then
  echo "PACKAGE_VERSION not passed as parameter: Using commit id as version"
  PACKAGE_VERSION="${CURRENT_VERSION}-commit-$(git rev-parse --short HEAD)" 
fi

QUAY_NAMESPACE=$2
QUAY_TOKEN=\"$(curl -sH "Content-Type: application/json" -XPOST https://quay.io/cnr/api/v1/users/login \
                   -d '{"user": {"username": "'"${QUAY_USERNAME}"'", "password": "'"${QUAY_PASSWORD}"'" } }' | jq -r .token )\"

echo Pushing operator $PACKAGE_NAME from $OPERATOR_DIR to quay.io/$QUAY_NAMESPACE/$PACKAGE_NAME:$PACKAGE_VERSION
eval operator-courier push "$OPERATOR_NAME" "$QUAY_NAMESPACE" "$PACKAGE_NAME" "$PACKAGE_VERSION" "$QUAY_TOKEN"
echo "Operator $OPERATOR_NAME succesfully pushed to quay.io/$QUAY_NAMESPACE/$OPERATOR_NAME:$PACKAGE_VERSION"
