FROM centos:centos8
USER root

RUN yum update -y && rm -rf /var/cache/yum

RUN yum -y install \
    python3 \
    python3-pip \
    make \
    curl \
    bash \
    && yum clean all

COPY . /scripts/

RUN rm -rf /Makefile && mv /scripts/utils/Makefile /

ENV INSTALL_DEPS=1
RUN python3 /scripts/utils/check-deps.py

COPY ./utils/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
CMD []
