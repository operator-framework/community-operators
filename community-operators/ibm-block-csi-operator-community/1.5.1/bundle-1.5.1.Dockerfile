FROM scratch

LABEL operators.operatorframework.io.bundle.channel.default.v1="maintenance-1.5"
LABEL operators.operatorframework.io.bundle.channels.v1="maintenance-1.5"
LABEL operators.operatorframework.io.bundle.manifests.v1=manifests/
LABEL operators.operatorframework.io.bundle.mediatype.v1=registry+v1
LABEL operators.operatorframework.io.bundle.metadata.v1=metadata/
LABEL operators.operatorframework.io.bundle.package.v1=ibm-block-csi-operator-community

COPY manifests /manifests/
COPY metadata /metadata/
LABEL com.redhat.openshift.versions="v4.6-v4.7"
LABEL com.redhat.delivery.operator.bundle=true
LABEL com.redhat.delivery.backport=true
