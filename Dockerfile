FROM docker:18

RUN apk add --update \
    python3 \
    python3-dev \
    py3-pip \
    build-base \
    make \
    curl \
    bash \
  && rm -rf /var/cache/apk/*

COPY . .
RUN rm -rf /Makefile && mv /scripts/utils/Makefile /
RUN make dependencies.check INSTALL_DEPS=1
