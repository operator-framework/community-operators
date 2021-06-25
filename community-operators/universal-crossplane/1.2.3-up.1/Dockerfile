FROM scratch

LABEL com.redhat.component="universal-crossplane"
LABEL com.redhat.delivery.backport="false"
LABEL com.redhat.delivery.operator.bundle="true"
LABEL com.redhat.openshift.versions="v4.6"
LABEL description="Upbound Universal Crossplane (UXP) is Upbound's official enterprise-grade distribution of Crossplane."
LABEL io.k8s.display-name="universal-crossplane"
LABEL io.openshift.tags="uxp,crossplane,upbound"
LABEL maintainer="Upbound Inc. <info@upbound.io>"
LABEL name="universal-crossplane"
LABEL ocs.tags="v4.6"
LABEL operators.operatorframework.io.bundle.channel.default.v1="stable"
LABEL operators.operatorframework.io.bundle.channels.v1="stable"
LABEL operators.operatorframework.io.bundle.manifests.v1="manifests/"
LABEL operators.operatorframework.io.bundle.mediatype.v1="registry+v1"
LABEL operators.operatorframework.io.bundle.metadata.v1="metadata/"
LABEL operators.operatorframework.io.bundle.package.v1="universal-crossplane"
LABEL summary="Upbound Universal Crossplane (UXP) is Upbound's official enterprise-grade distribution of Crossplane."

COPY manifests /manifests/
COPY metadata /metadata/
