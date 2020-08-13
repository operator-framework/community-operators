FROM quay.io/operator-framework/upstream-registry-builder:v1.13.3 as builder
ARG PERMISSIVE_LOAD=true
COPY upstream-community-operators manifests
RUN if [ $PERMISSIVE_LOAD = "true" ] ; then ./bin/initializer --permissive -o ./bundles.db ; else ./bin/initializer -o ./bundles.db ; fi 

FROM scratch
COPY --from=builder /build/bundles.db /bundles.db
COPY --from=builder /build/bin/registry-server /registry-server
COPY --from=builder /bin/grpc_health_probe /bin/grpc_health_probe
EXPOSE 50051
ENTRYPOINT ["/registry-server"]
CMD ["--database", "/bundles.db"]
