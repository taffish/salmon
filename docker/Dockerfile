FROM debian:13-slim@sha256:d7e12182ce18b85b93007c1dedf31f2d29e01ccf3182cc4017c709b6259bc132 AS fetcher

ARG BUILDARCH
ARG TARGETARCH
ARG SALMON_VERSION=2.8.0
ARG SALMON_COMMIT=ed926b8f6120c592ba13e696fe24732004ee0132
ARG SALMON_X86_64_SHA256=10a7f7994df7ef0592ac191cc79a1abd41316463000b307647a9dcab21e1efa6
ARG SALMON_AARCH64_SHA256=3b2bf20b7a87c8207e83debd7aa0a6fefa85fb3b211ca069a394584dee1025c3
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
    mkdir -p /opt/salmon/share; \
    printf '%s\n' \
      "upstream=COMBINE-lab/salmon" \
      "version=${SALMON_VERSION}" \
      "commit=${SALMON_COMMIT}" \
      "asset=${salmon_asset}" \
      "sha256=${salmon_sha256}" \
      "targetarch=${TARGETARCH}" \
      > /opt/salmon/share/source.txt; \
    grep -F "version=${SALMON_VERSION}" /opt/salmon/share/source.txt; \
    if [ -n "${BUILDARCH}" ] && [ "${BUILDARCH}" = "${TARGETARCH}" ]; then \
      test "$(/opt/salmon/salmon --version)" = "salmon ${SALMON_VERSION}"; \
    else \
      echo "cross-architecture fetch: skip target binary execution (${BUILDARCH:-unknown} -> ${TARGETARCH})"; \
    fi

FROM debian:13-slim@sha256:d7e12182ce18b85b93007c1dedf31f2d29e01ccf3182cc4017c709b6259bc132

ARG BUILDARCH
ARG TARGETARCH
ARG SALMON_VERSION=2.8.0
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
COPY docker/piscem-v2.rad /opt/salmon/share/piscem-v2.rad

RUN set -eux; \
    ln -sf /opt/salmon/salmon /usr/local/bin/salmon; \
    chmod 0755 /opt/salmon/share/salmon-smoke.sh; \
    chmod 0644 /opt/salmon/share/piscem-v2.rad

RUN set -eux; \
    grep -F "version=${SALMON_VERSION}" /opt/salmon/share/source.txt; \
    grep -F "targetarch=${TARGETARCH}" /opt/salmon/share/source.txt; \
    if [ -n "${BUILDARCH}" ] && [ "${BUILDARCH}" = "${TARGETARCH}" ]; then \
      SALMON_SMOKE_VERSION="${SALMON_VERSION}" \
          sh /opt/salmon/share/salmon-smoke.sh buildtime; \
    else \
      echo "cross-architecture final image: defer runtime smoke (${BUILDARCH:-unknown} -> ${TARGETARCH})"; \
    fi

WORKDIR /tmp
