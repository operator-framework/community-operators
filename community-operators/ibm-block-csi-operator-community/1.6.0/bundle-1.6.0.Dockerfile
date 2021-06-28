FROM scratch

LABEL operators.operatorframework.io.bundle.channel.default.v1=stable
LABEL operators.operatorframework.io.bundle.channels.v1=stable
LABEL operators.operatorframework.io.bundle.manifests.v1=manifests/
LABEL operators.operatorframework.io.bundle.mediatype.v1=registry+v1
LABEL operators.operatorframework.io.bundle.metadata.v1=metadata/
LABEL operators.operatorframework.io.bundle.package.v1=ibm-block-csi-operator

COPY manifests /manifests/
COPY metadata /metadata/
LABEL com.redhat.openshift.versions="v4.7,v4.8"
LABEL com.redhat.delivery.operator.bundle=true
