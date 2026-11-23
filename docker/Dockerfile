# Both stages pin the multi-platform Debian base. APT mirrors and release asset URLs
# are external: if a fetch fails, check the source/architecture and checksum first;
# do not silently substitute another binary, package revision or upstream version.
FROM debian:13-slim@sha256:d7e12182ce18b85b93007c1dedf31f2d29e01ccf3182cc4017c709b6259bc132 AS fetcher

ARG BUILDARCH
ARG TARGETARCH
ARG SALMON_VERSION=2.12.0
ARG SALMON_COMMIT=d71d1331371d29073006220369cbc48ff1802040
ARG SALMON_X86_64_SHA256=44f02f8cca063f68ffd978e948912e942716f37cb59acbce85de39e1e1f38f95
ARG SALMON_AARCH64_SHA256=c7d10d11a6246c8d33a25e28ad0848485338ba45576b2e94374a8efd62334e19
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
    chmod 0755 /opt/salmon /opt/salmon/share /opt/salmon/salmon; \
    chmod 0644 /opt/salmon/LICENSE /opt/salmon/README.md /opt/salmon/share/source.txt

FROM debian:13-slim@sha256:d7e12182ce18b85b93007c1dedf31f2d29e01ccf3182cc4017c709b6259bc132

ARG BUILDARCH
ARG TARGETARCH
ARG SALMON_VERSION=2.12.0
ARG DEBIAN_FRONTEND=noninteractive
ARG APT_MIRROR=http://deb.debian.org/debian
ARG APT_SECURITY_MIRROR=http://deb.debian.org/debian-security

ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8
ENV TAFFISH_ENV=TAFFISH
ENV TAFFISH_NAME=salmon
ENV TAFFISH_VERSION=${SALMON_VERSION}
ENV TAFFISH_RELEASE=1

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
