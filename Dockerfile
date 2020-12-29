ARG GO_VERSION=1.13.8

FROM quay.io/ibm/golang:1.15 AS build

ENV DISTRIBUTION_DIR /go/src/github.com/docker/distribution
ENV BUILDTAGS include_oss include_gcs

ARG GOOS=linux
ARG GOARM=6
ARG VERSION
ARG REVISION

RUN set -ex \
    && apk add --no-cache make git file

WORKDIR $DISTRIBUTION_DIR
COPY . $DISTRIBUTION_DIR
RUN CGO_ENABLED=0 make PREFIX=/go clean binaries && file ./bin/registry | grep "statically linked"

FROM quay.io/ibm/alpine:3.11

RUN set -ex \
    && apk add --no-cache ca-certificates apache2-utils

COPY cmd/registry/config-dev.yml /etc/docker/registry/config.yml
COPY --from=build /go/src/github.com/docker/distribution/bin/registry /bin/registry
VOLUME ["/var/lib/registry"]
EXPOSE 5000
ENTRYPOINT ["registry"]
CMD ["serve", "/etc/docker/registry/config.yml"]
