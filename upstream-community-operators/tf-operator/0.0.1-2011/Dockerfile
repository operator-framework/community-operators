FROM scratch

LABEL name="TF operator" \
maintainer="Tungsten Fabric" \
vendor="Tungsten Fabric" \
version="0.0.1-2011" \
release="0.0.1-2011" \
summary="Tungsten Fabric SDN operator" \
description="This operator will deploy and manage Tungsten Fabric to the cluster"

LABEL operators.operatorframework.io.bundle.mediatype.v1=registry+v1
LABEL operators.operatorframework.io.bundle.manifests.v1=manifests/
LABEL operators.operatorframework.io.bundle.metadata.v1=metadata/
LABEL operators.operatorframework.io.bundle.package.v1=tf-operator
LABEL operators.operatorframework.io.bundle.channels.v1=stable
LABEL operators.operatorframework.io.bundle.channel.default.v1=stable

COPY manifests /manifests/
COPY metadata/annotations.yaml /metadata/annotations.yaml
