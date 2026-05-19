# salmon

TAFFISH app for Salmon, a fast transcript-level RNA-seq quantification tool from
COMBINE-lab.

## Package Identity

| Field | Value |
| --- | --- |
| name | `salmon` |
| command | `taf-salmon` |
| kind | `tool` |
| TAFFISH version | `1.11.4-r1` |
| container image | `ghcr.io/taffish/salmon:1.11.4-r1` |
| upstream | `COMBINE-lab/salmon` |
| upstream release | `v1.11.4` |
| runtime version | `salmon 1.11.4` |
| native platforms | `linux/amd64`, `linux/arm64` |

## What Is Included

This app packages the official Salmon `v1.11.4` Linux release binaries:

- `salmon-linux-x86_64.tar.gz`
  - SHA256: `59dba764d579630a4ebbfaf7bb9575f1a72bbe215e76af3187d82b4665794833`
- `salmon-linux-aarch64.tar.gz`
  - SHA256: `930cf75009a2f0a705a6acc6f4613d2add03f00961893333cd750570b6431198`

The Dockerfile selects the correct upstream asset from Docker `TARGETARCH`,
verifies the checksum, installs the upstream `salmon` binary under
`/opt/salmon/bin/salmon`, and exposes it as `/usr/local/bin/salmon`.

The runtime image uses `debian:13-slim`. Debian 12 is not sufficient for these
official binaries because they require newer glibc/libstdc++ symbols such as
`GLIBC_2.38` and `GLIBCXX_3.4.32`. The image also generates `en_US.UTF-8`,
because `salmon index` needs a real generated locale in slim containers.

## Basic Usage

Show TAFFISH wrapper help:

```sh
taf-salmon --help
```

Show upstream Salmon help:

```sh
taf-salmon -- --help
taf-salmon salmon --help
```

Build an index:

```sh
taf-salmon salmon --no-version-check index \
  -t transcripts.fa \
  -i salmon_index \
  -k 31 \
  -p 8
```

Quantify single-end reads:

```sh
taf-salmon salmon --no-version-check quant \
  -i salmon_index \
  -l A \
  -r reads.fq.gz \
  -o sample_quant \
  -p 8
```

Quantify paired-end reads:

```sh
taf-salmon salmon --no-version-check quant \
  -i salmon_index \
  -l A \
  -1 reads_1.fq.gz \
  -2 reads_2.fq.gz \
  -o sample_quant \
  -p 8
```

Merge transcript TPMs from multiple `quant.sf` outputs:

```sh
taf-salmon salmon --no-version-check quantmerge \
  --quants sample1_quant sample2_quant \
  --names sample1 sample2 \
  --column TPM \
  -o merged_tpm.tsv
```

## TAFFISH Command Mode

This is a normal TAFFISH tool app with `command_mode = true`.

For Salmon subcommands, prefer the explicit executable form:

```sh
taf-salmon salmon index ...
taf-salmon salmon quant ...
taf-salmon salmon quantmerge ...
```

Do not rely on:

```sh
taf-salmon index ...
```

In command mode, a non-option first argument can be interpreted as a container
executable name rather than as a Salmon subcommand. The explicit
`taf-salmon salmon ...` form is unambiguous and also lets users run the same
container environment directly.

For option-leading arguments to the default upstream command, this also works:

```sh
taf-salmon -- --version
taf-salmon -- --no-version-check index --help
```

## Version Check And Network

Salmon may attempt an upstream version check before subcommands. The smoke tests
and examples use `--no-version-check` so runs are offline and deterministic. The
wrapper does not force that option, so users still get the upstream default
behavior unless they pass `--no-version-check`.

## Functional Surface

Packaged upstream command:

- `salmon index`: build the v1.11 SSHash-backed index
- `salmon quant`: quantify transcript abundance from reads or alignments
- `salmon quantmerge`: merge Salmon quantification tables
- `salmon --cite`: print citation information
- `salmon alevin`: present only as an upstream migration message

Salmon v1.11.4 removed the legacy integrated `salmon alevin` implementation.
This is an upstream change, not a TAFFISH packaging omission. Upstream recommends
the `piscem` plus `alevin-fry` stack for current single-cell workflows, or
Salmon `v1.10.2` if the historical `alevin` command is required.

## Compatibility Notes

Salmon v1.11 changed the underlying index format to the SSHash-based index.
Indices built with versions before `1.11.0` must be rebuilt before use with this
package.

The app supports native Linux `amd64` and native Linux `arm64` through official
upstream binaries. No Docker platform emulation is required for either declared
platform.

The container includes the upstream binary, the upstream README and GPL license,
glibc/libstdc++ runtime libraries from Debian 13, CA certificates, and a
generated `en_US.UTF-8` locale. It does not bundle reference transcriptomes,
genomes, decoy lists, annotation files, `piscem`, `alevin-fry`, `simpleaf`,
or external aligners.

## Smoke Coverage

The smoke tests are independent and run without network access. They check:

- `salmon 1.11.4` runtime version and citation DOI
- command help for `index`, `quant --help-reads`, `quant --help-alignment`,
  and `quantmerge`
- dynamic library resolution through `ldd`
- a tiny SSHash index build
- a tiny single-end `quant` run that writes `quant/quant.sf`
- `quantmerge` on two synthetic `quant.sf` directories
- the upstream `alevin` removal message

These tests verify packaging, command availability, and small real execution
paths. They are not a substitute for biological validation on production
references and read sets.

## Upstream

- Upstream repository: <https://github.com/COMBINE-lab/salmon>
- Documentation: <https://salmon.readthedocs.io/en/latest/>
- Release: <https://github.com/COMBINE-lab/salmon/releases/tag/v1.11.4>
- Upstream license: GPL-3.0-or-later
- Citation: Patro et al. 2017, Nature Methods
- DOI: `10.1038/nmeth.4197`
- PMID: `28263959`
