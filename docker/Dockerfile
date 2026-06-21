FROM debian:13-slim AS fetcher

ARG TARGETARCH
ARG SALMON_VERSION=2.1.1
ARG SALMON_X86_64_SHA256=184d87c5f376b33074e5d5a26538201d3ab13a9c7ea57c7862359b0c0d678d0e
ARG SALMON_AARCH64_SHA256=dea1432725e8530f90c75c0bcbbb8d7e88d145af23862aeecbbaa98bdb5f89fe
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
    curl -fsSL \
      -o /tmp/salmon.tar.xz \
      "https://github.com/COMBINE-lab/salmon/releases/download/v${SALMON_VERSION}/${salmon_asset}"; \
    echo "${salmon_sha256}  /tmp/salmon.tar.xz" | sha256sum -c -; \
    mkdir -p /opt/salmon; \
    tar -xJf /tmp/salmon.tar.xz -C /opt/salmon --strip-components=1; \
    test -x /opt/salmon/salmon; \
    test "$(/opt/salmon/salmon --version)" = "salmon ${SALMON_VERSION}"

FROM debian:13-slim

ARG SALMON_VERSION=2.1.1
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
    salmon --help 2>&1 | grep -F "RNA-seq transcript quantification (Rust port)" >/dev/null; \
    salmon --no-version-check --help 2>&1 | grep -F "no-op" >/dev/null; \
    salmon --no-version-check index --help 2>&1 | grep -F "Build a salmon index" >/dev/null; \
    salmon --no-version-check quant --help 2>&1 | grep -F "Quantify transcript abundances" >/dev/null; \
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
    grep -F '"salmon_version": "2.1.1"' idx/info.json >/dev/null; \
    grep -F '"index_version": 1' idx/info.json >/dev/null; \
    grep -F '"num_refs": 2' idx/info.json >/dev/null; \
    printf '@r1\nACGTACGTACGTACGTACGT\n+\nFFFFFFFFFFFFFFFFFFFF\n@r2\nTTTTGGGGCCCCAAAATTTT\n+\nFFFFFFFFFFFFFFFFFFFF\n@r3\nACGTACGTACGTACGTACGT\n+\nFFFFFFFFFFFFFFFFFFFF\n' > reads.fq; \
    salmon --no-version-check quant -i idx -l A -r reads.fq -o quant -p 1 --quiet >/tmp/taf-salmon-quant.log 2>&1; \
    test -s quant/quant.sf; \
    grep -F "Name" quant/quant.sf >/dev/null; \
    grep -F "tx1" quant/quant.sf >/dev/null; \
    grep -F "tx2" quant/quant.sf >/dev/null; \
    salmon --no-version-check quant -i idx -l A -r reads.fq -o sketch_quant -p 1 --sketch --quiet >/tmp/taf-salmon-sketch.log 2>&1; \
    test -s sketch_quant/quant.sf; \
    grep -F "tx1" sketch_quant/quant.sf >/dev/null; \
    grep -F "tx2" sketch_quant/quant.sf >/dev/null; \
    mkdir -p q1 q2; \
    printf 'Name\tLength\tEffectiveLength\tTPM\tNumReads\ntx1\t40\t2.432\t100.0\t2.0\ntx2\t40\t2.432\t0.0\t0.0\n' > q1/quant.sf; \
    printf 'Name\tLength\tEffectiveLength\tTPM\tNumReads\ntx1\t40\t2.432\t10.0\t1.0\ntx2\t40\t2.432\t90.0\t9.0\n' > q2/quant.sf; \
    salmon --no-version-check quantmerge --quants q1 q2 --names s1 s2 --column TPM -o merged.tsv >/tmp/taf-salmon-merge.log 2>&1; \
    grep -F "Name" merged.tsv >/dev/null; \
    grep -F "tx2" merged.tsv >/dev/null; \
    grep -F "90" merged.tsv >/dev/null; \
    { salmon --no-version-check alevin > alevin.out 2>&1 && exit 1 || true; }; \
    grep -F "salmon alevin is not available" alevin.out >/dev/null; \
    grep -F "alevin-fry" alevin.out >/dev/null; \
    rm -rf /tmp/taf-salmon-check /tmp/salmon.ldd

WORKDIR /root
