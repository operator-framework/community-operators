FROM sebastiansimko/operator-command-base:latest

COPY scripts/utils/entrypoint.sh scripts/utils/entrypoint.sh
COPY scripts/ci/check-kubeconfig scripts/ci/check-kubeconfig
RUN chmod +x ./scripts/utils/entrypoint.sh
ENTRYPOINT ["./scripts/utils/entrypoint.sh"]
CMD []