FROM debian:13-slim AS fetcher

ARG TARGETARCH
ARG SALMON_VERSION=2.4.1
ARG SALMON_X86_64_SHA256=882717ae835fdc6b8676f457a989a3d354a69adb3d7cab0051d21e2e4e1eaf40
ARG SALMON_AARCH64_SHA256=af8854b208082198aff13879ca69938cfe215e928289de948a802aa7c566efc8
ARG DEBIAN_FRONTEND=noninteractive
ARG APT_MIRROR=http://deb.debian.org/debian
ARG APT_SECURITY_MIRROR=http://deb.debian.org/debian-security

RUN set -eux; \
    sed -i \
      -e "s|http://deb.debian.org/debian|${APT_MIRROR}|g" \
      -e "s|http://deb.debian.org/debian-security|${APT_SECURITY_MIRROR}|g" \
      /etc/apt/sources.list.d/debian.sources; \
    for attempt in 1 2 3; do \
      apt-get update && \
      apt-get install -y --no-install-recommends ca-certificates curl xz-utils && \
      break; \
      if [ "${attempt}" = "3" ]; then exit 1; fi; \
      rm -rf /var/lib/apt/lists/*; \
      sleep 2; \
    done; \
    rm -rf /var/lib/apt/lists/*

WORKDIR /tmp/build

RUN set -eux; \
    case "${TARGETARCH}" in \
      amd64) \
        salmon_arch="x86_64-unknown-linux-gnu"; \
        salmon_sha256="${SALMON_X86_64_SHA256}"; \
        ;; \
      arm64) \
        salmon_arch="aarch64-unknown-linux-gnu"; \
        salmon_sha256="${SALMON_AARCH64_SHA256}"; \
        ;; \
      *) \
        echo "unsupported TARGETARCH=${TARGETARCH}" >&2; \
        exit 1; \
        ;; \
    esac; \
    salmon_asset="salmon-cli-${salmon_arch}.tar.xz"; \
    curl -fsSL --retry 3 --retry-all-errors --connect-timeout 30 \
      -o /tmp/salmon.tar.xz \
      "https://github.com/COMBINE-lab/salmon/releases/download/v${SALMON_VERSION}/${salmon_asset}"; \
    echo "${salmon_sha256}  /tmp/salmon.tar.xz" | sha256sum -c -; \
    mkdir -p /opt/salmon; \
    tar -xJf /tmp/salmon.tar.xz -C /opt/salmon --strip-components=1; \
    test -x /opt/salmon/salmon; \
    test "$(/opt/salmon/salmon --version)" = "salmon ${SALMON_VERSION}"

FROM debian:13-slim

ARG SALMON_VERSION=2.4.1
ARG DEBIAN_FRONTEND=noninteractive
ARG APT_MIRROR=http://deb.debian.org/debian
ARG APT_SECURITY_MIRROR=http://deb.debian.org/debian-security

ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8
ENV TAFFISH_ENV=TAFFISH
ENV TAFFISH_NAME=salmon

RUN set -eux; \
    sed -i \
      -e "s|http://deb.debian.org/debian|${APT_MIRROR}|g" \
      -e "s|http://deb.debian.org/debian-security|${APT_SECURITY_MIRROR}|g" \
      /etc/apt/sources.list.d/debian.sources; \
    for attempt in 1 2 3; do \
      apt-get update && \
      apt-get install -y --no-install-recommends \
        ca-certificates \
        libgcc-s1 \
        procps && \
      break; \
      if [ "${attempt}" = "3" ]; then exit 1; fi; \
      rm -rf /var/lib/apt/lists/*; \
      sleep 2; \
    done; \
    rm -rf /var/lib/apt/lists/*

COPY --from=fetcher /opt/salmon /opt/salmon
COPY docker/salmon-smoke.sh /opt/salmon/share/salmon-smoke.sh

RUN set -eux; \
    ln -sf /opt/salmon/salmon /usr/local/bin/salmon; \
    chmod 0755 /opt/salmon/share/salmon-smoke.sh

RUN set -eux; \
    SALMON_SMOKE_VERSION="${SALMON_VERSION}" \
        sh /opt/salmon/share/salmon-smoke.sh buildtime

WORKDIR /root
