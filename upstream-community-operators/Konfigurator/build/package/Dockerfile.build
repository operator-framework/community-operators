FROM stakater/go-dep:1.9.3
MAINTAINER "Stakater Team"

RUN apk update

ARG PROJECT_NAME="Konfigurator"

RUN apk -v --update \
    add git build-base && \
    rm -rf /var/cache/apk/* && \
    mkdir -p "$GOPATH/src/github.com/stakater/${PROJECT_NAME}"

ADD . "$GOPATH/src/github.com/stakater/${PROJECT_NAME}"

ARG REPO_PATH="github.com/stakater/${PROJECT_NAME}"
ARG BUILD_PATH="${REPO_PATH}/cmd/${PROJECT_NAME}"

RUN cd "$GOPATH/src/github.com/stakater/${PROJECT_NAME}" && \
    dep ensure -v && \
    CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -a --installsuffix cgo --ldflags="-s" -o /${PROJECT_NAME} ${BUILD_PATH}

COPY build/package/Dockerfile.run /

# Running this image produces a tarball suitable to be piped into another
# Docker build command.
CMD tar -cf - -C / Dockerfile.run Konfigurator
