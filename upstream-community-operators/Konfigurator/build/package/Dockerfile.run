FROM alpine:3.9
MAINTAINER "Stakater Team"

RUN apk add --update ca-certificates

COPY Konfigurator /bin/Konfigurator

ENTRYPOINT ["/bin/Konfigurator"]
