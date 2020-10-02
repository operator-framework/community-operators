FROM golang:1.13.12-alpine3.12 as registry_builder

RUN apk --no-cache add \
    git \
    make \
    sqlite \
    gcc \
    libc-dev

ENV REGISTRY_TAG v1.14.3

WORKDIR /src

RUN git clone https://github.com/operator-framework/operator-registry.git /tmp/registry \
    && cd /tmp/registry \
    && git reset --hard ${REGISTRY_TAG} \
    && mv vendor cmd pkg Makefile go.mod go.sum /src \
    && cd /src \
    && make build

# copy and build vendored grpc_health_probe
RUN mkdir -p /go/src/github.com/grpc-ecosystem && \
    cp -R vendor/github.com/grpc-ecosystem/grpc-health-probe /go/src/github.com/grpc-ecosystem/grpc_health_probe && \
    cp -R vendor/ /go/src/github.com/grpc-ecosystem/grpc_health_probe && \
    cd /go/src/github.com/grpc-ecosystem/grpc_health_probe && \
    CGO_ENABLED=0 go install -a -tags netgo -ldflags "-w"

FROM alpine:3.12 as bundles_builder

WORKDIR /registry

COPY --from=registry_builder /src/bin/ /usr/local/bin
COPY upstream-community-operators manifests

RUN initializer --permissive -o ./bundles.db

# Final runtime image
FROM alpine:3.12

WORKDIR /registry

COPY --from=registry_builder /src/bin/registry-server /usr/local/bin
COPY --from=registry_builder /go/bin/grpc-health-probe /usr/local/bin/
COPY --from=bundles_builder /registry/bundles.db /registry/bundles.db

RUN chgrp -R 0 /registry && \
    chgrp -R 0 /dev && \
    chmod -R g+rwx /registry && \
    chmod -R g+rwx /dev && \
    touch /etc/nsswitch.conf

# This image doesn't need to run as root user
USER 1001

EXPOSE 50051
ENTRYPOINT ["/usr/local/bin/registry-server"]
CMD ["--database", "/registry/bundles.db"]
