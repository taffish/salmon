FROM debian:13-slim AS fetcher

ARG TARGETARCH
ARG SALMON_VERSION=2.3.3
ARG SALMON_X86_64_SHA256=cdcc8469fb759ff55d30a3f71239c90cb6aec7433b99bd92ee111e49bf3dfb6e
ARG SALMON_AARCH64_SHA256=1da8efa7baa1c6584bf9833a7a6d26925c722cb35fffe0415693a933d0eca93d
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

ARG SALMON_VERSION=2.3.3
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
        libgcc-s1 && \
      break; \
      if [ "${attempt}" = "3" ]; then exit 1; fi; \
      rm -rf /var/lib/apt/lists/*; \
      sleep 2; \
    done; \
    rm -rf /var/lib/apt/lists/*

COPY --from=fetcher /opt/salmon /opt/salmon

RUN set -eux; \
    ln -sf /opt/salmon/salmon /usr/local/bin/salmon

RUN set -eux; \
    command -v salmon >/dev/null; \
    command -v ldd >/dev/null; \
    command -v locale >/dev/null; \
    test "$(salmon --version)" = "salmon ${SALMON_VERSION}"; \
    salmon --help 2>&1 | grep -F "RNA-seq transcript quantification" >/dev/null; \
    if salmon --help 2>&1 | grep -F "(Rust port)"; then exit 1; fi; \
    if salmon --help 2>&1 | grep -F "alevin"; then exit 1; fi; \
    salmon --no-version-check --help 2>&1 | grep -F "no-op" >/dev/null; \
    salmon --no-version-check index --help 2>&1 | grep -F "Build a salmon index" >/dev/null; \
    salmon --no-version-check index --help 2>&1 | grep -F "sshashTmpDir" >/dev/null; \
    salmon --no-version-check index --help 2>&1 | grep -F "ramLimit" >/dev/null; \
    salmon --no-version-check quant --help 2>&1 | grep -F "Quantify transcript abundances" >/dev/null; \
    salmon --no-version-check quant --help 2>&1 | grep -F "writeRad" >/dev/null; \
    salmon --no-version-check quant --help 2>&1 | grep -F "deterministic" >/dev/null; \
    salmon --no-version-check quant --help 2>&1 | grep -F "annotation" >/dev/null; \
    salmon --no-version-check quant --help 2>&1 | grep -F "emAccel" >/dev/null; \
    salmon --no-version-check quant --help 2>&1 | grep -F "squarem" >/dev/null; \
    salmon --no-version-check quant --help 2>&1 | grep -F "daarem" >/dev/null; \
    salmon --no-version-check quantmerge --help 2>&1 | grep -F "Merge a column across multiple samples" >/dev/null; \
    salmon --no-version-check debug-map --help 2>&1 | grep -F "per-read best-mapping detail" >/dev/null; \
    ldd "$(command -v salmon)" > /tmp/salmon.ldd; \
    grep -F "libgcc_s.so" /tmp/salmon.ldd >/dev/null; \
    grep -F "libc.so" /tmp/salmon.ldd >/dev/null; \
    ! grep -F "not found" /tmp/salmon.ldd >/dev/null; \
    mkdir -p /tmp/taf-salmon-check; \
    cd /tmp/taf-salmon-check; \
    printf '>tx1\nACGTACGTACGTACGTACGTACGTACGTACGTACGTACGT\n>tx2\nTTTTGGGGCCCCAAAATTTTGGGGCCCCAAAATTTTGGGG\n' > transcripts.fa; \
    salmon --no-version-check index -t transcripts.fa -i idx -k 15 -p 1 >/tmp/taf-salmon-index.log 2>&1; \
    test -s idx/info.json; \
    test -s idx/index.ssi; \
    test -s idx/index.ctab; \
    grep -F "\"salmon_version\": \"${SALMON_VERSION}\"" idx/info.json >/dev/null; \
    grep -F '"index_version": 1' idx/info.json >/dev/null; \
    grep -F '"num_refs": 2' idx/info.json >/dev/null; \
    printf '@r1\nACGTACGTACGTACGTACGT\n+\nFFFFFFFFFFFFFFFFFFFF\n@r2\nTTTTGGGGCCCCAAAATTTT\n+\nFFFFFFFFFFFFFFFFFFFF\n@r3\nACGTACGTACGTACGTACGT\n+\nFFFFFFFFFFFFFFFFFFFF\n' > reads.fq; \
    salmon --no-version-check quant -i idx -l A -r reads.fq -o quant -p 1 --quiet >/tmp/taf-salmon-quant.log 2>&1; \
    test -s quant/quant.sf; \
    grep -F "Name" quant/quant.sf >/dev/null; \
    grep -F "tx1" quant/quant.sf >/dev/null; \
    grep -F "tx2" quant/quant.sf >/dev/null; \
    rm -rf /tmp/taf-salmon-check /tmp/salmon.ldd

WORKDIR /root
