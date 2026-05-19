FROM debian:13-slim AS fetcher

ARG TARGETARCH
ARG SALMON_VERSION=1.11.4
ARG SALMON_X86_64_SHA256=59dba764d579630a4ebbfaf7bb9575f1a72bbe215e76af3187d82b4665794833
ARG SALMON_AARCH64_SHA256=930cf75009a2f0a705a6acc6f4613d2add03f00961893333cd750570b6431198
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
      apt-get install -y --no-install-recommends ca-certificates curl && \
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
        salmon_arch="x86_64"; \
        salmon_sha256="${SALMON_X86_64_SHA256}"; \
        ;; \
      arm64) \
        salmon_arch="aarch64"; \
        salmon_sha256="${SALMON_AARCH64_SHA256}"; \
        ;; \
      *) \
        echo "unsupported TARGETARCH=${TARGETARCH}" >&2; \
        exit 1; \
        ;; \
    esac; \
    salmon_asset="salmon-linux-${salmon_arch}.tar.gz"; \
    curl -fsSL \
      -o /tmp/salmon.tar.gz \
      "https://github.com/COMBINE-lab/salmon/releases/download/v${SALMON_VERSION}/${salmon_asset}"; \
    echo "${salmon_sha256}  /tmp/salmon.tar.gz" | sha256sum -c -; \
    mkdir -p /opt/salmon; \
    tar -xzf /tmp/salmon.tar.gz -C /opt/salmon --strip-components=1; \
    test -x /opt/salmon/bin/salmon; \
    test "$(/opt/salmon/bin/salmon --version)" = "salmon ${SALMON_VERSION}"

FROM debian:13-slim

ARG SALMON_VERSION=1.11.4
ARG DEBIAN_FRONTEND=noninteractive
ARG APT_MIRROR=http://deb.debian.org/debian
ARG APT_SECURITY_MIRROR=http://deb.debian.org/debian-security

ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8
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
        locales \
        libstdc++6 && \
      break; \
      if [ "${attempt}" = "3" ]; then exit 1; fi; \
      rm -rf /var/lib/apt/lists/*; \
      sleep 2; \
    done; \
    sed -i 's/^# *\(en_US.UTF-8 UTF-8\)/\1/' /etc/locale.gen; \
    locale-gen en_US.UTF-8; \
    rm -rf /var/lib/apt/lists/*

COPY --from=fetcher /opt/salmon /opt/salmon

RUN set -eux; \
    ln -sf /opt/salmon/bin/salmon /usr/local/bin/salmon

RUN set -eux; \
    command -v salmon >/dev/null; \
    command -v ldd >/dev/null; \
    command -v locale >/dev/null; \
    test "$(salmon --version)" = "salmon ${SALMON_VERSION}"; \
    salmon --no-version-check --help 2>&1 | grep -F "salmon v${SALMON_VERSION}" >/dev/null; \
    salmon --no-version-check index --help 2>&1 | grep -F "Creates a salmon index" >/dev/null; \
    salmon --no-version-check quant --help-reads 2>&1 | grep -F "selective-alignment-based" >/dev/null; \
    salmon --no-version-check quantmerge --help 2>&1 | grep -F "Merge multiple quantification results" >/dev/null; \
    salmon --no-version-check --cite 2>&1 | grep -F "10.1038/nmeth.4197" >/dev/null; \
    ldd "$(command -v salmon)" > /tmp/salmon.ldd; \
    grep -F "libstdc++.so" /tmp/salmon.ldd >/dev/null; \
    ! grep -F "not found" /tmp/salmon.ldd >/dev/null; \
    mkdir -p /tmp/taf-salmon-check; \
    cd /tmp/taf-salmon-check; \
    printf '>tx1\nACGTACGTACGTACGTACGTACGTACGTACGTACGTACGT\n>tx2\nTTTTGGGGCCCCAAAATTTTGGGGCCCCAAAATTTTGGGG\n' > transcripts.fa; \
    salmon --no-version-check index -t transcripts.fa -i idx -k 15 -p 1 >/tmp/taf-salmon-index.log 2>&1; \
    test -s idx/info.json; \
    test -s idx/sshash.bin; \
    grep -F '"num_kmers"' idx/info.json >/dev/null; \
    printf '@r1\nACGTACGTACGTACGTACGT\n+\nFFFFFFFFFFFFFFFFFFFF\n@r2\nTTTTGGGGCCCCAAAATTTT\n+\nFFFFFFFFFFFFFFFFFFFF\n@r3\nACGTACGTACGTACGTACGT\n+\nFFFFFFFFFFFFFFFFFFFF\n' > reads.fq; \
    salmon --no-version-check quant -i idx -l A -r reads.fq -o quant -p 1 --minAssignedFrags 1 -q >/tmp/taf-salmon-quant.log 2>&1; \
    test -s quant/quant.sf; \
    grep -F "Name" quant/quant.sf >/dev/null; \
    grep -F "tx1" quant/quant.sf >/dev/null; \
    grep -F "tx2" quant/quant.sf >/dev/null; \
    mkdir -p q1 q2; \
    printf 'Name\tLength\tEffectiveLength\tTPM\tNumReads\ntx1\t40\t2.432\t100.0\t2.0\ntx2\t40\t2.432\t0.0\t0.0\n' > q1/quant.sf; \
    printf 'Name\tLength\tEffectiveLength\tTPM\tNumReads\ntx1\t40\t2.432\t10.0\t1.0\ntx2\t40\t2.432\t90.0\t9.0\n' > q2/quant.sf; \
    salmon --no-version-check quantmerge --quants q1 q2 --names s1 s2 --column TPM -o merged.tsv >/tmp/taf-salmon-merge.log 2>&1; \
    grep -F "Name" merged.tsv >/dev/null; \
    grep -F "tx2" merged.tsv >/dev/null; \
    grep -F "90" merged.tsv >/dev/null; \
    { salmon --no-version-check alevin > alevin.out 2>&1 && exit 1 || true; }; \
    grep -F "alevin-fry" alevin.out >/dev/null; \
    rm -rf /tmp/taf-salmon-check /tmp/salmon.ldd

WORKDIR /root
