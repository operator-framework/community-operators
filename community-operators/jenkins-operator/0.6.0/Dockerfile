FROM scratch

LABEL com.redhat.delivery.operator.bundle=true
LABEL com.redhat.openshift.versions="v4.6"
LABEL com.redhat.delivery.backport=false

LABEL operators.operatorframework.io.bundle.mediatype.v1=registry+v1
LABEL operators.operatorframework.io.bundle.manifests.v1=manifests/
LABEL operators.operatorframework.io.bundle.metadata.v1=metadata/
LABEL operators.operatorframework.io.bundle.package.v1=jenkins-operator
LABEL operators.operatorframework.io.bundle.channels.v1=alpha
LABEL operators.operatorframework.io.bundle.channel.default.v1=alpha

LABEL com.redhat.component="jenkins-operator-bundle-container" 
LABEL name="jenkins-operator-bundle"
LABEL maintainer="openshift-dev-services+jenkins@redhat.com" 
LABEL version="0.6.0"
LABEL summary="Jenkins Operator bundle"
LABEL io.k8s.display-name="Jenkins Operator bundle" 
LABEL description="Jenkins Operator bundle for Jenkins Operator"

COPY ./manifests /manifests
COPY ./metadata/annotations.yaml /metadata/annotations.yaml