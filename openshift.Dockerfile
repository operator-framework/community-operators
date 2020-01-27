FROM openshift/origin-release:golang-1.12

RUN yum update -y \
    && yum install -y make git sqlite glibc-static openssl-static zlib-static \
    && yum groupinstall -y "Development Tools" "Development Libraries"

ENV GOPATH /go
ENV PATH $GOPATH/bin:/usr/local/go/bin:$PATH
ENV REGISTRY_TAG v1.5.6

WORKDIR /src

RUN git clone https://github.com/operator-framework/operator-registry.git /tmp/registry \
    && cd /tmp/registry \
    && git reset --hard ${REGISTRY_TAG} \
    && mv vendor cmd pkg Makefile go.mod go.sum /src \
    && cd /src \
    && make build \
    && rm -rd /tmp/registry

# copy and build vendored grpc_health_probe
RUN mkdir -p /go/src/github.com/grpc-ecosystem && \
    cp -R vendor/github.com/grpc-ecosystem/grpc-health-probe /go/src/github.com/grpc-ecosystem/grpc_health_probe && \
    cp -R vendor/ /go/src/github.com/grpc-ecosystem/grpc_health_probe && \
    cd /go/src/github.com/grpc-ecosystem/grpc_health_probe && \
    CGO_ENABLED=0 go install -a -tags netgo -ldflags "-w"

RUN mv /src/bin/initializer /bin/initializer \
    && mv /src/bin/registry-server /bin/registry-server \
    && mv /src/bin/configmap-server /bin/configmap-server \
    && mv /src/bin/appregistry-server /bin/appregistry-server \
    && mv /go/bin/grpc_health_probe /bin/grpc_health_probe

RUN mkdir /registry
WORKDIR /registry

COPY upstream-community-operators manifests

RUN /bin/initializer --permissive -o ./bundles.db

RUN chgrp -R 0 /registry && \
    chgrp -R 0 /dev && \
    chmod -R g+rwx /registry && \
    chmod -R g+rwx /dev

# This image doesn't need to run as root user
USER 1001

EXPOSE 50051
ENTRYPOINT ["/bin/registry-server"]
CMD ["--database", "/registry/bundles.db"]
