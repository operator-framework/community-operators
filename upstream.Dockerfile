FROM python:3 as builder

RUN pip3 install operator-courier==1.0.2

WORKDIR /usr/src
COPY upstream-community-operators /usr/src/upstream-community-operators
RUN for file in /usr/src/upstream-community-operators/*; do operator-courier nest $file /manifests/$(basename $file); done

FROM quay.io/openshift/origin-operator-registry:latest
COPY --from=builder /manifests manifests
RUN initializer
CMD ["registry-server"]

