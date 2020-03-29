FROM registry.access.redhat.com/ubi8/ubi-minimal
USER root

RUN microdnf update -y && rm -rf /var/cache/yum

RUN microdnf -y install \
    python3 \
    python3-pip \
    make \
    curl \
    bash \
<<<<<<< HEAD
    findutils \
=======
>>>>>>> e29e137... rebase to UBI8 minimal
    && microdnf clean all

COPY . /scripts/

RUN rm -rf /Makefile && mv /scripts/utils/Makefile /

ENV INSTALL_DEPS=1
RUN python3 /scripts/utils/check-deps.py

COPY ./utils/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
CMD []
