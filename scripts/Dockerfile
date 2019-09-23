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

COPY . /scripts
RUN rm -rf /Makefile && mv /scripts/utils/Makefile /
ENV INSTALL_DEPS=1
RUN python3 /scripts/utils/check-deps.py
