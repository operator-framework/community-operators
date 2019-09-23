FROM quay.io/operator-framework/operator-testing:base

COPY ./utils/entrypoint.sh /entrypoint.sh
COPY . /scripts/
RUN mv /scripts/utils/Makefile /
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
CMD []