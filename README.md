# salmon

TAFFISH app for Salmon, a fast transcript-level RNA-seq quantification tool from
COMBINE-lab.

## Package Identity

| Field | Value |
| --- | --- |
| name | `salmon` |
| command | `taf-salmon` |
| kind | `tool` |
| TAFFISH version | `2.0.1-r1` |
| container image | `ghcr.io/taffish/salmon:2.0.1-r1` |
| upstream | `COMBINE-lab/salmon` |
| upstream release | `v2.0.1` |
| runtime version | `salmon 2.0.1` |
| native platforms | `linux/amd64`, `linux/arm64` |

## What Is Included

This app packages the official Salmon `v2.0.1` Rust CLI Linux release binaries:

- `salmon-cli-x86_64-unknown-linux-gnu.tar.xz`
  - SHA256: `afab8492f3b55c6e5e302f7044df4d072a925560c8d09f61d862618dad48fd89`
- `salmon-cli-aarch64-unknown-linux-gnu.tar.xz`
  - SHA256: `c63dec5318ac09093824421d2f56f769c461399d0f28d44b8fb9275fedf87f45`

The Dockerfile selects the correct upstream asset from Docker `TARGETARCH`,
verifies the checksum, installs the upstream `salmon` binary under
`/opt/salmon/salmon`, and exposes it as `/usr/local/bin/salmon`.

Salmon 2.0 is a from-scratch Rust rewrite. It keeps the core
`salmon index` -> `salmon quant` -> `quant.sf` workflow and downstream
quantification table formats, but it is a new major version with intentional
breaking changes.

The runtime image uses `debian:13-slim` and the official Linux GNU binary. The
v2 binary is much lighter than the old C++ distribution and depends only on the
standard GNU runtime libraries available in Debian 13, notably `libgcc_s`, `libm`,
and `libc`.

## Basic Usage

Show TAFFISH wrapper help:

```sh
taf-salmon --help
```

Show upstream Salmon help and version:

```sh
taf-salmon -- --help
taf-salmon -- --version
taf-salmon salmon --help
taf-salmon salmon --version
```

Build a Salmon 2 index:

```sh
taf-salmon salmon index \
  -t transcripts.fa \
  -i salmon_index \
  -k 31 \
  -p 8
```

Quantify single-end reads:

```sh
taf-salmon salmon quant \
  -i salmon_index \
  -l A \
  -r reads.fq.gz \
  -o sample_quant \
  -p 8
```

Quantify paired-end reads:

```sh
taf-salmon salmon quant \
  -i salmon_index \
  -l A \
  -1 reads_1.fq.gz \
  -2 reads_2.fq.gz \
  -o sample_quant \
  -p 8
```

Use the Salmon 2 sketch mode:

```sh
taf-salmon salmon quant \
  -i salmon_index \
  -l A \
  -r reads.fq.gz \
  --sketch \
  -o sample_sketch_quant \
  -p 8
```

Merge transcript TPMs from multiple `quant.sf` outputs:

```sh
taf-salmon salmon quantmerge \
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
taf-salmon salmon debug-map ...
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
taf-salmon -- --help
```

## Version Check And Network

Salmon 2.0 accepts `--no-version-check` and `SALMON_NO_VERSION_CHECK` for
compatibility with C++ Salmon, but upstream documents them as no-ops: Salmon 2
does not contact the network for version checks. Keeping the flag in scripts is
safe, but no longer necessary.

## Functional Surface

Packaged upstream command:

- `salmon index`: build a Salmon 2 index from transcript FASTA
- `salmon quant`: quantify transcript abundance from reads or alignments
- `salmon quant --sketch`: use the Salmon 2 sketch / pseudoalignment path
- `salmon quantmerge`: merge Salmon quantification tables
- `salmon debug-map`: diagnostic per-read best-mapping detail
- `salmon alevin`: present only as an upstream migration message

Salmon 2.0 removed the legacy integrated `salmon alevin` implementation. This
is an upstream change, not a TAFFISH packaging omission. Upstream recommends the
`piscem` plus `alevin-fry` ecosystem for current single-cell workflows.

The old top-level `salmon --cite` command is not present in Salmon 2. Citation
information remains documented upstream and below.

## Compatibility Notes

Salmon 2.0 uses a new Rust index format and cannot read C++ Salmon / pufferfish
indices. Rebuild all pre-2.0 indices with this package before quantification.

Downstream quantification outputs remain compatible: `quant.sf`, `cmd_info.json`,
`lib_format_counts.json`, `aux_info/meta_info.json`, and inferential replicate
outputs are intended to stay drop-in for tximport, tximeta, fishpond, and swish.

The Salmon 2 migration guide documents removed, accepted-but-ignored, and new
options. Notable changes include:

- `--sketch` and `--sketchStrictOrphans` are new Salmon 2 quant options.
- `--minAssignedFrags` is removed.
- `--features` for `index` is removed.
- several niche C++ inference and alignment options are rejected or accepted
  only as compatibility no-ops.

Salmon `2.0.1` is a patch release over `2.0.0` with no new options, no breaking
changes, and no output-format changes. It refines selective-alignment
multimapping weights by including fragment-length probability terms and using
abundance-aware fragment-length-distribution training.

The app supports native Linux `amd64` and native Linux `arm64` through official
upstream binaries. No Docker platform emulation is required for either declared
platform.

The container includes the upstream binary, upstream README and BSD-3-Clause
license, GNU runtime libraries from Debian 13, and CA certificates. It does not
bundle reference transcriptomes, genomes, decoy lists, annotation files,
`piscem`, `alevin-fry`, `simpleaf`, `oarfish`, or external aligners.

## Smoke Coverage

The smoke tests are independent and run without network access. They check:

- `salmon 2.0.1` runtime version and Rust-port help banner
- no-op compatibility behavior for `--no-version-check`
- help for `index`, `quant`, `quantmerge`, and `debug-map`
- dynamic library resolution through `ldd`
- a tiny Salmon 2 index build that writes `info.json`, `index.ssi`, and
  `index.ctab`
- a tiny single-end selective-alignment `quant` run that writes `quant/quant.sf`
- a tiny `quant --sketch` run that writes `sketch_quant/quant.sf`
- `quantmerge` on two synthetic `quant.sf` directories
- the upstream `alevin` removal and migration message

These tests verify packaging, command availability, and small real execution
paths. They are not a substitute for biological validation on production
references and read sets.

## Upstream

- Upstream repository: <https://github.com/COMBINE-lab/salmon>
- Documentation: <https://combine-lab.github.io/salmon/>
- Release: <https://github.com/COMBINE-lab/salmon/releases/tag/v2.0.1>
- Migration guide: <https://github.com/COMBINE-lab/salmon/blob/v2.0.1/MIGRATION.md>
- Upstream license: BSD-3-Clause
- Citation: Patro et al. 2017, Nature Methods
- DOI: `10.1038/nmeth.4197`
- PMID: `28263959`
