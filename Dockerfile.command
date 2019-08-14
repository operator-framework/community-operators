FROM sebastiansimko/operator-command-base:latest

COPY scripts/utils/entrypoint.sh /entrypoint.sh
COPY . /
RUN mv /scripts/utils/Makefile /
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
CMD []